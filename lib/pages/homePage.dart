import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// database
import 'package:study_forge/models/note_model.dart';
import 'package:study_forge/models/reminder_model.dart';
import 'package:study_forge/models/user_profile_model.dart';
import 'package:study_forge/pages/ember_pages/ember_chat_provider.dart';
import 'package:study_forge/pages/session_pages/studySession.dart';
import 'package:study_forge/tables/note_table.dart';
import 'package:study_forge/tables/reminder_table.dart';

// custom widgets
import 'package:study_forge/components/sideBar.dart';
import 'package:study_forge/components/glowingLogo.dart';

// paths
import 'package:study_forge/pages/notesPage.dart';
import 'package:study_forge/pages/editor_pages/noteEditPage.dart';
import 'package:study_forge/pages/editor_pages/reminderEditPage.dart';

// utils
import 'package:study_forge/utils/navigationObservers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_forge/utils/gamification_service.dart';

import 'package:study_forge/themes/forge_colors.dart';

class ForgeHomePage extends StatefulWidget {
  const ForgeHomePage({super.key});

  @override
  State<ForgeHomePage> createState() => _ForgeHomeState();
}

class _ForgeHomeState extends State<ForgeHomePage>
    with RouteAware, TickerProviderStateMixin {
  final TextEditingController _controllerHome = TextEditingController();
  late final FocusNode _textFieldFocusNode;
  late final FocusNode _pageFocusNode;
  final noteManager = NoteManager();
  final reminderManager = ReminderManager();
  final gamificationService = GamificationService();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ember chat stuff
  bool _isTextValid = false;

  // user profile stuff for gamification bs
  UserProfile? userProfile;
  bool isLoadingProfile = true;
  static const int _maxMessageLength = 1000;

  @override
  void initState() {
    //UserProfileManager().clearUserProfile(); // for debugging
    super.initState();
    _checkFirstRun();
    loadPendingReminders();
    loadUserProfile();
    loadNotes();

    _controllerHome.addListener(_handleTextChanged);

    // setup animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _fadeController.forward();
    _slideController.forward();
    _textFieldFocusNode = FocusNode();
    _pageFocusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _textFieldFocusNode.dispose();
    _controllerHome.removeListener(_handleTextChanged);
    _pageFocusNode.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun') ?? true;

    if (isFirstRun) {
      await noteManager.ensureNoteTableExists();
      await reminderManager.ensureReminderTableExists();
      // create user profile db if it doesnt exist
      await gamificationService.getUserProfile();

      await prefs.setBool('isFirstRun', false);
    }
  }

  // grab user profile data
  void loadUserProfile() async {
    try {
      final profile = await gamificationService.getUserProfile();
      setState(() {
        userProfile = profile;
        isLoadingProfile = false;
      });
    } catch (e) {
      setState(() => isLoadingProfile = false);
    }
  }

  List<Reminder> pendingReminders = [];

  // load pending reminders in background
  void loadPendingReminders() async {
    final loadedReminders = await reminderManager.getPendingReminders();
    setState(() => pendingReminders = loadedReminders);
  }

  List<Reminder> reminders = [];

  // load all reminders in background
  void loadReminders() async {
    final loadedReminders = await reminderManager.getAllReminders();
    setState(() => reminders = loadedReminders);
  }

  List<Note> notes = [];

  // load notes in background
  void loadNotes() async {
    final loadedNotes = await noteManager.getAllNotes();
    setState(() => notes = loadedNotes);
  }

  void loadAllNotes() async {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            ForgeNotesPage(source: NavigationSource.homePage),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void loadStudySession() async {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            StudySessionPage(source: NavigationSource.homePage),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _sendMessage() {
    final quickText = _controllerHome.text.trim();
    _controllerHome.clear();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => EmberChatPage(quickMessage: quickText),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _handleTextChanged() {
    final isValid =
        _controllerHome.text.trim().isNotEmpty &&
        _controllerHome.text.length <= _maxMessageLength;

    if (isValid && !_isTextValid) {
      setState(() => _isTextValid = true);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() {});
      });
    } else if (!isValid && _isTextValid) {
      setState(() {});

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _isTextValid = false);
      });
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: ForgeColors.black,
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: ForgeColors.amber),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: ForgeColors.amber),
                ),
              ),
            ],
          ),
        ) ??
        false; // Handle null case
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        final shouldExit = await _showExitConfirmationDialog();
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: ForgeColors.scaffoldBackground,
        drawer: ForgeDrawer(selectedTooltip: "Home"),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Focus(
            focusNode: _pageFocusNode,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: ForgeColors.transparent,
                  scrolledUnderElevation: 0,
                  elevation: 0,
                  leading: Builder(
                    builder: (context) {
                      return Container(
                        child: IconButton(
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: ForgeColors.white,
                            size: 24,
                          ),
                          onPressed: () async {
                            _textFieldFocusNode.unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                            await Future.delayed(
                              const Duration(milliseconds: 50),
                            );
                            if (mounted) {
                              Scaffold.of(context).openDrawer();
                            }
                          },
                        ),
                      );
                    },
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            ForgeColors.silverGray.withValues(alpha: 0.15),
                            ForgeColors.attachedFileBg.withValues(alpha: 0.1),
                            ForgeColors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: GlowingLogo(),
                          ),
                          const SizedBox(height: 20),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  ForgeColors.amber200,
                                  ForgeColors.amber,
                                  ForgeColors.orange300,
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'Welcome to Study Forge',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w300,
                                  color: ForgeColors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildElegantContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElegantContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // some fancy divider thing
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ForgeColors.transparent,
                  ForgeColors.amber.withValues(alpha: 0.8),
                  ForgeColors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          _buildAIMessagePanel(),

          const SizedBox(height: 40),

          // quick action buttons grid
          _buildQuickActionsGrid(),

          const SizedBox(height: 40),

          // reminder preview
          _buildUpcomingRemindersSection(pendingReminders),

          const SizedBox(height: 40),

          // user stats cards
          _buildStatsCards(),

          const SizedBox(height: 40),

          // achievements section
          if (userProfile != null && userProfile!.badges.isNotEmpty) ...[
            _buildBadgesSection(),
            const SizedBox(height: 40),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAIMessagePanel() {
    final isMessageValid =
        _controllerHome.text.trim().isNotEmpty &&
        _controllerHome.text.length <= _maxMessageLength;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _controllerHome.text.length > _maxMessageLength
                      ? ForgeColors.errorBorder.withValues(alpha: 0.5)
                      : ForgeColors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controllerHome,
                focusNode: _textFieldFocusNode,
                autofocus: false,
                style: const TextStyle(color: ForgeColors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Ask Ember something...',
                  hintStyle: TextStyle(
                    color: ForgeColors.white.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                onChanged: (_) => setState(() {}),
                minLines: 1,
                maxLines: 2,
                maxLength: null,
              ),
            ),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isMessageValid ? 28 : 0,
            height: 48,
            curve: Curves.easeInOut,
            child: Visibility(
              visible: isMessageValid,
              child: IconButton(
                onPressed: _sendMessage,
                tooltip: "Send message",
                icon: Icon(
                  Icons.send_rounded,
                  color: ForgeColors.amber,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actionCardGradient = [
      const Color.fromARGB(255, 54, 54, 54).withValues(alpha: 0.15),
      ForgeColors.black.withValues(alpha: 0.1),
      ForgeColors.transparent,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: ForgeColors.amber100,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.note_add_outlined,
                  title: 'New Note',
                  subtitle: 'Got something?',
                  gradient: actionCardGradient,
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => NoteEditPage(
                          noteManager: NoteManager(),
                          isMD: false,
                        ),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    );

                    // if note was created update gamification stuff
                    if (result == true) {
                      await _onNoteCreated();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.schedule_outlined,
                  title: 'Set Reminder',
                  subtitle: 'Heads up',
                  gradient: actionCardGradient,
                  onTap: () => Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          ReminderEditPage(reminderManager: ReminderManager()),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.book_outlined,
                  title: 'Study Session',
                  subtitle: 'Start studying',
                  gradient: actionCardGradient,
                  onTap: loadStudySession,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.note_alt_outlined,
                  title: 'Load Notes',
                  subtitle: 'Access your notes',
                  gradient: actionCardGradient,
                  onTap: () => _loadNotesWithStyle(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ForgeColors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ForgeColors.orange500, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: ForgeColors.orange200,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: ForgeColors.amber200.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: ForgeColors.amber100,
                  letterSpacing: 0.5,
                ),
              ),
              if (userProfile != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ForgeColors.amber600, ForgeColors.orange600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: ForgeColors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${userProfile!.level}',
                        style: const TextStyle(
                          color: ForgeColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoadingProfile)
            const Center(
              child: CircularProgressIndicator(color: ForgeColors.amber),
            )
          else if (userProfile != null) ...[
            // level progress bar
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ForgeColors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ForgeColors.amber.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        gamificationService.getLevelTitle(userProfile!.level),
                        style: TextStyle(
                          color: ForgeColors.amber100,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${userProfile!.experienceToNextLevel} XP to next level',
                        style: TextStyle(
                          color: ForgeColors.amber300,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: userProfile!.levelProgress,
                      backgroundColor: ForgeColors.amber.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ForgeColors.amber,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            // stats row with numbers and shit
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Study Streak',
                    '${userProfile!.studyStreak} days',
                    Icons.local_fire_department_outlined,
                    ForgeColors.orange,
                    subtitle: gamificationService.getStreakMessage(
                      userProfile!.studyStreak,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Current XP',
                    '${userProfile!.experiencePoints}',
                    Icons.stars_outlined,
                    ForgeColors.amber,
                    subtitle:
                        '${userProfile!.experienceToNextLevel} to next level',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Notes Created',
                    '${userProfile!.notesCreated}',
                    Icons.description_outlined,
                    ForgeColors.deepOrange,
                    subtitle: '${notes.length} current',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tasks Done',
                    '${userProfile!.remindersCompleted}',
                    Icons.check_circle_outline,
                    ForgeColors.green,
                    subtitle: '${pendingReminders.length} pending',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Badges',
                    '${userProfile!.badges.length}',
                    Icons.military_tech_outlined,
                    ForgeColors.purple,
                    subtitle: 'Achievements',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Sessions',
                    '${userProfile!.totalStudySessions}',
                    Icons.timeline_outlined,
                    ForgeColors.blue,
                    subtitle: 'Study Sessions',
                  ),
                ),
              ],
            ),
          ] else
            Center(
              child: Text(
                'Unable to load progress data',
                style: TextStyle(color: ForgeColors.amber300),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: ForgeColors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: ForgeColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: ForgeColors.white.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderPreview(List<Reminder> reminders) {
    if (reminders.isEmpty) {
      return const Text(
        "No reminders in the next 2 days.",
        style: TextStyle(color: Colors.white54),
      );
    }

    return Column(
      children: reminders.map((reminder) {
        final time = DateFormat('hh:mm a').format(reminder.dueDate);
        final isToday = DateTime.now().day == reminder.dueDate.day;
        final isTomorrow =
            DateTime.now().add(const Duration(days: 1)).day ==
            reminder.dueDate.day;

        String label;
        if (isToday) {
          label = 'Today';
        } else if (isTomorrow) {
          label = 'Tomorrow';
        } else {
          label = DateFormat('EEEE').format(reminder.dueDate);
        }

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: Icon(
            Icons.access_time,
            color: isToday ? ForgeColors.amber : ForgeColors.orange,
          ),
          title: Text(
            reminder.title,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          subtitle: Text(
            "$label · $time",
            style: const TextStyle(color: Colors.white70),
          ),
        );
      }).toList(),
    );
  }

  List<Reminder> _filterUpcomingReminders(List<Reminder> allReminders) {
    final today = DateTime.now();
    final twoDaysFromNow = today.add(Duration(days: 2));
    final end = DateTime(
      twoDaysFromNow.year,
      twoDaysFromNow.month,
      twoDaysFromNow.day,
      23,
      59,
    );

    return allReminders.where((reminder) {
      final time = reminder.dueDate;
      return time.isAfter(today) && time.isBefore(end);
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Widget _buildUpcomingRemindersSection(List<Reminder> allReminders) {
    final upcoming = _filterUpcomingReminders(allReminders);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Reminders',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: ForgeColors.amber100,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: ForgeColors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ForgeColors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: _buildReminderPreview(upcoming),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Achievements',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: ForgeColors.amber100,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ForgeColors.purple600, ForgeColors.pink600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${userProfile!.badges.length} earned',
                  style: const TextStyle(
                    color: ForgeColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: ForgeColors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ForgeColors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: userProfile!.badges
                    .map((badge) => _buildBadgeChip(badge))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _loadNotesWithStyle() async {
    loadAllNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ForgeColors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ForgeColors.amber600, ForgeColors.orange700],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Notes loaded successfully!',
            style: TextStyle(
              color: ForgeColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // gamification methods...
  Future<void> _onNoteCreated() async {
    final oldProfile = userProfile;
    final newProfile = await gamificationService.recordNoteCreated();

    setState(() => userProfile = newProfile);

    // reload notes to get updated count
    loadNotes();

    // check for level up or badges with delays so snackbars dont overlap
    if (oldProfile != null) {
      await _showGamificationNotifications(oldProfile, newProfile, 10);
    }
  }

  Future<void> _showGamificationNotifications(
    UserProfile oldProfile,
    UserProfile newProfile,
    int baseXP,
  ) async {
    int delay = 0;

    if (GamificationService.didLevelUp(oldProfile, newProfile)) {
      Future.delayed(Duration(milliseconds: delay), () {
        _showLevelUpCelebration(newProfile.level);
      });
      delay += 500;
    }

    // then show badge if they got one
    if (GamificationService.didEarnBadge(oldProfile, newProfile)) {
      Future.delayed(Duration(milliseconds: delay), () {
        _showBadgeEarned(newProfile.badges.last);
      });
      delay += 500;
    }

    // finally show xp gained if no level up happened
    if (!GamificationService.didLevelUp(oldProfile, newProfile)) {
      Future.delayed(Duration(milliseconds: delay), () {
        _showXPGained(baseXP);
      });
    }
  }

  void _showLevelUpCelebration(int newLevel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ForgeColors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ForgeColors.purple600, ForgeColors.pink600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.celebration, color: ForgeColors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LEVEL UP! 🎉',
                      style: TextStyle(
                        color: ForgeColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'You reached Level $newLevel!',
                      style: TextStyle(color: ForgeColors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeEarned(String badge) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ForgeColors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ForgeColors.orange600, ForgeColors.amber600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.military_tech, color: ForgeColors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BADGE EARNED! 🏆',
                      style: TextStyle(
                        color: ForgeColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      badge,
                      style: TextStyle(color: ForgeColors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showXPGained(int xp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ForgeColors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ForgeColors.amber600, ForgeColors.orange700],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars, color: ForgeColors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '+$xp XP',
                style: TextStyle(
                  color: ForgeColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeChip(String badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ForgeColors.amber600.withValues(alpha: 0.3),
            ForgeColors.orange600.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ForgeColors.amber.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech, color: ForgeColors.amber300, size: 16),
          const SizedBox(width: 6),
          Text(
            badge,
            style: TextStyle(
              color: ForgeColors.amber100,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
