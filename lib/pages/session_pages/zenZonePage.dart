// This page is just temporary , it might change later along witht he study session approach

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:study_forge/models/room_model.dart';

class ZenZonePage extends StatefulWidget {
  final Room room;

  const ZenZonePage({super.key, required this.room});

  @override
  State<ZenZonePage> createState() => _ZenZonePageState();
}

class _ZenZonePageState extends State<ZenZonePage>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _seconds = 0;
  int _minutes = 25;
  bool _isRunning = false;
  bool _isPaused = false;

  TimerMode _currentMode = TimerMode.focus;

  // animations
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  // session trackingg (tempate for now)
  int _totalFocusTime = 0; // in seconds
  int _totalShortBreakTime = 0; // in seconds
  int _totalLongBreakTime = 0; // in seconds
  int _focusSessionsCompleted = 0;
  int _shortBreakSessionsCompleted = 0;
  int _longBreakSessionsCompleted = 0;
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _resetTimer();
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

  // TODO : change to use the rooms info soon
  void _resetTimer() {
    setState(() {
      switch (_currentMode) {
        case TimerMode.focus:
          _minutes = 25;
          _seconds = 0;
          break;
        case TimerMode.shortBreak:
          _minutes = 5;
          _seconds = 0;
          break;
        case TimerMode.longBreak:
          _minutes = 15;
          _seconds = 0;
          break;
      }
    });
  }

  void _startTimer() {
    if (!_isRunning) {
      _sessionStartTime = DateTime.now();
      setState(() {
        _isRunning = true;
        _isPaused = false;
      });

      _rotationController.repeat();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else if (_minutes > 0) {
            _minutes--;
            _seconds = 59;
          } else {
            _onTimerComplete();
          }
        });
      });
    }
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
      _rotationController.repeat();
      setState(() {
        _isPaused = false;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else if (_minutes > 0) {
            _minutes--;
            _seconds = 59;
          } else {
            _onTimerComplete();
          }
        });
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _rotationController.stop();
    _rotationController.reset();

    if (_sessionStartTime != null) {
      final elapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
      switch (_currentMode) {
        case TimerMode.focus:
          _totalFocusTime += elapsed;
          break;
        case TimerMode.shortBreak:
          _totalShortBreakTime += elapsed;
          break;
        case TimerMode.longBreak:
          _totalLongBreakTime += elapsed;
          break;
      }
    }

    setState(() {
      _isRunning = false;
      _isPaused = false;
    });
    _resetTimer();
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _rotationController.stop();
    _rotationController.reset();

    switch (_currentMode) {
      case TimerMode.focus:
        _focusSessionsCompleted++;
        _totalFocusTime += 25 * 60; // 25 minutes in seconds
        break;
      case TimerMode.shortBreak:
        _shortBreakSessionsCompleted++;
        _totalShortBreakTime += 5 * 60; // 5 minutes in seconds
        break;
      case TimerMode.longBreak:
        _longBreakSessionsCompleted++;
        _totalLongBreakTime += 15 * 60; // 15 minutes in seconds
        break;
    }

    HapticFeedback.heavyImpact();

    _showSessionCompletedDialog();

    setState(() {
      _isRunning = false;
      _isPaused = false;
    });

    _suggestNextMode();
  }

  void _suggestNextMode() {
    TimerMode nextMode;
    if (_currentMode == TimerMode.focus) {
      if (_focusSessionsCompleted % 4 == 0) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Focus Sessions:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$_focusSessionsCompleted',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Focus Time:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${(_totalFocusTime / 60).floor()}m',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Break Time:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${((_totalShortBreakTime + _totalLongBreakTime) / 60).floor()}m',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
              _resetTimer();
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

  Widget _buildTimerDisplay() {
    final roomColor = _getRoomColor();

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
                        value: _isRunning
                            ? 1.0 -
                                  ((_minutes * 60 + _seconds) /
                                      _getTotalSeconds())
                            : 0.0,
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
                            '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
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

  int _getTotalSeconds() {
    switch (_currentMode) {
      case TimerMode.focus:
        return 25 * 60;
      case TimerMode.shortBreak:
        return 5 * 60;
      case TimerMode.longBreak:
        return 15 * 60;
    }
  }

  int _getTotalSessionsCompleted() {
    return _focusSessionsCompleted +
        _shortBreakSessionsCompleted +
        _longBreakSessionsCompleted;
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

  Widget _buildModeButton(Color roomColor) {
    return PopupMenuButton<TimerMode>(
      onSelected: (mode) {
        if (!_isRunning || _isPaused) {
          setState(() {
            _currentMode = mode;
          });
          _resetTimer();

          if (_isPaused) {
            _timer?.cancel();
            _rotationController.stop();
            _rotationController.reset();
            setState(() {
              _isRunning = false;
              _isPaused = false;
            });
          }
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
              Text('Focus (25m)', style: TextStyle(color: Colors.white)),
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
              ? roomColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: (!_isRunning || _isPaused)
                ? roomColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Icon(
          _getModeIcon(_currentMode),
          color: (!_isRunning || _isPaused)
              ? roomColor
              : Colors.white.withOpacity(0.3),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent],
        ),
      ),
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
              '${_getTotalSessionsCompleted()} sessions',
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

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Colors.white.withOpacity(0.7),
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
      body: Column(
        children: [
          _buildRoomHeader(),
          const SizedBox(height: 40),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimerDisplay(),
                const SizedBox(height: 60),
                _buildControlButtons(),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
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
                  '${_getTotalSessionsCompleted()}',
                  Icons.check_circle,
                ),
                _buildStatCard(
                  'Breaks',
                  '${(_totalShortBreakTime + _totalLongBreakTime) ~/ 60}m',
                  Icons.coffee,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    final roomColor = _getRoomColor();

    return Container(
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
}

enum TimerMode { focus, shortBreak, longBreak }
