import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/user_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: UserService.getUserProfileStream(),
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 30),

                  // Profile Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        email.isNotEmpty ? email[0].toUpperCase() : 'U',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 40),

                  _buildSectionTitle('Kişisel Bilgiler'),
                  const SizedBox(height: 16),

                  // Editable Info Cards
                  _buildEditableCard(
                    context: context,
                    icon: Icons.cake_outlined,
                    label: 'Yaş',
                    value: age != null ? '$age yaşında' : 'Belirtilmedi',
                    onTap: () => _showNumberEditDialog(
                      context: context,
                      title: 'Yaşınızı Girin',
                      field: 'age',
                      currentValue: age,
                      min: 18,
                      max: 100,
                      suffix: 'yaş',
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildEditableCard(
                    context: context,
                    icon: Icons.monitor_weight_outlined,
                    label: 'Kilo',
                    value: weight != null ? '$weight kg' : 'Belirtilmedi',
                    onTap: () => _showNumberEditDialog(
                      context: context,
                      title: 'Kilonuzu Girin',
                      field: 'weight',
                      currentValue: weight,
                      min: 30,
                      max: 200,
                      suffix: 'kg',
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildEditableCard(
                    context: context,
                    icon: Icons.height,
                    label: 'Boy',
                    value: height != null ? '$height cm' : 'Belirtilmedi',
                    onTap: () => _showNumberEditDialog(
                      context: context,
                      title: 'Boyunuzu Girin',
                      field: 'height',
                      currentValue: height,
                      min: 100,
                      max: 250,
                      suffix: 'cm',
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildEditableCard(
                    context: context,
                    icon: Icons.person_outline,
                    label: 'Cinsiyet',
                    value: gender ?? 'Belirtilmedi',
                    onTap: () => _showSelectionDialog(
                      context: context,
                      title: 'Cinsiyet Seçin',
                      field: 'gender',
                      currentValue: gender,
                      options: ['Erkek', 'Kadın', 'Belirtmek istemiyorum'],
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildEditableCard(
                    context: context,
                    icon: Icons.restaurant_outlined,
                    label: 'Beslenme Tercihi',
                    value: dietType ?? 'Belirtilmedi',
                    onTap: () => _showSelectionDialog(
                      context: context,
                      title: 'Beslenme Tercihi Seçin',
                      field: 'dietType',
                      currentValue: dietType,
                      options: ['Her şey', 'Vejetaryen', 'Vegan', 'Pesketaryen'],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'PROFİL',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        IconButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
          },
          icon: const Icon(
            Icons.logout_rounded,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildEditableCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
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
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: selectedValue > min
                        ? () => setState(() => selectedValue--)
                        : null,
                    icon: Icon(
                      Icons.remove_circle_outline,
                      size: 36,
                      color: selectedValue > min
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '$selectedValue $suffix',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: selectedValue < max
                        ? () => setState(() => selectedValue++)
                        : null,
                    icon: Icon(
                      Icons.add_circle_outline,
                      size: 36,
                      color: selectedValue < max
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Kaydet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
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
                    color: currentValue == option
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentValue == option
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: currentValue == option
                                ? AppColors.dark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (currentValue == option)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.dark,
                          size: 22,
                        ),
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
