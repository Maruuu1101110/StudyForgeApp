import 'dart:core';
import 'package:study_forge/pages/aurora_pages/aurora_messaging_panel.dart';

class AuroraSession {
  final List<ChatMessage> messages = [];

  void addUserMessage(String content) {
    messages.add(ChatMessage(text: content, isFromAurora: false));
  }

  void addAuroraMessage(String content) {
    messages.add(ChatMessage(text: content, isFromAurora: true));
  }

  void clear() => messages.clear();
}
