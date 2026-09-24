/// Puntaje registrado para un ejercicio dentro de una evaluación.
class ExerciseScore {
  final String exerciseId;
  final int score; // 0 a 3
  final bool pain;

  const ExerciseScore({
    required this.exerciseId,
    required this.score,
    this.pain = false,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'score': score,
        'pain': pain,
      };

  factory ExerciseScore.fromJson(Map<String, dynamic> json) => ExerciseScore(
        exerciseId: json['exerciseId'] as String,
        score: json['score'] as int,
        pain: (json['pain'] as bool?) ?? false,
      );
}

/// Un ejercicio incluido en el plan del estudiante, con el puntaje que
/// obtuvo en la evaluación que lo originó.
class PlanItem {
  final String exerciseId;
  final int score;

  const PlanItem({required this.exerciseId, required this.score});

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'score': score,
      };

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
        exerciseId: json['exerciseId'] as String,
        score: json['score'] as int,
      );
}

class Evaluation {
  final String id;
  final String studentId;
  final DateTime date;
  final String? notes;
  final List<ExerciseScore> scores;
  final List<PlanItem> plan;

  const Evaluation({
    required this.id,
    required this.studentId,
    required this.date,
    required this.scores,
    required this.plan,
    this.notes,
  });

  int get totalScore => scores.fold(0, (sum, s) => sum + s.score);

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'date': date.toIso8601String(),
        'notes': notes,
        'scores': scores.map((s) => s.toJson()).toList(),
        'plan': plan.map((p) => p.toJson()).toList(),
      };

  factory Evaluation.fromJson(Map<String, dynamic> json) => Evaluation(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        date: DateTime.parse(json['date'] as String),
        notes: json['notes'] as String?,
        scores: (json['scores'] as List)
            .map((s) => ExerciseScore.fromJson(s as Map<String, dynamic>))
            .toList(),
        plan: (json['plan'] as List)
            .map((p) => PlanItem.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
