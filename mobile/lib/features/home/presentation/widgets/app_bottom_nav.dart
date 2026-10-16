import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Bottom navigation bar 5 mục 
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  static const List<String> _labels = [
    'Khẩn cấp',
    'Cấp cứu',
    'Trợ lý AI',
    'Bản đồ 115',
    'Cẩm nang',
  ];

  static const List<IconData> _icons = [
    Icons.warning_amber_rounded,
    Icons.medical_services,
    Icons.smart_toy,
    Icons.map,
    Icons.book,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xE5FAF8FF),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F0F172A),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_labels.length, (index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onItemTapped(index),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      _icons[index],
                      color: isSelected
                          ? AppColors.primaryRed
                          : AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _labels[index],
                      style: AppTextStyles.bottomNavLabel.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: -6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        shadows: [
                          BoxShadow(
                            color: const Color(0xFFFAF8FF),
                            blurRadius: 0,
                            offset: const Offset(0, 0),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}