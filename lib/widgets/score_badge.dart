import 'package:flutter/material.dart';

import '../theme.dart';

/// Círculo con el puntaje 0-3 de un patrón, coloreado según qué tan
/// comprometido está el movimiento (mismo criterio que la versión web).
class ScoreBadge extends StatelessWidget {
  final int score;

  const ScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    late final Color fg;
    late final Color bg;
    late final Color border;

    if (score <= 1) {
      fg = CafColors.coralStrong;
      bg = CafColors.coralTint;
      border = CafColors.coral;
    } else if (score == 2) {
      fg = CafColors.warn;
      bg = CafColors.warnTint;
      border = CafColors.warn;
    } else {
      fg = CafColors.accentStrong;
      bg = CafColors.accentTint;
      border = CafColors.accent;
    }

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
