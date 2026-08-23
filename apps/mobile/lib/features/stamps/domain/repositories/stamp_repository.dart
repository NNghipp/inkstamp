import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';

abstract interface class StampRepository {
  Future<List<Stamp>> getReceived();

  Future<List<Stamp>> getSent();

  Future<Stamp> publish({
    required StampDraft draft,
    required List<String> recipientIds,
  });
}
