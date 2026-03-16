// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'embedding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$embeddingServiceHash() => r'3beecb6efcd01d997015675c9484265fddc4ca67';

/// Provides an initialized [EmbeddingService].
///
/// Returns `AsyncValue<EmbeddingService>` — callers must handle loading state.
/// keepAlive: true — service persists for app lifetime; ONNX session is ~34MB.
///
/// Copied from [embeddingService].
@ProviderFor(embeddingService)
final embeddingServiceProvider = FutureProvider<EmbeddingService>.internal(
  embeddingService,
  name: r'embeddingServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$embeddingServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EmbeddingServiceRef = FutureProviderRef<EmbeddingService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
