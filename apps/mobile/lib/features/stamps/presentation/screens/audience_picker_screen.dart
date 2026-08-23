import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';

class AudiencePickerScreen extends ConsumerWidget {
  const AudiencePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StampDraft draft = ref.watch(stampComposerControllerProvider);
    final FriendsState friendsState = ref.watch(friendsControllerProvider);
    final StampComposerController controller = ref.read(
      stampComposerControllerProvider.notifier,
    );

    final int recipientCount = switch (draft.audience) {
      AudienceMode.allFriends => friendsState.friends.length,
      AudienceMode.closeFriends => friendsState.closeFriends.length,
      AudienceMode.selected => draft.selectedRecipientIds.length,
    };

    return InkstampScaffold(
      title: 'Send to',
      body: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.sm),
          _AudienceOption(
            icon: Icons.people_rounded,
            color: AppColors.sky,
            title: 'All Friends',
            subtitle: '${friendsState.friends.length} friends',
            selected: draft.audience == AudienceMode.allFriends,
            onTap: () => controller.setAudience(AudienceMode.allFriends),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AudienceOption(
            icon: Icons.star_rounded,
            color: AppColors.butter,
            title: 'Close Friends',
            subtitle: '${friendsState.closeFriends.length} people',
            selected: draft.audience == AudienceMode.closeFriends,
            onTap: () => controller.setAudience(AudienceMode.closeFriends),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AudienceOption(
            icon: Icons.tune_rounded,
            color: AppColors.lilac,
            title: 'Select People',
            subtitle: '${draft.selectedRecipientIds.length} selected',
            selected: draft.audience == AudienceMode.selected,
            onTap: () => controller.setAudience(AudienceMode.selected),
          ),
          if (draft.audience == AudienceMode.selected) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.separated(
                itemCount: friendsState.friends.length,
                separatorBuilder: (context, index) {
                  return const Divider(height: 1);
                },
                itemBuilder: (context, index) {
                  final InkstampFriend friend = friendsState.friends[index];
                  final bool selected = draft.selectedRecipientIds.contains(
                    friend.id,
                  );
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (_) => controller.toggleRecipient(friend.id),
                    secondary: UserAvatar(name: friend.displayName),
                    title: Text(friend.displayName),
                    subtitle: Text('@${friend.username}'),
                    activeColor: AppColors.ink,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ),
          ] else
            const Spacer(),
          const SizedBox(height: AppSpacing.md),
          InkstampButton(
            label: 'Send to $recipientCount people',
            icon: Icons.send_rounded,
            onPressed: recipientCount == 0
                ? null
                : () => context.push(AppRoutes.cameraSending),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _AudienceOption extends StatelessWidget {
  const _AudienceOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.white
          : AppColors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 25,
                backgroundColor: color,
                child: Icon(icon, color: AppColors.ink),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.charcoal),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.ink : AppColors.mist,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
