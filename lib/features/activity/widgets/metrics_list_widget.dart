import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetricsListWidget extends StatelessWidget {
  const MetricsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricRow(icon: '🔥', value: '1,840', label: 'calories'),
        const SizedBox(height: 16),
        _MetricRow(icon: '👣', value: '3,248', label: 'steps'),
        const SizedBox(height: 16),
        _MetricRow(icon: '💧', value: '6.5', label: 'cups'),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _MetricRow({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 16),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 20,
              color: const Color(0xFF1E293B),
            ),
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: '  $label',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
