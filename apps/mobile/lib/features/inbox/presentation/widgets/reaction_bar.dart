import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';

class ReactionBar extends StatelessWidget {
  const ReactionBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ReactionType? selected;
  final ValueChanged<ReactionType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ReactionType.values
            .map((ReactionType reaction) {
              final bool isSelected = reaction == selected;
              return Semantics(
                button: true,
                selected: isSelected,
                label: 'Reaction ${reaction.name}',
                child: InkWell(
                  onTap: () => onSelected(reaction),
                  customBorder: const CircleBorder(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.butter.withValues(alpha: 0.55)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      reaction.emoji,
                      style: TextStyle(fontSize: isSelected ? 27 : 23),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
