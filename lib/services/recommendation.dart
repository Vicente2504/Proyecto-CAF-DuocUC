import '../models/evaluation.dart';
import '../models/exercise.dart';

/// Motor de recomendación (paso 4 de la propuesta). Regla: cualquier
/// ejercicio con puntaje <= 1 se considera una debilidad y entra al plan
/// con su prescripción. Si ninguno cae bajo ese umbral, se usa el de
/// menor puntaje como mantención preventiva. Los ejercicios con dolor
/// nunca entran al plan: el estudiante debe ser evaluado antes.
/// Funciones puras, sin acceso a estado ni a la base de datos, para que
/// se puedan probar de forma aislada.
const int kWeakThreshold = 1;

List<PlanItem> buildExercisePlan(List<ExerciseScore> scores) {
  final candidates = scores.where((s) => !s.pain && s.score > 0).toList();
  var selected = candidates.where((s) => s.score <= kWeakThreshold).toList();
  if (selected.isEmpty && candidates.isNotEmpty) {
    final lowest = candidates.map((s) => s.score).reduce((a, b) => a < b ? a : b);
    if (lowest < 3) selected = candidates.where((s) => s.score == lowest).toList();
  }
  // Mantiene el orden del catálogo.
  final order = {for (var i = 0; i < kExercises.length; i++) kExercises[i].id: i};
  selected.sort((a, b) => (order[a.exerciseId] ?? 99).compareTo(order[b.exerciseId] ?? 99));
  return [for (final s in selected) PlanItem(exerciseId: s.exerciseId, score: s.score)];
}

/// Ejercicios donde se reportó dolor (o puntaje 0) en una evaluación.
List<ExerciseScore> painfulExercises(List<ExerciseScore> scores) =>
    scores.where((s) => s.pain || s.score == 0).toList();

int totalScoreOf(List<ExerciseScore> scores) =>
    scores.fold(0, (sum, s) => sum + s.score);

/// Próxima reevaluación sugerida: 5 semanas después (punto medio del
/// rango 4-6 semanas del paso 4 de la propuesta).
DateTime nextEvaluationDate(DateTime lastDate) =>
    lastDate.add(const Duration(days: 35));
