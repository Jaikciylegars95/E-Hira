import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/partition.dart';

class DBHelper {
  static Database? _db;
  static const String dbName = 'chorale_app.db';
  static const int dbVersion = 5; // ← Augmenté pour forcer la migration

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
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        titre             TEXT NOT NULL,
        categorie         TEXT NOT NULL,
        pdf_url           TEXT,
        audio_url         TEXT,
        version           INTEGER DEFAULT 1,
        local_pdf_path    TEXT,
        local_audio_path  TEXT,
        is_favorite       INTEGER DEFAULT 0,
        created_at        INTEGER DEFAULT (CAST(strftime('%s', 'now') AS INTEGER))
      )
    ''');
    print('Table partitions créée avec succès (version $version)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Migration de la base : v$oldVersion → v$newVersion');

    if (oldVersion < 2) {
      await _addColumnIfNotExists(db, 'partitions', 'local_pdf_path', 'TEXT');
      await _addColumnIfNotExists(db, 'partitions', 'local_audio_path', 'TEXT');
    }

    if (oldVersion < 3) {
      await _addColumnIfNotExists(db, 'partitions', 'created_at',
          'INTEGER DEFAULT (CAST(strftime(\'%s\', \'now\') AS INTEGER))');
    }

    if (oldVersion < 4) {
      print('Migration v3 → v4 : vérification colonnes locales');
      await _addColumnIfNotExists(db, 'partitions', 'local_pdf_path', 'TEXT');
      await _addColumnIfNotExists(db, 'partitions', 'local_audio_path', 'TEXT');
    }

    if (oldVersion < 5) {
      print('Migration v4 → v5 : vérification finale + nettoyage');
      await _addColumnIfNotExists(db, 'partitions', 'local_pdf_path', 'TEXT');
      await _addColumnIfNotExists(db, 'partitions', 'local_audio_path', 'TEXT');
    }
  }

  static Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    print('Downgrade détecté : suppression et recréation complète');
    await db.execute('DROP TABLE IF EXISTS partitions');
    await _onCreate(db, newVersion);
  }

  /// Ajoute une colonne si elle n'existe pas (avec gestion d'erreurs)
  static Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    try {
      final result = await db.rawQuery('''
        SELECT * FROM pragma_table_info('$table') WHERE name = '$column'
      ''');
      if (result.isEmpty) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
        print('Colonne "$column" ajoutée à la table $table');
      } else {
        print('Colonne "$column" existe déjà dans $table');
      }
    } catch (e) {
      print('Erreur lors de la vérification/ajout de $column : $e');
    }
  }

  // Récupère toutes les partitions
  static Future<List<Partition>> getAllPartitions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('partitions');
    print('Partitions chargées depuis DB : ${maps.length}');
    return List.generate(maps.length, (i) => Partition.fromMap(maps[i]));
  }

  // Insère ou met à jour une partition (upsert)
  static Future<void> insertOrUpdatePartition(Partition partition) async {
    final db = await database;
    try {
      await db.insert(
        'partitions',
        partition.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Partition insérée/mise à jour : ${partition.titre} (id: ${partition.id})');
    } catch (e) {
      print('Erreur insertion partition ${partition.titre} : $e');
      rethrow;
    }
  }

  // Met à jour uniquement le statut favori
  static Future<void> updateFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'partitions',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Favori mis à jour pour id $id → $isFavorite');
  }

  // Supprime une partition
  static Future<void> delete(int id) async {
    final db = await database;
    await db.delete('partitions', where: 'id = ?', whereArgs: [id]);
  }

  // Vide toute la table (pour tests)
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('partitions');
    print('Table partitions vidée complètement');
  }

  // Debug : affiche le schéma actuel de la table
  static Future<void> printTableSchema() async {
    final db = await database;
    final result = await db.rawQuery("PRAGMA table_info(partitions)");
    print("=== Schéma actuel de la table partitions (version $dbVersion) ===");
    if (result.isEmpty) {
      print("Table partitions n'existe pas encore !");
    } else {
      for (var row in result) {
        print(row);
      }
    }
    print("================================================================");
  }
}