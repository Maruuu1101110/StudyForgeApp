import 'package:flutter/material.dart';

class Questions {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final Color? themeColor;

  Questions({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.themeColor,
  });
}
