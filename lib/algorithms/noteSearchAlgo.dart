import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class Note {
  final String id;
  final String title;
  final String content;

  Note({required this.id, required this.title, required this.content});
}

class NoteManager {
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
          CREATE TABLE notes(
            id TEXT PRIMARY KEY,
            title TEXT,
            content TEXT,
            created_at INTEGER
          )
        ''');
      },
    );
  }

  Future<void> addNote(String id, String title, String content) async {
    final db = await database;

    try {
      final trimmedTitle = title.trim();
      final trimmedContent = content.trim();

      // Don't save if both are empty
      if (trimmedTitle.isEmpty && trimmedContent.isEmpty) return;

      // If title is empty but content exists, default the title
      final finalTitle = trimmedTitle.isEmpty
          ? "Untitled (${DateTime.now().second})"
          : trimmedTitle;

      await db.insert('notes', {
        'id': id,
        'title': finalTitle,
        'content': trimmedContent,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print("❌ DB Error while adding note: $e");
    }
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: 'created_at DESC', // 👈 newest first
    );
    ;

    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'],
        title: maps[i]['title'],
        content: maps[i]['content'],
      );
    });
  }

  Future<void> updateNote(String id, String newTitle, String newContent) async {
    final db = await database;
    await db.update(
      'notes',
      {'title': newTitle, 'content': newContent},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );

    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'],
        title: maps[i]['title'],
        content: maps[i]['content'],
      );
    });
  }

  Future<void> migrateDatabaseAddCreatedAt() async {
    final db = await database;

    // Try to add the column
    try {
      await db.execute("ALTER TABLE notes ADD COLUMN created_at INTEGER");
      print("✅ 'created_at' column added.");

      // Backfill existing notes with current timestamp
      int now = DateTime.now().millisecondsSinceEpoch;
      await db.execute("UPDATE notes SET created_at = $now");
      print("✅ Backfilled existing notes.");
    } catch (e) {
      print("⚠️ Migration skipped or failed: $e");
    }
  }

  Future<void> clearDB() async {
    final db = await database;
    await db.execute("DELETE FROM notes"); // 💣 nukes the whole table
  }
}
