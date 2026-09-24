import 'package:caf_movimiento_flutter/models/evaluation.dart';
import 'package:caf_movimiento_flutter/models/exercise.dart';
import 'package:caf_movimiento_flutter/services/recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

List<ExerciseScore> _scores(List<int> values, {Set<String> pain = const {}}) => [
      for (var i = 0; i < kExercises.length; i++)
        ExerciseScore(exerciseId: kExercises[i].id, score: values[i], pain: pain.contains(kExercises[i].id)),
    ];

void main() {
  test('el catálogo tiene los 10 ejercicios en orden', () {
    expect(kExercises.map((e) => e.name).toList(), [
      'Press banca',
      'Dominadas',
      'Peso muerto',
      'Sentadilla',
      'Plancha lateral',
      'Plancha frontal',
      'Estocada',
      'Remo',
      'Jalón al pecho',
      'Curl de bíceps',
    ]);
    expect(kMaxScore, 30);
  });

  test('los ejercicios con puntaje 1 entran al plan', () {
    final plan = buildExercisePlan(_scores([2, 1, 2, 3, 1, 2, 2, 3, 2, 3]));
    expect(plan.map((p) => p.exerciseId), ['dominadas', 'plancha-lateral']);
  });

  test('sin debilidades se usa el de menor puntaje como mantención', () {
    final plan = buildExercisePlan(_scores([3, 3, 2, 3, 3, 3, 3, 3, 3, 3]));
    expect(plan.map((p) => p.exerciseId), ['peso-muerto']);
  });

  test('todo en 3 no genera plan', () {
    expect(buildExercisePlan(_scores(List.filled(10, 3))), isEmpty);
  });

  test('los ejercicios con dolor no entran al plan', () {
    final scores = _scores([0, 1, 3, 3, 3, 3, 3, 3, 3, 3], pain: {'press-banca'});
    expect(buildExercisePlan(scores).map((p) => p.exerciseId), ['dominadas']);
    expect(painfulExercises(scores).map((s) => s.exerciseId), ['press-banca']);
  });
}
