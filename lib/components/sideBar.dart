import 'package:flutter/material.dart';
import 'package:study_forge/pages/homePage.dart';
import 'package:study_forge/pages/notesPage.dart';
import 'package:study_forge/pages/reminderPage.dart';
import 'package:study_forge/pages/editor_pages/noteEditPage.dart';
import 'package:study_forge/tables/note_table.dart';

class ForgeDrawer extends StatelessWidget {
  final String selectedTooltip;
  final VoidCallback? onNewNote;
  final VoidCallback? onBrowseFiles;
  final VoidCallback? onHome;
  final VoidCallback? onNotePage;
  final VoidCallback? onReminderPage;
  final VoidCallback? onSettings;

  ForgeDrawer({
    super.key,
    required this.selectedTooltip,
    this.onNewNote,
    this.onBrowseFiles,
    this.onHome,
    this.onNotePage,
    this.onReminderPage,
    this.onSettings,
  });

  final noteManager = NoteManager();
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      width: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top section
          Column(
            children: [
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
              _SidebarIcon(
                icon: Icons.folder_outlined,
                onPressed: onBrowseFiles ?? () {},
                tooltip: "Browse Files",
              ),

              const Divider(color: Colors.white24, indent: 10, endIndent: 10),

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
                            FadeTransition(opacity: animation, child: child),
                      ),
                    ),
              ),

              _SidebarIcon(
                icon: Icons.notes,
                tooltip: "Notes",
                isSelected: selectedTooltip == "Notes",
                onPressed:
                    onNotePage ??
                    () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                            ForgeNotesPage(source: NavigationSource.sidebar),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    ),
              ),
              _SidebarIcon(
                icon: Icons.calendar_month,
                tooltip: "Reminders",
                isSelected: selectedTooltip == "Reminders",
                onPressed:
                    onReminderPage ??
                    () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => ForgeReminderPage(),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    ),
              ),
            ],
          ),

          // Bottom section
          Column(
            children: [
              const Divider(color: Colors.white24, indent: 10, endIndent: 10),
              _SidebarIcon(
                icon: Icons.settings_outlined,
                tooltip: "Settings",
                isSelected: selectedTooltip == "Settings",
                onPressed: () {},
              ),
              const SizedBox(height: 20),
            ],
          ),
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
