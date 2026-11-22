import 'package:flutter/material.dart';

/// Decorative artwork for the offline learning library.
class MedicalEmblem extends StatelessWidget {
  const MedicalEmblem({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/brand/learning-kit.webp',
      width: 122,
      height: 154,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    ),
  );
}
