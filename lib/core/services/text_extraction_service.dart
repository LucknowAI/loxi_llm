import 'dart:io';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:docx_to_text/docx_to_text.dart';

/// Extracts plain text from PDF, DOCX, and TXT files.
class TextExtractionService {
  /// Extract all text from [filePath]. Returns the full document as a single String.
  ///
  /// Delegates by extension: .pdf → PDFKit/PdfBox, .docx → docx_to_text, else → dart:io.
  Future<String> extractText(String filePath) async {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.pdf')) return _extractPdf(filePath);
    if (lower.endsWith('.docx')) return _extractDocx(filePath);
    return File(filePath).readAsString();
  }

  Future<String> _extractPdf(String filePath) async {
    final doc = await PDFDoc.fromPath(filePath);
    return doc.text;
  }

  Future<String> _extractDocx(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return docxToText(bytes); // synchronous conversion
  }
}
