import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shadow.dart';

/// Banner chạm nhầm với nút HỦY BỎ 
class AppAmbulanceBanner extends StatelessWidget {
  final int countdownSeconds;
  final VoidCallback onCancel;

  const AppAmbulanceBanner({
    super.key,
    this.countdownSeconds = 5,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 384),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: ShapeDecoration(
          color: AppColors.chamNhamBg,
          shape: RoundedRectangleBorder(
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
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Phần trái: badge số + text
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  child: Stack(
                    children: [
                      Container(
                        transform: Matrix4.identity()
                          ..translate(0.0, 0.0)
                          ..rotateZ(-1.57),
                        height: 28,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(),
                        child: Stack(),
                      ),
                      Positioned(
                        left: 10.30,
                        top: 5,
                        child: Text(
                          countdownSeconds.toString(),
                          style: AppTextStyles.chamNhamCount,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHẲM NHẦM?',
                      style: AppTextStyles.chamNhamTitle,
                    ),
                    const SizedBox(height: 1.5),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Tự động gọi sau ',
                            style: AppTextStyles.chamNhamDesc,
                          ),
                          TextSpan(
                            text: '${countdownSeconds}s',
                            style: AppTextStyles.chamNhamDesc.copyWith(
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Nút HỦY BỎ
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: appSecondaryButtonDecoration(),
              child: Center(
                child: Text(
                  'HỦY BỎ',
                  style: AppTextStyles.cancelButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}