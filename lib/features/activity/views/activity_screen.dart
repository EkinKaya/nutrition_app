import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/health_service.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/services/user_service.dart';
import '../widgets/activity_header.dart';
import '../widgets/goal_percentage_widget.dart';
import '../widgets/water_glass_widget.dart';
import '../widgets/metrics_list_widget.dart';
import '../widgets/recommendation_card_widget.dart';
import 'step_detail_screen.dart';
import 'calorie_detail_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int _steps = 0;
  int _calories = 0;
  bool _isLoadingSteps = true;
  bool _hasHealthPermission = false;

  double _weightKg = 70.0;
  int _stepGoal = 10000;

  late Stream<int> _waterStream;

  @override
  void initState() {
    super.initState();
    _waterStream = ActivityService.getWaterGlassStream();
    _initData();
  }

  Future<void> _initData() async {
    await _loadUserProfile();
    await _checkAndLoadSteps();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await UserService.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          final w = profile['weight'];
          final g = profile['stepGoal'];
          if (w != null) _weightKg = (w as num).toDouble();
          if (g != null) _stepGoal = (g as num).toInt();
        });
      }
    } catch (_) {}
  }

  Future<void> _checkAndLoadSteps() async {
    final hasPermission = await HealthService.hasPermissions();
    if (!mounted) return;
    setState(() => _hasHealthPermission = hasPermission);
    if (hasPermission) {
      await _fetchSteps();
    } else {
      if (mounted) setState(() => _isLoadingSteps = false);
    }
  }

  Future<void> _requestPermissionAndLoad() async {
    setState(() => _isLoadingSteps = true);
    final granted = await HealthService.requestPermissions();
    if (!mounted) return;
    setState(() => _hasHealthPermission = granted);
    if (granted) {
      await _fetchSteps();
    } else {
      setState(() => _isLoadingSteps = false);
    }
  }

  Future<void> _fetchSteps() async {
    if (mounted) setState(() => _isLoadingSteps = true);
    final steps = await HealthService.getTodaySteps();
    if (!mounted) return;
    setState(() {
      _steps = steps;
      _calories = ActivityService.calculateCalories(steps, weightKg: _weightKg);
      _isLoadingSteps = false;
    });
  }

  void _showGoalDialog() {
    const options = [5000, 7500, 10000, 15000];
    int selected = _stepGoal;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // taşmayı önler
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.darkSoft,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Günlük Adım Hedefi',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hedef adıma göre kalori hesaplanır',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
                const SizedBox(height: 18),

                // Seçenekler
                ...options.map((goal) {
                  final isSelected = selected == goal;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => setS(() => selected = goal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.12)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.5)
                                : Colors.white.withOpacity(0.08),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _fmt(goal),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'adım',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            if (goal == 10000) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'önerilen',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _saveStepGoal(selected);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.dark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Kaydet',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveStepGoal(int goal) async {
    setState(() {
      _stepGoal = goal;
      _calories = ActivityService.calculateCalories(_steps, weightKg: _weightKg);
    });
    await UserService.updateUserProfile({'stepGoal': goal});
  }

  String _fmt(int n) {
    if (n >= 1000) {
      return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkSoft,
          onRefresh: _hasHealthPermission ? _fetchSteps : () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: StreamBuilder<int>(
              stream: _waterStream,
              builder: (context, waterSnap) {
                final waterGlasses = waterSnap.data ?? 0;
                final calorieGoal =
                    ActivityService.calorieGoalForWeight(_weightKg);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ActivityHeader(onSettingsTap: _showGoalDialog),
                    const SizedBox(height: 28),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: !_hasHealthPermission && !_isLoadingSteps
                              ? _PermissionWidget(
                                  onConnect: _requestPermissionAndLoad)
                              : GoalPercentageWidget(
                                  steps: _steps,
                                  stepGoal: _stepGoal,
                                  isLoading: _isLoadingSteps,
                                ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: WaterGlassWidget(
                            glasses: waterGlasses,
                            goal: ActivityService.dailyGlassGoal,
                            onAdd: ActivityService.addWaterGlass,
                            onRemove: ActivityService.removeWaterGlass,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    MetricsListWidget(
                      steps: _steps,
                      stepGoal: _stepGoal,
                      calories: _calories,
                      calorieGoal: calorieGoal,
                      onStepTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StepDetailScreen(
                            weightKg: _weightKg,
                            stepGoal: _stepGoal,
                            hasPermission: _hasHealthPermission,
                            onRequestPermission: _requestPermissionAndLoad,
                          ),
                        ),
                      ),
                      onCalorieTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CalorieDetailScreen(
                            weightKg: _weightKg,
                            stepGoal: _stepGoal,
                            hasPermission: _hasHealthPermission,
                            onRequestPermission: _requestPermissionAndLoad,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    RecommendationCardWidget(
                      steps: _steps,
                      stepGoal: _stepGoal,
                      waterGlasses: waterGlasses,
                      waterGoal: ActivityService.dailyGlassGoal,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animasyonlu yürüyen adam widget'ı ───
class _PermissionWidget extends StatelessWidget {
  final VoidCallback onConnect;
  const _PermissionWidget({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Daire çerçeve + yürüyen figür — GoalPercentageWidget ile aynı boyut
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Arka plan halkası
              CustomPaint(
                size: const Size(160, 160),
                painter: _DimRingPainter(),
              ),
              // Yürüyen adam
              const SizedBox(
                width: 72,
                height: 72,
                child: _WalkingFigure(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Sabit 48px metin alanı — WaterGlassWidget ile eşit
        SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Adımlarını takip et',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Bağlan butonu — +/- ile aynı yükseklik (40px) ve stil
        GestureDetector(
          onTap: onConnect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.45), width: 1.5),
            ),
            child: Center(
              child: Text(
                'Bağlan',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Yürüyen çöp adam çizen animasyonlu widget ───
class _WalkingFigure extends StatefulWidget {
  final Color color;
  const _WalkingFigure({required this.color});

  @override
  State<_WalkingFigure> createState() => _WalkingFigureState();
}

class _WalkingFigureState extends State<_WalkingFigure>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // -1.0 → +1.0 → -1.0 gidip gelir: simetrik salınım
    _ctrl = AnimationController(
      vsync: this,
      lowerBound: -1.0,
      upperBound: 1.0,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _WalkingFigurePainter(
          progress: _ctrl.value,
          color: widget.color,
        ),
      ),
    );
  }
}

class _WalkingFigurePainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 → 0.0 (reverse: true)
  final Color color;

  const _WalkingFigurePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09;

    // progress: -1.0 → +1.0 (AnimationController lowerBound/upperBound)
    // swing: sarkaç açısı ±30°
    final swing = progress * (pi / 6);

    // Kafa
    final headR = w * 0.13;
    final headC = Offset(w * 0.5, headR);
    canvas.drawCircle(headC, headR, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;

    // Gövde
    final bodyTop = Offset(w * 0.5, headR * 2);
    final bodyBot = Offset(w * 0.5, h * 0.56);
    canvas.drawLine(bodyTop, bodyBot, paint);

    // Kollar — bacaklara ters yönde (sarkaç hareketi)
    final armRoot = Offset(w * 0.5, h * 0.30);
    final armLen = w * 0.28;
    // Sağ kol ileri → sol bacak ileri
    canvas.drawLine(
      armRoot,
      Offset(armRoot.dx - sin(swing) * armLen,
          armRoot.dy + cos(swing) * armLen * 0.65),
      paint,
    );
    // Sol kol ileri → sağ bacak ileri
    canvas.drawLine(
      armRoot,
      Offset(armRoot.dx + sin(swing) * armLen,
          armRoot.dy + cos(swing) * armLen * 0.65),
      paint,
    );

    // Bacaklar — sarkaç hareketi
    final legLen = h * 0.38;
    // Sağ bacak
    canvas.drawLine(
      bodyBot,
      Offset(bodyBot.dx + sin(swing) * legLen,
          bodyBot.dy + cos(swing) * legLen),
      paint,
    );
    // Sol bacak (ters)
    canvas.drawLine(
      bodyBot,
      Offset(bodyBot.dx - sin(swing) * legLen,
          bodyBot.dy + cos(swing) * legLen),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WalkingFigurePainter old) =>
      old.progress != progress;
}

// GoalPercentageWidget ile aynı boyutta soluk arka plan halkası
class _DimRingPainter extends CustomPainter {
  const _DimRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 10.0;
    final radius = (size.width - strokeWidth) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
