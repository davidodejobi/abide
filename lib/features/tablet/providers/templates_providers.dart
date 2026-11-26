import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/templates_repository.dart';
import 'package:openbaptisthymnal/features/tablet/domain/builtin_templates.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';

final templatesRepositoryProvider = Provider<TemplatesRepository>((ref) {
  return TemplatesRepository(ref.watch(noteTemplatesDaoProvider));
});

/// The user's own templates, oldest first.
final myTemplatesProvider = StreamProvider<List<NoteTemplate>>((ref) {
  return ref.watch(templatesRepositoryProvider).watchMine();
});

/// Template by id, built-in or mine. Null while "Mine" is loading or when the
/// template no longer exists.
final templateByIdProvider = Provider.family<NoteTemplate?, String>((ref, id) {
  final builtIn = builtInTemplateById(id);
  if (builtIn != null) return builtIn;
  return ref
      .watch(myTemplatesProvider)
      .valueOrNull
      ?.where((t) => t.id == id)
      .firstOrNull;
});

const _pinsKey = 'note_template_pins';
const _speakerKey = 'note_template_last_speaker';
const _hintSeenKey = 'notes_template_hint_seen';

/// Pinned template ids, in the order the user arranged them. Any template,
/// built-in or mine. Ids of deleted templates are filtered where they are
/// shown, so a delete never has to reach in here.
final pinnedTemplateIdsProvider =
    NotifierProvider<PinnedTemplatesNotifier, List<String>>(
  PinnedTemplatesNotifier.new,
);

class PinnedTemplatesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() =>
      ref.read(sharedPreferencesProvider).getStringList(_pinsKey) ?? const [];

  Future<void> _set(List<String> next) async {
    state = next;
    await ref.read(sharedPreferencesProvider).setStringList(_pinsKey, next);
  }

  bool isPinned(String id) => state.contains(id);

  Future<void> pin(String id) async {
    if (!state.contains(id)) await _set([...state, id]);
  }

  Future<void> unpin(String id) => _set([...state]..remove(id));

  Future<void> toggle(String id) => isPinned(id) ? unpin(id) : pin(id);

  /// [newIndex] is the final position (`ReorderableListView.onReorderItem`).
  Future<void> reorder(int oldIndex, int newIndex) {
    final next = [...state];
    next.insert(newIndex, next.removeAt(oldIndex));
    return _set(next);
  }
}

/// The speaker last written in a note made from a template, used to prefill
/// the next one.
final lastSpeakerProvider = NotifierProvider<LastSpeakerNotifier, String?>(
  LastSpeakerNotifier.new,
);

class LastSpeakerNotifier extends Notifier<String?> {
  @override
  String? build() =>
      ref.read(sharedPreferencesProvider).getString(_speakerKey);

  Future<void> remember(String speaker) async {
    if (speaker == state) return;
    state = speaker;
    await ref.read(sharedPreferencesProvider).setString(_speakerKey, speaker);
  }
}

/// Whether the one-time "start from a template" hint on an empty Notes tab
/// has been dismissed (by the x, or by the first saved note).
final templateHintSeenProvider =
    NotifierProvider<TemplateHintSeenNotifier, bool>(
  TemplateHintSeenNotifier.new,
);

class TemplateHintSeenNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(_hintSeenKey) ?? false;

  Future<void> dismiss() async {
    if (state) return;
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_hintSeenKey, true);
  }
}
