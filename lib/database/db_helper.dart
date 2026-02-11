import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/partition.dart';

class DBHelper {
  static Database? _db;
  static const String dbName = 'chorale_app.db';
  static const int dbVersion = 3; // Incrémente quand tu changes la structure

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE partitions (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        titre            TEXT NOT NULL,
        categorie        TEXT NOT NULL,
        pdf_url          TEXT,
        audio_url        TEXT,
        version          INTEGER DEFAULT 1,
        localPdfPath     TEXT,
        localAudioPath   TEXT,
        isFavorite       INTEGER DEFAULT 0,
        created_at       INTEGER DEFAULT (CAST(strftime('%s', 'now') AS INTEGER))
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration de la v1 vers v2 (ajout des colonnes locales si elles n'existent pas)
      await _addColumnIfNotExists(db, 'partitions', 'localPdfPath', 'TEXT');
      await _addColumnIfNotExists(db, 'partitions', 'localAudioPath', 'TEXT');
    }

    if (oldVersion < 3) {
      // Migration de v2 vers v3 (exemple : ajout created_at si besoin)
      await _addColumnIfNotExists(db, 'partitions', 'created_at', 'INTEGER DEFAULT (CAST(strftime(\'%s\', \'now\') AS INTEGER))');
    }

    // Ajoute ici d'autres migrations futures quand tu incrémenteras dbVersion
  }

  // Méthode utilitaire pour ajouter une colonne seulement si elle n'existe pas
  static Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final result = await db.rawQuery('''
      SELECT * FROM pragma_table_info('$table') WHERE name = '$column'
    ''');
    if (result.isEmpty) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
      print('Colonne $column ajoutée à la table $table');
    }
  }

  static Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    // En cas de downgrade (rare), on peut supprimer et recréer la base
    // (ou laisser vide si tu ne veux rien faire)
    await db.execute('DROP TABLE IF EXISTS partitions');
    await _onCreate(db, newVersion);
  }

  // Récupère toutes les partitions
  static Future<List<Partition>> getAllPartitions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('partitions');
    return List.generate(maps.length, (i) => Partition.fromMap(maps[i]));
  }

  // Insère ou met à jour une partition (upsert)
  static Future<void> insertOrUpdatePartition(Partition partition) async {
    final db = await database;
    await db.insert(
      'partitions',
      partition.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Met à jour uniquement le statut favori
  static Future<void> updateFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'partitions',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprime une partition (rarement utilisé)
  static Future<void> delete(int id) async {
    final db = await database;
    await db.delete('partitions', where: 'id = ?', whereArgs: [id]);
  }

  // Vide toute la table (pour tests ou réinitialisation volontaire)
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('partitions');
  }

  // Pour debug : voir le schéma actuel de la table
  static Future<void> printTableSchema() async {
    final db = await database;
    final result = await db.rawQuery("PRAGMA table_info(partitions)");
    print("Schéma de la table partitions :");
    for (var row in result) {
      print(row);
    }
  }
}