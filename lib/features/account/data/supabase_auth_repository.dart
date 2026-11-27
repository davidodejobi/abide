import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';
import 'native_sign_in.dart';

/// Maps a Supabase / transport error onto what the UI can show. [verifying] is
/// true for the code step, where any server rejection means a bad or expired
/// code.
AuthFailure mapAuthError(Object e, {bool verifying = false}) {
  if (e is AuthFailure) return e;
  if (e is AuthRetryableFetchException ||
      e is SocketException ||
      e is TimeoutException) {
    return const AuthFailure(AuthFailureKind.network);
  }
  if (e is AuthException) {
    final code = e.code ?? '';
    if (code == 'otp_expired' || (verifying && e.statusCode != '429')) {
      return const AuthFailure(AuthFailureKind.wrongCode);
    }
    if (code == 'email_address_invalid' ||
        code == 'validation_failed' ||
        e.message.toLowerCase().contains('invalid') &&
            e.message.toLowerCase().contains('email')) {
      return const AuthFailure(AuthFailureKind.invalidEmail);
    }
  }
  return const AuthFailure(AuthFailureKind.unknown);
}

/// Real accounts on Supabase Auth. An anonymous user is converted in place
/// (same user id, so synced rows stay), and only when the email or identity
/// already belongs to someone does it switch to that existing user.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._auth, {
    Future<IdCredential> Function()? apple,
    Future<IdCredential> Function()? google,
  })  : _apple = apple,
        _google = google;

  /// Production wiring: native Apple / Google where the build supports them.
  factory SupabaseAuthRepository.native(GoTrueClient auth) =>
      SupabaseAuthRepository(
        auth,
        apple: appleSignInSupported ? appleCredential : null,
        google: googleSignInSupported ? googleCredential : null,
      );

  final GoTrueClient _auth;
  final Future<IdCredential> Function()? _apple;
  final Future<IdCredential> Function()? _google;

  /// True when the pending code belongs to an existing account (sign-in), false
  /// when it confirms an email change on the anonymous user.
  bool _existingAccount = false;
  Future<void>? _ensuring;

  @override
  bool get appleAvailable => _apple != null;

  @override
  bool get googleAvailable => _google != null;

  static AuthAccount accountOf(User? user) {
    if (user == null || user.isAnonymous) return const AuthAccount();
    final email = user.email;
    final provider = user.appMetadata['provider'] as String?;
    return AuthAccount(
      email: email == null || email.isEmpty ? null : email,
      provider: provider ?? 'email',
    );
  }

  @override
  Future<AuthAccount> ensureAnonymousSession() async {
    if (_auth.currentSession == null) {
      // One in-flight sign-in shared with sync, so two callers never create
      // two anonymous users.
      await (_ensuring ??= _auth
          .signInAnonymously()
          .timeout(const Duration(seconds: 10))
          .then<void>((_) {})
          .whenComplete(() => _ensuring = null));
    }
    return accountOf(_auth.currentUser);
  }

  @override
  Stream<AuthAccount> watchAccount() async* {
    yield accountOf(_auth.currentUser);
    yield* _auth.onAuthStateChange.map((s) => accountOf(s.session?.user));
  }

  @override
  Future<void> sendEmailCode(String email) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.isAnonymous) {
        try {
          await _auth.updateUser(UserAttributes(email: email));
          _existingAccount = false;
          return;
        } on AuthException catch (e) {
          // Already registered: this person is signing in on a new phone.
          if (e.code != 'email_exists') rethrow;
        }
      }
      await _auth.signInWithOtp(email: email, shouldCreateUser: false);
      _existingAccount = true;
    } catch (e) {
      throw mapAuthError(e);
    }
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    try {
      await _auth.verifyOTP(
        email: email,
        token: code,
        type: _existingAccount ? OtpType.email : OtpType.emailChange,
      );
    } catch (e) {
      throw mapAuthError(e, verifying: true);
    }
  }

  @override
  Future<void> signInWithApple() => _withIdToken(OAuthProvider.apple, _apple);

  @override
  Future<void> signInWithGoogle() =>
      _withIdToken(OAuthProvider.google, _google);

  Future<void> _withIdToken(
    OAuthProvider provider,
    Future<IdCredential> Function()? credential,
  ) async {
    if (credential == null) throw const AuthFailure(AuthFailureKind.unknown);
    try {
      final c = await credential();
      final user = _auth.currentUser;
      if (user != null && user.isAnonymous) {
        try {
          await _auth.linkIdentityWithIdToken(
              provider: provider, idToken: c.idToken, nonce: c.nonce);
          return;
        } on AuthException catch (e) {
          // That identity already belongs to another user: switch to them.
          if (e.code != 'identity_already_exists' && e.code != 'email_exists') {
            rethrow;
          }
        }
      }
      await _auth.signInWithIdToken(
          provider: provider, idToken: c.idToken, nonce: c.nonce);
    } catch (e) {
      throw mapAuthError(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Local data stays; the next sync re-keys onto this fresh anonymous user.
    await ensureAnonymousSession();
  }
}
