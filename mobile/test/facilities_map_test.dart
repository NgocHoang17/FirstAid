import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/app_services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/facilities/data/facilities_cubit.dart';
import 'package:mobile/features/facilities/data/facility.dart';
import 'package:mobile/features/facilities/presentation/facilities_map_view.dart';
import 'package:mobile/features/facilities/presentation/facilities_page.dart';
import 'package:mobile/features/settings/data/content_update_cubit.dart';
import 'support/mobile_fakes.dart';

class LocalTiles extends TileProvider {
  @override
  ImageProvider getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) => MemoryImage(
    // One transparent pixel; tests exercise real map layout without a tile server.
    TileProvider.transparentImage,
  );
}

class ChangingNetwork extends NetworkStatus {
  bool online = true;
  final controller = StreamController<bool>.broadcast();
  @override
  Future<bool> isOnline() async => online;
  @override
  Stream<bool> get changes => controller.stream;
  void change(bool value) {
    online = value;
    controller.add(value);
  }
}

class BrokenTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(base64Decode('AQID'));
}

void main() {
  final first = Facility(testFacility()..['name'] = 'Cơ sở kiểm thử An Hải');
  final second = Facility(
    testFacility(id: '00000000-0000-4000-8000-000000000402', latitude: 16.07)
      ..['name'] = 'Cơ sở kiểm thử Hải Châu',
  );

  Future<void> pumpMap(
    WidgetTester tester, {
    required NetworkStatus network,
    List<Facility>? items,
    UserLocation? location,
    VoidCallback? onShowList,
    ExternalActions? actions,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FacilitiesMapView(
              facilities: items ?? [first, second],
              network: network,
              location: location,
              tileProvider: LocalTiles(),
              actions: actions,
              onShowList: onShowList ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('A new location failure clears the old location', () async {
    final location = FakeLocation();
    final cubit = FacilitiesCubit(
      api: FakeApi(),
      store: MemoryStore(),
      location: location,
    );
    addTearDown(cubit.close);
    await cubit.loadLocal();
    await cubit.locate();
    expect(cubit.state.location, isNotNull);
    location.issue = LocationIssue.permanentlyDenied;
    await cubit.locate();
    expect(cubit.state.location, isNull);
    expect(cubit.state.issue, LocationIssue.permanentlyDenied);
  });

  testWidgets('Tile errors provide retry and saved-list actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FacilitiesMapView(
              facilities: [first],
              network: FakeNetwork(),
              tileProvider: BrokenTiles(),
              onShowList: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa tải được nền bản đồ'), findsOneWidget);
    expect(find.text('Thử tải lại bản đồ'), findsOneWidget);
    expect(find.text('Xem danh sách đã lưu'), findsOneWidget);
    expect(find.byKey(ValueKey('facility-pin-${first.id}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Verified pins open facility information and directions with a fallback',
    (tester) async {
      final actions = FailedActions();
      await pumpMap(
        tester,
        network: FakeNetwork(),
        actions: actions,
        items: [
          first,
          second,
          Facility(testFacility(id: 'inactive')..['is_active'] = false),
          Facility(testFacility(id: 'unchecked')..['verified_at'] = null),
          Facility(testFacility(id: 'invalid')..['latitude'] = 100),
        ],
      );
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
        2,
      );
      expect(find.byKey(const ValueKey('user-location-pin')), findsNothing);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('facility-pin-${first.id}')));
      await tester.pumpAndSettle();
      expect(find.text(first.name), findsOneWidget);
      expect(find.text(first.address), findsOneWidget);
      expect(find.text('Điện thoại: ${first.phone}'), findsOneWidget);
      await tester.tap(find.text('Chỉ đường'));
      await tester.pumpAndSettle();
      expect(actions.opened.single.path, '/maps/dir/');
      expect(actions.opened.single.queryParameters, {
        'api': '1',
        'destination': '${first.latitude},${first.longitude}',
      });
      expect(find.textContaining('Không mở được chỉ đường.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Network loss removes tiles and offers saved list; reconnect restores map',
    (tester) async {
      final network = ChangingNetwork();
      addTearDown(network.controller.close);
      var listRequested = false;
      await pumpMap(
        tester,
        network: network,
        onShowList: () => listRequested = true,
      );
      network.change(false);
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Bản đồ cần kết nối mạng'), findsOneWidget);
      await tester.tap(find.text('Xem danh sách đã lưu'));
      expect(listRequested, true);
      network.change(true);
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
        2,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Updated directory removes stale pins and no-result map is empty',
    (tester) async {
      final network = FakeNetwork();
      await pumpMap(tester, network: network);
      await pumpMap(tester, network: network, items: [second]);
      expect(find.byKey(ValueKey('facility-pin-${first.id}')), findsNothing);
      expect(find.byKey(ValueKey('facility-pin-${second.id}')), findsOneWidget);
      await pumpMap(tester, network: network, items: []);
      expect(find.byType(FlutterMap), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Map and facility sheet fit 320px at 200% text and show user location',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpMap(
        tester,
        network: FakeNetwork(),
        location: const UserLocation(16.06, 108.21),
      );
      expect(find.byKey(const ValueKey('user-location-pin')), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('facility-pin-${first.id}')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Chỉ đường'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(FacilityMapSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'List/map share search and denied location never blocks the map',
    (tester) async {
      final store = MemoryStore()
        ..snapshot = jsonEncode({
          ...testSnapshot(),
          'facilities': [first.json, second.json],
        });
      final api = FakeApi();
      final content = ContentUpdateCubit(api: api, store: store);
      await content.load();
      addTearDown(content.close);
      final location = FakeLocation()..issue = LocationIssue.denied;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider.value(
            value: content,
            child: FacilitiesPage(
              api: api,
              store: store,
              locationService: location,
              mapTileProvider: LocalTiles(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(location.requests, 0);
      await tester.enterText(find.byType(TextField), 'An Hai');
      await tester.ensureVisible(find.text('Dùng vị trí hiện tại'));
      await tester.tap(find.text('Dùng vị trí hiện tại'));
      await tester.pumpAndSettle();
      expect(location.requests, 1);
      expect(find.text('Chưa được cấp vị trí'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'An Hai',
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Bản đồ'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Bản đồ'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(FlutterMap),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
        1,
      );
      expect(find.byKey(const ValueKey('user-location-pin')), findsNothing);
      await tester.ensureVisible(find.text('Danh sách'));
      await tester.tap(find.text('Danh sách'));
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text(first.name), findsOneWidget);
      expect(find.text(second.name), findsNothing);
      expect(store.snapshot, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
}
