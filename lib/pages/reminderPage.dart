import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:study_forge/utils/navigationObservers.dart';
import 'package:study_forge/components/sideBar.dart';
import 'package:study_forge/components/speedDial.dart';
import 'package:study_forge/components/animatedPopIcon.dart';
import 'package:study_forge/components/cards/reminderCard.dart';
import 'package:study_forge/tables/reminder_table.dart';
import 'package:study_forge/models/reminder_model.dart';

class ForgeReminderPage extends StatefulWidget {
  const ForgeReminderPage({super.key});

  @override
  State<ForgeReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ForgeReminderPage> with RouteAware {
  final reminderManager = ReminderManager();
  List<Reminder> allReminders = [];
  bool isLoading = true;
  Set<String> selectedCards = {};
  bool get isSelectionMode => selectedCards.isNotEmpty;

  // Calendar state
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  late CalendarFormat _calendarFormat = CalendarFormat.month;

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
  void didPopNext() => loadReminders();

  @override
  void initState() {
    super.initState();
    reminderManager.ensureReminderTableExists();
    loadReminders();
  }

  Future<void> loadReminders() async {
    setState(() => isLoading = true);
    final allReminders = await reminderManager.getAllReminders();
    setState(() => this.allReminders = allReminders);
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text("Reminders"),
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
                    selectedCards.clear();
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
                  tooltip: "Delete Selected Reminders?",

                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
                        title: const Text("Delete Selected Reminder?"),
                        content: Text(
                          "Are you sure you want to delete ${selectedCards.length} reminder(s)?",
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
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      for (var id in selectedCards) {
                        await reminderManager.deleteReminder(id);
                      }

                      await loadReminders();
                      setState(() => selectedCards.clear());

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Reminder deleted")),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
      drawer: ForgeDrawer(selectedTooltip: "Reminders"),
      body: Column(
        children: [
          // Static Calendar (stays in place)
          Padding(
            padding: const EdgeInsets.all(10),
            child: TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: true,
                formatButtonShowsNext: false,
                formatButtonTextStyle: TextStyle(color: Colors.amber),
                formatButtonDecoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              calendarStyle: CalendarStyle(
                todayTextStyle: const TextStyle(color: Colors.black),
                selectedTextStyle: const TextStyle(color: Colors.black),
                todayDecoration: BoxDecoration(
                  color: const Color.fromARGB(123, 255, 224, 130),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(color: Colors.white70),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white),
                weekendStyle: TextStyle(color: Colors.white70),
              ),
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
          ),

          const SizedBox(height: 10),
          const Text(
            "Schedules",
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),

          // Scrollable list of reminders
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: allReminders.length,
              itemBuilder: (context, index) {
                final reminder = allReminders[index];
                final isSelected = selectedCards.contains(reminder.id);

                return Padding(
                  key: ValueKey(reminder.id),
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: ReminderCard(
                    reminder: reminder,
                    isSelected: isSelected,
                    isSelectionMode: isSelectionMode,
                    onSelectToggle: (id) {
                      setState(() {
                        if (selectedCards.contains(id)) {
                          selectedCards.remove(id);
                        } else {
                          selectedCards.add(id);
                        }
                      });
                    },
                    onRefresh: loadReminders, // Refresh after status change
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingSpeedDial(isReminders: true),
    );
  }
}
