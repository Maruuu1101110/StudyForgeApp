import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfExtractorService {
  Future<String?> pickAndExtractPdfText() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final document = PdfDocument(inputBytes: bytes);

        String extractedText = PdfTextExtractor(document).extractText();

        document.dispose();
        return extractedText;
      }
    } catch (e) {
      print("PDF extraction error: $e");
    }

    return null;
  }

  Future<String> extractTextFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final extractedText = PdfTextExtractor(document).extractText();

      document.dispose();
      return extractedText;
    } catch (e) {
      print("PDF extraction error: $e");
      return '';
    }
  }
}
