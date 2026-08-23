import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String fontFamily = 'sans-serif';

  static const TextStyle display = TextStyle(
    color: Color(0xFF22211F),
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -1.4,
  );

  static const TextStyle title = TextStyle(
    color: Color(0xFF22211F),
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.6,
  );

  static const TextStyle heading = TextStyle(
    color: Color(0xFF22211F),
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle body = TextStyle(
    color: Color(0xFF353431),
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle label = TextStyle(
    color: Color(0xFF353431),
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
}
