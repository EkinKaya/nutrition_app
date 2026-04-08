import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class RecommendationCardWidget extends StatelessWidget {
  final int steps;
  final int stepGoal;
  final int waterGlasses;
  final int waterGoal;

  const RecommendationCardWidget({
    super.key,
    this.steps = 0,
    this.stepGoal = 10000,
    this.waterGlasses = 0,
    this.waterGoal = 8,
  });

  @override
  Widget build(BuildContext context) {
    final tip = _getTip();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.dark.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Icon(tip.icon, color: AppColors.dark, size: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dark.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _Tip _getTip() {
    final stepPct = steps / stepGoal;
    final waterPct = waterGlasses / waterGoal;

    if (stepPct >= 1.0 && waterPct >= 1.0) {
      return _Tip(
        icon: Icons.emoji_events_outlined,
        title: 'Mükemmel gün!',
        subtitle: 'Tüm hedeflerini tamamladın, harika!',
      );
    }
    if (waterPct < 0.4) {
      return _Tip(
        icon: Icons.water_drop_outlined,
        title: 'Su içmeyi unutma!',
        subtitle: '${waterGoal - waterGlasses} bardak daha içmen gerekiyor',
      );
    }
    if (stepPct < 0.4) {
      final rem = stepGoal - steps;
      return _Tip(
        icon: Icons.directions_walk_outlined,
        title: 'Biraz yürüyelim!',
        subtitle: '${_fmt(rem)} adım daha atman gerekiyor',
      );
    }
    return _Tip(
      icon: Icons.tips_and_updates_outlined,
      title: 'İyi gidiyorsun!',
      subtitle: 'Hareket etmeye ve su içmeye devam et',
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    return '$n';
  }
}

class _Tip {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Tip({required this.icon, required this.title, required this.subtitle});
}
