import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// utils
import 'package:flutter/services.dart';
import 'package:study_forge/utils/navigationObservers.dart';

// components
import 'package:study_forge/components/sideBar.dart';
import 'package:study_forge/components/speedDial.dart';
import 'package:study_forge/components/animatedPopIcon.dart';
import 'package:study_forge/components/cards/reminderCard.dart';

// reminder core
import 'package:study_forge/tables/reminder_table.dart';
import 'package:study_forge/models/reminder_model.dart';

class ForgeReminderPage extends StatefulWidget {
  final NavigationSource source;
  const ForgeReminderPage({super.key, required this.source});

  @override
  State<ForgeReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ForgeReminderPage>
    with RouteAware, TickerProviderStateMixin {
  final reminderManager = ReminderManager();
  List<Reminder> allReminders = [];
  bool isLoading = true;
  Set<String> selectedCards = {};
  bool get isSelectionMode => selectedCards.isNotEmpty;

  // Animation controllers
  late AnimationController _staggerController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  // Calendar state
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  late CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<Reminder>> _events = {};

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
  void didPopNext() {
    loadReminders();
  }

  @override
  void initState() {
    super.initState();
    reminderManager.ensureReminderTableExists();

    // initialize stagger animation controller
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    loadReminders();
  }

  void _initializeAnimations() {
    final itemCount = allReminders.length;
    _slideAnimations = [];
    _fadeAnimations = [];

    for (int i = 0; i < itemCount; i++) {
      final double start = i * 0.1; // Stagger delay
      final double end = start + 0.4; // Animation duration per item

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

  Future<void> loadReminders() async {
    setState(() => isLoading = true);
    final allReminders = await reminderManager.getAllReminders();

    setState(() {
      this.allReminders = allReminders;
      _groupRemindersByDate(); // group *after* setting new reminders
      isLoading = false;
    });

    // Initialize animations after reminders are loaded
    _initializeAnimations();

    // Start the stagger animation
    _staggerController.reset();
    _staggerController.forward();
  }

  void _groupRemindersByDate() {
    _events.clear();
    for (var reminder in allReminders) {
      final day = DateTime(
        reminder.dueDate.year,
        reminder.dueDate.month,
        reminder.dueDate.day,
      );
      if (_events[day] == null) {
        _events[day] = [reminder];
      } else {
        _events[day]!.add(reminder);
      }
    }
  }

  Widget _buildEventsMarker(int count) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter reminders for the selected calendar day
    final filteredReminders = allReminders.where((reminder) {
      final scheduledDate = reminder.dueDate;
      return scheduledDate.year == _selectedDay.year &&
          scheduledDate.month == _selectedDay.month &&
          scheduledDate.day == _selectedDay.day;
    }).toList();

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
              "Reminders",
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
                        selectedCards.clear();
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
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
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
                                'Reminders deleted successfully!',
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
                eventLoader: (day) {
                  return _events[DateTime(day.year, day.month, day.day)] ?? [];
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 4,
                        child: _buildEventsMarker(events.length),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Elegant divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.amber.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              "Schedules",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: Colors.amber.shade100,
                letterSpacing: 0.5,
              ),
            ),

            // Scrollable list of reminders
            filteredReminders.isEmpty
                ? _buildEmptyState()
                : Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: filteredReminders.length,
                      itemBuilder: (context, index) {
                        final reminder = filteredReminders[index];
                        final isSelected = selectedCards.contains(reminder.id);

                        // Ensure we have animations for this index
                        if (index >= _slideAnimations.length ||
                            index >= _fadeAnimations.length) {
                          return const SizedBox.shrink();
                        }

                        return SlideTransition(
                          position: _slideAnimations[index],
                          child: FadeTransition(
                            opacity: _fadeAnimations[index],
                            child: Padding(
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
                                onRefresh:
                                    loadReminders, // Refresh after status change
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),

        floatingActionButton: FloatingSpeedDial(isReminders: true),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No reminders scheduled for this day.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to schedule one.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
