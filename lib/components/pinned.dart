import 'package:flutter/material.dart';

class PinnedIcon extends StatefulWidget {
  final bool initialStatus;
  final Function(bool) onToggle;

  const PinnedIcon({
    super.key,
    required this.initialStatus,
    required this.onToggle,
  });

  @override
  State<PinnedIcon> createState() => _PinnedIconState();
}

class _PinnedIconState extends State<PinnedIcon> {
  late bool isPinned;

  @override
  void initState() {
    super.initState();
    isPinned = widget.initialStatus;
  }

  void togglePinned() {
    final newStatus = !isPinned;
    widget.onToggle(newStatus);
    setState(() {
      isPinned = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: togglePinned,
      child: Icon(
        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
        color: isPinned ? Colors.amber : Colors.grey,
      ),
    );
  }
}
