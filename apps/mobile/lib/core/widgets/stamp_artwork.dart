import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';

class StampArtwork extends StatelessWidget {
  const StampArtwork({
    required this.seed,
    this.frameStyle = StampFrameStyle.classic,
    this.paperTone = PaperTone.cream,
    this.heroTag,
    this.showShadow = true,
    super.key,
  });

  final int seed;
  final StampFrameStyle frameStyle;
  final PaperTone paperTone;
  final Object? heroTag;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final Widget artwork = CustomPaint(
      painter: StampArtworkPainter(
        seed: seed,
        frameStyle: frameStyle,
        paperTone: paperTone,
      ),
      child: const AspectRatio(aspectRatio: 1),
    );

    final Widget framed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: showShadow
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: artwork,
    );

    if (heroTag == null) {
      return framed;
    }

    return Hero(tag: heroTag!, child: framed);
  }
}

class StampArtworkPainter extends CustomPainter {
  const StampArtworkPainter({
    required this.seed,
    required this.frameStyle,
    required this.paperTone,
  });

  final int seed;
  final StampFrameStyle frameStyle;
  final PaperTone paperTone;

  Color get _paperColor {
    return switch (paperTone) {
      PaperTone.cream => AppColors.paper,
      PaperTone.sky => AppColors.sky,
      PaperTone.blush => AppColors.blush,
      PaperTone.mint => AppColors.mint,
      PaperTone.lilac => AppColors.lilac,
      PaperTone.butter => AppColors.butter,
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path stampPath = _buildStampPath(size);
    canvas.clipPath(stampPath);
    canvas.drawRect(Offset.zero & size, Paint()..color = _paperColor);

    final double inset = size.shortestSide * 0.085;
    final Rect photoRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    final math.Random random = math.Random(seed);
    final List<List<Color>> palettes = <List<Color>>[
      <Color>[const Color(0xFF84A8BE), const Color(0xFFD8C1A4)],
      <Color>[const Color(0xFFDF9D84), const Color(0xFF7C9B82)],
      <Color>[const Color(0xFFABB9D4), const Color(0xFFDFCCB4)],
      <Color>[const Color(0xFF93AFA5), const Color(0xFFF0C5B5)],
      <Color>[const Color(0xFF6E8392), const Color(0xFFD7BDA7)],
    ];
    final List<Color> palette = palettes[seed.abs() % palettes.length];

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(photoRect, const Radius.circular(3)),
    );
    canvas.drawRect(
      photoRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette,
        ).createShader(photoRect),
    );

    final Paint silhouette = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.68);
    final double horizon = photoRect.top + photoRect.height * 0.66;
    canvas.drawRect(
      Rect.fromLTRB(photoRect.left, horizon, photoRect.right, photoRect.bottom),
      silhouette,
    );

    for (int index = 0; index < 3; index += 1) {
      final double x = photoRect.left + photoRect.width * (0.18 + index * 0.27);
      final double height =
          photoRect.height * (0.19 + random.nextDouble() * 0.14);
      canvas.drawRect(
        Rect.fromLTWH(x, horizon - height, 5, height),
        silhouette,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + 2.5, horizon - height),
          width: 27,
          height: 8,
        ),
        silhouette,
      );
    }

    final double personX =
        photoRect.left + photoRect.width * (0.42 + random.nextDouble() * 0.16);
    canvas.drawCircle(
      Offset(personX, horizon - photoRect.height * 0.25),
      photoRect.width * 0.027,
      silhouette,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(personX, horizon - photoRect.height * 0.15),
          width: photoRect.width * 0.07,
          height: photoRect.height * 0.18,
        ),
        const Radius.circular(8),
      ),
      silhouette,
    );
    canvas.restore();
  }

  Path _buildStampPath(Size size) {
    final double notch = switch (frameStyle) {
      StampFrameStyle.classic => size.shortestSide * 0.035,
      StampFrameStyle.soft => size.shortestSide * 0.045,
      StampFrameStyle.mini => size.shortestSide * 0.024,
      StampFrameStyle.bold => size.shortestSide * 0.055,
    };
    final int count = switch (frameStyle) {
      StampFrameStyle.classic => 11,
      StampFrameStyle.soft => 9,
      StampFrameStyle.mini => 15,
      StampFrameStyle.bold => 7,
    };
    final Path path = Path()..moveTo(notch, 0);
    final double horizontalStep = (size.width - notch * 2) / count;
    for (int index = 0; index < count; index += 1) {
      final double start = notch + index * horizontalStep;
      path
        ..lineTo(start + horizontalStep * 0.25, 0)
        ..quadraticBezierTo(
          start + horizontalStep * 0.5,
          notch,
          start + horizontalStep * 0.75,
          0,
        )
        ..lineTo(start + horizontalStep, 0);
    }
    path.lineTo(size.width, notch);
    final double verticalStep = (size.height - notch * 2) / count;
    for (int index = 0; index < count; index += 1) {
      final double start = notch + index * verticalStep;
      path
        ..lineTo(size.width, start + verticalStep * 0.25)
        ..quadraticBezierTo(
          size.width - notch,
          start + verticalStep * 0.5,
          size.width,
          start + verticalStep * 0.75,
        )
        ..lineTo(size.width, start + verticalStep);
    }
    path.lineTo(size.width - notch, size.height);
    for (int index = count - 1; index >= 0; index -= 1) {
      final double start = notch + index * horizontalStep;
      path
        ..lineTo(start + horizontalStep * 0.75, size.height)
        ..quadraticBezierTo(
          start + horizontalStep * 0.5,
          size.height - notch,
          start + horizontalStep * 0.25,
          size.height,
        )
        ..lineTo(start, size.height);
    }
    path.lineTo(0, size.height - notch);
    for (int index = count - 1; index >= 0; index -= 1) {
      final double start = notch + index * verticalStep;
      path
        ..lineTo(0, start + verticalStep * 0.75)
        ..quadraticBezierTo(
          notch,
          start + verticalStep * 0.5,
          0,
          start + verticalStep * 0.25,
        )
        ..lineTo(0, start);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant StampArtworkPainter oldDelegate) {
    return seed != oldDelegate.seed ||
        frameStyle != oldDelegate.frameStyle ||
        paperTone != oldDelegate.paperTone;
  }
}
