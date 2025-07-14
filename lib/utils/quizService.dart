import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'file_manager_service.dart';
import 'package:study_forge/pages/room_pages/quizMaterials/questions.dart';

class QuizService {
  static Future<void> saveQuizzesSet({
    required int roomId,
    required String setName,
    required List<Questions> questions,
  }) async {
    final dirPath = await FileManagerService.instance.getQuizzesPath(roomId);
    final file = File(path.join(dirPath, '$setName.json'));

    final jsonData = questions
        .map(
          (questions) => {
            'question': questions.question,
            'options': questions.options,
            'correctAnswer': questions.correctAnswer,
          },
        )
        .toList();

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonData),
    );
  }

  static Future<List<Questions>> loadQuizSet({
    required int roomId,
    required String quizName,
  }) async {
    final dirPath = await FileManagerService.instance.getQuizzesPath(roomId);
    final file = File(path.join(dirPath, '$quizName.json'));

    if (!await file.exists()) throw Exception('Quiz file not found.');

    final jsonString = await file.readAsString();
    final List<dynamic> jsonData = json.decode(jsonString);

    return jsonData
        .map(
          (item) => Questions(
            question: item["question"],
            options: List<String>.from(item["options"]),
            correctAnswer: item["correctAnswer"],
          ),
        )
        .toList();
  }
}
