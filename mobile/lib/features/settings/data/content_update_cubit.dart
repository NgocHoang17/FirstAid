import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../first_aid/data/reference_content_repository.dart';
import '../../../core/network/app_services.dart';
import '../../../core/storage/snapshot_store.dart';
import '../../../core/storage/bundled_snapshot.dart';

enum UpdateStatus { idle, loading, updating, unchanged, success, failed }

class ContentState {
  const ContentState({
    this.library,
    this.version,
    this.generatedAt,
    this.downloadedAt,
    this.status = UpdateStatus.loading,
    this.message,
  });
  final ReferenceLibrary? library;
  final String? version, generatedAt, downloadedAt, message;
  final UpdateStatus status;
}

class ContentUpdateCubit extends Cubit<ContentState> {
  ContentUpdateCubit({PublicApi? api, SnapshotStore? store})
    : api = api ?? PublicApi(),
      store = store ?? SqliteSnapshotStore.instance,
      super(const ContentState());
  final PublicApi api;
  final SnapshotStore store;
  Future<void> load() async {
    try {
      Map<String, dynamic>? saved;
      try {
        final text = await store.read();
        if (text != null) saved = jsonDecode(text) as Map<String, dynamic>;
        if (saved != null) validateSnapshot(saved);
      } catch (_) {
        saved = null;
      }
      final data = saved ?? await BundledSnapshot.load();
      final library =
          saved == null &&
              (data['schema_version'] == 1 ||
                  data.containsKey('region_code')) &&
              data['region_code'] != AppEnvironment.regionCode
          ? ReferenceLibrary.fromSnapshot({...data, 'facilities': <dynamic>[]})
          : validateSnapshot(data);
      if (saved == null && data['region_code'] == AppEnvironment.regionCode) {
        try {
          await store.replace(jsonEncode(data));
        } catch (_) {
          // The validated shipped data remains readable if storage is unavailable.
        }
      }
      if (!isClosed) {
        emit(
          ContentState(
            library: library,
            version: data['data_version'] as String?,
            generatedAt: data['generated_at'] as String?,
            downloadedAt: data['_downloaded_at'] as String?,
            status: UpdateStatus.idle,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          const ContentState(
            status: UpdateStatus.failed,
            message: 'Không tải được dữ liệu trên thiết bị. Hãy thử lại.',
          ),
        );
      }
    }
  }

  static ReferenceLibrary validateSnapshot(Map<String, dynamic> data) {
    if (![1, 2].contains(data['schema_version'])) {
      throw const FormatException('Unsupported snapshot schema');
    }
    if ((data['data_version'] as String? ?? '').isEmpty ||
        DateTime.tryParse(data['generated_at'] as String? ?? '') == null ||
        ((data['schema_version'] == 1 || data.containsKey('region_code')) &&
            data['region_code'] != AppEnvironment.regionCode)) {
      throw const FormatException('Invalid snapshot metadata');
    }
    final config = data['app_config'] as Map;
    if (config['locale'] != 'vi-VN' || config['emergency_number'] != '115') {
      throw const FormatException('Unsupported local configuration');
    }
    // V1 directory fields are ignored; they are outside the education scope.
    if (data['schema_version'] == 1) data['facilities'] = <dynamic>[];
    return ReferenceLibrary.fromSnapshot(data);
  }

  Future<void> update() async {
    if (state.status == UpdateStatus.updating || state.library == null) return;
    final before = state;
    emit(
      ContentState(
        library: before.library,
        version: before.version,
        generatedAt: before.generatedAt,
        downloadedAt: before.downloadedAt,
        status: UpdateStatus.updating,
      ),
    );
    try {
      final response = await api.get(
        '/offline-snapshot',
        query: {
          'region_code': AppEnvironment.regionCode,
          if (const bool.fromEnvironment('FIRSTAID_SNAPSHOT_V2'))
            'schema_version': 2,
        },
        headers: {
          if (before.downloadedAt != null)
            'If-None-Match': '"${before.version}"',
        },
      );
      if (response.statusCode == 304) {
        if (before.downloadedAt == null) {
          throw const FormatException('No downloaded snapshot');
        }
        if (isClosed) return;
        emit(
          ContentState(
            library: before.library,
            version: before.version,
            generatedAt: before.generatedAt,
            downloadedAt: before.downloadedAt,
            status: UpdateStatus.unchanged,
          ),
        );
        return;
      }
      final data = Map<String, dynamic>.from(
        (response.data as Map)['data'] as Map,
      );
      final library = validateSnapshot(data);
      final etag = response.headers.value('etag');
      if (etag != null && etag != '"${data['data_version']}"') {
        throw const FormatException('Snapshot version does not match ETag');
      }
      final downloaded = DateTime.now().toUtc().toIso8601String();
      data['_downloaded_at'] = downloaded;
      await store.replace(jsonEncode(data));
      if (!isClosed) {
        emit(
          ContentState(
            library: library,
            version: data['data_version'] as String,
            generatedAt: data['generated_at'] as String,
            downloadedAt: downloaded,
            status: UpdateStatus.success,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          ContentState(
            library: before.library,
            version: before.version,
            generatedAt: before.generatedAt,
            downloadedAt: before.downloadedAt,
            status: UpdateStatus.failed,
            message: error is FormatException
                ? 'Bản dữ liệu chưa tương thích. Cập nhật ứng dụng hoặc thử lại sau. Nội dung hiện tại vẫn được giữ.'
                : 'Chưa thể cập nhật. Kiểm tra kết nối và thử lại; nội dung hiện tại vẫn được giữ.',
          ),
        );
      }
    }
  }
}
