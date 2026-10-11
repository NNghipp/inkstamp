import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String fontFamily = 'BeVietnamPro';

  static const TextStyle display = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.8,
  );

  static const TextStyle title = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w500,
    height: 1.27,
    letterSpacing: -0.45,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.1,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.48,
  );
}
