import 'package:freezed_annotation/freezed_annotation.dart';

part 'document.freezed.dart';
part 'document.g.dart';

/// Represents an ingested document in the knowledge base.
@freezed
class Document with _$Document {
  const Document._();

  const factory Document({
    required String id,
    required String name,

    /// File format: pdf | docx | txt
    @Default('txt') String format,

    /// Number of text chunks stored in ObjectBox.
    @Default(0) int chunkCount,

    required int createdAtMs,
  }) = _Document;

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);
}
