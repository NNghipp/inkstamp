import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/inbox/presentation/widgets/reaction_bar.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';
import 'package:intl/intl.dart';

class StampDetailScreen extends ConsumerStatefulWidget {
  const StampDetailScreen({required this.stampId, super.key});

  final String stampId;

  @override
  ConsumerState<StampDetailScreen> createState() => _StampDetailScreenState();
}

class _StampDetailScreenState extends ConsumerState<StampDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref
          .read(stampTimelineControllerProvider.notifier)
          .markSeen(widget.stampId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(stampTimelineControllerProvider);
    final Stamp? stamp = ref
        .read(stampTimelineControllerProvider.notifier)
        .findById(widget.stampId);

    if (stamp == null) {
      return const InkstampScaffold(
        title: 'Stamp',
        body: Center(child: Text('This stamp is no longer available.')),
      );
    }

    return InkstampScaffold(
      title: stamp.senderName,
      actions: <Widget>[
        PopupMenuButton<String>(
          onSelected: (String value) {
            if (value == 'report') {
              context.push(AppRoutes.stampReport(stamp.id));
            } else if (value == 'remove') {
              ref
                  .read(stampTimelineControllerProvider.notifier)
                  .removeFromArchive(stamp.id);
              context.pop();
            }
          },
          itemBuilder: (context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'report', child: Text('Report')),
            PopupMenuItem<String>(
              value: 'remove',
              child: Text('Remove from archive'),
            ),
          ],
        ),
      ],
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              UserAvatar(name: stamp.senderName),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    stamp.senderName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    DateFormat('HH:mm · dd/MM/yyyy').format(stamp.createdAt),
                    style: const TextStyle(
                      color: AppColors.charcoal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.82,
            child: StampArtwork(
              seed: stamp.seed,
              frameStyle: stamp.frameStyle,
              paperTone: stamp.paperTone,
              heroTag: 'stamp-${stamp.id}',
            ),
          ),
          const Spacer(),
          ReactionBar(
            selected: stamp.reaction,
            onSelected: (ReactionType reaction) {
              ref
                  .read(stampTimelineControllerProvider.notifier)
                  .react(stamp.id, reaction);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          InkstampButton(
            label: 'Reply with a stamp',
            icon: Icons.camera_alt_rounded,
            onPressed: () => context.push(AppRoutes.stampReply(stamp.id)),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
