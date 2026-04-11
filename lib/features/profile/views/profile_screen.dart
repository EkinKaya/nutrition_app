import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  int? _swipedIndex;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;

  @override
  void initState() {
    super.initState();
    _profileStream = UserService.getUserProfileStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _profileStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final userData = snapshot.data?.data();
            final email = userData?['email'] as String? ?? FirebaseAuth.instance.currentUser?.email ?? '';
            final firebaseDisplayName = FirebaseAuth.instance.currentUser?.displayName;
            final displayName = (firebaseDisplayName != null && firebaseDisplayName.isNotEmpty)
                ? firebaseDisplayName
                : (userData?['displayName'] as String? ?? email.split('@').first);
            final age = userData?['age'];
            final weight = userData?['weight'];
            final height = userData?['height'];
            final gender = userData?['gender'];
            final dietType = userData?['dietType'];
            final pdfName = userData?['pdfName'];

            final infoItems = [
              _InfoItem(icon: Icons.cake_outlined, label: 'Yas', value: age != null ? '$age' : '--', suffix: 'yasinda', field: 'age', isNumber: true, min: 18, max: 100, numSuffix: 'yas'),
              _InfoItem(icon: Icons.monitor_weight_outlined, label: 'Kilo', value: weight != null ? '$weight' : '--', suffix: 'kg', field: 'weight', isNumber: true, min: 30, max: 200, numSuffix: 'kg'),
              _InfoItem(icon: Icons.height, label: 'Boy', value: height != null ? '$height' : '--', suffix: 'cm', field: 'height', isNumber: true, min: 100, max: 250, numSuffix: 'cm'),
              _InfoItem(icon: Icons.person_outline, label: 'Cinsiyet', value: gender ?? 'Belirtilmedi', suffix: '', field: 'gender', isNumber: false, options: ['Erkek', 'Kadin', 'Belirtmek istemiyorum']),
              _InfoItem(icon: Icons.restaurant_outlined, label: 'Beslenme', value: dietType ?? 'Belirtilmedi', suffix: '', field: 'dietType', isNumber: false, options: ['Her sey', 'Vejetaryen', 'Vegan', 'Pesketaryen']),
            ];

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PROFIL',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 2,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showLogoutConfirmation(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.7), size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Card - Lime Green
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: AppColors.dark,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _showAccountEditDialog(context, email),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      displayName,
                                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.dark),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.edit_outlined, size: 16, color: AppColors.dark.withOpacity(0.5)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.dark.withOpacity(0.6)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // PDF Upload Area
                          GestureDetector(
                            onTap: _isUploading ? null : () => _pickAndUploadPdf(context),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.dark.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.dark.withOpacity(0.2), width: 1),
                              ),
                              child: _isUploading
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.dark),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Yukleniyor...',
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: AppColors.dark,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pdfName != null ? 'Kan Testi Sonucu' : 'PDF Yukle',
                                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                                              ),
                                              if (pdfName != null)
                                                Text(
                                                  pdfName,
                                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.dark.withOpacity(0.6)),
                                                  overflow: TextOverflow.ellipsis,
                                                )
                                              else
                                                Text(
                                                  'Kan testi sonucunuzu yukleyin',
                                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.dark.withOpacity(0.6)),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (pdfName != null) ...[
                                          GestureDetector(
                                            onTap: () => _showDeletePdfDialog(context),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: AppColors.dark.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.close, color: AppColors.dark.withOpacity(0.8), size: 16),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Icon(
                                          pdfName != null ? Icons.refresh : Icons.upload_file_outlined,
                                          color: AppColors.dark.withOpacity(0.8),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Section Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'KISISEL BILGILER',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5), letterSpacing: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Cards - swipeable
                  ...List.generate(infoItems.length, (index) {
                    final item = infoItems[index];
                    final currentValue = item.isNumber
                        ? (item.field == 'age' ? age : item.field == 'weight' ? weight : height)
                        : (item.field == 'gender' ? gender : dietType);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
                      child: _buildSwipeableCard(
                        context: context,
                        index: index,
                        item: item,
                        currentValue: currentValue,
                      ),
                    );
                  }),

                  // BMI Card
                  if (weight != null && height != null)
                    _buildBmiCard(weight, height),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBmiCard(dynamic weight, dynamic height) {
    final w = (weight as num).toDouble();
    final h = (height as num).toDouble();
    final bmi = w / ((h / 100) * (h / 100));
    final bmiStr = bmi.toStringAsFixed(1);

    String category;
    Color color;
    String emoji;
    if (bmi < 18.5) {
      category = 'Zayıf';
      color = const Color(0xFF7B9CFF);
      emoji = '📉';
    } else if (bmi < 25) {
      category = 'Normal';
      color = AppColors.primary;
      emoji = '✅';
    } else if (bmi < 30) {
      category = 'Fazla Kilolu';
      color = Colors.orange;
      emoji = '⚠️';
    } else {
      category = 'Obez';
      color = Colors.red;
      emoji = '🔴';
    }

    // Bar position (15–40 range mapped to 0–1)
    final barPos = ((bmi - 15) / 25).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.monitor_heart_outlined, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vücut Kitle İndeksi (BMI)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            bmiStr,
                            style: GoogleFonts.urbanist(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$emoji $category',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // BMI spectrum bar
            LayoutBuilder(builder: (ctx, constraints) {
              final totalW = constraints.maxWidth;
              final indicatorX = (barPos * totalW).clamp(0.0, totalW - 3);
              return SizedBox(
                height: 16,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 4,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 8,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF7B9CFF),
                                Color(0xFF6BCB77),
                                Colors.orange,
                                Colors.red,
                              ],
                              stops: [0.0, 0.35, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: indicatorX,
                      child: Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            // Scale labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('15', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.3))),
                Text('18.5', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.3))),
                Text('25', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.3))),
                Text('30', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.3))),
                Text('40+', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.3))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeableCard({
    required BuildContext context,
    required int index,
    required _InfoItem item,
    required dynamic currentValue,
  }) {
    final isExpanded = _swipedIndex == index;
    const double editWidth = 80.0;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) {
            setState(() => _swipedIndex = index);
          } else if (details.primaryVelocity! > 100) {
            setState(() => _swipedIndex = null);
          }
        }
      },
      onTap: () {
        if (isExpanded) setState(() => _swipedIndex = null);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 92,
          child: Stack(
            children: [
              // Edit button behind (right side)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: editWidth,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _swipedIndex = null);
                    if (item.isNumber) {
                      _showNumberEditDialog(
                        context: context,
                        title: '${item.label} Girin',
                        field: item.field,
                        currentValue: currentValue as int?,
                        min: item.min ?? 0,
                        max: item.max ?? 100,
                        suffix: item.numSuffix ?? '',
                      );
                    } else {
                      _showSelectionDialog(
                        context: context,
                        title: '${item.label} Secin',
                        field: item.field,
                        currentValue: currentValue as String?,
                        options: item.options ?? [],
                      );
                    }
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                    ),
                    child: const Center(
                      child: Icon(Icons.edit_outlined, color: AppColors.dark, size: 24),
                    ),
                  ),
                ),
              ),
              // Main card (slides left)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: isExpanded ? -editWidth : 0,
                right: isExpanded ? editWidth : 0,
                top: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSoft,
                    border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.label,
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(item.value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                                if (item.suffix.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Text(item.suffix, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.5))),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _swipedIndex = isExpanded ? null : index);
                        },
                        child: Icon(
                          isExpanded ? Icons.chevron_right : Icons.chevron_left,
                          color: Colors.white.withOpacity(0.3),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() => _isUploading = true);

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;

    final url = await UserService.uploadPdf(file, fileName);

    if (mounted) {
      setState(() => _isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            url != null ? 'PDF basariyla yuklendi' : 'PDF yuklenirken hata olustu',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: url != null ? AppColors.primaryDark : Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showDeletePdfDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.darkSoft,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('PDF\'i Sil', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Yuklu PDF dosyasini silmek istediginize emin misiniz?', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.6)), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text('Iptal', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await UserService.deletePdf();
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text('Sil', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAccountEditDialog(BuildContext context, String currentEmail) {
    final user = FirebaseAuth.instance.currentUser;
    // Google ile giriş yapıldıysa sadece kullanıcı adı göster
    final isGoogleUser = user?.providerData
            .any((p) => p.providerId == 'google.com') ??
        false;

    final displayNameCtrl =
        TextEditingController(text: user?.displayName ?? currentEmail.split('@').first);
    final emailCtrl = TextEditingController(text: currentEmail);
    final passwordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    bool obscurePass = true;
    bool obscureNew = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            decoration: const BoxDecoration(
              color: AppColors.darkSoft,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Hesap Bilgileri',
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 18),

                // Kullanıcı adı
                _buildEditField(
                  label: 'Kullanıcı Adı',
                  controller: displayNameCtrl,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),

                if (!isGoogleUser) ...[
                  // Email
                  _buildEditField(
                    label: 'E-posta',
                    controller: emailCtrl,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),

                  // Mevcut şifre
                  _buildEditField(
                    label: 'Mevcut Şifre',
                    controller: passwordCtrl,
                    icon: Icons.lock_outline,
                    obscure: obscurePass,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.black54, size: 18,
                      ),
                      onPressed: () => setS(() => obscurePass = !obscurePass),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Yeni şifre
                  _buildEditField(
                    label: 'Yeni Şifre',
                    controller: newPasswordCtrl,
                    icon: Icons.lock_outline,
                    obscure: obscureNew,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.black54, size: 18,
                      ),
                      onPressed: () => setS(() => obscureNew = !obscureNew),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'E-posta veya şifre değiştirmek için mevcut şifreni gir.',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.35)),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(Icons.g_mobiledata_rounded, color: Colors.white.withOpacity(0.4), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Google hesabıyla giriş yapıldı',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _saveAccountChanges(
                        context: context,
                        displayName: displayNameCtrl.text.trim(),
                        newEmail: isGoogleUser ? null : emailCtrl.text.trim(),
                        currentPassword: passwordCtrl.text,
                        newPassword: newPasswordCtrl.text.isNotEmpty ? newPasswordCtrl.text : null,
                        currentEmail: currentEmail,
                        isGoogleUser: isGoogleUser,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.dark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Kaydet', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.black54, size: 18),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAccountChanges({
    required BuildContext context,
    required String displayName,
    required String? newEmail,
    required String currentPassword,
    required String? newPassword,
    required String currentEmail,
    required bool isGoogleUser,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Kullanıcı adını güncelle
      if (displayName.isNotEmpty && displayName != user.displayName) {
        await user.updateDisplayName(displayName);
        // Firestore'da da güncelle
        await UserService.updateUserProfile({'displayName': displayName});
      }

      if (!isGoogleUser && currentPassword.isNotEmpty) {
        // Mevcut şifre ile yeniden doğrula
        final credential = EmailAuthProvider.credential(
          email: currentEmail,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // Email değiştir
        if (newEmail != null && newEmail.isNotEmpty && newEmail != currentEmail) {
          await user.verifyBeforeUpdateEmail(newEmail);
          await UserService.updateUserProfile({'email': newEmail});
        }

        // Şifre değiştir
        if (newPassword != null && newPassword.length >= 6) {
          await user.updatePassword(newPassword);
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Bilgiler güncellendi', style: GoogleFonts.inter()),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String msg = 'Güncelleme başarısız';
        if (e.code == 'wrong-password') msg = 'Mevcut şifre yanlış';
        else if (e.code == 'requires-recent-login') msg = 'Lütfen tekrar giriş yapın';
        else if (e.code == 'email-already-in-use') msg = 'Bu e-posta zaten kullanımda';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.darkSoft,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Cikis Yap', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Hesabinizdan cikmak istediginize emin misiniz?', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.6)), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text('Iptal', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      }
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text('Cikis Yap', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showNumberEditDialog({
    required BuildContext context,
    required String title,
    required String field,
    required int? currentValue,
    required int min,
    required int max,
    required String suffix,
  }) {
    int selectedValue = currentValue ?? ((min + max) ~/ 2);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.darkSoft,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '$selectedValue $suffix',
                  style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.dark),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircleButton(icon: Icons.remove, enabled: selectedValue > min, onTap: () => setState(() => selectedValue--)),
                  const SizedBox(width: 48),
                  _buildCircleButton(icon: Icons.add, enabled: selectedValue < max, onTap: () => setState(() => selectedValue++)),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await UserService.updateUserProfile({field: selectedValue});
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.dark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Kaydet', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: enabled ? AppColors.primary : Colors.white.withOpacity(0.1), width: 2),
        ),
        child: Icon(icon, color: enabled ? AppColors.primary : Colors.white.withOpacity(0.3), size: 28),
      ),
    );
  }

  void _showSelectionDialog({
    required BuildContext context,
    required String title,
    required String field,
    required String? currentValue,
    required List<String> options,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.darkSoft,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 24),
            ...options.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () async {
                  await UserService.updateUserProfile({field: option});
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: currentValue == option ? AppColors.primary : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: currentValue == option ? AppColors.primary : Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: currentValue == option ? AppColors.dark : Colors.white),
                        ),
                      ),
                      if (currentValue == option)
                        const Icon(Icons.check_circle, color: AppColors.dark, size: 22),
                    ],
                  ),
                ),
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final String suffix;
  final String field;
  final bool isNumber;
  final int? min;
  final int? max;
  final String? numSuffix;
  final List<String>? options;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.suffix,
    required this.field,
    required this.isNumber,
    this.min,
    this.max,
    this.numSuffix,
    this.options,
  });
}
