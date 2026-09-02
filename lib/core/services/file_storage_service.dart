import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Provides filesystem paths for model and chat-image storage.
///
/// Models are stored in `<app-documents>/models/`, attached chat images in
/// `<app-documents>/images/`. Both are internal app storage — no Android
/// permissions required.
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

  Future<String> getImagesDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDocDir.path}/images');
    await imagesDir.create(recursive: true);
    return imagesDir.path;
  }

  Future<String> getImagePath(String filename) async {
    final dir = await getImagesDirectory();
    return '$dir/$filename';
  }

  /// Deletes an attached chat image given its full path (as stored on a
  /// chat message) — unlike [deleteModelFile], callers here always already
  /// hold the full path, not just a filename. No-op if missing, and no-op
  /// (rather than throw) if [path] isn't actually inside our own images
  /// directory — a safety guard against ever deleting an arbitrary file.
  Future<void> deleteImage(String path) async {
    final imagesDir = await getImagesDirectory();
    if (p.dirname(path) != imagesDir) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
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
