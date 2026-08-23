import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InkstampScaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: <Widget>[
                    const Spacer(),
                    SizedBox(
                      width: 238,
                      child: Transform.rotate(
                        angle: -0.055,
                        child: const StampArtwork(
                          seed: 14,
                          frameStyle: StampFrameStyle.classic,
                          paperTone: PaperTone.cream,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Small moments,\nkept for longer.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Capture a moment, turn it into a stamp and send it to the people you care about.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.charcoal,
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                    const Spacer(),
                    InkstampButton(
                      label: 'Get started with Inkstamp',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => context.push(AppRoutes.signIn),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
