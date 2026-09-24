import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/evaluation.dart';
import '../models/exercise.dart';
import '../models/student.dart';
import 'recommendation.dart';

/// Estado central de la aplicación: la lista de estudiantes y de
/// evaluaciones, con persistencia en el almacenamiento local del
/// navegador (vía shared_preferences, que en Flutter Web usa
/// localStorage por debajo). No hay backend: todo vive en el navegador
/// del instructor, igual que un prototipo de Fase 1 pensado para
/// demostrarse en un solo computador.
class AppState extends ChangeNotifier {
  static const _studentsKey = 'caf_students_v1';
  // v2: las evaluaciones puntúan los 10 ejercicios del catálogo (la v1
  // usaba los 7 patrones FMS y no es compatible).
  static const _evaluationsKey = 'caf_evaluations_v2';

  List<Student> _students = [];
  List<Evaluation> _evaluations = [];
  bool _loading = true;

  List<Student> get students => List.unmodifiable(_students);
  List<Evaluation> get evaluations => List.unmodifiable(_evaluations);
  bool get loading => _loading;

  final Random _random = Random();

  String _newId(String prefix) {
    final rand = _random.nextInt(0x7fffffff).toRadixString(36);
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$prefix-$time-$rand';
  }

  Future<void> load() async {
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

    _loading = false;
    notifyListeners();
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

  Future<void> addStudent(String name, String email) async {
    final student = Student(
      id: _newId('student'),
      name: name,
      email: email,
      addedAt: DateTime.now(),
    );
    _students = [..._students, student]
      ..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    await _persist();
  }

  Future<void> addEvaluation({
    required String studentId,
    required List<ExerciseScore> scores,
    String? notes,
  }) async {
    final evaluation = Evaluation(
      id: _newId('eval'),
      studentId: studentId,
      date: DateTime.now(),
      notes: notes,
      scores: scores,
      plan: buildExercisePlan(scores),
    );
    _evaluations = [..._evaluations, evaluation];
    notifyListeners();
    await _persist();
  }

  Evaluation? latestEvaluationFor(String studentId) {
    final list =
        _evaluations.where((e) => e.studentId == studentId).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => b.date.compareTo(a.date));
    return list.first;
  }

  List<Evaluation> historyFor(String studentId) {
    final list =
        _evaluations.where((e) => e.studentId == studentId).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
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
