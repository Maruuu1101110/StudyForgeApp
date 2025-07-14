import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:study_forge/utils/navigationObservers.dart';
import 'package:study_forge/pages/reminderPage.dart';
import 'package:study_forge/main.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// btw from dev Maruuu1101110
// I made this with just reading the docs and some trial and error and also with the help of AI...
//! Heres some guide: https://pub.dev/documentation/flutter_local_notifications/latest/
// so when sht goes down, God may help us both

class NotificationService {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // initialize the notification plugin,
  //request permissions,
  //and set up the notification channel,
  //CHECK THE MAIN IF ITS THERE CAUSE THIS IS IMPOTANT AF

  Future<void> initNotif() async {
    tz.initializeTimeZones();

    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
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
        AndroidInitializationSettings('@drawable/notification_logo');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
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
    try {
      const androidDetails = AndroidNotificationDetails(
        'reminder_channel_id',
        'Reminders',
        channelDescription: 'Reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      // time date zone convertion for version compatibility
      final scheduledTZDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // Debug logging
      debugPrint("Scheduling notification:");
      debugPrint("  ID: $id");
      debugPrint("  Title: $title");
      debugPrint("  Body: $body");
      debugPrint("  Scheduled for: $scheduledTZDateTime");
      debugPrint("  Current time: ${tz.TZDateTime.now(tz.local)}");

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title ?? '⏰ Reminder',
        body ?? 'You have a reminder due.',
        scheduledTZDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload ?? 'study_forge',
      );

      await scheduleRemindersUntilDue(
        baseId: id + 100,
        title: "⏰ Daily 8AM Reminder",
        body: title != null
            ? "Don’t forget: $title\n$body"
            : body ?? "You’ve got something to check this morning!",
        dueDate: scheduledTime,
        payload: payload,
      );

      scheduleDueTomorrowNotification(
        id: id + 200,
        title: "📌 Due Soon: ${title ?? 'Untitled Task'}",
        body: body != null
            ? "Heads up — due tomorrow! 📅\n$body"
            : "Don't forget to prepare!",

        dueDate: scheduledTime,
        payload: payload,
      );

      debugPrint("Notification scheduled successfully");
    } catch (e, stackTrace) {
      debugPrint("Error scheduling notification: $e");
      debugPrint("Stack trace: $stackTrace");
      rethrow;
    }
  }

  void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
    navigatorKey.currentState?.push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            ForgeReminderPage(source: NavigationSource.direct),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  static Future<void> cancelNotification(int notificationId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      await _flutterLocalNotificationsPlugin.cancel(notificationId + 100);
      await _flutterLocalNotificationsPlugin.cancel(notificationId + 200);
      debugPrint('Cancelled notification with ID: $notificationId');
    } catch (e) {
      debugPrint('Error cancelling notification $notificationId: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('Cancelled all notifications');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  // this is for debugging purposes
  static Future<void> debugPendingNotifications() async {
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      debugPrint("Pending notifications: ${pendingNotifications.length}");
      for (final notification in pendingNotifications) {
        debugPrint("  ID: ${notification.id}, Title: ${notification.title}");
      }
    } catch (e) {
      debugPrint("Error getting pending notifications: $e");
    }
  }
}

Future<void> scheduleRemindersUntilDue({
  required int baseId,
  required String? title,
  required String? body,
  required DateTime dueDate,
  String? payload,
}) async {
  final now = DateTime.now();
  DateTime currentDay = DateTime(now.year, now.month, now.day, 8);

  if (now.isAfter(currentDay)) {
    currentDay = currentDay.add(const Duration(days: 1));
  }

  int count = 0;
  while (currentDay.isBefore(dueDate)) {
    await NotificationService._flutterLocalNotificationsPlugin.zonedSchedule(
      baseId + count,
      title ?? '📅 Daily Reminder',
      body ?? 'Reminder for upcoming task!',
      tz.TZDateTime.from(currentDay, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel_id',
          'Reminders',
          channelDescription: 'Reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload ?? 'study_forge_persistent',
    );
    currentDay = currentDay.add(const Duration(days: 1));
    count++;
  }

  debugPrint("Scheduled $count daily 8AM reminders until $dueDate");
}

Future<void> scheduleDueTomorrowNotification({
  required int id,
  String? title,
  String? body,
  required DateTime dueDate,
  String? payload,
}) async {
  final notifyTime = DateTime(
    dueDate.year,
    dueDate.month,
    dueDate.day - 1,
    8,
    0,
  );
  if (notifyTime.isAfter(DateTime.now())) {
    final androidDetails = AndroidNotificationDetails(
      'reminder_channel_id',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    final notificationDetails = NotificationDetails(android: androidDetails);

    await NotificationService._flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title ?? '📌 Due Tomorrow!',
      body ?? 'Something is due tomorrow: $title',
      tz.TZDateTime.from(notifyTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload ?? 'study_forge_due',
    );
  }
}
