// lib/pages/search_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bible_read_page.dart';
import 'book_select_page.dart';
import '../l10n/app_strings.dart';

// ── 검색 범위 ─────────────────────────────────────────────────
class _Scope {
  final String label;
  final List<String>? keys;
  const _Scope(this.label, this.keys);
}

const _oldKeys = ['genesis','exodus','leviticus','numbers','deuteronomy','joshua','judges','ruth','1samuel','2samuel','1kings','2kings','1chronicles','2chronicles','ezra','nehemiah','esther','job','psalms','proverbs','ecclesiastes','songofsolomon','isaiah','jeremiah','lamentations','ezekiel','daniel','hosea','joel','amos','obadiah','jonah','micah','nahum','habakkuk','zephaniah','haggai','zechariah','malachi'];
const _newKeys = ['matthew','mark','luke','john','acts','romans','1corinthians','2corinthians','galatians','ephesians','philippians','colossians','1thessalonians','2thessalonians','1timothy','2timothy','titus','philemon','hebrews','james','1peter','2peter','1john','2john','3john','jude','revelation'];

final List<_Scope> _scopes = [
  const _Scope('전체 성경', null),
  _Scope('구약', _oldKeys),
  _Scope('신약', _newKeys),
  const _Scope('율법서', ['genesis','exodus','leviticus','numbers','deuteronomy']),
  const _Scope('역사서', ['joshua','judges','ruth','1samuel','2samuel','1kings','2kings','1chronicles','2chronicles','ezra','nehemiah','esther']),
  const _Scope('시편 & 지혜 문학', ['job','psalms','proverbs','ecclesiastes','songofsolomon']),
  const _Scope('예언서', ['isaiah','jeremiah','lamentations','ezekiel','daniel','hosea','joel','amos','obadiah','jonah','micah','nahum','habakkuk','zephaniah','haggai','zechariah','malachi']),
  const _Scope('복음서', ['matthew','mark','luke','john']),
  const _Scope('사도행전', ['acts']),
  const _Scope('서신', ['romans','1corinthians','2corinthians','galatians','ephesians','philippians','colossians','1thessalonians','2thessalonians','1timothy','2timothy','titus','philemon','hebrews','james','1peter','2peter','1john','2john','3john','jude']),
  const _Scope('요한계시록', ['revelation']),
];

class SearchResult {
  final String bookKey, bookName;
  final int chapter, verse;
  final String text;
  const SearchResult({required this.bookKey, required this.bookName,
      required this.chapter, required this.verse, required this.text});
}

// ── SearchPage ─────────────────────────────────────────────────
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl      = TextEditingController();
  final _focusNode = FocusNode();

  List<SearchResult> _results   = [];
  bool   _isSearching = false;
  bool   _hasSearched = false;
  String _lastQuery   = '';
  String _version     = 'krv';
  int    _scopeIndex  = 0;
  String _sortBy      = 'book';

  // BookSelectPage.versions에서 available:true인 것만 (일치 유지)
  static const _versionNames = {
    'krv':   '개역개정',
    'korv':  '개역성경',
    'kjv':   'KJV',
    'chiun': '和合本',
    'chisb': '思高本',
  };
  // 실제 데이터가 있는 번역본만 (메인화면과 동일)
  static const _availableVersions = ['krv', 'korv', 'kjv', 'chiun', 'chisb'];

  @override
  void initState() {
    super.initState();
    _loadVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _version = p.getString('last_version') ?? 'krv');
  }

  List<Map<String, dynamic>> get _scopeBooks {
    final scope = _scopes[_scopeIndex];
    final all   = BookSelectPage.allBooks;
    if (scope.keys == null) return all;
    return all.where((b) => scope.keys!.contains(b['key'])).toList();
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() {
      _isSearching = true;
      _hasSearched = false;
      _results     = [];
      _lastQuery   = q;
    });

    final found = <SearchResult>[];
    for (final book in _scopeBooks) {
      final bKey  = book['key'] as String;
      final bName = book['name'] as String;
      final chs   = book['chapters'] as int;
      for (int ch = 1; ch <= chs; ch++) {
        try {
          final raw  = await rootBundle.loadString('assets/bible/$_version/$bKey/$ch.json');
          final list = json.decode(raw) as List;
          for (int i = 0; i < list.length; i++) {
            final t = list[i].toString();
            if (t.contains(q)) {
              found.add(SearchResult(
                bookKey: bKey, bookName: bName,
                chapter: ch, verse: i + 1, text: t,
              ));
            }
          }
        } catch (_) {}
      }
    }

    // 정렬
    if (_sortBy == 'book') {
      // 책 순서대로
      final order = BookSelectPage.allBooks.map((b) => b['key'] as String).toList();
      found.sort((a, b) {
        final ai = order.indexOf(a.bookKey);
        final bi = order.indexOf(b.bookKey);
        if (ai != bi) return ai.compareTo(bi);
        if (a.chapter != b.chapter) return a.chapter.compareTo(b.chapter);
        return a.verse.compareTo(b.verse);
      });
    } else {
      // 관련성 (검색어 등장 횟수 많은 순)
      int countOccurrences(String text, String query) {
        int count = 0, idx = 0;
        while ((idx = text.indexOf(query, idx)) != -1) { count++; idx += query.length; }
        return count;
      }
      found.sort((a, b) =>
          countOccurrences(b.text, q).compareTo(countOccurrences(a.text, q)));
    }

    if (mounted) {
      setState(() {
        _results     = found;
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  List<TextSpan> _highlight(String text, String q, TextStyle base, Color color) {
    if (q.isEmpty) return [TextSpan(text: text, style: base)];
    final spans = <TextSpan>[];
    int start = 0;
    final lo = text.toLowerCase(), lq = q.toLowerCase();
    int idx = lo.indexOf(lq, start);
    while (idx != -1) {
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx), style: base));
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: base.copyWith(color: color, fontWeight: FontWeight.bold,
            backgroundColor: color.withOpacity(0.15)),
      ));
      start = idx + q.length;
      idx = lo.indexOf(lq, start);
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start), style: base));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bg        = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);
    final cardBg    = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final textColor = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub       = const Color(0xFF8E8E93);
    final primary   = Theme.of(context).colorScheme.primary;
    final chipBg    = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final chipBdr   = isDark ? const Color(0xFF2C3E50) : const Color(0xFFE5E5EA);
    final vName     = _versionNames[_version] ?? _version;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: const Text('구절 검색',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _showVersionPicker,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(vName,
                    style: TextStyle(fontSize: 13, color: primary,
                        fontWeight: FontWeight.w600)),
                Icon(Icons.expand_more_rounded, size: 16, color: primary),
              ]),
            ),
          ),
        ],
      ),
      body: Column(children: [

        // 검색창
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _ctrl, focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            style: TextStyle(color: textColor, fontSize: 16),
            decoration: InputDecoration(
              hintText: '검색어를 입력하세요',
              hintStyle: TextStyle(color: sub),
              prefixIcon: Icon(Icons.search_rounded, color: sub),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, color: sub),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() { _results = []; _hasSearched = false; _lastQuery = ''; });
                      })
                  : null,
              filled: true, fillColor: cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primary.withOpacity(0.5), width: 1.5)),
            ),
            onChanged: (v) => setState(() {}),
          ),
        ),

        // 범위 필터 칩
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            itemCount: _scopes.length,
            itemBuilder: (_, i) {
              final sel = i == _scopeIndex;
              return GestureDetector(
                onTap: () => setState(() {
                  _scopeIndex = i;
                  _results    = [];
                  _hasSearched = false;
                }),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? primary : chipBg,
                    borderRadius: BorderRadius.circular(20),
                    border: sel ? null : Border.all(color: chipBdr),
                  ),
                  child: Text(_scopes[i].label,
                      style: TextStyle(fontSize: 12,
                          color: sel ? Colors.white : sub,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                ),
              );
            },
          ),
        ),

        // 정렬 방식
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Row(children: [
            Text('정렬 방식', style: TextStyle(fontSize: 12, color: sub)),
            const Spacer(),
            GestureDetector(
              onTap: () => _showSortPicker(isDark, primary, sub),
              child: Row(children: [
                Text(_sortBy == 'book' ? '책에 의해' : '관련성에 의해',
                    style: TextStyle(fontSize: 12, color: primary,
                        fontWeight: FontWeight.w600)),
                Icon(Icons.expand_more_rounded, size: 16, color: primary),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 6),

        // 검색 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSearching ? null : () => _search(_ctrl.text),
              icon: _isSearching
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search_rounded, size: 18),
              label: Text(_isSearching ? '검색 중...' : '검색'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),

        // 결과
        Expanded(child: _buildResults(
            isDark, bg, cardBg, textColor, sub, primary, vName)),
      ]),
    );
  }

  Widget _buildResults(bool isDark, Color bg, Color cardBg,
      Color textColor, Color sub, Color primary, String vName) {
    final scopeLabel = _scopes[_scopeIndex].label;

    if (_isSearching) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text('$vName · $scopeLabel 검색 중...',
            style: TextStyle(color: sub, fontSize: 14)),
      ]));
    }

    if (!_hasSearched) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.auto_stories_rounded, size: 56,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('$vName · $scopeLabel에서 검색해요',
            style: TextStyle(color: sub, fontSize: 15)),
      ]));
    }

    if (_results.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off_rounded, size: 56,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('"$_lastQuery" 결과 없음', style: TextStyle(color: sub, fontSize: 15)),
        const SizedBox(height: 4),
        Text('$scopeLabel · $vName', style: TextStyle(color: sub.withOpacity(0.6), fontSize: 12)),
      ]));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 결과 개수 헤더
      Container(
        width: double.infinity,
        color: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFEEEEEE),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text('$scopeLabel에서 ${_results.length}개의 결과를 찾았습니다',
            style: TextStyle(fontSize: 13, color: sub, fontWeight: FontWeight.w500)),
      ),
      // 결과 목록
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: _results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = _results[i];
            return Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BibleReadPage(
                    version: _version,
                    bookKey: r.bookKey,
                    bookName: r.bookName,
                    chapter: r.chapter,
                    totalChapters: BookSelectPage.getChapterCount(r.bookKey),
                    highlightVerse: r.verse,
                  ),
                )),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.menu_book_rounded, size: 13, color: primary),
                      const SizedBox(width: 4),
                      Text('${r.bookName} ${r.chapter}:${r.verse}',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.bold, color: primary)),
                    ]),
                    const SizedBox(height: 6),
                    RichText(text: TextSpan(children: _highlight(
                      r.text, _lastQuery,
                      TextStyle(fontSize: 14, height: 1.6, color: textColor),
                      primary,
                    ))),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  void _showSortPicker(bool isDark, Color primary, Color sub) {
    final bg   = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final text = isDark ? Colors.white : Colors.black;
    final div  = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: sub.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          for (final entry in {'book': '책에 의해', 'relevance': '관련성에 의해'}.entries)
            Column(mainAxisSize: MainAxisSize.min, children: [
              Divider(height: 1, color: div),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _sortBy = entry.key);
                  if (_hasSearched) _search(_lastQuery);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(children: [
                    Expanded(child: Text(entry.value, style: TextStyle(
                        fontSize: 15,
                        color: _sortBy == entry.key ? primary : text,
                        fontWeight: _sortBy == entry.key
                            ? FontWeight.w600 : FontWeight.normal))),
                    if (_sortBy == entry.key)
                      Icon(Icons.check_rounded, color: primary, size: 20),
                  ]),
                ),
              ),
            ]),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  void _showVersionPicker() {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final text    = isDark ? Colors.white : Colors.black;
    final sub     = const Color(0xFF8E8E93);
    final div     = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    final primary = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: sub.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('번역본 선택', style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w600, color: text)),
            const SizedBox(height: 12),
            Divider(height: 1, color: div),
            ..._versionNames.entries.where((e) => _availableVersions.contains(e.key)).map((e) => GestureDetector(
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _version = e.key;
                  _results = [];
                  _hasSearched = false;
                  _lastQuery = '';
                });
                if (_ctrl.text.isNotEmpty) _search(_ctrl.text);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  Container(width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: e.key == _version ? primary : sub.withOpacity(0.4),
                            width: 2),
                        color: e.key == _version ? primary : Colors.transparent,
                      ),
                      child: e.key == _version
                          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                          : null),
                  const SizedBox(width: 14),
                  Text(e.value, style: TextStyle(fontSize: 15,
                      fontWeight: e.key == _version ? FontWeight.w600 : FontWeight.normal,
                      color: e.key == _version ? primary : text)),
                ]),
              ),
            )),
            const SizedBox(height: 8),
          ]),
        )),
      ),
    );
  }
}
