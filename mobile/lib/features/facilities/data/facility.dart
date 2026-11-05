import 'dart:math' as math;

class Facility {
  Facility(this.json);
  final Map<String, dynamic> json;
  String get id => json['id'] as String;
  String get name => json['name'] as String;
  String get address => json['address'] as String;
  String get region => json['region_code'] as String;
  String get phone => json['phone'] as String;
  double get latitude => (json['latitude'] as num).toDouble();
  double get longitude => (json['longitude'] as num).toDouble();
  String get verifiedAt => json['verified_at'] as String;
  String get hoursLabel => switch (json['emergency_24h']) {
    'YES' => 'Có',
    'NO' => 'Không',
    _ => 'Chưa rõ',
  };
  static List<Facility> parseList(List<dynamic> rows) {
    final ids = <String>{};
    final result = <Facility>[];
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      if (row['is_active'] != true) continue;
      final f = Facility(row);
      if (!ids.add(f.id) ||
          f.id.isEmpty ||
          f.name.trim().isEmpty ||
          f.address.trim().isEmpty ||
          f.region.isEmpty ||
          !RegExp(r'^\+?[0-9 ()-]{3,25}$').hasMatch(f.phone) ||
          !f.latitude.isFinite ||
          !f.longitude.isFinite ||
          f.latitude.abs() > 90 ||
          f.longitude.abs() > 180 ||
          DateTime.tryParse(f.verifiedAt) == null ||
          (row['verification_note'] as String? ?? '').trim().isEmpty ||
          !{'YES', 'NO', 'UNKNOWN'}.contains(row['emergency_24h'])) {
        throw const FormatException('Invalid verified facility');
      }
      result.add(f);
    }
    return result;
  }

  double distanceFrom(double lat, double lon) {
    double radians(double x) => x * math.pi / 180;
    final dLat = radians(latitude - lat), dLon = radians(longitude - lon);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(radians(lat)) *
            math.cos(radians(latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 6371 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
  }
}
