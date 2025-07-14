import 'package:flutter/material.dart';
import 'package:study_forge/pages/editor_pages/markdownEditPage.dart';
//import 'package:study_forge/pages/ember_pages/ember_messaging_panel.dart';
import 'package:study_forge/pages/ember_pages/ember_chat_provider.dart';

// paths | pages
import 'package:study_forge/pages/homePage.dart';
import 'package:study_forge/pages/session_pages/studySession.dart';
import 'package:study_forge/pages/notesPage.dart';
import 'package:study_forge/pages/reminderPage.dart';
import 'package:study_forge/pages/editor_pages/noteEditPage.dart';
import 'package:study_forge/pages/settingsPage.dart';
import 'package:study_forge/tables/note_table.dart';

// utils
import 'package:study_forge/utils/navigationObservers.dart';

class ForgeDrawer extends StatelessWidget {
  final String selectedTooltip;
  final VoidCallback? onNewNote;
  final VoidCallback? onBrowseFiles;
  final VoidCallback? onHome;
  final VoidCallback? onNotePage;
  final VoidCallback? onReminderPage;
  final VoidCallback? onStudySessionPage;
  final VoidCallback? onSettingsPage;
  final VoidCallback? onEmberPage;

  ForgeDrawer({
    super.key,
    required this.selectedTooltip,
    this.onNewNote,
    this.onBrowseFiles,
    this.onHome,
    this.onNotePage,
    this.onReminderPage,
    this.onStudySessionPage,
    this.onSettingsPage,
    this.onEmberPage,
  });

  final noteManager = NoteManager();
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      width: 60,
      child: Column(
        children: [
          // TOP SECTION
          const SizedBox(height: 40),
          _SidebarIcon(
            icon: Icons.note_add_outlined,
            onPressed:
                onNewNote ??
                () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        NoteEditPage(noteManager: noteManager, isMD: false),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                ),
            tooltip: "New Note",
          ),
          const SizedBox(height: 10),
          _SidebarIcon(
            icon: Icons.note_alt_outlined,
            onPressed:
                onNewNote ??
                () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        MarkDownEditPage(noteManager: noteManager, isMD: true),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                ),
            tooltip: "New MD Note",
          ),
          const SizedBox(height: 10),
          _SidebarIcon(
            icon: Icons.folder_outlined,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color.fromARGB(
                    255,
                    37,
                    37,
                    37,
                  ).withValues(alpha: 0.8),
                  title: Text('🚧 Under Construction'),
                  content: Text(
                    'The Folder Manager Page is currently under development. Check back soon!',
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber,
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
            tooltip: "Browse Files",
          ),
          const Divider(color: Colors.white24, indent: 10, endIndent: 10),

          // MID SCROLLABLE SECTION
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SidebarIcon(
                    icon: Icons.home,
                    tooltip: "Home",
                    isSelected: selectedTooltip == "Home",
                    onPressed:
                        onHome ??
                        () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => ForgeHomePage(),
                            transitionsBuilder: (_, animation, __, child) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 10),
                  _SidebarIcon(
                    icon: Icons.notes,
                    tooltip: "Notes",
                    isSelected: selectedTooltip == "Notes",
                    onPressed:
                        onNotePage ??
                        () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => ForgeNotesPage(
                              source: NavigationSource.sidebar,
                            ),
                            transitionsBuilder: (_, animation, __, child) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 10),
                  _SidebarIcon(
                    icon: Icons.calendar_month,
                    tooltip: "Reminders",
                    isSelected: selectedTooltip == "Reminders",
                    onPressed:
                        onReminderPage ??
                        () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => ForgeReminderPage(
                              source: NavigationSource.sidebar,
                            ),
                            transitionsBuilder: (_, animation, __, child) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 10),
                  _SidebarIcon(
                    icon: Icons.school_outlined,
                    tooltip: "Study Sessions",
                    isSelected: selectedTooltip == "Study Sessions",
                    onPressed:
                        onStudySessionPage ??
                        () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => StudySessionPage(
                              source: NavigationSource.sidebar,
                            ),
                            transitionsBuilder: (_, animation, __, child) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 10),
                  //for (int i = 0; i < 10; i++) // Debug: Ember spam
                  _SidebarIcon(
                    icon: Icons.chat_bubble_outline,
                    tooltip: "Chat with Ember",
                    isSelected: selectedTooltip == "Ember",
                    onPressed:
                        onStudySessionPage ??
                        () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => EmberChatPage(),
                            transitionsBuilder: (_, animation, __, child) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),

          // BOTTOM SECTION
          const Divider(color: Colors.white24, indent: 10, endIndent: 10),

          _SidebarIcon(
            icon: Icons.settings_outlined,
            tooltip: "Settings",
            isSelected: selectedTooltip == "Settings",
            onPressed:
                onSettingsPage ??
                () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => SettingsPage(),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  const _SidebarIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(
        icon,
        color: isSelected ? Colors.amber : Colors.white70,
        size: 28,
      ),
      onPressed: onPressed,
    );
  }
}
