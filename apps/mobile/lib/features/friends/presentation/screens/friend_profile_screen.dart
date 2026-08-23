import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';

class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FriendsState state = ref.watch(friendsControllerProvider);
    final InkstampFriend? friend = state.friends
        .where((InkstampFriend friend) => friend.id == userId)
        .firstOrNull;

    if (friend == null) {
      return const InkstampScaffold(
        title: 'Friends',
        body: Center(child: Text('This user could not be found.')),
      );
    }

    return InkstampScaffold(
      title: friend.displayName,
      body: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.xl),
          UserAvatar(
            name: friend.displayName,
            size: 108,
            backgroundColor: AppColors.sky,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            friend.displayName,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          Text(
            '@${friend.username}',
            style: const TextStyle(color: AppColors.charcoal),
          ),
          const SizedBox(height: AppSpacing.xl),
          SwitchListTile(
            value: friend.isCloseFriend,
            onChanged: (_) {
              ref
                  .read(friendsControllerProvider.notifier)
                  .toggleCloseFriend(friend.id);
            },
            title: const Text('Close Friends'),
            secondary: const Icon(Icons.star_rounded, color: AppColors.butter),
            contentPadding: EdgeInsets.zero,
          ),
          const Spacer(),
          InkstampButton(
            label: 'Remove friend',
            isSecondary: true,
            onPressed: () {
              ref
                  .read(friendsControllerProvider.notifier)
                  .removeFriend(friend.id);
              context.pop();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => _confirmBlock(context, ref, friend),
            icon: const Icon(Icons.block_rounded),
            label: const Text('Block user'),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _confirmBlock(
    BuildContext context,
    WidgetRef ref,
    InkstampFriend friend,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Block ${friend.displayName}?'),
          content: const Text(
            'You will no longer be able to send or view each other’s stamps.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      ref.read(friendsControllerProvider.notifier).blockFriend(friend.id);
      context.pop();
    }
  }
}
