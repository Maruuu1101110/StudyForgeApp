import 'package:flutter/material.dart';
import 'package:study_forge/pages/homePage.dart';
import 'package:study_forge/pages/noteRelated/noteEditPage.dart';
import 'package:study_forge/algorithms/noteSearchAlgo.dart';

class ForgeDrawer extends StatelessWidget {
  final VoidCallback onNewNote;
  final VoidCallback onBrowseFiles;

  ForgeDrawer({
    super.key,
    required this.onNewNote,
    required this.onBrowseFiles,
  });

  final noteManager = NoteManager();
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      width: 60, // Slim, just like Obsidian
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top section
          Column(
            children: [
              const SizedBox(height: 40),
              _SidebarIcon(
                icon: Icons.note_add_outlined,
                onPressed: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        NoteEditPage(noteManager: noteManager),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                ),
                tooltip: "New Note",
              ),
              _SidebarIcon(
                icon: Icons.folder_outlined,
                onPressed: onBrowseFiles,
                tooltip: "Browse Files",
              ),

              const Divider(color: Colors.white24, indent: 10, endIndent: 10),

              _SidebarIcon(
                icon: Icons.home,
                tooltip: "Home",
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const ForgeHomePage(),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                    ),
                  );
                },
              ),
              _SidebarIcon(
                icon: Icons.notes,
                tooltip: "Notes",
                isSelected: true,
                onPressed: () {},
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
