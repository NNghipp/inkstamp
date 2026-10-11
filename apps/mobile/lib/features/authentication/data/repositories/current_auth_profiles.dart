import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';

/// Discard queued auth/profile events that no longer describe the current UID.
/// In particular, an old profile failure must not sign out the new account.
Stream<AppUser?> currentAuthProfiles({
  required Stream<String?> authUids,
  required String? Function() currentUid,
  required Future<AppUser> Function(String uid) loadProfile,
}) {
  return authUids.asyncExpand((uid) async* {
    if (uid == null) {
      if (currentUid() == null) yield null;
      return;
    }
    try {
      final user = await loadProfile(uid);
      if (currentUid() == uid) yield user;
    } on Object {
      if (currentUid() == uid) rethrow;
    }
  });
}
