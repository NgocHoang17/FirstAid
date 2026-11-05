import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'api_client.dart';

abstract final class AppEnvironment {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const regionCode = String.fromEnvironment(
    'PILOT_REGION_CODE',
    defaultValue: 'VN-PILOT',
  );
  static const regionLabel = String.fromEnvironment(
    'PILOT_REGION_LABEL',
    defaultValue: 'Khu vực thí điểm',
  );
}

class OfflineException implements Exception {}

class ServiceUnavailable implements Exception {}

class NetworkStatus {
  Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } on MissingPluginException {
      // Connectivity is a hint; the HTTP timeout remains the final boundary.
      return true;
    } on PlatformException {
      return true;
    }
  }
}

class PublicApi {
  PublicApi({
    Dio? client,
    this.baseUrl = AppEnvironment.apiBaseUrl,
    NetworkStatus? network,
  }) : dio = client ?? ApiClient(baseUrl: baseUrl).dio,
       network = network ?? NetworkStatus();
  final Dio dio;
  final String baseUrl;
  final NetworkStatus network;
  Future<void> _ready() async {
    if (!await network.isOnline()) throw OfflineException();
    if (baseUrl.isEmpty) throw ServiceUnavailable();
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    await _ready();
    return dio
        .get(
          path,
          queryParameters: query,
          options: Options(
            headers: headers,
            validateStatus: (s) => s == 200 || s == 304,
          ),
        )
        .timeout(const Duration(seconds: 15));
  }

  Future<Map<String, dynamic>> ask(Map<String, dynamic> request) async {
    await _ready();
    final response = await dio
        .post('/assistant/query', data: request)
        .timeout(const Duration(seconds: 15));
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }
}
