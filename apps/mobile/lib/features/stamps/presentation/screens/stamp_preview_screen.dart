import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';

class StampPreviewScreen extends ConsumerWidget {
  const StampPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StampDraft draft = ref.watch(stampComposerControllerProvider);

    return InkstampScaffold(
      title: 'Your moment',
      body: Column(
        children: <Widget>[
          const Spacer(),
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.78,
            child: StampArtwork(
              seed: draft.seed,
              frameStyle: draft.frameStyle,
              paperTone: draft.paperTone,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'A moment worth keeping.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Keep this photo or retake it before creating your stamp.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.charcoal),
          ),
          const Spacer(),
          InkstampButton(
            label: 'Create stamp',
            icon: Icons.auto_awesome_rounded,
            onPressed: () => context.push(AppRoutes.cameraEditor),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkstampButton(
            label: 'Retake',
            icon: Icons.replay_rounded,
            isSecondary: true,
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
