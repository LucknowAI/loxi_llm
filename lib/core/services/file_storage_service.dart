import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Provides filesystem paths for model storage.
///
/// Models are stored in `<app-documents>/models/`.
/// This is internal app storage — no Android permissions required.
class FileStorageService {
  Future<String> getModelDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDocDir.path}/models');
    await modelDir.create(recursive: true);
    return modelDir.path;
  }

  Future<String> getModelPath(String filename) async {
    final dir = await getModelDirectory();
    return '$dir/$filename';
  }

  Future<bool> modelFileExists(String filename) async {
    final path = await getModelPath(filename);
    return File(path).exists();
  }

  Future<void> deleteModelFile(String filename) async {
    final path = await getModelPath(filename);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
