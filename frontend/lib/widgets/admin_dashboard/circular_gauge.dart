import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Jauge circulaire animée (CustomPainter).
class DashboardCircularGauge extends StatefulWidget {
  const DashboardCircularGauge({
    super.key,
    required this.label,
    required this.valueFraction,
    this.centerLabel,
    this.subLabel,
    this.trackColor,
    this.progressColor,
    this.size = 132,
  });

  final String label;
  /// 0–1
  final double valueFraction;
  final String? centerLabel;
  final String? subLabel;
  final Color? trackColor;
  final Color? progressColor;
  final double size;

  @override
  State<DashboardCircularGauge> createState() => _DashboardCircularGaugeState();
}

class _DashboardCircularGaugeState extends State<DashboardCircularGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void didUpdateWidget(DashboardCircularGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueFraction != widget.valueFraction) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.trackColor ?? AppColors.border;
    final prog = widget.progressColor ?? AppColors.accent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final sweep = (widget.valueFraction.clamp(0.0, 1.0)) * _anim.value;
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _GaugePainter(
                  progress: sweep,
                  trackColor: track,
                  progressColor: prog,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.centerLabel ??
                            '${(widget.valueFraction * 100).round()}%',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      if (widget.subLabel != null)
                        Text(
                          widget.subLabel!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 10.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - stroke;

    final trackPaint =
        Paint()
          ..color = trackColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round;

    final start = math.pi * 0.75;
    final fullSweep = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      fullSweep,
      false,
      trackPaint,
    );

    if (progress <= 0) return;

    final grad = SweepGradient(
      startAngle: start,
      endAngle: start + fullSweep * progress,
      colors: [
        progressColor.withValues(alpha: 0.4),
        progressColor,
      ],
    );

    final arcPaint =
        Paint()
          ..shader = grad.createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      fullSweep * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
