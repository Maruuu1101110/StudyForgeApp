import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EmberAIService {
  static final EmberAIService _instance = EmberAIService._internal();
  factory EmberAIService() => _instance;
  EmberAIService._internal();

  final String _baseUrl = dotenv.env["DIGITALOCEAN_GENAI_URL_BASE"]!;

  final String _accessKey = dotenv.env["DIGITALOCEAN_GENAI_ACCESS_KEY"]!;

  final String? _kbId = dotenv.env["DIGITALOCEAN_GENAI_KB_ID"];

  // this one is for the streamed version of her response
  Stream<String> sendMessageStream({
    required List<Map<String, String>> messages,
  }) async* {
    final uri = Uri.parse(_baseUrl);

    debugPrint('This is from the SERVICE:  ${messages.toString()}');

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
      throw EmberException(
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

  /// message to Ember
  /*
  Future<EmberResponse> sendMessage({required String message}) async {
    final uri = Uri.parse(_baseUrl);

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessKey',
        },
        body: jsonEncode({
          'messages': [
            {'role': 'user', 'content': message},
          ],
          'stream': false,
          'include_functions_info': false,
          'include_retrieval_info': false, // true later
          'include_guardrails_info': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        return EmberResponse(message: content.trim());
      }

      throw EmberException(
        'Ember API Error - Status: ${response.statusCode}, Body: ${response.body}',
      );
    } catch (e) {
      throw EmberException('Failed to connect to Ember: ${e}');
    }
  }
  */

  Future<void> sendFileToKnowledgeBase(File file) async {
    if (file == false || file.path.isEmpty) {
      throw EmberException("📂 No file selected to upload.");
    }

    final uri = Uri.parse(
      'https://api.digitalocean.com/v2/gen-ai/knowledge-bases/$_kbId/data-sources',
    );
    final accessToken = dotenv.env["DIGITALOCEAN_GENAI_FILE_ACCESS_TOKEN"]!;

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ File uploaded to Ember’s brain!');
    } else {
      final responseBody = await response.stream.bytesToString();
      throw EmberException(
        '🚨 Upload failed: ${response.statusCode}\n$responseBody',
      );
    }
  }

  /*
  Future<EmberResponse> generateQuizFromText({
    required String extractedText,
    int questionCount = 5,
    String difficulty = 'medium',
  }) {
    final prompt =
        '''
Generate a $questionCount-question multiple-choice quiz based on the following study content.
Difficulty: $difficulty.

---
$extractedText
---
Return only the questions with options and correct answers.
''';

    // hide for now
    // return sendMessage(message: prompt);
  }*/
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
