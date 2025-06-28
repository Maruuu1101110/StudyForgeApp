import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// custom widgets

// algorithms
import 'utils/navigationObservers.dart';

// pages
import 'package:study_forge/pages/homePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // ✅ Desktop-specific: Use FFI for SQLite
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
