import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_forge/utils/ember_ai_service.dart';
import 'package:study_forge/utils/pdf_extractor_service.dart';
import 'package:study_forge/components/sideBar.dart';
import 'package:markdown_widget/markdown_widget.dart';

// settings
import 'package:study_forge/pages/settingsPage.dart';

import 'package:study_forge/utils/code_wrapper.dart';
import 'chat_provider.dart';

import 'package:file_picker/file_picker.dart';

class EmberChatPage extends StatefulWidget {
  final String? quickMessage;
  const EmberChatPage({super.key, this.quickMessage});

  @override
  State<EmberChatPage> createState() => _EmberChatPageState();
}

class _EmberChatPageState extends State<EmberChatPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();
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
  String? _pdfText;

  final codeWrapper = (Widget child, String text, String language) =>
      CodeWrapperWidget(child: child, text: text);

  @override
  void initState() {
    super.initState();

    _initializeEmberService();

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
        sendMessage(prefilledText: widget.quickMessage);
        _scrollToBottom();
      }
      _scrollToBottom();
    });
  }

  Future<void> _initializeEmberService() async {
    try {
      await EmberAIService().init(); // load db-stored API values here
      debugPrint("--- Ember AI Service Initialized");
    } catch (e) {
      debugPrint("--- Ember init error: $e");
      // Optional: show a dialog/snackbar that says "Check Ember API config"
    }
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
    debugPrint("EMBER PAGE DISPOSED");
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

  List<Map<String, String>> _buildSessionContext(List<ChatMessage> messages) {
    final maxTurns = EmberMemoryController.instance.shortTermLimit;

    final filtered = messages
        .where((m) => m.status == MessageStatus.sent)
        .toList()
        .takeLast(maxTurns);

    debugPrint(" #### MAX TURNS ::: ${maxTurns.toString()} ####");

    return filtered
        .map(
          (msg) => {
            'role': msg.isFromEmber ? 'assistant' : 'user',
            'content': msg.text,
          },
        )
        .toList();
  }

  void sendMessage({String? prefilledText}) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final messages = chatProvider.messages;

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
      isFromEmber: false,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isPDF: _pickedFile ?? null,
    );

    chatProvider.addMessage(userMessage);

    setState(() {
      _isSending = true;
    });

    if (messages.length == 1) {
      _fadeController.forward();
    }

    if (prefilledText == null) {
      _controller.clear();
    }
    _scrollToBottom();

    final EmberMessageId = 'Ember_${DateTime.now().millisecondsSinceEpoch}';
    final EmberMessage = ChatMessage(
      text: '',
      isFromEmber: true,
      status: MessageStatus.sending,
      id: EmberMessageId,
    );

    chatProvider.addMessage(EmberMessage);

    final sessionContext = _buildSessionContext(chatProvider.messages);
    final contextText = (_pdfText != null && _pdfText!.trim().isNotEmpty)
        ? "📄 Reference Material:\n${_pdfText!}\n\n💬 Question:\n$text"
        : text;

    sessionContext.add({'role': 'user', 'content': contextText});

    EmberAIService()
        .sendMessageStream(messages: sessionContext)
        .listen(
          (chunk) {
            final messages = chatProvider.messages;
            final index = messages.indexWhere(
              (msg) => msg.id == EmberMessageId,
            );
            if (index != -1) {
              chatProvider.replaceMessage(
                index,
                messages[index].copyWith(text: messages[index].text + chunk),
              );
            }
            if (_isNearBottom()) {
              _smoothScrollToBottom();
            }
          },
          onDone: () {
            debugPrint(sessionContext.toString());
            final messages = chatProvider.messages;
            final index = messages.indexWhere(
              (msg) => msg.id == EmberMessageId,
            );
            if (index != -1) {
              chatProvider.replaceMessage(
                index,
                messages[index].copyWith(status: MessageStatus.sent),
              );
            }
            setState(() {
              _isSending = false;
              _pdfText = null;
              _pickedFile = null;
            });
          },
          onError: (error) {
            final messages = chatProvider.messages;
            final index = messages.indexWhere(
              (msg) => msg.id == EmberMessageId,
            );
            if (index != -1) {
              chatProvider.replaceMessage(
                index,
                messages[index].copyWith(
                  text: "Sorry, something went wrong. 😔.",
                  status: MessageStatus.failed,
                ),
              );
            }
            setState(() {
              _isSending = false;
              _pdfText = null;
              _pickedFile = null;
            });
          },
        );
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
    debugPrint("### Scrolled to bottom ### ");
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

  void _clearMessages() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.clear();
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
          'Are you sure you want to clear all messages and close the chat?',
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
              // Close the dialog
              Navigator.pop(context);

              // Clear chat messages in provider
              final chatProvider = Provider.of<ChatProvider>(
                context,
                listen: false,
              );
              chatProvider.clear();

              // Close the chat page
              Navigator.of(context).maybePop();
            },
            child: Text(
              'Clear & Close',
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // only allow PDFs
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath == null) {
        _showSnackBar("❌ Unable to read selected file.");
        return;
      }

      final file = File(filePath);
      final extractedText = await PdfExtractorService().extractTextFromFile(
        file,
      );

      if (extractedText.trim().isEmpty) {
        _showSnackBar("⚠️ No extractable text found in this PDF.");
        return;
      }

      debugPrint("Extracted PDF Text: $extractedText");

      setState(() {
        _pickedFile = result;
        _pdfText = extractedText; // this should be a global/String? variable
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final messages = Provider.of<ChatProvider>(context).messages;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        extendBody: true,
        backgroundColor: const Color.fromARGB(255, 15, 15, 15),
        resizeToAvoidBottomInset: true,

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
            child: Row(
              children: [
                EmberMemoryController.instance.shortTermLimit == 30
                    ? Icon(
                        Icons.whatshot_rounded,
                        color: Colors.orange,
                        size: 28,
                      )
                    : Container(),
                Text(
                  'Ember AI',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          leading: Builder(
            builder: (context) {
              return Container(
                child: IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              );
            },
          ),
          actions: [
            IconButton(
              onPressed: _clearMessages,
              tooltip: "Clear Messages",
              icon: Icon(
                Icons.cleaning_services_outlined,
                color: Colors.amber.shade300,
                size: 24,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_outlined,
                color: Colors.red,
                size: 30,
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
        drawer: ForgeDrawer(selectedTooltip: "Ember"),
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
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
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
                  offset: _showScrollToBottom
                      ? Offset.zero
                      : const Offset(0, 1),
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

            if (messages.isEmpty)
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
                                  child: Text(
                                    'Ember',
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
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, int index) {
    return Align(
      alignment: msg.isFromEmber ? Alignment.centerLeft : Alignment.centerRight,
      child: GestureDetector(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            gradient: msg.isFromEmber
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
              color: msg.isFromEmber
                  ? Colors.amber.withValues(alpha: 0.3)
                  : Colors.blue.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (msg.isFromEmber ? Colors.grey : Colors.grey).withValues(
                  alpha: 0.2,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.isFromEmber)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..scale(-1.0, 1.0),
                          child: Image.asset(
                            color: const Color.fromARGB(255, 39, 39, 39),
                            colorBlendMode: BlendMode.srcATop,
                            'assets/embers_assets/ember_head.png',
                            width: 100,
                            height: 100,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ember',
                        style: TextStyle(
                          color: Colors.amber.shade200,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      EmberMemoryController.instance.shortTermLimit == 30
                          ? Icon(
                              Icons.whatshot_rounded,
                              color: Colors.orange,
                              size: 16,
                            )
                          : Container(),

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
              msg.isFromEmber
                  ? MarkdownWidget(
                      data: msg.text,
                      selectable: true,
                      shrinkWrap: true,
                      config: MarkdownConfig.darkConfig.copy(
                        configs: [
                          PreConfig.darkConfig.copy(
                            wrapper: codeWrapper,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'SourceCodePro',
                            ),
                          ),
                          CodeConfig(
                            style: TextStyle(
                              fontFamily: 'SourceCodePro',
                              fontSize: 14,
                              backgroundColor: Colors.black12,
                              color: Colors.tealAccent,
                            ),
                          ),
                          PConfig(textStyle: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownWidget(
                          data: msg.text,
                          selectable: true,
                          shrinkWrap: true,
                          config: MarkdownConfig.darkConfig.copy(
                            configs: [
                              PreConfig.darkConfig.copy(
                                wrapper: codeWrapper,
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'SourceCodePro',
                                ),
                              ),
                              CodeConfig(
                                style: TextStyle(
                                  fontFamily: 'SourceCodePro',
                                  fontSize: 14,
                                  backgroundColor: Colors.black12,
                                  color: Colors.amberAccent,
                                ),
                              ),
                              PConfig(textStyle: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        if (msg.isPDF != null)
                          _buildFileContainerOnSent(msg.isPDF),
                      ],
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
                  if (!msg.isFromEmber)
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

  Widget _buildFileContainerOnSent(FilePickerResult? result) {
    if (result == null || result.files.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(2),
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.attach_file, color: Colors.amber.shade300, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.files.first.name,
              style: TextStyle(color: Colors.amber.shade200, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: EdgeInsetsGeometry.only(left: 4, right: 4, bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              if (_controller.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(5),
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
                    child: TextField(
                      cursorColor: Colors.amber,
                      controller: _controller,
                      focusNode: _textFieldFocusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Ask Ember something...',
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
                      minLines: 1,
                      maxLines: 3,
                      maxLength: null,
                    ),
                  ),

                  // file upload area
                  IconButton(
                    onPressed: _pickAndUploadFile,
                    icon: Icon(
                      Icons.attach_file,
                      color: Colors.amber,
                      size: 24,
                    ),
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
                                      _controller.text.length <=
                                          _maxMessageLength
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
        ),
      ),
    );
  }
}
