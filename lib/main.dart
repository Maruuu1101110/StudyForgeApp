import 'package:flutter/material.dart';
import 'package:study_forge/pages/noteRelated/noteEditPage.dart';
import 'package:study_forge/pages/notesPage.dart';
import 'package:device_preview/device_preview.dart';
import 'algorithms/navigationObservers.dart';

void main() {
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
      home: ForgeNotesPage(),
    );
  }
}
