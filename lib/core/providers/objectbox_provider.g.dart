// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'objectbox_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$objectBoxStoreHash() => r'e5f963a252997268aa2e0c09e6dfb1386189fdc9';

/// Overridden in main() with the real Store instance.
/// keepAlive: true — store must never be disposed.
///
/// Copied from [objectBoxStore].
@ProviderFor(objectBoxStore)
final objectBoxStoreProvider = Provider<Store>.internal(
  objectBoxStore,
  name: r'objectBoxStoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$objectBoxStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ObjectBoxStoreRef = ProviderRef<Store>;
String _$modelBoxHash() => r'6eebace962b13ec82399b2ee180e3a563f92f113';

/// Box<ModelEntity> — derived from the store.
///
/// Copied from [modelBox].
@ProviderFor(modelBox)
final modelBoxProvider = Provider<Box<ModelEntity>>.internal(
  modelBox,
  name: r'modelBoxProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$modelBoxHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ModelBoxRef = ProviderRef<Box<ModelEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
