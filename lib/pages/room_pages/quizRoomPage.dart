import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:study_forge/models/room_model.dart';
import 'package:study_forge/pages/room_pages/flashCardMaterials/flashCardContainer.dart';
import 'flashCardMaterials/flashCards.dart';
import 'package:study_forge/utils/flash_service.dart';
import 'package:study_forge/utils/file_manager_service.dart';
import 'package:study_forge/utils/navigationObservers.dart';
import 'flashCardMaterials/flashCardParses.dart';
import 'quizMaterials/quizSessionPage.dart';
import 'quizMaterials/questions.dart';
import 'quizMaterials/quizParser.dart';
import 'package:study_forge/utils/quizService.dart';

class QuizRoomPage extends StatefulWidget {
  final Room room;

  const QuizRoomPage({super.key, required this.room});

  @override
  State<QuizRoomPage> createState() => _QuizRoomPageState();
}

class _QuizRoomPageState extends State<QuizRoomPage>
    with RouteAware, TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;

  int _currentTabIndex = 0;
  int? _activeFlashcardSetIndex;

  bool isLoadingQuizzes = true;
  bool isLoadingFlashcards = true;
  List<Map<String, dynamic>> flashcardSets = [];
  List<Map<String, dynamic>> quizSets = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _pageController = PageController(initialPage: _currentTabIndex);
    _loadQuizSets();
    _loadFlashcardSets();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    _loadFlashcardSets();
    _loadQuizSets();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

  /// Quiz Set Logic
  Future<void> _loadQuizSets() async {
    if (widget.room.id == null) {
      setState(() => isLoadingQuizzes = false);
      return;
    }

    try {
      final files = await FileManagerService.instance.getRoomQuizzes(
        widget.room.id!,
      );

      final List<Map<String, dynamic>> sets = [];

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          final content = await file.readAsString();
          final decoded = jsonDecode(content);

          if (decoded is List) {
            final List<Questions> questions = [];

            for (final item in decoded) {
              if (item is Map<String, dynamic> &&
                  item.containsKey('question') &&
                  item.containsKey('options') &&
                  item.containsKey('correctAnswer')) {
                final List<String> options = List<String>.from(item['options']);
                final correctAnswer = item['correctAnswer'];

                if (options.contains(correctAnswer)) {
                  questions.add(
                    Questions(
                      question: item['question'],
                      options: options,
                      correctAnswer: correctAnswer,
                    ),
                  );
                }
              }
            }

            if (questions.isNotEmpty) {
              sets.add({
                'title': path.basenameWithoutExtension(file.path),
                'questions': questions,
                'file': file,
              });
            }
          }
        }
      }

      setState(() {
        quizSets = sets;
        isLoadingQuizzes = false;
      });
    } catch (e) {
      setState(() => isLoadingQuizzes = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading quizzes: $e')));
      }
    }
  }

  /// Flashcard Set Logic
  Future<void> _loadFlashcardSets() async {
    if (widget.room.id == null) {
      setState(() => isLoadingFlashcards = false);
      return;
    }
    try {
      final files = await FileManagerService.instance.getRoomFlashCards(
        widget.room.id!,
      );
      final List<Map<String, dynamic>> sets = [];
      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          final content = await file.readAsString();
          final decoded = jsonDecode(content);
          if (decoded is List) {
            final List<Flashcard> cards = [];
            for (final item in decoded) {
              if (item is Map<String, dynamic> &&
                  item.containsKey('question') &&
                  item.containsKey('answer')) {
                cards.add(
                  Flashcard(question: item['question'], answer: item['answer']),
                );
              }
            }
            // Inside the loop
            if (cards.isNotEmpty) {
              sets.add({
                'title': path.basenameWithoutExtension(file.path),
                'cards': cards,
                'file': file,
              });
            }
          }
        }
      }
      setState(() {
        flashcardSets = sets;
        isLoadingFlashcards = false;
      });
    } catch (e) {
      setState(() => isLoadingFlashcards = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading flashcards: $e')));
      }
    }
  }

  /// Quiz Set Creation Dialog
  void _showCreateQuizSetDialog() {
    final titleController = TextEditingController();
    final jsonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Paste Quiz Set JSON',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    cursorColor: _getRoomThemeColor(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Set Title',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _getRoomThemeColor(),
                          width: 2,
                        ),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: jsonController,
                    cursorColor: _getRoomThemeColor(),
                    maxLines: 12,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Paste Quiz JSON here',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText:
                          '[{"question":"...","options":["A","B","C","D"],"correctAnswer":"A"}]',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _getRoomThemeColor(),
                          width: 2,
                        ),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      try {
                        final parsed = json.decode(value ?? "");
                        if (parsed is! List) {
                          return 'Must be a list of quiz items';
                        }

                        for (final e in parsed) {
                          if (e is! Map ||
                              !e.containsKey('question') ||
                              !e.containsKey('options') ||
                              !e.containsKey('correctAnswer')) {
                            return 'Each item must have question, options, and correctAnswer';
                          }

                          if (e['options'] is! List ||
                              !(e['options'] as List).contains(
                                e['correctAnswer'],
                              )) {
                            return 'Correct answer must match one of the options';
                          }
                        }

                        return null;
                      } catch (e) {
                        return 'Malformed JSON';
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final rawList =
                            json.decode(jsonController.text) as List;
                        final questions = rawList
                            .map(
                              (e) => Questions(
                                question: e['question'],
                                options: List<String>.from(e['options']),
                                correctAnswer: e['correctAnswer'],
                              ),
                            )
                            .toList();

                        await QuizService.saveQuizzesSet(
                          roomId: widget.room.id!,
                          setName: titleController.text.trim(),
                          questions: questions,
                        );

                        Navigator.pop(context);
                        await _loadQuizSets();
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Quiz Set'),
                    style: ElevatedButton.styleFrom(
                      elevation: 6,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: _getRoomThemeColor(),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Flashcard Set Creation Dialog
  void _showCreateFlashcardSetDialog() {
    final titleController = TextEditingController();
    final jsonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Paste Flashcard Set JSON',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    cursorColor: _getRoomThemeColor(),
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Set Title',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _getRoomThemeColor(),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    cursorColor: _getRoomThemeColor(),
                    controller: jsonController,
                    maxLines: 12,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Paste Flashcard JSON here',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: '[{"question":"...","answer":"..."}]',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _getRoomThemeColor(),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      try {
                        final parsed = json.decode(value ?? "");
                        if (parsed is List &&
                            parsed.every(
                              (e) =>
                                  e is Map &&
                                  e.containsKey('question') &&
                                  e.containsKey('answer'),
                            )) {
                          return null;
                        }
                        return 'Invalid format: Must be a list of {"question", "answer"}';
                      } catch (e) {
                        return 'Malformed JSON';
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final List<dynamic> rawList = json.decode(
                          jsonController.text,
                        );
                        final flashcards = rawList
                            .map(
                              (e) => Flashcard(
                                question: e['question'],
                                answer: e['answer'],
                              ),
                            )
                            .toList();

                        await FlashcardService.saveFlashcardSet(
                          roomId: widget.room.id!,
                          setName: titleController.text.trim(),
                          cards: flashcards,
                        );
                        Navigator.pop(context);
                        await _loadFlashcardSets();
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Set'),
                    style: ElevatedButton.styleFrom(
                      elevation: 6,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: _getRoomThemeColor(),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _importQuizSet() async {
    try {
      final questions = await parseQuizFromFile();
      final topicName = await promptForTopicName(context);
      final roomId = widget.room.id!;
      if (topicName != null && topicName.trim().isNotEmpty) {
        await QuizService.saveQuizzesSet(
          roomId: roomId,
          setName: topicName.trim(),
          questions: questions,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quiz set "$topicName" imported.')),
        );
        await _loadQuizSets();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error importing quiz: $e')));
    }
  }

  Future<void> _importFlashcardSet() async {
    try {
      final flashcards = await parseFlashcardsFromFile();
      final topicName = await promptForTopicName(context);
      final roomId = widget.room.id!;
      if (topicName != null && topicName.trim().isNotEmpty) {
        await FlashcardService.saveFlashcardSet(
          roomId: roomId,
          setName: topicName.trim(),
          cards: flashcards,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flashcard set "$topicName" imported.')),
        );
        await _loadFlashcardSets();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error importing flashcards: $e')));
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
    _pageController.dispose();
    routeObserver.unsubscribe(this);
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
            leading: _buildBackButton(),
            actions: [_buildPopupMenu(themeColor)],
            flexibleSpace: _buildFlexibleSpace(themeColor),
          ),
          SliverToBoxAdapter(
            child: RepaintBoundary(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildQuizzesContent(themeColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
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
    );
  }

  Widget _buildPopupMenu(Color themeColor) {
    final Color textColor = Colors.white;
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (value) {
          if (value == 'create') {
            _showCreateFlashcardSetDialog();
          } else if (value == 'import') {
            _importFlashcardSet();
          } else if (value == 'qcreate') {
            _showCreateQuizSetDialog();
          } else if (value == 'qimport') {
            _importQuizSet();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'qcreate',
            child: Row(
              children: [
                Icon(Icons.playlist_add, size: 20, color: themeColor),
                const SizedBox(width: 10),
                Text('Create Quizzes Set', style: TextStyle(color: textColor)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'qimport',
            child: Row(
              children: [
                Icon(
                  Icons.import_contacts_outlined,
                  size: 20,
                  color: themeColor,
                ),
                const SizedBox(width: 10),
                Text('Import Quizzes Set', style: TextStyle(color: textColor)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'create',
            child: Row(
              children: [
                Icon(Icons.note_add_outlined, size: 20, color: themeColor),
                const SizedBox(width: 10),
                Text(
                  'Create Flashcard Set',
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'import',
            child: Row(
              children: [
                Icon(Icons.file_upload_outlined, size: 20, color: themeColor),
                const SizedBox(width: 10),
                Text(
                  'Import Flashcard Set',
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlexibleSpace(Color themeColor) {
    return FlexibleSpaceBar(
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
              child: Icon(Icons.quiz_outlined, size: 48, color: themeColor),
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
                  'Quizzes & Practice',
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
    );
  }

  Widget _buildHeaderTabs(Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildHeaderTab('Quizzes', 0, themeColor),
        const SizedBox(width: 32),
        _buildHeaderTab('Flashcards', 1, themeColor),
      ],
    );
  }

  Widget _buildHeaderTab(String label, int index, Color themeColor) {
    final isActive = _currentTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentTabIndex = index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: isActive ? themeColor : Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 2,
            width: isActive ? 40 : 0,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    Color themeColor, {
    bool isFlashcard = false,
    VoidCallback? onCreatePressed,
  }) {
    final icon = isFlashcard ? Icons.style_outlined : Icons.quiz_outlined;
    final title = isFlashcard ? 'No flashcards yet' : 'No quizzes yet';
    final subtitle = isFlashcard
        ? 'Tap the + button to create your first flashcard set!'
        : 'Tap the + button to create your first quiz!';
    final buttonText = isFlashcard ? 'Create Flashcard Set' : 'Create Quiz';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:
                  onCreatePressed ??
                  (isFlashcard ? _showCreateFlashcardSetDialog : () {}),
              icon: const Icon(Icons.add),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlidingContent(Color themeColor) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentTabIndex = index);
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildQuizzesSection(themeColor),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildFlashcardSection(themeColor),
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////// QUIZ CONTENT  //////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////

  void _enterQuizSession(List<Questions> questions) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => QuizSessionPage(
          questions: questions,
          themeColor: _getRoomThemeColor(),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _buildQuizzesContent(Color themeColor) {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildHeaderTabs(themeColor),
        const SizedBox(height: 16),
        _buildSlidingContent(themeColor),
      ],
    );
  }

  Widget _buildQuizList(Color themeColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildCreateButton(themeColor),
            const SizedBox(height: 12),
            ...List.generate(quizSets.length, (index) {
              final set = quizSets[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildQuizTile(set, index, themeColor),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(Color themeColor) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _showCreateQuizSetDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 46, 46, 46).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text("New Quiz Sets", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizTile(Map<String, dynamic> set, int index, Color themeColor) {
    return Material(
      color: Colors.black.withValues(alpha: 0.2), // your intended background
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.transparent,
        title: Text(
          set['title'] as String,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: IconButton(
          onPressed: () => _showQuizOptions(index),
          icon: Icon(Icons.donut_small, color: themeColor),
        ),
        onTap: () {
          _enterQuizSession(set['questions'] as List<Questions>);
        },
      ),
    );
  }

  Future<void> _deleteQuizSet(File file, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Delete Quiz Set?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will delete the quiz set "${path.basenameWithoutExtension(file.path)}". Are you sure?',
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
        if (await file.exists()) {
          await file.delete();
          if (!mounted) return;

          setState(() {
            quizSets.removeAt(index);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quiz set deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete quiz set: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showQuizOptions(int index) {
    final set = quizSets[index];
    final title = set['title'] as String;
    final file = set['file'];
    if (file == null || file is! File) {
      _showError('Quiz file reference is missing or corrupted.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  color: _getRoomThemeColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text(
                  'Edit Quiz Set',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final content = await file.readAsString();
                  final edited = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController(text: content);
                      return AlertDialog(
                        backgroundColor: const Color(0xFF1C1C1C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          'Edit Quiz JSON',
                          style: TextStyle(
                            color: _getRoomThemeColor(),
                            fontFamily: "Petrona",
                          ),
                        ),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: TextField(
                            controller: controller,
                            maxLines: null,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText:
                                  '[{"question": "...", "options": [...], "correctAnswer": "..."}]',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getRoomThemeColor(),
                            ),
                            onPressed: () {
                              Navigator.pop(context, controller.text);
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      );
                    },
                  );

                  if (edited != null) {
                    try {
                      final parsed = jsonDecode(edited);
                      if (parsed is List &&
                          parsed.every(
                            (q) =>
                                q is Map &&
                                q.containsKey('question') &&
                                q.containsKey('options') &&
                                q.containsKey('correctAnswer'),
                          )) {
                        await file.writeAsString(
                          const JsonEncoder.withIndent('  ').convert(parsed),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quiz set updated!')),
                        );
                        await _loadQuizSets();
                        setState(() {});
                      } else {
                        _showError(
                          'Invalid format. Must be a list of quizzes.',
                        );
                      }
                    } catch (e) {
                      _showError('Invalid JSON: ${e.toString()}');
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Set',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteQuizSet(file, index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuizzesSection(Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Quizzes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: themeColor.withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${quizSets.length} quizzes',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoadingQuizzes)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            )
          else if (quizSets.isEmpty)
            _buildEmptyState(
              themeColor,
              onCreatePressed: _showCreateQuizSetDialog,
            )
          else
            _buildQuizList(themeColor),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////// FLASHCARD CONTENT  //////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////

  Widget _buildFlashcardSection(Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Topics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: themeColor.withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${flashcardSets.length} topics',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoadingFlashcards)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            )
          else if (flashcardSets.isEmpty)
            _buildEmptyState(themeColor, isFlashcard: true)
          else
            _buildFlashcardList(themeColor),
        ],
      ),
    );
  }

  Widget _buildFlashcardList(Color themeColor) {
    if (_activeFlashcardSetIndex != null) {
      if (_activeFlashcardSetIndex! < 0 ||
          _activeFlashcardSetIndex! >= flashcardSets.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _activeFlashcardSetIndex = null);
        });
        _showError('Invalid flashcard set index.');
        return const SizedBox.shrink();
      }
      final set = flashcardSets[_activeFlashcardSetIndex!];
      final List<Flashcard> cards = set['cards'] as List<Flashcard>;
      final String title = set['title'] as String;
      final themeColor = _getRoomThemeColor();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() => _activeFlashcardSetIndex = null);
                },
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  color: themeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FlashCardContainer(
            flashCards: cards
                .map(
                  (card) =>
                      FlashcardWidget(flashcard: card, themeColor: themeColor),
                )
                .toList(),
          ),
        ],
      );
    }

    // show the list of flashcard sets
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showCreateFlashcardSetDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(
                255,
                46,
                46,
                46,
              ).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text("New Card", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: flashcardSets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final set = flashcardSets[index];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Colors.black.withValues(alpha: 0.2),
              title: Text(
                set['title'] as String,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: IconButton(
                onPressed: () => _showTopicOptions(index),
                icon: Icon(Icons.donut_small, color: themeColor),
              ),
              onTap: () {
                setState(() => _activeFlashcardSetIndex = index);
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _deleteFlashcardSet(File file, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Delete Flashcard Set?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will delete the flashcard set "${path.basenameWithoutExtension(file.path)}". Are you sure?',
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
        if (await file.exists()) {
          await file.delete();
          if (!mounted) return;

          setState(() {
            flashcardSets.removeAt(index);
            _activeFlashcardSetIndex = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flashcard set deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete flashcard set: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showTopicOptions(int index) {
    final set = flashcardSets[index];
    final title = set['title'] as String;
    final file = set['file'];
    if (file == null || file is! File) {
      _showError('Flashcard file reference is missing or corrupted.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  color: _getRoomThemeColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text(
                  'Edit Set',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final content = await file.readAsString();
                  final edited = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController(text: content);
                      return AlertDialog(
                        backgroundColor: const Color(0xFF1C1C1C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          'Edit Flashcards',
                          style: TextStyle(color: _getRoomThemeColor()),
                        ),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: TextField(
                            controller: controller,
                            maxLines: null,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '[{"question": "?", "answer": "?"}]',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getRoomThemeColor(),
                            ),
                            onPressed: () {
                              Navigator.pop(context, controller.text);
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      );
                    },
                  );

                  if (edited != null) {
                    try {
                      final parsed = jsonDecode(edited);
                      if (parsed is List) {
                        await file.writeAsString(
                          const JsonEncoder.withIndent('  ').convert(parsed),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Flashcard set updated!'),
                          ),
                        );
                        await _loadFlashcardSets();
                        setState(() {});
                      } else {
                        _showError(
                          'Invalid format. Must be a list of flashcards.',
                        );
                      }
                    } catch (e) {
                      _showError('Invalid JSON: ${e.toString()}');
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Set',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteFlashcardSet(
                    file,
                    index,
                  ); // then proceed to deletion
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showError(String message) {
    debugPrint('Error: $message');
  }
}
