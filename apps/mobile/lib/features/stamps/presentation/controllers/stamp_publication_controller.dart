import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';

/// Cache invalidation signal; does not initialize or load the History timeline.
final stampPublicationProvider =
    NotifierProvider<StampPublicationController, Stamp?>(
      StampPublicationController.new,
    );

class StampPublicationController extends Notifier<Stamp?> {
  @override
  Stamp? build() => null;
  void published(Stamp stamp) => state = stamp;
}
