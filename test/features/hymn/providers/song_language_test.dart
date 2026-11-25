import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  ProviderContainer fresh(SharedPreferences prefs) {
    final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    return c;
  }

  test('song language defaults to English off a non-Yoruba phone', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(fresh(prefs).read(languageProvider), 'en');
  });

  test('song language survives a fresh container over the same prefs',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = fresh(prefs);
    first.read(languageProvider.notifier).state = 'yo';
    expect(fresh(prefs).read(languageProvider), 'yo');
  });
}
