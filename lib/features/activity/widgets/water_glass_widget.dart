import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WaterGlassWidget extends StatelessWidget {
  final int glasses;
  final int goal;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const WaterGlassWidget({
    super.key,
    required this.glasses,
    required this.goal,
    required this.onAdd,
    required this.onRemove,
  });

  static const Color _waterColor = Color(0xFF45B7D1);

  @override
  Widget build(BuildContext context) {
    final fillPercent = (glasses / goal).clamp(0.0, 1.0);
    final canAdd = glasses < goal;
    final canRemove = glasses > 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 160px'lik alan — GoalPercentageWidget ile aynı yükseklik
        GestureDetector(
          onTap: canAdd ? onAdd : null,
          child: SizedBox(
            width: double.infinity,
            height: 160,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: fillPercent),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, fill, _) => SizedBox(
                  width: 84,
                  height: 118,
                  child: CustomPaint(
                    painter: _WaterGlassPainter(fillPercent: fill),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Sabit 48px metin alanı — _PermissionWidget ile eşit
        SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$glasses',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _waterColor,
                        fontFamily: 'Inter',
                      ),
                    ),
                    TextSpan(
                      text: '/$goal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.35),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'bardak su',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.4),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // + / - butonları
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // - kırmızı (kalori rengiyle aynı), her zaman görünür
            _GlassButton(
              icon: Icons.remove,
              enabled: canRemove,
              onTap: canRemove ? onRemove : null,
              size: 40,
              color: const Color(0xFFFF6B6B),
            ),
            const SizedBox(width: 12),
            _GlassButton(
              icon: Icons.add,
              enabled: canAdd,
              onTap: canAdd ? onAdd : null,
              size: 40,
              color: const Color(0xFF45B7D1),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  final double size;
  final Color color; // + mavi, - kırmızı

  const _GlassButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Aktif: tam renk / Pasif: soluk ama görünür
    final opacity = enabled ? 1.0 : 0.28;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(enabled ? 0.18 : 0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(enabled ? 0.45 : 0.18),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: color.withOpacity(opacity),
          size: size * 0.50,
        ),
      ),
    );
  }
}

class _WaterGlassPainter extends CustomPainter {
  final double fillPercent;

  const _WaterGlassPainter({required this.fillPercent});

  static const Color _waterColor = Color(0xFF45B7D1);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Düz trapez bardak şekli (yuvarlak köşe YOK)
    // Üst geniş, alt dar
    final tl = Offset(w * 0.04, 0);
    final tr = Offset(w * 0.96, 0);
    final br = Offset(w * 0.80, h * 0.90);
    final bl = Offset(w * 0.20, h * 0.90);

    final glassPath = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    // Bardak iç arka plan (boşken görünür olsun)
    canvas.drawPath(
      glassPath,
      Paint()
        ..color = Colors.white.withOpacity(0.04)
        ..style = PaintingStyle.fill,
    );

    // Su dolumu
    if (fillPercent > 0.005) {
      canvas.save();
      canvas.clipPath(glassPath);

      final waterTopY = h * 0.90 * (1 - fillPercent);

      // Su gradyanı
      canvas.drawRect(
        Rect.fromLTRB(0, waterTopY, w, h),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _waterColor.withOpacity(0.45),
              _waterColor.withOpacity(0.72),
            ],
          ).createShader(Rect.fromLTRB(0, waterTopY, w, h * 0.90)),
      );

      // Yüzey dalgası
      if (fillPercent > 0.04 && fillPercent < 0.95) {
        final wavePath = Path();
        const amp = 2.5;
        const steps = 60;
        for (int i = 0; i <= steps; i++) {
          final x = w * i / steps;
          final y = waterTopY + sin(i * 2 * pi / steps) * amp;
          i == 0 ? wavePath.moveTo(x, y) : wavePath.lineTo(x, y);
        }
        wavePath.lineTo(w, waterTopY - amp - 1);
        wavePath.lineTo(0, waterTopY - amp - 1);
        wavePath.close();
        canvas.drawPath(
          wavePath,
          Paint()..color = Colors.white.withOpacity(0.22),
        );
      }

      // Küçük kabarcıklar
      if (fillPercent > 0.18) {
        final bp = Paint()
          ..color = Colors.white.withOpacity(0.13)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.38, waterTopY + h * 0.08), 2.4, bp);
        canvas.drawCircle(Offset(w * 0.60, waterTopY + h * 0.16), 1.7, bp);
        canvas.drawCircle(Offset(w * 0.46, waterTopY + h * 0.24), 2.0, bp);
      }

      canvas.restore();
    }

    // Bardak çerçevesi
    final outlineColor = fillPercent > 0.05
        ? _waterColor.withOpacity(0.70)
        : Colors.white.withOpacity(0.25);

    canvas.drawPath(
      glassPath,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.miter,
    );

    // Alt kalın çizgi (bardak tabanı)
    canvas.drawLine(
      bl,
      br,
      Paint()
        ..color = outlineColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Sol kenar parlaması
    canvas.drawLine(
      Offset(w * 0.18, h * 0.06),
      Offset(w * 0.22, h * 0.70),
      Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..strokeWidth = 1.3,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterGlassPainter old) =>
      old.fillPercent != fillPercent;
}
