import 'dart:io';
import 'package:study_forge/utils/cloud_convertion_service.dart';
import 'package:study_forge/utils/file_manager_service.dart';

typedef ConversionCallback = void Function(File convertedFile);

class _ConversionJob {
  final File sourceFile;
  final String roomId;
  final ConversionCallback? onDone;

  _ConversionJob({required this.sourceFile, required this.roomId, this.onDone});
}

class ConversionQueueService {
  static final ConversionQueueService instance =
      ConversionQueueService._internal();
  ConversionQueueService._internal();

  final List<_ConversionJob> _queue = [];
  bool _isProcessing = false;

  void addFileToQueue({
    required File sourceFile,
    required String roomId,
    ConversionCallback? onConversionDone,
  }) {
    _queue.add(
      _ConversionJob(
        sourceFile: sourceFile,
        roomId: roomId,
        onDone: onConversionDone,
      ),
    );

    _processQueue();
  }

  void _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    final job = _queue.first;

    try {
      final converted = await CloudConvertService.instance.convertToPdf(
        job.sourceFile,
      );

      if (converted != null) {
        await FileManagerService.instance.saveFileToRoom(
          sourceFile: converted,
          roomId: job.roomId,
        );

        try {
          if (job.sourceFile.path.contains('tmp') ||
              job.sourceFile.path.contains('temp')) {
            await job.sourceFile.delete();
          }
        } catch (e) {
          print("Warning: Could not delete temp file: $e");
        }

        job.onDone?.call(converted);
      } else {
        try {
          if (job.sourceFile.path.contains('tmp') ||
              job.sourceFile.path.contains('temp')) {
            await job.sourceFile.delete();
          }
        } catch (e) {
          print("Warning: Could not delete temp file after failure: $e");
        }
      }
    } catch (e) {
      if (e.toString().contains('CloudConvert quota exceeded')) {
        print("CloudConvert quota exceeded - clearing queue");

        final allJobs = List<_ConversionJob>.from(_queue);

        for (final failedJob in allJobs) {
          failedJob.onDone?.call(failedJob.sourceFile);
        }
        clearQueue();
        _isProcessing = false;
        return;
      }

      try {
        if (job.sourceFile.path.contains('tmp') ||
            job.sourceFile.path.contains('temp')) {
          await job.sourceFile.delete();
        }
      } catch (cleanupError) {
        print(
          "Warning: Could not delete temp file after failure: $cleanupError",
        );
      }
      job.onDone?.call(job.sourceFile);

      print("Error during conversion: $e");
    } finally {
      if (_queue.isNotEmpty) {
        _queue.removeAt(0);
      }
      _isProcessing = false;
      await Future.delayed(Duration(milliseconds: 100));
      _processQueue();
    }
  }

  bool cancelConversion(File sourceFile) {
    final jobIndex = _queue.indexWhere(
      (job) => job.sourceFile.path == sourceFile.path,
    );

    if (jobIndex != -1) {
      final job = _queue[jobIndex];
      _queue.removeAt(jobIndex);

      try {
        if (job.sourceFile.path.contains('tmp') ||
            job.sourceFile.path.contains('temp')) {
          job.sourceFile.delete();
        }
      } catch (e) {
        print("Warning: Could not delete temp file during cancellation: $e");
      }

      return true;
    }
    return false;
  }

  bool isFileInQueue(File sourceFile) {
    return _queue.any((job) => job.sourceFile.path == sourceFile.path);
  }

  int get queueSize => _queue.length;

  void clearQueue() {
    for (final job in _queue) {
      try {
        if (job.sourceFile.path.contains('tmp') ||
            job.sourceFile.path.contains('temp')) {
          job.sourceFile.delete();
        }
      } catch (e) {
        print("Warning: Could not delete temp file during queue clear: $e");
      }
    }
    _queue.clear();
    _isProcessing = false;
  }

  List<File> get convertingFiles =>
      _queue.map((job) => job.sourceFile).toList();
}
