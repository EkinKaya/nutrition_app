import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ActivityHeader extends StatelessWidget {
  final VoidCallback? onSettingsTap;

  const ActivityHeader({super.key, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'GÜNLÜK HEDEF',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 2,
          ),
        ),
        GestureDetector(
          onTap: onSettingsTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.7), size: 20),
          ),
        ),
      ],
    );
  }
}
