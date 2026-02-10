import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Hira',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // fond sombre élégant
        cardTheme: CardThemeData(
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: const Color(0xFF1E293B), // cartes sombres
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white70,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const SplashScreen(), // ← on démarre directement sur ton splash screen réel
    );
  }
}