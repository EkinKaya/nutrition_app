import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/health_service.dart';

class StepDetailScreen extends StatefulWidget {
  final double weightKg;
  final int stepGoal;
  final bool hasPermission;
  final VoidCallback? onRequestPermission;

  const StepDetailScreen({
    super.key,
    this.weightKg = 70.0,
    this.stepGoal = 10000,
    this.hasPermission = true,
    this.onRequestPermission,
  });

  @override
  State<StepDetailScreen> createState() => _StepDetailScreenState();
}

class _StepDetailScreenState extends State<StepDetailScreen> {
  static const Color _accent = Color(0xFF4ECDC4);

  bool _isWeekly = true;
  bool _isLoading = true;
  List<_DayData> _data = [];

  @override
  void initState() {
    super.initState();
    if (widget.hasPermission) _loadData();
    else _buildEmptyData();
  }

  void _buildEmptyData() {
    final days = _isWeekly ? 7 : 30;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <_DayData>[];
    for (int i = days - 1; i >= 0; i--) {
      result.add(_DayData(date: today.subtract(Duration(days: i)), steps: 0));
    }
    setState(() {
      _data = result;
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final days = _isWeekly ? 7 : 30;
    final raw = await HealthService.getStepsPerDay(days: days);
    if (!mounted) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <_DayData>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      result.add(_DayData(date: day, steps: raw[day] ?? 0));
    }

    setState(() {
      _data = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nonZero = _data.where((d) => d.steps > 0).toList();
    final avg = nonZero.isEmpty
        ? 0
        : (nonZero.map((d) => d.steps).reduce((a, b) => a + b) /
                nonZero.length)
            .round();
    final total = _data.isEmpty
        ? 0
        : _data.map((d) => d.steps).reduce((a, b) => a + b);
    final best =
        _data.isEmpty ? null : _data.reduce((a, b) => a.steps >= b.steps ? a : b);
    final daysAboveGoal = _data.where((d) => d.steps >= widget.stepGoal).length;

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTabSelector(),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _accent))
                  : _buildContent(avg, total, best, daysAboveGoal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPermission() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_walk_rounded,
                  color: _accent, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Adım verilerine erişim yok',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Haftalık ve aylık adım geçmişini\ngörmek için sağlık verilerine izin ver.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onRequestPermission?.call();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'İzin Ver',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Adım',
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text(
                _isWeekly ? 'Son 7 gün' : 'Son 30 gün',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white.withOpacity(0.45)),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_walk_rounded,
                color: _accent, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _Tab(
              label: 'Haftalık',
              selected: _isWeekly,
              onTap: () {
                if (!_isWeekly) {
                  setState(() => _isWeekly = true);
                  widget.hasPermission ? _loadData() : _buildEmptyData();
                }
              },
            ),
            _Tab(
              label: 'Aylık',
              selected: !_isWeekly,
              onTap: () {
                if (_isWeekly) {
                  setState(() => _isWeekly = false);
                  widget.hasPermission ? _loadData() : _buildEmptyData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(int avg, int total, _DayData? best, int daysAboveGoal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar chart
          _StepBarChart(
            data: _data,
            goal: widget.stepGoal,
            color: _accent,
            isWeekly: _isWeekly,
          ),

          const SizedBox(height: 28),

          Text(
            _isWeekly ? 'Son 7 günün özeti' : 'Son 30 günün özeti',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.45),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Ort.',
                  value: _fmt(avg),
                  unit: 'adım/gün',
                  color: _accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'En Yüksek',
                  value: _fmt(best?.steps ?? 0),
                  unit: best != null ? _shortDate(best.date) : '-',
                  color: _accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Toplam',
                  value: _fmt(total),
                  unit: 'adım',
                  color: _accent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Highlight row 2
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Hedef',
                  value: '${widget.stepGoal >= 1000 ? '${widget.stepGoal ~/ 1000}K' : widget.stepGoal}',
                  unit: 'adım/gün',
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Hedefe Ulaşıldı',
                  value: '$daysAboveGoal',
                  unit: _isWeekly ? '/ 7 gün' : '/ 30 gün',
                  color: daysAboveGoal > 0 ? _accent : Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Hedef Oranı',
                  value: avg >= widget.stepGoal ? '✓' : _pct(avg, widget.stepGoal),
                  unit: avg >= widget.stepGoal ? 'hedef aşıldı' : 'hedefe ulaşıldı',
                  color: avg >= widget.stepGoal ? _accent : Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),

          if (avg > 0) ...[
            const SizedBox(height: 24),
            _InsightCard(avg: avg, goal: widget.stepGoal, isWeekly: _isWeekly),
          ],
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) {
      return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return '$n';
  }

  String _shortDate(DateTime d) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _pct(int val, int goal) => '%${((val / goal) * 100).clamp(0, 999).toInt()}';
}

// ─── Bar Chart ───────────────────────────────────────────────────────────────

class _StepBarChart extends StatelessWidget {
  final List<_DayData> data;
  final int goal;
  final Color color;
  final bool isWeekly;

  const _StepBarChart({
    required this.data,
    required this.goal,
    required this.color,
    required this.isWeekly,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final dataMax = data.map((d) => d.steps).reduce(max);
    final maxVal = max(dataMax, goal).toDouble();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: CustomPaint(
            painter: _BarChartPainter(
              data: data,
              maxVal: maxVal,
              goal: goal.toDouble(),
              color: color,
              isWeekly: isWeekly,
            ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 8),
        _buildLabels(),
      ],
    );
  }

  Widget _buildLabels() {
    if (isWeekly) {
      const dayAbbr = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((d) {
          final abbr = dayAbbr[(d.date.weekday - 1) % 7];
          final isToday = _isToday(d.date);
          return Text(
            abbr,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday
                  ? const Color(0xFF4ECDC4)
                  : Colors.white.withOpacity(0.35),
              fontFamily: 'Inter',
            ),
          );
        }).toList(),
      );
    } else {
      // Monthly: show only every 5th label
      return Row(
        children: List.generate(data.length, (i) {
          final show = i == 0 || (i + 1) % 5 == 0 || i == data.length - 1;
          return Expanded(
            child: Text(
              show ? '${data[i].date.day}' : '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.35),
                fontFamily: 'Inter',
              ),
            ),
          );
        }),
      );
    }
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_DayData> data;
  final double maxVal;
  final double goal;
  final Color color;
  final bool isWeekly;

  const _BarChartPainter({
    required this.data,
    required this.maxVal,
    required this.goal,
    required this.color,
    required this.isWeekly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final n = data.length;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    for (int g = 1; g <= 4; g++) {
      final y = h * (1 - g / 4);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Goal line (dashed)
    final goalY = h * (1 - goal / maxVal);
    _drawDashedLine(canvas, goalY, w, color.withOpacity(0.45));

    // Bars
    final totalGap = w * 0.04;
    final barSlot = (w - totalGap) / n;
    final barW = isWeekly ? barSlot * 0.55 : barSlot * 0.65;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < n; i++) {
      final d = data[i];
      final isToday = d.date == today;
      final fillH = d.steps > 0 ? (d.steps / maxVal) * h : 0.0;
      final x = totalGap / 2 + i * barSlot + (barSlot - barW) / 2;
      final top = h - fillH;

      if (d.steps == 0) {
        // Empty bar placeholder
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, h - 4, barW, 4),
            const Radius.circular(2),
          ),
          Paint()..color = Colors.white.withOpacity(0.06),
        );
        continue;
      }

      final aboveGoal = d.steps >= goal;
      final barColor = aboveGoal
          ? color
          : isToday
              ? color.withOpacity(0.7)
              : color.withOpacity(0.45);

      final rect = Rect.fromLTWH(x, top, barW, fillH);
      final rRect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      // Gradient fill
      canvas.drawRRect(
        rRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              barColor.withOpacity(aboveGoal ? 1.0 : 0.85),
              barColor.withOpacity(aboveGoal ? 0.75 : 0.55),
            ],
          ).createShader(rect),
      );

      // Today highlight glow
      if (isToday) {
        canvas.drawRRect(
          rRect,
          Paint()
            ..color = color.withOpacity(0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6),
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, double y, double w, Color c) {
    final paint = Paint()
      ..color = c
      ..strokeWidth = 1.2;
    const dashLen = 6.0;
    const gapLen = 4.0;
    double x = 0;
    while (x < w) {
      canvas.drawLine(Offset(x, y), Offset(min(x + dashLen, w), y), paint);
      x += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.data != data || old.maxVal != maxVal || old.goal != goal;
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF4ECDC4).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: selected
                ? Border.all(
                    color: const Color(0xFF4ECDC4).withOpacity(0.35), width: 1)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF4ECDC4)
                    : Colors.white.withOpacity(0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.4),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final int avg;
  final int goal;
  final bool isWeekly;

  const _InsightCard(
      {required this.avg, required this.goal, required this.isWeekly});

  @override
  Widget build(BuildContext context) {
    final pct = (avg / goal * 100).round();
    final aboveGoal = avg >= goal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: aboveGoal
            ? const Color(0xFF4ECDC4).withOpacity(0.1)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: aboveGoal
              ? const Color(0xFF4ECDC4).withOpacity(0.3)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          Icon(
            aboveGoal
                ? Icons.emoji_events_outlined
                : Icons.trending_up_rounded,
            color: aboveGoal
                ? const Color(0xFF4ECDC4)
                : Colors.white.withOpacity(0.6),
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aboveGoal
                      ? 'Hedefindesin!'
                      : 'Ortalaman hedefinle yakın',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: aboveGoal
                        ? const Color(0xFF4ECDC4)
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aboveGoal
                      ? '${isWeekly ? 'Haftalık' : 'Aylık'} ortalamanla ${_fmt(avg)} adım/gün yürüyorsun.'
                      : 'Ortalamanın %$pct\'i günlük hedefe ulaşıyor.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) {
      return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return '$n';
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _DayData {
  final DateTime date;
  final int steps;
  const _DayData({required this.date, required this.steps});
}
