import 'package:dio/dio.dart';

class ApiClient {
  // Khi chạy máy ảo Android, dùng 10.0.2.2 để trỏ về localhost của máy tính chạy backend
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}