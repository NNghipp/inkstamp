import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/app/theme/gallery_tokens.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/inbox/presentation/controllers/inbox_controller.dart';
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
  String? _readScheduledFor;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(stampDetailProvider(widget.stampId));
    if (detail.isLoading && (detail.isReloading || !detail.hasValue)) {
      return const InkstampScaffold(
        title: 'Stamp',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (detail.hasError) {
      return InkstampScaffold(
        title: 'Stamp',
        body: Center(
          child: TextButton(
            onPressed: () =>
                ref.invalidate(stampDetailProvider(widget.stampId)),
            child: const Text('Không thể tải stamp. Thử lại'),
          ),
        ),
      );
    }
    final Stamp? stamp = detail.value;

    if (stamp == null) {
      return const InkstampScaffold(
        title: 'Stamp',
        body: Center(child: Text('Stamp không còn khả dụng.')),
      );
    }
    final readKey =
        '${ref.watch(sessionControllerProvider).user?.id}/${stamp.id}';
    if (_readScheduledFor != readKey) {
      _readScheduledFor = readKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(inboxControllerProvider.notifier).markRead(stamp);
      });
    }

    return InkstampScaffold(
      title: 'Ký ức',
      actions: <Widget>[
        PopupMenuButton<String>(
          onSelected: (String value) {
            if (value == 'report' && !stamp.isSentByMe) {
              context.push(AppRoutes.stampReport(stamp.id));
            }
          },
          itemBuilder: (context) => <PopupMenuEntry<String>>[
            if (!stamp.isSentByMe)
              const PopupMenuItem<String>(
                value: 'report',
                child: Text('Report'),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      stamp.senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      DateFormat(
                        'HH:mm · dd/MM/yyyy',
                      ).format(stamp.captureTime.toLocal()),
                      style: const TextStyle(
                        color: GalleryTokens.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: StampArtwork(
                    seed: stamp.seed,
                    frameStyle: stamp.frameStyle,
                    paperTone: stamp.paperTone,
                    publicId: stamp.cloudinaryPublicId,
                    capturedAt: stamp.captureTime,
                  ),
                ),
              ),
            ),
          ),
          if (stamp.shortTitle.isNotEmpty)
            Text(
              stamp.shortTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (stamp.locationLabel != null)
            Text(
              stamp.locationLabel!,
              style: const TextStyle(
                color: GalleryTokens.secondaryText,
                fontSize: 12,
              ),
            ),
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
