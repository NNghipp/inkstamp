import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();
    final AppUser? user = ref.read(sessionControllerProvider).user;
    _displayNameController = TextEditingController(
      text: user?.displayName ?? 'Minh Anh',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = ref.watch(sessionControllerProvider).user;

    return InkstampScaffold(
      title: 'Edit profile',
      body: ListView(
        children: <Widget>[
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: UserAvatar(name: _displayNameController.text, size: 104),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _displayNameController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Display name',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: '@${user?.username ?? 'minhanh.stamps'}',
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              helperText:
                  'Username changes will be added after the closed beta.',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          InkstampButton(
            label: 'Save changes',
            onPressed: () {
              final String name = _displayNameController.text.trim();
              if (name.isEmpty) {
                return;
              }
              ref
                  .read(sessionControllerProvider.notifier)
                  .updateDisplayName(name);
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}
