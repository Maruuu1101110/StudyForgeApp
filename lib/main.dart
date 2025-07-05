import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_forge/tables/note_table.dart';
import 'package:study_forge/tables/reminder_table.dart';
import 'package:study_forge/tables/room_table.dart';
import 'package:study_forge/tables/user_profile_table.dart';
import 'package:timezone/data/latest.dart' as tz;

// custom widgets

// components
import 'utils/navigationObservers.dart';
import 'package:study_forge/utils/notification_service.dart';

// pages
import 'package:study_forge/pages/homePage.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>(); // for notification OnTap navigation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  ReminderManager().ensureReminderTableExists();
  NoteManager().ensureNoteTableExists();
  RoomTableManager.ensureRoomTableExists();
  UserProfileManager().ensureUserProfileTableExists();

  final notificationService = NotificationService();
  await notificationService.initNotif();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    DevicePreview(
      enabled: !kReleaseMode ? Platform.isLinux : false,
      builder: (context) => StudyForge(),
    ),
  );
}

class StudyForge extends StatelessWidget {
  const StudyForge({super.key});

  @override
  Widget build(BuildContext context) {
    Color appBarColor = const Color.fromARGB(255, 15, 15, 15);
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColorDark: appBarColor,
        useMaterial3: true,
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.transparent,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
          fontFamily: "Petrona",
        ),
        scaffoldBackgroundColor: appBarColor,
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            fontFamily: "Petrona",
          ),
          backgroundColor: appBarColor,
        ),
      ),
      home: ForgeHomePage(),
    );
  }
}
