import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';

class StampSentScreen extends StatelessWidget {
  const StampSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InkstampScaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.done_rounded,
              size: 60,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Your stamp is on its way!',
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Your moment is appearing in your friends’ Inboxes.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          InkstampButton(
            label: 'Take another stamp',
            icon: Icons.camera_alt_rounded,
            onPressed: () => context.go(AppRoutes.camera),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkstampButton(
            label: 'Xem Calendar',
            isSecondary: true,
            onPressed: () => context.go(AppRoutes.calendar),
          ),
        ],
      ),
    );
  }
}
