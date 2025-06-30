import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:study_forge/models/reminder_model.dart';

class ReminderManager {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    return await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'notes.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reminders(
            id TEXT PRIMARY KEY,
            title TEXT,
            tags TEXT,
            description TEXT,
            createdAt INTEGER,
            dueDate INTEGER,
            isPinned INTEGER,
            isCompleted INTEGER
          )
        ''');
      },
    );
  }

  Future<void> ensureReminderTableExists() async {
    final db = await database;
    await db.execute('''
    CREATE TABLE IF NOT EXISTS reminders(
      id TEXT PRIMARY KEY,
      title TEXT,
      tags TEXT,
      description TEXT,
      createdAt INTEGER,
      dueDate INTEGER,
      isPinned INTEGER,
      isCompleted INTEGER
    )
  ''');
  }

  Future<void> addReminder(Reminder reminder) async {
    final db = await database;

    await db.insert(
      'reminders',
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await database;

    await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<List<Reminder>> getAllReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      orderBy: 'isPinned DESC ,dueDate ASC',
    );

    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }

  Future<Reminder?> getReminderById(String id) async {
    final db = await database;
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
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllReminders() async {
    final db = await database;
    await db.delete('reminders');
  }

  Future<void> togglePinned(String id, bool isPinned) async {
    final db = await database;
    await db.update(
      'reminders',
      {'isPinned': isPinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Reminder>> getPinnedReminders() async {
    final db = await database;
    final maps = await db.query(
      'reminders',
      where: 'isPinned = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }

  Future<List<Reminder>> getCompletedReminders() async {
    final db = await database;
    final maps = await db.query(
      'reminders',
      where: 'isCompleted = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }
}
