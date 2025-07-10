import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:study_forge/models/room_model.dart';
import 'package:study_forge/tables/room_table.dart';
import 'package:study_forge/utils/navigationObservers.dart';
import 'package:study_forge/pages/room_pages/room_files_page.dart';
import 'package:study_forge/utils/file_manager_service.dart';

class ZenZonePage extends StatefulWidget {
  final Room room;

  const ZenZonePage({super.key, required this.room});

  @override
  State<ZenZonePage> createState() => _ZenZonePageState();
}

class _ZenZonePageState extends State<ZenZonePage>
    with RouteAware, TickerProviderStateMixin {
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _canLeave = true;

  TimerMode _currentMode = TimerMode.focus;

  DateTime? _endTime;

  // Store timer state for each mode
  final Map<TimerMode, int> _modeMinutes = {
    TimerMode.focus: 25,
    TimerMode.shortBreak: 5,
    TimerMode.longBreak: 15,
  };
  final Map<TimerMode, int> _modeSeconds = {
    TimerMode.focus: 0,
    TimerMode.shortBreak: 0,
    TimerMode.longBreak: 0,
  };

  // animations
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  // session tracking (template for now)
  int _totalFocusTime = 0; // in seconds
  int _totalShortBreakTime = 0; // in seconds
  int _totalLongBreakTime = 0; // in seconds
  late int _totalSessions;
  int _remainingTimeInSeconds = 0;

  RoomTableManager roomManager = RoomTableManager();

  List<FileSystemEntity> _roomFiles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _resetTimer();
    _totalSessions = widget.room.totalSessions;
    _loadRoomFiles();
  }

  void _loadRoomFiles() async {
    if (widget.room.id != null) {
      try {
        final files = await FileManagerService.instance.getRoomFiles(
          widget.room.id!,
        );
        setState(() {
          _roomFiles = files;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading files: $e')));
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() => _resetTimer();

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rotationController);

    _pulseController.repeat(reverse: true);
  }

  void _resetTimer({int? min, int? sec}) {
    setState(() {
      _canLeave = true;
      // Only reset the current mode's minutes/seconds
      _modeMinutes[_currentMode] = min ?? _defaultMinutes(_currentMode);
      _modeSeconds[_currentMode] = sec ?? 0;
      _timer?.cancel();
      _rotationController.reset();
      _isRunning = false;
      _isPaused = false;
      _endTime = null;
    });
  }

  // Helper to get default minutes by mode
  int _defaultMinutes(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return 25;
      case TimerMode.shortBreak:
        return 5;
      case TimerMode.longBreak:
        return 15;
    }
  }

  void _incrementLiveTimer(TimerMode mode) {
    setState(() {
      switch (mode) {
        case TimerMode.focus:
          _totalFocusTime++;
          break;
        case TimerMode.shortBreak:
          _totalShortBreakTime++;
          break;
        case TimerMode.longBreak:
          _totalLongBreakTime++;
          break;
      }
    });
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _canLeave = false;
      _isRunning = true;
      _isPaused = false;
    });

    final totalSeconds =
        (_modeMinutes[_currentMode] ?? _defaultMinutes(_currentMode)) * 60 +
        (_modeSeconds[_currentMode] ?? 0);

    _sessionTotalSeconds = totalSeconds;

    _endTime = DateTime.now().add(Duration(seconds: totalSeconds));
    _rotationController.repeat();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = _endTime!.difference(now);
      final remainingSecs = remaining.inSeconds;
      if (remainingSecs > 0) {
        setState(() {
          _remainingTimeInSeconds = remainingSecs;
          _modeMinutes[_currentMode] = remaining.inMinutes;
          _modeSeconds[_currentMode] = remaining.inSeconds % 60;
          _incrementLiveTimer(_currentMode);
        });
      } else {
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    if (_isRunning && !_isPaused) {
      _timer?.cancel();
      _rotationController.stop();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _resumeTimer() {
    if (_isRunning && _isPaused) {
      setState(() => _isPaused = false);
      final totalSeconds =
          (_modeMinutes[_currentMode] ?? _defaultMinutes(_currentMode)) * 60 +
          (_modeSeconds[_currentMode] ?? 0);

      _sessionTotalSeconds = totalSeconds;

      _endTime = DateTime.now().add(Duration(seconds: totalSeconds));
      _rotationController.repeat();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final remaining = _endTime!.difference(now);
        final remainingSecs = remaining.inSeconds;
        if (remainingSecs > 0) {
          setState(() {
            _remainingTimeInSeconds = remainingSecs;
            _modeMinutes[_currentMode] = remaining.inMinutes;
            _modeSeconds[_currentMode] = remaining.inSeconds % 60;
            _incrementLiveTimer(_currentMode);
          });
        } else {
          _onTimerComplete();
        }
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _rotationController.stop();
    _rotationController.reset();

    setState(() {
      _isRunning = false;
      _isPaused = false;
      _canLeave = true;
    });
    _resetTimer();
  }

  void _onTimerComplete() async {
    _timer?.cancel();
    _rotationController.stop();
    _rotationController.reset();

    setState(() {
      _isRunning = false;
      _isPaused = false;
      _canLeave = true;
    });

    // update session count
    if (_currentMode == TimerMode.focus) {
      _totalSessions++;
      await roomManager.updateTotalSessions(widget.room.id!, _totalSessions);
    }

    final totalMinutes = _totalFocusTime ~/ 60;
    await roomManager.updateStudyTime(widget.room.id!, totalMinutes);

    HapticFeedback.heavyImpact();

    _showSessionCompletedDialog();
    _suggestNextMode();
  }

  void _suggestNextMode() {
    TimerMode nextMode;
    if (_currentMode == TimerMode.focus) {
      if (widget.room.totalSessions % 4 == 0) {
        nextMode = TimerMode.longBreak;
      } else {
        nextMode = TimerMode.shortBreak;
      }
    } else {
      nextMode = TimerMode.focus;
    }
    _showModeChangeDialog(nextMode);
  }

  void _showSessionCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Text(
              'Session Complete!',
              style: TextStyle(
                color: Colors.amber,
                fontFamily: 'Petrona',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Great work! You\'ve completed a ${_getModeName(_currentMode).toLowerCase()} session.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontFamily: 'Petrona',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _buildSessionStatRow(
                    'Focus Sessions:',
                    '${widget.room.totalSessions}',
                    Colors.amber,
                  ),
                  const SizedBox(height: 4),
                  _buildSessionStatRow(
                    'Focus Time:',
                    '${(_totalFocusTime / 60).floor()}m',
                    Colors.amber,
                  ),
                  const SizedBox(height: 4),
                  _buildSessionStatRow(
                    'Break Time:',
                    '${((_totalShortBreakTime + _totalLongBreakTime) / 60).floor()}m',
                    Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Continue', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showModeChangeDialog(TimerMode suggestedMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ready for ${_getModeName(suggestedMode)}?',
          style: TextStyle(
            color: Colors.amber,
            fontFamily: 'Petrona',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Would you like to start a ${_getModeName(suggestedMode).toLowerCase()} session?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontFamily: 'Petrona',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Later',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentMode = suggestedMode;
              });
              // don't reset timer, just update UI
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: Text(
              'Start ${_getModeName(suggestedMode)}',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _getModeName(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return 'Focus Session';
      case TimerMode.shortBreak:
        return 'Short Break';
      case TimerMode.longBreak:
        return 'Long Break';
    }
  }

  Color _getRoomColor() {
    if (widget.room.color != null) {
      try {
        return Color(int.parse(widget.room.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.amber;
      }
    }
    return Colors.amber;
  }

  int _sessionTotalSeconds = 0; // used for progress bar

  Widget _buildTimerDisplay() {
    final roomColor = _getRoomColor();
    final minutes = _modeMinutes[_currentMode] ?? _defaultMinutes(_currentMode);
    final seconds = _modeSeconds[_currentMode] ?? 0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isRunning && !_isPaused ? _pulseAnimation.value : 1.0,
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      roomColor.withValues(alpha: 0.1),
                      roomColor.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: roomColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Progress indicator
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: _sessionTotalSeconds > 0
                            ? 1.0 -
                                  (_remainingTimeInSeconds /
                                      _sessionTotalSeconds)
                            : 1.0,
                        strokeWidth: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(roomColor),
                      ),
                    ),
                    // Timer text
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              fontFamily: 'JBM',
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getModeName(_currentMode),
                            style: TextStyle(
                              fontSize: 16,
                              color: roomColor,
                              fontFamily: 'Petrona',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildControlButtons() {
    final roomColor = _getRoomColor();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildModeButton(roomColor), // mode selection

        GestureDetector(
          onTap: () {
            if (!_isRunning) {
              _startTimer();
            } else if (_isPaused) {
              _resumeTimer();
            } else {
              _pauseTimer();
            }
          },
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [roomColor, roomColor.withValues(alpha: 0.8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: roomColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              !_isRunning
                  ? Icons.play_arrow
                  : _isPaused
                  ? Icons.play_arrow
                  : Icons.pause,
              color: Colors.black,
              size: 30,
            ),
          ),
        ),

        // stop button
        GestureDetector(
          onTap: _isRunning ? _stopTimer : null,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRunning
                  ? Colors.red.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: _isRunning
                    ? Colors.red.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              Icons.stop,
              color: _isRunning
                  ? Colors.red
                  : Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetTimerButton() {
    final roomColor = _getRoomColor();
    return Visibility(
      visible: _canLeave ? true : false,
      child: ElevatedButton.icon(
        icon: Icon(Icons.timer, color: roomColor),
        label: Text(
          'Set Timer',
          style: TextStyle(fontWeight: FontWeight.w600, color: roomColor),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF121212),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: roomColor),
          ),
        ),
        onPressed: () async {
          final result = await showDialog<Map<String, int>>(
            context: context,
            builder: (context) {
              int _customMinutes =
                  _modeMinutes[_currentMode] ?? _defaultMinutes(_currentMode);
              int _customSeconds = _modeSeconds[_currentMode] ?? 0;
              return AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Set Custom Timer',
                  style: TextStyle(color: Colors.amber, fontFamily: 'Petrona'),
                ),
                content: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Minutes',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            child: TextFormField(
                              initialValue: '$_customMinutes',
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: Colors.amber),
                              decoration: InputDecoration(
                                border: UnderlineInputBorder(),
                                hintText: 'Minutes',
                              ),
                              onChanged: (val) {
                                final numVal = int.tryParse(val) ?? 0;
                                _customMinutes = numVal.clamp(0, 59);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Seconds',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            child: TextFormField(
                              initialValue: '$_customSeconds',
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: Colors.amber),
                              decoration: InputDecoration(
                                border: UnderlineInputBorder(),
                                hintText: 'Seconds',
                              ),
                              onChanged: (val) {
                                final numVal = int.tryParse(val) ?? 0;
                                _customSeconds = numVal.clamp(0, 59);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.amber),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'minutes': _customMinutes,
                        'seconds': _customSeconds,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Set',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              );
            },
          );
          if (result != null) {
            setState(() {
              // Only update the current mode's timer
              _modeMinutes[_currentMode] = result['minutes']!;
              _modeSeconds[_currentMode] = result['seconds']!;
            });
          }
        },
      ),
    );
  }

  Widget _buildModeButton(Color roomColor) {
    return PopupMenuButton<TimerMode>(
      onSelected: (mode) {
        if (!_isRunning || _isPaused) {
          setState(() {
            _currentMode = mode;
          });
          // Do NOT reset timer here, preserve minutes/seconds per mode
        }
      },
      enabled: !_isRunning || _isPaused,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: TimerMode.focus,
          child: Row(
            children: [
              Icon(Icons.psychology, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text('Focus', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: TimerMode.shortBreak,
          child: Row(
            children: [
              Icon(Icons.coffee, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text('Short Break (5m)', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: TimerMode.longBreak,
          child: Row(
            children: [
              Icon(Icons.spa, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text('Long Break (15m)', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      color: const Color(0xFF2A2A2A),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (!_isRunning || _isPaused)
              ? roomColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: (!_isRunning || _isPaused)
                ? roomColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          _getModeIcon(_currentMode),
          color: (!_isRunning || _isPaused)
              ? roomColor
              : Colors.white.withValues(alpha: 0.3),
          size: 20,
        ),
      ),
    );
  }

  IconData _getModeIcon(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return Icons.psychology;
      case TimerMode.shortBreak:
        return Icons.coffee;
      case TimerMode.longBreak:
        return Icons.spa;
    }
  }

  Widget _buildRoomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Row(
        children: [
          // Room image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getRoomColor().withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child:
                  widget.room.imagePath != null &&
                      widget.room.imagePath!.isNotEmpty
                  ? (widget.room.imagePath!.startsWith('assets/')
                        ? Image.asset(
                            widget.room.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/sf_logo_nobg.png',
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.file(
                            File(widget.room.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/sf_logo_nobg.png',
                                fit: BoxFit.cover,
                              );
                            },
                          ))
                  : Image.asset('assets/sf_logo_nobg.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),

          // Room info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.room.subject,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Petrona',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.room.subtitle ?? 'Focus Session',
                  style: TextStyle(
                    fontSize: 14,
                    color: _getRoomColor(),
                    fontFamily: 'Petrona',
                  ),
                ),
              ],
            ),
          ),

          // Session stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getRoomColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getRoomColor().withValues(alpha: 0.3)),
            ),
            child: Text(
              '${_totalSessions} sessions',
              style: TextStyle(
                fontSize: 12,
                color: _getRoomColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    final roomColor = _getRoomColor();

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roomColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: roomColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'JBM',
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
              fontFamily: 'Petrona',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomEndDrawer() {
    return Drawer(
      backgroundColor: const Color.fromRGBO(25, 25, 25, 1),
      child: SafeArea(
        child: ViewOnlyFileListView(
          files: _roomFiles,
          themeColor: _getRoomColor(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _canLeave
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : Padding(
                padding: EdgeInsetsGeometry.only(left: 15),
                child: Icon(Icons.timer, size: 30, color: _getRoomColor()),
              ),

        title: Text(
          'Zen Zone',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Petrona',
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Zen Zone Guide',
                    style: TextStyle(
                      color: Colors.amber,
                      fontFamily: 'Petrona',
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🧘 Focus Session: 25 minutes of deep work\n'
                        '☕ Short Break: 5 minutes to recharge\n'
                        '🌿 Long Break: 15 minutes for deep rest\n\n'
                        'Based on the Pomodoro Technique for maximum productivity.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: 'Petrona',
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Got it',
                        style: TextStyle(color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      endDrawer: _buildRoomEndDrawer(),
      body: Expanded(
        child: Column(
          children: [
            _buildRoomHeader(),
            const SizedBox(height: 40),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimerDisplay(),
                  const SizedBox(height: 20),
                  _buildSetTimerButton(),
                  const SizedBox(height: 40),
                  _buildControlButtons(),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Total Focus',
                    '${(_totalFocusTime / 60).floor()}m',
                    Icons.timer,
                  ),
                  _buildStatCard(
                    'Sessions',
                    '${_totalSessions}',
                    Icons.check_circle,
                  ),
                  _buildStatCard(
                    'Breaks',
                    '${((_totalShortBreakTime + _totalLongBreakTime) ~/ 60)}m',
                    Icons.coffee,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TimerMode { focus, shortBreak, longBreak }
