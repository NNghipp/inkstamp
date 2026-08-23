import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';

class StampReplyScreen extends ConsumerWidget {
  const StampReplyScreen({required this.stampId, super.key});

  final String stampId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(stampTimelineControllerProvider);
    final Stamp? stamp = ref
        .read(stampTimelineControllerProvider.notifier)
        .findById(stampId);

    return InkstampScaffold(
      title: 'Stamp reply',
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: AppColors.blush,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 48,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Send a moment back',
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            stamp == null
                ? 'The original stamp is no longer available.'
                : 'Your next stamp will only be sent to ${stamp.senderName}.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          InkstampButton(
            label: 'Open camera',
            onPressed: stamp == null
                ? null
                : () {
                    ref
                        .read(stampComposerControllerProvider.notifier)
                        .capture(replyToStampId: stamp.id);
                    context.go(AppRoutes.camera);
                  },
          ),
        ],
      ),
    );
  }
}
