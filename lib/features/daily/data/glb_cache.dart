// Web has no app support directory and no dart:io: it gets no disk cache and
// no HTTP client from here, so models there come from the bundle or the
// sprite. Everything else uses the dart:io implementation.
export 'glb_cache_stub.dart' if (dart.library.io) 'glb_cache_io.dart';
