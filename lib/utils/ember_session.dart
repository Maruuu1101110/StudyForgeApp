import 'dart:core';
import 'package:study_forge/pages/ember_pages/chat_provider.dart';

class EmberSession {
  final List<ChatMessage> messages = [];

  void addUserMessage(String content) {
    messages.add(ChatMessage(text: content, isFromEmber: false));
  }

  void addEmberMessage(String content) {
    messages.add(ChatMessage(text: content, isFromEmber: true));
  }

  void clear() => messages.clear();
}
