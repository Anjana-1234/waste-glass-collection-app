import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'collections.db');
    return openDatabase(path, version: 1, onCreate: (db, version) {
      return db.execute('''
        CREATE TABLE collections (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplier_id TEXT,
          barcode_id TEXT,
          supplier_name TEXT,
          clear_kg REAL,
          coloured_kg REAL,
          condition TEXT,
          timestamp TEXT,
          synced INTEGER DEFAULT 0
        )
      ''');
    });
  }

  static Future<void> saveCollection(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('collections', data);
  }

  static Future<List<Map<String, dynamic>>> getAllCollections() async {
    final db = await database;
    return db.query('collections');
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('collections');
  }
}