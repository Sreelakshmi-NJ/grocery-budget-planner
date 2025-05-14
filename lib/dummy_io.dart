// dummy_io.dart
// Dummy implementations for file and directory, used when dart:io is not available (e.g., on the web).

class File {
  final String path;
  File(this.path);

  Future<File> writeAsString(String contents) async {
    // Dummy implementation – do nothing.
    return this;
  }
}

class Directory {
  final String path;
  Directory(this.path);
}

Future<Directory> getTemporaryDirectory() async {
  // Return a dummy directory path.
  return Directory('temp');
}
