import 'dart:convert';
import 'dart:html' as html;

/// Generates a Blob from [content] and triggers a download with the given [filename].
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
