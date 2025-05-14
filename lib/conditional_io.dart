// conditional_io.dart
// Exports dart:io when available; otherwise exports dummy implementations for the web.

export 'dummy_io.dart' if (dart.library.io) 'dart:io';
