import '../domain/auth_repository.dart';

/// Strings for the account UI, until the ARB move.
abstract final class AccountStrings {
  static const youSection = 'Account';
  static const saveRow = 'Save your road';
  static const saveRowHint = 'Keep your progress on every device';
  static String savedAs(String email) => 'Saved as $email';
  static const savedHint = 'Your road is safe';

  static const title = 'Save your road';
  static const body =
      'Keep your progress and notes across your phone, tablet and the web.';
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
  static String successBody(String email) =>
      'Your progress and notes now follow you. Signed in as $email.';
  static const done = 'Done';

  static String error(AuthFailureKind k) => switch (k) {
        AuthFailureKind.invalidEmail => 'That email does not look right.',
        AuthFailureKind.wrongCode =>
          'That code did not match. Check it and try again.',
        AuthFailureKind.network =>
          'No connection. Check your network and try again.',
        AuthFailureKind.unknown => 'Something went wrong. Please try again.',
      };
}
