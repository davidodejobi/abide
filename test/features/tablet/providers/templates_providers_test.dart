import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/tablet/providers/templates_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, SharedPreferences)> _make(
    [Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    myTemplatesProvider.overrideWith((ref) => Stream.value(const [])),
  ]);
  addTearDown(c.dispose);
  return (c, prefs);
}

void main() {
  test('Given pins, they keep order, persist, and unpin cleanly', () async {
    final (c, prefs) = await _make();
    final pins = c.read(pinnedTemplateIdsProvider.notifier);
    await pins.pin('a');
    await pins.pin('b');
    await pins.pin('c');
    await pins.pin('a'); // already pinned: no duplicate
    expect(c.read(pinnedTemplateIdsProvider), ['a', 'b', 'c']);

    await pins.reorderVisible(['a', 'b', 'c'], 0, 2); // a moves to the end
    expect(c.read(pinnedTemplateIdsProvider), ['b', 'c', 'a']);

    await pins.toggle('c');
    expect(c.read(pinnedTemplateIdsProvider), ['b', 'a']);
    expect(prefs.getStringList('note_template_pins'), ['b', 'a']);
  });

  test('Given a hidden pin, reordering keeps it at the end', () async {
    final (c, _) = await _make({
      'note_template_pins': ['a', 'gone', 'b', 'c'],
    });
    // "gone" is a deleted template: not shown, so not in the visible list.
    await c
        .read(pinnedTemplateIdsProvider.notifier)
        .reorderVisible(['a', 'b', 'c'], 2, 0);
    expect(c.read(pinnedTemplateIdsProvider), ['c', 'a', 'b', 'gone']);
  });

  test('Given saved pins, a new container reads them back', () async {
    final (c, _) = await _make({
      'note_template_pins': ['builtin:sermon'],
    });
    expect(c.read(pinnedTemplateIdsProvider), ['builtin:sermon']);
  });

  test('Given a built-in id, templateByIdProvider finds it without Mine',
      () async {
    final (c, _) = await _make();
    expect(c.read(templateByIdProvider('builtin:sermon'))?.name, 'Sermon');
    expect(c.read(templateByIdProvider('nope')), isNull);
  });

  test('Given a speaker, it is remembered across containers', () async {
    final (c, prefs) = await _make();
    expect(c.read(lastSpeakerProvider), isNull);
    await c.read(lastSpeakerProvider.notifier).remember('Ada Obi');
    expect(prefs.getString('note_template_last_speaker'), 'Ada Obi');
    expect(c.read(lastSpeakerProvider), 'Ada Obi');
  });

  test('Given the empty-notes hint, dismissing it sticks', () async {
    final (c, prefs) = await _make();
    expect(c.read(templateHintSeenProvider), isFalse);
    await c.read(templateHintSeenProvider.notifier).dismiss();
    expect(c.read(templateHintSeenProvider), isTrue);
    expect(prefs.getBool('notes_template_hint_seen'), isTrue);
  });
}
