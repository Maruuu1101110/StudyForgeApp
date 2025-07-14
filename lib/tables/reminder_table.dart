import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:study_forge/models/reminder_model.dart';
import 'package:study_forge/tables/user_profile_table.dart';
import 'package:study_forge/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:study_forge/utils/gamification_service.dart';
import 'package:study_forge/tables/db_helper.dart';

class ReminderManager {
  static Database? _database;
  ReminderManager._internal();
  static final ReminderManager _instance = ReminderManager._internal();
  factory ReminderManager() => _instance;

  static const String createReminderTableSQL = '''
  CREATE TABLE IF NOT EXISTS reminders(
    id TEXT PRIMARY KEY,
    title TEXT,
    tags TEXT,
    description TEXT,
    createdAt INTEGER,
    dueDate INTEGER,
    isPinned INTEGER,
    isCompleted INTEGER,
    isNotifEnabled INTEGER DEFAULT 1,
    notificationId INTEGER DEFAULT NULL
  )
''';

  Future<Database> get database async {
    if (_database != null) return _database!;
    return await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'studyforge.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(createReminderTableSQL);
      },
    );
  }

  Future<void> ensureNotificationExists() async {
    final db = await DBHelper.instance.database;
    try {
      await db.execute(
        'ALTER TABLE reminders ADD COLUMN isNotifEnabled INTEGER DEFAULT 1',
      );
    } catch (e) {}
    try {
      await db.execute(
        'ALTER TABLE reminders ADD COLUMN notificationId INTEGER DEFAULT NULL',
      );
    } catch (e) {} // catches are for ignoring existing columns
  }

  Future<void> ensureReminderTableExists() async {
    final db = await DBHelper.instance.database;

    await db.execute(createReminderTableSQL);
  }

  Future<void> addReminder(Reminder reminder) async {
    final db = await DBHelper.instance.database;

    await db.insert(
      'reminders',
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await DBHelper.instance.database;

    await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<List<Reminder>> getAllReminders() async {
    final db = await DBHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      orderBy: 'isPinned DESC ,dueDate DESC',
    );

    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }

  Future<Reminder?> getReminderById(String id) async {
    final db = await DBHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Reminder.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteReminder(String id) async {
    final db = await DBHelper.instance.database;

    final reminder = await getReminderById(id);
    if (reminder != null) {
      await NotificationService.cancelNotification(reminder.notificationId);
    }

    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllReminders() async {
    final db = await DBHelper.instance.database;

    // cancel notifications before deleting reminders
    await NotificationService.cancelAllNotifications();

    await db.delete('reminders');
  }

  Future<void> togglePinned(String id, bool isPinned) async {
    final db = await DBHelper.instance.database;

    await db.update(
      'reminders',
      {'isPinned': isPinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAsCompleted(
    String id,
    bool isCompleted,
    BuildContext context,
  ) async {
    final db = await DBHelper.instance.database;

    // Step 1: Snapshot old profile
    final oldProfile = await UserProfileManager().getUserProfile();

    // Step 2: Update XP and stats
    final newProfile = await GamificationService().recordReminderCompleted();

    // Step 3: Optional: Cancel notification
    if (isCompleted) {
      final reminder = await getReminderById(id);
      if (reminder != null) {
        await NotificationService.cancelNotification(reminder.notificationId);
      }
    }

    // Step 4: Update DB status
    await db.update(
      'reminders',
      {'isCompleted': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Step 5: Show any level up or badge celebration
    await GamificationService().showGamificationNotifications(
      oldProfile,
      newProfile,
      25, // xp amount for completing a reminder
      context,
    );
  }

  Future<List<Reminder>> getPinnedReminders() async {
    final db = await DBHelper.instance.database;

    final maps = await db.query(
      'reminders',
      where: 'isPinned = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }

  Future<List<Reminder>> getCompletedReminders() async {
    final db = await DBHelper.instance.database;

    final maps = await db.query(
      'reminders',
      where: 'isCompleted = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }

  Future<List<Reminder>> getPendingReminders() async {
    final db = await DBHelper.instance.database;

    final maps = await db.query(
      'reminders',
      where: 'isCompleted = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }
}
