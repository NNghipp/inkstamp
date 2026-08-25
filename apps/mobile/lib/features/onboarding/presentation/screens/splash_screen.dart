import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/core/widgets/paper_background.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PaperBackground(
        borderRadius: BorderRadius.zero,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _InkstampMark(size: 92),
              SizedBox(height: 20),
              Text(
                'Inkstamp',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -1.2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Turn moments into stamps',
                style: TextStyle(color: AppColors.charcoal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InkstampMark extends StatelessWidget {
  const _InkstampMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.sky,
        border: Border.all(color: AppColors.paper, width: 8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: AppColors.paper,
        size: size * 0.42,
      ),
    );
  }
}
