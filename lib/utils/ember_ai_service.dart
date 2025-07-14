import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:study_forge/pages/settingsPage.dart';

class EmberAIService {
  static final EmberAIService _instance = EmberAIService._internal();
  factory EmberAIService() => _instance;
  EmberAIService._internal();

  late String? _baseUrl;
  late String? _accessKey;

  bool _isInitialized = false;

  final _settings = SettingsManager();

  Future<void> init() async {
    _baseUrl = await _settings.getSetting('ember_api_url');
    _accessKey = await _settings.getSetting('ember_api_key');

    _isInitialized = true;
    debugPrint('🔥 EmberAIService initialized with $_baseUrl');
  }

  void _checkInit() {
    if (!_isInitialized) {
      throw StateError("EmberAIService not initialized. Call init() first.");
    }
  }

  Stream<String> sendMessageStream({
    required List<Map<String, String>> messages,
  }) async* {
    _checkInit();

    final uri = Uri.parse(_baseUrl!);

    debugPrint('🛰️ Sending to Ember: ${messages.toString()}');

    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessKey',
      })
      ..body = jsonEncode({
        'messages': messages,
        'stream': true,
        'include_functions_info': false,
        'include_retrieval_info': false,
        'include_guardrails_info': false,
      });

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw Exception(
        '❌ Ember Stream Error: ${streamedResponse.statusCode}\n$errorBody',
      );
    }

    await for (var line
        in streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final jsonString = line.replaceFirst('data: ', '').trim();
        if (jsonString == '[DONE]') break;

        try {
          final data = jsonDecode(jsonString);
          final chunk = data['choices']?[0]?['delta']?['content'];
          if (chunk != null) yield chunk;
        } catch (e) {
          debugPrint('⚠️ Ember chunk parse error: $e');
        }
      }
    }
  }
}

class EmberResponse {
  final String message;
  EmberResponse({required this.message});
}

class EmberException implements Exception {
  final String message;
  EmberException(this.message);
  @override
  String toString() => 'EmberException: $message';
}
