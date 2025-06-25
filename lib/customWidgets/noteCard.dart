import 'package:flutter/material.dart';
import 'package:study_forge/algorithms/noteSearchAlgo.dart';
import 'package:study_forge/pages/noteRelated/noteEditPage.dart';
import 'package:study_forge/customWidgets/bookmark.dart';

class NoteCard extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final bool isSelectionMode;
  final Function(String id)? onSelectToggle;

  const NoteCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onSelectToggle,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(widget.note.id),
      elevation: widget.isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: widget.isSelected
          ? const Color.fromRGBO(28, 28, 28, 1)
          : const Color.fromRGBO(20, 20, 20, 1),
      child: InkWell(
        onTap: handleTap,
        onLongPress: handleLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selection indicator + Title
                  Row(
                    children: [
                      widget.isSelected
                          ? const Icon(Icons.check_circle, color: Colors.amber)
                          : const SizedBox(width: 30),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.note.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.note.content.split(' ').take(10).join(' ')}...',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Top-right overlay for date and bookmark
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  Text(
                    "${widget.note.createdAt?.month ?? "?"}/${widget.note.createdAt?.day ?? "?"}",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  BookmarkIcon(
                    initialStatus: widget.note.isBookmarked,
                    onToggle: (newStatus) async {
                      await NoteManager().toggleBookmark(
                        widget.note.id,
                        newStatus,
                      );
                      setState(() {
                        widget.note.isBookmarked = newStatus;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void handleTap() {
    final bool isSelectionMode = widget.isSelectionMode;

    if (isSelectionMode) {
      widget.onSelectToggle!(widget.note.id); // toggle select
    } else {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => NoteEditPage(
            noteManager: NoteManager(),
            id: widget.note.id,
            title: widget.note.title,
            content: widget.note.content,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  void handleLongPress() {
    widget.onSelectToggle!(widget.note.id); // Just toggle selection
  }
}
