import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color ink = Color(0xFF22211F);
  static const Color charcoal = Color(0xFF353431);
  static const Color paper = Color(0xFFF6F0E7);
  static const Color paperDark = Color(0xFFE9E0D3);
  static const Color sky = Color(0xFF96B5CA);
  static const Color blush = Color(0xFFE8B8B4);
  static const Color mint = Color(0xFFB7D5C5);
  static const Color lilac = Color(0xFFC8BFDC);
  static const Color butter = Color(0xFFE9D69E);
  static const Color mist = Color(0xFFD5D7D5);
  static const Color white = Color(0xFFFFFCF8);
  static const Color danger = Color(0xFFB64D4D);
  static const Color success = Color(0xFF507A62);

  static const List<Color> paperTones = <Color>[
    paper,
    sky,
    blush,
    mint,
    lilac,
    butter,
  ];
}
