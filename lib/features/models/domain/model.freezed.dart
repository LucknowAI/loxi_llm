// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Model _$ModelFromJson(Map<String, dynamic> json) {
  return _Model.fromJson(json);
}

/// @nodoc
mixin _$Model {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get sizeLabel => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;
  ModelStatus get status => throw _privateConstructorUsedError;
  double get downloadProgress => throw _privateConstructorUsedError;
  String? get localPath => throw _privateConstructorUsedError;
  String? get huggingFaceRepo => throw _privateConstructorUsedError;
  String? get filename => throw _privateConstructorUsedError;
  String get format => throw _privateConstructorUsedError;

  /// Serializes this Model to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Model
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelCopyWith<Model> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelCopyWith<$Res> {
  factory $ModelCopyWith(Model value, $Res Function(Model) then) =
      _$ModelCopyWithImpl<$Res, Model>;
  @useResult
  $Res call(
      {String id,
      String name,
      String sizeLabel,
      int sizeBytes,
      ModelStatus status,
      double downloadProgress,
      String? localPath,
      String? huggingFaceRepo,
      String? filename,
      String format});
}

/// @nodoc
class _$ModelCopyWithImpl<$Res, $Val extends Model>
    implements $ModelCopyWith<$Res> {
  _$ModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Model
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? sizeLabel = null,
    Object? sizeBytes = null,
    Object? status = null,
    Object? downloadProgress = null,
    Object? localPath = freezed,
    Object? huggingFaceRepo = freezed,
    Object? filename = freezed,
    Object? format = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sizeLabel: null == sizeLabel
          ? _value.sizeLabel
          : sizeLabel // ignore: cast_nullable_to_non_nullable
              as String,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ModelStatus,
      downloadProgress: null == downloadProgress
          ? _value.downloadProgress
          : downloadProgress // ignore: cast_nullable_to_non_nullable
              as double,
      localPath: freezed == localPath
          ? _value.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String?,
      huggingFaceRepo: freezed == huggingFaceRepo
          ? _value.huggingFaceRepo
          : huggingFaceRepo // ignore: cast_nullable_to_non_nullable
              as String?,
      filename: freezed == filename
          ? _value.filename
          : filename // ignore: cast_nullable_to_non_nullable
              as String?,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelImplCopyWith<$Res> implements $ModelCopyWith<$Res> {
  factory _$$ModelImplCopyWith(
          _$ModelImpl value, $Res Function(_$ModelImpl) then) =
      __$$ModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String sizeLabel,
      int sizeBytes,
      ModelStatus status,
      double downloadProgress,
      String? localPath,
      String? huggingFaceRepo,
      String? filename,
      String format});
}

/// @nodoc
class __$$ModelImplCopyWithImpl<$Res>
    extends _$ModelCopyWithImpl<$Res, _$ModelImpl>
    implements _$$ModelImplCopyWith<$Res> {
  __$$ModelImplCopyWithImpl(
      _$ModelImpl _value, $Res Function(_$ModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of Model
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? sizeLabel = null,
    Object? sizeBytes = null,
    Object? status = null,
    Object? downloadProgress = null,
    Object? localPath = freezed,
    Object? huggingFaceRepo = freezed,
    Object? filename = freezed,
    Object? format = null,
  }) {
    return _then(_$ModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sizeLabel: null == sizeLabel
          ? _value.sizeLabel
          : sizeLabel // ignore: cast_nullable_to_non_nullable
              as String,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ModelStatus,
      downloadProgress: null == downloadProgress
          ? _value.downloadProgress
          : downloadProgress // ignore: cast_nullable_to_non_nullable
              as double,
      localPath: freezed == localPath
          ? _value.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String?,
      huggingFaceRepo: freezed == huggingFaceRepo
          ? _value.huggingFaceRepo
          : huggingFaceRepo // ignore: cast_nullable_to_non_nullable
              as String?,
      filename: freezed == filename
          ? _value.filename
          : filename // ignore: cast_nullable_to_non_nullable
              as String?,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelImpl extends _Model {
  const _$ModelImpl(
      {required this.id,
      required this.name,
      required this.sizeLabel,
      required this.sizeBytes,
      this.status = ModelStatus.available,
      this.downloadProgress = 0.0,
      this.localPath,
      this.huggingFaceRepo,
      this.filename,
      this.format = 'gguf'})
      : super._();

  factory _$ModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String sizeLabel;
  @override
  final int sizeBytes;
  @override
  @JsonKey()
  final ModelStatus status;
  @override
  @JsonKey()
  final double downloadProgress;
  @override
  final String? localPath;
  @override
  final String? huggingFaceRepo;
  @override
  final String? filename;
  @override
  @JsonKey()
  final String format;

  @override
  String toString() {
    return 'Model(id: $id, name: $name, sizeLabel: $sizeLabel, sizeBytes: $sizeBytes, status: $status, downloadProgress: $downloadProgress, localPath: $localPath, huggingFaceRepo: $huggingFaceRepo, filename: $filename, format: $format)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sizeLabel, sizeLabel) ||
                other.sizeLabel == sizeLabel) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.downloadProgress, downloadProgress) ||
                other.downloadProgress == downloadProgress) &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath) &&
            (identical(other.huggingFaceRepo, huggingFaceRepo) ||
                other.huggingFaceRepo == huggingFaceRepo) &&
            (identical(other.filename, filename) ||
                other.filename == filename) &&
            (identical(other.format, format) || other.format == format));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, sizeLabel, sizeBytes,
      status, downloadProgress, localPath, huggingFaceRepo, filename, format);

  /// Create a copy of Model
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelImplCopyWith<_$ModelImpl> get copyWith =>
      __$$ModelImplCopyWithImpl<_$ModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelImplToJson(
      this,
    );
  }
}

abstract class _Model extends Model {
  const factory _Model(
      {required final String id,
      required final String name,
      required final String sizeLabel,
      required final int sizeBytes,
      final ModelStatus status,
      final double downloadProgress,
      final String? localPath,
      final String? huggingFaceRepo,
      final String? filename,
      final String format}) = _$ModelImpl;
  const _Model._() : super._();

  factory _Model.fromJson(Map<String, dynamic> json) = _$ModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get sizeLabel;
  @override
  int get sizeBytes;
  @override
  ModelStatus get status;
  @override
  double get downloadProgress;
  @override
  String? get localPath;
  @override
  String? get huggingFaceRepo;
  @override
  String? get filename;
  @override
  String get format;

  /// Create a copy of Model
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelImplCopyWith<_$ModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
