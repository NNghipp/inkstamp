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
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';

class StampSendingScreen extends ConsumerStatefulWidget {
  const StampSendingScreen({super.key});

  @override
  ConsumerState<StampSendingScreen> createState() {
    return _StampSendingScreenState();
  }
}

class _StampSendingScreenState extends ConsumerState<StampSendingScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      Future<void>.microtask(_publish);
    }
  }

  @override
  Widget build(BuildContext context) {
    final StampDraft draft = ref.watch(stampComposerControllerProvider);
    final StampTimelineState state = ref.watch(stampTimelineControllerProvider);

    return InkstampScaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 210,
            child: StampArtwork(
              seed: draft.seed,
              frameStyle: draft.frameStyle,
              paperTone: draft.paperTone,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            state.errorMessage == null
                ? 'Sending your moment…'
                : 'Your stamp was not sent',
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.errorMessage == null)
            const SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                color: AppColors.ink,
                backgroundColor: AppColors.paperDark,
              ),
            )
          else ...<Widget>[
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: AppSpacing.lg),
            InkstampButton(label: 'Try again', onPressed: _publish),
          ],
        ],
      ),
    );
  }

  Future<void> _publish() async {
    final StampDraft draft = ref.read(stampComposerControllerProvider);
    final Stamp? stamp = await ref
        .read(stampTimelineControllerProvider.notifier)
        .publish(draft);
    if (stamp != null && mounted) {
      context.go(AppRoutes.cameraSuccess);
    }
  }
}
