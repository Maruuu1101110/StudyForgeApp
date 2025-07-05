import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final NavigationSource source;
  const ForgeNotesPage({super.key, required this.source});

  @override
  State<ForgeNotesPage> createState() => _ForgeNotesState();
}

class _ForgeNotesState extends State<ForgeNotesPage>
    with RouteAware, TickerProviderStateMixin {
  final noteManager = NoteManager();
  List<Note> allNotes = [];
  List<Note> searchResults = [];
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  Set<String> selectedNoteIds = {};
  Set<String> selectedNotes = {};
  bool get isSelectionMode => selectedNotes.isNotEmpty;
  bool isSearchActive = false;

  // animation controllers for those smooth transitions
  late AnimationController _staggerController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    noteManager.ensureNoteTableExists();

    // setup stagger animation controller
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    loadNotes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _staggerController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => loadNotes();

  Future<void> loadNotes() async {
    final notes = await noteManager.getAllNotes();
    setState(() => searchResults = notes);

    // setup animations after notes load
    _initializeAnimations();

    // start the stagger animation
    _staggerController.reset();
    _staggerController.forward();
  }

  void _initializeAnimations() {
    final itemCount = searchResults.length;
    _slideAnimations = [];
    _fadeAnimations = [];

    for (int i = 0; i < itemCount; i++) {
      final double start = i * 0.08; // delay between cards
      final double end = start + 0.4; // how long each card takes to animate

      final slideAnimation =
          Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _staggerController,
              curve: Interval(
                start.clamp(0.0, 0.6),
                end.clamp(0.0, 1.0),
                curve: Curves.easeOutBack,
              ),
            ),
          );

      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            start.clamp(0.0, 0.6),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );

      _slideAnimations.add(slideAnimation);
      _fadeAnimations.add(fadeAnimation);
    }
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

    // reset animations for search results
    _initializeAnimations();
    _staggerController.reset();
    _staggerController.forward();
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
    return PopScope(
      canPop: widget.source == NavigationSource.homePage,
      onPopInvokedWithResult: (didPop, result) async {
        if (widget.source == NavigationSource.homePage) {
          return;
        }
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
        backgroundColor: const Color.fromRGBO(15, 15, 15, 1),
        floatingActionButton: FloatingSpeedDial(isNotes: true),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.amber.shade200,
                Colors.amber,
                Colors.orange.shade300,
              ],
            ).createShader(bounds),
            child: const Text(
              "Notes",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          titleSpacing: 0,
          leading: Builder(
            builder: (context) {
              return Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              );
            },
          ),
          actions: [
            if (isSelectionMode) ...[
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: AnimatedPopIcon(
                  child: IconButton(
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.amber,
                      size: 24,
                    ),
                    tooltip: 'Cancel selection',
                    onPressed: () {
                      setState(() {
                        selectedNotes.clear();
                      });
                    },
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: AnimatedPopIcon(
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 24,
                    ),
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

                        await loadNotes();
                        setState(() => selectedNotes.clear());

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            content: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade600,
                                    Colors.red.shade800,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: const Text(
                                'Notes deleted successfully!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
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

              // animations for this card
              if (index >= _slideAnimations.length ||
                  index >= _fadeAnimations.length) {
                return const SizedBox.shrink();
              }

              return SlideTransition(
                position: _slideAnimations[index],
                child: FadeTransition(
                  opacity: _fadeAnimations[index],
                  child: Padding(
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
                      onRefresh: () => loadNotes(),
                    ),
                  ),
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
