import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../activity/views/activity_screen.dart';
import '../../recipes/views/recipes_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../chat/views/home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 3; // Chat default
  late PageController _pageController;

  // Siralama nav bar ile ayni: Aktivite, Tarif, Profil, Chat
  final List<Widget> _screens = const [
    ActivityScreen(),
    RecipesScreen(),
    ProfileScreen(),
    HomeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 3);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Nav bar boyutlari (bilesen olculerinden hesaplaniyor - responsive)
    const navBarVertPadding = 12.0 * 2; // symmetric vertical: 12
    const navBarContentHeight = 44.0; // en yuksek oge: Icon(24) + padding(10*2)
    const navBarHeight = navBarVertPadding + navBarContentHeight; // 68
    const navBarBottomPos = 24.0; // Positioned bottom degeri
    const contentGap = 8.0; // icerik ile bar arasi bosluk
    const navBarSpace = navBarBottomPos + navBarHeight + contentGap; // 100

    // Cihaz safe area'sindan buyuk olmasi garanti (responsive)
    final navBarReserved = math.max(navBarSpace, mediaQuery.padding.bottom);

    return Scaffold(
      backgroundColor: AppColors.dark,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Icerik - MediaQuery ile nav bar yuksekligi alt ekranlara iletiliyor
          MediaQuery(
            data: mediaQuery.copyWith(
              padding: mediaQuery.padding.copyWith(
                bottom: navBarReserved,
              ),
            ),
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _screens,
            ),
          ),

          // Nav bar arkasinda gradient (icerik yumusak sekilde kaybolur)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: navBarReserved + 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.dark.withOpacity(0.0),
                      AppColors.dark.withOpacity(0.8),
                      AppColors.dark,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Floating nav bar
          Positioned(
            left: 0,
            right: 0,
            bottom: navBarBottomPos,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkSoft,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNavItem(icon: Icons.bar_chart_rounded, index: 0),
            const SizedBox(width: 8),
            _buildNavItem(icon: Icons.restaurant_menu_rounded, index: 1),
            const SizedBox(width: 8),
            _buildNavItem(icon: Icons.person_outline_rounded, index: 2),
            const SizedBox(width: 12),
            _buildChatButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    final isSelected = _currentIndex == 3;

    return GestureDetector(
      onTap: () => _onTabTapped(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_rounded,
              size: 20,
              color: isSelected ? AppColors.dark : Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'Chat',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.dark : Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
