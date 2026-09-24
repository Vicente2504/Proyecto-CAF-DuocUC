import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/evaluation.dart';
import '../models/exercise.dart';
import '../services/app_state.dart';
import '../services/date_format.dart';
import '../services/recommendation.dart';
import '../theme.dart';
import '../widgets/notification_banner.dart';
import '../widgets/progress_chart.dart';
import '../widgets/score_badge.dart';

class StudentScreen extends StatelessWidget {
  final String? selectedStudentId;
  /// Si es null (rol estudiante) no se muestra el selector de estudiante.
  final ValueChanged<String>? onSelectStudent;

  const StudentScreen({super.key, required this.selectedStudentId, this.onSelectStudent});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final students = appState.students;

    if (students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Aún no hay estudiantes registrados. Agrega uno desde la vista Instructor.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    final student = students.firstWhere(
      (s) => s.id == selectedStudentId,
      orElse: () => students.first,
    );

    final history = appState.historyFor(student.id);
    final Evaluation? last = history.isEmpty ? null : history.last;
    final due = last == null ? null : nextEvaluationDate(last.date);

    final points = [
      for (final e in history) ProgressPoint(label: formatDateShortEs(e.date), total: e.totalScore),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MI FICHA DE MOVIMIENTO FUNCIONAL',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w600,
                          color: CafColors.accentStrong,
                        )),
                    const SizedBox(height: 4),
                    Text(student.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (onSelectStudent != null)
                DropdownButton<String>(
                  value: student.id,
                  items: [
                    for (final s in students) DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (id) {
                    if (id != null) onSelectStudent!(id);
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          NotificationBanner(nextDue: due),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Progreso histórico', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  ProgressChart(points: points),
                ],
              ),
            ),
          ),
          if (last != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detalle por ejercicio — última evaluación',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final ex in kExercises)
                          for (final score in last.scores.where((s) => s.exerciseId == ex.id))
                            _ExerciseDetailTile(exercise: ex, score: score),
                      ],
                    ),
                    if (last.notes != null && last.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('"${last.notes}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text('Mi plan de ejercicios', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 10),
          if (last != null && painfulExercises(last.scores).isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: CafColors.coralTint, borderRadius: BorderRadius.circular(8)),
              child: Text(
                'Con dolor: ${painfulExercises(last.scores).map((s) => exerciseName(s.exerciseId)).join(', ')}. '
                'No los realices hasta que un profesional te evalúe.',
                style: const TextStyle(color: CafColors.coralStrong),
              ),
            ),
          if (last == null || last.plan.isEmpty)
            const Text('Esta evaluación no generó ejercicios para reforzar.', style: TextStyle(color: Colors.black54))
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < last.plan.length; i++)
                    _PlanTile(item: last.plan[i], showDivider: i > 0),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseDetailTile extends StatelessWidget {
  final Exercise exercise;
  final ExerciseScore score;

  const _ExerciseDetailTile({required this.exercise, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withOpacity(.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ScoreBadge(score: score.score),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(exercise.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                if (score.pain)
                  const Text('Dolor reportado', style: TextStyle(fontSize: 11.5, color: CafColors.coralStrong)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final PlanItem item;
  final bool showDivider;

  const _PlanTile({required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final exercise = kExerciseById[item.exerciseId];
    if (exercise == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (showDivider) const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CafColors.accentTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Puntaje ${item.score}',
                  style: const TextStyle(fontSize: 11, color: CafColors.accentStrong, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(exercise.prescription, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
