import '../../models/app_user.dart';

/// Error de autenticación con un mensaje ya listo para mostrar al usuario.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

/// Eventos que ocurren fuera de una acción del usuario en la pantalla
/// (sesión expirada, o regreso desde el enlace de recuperación de
/// contraseña enviado por correo).
enum AuthBackendEvent { signedOut, passwordRecovery }

/// Resultado de un registro: o el usuario queda con sesión iniciada, o
/// debe confirmar su correo antes de poder ingresar.
class SignUpResult {
  final AppUser? user;
  const SignUpResult.signedIn(AppUser this.user);
  const SignUpResult.needsEmailConfirmation() : user = null;

  bool get needsEmailConfirmation => user == null;
}

/// Contrato que cumplen tanto Supabase (producción) como el modo demo.
abstract class AuthBackend {
  bool get isDemo;

  Stream<AuthBackendEvent> get events;

  /// Devuelve el usuario si ya había una sesión guardada.
  Future<AppUser?> restoreSession();

  Future<AppUser> signIn({required String email, required String password});

  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  /// Cambia la contraseña del usuario con sesión activa (usado al volver
  /// desde el enlace de recuperación).
  Future<AppUser> updatePassword(String newPassword);

  Future<void> signOut();
}
