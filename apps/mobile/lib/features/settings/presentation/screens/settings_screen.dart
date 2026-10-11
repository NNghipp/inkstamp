import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_motion.dart';
import 'package:inkstamp/core/images/stamp_image_format.dart';
import 'package:inkstamp/core/widgets/editorial_ui.dart';
import 'package:inkstamp/core/widgets/memory_photo.dart';
import 'package:inkstamp/features/archive/presentation/controllers/memory_view_controller.dart';
import 'package:inkstamp/features/authentication/domain/dev_auth_policy.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({this.designPreview = false, super.key});
  final bool designPreview;

  static const List<_CollectionItem> _items = <_CollectionItem>[
    _CollectionItem(EditorialAssets.street, '142', '26.09', 'Tách trà · 26/09'),
    _CollectionItem(EditorialAssets.tea, '141', '24.09', 'Phố quen · 24/09'),
    _CollectionItem(
      EditorialAssets.cafeFriends,
      '140',
      '22.09',
      'Góc quán · 22/09',
    ),
    _CollectionItem(
      EditorialAssets.portrait,
      '139',
      '18.09',
      'Nụ cười · 18/09',
    ),
    _CollectionItem(EditorialAssets.street, '138', '15.09', 'Nắng sớm · 15/09'),
    _CollectionItem(EditorialAssets.tea, '137', '10.09', 'Cuối chiều · 10/09'),
    _CollectionItem(
      EditorialAssets.cafeFriends,
      '136',
      '04.09',
      'Gió thu · 04/09',
    ),
    _CollectionItem(
      EditorialAssets.street,
      '135',
      '01.09',
      'Hoàng hôn · 01/09',
    ),
    _CollectionItem(
      EditorialAssets.portrait,
      '134',
      '28.08',
      'Kỷ niệm · 28/08',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stamps = designPreview ? null : ref.watch(collectionMemoriesProvider);
    final user = designPreview
        ? null
        : ref.watch(sessionControllerProvider).user;
    return ColoredBox(
      color: EditorialColors.canvas,
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey('collection-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: <Widget>[
            const EditorialHeader(
              title: 'cá nhân',
              trailing: EditorialAvatar(size: 32),
            ),
            const SizedBox(height: 19),
            _ProfileSummary(
              name: user?.displayName,
              username: user?.username,
              designPreview: designPreview,
            ),
            const SizedBox(height: 16),
            _Stats(
              count: designPreview
                  ? null
                  : ref.watch(stampTimelineControllerProvider).sent.length,
              friendCount: designPreview
                  ? null
                  : ref.watch(friendsControllerProvider).friends.length,
            ),
            const SizedBox(height: 18),
            _Filters(
              selected: designPreview
                  ? CollectionFilter.all
                  : ref.watch(collectionFilterProvider),
              onSelected: designPreview
                  ? null
                  : ref.read(collectionFilterProvider.notifier).select,
              count: designPreview
                  ? 142
                  : ref.watch(stampTimelineControllerProvider).sent.length,
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: EditorialColors.line),
            const SizedBox(height: 13),
            const Row(
              children: <Widget>[
                TechnicalText(
                  'TẬP TEM PHÁT HÀNH THÁNG 09 · 2026',
                  fontSize: 10,
                ),
                Spacer(),
                TechnicalText('SERIES NO. 09-A', fontSize: 9),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - 30) / 3;
                final scaler = MediaQuery.textScalerOf(context);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    // Square photo + thin frame, tiny existing metadata and title.
                    mainAxisExtent:
                        tileWidth +
                        11 +
                        scaler.scale(6) +
                        scaler.scale(10) * 1.2,
                  ),
                  itemCount: stamps?.length ?? _items.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (stamps == null) return _StampTile(item: _items[index]);
                    final stamp = stamps[index];
                    return _StampTile(
                      item: _CollectionItem(
                        null,
                        stamp.id,
                        DateFormat('dd.MM').format(stamp.createdAt),
                        stamp.shortTitle.isEmpty
                            ? DateFormat('dd/MM').format(stamp.createdAt)
                            : stamp.shortTitle,
                        publicId: stamp.cloudinaryThumbnailPublicId,
                      ),
                      onTap: () => context.push(AppRoutes.stamp(stamp.id)),
                    );
                  },
                );
              },
            ),
            if (stamps != null && stamps.isEmpty)
              const Text('Chưa có tem trong bộ sưu tập này.'),
            const SizedBox(height: 34),
            const _Perforation(),
            const SizedBox(height: 20),
            const _ArchiveSeal(),
            if (!designPreview && DevAuthPolicy.compiledEnabled)
              TextButton(
                onPressed: () async {
                  await ref.read(sessionControllerProvider.notifier).signOut();
                },
                child: const Text('DEV: Logout / switch test account'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({this.name, this.username, this.designPreview = false});
  final String? name;
  final String? username;
  final bool designPreview;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(color: Color(0x22000000), blurRadius: 5),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(3),
                child: EditorialAvatar(size: 62),
              ),
            ),
            Positioned(
              right: -2,
              bottom: 2,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black,
                child: Text(
                  'NK',
                  style: TextStyle(color: Colors.white, fontSize: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    name ?? (designPreview ? 'Hà Linh' : 'Cá nhân'),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: TechnicalText('INK-HL026', fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                username == null
                    ? (designPreview ? '@halinh.lens' : '')
                    : '@$username',
                style: const TextStyle(fontSize: 12, color: Color(0xFF4E4F4B)),
              ),
              const SizedBox(height: 3),
              const Text(
                'Ghi chép những khoảnh khắc dịu dàng\nqua góc nhìn thường nhật.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF5B5C57),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({this.count, this.friendCount});
  final int? count;
  final int? friendCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          '${count ?? 142} tem',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('·', style: TextStyle(color: EditorialColors.muted)),
        ),
        Text(
          '${friendCount ?? 18} bạn bè',
          style: const TextStyle(fontSize: 11, color: EditorialColors.muted),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('·', style: TextStyle(color: EditorialColors.muted)),
        ),
        const Text(
          'Hà Nội, 2026',
          style: TextStyle(fontSize: 11, color: EditorialColors.muted),
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    this.selected = CollectionFilter.all,
    this.onSelected,
    this.count = 142,
  });
  final CollectionFilter selected;
  final ValueChanged<CollectionFilter>? onSelected;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _Filter(
          label: 'Bộ sưu tập ($count)',
          selected: selected == CollectionFilter.all,
          onTap: onSelected == null
              ? null
              : () => onSelected!(CollectionFilter.all),
        ),
        const SizedBox(width: 7),
        _Filter(
          label: onSelected == null
              ? 'Tháng 09'
              : 'Tháng ${DateTime.now().month.toString().padLeft(2, '0')}',
          selected: selected == CollectionFilter.month,
          onTap: onSelected == null
              ? null
              : () => onSelected!(CollectionFilter.month),
        ),
        const SizedBox(width: 7),
        _Filter(
          label: '2026',
          selected: selected == CollectionFilter.year2026,
          onTap: onSelected == null
              ? null
              : () => onSelected!(CollectionFilter.year2026),
        ),
        const SizedBox(width: 7),
        _Filter(
          label: '2025',
          selected: selected == CollectionFilter.year2025,
          onTap: onSelected == null
              ? null
              : () => onSelected!(CollectionFilter.year2025),
        ),
        const Spacer(),
        Icon(Icons.tune, size: 18, color: Colors.grey[700]),
      ],
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({required this.label, this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: onTap == null ? 0 : 44),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.fast),
              decoration: BoxDecoration(
                color: selected ? Colors.black : const Color(0xFFF3F3F0),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF565752),
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionItem {
  const _CollectionItem(
    this.image,
    this.number,
    this.date,
    this.title, {
    this.publicId,
  });
  final String? image;
  final String? publicId;
  final String number;
  final String date;
  final String title;
}

class _StampTile extends StatelessWidget {
  const _StampTile({required this.item, this.onTap});
  final _CollectionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tem ${item.title}',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: <Widget>[
            Expanded(
              child: DecoratedBox(
                decoration: isProcessedStampImage(item.publicId)
                    ? const BoxDecoration()
                    : BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD9D9D3)),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x0C000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    children: <Widget>[
                      AspectRatio(
                        aspectRatio: 1,
                        child: SizedBox(
                          width: double.infinity,
                          child: MemoryPhoto(
                            asset: item.image,
                            publicId: item.publicId,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'TEM #${item.number}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 6,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            item.date,
                            style: const TextStyle(
                              fontSize: 6,
                              height: 1,
                              color: EditorialColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                height: 1.2,
                color: Color(0xFF555651),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(child: Divider(color: Color(0xFFC8C8C1))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: TechnicalText(
            'ĐƯỜNG RĂNG XÉ SỐ 01',
            fontSize: 8,
            color: Color(0xFFB7B7B0),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFC8C8C1))),
      ],
    );
  }
}

class _ArchiveSeal extends StatelessWidget {
  const _ArchiveSeal();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFF5F5F2)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.verified_outlined, size: 15),
                SizedBox(width: 7),
                TechnicalText(
                  'TẬP LƯU TRỮ CHÍNH THỨC',
                  color: EditorialColors.ink,
                  fontSize: 9,
                ),
              ],
            ),
            SizedBox(height: 14),
            TechnicalText(
              'TRANG 01 / 12 · MÃ PHÁT HÀNH: INK-2026-HL',
              fontSize: 9,
            ),
            SizedBox(height: 13),
            Text(
              'Toàn bộ bưu ảnh được đóng dấu lưu chiểu kỹ thuật số tại\nHà Nội',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF666762),
                fontSize: 11,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
