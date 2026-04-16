// lib/pages/activity_page.dart

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../services/bookmark_service.dart';
import '../services/highlight_service.dart';
import '../services/memo_service.dart';
import 'bookmark_page.dart';
import 'highlight_list_page.dart';
import 'memo_list_page.dart';
import 'dictionary_page.dart';
import 'search_page.dart';
import 'my_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  int _bookmarkCount  = 0;
  int _highlightCount = 0;
  int _memoCount      = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCounts();
  }

  void _loadCounts() {
    setState(() {
      _bookmarkCount  = BookmarkService.getAll().length;
      _highlightCount = HighlightService.getAll().length;
      _memoCount      = MemoService.getAll().length;
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _push(Widget page) {
    Navigator.push(context,
            MaterialPageRoute(builder: (_) => page))
        .then((_) => _loadCounts());
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final primary  = Theme.of(context).colorScheme.primary;
    final appState = BibleApp.of(context);
    final bg       = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F2F7);
    final cardBg   = isDark ? const Color(0xFF16213E) : Colors.white;
    final text     = isDark ? Colors.white : Colors.black;
    final sub      = const Color(0xFF8E8E93);
    final div      = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('활동',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          // 다크모드 토글
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: sub,
              size: 22,
            ),
            onPressed: () => appState?.toggleTheme(),
          ),
          // 마이페이지
          GestureDetector(
            onTap: () => _push(const MyPage()),
            child: Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.15),
              ),
              child: Icon(Icons.person_rounded, size: 18, color: primary),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [

          // ── 빠른 실행 (2×2 그리드) ──────────────────────────
          _sectionLabel('빠른 실행', sub),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: [
              _QuickCard(
                icon: Icons.track_changes_rounded,
                label: '바이블 트래커',
                desc: '읽기 진도 추적',
                color: const Color(0xFF5C7FA3),
                isDark: isDark,
                onTap: () => _snack('바이블 트래커 준비 중이에요'),
              ),
              _QuickCard(
                icon: Icons.group_rounded,
                label: '그룹',
                desc: '함께 읽는 성경',
                color: const Color(0xFF7B68EE),
                isDark: isDark,
                onTap: () => _snack('그룹 기능 준비 중이에요'),
              ),
              _QuickCard(
                icon: Icons.mic_rounded,
                label: '설교',
                desc: '말씀듣기 · 팟캐스트',
                color: const Color(0xFF4CAF50),
                isDark: isDark,
                onTap: () => _snack('설교 기능 준비 중이에요'),
              ),
              _QuickCard(
                icon: Icons.music_note_rounded,
                label: 'CCM',
                desc: '찬양 듣기 · 가사보기',
                color: const Color(0xFFFF9800),
                isDark: isDark,
                onTap: () => _snack('CCM 기능 준비 중이에요'),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── 내 기록 ────────────────────────────────────────
          _sectionLabel('내 기록', sub),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _RecordTile(
                  icon: Icons.bookmark_rounded,
                  iconColor: Colors.amber.shade600,
                  title: '북마크',
                  count: _bookmarkCount,
                  isDark: isDark,
                  divColor: div,
                  showDivider: true,
                  onTap: () => _push(const BookmarkPage()),
                ),
                _RecordTile(
                  icon: Icons.highlight_rounded,
                  iconColor: Colors.orange.shade400,
                  title: '형광펜',
                  count: _highlightCount,
                  isDark: isDark,
                  divColor: div,
                  showDivider: true,
                  onTap: () => _push(const HighlightListPage()),
                ),
                _RecordTile(
                  icon: Icons.edit_note_rounded,
                  iconColor: primary,
                  title: '묵상 노트',
                  count: _memoCount,
                  isDark: isDark,
                  divColor: div,
                  showDivider: false,
                  onTap: () => _push(const MemoListPage()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── 연구 도구 ──────────────────────────────────────
          _sectionLabel('연구 도구', sub),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _ToolTile(
                  icon: Icons.chrome_reader_mode_rounded,
                  iconColor: const Color(0xFF5C7FA3),
                  title: '원어 사전',
                  subtitle: '히브리어 8,274 · 헬라어 5,689',
                  isDark: isDark,
                  divColor: div,
                  showDivider: true,
                  badge: null,
                  onTap: () => _push(const DictionaryPage()),
                ),
                _ToolTile(
                  icon: Icons.link_rounded,
                  iconColor: const Color(0xFF9C27B0),
                  title: '교차 참조',
                  subtitle: '구절 간 연결 구절 탐색',
                  isDark: isDark,
                  divColor: div,
                  showDivider: true,
                  badge: '준비 중',
                  onTap: null,
                ),
                _ToolTile(
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF795548),
                  title: '주석',
                  subtitle: 'Matthew Henry · Gill\'s',
                  isDark: isDark,
                  divColor: div,
                  showDivider: false,
                  badge: '준비 중',
                  onTap: null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── 콘텐츠 ─────────────────────────────────────────
          _sectionLabel('콘텐츠', sub),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _ToolTile(
                  icon: Icons.track_changes_rounded,
                  iconColor: const Color(0xFF00BCD4),
                  title: '바이블 트래커',
                  subtitle: '읽기 기록 · 통독 진행률',
                  isDark: isDark,
                  divColor: div,
                  showDivider: true,
                  badge: '준비 중',
                  onTap: null,
                ),
                _ToolTile(
                  icon: Icons.headphones_rounded,
                  iconColor: const Color(0xFFE91E63),
                  title: 'CCM · 찬양',
                  subtitle: '찬양 재생 · 가사 보기',
                  isDark: isDark,
                  divColor: div,
                  showDivider: true,
                  badge: '준비 중',
                  onTap: null,
                ),
                _ToolTile(
                  icon: Icons.podcasts_rounded,
                  iconColor: const Color(0xFFFF5722),
                  title: '설교 · 팟캐스트',
                  subtitle: '말씀 듣기',
                  isDark: isDark,
                  divColor: div,
                  showDivider: true,
                  badge: '준비 중',
                  onTap: null,
                ),
                _ToolTile(
                  icon: Icons.groups_rounded,
                  iconColor: const Color(0xFF2196F3),
                  title: '그룹',
                  subtitle: '소그룹 · 공동체 나눔',
                  isDark: isDark,
                  divColor: div,
                  showDivider: false,
                  badge: '준비 중',
                  onTap: null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── 설정 ───────────────────────────────────────────
          _sectionLabel('설정', sub),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _SettingRow(
                  icon: isDark
                      ? Icons.wb_sunny_rounded
                      : Icons.nightlight_round,
                  iconColor: isDark ? Colors.amber : Colors.blueGrey,
                  title: '다크 모드',
                  isDark: isDark,
                  divColor: div,
                  showDivider: true,
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => appState?.toggleTheme(),
                    activeColor: primary,
                  ),
                  onTap: () => appState?.toggleTheme(),
                ),
                _SettingRow(
                  icon: Icons.person_rounded,
                  iconColor: primary,
                  title: '마이페이지',
                  isDark: isDark,
                  divColor: div,
                  showDivider: false,
                  trailing: Icon(Icons.chevron_right_rounded,
                      size: 20, color: sub),
                  onTap: () => _push(const MyPage()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── 앱 버전 ────────────────────────────────────────
          Center(
            child: Text('성경 앱 v1.0.0',
                style: TextStyle(fontSize: 12, color: sub)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, Color sub) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sub)),
      );
}

// ── 빠른 실행 카드 ─────────────────────────────────────────────
class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black)),
                  Text(desc,
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 기록 타일 ──────────────────────────────────────────────────
class _RecordTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final bool isDark;
  final Color divColor;
  final bool showDivider;
  final VoidCallback onTap;

  const _RecordTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.isDark,
    required this.divColor,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? Colors.white : Colors.black;
    final sub  = const Color(0xFF8E8E93);

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
                // 개수 뱃지
                if (count > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: iconColor)),
                  ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: sub),
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

// ── 도구 타일 ──────────────────────────────────────────────────
class _ToolTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color divColor;
  final bool showDivider;
  final String? badge;
  final VoidCallback? onTap;

  const _ToolTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.divColor,
    required this.showDivider,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text    = isDark ? Colors.white : Colors.black;
    final sub     = const Color(0xFF8E8E93);
    final enabled = onTap != null;

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
                    color: iconColor.withOpacity(enabled ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon,
                      size: 18,
                      color: enabled
                          ? iconColor
                          : iconColor.withOpacity(0.4)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 15,
                              color: enabled ? text : sub)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12, color: sub)),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sub.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(badge!,
                        style: TextStyle(
                            fontSize: 11, color: sub)),
                  )
                else
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: sub),
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

// ── 설정 행 ────────────────────────────────────────────────────
class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isDark;
  final Color divColor;
  final bool showDivider;
  final Widget trailing;
  final VoidCallback onTap;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isDark,
    required this.divColor,
    required this.showDivider,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? Colors.white : Colors.black;

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
