// lib/io_helper_real.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

export 'dart:io' show File, Directory;

Future<Directory> getTemporaryDirectoryForApp() async {
  return await getTemporaryDirectory();
}
