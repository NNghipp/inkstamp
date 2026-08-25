import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/features/authentication/data/repositories/in_memory_authentication_repository.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';

/// The sole composition point for the authentication repository.
///
/// Phase 2 replaces this implementation with the Firebase adapter without
/// changing presentation or domain code.
final Provider<AuthenticationRepository> authenticationRepositoryProvider =
    Provider<AuthenticationRepository>(
      (Ref ref) => InMemoryAuthenticationRepository(),
    );
