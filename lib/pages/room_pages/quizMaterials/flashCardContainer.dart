import 'package:flutter/material.dart';

class FlashCardContainer extends StatefulWidget {
  final List<Widget> flashCards;
  final int initialIndex;

  const FlashCardContainer({
    super.key,
    required this.flashCards,
    this.initialIndex = 0,
  });

  @override
  State<FlashCardContainer> createState() => _FlashCardContainerState();
}

class _FlashCardContainerState extends State<FlashCardContainer> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.flashCards.length - 1);
  }

  void _goToPrev() {
    setState(() {
      if (_currentIndex > 0) _currentIndex--;
    });
  }

  void _goToNext() {
    setState(() {
      if (_currentIndex < widget.flashCards.length - 1) _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == widget.flashCards.length - 1;
    final themeColor = Theme.of(context).colorScheme.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: themeColor.withOpacity(0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            width: 320,
            height: 310,
            child: widget.flashCards.isEmpty
                ? const Center(
                    child: Text(
                      'No flashcards',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: KeyedSubtree(
                      key: ValueKey(_currentIndex),
                      child: widget.flashCards[_currentIndex],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 0),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 32),
                color: isFirst ? Colors.grey : themeColor,
                onPressed: isFirst ? null : _goToPrev,
                tooltip: 'Previous',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.flashCards.isEmpty
                      ? '0/0'
                      : '${_currentIndex + 1} / ${widget.flashCards.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 32),
                color: isLast ? Colors.grey : themeColor,
                onPressed: isLast ? null : _goToNext,
                tooltip: 'Next',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
