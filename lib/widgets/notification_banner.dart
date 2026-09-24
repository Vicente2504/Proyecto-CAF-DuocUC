import 'package:flutter/material.dart';

import '../services/date_format.dart';
import '../theme.dart';

/// Aviso de próxima reevaluación (paso 4 de la propuesta: alerta cada
/// 4-6 semanas). No se muestra si faltan más de 7 días.
class NotificationBanner extends StatelessWidget {
  final DateTime? nextDue;

  const NotificationBanner({super.key, this.nextDue});

  @override
  Widget build(BuildContext context) {
    final due = nextDue;
    if (due == null) return const SizedBox.shrink();

    final days = due.difference(DateTime.now()).inDays;
    if (days > 7) return const SizedBox.shrink();

    final overdue = days < 0;
    final formatted = formatDateEs(due);
    final text = overdue
        ? 'Reevaluación atrasada desde el $formatted.'
        : 'Próxima reevaluación sugerida: $formatted (en $days día${days == 1 ? '' : 's'}).';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: overdue ? CafColors.coralTint : CafColors.accentTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(overdue ? '⏰' : '🔔'),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: overdue ? CafColors.coralStrong : CafColors.accentStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
