import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';

class UsernameSetupScreen extends ConsumerStatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  ConsumerState<UsernameSetupScreen> createState() {
    return _UsernameSetupScreenState();
  }
}

class _UsernameSetupScreenState extends ConsumerState<UsernameSetupScreen> {
  final TextEditingController _displayNameController = TextEditingController(
    text: 'Minh Anh',
  );
  final TextEditingController _usernameController = TextEditingController(
    text: 'minhanh.stamps',
  );

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SessionState state = ref.watch(sessionControllerProvider);

    return InkstampScaffold(
      title: 'Your profile',
      body: ListView(
        children: <Widget>[
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: <Widget>[
                const CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.sky,
                  child: Icon(
                    Icons.person_rounded,
                    size: 54,
                    color: AppColors.paper,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.ink,
                  ),
                  child: const Icon(
                    Icons.add_a_photo_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _displayNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Display name',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _usernameController,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixText: '@',
              prefixIcon: Icon(Icons.alternate_email_rounded),
              helperText:
                  '3–20 characters: lowercase letters, numbers, dots or underscores.',
            ),
          ),
          if (state.errorMessage != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          InkstampButton(
            label: 'Continue',
            isLoading: state.isLoading,
            onPressed: state.isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final String username = _usernameController.text.trim().toLowerCase();
    final String displayName = _displayNameController.text.trim();
    final RegExp usernamePattern = RegExp(r'^[a-z0-9._]{3,20}$');

    if (displayName.isEmpty || !usernamePattern.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your name and username.')),
      );
      return;
    }

    final bool success = await ref
        .read(sessionControllerProvider.notifier)
        .completeProfile(username: username, displayName: displayName);
    if (success && mounted) {
      context.go(AppRoutes.permissions);
    }
  }
}
