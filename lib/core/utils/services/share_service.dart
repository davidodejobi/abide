import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  Future<void> shareImage({
    required Uint8List imageBytes,
    required String filename,
    Rect? sharePositionOrigin,
  }) async {
    try {
      // Process image in an isolate to avoid blocking the UI
      final processedBytes = await compute(_processImageBytes, imageBytes);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$filename.png';

      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(processedBytes);

      // Share
      final xFile = XFile(filePath);
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
      rethrow;
    }
  }

  /// Shares plain text through the system share sheet.
  Future<void> shareText(String text, {Rect? sharePositionOrigin}) =>
      SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: sharePositionOrigin),
      );

  /// Saves the PNG to the photo gallery; the OS asks for permission on first use.
  Future<void> saveImage(Uint8List imageBytes, String filename) =>
      Gal.putImageBytes(imageBytes, name: filename);

  /// Decodes and re-encodes the image to ensure it is a valid PNG.
  /// Runs in a separate isolate.
  static Uint8List _processImageBytes(Uint8List bytes) {
    // Decode the image to ensure it's valid
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image data');
    }
    // Encode as PNG
    return Uint8List.fromList(img.encodePng(image));
  }
}
