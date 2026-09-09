import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Debounced username availability state
  Timer? _debounceTimer;
  _UsernameStatus _usernameStatus = _UsernameStatus.idle;

  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9._]{3,20}$');

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    final String raw = _usernameController.text.trim().toLowerCase();
    _debounceTimer?.cancel();

    if (raw.isEmpty || !_usernamePattern.hasMatch(raw)) {
      setState(() => _usernameStatus = _UsernameStatus.idle);
      return;
    }

    setState(() => _usernameStatus = _UsernameStatus.checking);

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      bool available;
      try {
        available = await ref
            .read(authenticationRepositoryProvider)
            .isUsernameAvailable(raw);
      } on Object {
        if (mounted) {
          setState(() => _usernameStatus = _UsernameStatus.idle);
        }
        return;
      }

      if (!mounted) {
        return;
      }

      // Guard against stale callback – only apply if the text hasn't changed.
      if (_usernameController.text.trim().toLowerCase() == raw) {
        setState(() {
          _usernameStatus = available
              ? _UsernameStatus.available
              : _UsernameStatus.taken;
        });
      }
    });
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
            decoration: InputDecoration(
              labelText: 'Username',
              prefixText: '@',
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              helperText:
                  '3–20 characters: lowercase letters, numbers, dots or underscores.',
              suffixIcon: _buildUsernameSuffix(),
            ),
          ),
          if (_usernameStatus == _UsernameStatus.taken) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'This username is already taken.',
              style: TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
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

  Widget? _buildUsernameSuffix() {
    return switch (_usernameStatus) {
      _UsernameStatus.idle => null,
      _UsernameStatus.checking => const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      _UsernameStatus.available => const Icon(
        Icons.check_circle_rounded,
        color: AppColors.success,
      ),
      _UsernameStatus.taken => const Icon(
        Icons.cancel_rounded,
        color: AppColors.danger,
      ),
    };
  }

  Future<void> _submit() async {
    final String username = _usernameController.text.trim().toLowerCase();
    final String displayName = _displayNameController.text.trim();

    if (displayName.isEmpty || !_usernamePattern.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your name and username.')),
      );
      return;
    }

    // GoRouter redirect will automatically navigate to the next screen
    // once SessionStage changes to `permissions`.
    await ref
        .read(sessionControllerProvider.notifier)
        .completeProfile(username: username, displayName: displayName);
  }
}

enum _UsernameStatus { idle, checking, available, taken }
