import 'package:flutter/material.dart';
import 'package:study_forge/models/room_model.dart';
import 'package:study_forge/utils/file_manager_service.dart';
import 'package:study_forge/utils/file_picker_service.dart';
import 'package:study_forge/utils/conversion_queue_service.dart';
import 'package:study_forge/utils/global_pdf_overlay_service.dart';
import 'dart:io';

class RoomFilesPage extends StatefulWidget {
  final Room room;

  const RoomFilesPage({super.key, required this.room});

  @override
  State<RoomFilesPage> createState() => _RoomFilesPageState();
}

class _RoomFilesPageState extends State<RoomFilesPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<FileSystemEntity> roomFiles = [];
  bool isLoading = true;
  bool isUploading = false;
  List<File> convertingFiles = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadRoomFiles();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  void _loadRoomFiles() async {
    if (widget.room.id != null) {
      try {
        final files = await FileManagerService.instance.getRoomFiles(
          widget.room.id!,
        );
        setState(() {
          roomFiles = files;
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading files: $e')));
        }
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _getRoomThemeColor() {
    if (widget.room.color != null) {
      try {
        return Color(
          int.parse(widget.room.color!.substring(1), radix: 16) + 0xFF000000,
        );
      } catch (e) {
        return Colors.amber;
      }
    }
    return Colors.amber;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getRoomThemeColor();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(15, 15, 15, 1),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  onPressed: _pickAndUploadFiles,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      themeColor.withValues(alpha: 0.3),
                      themeColor.withValues(alpha: 0.15),
                      Colors.grey.shade800.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Icon(
                        Icons.folder_open,
                        size: 48,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            themeColor.withValues(alpha: 0.9),
                            themeColor,
                            themeColor.withValues(alpha: 0.7),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Files & Resources',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        widget.room.subject,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildFilesContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _getRoomThemeColor().withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Files section
          _buildFilesSection(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFilesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Files',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: _getRoomThemeColor().withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${roomFiles.length + convertingFiles.length} files${convertingFiles.isNotEmpty ? ' (${convertingFiles.length} converting)' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            )
          else if (isUploading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Colors.amber),
                    SizedBox(height: 16),
                    Text(
                      'Uploading files...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            )
          else if (roomFiles.isEmpty)
            _buildEmptyState()
          else
            _buildFilesList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeColor = _getRoomThemeColor();

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No files yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your study materials',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickAndUploadFiles,
            icon: const Icon(Icons.add),
            label: const Text('Add Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    final allFiles = <File>[];

    for (final entity in roomFiles) {
      if (entity is File) {
        allFiles.add(entity);
      }
    }

    allFiles.addAll(convertingFiles);

    allFiles.sort((a, b) {
      final aIsConverting = convertingFiles.contains(a);
      final bIsConverting = convertingFiles.contains(b);

      if (aIsConverting && !bIsConverting) return -1;
      if (!aIsConverting && bIsConverting) return 1;
      return 0;
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allFiles.length,
      itemBuilder: (context, index) {
        return _buildFileItem(allFiles[index], index);
      },
    );
  }

  Widget _buildFileItem(File file, int index) {
    final fileName = file.path.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();
    final themeColor = _getRoomThemeColor();
    final isConverting = convertingFiles.contains(file);

    String fileSize;
    try {
      if (file.existsSync()) {
        fileSize = _formatFileSize(file.lengthSync());
      } else {
        fileSize = 'Processing...';
      }
    } catch (e) {
      fileSize = 'Processing...';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: 300,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConverting
              ? Colors.orange.withValues(alpha: 0.6)
              : themeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () => _handleFileTap(file, isConverting),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConverting
                  ? Colors.orange.withValues(alpha: 0.2)
                  : themeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: (!isConverting && fileExtension == 'pdf')
                  ? [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isConverting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  )
                : Icon(
                    _getFileIcon(fileExtension),
                    color: themeColor,
                    size: 24,
                  ),
          ),
          title: Text(
            fileName,
            style: TextStyle(
              color: isConverting ? Colors.orange : Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isConverting
                    ? 'Converting to PDF... (Tap to cancel)'
                    : fileSize,
                style: TextStyle(
                  color: isConverting
                      ? Colors.orange.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: isConverting
              ? Icon(Icons.close, color: Colors.orange.withValues(alpha: 0.7))
              : PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  color: Colors.grey.shade800,
                  onSelected: (value) => _handleFileAction(value, file),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new, color: Colors.white70),
                          SizedBox(width: 8),
                          Text('Open', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _pickAndUploadFiles() async {
    if (widget.room.id == null) return;

    setState(() => isUploading = true);

    try {
      final pickedFiles = await FilePickerService.instance.pickFiles(
        allowMultiple: true,
      );

      if (pickedFiles == null || pickedFiles.isEmpty) {
        setState(() => isUploading = false);
        return;
      }

      int pdfCount = 0;
      int convertCount = 0;

      for (final pickedFileResult in pickedFiles) {
        final isPdf = pickedFileResult.file.path.toLowerCase().endsWith('.pdf');

        if (isPdf) {
          final savedFile = await FileManagerService.instance.saveFileToRoom(
            sourceFile: pickedFileResult.file,
            roomId: widget.room.id!.toString(),
          );

          setState(() {
            roomFiles.add(savedFile);
          });

          pdfCount++;
        } else {
          final tempDir = Directory.systemTemp;
          final tempFile = File(
            '${tempDir.path}/${pickedFileResult.originalName}',
          );

          try {
            await pickedFileResult.file.copy(tempFile.path);

            convertCount++;

            setState(() {
              convertingFiles.add(tempFile);
            });

            ConversionQueueService.instance.addFileToQueue(
              sourceFile: tempFile,
              roomId: widget.room.id!.toString(),
              onConversionDone: (convertedFile) {
                if (mounted) {
                  setState(() {
                    convertingFiles.remove(tempFile);
                  });

                  if (convertedFile.path != tempFile.path) {
                    _loadRoomFiles();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to convert ${tempFile.path.split('/').last}. Please check your CloudConvert quota.',
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
            );
          } catch (e) {
            print("Error copying file to temp: $e");
            try {
              await tempFile.delete();
            } catch (_) {}
          }
        }
      }

      if (mounted) {
        final message = [
          if (pdfCount > 0) '$pdfCount PDF(s) uploaded',
          if (convertCount > 0) '$convertCount file(s) converting...',
        ].join(' & ');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }

      setState(() => isUploading = false);
    } catch (e) {
      setState(() => isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleFileAction(String action, File file) {
    switch (action) {
      case 'open':
        _openFile(file);
        break;
      case 'delete':
        _deleteFile(file);
        break;
    }
  }

  void _showCancelConversionDialog(File file) async {
    final fileName = file.path.split('/').last;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade800,
        title: const Text(
          'Cancel Conversion',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Do you want to cancel the conversion of "$fileName"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancel Conversion',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = ConversionQueueService.instance.cancelConversion(file);

      if (success) {
        setState(() {
          convertingFiles.remove(file);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Conversion of "$fileName" cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  void _openFile(File file) {
    final fileName = file.path.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();

    if (fileExtension == 'pdf') {
      GlobalPdfOverlayService().openPdfViewer(file.path, context: context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot open $fileExtension files directly. Only PDFs can be viewed.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _deleteFile(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade800,
        title: const Text('Delete File', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${file.path.split('/').last}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await file.delete();
        setState(() {
          roomFiles.remove(file);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleFileTap(File file, bool isConverting) {
    if (isConverting) {
      _showCancelConversionDialog(file);
    } else {
      _openFile(file);
    }
  }
}
