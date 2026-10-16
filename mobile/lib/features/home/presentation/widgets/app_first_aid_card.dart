import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shadow.dart';

/// Card phác sơ cứu tức thì
class AppFirstAidCard extends StatelessWidget {
  final Color iconBgColor;
  final Color labelColor;
  final String labelText;
  final String title;
  final String description;

  const AppFirstAidCard({
    super.key,
    required this.iconBgColor,
    required this.labelColor,
    required this.labelText,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: appCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon + nhãn
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: ShapeDecoration(
                    color: iconBgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: ShapeDecoration(
                    color: labelColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labelText,
                        style: AppTextStyles.statusLabel,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6.88),

            // Nội dung: title + description
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 141,
                  child: Text(
                    title,
                    style: AppTextStyles.firstAidTitle,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 141,
                  child: Text(
                    description,
                    style: AppTextStyles.firstAidDesc.copyWith(
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}