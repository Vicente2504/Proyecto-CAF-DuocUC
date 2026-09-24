import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../services/app_state.dart';
import '../services/date_format.dart';
import '../services/recommendation.dart';
import 'evaluation_form_dialog.dart';

class InstructorScreen extends StatelessWidget {
  final void Function(String studentId) onViewStudent;

  const InstructorScreen({super.key, required this.onViewStudent});

  Future<void> _showAddStudentDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo estudiante'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre y apellido'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              context.read<AppState>().addStudent(nameCtrl.text.trim(), emailCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final students = appState.students;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mis estudiantes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text(
                      'Ejecuta evaluaciones de movimiento y revisa el estado de cada estudiante.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _showAddStudentDialog(context),
                child: const Text('+ Nuevo estudiante'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: students.isEmpty
                ? const Center(
                    child: Text(
                      'Aún no hay estudiantes. Agrega el primero con el botón de arriba.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.separated(
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final s = students[i];
                      final last = appState.latestEvaluationFor(s.id);
                      final due = last == null ? null : nextEvaluationDate(last.date);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: 220,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(s.email, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  last == null ? 'Sin evaluaciones' : formatDateEs(last.date),
                                  style: TextStyle(color: last == null ? Colors.black45 : null),
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: Text(last == null ? '—' : '${last.totalScore} / $kMaxScore'),
                              ),
                              SizedBox(
                                width: 140,
                                child: Text(due == null ? '—' : formatDateEs(due)),
                              ),
                              OutlinedButton(
                                onPressed: () => onViewStudent(s.id),
                                child: const Text('Ver ficha'),
                              ),
                              FilledButton(
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => EvaluationFormDialog(studentId: s.id, studentName: s.name),
                                ),
                                child: const Text('Nueva evaluación'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
