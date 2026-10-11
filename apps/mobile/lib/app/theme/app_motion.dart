import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const screen = Duration(milliseconds: 260);
  static const shutter = Duration(milliseconds: 100);
  static const success = Duration(milliseconds: 400);
  static const focusHold = Duration(milliseconds: 1200);
  static const curve = Curves.easeOutCubic;

  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;

  static Widget transition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(parent: animation, curve: curve);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: .98, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}
