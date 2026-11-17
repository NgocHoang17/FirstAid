import 'package:flutter/material.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../data/reference_content_repository.dart';

class StepGallery extends StatefulWidget {
  const StepGallery({required this.step, super.key});
  final ReferenceStep step;
  @override
  State<StepGallery> createState() => _StepGalleryState();
}

class _StepGalleryState extends State<StepGallery> {
  int current = 0;
  @override
  void didUpdateWidget(covariant StepGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.json['id'] != widget.step.json['id'] ||
        oldWidget.step.images.length != widget.step.images.length ||
        oldWidget.step.json['image_layout'] !=
            widget.step.json['image_layout'] ||
        current >= widget.step.images.length) {
      current = 0;
    }
  }

  Widget picture(Map<String, dynamic> image) {
    final path = image['url'] as String? ?? '';
    final base = Uri.tryParse(AppEnvironment.apiBaseUrl);
    final valid = RegExp(r'^/api/v1/media/[a-f0-9-]{36}$').hasMatch(path);
    final url = valid && base != null && base.hasAuthority
        ? base.resolve(path).toString()
        : '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: url.isEmpty
            ? unavailable()
            : Image.network(
                url,
                fit: BoxFit.contain,
                cacheWidth: 1200,
                semanticLabel: image['alt_text'] as String? ?? 'Ảnh hướng dẫn',
                errorBuilder: (_, _, _) => unavailable(),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }

  Widget unavailable() => const ColoredBox(
    color: AppColors.tint,
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Chưa tải được ảnh.\nBạn vẫn có thể đọc hướng dẫn bằng chữ.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
  Widget caption(Map<String, dynamic> image) =>
      (image['caption'] as String? ?? '').isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            image['caption'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        );
  @override
  Widget build(BuildContext context) {
    final images = widget.step.images;
    if (images.isEmpty) return const SizedBox.shrink();
    final layout = widget.step.json['image_layout'] as String? ?? 'stacked';
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: layout == 'carousel' && images.length > 1
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: PageView.builder(
                    key: ValueKey('${widget.step.json['id']}-${images.length}'),
                    itemCount: images.length,
                    onPageChanged: (value) => setState(() => current = value),
                    itemBuilder: (_, i) => picture(images[i]),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ảnh ${current + 1}/${images.length} · Vuốt để xem',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
                caption(images[current]),
              ],
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final grid =
                    layout == 'grid' &&
                    constraints.maxWidth >= 260 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 24;
                return Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    for (final image in images)
                      SizedBox(
                        width: grid
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [picture(image), caption(image)],
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
