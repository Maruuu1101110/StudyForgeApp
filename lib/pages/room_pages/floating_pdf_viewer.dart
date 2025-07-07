import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class FloatingPdfViewer extends StatefulWidget {
  final File pdfFile;
  final String? roomName;
  final VoidCallback? onClose;

  const FloatingPdfViewer({
    super.key,
    required this.pdfFile,
    this.roomName,
    this.onClose,
  });

  @override
  State<FloatingPdfViewer> createState() => _FloatingPdfViewerState();
}

class _FloatingPdfViewerState extends State<FloatingPdfViewer>
    with TickerProviderStateMixin {
  late PdfViewerController _pdfViewerController;
  late AnimationController _animationController;
  late AnimationController _scaleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  int _currentPageNumber = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isMinimized = false;
  bool _isDragging = false;
  Offset _position = const Offset(20, 100);

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  String get _fileName => widget.pdfFile.path.split('/').last;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          if (!_isMinimized)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: screenSize.width,
                height: screenSize.height,
                color: Colors.black.withValues(alpha: 0.5),
                child: GestureDetector(
                  onTap: _closePdfViewer,
                  child: Container(),
                ),
              ),
            ),

          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Positioned(
                left: _position.dx,
                top: _position.dy,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _slideAnimation.value) * 50),
                    child: _buildFloatingContainer(screenSize),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingContainer(Size screenSize) {
    final containerWidth = _isMinimized ? 80.0 : screenSize.width * 0.9;
    final containerHeight = _isMinimized ? 80.0 : screenSize.height * 0.8;

    return GestureDetector(
      onPanStart: (details) {
        _isDragging = true;
      },
      onPanUpdate: (details) {
        if (_isDragging) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(
                0.0,
                screenSize.width - containerWidth,
              ),
              (_position.dy + details.delta.dy).clamp(
                0.0,
                screenSize.height - containerHeight,
              ),
            );
          });
        }
      },
      onPanEnd: (details) {
        _isDragging = false;
      },
      child: Container(
        width: containerWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(_isMinimized ? 40 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.grey[700]!, width: 1),
        ),
        child: _isMinimized ? _buildMinimizedView() : _buildExpandedView(),
      ),
    );
  }

  Widget _buildMinimizedView() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isMinimized = false;
          });
        },
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(
              colors: [Colors.red[400]!, Colors.red[600]!],
            ),
          ),
          child: const Center(
            child: Icon(Icons.picture_as_pdf, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildPdfContent()),
          if (_totalPages > 1) _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          border: Border(
            bottom: BorderSide(color: Colors.grey[700]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.roomName != null)
                    Text(
                      widget.roomName!,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                ],
              ),
            ),

            if (_totalPages > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_currentPageNumber / $_totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(width: 8),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _sharePdf,
                  icon: const Icon(
                    Icons.share,
                    color: Colors.white70,
                    size: 18,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),

                IconButton(
                  onPressed: () {
                    setState(() {
                      _isMinimized = true;
                    });
                  },
                  icon: const Icon(
                    Icons.minimize,
                    color: Colors.white70,
                    size: 18,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),

                IconButton(
                  onPressed: _closePdfViewer,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 18,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfContent() {
    if (_errorMessage != null) {
      return Container(
        color: Colors.grey[850],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 12),
              const Text(
                'Error loading PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          color: Colors.grey[850],
          child: PageStorage(
            bucket: PageStorageBucket(),
            child: SfPdfViewer.file(
              widget.pdfFile,
              controller: _pdfViewerController,
              onDocumentLoaded: _onDocumentLoaded,
              onPageChanged: _onPageChanged,
              onDocumentLoadFailed: _onDocumentLoadFailed,
              canShowPageLoadingIndicator: true,
            ),
          ),
        ),

        if (_isLoading)
          Container(
            color: Colors.grey[850]?.withValues(alpha: 0.9),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                  SizedBox(height: 12),
                  Text(
                    'Loading PDF...',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          border: Border(top: BorderSide(color: Colors.grey[700]!, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _currentPageNumber > 1 ? _goToPreviousPage : null,
              icon: const Icon(Icons.keyboard_arrow_left),
              color: Colors.white70,
              iconSize: 24,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),

            Expanded(
              child: Slider(
                value: _currentPageNumber.toDouble(),
                min: 1,
                max: _totalPages.toDouble(),
                divisions: _totalPages > 1 ? _totalPages - 1 : null,
                onChanged: (value) => _goToPage(value.toInt()),
                activeColor: Colors.red[400],
                inactiveColor: Colors.grey[600],
              ),
            ),

            IconButton(
              onPressed: _currentPageNumber < _totalPages
                  ? _goToNextPage
                  : null,
              icon: const Icon(Icons.keyboard_arrow_right),
              color: Colors.white70,
              iconSize: 24,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    );
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
      _isLoading = false;
    });
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPageNumber = details.newPageNumber;
    });
  }

  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    setState(() {
      _isLoading = false;
      _errorMessage = details.description;
    });
  }

  void _goToPage(int pageNumber) {
    if (pageNumber >= 1 && pageNumber <= _totalPages) {
      _pdfViewerController.jumpToPage(pageNumber);
    }
  }

  void _goToNextPage() {
    if (_currentPageNumber < _totalPages) {
      _pdfViewerController.nextPage();
    }
  }

  void _goToPreviousPage() {
    if (_currentPageNumber > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _sharePdf() async {
    try {
      final result = await Share.shareXFiles(
        [XFile(widget.pdfFile.path)],
        subject: 'PDF Document - $_fileName',
        text: 'Sharing PDF document from StudyForge',
      );

      if (result.status == ShareResultStatus.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _closePdfViewer() async {
    await _animationController.reverse();
    await _scaleController.reverse();
    widget.onClose?.call();
  }
}

class PdfViewerOverlay {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required File pdfFile,
    String? roomName,
  }) {
    hide();

    _currentOverlay = OverlayEntry(
      builder: (context) => FloatingPdfViewer(
        pdfFile: pdfFile,
        roomName: roomName,
        onClose: hide,
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
