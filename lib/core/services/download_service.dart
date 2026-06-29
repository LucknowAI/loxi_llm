import 'dart:io';
import 'package:dio/dio.dart';
import '../../features/models/domain/model.dart';
import 'file_storage_service.dart';

/// Wraps Dio for GGUF/.task model file downloads.
///
/// Supports progress callbacks, cancellation, and resume via
/// HTTP Range + FileAccessMode.append (requires server 206 support;
/// HuggingFace CDN supports it).
class DownloadService {
  DownloadService(this._dio, this._storage);

  final Dio _dio;
  final FileStorageService _storage;
  final Map<String, CancelToken> _tokens = {};

  /// Download [model] from HuggingFace to the app documents directory.
  ///
  /// [downloadUrl] must be a direct CDN URL (use [huggingFaceDownloadUrl]).
  /// [onProgress] receives the fraction in [0.0, 1.0] and a smoothed download
  /// speed in bytes/second (0 until the first sample window elapses).
  /// Throws [DioException] on network errors; check [CancelToken.isCancel] for user cancels.
  Future<String> downloadModel({
    required Model model,
    required String downloadUrl,
    required void Function(double progress, double bytesPerSecond) onProgress,
    String? hfToken,
  }) async {
    final savePath = await _storage.getModelPath(model.filename!);
    final file = File(savePath);
    final existingBytes = file.existsSync() ? file.lengthSync() : 0;

    final cancelToken = CancelToken();
    _tokens[model.id] = cancelToken;

    // Speed is sampled over ~500ms windows and exponentially smoothed so the
    // displayed value is steady rather than jumping on every progress event.
    var lastTime = DateTime.now();
    var lastReceived = existingBytes;
    var bytesPerSecond = 0.0;

    try {
      final headers = <String, dynamic>{};
      if (existingBytes > 0) headers['Range'] = 'bytes=$existingBytes-';
      if (hfToken != null) headers['Authorization'] = 'Bearer $hfToken';

      await _dio.download(
        downloadUrl,
        savePath,
        cancelToken: cancelToken,
        deleteOnError: false,
        fileAccessMode:
            existingBytes > 0 ? FileAccessMode.append : FileAccessMode.write,
        options: headers.isEmpty ? null : Options(headers: headers),
        onReceiveProgress: (received, total) {
          if (total <= 0) return; // server sent no Content-Length
          final totalEffective = total + existingBytes;
          final receivedEffective = received + existingBytes;

          final now = DateTime.now();
          final elapsedMs = now.difference(lastTime).inMilliseconds;
          if (elapsedMs >= 500) {
            final instant =
                (receivedEffective - lastReceived) / (elapsedMs / 1000.0);
            bytesPerSecond = bytesPerSecond == 0
                ? instant
                : bytesPerSecond * 0.6 + instant * 0.4;
            lastTime = now;
            lastReceived = receivedEffective;
          }
          onProgress(receivedEffective / totalEffective, bytesPerSecond);
        },
      );
      return savePath;
    } finally {
      _tokens.remove(model.id);
    }
  }

  /// Cancel an in-progress download.
  /// The partial file is retained (deleteOnError: false) for future resume.
  void cancelDownload(String modelId) {
    _tokens[modelId]?.cancel('User cancelled download');
    _tokens.remove(modelId);
  }

  bool isDownloading(String modelId) => _tokens.containsKey(modelId);
}
