// lib/io_helper_stub.dart
class Directory {
  final String path;
  Directory(this.path);
}

class File {
  final String path;
  File(this.path);
  Future<File> writeAsString(String contents) async {
    // Dummy implementation for web.
    return this;
  }
}

Future<Directory> getTemporaryDirectoryForApp() async {
  // Return a dummy directory for web.
  return Directory('temp');
}
