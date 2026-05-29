import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_service.dart';
import 'package:openbaptisthymnal/core/theme/font_scale.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer() async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('defaults to medium when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await makeContainer();

    expect(container.read(fontScaleProvider), FontScale.medium);
  });

  test('reads the persisted value when the provider builds', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await StorageService(prefs).saveFontScale(FontScale.large);

    final container = await makeContainer();

    expect(container.read(fontScaleProvider), FontScale.large);
  });

  test('setScale updates state and persists the choice', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await makeContainer();

    container.read(fontScaleProvider.notifier).setScale(FontScale.huge);

    expect(container.read(fontScaleProvider), FontScale.huge);

    final prefs = await SharedPreferences.getInstance();
    expect(StorageService(prefs).getFontScale(), FontScale.huge);
  });

  test('FontScale.fromName falls back to medium on unknown input', () {
    expect(FontScale.fromName(null), FontScale.medium);
    expect(FontScale.fromName('nonsense'), FontScale.medium);
    expect(FontScale.fromName('huge'), FontScale.huge);
  });
}
