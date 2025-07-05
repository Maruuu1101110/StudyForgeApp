import 'package:flutter/material.dart';
import 'package:study_forge/models/note_model.dart';
import 'package:study_forge/tables/note_table.dart';
import 'package:study_forge/components/animatedPopIcon.dart';
import 'package:study_forge/pages/editor_pages/markdownEditPage.dart';
import 'package:study_forge/pages/editor_pages/noteEditPage.dart';
import 'package:study_forge/components/bookmark.dart';

class NoteCard extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final bool isSelectionMode;
  final Function(String id)? onSelectToggle;
  final VoidCallback? onRefresh;

  const NoteCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onSelectToggle,
    this.onRefresh,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      key: ValueKey(widget.note.id),
      elevation: widget.isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.amber.withValues(alpha: 0.5),
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
              padding: const EdgeInsets.only(
                top: 30,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selection indicator + Title
                  SizedBox(height: 10),
                  Row(
                    children: [
                      widget.isSelected
                          ? const AnimatedPopIcon(
                              duration: Duration(milliseconds: 1000),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.amber,
                              ),
                            )
                          : const SizedBox(width: 0),
                      const SizedBox(width: 8),

                      // Expanded(
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 200),
                        child: Text(
                          widget.note.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    widget.note.content,
                    maxLines:
                        3, // Approximate height control: # of lines visible
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
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
                  Visibility(
                    visible: widget.note.isMarkDown,
                    child: Text(
                      "MD",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                      widget.onRefresh?.call();
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
        widget.note.isMarkDown
            ? PageRouteBuilder(
                pageBuilder: (_, __, ___) => MarkDownEditPage(
                  noteManager: NoteManager(),
                  id: widget.note.id,
                  title: widget.note.title,
                  content: widget.note.content,
                  isMD: widget.note.isMarkDown,
                ),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              )
            : PageRouteBuilder(
                pageBuilder: (_, __, ___) => NoteEditPage(
                  noteManager: NoteManager(),
                  id: widget.note.id,
                  title: widget.note.title,
                  content: widget.note.content,
                  isMD: widget.note.isMarkDown,
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
