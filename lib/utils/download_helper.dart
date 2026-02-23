import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';

/// Cross-platform file download helper.
/// On web, triggers a browser download.
/// On other platforms, this is a no-op (use FilePicker or share instead).
void downloadFile(String fileName, Uint8List bytes) {
  if (kIsWeb) {
    downloadFileImpl(fileName, bytes);
  }
}
