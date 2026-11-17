import 'dart:convert';
import 'package:flutter/services.dart';

abstract final class BundledSnapshot {
  static Future<Map<String, dynamic>> load() async {
    final bytes = await rootBundle.load('assets/content/offline_snapshot.json');
    final text = utf8.decode(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    return jsonDecode(text) as Map<String, dynamic>;
  }
}
