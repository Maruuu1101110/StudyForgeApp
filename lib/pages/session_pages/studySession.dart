import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:study_forge/components/sideBar.dart';
import 'package:study_forge/components/cards/roomsCard.dart';
import 'package:study_forge/components/speedDial.dart';
import 'package:study_forge/pages/room_pages/room_lobby_page.dart';
import 'package:study_forge/utils/navigationObservers.dart';
import 'package:study_forge/models/room_model.dart';
import 'package:study_forge/tables/room_table.dart';

class StudySessionPage extends StatefulWidget {
  final NavigationSource source;
  const StudySessionPage({super.key, required this.source});

  @override
  State<StudySessionPage> createState() => _StudySessionPageState();
}

class _StudySessionPageState extends State<StudySessionPage> with RouteAware {
  List<Room> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

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
  void didPopNext() => _loadRooms();

  Future<void> _loadRooms() async {
    try {
      final rooms = await RoomTableManager.getAllRooms();
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading rooms: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshRooms() async {
    await _loadRooms();
  }

  @override
  Widget build(BuildContext context) {
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
              "Study Sessions",
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
        ),
        drawer: ForgeDrawer(selectedTooltip: "Study Sessions"),
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 12),
                child: Text(
                  "Rooms",
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: Colors.amber.shade100,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.amber),
                      )
                    : _rooms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 64,
                              color: Colors.amber.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No Study Rooms Yet",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.amber.shade100,
                                fontFamily: "Petrona",
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Create your first room to get started!",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                                fontFamily: "Petrona",
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshRooms,
                        color: Colors.amber,
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black,
                                Colors.black,
                                Colors.black,
                              ],
                              stops: [0.0, 0.05, 0.5, 0.6],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: GridView.builder(
                            padding: const EdgeInsets.only(
                              top: 10,
                              left: 6,
                              right: 6,
                              bottom: 6,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio:
                                      0.7, // for card height/width ratio
                                ),
                            itemCount: _isLoading ? 0 : _rooms.length,
                            itemBuilder: (context, index) {
                              if (_isLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.amber,
                                  ),
                                );
                              }

                              if (_rooms.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final room = _rooms[index];
                              return RoomCard(
                                subject: room.subject,
                                isSelected: false,
                                subtitle: room.subtitle ?? "No subtitle",
                                status: room.status,
                                imagePath: room.imagePath,
                                roomColor: room.color,
                                roomId: room.id,
                                roomData: room,
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
                                onSelectToggle: (id) {
                                  debugPrint(
                                    'Room ${room.subject} selection toggled',
                                  );
                                },
                                onTap: () {
                                  debugPrint(
                                    'Room ${room.subject} tapped - entering study session',
                                  );
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) =>
                                          RoomLobbyPage(room: room),
                                      transitionsBuilder:
                                          (_, animation, __, child) =>
                                              FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              ),
                                    ),
                                  );
                                },
                                onRoomDeleted: () {
                                  _loadRooms();
                                },
                                onRoomUpdated: () {
                                  _loadRooms();
                                },
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingSpeedDial(isStudySessions: true),
      ),
    );
  }
}
