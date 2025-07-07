import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:study_forge/utils/aurora_ai_service.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:file_picker/file_picker.dart';

class AuroraChatPage extends StatefulWidget {
  final String? quickMessage;
  const AuroraChatPage({super.key, this.quickMessage});

  @override
  State<AuroraChatPage> createState() => _AuroraChatPageState();
}

class _AuroraChatPageState extends State<AuroraChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  bool _showScrollToBottom = false;
  late AnimationController _fadeController;
  late AnimationController _typingController;
  late AnimationController _sendButtonController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _typingAnimation;
  late Animation<double> _sendButtonScaleAnimation;

  static const int _maxMessageLength = 1000;

  FilePickerResult? _pickedFile;

  @override
  void initState() {
    super.initState();

    // initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );

    _sendButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );

    // typing animation loop
    _typingController.repeat(reverse: true);

    // add scroll listener for scroll-to-bottom button
    _scrollController.addListener(_onScroll);

    // add text controller listener for send button animation
    _controller.addListener(_onTextChanged);

    // start fade animation for welcome text
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.quickMessage?.isNotEmpty == true) {
        sendMessage(widget.quickMessage);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _typingController.dispose();
    _sendButtonController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final showButton = maxScroll - currentScroll > 200;

    if (_showScrollToBottom != showButton) {
      setState(() => _showScrollToBottom = showButton);
    }
  }

  void _onTextChanged() {
    if (_controller.text.isNotEmpty) {
      _sendButtonController.forward();
    } else {
      _sendButtonController.reverse();
    }
  }

  List<Map<String, String>> _buildSessionContext() {
    const int maxTurns =
        10; // 5 from ai, 5 from me = 10 total || 5 total exchanges

    final filtered = _messages
        .where((m) => m.status == MessageStatus.sent)
        .toList()
        .takeLast(maxTurns);

    return filtered
        .map(
          (msg) => {
            'role': msg.isFromAurora ? 'assistant' : 'user',
            'content': msg.text,
          },
        )
        .toList();
  }

  void sendMessage([String? prefilledText]) {
    String text;
    if (prefilledText != null) {
      text = prefilledText;
    } else {
      text = _controller.text.trim();
      if (text.isEmpty || _isSending) return;
    }

    if (text.length > _maxMessageLength) {
      _showSnackBar(
        'Message too long. Please keep it under $_maxMessageLength characters.',
      );
      return;
    }

    final userMessage = ChatMessage(
      text: text,
      isFromAurora: false,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
    });

    if (_messages.length == 1) {
      _fadeController.reverse();
    }

    if (prefilledText == null) {
      _controller.clear();
    }
    _scrollToBottom();

    final auroraMessageId = 'aurora_${DateTime.now().millisecondsSinceEpoch}';
    final auroraMessage = ChatMessage(
      text: '',
      isFromAurora: true,
      status: MessageStatus.sending,
      id: auroraMessageId,
    );

    setState(() {
      _messages.add(auroraMessage);
    });

    final sessionContext = _buildSessionContext()
      ..add({'role': 'user', 'content': text});

    AuroraAIService()
        .sendMessageStream(messages: sessionContext)
        .listen(
          (chunk) {
            setState(() {
              final index = _messages.indexWhere(
                (msg) => msg.id == auroraMessageId,
              );
              if (index != -1) {
                _messages[index] = _messages[index].copyWith(
                  text: _messages[index].text + chunk,
                );
              }
            });
            if (_isNearBottom()) {
              _smoothScrollToBottom();
            }
          },
          onDone: () {
            setState(() {
              final index = _messages.indexWhere(
                (msg) => msg.id == auroraMessageId,
              );
              if (index != -1) {
                _messages[index] = _messages[index].copyWith(
                  status: MessageStatus.sent,
                );
              }
              _isSending = false;
            });
          },
          onError: (error) {
            setState(() {
              final index = _messages.indexWhere(
                (msg) => msg.id == auroraMessageId,
              );
              if (index != -1) {
                _messages[index] = _messages[index].copyWith(
                  text: "Sorry, something went wrong. 😔\nTap to retry.",
                  status: MessageStatus.failed,
                );
              }
              _isSending = false;
            });
          },
        );
  }

  void sendMessageFromHome(Message) {
    sendMessage(Message);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.amber.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (animated) {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  void _smoothScrollToBottom() {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        final difference = maxScroll - currentScroll;
        if (difference > 50 && difference < 1000) {
          _scrollController.animateTo(
            maxScroll,
            duration: Duration(
              milliseconds: (difference / 4).clamp(150, 400).round(),
            ),
            curve: Curves.easeOutQuart,
          );
        }
      }
    });
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return (maxScroll - currentScroll) < 200;
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(25, 25, 25, 1),
        title: const Text(
          'Clear Conversation',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to clear all messages?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();

                _messages.add(
                  ChatMessage(
                    text:
                        "Hi! I'm Aurora, your AI study buddy! 🌟\n\nHow can I help you today?",
                    isFromAurora: true,
                  ),
                );
              });
            },
            child: Text(
              'Clear',
              style: TextStyle(color: Colors.amber.shade300),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeDisplay(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final day = timestamp.day;
      final month = _getMonthName(timestamp.month);
      return '$month $day, $hour:$minute';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  // File upload handler
  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _pickedFile = result;
      });
    }
  }

  Widget _buildFileContainer(FilePickerResult? result) {
    if (result == null || result.files.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(2),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.amber.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file, color: Colors.amber.shade300, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.files.first.name,
              style: TextStyle(color: Colors.amber.shade200, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.clear, color: Colors.amber.shade300, size: 24),
            onPressed: () {
              setState(() {
                _pickedFile = null; // Clear file state
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.amber.shade300, size: 24),
            onPressed: () async {
              final filePath = _pickedFile!.files.first.path;
              if (filePath != null) {
                final file = File(
                  filePath,
                ); // convert PlatformFile to dart:io File
                await AuroraAIService().sendFileToKnowledgeBase(file);
                setState(() {
                  _pickedFile = null;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ File path is null. Unable to upload."),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(15, 15, 15, 1),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.amber.shade200,
              Colors.amber,
              Colors.orange.shade300,
            ],
          ).createShader(bounds),
          child: const Text(
            'Aurora',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
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
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.clear_all_rounded,
              color: Colors.amber.shade300,
              size: 24,
            ),
            onPressed: _clearConversation,
            tooltip: 'Clear conversation',
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFC0C0C0).withValues(alpha: 0.15),
                Colors.grey.shade800.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        reverse: false,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: index == 0
                                    ? _fadeAnimation
                                    : const AlwaysStoppedAnimation(1.0),
                                child: SlideTransition(
                                  position: index == 0
                                      ? Tween<Offset>(
                                          begin: const Offset(0, 0.3),
                                          end: Offset.zero,
                                        ).animate(_fadeAnimation)
                                      : const AlwaysStoppedAnimation(
                                          Offset.zero,
                                        ),
                                  child: _buildMessageBubble(msg, index),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _buildInputSection(),
            ],
          ),

          // quick scroll button
          if (_showScrollToBottom)
            Positioned(
              bottom: 80,
              right: 16,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 200),
                offset: _showScrollToBottom ? Offset.zero : const Offset(0, 1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showScrollToBottom ? 1.0 : 0.0,
                  child: FloatingActionButton.small(
                    onPressed: () => _scrollToBottom(),
                    backgroundColor: Colors.amber.withValues(alpha: 0.9),
                    foregroundColor: Colors.black,
                    elevation: 4,
                    child: const Icon(Icons.keyboard_arrow_down, size: 20),
                  ),
                ),
              ),
            ),

          if (_messages.isEmpty)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_fadeAnimation),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    Colors.amber.shade200,
                                    Colors.amber,
                                    Colors.orange.shade300,
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Aurora',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your AI Study Buddy 🌟',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.amber.shade200,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.withValues(alpha: 0.1),
                                      Colors.orange.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'I can help you with:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.amber.shade200,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...[
                                      '• Analyzing your PDFs and notes',
                                      '• Creating quizzes from your materials',
                                      '• Study planning and motivation',
                                      '• Answering questions about your subjects',
                                    ].map(
                                      (text) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          text,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'How can I help you today?',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.amber.shade300,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, int index) {
    return Align(
      alignment: msg.isFromAurora
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: GestureDetector(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            gradient: msg.isFromAurora
                ? LinearGradient(
                    colors: [
                      Color.fromARGB(255, 54, 54, 54).withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.lightBlue.withValues(alpha: 0.4),
                      Colors.lightBlueAccent.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: msg.isFromAurora
                  ? Colors.amber.withValues(alpha: 0.3)
                  : Colors.blue.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (msg.isFromAurora ? Colors.grey : Colors.grey)
                    .withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.isFromAurora)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aurora',
                        style: TextStyle(
                          color: Colors.amber.shade200,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (msg.status == MessageStatus.sending && _isSending)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: AnimatedBuilder(
                            animation: _typingAnimation,
                            builder: (context, child) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'is typing',
                                    style: TextStyle(
                                      color: Colors.amber.shade200.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  ...List.generate(3, (dotIndex) {
                                    final delay = dotIndex * 0.2;
                                    final animationValue =
                                        (_typingAnimation.value + delay) % 1.0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      child: Transform.scale(
                                        scale:
                                            0.5 +
                                            (0.5 *
                                                (1 -
                                                        (animationValue - 0.5)
                                                                .abs() *
                                                            2)
                                                    .clamp(0.0, 1.0)),
                                        child: Container(
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade300,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                        ),
                      if (msg.status == MessageStatus.failed)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red.shade300,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              msg.isFromAurora
                  ? MarkdownWidget(
                      data: msg.text,
                      shrinkWrap: true,
                      selectable: true,
                      config: MarkdownConfig.darkConfig,
                    )
                  : Text(
                      msg.text,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getTimeDisplay(msg.timestamp),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  if (!msg.isFromAurora)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (msg.status == MessageStatus.sending)
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.blue.shade300,
                              ),
                            ),
                          )
                        else if (msg.status == MessageStatus.sent)
                          Icon(
                            Icons.check,
                            color: Colors.blue.shade300,
                            size: 14,
                          )
                        else if (msg.status == MessageStatus.failed)
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade300,
                            size: 14,
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(color: Colors.amber.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Column(
        children: [
          if (_controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_controller.text.length}/$_maxMessageLength',
                    style: TextStyle(
                      color: _controller.text.length > _maxMessageLength
                          ? Colors.red.shade300
                          : Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          if (_pickedFile != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Expanded(child: _buildFileContainer(_pickedFile))],
            ),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _controller.text.length > _maxMessageLength
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _controller,
                      focusNode: _textFieldFocusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Ask Aurora something...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (_) => sendMessage(),
                      onChanged: (_) => setState(() {}),
                      minLines: 1,
                      maxLines: 2,
                      maxLength: null,
                    ),
                  ),
                ),
              ),

              // file upload area
              IconButton(
                onPressed: _pickAndUploadFile,
                icon: Icon(Icons.attach_file, color: Colors.amber, size: 24),
                tooltip: 'Upload file',
              ),
              AnimatedBuilder(
                animation: _sendButtonScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _sendButtonScaleAnimation.value,
                    child: Container(
                      child: IconButton(
                        onPressed:
                            _controller.text.trim().isNotEmpty &&
                                _controller.text.length <= _maxMessageLength
                            ? sendMessage
                            : null,

                        icon: Icon(
                          Icons.send_rounded,
                          color:
                              _controller.text.trim().isNotEmpty &&
                                  _controller.text.length <= _maxMessageLength
                              ? Colors.amber
                              : Colors.white.withValues(alpha: 0.5),
                          size: 24,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isFromAurora;
  final DateTime timestamp;
  final MessageStatus status;
  final String? id;

  ChatMessage({
    required this.text,
    required this.isFromAurora,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
    this.id,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    bool? isFromAurora,
    String? id,
    MessageStatus? status,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isFromAurora: isFromAurora ?? this.isFromAurora,
      id: id ?? this.id,
      status: status ?? this.status,
    );
  }
}

enum MessageStatus { sending, sent, failed }

extension TakeLastExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) return this;
    return sublist(length - count);
  }
}
