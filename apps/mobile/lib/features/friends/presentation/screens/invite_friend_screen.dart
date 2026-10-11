import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

String inviteLinkForUsername(String username) {
  return 'https://inkstamp.app/u/${Uri.encodeComponent(username)}';
}

class InviteFriendScreen extends ConsumerWidget {
  const InviteFriendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String username =
        ref.watch(sessionControllerProvider).user?.username ?? '';
    final String inviteLink = inviteLinkForUsername(username);
    return InkstampScaffold(
      title: 'Invite friends',
      body: Column(
        children: <Widget>[
          const Spacer(),
          Container(
            width: 248,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: username.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : QrImageView(data: inviteLink),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            username.isEmpty ? 'Your profile' : '@$username',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Scan the code or share your link to connect on Inkstamp.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          InkstampButton(
            label: 'Copy invite link',
            icon: Icons.link_rounded,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: inviteLink));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite link copied.')),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
