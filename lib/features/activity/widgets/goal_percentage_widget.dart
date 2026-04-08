import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class GoalPercentageWidget extends StatelessWidget {
  final int steps;
  final int stepGoal;
  final bool isLoading;

  const GoalPercentageWidget({
    super.key,
    required this.steps,
    this.stepGoal = 10000,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (steps / stepGoal).clamp(0.0, 1.0);

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halka
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: isLoading ? 0.0 : progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              size: const Size(160, 160),
              painter: _RingPainter(
                progress: value,
                backgroundColor: Colors.white.withOpacity(0.08),
                progressColor: AppColors.primary,
                strokeWidth: 10,
              ),
            ),
          ),

          // Merkez icerik
          if (isLoading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatSteps(steps),
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'adım',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '%${(progress * 100).toInt()} hedef',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatSteps(int n) {
    if (n == 0) return '0';
    if (n >= 10000) {
      return n.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'),
            (m) => '${m.group(0)},',
          );
    }
    if (n >= 1000) {
      return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return '$n';
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.backgroundColor != backgroundColor;
}
