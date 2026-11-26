import 'dart:async';

import '../domain/auth_repository.dart';

/// In-memory stand-in until the Supabase layer lands. Any 6-digit code works.
/// Set [nextFailure] to make the next send or verify throw (tests, demos).
// ponytail: state is lost on restart; the real repo persists the session.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.delay = const Duration(milliseconds: 600)});

  final Duration delay;
  AuthFailure? nextFailure;

  AuthAccount _account = const AuthAccount();
  final _changes = StreamController<AuthAccount>.broadcast();

  Future<void> _wait() async {
    await Future<void>.delayed(delay);
    final f = nextFailure;
    if (f != null) {
      nextFailure = null;
      throw f;
    }
  }

  @override
  Future<AuthAccount> ensureAnonymousSession() async => _account;

  @override
  Stream<AuthAccount> watchAccount() async* {
    yield _account;
    yield* _changes.stream;
  }

  @override
  Future<void> sendEmailCode(String email) async {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      throw const AuthFailure(AuthFailureKind.invalidEmail);
    }
    await _wait();
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    await _wait();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const AuthFailure(AuthFailureKind.wrongCode);
    }
    _set(AuthAccount(email: email));
  }

  @override
  Future<void> signOut() async => _set(const AuthAccount());

  void _set(AuthAccount a) {
    _account = a;
    _changes.add(a);
  }
}
