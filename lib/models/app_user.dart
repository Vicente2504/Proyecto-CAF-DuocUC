/// Perfiles de la propuesta técnica (sección 3). El valor `dbValue` es el
/// que se guarda en la columna `profiles.role` de Supabase.
enum UserRole {
  admin('admin', 'Administrador'),
  instructor('instructor', 'Instructor'),
  estudiante('estudiante', 'Estudiante');

  final String dbValue;
  final String label;

  const UserRole(this.dbValue, this.label);

  /// Ante un valor desconocido se asume el rol con menos permisos.
  static UserRole fromDb(String? value) => UserRole.values.firstWhere(
        (r) => r.dbValue == value,
        orElse: () => UserRole.estudiante,
      );
}

/// Usuario autenticado junto con su perfil (nombre y rol).
class AppUser {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  String get displayName => fullName.isNotEmpty ? fullName : email;

  String get initials {
    final parts = displayName.split(RegExp(r'[\s@.]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
