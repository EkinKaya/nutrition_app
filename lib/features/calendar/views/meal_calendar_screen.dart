import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/services/meal_calendar_service.dart';
import '../../../core/theme/app_colors.dart';

class MealCalendarScreen extends StatefulWidget {
  const MealCalendarScreen({super.key});

  @override
  State<MealCalendarScreen> createState() => _MealCalendarScreenState();
}

class _MealCalendarScreenState extends State<MealCalendarScreen> {
  late DateTime _weekStart;
  late DateTime _selectedDay;
  Map<DateTime, DaySummary> _weekData = {};
  String? _weeklySummaryText;
  bool _loadingAiSummary = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = _monday(now);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _loadWeek();
    _checkAndLoadAiSummary();
  }

  DateTime _monday(DateTime d) {
    final diff = d.weekday - 1;
    return DateTime(d.year, d.month, d.day - diff);
  }

  Future<void> _loadWeek() async {
    final data = await MealCalendarService.getWeeklySummary(_weekStart);
    if (mounted) setState(() { _weekData = data; });
  }

  Future<void> _checkAndLoadAiSummary() async {
    // Sadece Pazartesi
    if (DateTime.now().weekday != DateTime.monday) return;
    final existing = await MealCalendarService.getWeeklySummaryText(DateTime.now());
    if (existing != null) {
      if (mounted) setState(() => _weeklySummaryText = existing);
      return;
    }
    await _generateAiSummary();
  }

  Future<void> _generateAiSummary() async {
    setState(() => _loadingAiSummary = true);
    try {
      // Geçen haftanın verisini al
      final lastWeekStart = _weekStart.subtract(const Duration(days: 7));
      final weekData = await MealCalendarService.getWeeklySummary(lastWeekStart);

      final buffer = StringBuffer();
      buffer.writeln('Geçen hafta (${_fmtDate(lastWeekStart)} – ${_fmtDate(lastWeekStart.add(const Duration(days: 6)))}) beslenme özeti:');
      weekData.forEach((date, summary) {
        buffer.writeln('${_dayName(date.weekday)}: ${summary.totalCalories} kcal, '
            'P:${summary.totalProtein.round()}g K:${summary.totalCarbs.round()}g Y:${summary.totalFat.round()}g '
            '(${summary.meals.length} öğün)');
      });
      buffer.writeln('\nBu veriye göre kısa (3-4 cümle) Türkçe haftalık beslenme yorumu yaz. Güçlü yönler ve gelişim alanları belirt.');

      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${ApiConfig.geminiApiKey}';
      http.Response? resp;
      for (int attempt = 1; attempt <= 3; attempt++) {
        resp = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {'role': 'user', 'parts': [{'text': buffer.toString()}]}
            ],
            'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 512}
          }),
        );
        if (resp.statusCode == 200 ||
            (resp.statusCode != 503 && resp.statusCode != 429)) break;
        if (attempt < 3) await Future.delayed(Duration(seconds: attempt * 3));
      }

      if (resp != null && resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          await MealCalendarService.saveWeeklySummaryText(DateTime.now(), text);
          if (mounted) setState(() => _weeklySummaryText = text);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingAiSummary = false);
  }

  void _prevWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _selectedDay = _weekStart;
      _weekData = {};
    });
    _loadWeek();
  }

  void _nextWeek() {
    final next = _weekStart.add(const Duration(days: 7));
    if (next.isAfter(DateTime.now())) return;
    setState(() {
      _weekStart = next;
      _selectedDay = _weekStart;
      _weekData = {};
    });
    _loadWeek();
  }

  bool get _isCurrentWeek {
    final now = _monday(DateTime.now());
    return _weekStart.year == now.year &&
        _weekStart.month == now.month &&
        _weekStart.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildWeekBar(),
            _buildDaySelector(),
            const SizedBox(height: 4),
            Expanded(child: _buildDayContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF7B9CFF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF7B9CFF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Öğün Takvimi',
            style: GoogleFonts.urbanist(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekBar() {
    final start = _weekStart;
    final end = start.add(const Duration(days: 6));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _prevWeek,
            icon: Icon(Icons.chevron_left_rounded,
                color: Colors.white.withOpacity(0.5)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${_fmtDate(start)} – ${_fmtDate(end)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _isCurrentWeek ? null : _nextWeek,
            icon: Icon(Icons.chevron_right_rounded,
                color: _isCurrentWeek
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.5)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: days.map((day) {
          final isSelected = day.year == _selectedDay.year &&
              day.month == _selectedDay.month &&
              day.day == _selectedDay.day;
          final isToday = day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;
          final isFuture = day.isAfter(today);
          final summary =
              _weekData[DateTime(day.year, day.month, day.day)];
          final hasMeals = summary != null && summary.meals.isNotEmpty;

          return Expanded(
            child: GestureDetector(
              onTap: isFuture ? null : () {
                setState(() => _selectedDay = day);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF7B9CFF)
                      : isToday
                          ? const Color(0xFF7B9CFF).withOpacity(0.12)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _shortDayName(day.weekday),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(isFuture ? 0.2 : 0.45),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${day.day}',
                      style: GoogleFonts.urbanist(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(isFuture ? 0.2 : 0.8),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasMeals
                            ? (isSelected
                                ? Colors.white
                                : const Color(0xFF7B9CFF))
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayContent() {
    return StreamBuilder<List<MealEntry>>(
      stream: MealCalendarService.getMealsStream(_selectedDay),
      builder: (context, snapshot) {
        final meals = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting &&
            meals.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7B9CFF)),
          );
        }

        // Update weekData with live stream result for dot indicators
        if (snapshot.hasData) {
          final key = DateTime(
              _selectedDay.year, _selectedDay.month, _selectedDay.day);
          if (_weekData[key]?.meals.length != meals.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _weekData[key] = DaySummary(date: _selectedDay, meals: meals);
                });
              }
            });
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Macro summary card
            if (meals.isNotEmpty) _buildMacroCard(meals),
            if (meals.isNotEmpty) const SizedBox(height: 16),

            // Meals
            if (meals.isEmpty)
              _buildEmptyDay()
            else ...[
              Text(
                'Öğünler',
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 10),
              ...meals.map((m) => _MealCard(
                    meal: m,
                    onDelete: () async {
                      await MealCalendarService.deleteMeal(
                          m.id, _selectedDay);
                      _loadWeek();
                    },
                  )),
            ],

            // Monday AI summary
            if (_weeklySummaryText != null || _loadingAiSummary)
              _buildWeeklySummary(),
          ],
        );
      },
    );
  }

  Widget _buildMacroCard(List<MealEntry> meals) {
    final cal = meals.fold(0, (s, m) => s + m.calories);
    final prot = meals.fold(0.0, (s, m) => s + m.protein);
    final carbs = meals.fold(0.0, (s, m) => s + m.carbs);
    final fat = meals.fold(0.0, (s, m) => s + m.fat);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7B9CFF).withOpacity(0.18),
            const Color(0xFF7B9CFF).withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF7B9CFF).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                '$cal kcal',
                style: GoogleFonts.urbanist(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${meals.length} öğün',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MacroChip(label: 'Protein', value: prot, color: const Color(0xFF6BCB77)),
              const SizedBox(width: 8),
              _MacroChip(label: 'Karb', value: carbs, color: const Color(0xFFFFD93D)),
              const SizedBox(width: 8),
              _MacroChip(label: 'Yağ', value: fat, color: const Color(0xFFFF6B6B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDay() {
    final isToday = _selectedDay.year == DateTime.now().year &&
        _selectedDay.month == DateTime.now().month &&
        _selectedDay.day == DateTime.now().day;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.restaurant_outlined,
              color: Colors.white.withOpacity(0.15), size: 48),
          const SizedBox(height: 16),
          Text(
            isToday ? 'Bugün henüz öğün eklenmemiş' : 'Bu gün öğün kaydı yok',
            style: GoogleFonts.urbanist(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI sohbetinden bir tarife uzun basarak\nkalorini takvime ekleyebilirsin',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.2),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Haftalık AI Yorumu',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loadingAiSummary)
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Yorumlanıyor...',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              )
            else
              Text(
                _weeklySummaryText ?? '',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.6,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day} ${_monthName(d.month)}';

  String _monthName(int m) => const [
        '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
        'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
      ][m];

  String _shortDayName(int w) =>
      const ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'][w];

  String _dayName(int w) =>
      const ['', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'][w];
}

// ---------------------------------------------------------------------------
// Macro chip
// ---------------------------------------------------------------------------
class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              '${value.round()}g',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meal card
// ---------------------------------------------------------------------------
class _MealCard extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onDelete;

  const _MealCard({required this.meal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restaurant_rounded,
                  color: Colors.orange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${meal.calories} kcal',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (meal.protein > 0) ...[
                        Text(
                          '  •  P:${meal.protein.round()}g  K:${meal.carbs.round()}g  Y:${meal.fat.round()}g',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _confirmDelete(context),
              icon: Icon(Icons.delete_outline_rounded,
                  color: Colors.white.withOpacity(0.3), size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Öğünü Sil',
            style: GoogleFonts.urbanist(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          '"${meal.name}" takvimden silinsin mi?',
          style:
              GoogleFonts.inter(color: Colors.white.withOpacity(0.7), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Vazgeç',
                style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.85),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Sil',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
