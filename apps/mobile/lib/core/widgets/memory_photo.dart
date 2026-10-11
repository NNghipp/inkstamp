import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_delivery_repository.dart';

/// Uses the existing authenticated media gateway, never a public Cloudinary URL.
class MemoryPhoto extends ConsumerWidget {
  const MemoryPhoto({this.publicId, this.asset, super.key});
  final String? publicId;
  final String? asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (asset != null) {
      return Image.asset(
        asset!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFE7E7E2)),
      );
    }
    if (publicId == null) return const ColoredBox(color: Color(0xFFE7E7E2));
    return ref
        .watch(mediaDeliveryUrlProvider(publicId!))
        .when(
          data: (url) => Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const ColoredBox(color: Color(0xFFE7E7E2)),
            errorBuilder: (_, _, _) => Center(
              child: IconButton(
                tooltip: 'Stamp không còn khả dụng. Tải lại ảnh',
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    ref.invalidate(mediaDeliveryUrlProvider(publicId!)),
              ),
            ),
          ),
          loading: () => const ColoredBox(color: Color(0xFFE7E7E2)),
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
