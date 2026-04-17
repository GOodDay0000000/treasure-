// lib/pages/book_info_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../services/book_info_service.dart';
import 'book_select_page.dart';
import 'bible_read_page.dart';

/// 66권 전체 목록 페이지. 각 카드를 탭하면 상세 다이얼로그/시트.
class BookInfoPage extends StatefulWidget {
  const BookInfoPage({super.key});

  @override
  State<BookInfoPage> createState() => _BookInfoPageState();
}

class _BookInfoPageState extends State<BookInfoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);
    final primary = Theme.of(context).colorScheme.primary;
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('성경 66권',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: sub,
          tabs: const [
            Tab(text: '구약 39'),
            Tab(text: '신약 27'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, BookInfo>>(
        future: BookInfoService().loadAll(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final map = snap.data!;
          return TabBarView(
            controller: _tab,
            children: [
              _grid(context, BookSelectPage.oldTestament, map, isDark),
              _grid(context, BookSelectPage.newTestament, map, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _grid(BuildContext context, List<Map<String, dynamic>> list,
      Map<String, BookInfo> map, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final b = list[i];
        final info = map[b['key']];
        return _BookCard(
          bookKey: b['key'] as String,
          abbr: b['abbr'] as String,
          info: info,
          isDark: isDark,
          onTap: () => _openDetail(b['key'] as String, info),
        );
      },
    );
  }

  void _openDetail(String bookKey, BookInfo? info) {
    if (info == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BookInfoSheet(info: info),
    );
  }
}

// ── 카드 ─────────────────────────────────────────────────────
class _BookCard extends StatelessWidget {
  final String bookKey;
  final String abbr;
  final BookInfo? info;
  final bool isDark;
  final VoidCallback onTap;

  const _BookCard({
    required this.bookKey,
    required this.abbr,
    required this.info,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final name = BibleBookNames.get(bookKey, AppLocale.current);
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(abbr,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primary)),
                ),
                const Spacer(),
                Text('${info?.chapters ?? "?"}장',
                    style: TextStyle(fontSize: 10, color: sub)),
              ]),
              const SizedBox(height: 8),
              Text(name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: text)),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  info?.theme ?? '',
                  style: TextStyle(
                      fontSize: 11, color: sub, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if ((info?.tags ?? const []).isNotEmpty)
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: info!.tags.take(3).map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 9, color: primary)),
                      )).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 상세 시트 ────────────────────────────────────────────────
class BookInfoSheet extends StatelessWidget {
  final BookInfo info;
  const BookInfoSheet({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final divColor = isDark ? const Color(0xFF2C3E50) : const Color(0xFFE5E5EA);
    final name = BibleBookNames.get(info.key, AppLocale.current);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: sub.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 18),
            Text(name,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: text)),
            const SizedBox(height: 6),
            Text(info.theme,
                style: TextStyle(
                    fontSize: 14, color: primary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            // 메타정보 그리드
            _metaRow(Icons.person_outline_rounded, '저자', info.author,
                text, sub),
            _metaRow(Icons.calendar_today_rounded, '연대', info.period,
                text, sub),
            _metaRow(Icons.location_on_outlined, '기록장소', info.writtenAt,
                text, sub),
            _metaRow(Icons.translate_rounded, '원어',
                info.originalLang == 'hebrew' ? '히브리어' : '헬라어',
                text, sub),
            _metaRow(Icons.menu_book_rounded, '장수', '${info.chapters}장',
                text, sub),
            const SizedBox(height: 16),
            Divider(color: divColor),
            const SizedBox(height: 12),
            // 요약
            Text('요약',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primary)),
            const SizedBox(height: 6),
            Text(info.summary,
                style: TextStyle(
                    fontSize: 14, color: text, height: 1.7)),
            const SizedBox(height: 18),
            // 핵심 구절
            if (info.keyVerses.isNotEmpty) ...[
              Text('핵심 구절',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: info.keyVerses
                    .map((vr) => _keyVerseChip(context, vr, primary))
                    .toList(),
              ),
              const SizedBox(height: 18),
            ],
            // 태그
            if (info.tags.isNotEmpty) ...[
              Text('주제 태그',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: info.tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('#$t',
                          style: TextStyle(
                              fontSize: 12, color: primary)),
                    )).toList(),
              ),
              const SizedBox(height: 18),
            ],
            // 읽으러 가기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openReading(context);
                },
                icon: const Icon(Icons.auto_stories_rounded, size: 18),
                label: Text('$name 읽기',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value,
      Color text, Color sub) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 16, color: sub),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(label,
              style: TextStyle(fontSize: 12, color: sub)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13, color: text,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }

  Widget _keyVerseChip(BuildContext context, String vr, Color primary) {
    return GestureDetector(
      onTap: () => _openVerse(context, vr),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bookmark_rounded, size: 12, color: primary),
          const SizedBox(width: 4),
          Text(vr,
              style: TextStyle(
                  fontSize: 12,
                  color: primary,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Future<void> _openReading(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString('last_version') ?? 'krv';
    final name = BibleBookNames.get(info.key, AppLocale.current);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BibleReadPage(
          version: version,
          bookKey: info.key,
          bookName: name,
          chapter: 1,
          totalChapters: info.chapters,
        ),
      ),
    );
  }

  Future<void> _openVerse(BuildContext context, String vr) async {
    // '1:1' 또는 '12:1-3' 형식 파싱
    final m = RegExp(r'^(\d+):(\d+)').firstMatch(vr);
    if (m == null) return;
    final chapter = int.parse(m.group(1)!);
    final verse = int.parse(m.group(2)!);
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString('last_version') ?? 'krv';
    final name = BibleBookNames.get(info.key, AppLocale.current);
    if (!context.mounted) return;
    Navigator.pop(context); // 시트 닫기
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BibleReadPage(
          version: version,
          bookKey: info.key,
          bookName: name,
          chapter: chapter,
          totalChapters: info.chapters,
          highlightVerse: verse,
        ),
      ),
    );
  }
}
