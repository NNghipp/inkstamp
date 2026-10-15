import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Explicit code-unit hash; independent of String.hashCode and runtime seeds.
@immutable
class StampPlacement {
  const StampPlacement(this.rotation, this.scale, this.offset);

  factory StampPlacement.forId(String id) {
    double unit(String salt) {
      var hash = 17;
      for (final code in '$id/$salt'.codeUnits) {
        hash = (hash * 31 + code) & 0x7fffffff;
      }
      // Mix high and low bits, retaining exact integer arithmetic on all targets.
      hash = ((hash >> 16) ^ hash) & 0x7fffffff;
      return (hash % 10001) / 10000;
    }

    return StampPlacement(
      (unit('angle') * 16 - 8) * math.pi / 180,
      .88 + unit('size') * .24,
      Offset((unit('x') - .5) * .05, (unit('y') - .5) * .06),
    );
  }

  final double rotation;
  final double scale;

  /// Fractions of the lane width, bounded to preserve separate hit regions.
  final Offset offset;
}

/// Vertical, lazy canvas blocks. Bounds reserve space for rotation and captions;
/// stamps never overlap another hit target, including at maximum text scaling.
class SliverStampGallery extends StatelessWidget {
  const SliverStampGallery({
    required this.ids,
    required this.itemBuilder,
    super.key,
  });

  final List<String> ids;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final lane = constraints.crossAxisExtent / 2;
      final captionHeight = MediaQuery.textScalerOf(context).scale(12) * 1.5;
      final extent = lane * 1.27 + captionHeight + 18;
      return SliverList.builder(
        itemCount: (ids.length / 2).ceil(),
        itemBuilder: (context, row) => SizedBox(
          height: extent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(2, (column) {
              final index = row * 2 + column;
              if (index >= ids.length) return const Expanded(child: SizedBox());
              final id = ids[index];
              final placement = StampPlacement.forId(id);
              final width = lane * .70 * placement.scale;
              return Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      left: (lane - width) / 2 + lane * placement.offset.dx,
                      top: lane * (.13 + column * .17 + placement.offset.dy),
                      width: width,
                      child: RepaintBoundary(
                        key: ValueKey('gallery-$id'),
                        child: Transform.rotate(
                          angle: placement.rotation,
                          child: itemBuilder(context, index),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      );
    },
  );
}
