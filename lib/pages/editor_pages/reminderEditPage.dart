import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:study_forge/tables/reminder_table.dart';
import 'package:study_forge/models/reminder_model.dart';
import 'package:study_forge/utils/notification_service.dart';

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
  final String? notificationId;
  final String? notificationTime;

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
    this.notificationId,
    this.notificationTime,
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

  late bool _willNotify;
  String _selectedLeadTimeKey = '5m';
  Duration _customLeadTimeDuration = Duration.zero;
  late String? _selectedUnit = 'minutes';
  late bool _isSaving = false;

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
    _willNotify = reminder?.isNotifEnabled ?? true;

    _titleController.addListener(_updateSaveButtonState);
    _descriptionController.addListener(_updateSaveButtonState);
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: _dueDate.isBefore(DateTime.now()) ? _dueDate : DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            dialogTheme: const DialogThemeData(
              backgroundColor: const Color.fromARGB(255, 25, 25, 25),
            ),
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
      _updateSaveButtonState();
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
    setState(() => _isSaving = true);
    final id = widget.existingReminder?.id ?? const Uuid().v4();
    final createdAt = widget.existingReminder?.createdAt ?? DateTime.now();
    // fix here: adjusted to fit into the 32-bit error
    int getNotificationIdFromReminder =
        DateTime.now().millisecondsSinceEpoch % 2147483647;

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
      createdAt: createdAt,
      isPinned: _isPinned,
      isCompleted: _isCompleted,
      isNotifEnabled: _willNotify,
      notificationId: getNotificationIdFromReminder,
    );
    try {
      if (widget.existingReminder != null) {
        // will cancel old notifs when updating/updated
        await NotificationService.cancelNotification(
          widget.existingReminder!.notificationId,
        );
        await widget.reminderManager.updateReminder(newReminder);
      } else {
        await widget.reminderManager.addReminder(newReminder);
      }
    } catch (e) {
      debugPrint("Error saving reminder: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error Saving: $e")));
      setState(() => _isSaving = false);
      return;
    }

    final scheduledTime = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    ).subtract(getLeadTimeDuration(_selectedLeadTimeKey));
    try {
      if (scheduledTime.isAfter(DateTime.now()) && _willNotify) {
        await NotificationService.scheduleNotification(
          id: getNotificationIdFromReminder, // use the new notification ID ALWAYS
          title: _titleController.text.isNotEmpty
              ? "⏰️Reminder: ${_titleController.text} | Due in $_selectedLeadTimeKey"
              : "⏰️ Reminder",
          body: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : "⚠️ You have a reminder due in $_selectedLeadTimeKey.",
          scheduledTime: scheduledTime,
          payload: id,
        );
      }
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error Scheduling: $e")));
      setState(() => _isSaving = false);
      return;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  Duration getLeadTimeDuration(String key) {
    if (key == 'custom...') {
      return _customLeadTimeDuration;
    }
    switch (key) {
      case '5m':
        return const Duration(minutes: 5);
      case '10m':
        return const Duration(minutes: 10);
      case '15m':
        return const Duration(minutes: 15);
      case '30m':
        return const Duration(minutes: 30);
      case '1h':
        return const Duration(hours: 1);
      default:
        return const Duration(minutes: 5);
    }
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
            onPressed: _isSaveEnabled && !_isSaving ? _saveReminder : null,
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
                  style: TextStyle(fontSize: 20, color: Colors.amber),
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
                    _updateSaveButtonState();
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
            SwitchListTile(
              inactiveTrackColor: const Color.fromARGB(75, 50, 50, 50),
              activeColor: Colors.amber,
              activeTrackColor: const Color.fromARGB(255, 77, 57, 0),
              inactiveThumbColor: Colors.amber,
              title: const Text(
                'Enable Notifications',
                style: TextStyle(color: Colors.amber),
              ),
              value: _willNotify,
              onChanged: (value) => setState(() {
                _willNotify = value;
                _updateSaveButtonState();
              }),
            ),
            const SizedBox(width: 10),
            if (_willNotify)
              Row(
                children: [
                  Text("Remind me before:", style: TextStyle(fontSize: 18)),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedLeadTimeKey,
                    dropdownColor: const Color.fromARGB(255, 30, 30, 30),
                    iconEnabledColor: Colors.amber,
                    underline: Container(),
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "Petrona",
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '5m',
                        child: Text(
                          '5 Minutes',
                          style: TextStyle(fontFamily: "Petrona"),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '10m',
                        child: Text(
                          '10 Minutes',
                          style: TextStyle(fontFamily: "Petrona"),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '15m',
                        child: Text(
                          '15 Minutes',
                          style: TextStyle(fontFamily: "Petrona"),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '30m',
                        child: Text(
                          '30 Minutes',
                          style: TextStyle(fontFamily: "Petrona"),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '1h',
                        child: Text(
                          '1 Hour',
                          style: TextStyle(fontFamily: "Petrona"),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'custom...',
                        child: Text(
                          'custom...',
                          style: TextStyle(fontFamily: "Petrona"),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedLeadTimeKey = value ?? '5m');
                      if (_selectedLeadTimeKey == "custom...") {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            TextEditingController customLeadTimeController =
                                TextEditingController();

                            return AlertDialog(
                              backgroundColor: const Color.fromARGB(
                                255,
                                30,
                                30,
                                30,
                              ),
                              title: const Text(
                                "Custom Lead Time",
                                style: TextStyle(color: Colors.amber),
                              ),
                              content: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: customLeadTimeController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: "Enter duration",
                                        hintStyle: TextStyle(
                                          color: Colors.white70,
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.amber,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.amber,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  DropdownButton<String>(
                                    value: _selectedUnit ?? 'minutes',
                                    dropdownColor: Color.fromARGB(
                                      255,
                                      30,
                                      30,
                                      30,
                                    ),
                                    iconEnabledColor: Colors.amber,
                                    style: TextStyle(color: Colors.white),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'minutes',
                                        child: Text(
                                          'min',
                                          style: TextStyle(
                                            fontFamily: "Petrona",
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'hours',
                                        child: Text(
                                          'hrs',
                                          style: TextStyle(
                                            fontFamily: "Petrona",
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'days',
                                        child: Text(
                                          'day',
                                          style: TextStyle(
                                            fontFamily: "Petrona",
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedUnit = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              actions: [
                                TextButton(
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                TextButton(
                                  child: const Text(
                                    "Save",
                                    style: TextStyle(color: Colors.amber),
                                  ),
                                  onPressed: () {
                                    final input = customLeadTimeController.text;
                                    final parsed = int.tryParse(input);

                                    try {
                                      if (parsed != null) {
                                        Duration leadTime;

                                        switch (_selectedUnit) {
                                          case 'minutes':
                                            leadTime = Duration(
                                              minutes: parsed,
                                            );
                                            break;
                                          case 'hours':
                                            leadTime = Duration(hours: parsed);
                                            break;
                                          case 'days':
                                            leadTime = Duration(days: parsed);
                                            break;
                                          default:
                                            leadTime = Duration(
                                              minutes: parsed,
                                            );
                                        }

                                        setState(() {
                                          _customLeadTimeDuration = leadTime;
                                          _selectedLeadTimeKey = "custom...";
                                        });
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("Invalid input: $e"),
                                        ),
                                      );
                                    }

                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    hint: const Text(
                      "Remind me before...",
                      style: TextStyle(color: Colors.white70),
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
              onChanged: (value) {
                _isCompleted = true;
                setState(() {
                  _updateSaveButtonState();
                });
              },
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
