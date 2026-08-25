import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkstampScaffold(
      title: 'A little access',
      body: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.xl),
          const _PermissionCard(
            icon: Icons.camera_alt_rounded,
            color: AppColors.sky,
            title: 'Camera',
            description: 'Capture moments directly to create stamps.',
          ),
          const SizedBox(height: AppSpacing.md),
          const _PermissionCard(
            icon: Icons.notifications_active_rounded,
            color: AppColors.blush,
            title: 'Notifications',
            description: 'Know when friends send a stamp or reaction.',
          ),
          const Spacer(),
          const Text(
            'Inkstamp does not access your contacts, photo library or location.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.charcoal),
          ),
          const SizedBox(height: AppSpacing.lg),
          InkstampButton(
            label: 'Allow and continue',
            onPressed: () {
              ref
                  .read(sessionControllerProvider.notifier)
                  .completePermissions();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
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
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
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
