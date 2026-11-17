import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/facilities/data/facility.dart';

void main() {
  test(
    'Expanded Da Nang catalogue loads every active facility and excludes pending entries',
    () {
      final data =
          jsonDecode(File('../data/facilities/danang.json').readAsStringSync())
              as Map;
      final records = data['records'] as List;
      final rows = [
        for (var index = 0; index < records.length; index++)
          {
            ...Map<String, dynamic>.from(records[index]['facility'] as Map),
            // The Admin API assigns real IDs. These IDs only emulate its response.
            'id':
                '00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
          },
      ];
      final facilities = Facility.parseList(rows);
      final activeRows = rows.where((row) => row['is_active'] == true).toList();
      expect(records.length, greaterThanOrEqualTo(70));
      expect(facilities.length, activeRows.length);
      expect(facilities.length, greaterThanOrEqualTo(60));
      expect(
        facilities.every(
          (facility) =>
              facility.region == 'VN-DN' &&
              facility.latitude.isFinite &&
              facility.longitude.isFinite &&
              DateTime.tryParse(facility.verifiedAt) != null,
        ),
        true,
      );
      for (final area in [
        'Hải Châu',
        'Thanh Khê',
        'Liên Chiểu',
        'Sơn Trà',
        'Ngũ Hành Sơn',
        'Cẩm Lệ',
        'Hòa Vang',
        'Hội An',
        'Tam Kỳ',
      ]) {
        expect(
          facilities.any(
            (facility) =>
                facility.name.toLowerCase().contains(area.toLowerCase()),
          ),
          true,
          reason: area,
        );
      }
      for (final row in rows.where((row) => row['is_active'] != true)) {
        expect(facilities.any((facility) => facility.id == row['id']), false);
      }
    },
  );
}
