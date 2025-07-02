import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// database
import 'package:study_forge/models/note_model.dart';
import 'package:study_forge/tables/note_table.dart';
import 'package:study_forge/tables/reminder_table.dart';

// custom widgets
import 'package:study_forge/components/sideBar.dart';

// utils
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_forge/utils/notification_service.dart';

class ForgeHomePage extends StatefulWidget {
  const ForgeHomePage({super.key});

  @override
  State<ForgeHomePage> createState() => _ForgeHomeState();
}

class _ForgeHomeState extends State<ForgeHomePage> {
  final noteManager = NoteManager();
  final reminderManager = ReminderManager();
  List<Note> allNotes = [];

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  void _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun') ?? true;

    if (isFirstRun) {
      await noteManager.ensureNoteTableExists();
      await reminderManager.ensureReminderTableExists();

      await prefs.setBool('isFirstRun', false);
    }
  }

  void loadAllNotes() async {
    final notes = await NoteManager().getAllNotes();
    setState(() => allNotes = notes);
  }

  Set<String> selectedNotes = {};
  List<Note> searchResults = [];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Color.fromRGBO(30, 30, 30, 1),
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: const Text("Home"),
          titleSpacing: 0,
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ),
        drawer: ForgeDrawer(selectedTooltip: "Home"),
        body: ElevatedButton(
          onPressed: () {
            final scheduledTime = DateTime.now().add(Duration(seconds: 10));
            NotificationService.scheduleNotification(
              id: 1,
              title: "Scheduled Notif",
              body: "This was scheduled 10 seconds ago!",
              scheduledTime: scheduledTime,
              payload: "hello_from_schedule",
            );
          },
          child: Text("Debug for Notification Scheduler."),
        ),
      ),
    );
  }
}
