import 'package:flutter/material.dart';
import 'package:study_forge/pages/homePage.dart';
import 'package:study_forge/pages/notesPage.dart';
import 'package:device_preview/device_preview.dart';

void main() {
  runApp(DevicePreview(enabled: false, builder: (context) => StudyForge()));
}

class StudyForge extends StatelessWidget {
  const StudyForge({super.key});

  @override
  Widget build(BuildContext context) {
    Color mainColor = Color.fromRGBO(30, 30, 30, 1);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: mainColor,
        ),
      ),
      home: ForgeNotesPage(),
    );
  }
}
