import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:study_forge/components/markdownShortcut.dart';
import 'package:study_forge/components/wordLimiter.dart';
import 'package:study_forge/tables/note_table.dart';
import 'package:study_forge/components/smart_md_editor.dart';
import 'package:study_forge/utils/file_manager_service.dart';
import 'package:path/path.dart' as path;
import 'package:study_forge/utils/code_wrapper.dart';

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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool isOnRead = true;
  bool isSaveEnabled = false;

  final codeWrapper = (Widget child, String text, String language) =>
      CodeWrapperWidget(child: child, text: text);

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title ?? '';
    _contentController.text = widget.content ?? '';

    _titleController.addListener(_updateSaveButtonState);
    _contentController.addListener(_updateSaveButtonState);
  }

  void _updateSaveButtonState() {
    final hasText =
        _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty;
    setState(() => isSaveEnabled = hasText);
  }

  void _addOrUpdateNote() async {
    final id = widget.id ?? Uuid().v4();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (widget.id != null) {
      await widget.noteManager.updateNote(id, title, content, widget.isMD);
    } else {
      await widget.noteManager.addNote(id, title, content, widget.isMD);
    }

    Navigator.pop(context);
  }

  Future<String?> _showSubjectPicker() async {
    final basePath = await FileManagerService.instance.getStudyForgeBasePath();
    final roomDirs = Directory(basePath).listSync().whereType<Directory>();

    final subjects = <String>[];
    for (final dir in roomDirs) {
      final metadata = await FileManagerService.instance
          .getRoomMetadataFromPath(dir.path);
      if (metadata != null && metadata['subject'] != null) {
        subjects.add(metadata['subject']);
      }
    }

    return await showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Row(
            children: const [
              Icon(Icons.school, color: Colors.amber),
              SizedBox(width: 10),
              Text('Pick a Subject', style: TextStyle(fontFamily: "Petrona")),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Container(
            constraints: const BoxConstraints(maxHeight: 300, minWidth: 280),
            width: double.minPositive,
            child: subjects.isEmpty
                ? const Center(child: Text("No subjects found."))
                : ListView.separated(
                    itemCount: subjects.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.book_outlined,
                          color: Colors.deepOrangeAccent,
                        ),
                        title: Text(
                          subject,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(subject),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Future<void> _exportMarkdown() async {
    final markdownText = _contentController.text;
    if (markdownText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note is empty!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedSubject = await _showSubjectPicker();
    if (selectedSubject == null) return;

    final matchedRoomId = await FileManagerService.instance
        .getRoomIdFromSubject(selectedSubject);

    if (matchedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subject "$selectedSubject" not found')),
      );
      return;
    }

    final filesPath = await FileManagerService.instance.getFilesPath(
      matchedRoomId,
    );
    final fileName = 'Note_${DateTime.now().millisecondsSinceEpoch}.md';
    final filePath = path.join(filesPath, fileName);

    final file = File(filePath);
    await file.writeAsString(markdownText);
    await FileManagerService.instance.incrementFileCount(matchedRoomId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Markdown saved to "$selectedSubject"!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text("Mark Down Notes", style: TextStyle(fontSize: 20)),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.navigate_before,
            color: Colors.white,
            size: 40,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: _exportMarkdown,
            icon: const Icon(Icons.file_upload, color: Colors.amber, size: 25),
          ),
          IconButton(
            onPressed: () => setState(() => isOnRead = !isOnRead),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: isOnRead
                  ? const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.amber,
                      size: 30,
                    )
                  : const Icon(
                      Icons.remove_red_eye,
                      color: Colors.amber,
                      size: 25,
                    ),
            ),
          ),
          IconButton(
            onPressed: isSaveEnabled ? _addOrUpdateNote : null,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: FaIcon(
                  FontAwesomeIcons.floppyDisk,
                  key: ValueKey<bool>(isSaveEnabled),
                  color: isSaveEnabled ? Colors.amber : Colors.grey,
                  size: 23,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Column(
          children: [
            if (!isOnRead)
              TitleField(controller: _titleController, wordLimit: 5),
            if (!isOnRead) const Divider(thickness: 1),
            Expanded(
              child: isOnRead
                  ? MarkdownWidget(
                      config: MarkdownConfig.darkConfig.copy(
                        configs: [
                          PreConfig.darkConfig.copy(
                            wrapper: codeWrapper,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'SourceCodePro',
                            ),
                          ),
                          CodeConfig(
                            style: const TextStyle(
                              fontFamily: 'SourceCodePro',
                              fontSize: 14,
                              backgroundColor: Colors.black12,
                              color: Colors.tealAccent,
                            ),
                          ),
                          PConfig(textStyle: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      data: _contentController.text,
                    )
                  : SmartMarkdownEditor(controller: _contentController),
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
