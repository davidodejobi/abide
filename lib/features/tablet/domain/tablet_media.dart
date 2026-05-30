/// Audio clips are stored as ordinary markdown image nodes
/// (`![](note_audio/x.m4a)`) so they reuse the existing relative-path codec and
/// insert flow; the editor and list tell them apart from real images by the
/// file extension. Keep this list in sync with what the recorder produces.
const _audioExtensions = {'.m4a', '.mp3', '.aac', '.wav', '.caf', '.ogg'};

/// Whether [path] points at an audio clip (by extension), as opposed to an
/// image. Case-insensitive; works on both relative and absolute paths.
bool isAudioPath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1) return false;
  return _audioExtensions.contains(path.substring(dot).toLowerCase());
}
