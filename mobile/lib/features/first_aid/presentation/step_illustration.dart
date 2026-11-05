import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../data/reference_content_repository.dart';

/// Original vector reminder diagrams. The adjacent instructions define the
/// actual procedure; these symbols never supply an anatomical position or dose.
class StepIllustration extends StatefulWidget {
  const StepIllustration({required this.step, super.key});
  final ReferenceStep step;
  @override
  State<StepIllustration> createState() => _StepIllustrationState();
}

class _StepIllustrationState extends State<StepIllustration> {
  late Future<Map<String, dynamic>?> diagram = load();
  Future<Map<String, dynamic>?> load() async {
    final asset = widget.step.assetKey;
    if (asset == null ||
        !RegExp(r'^assets/illustrations/[a-z_]+\.json$').hasMatch(asset)) {
      return null;
    }
    try {
      final data =
          jsonDecode(await rootBundle.loadString(asset, cache: false))
              as Map<String, dynamic>;
      if (data['schema_version'] != 1 ||
          !ReminderPainter.kinds.contains(data['kind']) ||
          data['label'] is! String ||
          data['caption'] is! String) {
        return null;
      }
      return data;
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant StepIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.assetKey != widget.step.assetKey) diagram = load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: diagram,
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (data == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Semantics(
          image: true,
          label: '${data['label']}. ${widget.step.altText ?? data['caption']}',
          child: ExcludeSemantics(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 2.8,
                    child: CustomPaint(
                      painter: ReminderPainter(data['kind'] as String),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['caption'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ReminderPainter extends CustomPainter {
  const ReminderPainter(this.kind);
  final String kind;
  static const kinds = {
    'shield',
    'phone',
    'observe',
    'pressure',
    'cloth',
    'water',
    'clock',
    'pulse',
    'breathing',
    'aed',
    'sequence',
    'rescue',
    'pause',
    'cold',
    'electric',
    'cooling',
    'pillow',
    'stop',
    'medical',
    'information',
  };
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320, size.height / 114);
    final pen = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = AppColors.surface;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), pen);
    void box(double x, double y, double w, double h, {double radius = 12}) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(radius),
      );
      canvas.drawRRect(rect, fill);
      canvas.drawRRect(rect, pen);
    }

    void plus(double x, double y) {
      line(x - 10, y, x + 10, y);
      line(x, y - 10, x, y + 10);
    }

    void arrow(double x1, double y1, double x2, double y2) {
      line(x1, y1, x2, y2);
      final angle = math.atan2(y2 - y1, x2 - x1);
      for (final delta in [-.6, .6]) {
        line(
          x2,
          y2,
          x2 - 12 * math.cos(angle + delta),
          y2 - 12 * math.sin(angle + delta),
        );
      }
    }

    void wave() => canvas.drawPath(
      Path()
        ..moveTo(65, 60)
        ..lineTo(117, 60)
        ..lineTo(133, 39)
        ..lineTo(147, 83)
        ..lineTo(164, 24)
        ..lineTo(181, 60)
        ..lineTo(252, 60),
      pen,
    );
    switch (kind) {
      case 'phone':
        box(123, 8, 74, 98);
        line(148, 20, 172, 20);
        canvas.drawCircle(const Offset(160, 91), 3, pen);
        plus(160, 55);
      case 'shield':
        final path = Path()
          ..moveTo(160, 9)
          ..lineTo(203, 25)
          ..lineTo(197, 66)
          ..quadraticBezierTo(188, 92, 160, 105)
          ..quadraticBezierTo(132, 92, 123, 66)
          ..lineTo(117, 25)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, pen);
        plus(160, 52);
      case 'water':
        line(76, 23, 148, 23);
        line(125, 12, 125, 23);
        line(148, 23, 148, 42);
        line(132, 42, 164, 42);
        for (final x in [132.0, 148.0, 164.0]) {
          line(x, 53, x, 63);
          line(x, 74, x, 80);
        }
        canvas.drawPath(
          Path()
            ..moveTo(81, 94)
            ..quadraticBezierTo(108, 80, 135, 94)
            ..quadraticBezierTo(161, 108, 188, 94)
            ..quadraticBezierTo(214, 80, 241, 94),
          pen,
        );
        box(207, 25, 27, 47, radius: 6);
        line(214, 17, 227, 17);
      case 'pulse':
        wave();
      case 'breathing':
        line(160, 13, 160, 44);
        for (final direction in [-1, 1]) {
          canvas.drawPath(
            Path()
              ..moveTo(160, 43)
              ..cubicTo(
                160 + direction * 25,
                18,
                160 + direction * 63,
                26,
                160 + direction * 65,
                61,
              )
              ..cubicTo(
                160 + direction * 68,
                97,
                160 + direction * 18,
                104,
                160 + direction * 12,
                77,
              )
              ..lineTo(160 + direction * 12, 49),
            pen,
          );
        }
      case 'clock':
        canvas.drawCircle(const Offset(160, 57), 44, fill);
        canvas.drawCircle(const Offset(160, 57), 44, pen);
        line(160, 28, 160, 57);
        line(160, 57, 184, 72);
        for (final angle in [0.0, math.pi / 2, math.pi, math.pi * 1.5]) {
          line(
            160 + 35 * math.cos(angle),
            57 + 35 * math.sin(angle),
            160 + 40 * math.cos(angle),
            57 + 40 * math.sin(angle),
          );
        }
      case 'pressure':
        box(106, 65, 108, 30, radius: 7);
        line(119, 74, 201, 74);
        arrow(145, 14, 145, 52);
        arrow(176, 14, 176, 52);
      case 'cloth':
        box(110, 17, 100, 80, radius: 7);
        line(123, 34, 197, 34);
        line(123, 80, 197, 80);
        plus(160, 57);
      case 'aed':
        box(113, 16, 94, 84);
        canvas.drawPath(
          Path()
            ..moveTo(164, 31)
            ..lineTo(145, 59)
            ..lineTo(163, 59)
            ..lineTo(154, 84)
            ..lineTo(179, 50)
            ..lineTo(161, 50)
            ..close(),
          pen,
        );
        line(207, 49, 233, 49);
        box(235, 30, 21, 38, radius: 5);
      case 'sequence':
        for (final x in [92.0, 160.0, 228.0]) {
          canvas.drawCircle(Offset(x, 57), 20, fill);
          canvas.drawCircle(Offset(x, 57), 20, pen);
        }
        arrow(116, 57, 134, 57);
        arrow(184, 57, 202, 57);
        line(85, 57, 91, 64);
        line(91, 64, 102, 49);
        line(153, 57, 159, 64);
        line(159, 64, 170, 49);
      case 'rescue':
        canvas.drawCircle(const Offset(157, 52), 33, pen);
        canvas.drawCircle(const Offset(157, 52), 17, pen);
        line(134, 29, 145, 40);
        line(180, 29, 169, 40);
        line(134, 75, 145, 64);
        line(180, 75, 169, 64);
        canvas.drawPath(
          Path()
            ..moveTo(72, 100)
            ..quadraticBezierTo(116, 82, 160, 100)
            ..quadraticBezierTo(204, 118, 248, 100),
          pen,
        );
      case 'pause':
        box(130, 24, 18, 66, radius: 6);
        box(172, 24, 18, 66, radius: 6);
        line(98, 104, 222, 104);
      case 'cold':
        for (final angle in [0.0, math.pi / 3, math.pi * 2 / 3]) {
          line(
            160 - 40 * math.cos(angle),
            57 - 40 * math.sin(angle),
            160 + 40 * math.cos(angle),
            57 + 40 * math.sin(angle),
          );
        }
        box(101, 8, 118, 98, radius: 18);
      case 'electric':
        canvas.drawPath(
          Path()
            ..moveTo(167, 18)
            ..lineTo(141, 61)
            ..lineTo(164, 61)
            ..lineTo(153, 95)
            ..lineTo(187, 49)
            ..lineTo(165, 49)
            ..close(),
          pen,
        );
        canvas.drawCircle(const Offset(160, 57), 49, pen);
        line(125, 22, 195, 92);
      case 'cooling':
        canvas.drawCircle(const Offset(102, 38), 17, pen);
        for (final angle in [0.0, math.pi / 2, math.pi, math.pi * 1.5]) {
          line(
            102 + 23 * math.cos(angle),
            38 + 23 * math.sin(angle),
            102 + 32 * math.cos(angle),
            38 + 32 * math.sin(angle),
          );
        }
        for (final y in [47.0, 66.0, 85.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(151, y)
              ..quadraticBezierTo(177, y - 13, 204, y)
              ..quadraticBezierTo(229, y + 13, 252, y),
            pen,
          );
        }
      case 'pillow':
        box(109, 49, 102, 52, radius: 18);
        canvas.drawCircle(const Offset(160, 44), 25, fill);
        canvas.drawCircle(const Offset(160, 44), 25, pen);
      case 'stop':
        canvas.drawCircle(const Offset(160, 57), 43, fill);
        canvas.drawCircle(const Offset(160, 57), 43, pen);
        line(130, 27, 190, 87);
      case 'medical':
        box(119, 19, 82, 88);
        plus(160, 46);
        box(148, 78, 24, 29, radius: 2);
        line(88, 107, 232, 107);
      case 'information':
        box(123, 13, 74, 91, radius: 6);
        for (final y in [36.0, 54.0, 72.0]) {
          line(138, y, 182, y);
        }
      default:
        canvas.drawPath(
          Path()
            ..moveTo(88, 57)
            ..quadraticBezierTo(160, -6, 232, 57)
            ..quadraticBezierTo(160, 120, 88, 57)
            ..close(),
          pen,
        );
        canvas.drawCircle(const Offset(160, 57), 18, pen);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ReminderPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
