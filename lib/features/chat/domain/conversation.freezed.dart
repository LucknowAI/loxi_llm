// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Conversation _$ConversationFromJson(Map<String, dynamic> json) {
  return _Conversation.fromJson(json);
}

/// @nodoc
mixin _$Conversation {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get systemPrompt => throw _privateConstructorUsedError;
  String get modelId => throw _privateConstructorUsedError;
  int get createdAtMs => throw _privateConstructorUsedError;
  int get updatedAtMs => throw _privateConstructorUsedError;
  bool get ragEnabled => throw _privateConstructorUsedError;
  bool get toolsEnabled => throw _privateConstructorUsedError;

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationCopyWith<Conversation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationCopyWith<$Res> {
  factory $ConversationCopyWith(
          Conversation value, $Res Function(Conversation) then) =
      _$ConversationCopyWithImpl<$Res, Conversation>;
  @useResult
  $Res call(
      {String id,
      String title,
      String systemPrompt,
      String modelId,
      int createdAtMs,
      int updatedAtMs,
      bool ragEnabled,
      bool toolsEnabled});
}

/// @nodoc
class _$ConversationCopyWithImpl<$Res, $Val extends Conversation>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? systemPrompt = null,
    Object? modelId = null,
    Object? createdAtMs = null,
    Object? updatedAtMs = null,
    Object? ragEnabled = null,
    Object? toolsEnabled = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      systemPrompt: null == systemPrompt
          ? _value.systemPrompt
          : systemPrompt // ignore: cast_nullable_to_non_nullable
              as String,
      modelId: null == modelId
          ? _value.modelId
          : modelId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAtMs: null == createdAtMs
          ? _value.createdAtMs
          : createdAtMs // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAtMs: null == updatedAtMs
          ? _value.updatedAtMs
          : updatedAtMs // ignore: cast_nullable_to_non_nullable
              as int,
      ragEnabled: null == ragEnabled
          ? _value.ragEnabled
          : ragEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      toolsEnabled: null == toolsEnabled
          ? _value.toolsEnabled
          : toolsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConversationImplCopyWith<$Res>
    implements $ConversationCopyWith<$Res> {
  factory _$$ConversationImplCopyWith(
          _$ConversationImpl value, $Res Function(_$ConversationImpl) then) =
      __$$ConversationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String systemPrompt,
      String modelId,
      int createdAtMs,
      int updatedAtMs,
      bool ragEnabled,
      bool toolsEnabled});
}

/// @nodoc
class __$$ConversationImplCopyWithImpl<$Res>
    extends _$ConversationCopyWithImpl<$Res, _$ConversationImpl>
    implements _$$ConversationImplCopyWith<$Res> {
  __$$ConversationImplCopyWithImpl(
      _$ConversationImpl _value, $Res Function(_$ConversationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? systemPrompt = null,
    Object? modelId = null,
    Object? createdAtMs = null,
    Object? updatedAtMs = null,
    Object? ragEnabled = null,
    Object? toolsEnabled = null,
  }) {
    return _then(_$ConversationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      systemPrompt: null == systemPrompt
          ? _value.systemPrompt
          : systemPrompt // ignore: cast_nullable_to_non_nullable
              as String,
      modelId: null == modelId
          ? _value.modelId
          : modelId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAtMs: null == createdAtMs
          ? _value.createdAtMs
          : createdAtMs // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAtMs: null == updatedAtMs
          ? _value.updatedAtMs
          : updatedAtMs // ignore: cast_nullable_to_non_nullable
              as int,
      ragEnabled: null == ragEnabled
          ? _value.ragEnabled
          : ragEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      toolsEnabled: null == toolsEnabled
          ? _value.toolsEnabled
          : toolsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationImpl extends _Conversation {
  const _$ConversationImpl(
      {required this.id,
      required this.title,
      this.systemPrompt = '',
      this.modelId = '',
      required this.createdAtMs,
      required this.updatedAtMs,
      this.ragEnabled = false,
      this.toolsEnabled = false})
      : super._();

  factory _$ConversationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey()
  final String systemPrompt;
  @override
  @JsonKey()
  final String modelId;
  @override
  final int createdAtMs;
  @override
  final int updatedAtMs;
  @override
  @JsonKey()
  final bool ragEnabled;
  @override
  @JsonKey()
  final bool toolsEnabled;

  @override
  String toString() {
    return 'Conversation(id: $id, title: $title, systemPrompt: $systemPrompt, modelId: $modelId, createdAtMs: $createdAtMs, updatedAtMs: $updatedAtMs, ragEnabled: $ragEnabled, toolsEnabled: $toolsEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.systemPrompt, systemPrompt) ||
                other.systemPrompt == systemPrompt) &&
            (identical(other.modelId, modelId) || other.modelId == modelId) &&
            (identical(other.createdAtMs, createdAtMs) ||
                other.createdAtMs == createdAtMs) &&
            (identical(other.updatedAtMs, updatedAtMs) ||
                other.updatedAtMs == updatedAtMs) &&
            (identical(other.ragEnabled, ragEnabled) ||
                other.ragEnabled == ragEnabled) &&
            (identical(other.toolsEnabled, toolsEnabled) ||
                other.toolsEnabled == toolsEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, systemPrompt, modelId,
      createdAtMs, updatedAtMs, ragEnabled, toolsEnabled);

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      __$$ConversationImplCopyWithImpl<_$ConversationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationImplToJson(
      this,
    );
  }
}

abstract class _Conversation extends Conversation {
  const factory _Conversation(
      {required final String id,
      required final String title,
      final String systemPrompt,
      final String modelId,
      required final int createdAtMs,
      required final int updatedAtMs,
      final bool ragEnabled,
      final bool toolsEnabled}) = _$ConversationImpl;
  const _Conversation._() : super._();

  factory _Conversation.fromJson(Map<String, dynamic> json) =
      _$ConversationImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get systemPrompt;
  @override
  String get modelId;
  @override
  int get createdAtMs;
  @override
  int get updatedAtMs;
  @override
  bool get ragEnabled;
  @override
  bool get toolsEnabled;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
