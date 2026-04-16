// lib/pages/my_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../l10n/app_strings.dart';
import 'book_select_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String _currentVersion = 'krv';
  double _fontSize        = 20.0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentVersion = prefs.getString('last_version') ?? 'krv';
      _fontSize       = prefs.getDouble('font_size') ?? 20.0;
    });
  }

  Future<void> _saveVersion(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_version', key);
    setState(() => _currentVersion = key);
  }

  Future<void> _toggleResearch() async {
    final prefs = await SharedPreferences.getInstance();
  }

  Future<void> _setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _fontSize = size);
    await prefs.setDouble('font_size', size);
  }

  void _showVersionSheet() {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final text    = isDark ? Colors.white : Colors.black;
    final sub     = const Color(0xFF8E8E93);
    final div     = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    final primary = Theme.of(context).colorScheme.primary;

    final groups = <String, List<BibleVersion>>{
      '한국어':  BookSelectPage.versions.where((v) => v.lang == 'ko').toList(),
      'English': BookSelectPage.versions.where((v) => v.lang == 'en').toList(),
      '中文':    BookSelectPage.versions.where((v) => v.lang == 'zh').toList(),
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: sub.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('번역본 선택',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text)),
              const SizedBox(height: 12),
              Divider(height: 1, color: div),
              ...groups.entries.expand((entry) => [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(entry.key,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sub)),
                  ),
                ),
                ...entry.value.map((v) {
                  final sel = v.key == _currentVersion;
                  return GestureDetector(
                    onTap: v.available ? () {
                      _saveVersion(v.key);
                      Navigator.pop(ctx);
                    } : null,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: sel ? primary : sub.withOpacity(0.4), width: 2),
                              color: sel ? primary : Colors.transparent,
                            ),
                            child: sel
                                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.name,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                                        color: v.available
                                            ? (sel ? primary : text)
                                            : sub)),
                                Text(v.desc,
                                    style: TextStyle(fontSize: 12, color: sub)),
                              ],
                            ),
                          ),
                          if (!v.available)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: sub.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('준비 중',
                                  style: TextStyle(fontSize: 11, color: sub)),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ]),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, Color primary,
      bool isDark, Color div, Color sub, Color text) {
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: sub.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('앱 언어 / App Language',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w600, color: text)),
              const SizedBox(height: 12),
              Divider(height: 1, color: div),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  itemCount: AppLanguage.values.length,
                  itemBuilder: (_, i) {
                    final lang = AppLanguage.values[i];
                    final sel  = AppLocale.current == lang;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        BibleApp.of(context)?.setLanguage(lang);
                        setState(() {});
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(children: [
                          Text(lang.flag,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(lang.label,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: sel
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: sel ? primary : text)),
                          ),
                          if (sel)
                            Icon(Icons.check_circle_rounded,
                                color: primary, size: 22),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final appState = BibleApp.of(context);
    final primary  = Theme.of(context).colorScheme.primary;
    final bg       = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F2F7);
    final cardBg   = isDark ? const Color(0xFF16213E) : Colors.white;
    final text     = isDark ? Colors.white : Colors.black;
    final sub      = const Color(0xFF8E8E93);
    final div      = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    // 현재 번역본 이름
    final versionName = BookSelectPage.versions
        .firstWhere((v) => v.key == _currentVersion,
            orElse: () => BookSelectPage.versions.first)
        .name;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocale.s.myPage,
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── 프로필 카드 ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: primary.withOpacity(0.15),
                  child: Icon(Icons.person_rounded, size: 30, color: primary),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('성경 앱',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: text)),
                    const SizedBox(height: 4),
                    Text(versionName,
                        style: TextStyle(fontSize: 13, color: sub)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 읽기 설정 ────────────────────────────────────────
          _Label(AppLocale.s.readingSettings, sub),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: cardBg, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                // 번역본
                _Tile(
                  icon: Icons.translate_rounded,
                  iconColor: primary,
                  title: AppLocale.s.translation,
                  divColor: div,
                  showDivider: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(versionName,
                          style: TextStyle(fontSize: 13, color: sub)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 18, color: sub),
                    ],
                  ),
                  onTap: _showVersionSheet,
                ),

                // 폰트 크기
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.format_size_rounded,
                            size: 18, color: primary),
                      ),
                      const SizedBox(width: 12),
                      Text(AppLocale.s.fontSize,
                          style: TextStyle(fontSize: 15, color: text)),
                      const Spacer(),
                      // 축소
                      GestureDetector(
                        onTap: () => _setFontSize((_fontSize - 2).clamp(12, 32)),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.remove_rounded, size: 16, color: sub),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${_fontSize.toInt()}',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: text)),
                      ),
                      // 확대
                      GestureDetector(
                        onTap: () => _setFontSize((_fontSize + 2).clamp(12, 32)),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add_rounded, size: 16, color: sub),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: div, indent: 60),


              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 언어 설정 ────────────────────────────────────────
          _Label(AppLocale.s.appLanguage, sub),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: cardBg, borderRadius: BorderRadius.circular(16)),
            child: _Tile(
              icon: Icons.language_rounded,
              iconColor: const Color(0xFF5C7FA3),
              title: AppLocale.s.appLanguage,
              divColor: div,
              showDivider: false,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${AppLocale.current.flag} ${AppLocale.current.label}',
                    style: TextStyle(fontSize: 13, color: sub),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: sub),
                ],
              ),
              onTap: () => _showLanguagePicker(context, primary, isDark, div, sub, text),
            ),
          ),

          const SizedBox(height: 24),

          // ── 화면 설정 ────────────────────────────────────────
          _Label(AppLocale.s.displaySettings, sub),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: cardBg, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _Tile(
                  icon: isDark
                      ? Icons.wb_sunny_rounded
                      : Icons.nightlight_round,
                  iconColor: isDark ? Colors.amber : Colors.blueGrey,
                  title: AppLocale.s.darkMode,
                  divColor: div,
                  showDivider: false,
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => appState?.toggleTheme(),
                    activeColor: primary,
                  ),
                  onTap: () => appState?.toggleTheme(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 앱 정보 ──────────────────────────────────────────
          _Label(AppLocale.s.appInfo, sub),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: cardBg, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _Tile(
                  icon: Icons.info_outline_rounded,
                  iconColor: primary,
                  title: AppLocale.s.version,
                  divColor: div,
                  showDivider: true,
                  trailing: Text('1.0.0',
                      style: TextStyle(fontSize: 13, color: sub)),
                  onTap: () {},
                ),
                _Tile(
                  icon: Icons.menu_book_rounded,
                  iconColor: Colors.green,
                  title: '수록 성경',
                  divColor: div,
                  showDivider: true,
                  trailing: Text('5개 번역본',
                      style: TextStyle(fontSize: 13, color: sub)),
                  onTap: () {},
                ),
                _Tile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF5C7FA3),
                  title: AppLocale.s.appLanguage + ' 지원',
                  divColor: div,
                  showDivider: false,
                  trailing: Text('한국어 · English · 中文',
                      style: TextStyle(fontSize: 12, color: sub)),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color divColor;
  final bool showDivider;
  final Widget trailing;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.divColor,
    required this.showDivider,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text   = isDark ? Colors.white : Colors.black;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: TextStyle(fontSize: 15, color: text)),
                ),
                trailing,
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: divColor, indent: 60),
      ],
    );
  }
}
