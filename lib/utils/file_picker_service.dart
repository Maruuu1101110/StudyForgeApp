import 'dart:io';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:study_forge/utils/file_manager_service.dart';

enum FileType { pdf, word, powerpoint, image, other }

class FilePickerService {
  static FilePickerService? _instance;
  static FilePickerService get instance => _instance ??= FilePickerService._();
  FilePickerService._();

  final FileManagerService _fileManager = FileManagerService.instance;

  static const List<String> supportedExtensions = [
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'jpg',
    'jpeg',
    'png',
    'txt',
    'rtf',
  ];

  static const List<String> pdfExtensions = ['pdf'];
  static const List<String> wordExtensions = ['doc', 'docx'];
  static const List<String> powerpointExtensions = ['ppt', 'pptx'];
  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png'];

  Future<List<PickedFileResult>?> pickFiles({
    bool allowMultiple = true,
    int? roomId,
  }) async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: fp.FileType.custom,
        allowedExtensions: supportedExtensions,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      List<PickedFileResult> pickedFiles = [];

      for (final platformFile in result.files) {
        if (platformFile.path == null) continue;

        final file = File(platformFile.path!);
        if (!await file.exists()) continue;

        final fileType = _getFileType(platformFile.extension ?? '');
        final pickedFile = PickedFileResult(
          file: file,
          originalName: platformFile.name,
          extension: platformFile.extension ?? '',
          fileType: fileType,
          sizeBytes: platformFile.size,
          needsConversion: fileType != FileType.pdf,
        );

        if (roomId != null) {
          final copied = await _copyFileToRoom(pickedFile, roomId);
          if (copied != null) {
            pickedFile.roomFilePath = copied;
          }
        }

        pickedFiles.add(pickedFile);
      }

      if (kDebugMode) {
        print('Successfully picked ${pickedFiles.length} files');
      }

      return pickedFiles;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking files: $e');
      }
      return null;
    }
  }

  Future<PickedFileResult?> pickSingleFile({int? roomId}) async {
    final files = await pickFiles(allowMultiple: false, roomId: roomId);
    return files?.isNotEmpty == true ? files!.first : null;
  }

  Future<String?> _copyFileToRoom(
    PickedFileResult pickedFile,
    int roomId,
  ) async {
    try {
      final filesPath = await _fileManager.getFilesPath(roomId);
      final fileName = _generateUniqueFileName(
        filesPath,
        pickedFile.originalName,
      );
      final destinationPath = path.join(filesPath, fileName);

      await pickedFile.file.copy(destinationPath);

      await _fileManager.incrementFileCount(roomId);

      if (kDebugMode) {
        print('Copied file to: $destinationPath');
      }

      return destinationPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error copying file to room: $e');
      }
      return null;
    }
  }

  String _generateUniqueFileName(String directoryPath, String originalName) {
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      return originalName;
    }

    final files = directory.listSync();
    final existingNames = files
        .where((entity) => entity is File)
        .map((file) => path.basename(file.path))
        .toSet();

    if (!existingNames.contains(originalName)) {
      return originalName;
    }

    final extension = path.extension(originalName);
    final nameWithoutExt = path.basenameWithoutExtension(originalName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return '${nameWithoutExt}_$timestamp$extension';
  }

  FileType _getFileType(String extension) {
    final ext = extension.toLowerCase();

    if (pdfExtensions.contains(ext)) {
      return FileType.pdf;
    } else if (wordExtensions.contains(ext)) {
      return FileType.word;
    } else if (powerpointExtensions.contains(ext)) {
      return FileType.powerpoint;
    } else if (imageExtensions.contains(ext)) {
      return FileType.image;
    } else {
      return FileType.other;
    }
  }

  Future<List<File>> getRoomFiles(int roomId) async {
    try {
      final filesPath = await _fileManager.getFilesPath(roomId);
      final directory = Directory(filesPath);

      if (!await directory.exists()) {
        return [];
      }

      final entities = await directory.list().toList();
      return entities.where((entity) => entity is File).cast<File>().toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting room files: $e');
      }
      return [];
    }
  }

  Future<bool> deleteRoomFile(String filePath, int roomId) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();

        await _fileManager.decrementFileCount(roomId);

        if (kDebugMode) {
          print('Deleted file: $filePath');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting file: $e');
      }
      return false;
    }
  }

  String getFileDisplayName(String filePath) {
    return path.basename(filePath);
  }

  String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  bool isConversionNeeded(String filePath) {
    final extension = getFileExtension(filePath).replaceFirst('.', '');
    return !pdfExtensions.contains(extension);
  }
}

class PickedFileResult {
  final File file;
  final String originalName;
  final String extension;
  final FileType fileType;
  final int sizeBytes;
  final bool needsConversion;
  String? roomFilePath;

  PickedFileResult({
    required this.file,
    required this.originalName,
    required this.extension,
    required this.fileType,
    required this.sizeBytes,
    required this.needsConversion,
    this.roomFilePath,
  });

  String get displayName => originalName;
  String get sizeString =>
      FilePickerService.instance.getFileSizeString(sizeBytes);

  bool get isPdf => fileType == FileType.pdf;
  bool get isWord => fileType == FileType.word;
  bool get isPowerpoint => fileType == FileType.powerpoint;
  bool get isImage => fileType == FileType.image;
}
