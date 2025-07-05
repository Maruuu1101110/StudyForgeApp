import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:study_forge/pages/editor_pages/markdownEditPage.dart';
import 'package:study_forge/pages/editor_pages/noteEditPage.dart';
import 'package:study_forge/pages/editor_pages/reminderEditPage.dart';
import 'package:study_forge/pages/session_pages/sessionEditPage.dart';

import 'package:study_forge/tables/note_table.dart';
import 'package:study_forge/tables/reminder_table.dart';
import 'package:study_forge/tables/room_table.dart';

class FloatingSpeedDial extends StatelessWidget {
  final bool? isNotes;
  final bool? isReminders;
  final bool? isStudySessions;
  final VoidCallback? onCreateRoom;

  const FloatingSpeedDial({
    super.key,
    this.isNotes,
    this.isReminders,
    this.isStudySessions,
    this.onCreateRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        buttonSize: const Size(45, 45),
        backgroundColor: Colors.amber,
        gradientBoxShape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber.shade600, Colors.orange.shade600],
        ),
        overlayColor: const Color.fromRGBO(0, 0, 0, 0.1),
        childMargin: const EdgeInsets.only(right: 2),
        spaceBetweenChildren: 10,
        children: [
          SpeedDialChild(
            visible: isStudySessions ?? false,
            backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
            labelBackgroundColor: Colors.transparent,
            labelShadow: [],
            child: const Icon(Icons.meeting_room, color: Colors.amber),
            label: 'New Study Room',
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    RoomEditPage(roomTableManager: RoomTableManager()),

                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            ),
          ),

          SpeedDialChild(
            visible: isNotes ?? false,
            backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
            labelBackgroundColor: Colors.transparent,
            labelShadow: [],
            child: const Icon(Icons.note_add, color: Colors.amber),
            label: 'New Note',
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    NoteEditPage(noteManager: NoteManager(), isMD: false),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            ),
          ),

          SpeedDialChild(
            visible: isNotes ?? false,
            backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
            labelBackgroundColor: Colors.transparent,
            labelShadow: [],
            child: const Icon(Icons.note_alt_outlined, color: Colors.amber),
            label: 'New MD Note',
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    MarkDownEditPage(noteManager: NoteManager(), isMD: true),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            ),
          ),

          SpeedDialChild(
            visible: isReminders ?? false,
            backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
            labelBackgroundColor: Colors.transparent,
            labelShadow: [],
            child: const Icon(Icons.note_alt_outlined, color: Colors.amber),
            label: 'Add Reminder',
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    ReminderEditPage(reminderManager: ReminderManager()),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            ),
          ),

          SpeedDialChild(
            backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
            labelBackgroundColor: Colors.transparent,
            labelShadow: [],
            child: const Icon(Icons.folder_open, color: Colors.amber),
            label: 'Open Folder',
            onTap: () => print('Open Folder tapped'),
          ),

          SpeedDialChild(
            child: const Icon(Icons.search, color: Colors.amber),
            label: 'Search',
            labelBackgroundColor: Colors.transparent,
            labelShadow: [],
            backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
            onTap: () => print("Pressed Search"),
          ),
        ],
      ),
    );
  }
}
