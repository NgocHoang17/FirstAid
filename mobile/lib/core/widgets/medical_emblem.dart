import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Decorative brand artwork; does not depict a medical procedure.
class MedicalEmblem extends StatelessWidget {
  const MedicalEmblem({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 104,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.onPrimary.withValues(alpha: .09),
              border: Border.all(
                color: AppColors.onPrimary.withValues(alpha: .18),
              ),
            ),
          ),
          Transform.rotate(
            angle: -.1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: .2),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                color: AppColors.primary,
                size: 48,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryRaised, width: 3),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppColors.primaryDark,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
