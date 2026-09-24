/// Configuración que se inyecta al compilar, sin escribir secretos en el
/// código:
///
///   flutter run -d chrome --dart-define-from-file=env.json
///
/// Si no se entregan SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY, la app arranca en
/// "modo demo": autenticación local con cuentas de prueba, útil para
/// desarrollar la interfaz sin tener el proyecto de Supabase creado.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Dominios institucionales con los que se permite crear una cuenta.
  /// Debe coincidir con la lista de `handle_new_user` en
  /// supabase/migrations/0001_auth_profiles.sql.
  static const allowedEmailDomains = ['duocuc.cl', 'duoc.cl', 'profesor.duoc.cl'];
}
