import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:openbaptisthymnal/core/utils/services/file_storage_service.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_media.dart';

/// Media in notes stays a standard markdown image line so older builds, the
/// link graph and sync keep working:
///
///   `![caption](note_images/x.png "size=m align=left")`
///   `![Recording name](note_audio/x.m4a "dur=135000 speed=150 peaks=0a1f...")`
///
/// Defaults are omitted, so a legacy `![](x.png)` encodes back byte-identical.
/// The alt text is the caption (image) or the name (audio); the title carries
/// the attributes. In the live document images are `image` nodes and audio
/// clips are `audio` nodes.

const audioNodeType = 'audio';
const mediaUrlKey = 'url';
const mediaTextKey = 'text'; // caption (image) or name (audio)
const imageSizeKey = 'size'; // s | m | full
const imageAlignKey = 'align'; // left | center
const audioDurationKey = 'durationMs';
const audioSpeedKey = 'speed'; // percent, 100 = 1x
const audioPeaksKey = 'peaks'; // hex, one byte per bar

const imageSizes = ['s', 'm', 'full'];
const imageAligns = ['left', 'center'];
const defaultImageSize = 'full';
const defaultImageAlign = 'center';
const peakBars = 48;

/// Fraction of the content width for each size preset.
double imageSizeFraction(String size) => switch (size) {
      's' => 0.4,
      'm' => 0.7,
      _ => 1.0,
    };

Node imageMediaNode({
  required String url,
  String caption = '',
  String size = defaultImageSize,
  String align = defaultImageAlign,
}) =>
    Node(type: ImageBlockKeys.type, attributes: {
      mediaUrlKey: url,
      mediaTextKey: caption,
      imageSizeKey: size,
      imageAlignKey: align,
    });

Node audioMediaNode({
  required String url,
  String name = '',
  int durationMs = 0,
  int speed = 100,
  String peaks = '',
}) =>
    Node(type: audioNodeType, attributes: {
      mediaUrlKey: url,
      mediaTextKey: name,
      audioDurationKey: durationMs,
      audioSpeedKey: speed,
      audioPeaksKey: peaks,
    });

/// Quantises [samples] (any magnitude) to [peakBars] one-byte bars as hex.
String encodePeaks(List<double> samples) {
  if (samples.isEmpty) return '';
  final mags = samples.map((s) => s.abs()).toList();
  final maxMag = mags.reduce((a, b) => a > b ? a : b);
  if (maxMag == 0) return '';
  final out = StringBuffer();
  for (var i = 0; i < peakBars; i++) {
    final from = i * mags.length ~/ peakBars;
    final to = ((i + 1) * mags.length ~/ peakBars).clamp(from + 1, mags.length);
    var m = 0.0;
    for (var j = from; j < to && j < mags.length; j++) {
      if (mags[j] > m) m = mags[j];
    }
    out.write((m / maxMag * 255)
        .round()
        .clamp(0, 255)
        .toRadixString(16)
        .padLeft(2, '0'));
  }
  return out.toString();
}

List<double> decodePeaks(String hex) {
  final out = <double>[];
  for (var i = 0; i + 2 <= hex.length; i += 2) {
    final v = int.tryParse(hex.substring(i, i + 2), radix: 16);
    if (v == null) return const [];
    out.add(v / 255);
  }
  return out;
}

/// Escapes unbalanced `[`/`]` and backslashes so the text is a valid image
/// description. Balanced pairs (such as `[[bible:JHN.1.1]]`) stay literal so
/// caption links reach the link graph and the tappable renderer.
String escapeCaption(String text) {
  final flat = text.replaceAll(RegExp(r'\s*\n\s*'), ' ');
  final open = <int>[];
  final unbalanced = <int>{};
  for (var i = 0; i < flat.length; i++) {
    final c = flat[i];
    if (c == '[') {
      open.add(i);
    } else if (c == ']') {
      if (open.isEmpty) {
        unbalanced.add(i);
      } else {
        open.removeLast();
      }
    }
  }
  unbalanced.addAll(open);
  final b = StringBuffer();
  for (var i = 0; i < flat.length; i++) {
    final c = flat[i];
    if (c == r'\' || unbalanced.contains(i)) b.write(r'\');
    b.write(c);
  }
  return b.toString();
}

Map<String, String> _parseTitle(String? title) {
  final out = <String, String>{};
  for (final part in (title ?? '').split(RegExp(r'\s+'))) {
    final eq = part.indexOf('=');
    if (eq > 0) out[part.substring(0, eq)] = part.substring(eq + 1);
  }
  return out;
}

String _resolve(String url) =>
    isExternalUrl(url) ? url : FileStorageService.absolutePath(url);
String _durable(String url) =>
    isExternalUrl(url) ? url : FileStorageService.relativePath(url);

bool isExternalUrl(String url) =>
    url.startsWith('http://') ||
    url.startsWith('https://') ||
    url.startsWith('data:');

/// Decodes `![alt](src "title")` (as a bare `img` or a paragraph holding only
/// one) into an image or audio node. Registered ahead of appflowy's own image
/// parser, so no vendored file changes.
class NoteMediaMarkdownParser extends CustomMarkdownParser {
  const NoteMediaMarkdownParser();

  @override
  List<Node> transform(
    md.Node element,
    List<CustomMarkdownParser> parsers, {
    MarkdownListType listType = MarkdownListType.unknown,
    int? startNumber,
  }) {
    if (element is! md.Element) return [];
    md.Element? img;
    if (element.tag == 'img') {
      img = element;
    } else if (element.tag == 'p' && element.children?.length == 1) {
      final only = element.children!.first;
      if (only is md.Element && only.tag == 'img') img = only;
    }
    final src = img?.attributes['src'];
    if (img == null || src == null) return [];

    final alt = img.attributes['alt'] ?? '';
    final attrs = _parseTitle(img.attributes['title']);
    final url = _resolve(src);
    if (isAudioPath(src)) {
      return [
        audioMediaNode(
          url: url,
          name: alt,
          durationMs: int.tryParse(attrs['dur'] ?? '') ?? 0,
          speed: int.tryParse(attrs['speed'] ?? '') ?? 100,
          peaks: attrs['peaks'] ?? '',
        ),
      ];
    }
    final size =
        imageSizes.contains(attrs['size']) ? attrs['size']! : defaultImageSize;
    final align = imageAligns.contains(attrs['align'])
        ? attrs['align']!
        : defaultImageAlign;
    return [imageMediaNode(url: url, caption: alt, size: size, align: align)];
  }
}

String _line(String alt, String url, List<String> attrs) {
  final title = attrs.isEmpty ? '' : ' "${attrs.join(' ')}"';
  return '![${escapeCaption(alt)}](${_durable(url)}$title)';
}

class NoteImageNodeParser extends NodeParser {
  const NoteImageNodeParser();
  @override
  String get id => ImageBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final a = node.attributes;
    final size = a[imageSizeKey] as String? ?? defaultImageSize;
    final align = a[imageAlignKey] as String? ?? defaultImageAlign;
    return _line(
        a[mediaTextKey] as String? ?? '', a[mediaUrlKey] as String? ?? '', [
      if (size != defaultImageSize) 'size=$size',
      if (align != defaultImageAlign) 'align=$align',
    ]);
  }
}

class NoteAudioNodeParser extends NodeParser {
  const NoteAudioNodeParser();
  @override
  String get id => audioNodeType;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final a = node.attributes;
    final dur = a[audioDurationKey] as int? ?? 0;
    final speed = a[audioSpeedKey] as int? ?? 100;
    final peaks = a[audioPeaksKey] as String? ?? '';
    return _line(
        a[mediaTextKey] as String? ?? '', a[mediaUrlKey] as String? ?? '', [
      if (dur > 0) 'dur=$dur',
      if (speed != 100) 'speed=$speed',
      if (peaks.isNotEmpty) 'peaks=$peaks',
    ]);
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Default name for a new recording, e.g. `Recording, 26 Nov, 10:42`.
String defaultRecordingName(DateTime t) {
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return 'Recording, ${t.day} ${_months[t.month - 1]}, $hh:$mm';
}
