import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FriendsState state = ref.watch(friendsControllerProvider);

    return InkstampScaffold(
      title: 'Friend requests',
      body: state.requests.isEmpty
          ? const Center(child: Text('No pending friend requests.'))
          : ListView.separated(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              itemCount: state.requests.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: AppSpacing.sm);
              },
              itemBuilder: (context, index) {
                final InkstampFriend friend = state.requests[index];
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: <Widget>[
                      UserAvatar(name: friend.displayName),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              friend.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text('@${friend.username}'),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Decline',
                        onPressed: () {
                          ref
                              .read(friendsControllerProvider.notifier)
                              .declineRequest(friend.id);
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                      IconButton.filled(
                        tooltip: 'Accept',
                        onPressed: () {
                          ref
                              .read(friendsControllerProvider.notifier)
                              .acceptRequest(friend.id);
                        },
                        icon: const Icon(Icons.check_rounded),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
