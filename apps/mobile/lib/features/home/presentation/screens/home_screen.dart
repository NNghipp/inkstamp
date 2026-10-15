import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/gallery_tokens.dart';
import 'package:inkstamp/core/widgets/editorial_ui.dart';
import 'package:inkstamp/core/widgets/memory_photo.dart';
import 'package:inkstamp/features/archive/presentation/controllers/memory_view_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({this.initializeCamera = true, super.key});

  // Kept for compatibility with the existing lightweight widget harness.
  final bool initializeCamera;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = initializeCamera ? ref.watch(memoriesProvider) : null;
    return ColoredBox(
      color: EditorialColors.canvas,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
          key: const PageStorageKey('history-scroll'),
          children: <Widget>[
            EditorialHeader(
              title: 'khoảnh khắc',
              trailing: initializeCamera
                  ? IconButton(
                      tooltip: 'Hộp thư',
                      onPressed: () => context.push(AppRoutes.inbox),
                      icon: const Icon(Icons.inbox_outlined, size: 22),
                    )
                  : const EditorialAvatar(size: 32),
            ),
            const SizedBox(height: 7),
            const _FeedLabel(),
            const SizedBox(height: 17),
            if (memories != null) ...<Widget>[
              if (ref.watch(stampTimelineControllerProvider).isLoading)
                const Center(child: CircularProgressIndicator()),
              if (ref.watch(stampTimelineControllerProvider).errorMessage !=
                  null)
                TextButton(
                  onPressed: () =>
                      ref.read(stampTimelineControllerProvider.notifier).load(),
                  child: const Text('Không thể tải ký ức. Thử lại'),
                ),
              if (memories.isEmpty &&
                  !ref.watch(stampTimelineControllerProvider).isLoading)
                const Text('Chưa có khoảnh khắc.'),
              for (final stamp in memories) ...<Widget>[
                _MomentCard(
                  publicId: stamp.cloudinaryPublicId,
                  capturedAt: stamp.captureTime,
                  time: DateFormat('HH:mm').format(stamp.captureTime.toLocal()),
                  person: stamp.senderName,
                  caption: stamp.shortTitle,
                  onTap: () => context.push(AppRoutes.stamp(stamp.id)),
                ),
                const SizedBox(height: 20),
              ],
            ] else ...const <Widget>[
              _MomentCard(
                image: EditorialAssets.street,
                time: '08:30',
                person: 'Lan',
                caption: 'Nắng sớm ngõ nhỏ',
              ),
              SizedBox(height: 20),
              _MomentCard(
                image: EditorialAssets.cafeFriends,
                time: '17:15',
                person: 'Minh',
                caption: 'Cà phê chiều cùng Minh',
              ),
              SizedBox(height: 20),
              _MomentCard(
                image: EditorialAssets.street,
                time: '19:45',
                person: 'An',
                caption: 'Hoàng hôn qua vòm cây',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedLabel extends StatelessWidget {
  const _FeedLabel();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Những khoảnh khắc được giữ lại.',
      style: TextStyle(color: GalleryTokens.secondaryText, fontSize: 12),
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    this.image,
    this.publicId,
    this.onTap,
    this.capturedAt,
    required this.time,
    required this.person,
    required this.caption,
  });

  final String? image;
  final String? publicId;
  final VoidCallback? onTap;
  final DateTime? capturedAt;
  final String time;
  final String person;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'Ký ức của $person, $time, $caption',
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: const BoxDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  MemoryPhoto(
                    asset: image,
                    publicId: publicId,
                    capturedAt: capturedAt,
                  ),
                  Positioned(top: 10, left: 10, child: _PhotoTag(label: time)),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * .40,
                      ),
                      child: _PhotoTag(label: person),
                    ),
                  ),
                  if (caption.isNotEmpty)
                    Positioned(
                      bottom: capturedAt == null ? 10 : 46,
                      left: 10,
                      right: 10,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _PhotoTag(label: caption, large: true),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTag extends StatelessWidget {
  const _PhotoTag({required this.label, this.large = false});

  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GalleryTokens.overlay,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: large ? 9 : 8, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: large ? 12 : 11,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ),
    );
  }
}
