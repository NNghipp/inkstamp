import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';
import 'package:inkstamp/features/friends/presentation/widgets/friend_tile.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FriendsState state = ref.watch(friendsControllerProvider);

    return InkstampScaffold(
      title: 'Friends',
      actions: <Widget>[
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xl,
              ),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.person_search_rounded,
                        color: AppColors.sky,
                        label: 'Find friends',
                        onTap: () => context.push(AppRoutes.friendSearch),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.qr_code_2_rounded,
                        color: AppColors.mint,
                        label: 'Invite',
                        onTap: () => context.push(AppRoutes.inviteFriend),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuickAction(
                  icon: Icons.star_rounded,
                  color: AppColors.butter,
                  label: 'Close Friends · ${state.closeFriends.length}',
                  onTap: () => context.push(AppRoutes.closeFriends),
                ),
                if (state.requests.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  Material(
                    color: AppColors.blush.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                      onTap: () => context.push(AppRoutes.friendRequests),
                      leading: const Icon(Icons.person_add_alt_1_rounded),
                      title: Text(
                        '${state.requests.length} pending requests',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '${state.friends.length} friends',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...state.friends.map((InkstampFriend friend) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: FriendTile(
                      friend: friend,
                      onTap: () {
                        context.push(AppRoutes.friendProfile(friend.id));
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: color,
                child: Icon(icon, color: AppColors.ink),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
