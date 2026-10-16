import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shadow.dart';

/// Card liên hệ khẩn cấp trực tiếp (GỌI 115 + Báo người thân)
class AppEmergencyContact extends StatelessWidget {
  final VoidCallback onCall115;
  final VoidCallback onNotifyFamily;

  const AppEmergencyContact({
    super.key,
    required this.onCall115,
    required this.onNotifyFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: appCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          // Header: tiêu đề + chấm xanh "Miễn phí 115"
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Liên hệ khẩn cấp trực tiếp',
                style: AppTextStyles.sectionTitle16,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: ShapeDecoration(
                      color: AppColors.free115Green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Miễn phí 115',
                    style: AppTextStyles.free115,
                  ),
                ],
              ),
            ],
          ),

          // Nút GỌI 115 + Báo người thân
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  decoration: ShapeDecoration(
                    color: AppColors.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onCall115,
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'GỌI 115',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                                height: 1.50,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 56,
                padding: const EdgeInsets.only(left: 8.48, right: 8.50),
                decoration: ShapeDecoration(
                  color: AppColors.secondaryBg,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 1,
                      color: AppColors.borderLight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onNotifyFamily,
                    child: const Center(
                      child: Text(
                        'Báo người thân',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          height: 1.50,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}