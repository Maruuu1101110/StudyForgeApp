import 'package:flutter/material.dart';

// custom widgets
import '../components/sideBar.dart';
import '../components/cards/noteCard.dart';
import '../components/speedDial.dart';
import 'package:study_forge/components/animatedPopIcon.dart';

// database
import 'package:study_forge/models/note_model.dart';
import 'package:study_forge/tables/note_table.dart';
import 'package:study_forge/utils/navigationObservers.dart';

// pages

class ForgeNotesPage extends StatefulWidget {
  const ForgeNotesPage({super.key});

  @override
  State<ForgeNotesPage> createState() => _ForgeNotesState();
}

class _ForgeNotesState extends State<ForgeNotesPage> with RouteAware {
  final noteManager = NoteManager();
  List<Note> allNotes = [];
  List<Note> searchResults = [];
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  Set<String> selectedNoteIds = {};
  Set<String> selectedNotes = {};
  bool get isSelectionMode => selectedNotes.isNotEmpty;
  bool isSearchActive = false;

  @override
  void initState() {
    super.initState();
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
  void didPopNext() => loadNotes();

  Future<void> loadNotes() async {
    final notes = await noteManager.getAllNotes();
    setState(() => searchResults = notes);
  }

  Future<void> resetSearch() async {
    final allNotes = await noteManager.getAllNotes();
    setState(() {
      searchQuery = '';
      searchResults = allNotes;
    });
  }

  void loadAllNotes() async {
    final notes = await NoteManager().getAllNotes();
    setState(() => allNotes = notes);
  }

  void openSearch() {
    setState(() => isSearchActive = true);
  }

  void closeSearch() {
    setState(() => isSearchActive = false);
  }

  Future<void> performSearch(String query) async {
    final results = await noteManager.searchNotes(query);
    setState(() {
      searchQuery = query;
      searchResults = results;
    });
  }

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
        floatingActionButton: FloatingSpeedDial(isNotes: true),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: const Text("Notes"),
          titleSpacing: 0,
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
          actions: [
            if (isSelectionMode) ...[
              AnimatedPopIcon(
                child: IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.amber, size: 30),
                  tooltip: 'Cancel selection',
                  onPressed: () {
                    setState(() {
                      selectedNotes
                          .clear(); // 🔁 This should rebuild the screen
                    });
                  },
                ),
              ),

              Padding(
                padding: EdgeInsets.only(right: 10),
                child: AnimatedPopIcon(
                  child: IconButton(
                    iconSize: 30,
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    tooltip: "Delete Selected Notes?",

                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
                          title: const Text("Delete Selected Notes?"),
                          content: Text(
                            "Are you sure you want to delete ${selectedNotes.length} note(s)?",
                            style: TextStyle(fontSize: 16),
                          ),
                          actions: [
                            TextButton(
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(false),
                            ),
                            TextButton(
                              child: const Text(
                                "Delete",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: () => Navigator.of(
                                ctx,
                              ).pop(true), // ✅ just pop true here
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        for (var id in selectedNotes) {
                          await noteManager.deleteNote(id);
                        }

                        await loadNotes(); // ✅ now it refreshes after deletion
                        setState(
                          () => selectedNotes.clear(),
                        ); // 🧼 clear selection

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Notes deleted")),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
        drawer: ForgeDrawer(selectedTooltip: "Notes"),

        body: Padding(
          padding: EdgeInsetsGeometry.all(10),
          child: ListView.builder(
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final note = searchResults[index];
              // final isSelected = selectedNotes.contains(note.id);

              return Padding(
                key: ValueKey(note.id),
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 4.0,
                ),
                child: NoteCard(
                  note: note,
                  isSelected: selectedNotes.contains(note.id),
                  isSelectionMode: selectedNotes.isNotEmpty,
                  onSelectToggle: (id) {
                    setState(() {
                      selectedNotes.contains(id)
                          ? selectedNotes.remove(id)
                          : selectedNotes.add(id);
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String getPreviewText(String content, {int wordLimit = 15}) {
    final words = content.split(RegExp(r'\s+'));
    return words.take(wordLimit).join(' ') +
        (words.length > wordLimit ? '...' : '');
  }
}
