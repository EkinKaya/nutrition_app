import 'package:flutter/material.dart';
import 'package:nutrition_app/core/theme/app_theme.dart';
import 'package:nutrition_app/features/auth/views/splash_screen.dart';
import 'package:nutrition_app/features/auth/views/login_screen.dart';
import 'package:nutrition_app/features/auth/views/register_screen.dart';
import 'package:nutrition_app/features/chat/views/home_screen.dart';
import 'auth_gate.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Beslenmenin Arkadaşı',
      theme: AppTheme.lightTheme,

      // Routes
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/auth': (context) => const AuthGate(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}