import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme.dart';

class ProgressPoint {
  final String label;
  final int total;
  const ProgressPoint({required this.label, required this.total});
}

/// Gráfico de línea del progreso histórico del puntaje total, dibujado
/// a mano con CustomPainter (sin librerías externas de gráficos).
class ProgressChart extends StatelessWidget {
  final List<ProgressPoint> points;

  const ProgressChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Aún no hay evaluaciones para graficar el progreso.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return SizedBox(
      height: 170,
      width: double.infinity,
      child: CustomPaint(painter: _ProgressChartPainter(points)),
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  final List<ProgressPoint> points;
  _ProgressChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 28.0;
    const padTop = 10.0;
    const padBottom = 24.0;
    final innerW = size.width - padX * 2;
    final innerH = size.height - padTop - padBottom;

    double xFor(int i) => points.length == 1
        ? padX + innerW / 2
        : padX + innerW * i / (points.length - 1);
    double yFor(num value) =>
        padTop + innerH - innerH * value / kMaxScore;

    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(.08)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: Colors.black.withOpacity(.45), fontSize: 10);

    for (final g in [0, kMaxScore ~/ 2, kMaxScore]) {
      final y = yFor(g);
      canvas.drawLine(Offset(padX, y), Offset(size.width - padX, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: '$g', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padX - 8 - tp.width, y - tp.height / 2));
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = Offset(xFor(i), yFor(points[i].total));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    final areaPath = Path.from(path)
      ..lineTo(xFor(points.length - 1), padTop + innerH)
      ..lineTo(xFor(0), padTop + innerH)
      ..close();

    canvas.drawPath(areaPath, Paint()..color = CafColors.accentTint);
    canvas.drawPath(
      path,
      Paint()
        ..color = CafColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < points.length; i++) {
      final p = Offset(xFor(i), yFor(points[i].total));
      canvas.drawCircle(p, 4, Paint()..color = CafColors.accentStrong);

      final tp = TextPainter(
        text: TextSpan(text: points[i].label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, size.height - padBottom + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
