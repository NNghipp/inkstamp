import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_motion.dart';

/// Pointer feedback never delays or dispatches the child's actual action.
class PressFeedback extends StatefulWidget {
  const PressFeedback({required this.child, this.enabled = true, super.key});
  final Widget child;
  final bool enabled;

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  bool _pressed = false;

  void _set(bool value) {
    if (mounted && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled ? (_) => _set(true) : null,
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: widget.enabled && _pressed ? .96 : 1,
      duration: AppMotion.duration(context, AppMotion.shutter),
      curve: AppMotion.curve,
      child: widget.child,
    ),
  );
}

class SettleIn extends StatelessWidget {
  const SettleIn({required this.child, this.identity, super.key});
  final Widget child;
  final Object? identity;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(identity),
    tween: Tween<double>(begin: 0, end: 1),
    duration: AppMotion.duration(context, AppMotion.screen),
    curve: AppMotion.curve,
    builder: (_, value, child) => Opacity(
      opacity: .9 + .1 * value,
      child: Transform.translate(
        offset: Offset(0, 6 * (1 - value)),
        child: Transform.scale(scale: .98 + .02 * value, child: child),
      ),
    ),
    child: child,
  );
}

class SelectionFeedback extends StatelessWidget {
  const SelectionFeedback({
    required this.selected,
    required this.child,
    super.key,
  });
  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(selected),
    tween: Tween(begin: selected ? 1.04 : 1, end: 1),
    duration: AppMotion.duration(context, AppMotion.fast),
    curve: AppMotion.curve,
    builder: (_, value, child) => Transform.scale(scale: value, child: child),
    child: child,
  );
}
