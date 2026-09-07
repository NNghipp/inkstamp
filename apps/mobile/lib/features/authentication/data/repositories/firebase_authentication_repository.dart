import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:inkstamp/features/authentication/domain/entities/app_user.dart';
import 'package:inkstamp/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthenticationRepository implements AuthenticationRepository {
  FirebaseAuthenticationRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  Future<void>? _googleInitialization;

  // ---------------------------------------------------------------------------
  // Sign-in
  // ---------------------------------------------------------------------------

  @override
  Future<AppUser> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    _googleInitialization ??= googleSignIn.initialize();
    await _googleInitialization;

    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    return _userFromFirebase(userCredential.user);
  }

  @override
  Future<AppUser> signInWithApple() async {
    final AuthorizationCredentialAppleID appleCredential =
        await SignInWithApple.getAppleIDCredential(
      scopes: <AppleIDAuthorizationScopes>[
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final OAuthCredential credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    return _userFromFirebase(userCredential.user);
  }

  // ---------------------------------------------------------------------------
  // Username availability
  // ---------------------------------------------------------------------------

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final String normalized = username.trim().toLowerCase();
    if (normalized.length < 3 || normalized.length > 20) {
      return false;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.doc('usernames/$normalized').get();
    if (!snapshot.exists) {
      return true;
    }

    // If the current user already owns this username, it is still "available"
    // for them.
    final String? ownerId = snapshot.data()?['userId'] as String?;
    return ownerId == _auth.currentUser?.uid;
  }

  // ---------------------------------------------------------------------------
  // Profile update (reserves username via Cloud Function)
  // ---------------------------------------------------------------------------

  @override
  Future<AppUser> updateProfile({
    required AppUser user,
    required String username,
    required String displayName,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable('reserveUsername');
    await callable.call<dynamic>(<String, String>{
      'username': username,
      'displayName': displayName,
    });

    return user.copyWith(
      username: username.toLowerCase(),
      displayName: displayName,
    );
  }

  // ---------------------------------------------------------------------------
  // Sign-out & account deletion
  // ---------------------------------------------------------------------------

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  // ---------------------------------------------------------------------------
  // Auth state stream
  // ---------------------------------------------------------------------------

  /// A convenience stream exposing Firebase Auth state changes as [AppUser?].
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((User? firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      return _loadUserProfile(firebaseUser.uid);
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<AppUser> _userFromFirebase(User? firebaseUser) async {
    if (firebaseUser == null) {
      throw Exception('Firebase user is null after sign-in.');
    }
    return _loadUserProfile(firebaseUser.uid);
  }

  Future<AppUser> _loadUserProfile(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.doc('users/$uid').get();

    if (snapshot.exists) {
      final Map<String, dynamic> data = snapshot.data()!;
      return AppUser(
        id: uid,
        username: (data['username'] as String?) ?? '',
        displayName: (data['displayName'] as String?) ?? '',
        onboardingComplete: (data['onboardingComplete'] as bool?) ?? false,
      );
    }

    // New user – no Firestore profile yet.
    return AppUser(
      id: uid,
      username: '',
      displayName: '',
      onboardingComplete: false,
    );
  }
}
