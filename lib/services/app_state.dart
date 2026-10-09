import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/evaluation.dart';
import '../models/student.dart';
import 'data/data_repository.dart';
import 'recommendation.dart';

/// Estado central de la aplicación: la lista de estudiantes y de
/// evaluaciones que el usuario actual puede ver. Dónde se guardan lo
/// decide el [DataRepository]: PostgreSQL en Supabase, o el navegador en
/// el modo demo.
class AppState extends ChangeNotifier {
  AppState(this._repository);

  final DataRepository _repository;
  AppUser? _user;

  List<Student> _students = [];
  List<Evaluation> _evaluations = [];
  bool _loading = true;
  String? _error;

  List<Student> get students => List.unmodifiable(_students);
  List<Evaluation> get evaluations => List.unmodifiable(_evaluations);
  bool get loading => _loading;

  /// Mensaje del último error al cargar, o null si la carga funcionó.
  String? get error => _error;

  /// Carga los datos de [user]. Se llama al entrar a la app, porque lo
  /// que se ve depende del rol; si es estudiante, antes se asegura de que
  /// tenga su ficha. No avisa a la interfaz al comenzar (puede llamarse
  /// desde initState); para eso está [retry].
  Future<void> load(AppUser user) async {
    _user = user;
    _loading = true;
    _error = null;
    _students = [];
    _evaluations = [];
    try {
      if (user.role == UserRole.estudiante) {
        await _repository.ensureStudentRecord(user);
      }
      final data = await _repository.load();
      _students = [...data.students]..sort((a, b) => a.name.compareTo(b.name));
      _evaluations = [...data.evaluations];
    } on DataFailure catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  /// Vuelve a cargar mostrando el indicador de carga.
  Future<void> retry() {
    final future = load(_user!);
    notifyListeners();
    return future;
  }

  /// Lanza [DataFailure] si no se pudo guardar.
  Future<void> addStudent(String name, String email) async {
    final student = await _repository.addStudent(name: name, email: email);
    _students = [..._students, student]
      ..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  /// Lanza [DataFailure] si no se pudo guardar.
  Future<void> addEvaluation({
    required String studentId,
    required List<ExerciseScore> scores,
    String? notes,
  }) async {
    final evaluation = await _repository.addEvaluation(
      studentId: studentId,
      scores: scores,
      plan: buildExercisePlan(scores),
      notes: notes,
    );
    _evaluations = [..._evaluations, evaluation];
    notifyListeners();
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
}
