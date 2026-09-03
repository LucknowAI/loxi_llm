import 'dart:io';
import 'package:dio/dio.dart';
import '../../features/models/domain/model.dart';
import 'file_storage_service.dart';

/// Combines per-file download fractions into a single overall progress
/// value, weighted by each file's share of the combined byte count.
///
/// Pure and side-effect free so the weighting math is unit-testable without
/// a real download. When [mmprojSizeBytes] is 0 (no companion file), this
/// reduces to [baseFraction].
double combinedDownloadProgress({
  required double baseFraction,
  required double mmprojFraction,
  required int baseSizeBytes,
  required int mmprojSizeBytes,
}) {
  final total = baseSizeBytes + mmprojSizeBytes;
  if (total <= 0) return baseFraction;
  final baseWeight = baseSizeBytes / total;
  final mmprojWeight = mmprojSizeBytes / total;
  return baseFraction * baseWeight + mmprojFraction * mmprojWeight;
}

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

  /// Download [model] (and, when present, its mmproj vision-projector
  /// companion file) from HuggingFace to the app documents directory.
  ///
  /// [downloadUrl] must be a direct CDN URL (use [huggingFaceDownloadUrl]).
  /// [mmprojDownloadUrl] downloads the companion file (use
  /// [huggingFaceMmprojDownloadUrl]) sequentially after the base file, only
  /// when both it and `model.mmprojFilename` are non-null.
  /// [onProgress] receives the combined fraction in [0.0, 1.0] (size-weighted
  /// across both files when a mmproj download is in progress) and a smoothed
  /// download speed in bytes/second (0 until the first sample window elapses).
  /// Throws [DioException] on network errors; check [CancelToken.isCancel] for user cancels.
  Future<({String modelPath, String? mmprojPath})> downloadModel({
    required Model model,
    required String downloadUrl,
    required void Function(double progress, double bytesPerSecond) onProgress,
    String? mmprojDownloadUrl,
    String? hfToken,
  }) async {
    final hasMmproj = mmprojDownloadUrl != null && model.mmprojFilename != null;
    final baseSizeBytes = model.sizeBytes;
    final mmprojSizeBytes = hasMmproj ? (model.mmprojSizeBytes ?? 0) : 0;

    var baseFraction = 0.0;
    var mmprojFraction = 0.0;
    void reportCombined(double bytesPerSecond) {
      final combined = hasMmproj
          ? combinedDownloadProgress(
              baseFraction: baseFraction,
              mmprojFraction: mmprojFraction,
              baseSizeBytes: baseSizeBytes,
              mmprojSizeBytes: mmprojSizeBytes,
            )
          : baseFraction;
      onProgress(combined, bytesPerSecond);
    }

    final cancelToken = CancelToken();
    _tokens[model.id] = cancelToken;

    try {
      final modelPath = await _downloadFile(
        filename: model.filename!,
        url: downloadUrl,
        cancelToken: cancelToken,
        hfToken: hfToken,
        onProgress: (progress, bytesPerSecond) {
          baseFraction = progress;
          reportCombined(bytesPerSecond);
        },
      );

      String? mmprojPath;
      if (hasMmproj) {
        mmprojPath = await _downloadFile(
          filename: model.mmprojFilename!,
          url: mmprojDownloadUrl,
          cancelToken: cancelToken,
          hfToken: hfToken,
          onProgress: (progress, bytesPerSecond) {
            mmprojFraction = progress;
            reportCombined(bytesPerSecond);
          },
        );
      }

      return (modelPath: modelPath, mmprojPath: mmprojPath);
    } finally {
      _tokens.remove(model.id);
    }
  }

  /// Downloads a single file to the app's model directory, reporting its own
  /// fraction in [0.0, 1.0] via [onProgress]. Shared by the base model and
  /// mmproj legs of [downloadModel].
  Future<String> _downloadFile({
    required String filename,
    required String url,
    required CancelToken cancelToken,
    required void Function(double progress, double bytesPerSecond) onProgress,
    String? hfToken,
  }) async {
    final savePath = await _storage.getModelPath(filename);
    final file = File(savePath);
    final existingBytes = file.existsSync() ? file.lengthSync() : 0;

    // Speed is sampled over ~500ms windows and exponentially smoothed so the
    // displayed value is steady rather than jumping on every progress event.
    var lastTime = DateTime.now();
    var lastReceived = existingBytes;
    var bytesPerSecond = 0.0;

    final headers = <String, dynamic>{};
    if (existingBytes > 0) headers['Range'] = 'bytes=$existingBytes-';
    if (hfToken != null) headers['Authorization'] = 'Bearer $hfToken';

    await _dio.download(
      url,
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
  }

  /// Cancel an in-progress download.
  /// The partial file is retained (deleteOnError: false) for future resume.
  void cancelDownload(String modelId) {
    _tokens[modelId]?.cancel('User cancelled download');
    _tokens.remove(modelId);
  }

  bool isDownloading(String modelId) => _tokens.containsKey(modelId);
}
