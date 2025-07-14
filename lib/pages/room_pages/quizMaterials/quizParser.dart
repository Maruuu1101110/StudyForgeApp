import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:study_forge/pages/room_pages/quizMaterials/questions.dart';

Future<List<Questions>> parseQuizFromFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result != null && result.files.single.path != null) {
    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    final List<dynamic> jsonData = json.decode(jsonString);

    return jsonData.map((item) {
      return Questions(
        question: item['question'],
        options: List<String>.from(item['options']),
        correctAnswer: item['correctAnswer'],
        explanation: item['explanation'],
        themeColor: item['themeColor'] != null
            ? Color(item['themeColor'])
            : null,
      );
    }).toList();
  } else {
    throw Exception("No file selected.");
  }
}
