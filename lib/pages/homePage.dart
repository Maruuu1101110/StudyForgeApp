import 'package:flutter/material.dart';
import 'package:study_forge/algorithms/noteSearchAlgo.dart';
import 'package:study_forge/pages/notesPage.dart';
import 'package:study_forge/pages/noteRelated/noteEditPage.dart';

class ForgeHomePage extends StatefulWidget {
  const ForgeHomePage({super.key});

  @override
  State<ForgeHomePage> createState() => _ForgeHomeState();
}

class _ForgeHomeState extends State<ForgeHomePage> {
  Widget _SidebarIcon({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isSelected = false,
  }) {
    return IconButton(
      isSelected: true,
      icon: Icon(icon, color: isSelected ? Colors.amber : Colors.white),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 24,
      padding: const EdgeInsets.all(8),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          return isSelected ? Colors.white12 : Colors.transparent;
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        overlayColor: WidgetStateProperty.all(Colors.white10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
        return shouldExit ?? false;
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
        drawer: Drawer(
          backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
          width: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 40),
                  _SidebarIcon(
                    icon: Icons.note_add_outlined,
                    onPressed: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                            NoteEditPage(noteManager: NoteManager()),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    ),
                    tooltip: "New Note",
                  ),
                  _SidebarIcon(
                    icon: Icons.folder_outlined,
                    onPressed: () {},
                    tooltip: "Browse Files",
                  ),
                  const Divider(
                    color: Colors.white24,
                    indent: 10,
                    endIndent: 10,
                  ),
                  _SidebarIcon(
                    icon: Icons.home,
                    onPressed: () {},
                    tooltip: "Home",
                    isSelected: true,
                  ),
                  _SidebarIcon(
                    icon: Icons.notes,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  ForgeNotesPage(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                        ),
                      );
                    },
                    tooltip: "Notes",
                  ),
                ],
              ),
              Column(
                children: [
                  const Divider(
                    color: Colors.white24,
                    indent: 10,
                    endIndent: 10,
                  ),
                  _SidebarIcon(
                    icon: Icons.settings_outlined,
                    onPressed: () {},
                    tooltip: "Settings",
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Welcome to this "WTF is this app".... just do some random shi-\n\n\nbtw Settings and Folder is out of service, same with Search....<heh>',
            style: TextStyle(fontSize: 25),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
