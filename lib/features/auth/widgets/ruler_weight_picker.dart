import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class RulerWeightPicker extends StatefulWidget {
  final int initialWeight;
  final ValueChanged<int> onWeightChanged;

  const RulerWeightPicker({
    super.key,
    required this.initialWeight,
    required this.onWeightChanged,
  });

  @override
  State<RulerWeightPicker> createState() => _RulerWeightPickerState();
}

class _RulerWeightPickerState extends State<RulerWeightPicker> {
  late ScrollController _scrollController;
  late int _currentWeight;
  final double _itemWidth = 8.0;

  @override
  void initState() {
    super.initState();
    _currentWeight = widget.initialWeight;
    // Start at initial weight (offset from 30kg)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      final centerOffset = screenWidth / 2;
      final initialOffset = (_currentWeight - 30) * _itemWidth - centerOffset + (_itemWidth / 2);
      _scrollController.jumpTo(initialOffset);
    });
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerOffset = screenWidth / 2;
    final offset = _scrollController.offset + centerOffset - (_itemWidth / 2);
    final weight = (offset / _itemWidth).round() + 30;

    if (weight >= 30 && weight <= 200 && weight != _currentWeight) {
      setState(() {
        _currentWeight = weight;
      });
      widget.onWeightChanged(_currentWeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Unit selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUnitButton('KG', true),
            const SizedBox(width: 8),
            _buildUnitButton('LB', false),
          ],
        ),
        const SizedBox(height: 32),
        // Current weight display
        Text(
          _currentWeight.toString(),
          style: GoogleFonts.urbanist(
            fontSize: 64,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
        Text(
          'kg',
          style: GoogleFonts.urbanist(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 40),
        // Ruler
        SizedBox(
          height: 90,
          child: Stack(
            children: [
              // Scrollable ruler
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(171, (index) {
                    final weight = index + 30;
                    final isMajor = weight % 5 == 0;
                    return _buildRulerMark(weight, isMajor);
                  }),
                ),
              ),
              // Center indicator
              Center(
                child: Container(
                  width: 3,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitButton(String unit, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        unit,
        style: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppColors.dark : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildRulerMark(int weight, bool isMajor) {
    return Container(
      width: _itemWidth,
      height: 90,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMajor)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                weight.toString(),
                style: GoogleFonts.urbanist(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Container(
            width: 2,
            height: isMajor ? 25 : 12,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(isMajor ? 0.5 : 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
