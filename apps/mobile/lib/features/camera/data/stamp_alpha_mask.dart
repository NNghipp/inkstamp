import 'dart:math' as math;

import 'package:image/image.dart' as image;

/// One normalized mask for both resolutions: 12 circular perforations per side.
/// Coverage is antialiased at the output pixel size, never painted paper/black.
class StampAlphaMask {
  static const int perforations = 12;
  static const double radius = 0.025;

  static image.Image apply(image.Image source) {
    final result = source.convert(format: image.Format.uint8, numChannels: 4);
    final size = result.width;
    if (size != result.height) {
      throw ArgumentError('Stamp mask requires a square processed image.');
    }
    final r = size * radius;
    final pitch = size / perforations;
    for (final pixel in result) {
      final x = pixel.x + 0.5;
      final y = pixel.y + 0.5;
      // The interior is unchanged; only the edge band needs mask evaluation.
      if (x > r + 1 && x < size - r - 1 && y > r + 1 && y < size - r - 1) {
        continue;
      }
      final dx = x - (x / pitch).floor() * pitch - pitch / 2;
      final dy = y - (y / pitch).floor() * pitch - pitch / 2;
      var distance = math.min(
        math.min(
          math.sqrt(dx * dx + y * y) - r,
          math.sqrt(dx * dx + (size - y) * (size - y)) - r,
        ),
        math.min(
          math.sqrt(dy * dy + x * x) - r,
          math.sqrt(dy * dy + (size - x) * (size - x)) - r,
        ),
      );
      // Rounded outer corners also have genuine transparent pixels.
      final cx = math.max(r - x, math.max(x - (size - r), 0.0));
      final cy = math.max(r - y, math.max(y - (size - r), 0.0));
      distance = math.min(distance, r - math.sqrt(cx * cx + cy * cy));
      final coverage = (distance + 0.5).clamp(0.0, 1.0);
      pixel.a = (pixel.a * coverage).round();
      if (pixel.a == 0) pixel.setRgba(0, 0, 0, 0);
    }
    return result;
  }
}
