import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_user.dart';
import '../../models/evaluation.dart';
import '../../models/exercise.dart';
import '../../models/student.dart';
import '../recommendation.dart';
import 'data_repository.dart';

/// Modo demo: guarda fichas y evaluaciones en el navegador (vía
/// shared_preferences, que en Flutter Web usa localStorage por debajo).
/// Sin base de datos ni control de acceso: solo para desarrollo.
class LocalDataRepository implements DataRepository {
  static const _studentsKey = 'caf_students_v1';
  // v2: las evaluaciones puntúan los 10 ejercicios del catálogo (la v1
  // usaba los 7 patrones FMS y no es compatible).
  static const _evaluationsKey = 'caf_evaluations_v2';

  List<Student> _students = [];
  List<Evaluation> _evaluations = [];

  final Random _random = Random();

  String _newId(String prefix) {
    final rand = _random.nextInt(0x7fffffff).toRadixString(36);
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$prefix-$time-$rand';
  }

  @override
  Future<DataSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final studentsRaw = prefs.getString(_studentsKey);
    final evaluationsRaw = prefs.getString(_evaluationsKey);

    if (studentsRaw == null) {
      _seedDemoData();
      await _persist(prefs);
    } else {
      _students = (jsonDecode(studentsRaw) as List)
          .map((j) => Student.fromJson(j as Map<String, dynamic>))
          .toList();
      if (evaluationsRaw == null) {
        // Primera carga con el formato v2: se vuelven a crear las
        // evaluaciones de ejemplo para los estudiantes demo que existan.
        _evaluations = _demoEvaluations()
            .where((e) => _students.any((s) => s.id == e.studentId))
            .toList();
        await _persist(prefs);
      } else {
        _evaluations = (jsonDecode(evaluationsRaw) as List)
            .map((j) => Evaluation.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    }
    return (students: _students, evaluations: _evaluations);
  }

  Future<void> _persist([SharedPreferences? sharedPrefs]) async {
    final prefs = sharedPrefs ?? await SharedPreferences.getInstance();
    await prefs.setString(
      _studentsKey,
      jsonEncode(_students.map((s) => s.toJson()).toList()),
    );
    await prefs.setString(
      _evaluationsKey,
      jsonEncode(_evaluations.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> ensureStudentRecord(AppUser user) async {
    await load();
    final email = user.email.trim().toLowerCase();
    if (_students.any((s) => s.email.trim().toLowerCase() == email)) return;
    await addStudent(name: user.fullName.isNotEmpty ? user.fullName : email.split('@').first, email: email);
  }

  @override
  Future<Student> addStudent({required String name, required String email}) async {
    final student = Student(
      id: _newId('student'),
      name: name,
      email: email,
      addedAt: DateTime.now(),
    );
    _students = [..._students, student];
    await _persist();
    return student;
  }

  @override
  Future<Evaluation> addEvaluation({
    required String studentId,
    required List<ExerciseScore> scores,
    required List<PlanItem> plan,
    String? notes,
  }) async {
    final evaluation = Evaluation(
      id: _newId('eval'),
      studentId: studentId,
      date: DateTime.now(),
      notes: notes,
      scores: scores,
      plan: plan,
    );
    _evaluations = [..._evaluations, evaluation];
    await _persist();
    return evaluation;
  }

  void _seedDemoData() {
    final now = DateTime.now();
    final javiera = Student(
      id: 'student-javiera',
      name: 'Javiera Muñoz',
      email: 'javiera.munoz@duocuc.cl',
      addedAt: now.subtract(const Duration(days: 52)),
    );
    final benjamin = Student(
      id: 'student-benjamin',
      name: 'Benjamín Torres',
      email: 'benjamin.torres@duocuc.cl',
      addedAt: now.subtract(const Duration(days: 52)),
    );
    final antonia = Student(
      id: 'student-antonia',
      name: 'Antonia Vera',
      email: 'antonia.vera@duocuc.cl',
      addedAt: now.subtract(const Duration(days: 52)),
    );
    final matias = Student(
      id: 'student-matias',
      name: 'Matías Contreras',
      email: 'matias.contreras@duocuc.cl',
      addedAt: now.subtract(const Duration(days: 52)),
    );
    _students = [javiera, benjamin, antonia, matias];
    _evaluations = _demoEvaluations();
  }

  List<Evaluation> _demoEvaluations() {
    final now = DateTime.now();

    // Puntajes en el orden del catálogo: press banca, dominadas, peso
    // muerto, sentadilla, plancha lateral, plancha frontal, estocada,
    // remo, jalón al pecho y curl de bíceps.
    List<ExerciseScore> scoresOf(List<int> values) => [
          for (var i = 0; i < kExercises.length; i++)
            ExerciseScore(exerciseId: kExercises[i].id, score: values[i]),
        ];

    final firstScores = scoresOf([2, 1, 2, 3, 1, 2, 2, 3, 2, 3]);
    final secondScores = scoresOf([3, 2, 3, 3, 2, 3, 3, 3, 3, 3]);

    return [
      Evaluation(
        id: 'eval-javiera-1',
        studentId: 'student-javiera',
        date: now.subtract(const Duration(days: 42)),
        notes: 'Evaluación inicial de ingreso al CAF.',
        scores: firstScores,
        plan: buildExercisePlan(firstScores),
      ),
      Evaluation(
        id: 'eval-javiera-2',
        studentId: 'student-javiera',
        date: now.subtract(const Duration(days: 3)),
        notes: 'Control de seguimiento.',
        scores: secondScores,
        plan: buildExercisePlan(secondScores),
      ),
    ];
  }
}
