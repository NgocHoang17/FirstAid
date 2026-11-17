import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../data/facilities_cubit.dart';
import '../data/facility.dart';
import 'facility_actions.dart';

class FacilitiesMapView extends StatefulWidget {
  const FacilitiesMapView({
    required this.facilities,
    required this.network,
    required this.onShowList,
    this.location,
    this.actions,
    this.tileProvider,
    super.key,
  });
  final List<Facility> facilities;
  final NetworkStatus network;
  final UserLocation? location;
  final VoidCallback onShowList;
  final ExternalActions? actions;
  final TileProvider? tileProvider;

  @override
  State<FacilitiesMapView> createState() => _FacilitiesMapViewState();
}

class _FacilitiesMapViewState extends State<FacilitiesMapView>
    with WidgetsBindingObserver {
  final controller = MapController();
  StreamSubscription<bool>? subscription;
  bool? online;
  bool tileError = false;
  bool mapReady = false;
  int tileGeneration = 0;
  int connectivityGeneration = 0;

  List<Facility> get verified => widget.facilities
      .where((facility) => facility.hasVerifiedLocation)
      .toList();
  List<LatLng> get points => [
    for (final f in verified) LatLng(f.latitude, f.longitude),
    if (widget.location case final location?)
      LatLng(location.latitude, location.longitude),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    subscription = widget.network.changes.listen(
      (connected) {
        connectivityGeneration++;
        setConnection(connected);
      },
      onError: (Object _) {
        /* A tile failure still exposes retry/list actions. */
      },
    );
    checkConnection();
  }

  void setConnection(bool connected) {
    if (!mounted) return;
    setState(() {
      if (online != connected) {
        mapReady = false;
        tileError = false;
      }
      online = connected;
    });
  }

  Future<void> checkConnection() async {
    final generation = ++connectivityGeneration;
    bool connected;
    try {
      connected = await widget.network.isOnline();
    } catch (_) {
      connected = false;
    }
    if (mounted && generation == connectivityGeneration) {
      setConnection(connected);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkConnection();
    }
  }

  @override
  void didUpdateWidget(covariant FacilitiesMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.facilities
        .map((f) => '${f.id}:${f.json['latitude']}:${f.json['longitude']}')
        .toList();
    final current = widget.facilities
        .map((f) => '${f.id}:${f.json['latitude']}:${f.json['longitude']}')
        .toList();
    if (!listEquals(previous, current) ||
        oldWidget.location != widget.location) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && mapReady && online == true) fitAll();
      });
    }
  }

  void fitAll() {
    final coordinates = points;
    if (coordinates.isEmpty) return;
    controller.fitCamera(
      CameraFit.coordinates(
        coordinates: coordinates,
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 116),
        maxZoom: 15,
      ),
    );
  }

  void reportTileError() {
    if (!mounted || tileError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !tileError) setState(() => tileError = true);
    });
  }

  void openFacility(Facility facility) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          FacilityMapSheet(facility: facility, actions: widget.actions),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (online == null) {
      return const StatusCard(
        'Đang mở bản đồ…',
        'Đang kiểm tra kết nối mạng.',
        loading: true,
      );
    }
    if (online == false) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusCard(
            'Bản đồ cần kết nối mạng',
            'Bạn vẫn có thể xem tên, địa chỉ và số điện thoại trong danh sách đã lưu.',
            action: 'Xem danh sách đã lưu',
            onAction: widget.onShowList,
          ),
          TextButton(
            onPressed: checkConnection,
            child: const Text('Kiểm tra lại kết nối'),
          ),
        ],
      );
    }
    if (points.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${verified.length} cơ sở trên bản đồ • Chạm ghim để xem',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 360,
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCameraFit: CameraFit.coordinates(
                  coordinates: points,
                  padding: const EdgeInsets.fromLTRB(40, 40, 40, 116),
                  maxZoom: 15,
                ),
                minZoom: 3,
                maxZoom: 18,
                backgroundColor: AppColors.tint,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () {
                  mapReady = true;
                },
              ),
              children: [
                TileLayer(
                  key: ValueKey(tileGeneration),
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'vn.firstaid.course (https://github.com/NgocHoang17/FirstAid)',
                  tileProvider: widget.tileProvider,
                  maxNativeZoom: 19,
                  panBuffer: 0,
                  errorTileCallback: (_, _, _) => reportTileError(),
                ),
                MarkerLayer(
                  markers: [
                    for (final facility in verified)
                      Marker(
                        point: LatLng(facility.latitude, facility.longitude),
                        width: 48,
                        height: 48,
                        child: IconButton.filled(
                          key: ValueKey('facility-pin-${facility.id}'),
                          tooltip: facility.name,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          onPressed: () => openFacility(facility),
                          icon: const Icon(Icons.local_hospital_rounded),
                        ),
                      ),
                    if (widget.location case final location?)
                      Marker(
                        point: LatLng(location.latitude, location.longitude),
                        width: 28,
                        height: 28,
                        child: Semantics(
                          label: 'Vị trí vừa lấy của bạn',
                          child: Container(
                            key: const ValueKey('user-location-pin'),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A5EDB),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Always visible; never hide attribution behind a toggle or sheet control.
                Align(
                  alignment: Alignment.bottomRight,
                  child: Material(
                    color: AppColors.surface,
                    child: TextButton(
                      onPressed: () async {
                        final opened =
                            await (widget.actions ?? ExternalActions()).open(
                              Uri.parse(
                                'https://www.openstreetmap.org/copyright',
                              ),
                            );
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Thông tin bản quyền: openstreetmap.org/copyright',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: fitAll,
              icon: const Icon(Icons.fit_screen),
              label: const Text('Xem tất cả'),
            ),
            if (widget.location != null)
              OutlinedButton.icon(
                onPressed: () => controller.move(
                  LatLng(widget.location!.latitude, widget.location!.longitude),
                  15,
                ),
                icon: const Icon(Icons.my_location),
                label: const Text('Vị trí của tôi'),
              ),
          ],
        ),
        if (tileError) ...[
          const SizedBox(height: 12),
          StatusCard(
            'Chưa tải được nền bản đồ',
            'Kiểm tra kết nối hoặc tiếp tục xem danh sách đã lưu.',
            action: 'Xem danh sách đã lưu',
            onAction: widget.onShowList,
          ),
          TextButton(
            onPressed: () {
              setState(() {
                tileError = false;
                tileGeneration++;
              });
              checkConnection();
            },
            child: const Text('Thử tải lại bản đồ'),
          ),
        ],
      ],
    );
  }
}

class FacilityMapSheet extends StatefulWidget {
  const FacilityMapSheet({required this.facility, this.actions, super.key});
  final Facility facility;
  final ExternalActions? actions;
  @override
  State<FacilityMapSheet> createState() => _FacilityMapSheetState();
}

class _FacilityMapSheetState extends State<FacilityMapSheet> {
  bool opening = false;
  String? fallback;

  Future<void> open(bool directions) async {
    if (opening) return;
    setState(() {
      opening = true;
      fallback = null;
    });
    final facility = widget.facility;
    final uri = directions
        ? facilityDirectionsUri(facility)
        : Uri(
            scheme: 'tel',
            path: facility.phone.replaceAll(RegExp(r'[^+0-9]'), ''),
          );
    final success = await (widget.actions ?? ExternalActions()).open(uri);
    if (!mounted) return;
    setState(() {
      opening = false;
      if (!success) {
        fallback = directions
            ? 'Không mở được chỉ đường. Bạn có thể sao chép địa chỉ để tìm trong ứng dụng bản đồ.'
            : 'Không mở được ứng dụng gọi. Bạn có thể sao chép số điện thoại bên dưới.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.facility;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Đóng thông tin cơ sở',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              Text(f.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SelectableText(f.address),
              const SizedBox(height: 12),
              SelectableText('Điện thoại: ${f.phone}'),
              const SizedBox(height: 12),
              Text(
                'Cấp cứu 24/7: ${f.hoursLabel} • Xác minh: ${displayDate(f.verifiedAt)}',
              ),
              const SizedBox(height: 8),
              Text(f.json['verification_note'] as String),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: opening ? null : () => open(true),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Chỉ đường'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: opening ? null : () => open(false),
                icon: const Icon(Icons.call_outlined),
                label: const Text('Gọi cơ sở'),
              ),
              if (fallback != null) ...[
                const SizedBox(height: 12),
                Text(fallback!),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: '${f.name}\n${f.address}\n${f.phone}',
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép thông tin cơ sở.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Sao chép thông tin'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
