import 'package:appflowy_editor/appflowy_editor.dart';

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
Document noteMarkdownToDocument(String markdown) =>
    markdownToDocument(markdown);

/// A blank line between blocks keeps adjacent paragraphs from merging when the
/// markdown is re-parsed, and makes the encode step idempotent.
String noteDocumentToMarkdown(Document document) =>
    documentToMarkdown(document, lineBreak: '\n').trimRight();
