import 'package:flutter/material.dart';

class TitleField extends StatefulWidget {
  final int wordLimit;
  final TextEditingController controller;
  const TitleField({super.key, required this.controller, this.wordLimit = 5});

  @override
  State<TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<TitleField> {
  String? errorText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_enforceWordLimit);
  }

  void _enforceWordLimit() {
    final text = widget.controller.text;
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length > widget.wordLimit) {
      // Truncate to limit
      final limited = words.take(widget.wordLimit).join(' ');
      widget.controller.text = limited;
      widget.controller.selection = TextSelection.collapsed(
        offset: limited.length,
      );
      setState(() {
        errorText = "Maximum ${widget.wordLimit} words allowed";
      });
    } else {
      setState(() {
        errorText = null;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_enforceWordLimit);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 35,
      ), // 🔥 makes the input text amber
      decoration: InputDecoration(
        label: Text("Title"),
        labelStyle: TextStyle(fontSize: 35),
        floatingLabelStyle: TextStyle(fontSize: 18, color: Colors.amber),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),

        errorText: errorText,
      ),
    );
  }
}
