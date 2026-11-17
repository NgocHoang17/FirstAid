import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Original decorative learning artwork, without clinical procedures.
class MedicalEmblem extends StatelessWidget {
  const MedicalEmblem({super.key});
  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: SizedBox(
      width: 110,
      height: 150,
      child: CustomPaint(painter: _LearningPainter()),
    ),
  );
}

class _LearningPainter extends CustomPainter {
  const _LearningPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 140, size.height / 180);
    final fill = Paint();
    void rect(double x, double y, double w, double h, Color c, double r) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
        fill..color = c,
      );
    }

    canvas.drawCircle(
      const Offset(70, 86),
      65,
      fill..color = AppColors.accent.withValues(alpha: .16),
    );
    rect(8, 34, 85, 112, AppColors.onPrimary.withValues(alpha: .2), 12);
    rect(15, 28, 85, 112, AppColors.surface, 12);
    rect(24, 39, 36, 7, AppColors.accent, 3);
    for (var i = 0; i < 4; i++) {
      rect(24, 63 + i * 12, 55 - i * 5, 4, AppColors.tint, 2);
    }
    rect(24, 117, 42, 8, AppColors.primary, 4);
    final pen = Paint()
      ..color = AppColors.primaryDark
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(97, 124), const Offset(90, 160), pen);
    canvas.drawLine(const Offset(113, 124), const Offset(124, 160), pen);
    canvas.drawCircle(
      const Offset(106, 58),
      13,
      fill..color = const Color(0xFFF3C7A8),
    );
    rect(92, 75, 31, 52, AppColors.accent, 12);
    canvas.drawLine(
      const Offset(96, 84),
      const Offset(78, 102),
      Paint()
        ..color = const Color(0xFFF3C7A8)
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    final shield = Path()
      ..moveTo(79, 100)
      ..lineTo(110, 110)
      ..lineTo(108, 133)
      ..quadraticBezierTo(103, 148, 94, 154)
      ..quadraticBezierTo(81, 145, 79, 132)
      ..close();
    canvas.drawPath(shield, fill..color = AppColors.surface);
    canvas.drawLine(
      const Offset(87, 126),
      const Offset(101, 126),
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(94, 119),
      const Offset(94, 133),
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    rect(29, 158, 43, 6, AppColors.accent.withValues(alpha: .4), 3);
  }

  @override
  bool shouldRepaint(covariant _LearningPainter oldDelegate) => false;
}
