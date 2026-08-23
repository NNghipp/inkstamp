import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';
import 'package:intl/intl.dart';

enum ArchiveFilter { received, sent }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  ArchiveFilter _filter = ArchiveFilter.received;

  @override
  Widget build(BuildContext context) {
    final StampTimelineState state = ref.watch(stampTimelineControllerProvider);
    final DateTime month = DateTime.now();
    final List<Stamp> stamps = _filter == ArchiveFilter.received
        ? state.received
        : state.sent;
    final int daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final int leadingSpaces = DateTime(month.year, month.month).weekday - 1;

    return InkstampScaffold(
      title: 'Calendar',
      body: ListView(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy', 'en').format(month),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              SegmentedButton<ArchiveFilter>(
                segments: const <ButtonSegment<ArchiveFilter>>[
                  ButtonSegment<ArchiveFilter>(
                    value: ArchiveFilter.received,
                    label: Text('Received'),
                  ),
                  ButtonSegment<ArchiveFilter>(
                    value: ArchiveFilter.sent,
                    label: Text('Sent'),
                  ),
                ],
                selected: <ArchiveFilter>{_filter},
                onSelectionChanged: (Set<ArchiveFilter> value) {
                  setState(() => _filter = value.first);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            children: <Widget>[
              _Weekday('T2'),
              _Weekday('T3'),
              _Weekday('T4'),
              _Weekday('T5'),
              _Weekday('T6'),
              _Weekday('T7'),
              _Weekday('CN'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
              childAspectRatio: 0.72,
            ),
            itemCount: leadingSpaces + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingSpaces) {
                return const SizedBox.shrink();
              }
              final int day = index - leadingSpaces + 1;
              final List<Stamp> dayStamps = stamps
                  .where((Stamp stamp) {
                    return stamp.createdAt.year == month.year &&
                        stamp.createdAt.month == month.month &&
                        stamp.createdAt.day == day;
                  })
                  .toList(growable: false);
              return _CalendarDay(
                day: day,
                stamp: dayStamps.firstOrNull,
                onTap: dayStamps.isEmpty
                    ? null
                    : () {
                        final String date = DateFormat(
                          'yyyy-MM-dd',
                        ).format(DateTime(month.year, month.month, day));
                        context.push(AppRoutes.archiveDay(date));
                      },
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Recently', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 152,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stamps.length,
              separatorBuilder: (context, index) {
                return const SizedBox(width: AppSpacing.sm);
              },
              itemBuilder: (context, index) {
                final Stamp stamp = stamps[index];
                return GestureDetector(
                  onTap: () => context.push(AppRoutes.archiveStamp(stamp.id)),
                  child: SizedBox(
                    width: 140,
                    child: StampArtwork(
                      seed: stamp.seed,
                      frameStyle: stamp.frameStyle,
                      paperTone: stamp.paperTone,
                      showShadow: false,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.charcoal,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.stamp,
    required this.onTap,
  });

  final int day;
  final Stamp? stamp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: <Widget>[
          Text(
            '$day',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          if (stamp != null)
            Expanded(
              child: StampArtwork(
                seed: stamp!.seed,
                frameStyle: stamp!.frameStyle,
                paperTone: stamp!.paperTone,
                showShadow: false,
              ),
            )
          else
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
