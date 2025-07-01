import 'package:flutter/material.dart';
import 'package:study_forge/models/note_model.dart';

class FloatingSearchOverlay extends StatefulWidget {
  final List<Note> allNotes;
  final VoidCallback onClose;

  const FloatingSearchOverlay({
    super.key,
    required this.allNotes,
    required this.onClose,
  });

  @override
  State<FloatingSearchOverlay> createState() => _FloatingSearchOverlayState();
}

class _FloatingSearchOverlayState extends State<FloatingSearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  List<Note> _results = [];

  void _onSearchChanged(String query) {
    setState(() {
      _results = widget.allNotes
          .where(
            (note) =>
                note.title.toLowerCase().contains(query.toLowerCase()) ||
                note.content.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Dismiss when tapped outside
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),

            // Floating search bar
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: const Color.fromRGBO(30, 30, 30, 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    cursorColor: Colors.amber,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search notes...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.amber),
                    ),
                  ),
                ),
              ),
            ),

            // Floating results list
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              bottom: 40,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: const Color.fromRGBO(20, 20, 20, 1),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context).size.height *
                        0.6, // limit height to 60% of screen
                  ),
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final note = _results[index];
                      return ListTile(
                        title: Text(
                          note.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "${note.content.split(" ").take(10).join(" ")}...",
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () {
                          // handle tap
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
