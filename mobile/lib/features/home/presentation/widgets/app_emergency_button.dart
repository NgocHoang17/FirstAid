import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Nút khẩn cấp lớn tròn đỏ "CẤP CỨU KHẨN CẤP"
class AppEmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AppEmergencyButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Vầng sáng đỏ nhạt phía sau nút
        Positioned(
          left: -12,
          top: -12,
          child: Container(
            width: 232,
            height: 232,
            decoration: ShapeDecoration(
              color: AppColors.emergencyGlow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ),

        // Nút chính tròn đỏ
        Container(
          width: 208,
          height: 208,
          padding: const EdgeInsets.all(8),
          decoration: ShapeDecoration(
            color: AppColors.primaryRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
            ),
            shadows: [
              BoxShadow(
                color: const Color(0x19000000),
                blurRadius: 10,
                offset: const Offset(0, 8),
                spreadRadius: -6,
              ),
              BoxShadow(
                color: const Color(0x19000000),
                blurRadius: 25,
                offset: const Offset(0, 20),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'CẤP CỨU\nKHẨN CẤP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}