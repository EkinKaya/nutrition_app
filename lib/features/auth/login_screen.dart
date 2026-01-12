import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'register_screen.dart';
import '../../app/auth_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  static const String appName = 'Nutrition App';

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  late final AnimationController _bgCtrl;
  late final AnimationController _taglineCtrl;

  final List<String> _taglines = const [
    'Personalize meals. Track habits.',
    'Eat smart. Stay consistent.',
    'Recipes that fit your day.',
    'Small steps, real results.',
  ];

  int _tagIndex = 0;

  @override
  void initState() {
    super.initState();

    // Arka plan “yüzen” glow hareketi
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Logo altı yazı değişimi (abartısız)
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    // Döngü: her 2.5 sn’de bir tagline değişsin
    Future<void>.delayed(const Duration(milliseconds: 900), _cycleTagline);
  }

  void _cycleTagline() {
    if (!mounted) return;

    _taglineCtrl.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _tagIndex = (_tagIndex + 1) % _taglines.length);
      _taglineCtrl.reverse(from: 1);
    });

    Future<void>.delayed(const Duration(milliseconds: 2500), _cycleTagline);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _bgCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final msg = switch (e.code) {
        'user-not-found' => 'Bu email ile kullanıcı yok.',
        'wrong-password' => 'Şifre hatalı.',
        'invalid-email' => 'Email formatı hatalı.',
        'user-disabled' => 'Bu kullanıcı devre dışı.',
        _ => 'Giriş başarısız: ${e.message ?? e.code}',
      };

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToRegister() {
    Navigator.of(context).push(_slideRoute(const RegisterScreen(), fromRight: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (context, _) {
          final t = _bgCtrl.value;

          return _AuthBackground(
            t: t,
            child: SafeArea(
              child: Stack(
                children: [
                  // Üst kısım: logo + başlık + değişen tagline
                  Positioned(
                    top: 18,
                    left: 18,
                    right: 18,
                    child: _Header(
                      appName: appName,
                      tagline: _taglines[_tagIndex],
                      progress: _taglineCtrl.value,
                    ),
                  ),

                  // Form card (asimetrik konum: biraz aşağı, biraz sağa)
                  Align(
                    alignment: const Alignment(0.12, 0.25),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _GlassCard(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Giriş yap ve kişisel planına devam et.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.72),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 18),

                              _LabeledField(
                                label: 'Email',
                                child: _InputField(
                                  controller: _emailCtrl,
                                  hintText: 'ornek@mail.com',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.mail_outline_rounded,
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return 'Email boş olamaz';
                                    if (!value.contains('@')) return 'Geçerli bir email gir';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),

                              _LabeledField(
                                label: 'Password',
                                child: _InputField(
                                  controller: _passCtrl,
                                  hintText: '••••••••',
                                  obscureText: _obscure,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      color: Colors.white.withOpacity(0.78),
                                    ),
                                  ),
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return 'Şifre boş olamaz';
                                    if (value.length < 6) return 'En az 6 karakter';
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Asimetrik buton satırı:
                              // Sol: küçük “secondary circle”
                              // Sağ: büyük neon pill
                              Row(
                                children: [
                                  _CircleAction(
                                    tooltip: 'Demo',
                                    onTap: _loading ? null : () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Buraya Google giriş eklenebilir.')),
                                      );
                                    },
                                    icon: Icons.auto_awesome_rounded,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _PrimaryPillButton(
                                      text: 'Giriş Yap',
                                      loading: _loading,
                                      onPressed: _loading ? null : _login,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _goToRegister,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white.withOpacity(0.85),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text(
                                    'Üye değil misin? Kayıt ol',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Alt tarafta “soft” dekoratif bir bar (sade)
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Opacity(
                      opacity: 0.55,
                      child: Row(
                        children: [
                          Container(
                            height: 3,
                            width: 54,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB7F06A),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Slide route helper
Route _slideRoute(Widget page, {required bool fromRight}) {
  final begin = Offset(fromRight ? 1 : -1, 0);
  const end = Offset.zero;
  const curve = Curves.easeOutCubic;

  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

/* ---------------- UI BLOCKS ---------------- */

class _AuthBackground extends StatelessWidget {
  const _AuthBackground({required this.t, required this.child});
  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // “Hareketli” hissi: glow’ların pozisyonu t ile kayıyor.
    final shiftA = lerpDouble(-0.7, 0.9, t)!;
    final shiftB = lerpDouble(0.8, -0.6, t)!;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF061510), Color(0xFF0B2A21), Color(0xFF071A14)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -90,
            child: _GlowBlob(color: const Color(0xFFB7F06A).withOpacity(0.18), size: 260),
          ),
          Positioned(
            top: 90 + 60 * sin(t * pi),
            left: -100 + 40 * cos(t * pi),
            child: _GlowBlob(color: Colors.white.withOpacity(0.08), size: 220),
          ),
          Positioned(
            bottom: -140,
            left: -70,
            child: _GlowBlob(color: const Color(0xFF7AE6C8).withOpacity(0.10), size: 320),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment(shiftA, -0.1),
              child: _SoftPill(width: 210, height: 76, opacity: 0.08),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment(shiftB, 0.55),
              child: _SoftPill(width: 260, height: 92, opacity: 0.06),
            ),
          ),
          Positioned.fill(child: _NoiseOverlay(opacity: 0.045)),
          child,
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.appName,
    required this.tagline,
    required this.progress,
  });

  final String appName;
  final String tagline;
  final double progress; // 0..1 (tagline crossfade-ish)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // “Logo” (şimdilik ikon + glow)
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: const Icon(Icons.eco_rounded, color: Color(0xFFB7F06A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appName,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              // Tagline anim: AnimatedSwitcher yerine progress ile “kayma + fade”
              ClipRect(
                child: Transform.translate(
                  offset: Offset(0, lerpDouble(6, 0, 1 - progress)!),
                  child: Opacity(
                    opacity: lerpDouble(0.35, 1.0, 1 - progress)!,
                    child: Text(
                      tagline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.72),
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sağ üst “badge” gibi küçük ikon
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Icon(Icons.tune_rounded, color: Colors.white.withOpacity(0.78)),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(blurRadius: 70, spreadRadius: 16, color: color)],
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  const _SoftPill({required this.width, required this.height, required this.opacity});
  final double width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(opacity + 0.03)),
      ),
    );
  }
}

class _NoiseOverlay extends StatelessWidget {
  const _NoiseOverlay({required this.opacity});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
      child: Container(color: Colors.white.withOpacity(opacity)),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
        prefixIcon: Icon(prefixIcon, color: Colors.white.withOpacity(0.72)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: base,
        focusedBorder: base.copyWith(
          borderSide: const BorderSide(color: Color(0xFFB7F06A), width: 1.2),
        ),
        errorBorder: base.copyWith(
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.9)),
        ),
        focusedErrorBorder: base.copyWith(
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.9)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({
    required this.text,
    required this.loading,
    required this.onPressed,
  });

  final String text;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Asimetrik hissi için: pill butonun arkasına hafif “offset” glow katmanı
    return Stack(
      children: [
        Positioned(
          left: 10,
          right: -10,
          top: 8,
          bottom: -8,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFB7F06A).withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB7F06A),
              foregroundColor: const Color(0xFF0F1A14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.tooltip,
    required this.onTap,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.82)),
        ),
      ),
    );
  }
}
