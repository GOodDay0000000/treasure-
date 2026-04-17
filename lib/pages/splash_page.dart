// lib/pages/splash_page.dart
//
// 스플래시 화면: 다크/라이트 이미지 전체 배경.
// onboarding_done 플래그를 확인해 다음 화면으로 즉시 전환.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation_page.dart';
import 'onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => done ? const MainNavigationPage() : const OnboardingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/images/splash_dark.png'
        : 'assets/images/splash_light.png';
    final fallback = isDark
        ? const Color(0xFF0D1B2A)
        : const Color(0xFFF7F9FC);

    return Scaffold(
      backgroundColor: fallback,
      body: Image.asset(
        asset,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        // 이미지가 아직 없으면 배경 단색만 보이도록
        errorBuilder: (_, __, ___) => Container(color: fallback),
      ),
    );
  }
}
