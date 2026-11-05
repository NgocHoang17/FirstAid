import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/network/app_services.dart';
import '../../../core/storage/snapshot_store.dart';
import 'facility.dart';

enum LocationIssue { denied, permanentlyDenied, disabled, unavailable }

class LocationFailure implements Exception {
  LocationFailure(this.issue);
  final LocationIssue issue;
}

class UserLocation {
  const UserLocation(this.latitude, this.longitude);
  final double latitude, longitude;
}

class LocationService {
  Future<UserLocation> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationFailure(LocationIssue.disabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationFailure(LocationIssue.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure(LocationIssue.permanentlyDenied);
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw LocationFailure(LocationIssue.unavailable);
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
    return UserLocation(position.latitude, position.longitude);
  }

  Future<bool> openSettings({bool service = false}) => service
      ? Geolocator.openLocationSettings()
      : Geolocator.openAppSettings();
}

class FacilityState {
  const FacilityState({
    this.items = const [],
    this.loading = true,
    this.refreshing = false,
    this.locating = false,
    this.location,
    this.issue,
    this.message,
    this.cached = true,
  });
  final List<Facility> items;
  final bool loading, refreshing, locating, cached;
  final UserLocation? location;
  final LocationIssue? issue;
  final String? message;
  List<Facility> get ordered {
    final result = [...items];
    final point = location;
    if (point != null) {
      result.sort(
        (a, b) => a
            .distanceFrom(point.latitude, point.longitude)
            .compareTo(b.distanceFrom(point.latitude, point.longitude)),
      );
    }
    return result;
  }
}

class FacilitiesCubit extends Cubit<FacilityState> {
  FacilitiesCubit({
    required this.api,
    required this.store,
    LocationService? location,
  }) : locationService = location ?? LocationService(),
       super(const FacilityState());
  final PublicApi api;
  final SnapshotStore store;
  final LocationService locationService;
  Future<void> loadLocal() async {
    try {
      final cached = await store.readFacilities(AppEnvironment.regionCode);
      final snapshot = cached == null ? await store.read() : null;
      final rows = cached != null
          ? jsonDecode(cached) as List
          : snapshot != null
          ? (jsonDecode(snapshot) as Map)['facilities'] as List
          : <dynamic>[];
      final items = Facility.parseList(
        rows,
      ).where((f) => f.region == AppEnvironment.regionCode).toList();
      if (!isClosed) {
        emit(
          FacilityState(items: items, loading: false, location: state.location),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          FacilityState(
            items: state.items,
            loading: false,
            location: state.location,
            message:
                'Chưa đọc được danh bạ đã lưu. Bạn có thể tải lại khi có mạng.',
          ),
        );
      }
    }
  }

  Future<void> refresh() async {
    if (state.refreshing || state.locating) return;
    final before = state;
    emit(
      FacilityState(
        items: before.items,
        loading: false,
        refreshing: true,
        location: before.location,
        issue: before.issue,
      ),
    );
    try {
      final response = await api.get(
        '/facilities',
        query: {'region_code': AppEnvironment.regionCode},
      );
      final rows = (response.data as Map)['data']['items'] as List;
      final items = Facility.parseList(rows);
      if (items.length > 100 ||
          items.any((f) => f.region != AppEnvironment.regionCode)) {
        throw const FormatException('Invalid directory scope');
      }
      var saved = true;
      try {
        await store.replaceFacilities(
          AppEnvironment.regionCode,
          jsonEncode(rows),
        );
      } catch (_) {
        saved = false;
      }
      if (!isClosed) {
        emit(
          FacilityState(
            items: items,
            loading: false,
            location: before.location,
            issue: before.issue,
            cached: false,
            message: saved
                ? 'Danh bạ đã được cập nhật và lưu trên thiết bị.'
                : 'Đã tải danh bạ nhưng chưa lưu được trên thiết bị. Hãy thử tải lại.',
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          FacilityState(
            items: before.items,
            loading: false,
            location: before.location,
            issue: before.issue,
            message: error is OfflineException
                ? 'Bạn đang ngoại tuyến. Đang dùng danh bạ đã lưu.'
                : 'Chưa tải được danh bạ. Bạn vẫn có thể xem dữ liệu đã lưu và thử lại.',
          ),
        );
      }
    }
  }

  Future<void> locate() async {
    if (state.locating || state.refreshing) return;
    final before = state;
    emit(
      FacilityState(
        items: before.items,
        loading: false,
        locating: true,
        cached: before.cached,
        location: before.location,
      ),
    );
    UserLocation? point;
    LocationIssue? issue;
    try {
      point = await locationService.current();
    } on LocationFailure catch (error) {
      issue = error.issue;
    } catch (_) {
      issue = LocationIssue.unavailable;
    }
    if (!isClosed) {
      emit(
        FacilityState(
          items: state.items,
          loading: false,
          location: point ?? before.location,
          issue: issue,
          cached: before.cached,
        ),
      );
    }
  }
}
