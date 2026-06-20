import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:openbaptisthymnal/core/utils/services/file_storage_service.dart';

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
/// Images are stored as a durable relative path (`![](note_images/x.png)`) but
/// the live document needs an absolute path for `Image.file`, so we convert on
/// the way in and back to relative on the way out (see [FileStorageService]).

/// Matches a markdown image: `![alt](url)`.
final _imageMarkdown = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');

/// Matches an image line that is glued to the next/previous line by a single
/// newline (no blank line between). CommonMark folds `![](url)\ntext` into one
/// paragraph, which makes the parser drop the image block entirely (the clip
/// "disappears" / renders as raw `![](id)` text). We re-insert the blank line
/// so the image stays its own block.
final _gluedImageBefore = RegExp(r'(\S)\n(!\[[^\]]*\]\([^)]+\))');
final _gluedImageAfter = RegExp(r'(!\[[^\]]*\]\([^)]+\))\n(?!\n|$)');

/// Guarantees a blank line on both sides of every image line so it parses as a
/// standalone block. Idempotent: lines already blank-separated are untouched.
String _isolateImageBlocks(String markdown) {
  var out = markdown.replaceAllMapped(
    _gluedImageBefore,
    (m) => '${m[1]}\n\n${m[2]}',
  );
  out = out.replaceAllMapped(_gluedImageAfter, (m) => '${m[1]}\n\n');
  return out;
}

bool _isExternal(String url) =>
    url.startsWith('http://') ||
    url.startsWith('https://') ||
    url.startsWith('data:');

/// Seeds a [Document] from stored [markdown]. Empty notes get a single blank
/// paragraph so the editor has a body to place the cursor in.
Document noteMarkdownToDocument(String markdown) {
  if (markdown.trim().isEmpty) {
    return Document.blank(withInitialText: true);
  }
  // Repair notes saved with an image glued to adjacent text (older audio notes
  // were stored this way and lose the clip on load); then resolve relative
  // image paths to absolute for the live document.
  final isolated = _isolateImageBlocks(markdown);
  final resolved = isolated.replaceAllMapped(_imageMarkdown, (m) {
    final url = m[2]!;
    if (_isExternal(url)) return m[0]!;
    return '![${m[1]}](${FileStorageService.absolutePath(url)})';
  });
  return markdownToDocument(resolved);
}

/// Encodes the editor [document] back to markdown, rewriting absolute image
/// paths to their durable relative form. A blank line between blocks keeps
/// adjacent paragraphs from merging when re-parsed and makes encoding
/// idempotent.
String noteDocumentToMarkdown(Document document) {
  final markdown = documentToMarkdown(document, lineBreak: '\n').trimRight();
  // `documentToMarkdown` emits only single newlines, which glues an image to
  // adjacent text and drops the clip on the next parse. Isolate image blocks so
  // what we persist always reloads losslessly.
  final isolated = _isolateImageBlocks(markdown);
  return isolated.replaceAllMapped(_imageMarkdown, (m) {
    final url = m[2]!;
    if (_isExternal(url)) return m[0]!;
    return '![${m[1]}](${FileStorageService.relativePath(url)})';
  });
}
