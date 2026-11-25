/// The reader's account. [email] is null while the session is anonymous.
class AuthAccount {
  const AuthAccount({this.email});

  final String? email;

  bool get isSaved => email != null;
}

enum AuthFailureKind { invalidEmail, wrongCode, network, unknown }

/// What the UI can show. Real backends map their own errors onto this.
class AuthFailure implements Exception {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;

  @override
  String toString() => 'AuthFailure($kind)';
}

/// Account seam. The fake lives in `data/`; the Supabase layer implements this
/// later and is swapped in through `authRepositoryProvider`.
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

  /// Back to a fresh anonymous session.
  Future<void> signOut();
}
