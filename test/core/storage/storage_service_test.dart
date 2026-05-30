import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StorageService', () {
    late StorageService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = StorageService(prefs);
    });

    test('getThemeMode returns ThemeMode.system when nothing is stored', () {
      expect(service.getThemeMode(), ThemeMode.system);
    });

    test('saveThemeMode persists light mode', () async {
      await service.saveThemeMode(ThemeMode.light);
      expect(service.getThemeMode(), ThemeMode.light);
    });

    test('saveThemeMode persists dark mode', () async {
      await service.saveThemeMode(ThemeMode.dark);
      expect(service.getThemeMode(), ThemeMode.dark);
    });

    test('saveThemeMode persists system mode', () async {
      await service.saveThemeMode(ThemeMode.system);
      expect(service.getThemeMode(), ThemeMode.system);
    });

    test('getThemeMode falls back to system for unknown stored value',
        () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'garbage_value'});
      final prefs = await SharedPreferences.getInstance();
      final s = StorageService(prefs);
      expect(s.getThemeMode(), ThemeMode.system);
    });

    test('saveThemeMode overwrites a previously saved mode', () async {
      await service.saveThemeMode(ThemeMode.dark);
      await service.saveThemeMode(ThemeMode.light);
      expect(service.getThemeMode(), ThemeMode.light);
    });
  });
}
