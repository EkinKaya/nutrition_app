import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class RulerHeightPicker extends StatefulWidget {
  final int initialHeight;
  final ValueChanged<int> onHeightChanged;

  const RulerHeightPicker({
    super.key,
    required this.initialHeight,
    required this.onHeightChanged,
  });

  @override
  State<RulerHeightPicker> createState() => _RulerHeightPickerState();
}

class _RulerHeightPickerState extends State<RulerHeightPicker> {
  late ScrollController _scrollController;
  late int _currentHeight;
  final double _itemHeight = 8.0;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialOffset = (_currentHeight - 100) * _itemHeight - 100;
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
    final offset = _scrollController.offset + 100;
    final height = (offset / _itemHeight).round() + 100;

    if (height >= 100 && height <= 250 && height != _currentHeight) {
      setState(() {
        _currentHeight = height;
      });
      widget.onHeightChanged(_currentHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Unit selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUnitButton('CM', true),
            const SizedBox(width: 8),
            _buildUnitButton('FT', false),
          ],
        ),
        const SizedBox(height: 24),
        // Current height display
        Text(
          _currentHeight.toString(),
          style: GoogleFonts.urbanist(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
        Text(
          'cm',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        // Vertical ruler
        Container(
          height: 250,
          width: 120,
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.3),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Scrollable ruler
              SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    ...List.generate(151, (index) {
                      final height = index + 100;
                      final isMajor = height % 10 == 0;
                      return _buildRulerMark(height, isMajor);
                    }),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              // Center indicator (horizontal line)
              Container(
                width: 80,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
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

  Widget _buildRulerMark(int height, bool isMajor) {
    return Container(
      height: _itemHeight,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isMajor)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                height.toString(),
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Container(
            width: isMajor ? 30 : 15,
            height: 2,
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
