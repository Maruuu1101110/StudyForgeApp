import 'package:flutter/material.dart';
import 'questions.dart';
import 'package:study_forge/tables/user_profile_table.dart';
import 'package:study_forge/models/user_profile_model.dart';
import 'package:study_forge/utils/gamification_service.dart';

class QuizSessionPage extends StatefulWidget {
  final List<Questions> questions;
  final Color themeColor;

  const QuizSessionPage({required this.questions, required this.themeColor});

  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage>
    with SingleTickerProviderStateMixin {
  int currentQuestionIndex = 0;
  late List<int?> selectedAnswers;
  List<int> wrongAnswerIndices = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late bool _quizStarted;
  final gamificationService = GamificationService();
  UserProfile? userProfile;

  @override
  void initState() {
    super.initState();
    selectedAnswers = List.filled(widget.questions.length, null);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );
    _fadeController.forward();
    _quizStarted = false;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _selectAnswer(int answerIndex) {
    if (!mounted) return;
    setState(() {
      selectedAnswers[currentQuestionIndex] = answerIndex;
    });
  }

  void _goToPreviousQuestion() {
    if (currentQuestionIndex > 0) {
      wrongAnswerIndices.remove(currentQuestionIndex);
      if (!mounted) return;
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  void _goToNextQuestion() {
    final selectedIndex = selectedAnswers[currentQuestionIndex];
    final question = widget.questions[currentQuestionIndex];

    // Prevent null or out-of-bounds selection
    if (selectedIndex == null ||
        selectedIndex < 0 ||
        selectedIndex >= question.options.length) {
      if (!wrongAnswerIndices.contains(currentQuestionIndex)) {
        wrongAnswerIndices.add(currentQuestionIndex);
      }
    } else {
      final selectedText = question.options[selectedIndex];
      if (selectedText != question.correctAnswer) {
        if (!wrongAnswerIndices.contains(currentQuestionIndex)) {
          wrongAnswerIndices.add(currentQuestionIndex);
        }
      } else {
        wrongAnswerIndices.remove(currentQuestionIndex);
      }
    }

    if (currentQuestionIndex < widget.questions.length - 1) {
      if (!mounted) return;
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    int score = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final selectedIndex = selectedAnswers[i];
      final selectedText = selectedIndex != null
          ? widget.questions[i].options[selectedIndex]
          : null;

      if (selectedText != null &&
          selectedText == widget.questions[i].correctAnswer) {
        score++;
      }
    }

    List<Map<String, dynamic>> wrongAnswers = wrongAnswerIndices.map((i) {
      String yourAnswer = 'No answer';
      final selectedIndex = selectedAnswers[i];
      if (selectedIndex != null &&
          selectedIndex >= 0 &&
          selectedIndex < widget.questions[i].options.length) {
        yourAnswer = widget.questions[i].options[selectedAnswers[i]!];
      }
      return {
        'question': widget.questions[i].question,
        'yourAnswer': yourAnswer,
        'correctAnswer': widget.questions[i].correctAnswer,
      };
    }).toList();

    UserProfileManager().addExperiencePoints(score * 2); // for exp points

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Quiz Complete",
          style: TextStyle(color: Colors.white),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "You scored $score / ${widget.questions.length}!",
                  style: const TextStyle(color: Colors.white70),
                ),
                if (wrongAnswers.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    "Incorrect Answers:",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...wrongAnswers.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['question'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Your answer: ${item['yourAnswer']}",
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "Correct answer: ${item['correctAnswer']}",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: widget.themeColor)),
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

  Widget _buildFlexibleSpace() {
    return FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.themeColor.withValues(alpha: 0.3),
              widget.themeColor.withValues(alpha: 0.15),
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
                Icons.quiz_outlined,
                size: 48,
                color: widget.themeColor,
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fadeAnimation,
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    widget.themeColor.withValues(alpha: 0.9),
                    widget.themeColor,
                    widget.themeColor.withValues(alpha: 0.7),
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Quiz Session',
                  style: TextStyle(
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
                'Answer the questions and test your knowledge!',
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

  Widget _buildWaitForStart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_empty, size: 48, color: Colors.white70),
          const SizedBox(height: 16),
          Text(
            'Waiting for the quiz to start...',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 50),
          TextButton(
            onPressed: () {
              setState(() {
                _quizStarted = true;
              });
              _fadeController.forward();
            },

            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 8.0,
              ),
              foregroundColor: Colors.white,
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: widget.themeColor, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.play_arrow_outlined),
                SizedBox(width: 4),
                Text("Start", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${currentQuestionIndex + 1} of ${widget.questions.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / widget.questions.length,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Questions question) {
    return Container(
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 38, 38, 38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.themeColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.label_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Question ${currentQuestionIndex + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${1} pts',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 20),
          ...List.generate(question.options.length, (i) {
            final isSelected = selectedAnswers[currentQuestionIndex] == i;
            return _buildAnswerOption(
              question.options[i],
              isSelected,
              () => _selectAnswer(i),
              widget.themeColor,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(
    String text,
    bool isSelected,
    VoidCallback onTap,
    Color themeColor,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 70,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? themeColor : Colors.white70,
            width: 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black26, blurRadius: 6)]
              : [],
        ),
        child: ListTile(
          title: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildPrevButton(bool answered) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: 50,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: answered
                ? const Color.fromARGB(255, 38, 38, 38)
                : Colors.grey[700],
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: answered ? 2 : 0,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _goToPreviousQuestion,
          child: Icon(
            Icons.arrow_back_ios_new_outlined,
            size: 18, // tiny icon
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(bool answered) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: 50, // much smaller width
        height: 50, // much smaller height
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: answered
                ? const Color.fromARGB(255, 38, 38, 38)
                : Colors.grey[700],
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero, // remove all default padding
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: answered ? 2 : 0,
            minimumSize: Size.zero, // shrink to minimum
            tapTargetSize:
                MaterialTapTargetSize.shrinkWrap, // for smallest tap area
          ),
          onPressed: answered ? _goToNextQuestion : null,
          child: Icon(
            currentQuestionIndex < widget.questions.length - 1
                ? Icons.arrow_forward_ios_outlined
                : Icons.check,
            size: 18, // tiny icon
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.questions[currentQuestionIndex];
    final answered = selectedAnswers[currentQuestionIndex] != null;

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
            flexibleSpace: _buildFlexibleSpace(),
          ),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _quizStarted
                    ? Column(
                        children: [
                          const SizedBox(height: 24),
                          _buildProgressBar(),
                          const SizedBox(height: 28),
                          _buildQuizCard(current),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Visibility(
                                visible: currentQuestionIndex > 0,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 50,
                                    bottom: 30,
                                  ),
                                  child: _buildPrevButton(answered),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 50,
                                  bottom: 30,
                                ),
                                child: _buildNextButton(answered),
                              ),
                            ],
                          ),
                        ],
                      )
                    : _buildWaitForStart(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
