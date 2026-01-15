import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/fruit_character.dart';

class GoalPercentageWidget extends StatelessWidget {
  final int percentage;

  const GoalPercentageWidget({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPercentage(),
        const Spacer(),
        SizedBox(
          width: 140,
          height: 180,
          child: FruitCharacter(
            size: FruitSize.medium,
            action: FruitAction.celebrating,
            showPlatform: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPercentage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$percentage',
          style: GoogleFonts.inter(
            fontSize: 80,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
            height: 0.9,
          ),
        ),
        Text(
          '%',
          style: GoogleFonts.inter(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}