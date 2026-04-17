// lib/pages/bible_tracker_page.dart
//
// 바이블 트래커 — 읽기 플랜 / 오늘 분량 / 스트릭 / 퀘스트
// SharedPreferences 저장:
//   tracker_plan              : 'nt30' | 'core90' | 'mcheyne365' | 'custom' | ''
//   tracker_start             : 'YYYY-MM-DD'
//   tracker_read_dates        : List<String> 'YYYY-MM-DD'
//   tracker_quests_completed  : List<String> 퀘스트 id
//   tracker_read_chapters     : experience_service의 voyager_read_chapters 재활용

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../services/experience_service.dart';
import 'bible_read_page.dart';
import 'book_select_page.dart';

// ── 플랜 정의 ────────────────────────────────────────────────
class TrackerPlan {
  final String id;
  final String emoji;
  final String name;
  final String desc;
  final int days;
  final List<String> books;     // 대상 책 key 목록
  const TrackerPlan({
    required this.id,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.days,
    required this.books,
  });

  static const List<String> _nt = [
    'matthew','mark','luke','john','acts','romans','1corinthians',
    '2corinthians','galatians','ephesians','philippians','colossians',
    '1thessalonians','2thessalonians','1timothy','2timothy','titus',
    'philemon','hebrews','james','1peter','2peter','1john','2john',
    '3john','jude','revelation',
  ];
  static const List<String> _core = [
    'genesis','exodus','psalms','proverbs','isaiah','daniel',
    ..._nt,
  ];

  static const List<TrackerPlan> all = [
    TrackerPlan(
      id: 'nt30', emoji: '📅', name: '30일 신약 완독',
      desc: '신약 27권을 30일에 읽기', days: 30, books: _nt,
    ),
    TrackerPlan(
      id: 'core90', emoji: '📅', name: '90일 신구약 핵심',
      desc: '구약 핵심 + 신약 전체', days: 90, books: _core,
    ),
    TrackerPlan(
      id: 'mcheyne365', emoji: '📅', name: '1년 성경 완독 (맥체인)',
      desc: '1년에 신약 2회·구약 1회', days: 365, books: [],
    ),
    TrackerPlan(
      id: 'custom', emoji: '✏️', name: '직접 설정',
      desc: '내 속도로 자유롭게', days: 0, books: [],
    ),
  ];

  static TrackerPlan? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}

// ── 퀘스트 정의 ──────────────────────────────────────────────
class TrackerQuest {
  final String id;
  final String emoji;
  final String title;
  final int expReward;
  final bool Function(TrackerSnapshot s) done;
  const TrackerQuest({
    required this.id,
    required this.emoji,
    required this.title,
    required this.expReward,
    required this.done,
  });

  static final List<TrackerQuest> all = [
    TrackerQuest(
      id: 'first_chapter', emoji: '🏆', title: '첫 장 읽기',
      expReward: 10,
      done: (s) => s.readChapters.isNotEmpty,
    ),
    TrackerQuest(
      id: 'streak_7', emoji: '🏆', title: '7일 연속 읽기',
      expReward: 50,
      done: (s) => s.streak >= 7,
    ),
    TrackerQuest(
      id: 'nt_complete', emoji: '🏆', title: '신약 완독',
      expReward: 200,
      done: (s) => TrackerPlan._nt.every((k) => s.readBooks.contains(k)),
    ),
    TrackerQuest(
      id: 'ot_complete', emoji: '🏆', title: '구약 완독',
      expReward: 300,
      done: (s) {
        final otKeys =
            BookSelectPage.oldTestament.map((b) => b['key'] as String);
        return otKeys.every((k) => s.readBooks.contains(k));
      },
    ),
    TrackerQuest(
      id: 'bible_complete', emoji: '🏆', title: '66권 완독',
      expReward: 1000,
      done: (s) {
        final all = BookSelectPage.allBooks
            .map((b) => b['key'] as String);
        return all.every((k) => s.readBooks.contains(k));
      },
    ),
  ];
}

// ── 계산용 스냅샷 ───────────────────────────────────────────
class TrackerSnapshot {
  final Set<String> readChapters; // "book:chapter"
  final Set<String> readBooks;    // "book"
  final List<DateTime> readDates; // 정렬됨
  final int streak;
  final Set<String> completedQuestIds;

  TrackerSnapshot({
    required this.readChapters,
    required this.readBooks,
    required this.readDates,
    required this.streak,
    required this.completedQuestIds,
  });
}

// ── 페이지 ───────────────────────────────────────────────────
class BibleTrackerPage extends StatefulWidget {
  const BibleTrackerPage({super.key});

  @override
  State<BibleTrackerPage> createState() => _BibleTrackerPageState();
}

class _BibleTrackerPageState extends State<BibleTrackerPage> {
  String _planId = '';
  DateTime? _startDate;
  Set<String> _readDates = {}; // 'YYYY-MM-DD'
  Set<String> _completedQuests = {};
  String _version = 'krv';

  TrackerSnapshot? _snap;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final readCh = await ExperienceService.getReadChapters();
    final readBooks = await ExperienceService.getReadBooks();
    final readDates =
        (prefs.getStringList('tracker_read_dates') ?? <String>[]).toSet();
    // 오늘 한 장이라도 읽었으면 오늘 날짜 자동 추가
    final today = _isoDate(DateTime.now());
    if (readCh.isNotEmpty && !readDates.contains(today)) {
      // 기존 기록이 있을 때만 자동 추가 방지
    }

    final dates = readDates
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .toList()
      ..sort();

    final streak = _calcStreak(dates);

    if (!mounted) return;
    setState(() {
      _planId = prefs.getString('tracker_plan') ?? '';
      _startDate = DateTime.tryParse(prefs.getString('tracker_start') ?? '');
      _readDates = readDates;
      _completedQuests =
          (prefs.getStringList('tracker_quests_completed') ?? <String>[])
              .toSet();
      _version = prefs.getString('last_version') ?? 'krv';
      _snap = TrackerSnapshot(
        readChapters: readCh,
        readBooks: readBooks,
        readDates: dates,
        streak: streak,
        completedQuestIds: _completedQuests,
      );
    });

    // 미완료 퀘스트 자동 완료 처리
    await _checkQuests();
  }

  Future<void> _checkQuests() async {
    if (_snap == null) return;
    final prefs = await SharedPreferences.getInstance();
    final completed = Set<String>.from(_completedQuests);
    bool changed = false;
    for (final q in TrackerQuest.all) {
      if (!completed.contains(q.id) && q.done(_snap!)) {
        completed.add(q.id);
        await ExperienceService.addExp(q.expReward);
        changed = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${q.emoji} ${q.title} 완료 · +${q.expReward} EXP'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
    if (changed) {
      await prefs.setStringList(
          'tracker_quests_completed', completed.toList());
      if (mounted) setState(() => _completedQuests = completed);
    }
  }

  Future<void> _selectPlan(TrackerPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracker_plan', plan.id);
    await prefs.setString(
        'tracker_start', _isoDate(DateTime.now()));
    if (!mounted) return;
    setState(() {
      _planId = plan.id;
      _startDate = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${plan.emoji} ${plan.name} 시작!'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _markTodayRead() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _isoDate(DateTime.now());
    final set = Set<String>.from(_readDates)..add(today);
    await prefs.setStringList('tracker_read_dates', set.toList());
    await ExperienceService.addExp(ExperienceService.expPerChapterRead);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('✓ 오늘 분량 완료! +10 EXP'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  // ── 오늘 분량 계산 ───────────────────────────────────────
  (String book, int chapter)? _todayAssignment() {
    final plan = TrackerPlan.byId(_planId);
    if (plan == null || plan.books.isEmpty || _startDate == null) return null;
    final diff = DateTime.now().difference(_startDate!).inDays;
    // 총 장 수 계산 (해당 plan의 책들)
    final chapters = <(String, int)>[];
    for (final bk in plan.books) {
      final total = BookSelectPage.getChapterCount(bk);
      for (int c = 1; c <= total; c++) {
        chapters.add((bk, c));
      }
    }
    if (chapters.isEmpty) return null;
    // 하루당 장 수 = (total / days) 올림
    final perDay = (chapters.length / plan.days).ceil();
    final idx = (diff * perDay).clamp(0, chapters.length - 1);
    return chapters[idx];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);
    final primary = Theme.of(context).colorScheme.primary;
    const gold = Color(0xFFC9A84C);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('바이블 트래커',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _snap == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _buildCurrentPlan(isDark, gold),
                  const SizedBox(height: 20),
                  _sectionLabel('플랜 목록', isDark),
                  const SizedBox(height: 10),
                  ...TrackerPlan.all.map(
                      (p) => _PlanTile(
                            plan: p,
                            selected: p.id == _planId,
                            isDark: isDark,
                            onTap: () => _selectPlan(p),
                          )),
                  const SizedBox(height: 20),
                  _sectionLabel('오늘 읽을 분량', isDark),
                  const SizedBox(height: 10),
                  _buildTodayAssignment(isDark, gold),
                  const SizedBox(height: 20),
                  _sectionLabel('달력 (최근 30일)', isDark),
                  const SizedBox(height: 10),
                  _buildCalendar(isDark, gold),
                  const SizedBox(height: 20),
                  _sectionLabel('퀘스트', isDark),
                  const SizedBox(height: 10),
                  ...TrackerQuest.all.map((q) => _QuestTile(
                        quest: q,
                        completed: _completedQuests.contains(q.id),
                        isDark: isDark,
                      )),
                  const SizedBox(height: 28),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String t, bool isDark) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 4),
        child: Text(t,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
      );

  Widget _buildCurrentPlan(bool isDark, Color gold) {
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    final plan = TrackerPlan.byId(_planId);
    final totalDays = plan?.days ?? 0;
    final elapsed = _startDate == null
        ? 0
        : DateTime.now().difference(_startDate!).inDays;
    final remain = totalDays > 0 ? (totalDays - elapsed).clamp(0, totalDays) : 0;
    final pct = totalDays > 0
        ? (elapsed / totalDays).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(plan?.emoji ?? '🧭',
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan?.name ?? '플랜 없음',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: text)),
                  const SizedBox(height: 2),
                  Text(plan == null
                      ? '아래에서 플랜을 선택해 항해를 시작해요'
                      : plan.desc,
                      style: TextStyle(fontSize: 12, color: sub)),
                ],
              ),
            ),
            // 스트릭
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 3),
                Text('${_snap!.streak}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B35))),
              ]),
            ),
          ]),
          if (plan != null && totalDays > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: isDark
                    ? const Color(0xFF2C3E50)
                    : const Color(0xFFE5E5EA),
                valueColor: AlwaysStoppedAnimation(gold),
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Text('진행률 ${(pct * 100).toInt()}%',
                  style: TextStyle(fontSize: 11, color: sub)),
              const Spacer(),
              Text('D-${remain == 0 ? 'Day' : remain}',
                  style: TextStyle(
                      fontSize: 11, color: gold,
                      fontWeight: FontWeight.w700)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayAssignment(bool isDark, Color gold) {
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final assign = _todayAssignment();

    if (assign == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, size: 18, color: sub),
          const SizedBox(width: 10),
          Expanded(
              child: Text('플랜을 선택하면 오늘 분량이 자동 배정돼요',
                  style: TextStyle(fontSize: 13, color: sub))),
        ]),
      );
    }

    final bookName = BibleBookNames.get(assign.$1, AppLocale.current);
    final todayDone = _readDates.contains(_isoDate(DateTime.now()));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_stories_rounded, color: gold, size: 20),
            const SizedBox(width: 8),
            Text('$bookName ${assign.$2}장',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: text)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BibleReadPage(
                      version: _version,
                      bookKey: assign.$1,
                      bookName: bookName,
                      chapter: assign.$2,
                      totalChapters:
                          BookSelectPage.getChapterCount(assign.$1),
                    ),
                  )).then((_) => _load());
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('지금 읽기'),
                style: FilledButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: const Color(0xFF0D1B2A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: todayDone ? null : _markTodayRead,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: todayDone
                      ? gold
                      : (isDark
                          ? const Color(0xFF2C3E50)
                          : const Color(0xFFE5E5EA)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: todayDone
                      ? const Color(0xFF0D1B2A)
                      : sub,
                  size: 22,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isDark, Color gold) {
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    // 최근 30일 격자 (오늘 기준 역순)
    final today = DateTime.now();
    final days = List.generate(30, (i) {
      final d = today.subtract(Duration(days: 29 - i));
      return d;
    });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: gold, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('읽은 날',
                  style: TextStyle(fontSize: 11, color: sub)),
              const SizedBox(width: 14),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C3E50)
                      : const Color(0xFFE5E5EA),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text('없음',
                  style: TextStyle(fontSize: 11, color: sub)),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: days.map((d) {
              final read = _readDates.contains(_isoDate(d));
              return Container(
                decoration: BoxDecoration(
                  color: read
                      ? gold
                      : (isDark
                          ? const Color(0xFF2C3E50)
                          : const Color(0xFFE5E5EA)),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── 플랜 타일 ────────────────────────────────────────────────
class _PlanTile extends StatelessWidget {
  final TrackerPlan plan;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC9A84C);
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? gold.withOpacity(0.12) : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? gold
                  : (isDark
                      ? const Color(0xFF2C3E50)
                      : const Color(0xFFE5E5EA)),
              width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Text(plan.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? gold : text)),
                const SizedBox(height: 2),
                Text(plan.desc,
                    style: TextStyle(fontSize: 12, color: sub)),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: gold, size: 22),
        ]),
      ),
    );
  }
}

// ── 퀘스트 타일 ─────────────────────────────────────────────
class _QuestTile extends StatelessWidget {
  final TrackerQuest quest;
  final bool completed;
  final bool isDark;
  const _QuestTile({
    required this.quest,
    required this.completed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC9A84C);
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: completed ? gold.withOpacity(0.1) : cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Text(quest.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(quest.title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: completed ? sub : text,
                  decoration: completed
                      ? TextDecoration.lineThrough
                      : null)),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: completed
                ? gold.withOpacity(0.18)
                : gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            completed ? '✓ 완료' : '+${quest.expReward}',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: gold),
          ),
        ),
      ]),
    );
  }
}

// ── 유틸 ────────────────────────────────────────────────────
String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int _calcStreak(List<DateTime> dates) {
  if (dates.isEmpty) return 0;
  final todayStr = _isoDate(DateTime.now());
  final yesterdayStr =
      _isoDate(DateTime.now().subtract(const Duration(days: 1)));
  final setStrs = dates.map(_isoDate).toSet();
  // 오늘 또는 어제부터 역으로 연속 카운트
  DateTime cursor;
  if (setStrs.contains(todayStr)) {
    cursor = DateTime.now();
  } else if (setStrs.contains(yesterdayStr)) {
    cursor = DateTime.now().subtract(const Duration(days: 1));
  } else {
    return 0;
  }
  int streak = 0;
  while (setStrs.contains(_isoDate(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
