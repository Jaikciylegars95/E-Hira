import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/partition.dart';

class DBHelper {
  static Database? _db;
  static const String dbName = 'chorale_db.db';
  static const int dbVersion = 2;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE partitions (
        id               INTEGER PRIMARY KEY,
        titre            TEXT NOT NULL,
        categorie        TEXT NOT NULL,
        pdf_url          TEXT,
        audio_url        TEXT,
        version          INTEGER DEFAULT 1,
        local_pdf_path   TEXT,
        local_audio_path TEXT,
        is_favorite      INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE partitions ADD COLUMN local_pdf_path TEXT;');
      await db.execute('ALTER TABLE partitions ADD COLUMN local_audio_path TEXT;');
    }
  }

  static Future<List<Partition>> getAllPartitions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('partitions');
    return maps.map((map) => Partition.fromMap(map)).toList();
  }

  static Future<void> insertOrUpdatePartition(Partition partition) async {
    final db = await database;
    await db.insert(
      'partitions',
      partition.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'partitions',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> delete(int id) async {
    final db = await database;
    await db.delete('partitions', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('partitions');
  }
}