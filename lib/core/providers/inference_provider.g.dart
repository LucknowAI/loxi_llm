// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inference_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$inferenceNotifierHash() => r'2e05ee824bc11575243728feea6f917c426a0614';

/// Manages the lifecycle of the currently loaded [InferenceBackend].
///
/// State: `AsyncData(null)` = no model loaded
///        `AsyncData(backend)` = model loaded and ready
///        `AsyncLoading()` = model is initializing
///        `AsyncError(...)` = initialization failed
///
/// keepAlive: true — the loaded backend must survive tab navigation.
///
/// Copied from [InferenceNotifier].
@ProviderFor(InferenceNotifier)
final inferenceNotifierProvider =
    AsyncNotifierProvider<InferenceNotifier, InferenceBackend?>.internal(
  InferenceNotifier.new,
  name: r'inferenceNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inferenceNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$InferenceNotifier = AsyncNotifier<InferenceBackend?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
