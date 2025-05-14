// lib/file_downloader_web.dart
import 'dart:convert';
import 'dart:html' as html;

void downloadFile(String content, String filename) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  html.Url.revokeObjectUrl(url);
}
