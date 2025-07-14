import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:study_forge/main.dart';
import 'package:share_plus/share_plus.dart';
import 'package:markdown_widget/markdown_widget.dart';

class GlobalPdfOverlayService {
  static final GlobalPdfOverlayService _instance =
      GlobalPdfOverlayService._internal();
  factory GlobalPdfOverlayService() => _instance;
  GlobalPdfOverlayService._internal();

  OverlayEntry? _overlayEntry;
  bool _isMinimized = false;
  bool _isOpen = false;
  String? _currentFilePath;
  PdfViewerController _pdfController = PdfViewerController();

  bool get isOpen => _isOpen;
  String? get currentFilePath => _currentFilePath;

  void openPdfViewer(
    String filePath, {
    BuildContext? context,
    Color? roomColor,
  }) {
    if (_isOpen && _currentFilePath == filePath) {
      if (_isMinimized) {
        _toggleMinimize();
      }
      return;
    }
    if (_isOpen) {
      closePdfViewer();
    }
    _currentFilePath = filePath;
    _isOpen = true;
    _isMinimized = false;
    _pdfController = PdfViewerController();

    _createOverlay(context, roomColor);
  }

  void closePdfViewer() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _isOpen = false;
    _isMinimized = false;
    _currentFilePath = null;
  }

  void _toggleMinimize() {
    if (!_isOpen) return;

    _isMinimized = !_isMinimized;
    _overlayEntry?.markNeedsBuild();
  }

  void _createOverlay(BuildContext? providedContext, Color? roomColor) {
    final context = providedContext ?? navigatorKey.currentContext;
    if (context == null) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final themeColor = roomColor ?? Theme.of(context).colorScheme.primary;

    _overlayEntry = OverlayEntry(
      builder: (context) => FloatingPdfViewer(
        roomColor: themeColor,
        filePath: _currentFilePath!,
        isMinimized: _isMinimized,
        onClose: closePdfViewer,
        onToggleMinimize: _toggleMinimize,
        pdfController: _pdfController,
      ),
    );

    overlay.insert(_overlayEntry!);
  }
}

class GlobalMdOverlayService {
  static final GlobalMdOverlayService _instance =
      GlobalMdOverlayService._internal();
  factory GlobalMdOverlayService() => _instance;
  GlobalMdOverlayService._internal();

  OverlayEntry? _overlayEntry;
  bool _isMinimized = false;
  bool _isOpen = false;
  String? _currentFilePath;

  bool get isOpen => _isOpen;
  String? get currentFilePath => _currentFilePath;

  void openMdViewer(
    String filePath, {
    BuildContext? context,
    Color? roomColor,
  }) {
    if (_isOpen && _currentFilePath == filePath) {
      if (_isMinimized) {
        _toggleMinimize();
      }
      return;
    }
    if (_isOpen) {
      closeMdViewer();
    }
    _currentFilePath = filePath;
    _isOpen = true;
    _isMinimized = false;

    _createOverlay(context, roomColor);
  }

  void closeMdViewer() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
    _isMinimized = false;
    _currentFilePath = null;
  }

  void _toggleMinimize() {
    if (!_isOpen) return;
    _isMinimized = !_isMinimized;
    _overlayEntry?.markNeedsBuild();
  }

  void _createOverlay(BuildContext? providedContext, Color? roomColor) {
    final context = providedContext ?? navigatorKey.currentContext;
    if (context == null) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final resolvedColor = roomColor ?? Theme.of(context).colorScheme.primary;

    _overlayEntry = OverlayEntry(
      builder: (context) => FloatingMarkdownViewer(
        roomColor: resolvedColor,
        filePath: _currentFilePath!,
        isMinimized: _isMinimized,
        onClose: closeMdViewer,
        onToggleMinimize: _toggleMinimize,
      ),
    );

    overlay.insert(_overlayEntry!);
  }
}

class FloatingPdfViewer extends StatefulWidget {
  final Color roomColor;
  final String filePath;
  final bool isMinimized;
  final VoidCallback onClose;
  final VoidCallback onToggleMinimize;
  final PdfViewerController pdfController;

  const FloatingPdfViewer({
    required this.roomColor,
    required this.filePath,
    required this.isMinimized,
    required this.onClose,
    required this.onToggleMinimize,
    required this.pdfController,
  });

  @override
  State<FloatingPdfViewer> createState() => _FloatingPdfViewerState();
}

class _FloatingPdfViewerState extends State<FloatingPdfViewer> {
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;

  @override
  void didUpdateWidget(covariant FloatingPdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {}); // forces a rebuild with new minimized state
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMinimized = widget.isMinimized;

    const bubbleSize = Size(60, 60);
    final expandedSize = Size(screenSize.width * 0.85, screenSize.height * 0.7);

    final currentSize = isMinimized ? bubbleSize : expandedSize;

    final constrainedPosition = Offset(
      _position.dx.clamp(0, screenSize.width - currentSize.width),
      _position.dy.clamp(0, screenSize.height - currentSize.height),
    );

    return Positioned(
      left: constrainedPosition.dx,
      top: constrainedPosition.dy,
      child: GestureDetector(
        onPanStart: (details) {
          _isDragging = true;
        },
        onPanUpdate: (details) {
          if (_isDragging) {
            setState(() {
              _position += details.delta;
            });
          }
        },
        onPanEnd: (details) {
          _isDragging = false;
        },
        onTap: isMinimized ? widget.onToggleMinimize : null,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(isMinimized ? 30 : 12),
          child: Container(
            width: currentSize.width,
            height: currentSize.height,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 20, 20, 20),
              borderRadius: BorderRadius.circular(isMinimized ? 30 : 12),
              border: Border.all(
                color: widget.roomColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: isMinimized ? _buildMinimizedView() : _buildExpandedView(),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedView() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            widget.roomColor.withValues(alpha: 1),
            widget.roomColor.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.picture_as_pdf, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildExpandedView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildPdfViewer()),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Material(
      color: const Color.fromARGB(255, 30, 30, 30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.filePath.split('/').last,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.minimize, color: Colors.white, size: 20),
              onPressed: widget.onToggleMinimize,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: widget.onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Container(
      color: Colors.white,
      child: PageStorage(
        bucket: PageStorageBucket(),
        child: SfPdfViewer.file(
          File(widget.filePath),
          controller: widget.pdfController,
          enableDoubleTapZooming: true,
          enableTextSelection: true,
          onDocumentLoadFailed: (details) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load PDF: ${details.error}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Material(
      color: const Color.fromARGB(255, 30, 30, 30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_out, color: Colors.white, size: 20),
              onPressed: () => widget.pdfController.zoomLevel -= 0.25,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
              onPressed: () => widget.pdfController.zoomLevel += 0.25,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
            IconButton(
              icon: const Icon(Icons.first_page, color: Colors.white, size: 20),
              onPressed: () => widget.pdfController.firstPage(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
            IconButton(
              icon: const Icon(Icons.last_page, color: Colors.white, size: 20),
              onPressed: () => widget.pdfController.lastPage(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white, size: 20),
              onPressed: () => _sharePdf(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePdf() {
    final fileName = widget.filePath.split('/').last;
    Share.shareXFiles(
      [XFile(widget.filePath)],
      text: 'Sharing PDF: $fileName',
      subject: fileName,
    );
  }
}

class FloatingMarkdownViewer extends StatefulWidget {
  final Color roomColor;
  final String filePath;
  final bool isMinimized;
  final VoidCallback onClose;
  final VoidCallback onToggleMinimize;

  const FloatingMarkdownViewer({
    required this.roomColor,
    required this.filePath,
    required this.isMinimized,
    required this.onClose,
    required this.onToggleMinimize,
  });

  @override
  State<FloatingMarkdownViewer> createState() => _FloatingMarkdownViewerState();
}

class _FloatingMarkdownViewerState extends State<FloatingMarkdownViewer> {
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;
  late Future<String> _markdownFuture;

  @override
  void initState() {
    super.initState();
    _markdownFuture = File(widget.filePath).readAsString();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const bubbleSize = Size(60, 60);
    final expandedSize = Size(screenSize.width * 0.85, screenSize.height * 0.7);

    final currentSize = widget.isMinimized ? bubbleSize : expandedSize;
    final constrainedPosition = Offset(
      _position.dx.clamp(0, screenSize.width - currentSize.width),
      _position.dy.clamp(0, screenSize.height - currentSize.height),
    );

    return Positioned(
      left: constrainedPosition.dx,
      top: constrainedPosition.dy,
      child: GestureDetector(
        onPanStart: (_) => _isDragging = true,
        onPanUpdate: (details) {
          if (_isDragging) {
            setState(() => _position += details.delta);
          }
        },
        onPanEnd: (_) => _isDragging = false,
        onTap: widget.isMinimized ? widget.onToggleMinimize : null,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(widget.isMinimized ? 30 : 12),
          child: Container(
            width: currentSize.width,
            height: currentSize.height,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 20, 20, 20),
              borderRadius: BorderRadius.circular(widget.isMinimized ? 30 : 12),
              border: Border.all(
                color: widget.roomColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: widget.isMinimized ? _buildMinimized() : _buildExpanded(),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimized() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            widget.roomColor.withValues(alpha: 1),
            widget.roomColor.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.text_snippet, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildExpanded() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<String>(
              future: _markdownFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                if (snapshot.hasError)
                  return const Center(child: Text("Error loading markdown"));

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MarkdownWidget(
                    data: snapshot.data ?? '',
                    config: MarkdownConfig.darkConfig,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Material(
      color: const Color.fromARGB(255, 30, 30, 30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.filePath.split('/').last,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.minimize, color: Colors.white, size: 20),
              onPressed: widget.onToggleMinimize,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: widget.onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class GlobalFloatingViewerService {
  static final GlobalFloatingViewerService _instance =
      GlobalFloatingViewerService._internal();
  factory GlobalFloatingViewerService() => _instance;
  GlobalFloatingViewerService._internal();

  OverlayEntry? _overlayEntry;
  bool _isMinimized = false;
  bool _isOpen = false;
  String? _currentFilePath;
  PdfViewerController _pdfController = PdfViewerController();

  bool get isOpen => _isOpen;
  String? get currentFilePath => _currentFilePath;

  void openViewer(String filePath, {BuildContext? context}) {
    if (_isOpen && _currentFilePath == filePath) {
      if (_isMinimized) _toggleMinimize();
      return;
    }
    closeViewer();

    _currentFilePath = filePath;
    _isOpen = true;
    _isMinimized = false;
    _pdfController = PdfViewerController();

    _createOverlay(context);
  }

  void closeViewer() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
    _isMinimized = false;
    _currentFilePath = null;
  }

  void _toggleMinimize() {
    if (!_isOpen) return;
    _isMinimized = !_isMinimized;
    _overlayEntry?.markNeedsBuild();
  }

  void _createOverlay(BuildContext? providedContext) {
    final context = providedContext ?? navigatorKey.currentContext;
    if (context == null || _currentFilePath == null) return;

    final ext = _currentFilePath!.split('.').last.toLowerCase();
    final overlay = Overlay.of(context, rootOverlay: true);
    final themeColor = Theme.of(context).colorScheme.primary;

    Widget viewer;
    if (['md', 'markdown'].contains(ext)) {
      viewer = FloatingMarkdownViewer(
        roomColor: themeColor,
        filePath: _currentFilePath!,
        isMinimized: _isMinimized,
        onClose: closeViewer,
        onToggleMinimize: _toggleMinimize,
      );
    } else if (ext == 'pdf') {
      viewer = FloatingPdfViewer(
        roomColor: themeColor,
        filePath: _currentFilePath!,
        isMinimized: _isMinimized,
        onClose: closeViewer,
        onToggleMinimize: _toggleMinimize,
        pdfController: _pdfController,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unsupported file format: .$ext")));
      _isOpen = false;
      return;
    }

    _overlayEntry = OverlayEntry(builder: (context) => viewer);
    overlay.insert(_overlayEntry!);
  }
}
