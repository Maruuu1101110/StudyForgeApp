import 'package:flutter/material.dart';
import '/algorithms/noteSearchAlgo.dart';
import 'homePage.dart';

class ForgeNotesPage extends StatefulWidget {
  const ForgeNotesPage({super.key});

  @override
  State<ForgeNotesPage> createState() => _ForgeNotesState();
}

class _ForgeNotesState extends State<ForgeNotesPage> {
  final noteManager = NoteManager();
  final FocusNode _searchfocus = FocusNode();
  List<Note> searchResults = [];

  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  RichText highlightText(
    String text,
    String query, {
    bool bold = false,
    double fontSize = 14,
  }) {
    final baseStyle = TextStyle(
      color: Colors.white,
      fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
      fontSize: fontSize,
    );

    if (query.isEmpty) {
      return RichText(
        text: TextSpan(text: text, style: baseStyle),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return RichText(
        text: TextSpan(text: text, style: baseStyle),
      );
    }

    final before = text.substring(0, matchIndex);
    final match = text.substring(matchIndex, matchIndex + query.length);
    final after = text.substring(matchIndex + query.length);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: baseStyle.copyWith(
              backgroundColor: Colors.amber,
              color: Colors.black,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  String getPreviewText(String content, {int wordLimit = 15}) {
    final words = content.split(RegExp(r'\s+')); // Split by spaces
    if (words.length <= wordLimit) return "\n        " + content;
    return '\n        ' + words.take(wordLimit).join(' ') + '...';
  }

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
        if (_searchfocus.hasFocus) {
          _searchfocus.unfocus();
          return false;
        }
        if (searchQuery.isNotEmpty) {
          setState(() {
            searchQuery = '';
            searchResults = noteManager.allNotes;
          });
          return false;
        }

        // Show exit confirmation as usual
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Color.fromRGBO(30, 30, 30, 1),
            title: const Text('Exit App?'),
            content: const Text(
              'Are you sure you want to exit?',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                style: ButtonStyle(elevation: WidgetStatePropertyAll(20)),
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
        // ...
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: Text("Notes"),
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
          width: 60, // Slim, just like Obsidian
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Icon Stack
              Column(
                children: [
                  const SizedBox(height: 40),
                  _SidebarIcon(
                    icon: Icons.note_add_outlined,
                    onPressed: () {},
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
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  ForgeHomePage(),
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
                    tooltip: "Home",
                  ),
                  _SidebarIcon(
                    icon: Icons.notes,
                    onPressed: () {},
                    tooltip: "Notes",
                    isSelected: true,
                  ),
                ],
              ),

              // Bottom Icon Stack (settings/logout)
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

        ///
        ///THIS IS THE BORDER BETWEEN THE BODY AND THE APP BAR
        ///
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // 🔍 The search field
              TextField(
                cursorColor: Colors.amber,
                focusNode: _searchfocus,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Search your notes...",
                  //enabledBorder: OutlineInputBorder(
                  //  borderSide: BorderSide(color: Colors.amber),
                  //),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                onChanged: (query) {
                  setState(() {
                    searchQuery = query;
                    searchResults = noteManager.searchNotes(query);
                  });
                },
              ),

              const SizedBox(height: 10),

              // 📋 The list of filtered notes
              Expanded(
                child: searchQuery.isEmpty
                    ? (noteManager.allNotes.isEmpty
                          ? const Center(
                              child: Text(
                                "No notes available.",
                                style: TextStyle(fontSize: 30),
                              ),
                            )
                          : ListView.builder(
                              itemCount: noteManager.allNotes.length,
                              itemBuilder: (context, index) {
                                final note = noteManager.allNotes[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ), // spacing between cards
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    color: Color.fromRGBO(19, 19, 19, 1),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: highlightText(
                                        note.title,
                                        searchQuery,
                                        bold: true,
                                        fontSize: 20,
                                      ),
                                      subtitle: highlightText(
                                        getPreviewText(
                                          note.content,
                                          wordLimit: 20,
                                        ),
                                        searchQuery,
                                        fontSize: 14,
                                      ),
                                      onTap: () {
                                        // open note
                                      },
                                    ),
                                  ),
                                );
                              },
                            ))
                    : (searchResults.isEmpty
                          ? const Center(
                              child: Text(
                                "No matching notes.",
                                style: TextStyle(fontSize: 20),
                              ),
                            )
                          : ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final note = searchResults[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    color: Color.fromRGBO(19, 19, 19, 1),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: highlightText(
                                        note.title,
                                        searchQuery,
                                        bold: true,
                                        fontSize: 20,
                                      ),
                                      subtitle: highlightText(
                                        getPreviewText(
                                          note.content,
                                          wordLimit: 20,
                                        ),
                                        searchQuery,
                                        fontSize: 14,
                                      ),
                                      onTap: () {
                                        // open note
                                      },
                                    ),
                                  ),
                                );
                              },
                            )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
