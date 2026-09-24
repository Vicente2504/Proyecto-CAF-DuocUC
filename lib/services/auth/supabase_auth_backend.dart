import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_user.dart';
import 'auth_backend.dart';

/// Autenticación real con Supabase Auth. El rol de cada usuario vive en la
/// tabla `public.profiles` (ver supabase/migrations), nunca en el cliente:
/// quien se registra queda siempre como estudiante y solo un
/// administrador puede asignar los roles de instructor o administrador.
class SupabaseAuthBackend implements AuthBackend {
  SupabaseAuthBackend(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  /// En la web, los enlaces de confirmación y recuperación vuelven a la
  /// misma dirección desde donde se abrió la app.
  String? get _redirectUrl => kIsWeb ? Uri.base.origin : null;

  @override
  bool get isDemo => false;

  @override
  Stream<AuthBackendEvent> get events => _auth.onAuthStateChange
      .map<AuthBackendEvent?>((state) => switch (state.event) {
            AuthChangeEvent.signedOut => AuthBackendEvent.signedOut,
            AuthChangeEvent.passwordRecovery => AuthBackendEvent.passwordRecovery,
            _ => null,
          })
      .where((e) => e != null)
      .cast<AuthBackendEvent>();

  @override
  Future<AppUser?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _guard(() => _loadProfile(user));
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return _guard(() async {
      final res = await _auth.signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user == null) throw const AuthFailure('No se pudo iniciar sesión.');
      try {
        return await _loadProfile(user);
      } catch (_) {
        await _auth.signOut();
        rethrow;
      }
    });
  }

  @override
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final res = await _auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        emailRedirectTo: _redirectUrl,
      );
      final user = res.user;
      // Con confirmación de correo activa, Supabase no devuelve error si el
      // correo ya existe: responde un usuario sin identidades.
      if (user == null || (user.identities?.isEmpty ?? false)) {
        throw const AuthFailure('Ya existe una cuenta con este correo.');
      }
      if (res.session == null) return const SignUpResult.needsEmailConfirmation();
      return SignUpResult.signedIn(await _loadProfile(user));
    });
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _guard(() => _auth.resetPasswordForEmail(email, redirectTo: _redirectUrl));
  }

  @override
  Future<AppUser> updatePassword(String newPassword) {
    return _guard(() async {
      final res = await _auth.updateUser(UserAttributes(password: newPassword));
      final user = res.user;
      if (user == null) throw const AuthFailure('No se pudo actualizar la contraseña.');
      return _loadProfile(user);
    });
  }

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  Future<AppUser> _loadProfile(User user) async {
    final row = await _client
        .from('profiles')
        .select('full_name, role')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) {
      throw const AuthFailure(
        'Tu cuenta no tiene un perfil asignado. Contacta al administrador del CAF.',
      );
    }
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: (row['full_name'] as String?) ?? '',
      role: UserRole.fromDb(row['role'] as String?),
    );
  }

  /// Traduce los errores de Supabase a mensajes en español.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on AuthRetryableFetchException {
      throw const AuthFailure('No se pudo conectar con el servidor. Revisa tu conexión a internet.');
    } on AuthWeakPasswordException {
      throw const AuthFailure('La contraseña es demasiado débil. Usa al menos 8 caracteres combinando letras y números.');
    } on AuthException catch (e) {
      throw AuthFailure(_translate(e));
    } on PostgrestException {
      throw const AuthFailure('No se pudo cargar tu perfil. Intenta nuevamente en unos minutos.');
    } catch (_) {
      throw const AuthFailure('Ocurrió un error inesperado. Intenta nuevamente.');
    }
  }

  String _translate(AuthException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();
    if (code == 'invalid_credentials' || msg.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (code == 'email_not_confirmed' || msg.contains('email not confirmed')) {
      return 'Debes confirmar tu correo antes de ingresar. Revisa tu bandeja de entrada.';
    }
    if (code == 'user_already_exists' || msg.contains('already registered')) {
      return 'Ya existe una cuenta con este correo.';
    }
    if (code.contains('rate_limit') || e.statusCode == '429') {
      return 'Demasiados intentos. Espera unos minutos antes de volver a intentar.';
    }
    if (code == 'same_password') {
      return 'La nueva contraseña debe ser distinta de la anterior.';
    }
    if (msg.contains('database error saving new user')) {
      return 'No se pudo crear la cuenta. Verifica que uses tu correo institucional de Duoc UC.';
    }
    return 'No se pudo completar la operación (${e.message}).';
  }
}
