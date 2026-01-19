import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ScrollableAgePicker extends StatefulWidget {
  final int initialAge;
  final ValueChanged<int> onAgeChanged;

  const ScrollableAgePicker({
    super.key,
    required this.initialAge,
    required this.onAgeChanged,
  });

  @override
  State<ScrollableAgePicker> createState() => _ScrollableAgePickerState();
}

class _ScrollableAgePickerState extends State<ScrollableAgePicker> {
  late FixedExtentScrollController _scrollController;
  late int _currentAge;

  @override
  void initState() {
    super.initState();
    _currentAge = widget.initialAge;
    _scrollController = FixedExtentScrollController(
      initialItem: widget.initialAge - 18,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Selected item background
          Center(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.backgroundAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          ),
          // Scrollable list
          ListWheelScrollView.useDelegate(
            controller: _scrollController,
            itemExtent: 60,
            perspective: 0.005,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _currentAge = index + 18;
              });
              widget.onAgeChanged(_currentAge);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 83, // 18 to 100
              builder: (context, index) {
                final age = index + 18;
                final isSelected = age == _currentAge;

                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.urbanist(
                      fontSize: isSelected ? 48 : 32,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.dark
                          : AppColors.textSecondary.withOpacity(0.4),
                    ),
                    child: Text(age.toString()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
