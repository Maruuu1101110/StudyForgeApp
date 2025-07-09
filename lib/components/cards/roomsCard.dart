// This is cards for rooms which are gonna be used for the study sessions

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:study_forge/tables/room_table.dart';
import 'package:study_forge/models/room_model.dart';
import 'package:study_forge/pages/editor_pages/roomEditPage.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class RoomCard extends StatefulWidget {
  final bool isSelected; // if the room is selected
  final Function(String id) onSelectToggle; // callback for selection toggle
  final IconData icon; // icon for the room // change this later for photo
  final String subject; // subject for the room
  final String subtitle; // subtitle for the room
  final String status; // status of the room
  final List<Color> gradient; // gradient colors for the card
  final VoidCallback onTap; // function to call when the room is tapped
  final String? imagePath; // path to the room image
  final String? roomColor; // hex color string for the room theme
  final int? roomId; // room ID for database operations
  final Function()? onRoomDeleted; // callback when room is deleted
  final Function()? onRoomUpdated; // callback when room is updated
  final Room? roomData; // complete room data for editing

  const RoomCard({
    super.key,
    required this.subject,
    required this.isSelected,
    required this.onSelectToggle,
    this.icon = Icons.room,
    required this.status,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.imagePath, // optional image path
    this.roomColor, // optional room color
    this.roomId, // optional room ID
    this.onRoomDeleted, // optional deletion callback
    this.onRoomUpdated, // optional update callback
    this.roomData, // optional complete room data
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  Color _getStatusColor() {
    switch (widget.status.toLowerCase()) {
      case 'ongoing':
      case 'active':
        return Colors.green.shade400;
      case 'completed':
        return Colors.blue.shade400;
      case 'archived':
        return Colors.grey.shade400;
      case 'paused':
        return Colors.orange.shade400;
      default:
        return Colors.amber.shade400;
    }
  }

  Color _getRoomColor() {
    if (widget.roomColor == null) return Colors.white.withValues(alpha: 0.2);
    try {
      return Color(
        int.parse(widget.roomColor!.substring(1), radix: 16) + 0xFF000000,
      );
    } catch (e) {
      return Colors.white.withValues(alpha: 0.2);
    }
  }

  Widget _buildRoomImage() {
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      if (widget.imagePath!.startsWith('/')) {
        return Image.file(
          File(widget.imagePath!),
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon();
          },
        );
      } else {
        return Image.asset(
          widget.imagePath!,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon();
          },
        );
      }
    }

    // fallback if no image provided
    return _buildFallbackIcon();
  }

  // default image
  Widget _buildFallbackIcon() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 54, 54, 54).withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/sf_logo_nobg.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // another fallback if default fails to load
            return Icon(Icons.room, size: 32, color: Colors.orange.shade500);
          },
        ),
      ),
    );
  }

  // ROOM DELETION
  void _deleteRoom() async {
    if (widget.roomId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot delete room: ID not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // confirmation dialog before deleting
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text('Delete Room', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete "${widget.subject}"? This action cannot be undone.',
            style: TextStyle(color: Colors.grey.shade300),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        // loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Deleting room...'),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );

        // delete from db
        int result = await RoomTableManager.deleteRoom(widget.roomId!);

        if (mounted) {
          if (result > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Room "${widget.subject}" deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );

            // refresh ui after deletion
            if (widget.onRoomDeleted != null) {
              widget.onRoomDeleted!();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete room: No rows affected'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting room: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // CHANGE ROOM COLOR
  void _changeColor() async {
    if (widget.roomId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot change color: Room ID not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // fetch the current | selected room color
    Color currentColor = _getRoomColor();
    Color newColor = currentColor;

    // color picker
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            'Change Room Color',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Theme(
              data: Theme.of(context).copyWith(
                cardTheme: CardThemeData(color: Colors.grey.shade800),
                tabBarTheme: TabBarThemeData(
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(color: Colors.orange.shade400),
                  ),
                ),
                textTheme: TextTheme(
                  bodyMedium: TextStyle(color: Colors.white),
                  bodySmall: TextStyle(color: Colors.black),
                ),
              ),
              child: ColorPicker(
                pickerColor: currentColor,
                onColorChanged: (Color color) {
                  newColor = color;
                },
                enableAlpha: false,
                displayThumbColor: true,
                pickerAreaHeightPercent: 0.8,
                paletteType: PaletteType.hueWheel,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Apply', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        // loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Updating color...'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(milliseconds: 1500),
          ),
        );

        // color to hex string converter
        String hexColor =
            '#${newColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

        // get current room color and upadte
        Room? currentRoom = widget.roomData;
        if (currentRoom == null) {
          currentRoom = await RoomTableManager.getRoomById(widget.roomId!);
          if (currentRoom == null) {
            throw Exception('Room not found');
          }
        }

        // create updated room with new color
        Room updatedRoom = Room(
          id: currentRoom.id,
          subject: currentRoom.subject,
          subtitle: currentRoom.subtitle,
          status: currentRoom.status,
          imagePath: currentRoom.imagePath,
          color: hexColor, // Updated color
          createdAt: currentRoom.createdAt,
          lastAccessedAt: currentRoom.lastAccessedAt,
          totalSessions: currentRoom.totalSessions,
          totalStudyTime: currentRoom.totalStudyTime,
          goals: currentRoom.goals,
          isFavorite: currentRoom.isFavorite,
          description: currentRoom.description,
        );

        // update room in database
        int result = await RoomTableManager.updateRoom(updatedRoom);

        if (mounted) {
          if (result > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Room color updated successfully'),
                backgroundColor: Colors.green,
              ),
            );

            // refresh ui after color change
            if (widget.onRoomUpdated != null) {
              widget.onRoomUpdated!();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update room color'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating color: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // EDIT ROOM
  void _editRoom() async {
    if (widget.roomId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot edit room: ID not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      Room? roomToEdit = widget.roomData;

      if (roomToEdit == null) {
        final rooms = await RoomTableManager.getAllRooms();
        roomToEdit = rooms.firstWhere(
          (room) => room.id == widget.roomId,
          orElse: () => throw Exception('Room not found'),
        );
      }

      if (mounted) {
        final result = await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => RoomEditPage(
              roomTableManager: RoomTableManager(),
              existingRoom: roomToEdit,
            ),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );

        // refresh ui if updated room
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Room "${widget.subject}" updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          if (widget.onRoomUpdated != null) {
            widget.onRoomUpdated!();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening edit page: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.gradient,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isPressed
                            ? Colors.amber.withValues(alpha: 0.4)
                            : _getRoomColor().withValues(alpha: 0.3),
                        width: _isPressed ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // subject image
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _buildRoomImage(),
                              ),
                            ),
                          ),
                        ),

                        // text section
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  widget.subject,
                                  style: TextStyle(
                                    color: Colors.orange.shade200,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  height: 1,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        _getRoomColor(),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    color: Colors.amber.shade200.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor().withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getStatusColor().withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    widget.status,
                                    style: TextStyle(
                                      color: _getStatusColor(),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: PopupMenuButton<String>(
                        color: Colors.black.withValues(alpha: 0.8),
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 18,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'deleteRoom':
                              _deleteRoom();
                              break;
                            case 'changeColor':
                              _changeColor();
                              break;
                            case 'editRoom':
                              _editRoom();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'deleteRoom',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete Room',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'changeColor',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.palette_outlined,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Change Color',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'editRoom',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Edit Room',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
