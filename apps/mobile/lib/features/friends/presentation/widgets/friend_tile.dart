import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';

class FriendTile extends StatelessWidget {
  const FriendTile({
    required this.friend,
    this.onTap,
    this.trailing,
    super.key,
  });

  final InkstampFriend friend;
  final VoidCallback? onTap;
  final Widget? trailing;

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
              UserAvatar(
                name: friend.displayName,
                backgroundColor: _avatarColor(friend.id),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      friend.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '@${friend.username}',
                      style: const TextStyle(
                        color: AppColors.charcoal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (friend.isCloseFriend)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.xs),
                  child: Icon(
                    Icons.star_rounded,
                    color: AppColors.butter,
                    size: 20,
                  ),
                ),
              trailing ?? const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Color _avatarColor(String id) {
    const List<Color> colors = <Color>[
      AppColors.sky,
      AppColors.blush,
      AppColors.mint,
      AppColors.lilac,
      AppColors.butter,
    ];
    return colors[id.hashCode.abs() % colors.length];
  }
}
