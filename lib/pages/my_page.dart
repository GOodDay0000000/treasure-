// lib/pages/my_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../l10n/app_strings.dart';
import '../services/experience_service.dart';
import 'book_select_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String _currentVersion = 'krv';
  double _fontSize        = 20.0;

  // 항해자 프로필
  int _exp = 0;
  String _nickname = '항해자';
  VoyagerGrade _grade = VoyagerGrade.all.first;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadProfile();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentVersion = prefs.getString('last_version') ?? 'krv';
      _fontSize       = prefs.getDouble('font_size') ?? 20.0;
    });
  }

  Future<void> _loadProfile() async {
    final exp = await ExperienceService.getExp();
    final nick = await ExperienceService.getNickname();
    if (!mounted) return;
    setState(() {
      _exp = exp;
      _nickname = nick;
      _grade = VoyagerGrade.fromExp(exp);
    });
  }

  Future<void> _editNickname() async {
    final ctrl = TextEditingController(text: _nickname);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B2D3F) : Colors.white,
        title: const Text('닉네임 수정'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 16,
          decoration: const InputDecoration(
            hintText: '항해자 이름',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('저장')),
        ],
      ),
    );
    if (result != null) {
      await ExperienceService.setNickname(result);
      await _loadProfile();
    }
  }

  Future<void> _confirmReset() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B2D3F) : Colors.white,
        title: const Text('⚠️ 항해 초기화'),
        content: const Text(
            '경험치·등급·읽은 장 기록이 모두 삭제됩니다. 북마크/형광펜/메모는 유지됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ExperienceService.resetAll();
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('항해가 초기화됐어요'),
        behavior: SnackBarBehavior.floating,
      ));
    }
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

          // ── 항해자 프로필 카드 ────────────────────────────
          _VoyagerCard(
            exp: _exp,
            grade: _grade,
            nickname: _nickname,
            onTapNickname: _editNickname,
            onReset: _confirmReset,
            isDark: isDark,
            cardBg: cardBg,
            text: text,
            sub: sub,
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

// ── 항해자 카드 ───────────────────────────────────────────────
class _VoyagerCard extends StatelessWidget {
  final int exp;
  final VoyagerGrade grade;
  final String nickname;
  final VoidCallback onTapNickname;
  final VoidCallback onReset;
  final bool isDark;
  final Color cardBg;
  final Color text;
  final Color sub;

  const _VoyagerCard({
    required this.exp,
    required this.grade,
    required this.nickname,
    required this.onTapNickname,
    required this.onReset,
    required this.isDark,
    required this.cardBg,
    required this.text,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC9A84C);
    final nextIdx = VoyagerGrade.all.indexOf(grade) + 1;
    final isMax = nextIdx >= VoyagerGrade.all.length;
    final next = isMax ? null : VoyagerGrade.all[nextIdx];
    final segExp = exp - grade.minExp;
    final segTotal = isMax ? 1 : (next!.minExp - grade.minExp);
    final pct = isMax ? 1.0 : (segExp / segTotal).clamp(0.0, 1.0);
    final remain = isMax ? 0 : (next!.minExp - exp);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: gold.withOpacity(0.35)),
                ),
                child: Center(
                  child: Text(grade.emoji,
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onTapNickname,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              nickname,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_rounded,
                              size: 13, color: sub),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${grade.name} · $exp EXP',
                      style: const TextStyle(
                          fontSize: 12,
                          color: gold,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: isDark
                  ? const Color(0xFF2C3E50)
                  : const Color(0xFFE5E5EA),
              valueColor: const AlwaysStoppedAnimation(gold),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                isMax
                    ? '최고 등급입니다 — 방주에 도달했어요'
                    : '다음 등급 ${next!.emoji} ${next.name}까지 $remain EXP',
                style: TextStyle(fontSize: 11, color: sub),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onReset,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 12, color: sub),
                      const SizedBox(width: 2),
                      Text('항해 초기화',
                          style: TextStyle(
                              fontSize: 10, color: sub)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
