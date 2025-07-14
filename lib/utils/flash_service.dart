import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'file_manager_service.dart';
import 'package:study_forge/pages/room_pages/flashCardMaterials/flashCards.dart';

class FlashcardService {
  static Future<void> saveFlashcardSet({
    required int roomId,
    required String setName,
    required List<Flashcard> cards,
  }) async {
    final dirPath = await FileManagerService.instance.getFlashCardPath(roomId);
    final file = File(path.join(dirPath, '$setName.json'));

    final jsonData = cards
        .map((card) => {'question': card.question, 'answer': card.answer})
        .toList();

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonData),
    );
  }

  static Future<List<Flashcard>> loadFlashcardSet({
    required int roomId,
    required String setName,
  }) async {
    final dirPath = await FileManagerService.instance.getFlashCardPath(roomId);
    final file = File(path.join(dirPath, '$setName.json'));

    if (!await file.exists()) throw Exception('Flashcard file not found.');

    final jsonString = await file.readAsString();
    final List<dynamic> jsonData = json.decode(jsonString);

    return jsonData
        .map(
          (item) =>
              Flashcard(question: item['question'], answer: item['answer']),
        )
        .toList();
  }

  static Future<List<String>> listFlashcardSets(int roomId) async {
    final dirPath = await FileManagerService.instance.getFlashCardPath(roomId);
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final files = dir.listSync().whereType<File>();
    return files
        .where((f) => f.path.endsWith('.json'))
        .map((f) => path.basenameWithoutExtension(f.path))
        .toList();
  }
}
