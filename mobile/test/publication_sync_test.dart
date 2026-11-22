import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/settings/data/content_update_cubit.dart';
import 'support/mobile_fakes.dart';

void main() {
  final fixture = Platform.environment['FIRSTAID_TEST_SNAPSHOTS'];
  test(
    'mobile imports the published revision and withdraws it at next sync',
    () async {
      final data =
          jsonDecode(File(fixture!).readAsStringSync()) as Map<String, dynamic>;
      final api = FakeApi();
      final store = MemoryStore()
        ..snapshot = File(
          'assets/content/offline_snapshot.json',
        ).readAsStringSync();
      final catalog = ContentUpdateCubit(api: api, store: store);
      addTearDown(catalog.close);
      await catalog.load();
      for (final phase in ['published', 'withdrawn']) {
        ContentUpdateCubit.validateSnapshot(
          Map<String, dynamic>.from(data[phase] as Map),
        );
        api.onGet = (path, _, _) async => Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {'data': data[phase]},
        );
        await catalog.update();
        expect(catalog.state.status, UpdateStatus.success);
        expect(
          catalog.state.library!.articles.any((a) => a.id == data['id']),
          phase == 'published',
        );
      }
    },
    skip: fixture == null
        ? 'Requires snapshots from disposable publication lifecycle'
        : false,
  );
}
