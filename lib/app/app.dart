import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrition_app/core/theme/app_theme.dart';
import 'package:nutrition_app/features/auth/screens/splash_screen.dart';
import 'package:nutrition_app/features/auth/screens/login_screen.dart';
import 'package:nutrition_app/features/auth/screens/register_screen.dart';
import 'package:nutrition_app/features/home/screens/home_screen.dart';
import 'package:nutrition_app/shared/providers/character_position_provider.dart';
import 'auth_gate.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CharacterPositionProvider()),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}