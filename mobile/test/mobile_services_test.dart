import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/assistant/data/assistant_cubit.dart';
import 'package:mobile/features/facilities/data/facilities_cubit.dart';
import 'package:mobile/features/facilities/data/facility.dart';
import 'package:mobile/features/settings/data/content_update_cubit.dart';
import 'package:mobile/features/first_aid/data/reference_content_repository.dart';
import 'package:mobile/features/knowledge/presentation/knowledge_page.dart';
import 'support/mobile_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Snapshot update commits only valid public content and handles ETags',
    () async {
      final store = MemoryStore()
        ..snapshot = jsonEncode({
          ...testSnapshot(),
          '_downloaded_at': '2026-11-01T01:00:00Z',
        });
      final api = FakeApi();
      final cubit = ContentUpdateCubit(api: api, store: store);
      addTearDown(cubit.close);
      await cubit.load();
      api.onGet = (path, query, headers) async {
        expect(path, '/offline-snapshot');
        expect(headers!['If-None-Match'], '"test-v1"');
        return response(null, status: 304);
      };
      await cubit.update();
      expect(cubit.state.status, UpdateStatus.unchanged);
      api.onGet = (_, _, _) async => response(testSnapshot(version: 'test-v2'));
      await cubit.update();
      expect(cubit.state.status, UpdateStatus.success);
      expect(cubit.state.version, 'test-v2');
      final good = store.snapshot;
      for (final invalid in [
        'schema',
        'draft',
        'reference',
        'region',
        'duplicate',
      ]) {
        final data = testSnapshot(version: 'bad');
        switch (invalid) {
          case 'schema':
            data['schema_version'] = 99;
          case 'draft':
            data['articles'][0]['status'] = 'DRAFT';
          case 'reference':
            data['articles'][0]['references'][0]['source_id'] = 'missing';
          case 'region':
            data['region_code'] = 'wrong-region';
          case 'duplicate':
            data['articles'].add(data['articles'][0]);
        }
        api.onGet = (_, _, _) async => response(data);
        await cubit.update();
        expect(cubit.state.status, UpdateStatus.failed, reason: invalid);
        expect(store.snapshot, good);
        expect(cubit.state.version, 'test-v2');
      }
      store.failWrite = true;
      api.onGet = (_, _, _) async => response(testSnapshot(version: 'test-v3'));
      await cubit.update();
      expect(cubit.state.status, UpdateStatus.failed);
      expect(store.snapshot, good);
      expect(cubit.state.version, 'test-v2');
    },
  );
  test(
    'Public snapshot can remove all articles from a category without restoring drafts',
    () {
      final data = testSnapshot();
      data['articles'].removeWhere((a) => a['category_code'] == 'FA02');
      final library = ContentUpdateCubit.validateSnapshot(data);
      expect(library.forCategory('FA02'), isEmpty);
      expect(library.articles.every((a) => a.isPublic), true);
    },
  );
  test(
    'Search uses category keywords and shared articles for either age filter',
    () {
      final library = ReferenceLibrary.fromSnapshot(testSnapshot());
      for (final age in ['ADULT', 'CHILD']) {
        expect(
          searchArticles(library, 'cho can', age: age).single.ageGroup,
          'ALL',
        );
        expect(
          searchArticles(
            library,
            'CPR',
            age: age,
          ).every((a) => a.ageGroup == age || a.ageGroup == 'ALL'),
          true,
        );
      }
      expect(searchArticles(library, 'khongcofoobar'), isEmpty);
    },
  );
  test(
    'Chat handles all statuses and rejects uncited or mismatched answers',
    () {
      for (final status in [
        'answered',
        'clarification_needed',
        'emergency_redirect',
        'insufficient_evidence',
        'out_of_scope',
        'unavailable',
      ]) {
        final data = <String, dynamic>{
          'request_id': 'r1',
          'status': status,
          'clarification_question': 'Tình huống nào?',
          'answer_blocks': [
            {
              'text': 'Thông tin kiểm thử',
              'citation_ids': ['c1'],
            },
          ],
          'citations': [
            {
              'id': 'c1',
              'source_id': 's1',
              'source_revision': 1,
              'evidence_id': 'test',
            },
          ],
        };
        final reply = ChatReply.parse(data, 'r1');
        expect(reply.blocks.isNotEmpty, status == 'answered');
        if (status == 'answered') {
          data['answer_blocks'][0]['citation_ids'] = ['missing'];
          expect(() => ChatReply.parse(data, 'r1'), throwsFormatException);
        }
        expect(
          () => ChatReply.parse(data, 'different-request'),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'Chat is stateless, prevents duplicate sends and preserves retry on failure',
    () async {
      final api = FakeApi();
      final pending = Completer<Map<String, dynamic>>();
      api.onAsk = (_) => pending.future;
      final cubit = AssistantCubit(api);
      addTearDown(cubit.close);
      final sending = cubit.send('  Câu hỏi đầy đủ  ', 'CHILD');
      await cubit.send('Lặp', null);
      expect(api.requests.length, 1);
      final request = api.requests.single;
      expect(request.keys.toSet(), {
        'client_request_id',
        'message',
        'age_group',
        'context_mode',
      });
      expect(request['message'], 'Câu hỏi đầy đủ');
      expect(request['age_group'], 'CHILD');
      pending.complete({
        'request_id': request['client_request_id'],
        'status': 'unavailable',
      });
      await sending;
      expect(cubit.state.turns.single.message, 'Câu hỏi đầy đủ');
      expect(cubit.state.turns.single.reply!.status, ChatStatus.unavailable);
      await cubit.send('x' * 2001, null);
      expect(api.requests.length, 1);
      api.onAsk = (request) async => {
        'request_id': request['client_request_id'],
        'status': 'out_of_scope',
      };
      await cubit.send('Câu hỏi đầy đủ', 'CHILD', retry: true);
      expect(cubit.state.turns.length, 1);
      expect(cubit.state.turns.single.reply!.status, ChatStatus.outOfScope);
    },
  );
  test(
    'Directory requests location only after a user action, and keeps cached data on failure',
    () async {
      final store = MemoryStore()
        ..snapshot = jsonEncode({
          ...testSnapshot(),
          'facilities': [
            testFacility(),
            testFacility(
              id: '00000000-0000-4000-8000-000000000402',
              latitude: 17,
            ),
          ],
        });
      final location = FakeLocation();
      final api = FakeApi();
      final cubit = FacilitiesCubit(api: api, store: store, location: location);
      addTearDown(cubit.close);
      await cubit.loadLocal();
      expect(location.requests, 0);
      expect(cubit.state.items.length, 2);
      location.issue = LocationIssue.permanentlyDenied;
      await cubit.locate();
      expect(cubit.state.issue, LocationIssue.permanentlyDenied);
      expect(cubit.state.items.length, 2);
      location.issue = null;
      await cubit.locate();
      expect(
        cubit.state.ordered.first.distanceFrom(16.05, 108.2),
        closeTo(0, .001),
      );
      await cubit.refresh();
      expect(cubit.state.items.length, 2);
      expect(cubit.state.message, isNotNull);
      expect(
        Facility.parseList([testFacility()..['is_active'] = false]),
        isEmpty,
      );
      expect(
        () => Facility.parseList([testFacility()..['verified_at'] = null]),
        throwsA(anything),
      );
    },
  );
}
