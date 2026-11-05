import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mobile/core/network/app_services.dart';
import 'package:mobile/core/storage/snapshot_store.dart';
import 'package:mobile/features/facilities/data/facilities_cubit.dart';
import 'package:mobile/features/facilities/presentation/facilities_page.dart';

Map<String, dynamic> testSnapshot({String version = 'test-v1'}) {
  final seed =
      jsonDecode(
            File('assets/content/reference_library.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  // Synthetic publication flags are confined to test fixtures.
  for (final article in seed['articles'] as List) {
    article['status'] = 'PUBLISHED';
    article['content_checked'] = true;
    article['checked_at'] = '2026-11-01T00:00:00Z';
  }
  return {
    'schema_version': 1,
    'data_version': version,
    'generated_at': '2026-11-01T00:00:00Z',
    'region_code': AppEnvironment.regionCode,
    'app_config': {'locale': 'vi-VN', 'emergency_number': '115'},
    'categories': seed['categories'],
    'articles': seed['articles'],
    'sources': seed['sources'],
    'facilities': <dynamic>[],
  };
}

Map<String, dynamic> testFacility({
  String id = '00000000-0000-4000-8000-000000000401',
  double latitude = 16.05,
}) => {
  'id': id,
  'name': 'Cơ sở kiểm thử',
  'region_code': AppEnvironment.regionCode,
  'address': 'Địa chỉ chỉ dùng trong kiểm thử',
  'phone': '0000000000',
  'latitude': latitude,
  'longitude': 108.2,
  'emergency_24h': 'UNKNOWN',
  'verification_note': 'Dữ liệu giả lập trong test',
  'verified_at': '2026-11-01T00:00:00Z',
  'is_active': true,
};

class MemoryStore implements SnapshotStore {
  String? snapshot;
  final directories = <String, String>{};
  bool failWrite = false;
  @override
  Future<String?> read() async => snapshot;
  @override
  Future<void> replace(String data) async {
    if (failWrite) throw StateError('write failed');
    snapshot = data;
    directories.clear();
  }

  @override
  Future<String?> readFacilities(String region) async => directories[region];
  @override
  Future<void> replaceFacilities(String region, String data) async {
    if (failWrite) throw StateError('write failed');
    directories[region] = data;
  }
}

class FakeNetwork extends NetworkStatus {
  bool online = true;
  @override
  Future<bool> isOnline() async => online;
}

class FakeApi extends PublicApi {
  FakeApi()
    : super(baseUrl: 'https://firstaid.invalid/api/v1', network: FakeNetwork());
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onAsk;
  Future<Response<dynamic>> Function(
    String,
    Map<String, dynamic>?,
    Map<String, dynamic>?,
  )?
  onGet;
  final requests = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> ask(Map<String, dynamic> request) async {
    requests.add(request);
    if (!await network.isOnline()) throw OfflineException();
    return onAsk == null ? throw ServiceUnavailable() : onAsk!(request);
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    if (!await network.isOnline()) throw OfflineException();
    return onGet == null
        ? throw ServiceUnavailable()
        : onGet!(path, query, headers);
  }
}

Response<dynamic> response(Object? data, {int status = 200}) => Response(
  requestOptions: RequestOptions(),
  statusCode: status,
  data: data == null ? null : {'data': data},
);

class FakeLocation extends LocationService {
  LocationIssue? issue;
  int requests = 0;
  @override
  Future<UserLocation> current() async {
    requests++;
    if (issue != null) throw LocationFailure(issue!);
    return const UserLocation(16.05, 108.2);
  }
}

class FailedActions extends ExternalActions {
  final opened = <Uri>[];
  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return false;
  }
}
