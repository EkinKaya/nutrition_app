import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/meal_calendar_service.dart';

class PortionDialog extends StatefulWidget {
  final String mealName;
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
  final _calCtrl  = TextEditingController();
  final _protCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl  = TextEditingController();

  bool _loading = false;
  String? _error;

  bool get _canSave =>
      _calCtrl.text.trim().isNotEmpty &&
      _protCtrl.text.trim().isNotEmpty &&
      _carbCtrl.text.trim().isNotEmpty &&
      _fatCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Her field değişince "Takvime Ekle" butonunu yenile
    for (final c in [_calCtrl, _protCtrl, _carbCtrl, _fatCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _calCtrl.dispose();
    _protCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _calculate() async {
    final grams = int.tryParse(_gramsCtrl.text.trim());
    if (grams == null || grams <= 0) {
      setState(() => _error = 'Geçerli bir gram değeri gir');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final result = await GeminiService.getNutritionalInfo(
      widget.foodDescription,
      grams,
      userValues: {
        'calories': _parse(_calCtrl),
        'protein':  _parse(_protCtrl),
        'carbs':    _parse(_carbCtrl),
        'fat':      _parse(_fatCtrl),
      },
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isEmpty) {
        _error = 'AI şu an yanıt vermiyor. Değerleri manuel girebilirsin.';
      } else {
        // Boş alanları AI değeriyle doldur; dolu olanları koru
        if (_calCtrl.text.trim().isEmpty)
          _calCtrl.text = result['calories']!.round().toString();
        if (_protCtrl.text.trim().isEmpty)
          _protCtrl.text = result['protein']!.toStringAsFixed(1);
        if (_carbCtrl.text.trim().isEmpty)
          _carbCtrl.text = result['carbs']!.toStringAsFixed(1);
        if (_fatCtrl.text.trim().isEmpty)
          _fatCtrl.text = result['fat']!.toStringAsFixed(1);
        _error = null;
      }
    });
  }

  Future<void> _save() async {
    final cal  = _parse(_calCtrl)  ?? 0;
    final prot = _parse(_protCtrl) ?? 0;
    final carb = _parse(_carbCtrl) ?? 0;
    final fat  = _parse(_fatCtrl)  ?? 0;

    final entry = MealEntry(
      id: '',
      name: widget.mealName,
      calories: cal.round(),
      protein: prot,
      carbs: carb,
      fat: fat,
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

    final maxH = MediaQuery.of(context).size.height * 0.82;

    return Material(
      color: Colors.transparent,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: const Color(0xFF7B9CFF).withOpacity(0.2)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
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

                const SizedBox(height: 18),

                // ── Gram + Hesapla ───────────────────────────────────
                _SectionLabel('Porsiyon ağırlığı'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _WhiteField(
                        ctrl: _gramsCtrl,
                        suffix: 'g',
                        numeric: true,
                        decimal: false,
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
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                      ),
                    ),
                  ],
                ),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.orange.shade300)),
                ],

                const SizedBox(height: 18),
                Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 16),

                // ── Besin değerleri ──────────────────────────────────
                _SectionLabel('Besin değerleri'),
                const SizedBox(height: 4),
                Text(
                  'AI hesaplar veya kendin girebilirsin',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.3)),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _WhiteField(
                          ctrl: _calCtrl,
                          label: 'Kalori',
                          suffix: 'kcal'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _WhiteField(
                          ctrl: _protCtrl,
                          label: 'Protein',
                          suffix: 'g'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _WhiteField(
                          ctrl: _carbCtrl,
                          label: 'Karb',
                          suffix: 'g'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _WhiteField(
                          ctrl: _fatCtrl,
                          label: 'Yağ',
                          suffix: 'g'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Butonlar ─────────────────────────────────────────
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
                        onPressed: _canSave ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canSave
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.08),
                          foregroundColor: _canSave
                              ? AppColors.dark
                              : Colors.white.withOpacity(0.25),
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
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
        ), // ConstrainedBox
      ),
    );
  }
}

// ── Yardımcı widget'lar ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.5)),
      );
}

class _WhiteField extends StatelessWidget {
  final TextEditingController ctrl;
  final String? label;
  final String suffix;
  final bool numeric;
  final bool decimal;

  const _WhiteField({
    required this.ctrl,
    this.label,
    required this.suffix,
    this.numeric = true,
    this.decimal = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric
          ? (decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number)
          : TextInputType.text,
      style: GoogleFonts.inter(
          fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.inter(fontSize: 11, color: Colors.black45),
        suffixText: suffix,
        suffixStyle:
            GoogleFonts.inter(fontSize: 12, color: Colors.black45),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
