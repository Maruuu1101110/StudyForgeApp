import 'package:flutter/material.dart';
import 'package:study_forge/algorithms/noteSearchAlgo.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:study_forge/pages/homePage.dart';

class NoteEditPage extends StatefulWidget {
  final NoteManager noteManager;
  final String? id;
  final String? title;
  final String? content;

  const NoteEditPage({
    super.key,
    required this.noteManager,
    this.id,
    this.title,
    this.content,
  });

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  late TextEditingController _titleController = TextEditingController();
  late TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    _titleController = TextEditingController(text: widget.title);
    _contentController = TextEditingController(text: widget.content);

    _titleController.addListener(() {
      setState(() {});
    });
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.all(20),
        child: SpeedDial(
          icon: Icons.add,
          buttonSize: Size(55, 55),
          activeIcon: Icons.close,
          backgroundColor: Colors.amber,
          overlayColor: Color.fromRGBO(0, 0, 0, 0.1),
          childMargin: EdgeInsets.only(right: 2),
          spaceBetweenChildren: 10,
          children: [
            SpeedDialChild(
              backgroundColor: Color.fromRGBO(30, 30, 30, 1),
              labelBackgroundColor: Color.fromRGBO(30, 30, 30, 0),
              labelShadow: [],
              child: Icon(Icons.note_add, color: Colors.amber),
              label: 'New Note',
              onTap: () => Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      NoteEditPage(noteManager: widget.noteManager),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                ),
              ),
            ),
            SpeedDialChild(
              backgroundColor: Color.fromRGBO(30, 30, 30, 1),
              labelBackgroundColor: Color.fromRGBO(30, 30, 30, 0),
              labelShadow: [],
              child: Icon(Icons.folder_open, color: Colors.amber),
              label: 'Open Folder',
              onTap: () => print('Open Folder tapped'),
            ),
          ],
        ),
      ),
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
            icon: Icon(Icons.save, color: Colors.amber),
            onPressed: () async {
              final id = widget.id ?? Uuid().v4();
              final title = _titleController.text.trim();
              final content = _contentController.text.trim();

              if (widget.id != null) {
                await widget.noteManager.updateNote(id, title, content);
              } else {
                await widget.noteManager.addNote(id, title, content);
              }

              Navigator.pop(context); // Go back after saving
            },
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
                  style: const TextStyle(
                    color: Colors.white,
                  ), // 🔥 makes the input text amber
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
