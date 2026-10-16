import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Brand name "FirstAid"
  static const TextStyle brandName = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.45,
    color: AppColors.primaryRed,
  );

  // Nút khẩn cấp lớn "CẤP CỨU KHẨN CẤP"
  static const TextStyle emergencyBig = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.25,
    letterSpacing: -0.55,
    color: Colors.white,
  );

  // Tiêu đề section 18px
  static const TextStyle sectionTitle18 = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.33,
    color: AppColors.textPrimary,
  );

  // Tiêu đề section 16px (Liên hệ khẩn cấp trực tiếp)
  static const TextStyle sectionTitle16 = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.50,
    color: AppColors.textPrimary,
  );

  // Tên địa chỉ chính
  static const TextStyle locationValue = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  // Tên phác sơ cứu (Ngừng tim / Đột quy...)
  static const TextStyle firstAidTitle = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  // Nút "GỌI 115"
  static const TextStyle call115Button = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.50,
    color: Colors.white,
  );

  // Nút "Báo người thân"
  static const TextStyle notifyButton = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.50,
    color: AppColors.textPrimary,
  );

  // Mô tả phác sơ cứu (Ép tim CPR 110 BPM...)
  static const TextStyle firstAidDesc = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.50,
    color: AppColors.primaryRed,
  );

  // Nhãn trạng thái (TỐI KHẨN, NGHẸT THỞ...)
  static const TextStyle statusLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.50,
    color: Colors.white,
  );

  // Chú thích nhỏ (Vị trí hiện tại, Sao chép, xem thêm...)
  static const TextStyle captionInter12 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.50,
    color: AppColors.textSecondary,
  );

  // Chạm nhầm
  static const TextStyle chamNhamTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.25,
    letterSpacing: 0.72,
    color: AppColors.chamNhamText,
  );

  // "Tự động gọi sau 5s"
  static const TextStyle chamNhamDesc = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.50,
    color: AppColors.textSecondary,
  );

  // Số đếm cham nham (5)
  static const TextStyle chamNhamCount = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.50,
    color: AppColors.primaryRed,
  );

  // Nút HỦY BỎ
  static const TextStyle cancelButton = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.43,
    color: AppColors.primaryRed,
  );

  // Bottom nav label
  static const TextStyle bottomNavLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: AppColors.textSecondary,
  );

  // "Miễn phí 115"
  static const TextStyle free115 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.50,
    color: AppColors.free115Green,
  );
}