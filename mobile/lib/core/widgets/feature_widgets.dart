import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

const pagePadding = EdgeInsets.all(24);
const sectionGap = SizedBox(height: 16);

class FeatureHeader extends StatelessWidget {
  const FeatureHeader(
    this.title, {
    this.subtitle,
    this.icon = Icons.health_and_safety_outlined,
    super.key,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.3,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryRaised,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: AppColors.onPrimaryMuted),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.onPrimaryMuted,
            ),
          ),
        ],
      ],
    ),
  );
}

class StatusCard extends StatelessWidget {
  const StatusCard(
    this.title,
    this.message, {
    this.warning = false,
    this.loading = false,
    this.action,
    this.onAction,
    super.key,
  });
  final String title, message;
  final bool warning, loading;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: warning ? AppColors.warning : AppColors.info,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: warning ? const Color(0xFFDDCBA3) : AppColors.border,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (loading) ...[const LinearProgressIndicator(), sectionGap],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              warning ? Icons.info_outline_rounded : Icons.info_outline_rounded,
              size: 22,
              color: warning ? AppColors.warningInk : AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(message),
        if (action != null) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ],
    ),
  );
}

class FeatureAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FeatureAppBar(this.title, {this.onSettings, super.key});
  final String title;
  final VoidCallback? onSettings;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    actions: [
      if (onSettings != null)
        IconButton(
          tooltip: 'Cài đặt và dữ liệu',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
    ],
  );
}

String displayDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) return 'Chưa có';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
