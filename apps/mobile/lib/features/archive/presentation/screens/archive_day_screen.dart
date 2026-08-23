import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';
import 'package:intl/intl.dart';

class ArchiveDayScreen extends ConsumerWidget {
  const ArchiveDayScreen({required this.date, super.key});

  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime parsedDate = DateTime.parse(date);
    final StampTimelineState state = ref.watch(stampTimelineControllerProvider);
    final List<Stamp> stamps = <Stamp>[...state.received, ...state.sent]
        .where((Stamp stamp) {
          return DateUtils.isSameDay(stamp.createdAt, parsedDate);
        })
        .toList(growable: false);

    return InkstampScaffold(
      title: DateFormat('dd MMMM yyyy', 'en').format(parsedDate),
      body: stamps.isEmpty
          ? const Center(child: Text('No stamps on this day.'))
          : GridView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.xl,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
              ),
              itemCount: stamps.length,
              itemBuilder: (context, index) {
                final Stamp stamp = stamps[index];
                return GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.archiveStamp(stamp.id));
                  },
                  child: StampArtwork(
                    seed: stamp.seed,
                    frameStyle: stamp.frameStyle,
                    paperTone: stamp.paperTone,
                  ),
                );
              },
            ),
    );
  }
}
