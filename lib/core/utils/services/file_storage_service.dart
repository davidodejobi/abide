import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// App-wide persistent file storage. Exposed as a single instance via
/// `fileStorageServiceProvider` — features should depend on that provider
/// rather than resolving the documents directory or constructing pickers
/// themselves, so image/file handling stays consistent across the app.
///
/// Stored references are **relative** to the documents directory (e.g.
/// `note_images/uuid.png`). iOS rewrites the absolute container path on every
/// relaunch/reinstall, so an absolute path saved today is dead tomorrow — only
/// the relative form is durable. Resolve it back to an absolute path with
/// [absolutePath] right before handing it to `Image.file`.
class FileStorageService {
  const FileStorageService();

  static const _uuid = Uuid();

  /// Cached documents-dir path so [absolutePath]/[relativePath] can run
  /// synchronously (the editor + list build these paths during `build`).
  /// Populated once by [init] at app startup.
  static String? _documentsPath;

  /// Resolves and caches the documents directory. Call once in `main()` before
  /// `runApp` so path conversion is available synchronously everywhere.
  static Future<void> init() async {
    _documentsPath = (await getApplicationDocumentsDirectory()).path;
  }

  /// Copies [sourcePath] into `<documents>/<bucket>/` and returns the path
  /// *relative* to the documents dir (e.g. `note_images/uuid.png`). We copy
  /// rather than reference the original because pickers hand back paths in an
  /// OS cache that may be purged.
  Future<String> persistFile(
    String sourcePath, {
    required String bucket,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    _documentsPath ??= docs.path;
    final dir = Directory(p.join(docs.path, bucket));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final name = '${_uuid.v4()}${p.extension(sourcePath)}';
    await File(sourcePath).copy(p.join(dir.path, name));
    return p.join(bucket, name);
  }

  /// Picks an image from [source], persists it into [bucket], and returns the
  /// stored relative path — or `null` if the user cancelled.
  Future<String?> pickAndPersistImage({
    required String bucket,
    ImageSource source = ImageSource.gallery,
    int imageQuality = 85,
  }) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: imageQuality,
    );
    if (picked == null) return null;
    return persistFile(picked.path, bucket: bucket);
  }

  /// Deletes a previously persisted file (relative or absolute path). No-op if
  /// it is already gone.
  Future<void> deleteFile(String path) async {
    final file = File(absolutePath(path));
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Resolves a stored relative path to an absolute one for the current
  /// install. Already-absolute paths are returned unchanged.
  static String absolutePath(String path) {
    if (p.isAbsolute(path)) return path;
    final base = _documentsPath;
    return base == null ? path : p.join(base, path);
  }

  /// Converts an absolute path under the documents dir back to its durable
  /// relative form. Paths outside the documents dir are returned unchanged.
  static String relativePath(String path) {
    final base = _documentsPath;
    if (base == null || !p.isAbsolute(path)) return path;
    return p.isWithin(base, path) ? p.relative(path, from: base) : path;
  }
}
