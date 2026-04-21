import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fond dégradé vert sombre (cohérent Welcome / Login).
class IndustrialBackground extends StatelessWidget {
  const IndustrialBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gradientTop, AppColors.darkGreen],
        ),
      ),
      child: child,
    );
  }
}
