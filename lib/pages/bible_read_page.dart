// lib/pages/bible_read_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verse_ref.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';
import '../models/memo.dart';
import '../services/bookmark_service.dart';
import '../services/highlight_service.dart';
import '../services/memo_service.dart';
import 'memo_detail_page.dart';
import 'dictionary_page.dart';
import 'search_page.dart';
import '../l10n/app_strings.dart';
import 'book_select_page.dart';
import 'sheets/commentary_sheet.dart';
import 'sheets/cross_reference_sheet.dart';
import '../services/cross_reference_service.dart';
import '../services/experience_service.dart';

class BibleReadPage extends StatefulWidget {
  final String version;
  final String bookKey;
  final String bookName;
  final int    chapter;
  final int    totalChapters;
  final int?   highlightVerse;

  const BibleReadPage({
    super.key,
    required this.version,
    required this.bookKey,
    required this.bookName,
    required this.chapter,
    required this.totalChapters,
    this.highlightVerse,
  });

  @override
  State<BibleReadPage> createState() => _BibleReadPageState();
}

class _BibleReadPageState extends State<BibleReadPage>
    with SingleTickerProviderStateMixin {

  // ── 페이지 ─────────────────────────────────────────────────
  late PageController _pageController;
  late int _currentChapter;

  // ── 본문 ───────────────────────────────────────────────────
  List<String> verses   = [];
  bool         isLoading = true;

  // ── 장 캐시 (이전/다음 장 프리로드용) ────────────────────
  final Map<int, List<String>> _chapterCache = {};

  // ── 폰트 ───────────────────────────────────────────────────
  double _fontSize = 20.0;

  // ── 절 탭 on/off ──────────────────────────────────────────
  bool _verseTapEnabled = true;

  // ── 북마크/형광펜/메모 ────────────────────────────────────
  Map<int, Bookmark>  _bookmarksByVerse  = {};
  Map<int, Highlight> _highlightsByVerse = {};
  Set<int>            _memoVerseNumbers  = {};

  // ── 절 선택 (다중 토글) ───────────────────────────────────
  // 각 절 탭 = 그 절만 토글. 이미 선택이면 해제, 아니면 추가.
  // 연속/비연속 상관없이 자유 누적 선택.
  // 빈 곳 탭 또는 '전체 해제' 버튼 = 모두 해제.
  Set<int> _selectedVerses = {};
  late AnimationController _barController;
  late Animation<Offset>   _barSlide;

  bool get _hasSelection => _selectedVerses.isNotEmpty;

  // ── 스크롤 & 절 추적 ────────────────────────────────────────
  final ScrollController    _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys        = {};
  final GlobalKey           _highlightKey     = GlobalKey();


  // ── 클래식 모드 ────────────────────────────────────────────────
  bool _classicMode = false;

  // ── 하이라이트 절 만료 여부 ──────────────────────────────────
  bool _highlightExpired = false;

  // ── 하단 바 숨김/표시 ────────────────────────────────────────
  bool     _bottomBarVisible = true;
  DateTime _lastScrollTime   = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapter;
    _pageController = PageController(initialPage: _currentChapter - 1);

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _barSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _barController, curve: Curves.easeOut));

    _loadPrefs();
    _loadBibleText(_currentChapter);
    _loadChapterData(_currentChapter);
    _saveLastRead();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _barController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── 설정 로드/저장 ─────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize        = prefs.getDouble('font_size')        ?? 20.0;
      _classicMode     = prefs.getBool('classic_mode')       ?? false;
      _verseTapEnabled = prefs.getBool('verse_tap_enabled')  ?? true;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size',         _fontSize);
    await prefs.setBool  ('classic_mode',      _classicMode);
    await prefs.setBool  ('verse_tap_enabled', _verseTapEnabled);
  }

  Future<void> _saveLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_version',   widget.version);
    await prefs.setString('last_book_key',  widget.bookKey);
    await prefs.setString('last_book_name', widget.bookName);
    await prefs.setInt   ('last_chapter',   _currentChapter);
    // 연구소 탭이 사용하는 last_read_* 키도 함께 갱신
    await prefs.setString('last_read_book',    widget.bookKey);
    await prefs.setInt   ('last_read_chapter', _currentChapter);
  }

  Future<void> _saveLastVerse(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_verse', v);
  }

  // ── 데이터 로드 ────────────────────────────────────────────
  void _loadChapterData(int chapter) {
    setState(() {
      _bookmarksByVerse  = BookmarkService.getByChapter(widget.bookKey, chapter);
      _highlightsByVerse = HighlightService.getByChapter(widget.bookKey, chapter);
      _memoVerseNumbers  = MemoService.getVerseNumbersWithMemos(widget.bookKey, chapter);
    });
  }

  Future<List<String>> _fetchChapter(int chapter) async {
    final cached = _chapterCache[chapter];
    if (cached != null) return cached;
    final path = 'assets/bible/${widget.version}/${widget.bookKey}/$chapter.json';
    final raw  = await rootBundle.loadString(path);
    final data = json.decode(raw) as List<dynamic>;
    final list = data.map((e) => e.toString()).toList();
    _chapterCache[chapter] = list;
    // 현재 장에서 ±2 범위 밖은 메모리 정리
    _chapterCache.removeWhere((k, _) => (k - _currentChapter).abs() > 2);
    return list;
  }

  void _preloadNeighbors(int chapter) {
    for (final n in [chapter - 1, chapter + 1]) {
      if (n < 1 || n > widget.totalChapters) continue;
      if (_chapterCache.containsKey(n)) continue;
      // 실패는 조용히 무시 (선제 로드일 뿐)
      _fetchChapter(n).catchError((_) => <String>[]);
    }
  }

  Future<void> _loadBibleText(int chapter) async {
    // 캐시 히트 → 즉시 표시, 스피너 없음
    final cached = _chapterCache[chapter];
    if (cached != null) {
      setState(() {
        verses = cached;
        isLoading = false;
        _verseKeys.clear();
        _highlightExpired = false;
      });
      // 첫 방문 장만 +10 EXP (중복 방지는 서비스가 처리)
      ExperienceService.markChapterRead(widget.bookKey, chapter);
      if (widget.highlightVerse != null && chapter == widget.chapter) {
        _scrollToVerse(widget.highlightVerse!);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _highlightExpired = true);
        });
      }
      _preloadNeighbors(chapter);
      return;
    }

    setState(() { isLoading = true; _verseKeys.clear(); _highlightExpired = false; });
    try {
      final list = await _fetchChapter(chapter);
      if (!mounted) return;
      setState(() {
        verses    = list;
        isLoading = false;
      });
      // 첫 방문 장만 +10 EXP — ExperienceService가 중복 방지
      ExperienceService.markChapterRead(widget.bookKey, chapter);
      if (widget.highlightVerse != null && chapter == widget.chapter) {
        _scrollToVerse(widget.highlightVerse!);
        // 1.5초 후 하이라이트 자동 소멸
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _highlightExpired = true);
        });
      }
      _preloadNeighbors(chapter);
    } catch (e) {
      if (!mounted) return;
      setState(() { verses = ['해당 장을 불러올 수 없어요.']; isLoading = false; });
    }
  }

  // ── 절 스크롤 추적 ─────────────────────────────────────────
  void _scrollToVerse(int verseNum) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        final key = _verseKeys[verseNum];
        final ctx = key?.currentContext;
        if (ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          duration:  const Duration(milliseconds: 450),
          curve:     Curves.easeOutCubic,
          alignment: 0.1,
        );
      });
    });
  }

  // ── 페이지 전환 ────────────────────────────────────────────
  void _onPageChanged(int pageIndex) {
    final newChapter = pageIndex + 1;
    final cached = _chapterCache[newChapter];
    setState(() {
      _currentChapter = newChapter;
      _selectedVerses = {};
      _verseKeys.clear();
      // 캐시 히트면 즉시 새 장 텍스트로, 아니면 잠시 빈 채로
      verses = cached ?? [];
      isLoading = cached == null;
    });
    _barController.reverse();
    _loadBibleText(newChapter);
    _loadChapterData(newChapter);
    _saveLastRead();
  }

  // ── 절 선택 (토글) ─────────────────────────────────────────
  void _selectVerse(int verseNum) {
    if (!_verseTapEnabled || verses.isEmpty) return;
    final idx = verseNum - 1;
    if (idx < 0 || idx >= verses.length) return;

    setState(() {
      if (_selectedVerses.contains(verseNum)) {
        // 이미 선택 → 그 절만 해제 (다른 선택은 유지)
        _selectedVerses = {..._selectedVerses}..remove(verseNum);
      } else {
        // 새 절 → 선택 추가 (누적)
        _selectedVerses = {..._selectedVerses, verseNum};
      }
    });

    if (_hasSelection) {
      _barController.forward();
      HapticFeedback.selectionClick();
      _scrollToVerse(verseNum);
      _saveLastVerse(verseNum);
    } else {
      _barController.reverse();
    }
  }

  void _clearSelection() {
    if (_selectedVerses.isEmpty) return;
    setState(() => _selectedVerses = {});
    _barController.reverse();
  }

  void _toggleVerseTap() {
    // verses가 아직 준비 안됐으면 선택 상태 접근이 위험 → 선택은 무조건 비우고,
    // 실제 rebuild는 다음 프레임으로 미뤄 PageView의 진행 중 빌드와 충돌 방지
    HapticFeedback.selectionClick();
    final nextEnabled = !_verseTapEnabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _verseTapEnabled = nextEnabled;
        _selectedVerses = {};
      });
      _barController.reverse();
      _savePrefs();
      _snack(nextEnabled ? '절 탭이 켜졌어요' : '절 탭이 꺼졌어요');
    });
  }

  // 스테일 verseNum이 섞이지 않도록 현재 verses.length 기준으로 걸러줌.
  // 장 전환 레이스에서 이전 장의 인덱스가 살아남는 상황 방어.
  Set<int> _prunedSelection() =>
      _selectedVerses.where((n) => n >= 1 && n <= verses.length).toSet();

  // ── 폰트 버튼 조절 ─────────────────────────────────────────
  void _changeFontSize(double delta) {
    setState(() { _fontSize = (_fontSize + delta).clamp(12.0, 32.0); });
    _savePrefs();
  }

  // ── 스크롤 시 하단 바 숨김 ─────────────────────────────────
  void _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (_bottomBarVisible) setState(() => _bottomBarVisible = false);
      _lastScrollTime = DateTime.now();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        if (DateTime.now().difference(_lastScrollTime).inMilliseconds >= 550) {
          setState(() => _bottomBarVisible = true);
        }
      });
    }
  }

  // ── 선택된 절들을 VerseRef 리스트로 (범위 체크 포함) ────────
  List<VerseRef> _selectedRefs() {
    final sorted = _prunedSelection().toList()..sort();
    return sorted.map(_makeVerseRef).toList();
  }

  // 선택된 절들의 공통 하이라이트 키. 전부 동일하면 그 키, 아니면 null.
  String? _computeSharedHighlight(Set<int> selection) {
    if (selection.isEmpty) return null;
    final keys =
        selection.map((n) => _highlightsByVerse[n]?.colorKey).toSet();
    return keys.length == 1 ? keys.first : null;
  }

  // ── 형광펜 (다중) ──────────────────────────────────────────
  Future<void> _applyHighlight(String colorKey) async {
    final refs = _selectedRefs();
    if (refs.isEmpty) return;
    // 모두 같은 색이면 토글로 지워지고, 아니면 일괄 적용됨
    final pruned = _prunedSelection();
    final colors =
        pruned.map((n) => _highlightsByVerse[n]?.colorKey).toSet();
    final allSame = colors.length == 1 && colors.first == colorKey;
    for (final ref in refs) {
      await HighlightService.save(ref, colorKey);
    }
    _loadChapterData(_currentChapter);
    _snack(allSame
        ? '형광펜을 지웠어요'
        : '${refs.length}절에 ${HighlightColor.fromKey(colorKey).label} 형광펜');
  }

  // ── 북마크 (다중) ──────────────────────────────────────────
  Future<void> _toggleBookmark() async {
    final refs = _selectedRefs();
    if (refs.isEmpty) return;
    final allMarked =
        refs.every((r) => _bookmarksByVerse.containsKey(r.verse));
    if (allMarked) {
      for (final ref in refs) {
        await BookmarkService.toggle(ref);
      }
      _snack('${refs.length}절 북마크 해제');
    } else {
      for (final ref in refs) {
        if (!_bookmarksByVerse.containsKey(ref.verse)) {
          await BookmarkService.toggle(ref);
        }
      }
      _snack('${refs.length}절 북마크 저장 ★');
    }
    _loadChapterData(_currentChapter);
  }

  // ── 복사 (다중) ────────────────────────────────────────────
  void _copyVerse() {
    final pruned = _prunedSelection();
    if (pruned.isEmpty) return;
    final sorted = pruned.toList()..sort();
    final lines = <String>[];
    for (final n in sorted) {
      final idx = n - 1;
      if (idx < 0 || idx >= verses.length) continue;
      lines.add('$n ${verses[idx]}');
    }
    if (lines.isEmpty) return;
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    _snack('${lines.length}절 복사됐어요');
  }

  // ── 주석 시트 ──────────────────────────────────────────────
  void _openCommentary() {
    final focusVerse = _prunedSelection().isEmpty
        ? null
        : (_prunedSelection().toList()..sort()).first;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CommentarySheet(
        bookKey: widget.bookKey,
        chapter: _currentChapter,
        highlightVerse: focusVerse,
      ),
    );
  }

  // ── 교차 참조 시트 ─────────────────────────────────────────
  void _openCrossReference() {
    final pruned = _prunedSelection();
    if (pruned.isEmpty) return;
    final sorted = pruned.toList()..sort();
    final verse = sorted.first;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CrossReferenceSheet(
        version: widget.version,
        bookKey: widget.bookKey,
        chapter: _currentChapter,
        verse: verse,
        onSelect: (CrossRef r) {
          Navigator.pop(context);
          _clearSelection();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BibleReadPage(
                version: widget.version,
                bookKey: r.bookKey,
                bookName: BibleBookNames.get(r.bookKey, AppLocale.current),
                chapter: r.chapter,
                totalChapters: BookSelectPage.getChapterCount(r.bookKey),
                highlightVerse: r.verse,
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 메모 (다중) ────────────────────────────────────────────
  void _goToMemo() {
    final refs = _selectedRefs();
    if (refs.isEmpty) return;
    _clearSelection();
    _showMemoSelector(refs);
  }

  void _showMemoSelector(List<VerseRef> verseRefs) {
    final memos  = MemoService.getAll();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MemoSelectorSheet(
        verseRefs:    verseRefs,
        memos:        memos,
        isDark:       isDark,
        primaryColor: Theme.of(context).colorScheme.primary,
        onNewMemo: () {
          Navigator.pop(context);
          Navigator.push(context,
            MaterialPageRoute(
              builder: (_) => MemoDetailPage(initialVerses: verseRefs),
            ),
          ).then((_) => _loadChapterData(_currentChapter));
        },
        onExistingMemo: (memo) async {
          Navigator.pop(context);
          int added = 0;
          for (final vr in verseRefs) {
            if (await MemoService.addVerse(memo.id, vr)) added++;
          }
          _loadChapterData(_currentChapter);
          _snack(added > 0
              ? '"${memo.previewTitle}"에 $added절 추가'
              : '이미 추가된 구절이에요');
        },
      ),
    );
  }

  // ── 성경 전체 Bottom Sheet ───────────────────────────────────
  void _showBiblePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BiblePickerSheet(
        version: widget.version,
        onSelect: (bookKey, bookName, chapter, {int? verse}) {
          Navigator.pop(context); // Bottom Sheet 닫기
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BibleReadPage(
                version:       widget.version,
                bookKey:       bookKey,
                bookName:      bookName,
                chapter:       chapter,
                totalChapters: BookSelectPage.getChapterCount(bookKey),
                highlightVerse: verse,
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 헬퍼 ───────────────────────────────────────────────────
  // verses 범위를 방어해서 장 이동 중 out-of-range로 빨간 화면 뜨는 것 방지
  VerseRef _makeVerseRef(int verseNum) {
    final idx = verseNum - 1;
    final text = (idx >= 0 && idx < verses.length) ? verses[idx] : '';
    return VerseRef(
      version:   widget.version,
      bookKey:   widget.bookKey,
      bookName:  widget.bookName,
      chapter:   _currentChapter,
      verse:     verseNum,
      verseText: text,
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final bgColor   = isDark ? const Color(0xFF1A2535) : const Color(0xFFFFF8F0);
    final primary   = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('${BibleBookNames.get(widget.bookKey, AppLocale.current)} ${AppLocale.s.chapter(_currentChapter)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // ── 절 탭 on/off (고정 위치: 첫 번째) ──
          IconButton(
            icon: Icon(
              _verseTapEnabled
                  ? Icons.touch_app_rounded
                  : Icons.do_not_touch_rounded,
              size: 20,
              color: _verseTapEnabled
                  ? primary
                  : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
            ),
            tooltip: _verseTapEnabled ? '절 탭 끄기' : '절 탭 켜기',
            onPressed: _toggleVerseTap,
          ),
          // 폰트 축소 / 확대
          IconButton(
            icon: const Icon(Icons.text_decrease, size: 20),
            tooltip: '글자 작게',
            onPressed: () => _changeFontSize(-2),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase, size: 20),
            tooltip: '글자 크게',
            onPressed: () => _changeFontSize(2),
          ),
          // 클래식 모드 토글 (독립 버튼)
          IconButton(
            icon: Icon(
              _classicMode
                  ? Icons.format_list_numbered_rounded
                  : Icons.menu_book_rounded,
              size: 20,
              color: _classicMode
                  ? primary
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            tooltip: _classicMode ? '일반 모드로' : '클래식 모드로',
            onPressed: () {
              setState(() => _classicMode = !_classicMode);
              _savePrefs();
            },
          ),
          // 주석 (독립 버튼)
          IconButton(
            icon: Icon(Icons.comment_rounded,
                size: 20,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            tooltip: '주석',
            onPressed: _openCommentary,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // ── PageView + 스크롤 감지 ────────────────────────
          NotificationListener<ScrollNotification>(
            onNotification: (n) { _onScrollNotification(n); return false; },
            child: PageView.builder(
              controller:    _pageController,
              onPageChanged: _onPageChanged,
              itemCount:     widget.totalChapters,
              physics:       const PageScrollPhysics(),
              itemBuilder: (_, pageIndex) {
                final isCurrent = pageIndex + 1 == _currentChapter;
                // verses 비었거나 로딩 중이면 스피너만 (빈 리스트 접근 방지)
                final showLoading = isCurrent && (isLoading || verses.isEmpty);
                return GestureDetector(
                  onTap: _clearSelection,
                  behavior: HitTestBehavior.opaque,
                  child: showLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildVerseList(isDark, textColor, primary),
                );
              },
            ),
          ),

          // ── 절 선택 액션바 ────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SlideTransition(
              position: _barSlide,
              child: () {
                final pruned = _prunedSelection();
                if (pruned.isEmpty || verses.isEmpty) return const SizedBox();
                final sortedNums = pruned.toList()..sort();
                final refs = sortedNums.map(_makeVerseRef).toList();
                return _VerseActionBar(
                  verseRefs: refs,
                  isDark: isDark,
                  allBookmarked: pruned.every(_bookmarksByVerse.containsKey),
                  sharedHighlightKey: _computeSharedHighlight(pruned),
                  anyMemo: pruned.any(_memoVerseNumbers.contains),
                  onClose: _clearSelection,
                  onHighlight: _applyHighlight,
                  onBookmark: _toggleBookmark,
                  onCopy: _copyVerse,
                  onMemo: _goToMemo,
                  onCrossRef: _openCrossReference,
                );
              }(),
            ),
          ),

          // ── 하단 고정 버튼 (스크롤 시 숨김) ─────────────
          if (_prunedSelection().isEmpty)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: AnimatedSlide(
                offset:   _bottomBarVisible ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 250),
                curve:    Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity:  _bottomBarVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: _FixedBottomBar(
                    isDark:   isDark,
                    primary:  primary,
                    onDictionary:  () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DictionaryPage())),
                    onSearch: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage())),
                    onNextChapter: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut),
                    onBibleList:   () => _showBiblePicker(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 절 목록 렌더링 ──────────────────────────────────────────
  Widget _buildVerseList(bool isDark, Color textColor, Color primary) {
    if (_classicMode) return _buildClassicView(isDark, textColor, primary);
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(verses.length, (index) {
          final verseNum    = index + 1;
          final isSelected  = _selectedVerses.contains(verseNum);
          final isBookmarked = _bookmarksByVerse.containsKey(verseNum);
          final highlight   = _highlightsByVerse[verseNum];
          final hasMemo     = _memoVerseNumbers.contains(verseNum);
          final isTarget    = !_highlightExpired &&
                              widget.highlightVerse == verseNum &&
                              widget.chapter == _currentChapter;

          final key = _verseKeys.putIfAbsent(verseNum, () => GlobalKey());

          // 보물 컨셉: 북마크는 테마와 무관하게 골드로 통일
          const treasureGold = Color(0xFFC9A84C);
          Color? bg;
          if (isSelected)        bg = primary.withOpacity(isDark ? 0.2 : 0.1);
          else if (highlight != null) {
            final base = highlight.highlightColor.color;
            bg = isDark ? base.withOpacity(0.35) : base.withOpacity(0.65);
          } else if (isBookmarked) {
            bg = isDark
                ? treasureGold.withOpacity(0.18)
                : treasureGold.withOpacity(0.10);
          } else if (isTarget) {
            bg = primary.withOpacity(isDark ? 0.15 : 0.08);
          }

          Color? borderColor;
          if (isSelected)        borderColor = primary;
          else if (isBookmarked) borderColor = treasureGold;
          else if (hasMemo)      borderColor = primary.withOpacity(0.5);
          else if (isTarget)     borderColor = primary.withOpacity(0.4);

          Color numColor = Colors.grey.shade500;
          if (isSelected || hasMemo || isTarget) numColor = primary;
          else if (isBookmarked) numColor = treasureGold;

          return KeyedSubtree(
            key: key,
            child: GestureDetector(
              key: isTarget ? _highlightKey : null,
              onTap: () => _selectVerse(verseNum),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: borderColor != null
                      ? Border(left: BorderSide(color: borderColor, width: 3))
                      : null,
                ),
                padding: EdgeInsets.only(
                  left: borderColor != null ? 10 : 0,
                  right: 8, top: 10, bottom: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: '$verseNum  ',
                            style: TextStyle(
                              fontSize: _fontSize * 0.7,
                              color: numColor,
                              height: 1.9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: verses[index],
                            style: TextStyle(
                              fontSize: _fontSize,
                              height: 1.9,
                              color: textColor,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    if (hasMemo && !isSelected)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Icon(Icons.edit_note_rounded,
                            size: 16, color: primary.withOpacity(0.6)),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── 클래식 모드 뷰 (책처럼 읽기) ────────────────────────────
extension _ClassicView on _BibleReadPageState {
  Widget _buildClassicView(bool isDark, Color textColor, Color primary) {
    final bg = isDark ? const Color(0xFF1A2535) : const Color(0xFFFFF8F0);

    // 제목 줄 (장 번호)
    final chapterTitle = '${widget.chapter}장';

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 장 제목
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              chapterTitle,
              style: TextStyle(
                fontSize: _fontSize * 1.1,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ),
          // 본문: 절번호 인라인, 연속 텍스트
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: _fontSize,
                height: 2.0,
                color: textColor,
              ),
              children: List.generate(verses.length, (i) {
                final verseNum = i + 1;
                return TextSpan(children: [
                  // 절 번호 (위첨자 스타일)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Text(
                        '$verseNum ',
                        style: TextStyle(
                          fontSize: _fontSize * 0.6,
                          color: primary.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  // 절 본문
                  TextSpan(text: '${verses[i]} '),
                ]);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 하단 고정 버튼 바 ─────────────────────────────────────────
class _FixedBottomBar extends StatelessWidget {
  final bool         isDark;
  final Color        primary;
  final VoidCallback onDictionary;
  final VoidCallback onSearch;
  final VoidCallback onNextChapter;
  final VoidCallback onBibleList;

  const _FixedBottomBar({
    required this.isDark,
    required this.primary,
    required this.onDictionary,
    required this.onSearch,
    required this.onNextChapter,
    required this.onBibleList,
  });

  @override
  Widget build(BuildContext context) {
    final bg  = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final sub = const Color(0xFF8E8E93);
    final div = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: div, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              _FBtn(icon: Icons.chrome_reader_mode_rounded, label: AppLocale.s.dictionary,   color: sub, onTap: onDictionary),
              _FBtn(icon: Icons.search_rounded,             label: AppLocale.s.search,   color: sub, onTap: onSearch),
              // 중앙 다음 장 강조
              Expanded(
                child: GestureDetector(
                  onTap: onNextChapter,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.skip_next_rounded, color: primary, size: 26),
                      Text('다음 장',
                          style: TextStyle(
                              fontSize: 10,
                              color: primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              _FBtn(icon: Icons.auto_stories_rounded, label: '성경 전체', color: sub, onTap: onBibleList),
            ],
          ),
        ),
      ),
    );
  }
}

class _FBtn extends StatelessWidget {
  final IconData icon; final String label;
  final Color color;   final VoidCallback onTap;
  const _FBtn({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
        ),
      );
}

// 형광펜 색상에 의미 라벨을 매핑 — 단순 색이름이 아닌 '용도'로 인식하도록
const Map<String, String> _hlMeaning = {
  'yellow': '핵심',
  'green':  '적용',
  'blue':   '질문',
  'pink':   '감동',
  'orange': '기도',
};

// ── 절 액션바 (다중 선택 지원) ────────────────────────────────
class _VerseActionBar extends StatelessWidget {
  final List<VerseRef> verseRefs;
  final bool           isDark;
  final bool           allBookmarked;
  final String?        sharedHighlightKey; // 모두 동일 색이면 그 키, 아니면 null
  final bool           anyMemo;
  final VoidCallback         onClose;
  final ValueChanged<String> onHighlight;
  final VoidCallback         onBookmark;
  final VoidCallback         onCopy;
  final VoidCallback         onMemo;
  final VoidCallback         onCrossRef;

  const _VerseActionBar({
    required this.verseRefs, required this.isDark,
    required this.allBookmarked, required this.sharedHighlightKey,
    required this.anyMemo, required this.onClose,
    required this.onHighlight, required this.onBookmark,
    required this.onCopy, required this.onMemo,
    required this.onCrossRef,
  });

  // 범위 라벨: 단일 "창세기 1:3", 다중 "창세기 1:3-7"
  String get _rangeLabel {
    if (verseRefs.isEmpty) return '';
    final first = verseRefs.first;
    if (verseRefs.length == 1) return first.label;
    final last = verseRefs.last;
    return '${first.bookName} ${first.chapter}:${first.verse}-${last.verse}';
  }

  @override
  Widget build(BuildContext context) {
    final bg      = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final text    = isDark ? Colors.white : Colors.black;
    final sub     = const Color(0xFF8E8E93);
    final div     = isDark ? const Color(0xFF38383A) : const Color(0xFFE8E8E8);
    final primary = Theme.of(context).colorScheme.primary;
    final count   = verseRefs.length;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withOpacity(0.12),
            blurRadius: 16, offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: sub.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_rangeLabel,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('$count절 선택됨',
                            style: TextStyle(fontSize: 11, color: primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TopBtn(
                    icon: Icons.hub_rounded,
                    label: '참조',
                    isDark: isDark,
                    onTap: onCrossRef,
                    disabled: count != 1,
                    disabledTooltip:
                        '한 절만 선택하면 교차참조를 볼 수 있어요',
                  ),
                  const SizedBox(width: 6),
                  _TopBtn(icon: Icons.copy_rounded, label: '복사',
                      isDark: isDark, onTap: onCopy),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, size: 16, color: sub),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: div),
            const SizedBox(height: 12),
            // ── 형광펜 섹션 (말씀 표시하기) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.format_color_fill_rounded, size: 13, color: primary),
                  const SizedBox(width: 6),
                  Text('말씀 표시',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: text.withOpacity(0.8),
                          letterSpacing: 0.2)),
                  const SizedBox(width: 8),
                  if (sharedHighlightKey != null)
                    Expanded(
                      child: Text(
                        _hlMeaning[sharedHighlightKey!] ?? '',
                        style: TextStyle(
                            fontSize: 11,
                            color: primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  // 지우기 버튼 (현재 표시를 제거)
                  GestureDetector(
                    onTap: sharedHighlightKey != null
                        ? () => onHighlight(sharedHighlightKey!)
                        : null,
                    child: Container(
                      width: 40, height: 40,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sharedHighlightKey != null
                              ? sub.withOpacity(0.5)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Icon(Icons.format_color_reset_rounded,
                          size: 18,
                          color: sharedHighlightKey != null
                              ? sub
                              : sub.withOpacity(0.3)),
                    ),
                  ),
                  // 색 + 용도 라벨
                  ...HighlightColor.values.map((hc) {
                    final sel = sharedHighlightKey == hc.key;
                    final meaning = _hlMeaning[hc.key] ?? '';
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onHighlight(hc.key),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: sel ? 34 : 28,
                              height: sel ? 34 : 28,
                              decoration: BoxDecoration(
                                color: hc.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: sel ? primary : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                            color: hc.color.withOpacity(0.55),
                                            blurRadius: 8),
                                      ]
                                    : null,
                              ),
                              child: sel
                                  ? const Icon(Icons.check_rounded,
                                      size: 14, color: Colors.black54)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(meaning,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: sel ? primary : sub,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: div),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _ActionBtn(
                    icon: Icons.edit_note_rounded,
                    label: anyMemo ? '노트 수정' : '노트',
                    isDark: isDark, isActive: anyMemo, onTap: onMemo,
                  ),
                  const SizedBox(width: 10),
                  // 북마크 = 보물 표시. 라이트·다크 모두 골드로 통일
                  _ActionBtn(
                    icon: allBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    label: allBookmarked ? '보물 해제' : '보물 표시',
                    isDark: isDark,
                    isActive: allBookmarked,
                    activeColor: const Color(0xFFC9A84C),
                    onTap: onBookmark,
                  ),
                  const SizedBox(width: 10),
                  _ActionBtn(
                    icon: Icons.deselect_rounded,
                    label: '전체 해제',
                    isDark: isDark, isActive: false,
                    onTap: onClose,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── 메모 선택 시트 ────────────────────────────────────────────
class _MemoSelectorSheet extends StatelessWidget {
  final List<VerseRef> verseRefs;
  final List<Memo>     memos;
  final bool           isDark;
  final Color          primaryColor;
  final VoidCallback   onNewMemo;
  final ValueChanged<Memo> onExistingMemo;

  const _MemoSelectorSheet({
    required this.verseRefs, required this.memos,
    required this.isDark, required this.primaryColor,
    required this.onNewMemo, required this.onExistingMemo,
  });

  String get _headerLabel {
    if (verseRefs.isEmpty) return '';
    final first = verseRefs.first;
    if (verseRefs.length == 1) return first.label;
    final last = verseRefs.last;
    return '${first.bookName} ${first.chapter}:${first.verse}-${last.verse} · ${verseRefs.length}절';
  }

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final text   = isDark ? Colors.white : Colors.black;
    final sub    = const Color(0xFF8E8E93);
    final div    = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    final cardBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: sub, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Text('노트에 추가',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text)),
            const SizedBox(height: 3),
            Text(_headerLabel, style: TextStyle(fontSize: 13, color: sub)),
            const SizedBox(height: 12),
            Divider(height: 1, color: div),
            _SelectorItem(icon: Icons.add_circle_outline_rounded,
                label: '새 노트 작성', color: primaryColor, onTap: onNewMemo),
            if (memos.isNotEmpty) ...[
              Divider(height: 1, color: div),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('기존 노트에 추가', style: TextStyle(fontSize: 12, color: sub)),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: memos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final memo = memos[i];
                    return GestureDetector(
                      onTap: () => onExistingMemo(memo),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: cardBg, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(memo.previewTitle,
                                      style: TextStyle(fontSize: 14,
                                          fontWeight: FontWeight.w600, color: text),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (memo.versesLabel.isNotEmpty)
                                    Text(memo.versesLabel,
                                        style: TextStyle(fontSize: 12, color: sub)),
                                ],
                              ),
                            ),
                            Icon(Icons.add_rounded, color: primaryColor, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('아직 작성된 노트가 없어요\n새 노트로 시작해보세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: sub, height: 1.6)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 작은 위젯들 ───────────────────────────────────────────────
class _TopBtn extends StatelessWidget {
  final IconData icon; final String label;
  final bool isDark;   final VoidCallback onTap;
  final bool disabled;
  final String? disabledTooltip;
  const _TopBtn({
    required this.icon, required this.label,
    required this.isDark, required this.onTap,
    this.disabled = false,
    this.disabledTooltip,
  });
  @override
  Widget build(BuildContext context) {
    final base = const Color(0xFF8E8E93);
    final color = disabled ? base.withOpacity(0.35) : base;
    final bgBase = isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade100;
    final bg = disabled ? bgBase.withOpacity(0.5) : bgBase;

    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ]),
    );

    if (disabled) {
      final tip = disabledTooltip;
      final wrapped = GestureDetector(
        onTap: tip == null ? null : () {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tip),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
        },
        child: body,
      );
      return tip == null ? wrapped : Tooltip(message: tip, child: wrapped);
    }
    return GestureDetector(onTap: onTap, child: body);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final String label;
  final bool isDark;   final bool isActive;
  final Color? activeColor; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label,
      required this.isDark, required this.isActive,
      this.activeColor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final color   = isActive ? (activeColor ?? primary) : const Color(0xFF8E8E93);
    final bg      = isActive
        ? (activeColor ?? primary).withOpacity(0.1)
        : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    );
  }
}

class _SelectorItem extends StatelessWidget {
  final IconData icon; final String label;
  final Color color;   final VoidCallback onTap;
  const _SelectorItem({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Text(label, style: TextStyle(color: color, fontSize: 16)),
      ]),
    ),
  );
}

// ── 성경 선택 Bottom Sheet (읽기 화면 내부용) ─────────────────
class _BiblePickerSheet extends StatefulWidget {
  final String version;
  final void Function(String bookKey, String bookName, int chapter, {int? verse}) onSelect;

  const _BiblePickerSheet({
    required this.version,
    required this.onSelect,
  });

  @override
  State<_BiblePickerSheet> createState() => _BiblePickerSheetState();
}

class _BiblePickerSheetState extends State<_BiblePickerSheet>
    with SingleTickerProviderStateMixin {

  late TabController _tab;
  Map<String, dynamic>? _selectedBook;
  int? _selectedChapter;
  int  _verseCount   = 0;
  bool _showVerseTab = true;

  @override
  void initState() {
    super.initState();
    _initTab();
  }

  void _initTab({int initialIndex = 0}) {
    final len = _showVerseTab ? 3 : 2;
    _tab = TabController(
        length: len, vsync: this,
        initialIndex: initialIndex.clamp(0, len - 1));
    _tab.addListener(() {
      if (!_tab.indexIsChanging) return;
      final idx = _tab.index;
      if (idx == 1 && _selectedBook == null) _tab.animateTo(0);
      if (_showVerseTab && idx == 2 && _selectedChapter == null) {
        _tab.animateTo(_selectedBook == null ? 0 : 1);
      }
    });
  }

  void _toggleVerseTab() {
    final cur = _tab.index;
    final old = _tab;
    setState(() => _showVerseTab = !_showVerseTab);
    _initTab(initialIndex: cur.clamp(0, _showVerseTab ? 2 : 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _selectBook(Map<String, dynamic> book) {
    setState(() { _selectedBook = book; _selectedChapter = null; _verseCount = 0; });
    _tab.animateTo(1);
  }

  Future<void> _selectChapter(int chapter) async {
    setState(() => _selectedChapter = chapter);
    try {
      final path = 'assets/bible/${widget.version}/${_selectedBook!['key']}/$chapter.json';
      final raw  = await rootBundle.loadString(path);
      final list = json.decode(raw) as List;
      setState(() => _verseCount = list.length);
      if (_showVerseTab) _tab.animateTo(2);
      else widget.onSelect(_selectedBook!['key'], _selectedBook!['name'], chapter);
    } catch (_) {
      widget.onSelect(_selectedBook!['key'], _selectedBook!['name'], chapter);
    }
  }

  void _selectVerse(int verse) {
    widget.onSelect(
      _selectedBook!['key'], _selectedBook!['name'], _selectedChapter!, verse: verse);
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF1A2535) : const Color(0xFFFFF8F0);
    final primary = Theme.of(context).colorScheme.primary;
    final sub     = const Color(0xFF8E8E93);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize:     0.95,
      minChildSize:     0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: sub.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 4),

            // 탭바 + 절 탭 토글
            Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tab,
                    indicatorColor: primary,
                    labelColor: primary,
                    unselectedLabelColor: sub,
                    tabs: [
                      const Tab(text: '권'),
                      Tab(child: Text('장', style: TextStyle(
                          color: _selectedBook != null ? primary : sub))),
                      if (_showVerseTab)
                        Tab(child: Text('절', style: TextStyle(
                            color: _selectedChapter != null ? primary : sub))),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleVerseTab,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: _showVerseTab ? primary.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.format_list_numbered_rounded,
                            size: 14, color: _showVerseTab ? primary : sub),
                        const SizedBox(width: 3),
                        Text('절', style: TextStyle(
                            fontSize: 11,
                            color: _showVerseTab ? primary : sub,
                            fontWeight: _showVerseTab ? FontWeight.w600 : FontWeight.normal)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tab,
                physics: const ClampingScrollPhysics(),
                children: [
                  // 권
                  _BibleBookGrid(
                    isDark: isDark,
                    selectedKey: _selectedBook?['key'],
                    onSelect: _selectBook,
                  ),
                  // 장
                  _selectedBook != null
                      ? _BibleChapterGrid(
                          isDark: isDark,
                          book: _selectedBook!,
                          selectedChapter: _selectedChapter,
                          onSelect: _selectChapter,
                        )
                      : _BibleEmptyHint(
                          icon: Icons.auto_stories_rounded,
                          message: '권 탭에서 책을 선택해주세요',
                          isDark: isDark),
                  // 절
                  if (_showVerseTab)
                    _selectedChapter != null && _verseCount > 0
                        ? _BibleVerseGrid(
                            isDark: isDark,
                            verseCount: _verseCount,
                            onSelect: _selectVerse,
                          )
                        : _BibleEmptyHint(
                            icon: Icons.format_list_numbered_rounded,
                            message: '장을 선택하면 절을 고를 수 있어요',
                            isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 그리드 위젯들 ─────────────────────────────────────────────
class _BibleBookGrid extends StatelessWidget {
  final bool isDark;
  final String? selectedKey;
  final ValueChanged<Map<String, dynamic>> onSelect;
  const _BibleBookGrid({required this.isDark, required this.selectedKey, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final sectionBg   = isDark ? const Color(0xFF1E2E42) : const Color(0xFFEEEEEE);
    final sectionText = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    return ListView(
      children: [
        _sectionHeader('구약', sectionBg, sectionText),
        _buildGrid(context, BookSelectPage.oldTestament),
        _sectionHeader('신약', sectionBg, sectionText),
        _buildGrid(context, BookSelectPage.newTestament),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _sectionHeader(String title, Color bg, Color color) => Container(
    color: bg,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
  );

  Widget _buildGrid(BuildContext context, List<Map<String, dynamic>> books) {
    final cellBg  = isDark ? const Color(0xFF1A2535) : Colors.white;
    final border  = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final primary = Theme.of(context).colorScheme.primary;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, childAspectRatio: 1.0),
      itemCount: books.length,
      itemBuilder: (_, i) {
        final book = books[i];
        final sel  = book['key'] == selectedKey;
        final abbr = book['abbr'] as String;
        return GestureDetector(
          onTap: () => onSelect(book),
          child: Container(
            decoration: BoxDecoration(
              color: sel ? primary.withOpacity(0.08) : cellBg,
              border: Border.all(color: border, width: 0.5),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(abbr, style: TextStyle(
                  fontSize: abbr.length > 2 ? 13 : 18,
                  fontWeight: FontWeight.bold,
                  color: sel ? primary : (isDark ? Colors.white : Colors.black))),
              const SizedBox(height: 2),
              Text(book['name'] as String, style: TextStyle(
                  fontSize: 9, color: sel ? primary : Colors.grey.shade500),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      },
    );
  }
}

class _BibleChapterGrid extends StatelessWidget {
  final bool isDark;
  final Map<String, dynamic> book;
  final int? selectedChapter;
  final ValueChanged<int> onSelect;
  const _BibleChapterGrid({required this.isDark, required this.book,
      required this.selectedChapter, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final chapters = book['chapters'] as int;
    final cellBg   = isDark ? const Color(0xFF1A2535) : Colors.white;
    final border   = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final primary  = Theme.of(context).colorScheme.primary;
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6, childAspectRatio: 1.0),
      itemCount: chapters,
      itemBuilder: (_, i) {
        final ch  = i + 1;
        final sel = ch == selectedChapter;
        return GestureDetector(
          onTap: () => onSelect(ch),
          child: Container(
            decoration: BoxDecoration(
              color: sel ? primary.withOpacity(0.08) : cellBg,
              border: Border.all(color: border, width: 0.5),
            ),
            child: Center(child: Text('$ch', style: TextStyle(
                fontSize: 16,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                color: sel ? primary : (isDark ? Colors.white : Colors.black)))),
          ),
        );
      },
    );
  }
}

class _BibleVerseGrid extends StatelessWidget {
  final bool isDark;
  final int verseCount;
  final ValueChanged<int> onSelect;
  const _BibleVerseGrid({required this.isDark, required this.verseCount, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cellBg  = isDark ? const Color(0xFF1A2535) : Colors.white;
    final border  = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final sub     = const Color(0xFF8E8E93);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('절을 선택하면 해당 위치로 바로 이동해요',
              style: TextStyle(fontSize: 12, color: sub)),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6, childAspectRatio: 1.0),
            itemCount: verseCount,
            itemBuilder: (_, i) {
              final v = i + 1;
              return GestureDetector(
                onTap: () => onSelect(v),
                child: Container(
                  decoration: BoxDecoration(
                    color: cellBg, border: Border.all(color: border, width: 0.5)),
                  child: Center(child: Text('$v', style: TextStyle(
                      fontSize: 15, color: isDark ? Colors.white : Colors.black))),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BibleEmptyHint extends StatelessWidget {
  final IconData icon; final String message; final bool isDark;
  const _BibleEmptyHint({required this.icon, required this.message, required this.isDark});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 56, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(message, style: TextStyle(fontSize: 14,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
    ]),
  );
}
