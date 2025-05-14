// lib/io_helper.dart
export 'io_helper_stub.dart' if (dart.library.io) 'io_helper_real.dart';

import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class File {
  final String path;
  
  File(this.path);

  Future<void> writeAsBytes(List<int> bytes) async {
    if (kIsWeb) {
      throw UnsupportedError('Writing files is not supported on web platforms');
    }
    final file = io.File(path);
    await file.writeAsBytes(bytes);
  }

  Future<void> writeAsString(String contents) async {
    if (kIsWeb) {
      throw UnsupportedError('Writing files is not supported on web platforms');
    }
    final file = io.File(path);
    await file.writeAsString(contents);
  }
}

class Directory {
  final String path;
  
  Directory(this.path);

  static Directory fromIoDirectory(io.Directory dir) {
    return Directory(dir.path);
  }
}

Future<Directory> getTemporaryDirectoryForApp() async {
  if (kIsWeb) {
    throw UnsupportedError('Getting temporary directory is not supported on web platforms');
  }
  final directory = await getTemporaryDirectory();
  return Directory(directory.path);
}
