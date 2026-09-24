import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../services/app_state.dart';
import '../services/date_format.dart';
import '../services/recommendation.dart';
import '../theme.dart';
import '../widgets/stat_card.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final students = appState.students;
    final evaluations = appState.evaluations;

    final latestEvals = [
      for (final s in students)
        if (appState.latestEvaluationFor(s.id) != null) appState.latestEvaluationFor(s.id)!,
    ];

    final totals = [for (final e in latestEvals) e.totalScore];
    final avg = totals.isEmpty
        ? null
        : (totals.reduce((a, b) => a + b) / totals.length * 10).round() / 10;

    final weakCounts = <String, int>{};
    for (final e in latestEvals) {
      for (final s in e.scores) {
        if (s.score <= 1) weakCounts[s.exerciseId] = (weakCounts[s.exerciseId] ?? 0) + 1;
      }
    }
    final weakList = weakCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = weakList.isEmpty ? 1 : weakList.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    final dueSoon = latestEvals.where((e) {
      final due = nextEvaluationDate(e.date);
      return due.difference(DateTime.now()).inDays <= 7;
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Panel general del CAF', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Calidad de movimiento promedio de la sede y ejercicios con más dificultad.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StatCard(label: 'Estudiantes', value: '${students.length}'),
              StatCard(label: 'Evaluaciones', value: '${evaluations.length}'),
              StatCard(label: 'Puntaje promedio', value: avg?.toString() ?? '—', hint: 'sobre $kMaxScore'),
              StatCard(label: 'Pendientes de reevaluación', value: '$dueSoon'),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ejercicios con más dificultad',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (weakList.isEmpty)
                    const Text('No hay ejercicios con puntaje ≤ 1 registrados todavía.',
                        style: TextStyle(color: Colors.black54))
                  else
                    for (final entry in weakList)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 190,
                              child: Text(
                                exerciseName(entry.key),
                                style: const TextStyle(fontSize: 13.5),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: entry.value / maxCount,
                                  minHeight: 8,
                                  backgroundColor: Colors.black.withOpacity(.06),
                                  color: CafColors.coral,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(width: 24, child: Text('${entry.value}', textAlign: TextAlign.right)),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Estudiantes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 10),
          if (students.isEmpty)
            const Text('Sin estudiantes todavía.', style: TextStyle(color: Colors.black54))
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < students.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(students[i].name)),
                          Expanded(
                            flex: 2,
                            child: Text(students[i].email, style: const TextStyle(color: Colors.black54)),
                          ),
                          Expanded(
                            child: Builder(builder: (context) {
                              final last = appState.latestEvaluationFor(students[i].id);
                              return Text(last == null ? '—' : formatDateEs(last.date));
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
