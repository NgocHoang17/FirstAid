import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile/core/storage/snapshot_store.dart';
import 'package:mobile/features/settings/data/content_update_cubit.dart';
import 'support/mobile_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test(
    'Upgrading the old directory database preserves saved learning content',
    () async {
      final dir = await Directory.systemTemp.createTemp('firstaid-upgrade-');
      final path = '${dir.path}/content.db';
      final payload = jsonEncode(testSnapshot());
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE snapshot (id INTEGER PRIMARY KEY, payload TEXT NOT NULL)',
            );
            await db.execute(
              'CREATE TABLE facilities (region TEXT PRIMARY KEY, payload TEXT NOT NULL)',
            );
            await db.insert('snapshot', {'id': 1, 'payload': payload});
            await db.insert('facilities', {'region': 'old', 'payload': '[]'});
          },
        ),
      );
      await old.close();
      final store = SqliteSnapshotStore(
        factory: databaseFactoryFfi,
        path: path,
      );
      addTearDown(() async {
        await store.close();
        await dir.delete(recursive: true);
      });
      expect(await store.read(), payload);
      final db = await databaseFactoryFfi.openDatabase(path);
      expect(
        await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='facilities'",
        ),
        isEmpty,
      );
    },
  );
  test(
    'SQLite replacement survives reopening and rolls back content on failure',
    () async {
      final dir = await Directory.systemTemp.createTemp('firstaid-sqlite-');
      final path = '${dir.path}/content.db';
      final store = SqliteSnapshotStore(
        factory: databaseFactoryFfi,
        path: path,
      );
      addTearDown(() async {
        await store.close();
        await dir.delete(recursive: true);
      });
      final old = jsonEncode(testSnapshot());
      await store.replace(old);
      await store.close();
      expect(await store.read(), old);
      final db = await databaseFactoryFfi.openDatabase(path);
      await db.execute(
        "CREATE TRIGGER fail_snapshot_write BEFORE INSERT ON snapshot BEGIN SELECT RAISE(ABORT, 'test disk failure'); END",
      );
      await expectLater(
        store.replace(jsonEncode(testSnapshot(version: 'new'))),
        throwsA(anything),
      );
      expect(await store.read(), old);
      await db.execute('DROP TRIGGER fail_snapshot_write');
      await store.replace(jsonEncode(testSnapshot(version: 'new')));
      await store.close();
      expect(jsonDecode((await store.read())!)['data_version'], 'new');
    },
  );
  test(
    'A removed category and an empty public snapshot remain removed after restart',
    () async {
      final store = MemoryStore();
      final api = FakeApi();
      final cubit = ContentUpdateCubit(store: store, api: api);
      addTearDown(cubit.close);
      await cubit.load();
      final changed = testSnapshot(version: 'removed');
      final id = changed['categories'][0]['id'];
      changed['categories'].removeAt(0);
      changed['articles'].removeWhere((a) => a['category_id'] == id);
      api.onGet = (_, _, _) async => response(changed);
      await cubit.update();
      expect(cubit.state.status, UpdateStatus.success);
      expect(cubit.state.library!.categories.length, 17);
      final empty = testSnapshot(version: 'empty');
      for (final key in ['categories', 'articles', 'sources', 'facilities']) {
        empty[key] = <dynamic>[];
      }
      api.onGet = (_, _, _) async => response(empty);
      await cubit.update();
      final restarted = ContentUpdateCubit(store: store, api: api);
      addTearDown(restarted.close);
      await restarted.load();
      expect(restarted.state.version, 'empty');
      expect(restarted.state.library!.articles, isEmpty);
      expect(restarted.state.library!.categories, isEmpty);
    },
  );
  test('Mismatched ETag never replaces valid content', () async {
    final store = MemoryStore()..snapshot = jsonEncode(testSnapshot());
    final api = FakeApi()
      ..onGet = (_, _, _) async {
        final result = response(testSnapshot(version: 'changed'));
        result.headers.set('etag', '"different"');
        return result;
      };
    final cubit = ContentUpdateCubit(store: store, api: api);
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.update();
    expect(cubit.state.status, UpdateStatus.failed);
    expect(cubit.state.version, 'test-v1');
  });
}
