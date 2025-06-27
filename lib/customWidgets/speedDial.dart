import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:study_forge/pages/editor_pages/markdownEditPage.dart';
import 'package:study_forge/pages/editor_pages/noteEditPage.dart';
import 'package:study_forge/algorithms/noteSearchAlgo.dart';

class FloatingSpeedDial extends StatelessWidget {
  const FloatingSpeedDial({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        buttonSize: const Size(55, 55),
        backgroundColor: Colors.amber,
        overlayColor: const Color.fromRGBO(0, 0, 0, 0.1),
        childMargin: const EdgeInsets.only(right: 2),
        spaceBetweenChildren: 10,
        children: [
          SpeedDialChild(
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
            backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
            labelBackgroundColor: Colors.transparent,
            labelShadow: [],
            child: const Icon(Icons.folder_open, color: Colors.amber),
            label: 'Open Folder',
            onTap: () => print('Open Folder tapped'),
          ),

          SpeedDialChild(
            child: const Icon(Icons.search, color: Colors.amber),
            label: 'Search Notes',
            labelBackgroundColor: Colors.transparent,
            labelShadow: [],
            backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
            onTap: () => print("Pressed Search Notes"),
          ),
        ],
      ),
    );
  }
}
