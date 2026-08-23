sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;
}

final class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure(super.message);
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure(super.message);
}

final class CameraFailure extends AppFailure {
  const CameraFailure(super.message);
}

final class ImageProcessingFailure extends AppFailure {
  const ImageProcessingFailure(super.message);
}

final class UploadFailure extends AppFailure {
  const UploadFailure(super.message);
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

final class FriendshipFailure extends AppFailure {
  const FriendshipFailure(super.message);
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure(super.message);
}

final class RateLimitFailure extends AppFailure {
  const RateLimitFailure(super.message);
}

final class ContentUnavailableFailure extends AppFailure {
  const ContentUnavailableFailure(super.message);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message);
}
