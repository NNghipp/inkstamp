import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';

class CloseFriendsScreen extends ConsumerWidget {
  const CloseFriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FriendsState state = ref.watch(friendsControllerProvider);

    return InkstampScaffold(
      title: 'Close Friends',
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.butter.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.lock_outline_rounded),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Only you can see who is on your Close Friends list.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: state.friends.length,
              separatorBuilder: (context, index) {
                return const Divider(height: 1);
              },
              itemBuilder: (context, index) {
                final InkstampFriend friend = state.friends[index];
                return SwitchListTile(
                  value: friend.isCloseFriend,
                  onChanged: (_) {
                    ref
                        .read(friendsControllerProvider.notifier)
                        .toggleCloseFriend(friend.id);
                  },
                  secondary: UserAvatar(name: friend.displayName),
                  title: Text(friend.displayName),
                  subtitle: Text('@${friend.username}'),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.ink,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
