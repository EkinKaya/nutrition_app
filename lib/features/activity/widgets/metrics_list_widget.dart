import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class MetricsListWidget extends StatelessWidget {
  final int steps;
  final int stepGoal;
  final int calories;
  final int calorieGoal;
  final VoidCallback? onStepTap;
  final VoidCallback? onCalorieTap;

  const MetricsListWidget({
    super.key,
    required this.steps,
    required this.stepGoal,
    required this.calories,
    required this.calorieGoal,
    this.onStepTap,
    this.onCalorieTap,
  });

  @override
  Widget build(BuildContext context) {
    final stepProgress = (steps / stepGoal).clamp(0.0, 1.0);
    final calProgress = (calories / calorieGoal).clamp(0.0, 1.0);

    return Column(
      children: [
        _MetricCard(
          icon: Icons.local_fire_department_outlined,
          iconColor: const Color(0xFFFF6B6B),
          value: '$calories',
          label: 'kalori',
          sublabel: '$calorieGoal kal hedef',
          progress: calProgress,
          onTap: onCalorieTap,
        ),
        const SizedBox(height: 12),
        _MetricCard(
          icon: Icons.directions_walk_outlined,
          iconColor: const Color(0xFF4ECDC4),
          value: _formatNumber(steps),
          label: 'adım',
          sublabel: '${_formatNumber(stepGoal)} hedef',
          progress: stepProgress,
          onTap: onStepTap,
        ),
      ],
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000) {
      return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return '$n';
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String sublabel;
  final double progress;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onTap != null
              ? iconColor.withOpacity(0.12)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // Ikon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          // Deger + etiket
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      sublabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) =>
                        LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '%${(progress * 100).toInt()}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.2), size: 16),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
