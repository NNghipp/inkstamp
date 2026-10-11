import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/authentication/domain/dev_auth_policy.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';

class DevTestLogin extends ConsumerWidget {
  const DevTestLogin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!DevAuthPolicy.compiledEnabled ||
        !ref.watch(firebaseInitializedProvider)) {
      return const SizedBox.shrink();
    }
    final loading = ref.watch(sessionControllerProvider).isLoading;
    return Column(
      children: [
        const Text('DEV only · inkstamp-dev'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final account in DevTestAccount.values)
              TextButton(
                onPressed: loading ? null : () => _login(context, ref, account),
                child: Text('Login as ${account.label}'),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _login(
    BuildContext context,
    WidgetRef ref,
    DevTestAccount account,
  ) async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => _DevPasswordDialog(account: account),
    );
    if (password == null || password.isEmpty || !context.mounted) return;
    await ref
        .read(sessionControllerProvider.notifier)
        .signInForDevelopment(account, password: password);
  }
}

class _DevPasswordDialog extends StatefulWidget {
  const _DevPasswordDialog({required this.account});
  final DevTestAccount account;
  @override
  State<_DevPasswordDialog> createState() => _DevPasswordDialogState();
}

class _DevPasswordDialogState extends State<_DevPasswordDialog> {
  final input = TextEditingController();
  @override
  void dispose() {
    input.clear();
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('DEV ${widget.account.label}'),
    content: TextField(
      controller: input,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      decoration: const InputDecoration(labelText: 'Local test password'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, input.text),
        child: const Text('Sign in'),
      ),
    ],
  );
}
