import 'package:markdown_editor_plus/markdown_editor_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SmartMarkdownEditor extends StatefulWidget {
  final TextEditingController controller;

  const SmartMarkdownEditor({super.key, required this.controller});

  @override
  State<SmartMarkdownEditor> createState() => _SmartMarkdownEditorState();
}

class _SmartMarkdownEditorState extends State<SmartMarkdownEditor> {
  final FocusNode _focusNode = FocusNode();

  void _insertWrapped(String left, String right) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    final before = text.substring(0, selection.start);
    final selected = text.substring(selection.start, selection.end);
    final after = text.substring(selection.end);

    final newText = "$before$left$selected$right$after";
    final cursorPos = selection.baseOffset + left.length + selected.length;

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(offset: cursorPos);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      if (key == LogicalKeyboardKey.tab) {
        _insertWrapped("    ", ""); // or use "\t" if you prefer a tab character
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.backquote) {
        _insertWrapped("`", "`");
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit8 &&
          HardwareKeyboard.instance.isShiftPressed) {
        _insertWrapped("**", "**");
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit9 &&
          HardwareKeyboard.instance.isShiftPressed) {
        // Shift + 9 = (
        _insertWrapped("(", ")");
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.digit0 &&
          HardwareKeyboard.instance.isShiftPressed) {
        // Shift + 0 = )
        _insertWrapped("[", "]");
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.keyT &&
          HardwareKeyboard.instance.isControlPressed) {
        // Ctrl + T = Strikethrough (~~text~~)
        _insertWrapped("~~", "~~");
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.keyI &&
          HardwareKeyboard.instance.isControlPressed) {
        // Ctrl + I = Italic (_text_)
        _insertWrapped("_", "_");
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.keyH &&
          HardwareKeyboard.instance.isControlPressed) {
        // Ctrl + H = Heading (# text)
        _insertWrapped("# ", "");
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: MarkdownField(
        controller: widget.controller,
        maxLines: null,
        expands: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Type markdown...",
          border: InputBorder.none,
        ),
      ),
    );
  }
}
