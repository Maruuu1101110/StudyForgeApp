import 'package:flutter/material.dart';
import 'package:study_forge/models/reminder_model.dart';
import 'package:study_forge/components/animatedPopIcon.dart';
import 'package:study_forge/components/pinned.dart';
import 'package:intl/intl.dart';
import 'package:study_forge/pages/editor_pages/reminderEditPage.dart';
import 'package:study_forge/tables/reminder_table.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final bool isSelected;
  final bool isSelectionMode;
  final Function(String id)? onSelectToggle;
  final VoidCallback? onRefresh;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onSelectToggle,
    this.onRefresh,
  });

  String getFormattedDate(DateTime date) {
    return DateFormat('MMM dd, yyyy – hh:mm a').format(date);
  }

  String getTimeRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (reminder.isCompleted && dueDate.isBefore(now)) {
      return 'Completed';
    }
    if (difference.isNegative) {
      return 'Overdue by ${difference.abs().inHours}h';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins left';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hrs left';
    }
    return '${difference.inDays} days left';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(reminder.id),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isSelected
          ? const Color.fromRGBO(28, 28, 28, 1)
          : const Color.fromRGBO(20, 20, 20, 1),
      child: InkWell(
        onTap: () {
          if (isSelectionMode) {
            onSelectToggle?.call(reminder.id);
          } else {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => ReminderEditPage(
                  reminderManager: ReminderManager(),
                  existingReminder: reminder,
                ),

                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            );
          }
        },

        onLongPress: () {
          onSelectToggle?.call(reminder.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //  Header Row (title + pin + selected)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isSelected)
                    const AnimatedPopIcon(
                      duration: Duration(milliseconds: 1000),
                      child: Icon(Icons.check_circle, color: Colors.amber),
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: reminder.isCompleted
                            ? Colors.green
                            : reminder.dueDate.isBefore(DateTime.now())
                            ? Colors.red
                            : Colors.white70,
                      ),
                    ),
                  ),

                  // Completion checkbox
                  GestureDetector(
                    onTap: reminder.isCompleted
                        ? null
                        : () async {
                            await ReminderManager().markAsCompleted(
                              reminder.id,
                              true,
                            );
                            onRefresh?.call();
                          },
                    child: Icon(
                      reminder.isCompleted
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: reminder.isCompleted ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Pin icon if reminder is pinned
                  PinnedIcon(
                    initialStatus: reminder.isPinned,
                    onToggle: (newStatus) async {
                      await ReminderManager().togglePinned(
                        reminder.id,
                        newStatus,
                      );
                      onRefresh?.call();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Due date and Time remaining
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.white54),
                  const SizedBox(width: 6),
                  Text(
                    getFormattedDate(reminder.dueDate),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.timer, size: 16, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    getTimeRemaining(reminder.dueDate),
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                reminder.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
