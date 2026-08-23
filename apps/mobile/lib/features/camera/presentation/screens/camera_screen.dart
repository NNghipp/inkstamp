import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  bool _frontCamera = false;
  bool _flashEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 102),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: const _CameraPreviewSimulation(),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _CameraControl(
                    icon: _flashEnabled
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    label: 'Flash',
                    onPressed: () {
                      setState(() => _flashEnabled = !_flashEnabled);
                    },
                  ),
                  const Text(
                    'INKSTAMP',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  _CameraControl(
                    icon: Icons.cameraswitch_rounded,
                    label: 'Switch camera',
                    onPressed: () {
                      setState(() => _frontCamera = !_frontCamera);
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 3),
                    ),
                    child: Semantics(
                      button: true,
                      label: 'Take photo',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          final String? replyTo = ref
                              .read(stampComposerControllerProvider)
                              .replyToStampId;
                          ref
                              .read(stampComposerControllerProvider.notifier)
                              .capture(replyToStampId: replyTo);
                          context.push(AppRoutes.cameraPreview);
                        },
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 42,
              right: 34,
              child: Text(
                _frontCamera ? 'FRONT' : 'BACK',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.72),
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPreviewSimulation extends StatelessWidget {
  const _CameraPreviewSimulation();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CameraScenePainter(),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Keep your moment inside the frame',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF8EB5D0), Color(0xFFD6C8B7)],
          stops: <double>[0, 0.72],
        ).createShader(bounds),
    );

    final Paint dark = Paint()..color = const Color(0xFF3A3D3D);
    final double horizon = size.height * 0.71;
    canvas.drawRect(Rect.fromLTRB(0, horizon, size.width, size.height), dark);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.58, horizon)
        ..lineTo(size.width, size.height * 0.46)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width * 0.71, size.height)
        ..close(),
      Paint()..color = const Color(0xFF555657),
    );

    for (int index = 0; index < 4; index += 1) {
      final double x = size.width * (0.14 + index * 0.14);
      final double poleTop = horizon - size.height * (0.24 - index * 0.025);
      canvas.drawRect(Rect.fromLTWH(x, poleTop, 5, horizon - poleTop), dark);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 2, poleTop, 44, 8),
          const Radius.circular(6),
        ),
        dark,
      );
    }

    final double centerX = size.width * 0.5;
    canvas.drawCircle(
      Offset(centerX, horizon - 88),
      12,
      Paint()..color = const Color(0xFF2E2927),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, horizon - 47),
          width: 34,
          height: 78,
        ),
        const Radius.circular(14),
      ),
      Paint()..color = const Color(0xFF6D716E),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraControl extends StatelessWidget {
  const _CameraControl({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.ink.withValues(alpha: 0.42),
          foregroundColor: AppColors.white,
        ),
        icon: Icon(icon),
      ),
    );
  }
}
