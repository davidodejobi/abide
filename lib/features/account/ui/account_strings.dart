import '../domain/auth_repository.dart';

/// Strings for the account UI, until the ARB move.
abstract final class AccountStrings {
  static const youSection = 'Account';
  static const saveRow = 'Save your road';
  static const saveRowHint = 'Keep your progress on every device';
  static const savedHint = 'Your road is safe';

  static const title = 'Save your road';
  static const body =
      'Signing in keeps your notes, highlights and reading progress safe on every phone.';
  static const continueApple = 'Continue with Apple';
  static const continueGoogle = 'Continue with Google';
  static const orEmail = 'or use your email';
  static String signedInWith(AuthAccount a) => switch (a.provider) {
        'apple' => 'Signed in with Apple',
        'google' => 'Signed in with Google',
        _ => 'Signed in as ${a.email}',
      };
  static const signOut = 'Sign out';
  static const signOutTitle = 'Sign out?';
  static const signOutBody =
      'Your notes, highlights and reading progress are saved to your account '
      'and will be removed from this phone. Folders, your own templates and '
      'verse notes stay on this phone. Sign in again any time to get your '
      'notes back.';
  static const signOutUnsaved =
      "Some changes haven't been saved to your account yet. "
      'Connect to the internet and try again.';
  static const ok = 'OK';
  static const cancel = 'Cancel';
  static const emailLabel = 'Email address';
  static const sendCode = 'Send me a code';
  static const notNow = 'Not now';
  static String codeSent(String email) => 'We sent a 6-digit code to $email.';
  static const codeLabel = '6-digit code';
  static const verify = 'Confirm';
  static const changeEmail = 'Use a different email';
  static const resend = 'Send again';
  static String resendIn(int s) => 'Send again in ${s}s';
  static const successTitle = 'Your road is saved';
  static String successBody(String email) => email.isEmpty
      ? 'Your progress and notes now follow you.'
      : 'Your progress and notes now follow you. Signed in as $email.';
  static const done = 'Done';

  static String error(AuthFailureKind k) => switch (k) {
        AuthFailureKind.invalidEmail => 'That email does not look right.',
        AuthFailureKind.wrongCode =>
          'That code did not match. Check it and try again.',
        AuthFailureKind.network =>
          'No connection. Check your network and try again.',
        AuthFailureKind.cancelled => '',
        AuthFailureKind.unknown => 'Something went wrong. Please try again.',
      };
}
