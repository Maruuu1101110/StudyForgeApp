import 'package:flutter/material.dart';

class Flashcard {
  final String question;
  final String answer;

  Flashcard({required this.question, required this.answer});
}

class FlashcardWidget extends StatefulWidget {
  final Flashcard flashcard;
  final Color themeColor;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
    required this.themeColor,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    _isFlipped = !_isFlipped;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final isFront = _controller.value < 0.5;
          final rotation = _controller.value * 3.14159;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(rotation),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isFront
                    ? Color.fromRGBO(15, 15, 15, 1)
                    : const Color.fromARGB(
                        66,
                        64,
                        64,
                        64,
                      ).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.themeColor.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Center(
                child: isFront
                    ? Text(
                        widget.flashcard.question,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(3.14159),
                        child: Text(
                          widget.flashcard.answer,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/*
class FlipCardWidget extends StatefulWidget {
  final String frontText;
  final String backText;

  const FlipCardWidget({required this.frontText, required this.backText});

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  void _flipCard() {
    setState(() {
      _isFront = !_isFront;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rotation = Tween(begin: 0.0, end: 1.0).animate(_controller);

    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: rotation,
        builder: (context, child) {
          final isUnder = (_controller.value > 0.5);
          final displayText = isUnder ? widget.backText : widget.frontText;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(_controller.value * 3.14),
            child: Container(
              width: 300,
              height: 180,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isUnder ? Colors.blueGrey : Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  displayText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}*/
