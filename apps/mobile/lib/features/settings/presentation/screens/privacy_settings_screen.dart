import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InkstampScaffold(
      title: 'Privacy',
      body: ListView(
        children: const <Widget>[
          SizedBox(height: AppSpacing.sm),
          _PrivacyCard(
            icon: Icons.photo_camera_outlined,
            color: AppColors.sky,
            title: 'Camera-only',
            description:
                'Inkstamp does not access your photo library, contacts or location.',
          ),
          SizedBox(height: AppSpacing.md),
          _PrivacyCard(
            icon: Icons.visibility_off_outlined,
            color: AppColors.mint,
            title: 'Private sharing',
            description: 'Only selected recipients can access each stamp.',
          ),
          SizedBox(height: AppSpacing.md),
          _PrivacyCard(
            icon: Icons.widgets_outlined,
            color: AppColors.lilac,
            title: 'Widget',
            description: 'Your latest stamp can appear on your Home Screen.',
          ),
          SizedBox(height: AppSpacing.md),
          _PrivacyCard(
            icon: Icons.location_off_outlined,
            color: AppColors.blush,
            title: 'No location metadata',
            description:
                'EXIF and GPS data are removed before a stamp is uploaded.',
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
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
                const SizedBox(height: AppSpacing.xs),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
