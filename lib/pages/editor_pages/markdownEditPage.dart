import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// custom widgets
import 'package:study_forge/components/markdownShortcut.dart';
import 'package:study_forge/components/wordLimiter.dart';

// algorithms
import 'package:study_forge/algorithms/noteSearchAlgo.dart';
import 'package:study_forge/components/smart_md_editor.dart';

//markdown packages //
import 'package:markdown_widget/markdown_widget.dart';

class MarkDownEditPage extends StatefulWidget {
  final NoteManager noteManager;
  final String? id;
  final String? title;
  final String? content;
  final bool isMD;

  const MarkDownEditPage({
    super.key,
    required this.noteManager,
    this.id,
    this.title,
    this.content,
    required this.isMD,
  });

  @override
  State<MarkDownEditPage> createState() => _MarkDownEditPageState();
}

class _MarkDownEditPageState extends State<MarkDownEditPage> {
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

  bool isOnRead = true;

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
        title: Text("Mark Down Notes", style: TextStyle(fontSize: 20)),
        titleSpacing: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(
                Icons.navigate_before,
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
            onPressed: isOnRead
                ? () async {
                    setState(() {
                      isOnRead = false;
                    });
                  }
                : () {
                    setState(() {
                      isOnRead = true;
                    });
                  },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: isOnRead
                  ? Icon(Icons.edit_note_rounded, color: Colors.amber, size: 30)
                  : Icon(Icons.remove_red_eye, color: Colors.amber, size: 25),
            ),
          ),

          IconButton(
            onPressed: isSaveEnabled
                ? () async {
                    final id = widget.id ?? Uuid().v4();
                    final title = _titleController.text.trim();
                    final content = _contentController.text.trim();
                    final isMD = true;

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
                padding: EdgeInsets.only(right: 15),
                child: FaIcon(
                  FontAwesomeIcons.save,
                  key: ValueKey<bool>(isSaveEnabled), // forces switch
                  color: isSaveEnabled ? Colors.amber : Colors.grey,
                  size: 23,
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
              child: isOnRead
                  ? SizedBox(width: 10)
                  : TitleField(controller: _titleController, wordLimit: 5),
            ),
            if (!isOnRead) Divider(thickness: 1, indent: 10, endIndent: 10),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: Colors.amber,
                    selectionColor: Color(0x44FFC107),
                    selectionHandleColor: Colors.amber,
                  ),
                ),
                child: Expanded(
                  child: isOnRead
                      ? MarkdownWidget(
                          config: MarkdownConfig.darkConfig,
                          padding: EdgeInsets.all(10),
                          data: _contentController.text,
                        )
                      : Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: const TextSelectionThemeData(
                              cursorColor: Colors.amber,
                              selectionColor: Color(0x44FFC107),
                              selectionHandleColor: Colors.amber,
                            ),
                          ),
                          child: SmartMarkdownEditor(
                            controller: _contentController,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomSheet: !isOnRead
          ? SafeArea(child: MarkdownShortcutBar(controller: _contentController))
          : null,
    );
  }
}
