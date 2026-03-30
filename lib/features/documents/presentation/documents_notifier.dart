import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:langchain/langchain.dart' hide Document;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/embedding_provider.dart';
import '../../../core/services/text_extraction_service.dart';
import '../../../features/documents/data/document_chunk_repository.dart';
import '../../../features/documents/data/document_repository.dart';
import '../../../features/documents/domain/document.dart';
import '../../../features/documents/domain/document_chunk.dart';
import '../../settings/presentation/settings_notifier.dart';

part 'documents_notifier.g.dart';

@riverpod
class DocumentsNotifier extends _$DocumentsNotifier {
  @override
  Future<List<Document>> build() async {
    return ref.watch(documentRepositoryProvider).getAll();
  }

  /// Open file picker, then run the ingestion pipeline.
  Future<void> pickAndIngest() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final path = file.path;
    if (path == null) return;
    await _ingest(path, file.name);
  }

  Future<void> _ingest(String filePath, String fileName) async {
    state = const AsyncLoading();
    try {
      // 0. Guard: reject files > 10 MB
      final fileSize = await File(filePath).length();
      if (fileSize > 10 * 1024 * 1024) {
        state = AsyncError(
          'File too large (max 10 MB)',
          StackTrace.current,
        );
        return;
      }

      // 1. Extract text
      final extractor = TextExtractionService();
      final text = await extractor.extractText(filePath);

      // 2. Chunk — use chunkSize from settings
      final chunkSize = ref.read(settingsNotifierProvider).chunkSize;
      final splitter = RecursiveCharacterTextSplitter(
        chunkSize: chunkSize,
        chunkOverlap: 50,
      );
      final chunkTexts = splitter.splitText(text);

      // 3. Persist Document record
      final now = DateTime.now().millisecondsSinceEpoch;
      final docId = 'doc-$now';
      final format = _detectFormat(fileName);
      final doc = Document(
        id: docId,
        name: fileName,
        format: format,
        chunkCount: chunkTexts.length,
        createdAtMs: now,
      );
      ref.read(documentRepositoryProvider).save(doc);

      // 4. Embed each chunk and store
      final embeddingService = ref.read(embeddingServiceProvider).valueOrNull;
      final chunkRepo = ref.read(documentChunkRepositoryProvider);
      final chunks = <DocumentChunk>[];
      for (int i = 0; i < chunkTexts.length; i++) {
        List<double>? embedding;
        if (embeddingService != null && embeddingService.isInitialized) {
          embedding = await embeddingService.embedPassage(chunkTexts[i]);
        }
        chunks.add(DocumentChunk(
          chunkId: 'chunk-$docId-$i',
          documentId: docId,
          content: chunkTexts[i],
          chunkIndex: i,
          createdAtMs: now,
          embedding: embedding,
        ));
      }
      chunkRepo.saveChunks(chunks);

      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteDocument(String documentId) async {
    ref.read(documentRepositoryProvider).delete(documentId);
    ref.read(documentChunkRepositoryProvider).deleteByDocumentId(documentId);
    ref.invalidateSelf();
  }

  String _detectFormat(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'pdf';
    if (lower.endsWith('.docx')) return 'docx';
    return 'txt';
  }
}
