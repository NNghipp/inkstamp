import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_colors.dart';

class PaperBackground extends StatelessWidget {
  const PaperBackground({
    required this.child,
    this.color = AppColors.paper,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: _PaperPainter(color),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);

    final math.Random random = math.Random(2411);
    final Paint grain = Paint()..strokeWidth = 0.8;
    final int specks = math.max(60, (size.width * size.height / 900).round());

    for (int index = 0; index < specks; index += 1) {
      grain.color = AppColors.ink.withValues(
        alpha: 0.012 + random.nextDouble() * 0.025,
      );
      final Offset point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      canvas.drawCircle(point, random.nextDouble() * 0.8 + 0.2, grain);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
