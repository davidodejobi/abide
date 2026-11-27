import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/auth_repository.dart';

/// What Supabase needs from a native provider sign-in.
typedef IdCredential = ({String idToken, String? nonce});

/// Client ids, supplied at build time. Never hardcoded.
const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

/// Set to true only on builds whose Local.xcconfig supplies the reversed iOS
/// client id URL scheme; without it the Google SDK crashes the app on iOS.
const googleIosUrlSchemeSet = bool.fromEnvironment('GOOGLE_IOS_URL_SCHEME_SET');

/// Sign in with Apple is offered on iOS only.
bool get appleSignInSupported => !kIsWeb && Platform.isIOS;

/// Google needs the web client id (the id token's audience, which Supabase
/// checks) and, on iOS, the iOS client id and its URL scheme as well.
bool get googleSignInSupported {
  if (kIsWeb || googleWebClientId.isEmpty) return false;
  if (Platform.isIOS) {
    return googleIosClientId.isNotEmpty && googleIosUrlSchemeSet;
  }
  return Platform.isAndroid;
}

String _randomNonce([int length = 32]) {
  const chars =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
  final r = Random.secure();
  return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
}

Future<IdCredential> appleCredential() async {
  // Apple gets the SHA-256 of the nonce, Supabase the raw one.
  final raw = _randomNonce();
  final hashed = sha256.convert(utf8.encode(raw)).toString();
  try {
    final c = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
      nonce: hashed,
    );
    final token = c.identityToken;
    if (token == null) throw const AuthFailure(AuthFailureKind.unknown);
    return (idToken: token, nonce: raw);
  } on SignInWithAppleAuthorizationException catch (e) {
    if (e.code == AuthorizationErrorCode.canceled) {
      throw const AuthFailure(AuthFailureKind.cancelled);
    }
    rethrow;
  } on PlatformException {
    throw const AuthFailure(AuthFailureKind.unknown);
  }
}

Future<void>? _googleInit;

Future<IdCredential> googleCredential() async {
  // The plugin requires initialize to run exactly once, and the nonce can only
  // be set there, so a per-attempt nonce is impossible. No nonce is used: the
  // Supabase Google provider must have "Skip nonce checks" enabled.
  final g = GoogleSignIn.instance;
  try {
    await (_googleInit ??= g.initialize(
      clientId: !kIsWeb && Platform.isIOS ? googleIosClientId : null,
      serverClientId: googleWebClientId,
    ).catchError((Object e) {
      _googleInit = null; // a failed init may be retried
      throw e;
    }));
    final account = await g.authenticate();
    final token = account.authentication.idToken;
    if (token == null) throw const AuthFailure(AuthFailureKind.unknown);
    return (idToken: token, nonce: null);
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) {
      throw const AuthFailure(AuthFailureKind.cancelled);
    }
    rethrow;
  } on PlatformException {
    throw const AuthFailure(AuthFailureKind.unknown);
  }
}
