import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/app/theme/gallery_tokens.dart';
import 'package:inkstamp/core/images/stamp_image_format.dart';
import 'package:inkstamp/core/widgets/stamp_date_overlay.dart';
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_delivery_repository.dart';

/// Uses the existing authenticated media gateway, never a public Cloudinary URL.
class MemoryPhoto extends ConsumerWidget {
  const MemoryPhoto({
    this.publicId,
    this.asset,
    this.decodeSize = 1440,
    this.capturedAt,
    super.key,
  });
  final String? publicId;
  final String? asset;
  final int decodeSize;
  final DateTime? capturedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (asset != null) {
      return Image.asset(
        asset!,
        fit: BoxFit.cover,
        cacheWidth: decodeSize,
        errorBuilder: (_, _, _) =>
            const ColoredBox(color: GalleryTokens.surface),
      );
    }
    if (publicId == null) return const ColoredBox(color: GalleryTokens.surface);
    return ref
        .watch(mediaDeliveryUrlProvider(publicId!))
        .when(
          data: (url) {
            final photo = Image.network(
              url,
              fit: BoxFit.cover,
              // Delivery already returns 512px thumbnails / 1440px full images.
              // Keep the NetworkImage cache key used by privacy revocation.
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const ColoredBox(color: GalleryTokens.surface),
              errorBuilder: (_, _, _) => Center(
                child: IconButton(
                  tooltip: 'Stamp không còn khả dụng. Tải lại ảnh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      ref.invalidate(mediaDeliveryUrlProvider(publicId!)),
                ),
              ),
            );
            return capturedAt != null && isProcessedStampImage(publicId)
                ? StampDateOverlay(date: capturedAt!, child: photo)
                : photo;
          },
          loading: () => const ColoredBox(color: GalleryTokens.surface),
          error: (_, _) => Center(
            child: IconButton(
              tooltip: 'Tải lại ảnh',
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.invalidate(mediaDeliveryUrlProvider(publicId!)),
            ),
          ),
        );
  }
}
