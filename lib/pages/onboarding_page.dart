// lib/pages/onboarding_page.dart
//
// 최초 실행 온보딩 4단계: 환영 → 언어 → 번역본 → 알림

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import 'book_select_page.dart';
import 'main_navigation_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pc = PageController();
  int _step = 0;

  AppLanguage _selectedLang = AppLanguage.ko;
  String _selectedVersion = 'krv';
  bool _notifAllow = true;

  @override
  void initState() {
    super.initState();
    _selectedLang = AppLocale.current;
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      _pc.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setString('last_version', _selectedVersion);
    await prefs.setBool('notification_allow', _notifAllow);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);
    final gold = const Color(0xFFC9A84C);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // 단계 점
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final active = i == _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? gold
                          : (isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _WelcomeStep(isDark: isDark),
                  _LanguageStep(
                    selected: _selectedLang,
                    onSelect: (lang) {
                      setState(() => _selectedLang = lang);
                      BibleApp.of(context)?.setLanguage(lang);
                    },
                    isDark: isDark,
                  ),
                  _VersionStep(
                    selected: _selectedVersion,
                    onSelect: (key) => setState(() => _selectedVersion = key),
                    isDark: isDark,
                  ),
                  _NotifStep(
                    allow: _notifAllow,
                    onChange: (v) => setState(() => _notifAllow = v),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            // 하단 액션
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => _pc.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut),
                      child: Text('이전',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : Colors.black54)),
                    )
                  else
                    const SizedBox(width: 64),
                  const Spacer(),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: const Color(0xFF0D1B2A),
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _step == 0
                            ? '시작하기'
                            : _step == 3
                                ? '완료'
                                : '다음',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 1단계: 환영 ───────────────────────────────────────────────
class _WelcomeStep extends StatelessWidget {
  final bool isDark;
  const _WelcomeStep({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFC9A84C);
    final textColor = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.white70 : Colors.black54;
    final splashAsset = isDark
        ? 'assets/images/splash_dark.png'
        : 'assets/images/splash_light.png';

    return Stack(
      children: [
        // 스플래시 이미지 재사용 (있을 때만)
        Positioned.fill(
          child: Image.asset(
            splashAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(),
          ),
        ),
        // 가독성 위해 하단 그라데이션
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  (isDark ? const Color(0xFF0D1B2A) : Colors.white)
                      .withOpacity(0.85),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.anchor_rounded, size: 22, color: gold),
                    const SizedBox(width: 10),
                    Text('Treasure',
                        style: GoogleFonts.dancingScript(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: gold)),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Treasure에 오신 것을 환영합니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                const SizedBox(height: 10),
                Text('말씀이라는 보물을 찾아 함께 항해해요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: subColor, height: 1.6)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 2단계: 언어 선택 ─────────────────────────────────────────
class _LanguageStep extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelect;
  final bool isDark;
  const _LanguageStep({
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFC9A84C);
    final textColor = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.white60 : Colors.black54;
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('언어를 선택해주세요',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor)),
          const SizedBox(height: 6),
          Text('앱 전체에 적용되며 언제든 변경할 수 있어요',
              style: TextStyle(fontSize: 13, color: sub)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              itemCount: AppLanguage.values.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (_, i) {
                final lang = AppLanguage.values[i];
                final sel = lang == selected;
                return GestureDetector(
                  onTap: () => onSelect(lang),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: sel ? gold.withOpacity(0.15) : cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel
                            ? gold
                            : (isDark
                                ? const Color(0xFF2C3E50)
                                : const Color(0xFFE5E5EA)),
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(lang.flag,
                            style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            lang.label,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: sel ? gold : textColor),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3단계: 번역본 선택 ───────────────────────────────────────
class _VersionStep extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final bool isDark;
  const _VersionStep({
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFC9A84C);
    final textColor = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.white60 : Colors.black54;
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;

    final available =
        BookSelectPage.versions.where((v) => v.available).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('번역본을 선택해주세요',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor)),
          const SizedBox(height: 6),
          Text('기본 번역본이에요. 마이페이지에서 언제든 바꿀 수 있어요',
              style: TextStyle(fontSize: 13, color: sub)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: available.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final v = available[i];
                final sel = v.key == selected;
                return GestureDetector(
                  onTap: () => onSelect(v.key),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sel ? gold.withOpacity(0.12) : cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel
                            ? gold
                            : (isDark
                                ? const Color(0xFF2C3E50)
                                : const Color(0xFFE5E5EA)),
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: sel ? gold : sub, width: 2),
                            color: sel ? gold : Colors.transparent,
                          ),
                          child: sel
                              ? const Icon(Icons.check_rounded,
                                  size: 14,
                                  color: Color(0xFF0D1B2A))
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.name,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? gold : textColor)),
                              const SizedBox(height: 2),
                              Text(v.desc,
                                  style: TextStyle(
                                      fontSize: 12, color: sub)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4단계: 알림 ───────────────────────────────────────────────
class _NotifStep extends StatelessWidget {
  final bool allow;
  final ValueChanged<bool> onChange;
  final bool isDark;
  const _NotifStep({
    required this.allow,
    required this.onChange,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFC9A84C);
    final textColor = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.white60 : Colors.black54;
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_active_rounded,
              size: 72, color: gold.withOpacity(0.9)),
          const SizedBox(height: 18),
          Text('매일 말씀 알림을 받으시겠어요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor)),
          const SizedBox(height: 8),
          Text('잊지 않고 말씀을 만날 수 있도록 도와드려요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: sub)),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChange(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: allow ? gold.withOpacity(0.14) : cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: allow ? gold : const Color(0xFFE5E5EA),
                        width: allow ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: allow ? gold : sub, size: 28),
                        const SizedBox(height: 6),
                        Text('허용',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: allow ? gold : textColor)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChange(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: !allow ? gold.withOpacity(0.14) : cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: !allow ? gold : const Color(0xFFE5E5EA),
                        width: !allow ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.schedule_rounded,
                            color: !allow ? gold : sub, size: 28),
                        const SizedBox(height: 6),
                        Text('나중에',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: !allow ? gold : textColor)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('* 실제 알림은 이후 버전에서 활성화됩니다',
              style: TextStyle(fontSize: 11, color: sub)),
        ],
      ),
    );
  }
}
