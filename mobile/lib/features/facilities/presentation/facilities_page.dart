import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/facilities_cubit.dart';
import '../data/facility.dart';
import '../../../core/network/app_services.dart';
import '../../../core/storage/snapshot_store.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../first_aid/presentation/quick_aid_pages.dart';
import '../../settings/data/content_update_cubit.dart';

class ExternalActions {
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({
    required this.api,
    required this.store,
    this.onSettings,
    this.locationService,
    this.actions,
    super.key,
  });
  final PublicApi api;
  final SnapshotStore store;
  final VoidCallback? onSettings;
  final LocationService? locationService;
  final ExternalActions? actions;
  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  late final cubit = FacilitiesCubit(
    api: widget.api,
    store: widget.store,
    location: widget.locationService,
  )..loadLocal();
  String query = '';
  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<ContentUpdateCubit, ContentState>(
    listenWhen: (before, after) =>
        after.status == UpdateStatus.success && before.status != after.status,
    listener: (_, _) => cubit.loadLocal(),
    child: Scaffold(
      appBar: FeatureAppBar('Cơ sở y tế', onSettings: widget.onSettings),
      body: BlocBuilder<FacilitiesCubit, FacilityState>(
        bloc: cubit,
        builder: (context, state) {
          final items = state.ordered
              .where(
                (f) => searchKey(
                  '${f.name} ${f.address}',
                ).contains(searchKey(query.trim())),
              )
              .toList();
          final (locationTitle, locationMessage) = switch (state.issue) {
            LocationIssue.denied => (
              'Chưa được cấp vị trí',
              'Bạn vẫn có thể tìm cơ sở theo tên hoặc địa chỉ trong khu vực.',
            ),
            LocationIssue.permanentlyDenied => (
              'Quyền vị trí đang bị tắt',
              'Bạn có thể bật quyền trong cài đặt hoặc tiếp tục xem danh bạ.',
            ),
            LocationIssue.disabled => (
              'Dịch vụ vị trí đang tắt',
              'Bật vị trí trong cài đặt thiết bị để xem khoảng cách.',
            ),
            LocationIssue.unavailable => (
              'Chưa lấy được vị trí',
              'Thử lại sau. Danh bạ vẫn sử dụng được.',
            ),
            null => (
              'Đã có vị trí hiện tại',
              'Sắp xếp theo khoảng cách đường thẳng, không phải quãng đường di chuyển.',
            ),
          };
          return ListView(
            padding: pagePadding,
            key: const PageStorageKey('facilities'),
            children: [
              const FeatureHeader(
                'Tìm cơ sở y tế',
                subtitle: 'Danh bạ tham khảo • Không điều phối cấp cứu',
              ),
              sectionGap,
              OutlinedButton(
                onPressed: state.locating || state.refreshing
                    ? null
                    : cubit.locate,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    state.locating
                        ? 'Đang lấy vị trí…'
                        : 'Dùng vị trí hiện tại',
                  ),
                ),
              ),
              sectionGap,
              if (state.issue != null || state.location != null) ...[
                StatusCard(
                  locationTitle,
                  locationMessage,
                  warning: state.issue != null,
                  action:
                      state.issue == LocationIssue.permanentlyDenied ||
                          state.issue == LocationIssue.disabled
                      ? 'Mở cài đặt vị trí'
                      : null,
                  onAction: () async {
                    var opened = false;
                    try {
                      opened = await cubit.locationService.openSettings(
                        service: state.issue == LocationIssue.disabled,
                      );
                    } catch (_) {
                      /* Keep directory available. */
                    }
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Hãy mở phần Vị trí trong cài đặt thiết bị.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                sectionGap,
              ],
              const Text(
                'Khu vực',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(AppEnvironment.regionLabel),
              ),
              TextField(
                onChanged: (text) => setState(() => query = text),
                decoration: InputDecoration(
                  hintText: 'Tìm tên cơ sở hoặc địa chỉ…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              sectionGap,
              if (state.message != null) ...[
                StatusCard('Thông tin danh bạ', state.message!),
                sectionGap,
              ] else if (state.cached && state.items.isNotEmpty) ...[
                const StatusCard(
                  'Đang dùng dữ liệu đã lưu',
                  'Không thể xác nhận thông tin theo thời gian thực. Hãy gọi cơ sở trước khi đến.',
                ),
                sectionGap,
              ],
              if (state.loading)
                const StatusCard(
                  'Đang đọc danh bạ…',
                  'Đang mở dữ liệu trên thiết bị.',
                  loading: true,
                )
              else if (items.isEmpty)
                StatusCard(
                  state.items.isEmpty
                      ? 'Chưa có cơ sở trong khu vực'
                      : 'Không tìm thấy cơ sở',
                  state.items.isEmpty
                      ? 'Chưa có danh bạ đã xác minh trên thiết bị. Tải danh bạ khi có mạng hoặc gọi 115 nếu cần cấp cứu.'
                      : 'Thử tìm bằng tên hoặc địa chỉ khác.',
                ),
              for (final item in items) ...[
                AidCard(
                  item.name,
                  '${item.address}\n24/7: ${item.hoursLabel} • Xác minh: ${displayDate(item.verifiedAt)}${state.location == null ? '' : '\nKhoảng cách đường thẳng: ${item.distanceFrom(state.location!.latitude, state.location!.longitude).toStringAsFixed(1)} km'}',
                  onTap: () => openPage(
                    context,
                    FacilityDetailPage(facility: item, actions: widget.actions),
                  ),
                ),
                sectionGap,
              ],
              sectionGap,
              FilledButton(
                onPressed: state.refreshing || state.locating || state.loading
                    ? null
                    : cubit.refresh,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    state.refreshing ? 'Đang tải danh bạ…' : 'Tải lại danh bạ',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class FacilityDetailPage extends StatefulWidget {
  const FacilityDetailPage({required this.facility, this.actions, super.key});
  final Facility facility;
  final ExternalActions? actions;
  @override
  State<FacilityDetailPage> createState() => _FacilityDetailPageState();
}

class _FacilityDetailPageState extends State<FacilityDetailPage> {
  bool opening = false;
  String? fallback;
  Future<void> open(bool map) async {
    if (opening) return;
    setState(() {
      opening = true;
      fallback = null;
    });
    final f = widget.facility;
    final uri = map
        ? Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': '${f.latitude},${f.longitude}',
          })
        : Uri(scheme: 'tel', path: f.phone.replaceAll(RegExp(r'[^+0-9]'), ''));
    final success = await (widget.actions ?? ExternalActions()).open(uri);
    if (mounted) {
      setState(() {
        opening = false;
        fallback = success
            ? null
            : map
            ? 'Không mở được bản đồ. Địa chỉ: ${f.address}'
            : 'Không mở được ứng dụng gọi. Số điện thoại: ${f.phone}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.facility;
    return Scaffold(
      appBar: const FeatureAppBar('Thông tin cơ sở'),
      body: ListView(
        padding: pagePadding,
        children: [
          FeatureHeader(f.name),
          sectionGap,
          AidCard('Địa chỉ', f.address),
          sectionGap,
          AidCard('Điện thoại', f.phone),
          sectionGap,
          AidCard('Hoạt động 24/7', f.hoursLabel),
          sectionGap,
          AidCard(
            'Ngày xác minh',
            '${displayDate(f.verifiedAt)}\n${f.json['verification_note']}',
          ),
          sectionGap,
          const StatusCard(
            'Liên hệ trước khi đến',
            'Thông tin có thể thay đổi. Danh bạ không xác nhận cơ sở đang nhận bệnh hoặc điều phối cấp cứu.',
          ),
          sectionGap,
          if (fallback != null) ...[
            SelectableText(fallback!),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: '${f.name}\n${f.address}\n${f.phone}'),
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
            sectionGap,
          ],
          FilledButton(
            onPressed: opening ? null : () => open(false),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Gọi cơ sở'),
            ),
          ),
          sectionGap,
          OutlinedButton(
            onPressed: opening ? null : () => open(true),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Mở bản đồ'),
            ),
          ),
        ],
      ),
    );
  }
}
