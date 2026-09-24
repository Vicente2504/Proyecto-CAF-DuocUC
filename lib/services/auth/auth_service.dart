import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';
import 'auth_backend.dart';

enum AuthStatus { initializing, signedOut, signedIn, passwordRecovery }

/// Estado de sesión que observa la interfaz. Las pantallas llaman a estos
/// métodos y muestran el `AuthFailure.message` si algo falla.
class AuthService extends ChangeNotifier {
  AuthService(this._backend);

  final AuthBackend _backend;
  StreamSubscription<AuthBackendEvent>? _subscription;

  AuthStatus _status = AuthStatus.initializing;
  AppUser? _user;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isDemo => _backend.isDemo;

  Future<void> init() async {
    _subscription = _backend.events.listen(_onBackendEvent);
    AppUser? restored;
    try {
      restored = await _backend.restoreSession();
    } on AuthFailure {
      await _backend.signOut();
    }
    _user = restored;
    // Un evento de recuperación de contraseña puede llegar mientras se
    // restaura la sesión; en ese caso tiene prioridad.
    if (_status == AuthStatus.initializing) {
      _status = restored == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    }
    notifyListeners();
  }

  void _onBackendEvent(AuthBackendEvent event) {
    switch (event) {
      case AuthBackendEvent.signedOut:
        _user = null;
        _status = AuthStatus.signedOut;
      case AuthBackendEvent.passwordRecovery:
        _status = AuthStatus.passwordRecovery;
    }
    notifyListeners();
  }

  static String _normalize(String email) => email.trim().toLowerCase();

  Future<void> signIn({required String email, required String password}) async {
    _user = await _backend.signIn(email: _normalize(email), password: password);
    _status = AuthStatus.signedIn;
    notifyListeners();
  }

  /// Devuelve `true` si el usuario debe confirmar su correo antes de
  /// poder ingresar.
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final result = await _backend.signUp(
      fullName: fullName.trim(),
      email: _normalize(email),
      password: password,
    );
    if (result.needsEmailConfirmation) return true;
    _user = result.user;
    _status = AuthStatus.signedIn;
    notifyListeners();
    return false;
  }

  Future<void> sendPasswordReset(String email) => _backend.sendPasswordReset(_normalize(email));

  Future<void> updatePassword(String newPassword) async {
    _user = await _backend.updatePassword(newPassword);
    _status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _backend.signOut();
    } finally {
      _user = null;
      _status = AuthStatus.signedOut;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
