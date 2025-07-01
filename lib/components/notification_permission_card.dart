import 'package:flutter/material.dart';

// Notification permission card reverted to placeholder.
class NotificationPermissionCard extends StatelessWidget {
  const NotificationPermissionCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Color.fromARGB(255, 30, 30, 30),
      child: ListTile(
        leading: Icon(Icons.notifications, color: Colors.amber),
        title: Text(
          'Notification Permission',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Notification permission UI goes here.',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
