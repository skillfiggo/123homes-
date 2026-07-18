// lib/utils/image_helper.dart
//
// Central utility for image compression + canonical naming.
// All uploads in the app go through [ImageHelper.prepare] so that:
//   • every file is compressed to ≤85% quality, max 1280px wide/tall
//   • files are renamed with a deterministic, human-readable pattern
//     instead of the default picker temp names
//
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageHelper {
  /// Compress [file] and write it to the system temp dir with a clean name.
  ///
  /// [prefix]  – logical prefix for the file, e.g. `listing`, `avatar`, `doc`
  /// [uid]     – current user UID (used in the filename for traceability)
  /// [index]   – position in a multi-upload batch (0-based)
  ///
  /// Returns the compressed [File] ready to upload.
  static Future<File> prepare(
    File file, {
    required String prefix,
    required String uid,
    int index = 0,
    int quality = 82,
    int maxWidth = 1280,
    int maxHeight = 1280,
  }) async {
    final tmpDir = await getTemporaryDirectory();

    // Build canonical filename: <prefix>_<shortUid>_<timestamp>_<index>.jpg
    // We always output JPEG so the format is predictable and widely supported.
    final shortUid  = uid.replaceAll('-', '').substring(0, 12);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outName   = '${prefix}_${shortUid}_${timestamp}_$index.jpg';
    final outPath   = p.join(tmpDir.path, outName);

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality:   quality,
      minWidth:  maxWidth,
      minHeight: maxHeight,
      format:    CompressFormat.jpeg,
    );

    // Fallback: if compression fails for any reason, return the original file.
    return result != null ? File(result.path) : file;
  }

  /// Convenience method for a batch of files.
  static Future<List<File>> prepareBatch(
    List<File> files, {
    required String prefix,
    required String uid,
    int quality = 82,
    int maxWidth = 1280,
    int maxHeight = 1280,
  }) async {
    final result = <File>[];
    for (int i = 0; i < files.length; i++) {
      result.add(await prepare(
        files[i],
        prefix: prefix,
        uid: uid,
        index: i,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ));
    }
    return result;
  }
}
