import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:study_forge/models/note_model.dart';

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
            created_at INTEGER,
            bookmarked INTEGER,
            isMarkDown INTEGER
          )
        ''');
      },
    );
  }

  Future<void> addNote(
    String id,
    String title,
    String content,
    bool isMarkDown,
  ) async {
    final db = await database;

    final trimmedTitle = title.trim();
    final trimmedContent = content.trim();
    if (trimmedTitle.isEmpty && trimmedContent.isEmpty) return;

    final finalTitle = trimmedTitle.isEmpty
        ? "Untitled (${DateTime.now().second})"
        : trimmedTitle;

    final note = Note(
      id: id,
      title: finalTitle,
      content: trimmedContent,
      createdAt: DateTime.now(),
      isBookmarked: false,
      isMarkDown: isMarkDown,
    );

    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final maps = await db.query(
      'notes',
      orderBy: 'bookmarked DESC, created_at DESC, title ASC',
    );

    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );

    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<void> updateNote(
    String id,
    String newTitle,
    String newContent,
    bool isMarkDown,
  ) async {
    final db = await database;
    await db.update(
      'notes',
      {'title': newTitle, 'content': newContent, 'isMarkDown': isMarkDown},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleBookmark(String id, bool isBookmarked) async {
    final db = await database;
    await db.update(
      'notes',
      {'bookmarked': isBookmarked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearDB() async {
    final db = await database;
    await db.execute("DELETE FROM notes");
  }

  Future<void> migrateDatabaseAddCreatedAt() async {
    final db = await database;
    try {
      await db.execute("ALTER TABLE notes ADD COLUMN created_at INTEGER");
      await db.execute(
        "UPDATE notes SET created_at = ${DateTime.now().millisecondsSinceEpoch}",
      );
      print("✅ Migration: 'created_at' column added and backfilled.");
    } catch (e) {
      print("⚠️ Migration skipped or failed: $e");
    }
  }

  Future<void> migrateDatabaseAddBookmarked() async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA table_info(notes)');
    print(result);
    await db.execute('''
    ALTER TABLE notes ADD COLUMN isBookmarked INTEGER DEFAULT 0
  ''');
  }

  Future<void> migrateDatabaseAddMarkdown() async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA table_info(notes)');
    print(result);
    await db.execute('''
    ALTER TABLE notes ADD COLUMN isMarkDown INTEGER DEFAULT 0
  ''');
  }
}
