import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.name,
    this.size = 44,
    this.backgroundColor = AppColors.sky,
    super.key,
  });

  final String name;
  final double size;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final String initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .take(2)
        .map((String part) => part[0].toUpperCase())
        .join();

    return Semantics(
      label: '$name profile picture',
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: backgroundColor,
        foregroundColor: AppColors.ink,
        child: Text(
          initials,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: size * 0.34),
        ),
      ),
    );
  }
}
