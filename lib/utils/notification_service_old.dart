import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:study_forge/pages/reminderPage.dart';
import 'package:study_forge/main.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// btw from dev Maruuu1101110
// I made this with just reading the docs and some trial and error and also with the help of AI...
//! Heres some guide: https://pub.dev/documentation/flutter_local_notifications/latest/
// so when sht goes down, goodlck

class NotificationService {
  // initialize the notification plugin,
  //request permissions,
  //and set up the notification channel,
  //CHECK THE MAIN IF ITS THERE CAUSE THIS IS IMPOTANT AF
  Future<void> initNotif() async {
    tz.initializeTimeZones();
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    try {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      } else {
        debugPrint("AndroidFlutterLocalNotificationsPlugin not available");
      }
    } catch (e, stackTrace) {
      debugPrint("Error requesting notification permission: $e");
      debugPrint("Stack trace: $stackTrace");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/notification_icon');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String? title,
    required String? body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel_id',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title ?? '⏰ Reminder',
      body ?? 'You have a reminder due.',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      //  uiLocalNotificationDateInterpretation:
      //      UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'study_forge',
    );
  }

  /* this is still a WIP sooo might go back to this later...
  static Future<void> scheduleOnRepeatDays({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    DateTime? repeatInterval,
    String? payload,
  }) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel_id',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
  }
*/
  void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
    navigatorKey.currentState?.push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ForgeReminderPage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ); // gonna update this when notifs are accessed by other features too
  }

  static Future<void> cancelNotification(int notificationId) async {
    try {
      await FlutterLocalNotificationsPlugin().cancel(notificationId);
      debugPrint('Cancelled notification with ID: $notificationId');
    } catch (e) {
      debugPrint('Error cancelling notification $notificationId: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await FlutterLocalNotificationsPlugin().cancelAll();
      debugPrint('Cancelled all notifications');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  static Future<bool> canScheduleExactAlarms() async {
    // dunno why this is even here tbh
    // theres no button to trigger immediately notifs sooo..
    return false;
  }
}
