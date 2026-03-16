import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum ModelStatus {
  @JsonValue('available')
  available,
  @JsonValue('downloading')
  downloading,
  @JsonValue('paused')
  paused,
  @JsonValue('downloaded')
  downloaded,
  @JsonValue('loading')
  loading,
  @JsonValue('loaded')
  loaded,
  @JsonValue('error')
  error,
}
