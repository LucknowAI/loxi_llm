// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Message _$MessageFromJson(Map<String, dynamic> json) {
  return _Message.fromJson(json);
}

/// @nodoc
mixin _$Message {
  String get id => throw _privateConstructorUsedError;
  String get conversationId => throw _privateConstructorUsedError;
  MessageRole get role => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  int get createdAtMs =>
      throw _privateConstructorUsedError; // DateTime.now().millisecondsSinceEpoch
  String? get imagePath => throw _privateConstructorUsedError;

  /// Same model-call numbers as the Model I/O log line for this reply.
  /// Null on older messages and on user turns.
  int? get tokenCount => throw _privateConstructorUsedError;
  int? get timeToFirstTokenMs => throw _privateConstructorUsedError;
  int? get totalDurationMs => throw _privateConstructorUsedError;

  /// Send until the reply was saved, including a summary or tool calls.
  /// [totalDurationMs] stays the model call, which is what tok/s uses.
  int? get replyWaitMs => throw _privateConstructorUsedError;

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageCopyWith<Message> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
  @useResult
  $Res call(
      {String id,
      String conversationId,
      MessageRole role,
      String content,
      int createdAtMs,
      String? imagePath,
      int? tokenCount,
      int? timeToFirstTokenMs,
      int? totalDurationMs,
      int? replyWaitMs});
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? role = null,
    Object? content = null,
    Object? createdAtMs = null,
    Object? imagePath = freezed,
    Object? tokenCount = freezed,
    Object? timeToFirstTokenMs = freezed,
    Object? totalDurationMs = freezed,
    Object? replyWaitMs = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MessageRole,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAtMs: null == createdAtMs
          ? _value.createdAtMs
          : createdAtMs // ignore: cast_nullable_to_non_nullable
              as int,
      imagePath: freezed == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenCount: freezed == tokenCount
          ? _value.tokenCount
          : tokenCount // ignore: cast_nullable_to_non_nullable
              as int?,
      timeToFirstTokenMs: freezed == timeToFirstTokenMs
          ? _value.timeToFirstTokenMs
          : timeToFirstTokenMs // ignore: cast_nullable_to_non_nullable
              as int?,
      totalDurationMs: freezed == totalDurationMs
          ? _value.totalDurationMs
          : totalDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      replyWaitMs: freezed == replyWaitMs
          ? _value.replyWaitMs
          : replyWaitMs // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MessageImplCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$$MessageImplCopyWith(
          _$MessageImpl value, $Res Function(_$MessageImpl) then) =
      __$$MessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String conversationId,
      MessageRole role,
      String content,
      int createdAtMs,
      String? imagePath,
      int? tokenCount,
      int? timeToFirstTokenMs,
      int? totalDurationMs,
      int? replyWaitMs});
}

/// @nodoc
class __$$MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$MessageImpl>
    implements _$$MessageImplCopyWith<$Res> {
  __$$MessageImplCopyWithImpl(
      _$MessageImpl _value, $Res Function(_$MessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? role = null,
    Object? content = null,
    Object? createdAtMs = null,
    Object? imagePath = freezed,
    Object? tokenCount = freezed,
    Object? timeToFirstTokenMs = freezed,
    Object? totalDurationMs = freezed,
    Object? replyWaitMs = freezed,
  }) {
    return _then(_$MessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MessageRole,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAtMs: null == createdAtMs
          ? _value.createdAtMs
          : createdAtMs // ignore: cast_nullable_to_non_nullable
              as int,
      imagePath: freezed == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenCount: freezed == tokenCount
          ? _value.tokenCount
          : tokenCount // ignore: cast_nullable_to_non_nullable
              as int?,
      timeToFirstTokenMs: freezed == timeToFirstTokenMs
          ? _value.timeToFirstTokenMs
          : timeToFirstTokenMs // ignore: cast_nullable_to_non_nullable
              as int?,
      totalDurationMs: freezed == totalDurationMs
          ? _value.totalDurationMs
          : totalDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      replyWaitMs: freezed == replyWaitMs
          ? _value.replyWaitMs
          : replyWaitMs // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageImpl extends _Message {
  const _$MessageImpl(
      {required this.id,
      required this.conversationId,
      required this.role,
      required this.content,
      required this.createdAtMs,
      this.imagePath,
      this.tokenCount,
      this.timeToFirstTokenMs,
      this.totalDurationMs,
      this.replyWaitMs})
      : super._();

  factory _$MessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageImplFromJson(json);

  @override
  final String id;
  @override
  final String conversationId;
  @override
  final MessageRole role;
  @override
  final String content;
  @override
  final int createdAtMs;
// DateTime.now().millisecondsSinceEpoch
  @override
  final String? imagePath;

  /// Same model-call numbers as the Model I/O log line for this reply.
  /// Null on older messages and on user turns.
  @override
  final int? tokenCount;
  @override
  final int? timeToFirstTokenMs;
  @override
  final int? totalDurationMs;

  /// Send until the reply was saved, including a summary or tool calls.
  /// [totalDurationMs] stays the model call, which is what tok/s uses.
  @override
  final int? replyWaitMs;

  @override
  String toString() {
    return 'Message(id: $id, conversationId: $conversationId, role: $role, content: $content, createdAtMs: $createdAtMs, imagePath: $imagePath, tokenCount: $tokenCount, timeToFirstTokenMs: $timeToFirstTokenMs, totalDurationMs: $totalDurationMs, replyWaitMs: $replyWaitMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAtMs, createdAtMs) ||
                other.createdAtMs == createdAtMs) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.tokenCount, tokenCount) ||
                other.tokenCount == tokenCount) &&
            (identical(other.timeToFirstTokenMs, timeToFirstTokenMs) ||
                other.timeToFirstTokenMs == timeToFirstTokenMs) &&
            (identical(other.totalDurationMs, totalDurationMs) ||
                other.totalDurationMs == totalDurationMs) &&
            (identical(other.replyWaitMs, replyWaitMs) ||
                other.replyWaitMs == replyWaitMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      conversationId,
      role,
      content,
      createdAtMs,
      imagePath,
      tokenCount,
      timeToFirstTokenMs,
      totalDurationMs,
      replyWaitMs);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      __$$MessageImplCopyWithImpl<_$MessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageImplToJson(
      this,
    );
  }
}

abstract class _Message extends Message {
  const factory _Message(
      {required final String id,
      required final String conversationId,
      required final MessageRole role,
      required final String content,
      required final int createdAtMs,
      final String? imagePath,
      final int? tokenCount,
      final int? timeToFirstTokenMs,
      final int? totalDurationMs,
      final int? replyWaitMs}) = _$MessageImpl;
  const _Message._() : super._();

  factory _Message.fromJson(Map<String, dynamic> json) = _$MessageImpl.fromJson;

  @override
  String get id;
  @override
  String get conversationId;
  @override
  MessageRole get role;
  @override
  String get content;
  @override
  int get createdAtMs; // DateTime.now().millisecondsSinceEpoch
  @override
  String? get imagePath;

  /// Same model-call numbers as the Model I/O log line for this reply.
  /// Null on older messages and on user turns.
  @override
  int? get tokenCount;
  @override
  int? get timeToFirstTokenMs;
  @override
  int? get totalDurationMs;

  /// Send until the reply was saved, including a summary or tool calls.
  /// [totalDurationMs] stays the model call, which is what tok/s uses.
  @override
  int? get replyWaitMs;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
