import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/download_service.dart';
import '../services/file_storage_service.dart';

part 'download_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 30), // large files
      followRedirects: true,
      maxRedirects: 5,
    ),
  );
}

@Riverpod(keepAlive: true)
FileStorageService fileStorageService(Ref ref) {
  return FileStorageService();
}

@Riverpod(keepAlive: true)
DownloadService downloadService(Ref ref) {
  return DownloadService(
    ref.watch(dioProvider),
    ref.watch(fileStorageServiceProvider),
  );
}
