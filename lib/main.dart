import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_forge/tables/note_table.dart';
import 'package:study_forge/tables/reminder_table.dart';
import 'package:study_forge/tables/room_table.dart';
import 'package:study_forge/tables/user_profile_table.dart';
import 'package:study_forge/pages/settingsPage.dart';
import 'package:study_forge/utils/ember_ai_service.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:study_forge/pages/ember_pages/chat_provider.dart';

// custom widgets

// components
import 'utils/navigationObservers.dart';
import 'package:study_forge/utils/notification_service.dart';
import 'package:study_forge/utils/file_manager_service.dart';

// pages
import 'package:study_forge/pages/homePage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Caught error: ${details.exception}');
  };
  // primary initialization
  WidgetsFlutterBinding.ensureInitialized();

  // sqlite for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // environment variables | configs
  await SettingsManager().database;
  await dotenv.load(fileName: "assets/.env");
  await EmberAIService().init();

  // timezone initialization
  tz.initializeTimeZones();

  // storage permissions
  await FileManagerService.instance.requestStoragePermissions();

  // database initialization
  await ReminderManager().ensureReminderTableExists();
  await ReminderManager().ensureNotificationExists();
  await NoteManager().ensureNoteTableExists();
  await RoomTableManager.ensureRoomTableExists();
  await UserProfileManager().ensureUserProfileTableExists();

  // notification service initialization
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      final notificationService = NotificationService();
      await notificationService.initNotif();
    }
  } catch (e) {
    debugPrint("Notification init failed: $e");
  }

  // main app run
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ChatProvider())],
      child: DevicePreview(
        enabled: !kReleaseMode && Platform.isLinux,
        //enabled: true,
        builder: (context) => StudyForge(),
      ),
    ),
  );
}

class StudyForge extends StatefulWidget {
  const StudyForge({super.key});

  @override
  State<StudyForge> createState() => _StudyForgeState();
}

class _StudyForgeState extends State<StudyForge> {
  @override
  Widget build(BuildContext context) {
    Color appBarColor = const Color.fromARGB(255, 15, 15, 15);
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      title: 'StudyForge',

      theme: ThemeData(
        primaryColorDark: appBarColor,
        useMaterial3: true,
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.transparent,
        ),

        textTheme: ThemeData.dark().textTheme.copyWith(
          bodyLarge: const TextStyle(
            color: Colors.white,
            fontFamily: "Petrona",
          ),
          bodyMedium: const TextStyle(
            color: Colors.white,
            fontFamily: "Petrona",
          ),
          bodySmall: const TextStyle(
            color: Colors.white70,
            fontFamily: "Petrona",
          ),
          titleLarge: const TextStyle(
            color: Colors.white,
            fontFamily: "Petrona",
          ),
          titleMedium: const TextStyle(
            color: Colors.white,
            fontFamily: "Petrona",
          ),
          labelLarge: const TextStyle(
            color: Colors.white,
            fontFamily: "Petrona",
          ),
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
