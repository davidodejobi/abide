import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/account/data/native_sign_in.dart';
import 'package:openbaptisthymnal/features/account/data/supabase_auth_repository.dart';
import 'package:openbaptisthymnal/features/account/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user({
  bool anon = true,
  String? email,
  String provider = 'anonymous',
  List<UserIdentity>? identities,
}) =>
    User(
      id: 'u1',
      identities: identities,
      appMetadata: {'provider': provider},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
      email: email,
      isAnonymous: anon,
    );

/// The seam is GoTrueClient: only the calls the repository makes are faked.
class _FakeAuth implements GoTrueClient {
  User? user = _user();
  final calls = <String>[];
  Object? updateError;
  Object? linkError;
  Object? verifyError;

  @override
  User? get currentUser => user;

  /// ensureAnonymousSession signs in when there is no session.
  bool hasSession = true;

  @override
  Session? get currentSession => hasSession
      ? Session(accessToken: 't', tokenType: 'bearer', user: _user())
      : null;

  @override
  Future<AuthResponse> signInAnonymously(
      {Map<String, dynamic>? data, String? captchaToken}) async {
    calls.add('signInAnonymously');
    hasSession = true;
    return AuthResponse();
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    calls.add('signOut');
  }

  @override
  Future<UserResponse> updateUser(UserAttributes attributes,
      {String? emailRedirectTo, String? nonce}) async {
    calls.add('updateUser');
    if (updateError != null) throw updateError!;
    return UserResponse.fromJson(const {'id': 'u1'});
  }

  @override
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    String? emailRedirectTo,
    bool? shouldCreateUser,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    calls.add('signInWithOtp shouldCreateUser=$shouldCreateUser');
  }

  @override
  Future<AuthResponse> verifyOTP({
    String? email,
    String? phone,
    String? token,
    required OtpType type,
    String? redirectTo,
    String? captchaToken,
    String? tokenHash,
  }) async {
    calls.add('verifyOTP ${type.name}');
    if (verifyError != null) throw verifyError!;
    return AuthResponse();
  }

  @override
  Future<AuthResponse> linkIdentityWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
    String? captchaToken,
  }) async {
    calls.add('link ${provider.name}');
    if (linkError != null) throw linkError!;
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
    String? captchaToken,
  }) async {
    calls.add('signInWithIdToken ${provider.name}');
    return AuthResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<IdCredential> _cred() async => (idToken: 't', nonce: 'n');

Future<AuthFailureKind?> _kind(Future<void> Function() f) async {
  try {
    await f();
  } on AuthFailure catch (e) {
    return e.kind;
  }
  return null;
}

void main() {
  group('mapAuthError', () {
    test('transport problems are network', () {
      for (final e in [
        AuthRetryableFetchException(message: 'x'),
        const SocketException('x'),
        TimeoutException('x'),
      ]) {
        expect(mapAuthError(e).kind, AuthFailureKind.network);
      }
    });

    test('bad email on send', () {
      expect(
          mapAuthError(AuthApiException('bad',
                  statusCode: '400', code: 'email_address_invalid'))
              .kind,
          AuthFailureKind.invalidEmail);
      expect(
          mapAuthError(AuthException('Unable to validate email address: invalid format'))
              .kind,
          AuthFailureKind.invalidEmail);
    });

    test('a rejected code on verify is wrongCode, a rate limit is not', () {
      expect(
          mapAuthError(
                  AuthApiException('expired',
                      statusCode: '403', code: 'otp_expired'),
                  verifying: true)
              .kind,
          AuthFailureKind.wrongCode);
      expect(
          mapAuthError(
                  AuthApiException('Token has expired or is invalid',
                      statusCode: '403'),
                  verifying: true)
              .kind,
          AuthFailureKind.wrongCode);
      expect(
          mapAuthError(AuthApiException('bad', statusCode: '403', code: 'invalid_otp'),
                  verifying: true)
              .kind,
          AuthFailureKind.wrongCode);
      // Unrelated rejections and a missing session are not a wrong code.
      expect(
          mapAuthError(AuthApiException('bad', statusCode: '403'),
                  verifying: true)
              .kind,
          AuthFailureKind.unknown);
      expect(mapAuthError(AuthSessionMissingException(), verifying: true).kind,
          AuthFailureKind.unknown);
      expect(mapAuthError(PlatformException(code: 'x')).kind,
          AuthFailureKind.unknown);
      expect(
          mapAuthError(AuthApiException('slow down', statusCode: '429'),
                  verifying: true)
              .kind,
          AuthFailureKind.unknown);
    });

    test('anything else is unknown, and our own failures pass through', () {
      expect(mapAuthError(StateError('x')).kind, AuthFailureKind.unknown);
      expect(mapAuthError(const AuthFailure(AuthFailureKind.cancelled)).kind,
          AuthFailureKind.cancelled);
    });
  });

  group('accountOf', () {
    test('anonymous is not saved; email and provider users are', () {
      expect(SupabaseAuthRepository.accountOf(_user()).isSaved, isFalse);
      expect(SupabaseAuthRepository.accountOf(null).isSaved, isFalse);
      final a = SupabaseAuthRepository.accountOf(
          _user(anon: false, email: 'a@b.co', provider: 'email'));
      expect(a.isSaved, isTrue);
      expect(a.email, 'a@b.co');
      final g = SupabaseAuthRepository.accountOf(
          _user(anon: false, provider: 'google'));
      expect(g.isSaved, isTrue);
      expect(g.provider, 'google');
    });
  });

  test('provider label comes from the newest identity', () {
    UserIdentity id(String p, String at) => UserIdentity(
        id: p,
        userId: 'u1',
        identityData: const {},
        identityId: p,
        provider: p,
        createdAt: at,
        lastSignInAt: at);
    final a = SupabaseAuthRepository.accountOf(_user(
      anon: false,
      email: 'a@b.co',
      provider: 'email',
      identities: [id('email', '2026-01-01'), id('google', '2026-02-01')],
    ));
    expect(a.provider, 'google');
  });

  group('email flow', () {
    test('a missing session is started before the email step', () async {
      final auth = _FakeAuth()..hasSession = false;
      await SupabaseAuthRepository(auth).sendEmailCode('a@b.co');
      expect(auth.calls.first, 'signInAnonymously');
    });

    test('sign out only ends the session', () async {
      final auth = _FakeAuth();
      var google = 0;
      await SupabaseAuthRepository(auth, googleSignOut: () async {
        google++;
        throw StateError('ignored');
      }).signOut();
      expect(auth.calls, ['signOut']);
      expect(google, 1);
    });

    test('anonymous user: updateUser then emailChange keeps the user id',
        () async {
      final auth = _FakeAuth();
      final repo = SupabaseAuthRepository(auth);
      await repo.sendEmailCode('a@b.co');
      await repo.verifyCode('a@b.co', '123456');
      expect(auth.calls, ['updateUser', 'verifyOTP emailChange']);
    });

    test('already registered falls back to sign-in with the email code',
        () async {
      final auth = _FakeAuth()
        ..updateError =
            AuthApiException('taken', statusCode: '422', code: 'email_exists');
      final repo = SupabaseAuthRepository(auth);
      await repo.sendEmailCode('a@b.co');
      await repo.verifyCode('a@b.co', '123456');
      expect(auth.calls, [
        'updateUser',
        'signInWithOtp shouldCreateUser=false',
        'verifyOTP email',
      ]);
    });

    test('a wrong code maps to wrongCode', () async {
      final auth = _FakeAuth()
        ..verifyError = AuthApiException('Token has expired or is invalid',
            statusCode: '403');
      final repo = SupabaseAuthRepository(auth);
      await repo.sendEmailCode('a@b.co');
      expect(await _kind(() => repo.verifyCode('a@b.co', '000000')),
          AuthFailureKind.wrongCode);
    });
  });

  group('provider sign-in', () {
    test('availability follows the injected providers', () {
      final none = SupabaseAuthRepository(_FakeAuth());
      expect(none.appleAvailable, isFalse);
      expect(none.googleAvailable, isFalse);
      final both =
          SupabaseAuthRepository(_FakeAuth(), apple: _cred, google: _cred);
      expect(both.appleAvailable, isTrue);
      expect(both.googleAvailable, isTrue);
    });

    test('anonymous user links the identity (same user id)', () async {
      final auth = _FakeAuth();
      await SupabaseAuthRepository(auth, apple: _cred).signInWithApple();
      expect(auth.calls, ['link apple']);
    });

    test('identity owned by someone else switches to that user', () async {
      final auth = _FakeAuth()
        ..linkError = AuthApiException('exists',
            statusCode: '422', code: 'identity_already_exists');
      await SupabaseAuthRepository(auth, google: _cred).signInWithGoogle();
      expect(auth.calls, ['link google', 'signInWithIdToken google']);
    });

    test('a signed-in (non-anonymous) user just signs in', () async {
      final auth = _FakeAuth()..user = _user(anon: false, email: 'a@b.co');
      await SupabaseAuthRepository(auth, apple: _cred).signInWithApple();
      expect(auth.calls, ['signInWithIdToken apple']);
    });

    test('cancelling passes through as cancelled', () async {
      final repo = SupabaseAuthRepository(_FakeAuth(),
          apple: () async =>
              throw const AuthFailure(AuthFailureKind.cancelled));
      expect(await _kind(repo.signInWithApple), AuthFailureKind.cancelled);
    });
  });
}
