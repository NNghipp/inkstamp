import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FriendsState state = ref.watch(friendsControllerProvider);

    return InkstampScaffold(
      title: 'Blocked users',
      body: state.blocked.isEmpty
          ? const Center(child: Text('You have not blocked anyone.'))
          : ListView.separated(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              itemCount: state.blocked.length,
              separatorBuilder: (context, index) {
                return const Divider(height: 1);
              },
              itemBuilder: (context, index) {
                final InkstampFriend friend = state.blocked[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: UserAvatar(name: friend.displayName),
                  title: Text(friend.displayName),
                  subtitle: Text('@${friend.username}'),
                  trailing: TextButton(
                    onPressed: () {
                      ref
                          .read(friendsControllerProvider.notifier)
                          .unblockFriend(friend.id);
                    },
                    child: const Text('Unblock'),
                  ),
                );
              },
            ),
    );
  }
}
