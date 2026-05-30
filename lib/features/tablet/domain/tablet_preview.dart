import 'package:openbaptisthymnal/core/utils/services/file_storage_service.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_media.dart';

/// Helpers that turn a note's raw markdown into list-friendly previews, so the
/// Tablets list shows readable text and thumbnails instead of leaking syntax
/// like `**bold**`, `[[hymn:hymn_0003]]`, or `![](note_images/x.png)`.

final _image = RegExp(r'!\[[^\]]*\]\(([^)]+)\)');
final _wikilink = RegExp(r'\[\[([^\[\]]*)\]\]');
final _mdLink = RegExp(r'\[([^\]]*)\]\(([^)]+)\)');
final _heading = RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true);
final _quote = RegExp(r'^\s{0,3}>\s?', multiLine: true);
final _listMarker = RegExp(r'^\s*(?:[-*+]|\d+\.)\s+', multiLine: true);
final _todoMarker = RegExp(r'\[[ xX]\]\s*');
final _emphasis = RegExp(r'(\*\*|__|\*|_|~~|`)');
final _whitespace = RegExp(r'\s+');

/// Best plain-text snippet for a note: strips markdown syntax and collapses to
/// a single readable line. Returns an empty string when there's no text body.
String notePreviewText(String markdown) {
  var text = markdown;
  text = text.replaceAll(_image, ''); // drop images from the text snippet
  // `[[hymn:hymn_0003]]` / `[[Some Note]]` → the human-readable part.
  text = text.replaceAllMapped(_wikilink, (m) {
    final inner = m[1]!.trim();
    final colon = inner.indexOf(':');
    return colon == -1 ? inner : inner.substring(colon + 1).trim();
  });
  text = text.replaceAllMapped(_mdLink, (m) => m[1] ?? '');
  text = text
      .replaceAll(_heading, '')
      .replaceAll(_quote, '')
      .replaceAll(_listMarker, '')
      .replaceAll(_todoMarker, '')
      .replaceAll(_emphasis, '');

  for (final line in text.split('\n')) {
    final cleaned = line.replaceAll(_whitespace, ' ').trim();
    if (cleaned.isNotEmpty) return cleaned;
  }
  return '';
}

/// The first *image* in a note resolved to an absolute path for `Image.file`,
/// or an external URL as-is. `null` when the note has no image. Audio clips are
/// stored as image nodes too, so they're skipped here (see [noteHasAudio]).
String? notePreviewImage(String markdown) {
  for (final match in _image.allMatches(markdown)) {
    final url = match.group(1)!;
    if (isAudioPath(url)) continue;
    if (url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('data:')) {
      return url;
    }
    return FileStorageService.absolutePath(url);
  }
  return null;
}

/// Whether the note contains at least one audio clip. Used to show a voice-note
/// marker in the list when there's no image thumbnail to display.
bool noteHasAudio(String markdown) =>
    _image.allMatches(markdown).any((m) => isAudioPath(m.group(1)!));
