import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class SnapshotStore {
  Future<String?> read();
  Future<void> replace(String snapshot);
  Future<String?> readFacilities(String region);
  Future<bool> replaceFacilities(
    String region,
    String facilities, {
    required String? snapshotAtRequest,
  });
}

class SqliteSnapshotStore implements SnapshotStore {
  SqliteSnapshotStore({
    DatabaseFactory? factory,
    this.path = 'firstaid_content.db',
  }) : _factory = factory;
  final DatabaseFactory? _factory;
  final String path;
  static final instance = SqliteSnapshotStore();
  Future<Database>? _opening;
  Future<Database> get _database =>
      _opening ??= _open().catchError((Object error) {
        _opening = null;
        throw error;
      });

  Future<void> close() async {
    final pending = _opening;
    if (pending != null) await (await pending).close();
    _opening = null;
  }

  Future<Database> _open() async {
    if (_factory == null &&
        (kIsWeb ||
            !{
              TargetPlatform.android,
              TargetPlatform.iOS,
              TargetPlatform.macOS,
            }.contains(defaultTargetPlatform))) {
      throw UnsupportedError('Persistent storage requires a mobile device.');
    }
    return (_factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE snapshot (id INTEGER PRIMARY KEY CHECK(id = 1), payload TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE facilities (region TEXT PRIMARY KEY, payload TEXT NOT NULL)',
          );
        },
      ),
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
  Future<bool> replaceFacilities(
    String region,
    String facilities, {
    required String? snapshotAtRequest,
  }) async {
    final db = await _database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'snapshot',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );
      final current = rows.isEmpty ? null : rows.first['payload'] as String;
      // A delayed directory response must not resurrect a facility removed by
      // a newer full snapshot. Compare and write in the same transaction.
      if (current != snapshotAtRequest) return false;
      await txn.insert('facilities', {
        'region': region,
        'payload': facilities,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    });
  }
}
