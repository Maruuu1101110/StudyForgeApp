import 'dart:io';

import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'algorithms/navigationObservers.dart';
import 'package:study_forge/pages/homePage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // ✅ Desktop-specific: Use FFI for SQLite
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(DevicePreview(enabled: false, builder: (context) => StudyForge()));
}

class StudyForge extends StatelessWidget {
  const StudyForge({super.key});

  @override
  Widget build(BuildContext context) {
    Color mainColor = const Color.fromARGB(255, 30, 30, 30);
    return MaterialApp(
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
          fontFamily: "Petrona",
        ),
        scaffoldBackgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            fontFamily: "Petrona",
          ),
          backgroundColor: mainColor,
        ),
      ),
      home: ForgeHomePage(),
    );
  }
}
