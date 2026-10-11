import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/core/images/stamp_image_format.dart';
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
                  time: DateFormat('HH:mm').format(stamp.createdAt.toLocal()),
                  person: stamp.senderName,
                  caption: stamp.shortTitle,
                  onTap: () => context.push(AppRoutes.stamp(stamp.id)),
                ),
                const SizedBox(height: 24),
              ],
            ] else ...const <Widget>[
              _MomentCard(
                image: EditorialAssets.street,
                time: '08:30',
                person: 'Lan',
                caption: 'Nắng sớm ngõ nhỏ',
              ),
              SizedBox(height: 24),
              _MomentCard(
                image: EditorialAssets.cafeFriends,
                time: '17:15',
                person: 'Minh',
                caption: 'Cà phê chiều cùng Minh',
              ),
              SizedBox(height: 24),
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
    return const SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 470,
          child: Row(
            children: <Widget>[
              TechnicalText('BẢN TIN THỊ GIÁC', fontSize: 11),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 9),
                child: Text('/', style: TextStyle(color: Color(0xFFB1B1AB))),
              ),
              Text(
                'Hôm nay',
                style: TextStyle(
                  color: EditorialColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              Icon(
                Icons.filter_vintage_outlined,
                size: 15,
                color: Color(0xFF6B6C67),
              ),
              SizedBox(width: 6),
              TechnicalText('CUỘN TEM 35MM', fontSize: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    this.image,
    this.publicId,
    this.onTap,
    required this.time,
    required this.person,
    required this.caption,
  });

  final String? image;
  final String? publicId;
  final VoidCallback? onTap;
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
          decoration: isProcessedStampImage(publicId)
              ? const BoxDecoration()
              : BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E2DD)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 7,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  MemoryPhoto(asset: image, publicId: publicId),
                  Positioned(top: 10, left: 10, child: _PhotoTag(label: time)),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _PhotoTag(label: person),
                  ),
                  if (caption.isNotEmpty)
                    Positioned(
                      bottom: 10,
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
        color: const Color(0xC936352F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 11 : 10,
          vertical: large ? 5 : 4,
        ),
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
