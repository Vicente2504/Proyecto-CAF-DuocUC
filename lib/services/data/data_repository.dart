import '../../models/app_user.dart';
import '../../models/evaluation.dart';
import '../../models/student.dart';

/// Error de datos con un mensaje listo para mostrar al usuario.
class DataFailure implements Exception {
  final String message;

  const DataFailure(this.message);

  @override
  String toString() => message;
}

typedef DataSnapshot = ({List<Student> students, List<Evaluation> evaluations});

/// Dónde se guardan las fichas y evaluaciones. Hay dos implementaciones:
/// la base de datos PostgreSQL de Supabase y el almacenamiento local del
/// navegador para el modo demo.
abstract class DataRepository {
  /// Todo lo que el usuario actual puede ver (las políticas RLS de la base
  /// de datos filtran según su rol).
  Future<DataSnapshot> load();

  /// Garantiza que el estudiante con sesión iniciada tenga su ficha, para
  /// que aparezca en la lista del instructor sin agregarlo a mano.
  Future<void> ensureStudentRecord(AppUser user);

  Future<Student> addStudent({required String name, required String email});

  Future<Evaluation> addEvaluation({
    required String studentId,
    required List<ExerciseScore> scores,
    required List<PlanItem> plan,
    String? notes,
  });
}
