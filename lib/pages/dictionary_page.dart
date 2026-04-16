// lib/pages/dictionary_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── 모델 ──────────────────────────────────────────────
class DictionaryEntry {
  final int id;
  final String? sub;
  final String original;
  final String pronunciation;
  final String meaning;

  const DictionaryEntry({
    required this.id,
    this.sub,
    required this.original,
    required this.pronunciation,
    required this.meaning,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> m) => DictionaryEntry(
        id: m['id'] as int,
        sub: m['sub'] as String?,
        original: m['original'] as String? ?? '',
        pronunciation: m['pronunciation'] as String? ?? '',
        meaning: m['meaning'] as String? ?? '',
      );

  String get displayId =>
      (sub != null && sub!.isNotEmpty) ? '$id$sub' : '$id';
}

// ── 서비스 (메모리 캐시) ──────────────────────────────
class _DictService {
  static final _DictService _i = _DictService._();
  factory _DictService() => _i;
  _DictService._();

  List<DictionaryEntry>? _hebrew;
  List<DictionaryEntry>? _greek;

  Future<List<DictionaryEntry>> _load(String lang) async {
    final raw = await rootBundle.loadString('assets/data/${lang}_dict.json');
    final list = jsonDecode(raw) as List;
    return list.map((e) => DictionaryEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DictionaryEntry>> hebrew() async =>
      _hebrew ??= await _load('hebrew');

  Future<List<DictionaryEntry>> greek() async =>
      _greek ??= await _load('greek');

  Future<List<DictionaryEntry>> search(String lang, String query) async {
    final entries = lang == 'hebrew' ? await hebrew() : await greek();
    final q = query.trim();
    if (q.isEmpty) return [];

    final numQuery = int.tryParse(q);
    if (numQuery != null) {
      return entries.where((e) => e.id == numQuery).toList();
    }
    return entries
        .where((e) => e.pronunciation.contains(q) || e.meaning.contains(q))
        .take(60)
        .toList();
  }
}

// ── 페이지 ────────────────────────────────────────────
class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ctrl = TextEditingController();
  final _service = _DictService();

  String _lang = 'hebrew';
  List<DictionaryEntry> _results = [];
  String _browseFilter = '전체'; // 번호 범위 필터
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _lang = _tabController.index == 0 ? 'hebrew' : 'greek';
          _results = [];
          _hasSearched = false;
          _browseFilter = '전체';
          _ctrl.clear();
        });
      }
    });
    _preload();
  }

  Future<void> _preload() async {
    await Future.wait([_service.hebrew(), _service.greek()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; _browseFilter = '전체'; });
      return;
    }
    setState(() => _isSearching = true);
    final results = await _service.search(_lang, query);
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: const Text('원어 사전',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '히브리어 (구약)'),
            Tab(text: '헬라어 (신약)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text('사전 불러오는 중...'),
              ],
            ))
          : Column(children: [
              _buildSearchBar(isDark),
              _buildRangeBar(isDark),   // 번호 범위 필터 (항상 표시)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContent(isDark),
                    _buildContent(isDark),
                  ],
                ),
              ),
            ]),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final subColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _ctrl,
        onChanged: _search,
        style: TextStyle(
          color: isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: '번호(예: 26) 또는 한글(예: 사랑)로 검색',
          hintStyle: TextStyle(color: subColor, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: subColor),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: subColor),
                  onPressed: () { _ctrl.clear(); _search(''); },
                )
              : null,
          filled: true,
          fillColor: cardBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primary.withOpacity(0.5), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final subColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) return _buildEmptyState(isDark);

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('"${_ctrl.text}" 검색 결과가 없어요',
                style: TextStyle(color: subColor, fontSize: 15)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(
            '검색 결과 ${_results.length}개',
            style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _EntryCard(entry: _results[i], isDark: isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final subColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final isHebrew = _lang == 'hebrew';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 72,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            isHebrew ? '히브리어 원어 사전' : '헬라어 원어 사전',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHebrew ? '총 8,274 단어' : '총 5,689 단어',
            style: TextStyle(color: subColor, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text('번호 또는 한글로 검색해보세요',
              style: TextStyle(color: subColor, fontSize: 13)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: (isHebrew
                    ? ['26', '사랑', '평화', '아버지']
                    : ['26', '믿음', '은혜', '사랑'])
                .map((q) => _HintChip(
                      label: q,
                      isDark: isDark,
                      onTap: () { _ctrl.text = q; _search(q); },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── 번호 범위 필터 바 (항상 표시) ────────────────────────
  Widget _buildRangeBar(bool isDark) {
    final cardBg  = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final sub     = Colors.grey.shade500;
    // 히브리어/헬라어 모두 번호 범위로 통일
    final filters = ['전체','1-99','100-199','200-299','300-399','400-499',
        '500-599','600-699','700-799','800-899','900-999','1000+'];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
        child: Row(children: [
          Icon(Icons.filter_list_rounded, size: 16, color: sub),
          const SizedBox(width: 6),
          Text('번호 범위로 찾기',
              style: TextStyle(fontSize: 13, color: sub)),
        ]),
      ),
      SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: filters.length,
          itemBuilder: (_, i) {
            final f = filters[i];
            final sel = _browseFilter == f;
            return GestureDetector(
              onTap: () => setState(() => _browseFilter = f),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? primary : cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: sel ? null : Border.all(
                      color: isDark ? const Color(0xFF2C3E50) : const Color(0xFFE5E5EA)),
                ),
                child: Text(f, style: TextStyle(
                    fontSize: 13,
                    color: sel ? Colors.white : sub,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 4),
    ]);
  }

  // ── 콘텐츠 (검색결과 or 번호순 목록) ──────────────────────
  Widget _buildContent(bool isDark) {
    final sub   = Colors.grey.shade500;
    final isHeb = _lang == 'hebrew';

    // 검색 중이면 검색 결과 표시
    if (_hasSearched) return _buildBody(isDark);

    // 기본: 번호순 전체 목록 (범위 필터 적용)
    return FutureBuilder<List<DictionaryEntry>>(
      future: isHeb ? _DictService().hebrew() : _DictService().greek(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var entries = snap.data!;

        // 번호 범위 필터 적용
        if (_browseFilter.isNotEmpty && _browseFilter != '전체') {
          final parts = _browseFilter.split('-');
          if (parts.length == 2) {
            final lo = int.tryParse(parts[0]) ?? 0;
            final hi = int.tryParse(parts[1]) ?? 999999;
            entries = entries.where((e) => e.id >= lo && e.id <= hi).toList();
          } else if (_browseFilter.contains('+')) {
            final lo = int.tryParse(_browseFilter.replaceAll('+', '')) ?? 1000;
            entries = entries.where((e) => e.id >= lo).toList();
          }
        }

        if (entries.isEmpty) {
          return Center(child: Text('결과 없음',
              style: TextStyle(color: sub)));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _EntryCard(entry: entries[i], isDark: isDark),
        );
      },
    );
  }


} // _DictionaryPageState

// ── 단어 카드 ──────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final DictionaryEntry entry;
  final bool isDark;
  const _EntryCard({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final textColor =
        isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 번호 뱃지
            Container(
              constraints: const BoxConstraints(minWidth: 44),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.displayId,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.original,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(entry.pronunciation,
                            style: TextStyle(
                                fontSize: 14,
                                color: primary,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(entry.meaning,
                      style: TextStyle(
                          fontSize: 13, color: subColor, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 힌트 칩 ───────────────────────────────────────────
class _HintChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _HintChip({required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                color: primary,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}
