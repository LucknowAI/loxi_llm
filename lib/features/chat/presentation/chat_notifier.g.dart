// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatNotifierHash() => r'd4fe40f92c90583e7977979f1fc3fe72013f03ee';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ChatNotifier
    extends BuildlessAutoDisposeAsyncNotifier<ChatState> {
  late final String conversationId;

  FutureOr<ChatState> build(
    String conversationId,
  );
}

/// See also [ChatNotifier].
@ProviderFor(ChatNotifier)
const chatNotifierProvider = ChatNotifierFamily();

/// See also [ChatNotifier].
class ChatNotifierFamily extends Family<AsyncValue<ChatState>> {
  /// See also [ChatNotifier].
  const ChatNotifierFamily();

  /// See also [ChatNotifier].
  ChatNotifierProvider call(
    String conversationId,
  ) {
    return ChatNotifierProvider(
      conversationId,
    );
  }

  @override
  ChatNotifierProvider getProviderOverride(
    covariant ChatNotifierProvider provider,
  ) {
    return call(
      provider.conversationId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatNotifierProvider';
}

/// See also [ChatNotifier].
class ChatNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<ChatNotifier, ChatState> {
  /// See also [ChatNotifier].
  ChatNotifierProvider(
    String conversationId,
  ) : this._internal(
          () => ChatNotifier()..conversationId = conversationId,
          from: chatNotifierProvider,
          name: r'chatNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatNotifierHash,
          dependencies: ChatNotifierFamily._dependencies,
          allTransitiveDependencies:
              ChatNotifierFamily._allTransitiveDependencies,
          conversationId: conversationId,
        );

  ChatNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  FutureOr<ChatState> runNotifierBuild(
    covariant ChatNotifier notifier,
  ) {
    return notifier.build(
      conversationId,
    );
  }

  @override
  Override overrideWith(ChatNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatNotifierProvider._internal(
        () => create()..conversationId = conversationId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ChatNotifier, ChatState>
      createElement() {
    return _ChatNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatNotifierProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatNotifierRef on AutoDisposeAsyncNotifierProviderRef<ChatState> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ChatNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ChatNotifier, ChatState>
    with ChatNotifierRef {
  _ChatNotifierProviderElement(super.provider);

  @override
  String get conversationId => (origin as ChatNotifierProvider).conversationId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
