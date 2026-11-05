import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class SnapshotStore {
  Future<String?> read();
  Future<void> replace(String snapshot);
  Future<String?> readFacilities(String region);
  Future<void> replaceFacilities(String region, String facilities);
}

class SqliteSnapshotStore implements SnapshotStore {
  static final instance = SqliteSnapshotStore();
  Future<Database>? _opening;
  Future<Database> get _database => _opening ??= _open();

  Future<Database> _open() async {
    if (kIsWeb ||
        !{
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform)) {
      throw UnsupportedError('Persistent storage requires a mobile device.');
    }
    return openDatabase(
      'firstaid_content.db',
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE snapshot (id INTEGER PRIMARY KEY CHECK(id = 1), payload TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE facilities (region TEXT PRIMARY KEY, payload TEXT NOT NULL)',
        );
      },
    );
  }

  Future<String?> _read(String table, String where, List<Object?> args) async {
    try {
      final db = await _database;
      final rows = await db.query(
        table,
        where: where,
        whereArgs: args,
        limit: 1,
      );
      return rows.isEmpty ? null : rows.first['payload'] as String;
    } on MissingPluginException {
      _opening = null;
      return null;
    } on UnsupportedError {
      _opening = null;
      return null;
    }
  }

  @override
  Future<String?> read() => _read('snapshot', 'id = ?', [1]);
  @override
  Future<String?> readFacilities(String region) =>
      _read('facilities', 'region = ?', [region]);

  @override
  Future<void> replace(String snapshot) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.insert('snapshot', {
        'id': 1,
        'payload': snapshot,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      // A full snapshot also replaces any previously refreshed directory cache.
      await txn.delete('facilities');
    });
  }

  @override
  Future<void> replaceFacilities(String region, String facilities) async {
    final db = await _database;
    await db.transaction(
      (txn) => txn.insert('facilities', {
        'region': region,
        'payload': facilities,
      }, conflictAlgorithm: ConflictAlgorithm.replace),
    );
  }
}
