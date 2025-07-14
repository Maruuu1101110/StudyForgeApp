import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  static Database? _database;

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'studyforge.db');

    _database = await openDatabase(path, version: 1);

    return _database!;
  }
}
