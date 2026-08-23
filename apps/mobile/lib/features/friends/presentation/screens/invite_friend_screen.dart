import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';

class InviteFriendScreen extends StatelessWidget {
  const InviteFriendScreen({super.key});

  static const String inviteLink = 'https://inkstamp.app/u/minhanh.stamps';

  @override
  Widget build(BuildContext context) {
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
            child: const AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(painter: _QrPlaceholderPainter()),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '@minhanh.stamps',
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
              await Clipboard.setData(const ClipboardData(text: inviteLink));
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

class _QrPlaceholderPainter extends CustomPainter {
  const _QrPlaceholderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppColors.ink;
    const List<List<int>> modules = <List<int>>[
      <int>[1, 1, 1, 0, 1, 0, 1, 1, 1],
      <int>[1, 0, 1, 0, 0, 1, 1, 0, 1],
      <int>[1, 1, 1, 1, 0, 1, 1, 1, 1],
      <int>[0, 0, 1, 0, 1, 0, 0, 1, 0],
      <int>[1, 1, 0, 1, 1, 1, 0, 1, 1],
      <int>[0, 1, 1, 0, 1, 0, 1, 0, 0],
      <int>[1, 1, 1, 0, 0, 1, 1, 1, 1],
      <int>[1, 0, 1, 1, 1, 0, 1, 0, 1],
      <int>[1, 1, 1, 0, 1, 1, 1, 1, 1],
    ];
    final double cell = size.width / modules.length;
    for (int row = 0; row < modules.length; row += 1) {
      for (int column = 0; column < modules[row].length; column += 1) {
        if (modules[row][column] == 1) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                column * cell + 2,
                row * cell + 2,
                cell - 4,
                cell - 4,
              ),
              const Radius.circular(2),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
