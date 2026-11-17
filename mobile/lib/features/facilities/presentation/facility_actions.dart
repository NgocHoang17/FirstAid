import 'package:url_launcher/url_launcher.dart';
import '../data/facility.dart';

class ExternalActions {
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

Uri facilityDirectionsUri(Facility facility) => Uri.https(
  'www.google.com',
  '/maps/dir/',
  {'api': '1', 'destination': '${facility.latitude},${facility.longitude}'},
);
