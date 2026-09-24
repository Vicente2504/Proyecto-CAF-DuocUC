import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/evaluation.dart';
import '../models/exercise.dart';
import '../services/app_state.dart';
import '../theme.dart';

/// Formulario de evaluación: los 10 ejercicios del catálogo, puntaje 0-3
/// cada uno, marca de dolor y observaciones. Al guardar, AppState.addEvaluation
/// genera el plan de correctivos automáticamente (paso 4 de la
/// propuesta).
class EvaluationFormDialog extends StatefulWidget {
  final String studentId;
  final String studentName;

  const EvaluationFormDialog({super.key, required this.studentId, required this.studentName});

  @override
  State<EvaluationFormDialog> createState() => _EvaluationFormDialogState();
}

class _EvaluationFormDialogState extends State<EvaluationFormDialog> {
  final Map<String, int> _scores = {for (final e in kExercises) e.id: 2};
  final Map<String, bool> _pain = {for (final e in kExercises) e.id: false};
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _total => _scores.values.fold(0, (a, b) => a + b);

  void _submit() {
    final scores = kExercises
        .map((e) => ExerciseScore(
              exerciseId: e.id,
              score: _scores[e.id] ?? 2,
              pain: _pain[e.id] ?? false,
            ))
        .toList();

    context.read<AppState>().addEvaluation(
          studentId: widget.studentId,
          scores: scores,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nueva evaluación',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(widget.studentName, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  Text(
                    '$_total / $kMaxScore',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: CafColors.accentStrong,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < kExercises.length; i++)
                      _ExerciseField(
                        number: i + 1,
                        exercise: kExercises[i],
                        score: _scores[kExercises[i].id] ?? 2,
                        pain: _pain[kExercises[i].id] ?? false,
                        onScoreChanged: (v) => setState(() => _scores[kExercises[i].id] = v),
                        onPainChanged: (v) => setState(() {
                          _pain[kExercises[i].id] = v;
                          if (v) _scores[kExercises[i].id] = 0;
                        }),
                      ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Observaciones'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Guardar y generar plan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseField extends StatelessWidget {
  final int number;
  final Exercise exercise;
  final int score;
  final bool pain;
  final ValueChanged<int> onScoreChanged;
  final ValueChanged<bool> onPainChanged;

  const _ExerciseField({
    required this.number,
    required this.exercise,
    required this.score,
    required this.pain,
    required this.onScoreChanged,
    required this.onPainChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withOpacity(.12)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. ${exercise.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(exercise.criteria, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final v in [0, 1, 2, 3])
                ChoiceChip(
                  label: Text('$v'),
                  tooltip: kScoreLabels[v],
                  selected: score == v,
                  onSelected: (_) => onScoreChanged(v),
                  selectedColor: CafColors.accentTint,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: score == v ? CafColors.accentStrong : null,
                  ),
                ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('Dolor'),
                selected: pain,
                onSelected: onPainChanged,
                selectedColor: CafColors.coralTint,
                checkmarkColor: CafColors.coralStrong,
                labelStyle: TextStyle(color: pain ? CafColors.coralStrong : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
