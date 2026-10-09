import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_user.dart';
import '../../models/evaluation.dart';
import '../../models/exercise.dart';
import '../../models/student.dart';
import 'data_repository.dart';

/// Fichas y evaluaciones guardadas en PostgreSQL (Supabase). Las tablas y
/// las reglas de acceso por rol están en
/// supabase/migrations/0002_students_evaluations.sql.
class SupabaseDataRepository implements DataRepository {
  SupabaseDataRepository(this._client);

  final SupabaseClient _client;

  static const _evaluationColumns = 'id, student_id, evaluated_at, notes, '
      'evaluation_scores(exercise_id, score, pain), '
      'evaluation_plan_items(exercise_id, score)';

  @override
  Future<DataSnapshot> load() => _guard(() async {
        final students = await _client
            .from('students')
            .select('id, full_name, email, created_at')
            .order('full_name');
        final evaluations = await _client
            .from('evaluations')
            .select(_evaluationColumns)
            .order('evaluated_at');
        return (
          students: students.map(_studentFromRow).toList(),
          evaluations: evaluations.map(_evaluationFromRow).toList(),
        );
      });

  /// En Supabase la ficha la crea la base de datos al registrarse (trigger
  /// de supabase/migrations/0003_auto_student_record.sql).
  @override
  Future<void> ensureStudentRecord(AppUser user) async {}

  @override
  Future<Student> addStudent({required String name, required String email}) => _guard(() async {
        final normalized = email.trim().toLowerCase();
        final row = await _client
            .from('students')
            .insert({'full_name': name.trim(), 'email': normalized.isEmpty ? null : normalized})
            .select('id, full_name, email, created_at')
            .single();
        return _studentFromRow(row);
      });

  @override
  Future<Evaluation> addEvaluation({
    required String studentId,
    required List<ExerciseScore> scores,
    required List<PlanItem> plan,
    String? notes,
  }) =>
      _guard(() async {
        final row = await _client.rpc('create_evaluation', params: {
          'p_student_id': studentId,
          'p_notes': notes,
          'p_scores': [
            for (final s in scores) {'exercise_id': s.exerciseId, 'score': s.score, 'pain': s.pain},
          ],
          'p_plan': [
            for (final p in plan) {'exercise_id': p.exerciseId, 'score': p.score},
          ],
        }) as Map<String, dynamic>;
        return Evaluation(
          id: row['id'] as String,
          studentId: row['student_id'] as String,
          date: DateTime.parse(row['evaluated_at'] as String).toLocal(),
          notes: row['notes'] as String?,
          scores: scores,
          plan: plan,
        );
      });

  static Student _studentFromRow(Map<String, dynamic> row) => Student(
        id: row['id'] as String,
        name: row['full_name'] as String,
        email: (row['email'] as String?) ?? '',
        addedAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );

  static final Map<String, int> _catalogOrder = {
    for (var i = 0; i < kExercises.length; i++) kExercises[i].id: i,
  };

  static int _byCatalog(String a, String b) =>
      (_catalogOrder[a] ?? 99).compareTo(_catalogOrder[b] ?? 99);

  static Evaluation _evaluationFromRow(Map<String, dynamic> row) {
    final scores = [
      for (final s in row['evaluation_scores'] as List)
        ExerciseScore(
          exerciseId: s['exercise_id'] as String,
          score: s['score'] as int,
          pain: (s['pain'] as bool?) ?? false,
        ),
    ]..sort((a, b) => _byCatalog(a.exerciseId, b.exerciseId));
    final plan = [
      for (final p in row['evaluation_plan_items'] as List)
        PlanItem(exerciseId: p['exercise_id'] as String, score: p['score'] as int),
    ]..sort((a, b) => _byCatalog(a.exerciseId, b.exerciseId));
    return Evaluation(
      id: row['id'] as String,
      studentId: row['student_id'] as String,
      date: DateTime.parse(row['evaluated_at'] as String).toLocal(),
      notes: row['notes'] as String?,
      scores: scores,
      plan: plan,
    );
  }

  /// Traduce los errores de PostgreSQL / Supabase a mensajes en español.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      // 23505: unique_violation · 42501: permiso denegado por RLS.
      if (e.code == '23505') {
        throw const DataFailure('Ya existe un estudiante registrado con ese correo.');
      }
      if (e.code == '42501') {
        throw const DataFailure('Tu cuenta no tiene permisos para realizar esta acción.');
      }
      throw DataFailure('No se pudo guardar en la base de datos (${e.message}).');
    } on AuthException {
      throw const DataFailure('Tu sesión expiró. Vuelve a iniciar sesión.');
    } catch (_) {
      throw const DataFailure('No se pudo conectar con la base de datos. Revisa tu conexión a internet.');
    }
  }
}
