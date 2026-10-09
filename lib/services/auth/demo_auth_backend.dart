import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_user.dart';
import 'auth_backend.dart';

/// Autenticación local SOLO para desarrollo, activa cuando la app se
/// ejecuta sin credenciales de Supabase. Las cuentas registradas se
/// guardan en el navegador sin cifrar: no usar con datos reales.
class DemoAuthBackend implements AuthBackend {
  static const demoPassword = 'caf12345';
  static const _sessionKey = 'caf_demo_session_v1';
  static const _usersKey = 'caf_demo_users_v1';
  // Roles cambiados desde la sección Usuarios: {correo: rol}.
  static const _rolesKey = 'caf_demo_roles_v1';

  static const demoAccounts = [
    AppUser(id: 'demo-admin', email: 'admin@duoc.cl', fullName: 'Administración CAF', role: UserRole.admin),
    AppUser(id: 'demo-instructor', email: 'instructor@duoc.cl', fullName: 'Instructor CAF', role: UserRole.instructor),
    // Coincide con una estudiante de los datos de ejemplo de AppState.
    AppUser(id: 'demo-javiera', email: 'javiera.munoz@duocuc.cl', fullName: 'Javiera Muñoz', role: UserRole.estudiante),
  ];

  final _events = StreamController<AuthBackendEvent>.broadcast();

  @override
  bool get isDemo => true;

  @override
  Stream<AuthBackendEvent> get events => _events.stream;

  @override
  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionKey);
    if (email == null) return null;
    return (await _allUsers(prefs))[email]?.user;
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final prefs = await SharedPreferences.getInstance();
    final entry = (await _allUsers(prefs))[email];
    if (entry == null || entry.password != password) {
      throw const AuthFailure('Correo o contraseña incorrectos.');
    }
    await prefs.setString(_sessionKey, email);
    return entry.user;
  }

  @override
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final prefs = await SharedPreferences.getInstance();
    if ((await _allUsers(prefs)).containsKey(email)) {
      throw const AuthFailure('Ya existe una cuenta con este correo.');
    }
    final user = AppUser(
      id: 'demo-${DateTime.now().microsecondsSinceEpoch}',
      email: email,
      fullName: fullName,
      role: UserRole.estudiante,
    );
    final registered = _registeredRaw(prefs)
      ..add({'id': user.id, 'email': email, 'fullName': fullName, 'password': password});
    await prefs.setString(_usersKey, jsonEncode(registered));
    await prefs.setString(_sessionKey, email);
    return SignUpResult.signedIn(user);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    throw const AuthFailure(
      'La recuperación de contraseña no está disponible en modo demo. '
      'La contraseña de las cuentas de prueba es $demoPassword.',
    );
  }

  @override
  Future<AppUser> updatePassword(String newPassword) async {
    throw const AuthFailure('No disponible en modo demo.');
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  @override
  Future<List<AppUser>> listUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await _requireAdmin(prefs);
    final users = (await _allUsers(prefs)).values.map((e) => e.user).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return users;
  }

  @override
  Future<AppUser> updateUserRole(String userId, UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await _requireAdmin(prefs);
    final users = (await _allUsers(prefs)).values.map((e) => e.user).toList();
    final target = users.firstWhere((u) => u.id == userId,
        orElse: () => throw const AuthFailure('El usuario ya no existe.'));
    if (target.role == UserRole.admin &&
        role != UserRole.admin &&
        !users.any((u) => u.role == UserRole.admin && u.id != userId)) {
      throw const AuthFailure('Debe quedar al menos un administrador.');
    }
    final roles = _roleOverrides(prefs)..[target.email] = role.dbValue;
    await prefs.setString(_rolesKey, jsonEncode(roles));
    return AppUser(id: target.id, email: target.email, fullName: target.fullName, role: role);
  }

  Future<void> _requireAdmin(SharedPreferences prefs) async {
    final email = prefs.getString(_sessionKey);
    final current = email == null ? null : (await _allUsers(prefs))[email]?.user;
    if (current?.role != UserRole.admin) {
      throw const AuthFailure('Solo un administrador puede cambiar roles.');
    }
  }

  Map<String, dynamic> _roleOverrides(SharedPreferences prefs) {
    final raw = prefs.getString(_rolesKey);
    return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _registeredRaw(SharedPreferences prefs) {
    final raw = prefs.getString(_usersKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, ({AppUser user, String password})>> _allUsers(SharedPreferences prefs) async {
    final roles = _roleOverrides(prefs);
    AppUser withRole(AppUser u) => roles[u.email] == null
        ? u
        : AppUser(id: u.id, email: u.email, fullName: u.fullName, role: UserRole.fromDb(roles[u.email] as String));
    final base = {
      for (final u in demoAccounts) u.email: (user: u, password: demoPassword),
      for (final j in _registeredRaw(prefs))
        j['email'] as String: (
          user: AppUser(
            id: j['id'] as String,
            email: j['email'] as String,
            fullName: j['fullName'] as String,
            role: UserRole.estudiante,
          ),
          password: j['password'] as String,
        ),
    };
    return {for (final e in base.entries) e.key: (user: withRole(e.value.user), password: e.value.password)};
  }
}
