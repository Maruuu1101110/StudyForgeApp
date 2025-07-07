import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class PdfViewerPage extends StatefulWidget {
  final File pdfFile;
  final String? roomName;

  const PdfViewerPage({super.key, required this.pdfFile, this.roomName});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late PdfViewerController _pdfViewerController;
  int _currentPageNumber = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  String get _fileName => widget.pdfFile.path.split('/').last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fileName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.roomName != null)
              Text(
                widget.roomName!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
          ],
        ),
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        elevation: 2,
        shadowColor: isDark ? Colors.black54 : Colors.grey[300],
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_totalPages > 0)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_currentPageNumber / $_totalPages',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          // Share/Export button
          IconButton(
            icon: Icon(
              Icons.share,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: _sharePdf,
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'zoom_in',
                child: Row(
                  children: [
                    Icon(Icons.zoom_in),
                    SizedBox(width: 8),
                    Text('Zoom In'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'zoom_out',
                child: Row(
                  children: [
                    Icon(Icons.zoom_out),
                    SizedBox(width: 8),
                    Text('Zoom Out'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'fit_width',
                child: Row(
                  children: [
                    Icon(Icons.fit_screen),
                    SizedBox(width: 8),
                    Text('Fit Width'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'goto_page',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Go to Page'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(context, isDark),
      bottomNavigationBar: _buildBottomNavigation(context, isDark),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading PDF',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SfPdfViewer.file(
          widget.pdfFile,
          controller: _pdfViewerController,
          onDocumentLoaded: _onDocumentLoaded,
          onPageChanged: _onPageChanged,
          onDocumentLoadFailed: _onDocumentLoadFailed,
          canShowPageLoadingIndicator: true,
        ),
        if (_isLoading)
          Container(
            color: (isDark ? Colors.grey[900] : Colors.white)?.withOpacity(0.8),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading PDF...', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context, bool isDark) {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey[300])!.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _currentPageNumber > 1 ? _goToPreviousPage : null,
            icon: const Icon(Icons.keyboard_arrow_left),
            iconSize: 32,
          ),
          IconButton(
            onPressed: _goToFirstPage,
            icon: const Icon(Icons.first_page),
          ),
          Expanded(
            child: Slider(
              value: _currentPageNumber.toDouble(),
              min: 1,
              max: _totalPages.toDouble(),
              divisions: _totalPages > 1 ? _totalPages - 1 : null,
              onChanged: (value) => _goToPage(value.toInt()),
            ),
          ),
          IconButton(
            onPressed: _goToLastPage,
            icon: const Icon(Icons.last_page),
          ),
          IconButton(
            onPressed: _currentPageNumber < _totalPages ? _goToNextPage : null,
            icon: const Icon(Icons.keyboard_arrow_right),
            iconSize: 32,
          ),
        ],
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

  void _goToFirstPage() {
    _pdfViewerController.jumpToPage(1);
  }

  void _goToLastPage() {
    _pdfViewerController.jumpToPage(_totalPages);
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'zoom_in':
        _pdfViewerController.zoomLevel += 0.25;
        break;
      case 'zoom_out':
        _pdfViewerController.zoomLevel -= 0.25;
        break;
      case 'fit_width':
        _pdfViewerController.zoomLevel = 1.0;
        break;
      case 'goto_page':
        _showGoToPageDialog();
        break;
    }
  }

  void _showGoToPageDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Page number (1-$_totalPages)',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pageNumber = int.tryParse(controller.text);
              if (pageNumber != null &&
                  pageNumber >= 1 &&
                  pageNumber <= _totalPages) {
                _goToPage(pageNumber);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter a valid page number (1-$_totalPages)',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _sharePdf() async {
    try {
      final result = await Share.shareXFiles(
        [XFile(widget.pdfFile.path)],
        subject: 'PDF Document - $_fileName',
        text: 'Sharing PDF document from StudyForge',
      );

      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
