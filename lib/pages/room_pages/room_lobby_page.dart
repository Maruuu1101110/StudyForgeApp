import 'dart:io';
import 'package:flutter/material.dart';
import 'package:study_forge/models/room_model.dart';
import 'package:study_forge/pages/room_pages/quizRoomPage.dart';
import 'package:study_forge/pages/room_pages/zenZonePage.dart';
import 'package:study_forge/utils/file_manager_service.dart';
import 'package:study_forge/utils/navigationObservers.dart';
import 'package:study_forge/pages/room_pages/room_files_page.dart';

class RoomLobbyPage extends StatefulWidget {
  final Room room;

  const RoomLobbyPage({super.key, required this.room});

  @override
  State<RoomLobbyPage> createState() => _RoomLobbyPageState();
}

class _RoomLobbyPageState extends State<RoomLobbyPage>
    with RouteAware, TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<FileSystemEntity> files = [];
  List<FileSystemEntity> quizSets = [];
  List<FileSystemEntity> flashCards = [];

  Map<String, dynamic>? roomMetadata;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadRoomData();
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
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => _loadRoomData();

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  void _loadRoomData() async {
    if (widget.room.id != null) {
      final metadata = await FileManagerService.instance.getRoomMetadata(
        widget.room.id!,
      );
      final files = await FileManagerService.instance.getRoomFiles(
        widget.room.id!,
      );
      final quizSets = await FileManagerService.instance.getRoomQuizzes(
        widget.room.id!,
      );
      final flashCards = await FileManagerService.instance.getRoomFlashCards(
        widget.room.id!,
      );
      setState(() {
        this.files = files;
        this.quizSets = quizSets;
        this.flashCards = flashCards;
        roomMetadata = metadata;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _getRoomThemeColor() {
    if (widget.room.color != null) {
      try {
        return Color(
          int.parse(widget.room.color!.substring(1), radix: 16) + 0xFF000000,
        );
      } catch (e) {
        return Colors.amber;
      }
    }
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getRoomThemeColor();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(15, 15, 15, 1),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            leading: Container(
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
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
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
                    Icons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    // TODO: Room settings
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      themeColor.withValues(alpha: 0.3),
                      themeColor.withValues(alpha: 0.15),
                      Colors.grey.shade800.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildRoomIcon(),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            themeColor.withValues(alpha: 0.9),
                            themeColor,
                            themeColor.withValues(alpha: 0.7),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          widget.room.subject,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (widget.room.subtitle?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          widget.room.subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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
    );
  }

  Widget _buildRoomIcon() {
    final themeColor = _getRoomThemeColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            themeColor.withValues(alpha: 0.3),
            themeColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Icon(Icons.school, size: 40, color: themeColor),
    );
  }

  Widget _buildElegantContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _getRoomThemeColor().withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          _buildRoomActionsGrid(),

          const SizedBox(height: 30),

          _buildStatsCards(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRoomActionsGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room Sections',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: _getRoomThemeColor().withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.folder_open_outlined,
                  title: 'Files & Resources',
                  subtitle: '${files.length} files',
                  gradient: [
                    const Color.fromARGB(
                      255,
                      54,
                      54,
                      54,
                    ).withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  onTap: () => _navigateToFiles(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.quiz_outlined,
                  title: 'Quizzes & Practice',
                  subtitle: '${quizSets.length + flashCards.length} quizzes',
                  gradient: [
                    const Color.fromARGB(
                      255,
                      54,
                      54,
                      54,
                    ).withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  onTap: () => _navigateToQuizzes(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.self_improvement_outlined,
                  title: 'Study Zone',
                  subtitle: 'Focus & Timer',
                  gradient: [
                    const Color.fromARGB(
                      255,
                      54,
                      54,
                      54,
                    ).withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  onTap: () => _navigateToStudyZone(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.trending_up_outlined,
                  title: 'Progress',
                  subtitle: 'Track your journey',
                  gradient: [
                    const Color.fromARGB(
                      255,
                      54,
                      54,
                      54,
                    ).withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  onTap: () => _navigateToProgress(),
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
    final themeColor = _getRoomThemeColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
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
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: themeColor, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: themeColor.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _getRoomThemeColor().withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
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
    final themeColor = _getRoomThemeColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room Overview',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: themeColor.withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.amber))
          else if (roomMetadata != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Study Sessions',
                    '${widget.room.totalSessions}',
                    Icons.access_time_outlined,
                    themeColor,
                    subtitle: 'Total completed',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Files Stored',
                    '${files.length}',
                    Icons.folder_outlined,
                    themeColor,
                    subtitle: 'Ready to access',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Quizzes Created',
                    '${quizSets.length + flashCards.length}',
                    Icons.quiz_outlined,
                    themeColor,
                    subtitle: 'Practice available',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Last Activity',
                    _formatLastActivity(),
                    Icons.schedule_outlined,
                    themeColor,
                    subtitle: 'Keep the momentum',
                  ),
                ),
              ],
            ),
          ],
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
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatLastActivity() {
    if (roomMetadata?['lastActivity'] != null) {
      final lastActivity = DateTime.tryParse(roomMetadata!['lastActivity']);
      if (lastActivity != null) {
        final difference = DateTime.now().difference(lastActivity);
        if (difference.inDays > 0) {
          return '${difference.inDays}d ago';
        } else if (difference.inHours > 0) {
          return '${difference.inHours}h ago';
        } else {
          return '${difference.inMinutes}m ago';
        }
      }
    }
    return 'Never';
  }

  void _navigateToFiles() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => RoomFilesPage(room: widget.room),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _navigateToQuizzes() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => QuizRoomPage(room: widget.room),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _navigateToStudyZone() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ZenZonePage(room: widget.room),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _navigateToProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(
          255,
          37,
          37,
          37,
        ).withValues(alpha: 0.8),
        title: Text('🚧 Under Construction'),
        content: Text(
          'The Progress Page is currently under development. Check back soon!',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber,
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
