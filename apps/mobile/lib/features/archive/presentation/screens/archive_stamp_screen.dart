import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';
import 'package:intl/intl.dart';

class ArchiveStampScreen extends ConsumerWidget {
  const ArchiveStampScreen({required this.stampId, super.key});

  final String stampId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(stampTimelineControllerProvider);
    final Stamp? stamp = ref
        .read(stampTimelineControllerProvider.notifier)
        .findById(stampId);

    return InkstampScaffold(
      title: 'Archive',
      body: stamp == null
          ? const Center(child: Text('This stamp is no longer available.'))
          : Column(
              children: <Widget>[
                const Spacer(),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.82,
                  child: StampArtwork(
                    seed: stamp.seed,
                    frameStyle: stamp.frameStyle,
                    paperTone: stamp.paperTone,
                    publicId: stamp.cloudinaryPublicId,
                    capturedAt: stamp.captureTime,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  stamp.isSentByMe ? 'Sent by you' : 'From ${stamp.senderName}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DateFormat(
                    'HH:mm · dd/MM/yyyy',
                  ).format(stamp.captureTime.toLocal()),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (stamp.shortTitle.isNotEmpty) Text(stamp.shortTitle),
                if (stamp.locationLabel != null) Text(stamp.locationLabel!),
                if (stamp.reaction != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    stamp.reaction!.emoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                ],
                const Spacer(),
              ],
            ),
    );
  }
}
