import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Helper tạo ShapeDecoration chuẩn cho card trắng + viền + shadow 
ShapeDecoration appCardDecoration() {
  return ShapeDecoration(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      side: const BorderSide(
        width: 1,
        color: AppColors.borderLight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    shadows: [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 2,
        offset: const Offset(0, 1),
        spreadRadius: 0,
      ),
    ],
  );
}

/// Helper tạo ShapeDecoration cho nútSecondary (Sao chép, HỦY BỎ, v.v.)
ShapeDecoration appSecondaryButtonDecoration() {
  return ShapeDecoration(
    color: AppColors.secondaryBg,
    shape: RoundedRectangleBorder(
      side: const BorderSide(
        width: 1,
        color: AppColors.borderLight,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    shadows: [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 2,
        offset: const Offset(0, 1),
        spreadRadius: 0,
      ),
    ],
  );
}