import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class FileManagerService {
  static const String _studyForgeFolderName = 'Study Forge';
  static const String _filesFolderName = 'Files';
  static const String _quizzesFolderName = 'Quizzes';
  static const String _progressFolderName = 'Progress';
  static const String _metadataFileName = 'metadata.json';

  static FileManagerService? _instance;
  static FileManagerService get instance =>
      _instance ??= FileManagerService._();
  FileManagerService._();

  Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }

      return false;
    }

    return true;
  }

  Future<String> get _studyForgeBasePath async {
    final Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      final studyForgePath = path.join(
        externalDir.parent.parent.parent.parent.path,
        _studyForgeFolderName,
      );
      return studyForgePath;
    }

    final Directory appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, _studyForgeFolderName);
  }

  Future<String> getRoomFolderPath(int roomId) async {
    final basePath = await _studyForgeBasePath;
    return path.join(basePath, 'room_$roomId');
  }

  Future<bool> createRoomFolder({
    required int roomId,
    required String subject,
    String? description,
  }) async {
    try {
      if (!await requestStoragePermissions()) {
        throw Exception('Storage permission denied');
      }

      final roomPath = await getRoomFolderPath(roomId);
      final roomDir = Directory(roomPath);

      if (await roomDir.exists()) {
        if (kDebugMode) {
          print('Room folder already exists: $roomPath');
        }
        return true;
      }

      await roomDir.create(recursive: true);

      await _createSubfolders(roomPath);

      await _createMetadata(
        roomPath: roomPath,
        roomId: roomId,
        subject: subject,
        description: description,
      );

      if (kDebugMode) {
        print('Successfully created room folder: $roomPath');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating room folder: $e');
      }
      return false;
    }
  }

  Future<void> _createSubfolders(String roomPath) async {
    final subfolders = [
      _filesFolderName,
      _quizzesFolderName,
      _progressFolderName,
    ];

    for (final folderName in subfolders) {
      final folderPath = path.join(roomPath, folderName);
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
    }
  }

  Future<void> _createMetadata({
    required String roomPath,
    required int roomId,
    required String subject,
    String? description,
  }) async {
    final metadata = {
      'roomId': roomId,
      'subject': subject,
      'description': description ?? '',
      'created': DateTime.now().toIso8601String(),
      'lastAccessed': DateTime.now().toIso8601String(),
      'fileCount': 0,
      'quizCount': 0,
      'version': '1.0',
    };

    final metadataPath = path.join(roomPath, _metadataFileName);
    final metadataFile = File(metadataPath);
    await metadataFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(metadata),
    );
  }

  Future<Map<String, dynamic>?> getRoomMetadata(int roomId) async {
    try {
      final roomPath = await getRoomFolderPath(roomId);
      final metadataPath = path.join(roomPath, _metadataFileName);
      final metadataFile = File(metadataPath);

      if (!await metadataFile.exists()) {
        return null;
      }

      final content = await metadataFile.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error reading room metadata: $e');
      }
      return null;
    }
  }

  Future<bool> updateRoomMetadata(
    int roomId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final currentMetadata = await getRoomMetadata(roomId) ?? {};

      currentMetadata.addAll(updates);
      currentMetadata['lastAccessed'] = DateTime.now().toIso8601String();

      final roomPath = await getRoomFolderPath(roomId);
      final metadataPath = path.join(roomPath, _metadataFileName);
      final metadataFile = File(metadataPath);

      await metadataFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(currentMetadata),
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating room metadata: $e');
      }
      return false;
    }
  }

  Future<bool> deleteRoomFolder(int roomId) async {
    try {
      final roomPath = await getRoomFolderPath(roomId);
      final roomDir = Directory(roomPath);

      if (await roomDir.exists()) {
        await roomDir.delete(recursive: true);
        if (kDebugMode) {
          print('Successfully deleted room folder: $roomPath');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Room folder does not exist: $roomPath');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting room folder: $e');
      }
      return false;
    }
  }

  Future<String> getFilesPath(int roomId) async {
    final roomPath = await getRoomFolderPath(roomId);
    return path.join(roomPath, _filesFolderName);
  }

  Future<String> getQuizzesPath(int roomId) async {
    final roomPath = await getRoomFolderPath(roomId);
    return path.join(roomPath, _quizzesFolderName);
  }

  Future<String> getProgressPath(int roomId) async {
    final roomPath = await getRoomFolderPath(roomId);
    return path.join(roomPath, _progressFolderName);
  }

  Future<List<FileSystemEntity>> getRoomFiles(int roomId) async {
    try {
      final filesPath = await getFilesPath(roomId);
      final filesDir = Directory(filesPath);

      if (!await filesDir.exists()) {
        return [];
      }

      return await filesDir.list().toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting room files: $e');
      }
      return [];
    }
  }

  Future<bool> roomFolderExists(int roomId) async {
    try {
      final roomPath = await getRoomFolderPath(roomId);
      final roomDir = Directory(roomPath);
      return await roomDir.exists();
    } catch (e) {
      return false;
    }
  }

  Future<void> incrementFileCount(int roomId) async {
    final metadata = await getRoomMetadata(roomId);
    if (metadata != null) {
      final currentCount = metadata['fileCount'] ?? 0;
      await updateRoomMetadata(roomId, {'fileCount': currentCount + 1});
    }
  }

  Future<void> decrementFileCount(int roomId) async {
    final metadata = await getRoomMetadata(roomId);
    if (metadata != null) {
      final currentCount = metadata['fileCount'] ?? 0;
      await updateRoomMetadata(roomId, {
        'fileCount': (currentCount - 1).clamp(0, double.infinity).toInt(),
      });
    }
  }

  Future<File> saveFileToRoom({
    required File sourceFile,
    required String roomId,
  }) async {
    final filesPath = await getFilesPath(int.parse(roomId));
    final fileName = path.basename(sourceFile.path);
    final targetPath = path.join(filesPath, fileName);
    final copiedFile = await sourceFile.copy(targetPath);
    await incrementFileCount(int.parse(roomId));

    return copiedFile;
  }
}
