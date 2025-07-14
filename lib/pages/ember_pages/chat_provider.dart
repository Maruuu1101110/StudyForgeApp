import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

enum MessageStatus { sending, sent, failed }

class ChatMessage {
  final String text;
  final bool isFromEmber;
  final DateTime timestamp;
  final MessageStatus status;
  final String? id;
  final FilePickerResult? isPDF;

  ChatMessage({
    required this.text,
    required this.isFromEmber,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
    this.id,
    this.isPDF,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    bool? isFromEmber,
    String? id,
    MessageStatus? status,
    FilePickerResult? isPDF,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isFromEmber: isFromEmber ?? this.isFromEmber,
      id: id ?? this.id,
      status: status ?? this.status,
      isPDF: isPDF ?? this.isPDF,
    );
  }
}

class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void replaceMessage(int index, ChatMessage newMsg) {
    _messages[index] = newMsg;
    notifyListeners();
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }
}

extension TakeLastExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) return List<T>.from(this);
    return sublist(length - count);
  }
}
