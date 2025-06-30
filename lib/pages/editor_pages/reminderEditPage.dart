import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:study_forge/tables/reminder_table.dart';
import 'package:study_forge/models/reminder_model.dart';

class ReminderEditPage extends StatefulWidget {
  final ReminderManager reminderManager;
  final Reminder? existingReminder;
  final String? id;
  final String? title;
  final String? description;
  final String? tags;
  final DateTime? dueDate;
  final bool? isPinned;
  final bool? isCompleted;

  const ReminderEditPage({
    Key? key,
    required this.reminderManager,
    this.existingReminder,
    this.id,
    this.title,
    this.description,
    this.tags,
    this.dueDate,
    this.isPinned,
    this.isCompleted,
  }) : super(key: key);

  @override
  _ReminderEditPageState createState() => _ReminderEditPageState();
}

class _ReminderEditPageState extends State<ReminderEditPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagController;

  late DateTime _dueDate;
  late TimeOfDay _dueTime;

  late bool _isPinned;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    final reminder = widget.existingReminder;

    _titleController = TextEditingController(text: reminder?.title ?? "");
    _descriptionController = TextEditingController(
      text: reminder?.description ?? "",
    );
    _tagController = TextEditingController(text: reminder?.tags ?? "");
    _dueDate = reminder?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _dueTime = TimeOfDay.fromDateTime(_dueDate);
    _isPinned = reminder?.isPinned ?? false;
    _isCompleted = reminder?.isCompleted ?? false;

    _titleController.addListener(_updateSaveButtonState);
    _descriptionController.addListener(_updateSaveButtonState);
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            dialogBackgroundColor: const Color.fromARGB(255, 25, 25, 25),
            colorScheme: ColorScheme.dark(
              primary: Colors.amber,
              surface: const Color.fromARGB(255, 30, 30, 30),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.amber),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dueDate) {
      setState(() => _dueDate = picked);
      _updateSaveButtonState(); // Update save button state when date changes
    }
  }

  Future<void> _selectDueTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber,
              surface: Color.fromARGB(255, 30, 30, 30),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Color.fromARGB(255, 25, 25, 25),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueTime) {
      setState(() {
        _dueTime = picked;
        _updateSaveButtonState();
      });
    }
  }

  void _saveReminder() async {
    final id = widget.existingReminder?.id ?? const Uuid().v4();
    final createdAt = widget.existingReminder?.createdAt ?? DateTime.now();

    final newReminder = Reminder(
      id: id,
      title: _titleController.text,
      description: _descriptionController.text,
      tags: _tagController.text.isNotEmpty ? _tagController.text : null,
      dueDate: DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      ),
      // Combine date and time into a single DateTime object
      createdAt: createdAt,
      isPinned: _isPinned,
      isCompleted: _isCompleted,
    );

    if (widget.existingReminder != null) {
      await widget.reminderManager.updateReminder(newReminder);
    } else {
      await widget.reminderManager.addReminder(newReminder);
    }

    Navigator.of(context).pop();
  }

  bool _isSaveEnabled = false;
  void _updateSaveButtonState() {
    final hasText =
        _titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty;

    if (hasText != _isSaveEnabled) {
      setState(() => _isSaveEnabled = hasText);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 18, 18),
        title: Text(
          widget.existingReminder == null ? 'Add Reminder' : 'Edit Reminder',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.save,
                  key: ValueKey<bool>(_isSaveEnabled), // forces switch
                  color: _isSaveEnabled ? Colors.amber : Colors.grey,
                  size: 30,
                ),
              ),
            ),
            onPressed: _isSaveEnabled ? _saveReminder : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SizedBox(height: 10),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Subject'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              minLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Description'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  "Tags: ",
                  style: TextStyle(fontSize: 20, color: Colors.amberAccent),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _tagController.text.isNotEmpty
                      ? _tagController.text
                      : null,
                  dropdownColor: const Color.fromARGB(255, 30, 30, 30),
                  iconEnabledColor: Colors.amber,
                  underline: Container(),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'Work', child: Text('Work')),
                    DropdownMenuItem(
                      value: 'Personal',
                      child: Text('Personal'),
                    ),
                    DropdownMenuItem(value: 'Study', child: Text('Study')),
                    DropdownMenuItem(
                      value: 'Projects',
                      child: Text('Projects'),
                    ),
                    DropdownMenuItem(value: 'Health', child: Text('Health')),
                    DropdownMenuItem(value: 'Others', child: Text('Others')),
                  ],
                  onChanged: (value) {
                    setState(() => _tagController.text = value ?? '');
                    _updateSaveButtonState(); // Update save button state
                  },
                  hint: Text(
                    _tagController.text.isNotEmpty
                        ? _tagController.text
                        : "Select Tag",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              tileColor: const Color.fromARGB(255, 25, 25, 25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              title: const Text(
                'Due Date & Time',
                style: TextStyle(color: Colors.amber),
              ),
              subtitle: Text(
                '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}'
                ' - ${_dueTime.format(context)}',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.amber),
                    tooltip: 'Pick date',
                    onPressed: () => _selectDueDate(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time, color: Colors.amber),
                    tooltip: 'Pick time',
                    onPressed: () => _selectDueTime(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            SwitchListTile(
              inactiveTrackColor: const Color.fromARGB(75, 50, 50, 50),
              activeColor: Colors.amber,
              activeTrackColor: const Color.fromARGB(255, 77, 57, 0),
              inactiveThumbColor: Colors.amber,
              title: const Text(
                'Pin Reminder',
                style: TextStyle(color: Colors.amber),
              ),
              value: _isPinned,
              onChanged: (value) => setState(() {
                _isPinned = value;
                _updateSaveButtonState();
                // Update save button state
              }),
            ),
            SwitchListTile(
              inactiveTrackColor: const Color.fromARGB(75, 50, 50, 50),
              activeColor: Colors.amber,
              activeTrackColor: const Color.fromARGB(255, 77, 57, 0),
              inactiveThumbColor: Colors.amber,
              title: const Text(
                'Mark as Completed',
                style: TextStyle(color: Colors.amber),
              ),
              value: _isCompleted,
              onChanged: (value) => setState(() {
                _isCompleted = value;
                _updateSaveButtonState(); // Update save button state
              }),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color.fromARGB(138, 255, 255, 255)),
      floatingLabelStyle: const TextStyle(color: Colors.amber),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.amber, width: 2.0),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(80, 255, 193, 7)),
      ),
    );
  }
}
