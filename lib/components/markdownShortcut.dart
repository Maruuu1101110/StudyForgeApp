import 'package:flutter/material.dart';

class MarkdownShortcutBar extends StatefulWidget {
  final TextEditingController controller;

  const MarkdownShortcutBar({required this.controller, super.key});

  @override
  State<MarkdownShortcutBar> createState() => _MarkdownShortcutBarState();
}

class _MarkdownShortcutBarState extends State<MarkdownShortcutBar> {
  // Undo/Redo stacks with configurable limit
  static const int _maxUndoStackSize = 100;
  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];

  // Flags to prevent recursive calls and track state
  bool _isProgrammaticChange = false;
  TextEditingValue? _lastUserEdit;

  @override
  void initState() {
    super.initState();
    _initializeUndoStack();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  /// Initialize the undo stack with the current controller value
  void _initializeUndoStack() {
    final initialValue = widget.controller.value;
    _undoStack.add(initialValue);
    _lastUserEdit = initialValue;
  }

  /// Handle text changes and manage undo/redo stacks
  void _handleTextChanged() {
    // Skip programmatic changes from undo/redo operations
    if (_isProgrammaticChange) return;

    final currentValue = widget.controller.value;

    // Only add to undo stack if content or selection actually changed
    if (_hasValueChanged(currentValue)) {
      _addToUndoStack(currentValue);
      _clearRedoStack();
      _lastUserEdit = currentValue;
    }
  }

  /// Check if the current value differs from the last user edit
  bool _hasValueChanged(TextEditingValue currentValue) {
    return _lastUserEdit?.text != currentValue.text ||
        _lastUserEdit?.selection != currentValue.selection;
  }

  /// Add a value to the undo stack with size management
  void _addToUndoStack(TextEditingValue value) {
    _undoStack.add(value);

    // Maintain maximum stack size
    if (_undoStack.length > _maxUndoStackSize) {
      _undoStack.removeAt(0);
    }
  }

  /// Clear the redo stack (called when new edits are made)
  void _clearRedoStack() {
    _redoStack.clear();
  }

  /// Undo the last action
  void _undo() {
    if (!canUndo) return;

    _performProgrammaticChange(() {
      // Move current state to redo stack
      final currentValue = _undoStack.removeLast();
      _redoStack.add(currentValue);

      // Restore previous state
      final previousValue = _undoStack.last;
      _restoreValue(previousValue);
    });
  }

  /// Redo the last undone action
  void _redo() {
    if (!canRedo) return;

    _performProgrammaticChange(() {
      // Restore from redo stack
      final redoValue = _redoStack.removeLast();
      _undoStack.add(redoValue);
      _restoreValue(redoValue);
    });
  }

  /// Perform a programmatic change without triggering listeners
  void _performProgrammaticChange(VoidCallback operation) {
    _isProgrammaticChange = true;
    try {
      operation();
    } finally {
      _isProgrammaticChange = false;
      setState(() {});
    }
  }

  /// Restore a text editing value to the controller
  void _restoreValue(TextEditingValue value) {
    widget.controller.value = value;
    _lastUserEdit = value;
  }

  /// Check if undo operation is available
  bool get canUndo => _undoStack.length >= 2;

  /// Check if redo operation is available
  bool get canRedo => _redoStack.isNotEmpty;

  /// Get the current undo stack size (for debugging/testing)
  int get undoStackSize => _undoStack.length;

  /// Get the current redo stack size (for debugging/testing)
  int get redoStackSize => _redoStack.length;

  void _wrapText(String left, String right) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid ||
        selection.baseOffset < 0 ||
        selection.extentOffset < 0)
      return;

    final selected = selection.textInside(text);
    final before = selection.textBefore(text);
    final after = selection.textAfter(text);

    final newText = before + left + selected + right + after;

    widget.controller.value = widget.controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.baseOffset + left.length + selected.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Scrollbar(
        thumbVisibility: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _shortcut(
                "",
                'Undo',
                Icons.undo,
                _undo,
                enabled: _undoStack.length > 1,
              ),
              _shortcut(
                "",
                'Redo',
                Icons.redo,
                _redo,
                enabled: _redoStack.isNotEmpty,
              ),
              _shortcut(
                "B",
                'Bold',
                Icons.format_bold,
                () => _wrapText("**", "**"),
              ),
              _shortcut(
                "I",
                'Italic',
                Icons.format_italic,
                () => _wrapText("*", "*"),
              ),
              _shortcut(
                "Code",
                'Inline code',
                Icons.code,
                () => _wrapText("`", "`"),
              ),
              _shortcut(
                "Block",
                'Code block',
                Icons.notes,
                () => _wrapText("```\n", "\n```"),
              ),
              _shortcut(
                "H1",
                'Heading 1',
                Icons.title,
                () => _wrapText("# ", ""),
              ),
              _shortcut(
                "H2",
                'Heading 2',
                Icons.title,
                () => _wrapText("## ", ""),
              ),
              _shortcut(
                "List",
                'List',
                Icons.format_list_bulleted,
                () => _wrapText("- ", ""),
              ),
              _shortcut(
                "Link",
                'Insert link',
                Icons.link,
                () => _wrapText("[", "](url)"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcut(
    String label,
    String tooltip,
    IconData icon,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 200),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(7),
            onTap: enabled ? onPressed : null,
            highlightColor: Colors.amber.withOpacity(enabled ? 0.2 : 0.0),
            splashColor: Colors.amber.withOpacity(enabled ? 0.1 : 0.0),
            child: Ink(
              decoration: BoxDecoration(
                color: const Color.fromARGB(110, 0, 0, 0),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color.fromARGB(255, 87, 87, 87),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: enabled
                        ? Colors.amber
                        : Colors.amber.withOpacity(0.4),
                  ),
                  if (label.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
