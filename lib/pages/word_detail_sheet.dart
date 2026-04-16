// lib/pages/word_detail_sheet.dart
//
// 연구 모드에서 단어 탭 시 표시되는 Bottom Sheet
// 현재: 히브리어/헬라어 사전 검색 (Strong# 또는 단어 기반)
// 추후: tagged JSON 완성 시 형태소, 교차참조 탭 활성화

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/verse_ref.dart';
import '../services/memo_service.dart';
import 'memo_detail_page.dart';

// ── 사전 엔트리 모델 ──────────────────────────────────────────
class LexiconEntry {
  final String strong;          // "H430" or "G2316"
  final String lemma;           // 원어 문자
  final String transliteration; // 음역
  final String pronunciation;   // 발음
  final String definitionKo;    // 한국어 뜻
  final String definitionEn;    // 영어 뜻 (BDB/Thayer)
  final String kjvUsage;        // KJV 사용 패턴
  final int    count;           // 사용 횟수
  final String origin;          // 어원

  const LexiconEntry({
    required this.strong,
    required this.lemma,
    required this.transliteration,
    required this.pronunciation,
    required this.definitionKo,
    required this.definitionEn,
    required this.kjvUsage,
    required this.count,
    required this.origin,
  });

  factory LexiconEntry.fromJson(Map<String, dynamic> m) => LexiconEntry(
        strong:          m['strong']          as String? ?? '',
        lemma:           m['lemma']           as String? ?? '',
        transliteration: m['transliteration'] as String? ?? '',
        pronunciation:   m['pronunciation']   as String? ?? '',
        definitionKo:    m['definition_ko']   as String? ?? '',
        definitionEn:    m['definition_en']   as String? ?? '',
        kjvUsage:        m['kjv_usage']       as String? ?? '',
        count:           m['count']           as int?    ?? 0,
        origin:          m['origin']          as String? ?? '',
      );

  bool get isHebrew => strong.startsWith('H');
  bool get isGreek  => strong.startsWith('G');
}

// ── Strong# 기반 사전 서비스 ──────────────────────────────────
class _LexiconService {
  static final _LexiconService _i = _LexiconService._();
  factory _LexiconService() => _i;
  _LexiconService._();

  Map<String, LexiconEntry>? _combined;

  Future<Map<String, LexiconEntry>> _load() async {
    if (_combined != null) return _combined!;
    try {
      // Strong's 통합 사전 (step_a2_strongs.py 결과물)
      final raw  = await rootBundle.loadString(
          'assets/lexicon/strongs_combined.json');
      final map  = jsonDecode(raw) as Map<String, dynamic>;
      _combined  = map.map((k, v) =>
          MapEntry(k, LexiconEntry.fromJson(v as Map<String, dynamic>)));
      return _combined!;
    } catch (_) {
      // strongs_combined.json 없을 때 기존 사전으로 fallback
      return _loadFallback();
    }
  }

  Future<Map<String, LexiconEntry>> _loadFallback() async {
    // 기존 hebrew_dict.json + greek_dict.json 로 임시 매핑
    final result = <String, LexiconEntry>{};
    try {
      final hRaw  = await rootBundle.loadString('assets/data/hebrew_dict.json');
      final hList = jsonDecode(hRaw) as List;
      for (final item in hList) {
        final m   = item as Map<String, dynamic>;
        final id  = m['id'] as int;
        final key = 'H$id';
        result[key] = LexiconEntry(
          strong:          key,
          lemma:           m['original']      as String? ?? '',
          transliteration: m['pronunciation'] as String? ?? '',
          pronunciation:   '',
          definitionKo:    m['meaning']       as String? ?? '',
          definitionEn:    '',
          kjvUsage:        '',
          count:           0,
          origin:          '',
        );
      }
    } catch (_) {}
    try {
      final gRaw  = await rootBundle.loadString('assets/data/greek_dict.json');
      final gList = jsonDecode(gRaw) as List;
      for (final item in gList) {
        final m   = item as Map<String, dynamic>;
        final id  = m['id'] as int;
        final key = 'G$id';
        result[key] = LexiconEntry(
          strong:          key,
          lemma:           m['original']      as String? ?? '',
          transliteration: m['pronunciation'] as String? ?? '',
          pronunciation:   '',
          definitionKo:    m['meaning']       as String? ?? '',
          definitionEn:    '',
          kjvUsage:        '',
          count:           0,
          origin:          '',
        );
      }
    } catch (_) {}
    _combined = result;
    return result;
  }

  Future<LexiconEntry?> findByStrong(String strongNum) async {
    final map = await _load();
    return map[strongNum];
  }

  Future<List<LexiconEntry>> searchByKorean(String query) async {
    final map = await _load();
    return map.values
        .where((e) =>
            e.definitionKo.contains(query) ||
            e.transliteration.contains(query))
        .take(20)
        .toList();
  }
}

// ── 탭 정의 ──────────────────────────────────────────────────
enum _Tab { lexicon, morphology, crossRef, memo }

// ── WordDetailSheet ───────────────────────────────────────────
class WordDetailSheet extends StatefulWidget {
  final String   word;       // 탭한 단어 텍스트
  final String?  strongNum;  // Strong 번호 (있으면 직접 조회)
  final VerseRef? verseRef;  // 연결할 구절 (메모용)

  const WordDetailSheet({
    super.key,
    required this.word,
    this.strongNum,
    this.verseRef,
  });

  // ── 정적 열기 헬퍼 ──────────────────────────────────────────
  static Future<void> show(
    BuildContext context, {
    required String word,
    String? strongNum,
    VerseRef? verseRef,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordDetailSheet(
        word:      word,
        strongNum: strongNum,
        verseRef:  verseRef,
      ),
    );
  }

  @override
  State<WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends State<WordDetailSheet>
    with SingleTickerProviderStateMixin {
  final _service = _LexiconService();

  _Tab          _tab     = _Tab.lexicon;
  LexiconEntry? _entry;
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    LexiconEntry? found;

    if (widget.strongNum != null) {
      found = await _service.findByStrong(widget.strongNum!);
    }

    // Strong# 없으면 한국어로 검색
    if (found == null) {
      final results = await _service.searchByKorean(widget.word);
      found = results.isNotEmpty ? results.first : null;
    }

    if (mounted) setState(() { _entry = found; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final primary  = Theme.of(context).colorScheme.primary;
    final bg       = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final sub      = const Color(0xFF8E8E93);

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize:     0.3,
      maxChildSize:     0.92,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 드래그 핸들
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: sub.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),

            // ── 헤더 ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildHeader(isDark, primary, sub),
            ),

            const SizedBox(height: 16),

            // ── 탭 ──────────────────────────────────────────
            if (!_loading) _buildTabBar(isDark, primary, sub),

            const SizedBox(height: 4),
            const Divider(height: 1),

            // ── 탭 내용 ──────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      controller: ctrl,
                      padding: const EdgeInsets.all(20),
                      child: _buildTabContent(isDark, primary, sub),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 헤더 (원어 + Strong#) ─────────────────────────────────
  Widget _buildHeader(bool isDark, Color primary, Color sub) {
    final text = isDark ? Colors.white : Colors.black;

    if (_entry == null) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.word,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: text)),
                const SizedBox(height: 4),
                Text('사전 정보를 찾을 수 없어요',
                    style: TextStyle(fontSize: 13, color: sub)),
              ],
            ),
          ),
          _MemoButton(
            word: widget.word,
            entry: null,
            verseRef: widget.verseRef,
            primary: primary,
            isDark: isDark,
          ),
        ],
      );
    }

    final e = _entry!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 원어 + 음역
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(e.lemma.isNotEmpty ? e.lemma : widget.word,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: text)),
                  if (e.transliteration.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Text(e.transliteration,
                        style: TextStyle(
                            fontSize: 16,
                            color: primary,
                            fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              // Strong# + 사용 횟수
              Row(
                children: [
                  if (e.strong.isNotEmpty)
                    _Badge(
                        text: e.strong,
                        color: e.isHebrew
                            ? const Color(0xFF5C7FA3)
                            : const Color(0xFF7B68EE)),
                  if (e.count > 0) ...[
                    const SizedBox(width: 8),
                    _Badge(
                        text: '${e.count}회 사용',
                        color: sub),
                  ],
                  if (e.pronunciation.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(e.pronunciation,
                        style: TextStyle(fontSize: 12, color: sub)),
                  ],
                ],
              ),
            ],
          ),
        ),
        _MemoButton(
          word: widget.word,
          entry: _entry,
          verseRef: widget.verseRef,
          primary: primary,
          isDark: isDark,
        ),
      ],
    );
  }

  // ── 탭 바 ─────────────────────────────────────────────────
  Widget _buildTabBar(bool isDark, Color primary, Color sub) {
    final tabs = [
      (tab: _Tab.lexicon,    label: '사전',    enabled: true),
      (tab: _Tab.morphology, label: '형태소',  enabled: false),
      (tab: _Tab.crossRef,   label: '연결구절', enabled: false),
      (tab: _Tab.memo,       label: '메모',    enabled: true),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs.map((t) {
          final sel = _tab == t.tab;
          return GestureDetector(
            onTap: t.enabled
                ? () => setState(() => _tab = t.tab)
                : null,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel
                    ? primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: sel
                    ? Border.all(color: primary.withOpacity(0.4), width: 1)
                    : null,
              ),
              child: Text(
                t.enabled ? t.label : '${t.label} 🔜',
                style: TextStyle(
                    fontSize: 13,
                    color: sel
                        ? primary
                        : (t.enabled ? sub : sub.withOpacity(0.4)),
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 탭 내용 ────────────────────────────────────────────────
  Widget _buildTabContent(bool isDark, Color primary, Color sub) {
    switch (_tab) {
      case _Tab.lexicon:    return _buildLexicon(isDark, primary, sub);
      case _Tab.morphology: return _buildComingSoon('형태소', sub);
      case _Tab.crossRef:   return _buildComingSoon('연결구절', sub);
      case _Tab.memo:       return _buildMemoTab(isDark, primary, sub);
    }
  }

  // ── 사전 탭 ────────────────────────────────────────────────
  Widget _buildLexicon(bool isDark, Color primary, Color sub) {
    if (_entry == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('"${widget.word}"에 대한 사전 정보가 없어요',
              style: TextStyle(color: sub, fontSize: 14),
              textAlign: TextAlign.center),
        ),
      );
    }
    final e    = _entry!;
    final text = isDark ? Colors.white : Colors.black;
    final div  = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 한국어 뜻
        if (e.definitionKo.isNotEmpty) ...[
          _SectionLabel('뜻 (한국어)', sub),
          const SizedBox(height: 8),
          Text(e.definitionKo,
              style: TextStyle(fontSize: 15, color: text, height: 1.6)),
          const SizedBox(height: 20),
        ],

        // 영어 뜻 (BDB/Thayer)
        if (e.definitionEn.isNotEmpty) ...[
          _SectionLabel('Definition (English)', sub),
          const SizedBox(height: 8),
          Text(e.definitionEn,
              style: TextStyle(fontSize: 14, color: text, height: 1.6)),
          const SizedBox(height: 20),
        ],

        // KJV 사용 패턴
        if (e.kjvUsage.isNotEmpty) ...[
          Divider(color: div),
          const SizedBox(height: 12),
          _SectionLabel('KJV 사용 패턴', sub),
          const SizedBox(height: 8),
          Text(e.kjvUsage,
              style: TextStyle(fontSize: 13, color: sub, height: 1.5)),
          const SizedBox(height: 20),
        ],

        // 어원
        if (e.origin.isNotEmpty) ...[
          Divider(color: div),
          const SizedBox(height: 12),
          _SectionLabel('어원', sub),
          const SizedBox(height: 8),
          Text(e.origin,
              style: TextStyle(fontSize: 13, color: sub, height: 1.5)),
        ],
      ],
    );
  }

  // ── 메모 탭 ────────────────────────────────────────────────
  Widget _buildMemoTab(bool isDark, Color primary, Color sub) {
    final memos = MemoService.getAll();
    final text  = isDark ? Colors.white : Colors.black;
    final cardBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 새 메모 버튼
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemoDetailPage(
                  initialVerse: widget.verseRef,
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: primary, size: 20),
                const SizedBox(width: 8),
                Text('새 노트 작성',
                    style: TextStyle(
                        color: primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),

        if (memos.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionLabel('기존 노트에 추가', sub),
          const SizedBox(height: 10),
          ...memos.map((memo) => GestureDetector(
                onTap: () async {
                  if (widget.verseRef != null) {
                    await MemoService.addVerse(memo.id, widget.verseRef!);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded,
                          size: 18, color: primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(memo.previewTitle,
                            style: TextStyle(fontSize: 14, color: text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Icon(Icons.add_rounded, color: primary, size: 18),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildComingSoon(String name, Color sub) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.construction_rounded,
                  size: 48, color: sub.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text('$name 기능은 준비 중이에요',
                  style: TextStyle(color: sub, fontSize: 14)),
              const SizedBox(height: 8),
              Text('Strong# 태깅 데이터 완성 후 활성화돼요',
                  style: TextStyle(color: sub.withOpacity(0.6), fontSize: 12)),
            ],
          ),
        ),
      );
}

// ── 메모 버튼 ─────────────────────────────────────────────────
class _MemoButton extends StatelessWidget {
  final String        word;
  final LexiconEntry? entry;
  final VerseRef?     verseRef;
  final Color         primary;
  final bool          isDark;

  const _MemoButton({
    required this.word,
    required this.entry,
    required this.verseRef,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemoDetailPage(initialVerse: verseRef),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, size: 16, color: primary),
            const SizedBox(width: 4),
            Text('메모',
                style: TextStyle(
                    fontSize: 13,
                    color: primary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── 작은 위젯들 ───────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  final Color  color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600)),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color  color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color));
}
