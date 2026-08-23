import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';

class InkstampButton extends StatelessWidget {
  const InkstampButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      foregroundColor: isSecondary ? AppColors.ink : AppColors.white,
      backgroundColor: isSecondary ? AppColors.white : AppColors.ink,
      disabledBackgroundColor: AppColors.mist,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );

    if (isLoading) {
      return FilledButton(
        onPressed: null,
        style: style,
        child: const SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(label),
        ),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: style,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(label),
      ),
    );
  }
}
