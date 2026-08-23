import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() {
    return _DeleteAccountScreenState();
  }
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final TextEditingController _confirmationController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SessionState state = ref.watch(sessionControllerProvider);

    return InkstampScaffold(
      title: 'Delete account',
      body: ListView(
        children: <Widget>[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.blush.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: <Widget>[
                Icon(
                  Icons.warning_amber_rounded,
                  size: 52,
                  color: AppColors.danger,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'This action cannot be undone',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Your profile, username, sent stamps, media and related access will be deleted.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Type DELETE to confirm:'),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _confirmationController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'DELETE'),
          ),
          const SizedBox(height: AppSpacing.xl),
          InkstampButton(
            label: 'Permanently delete account',
            isLoading: state.isLoading,
            onPressed:
                _confirmationController.text.trim().toUpperCase() == 'DELETE' &&
                    !state.isLoading
                ? _delete
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    await ref.read(sessionControllerProvider.notifier).deleteAccount();
    if (mounted) {
      context.go(AppRoutes.welcome);
    }
  }
}
