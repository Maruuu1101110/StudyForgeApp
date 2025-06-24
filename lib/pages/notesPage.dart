import 'package:flutter/material.dart';
import '/algorithms/noteSearchAlgo.dart';
import 'homePage.dart';
import 'noteRelated/noteEditPage.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:study_forge/algorithms/navigationObservers.dart';

class ForgeNotesPage extends StatefulWidget {
  const ForgeNotesPage({super.key});

  @override
  State<ForgeNotesPage> createState() => _ForgeNotesState();
}

class _ForgeNotesState extends State<ForgeNotesPage> with RouteAware {
  final noteManager = NoteManager();
  final FocusNode _searchfocus = FocusNode();
  List<Note> searchResults = [];

  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  RichText highlightText(
    String text,
    String query, {
    bool bold = false,
    double fontSize = 16,
    String fontFamily = "Petrona",
  }) {
    final baseStyle = TextStyle(
      color: Colors.white,
      fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
      fontSize: fontSize,
      fontFamily: fontFamily,
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

  @override
  void initState() {
    super.initState();
    //noteManager.migrateDatabaseAddCreatedAt(); // Uncomment if database is updated.....
    //noteManager.clearDB(); // uncommment if you want to nuke the database
    loadNotes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    loadNotes(); // ← called when returning back to this screen
  }

  String getPreviewText(String content, {int wordLimit = 15}) {
    final words = content.split(RegExp(r'\s+')); // Split by spaces
    if (words.length <= wordLimit) return "\n    -    $content";
    return '\n    -    ${words.take(wordLimit).join(' ')}...';
  }

  Future<void> resetSearch() async {
    final allNotes = await noteManager.getAllNotes();
    setState(() {
      searchQuery = '';
      searchResults = allNotes;
    });
  }

  Future<void> performSearch(String query) async {
    final results = await noteManager.searchNotes(
      query,
    ); // Await the search results
    setState(() {
      searchQuery = query;
      searchResults = results;
    });
  }

  void loadNotes() async {
    final notes = await noteManager.getAllNotes();
    setState(() {
      searchResults = notes;
    });
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
          resetSearch();
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
        floatingActionButton: Padding(
          padding: EdgeInsets.all(20),
          child: SpeedDial(
            icon: Icons.add,
            buttonSize: Size(55, 55),
            activeIcon: Icons.close,
            backgroundColor: Colors.amber,
            overlayColor: Color.fromRGBO(0, 0, 0, 0.1),
            childMargin: EdgeInsets.only(right: 2),
            spaceBetweenChildren: 10,
            children: [
              SpeedDialChild(
                backgroundColor: Color.fromRGBO(30, 30, 30, 1),
                labelBackgroundColor: Colors.transparent,
                child: Icon(Icons.note_add, color: Colors.amber),
                label: 'New Note',
                labelShadow: [],
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        NoteEditPage(noteManager: noteManager),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                  ),
                ),
              ),
              SpeedDialChild(
                backgroundColor: Color.fromRGBO(30, 30, 30, 1),
                labelBackgroundColor: Colors.transparent,
                labelShadow: [],
                child: Icon(Icons.folder_open, color: Colors.amber),
                label: 'Open Folder',
                onTap: () => print('Open Folder tapped'),
              ),
            ],
          ),
        ),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Color.fromARGB(255, 30, 30, 30),
          title: Text("Notes"),
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
                  performSearch(query);
                },
              ),

              const SizedBox(height: 10),

              // 📋 The list of filtered notes
              Expanded(
                child: searchQuery.isEmpty
                    ? FutureBuilder<List<Note>>(
                        future: noteManager
                            .getAllNotes(), // Fetch notes asynchronously
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            ); // Show loading spinner
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(
                                "No notes available.",
                                style: TextStyle(
                                  fontSize: 30,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }

                          final notes = snapshot.data!;
                          return ListView.builder(
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              final note = notes[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 4.0,
                                ),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  color: Color.fromRGBO(20, 20, 20, 1),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(note.title),
                                    subtitle: Text(
                                      getPreviewText(note.content),
                                    ),
                                    textColor: Colors.white,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) => NoteEditPage(
                                                noteManager: noteManager,
                                                id: note.id,
                                                title: note.title,
                                                content: note.content,
                                              ),
                                          transitionsBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                );
                                              },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
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
                                    horizontal: 0,
                                    vertical: 4.0,
                                  ),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    color: Color.fromRGBO(20, 20, 20, 1),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
                                        fontSize: 16,
                                      ),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          PageRouteBuilder(
                                            pageBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                ) => NoteEditPage(
                                                  noteManager: noteManager,
                                                  id: note.id,
                                                  title: note.title,
                                                  content: note.content,
                                                ),
                                            transitionsBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                  child,
                                                ) {
                                                  return FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  );
                                                },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            )),
              ), //Above this code
            ],
          ),
        ),
      ),
    );
  }
}
