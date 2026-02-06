import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../pages/splash_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Hira',
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}
