import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:study_forge/algorithms/noteSearchAlgo.dart';

class NoteEditPage extends StatefulWidget {
  final NoteManager noteManager;
  final String? id;
  final String? title;
  final String? content;
  final bool isMD;

  const NoteEditPage({
    super.key,
    required this.noteManager,
    this.id,
    this.title,
    this.content,
    required this.isMD,
  });

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final noteManager = NoteManager();
  late TextEditingController _titleController = TextEditingController();
  late TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _contentController = TextEditingController(text: widget.content);

    _titleController.addListener(() {
      setState(() {});
    });

    _titleController.addListener(_updateSaveButtonState);
    _contentController.addListener(_updateSaveButtonState);
  }

  bool isSaveEnabled = false;
  void _updateSaveButtonState() {
    final hasText =
        _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty;
    if (hasText != isSaveEnabled) {
      setState(() => isSaveEnabled = hasText);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void addNote() {
    final idToUse = widget.id ?? Uuid().v4();
    widget.noteManager.addNote(
      idToUse,
      _titleController.text,
      _contentController.text,
      widget.isMD,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ...
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text("Notes"),
        titleSpacing: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(
                Icons.navigate_before_rounded,
                color: Colors.white,
                size: 40,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: isSaveEnabled
                ? () async {
                    final id = widget.id ?? Uuid().v4();
                    final title = _titleController.text.trim();
                    final content = _contentController.text.trim();
                    final isMD = false;

                    if (widget.id != null) {
                      await widget.noteManager.updateNote(
                        id,
                        title,
                        content,
                        isMD,
                      );
                    } else {
                      await widget.noteManager.addNote(
                        id,
                        title,
                        content,
                        isMD,
                      );
                    }

                    Navigator.pop(context);
                  }
                : null,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.save,
                  key: ValueKey<bool>(isSaveEnabled), // forces switch
                  color: isSaveEnabled ? Colors.amber : Colors.grey,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: Colors.amber,
                  selectionColor: Color(0x44FFC107),
                  selectionHandleColor: Colors.amber,
                ),
              ),
              child: TextFormField(
                controller: _titleController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 35,
                ), // 🔥 makes the input text amber
                decoration: InputDecoration(
                  hintText: "Title",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            Divider(thickness: 1, indent: 10, endIndent: 10),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: Colors.amber,
                    selectionColor: Color(0x44FFC107),
                    selectionHandleColor: Colors.amber,
                  ),
                ),
                child: TextFormField(
                  controller: _contentController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Type something...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
