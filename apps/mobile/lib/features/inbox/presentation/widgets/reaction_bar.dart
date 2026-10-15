import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_motion.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/app/theme/gallery_tokens.dart';
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
        color: GalleryTokens.glass,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                    duration: AppMotion.duration(context, AppMotion.fast),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 48,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GalleryTokens.selectedGlass
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      reaction.emoji,
                      style: const TextStyle(fontSize: 22),
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
