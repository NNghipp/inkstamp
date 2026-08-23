import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';

class WidgetIntroScreen extends ConsumerWidget {
  const WidgetIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkstampScaffold(
      title: 'Stamps on your Home Screen',
      body: Column(
        children: <Widget>[
          const Spacer(),
          Container(
            width: 250,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(38),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.local_post_office, color: AppColors.butter),
                    SizedBox(width: 8),
                    Text(
                      'Inkstamp',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                StampArtwork(
                  seed: 27,
                  frameStyle: StampFrameStyle.soft,
                  paperTone: PaperTone.blush,
                  showShadow: false,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Linh sent a new stamp',
                  style: TextStyle(color: AppColors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Keep friends a little closer.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'The widget shows your latest stamp on the Home Screen. Only enable it if you are comfortable with photos appearing there.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          InkstampButton(
            label: 'Finish',
            onPressed: () {
              ref.read(sessionControllerProvider.notifier).completeOnboarding();
              context.go(AppRoutes.camera);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
