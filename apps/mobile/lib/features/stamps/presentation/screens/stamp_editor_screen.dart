import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';

class StampEditorScreen extends ConsumerWidget {
  const StampEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StampDraft draft = ref.watch(stampComposerControllerProvider);
    final StampComposerController controller = ref.read(
      stampComposerControllerProvider.notifier,
    );

    return InkstampScaffold(
      title: 'Create stamp',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Center(
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.68,
                child: StampArtwork(
                  seed: draft.seed,
                  frameStyle: draft.frameStyle,
                  paperTone: draft.paperTone,
                ),
              ),
            ),
          ),
          Text('Stamp edge', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: StampFrameStyle.values
                .map((StampFrameStyle style) {
                  final bool selected = draft.frameStyle == style;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: _EditorChoice(
                        selected: selected,
                        label: switch (style) {
                          StampFrameStyle.classic => 'Classic',
                          StampFrameStyle.soft => 'Soft',
                          StampFrameStyle.mini => 'Mini',
                          StampFrameStyle.bold => 'Bold',
                        },
                        onTap: () => controller.setFrame(style),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Paper tone', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: PaperTone.values
                .map((PaperTone tone) {
                  final int index = PaperTone.values.indexOf(tone);
                  final bool selected = draft.paperTone == tone;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: '${tone.name} paper tone',
                    child: GestureDetector(
                      onTap: () => controller.setPaperTone(tone),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: selected ? 44 : 38,
                        height: selected ? 44 : 38,
                        decoration: BoxDecoration(
                          color: AppColors.paperTones[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.ink : AppColors.white,
                            width: selected ? 3 : 2,
                          ),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: AppSpacing.xl),
          InkstampButton(
            label: draft.replyToStampId == null
                ? 'Choose recipients'
                : 'Reply with a stamp',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              context.push(
                draft.replyToStampId == null
                    ? AppRoutes.cameraAudience
                    : AppRoutes.cameraSending,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _EditorChoice extends StatelessWidget {
  const _EditorChoice({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.white : AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
