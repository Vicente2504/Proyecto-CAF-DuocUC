import 'package:flutter/material.dart';

import '../theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;

  const StatCard({super.key, required this.label, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 11, letterSpacing: .5, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: CafColors.accentStrong,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 2),
              Text(hint!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }
}
