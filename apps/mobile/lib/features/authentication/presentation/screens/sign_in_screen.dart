import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/features/authentication/domain/use_cases/sign_in.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionState state = ref.watch(sessionControllerProvider);

    return InkstampScaffold(
      title: 'Sign in',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Spacer(),
          Container(
            height: 118,
            width: 118,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sky,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_post_office_rounded,
              size: 52,
              color: AppColors.paper,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Welcome to Inkstamp',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Sign in to start sharing real moments with your friends.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          if (state.errorMessage != null) ...<Widget>[
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          InkstampButton(
            label: 'Continue with Apple',
            icon: Icons.apple_rounded,
            isLoading: state.isLoading,
            onPressed: state.isLoading
                ? null
                : () {
                    ref
                        .read(sessionControllerProvider.notifier)
                        .signIn(SignInProvider.apple);
                  },
          ),
          const SizedBox(height: AppSpacing.sm),
          InkstampButton(
            label: 'Continue with Google',
            icon: Icons.g_mobiledata_rounded,
            isSecondary: true,
            onPressed: state.isLoading
                ? null
                : () {
                    ref
                        .read(sessionControllerProvider.notifier)
                        .signIn(SignInProvider.google);
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'By continuing, you agree to the Terms of Use and Privacy Policy.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.charcoal),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
