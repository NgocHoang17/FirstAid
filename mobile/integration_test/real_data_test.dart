import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart' show deleteDatabase, getDatabasesPath;
import 'package:mobile/app.dart';
import 'package:mobile/core/network/app_services.dart';
import 'package:mobile/core/storage/snapshot_store.dart';
import 'package:mobile/features/assistant/data/assistant_cubit.dart';
import 'package:mobile/features/settings/data/content_update_cubit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Real PostgreSQL, Node.js, RAG and Android share reviewed app data', (
    tester,
  ) async {
    final api = PublicApi();
    final databasePath =
        '${await getDatabasesPath()}/firstaid_live_test_${DateTime.now().microsecondsSinceEpoch}.db';
    final store = SqliteSnapshotStore(path: databasePath);
    final content = ContentUpdateCubit(api: api, store: store);
    final assistant = AssistantCubit(api);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await content.close();
      await assistant.close();
      await store.close();
      await deleteDatabase(databasePath);
    });
    await content.load();
    expect(content.state.library, isNotNull, reason: content.state.message);
    expect(content.state.library!.articles.length, 24);
    await content.update();
    expect(
      content.state.status,
      UpdateStatus.success,
      reason:
          'Kiểm tra backend Node.js đã seed và API_BASE_URL=${AppEnvironment.apiBaseUrl}. ${content.state.message ?? ''}',
    );
    await content.update();
    expect(content.state.status, UpdateStatus.unchanged);
    final version = content.state.version;
    await store.close();
    expect(jsonDecode((await store.read())!)['data_version'], version);
    await assistant.send('Kiến thức sơ cứu bỏng nhiệt nhẹ', null);
    final reply = assistant.state.turns.single.reply!;
    expect(reply.status, ChatStatus.answered);
    expect(reply.citations, isNotEmpty);
    for (final citation in reply.citations) {
      final source = content.state.library!.sources[citation.sourceId]!;
      expect(citation.revision, source.json['revision']);
    }
    await tester.pumpWidget(MyApp(api: api, store: store));
    await tester.pumpAndSettle();
    expect(find.text('Cơ sở y tế'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
