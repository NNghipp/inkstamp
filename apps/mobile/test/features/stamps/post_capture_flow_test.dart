import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/camera/domain/repositories/camera_repository.dart';
import 'package:inkstamp/features/camera/presentation/controllers/camera_controller.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_upload_repository.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp_draft.dart';
import 'package:inkstamp/features/stamps/domain/repositories/media_upload_repository.dart';
import 'package:inkstamp/features/stamps/domain/repositories/stamp_repository.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/post_capture_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';

import '../camera/camera_controller_test.dart' show FakeImageProcessor;

const flowFriends = <InkstampFriend>[
  InkstampFriend(
    id: 'lan',
    username: 'lan',
    displayName: 'Lan',
    status: FriendStatus.accepted,
  ),
  InkstampFriend(
    id: 'minh',
    username: 'minh',
    displayName: 'Minh',
    status: FriendStatus.accepted,
  ),
];

class FlowFriendsController extends FriendsController {
  @override
  FriendsState build() => const FriendsState(friends: flowFriends);
}

class FlowStampRepository implements StampRepository {
  int calls = 0;
  int failures = 0;
  Completer<void>? gate;
  final drafts = <StampDraft>[];
  final audiences = <List<String>>[];
  List<Stamp> received = [];
  List<Stamp> sent = [];
  int pageCalls = 0;
  int readCalls = 0;
  int pageFailures = 0;
  bool readFails = false;
  int monthFailures = 0;
  Completer<void>? detailGate;
  bool detailFails = false;
  final unavailable = <String>{};
  final ranges = <(DateTime, DateTime)>[];
  int historyReads = 0;
  @override
  Future<StampPage> fetchReceivedPage({
    StampCursor? after,
    int limit = 25,
  }) async {
    pageCalls++;
    if (pageFailures-- > 0) throw StateError('offline');
    return pageStamps(
      received.where((s) => !unavailable.contains(s.id)).toList(),
      after,
      limit,
    );
  }

  @override
  Future<List<Stamp>> fetchMonth(DateTime start, DateTime end) async {
    ranges.add((start, end));
    if (monthFailures-- > 0) throw StateError('offline');
    return [...received, ...sent]
        .where(
          (s) =>
              !unavailable.contains(s.id) &&
              !s.createdAt.isBefore(start) &&
              s.createdAt.isBefore(end),
        )
        .toList()
      ..sort(compareStamps);
  }

  @override
  Future<Stamp?> getById(String id) async {
    if (detailGate != null) await detailGate!.future;
    if (detailFails) throw StateError('offline');
    if (unavailable.contains(id)) return null;
    for (final s in [...received, ...sent]) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<void> markDeliveryRead(String id) async {
    readCalls++;
    if (readFails) throw StateError('offline');
    received = received
        .map((s) => s.id == id ? s.copyWith(isSeen: true) : s)
        .toList();
  }

  @override
  Future<List<Stamp>> getReceived() async {
    historyReads++;
    return received;
  }

  @override
  Future<List<Stamp>> getSent() async {
    historyReads++;
    return sent;
  }

  @override
  Future<Stamp> publish({
    required StampDraft draft,
    required List<String> recipientIds,
  }) async {
    calls++;
    drafts.add(draft);
    audiences.add(List.of(recipientIds));
    if (gate != null) await gate!.future;
    if (failures-- > 0) throw StateError('Lost network response');
    return flowStamp('published', DateTime(2026, 9, 26));
  }
}

Stamp flowStamp(String id, DateTime date, {String? caption, bool own = true}) =>
    Stamp(
      id: id,
      senderId: 'lan',
      senderName: 'Lan',
      createdAt: date,
      seed: 1,
      frameStyle: StampFrameStyle.classic,
      paperTone: PaperTone.cream,
      isSentByMe: own,
      caption: caption,
    );

class FlowUploads implements MediaUploadRepository {
  int photos = 0;
  int thumbs = 0;
  int thumbnailFailures = 0;
  final deleted = <String>[];
  @override
  Future<String> uploadStamp(String path) async => 'photo-${++photos}';
  @override
  Future<String> uploadThumbnail(String path) async {
    thumbs++;
    if (thumbnailFailures-- > 0) throw const MediaUploadException('offline');
    return 'thumbnail-$thumbs';
  }

  @override
  Future<void> delete(String id) async => deleted.add(id);
}

ProviderContainer flowContainer(
  FlowStampRepository repository,
  FlowUploads uploads, {
  FakeImageProcessor? processor,
  CameraRepository? camera,
}) => ProviderContainer(
  overrides: [
    stampRepositoryProvider.overrideWithValue(repository),
    mediaUploadRepositoryProvider.overrideWithValue(uploads),
    friendsControllerProvider.overrideWith(FlowFriendsController.new),
    imageProcessingRepositoryProvider.overrideWithValue(
      processor ?? FakeImageProcessor(),
    ),
    if (camera != null) cameraRepositoryProvider.overrideWithValue(camera),
  ],
);

void seedDraft(ProviderContainer container) => container
    .read(stampComposerControllerProvider.notifier)
    .capture(
      localImagePath: 'processed.jpg',
      localThumbnailPath: 'thumbnail.jpg',
    );

void main() {
  test(
    'ALL default; custom multi-select; empty remains custom; ALL clears',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final composer = container.read(stampComposerControllerProvider.notifier);
      expect(
        container.read(stampComposerControllerProvider).audience,
        AudienceMode.allFriends,
      );
      composer.toggleRecipient('lan');
      expect(
        container.read(stampComposerControllerProvider).audience,
        AudienceMode.selected,
      );
      composer.toggleRecipient('minh');
      expect(
        container.read(stampComposerControllerProvider).selectedRecipientIds,
        {'lan', 'minh'},
      );
      composer.toggleRecipient('lan');
      composer.toggleRecipient('minh');
      expect(
        container.read(stampComposerControllerProvider).audience,
        AudienceMode.selected,
      );
      expect(
        container.read(stampComposerControllerProvider).selectedRecipientIds,
        isEmpty,
      );
      composer.toggleRecipient('lan');
      composer.setAudience(AudienceMode.allFriends);
      expect(
        container.read(stampComposerControllerProvider).selectedRecipientIds,
        isEmpty,
      );
    },
  );

  test('empty custom cannot publish and makes no upload calls', () async {
    final repo = FlowStampRepository();
    final uploads = FlowUploads();
    final container = flowContainer(repo, uploads);
    addTearDown(container.dispose);
    final subscription = container.listen(
      postCaptureControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    seedDraft(container);
    container
        .read(stampComposerControllerProvider.notifier)
        .setAudience(AudienceMode.selected);
    expect(
      await container.read(postCaptureControllerProvider.notifier).send(),
      isFalse,
    );
    expect(uploads.photos, 0);
    expect(repo.calls, 0);
  });

  test(
    'send starts once, locks discard, exposes loading, cleans only on success finish',
    () async {
      final repo = FlowStampRepository()..gate = Completer<void>();
      final uploads = FlowUploads();
      final processor = FakeImageProcessor();
      final container = flowContainer(repo, uploads, processor: processor);
      addTearDown(container.dispose);
      final subscription = container.listen(
        postCaptureControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      seedDraft(container);
      final controller = container.read(postCaptureControllerProvider.notifier);
      final sending = controller.send();
      expect(
        container.read(postCaptureControllerProvider),
        PostCapturePhase.sending,
      );
      expect(await controller.send(), isFalse);
      expect(await controller.discard(), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls, 1);
      expect(processor.deletedPaths, isEmpty);
      repo.gate!.complete();
      expect(await sending, isTrue);
      expect(
        container.read(postCaptureControllerProvider),
        PostCapturePhase.sent,
      );
      expect(repo.audiences.single, ['lan', 'minh']);
      expect(processor.deletedPaths, isEmpty);
      await controller.finish();
      expect(
        processor.deletedPaths,
        containsAll(['processed.jpg', 'thumbnail.jpg']),
      );
      expect(
        container.read(stampComposerControllerProvider).localImagePath,
        isNull,
      );
    },
  );

  test(
    'ambiguous publish keeps draft and retries same media/audience without recapture',
    () async {
      final repo = FlowStampRepository()..failures = 1;
      final uploads = FlowUploads();
      final processor = FakeImageProcessor();
      final container = flowContainer(repo, uploads, processor: processor);
      addTearDown(container.dispose);
      final subscription = container.listen(
        postCaptureControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      seedDraft(container);
      final controller = container.read(postCaptureControllerProvider.notifier);
      expect(await controller.send(), isFalse);
      expect(
        container.read(postCaptureControllerProvider),
        PostCapturePhase.failed,
      );
      expect(
        container.read(stampComposerControllerProvider).localImagePath,
        'processed.jpg',
      );
      expect(processor.deletedPaths, isEmpty);
      expect(uploads.deleted, isEmpty);
      expect(await controller.send(), isTrue);
      expect(uploads.photos, 1);
      expect(uploads.thumbs, 1);
      expect(
        repo.drafts[0].cloudinaryPublicId,
        repo.drafts[1].cloudinaryPublicId,
      );
      expect(
        repo.drafts[0].cloudinaryThumbnailPublicId,
        repo.drafts[1].cloudinaryThumbnailPublicId,
      );
      expect(repo.audiences[0], repo.audiences[1]);
      expect(container.read(stampTimelineControllerProvider).sent.length, 1);
    },
  );

  test(
    'thumbnail retry reuses photo; discard cleans local files and partial upload',
    () async {
      final repo = FlowStampRepository();
      final uploads = FlowUploads()..thumbnailFailures = 1;
      final processor = FakeImageProcessor();
      final container = flowContainer(repo, uploads, processor: processor);
      addTearDown(container.dispose);
      final subscription = container.listen(
        postCaptureControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      seedDraft(container);
      final controller = container.read(postCaptureControllerProvider.notifier);
      expect(await controller.send(), isFalse);
      expect(repo.calls, 0);
      expect(await controller.discard(), isTrue);
      expect(uploads.deleted, ['photo-1']);
      expect(
        processor.deletedPaths,
        containsAll(['processed.jpg', 'thumbnail.jpg']),
      );
    },
  );
}
