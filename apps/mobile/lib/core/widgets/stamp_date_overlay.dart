import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date is presentation metadata; never flattens the RGBA stamp underneath.
class StampDateOverlay extends StatelessWidget {
  const StampDateOverlay({
    required this.child,
    required this.date,
    this.bottom = 0,
    super.key,
  });
  final Widget child;
  final DateTime date;
  final double bottom;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (!width.isFinite || width < 100) return child;
      final inset = width * .065;
      return Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned(
            right: inset,
            bottom: inset + bottom,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xCC0F0F10),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  child: Text(
                    DateFormat('dd.MM.yyyy').format(date.toLocal()),
                    key: const ValueKey('stamp-capture-date'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width < 200 ? 8 : 11,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
