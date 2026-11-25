import 'dart:math' as math;

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Anonymous, aggregate company for one plan day, the shape of the
/// `world_company(p_plan_key, p_day_index)` RPC. Any count the server holds
/// back (under 5 readers) arrives as null: show "a few", or nothing. Never
/// names, never individual activity, nothing that ranks.
class WorldCompany {
  const WorldCompany({this.readersOnDay, this.readersToday, this.totalWalkers});

  /// Readers who finished this plan day today.
  final int? readersOnDay;

  /// Readers who read anything today.
  final int? readersToday;

  /// Everyone walking this plan.
  final int? totalWalkers;
}

/// Where the counts come from. The Supabase source (the RPC above, keyed by
/// plan key such as 'bible-in-a-year@2027') plugs in here later. Null means
/// "no data": the UI shows nothing at all.
abstract interface class WorldCompanySource {
  Future<WorldCompany?> load(String planKey, int dayIndex);
}

/// Placeholder numbers, deterministic per day, until the Supabase source lands.
class FakeWorldCompanySource implements WorldCompanySource {
  const FakeWorldCompanySource();

  @override
  Future<WorldCompany?> load(String planKey, int dayIndex) async {
    final n = 600 + (dayIndex * 7919) % 3000;
    return WorldCompany(
        readersOnDay: n, readersToday: n * 3, totalWalkers: n * 9);
  }
}

class NoWorldCompanySource implements WorldCompanySource {
  const NoWorldCompanySource();

  @override
  Future<WorldCompany?> load(String planKey, int dayIndex) async => null;
}

final worldCompanySourceProvider =
    Provider<WorldCompanySource>((ref) => const FakeWorldCompanySource());

final worldCompanyProvider =
    FutureProvider.family<WorldCompany?, ({String planKey, int day})>(
  (ref, k) async {
    try {
      return await ref.watch(worldCompanySourceProvider).load(k.planKey, k.day);
    } catch (_) {
      return null; // a failed lookup hides the line, never errors the screen
    }
  },
);

/// Fewer readers than this show as "a few": a tiny count can point at people.
const worldMinCount = 5;

const _dotSeparatorLocales = {'de', 'es', 'it', 'pt', 'nl', 'id', 'tr', 'da'};
const _spaceSeparatorLocales = {'fr', 'ru', 'pl', 'cs', 'sv', 'nb', 'fi'};

/// 1,204 / 1.204 / 1 204 by the reader's locale (no intl dependency yet).
String formatCount(int n, Locale locale) {
  final l = locale.languageCode;
  final sep = _spaceSeparatorLocales.contains(l)
      ? ' '
      : _dotSeparatorLocales.contains(l)
          ? '.'
          : ',';
  final s = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(sep);
    out.write(s[i]);
  }
  return out.toString();
}

/// A soft dot walking near the reader. Not a real person.
typedef CompanionSpot = ({double along, double side, double phase});

/// At most 12 dots, growing slowly with the count, placed deterministically
/// from [seed] (the day) so the road never reshuffles on rebuild.
List<CompanionSpot> companionSpots(int readers, int seed) {
  if (readers < worldMinCount) return const [];
  final n = math.min(12, (math.log(readers) / math.ln10 * 3).round());
  final rnd = math.Random(seed * 7919 + 13);
  return [
    for (var i = 0; i < n; i++)
      (
        along: -1.6 + rnd.nextDouble() * 3.2, // stops either side of the reader
        side: (rnd.nextBool() ? 1 : -1) * (16 + rnd.nextDouble() * 18), // px
        phase: rnd.nextDouble() * 2 * math.pi,
      ),
  ];
}
