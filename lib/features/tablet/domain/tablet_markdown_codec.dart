import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_media.dart';

/// Bridges stored note markdown and the AppFlowy [Document] the editor edits.
///
/// Markdown stays the single source of truth: it is what we persist in Drift
/// and what [parseLinks] scans to build the link graph. So these wrappers must
/// round-trip losslessly — `toMarkdown(toDocument(md)) == md` for the content
/// our editor produces.
///
/// `[[wikilinks]]` are deliberately *not* given a custom inline node: the
/// default codec already preserves them as literal text, so they survive the
/// round-trip untouched and the link graph keeps reading them straight from
/// the markdown. Styling and tap-to-navigate happen at render time via the
/// editor's `textSpanDecorator`, not in the document model.
///
/// Media is stored as a durable relative path (`![](note_images/x.png)`) but
/// the live document needs an absolute path, so the media parsers convert on the
/// way in and back to relative on the way out (see [FileStorageService]).

/// A whole-line media image: `![alt](path)` or `![alt](path "title")`.
final _mediaLine = RegExp(r'^!\[.*\]\(\S+?(?: "[^"]*")?\)$');

/// Guarantees a blank line on both sides of every media line so it parses as a
/// standalone block. CommonMark folds `![](url)\ntext` into one paragraph,
/// which drops the clip. Idempotent: lines already blank-separated are
/// untouched.
String _isolateImageBlocks(String markdown) {
  final lines = markdown.split('\n');
  final out = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final isMedia = _mediaLine.hasMatch(lines[i]);
    if (isMedia && out.isNotEmpty && out.last.trim().isNotEmpty) out.add('');
    out.add(lines[i]);
    final next = i + 1 < lines.length ? lines[i + 1] : null;
    if (isMedia && next != null && next.trim().isNotEmpty) out.add('');
  }
  return out.join('\n');
}

/// Seeds a [Document] from stored [markdown]. Empty notes get a single blank
/// paragraph so the editor has a body to place the cursor in. Media lines
/// become `image` / `audio` nodes with absolute paths (see note_media.dart).
Document noteMarkdownToDocument(String markdown) {
  if (markdown.trim().isEmpty) {
    return Document.blank(withInitialText: true);
  }
  return markdownToDocument(
    _isolateImageBlocks(markdown),
    markdownParsers: const [NoteMediaMarkdownParser()],
  );
}

/// Encodes the editor [document] back to markdown, rewriting absolute media
/// paths to their durable relative form. A blank line between blocks keeps
/// adjacent paragraphs from merging when re-parsed and makes encoding
/// idempotent.
String noteDocumentToMarkdown(Document document) {
  final markdown = documentToMarkdown(
    document,
    lineBreak: '\n',
    customParsers: const [NoteImageNodeParser(), NoteAudioNodeParser()],
  ).trimRight();
  return _isolateImageBlocks(markdown);
}
