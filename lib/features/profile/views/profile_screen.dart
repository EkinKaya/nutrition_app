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
            final email = userData?['email'] ?? '';
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
                                email.isNotEmpty ? email[0].toUpperCase() : 'U',
                                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            email.split('@').first,
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.dark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.dark.withOpacity(0.6)),
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

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
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
                      Icon(
                        Icons.chevron_left,
                        color: Colors.white.withOpacity(0.2),
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
