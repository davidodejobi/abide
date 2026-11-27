/// The reader's account. [email] and [provider] are null while the session is
/// anonymous. [provider] is `email`, `apple` or `google`.
class AuthAccount {
  const AuthAccount({this.email, this.provider});

  final String? email;
  final String? provider;

  bool get isSaved => email != null || provider != null;

  @override
  bool operator ==(Object other) =>
      other is AuthAccount && other.email == email && other.provider == provider;

  @override
  int get hashCode => Object.hash(email, provider);
}

/// [cancelled] is the reader backing out of Apple or Google: not an error to
/// show.
enum AuthFailureKind { invalidEmail, wrongCode, network, cancelled, unknown }

/// What the UI can show. Real backends map their own errors onto this.
class AuthFailure implements Exception {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;

  @override
  String toString() => 'AuthFailure($kind)';
}

/// Account seam. `FakeAuthRepository` and `SupabaseAuthRepository` live in
/// `data/` and are swapped in through `authRepositoryProvider`.
///
/// "Save" converts the anonymous session in place (same user id, so rows
/// already keyed to it stay): [sendEmailCode] then [verifyCode].
abstract interface class AuthRepository {
  /// Starts (or resumes) the silent anonymous session.
  Future<AuthAccount> ensureAnonymousSession();

  /// Emits the current account first, then every change.
  Stream<AuthAccount> watchAccount();

  /// Throws [AuthFailure] (invalidEmail, network).
  Future<void> sendEmailCode(String email);

  /// Throws [AuthFailure] (wrongCode, network).
  Future<void> verifyCode(String email, String code);

  /// Native Apple / Google sign-in. Keeps the same user id when the session is
  /// anonymous; lands on the existing account when the identity is already
  /// registered. Throws [AuthFailure] (cancelled, network, unknown).
  Future<void> signInWithApple();
  Future<void> signInWithGoogle();

  /// Whether the buttons should be offered at all on this device/build.
  bool get appleAvailable;
  bool get googleAvailable;

  /// Back to a fresh anonymous session. Local data is never touched.
  Future<void> signOut();
}
