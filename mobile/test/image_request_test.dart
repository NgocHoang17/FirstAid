import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/app_services.dart';
import 'package:mobile/features/settings/data/content_update_cubit.dart';
import 'support/mobile_fakes.dart';

void main() {
  test(
    'image submission sends two named parts through the public gateway',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.path, '/assistant/query-with-image');
            expect(
              request.headers.keys.map((s) => s.toLowerCase()),
              isNot(contains('x-internal-token')),
            );
            final form = request.data as FormData;
            expect(
              form.files.map((p) => p.key),
              containsAll(['request', 'image']),
            );
            final jsonPart = form.files
                .firstWhere((p) => p.key == 'request')
                .value;
            expect(
              jsonPart.contentType.toString(),
              startsWith('application/json'),
            );
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'data': {'status': 'unavailable'},
                },
              ),
            );
          },
        ),
      );
      final api = PublicApi(
        client: dio,
        baseUrl: dio.options.baseUrl,
        network: FakeNetwork(),
      );
      expect(
        (await api.askImage(
          {'message': 'Học sơ cứu'},
          Uint8List.fromList([1, 2]),
          'image/png',
        ))['status'],
        'unavailable',
      );
    },
  );

  test(
    'a schema 2 snapshot without directory or region preserves the lessons',
    () {
      final v1 = testSnapshot();
      final v2 = jsonDecode(jsonEncode(v1)) as Map<String, dynamic>;
      v2['schema_version'] = 2;
      v2.remove('region_code');
      v2.remove('facilities');
      expect(
        ContentUpdateCubit.validateSnapshot(v2).articles.map((a) => a.id),
        ContentUpdateCubit.validateSnapshot(v1).articles.map((a) => a.id),
      );
    },
  );
}
