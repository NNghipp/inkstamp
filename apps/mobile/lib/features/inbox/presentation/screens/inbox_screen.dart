import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';
import 'package:intl/intl.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StampTimelineState state = ref.watch(stampTimelineControllerProvider);

    return InkstampScaffold(
      title: 'Inbox',
      actions: <Widget>[
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.received.isEmpty
          ? const _EmptyInbox()
          : RefreshIndicator(
              onRefresh: ref
                  .read(stampTimelineControllerProvider.notifier)
                  .load,
              child: ListView.separated(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xl,
                ),
                itemCount: state.received.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: AppSpacing.md);
                },
                itemBuilder: (context, index) {
                  return _InboxStampCard(stamp: state.received[index]);
                },
              ),
            ),
    );
  }
}

class _InboxStampCard extends StatelessWidget {
  const _InboxStampCard({required this.stamp});

  final Stamp stamp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: () => context.push(AppRoutes.stamp(stamp.id)),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm · dd/MM').format(stamp.createdAt),
                          style: const TextStyle(
                            color: AppColors.charcoal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!stamp.isSeen)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.blush,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (stamp.reaction != null)
                    Text(
                      stamp.reaction!.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              StampArtwork(
                seed: stamp.seed,
                frameStyle: stamp.frameStyle,
                paperTone: stamp.paperTone,
                heroTag: 'stamp-${stamp.id}',
                showShadow: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.mark_email_unread_outlined,
            size: 64,
            color: AppColors.sky,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your Inbox is waiting for a moment',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Add a friend or send your first stamp to get started.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
