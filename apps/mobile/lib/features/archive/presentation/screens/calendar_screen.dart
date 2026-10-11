import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_motion.dart';
import 'package:inkstamp/core/images/stamp_image_format.dart';
import 'package:inkstamp/core/widgets/editorial_ui.dart';
import 'package:inkstamp/core/widgets/memory_photo.dart';
import 'package:inkstamp/core/widgets/motion_feedback.dart';
import 'package:inkstamp/features/archive/presentation/controllers/memory_view_controller.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({this.designPreview = false, super.key});
  final bool designPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = designPreview
        ? null
        : ref.watch(calendarSelectionProvider);
    final monthState = designPreview
        ? null
        : ref.watch(calendarMonthProvider(selection!.month));
    final memories = monthState?.isReloading == true
        ? const <Stamp>[]
        : monthState?.value ?? const <Stamp>[];
    final dayMemories = designPreview
        ? const <Stamp>[]
        : ref.watch(dayMemoriesProvider);
    return ColoredBox(
      color: EditorialColors.canvas,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          key: const PageStorageKey('calendar-scroll'),
          children: <Widget>[
            const EditorialHeader(
              title: 'lịch',
              trailing: EditorialAvatar(size: 32),
            ),
            const SizedBox(height: 18),
            _MonthHeading(
              month: selection?.month,
              count: memories.length,
              onPrevious: designPreview
                  ? null
                  : () => ref
                        .read(calendarSelectionProvider.notifier)
                        .moveMonth(-1),
              onNext: designPreview
                  ? null
                  : () => ref
                        .read(calendarSelectionProvider.notifier)
                        .moveMonth(1),
            ),
            const SizedBox(height: 20),
            if (monthState?.isLoading == true)
              const LinearProgressIndicator(minHeight: 2),
            if (monthState?.hasError == true)
              TextButton(
                onPressed: () =>
                    ref.invalidate(calendarMonthProvider(selection!.month)),
                child: const Text('Không thể tải lịch. Thử lại'),
              ),
            if (!designPreview)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Làm mới lịch',
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () =>
                      ref.invalidate(calendarMonthProvider(selection!.month)),
                ),
              ),
            AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.standard),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(.03 * (selection?.direction ?? 1), 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _CalendarGrid(
                key: ValueKey(selection?.month),
                month: selection?.month,
                selected: selection?.date,
                memories: memories,
                onSelected: designPreview
                    ? null
                    : ref.read(calendarSelectionProvider.notifier).select,
              ),
            ),
            const SizedBox(height: 25),
            const Divider(height: 1, color: EditorialColors.line),
            const SizedBox(height: 17),
            _DayHeading(
              date: selection?.date,
              count: dayMemories.length,
              designPreview: designPreview,
            ),
            const SizedBox(height: 28),
            if (!designPreview)
              SettleIn(
                identity: selection!.date ?? selection.month,
                child: Column(
                  children: <Widget>[
                    if (dayMemories.isEmpty)
                      SizedBox(
                        height: 120,
                        child: Center(
                          child: Text(
                            selection.date == null
                                ? 'Chọn một ngày để xem khoảnh khắc.'
                                : 'Chưa có khoảnh khắc trong ngày này.',
                          ),
                        ),
                      ),
                    for (final stamp in dayMemories)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 45),
                        child: _ArchiveEntry(
                          stampNumber: stamp.id,
                          publicId: stamp.cloudinaryThumbnailPublicId,
                          lens: '',
                          title: stamp.shortTitle.isEmpty
                              ? stamp.senderName
                              : stamp.shortTitle,
                          time: DateFormat(
                            'HH:mm',
                          ).format(stamp.createdAt.toLocal()),
                          note: '',
                          date: stamp.createdAt.toLocal(),
                          onTap: () => context.push(AppRoutes.stamp(stamp.id)),
                        ),
                      ),
                  ],
                ),
              )
            else ...const <Widget>[
              _ArchiveEntry(
                stampNumber: '142',
                image: EditorialAssets.tea,
                lens: '35MM · F/2.0 · 1/250S',
                title: 'Tách trà sáng',
                time: '07:45',
                note:
                    'Nắng sớm rọi chéo góc bàn gỗ sồi, chút ấm áp dịu dàng trước khi nhịp phố xá bắt đầu rộn rã.',
              ),
              SizedBox(height: 45),
              _ArchiveEntry(
                stampNumber: '143',
                image: EditorialAssets.street,
                lens: '50MM · F/1.4 · 1/500S',
                title: 'Góc phố quen',
                time: '16:20',
                note:
                    'Bóng lá rợp con ngõ nhỏ, gánh hàng rong lướt qua để lại vệt nắng chiều thơm mùi hoa sữa.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthHeading extends StatelessWidget {
  const _MonthHeading({
    this.month,
    this.count = 14,
    this.onPrevious,
    this.onNext,
  });
  final DateTime? month;
  final int count;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                month == null
                    ? 'Tháng 9, 2026'
                    : 'Tháng ${month!.month}, ${month!.year}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 2),
              TechnicalText(
                month == null
                    ? 'TẬP TEM KỶ NIỆM · KHO LƯU TRỮ · 14 TEM ĐÃ\nPHÁT HÀNH'
                    : 'TẬP TEM KỶ NIỆM · KHO LƯU TRỮ · $count TEM',
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: <Widget>[
              if (onPrevious != null)
                IconButton(
                  tooltip: 'Tháng trước',
                  onPressed: onPrevious,
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: EditorialColors.muted,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: EditorialColors.muted,
                ),
              if (onPrevious == null) const SizedBox(width: 18),
              if (onNext != null)
                IconButton(
                  tooltip: 'Tháng sau',
                  onPressed: onNext,
                  icon: const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: EditorialColors.muted,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: EditorialColors.muted,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    this.month,
    this.selected,
    this.memories = const [],
    this.onSelected,
    super.key,
  });
  final DateTime? month;
  final DateTime? selected;
  final List<Stamp> memories;
  final ValueChanged<DateTime>? onSelected;

  static const List<String> _weekdays = <String>[
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];
  static const List<int> _days = <int>[
    31,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    1,
    2,
    3,
    4,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: _weekdays
              .map(
                (String item) => Expanded(
                  child: TechnicalText(
                    item,
                    fontSize: 10,
                    letterSpacing: 0.3,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 56,
          ),
          itemCount: month == null
              ? _days.length
              : (((DateTime(month!.year, month!.month + 1, 0).day +
                                month!.weekday -
                                1) /
                            7)
                        .ceil() *
                    7),
          itemBuilder: (BuildContext context, int index) {
            if (month != null) {
              final date = DateTime(
                month!.year,
                month!.month,
                index - month!.weekday + 2,
              );
              final outside = date.month != month!.month;
              final items = memories
                  .where((s) => sameDay(s.createdAt, date))
                  .toList();
              final isSelected = selected != null && sameDay(date, selected!);
              return Semantics(
                selected: isSelected,
                button: true,
                label:
                    '${DateFormat('dd/MM/yyyy').format(date)}, ${items.length} khoảnh khắc',
                child: GestureDetector(
                  onTap: () => onSelected?.call(date),
                  child: AnimatedContainer(
                    duration: AppMotion.duration(context, AppMotion.fast),
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: EditorialColors.ink, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (items.isNotEmpty)
                          SizedBox(
                            width: 21,
                            height: 21,
                            child: MemoryPhoto(
                              publicId: items.first.cloudinaryThumbnailPublicId,
                            ),
                          ),
                        Text(
                          items.length > 1
                              ? '${date.day} · ${items.length}'
                              : '${date.day}',
                          style: TextStyle(
                            fontSize: items.isEmpty ? 12 : 7,
                            color: outside
                                ? const Color(0xFFD4D4CE)
                                : EditorialColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final int day = _days[index];
            final bool outside = index == 0 || index >= 31;
            if (day == 12 || day == 18 || day == 26) {
              return _StampDay(
                day: day,
                selected: day == 26,
                image: day == 18
                    ? EditorialAssets.cafeFriends
                    : EditorialAssets.tea,
                number: day == 12
                    ? '138'
                    : day == 18
                    ? '140'
                    : '142',
              );
            }
            return Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: outside
                      ? const Color(0xFFD4D4CE)
                      : EditorialColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StampDay extends StatelessWidget {
  const _StampDay({
    required this.day,
    required this.selected,
    required this.image,
    required this.number,
  });

  final int day;
  final bool selected;
  final String image;
  final String number;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: selected
            ? Border.all(color: EditorialColors.ink, width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 31,
              height: 21,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(image, fit: BoxFit.cover),
                  Positioned(
                    right: 1,
                    top: 1,
                    child: ColoredBox(
                      color: const Color(0xC0000000),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          '#$number',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('$day', style: const TextStyle(fontSize: 7)),
                const SizedBox(width: 8),
                const Text(
                  'HN',
                  style: TextStyle(fontSize: 5, color: EditorialColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeading extends StatelessWidget {
  const _DayHeading({this.date, this.count = 2, this.designPreview = true});
  final DateTime? date;
  final int count;
  final bool designPreview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          date == null
              ? (designPreview ? '26 Tháng 9, 2026' : 'Chọn ngày')
              : '${date!.day} Tháng ${date!.month}, ${date!.year}',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Text(
          '·  ${designPreview ? 2 : count} khoảnh khắc',
          style: const TextStyle(color: EditorialColors.muted, fontSize: 12),
        ),
        const Spacer(),
        if (designPreview) const TechnicalText('HÀ NỘI', fontSize: 9),
      ],
    );
  }
}

class _ArchiveEntry extends StatelessWidget {
  const _ArchiveEntry({
    required this.stampNumber,
    this.image,
    this.publicId,
    this.date,
    this.onTap,
    required this.lens,
    required this.title,
    required this.time,
    required this.note,
  });

  final String stampNumber;
  final String? image;
  final String? publicId;
  final DateTime? date;
  final VoidCallback? onTap;
  final String lens;
  final String title;
  final String time;
  final String note;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: isProcessedStampImage(publicId)
                  ? const BoxDecoration()
                  : BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFD9D9D3)),
                    ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
                          child: SizedBox.square(
                            dimension: 5,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: TechnicalText(
                            'INKSTAMP · TEM #$stampNumber · HN-026',
                            color: EditorialColors.ink,
                            fontSize: 9,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TechnicalText(
                          date == null
                              ? '26.09.2026 · HÀ\nNỘI'
                              : DateFormat('dd.MM.yyyy').format(date!),
                          fontSize: 9,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: EditorialColors.line),
                    const SizedBox(height: 14),
                    AspectRatio(
                      aspectRatio: 1,
                      child: MemoryPhoto(asset: image, publicId: publicId),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        const TechnicalText(
                          'VẬT THỂ TEM PHÁT HÀNH',
                          fontSize: 9,
                        ),
                        const Spacer(),
                        TechnicalText(lens, fontSize: 9, letterSpacing: 0.2),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 27),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * .5,
                ),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TechnicalText(time, fontSize: 10, letterSpacing: 0.2),
              const Spacer(),
              const TechnicalText('HÀ NỘI', fontSize: 9),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(
              color: Color(0xFF62625D),
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
