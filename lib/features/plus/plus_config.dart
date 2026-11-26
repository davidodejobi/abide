import 'package:flutter/foundation.dart';

import 'domain/plus_rules.dart';

/// Plus config and copy. Prices are placeholders until the billing provider
/// is chosen; real prices will come from the store, in the reader's currency.
/// Plain English, denomination-neutral.
abstract final class PlusConfig {
  /// Release gate: Plus UI exists only in debug builds, or when built with
  /// --dart-define=PLUS_ENABLED=true. Off in release until billing is real.
  static final enabled = plusFeaturesEnabled(
      debug: kDebugMode, flag: const bool.fromEnvironment('PLUS_ENABLED'));

  static const trialDays = 7;
  static const reminderDay = 5;
  static const monthlyPrice = '\$4.99';
  static const annualPrice = '\$29.99';
  static const sponsorYearPrice = '\$29.99';
  static const sponsorMonthPrice = '\$4.99';
  static const termsUrl = 'https://abide-app-open.vercel.app/terms.html';
  static const privacyUrl = 'https://abide-app-open.vercel.app/privacy.html';
}

/// Plus-only extras. Scripture, hymns and reading plans are never here.
enum PlusFeature {
  audio('Listen to hymns and Scripture', 'Hear every hymn and passage read aloud.'),
  extraRoad('More roads to walk', 'Open extra worlds on your reading road.'),
  family('Read with family and friends', 'Invite people to walk the road with you.'),
  widget('Home screen widget', "Keep today's verse on your home screen."),
  sync('Sync across devices', 'Back up your road and notes, and pick them up anywhere.'),
  offlineTranslation('Offline translations', 'Download more Bible translations to read with no signal.');

  const PlusFeature(this.title, this.blurb);
  final String title;
  final String blurb;
}

abstract final class PlusStrings {
  static const title = 'Lumway Plus';
  static const freePromise =
      'Scripture, hymns and your reading plan are free, always. Plus adds extras and helps keep them free for everyone.';
  static const included = 'What Plus adds';
  static const annual = 'Yearly';
  static const monthly = 'Monthly';
  static const bestValue = 'Best value';
  static const cancelAnytime = 'Cancel any time.';
  static const startTrial = 'Try free for 7 days';
  static const notNow = 'Not now';
  static const continueFree = 'Continue free';
  static const seeAll = 'See everything in Plus';
  static const restore = 'Restore purchases';
  static const restored = 'Plus restored.';
  static const nothingToRestore = 'No earlier purchase found.';
  static const terms = 'Terms';
  static const privacy = 'Privacy';
  static const youHavePlus = 'You have Plus. Thank you.';
  static const manage = 'Manage subscription';
  static const gotIt = 'Got it';
  static const seePlans = 'See Plus plans';
  static const failed = 'That did not go through. You have not been charged.';
  static const sponsorRow = 'Sponsor a reader';
  static const plusRow = 'Lumway Plus';
  static const plusRowActive = 'Active';
  static const plusRowFree = 'Extras, and a way to support free reading';
  static const onboardingTitle = 'Want a little more?';
  static const onboardingBody =
      'Everything you just set up stays free. Try Plus for 7 days if you would like audio, extra roads and sync.';
  static const debugToggle = 'Simulate Plus (debug)';

  static String thenPrice(String price, String period) =>
      'Free for ${PlusConfig.trialDays} days, then $price a $period. $cancelAnytime';
  static String gateBody(PlusFeature f) =>
      '${f.blurb} Plus is optional. Reading stays free.';
  static String reminderTitle(int daysLeft) =>
      'Your free trial ends in $daysLeft ${daysLeft == 1 ? 'day' : 'days'}';
  static String reminderBody(String date, String price) =>
      'You will be charged $price on $date unless you cancel.';

  static const sponsorTitle = 'Sponsor a reader';
  static const sponsorBody =
      'Pay for Plus access for someone who could not afford it. Reading is free for everyone either way.';
  static const sponsorYear = 'One year for a reader';
  static const sponsorMonth = 'One month for a reader';
  static const sponsorThanks = 'Thank you. A reader will receive Plus.';
}
