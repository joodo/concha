import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<bool> isInTemporaryDirectory(String filePath) async {
  final Directory tempDir = await getTemporaryDirectory();

  String normalizedFilePath = p.canonicalize(filePath);
  String normalizedTempPath = p.canonicalize(tempDir.path);

  return p.isWithin(normalizedTempPath, normalizedFilePath);
}
