import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/meal_calendar_service.dart';

/// Porsiyon gramı → AI besin değeri hesaplama → takvime kaydetme dialogu.
/// Hem chat ekranından hem tarif kitabından kullanılır.
class PortionDialog extends StatefulWidget {
  final String mealName;

  /// Tarif içeriği veya yiyecek açıklaması (AI'ya gönderilir)
  final String foodDescription;

  const PortionDialog({
    super.key,
    required this.mealName,
    required this.foodDescription,
  });

  @override
  State<PortionDialog> createState() => _PortionDialogState();
}

class _PortionDialogState extends State<PortionDialog> {
  final _gramsCtrl = TextEditingController(text: '150');
  bool _loading = false;
  Map<String, double>? _macros;
  String? _error;

  @override
  void dispose() {
    _gramsCtrl.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    final grams = int.tryParse(_gramsCtrl.text.trim());
    if (grams == null || grams <= 0) {
      setState(() => _error = 'Geçerli bir gram değeri gir');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _macros = null;
    });
    final result =
        await GeminiService.getNutritionalInfo(widget.foodDescription, grams);
    if (mounted) {
      setState(() {
        _loading = false;
        if (result.isEmpty) {
          _error = 'Hesaplanamadı, tekrar dene';
        } else {
          _macros = result;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_macros == null) return;
    final entry = MealEntry(
      id: '',
      name: widget.mealName,
      calories: _macros!['calories']?.round() ?? 0,
      protein: _macros!['protein'] ?? 0,
      carbs: _macros!['carbs'] ?? 0,
      fat: _macros!['fat'] ?? 0,
      savedAt: DateTime.now(),
    );
    if (!mounted) return;
    Navigator.pop(context);
    final success = await MealCalendarService.saveMeal(entry, DateTime.now());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          success ? 'Takvime eklendi!' : 'Eklenemedi',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: success ? const Color(0xFF7B9CFF) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.now();
    final dateStr =
        '${d.day}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    return Material(
      color: Colors.transparent,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: const Color(0xFF7B9CFF).withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B9CFF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded,
                        color: Color(0xFF7B9CFF), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mealName,
                          style: GoogleFonts.urbanist(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Bugün ($dateStr) takvime eklenecek',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'Porsiyon ağırlığı',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gramsCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        suffixText: 'g',
                        suffixStyle: GoogleFonts.inter(
                            fontSize: 14, color: Colors.black45),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B9CFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Hesapla',
                              style: GoogleFonts.urbanist(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.red.shade300)),
              ],

              if (_macros != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B9CFF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF7B9CFF).withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${_macros!['calories']?.round()} kcal',
                            style: GoogleFonts.urbanist(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _MacroLabel('Protein',
                              '${_macros!['protein']?.round()}g',
                              const Color(0xFF6BCB77)),
                          _MacroLabel('Karb',
                              '${_macros!['carbs']?.round()}g',
                              const Color(0xFFFFD93D)),
                          _MacroLabel('Yağ',
                              '${_macros!['fat']?.round()}g',
                              const Color(0xFFFF6B6B)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: Colors.white.withOpacity(0.12)),
                        ),
                      ),
                      child: Text('İptal',
                          style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _macros != null ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _macros != null
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.1),
                        foregroundColor: _macros != null
                            ? AppColors.dark
                            : Colors.white.withOpacity(0.3),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Takvime Ekle',
                          style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroLabel(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color)),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
