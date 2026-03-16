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
String _$conversationBoxHash() => r'af79e62ea40f3ea7b6936f04fc1b738466749387';

/// See also [conversationBox].
@ProviderFor(conversationBox)
final conversationBoxProvider = Provider<Box<ConversationEntity>>.internal(
  conversationBox,
  name: r'conversationBoxProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$conversationBoxHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConversationBoxRef = ProviderRef<Box<ConversationEntity>>;
String _$messageBoxHash() => r'30e134e966a4705b7e1a684ac0cb063ad881fdda';

/// See also [messageBox].
@ProviderFor(messageBox)
final messageBoxProvider = Provider<Box<MessageEntity>>.internal(
  messageBox,
  name: r'messageBoxProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$messageBoxHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessageBoxRef = ProviderRef<Box<MessageEntity>>;
String _$documentChunkBoxHash() => r'ada884f65ea25de83da39b3d0f232eb6dec81b38';

/// See also [documentChunkBox].
@ProviderFor(documentChunkBox)
final documentChunkBoxProvider = Provider<Box<DocumentChunkEntity>>.internal(
  documentChunkBox,
  name: r'documentChunkBoxProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$documentChunkBoxHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DocumentChunkBoxRef = ProviderRef<Box<DocumentChunkEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
