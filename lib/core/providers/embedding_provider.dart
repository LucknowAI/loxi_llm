import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/embedding_service.dart';

part 'embedding_provider.g.dart';

/// Provides an initialized [EmbeddingService].
///
/// Returns `AsyncValue<EmbeddingService>` — callers must handle loading state.
/// keepAlive: true — service persists for app lifetime; ONNX session is ~34MB.
@Riverpod(keepAlive: true)
Future<EmbeddingService> embeddingService(Ref ref) async {
  final service = EmbeddingService();
  await service.init();
  ref.onDispose(service.dispose);
  return service;
}
