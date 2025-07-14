import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'flashCards.dart'; // Your model path

Future<List<Flashcard>> parseFlashcardsFromFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result != null && result.files.single.path != null) {
    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    final List<dynamic> jsonData = json.decode(jsonString);

    return jsonData.map((item) {
      return Flashcard(question: item['question'], answer: item['answer']);
    }).toList();
  } else {
    throw Exception("No file selected.");
  }
}

Future<String?> promptForTopicName(BuildContext context) async {
  String topicName = '';
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Enter Topic Name'),
      content: TextField(
        onChanged: (value) => topicName = value,
        decoration: const InputDecoration(hintText: "e.g., Chemistry 101"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, topicName),
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
