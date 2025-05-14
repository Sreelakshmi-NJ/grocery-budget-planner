// lib/file_downloader.dart
export 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart';

import 'dart:html' as html;
import 'package:flutter/foundation.dart';

Future<void> downloadFile(String content, String fileName) async {
  if (!kIsWeb) {
    throw UnsupportedError('This method is only supported on web platforms');
  }

  // Create blob
  final bytes = content.codeUnits;
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Create download link
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..style.display = 'none';
  
  html.document.body?.children.add(anchor);
  
  // Trigger download
  anchor.click();
  
  // Cleanup
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
