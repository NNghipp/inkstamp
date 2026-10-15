import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_motion.dart';
import 'package:inkstamp/app/theme/gallery_tokens.dart';
import 'package:inkstamp/core/widgets/editorial_ui.dart';
import 'package:inkstamp/core/widgets/memory_photo.dart';
import 'package:inkstamp/core/widgets/motion_feedback.dart';
import 'package:inkstamp/core/widgets/spatial_stamp_gallery.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/archive/presentation/controllers/memory_view_controller.dart';
import 'package:inkstamp/features/authentication/domain/dev_auth_policy.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({this.designPreview = false, super.key});
  final bool designPreview;

  static const _assets = [
    EditorialAssets.street,
    EditorialAssets.tea,
    EditorialAssets.cafeFriends,
    EditorialAssets.portrait,
    EditorialAssets.street,
    EditorialAssets.tea,
    EditorialAssets.cafeFriends,
    EditorialAssets.street,
    EditorialAssets.portrait,
  ];
  static const _titles = [
    'Tách trà · 26/09',
    'Phố quen · 24/09',
    'Góc quán · 22/09',
    'Nụ cười · 18/09',
    'Nắng sớm · 15/09',
    'Cuối chiều · 10/09',
    'Gió thu · 04/09',
    'Hoàng hôn · 01/09',
    'Kỷ niệm · 28/08',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stamps = designPreview ? null : ref.watch(collectionMemoriesProvider);
    final user = designPreview
        ? null
        : ref.watch(sessionControllerProvider).user;
    final count = designPreview
        ? 142
        : ref.watch(stampTimelineControllerProvider).sent.length;
    final friends = designPreview
        ? 18
        : ref.watch(friendsControllerProvider).friends.length;
    final ids =
        stamps?.map((s) => s.id).toList() ??
        List.generate(_assets.length, (i) => 'preview-${142 - i}');
    return ColoredBox(
      color: GalleryTokens.canvas,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const PageStorageKey('collection-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EditorialHeader(title: 'bộ sưu tập'),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (designPreview)
                          const EditorialAvatar(size: 52)
                        else
                          UserAvatar(
                            name: user?.displayName ?? 'InkStamp',
                            size: 52,
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ??
                                    (designPreview ? 'Hà Linh' : 'Cá nhân'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                user?.username == null
                                    ? (designPreview ? '@halinh.lens' : '')
                                    : '@${user!.username}',
                                style: const TextStyle(
                                  color: GalleryTokens.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ghi chép những khoảnh khắc dịu dàng qua góc nhìn thường nhật.',
                      style: TextStyle(
                        color: GalleryTokens.secondaryText,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$count tem  ·  $friends bạn bè',
                      style: const TextStyle(
                        color: GalleryTokens.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final filter in CollectionFilter.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _CollectionFilterControl(
                                label: switch (filter) {
                                  CollectionFilter.all => 'Bộ sưu tập ($count)',
                                  CollectionFilter.month =>
                                    designPreview
                                        ? 'Tháng 09'
                                        : 'Tháng ${DateTime.now().month.toString().padLeft(2, '0')}',
                                  CollectionFilter.year2026 => '2026',
                                  CollectionFilter.year2025 => '2025',
                                },
                                selected:
                                    (designPreview
                                        ? CollectionFilter.all
                                        : ref.watch(
                                            collectionFilterProvider,
                                          )) ==
                                    filter,
                                onTap: designPreview
                                    ? null
                                    : () => ref
                                          .read(
                                            collectionFilterProvider.notifier,
                                          )
                                          .select(filter),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverStampGallery(
                ids: ids,
                itemBuilder: (context, index) {
                  final stamp = stamps == null ? null : stamps[index];
                  final title = stamp == null
                      ? _titles[index]
                      : stamp.shortTitle.isEmpty
                      ? DateFormat('dd/MM').format(stamp.captureTime)
                      : stamp.shortTitle;
                  return Semantics(
                    button: stamp != null,
                    label: 'Tem $title',
                    child: PressFeedback(
                      enabled: stamp != null,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: stamp == null
                            ? null
                            : () => context.push(AppRoutes.stamp(stamp.id)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: MemoryPhoto(
                                publicId: stamp?.cloudinaryThumbnailPublicId,
                                asset: stamp == null ? _assets[index] : null,
                                decodeSize: 512,
                                capturedAt: stamp?.captureTime,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: GalleryTokens.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (stamps != null && stamps.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Chưa có tem trong bộ sưu tập này.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (!designPreview && DevAuthPolicy.compiledEnabled)
              SliverToBoxAdapter(
                child: TextButton(
                  onPressed: () async =>
                      ref.read(sessionControllerProvider.notifier).signOut(),
                  child: const Text('DEV: Logout / switch test account'),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _CollectionFilterControl extends StatelessWidget {
  const _CollectionFilterControl({
    required this.label,
    required this.selected,
    this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Center(
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.fast),
            curve: AppMotion.curve,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? GalleryTokens.selectedGlass
                  : GalleryTokens.glass,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected ? const Color(0x40FFFFFF) : GalleryTokens.line,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? GalleryTokens.text
                    : GalleryTokens.secondaryText,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
