import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import 'firestore_refs.dart';

/// Raised for anything the sign-in / sign-up screens should show inline.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({required FirebaseAuth auth, required FirebaseFirestore db})
      : _auth = auth,
        _refs = Refs(db);


  final FirebaseAuth _auth;
  final Refs _refs;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Live view of `users/{uid}`, so a role change in the console reaches the
  /// running app without a restart.
  Stream<AppUser?> watchAppUser(String uid) =>
      _refs.user(uid).snapshots().map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(displayName.trim());
      // Every new account starts as a learner. Admin is granted only by editing
      // this field in the Firebase console; the rules forbid self-promotion.
      await _refs.user(uid).set({
        'email': email.trim(),
        'displayName': displayName.trim(),
        'role': UserRole.learner.name,
        'soundEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  /// Signs in with Google, and returns false if the learner backed out of the
  /// account picker — a cancel is a normal outcome, not an error to show.
  ///
  /// Two routes, because the two platforms hand Firebase a credential in
  /// different ways: on the web `google_sign_in` deliberately has no
  /// `authenticate()` (the browser SDK wants its own rendered button), so the
  /// popup flow built into `firebase_auth` is the supported path there. On
  /// Android the native picker gives us an ID token to trade for a Firebase
  /// credential.
  Future<bool> signInWithGoogle() async {
    try {
      final UserCredential cred;
      if (kIsWeb) {
        try {
          cred = await _auth.signInWithPopup(GoogleAuthProvider());
        } on FirebaseAuthException catch (e) {
          // Some browsers (and most in-app webviews) refuse the popup outright.
          // The redirect flow navigates away and comes back signed in, so this
          // future never completes — `authStateChanges` reports the result, and
          // `appUserProvider` backfills the profile doc on the way through.
          if (e.code == 'popup-blocked' ||
              e.code == 'operation-not-supported-in-this-environment') {
            await _auth.signInWithRedirect(GoogleAuthProvider());
            return true;
          }
          rethrow;
        }
      } else {
        await _initGoogleSignIn();
        final account =
            await GoogleSignIn.instance.authenticate(scopeHint: const ['email']);
        final idToken = account.authentication.idToken;
        if (idToken == null) {
          throw const AuthFailure(
            'Google did not return a sign-in token. Please try again.',
          );
        }
        cred = await _auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      }

      final user = cred.user;
      // First Google sign-in on this project has no `users/{uid}` doc yet.
      // Writing it here rather than leaving it to `appUserProvider` means the
      // dashboard has a name and role to read the moment the router redirects.
      if (user != null) await ensureProfile(user);
      return true;
    } on FirebaseAuthException catch (e) {
      // The learner closing the popup is a cancel, not a failure.
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'user-cancelled') {
        return false;
      }
      throw AuthFailure(_message(e));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      throw AuthFailure(_googleMessage(e));
    }
  }

  /// `initialize()` is documented as a once-per-process call, so the flag keeps
  /// a second tap on the button from repeating it.
  Future<void> _initGoogleSignIn() async {
    if (_googleReady) return;
    // No client IDs passed on purpose: android/app/google-services.json already
    // carries the web OAuth client entry the plugin needs, and hard-coding it
    // here would drift from whatever the Firebase console hands out next.
    await GoogleSignIn.instance.initialize();
    _googleReady = true;
  }

  bool _googleReady = false;

  /// Backfills the profile document for an account that has an Auth record but
  /// no Firestore doc (e.g. one created directly in the console).
  Future<void> ensureProfile(User user) async {
    final ref = _refs.user(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'email': user.email ?? '',
      'displayName': user.displayName ?? (user.email?.split('@').first ?? 'Learner'),
      'role': UserRole.learner.name,
      'soundEnabled': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSoundEnabled(String uid, bool enabled) =>
      _refs.user(uid).set({'soundEnabled': enabled}, SetOptions(merge: true));

  Future<void> signOut() async {
    // Clearing the native credential state too, so the next sign-in offers the
    // account picker instead of silently re-using the last Google account.
    // Nothing to clear on web, and a failure here must not block the Firebase
    // sign-out that actually logs the learner out.
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  String _message(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => 'That email address doesn\'t look right.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Email or password is incorrect.',
        'email-already-in-use' => 'An account already exists for that email.',
        'weak-password' => 'Pick a password with at least 6 characters.',
        'operation-not-allowed' =>
          'Email sign-in isn\'t enabled on this Firebase project yet.',
        'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
        'network-request-failed' => 'No connection. Check your network and retry.',
        _ => e.message ?? 'Something went wrong. Please try again.',
      };

  String _googleMessage(GoogleSignInException e) => switch (e.code) {
        // Android's Credential Manager reports some setup problems as a plain
        // cancel, so this wording covers both readings of the same code.
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted =>
          'Google sign-in didn\'t finish. Please try again.',
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          'Google sign-in isn\'t set up for this build yet. '
              'See docs/01-firebase-setup.md.',
        GoogleSignInExceptionCode.uiUnavailable =>
          'Google sign-in couldn\'t open right now. Please try again.',
        GoogleSignInExceptionCode.userMismatch =>
          'That\'s a different Google account than the one already signed in.',
        GoogleSignInExceptionCode.unknownError =>
          e.description ?? 'Google sign-in failed. Please try again.',
      };
}
