import 'package:flutter/material.dart';

class BookmarkIcon extends StatefulWidget {
  final bool initialStatus;
  final Function(bool) onToggle;

  const BookmarkIcon({
    super.key,
    required this.initialStatus,
    required this.onToggle,
  });

  @override
  State<BookmarkIcon> createState() => _BookmarkIconState();
}

class _BookmarkIconState extends State<BookmarkIcon> {
  late bool isBookmarked;

  @override
  void initState() {
    super.initState();
    isBookmarked = widget.initialStatus;
  }

  void toggleBookmark() {
    final newStatus = !isBookmarked;
    widget.onToggle(newStatus);
    setState(() {
      isBookmarked = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleBookmark,
      child: Icon(
        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        color: isBookmarked ? Colors.amber : Colors.grey,
      ),
    );
  }
}
