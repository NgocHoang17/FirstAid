import '../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/content_update_cubit.dart';
import '../../first_aid/presentation/quick_aid_pages.dart';
import '../../../core/widgets/feature_widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const FeatureAppBar('Cài đặt và dữ liệu'),
    body: BlocBuilder<ContentUpdateCubit, ContentState>(
      builder: (context, state) {
        final busy =
            state.status == UpdateStatus.updating ||
            state.status == UpdateStatus.loading;
        final (title, message) = switch (state.status) {
          UpdateStatus.updating => (
            'Đang tải bản cập nhật…',
            'Giữ ứng dụng mở. Bộ hiện tại vẫn được giữ nguyên.',
          ),
          UpdateStatus.success => (
            'Cập nhật thành công',
            'Bộ nội dung mới đã được lưu trên thiết bị.',
          ),
          UpdateStatus.unchanged => (
            'Đã là bản mới nhất',
            'Bạn đang sử dụng phiên bản mới nhất từ máy chủ.',
          ),
          UpdateStatus.failed => (
            'Cập nhật chưa thành công',
            state.message ?? 'Hãy thử lại khi có mạng.',
          ),
          UpdateStatus.loading => (
            'Đang đọc dữ liệu…',
            'Đang mở bộ nội dung trên thiết bị.',
          ),
          UpdateStatus.idle => (
            'Tra cứu ngoại tuyến',
            'Bài hướng dẫn và nguồn đã lưu có thể đọc khi không có mạng.',
          ),
        };
        return ListView(
          padding: pagePadding,
          children: [
            const FeatureHeader('Dữ liệu ngoại tuyến'),
            sectionGap,
            AidCard(
              'Bộ nội dung trên thiết bị',
              'Phiên bản: ${state.version ?? 'Đang đọc…'}\nNgày phát hành: ${displayDate(state.generatedAt)}\nNgày tải: ${state.downloadedAt == null ? 'Đi kèm ứng dụng' : displayDate(state.downloadedAt)}\n${state.library?.categories.length ?? 0} nhóm • ${state.library?.articles.length ?? 0} bài',
              color: AppColors.tint,
            ),
            sectionGap,
            StatusCard(
              title,
              message,
              warning: state.status == UpdateStatus.failed,
              loading: busy,
            ),
            sectionGap,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy
                    ? null
                    : () => state.library == null
                          ? context.read<ContentUpdateCubit>().load()
                          : context.read<ContentUpdateCubit>().update(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    state.status == UpdateStatus.failed
                        ? 'Thử lại'
                        : busy
                        ? 'Đang xử lý…'
                        : 'Kiểm tra cập nhật',
                  ),
                ),
              ),
            ),
            sectionGap,
            if (state.library?.articles.any((a) => !a.isPublic) ?? false) ...[
              const StatusCard(
                'Nội dung đang rà soát',
                'Bản phát triển có các bài tham khảo chưa được duyệt để phát hành.',
                warning: true,
              ),
              sectionGap,
            ],
            const AidCard(
              'Thông tin ứng dụng',
              'FirstAid • Phiên bản 1.0.0\nĐồ án chuyên ngành\nKiến thức sơ cứu cho người lớn và trẻ em.',
            ),
          ],
        );
      },
    ),
  );
}
