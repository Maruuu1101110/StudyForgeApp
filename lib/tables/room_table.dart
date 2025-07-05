// Room table manager for database operations
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:study_forge/models/room_model.dart';
import 'package:flutter/foundation.dart';

class RoomTableManager {
  static Database? _database;
  RoomTableManager._internal();
  static final RoomTableManager _instance = RoomTableManager._internal();
  factory RoomTableManager() => _instance;

  static const String _tableName = 'rooms';

  // create the rooms table
  static const String createRoomTableSQL =
      '''
    CREATE TABLE IF NOT EXISTS $_tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subject TEXT NOT NULL,
      subtitle TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'Active',
      imagePath TEXT,
      color TEXT,
      createdAt INTEGER NOT NULL,
      lastAccessedAt INTEGER,
      totalSessions INTEGER NOT NULL DEFAULT 0,
      totalStudyTime INTEGER NOT NULL DEFAULT 0,
      goals TEXT,
      isFavorite INTEGER NOT NULL DEFAULT 0,
      description TEXT,
      UNIQUE(subject)
    )
  ''';

  // get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // initialize database
  static Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'study_forge.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(createRoomTableSQL);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing room database: $e');
      }
      rethrow;
    }
  }

  // ensure the rooms table exists
  static Future<void> ensureRoomTableExists() async {
    final db = await database;
    try {
      await db.execute(createRoomTableSQL);
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring room table exists: $e');
      }
      rethrow;
    }
  }

  // insert a new room
  static Future<int> insertRoom(Room room) async {
    final db = await database;
    try {
      return await db.insert(
        _tableName,
        room.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to insert room: $e');
    }
  }

  // get all rooms
  static Future<List<Room>> getAllRooms() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'lastAccessedAt DESC, createdAt DESC',
      );
      return List.generate(maps.length, (i) => Room.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get rooms: $e');
    }
  }

  // get room by ID
  static Future<Room?> getRoomById(int id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Room.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get room by ID: $e');
    }
  }

  // get room by subject
  static Future<Room?> getRoomBySubject(String subject) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'subject = ?',
        whereArgs: [subject],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Room.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get room by subject: $e');
    }
  }

  // update room
  static Future<int> updateRoom(Room room) async {
    final db = await database;
    try {
      return await db.update(
        _tableName,
        room.toMap(),
        where: 'id = ?',
        whereArgs: [room.id],
      );
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  // delete room
  static Future<int> deleteRoom(int id) async {
    final db = await database;
    try {
      return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }

  // get rooms by status
  static Future<List<Room>> getRoomsByStatus(String status) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'lastAccessedAt DESC, createdAt DESC',
      );
      return List.generate(maps.length, (i) => Room.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get rooms by status: $e');
    }
  }

  // get favorite rooms
  static Future<List<Room>> getFavoriteRooms() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'isFavorite = ?',
        whereArgs: [1],
        orderBy: 'lastAccessedAt DESC, createdAt DESC',
      );
      return List.generate(maps.length, (i) => Room.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get favorite rooms: $e');
    }
  }

  // update room last accessed time
  static Future<int> updateLastAccessedTime(int roomId) async {
    final db = await database;
    try {
      return await db.update(
        _tableName,
        {'lastAccessedAt': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [roomId],
      );
    } catch (e) {
      throw Exception('Failed to update last accessed time: $e');
    }
  }

  // increment session count and add study time
  static Future<int> addSessionData(int roomId, int studyTimeMinutes) async {
    final db = await database;
    try {
      return await db.rawUpdate(
        '''
        UPDATE $_tableName 
        SET totalSessions = totalSessions + 1,
            totalStudyTime = totalStudyTime + ?,
            lastAccessedAt = ?
        WHERE id = ?
      ''',
        [studyTimeMinutes, DateTime.now().millisecondsSinceEpoch, roomId],
      );
    } catch (e) {
      throw Exception('Failed to add session data: $e');
    }
  }

  // toggle favorite status
  static Future<int> toggleFavorite(int roomId) async {
    final db = await database;
    try {
      return await db.rawUpdate(
        '''
        UPDATE $_tableName 
        SET isFavorite = CASE 
          WHEN isFavorite = 1 THEN 0 
          ELSE 1 
        END
        WHERE id = ?
      ''',
        [roomId],
      );
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // archive room (set status to Archived)
  static Future<int> archiveRoom(int roomId) async {
    final db = await database;
    try {
      return await db.update(
        _tableName,
        {'status': 'Archived'},
        where: 'id = ?',
        whereArgs: [roomId],
      );
    } catch (e) {
      throw Exception('Failed to archive room: $e');
    }
  }

  // restore room (set status to Active)
  static Future<int> restoreRoom(int roomId) async {
    final db = await database;
    try {
      return await db.update(
        _tableName,
        {'status': 'Active'},
        where: 'id = ?',
        whereArgs: [roomId],
      );
    } catch (e) {
      throw Exception('Failed to restore room: $e');
    }
  }

  // get room statistics
  static Future<Map<String, dynamic>> getRoomStats() async {
    final db = await database;
    try {
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as totalRooms,
          COUNT(CASE WHEN status = 'Active' THEN 1 END) as activeRooms,
          COUNT(CASE WHEN status = 'Completed' THEN 1 END) as completedRooms,
          COUNT(CASE WHEN status = 'Archived' THEN 1 END) as archivedRooms,
          COUNT(CASE WHEN isFavorite = 1 THEN 1 END) as favoriteRooms,
          SUM(totalSessions) as totalSessions,
          SUM(totalStudyTime) as totalStudyTime
        FROM $_tableName
      ''');

      if (result.isNotEmpty) {
        return result.first;
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get room statistics: $e');
    }
  }

  // search rooms by subject or subtitle
  static Future<List<Room>> searchRooms(String query) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'subject LIKE ? OR subtitle LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'lastAccessedAt DESC, createdAt DESC',
      );
      return List.generate(maps.length, (i) => Room.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to search rooms: $e');
    }
  }

  // get recently accessed rooms
  static Future<List<Room>> getRecentlyAccessedRooms({int limit = 5}) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'lastAccessedAt IS NOT NULL',
        orderBy: 'lastAccessedAt DESC',
        limit: limit,
      );
      return List.generate(maps.length, (i) => Room.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get recently accessed rooms: $e');
    }
  }

  // bulk delete rooms by IDs
  static Future<int> deleteRooms(List<int> roomIds) async {
    final db = await database;
    try {
      final placeholders = roomIds.map((id) => '?').join(',');
      return await db.rawDelete(
        'DELETE FROM $_tableName WHERE id IN ($placeholders)',
        roomIds,
      );
    } catch (e) {
      throw Exception('Failed to delete rooms: $e');
    }
  }
}
