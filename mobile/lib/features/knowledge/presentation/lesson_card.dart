import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../first_aid/data/reference_content_repository.dart';
import '../../first_aid/presentation/quick_aid_pages.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({required this.article, required this.onTap, super.key});
  final ReferenceArticle article;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(16) > 24;
    final artwork = Container(
      width: large ? double.infinity : 82,
      height: large ? 88 : 96,
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 8,
            top: 8,
            child: Icon(
              Icons.add_rounded,
              color: AppColors.primary.withValues(alpha: .14),
              size: 20,
            ),
          ),
          Icon(
            situationIcon(article.categoryCode),
            color: AppColors.primary,
            size: 38,
          ),
        ],
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          article.ageLabel,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.accentInk,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          article.title,
          style: const TextStyle(
            fontSize: 17,
            height: 1.4,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          article.summary,
          maxLines: large ? null : 2,
          overflow: large ? null : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: large
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [artwork, const SizedBox(height: 16), details],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    artwork,
                    const SizedBox(width: 16),
                    Expanded(child: details),
                  ],
                ),
        ),
      ),
    );
  }
}
