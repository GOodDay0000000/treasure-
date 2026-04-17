// lib/pages/lab_page.dart
//
// 연구소 — 9개 섹션 + 공통 UX 패턴
// 섹션 순서: 66권 → 원어 사전 → 주석 → 교차참조 → 타임라인 → 지도 탐험
//           → 통계 → 주제별 탐구 → 배경 백과
//
// 각 섹션: [제목 · 더 알아보기 →] / 미리보기 카드·칩 2~3개
//         '더 알아보기'는 전체 목록 시트로 확장

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/bible_timeline.dart';
import '../data/map_regions.dart';
import '../l10n/app_strings.dart';
import '../services/commentary_service.dart';
import '../services/cross_reference_service.dart';
import 'bible_read_page.dart';
import 'book_info_page.dart';
import 'book_select_page.dart';
import 'dictionary_page.dart';
import 'main_navigation_page.dart';
import 'memo_list_page.dart';
import 'sheets/commentary_sheet.dart';
import 'sheets/cross_reference_sheet.dart';

class LabPage extends StatefulWidget {
  const LabPage({super.key});

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
  String? _lastBook;
  int? _lastChapter;
  int? _lastVerse;
  String _version = 'krv';

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  Future<void> _loadLast() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _version = prefs.getString('last_version') ?? 'krv';
      _lastBook = prefs.getString('last_read_book') ??
          prefs.getString('last_book_key');
      _lastChapter = prefs.getInt('last_read_chapter') ??
          prefs.getInt('last_chapter');
      _lastVerse = prefs.getInt('last_read_verse');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_rounded, size: 20, color: primary),
            const SizedBox(width: 8),
            Text('연구소',
                style: GoogleFonts.dancingScript(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: primary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '연구 노트',
            icon: Icon(Icons.edit_note_rounded, color: primary, size: 24),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => MemoListPage())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLast,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            _section(
              icon: Icons.auto_stories_rounded,
              title: '성경 66권',
              subtitle: '구약 39 · 신약 27',
              onMore: null,
              child: _LabCard(
                icon: Icons.menu_book_rounded,
                title: '모든 책 탐색',
                subtitle: '저자·연대·핵심 구절·요약',
                isDark: isDark,
                accent: primary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BookInfoPage())),
              ),
            ),

            _section(
              icon: Icons.translate_rounded,
              title: '원어 사전',
              subtitle: '히브리어·헬라어·알파벳',
              onMore: null,
              child: _LabCard(
                icon: Icons.language_rounded,
                title: '사전 + 알파벳 학습',
                subtitle: 'Strong\'s 번호 검색',
                isDark: isDark,
                accent: primary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DictionaryPage())),
              ),
            ),

            _section(
              icon: Icons.auto_awesome_motion_rounded,
              title: '오늘의 말씀 해설',
              subtitle: _todayVerseLabel(),
              onMore: _openCommentaryFromToday,
              child: _TodayCommentaryCard(
                bookKey: _todayBook(),
                chapter: _todayChapter(),
                verse: _todayVerse(),
                isDark: isDark,
                primary: primary,
                onOpen: _openCommentaryFromToday,
              ),
            ),

            _section(
              icon: Icons.hub_rounded,
              title: '교차 참조',
              subtitle: _lastLocLabel(withVerse: true),
              onMore: (_lastBook == null || _lastVerse == null)
                  ? null
                  : _openCrossRef,
              child: _CrossRefPreview(
                bookKey: _lastBook,
                chapter: _lastChapter,
                verse: _lastVerse,
                version: _version,
                isDark: isDark,
                primary: primary,
                onTapRef: _navigateToRef,
              ),
            ),

            _section(
              icon: Icons.timeline_rounded,
              title: '성경 타임라인',
              subtitle: 'BC 2166 ~ AD 90',
              onMore: _openAllTimeline,
              child: SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: 3,
                  itemBuilder: (_, i) => _TimelineCard(
                    event: bibleTimeline[i],
                    isDark: isDark,
                    primary: primary,
                  ),
                ),
              ),
            ),

            _section(
              icon: Icons.map_rounded,
              title: '성경 지도 탐험',
              subtitle: '${bibleMapRegions.length}개 지역',
              onMore: _openAllRegions,
              child: SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final r = bibleMapRegions[i];
                    return _RegionCard(
                      region: r,
                      isDark: isDark,
                      primary: primary,
                      onTap: () => _openRegion(r),
                    );
                  },
                ),
              ),
            ),

            _section(
              icon: Icons.bar_chart_rounded,
              title: '성경 통계',
              subtitle: '재밌는 숫자들',
              onMore: _openAllStats,
              child: FutureBuilder<List<_Stat>>(
                future: _loadStats(),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final stats = snap.data!.take(3).toList();
                  return Column(
                    children: stats
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _StatCard(
                                stat: s,
                                isDark: isDark,
                                primary: primary,
                                onTap: s.ref == null
                                    ? null
                                    : () => _navigateToRefStr(s.ref!),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ),

            _section(
              icon: Icons.auto_awesome_rounded,
              title: '주제별 탐구',
              subtitle: '핵심 주제 20가지',
              onMore: _openAllTopics,
              child: FutureBuilder<List<_Topic>>(
                future: _loadTopics(),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final preview = snap.data!.take(4).toList();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: preview
                        .map((t) => _TopicChip(
                              topic: t,
                              isDark: isDark,
                              primary: primary,
                              onTap: () => _openTopic(t),
                            ))
                        .toList(),
                  );
                },
              ),
            ),

            _section(
              icon: Icons.account_balance_rounded,
              title: '성경 배경 백과',
              subtitle: '문화·지리·역사·성전',
              onMore: _openAllBackground,
              child: FutureBuilder<List<_BackgroundItem>>(
                future: _loadBackground(),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final preview = snap.data!.take(3).toList();
                  return Column(
                    children: preview
                        .map((it) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _BackgroundCard(
                                item: it,
                                isDark: isDark,
                                onTap: () => _openBackground(it),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 섹션 래퍼 (공통 UX) ──────────────────────────────────
  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onMore,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primary = Theme.of(context).colorScheme.primary;
            final text =
                isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
            final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 0, 10),
              child: Row(children: [
                Icon(icon, color: primary, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: text)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(subtitle,
                      style: TextStyle(fontSize: 12, color: sub),
                      overflow: TextOverflow.ellipsis),
                ),
                if (onMore != null)
                  GestureDetector(
                    onTap: onMore,
                    behavior: HitTestBehavior.opaque,
                    child: Row(children: [
                      Text('더 알아보기',
                          style: TextStyle(
                              fontSize: 11,
                              color: primary,
                              fontWeight: FontWeight.w600)),
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: primary),
                    ]),
                  ),
              ]),
            );
          }),
          child,
        ],
      ),
    );
  }

  String _lastLocLabel({required bool withVerse}) {
    if (_lastBook == null || _lastChapter == null) return '최근 없음';
    final name = BibleBookNames.get(_lastBook!, AppLocale.current);
    if (withVerse && _lastVerse != null) {
      return '$name $_lastChapter:$_lastVerse';
    }
    return '$name $_lastChapter장';
  }

  // ── 오늘의 말씀 선정 ────────────────────────────────────
  // 마지막 읽은 위치가 있으면 그걸 우선, 없으면 날짜 기반 결정론적 선택
  static const List<List<dynamic>> _dailyPicks = [
    ['psalms', 23, 1],
    ['john', 3, 16],
    ['matthew', 6, 33],
    ['isaiah', 41, 10],
    ['romans', 8, 28],
    ['philippians', 4, 13],
    ['jeremiah', 29, 11],
    ['proverbs', 3, 5],
    ['john', 14, 6],
    ['ephesians', 2, 8],
    ['psalms', 119, 105],
    ['1corinthians', 13, 4],
    ['hebrews', 11, 1],
    ['matthew', 11, 28],
    ['joshua', 1, 9],
  ];

  List<dynamic> _todayPick() {
    if (_lastBook != null && _lastChapter != null) {
      return [_lastBook!, _lastChapter!, _lastVerse];
    }
    final doy = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _dailyPicks[doy % _dailyPicks.length];
  }

  String _todayBook() => _todayPick()[0] as String;
  int _todayChapter() => _todayPick()[1] as int;
  int? _todayVerse() => _todayPick()[2] as int?;

  String _todayVerseLabel() {
    final p = _todayPick();
    final name = BibleBookNames.get(p[0] as String, AppLocale.current);
    final v = p[2];
    return v == null ? '$name ${p[1]}장' : '$name ${p[1]}:$v';
  }

  void _openCommentaryFromToday() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentarySheet(
        bookKey: _todayBook(),
        chapter: _todayChapter(),
        highlightVerse: _todayVerse(),
      ),
    );
  }

  // ── 액션 ────────────────────────────────────────────────
  void _openCrossRef() {
    if (_lastBook == null || _lastChapter == null || _lastVerse == null) {
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CrossReferenceSheet(
        version: _version,
        bookKey: _lastBook!,
        chapter: _lastChapter!,
        verse: _lastVerse!,
        onSelect: (r) {
          Navigator.pop(context);
          _navigateToRef(r);
        },
      ),
    );
  }

  void _navigateToRef(CrossRef r) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BibleReadPage(
        version: _version,
        bookKey: r.bookKey,
        bookName: BibleBookNames.get(r.bookKey, AppLocale.current),
        chapter: r.chapter,
        totalChapters: BookSelectPage.getChapterCount(r.bookKey),
        highlightVerse: r.verse,
      ),
    )).then((_) => _loadLast());
  }

  void _navigateToRefStr(String refStr) {
    final m = RegExp(r'^([a-z0-9]+):(\d+):(\d+)').firstMatch(refStr);
    if (m == null) return;
    final book = m.group(1)!;
    final ch = int.parse(m.group(2)!);
    final v = int.parse(m.group(3)!);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BibleReadPage(
        version: _version,
        bookKey: book,
        bookName: BibleBookNames.get(book, AppLocale.current),
        chapter: ch,
        totalChapters: BookSelectPage.getChapterCount(book),
        highlightVerse: v,
      ),
    )).then((_) => _loadLast());
  }

  void _openRegion(MapRegion r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RegionSheet(region: r),
    );
  }

  void _openTopic(_Topic t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TopicSheet(
        topic: t,
        version: _version,
        onTapVerse: (ref) {
          Navigator.pop(context);
          _navigateToRefStr(ref);
        },
      ),
    );
  }

  void _openBackground(_BackgroundItem b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BackgroundSheet(
        item: b,
        onTapVerse: (ref) {
          Navigator.pop(context);
          _navigateToRefStr(ref);
        },
      ),
    );
  }

  void _openAllTimeline() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AllTimelineSheet(),
    );
  }

  void _openAllRegions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AllRegionsSheet(onTap: _openRegion),
    );
  }

  void _openAllStats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AllStatsSheet(onTapRef: _navigateToRefStr),
    );
  }

  void _openAllTopics() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AllTopicsSheet(onTapTopic: (t) {
        Navigator.pop(context);
        _openTopic(t);
      }),
    );
  }

  void _openAllBackground() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AllBackgroundSheet(onTapItem: (it) {
        Navigator.pop(context);
        _openBackground(it);
      }),
    );
  }
}

// ── 공통 위젯 ──────────────────────────────────────────────────
class _LabCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;
  const _LabCard({
    required this.icon, required this.title, required this.subtitle,
    required this.isDark, required this.accent, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: text)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: sub)),
              ],
            )),
            Icon(Icons.chevron_right_rounded, color: sub, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ── 오늘의 말씀 해설 카드 ──────────────────────────────────
class _TodayCommentaryCard extends StatelessWidget {
  final String bookKey;
  final int chapter;
  final int? verse;
  final bool isDark;
  final Color primary;
  final VoidCallback onOpen;
  const _TodayCommentaryCard({
    required this.bookKey,
    required this.chapter,
    required this.verse,
    required this.isDark,
    required this.primary,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChapterCommentary?>(
      future: CommentaryService().getChapter(bookKey, chapter),
      builder: (_, snap) {
        final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
        final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
        final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
        final name = BibleBookNames.get(bookKey, AppLocale.current);

        MapEntry<String, String>? pick;
        String? fallback;
        if (snap.connectionState == ConnectionState.done) {
          final ch = snap.data;
          if (ch == null) {
            fallback = '이 장의 주석이 아직 없어요';
          } else {
            final entries = ch.sortedEntries();
            if (verse != null && entries.isNotEmpty) {
              final found = entries.where((e) {
                final k = e.key;
                if (k == '$verse') return true;
                final dash = k.indexOf('-');
                if (dash < 0) return false;
                final lo = int.tryParse(k.substring(0, dash));
                final hi = int.tryParse(k.substring(dash + 1));
                return lo != null && hi != null && verse! >= lo && verse! <= hi;
              }).toList();
              pick = found.isNotEmpty ? found.first : entries.first;
            } else if (entries.isNotEmpty) {
              pick = entries.first;
            } else {
              fallback = '주석 없음';
            }
          }
        }

        final verseLabel = verse == null
            ? '$name $chapter장'
            : '$name $chapter:$verse';

        return Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onOpen,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primary.withOpacity(0.25),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.wb_sunny_rounded, size: 14, color: primary),
                    const SizedBox(width: 6),
                    Text('TODAY',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: primary)),
                    const Spacer(),
                    if (pick != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${pick.key}절',
                            style: TextStyle(
                                fontSize: 10,
                                color: primary,
                                fontWeight: FontWeight.w700)),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Text(verseLabel,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: text)),
                  const SizedBox(height: 10),
                  if (snap.connectionState != ConnectionState.done)
                    const SizedBox(
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (fallback != null)
                    Text(fallback,
                        style: TextStyle(fontSize: 13, color: sub, height: 1.55))
                  else if (pick != null)
                    Text(pick.value,
                        style: TextStyle(
                            fontSize: 13, color: text, height: 1.6),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text('Church Fathers · Public Domain',
                        style: TextStyle(
                            fontSize: 10,
                            color: sub,
                            fontStyle: FontStyle.italic)),
                    const Spacer(),
                    Text('해설 전체 보기',
                        style: TextStyle(
                            fontSize: 11,
                            color: primary,
                            fontWeight: FontWeight.w700)),
                    Icon(Icons.arrow_forward_rounded,
                        size: 13, color: primary),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── 교차참조 미리보기 ──────────────────────────────────────
class _CrossRefPreview extends StatelessWidget {
  final String? bookKey;
  final int? chapter;
  final int? verse;
  final String version;
  final bool isDark;
  final Color primary;
  final void Function(CrossRef) onTapRef;
  const _CrossRefPreview({
    required this.bookKey, required this.chapter, required this.verse,
    required this.version,
    required this.isDark, required this.primary, required this.onTapRef,
  });
  @override
  Widget build(BuildContext context) {
    if (bookKey == null || chapter == null || verse == null) {
      return const _EmptyHint(
        icon: Icons.hub_outlined,
        text: '성경에서 절을 선택하면 관련 구절이 보여요',
      );
    }
    return FutureBuilder<List<CrossRef>>(
      future:
          CrossReferenceService().getReferences(bookKey!, chapter!, verse!),
      builder: (_, snap) {
        final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
        final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
        final refs = snap.data ?? const [];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg, borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (refs.isEmpty)
                Text('이 구절의 교차참조가 없어요',
                    style: TextStyle(fontSize: 12, color: sub))
              else
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: refs.take(3).map((r) {
                    final n = BibleBookNames.get(r.bookKey, AppLocale.current);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onTapRef(r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('$n ${r.chapter}:${r.verse}',
                            style: TextStyle(
                                fontSize: 12,
                                color: primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── 지역 카드 ──────────────────────────────────────────────
class _RegionCard extends StatelessWidget {
  final MapRegion region;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;
  const _RegionCard({
    required this.region, required this.isDark,
    required this.primary, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return SizedBox(
      width: 150,
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(region.emoji, style: const TextStyle(fontSize: 20)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${region.bookKeys.length}권',
                        style: TextStyle(
                            fontSize: 9,
                            color: primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(region.name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: text)),
                const SizedBox(height: 2),
                Text(region.period,
                    style: TextStyle(fontSize: 10, color: sub),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Expanded(child: Text(region.desc,
                    style: TextStyle(fontSize: 11, color: sub, height: 1.4),
                    maxLines: 3, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionSheet extends StatelessWidget {
  final MapRegion region;
  const _RegionSheet({required this.region});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: sub.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 18),
            Row(children: [
              Text(region.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(region.name,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: text)),
                  Text(region.period,
                      style: TextStyle(fontSize: 13, color: sub)),
                ],
              )),
            ]),
            const SizedBox(height: 18),
            Text(region.desc,
                style: TextStyle(fontSize: 14, color: text, height: 1.6)),
            if (region.story.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withOpacity(0.2)),
                ),
                child: Text(region.story,
                    style: TextStyle(fontSize: 13, color: text, height: 1.7)),
              ),
            ],
            const SizedBox(height: 18),
            Text('관련 성경 ${region.bookKeys.length}권',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: region.bookKeys.map((k) {
                final name = BibleBookNames.get(k, AppLocale.current);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(name,
                      style: TextStyle(
                          fontSize: 12,
                          color: primary,
                          fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // MainNavigationPage의 보물지도 탭(index=1)으로 전환
                  MainNavigationPage.of(context)?.goToTab(1);
                },
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('보물지도에서 보기',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
}

// ── 전체 지역 시트 ──────────────────────────────────────────
class _AllRegionsSheet extends StatelessWidget {
  final void Function(MapRegion) onTap;
  const _AllRegionsSheet({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: sub.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Icon(Icons.map_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              Text('성경 지도 탐험 — ${bibleMapRegions.length}개 지역',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: text)),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemCount: bibleMapRegions.length,
              itemBuilder: (_, i) => _RegionCard(
                region: bibleMapRegions[i],
                isDark: isDark,
                primary: primary,
                onTap: () {
                  Navigator.pop(context);
                  onTap(bibleMapRegions[i]);
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── 타임라인 ────────────────────────────────────────────────
class _TimelineCard extends StatelessWidget {
  final BibleEvent event;
  final bool isDark;
  final Color primary;
  const _TimelineCard({
    required this.event, required this.isDark, required this.primary,
  });
  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFC9A84C);
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final lineColor = isDark ? const Color(0xFF2C3E50) : const Color(0xFFE0E6ED);
    return SizedBox(
      width: 220,
      child: Stack(children: [
        Positioned(
          top: 14, left: 0, right: 0,
          child: Container(height: 2, color: lineColor),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: gold, borderRadius: BorderRadius.circular(20),
                ),
                child: Text(event.displayYear,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0D1B2A),
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lineColor, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.event,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: text),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Expanded(child: Text(event.desc,
                          style: TextStyle(fontSize: 11, color: sub, height: 1.45),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4, runSpacing: 4,
                        children: event.books.take(3).map((k) {
                          final bookName = BookSelectPage.allBooks
                              .firstWhere((b) => b['key'] == k,
                                  orElse: () => {'abbr': k})['abbr'] as String;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(bookName,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: gold,
                                    fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _AllTimelineSheet extends StatelessWidget {
  const _AllTimelineSheet();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: sub.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Icon(Icons.timeline_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              Text('성경 타임라인 — ${bibleTimeline.length}개 이벤트',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: text)),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: bibleTimeline.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final e = bibleTimeline[i];
                final gold = const Color(0xFFC9A84C);
                final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(e.displayYear,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF0D1B2A),
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.event,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: text),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 6),
                      Text(e.desc,
                          style: TextStyle(fontSize: 12, color: sub, height: 1.5)),
                    ],
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── 통계 ────────────────────────────────────────────────────
class _Stat {
  final String emoji;
  final String title;
  final String value;
  final String detail;
  final String? ref;
  final String? note;
  const _Stat({
    required this.emoji, required this.title, required this.value,
    required this.detail, this.ref, this.note,
  });
  factory _Stat.fromJson(Map<String, dynamic> m) => _Stat(
        emoji: m['emoji'] as String,
        title: m['title'] as String,
        value: m['value'] as String,
        detail: m['detail'] as String? ?? '',
        ref: m['ref'] as String?,
        note: m['note'] as String?,
      );
}

Future<List<_Stat>> _loadStats() async {
  final raw = await rootBundle.loadString('assets/data/bible_stats.json');
  final list = jsonDecode(raw) as List;
  return list.map((e) => _Stat.fromJson(e as Map<String, dynamic>)).toList();
}

class _StatCard extends StatelessWidget {
  final _Stat stat;
  final bool isDark;
  final Color primary;
  final VoidCallback? onTap;
  const _StatCard({
    required this.stat, required this.isDark,
    required this.primary, this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Text(stat.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.title,
                    style: TextStyle(
                        fontSize: 11,
                        color: sub,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(stat.value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: text)),
                if (stat.detail.isNotEmpty)
                  Text(stat.detail,
                      style: TextStyle(fontSize: 11, color: sub, height: 1.35)),
              ],
            )),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: sub, size: 18),
          ]),
        ),
      ),
    );
  }
}

class _AllStatsSheet extends StatelessWidget {
  final void Function(String) onTapRef;
  const _AllStatsSheet({required this.onTapRef});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: FutureBuilder<List<_Stat>>(
          future: _loadStats(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(children: [
              const SizedBox(height: 10),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: sub.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Icon(Icons.bar_chart_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text('성경 통계 — ${snap.data!.length}가지',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: text)),
                ]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: snap.data!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final s = snap.data![i];
                    return _StatDetailCard(
                      stat: s,
                      isDark: isDark,
                      primary: primary,
                      onTap: s.ref == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              onTapRef(s.ref!);
                            },
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _StatDetailCard extends StatelessWidget {
  final _Stat stat;
  final bool isDark;
  final Color primary;
  final VoidCallback? onTap;
  const _StatDetailCard({
    required this.stat, required this.isDark,
    required this.primary, this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(stat.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stat.title,
                        style: TextStyle(fontSize: 12, color: sub)),
                    const SizedBox(height: 2),
                    Text(stat.value,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: text)),
                  ],
                )),
                if (onTap != null)
                  Icon(Icons.arrow_forward_rounded,
                      color: primary, size: 16),
              ]),
              if (stat.detail.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(stat.detail,
                    style: TextStyle(fontSize: 12, color: sub, height: 1.5)),
              ],
              if ((stat.note ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(stat.note!,
                      style: TextStyle(
                          fontSize: 11, color: text, height: 1.6)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── 주제 ────────────────────────────────────────────────────
class _VerseRef {
  final String ref;
  final String preview;
  const _VerseRef({required this.ref, required this.preview});
}

class _Topic {
  final String id, title, emoji;
  final String? hebrew, hebrewRoman, greek, greekRoman;
  final String description, deepDescription;
  final List<_VerseRef> verses;
  final List<String> relatedTopics, relatedWords;
  const _Topic({
    required this.id, required this.title, required this.emoji,
    this.hebrew, this.hebrewRoman, this.greek, this.greekRoman,
    required this.description, required this.deepDescription,
    required this.verses,
    this.relatedTopics = const [],
    this.relatedWords = const [],
  });
  factory _Topic.fromJson(String key, Map<String, dynamic> m) => _Topic(
        id: m['id'] as String? ?? key,
        title: m['title'] as String,
        emoji: m['emoji'] as String,
        hebrew: m['hebrew'] as String?,
        hebrewRoman: m['hebrewRoman'] as String?,
        greek: m['greek'] as String?,
        greekRoman: m['greekRoman'] as String?,
        description: m['description'] as String,
        deepDescription: m['deepDescription'] as String? ?? '',
        verses: (m['verses'] as List).map((v) {
          if (v is String) return _VerseRef(ref: v, preview: '');
          final vm = v as Map<String, dynamic>;
          return _VerseRef(
              ref: vm['ref'] as String,
              preview: vm['preview'] as String? ?? '');
        }).toList(),
        relatedTopics: (m['relatedTopics'] as List?)?.cast<String>() ?? const [],
        relatedWords: (m['relatedWords'] as List?)?.cast<String>() ?? const [],
      );
}

Future<List<_Topic>> _loadTopics() async {
  final raw = await rootBundle.loadString('assets/data/topics.json');
  final obj = jsonDecode(raw) as Map<String, dynamic>;
  return obj.entries
      .map((e) => _Topic.fromJson(e.key, e.value as Map<String, dynamic>))
      .toList();
}

class _TopicChip extends StatelessWidget {
  final _Topic topic;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;
  const _TopicChip({
    required this.topic, required this.isDark,
    required this.primary, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(topic.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(topic.title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: text)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: primary, size: 16),
          ]),
        ),
      ),
    );
  }
}

class _TopicSheet extends StatelessWidget {
  final _Topic topic;
  final String version;
  final void Function(String ref) onTapVerse;
  const _TopicSheet({
    required this.topic, required this.version, required this.onTapVerse,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: sub.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 16),
            Center(child: Text(topic.emoji, style: const TextStyle(fontSize: 42))),
            const SizedBox(height: 8),
            Center(child: Text(topic.title,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: text))),
            const SizedBox(height: 6),
            if (topic.hebrew != null || topic.greek != null)
              Center(
                child: Wrap(
                  spacing: 16,
                  children: [
                    if (topic.hebrew != null)
                      _langChip(topic.hebrew!, topic.hebrewRoman, true, primary),
                    if (topic.greek != null)
                      _langChip(topic.greek!, topic.greekRoman, false, primary),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Text(topic.description,
                style: TextStyle(fontSize: 14, color: text, height: 1.65)),
            if (topic.deepDescription.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(topic.deepDescription,
                    style: TextStyle(fontSize: 13, color: text, height: 1.75)),
              ),
            ],
            const SizedBox(height: 18),
            Text('핵심 구절 ${topic.verses.length}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primary)),
            const SizedBox(height: 8),
            ...topic.verses.map((v) => _VerseRefTile(
                  verseRef: v,
                  isDark: isDark,
                  primary: primary,
                  onTap: () => onTapVerse(v.ref),
                )),
          ],
        ),
      ),
    );
  }

  Widget _langChip(String letter, String? translit, bool isHebrew, Color primary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(letter,
            textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
                fontSize: 22,
                color: primary,
                fontWeight: FontWeight.w500)),
        if (translit != null)
          Text(translit,
              style: TextStyle(
                  fontSize: 11,
                  color: primary,
                  fontStyle: FontStyle.italic)),
      ],
    );
  }
}

class _VerseRefTile extends StatelessWidget {
  final _VerseRef verseRef;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;
  const _VerseRefTile({
    required this.verseRef, required this.isDark,
    required this.primary, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final m = RegExp(r'^([a-z0-9]+):(\d+):(\d+(?:-\d+)?)').firstMatch(verseRef.ref);
    if (m == null) return const SizedBox.shrink();
    final name = BibleBookNames.get(m.group(1)!, AppLocale.current);
    final label = '$name ${m.group(2)}:${m.group(3)}';
    final cardBg = isDark ? const Color(0xFF16213E) : const Color(0xFFF7F9FC);
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_forward_rounded, size: 13, color: primary),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primary)),
                    if (verseRef.preview.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(verseRef.preview,
                          style: TextStyle(
                              fontSize: 12, color: text, height: 1.5),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                )),
                Icon(Icons.chevron_right_rounded, size: 16, color: sub),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllTopicsSheet extends StatelessWidget {
  final void Function(_Topic) onTapTopic;
  const _AllTopicsSheet({required this.onTapTopic});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: FutureBuilder<List<_Topic>>(
          future: _loadTopics(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(children: [
              const SizedBox(height: 10),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: sub.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Icon(Icons.auto_awesome_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text('주제별 탐구 — ${snap.data!.length}가지',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: text)),
                ]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: snap.data!.length,
                  itemBuilder: (_, i) {
                    final t = snap.data![i];
                    return _TopicChip(
                      topic: t,
                      isDark: isDark,
                      primary: primary,
                      onTap: () => onTapTopic(t),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

// ── 배경 백과 ────────────────────────────────────────────────
class _BackgroundItem {
  final String id, title, category, categoryTitle, emoji;
  final String summary, content, significance, funFact;
  final List<String> relatedVerses;
  final String? relatedRegion;
  const _BackgroundItem({
    required this.id, required this.title, required this.category,
    required this.categoryTitle, required this.emoji,
    required this.summary, required this.content,
    required this.significance, required this.funFact,
    required this.relatedVerses, this.relatedRegion,
  });
  factory _BackgroundItem.fromJson(Map<String, dynamic> m) => _BackgroundItem(
        id: m['id'] as String,
        title: m['title'] as String,
        category: m['category'] as String,
        categoryTitle: m['categoryTitle'] as String,
        emoji: m['emoji'] as String,
        summary: m['summary'] as String? ?? '',
        content: m['content'] as String,
        significance: m['significance'] as String? ?? '',
        funFact: m['funFact'] as String? ?? '',
        relatedVerses:
            (m['relatedVerses'] as List?)?.cast<String>() ?? const [],
        relatedRegion: m['relatedRegion'] as String?,
      );
}

Future<List<_BackgroundItem>> _loadBackground() async {
  final raw = await rootBundle.loadString('assets/data/background.json');
  final list = jsonDecode(raw) as List;
  return list
      .map((e) => _BackgroundItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

class _BackgroundCard extends StatelessWidget {
  final _BackgroundItem item;
  final bool isDark;
  final VoidCallback onTap;
  const _BackgroundCard({
    required this.item, required this.isDark, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Text(item.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: text)),
                const SizedBox(height: 3),
                Text(item.summary.isNotEmpty ? item.summary : item.content,
                    style: TextStyle(fontSize: 11, color: sub, height: 1.45),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            )),
            Icon(Icons.chevron_right_rounded, color: sub, size: 18),
          ]),
        ),
      ),
    );
  }
}

class _AllBackgroundSheet extends StatelessWidget {
  final void Function(_BackgroundItem) onTapItem;
  const _AllBackgroundSheet({required this.onTapItem});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: FutureBuilder<List<_BackgroundItem>>(
          future: _loadBackground(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data!;
            final groups = <String, List<_BackgroundItem>>{};
            for (final it in items) {
              groups.putIfAbsent(it.category, () => []).add(it);
            }
            return Column(children: [
              const SizedBox(height: 10),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: sub.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Icon(Icons.account_balance_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text('성경 배경 백과 — ${items.length}항목',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: text)),
                ]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: groups.entries.expand((e) => [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                          child: Text(e.value.first.categoryTitle,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                        ...e.value.map((it) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _BackgroundCard(
                                item: it,
                                isDark: isDark,
                                onTap: () => onTapItem(it),
                              ),
                            )),
                      ]).toList(),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _BackgroundSheet extends StatelessWidget {
  final _BackgroundItem item;
  final void Function(String ref) onTapVerse;
  const _BackgroundSheet({required this.item, required this.onTapVerse});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: sub.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 16),
            Row(children: [
              Text(item.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: text)),
                  Text(item.categoryTitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: primary,
                          fontWeight: FontWeight.w600)),
                ],
              )),
            ]),
            if (item.summary.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(item.summary,
                  style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: primary,
                      height: 1.55)),
            ],
            const SizedBox(height: 14),
            Text(item.content,
                style: TextStyle(fontSize: 14, color: text, height: 1.75)),
            if (item.significance.isNotEmpty) ...[
              const SizedBox(height: 18),
              _highlightBlock('성경적 의미', item.significance, primary, text, isDark),
            ],
            if (item.funFact.isNotEmpty) ...[
              const SizedBox(height: 10),
              _highlightBlock('흥미로운 사실', item.funFact, primary, text, isDark),
            ],
            if (item.relatedVerses.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('관련 구절 ${item.relatedVerses.length}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: item.relatedVerses.map((ref) {
                  final m = RegExp(r'^([a-z0-9]+):(\d+):(\d+(?:-\d+)?)').firstMatch(ref);
                  if (m == null) return const SizedBox.shrink();
                  final name = BibleBookNames.get(m.group(1)!, AppLocale.current);
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onTapVerse(ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('$name ${m.group(2)}:${m.group(3)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _highlightBlock(
      String label, String body, Color primary, Color text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
          const SizedBox(height: 5),
          Text(body,
              style: TextStyle(fontSize: 13, color: text, height: 1.7)),
        ],
      ),
    );
  }
}

// ── 기타 ────────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(icon, color: sub, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
            style: TextStyle(fontSize: 12, color: sub))),
      ]),
    );
  }
}
