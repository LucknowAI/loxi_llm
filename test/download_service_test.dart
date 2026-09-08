import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loki_llm/core/services/download_service.dart';
import 'package:loki_llm/core/services/file_storage_service.dart';
import 'package:loki_llm/features/models/domain/model.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Points [FileStorageService] at a temp directory instead of the real
/// platform application-documents path, so tests can run without a device.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._path);
  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}

/// Records every request it's asked to serve so tests can assert whether
/// [DownloadService] skipped the network call for an already-complete leg.
/// Returns as many zero bytes as the caller configures via [nextBodyLength],
/// as a 206 Partial Content response when a Range header is present.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int nextBodyLength = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final bytes = Uint8List(nextBodyLength);
    final isRange = options.headers.containsKey('Range');
    return ResponseBody.fromBytes(
      bytes,
      isRange ? 206 : 200,
      headers: {
        Headers.contentLengthHeader: ['$nextBodyLength'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tempDir;
  late FileStorageService storage;
  late _RecordingAdapter adapter;
  late DownloadService service;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('download_service_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    storage = FileStorageService();
    adapter = _RecordingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    service = DownloadService(dio, storage);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  Model model({
    required int sizeBytes,
    String filename = 'base.gguf',
    String? mmprojFilename,
    int? mmprojSizeBytes,
  }) =>
      Model(
        id: 'm',
        name: 'm',
        sizeLabel: '',
        sizeBytes: sizeBytes,
        filename: filename,
        mmprojFilename: mmprojFilename,
        mmprojSizeBytes: mmprojSizeBytes,
      );

  Future<String> modelPath(String filename) => storage.getModelPath(filename);

  Future<void> writeFile(String path, int length) async {
    await File(path).create(recursive: true);
    await File(path).writeAsBytes(Uint8List(length));
  }

  test('base file already fully on disk, mmproj missing entirely: base leg '
      'makes no request, mmproj leg is requested with no Range header', () async {
    await writeFile(await modelPath('base.gguf'), 10);
    adapter.nextBodyLength = 5;

    final result = await service.downloadModel(
      model: model(
        sizeBytes: 10,
        mmprojFilename: 'mmproj.gguf',
        mmprojSizeBytes: 5,
      ),
      downloadUrl: 'https://example.test/base',
      mmprojDownloadUrl: 'https://example.test/mmproj',
      onProgress: (_, __) {},
    );

    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.headers.containsKey('Range'), isFalse);
    expect(File(result.modelPath).lengthSync(), 10);
    expect(File(result.mmprojPath!).lengthSync(), 5);
  });

  test('base file on disk larger than model.sizeBytes (stale catalog size): '
      'still skipped, not re-requested', () async {
    await writeFile(await modelPath('base.gguf'), 12);

    final result = await service.downloadModel(
      model: model(sizeBytes: 10),
      downloadUrl: 'https://example.test/base',
      onProgress: (_, __) {},
    );

    expect(adapter.requests, isEmpty);
    expect(File(result.modelPath).lengthSync(), 12);
  });

  test('both legs already complete: downloadModel resolves with no requests '
      'at all', () async {
    await writeFile(await modelPath('base.gguf'), 10);
    await writeFile(await modelPath('mmproj.gguf'), 5);

    final result = await service.downloadModel(
      model: model(
        sizeBytes: 10,
        mmprojFilename: 'mmproj.gguf',
        mmprojSizeBytes: 5,
      ),
      downloadUrl: 'https://example.test/base',
      mmprojDownloadUrl: 'https://example.test/mmproj',
      onProgress: (_, __) {},
    );

    expect(adapter.requests, isEmpty);
    expect(result.modelPath, isNotNull);
    expect(result.mmprojPath, isNotNull);
  });

  test('partial mmproj file present: resumed with a Range header from the '
      'existing byte offset, not skipped', () async {
    await writeFile(await modelPath('base.gguf'), 10);
    await writeFile(await modelPath('mmproj.gguf'), 3);
    adapter.nextBodyLength = 5; // remaining bytes for an 8-byte mmproj file

    final result = await service.downloadModel(
      model: model(
        sizeBytes: 10,
        mmprojFilename: 'mmproj.gguf',
        mmprojSizeBytes: 8,
      ),
      downloadUrl: 'https://example.test/base',
      mmprojDownloadUrl: 'https://example.test/mmproj',
      onProgress: (_, __) {},
    );

    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.headers['Range'], 'bytes=3-');
    expect(File(result.mmprojPath!).lengthSync(), 8);
  });

  test('expectedSizeBytes of 0 never skips, even if an on-disk file is '
      'already non-empty', () async {
    await writeFile(await modelPath('base.gguf'), 5);
    adapter.nextBodyLength = 3;

    await service.downloadModel(
      model: model(sizeBytes: 0),
      downloadUrl: 'https://example.test/base',
      onProgress: (_, __) {},
    );

    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.headers['Range'], 'bytes=5-');
  });
}
