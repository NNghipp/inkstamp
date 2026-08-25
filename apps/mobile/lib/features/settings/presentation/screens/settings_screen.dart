import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/settings/presentation/widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? user = ref.watch(sessionControllerProvider).user;

    return InkstampScaffold(
      title: 'Settings',
      body: ListView(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: <Widget>[
                UserAvatar(name: user?.displayName ?? 'Minh Anh', size: 64),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user?.displayName ?? 'Minh Anh',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text('@${user?.username ?? 'minhanh.stamps'}'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit profile',
                  onPressed: () => context.push(AppRoutes.editProfile),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            iconColor: AppColors.blush,
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          SettingsTile(
            icon: Icons.shield_outlined,
            title: 'Privacy and safety',
            iconColor: AppColors.mint,
            onTap: () => context.push(AppRoutes.privacySettings),
          ),
          SettingsTile(
            icon: Icons.block_rounded,
            title: 'Blocked users',
            iconColor: AppColors.lilac,
            onTap: () => context.push(AppRoutes.blockedUsers),
          ),
          SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help',
            iconColor: AppColors.butter,
            onTap: () => context.push(AppRoutes.help),
          ),
          const Divider(height: AppSpacing.xl),
          SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            iconColor: AppColors.mist,
            onTap: () => ref.read(sessionControllerProvider.notifier).signOut(),
          ),
          SettingsTile(
            icon: Icons.delete_outline_rounded,
            title: 'Delete account',
            iconColor: AppColors.blush,
            onTap: () => context.push(AppRoutes.deleteAccount),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Center(
            child: Text(
              'Inkstamp 0.1.0 · Closed beta',
              style: TextStyle(color: AppColors.charcoal, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
