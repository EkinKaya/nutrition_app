import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/metric_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Kullanıcı';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROFILE',
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
              ),

              const SizedBox(height: 30),

              // İsim
              Text(
                userName,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '25 yaşında',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Daily Goals başlığı
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Daily Goals',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Metric cards
              MetricCard(
                icon: Icons.local_fire_department,
                label: 'Calories',
                value: '2,000',
                gradient: AppColors.primaryGradient,
              ),
              
              const SizedBox(height: 12),
              
              MetricCard(
                icon: Icons.directions_walk,
                label: 'Steps',
                value: '3,500',
                gradient: AppColors.primaryGradient,
              ),

              const SizedBox(height: 12),

              MetricCard(
                icon: Icons.bedtime,
                label: 'Sleep',
                value: '8h',
                gradient: AppColors.primaryGradient,
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}