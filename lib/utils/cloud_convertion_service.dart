import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CloudConvertService {
  static final CloudConvertService instance = CloudConvertService._internal();
  CloudConvertService._internal();

  final Dio _dio = Dio();

  String get _apiKey {
    final key = dotenv.env['CLOUDCONVERT_API_KEY'] ?? '';
    if (key.isEmpty) {
      throw Exception(
        'CloudConvert API key not found in environment variables. Please check your .env file.',
      );
    }
    return key;
  }

  final String _baseUrl = 'https://api.cloudconvert.com/v2';

  Future<File?> convertToPdf(File sourceFile) async {
    final fileName = p.basename(sourceFile.path);

    try {
      final jobResponse = await _dio.post(
        '$_baseUrl/jobs',
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $_apiKey',
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        ),
        data: jsonEncode({
          'tasks': {
            'import-file': {'operation': 'import/upload'},
            'convert-file': {
              'operation': 'convert',
              'input': 'import-file',
              'output_format': 'pdf',
            },
            'export-file': {'operation': 'export/url', 'input': 'convert-file'},
          },
        }),
      );

      final jobId = jobResponse.data['data']['id'];
      final uploadUrl = jobResponse.data['data']['tasks'].firstWhere(
        (task) => task['name'] == 'import-file',
      )['result']['form']['url'];
      final uploadParams = jobResponse.data['data']['tasks'].firstWhere(
        (task) => task['name'] == 'import-file',
      )['result']['form']['parameters'];

      final formData = FormData.fromMap({
        ...Map<String, dynamic>.from(uploadParams),
        'file': await MultipartFile.fromFile(
          sourceFile.path,
          filename: fileName,
        ),
      });

      await _dio.post(uploadUrl, data: formData);

      bool isCompleted = false;
      String? fileUrl;

      while (!isCompleted) {
        final statusRes = await _dio.get(
          '$_baseUrl/jobs/$jobId',
          options: Options(
            headers: {HttpHeaders.authorizationHeader: 'Bearer $_apiKey'},
          ),
        );

        final jobData = statusRes.data['data'];
        final status = jobData['status'];

        if (status == 'finished') {
          final exportTask = jobData['tasks'].firstWhere(
            (t) => t['name'] == 'export-file' && t['status'] == 'finished',
          );

          fileUrl = exportTask['result']['files'][0]['url'];
          isCompleted = true;
        } else if (status == 'error') {
          throw Exception('Conversion job failed.');
        }

        await Future.delayed(Duration(seconds: 2));
      }

      if (fileUrl != null) {
        final tempDir = await getTemporaryDirectory();
        final savePath = p.join(
          tempDir.path,
          '${p.basenameWithoutExtension(fileName)}.pdf',
        );

        await _dio.download(fileUrl, savePath);
        return File(savePath);
      }

      return null;
    } catch (e) {
      if (e.toString().contains('402')) {
        // Quota error
        throw CloudConvertQuotaException(
          'CloudConvert quota exceeded. Please check your account credits.',
        );
      } else if (e.toString().contains('401')) {
        // Authentication error
        throw CloudConvertAuthException(
          'CloudConvert authentication failed. Please check your API key.',
        );
      } else if (e.toString().contains('400')) {
        // Bad request error
        throw CloudConvertException(
          'Invalid file format or request. CloudConvert could not process this file.',
        );
      } else {
        // from CloudConvert or DIO
        throw CloudConvertException('CloudConvert service error: $e');
      }
    }
  }
}

class CloudConvertException implements Exception {
  final String message;
  CloudConvertException(this.message);

  @override
  String toString() => message;
}

class CloudConvertQuotaException extends CloudConvertException {
  CloudConvertQuotaException(String message) : super(message);
}

class CloudConvertAuthException extends CloudConvertException {
  CloudConvertAuthException(String message) : super(message);
}
