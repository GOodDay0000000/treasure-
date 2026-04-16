// lib/pages/book_select_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_strings.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bible_read_page.dart';
import 'search_page.dart';
import 'memo_list_page.dart';
import 'my_page.dart';
import 'dictionary_page.dart';
import 'bookmark_page.dart';
import 'highlight_list_page.dart';
import '../main.dart';

// ── 번역본 모델 ────────────────────────────────────────────────
class BibleVersion {
  final String key;
  final String name;
  final String nameEn;
  final String desc;
  final bool   available;
  final String lang;

  const BibleVersion({
    required this.key,
    required this.name,
    required this.nameEn,
    required this.desc,
    required this.available,
    required this.lang,
  });
}

// ── BookSelectPage ─────────────────────────────────────────────
class BookSelectPage extends StatefulWidget {
  const BookSelectPage({super.key});

  static const List<BibleVersion> versions = [
    BibleVersion(key:'krv',   name:'개역개정', nameEn:'KRV',  desc:'대한성서공회 (1998)',        available:true,  lang:'ko'),
    BibleVersion(key:'korv',  name:'개역성경', nameEn:'KORV', desc:'개역한글 (1952)',            available:true,  lang:'ko'),
    BibleVersion(key:'kjv',   name:'KJV',      nameEn:'KJV',  desc:'King James Version (1769)', available:true,  lang:'en'),
    BibleVersion(key:'chiun', name:'和合本',   nameEn:'CUV',  desc:'중국어 번체 (1919)',         available:true,  lang:'zh'),
    BibleVersion(key:'chisb', name:'思高本',   nameEn:'CSB',  desc:'중국어 사고성경',            available:true,  lang:'zh'),
    BibleVersion(key:'niv',   name:'NIV',      nameEn:'NIV',  desc:'준비 중',                   available:false, lang:'en'),
    BibleVersion(key:'esv',   name:'ESV',      nameEn:'ESV',  desc:'준비 중',                   available:false, lang:'en'),
  ];

  static const List<Map<String, dynamic>> oldTestament = [
    {'key':'genesis',       'name':'창세기',       'abbr':'창',  'chapters':50},
    {'key':'exodus',        'name':'출애굽기',     'abbr':'출',  'chapters':40},
    {'key':'leviticus',     'name':'레위기',       'abbr':'레',  'chapters':27},
    {'key':'numbers',       'name':'민수기',       'abbr':'민',  'chapters':36},
    {'key':'deuteronomy',   'name':'신명기',       'abbr':'신',  'chapters':34},
    {'key':'joshua',        'name':'여호수아',     'abbr':'수',  'chapters':24},
    {'key':'judges',        'name':'사사기',       'abbr':'삿',  'chapters':21},
    {'key':'ruth',          'name':'룻기',         'abbr':'룻',  'chapters':4},
    {'key':'1samuel',       'name':'사무엘상',     'abbr':'삼상','chapters':31},
    {'key':'2samuel',       'name':'사무엘하',     'abbr':'삼하','chapters':24},
    {'key':'1kings',        'name':'열왕기상',     'abbr':'왕상','chapters':22},
    {'key':'2kings',        'name':'열왕기하',     'abbr':'왕하','chapters':25},
    {'key':'1chronicles',   'name':'역대상',       'abbr':'대상','chapters':29},
    {'key':'2chronicles',   'name':'역대하',       'abbr':'대하','chapters':36},
    {'key':'ezra',          'name':'에스라',       'abbr':'스',  'chapters':10},
    {'key':'nehemiah',      'name':'느헤미야',     'abbr':'느',  'chapters':13},
    {'key':'esther',        'name':'에스더',       'abbr':'에',  'chapters':10},
    {'key':'job',           'name':'욥기',         'abbr':'욥',  'chapters':42},
    {'key':'psalms',        'name':'시편',         'abbr':'시',  'chapters':150},
    {'key':'proverbs',      'name':'잠언',         'abbr':'잠',  'chapters':31},
    {'key':'ecclesiastes',  'name':'전도서',       'abbr':'전',  'chapters':12},
    {'key':'songofsolomon', 'name':'아가',         'abbr':'아',  'chapters':8},
    {'key':'isaiah',        'name':'이사야',       'abbr':'사',  'chapters':66},
    {'key':'jeremiah',      'name':'예레미야',     'abbr':'렘',  'chapters':52},
    {'key':'lamentations',  'name':'예레미야애가', 'abbr':'애',  'chapters':5},
    {'key':'ezekiel',       'name':'에스겔',       'abbr':'겔',  'chapters':48},
    {'key':'daniel',        'name':'다니엘',       'abbr':'단',  'chapters':12},
    {'key':'hosea',         'name':'호세아',       'abbr':'호',  'chapters':14},
    {'key':'joel',          'name':'요엘',         'abbr':'욜',  'chapters':3},
    {'key':'amos',          'name':'아모스',       'abbr':'암',  'chapters':9},
    {'key':'obadiah',       'name':'오바댜',       'abbr':'옵',  'chapters':1},
    {'key':'jonah',         'name':'요나',         'abbr':'욘',  'chapters':4},
    {'key':'micah',         'name':'미가',         'abbr':'미',  'chapters':7},
    {'key':'nahum',         'name':'나훔',         'abbr':'나',  'chapters':3},
    {'key':'habakkuk',      'name':'하박국',       'abbr':'합',  'chapters':3},
    {'key':'zephaniah',     'name':'스바냐',       'abbr':'습',  'chapters':3},
    {'key':'haggai',        'name':'학개',         'abbr':'학',  'chapters':2},
    {'key':'zechariah',     'name':'스가랴',       'abbr':'슥',  'chapters':14},
    {'key':'malachi',       'name':'말라기',       'abbr':'말',  'chapters':4},
  ];

  static const List<Map<String, dynamic>> newTestament = [
    {'key':'matthew',        'name':'마태복음',      'abbr':'마',  'chapters':28},
    {'key':'mark',           'name':'마가복음',      'abbr':'막',  'chapters':16},
    {'key':'luke',           'name':'누가복음',      'abbr':'눅',  'chapters':24},
    {'key':'john',           'name':'요한복음',      'abbr':'요',  'chapters':21},
    {'key':'acts',           'name':'사도행전',      'abbr':'행',  'chapters':28},
    {'key':'romans',         'name':'로마서',        'abbr':'롬',  'chapters':16},
    {'key':'1corinthians',   'name':'고린도전서',    'abbr':'고전','chapters':16},
    {'key':'2corinthians',   'name':'고린도후서',    'abbr':'고후','chapters':13},
    {'key':'galatians',      'name':'갈라디아서',    'abbr':'갈',  'chapters':6},
    {'key':'ephesians',      'name':'에베소서',      'abbr':'엡',  'chapters':6},
    {'key':'philippians',    'name':'빌립보서',      'abbr':'빌',  'chapters':4},
    {'key':'colossians',     'name':'골로새서',      'abbr':'골',  'chapters':4},
    {'key':'1thessalonians', 'name':'데살로니가전서','abbr':'살전','chapters':5},
    {'key':'2thessalonians', 'name':'데살로니가후서','abbr':'살후','chapters':3},
    {'key':'1timothy',       'name':'디모데전서',    'abbr':'딤전','chapters':6},
    {'key':'2timothy',       'name':'디모데후서',    'abbr':'딤후','chapters':4},
    {'key':'titus',          'name':'디도서',        'abbr':'딛',  'chapters':3},
    {'key':'philemon',       'name':'빌레몬서',      'abbr':'몬',  'chapters':1},
    {'key':'hebrews',        'name':'히브리서',      'abbr':'히',  'chapters':13},
    {'key':'james',          'name':'야고보서',      'abbr':'약',  'chapters':5},
    {'key':'1peter',         'name':'베드로전서',    'abbr':'벧전','chapters':5},
    {'key':'2peter',         'name':'베드로후서',    'abbr':'벧후','chapters':3},
    {'key':'1john',          'name':'요한일서',      'abbr':'요일','chapters':5},
    {'key':'2john',          'name':'요한이서',      'abbr':'요이','chapters':1},
    {'key':'3john',          'name':'요한삼서',      'abbr':'요삼','chapters':1},
    {'key':'jude',           'name':'유다서',        'abbr':'유',  'chapters':1},
    {'key':'revelation',     'name':'요한계시록',    'abbr':'계',  'chapters':22},
  ];

  static const List<Map<String, dynamic>> allBooks = [
    ...oldTestament,
    ...newTestament,
  ];

  static int getChapterCount(String bookKey) {
    final book = allBooks.firstWhere(
      (b) => b['key'] == bookKey,
      orElse: () => {'chapters': 1},
    );
    return book['chapters'] as int;
  }

  @override
  State<BookSelectPage> createState() => _BookSelectPageState();
}

// ── State ──────────────────────────────────────────────────────
class _BookSelectPageState extends State<BookSelectPage> {
  String _version     = 'krv';
  String _bookKey     = 'genesis';
  String _bookName    = '창세기';
  int    _chapter     = 1;
  String _previewText = '';
  List<String> _shortcuts = ['search', 'memo', 'bookmark', 'dictionary'];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getString('last_version') ?? 'krv';
    final version  = _version.isNotEmpty ? _version : savedVersion;
    final bookKey  = prefs.getString('last_book_key')  ?? 'genesis';
    final bookName = prefs.getString('last_book_name') ?? '창세기';
    final chapter  = prefs.getInt('last_chapter')      ?? 1;
    final shortcuts = prefs.getStringList('main_shortcuts')
        ?? ['search', 'memo', 'bookmark', 'dictionary'];

    String preview = '';
    try {
      final raw  = await rootBundle.loadString(
          'assets/bible/$version/$bookKey/$chapter.json');
      final list = json.decode(raw) as List;
      if (list.isNotEmpty) {
        preview = list[0].toString();
        if (preview.length > 40) preview = '${preview.substring(0, 40)}…';
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _version      = version;
        _bookKey      = bookKey;
        _bookName     = bookName;
        _chapter      = chapter;
        _previewText  = preview;
        _shortcuts    = shortcuts.length == 4 ? shortcuts
            : ['search', 'memo', 'bookmark', 'dictionary'];
      });
    }
  }

  Future<void> _saveShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('main_shortcuts', _shortcuts);
  }

  // ── 읽기 화면 이동 ─────────────────────────────────────────
  void _openReading({
    required String bookKey,
    required String bookName,
    required int    chapter,
    int?            verse,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BibleReadPage(
          version:        _version,
          bookKey:        bookKey,
          bookName:       bookName,
          chapter:        chapter,
          totalChapters:  BookSelectPage.getChapterCount(bookKey),
          highlightVerse: verse,
        ),
      ),
    ).then((_) => _loadPrefs());
  }

  // ── 단축 버튼 실행 ─────────────────────────────────────────
  void _runShortcut(String key) {
    switch (key) {
      case 'search':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => SearchPage()));
        break;
      case 'memo':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => MemoListPage()))
            .then((_) => _loadPrefs());
        break;
      case 'bookmark':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => BookmarkPage()));
        break;
      case 'dictionary':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => DictionaryPage()));
        break;
      case 'darkmode':
        BibleApp.of(context)?.toggleTheme();
        break;
      case 'highlight':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => HighlightListPage()));
        break;
      case 'mypage':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => MyPage()));
        break;
    }
  }

  // ── 책 선택 Bottom Sheet ───────────────────────────────────
  void _showBookPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookPickerSheet(
        version: _version,
        onSelect: (bookKey, bookName, chapter, {int? verse}) {
          Navigator.pop(context);
          _openReading(
            bookKey:  bookKey,
            bookName: bookName,
            chapter:  chapter,
            verse:    verse,
          );
        },
      ),
    );
  }

  // ── 번역본 선택 ────────────────────────────────────────────
  void _showVersionPicker() {
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
          child: SingleChildScrollView(
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
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w600, color: text)),
                const SizedBox(height: 12),
                Divider(height: 1, color: div),
                ...groups.entries.expand((entry) => [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(entry.key,
                          style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w600, color: sub)),
                    ),
                  ),
                  ...entry.value.map((v) {
                    final sel = v.key == _version;
                    return GestureDetector(
                      onTap: v.available ? () async {
                        Navigator.pop(ctx);
                        setState(() => _version = v.key);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('last_version', v.key);
                        _loadPrefs();
                      } : null,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: sel
                                        ? primary
                                        : sub.withOpacity(0.4),
                                    width: 2),
                                color: sel ? primary : Colors.transparent,
                              ),
                              child: sel
                                  ? const Icon(Icons.check_rounded,
                                      size: 12, color: Colors.white)
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
                                          fontWeight: sel
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: v.available
                                              ? (sel ? primary : text)
                                              : sub)),
                                  Text(v.desc,
                                      style: TextStyle(
                                          fontSize: 12, color: sub)),
                                ],
                              ),
                            ),
                            if (!v.available)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: sub.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('준비 중',
                                    style: TextStyle(
                                        fontSize: 11, color: sub)),
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
      ),
    );
  }

  // ── 단축 버튼 커스텀 시트 ──────────────────────────────────
  void _showShortcutCustomizer() {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bg      = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final text    = isDark ? Colors.white : Colors.black;
    final sub     = const Color(0xFF8E8E93);
    final div     = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                        color: sub.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  Text('바로가기 설정',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: text)),
                  const SizedBox(height: 6),
                  Text('원하는 기능을 4개 선택하세요',
                      style: TextStyle(fontSize: 13, color: sub)),
                  const SizedBox(height: 16),
                  // 현재 선택 미리보기
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _shortcuts.map((key) {
                        final info = _QuickActions.allShortcuts[key]
                            ?? _QuickActions.allShortcuts['search']!;
                        return Column(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(info['icon'] as IconData,
                                  color: primary, size: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(info['label'] as String,
                                style:
                                    TextStyle(fontSize: 11, color: sub)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: div),
                  // 전체 옵션
                  ..._QuickActions.allShortcuts.entries.map((entry) {
                    final isSel = _shortcuts.contains(entry.key);
                    final info  = entry.value;
                    final avail = info['available'] as bool;
                    return GestureDetector(
                      onTap: avail
                          ? () {
                              if (isSel) {
                                if (_shortcuts.length > 1) {
                                  setState(() =>
                                      _shortcuts.remove(entry.key));
                                  setModal(() {});
                                }
                              } else if (_shortcuts.length < 4) {
                                setState(() => _shortcuts.add(entry.key));
                                setModal(() {});
                              } else {
                                setState(() {
                                  _shortcuts.removeLast();
                                  _shortcuts.add(entry.key);
                                });
                                setModal(() {});
                              }
                              _saveShortcuts();
                            }
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: isSel
                                    ? primary.withOpacity(0.15)
                                    : (isDark
                                        ? const Color(0xFF3A3A3C)
                                        : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(info['icon'] as IconData,
                                  size: 20,
                                  color: isSel
                                      ? primary
                                      : (avail
                                          ? sub
                                          : sub.withOpacity(0.3))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(info['label'] as String,
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: avail
                                          ? text
                                          : sub.withOpacity(0.5))),
                            ),
                            if (isSel)
                              Icon(Icons.check_circle_rounded,
                                  color: primary, size: 22)
                            else if (avail)
                              Icon(Icons.add_circle_outline_rounded,
                                  color: sub, size: 22)
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: sub.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('준비 중',
                                    style: TextStyle(
                                        fontSize: 11, color: sub)),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 날짜 ───────────────────────────────────────────────────
  String _getDateLabel() {
    final now = DateTime.now();
    const days = ['월요일','화요일','수요일','목요일','금요일','토요일','일요일'];
    return '${days[now.weekday - 1]}, ${now.month}월 ${now.day}일';
  }

  String get _versionName => BookSelectPage.versions
      .firstWhere((v) => v.key == _version,
          orElse: () => BookSelectPage.versions.first)
      .name;

  // ── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bg      = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);
    final cardBg  = isDark ? const Color(0xFF16213E) : Colors.white;
    final text    = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub     = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.anchor_rounded,
                size: 22,
                color: primary),
            const SizedBox(width: 6),
            Text(
              'Treasure',
              style: GoogleFonts.dancingScript(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: sub, size: 24),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => SearchPage())),
          ),
          // 연구모드 토글
          // 마이페이지
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => MyPage())),
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final maxW = isTablet ? 520.0 : double.infinity;
            final hPad = isTablet ? 32.0 : 24.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: isTablet ? 24 : 12),

                        // 날짜
                        Text(_getDateLabel(),
                            style: TextStyle(fontSize: 13, color: sub)),
                        const SizedBox(height: 16),

                        // ── 메인 카드: 성경 전체 보기 ──────────
                        _BibleSelectCard(
                          isDark:       isDark,
                          cardBg:       cardBg,
                          primary:      primary,
                          sub:          sub,
                          versionName:  _versionName,
                          onTap:        _showBookPicker,
                          onVersionTap: _showVersionPicker,
                        ),
                        const SizedBox(height: 12),

                        // ── 이어읽기 (작은 행) ─────────────────
                        _ResumeRow(
                          bookName:     _bookName,
                          chapter:      _chapter,
                          cardBg:       cardBg,
                          primary:      primary,
                          sub:          sub,
                            onTap: () => _openReading(
                            bookKey:  _bookKey,
                            bookName: _bookName,
                            chapter:  _chapter,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── 단축 버튼 ──────────────────────────
                        _QuickActions(
                          isDark:      isDark,
                          primary:     primary,
                          sub:         sub,
                          shortcuts:   _shortcuts,
                          onTap:       _runShortcut,
                          onCustomize: _showShortcutCustomizer,
                        ),
                        SizedBox(height: isTablet ? 40 : 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── 성경 전체 보기 메인 카드 ──────────────────────────────────
class _BibleSelectCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg, primary, sub;
  final String versionName;
  final VoidCallback onTap, onVersionTap;

  const _BibleSelectCard({
    required this.isDark,
    required this.cardBg,
    required this.primary,
    required this.sub,
    required this.versionName,
    required this.onTap,
    required this.onVersionTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 번역본 배지
                  GestureDetector(
                    onTap: onVersionTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(versionName,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: primary,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 2),
                          Icon(Icons.expand_more_rounded,
                              size: 14, color: primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(AppLocale.s.bible,
                      style: TextStyle(
                          fontSize: 13,
                          color: sub,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(AppLocale.s.browseBible,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFE8E3D8)
                              : const Color(0xFF1A1A1A),
                          height: 1.2)),
                  const SizedBox(height: 8),
                  Text('${AppLocale.s.oldTestament} 39${AppLocale.s.navBible.length > 0 ? "권" : ""} · ${AppLocale.s.newTestament} 27${AppLocale.s.navBible.length > 0 ? "권" : ""}',
                      style: TextStyle(fontSize: 13, color: sub)),
                ],
              ),
            ),
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_stories_rounded,
                  color: primary, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 이어읽기 작은 행 ──────────────────────────────────────────
class _ResumeRow extends StatelessWidget {
  final String bookName;
  final int    chapter;
  final Color  cardBg, primary, sub;
  final VoidCallback onTap;

  const _ResumeRow({
    required this.bookName,
    required this.chapter,
    required this.cardBg,
    required this.primary,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.play_circle_rounded, color: primary, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(AppLocale.s.continueReading,
                          style: TextStyle(
                              fontSize: 12,
                              color: sub,
                              fontWeight: FontWeight.w500)),

                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('$bookName $chapter장',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: sub, size: 20),
          ],
        ),
      ),
    );
  }
}


// ── 커스텀 단축 버튼 ──────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final bool         isDark;
  final Color        primary, sub;
  final List<String> shortcuts;
  final ValueChanged<String> onTap;
  final VoidCallback onCustomize;

  const _QuickActions({
    required this.isDark,
    required this.primary,
    required this.sub,
    required this.shortcuts,
    required this.onTap,
    required this.onCustomize,
  });

  static const Map<String, Map<String, dynamic>> allShortcuts = {
    'search':     {'label': '검색',   'icon': Icons.search_rounded,             'available': true},
    'memo':       {'label': '메모',   'icon': Icons.edit_note_rounded,          'available': true},
    'bookmark':   {'label': '북마크', 'icon': Icons.bookmark_rounded,           'available': true},
    'dictionary': {'label': '사전',   'icon': Icons.chrome_reader_mode_rounded, 'available': true},
    'highlight':  {'label': '형광펜', 'icon': Icons.highlight_rounded,          'available': true},
    'mypage':     {'label': '마이',   'icon': Icons.person_rounded,             'available': true},
    'tracker':    {'label': '트래커', 'icon': Icons.track_changes_rounded,      'available': false},
    'ccm':        {'label': 'CCM',    'icon': Icons.headphones_rounded,         'available': false},
    'group':      {'label': '그룹',   'icon': Icons.groups_rounded,             'available': false},
    'sermon':     {'label': '설교',   'icon': Icons.podcasts_rounded,           'available': false},
    'darkmode':   {'label': '다크모드', 'icon': Icons.dark_mode_rounded,           'available': true},
  };

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: shortcuts.map((key) {
            final info = allShortcuts[key] ?? allShortcuts['search']!;
            return _QBtn(
              icon:        info['icon'] as IconData,
              label:       info['label'] as String,
              isDark:      isDark,
              primary:     primary,
              cardBg:      cardBg,
              onTap:       () => onTap(key),
              onLongPress: onCustomize,
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onCustomize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_rounded, size: 11,
                  color: sub.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text('길게 눌러 편집',
                  style: TextStyle(
                      fontSize: 11, color: sub.withOpacity(0.5))),
            ],
          ),
        ),
      ],
    );
  }
}

class _QBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     isDark;
  final Color    primary, cardBg;
  final VoidCallback onTap, onLongPress;

  const _QBtn({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.primary,
    required this.cardBg,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:       onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: cardBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: primary, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── 책 선택 Bottom Sheet ───────────────────────────────────────
class _BookPickerSheet extends StatefulWidget {
  final String version;
  final void Function(String, String, int, {int? verse}) onSelect;

  const _BookPickerSheet({
    required this.version,
    required this.onSelect,
  });

  @override
  State<_BookPickerSheet> createState() => _BookPickerSheetState();
}

class _BookPickerSheetState extends State<_BookPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController      _tab;
  Map<String, dynamic>?   _selectedBook;
  int?                    _selectedChapter;
  int                     _verseCount   = 0;
  bool                    _showVerseTab = true;

  @override
  void initState() {
    super.initState();
    _initTab();
  }

  void _initTab({int idx = 0}) {
    final len = _showVerseTab ? 3 : 2;
    _tab = TabController(
        length: len, vsync: this,
        initialIndex: idx.clamp(0, len - 1));
    _tab.addListener(() {
      if (!_tab.indexIsChanging) return;
      final i = _tab.index;
      if (i == 1 && _selectedBook == null)      _tab.animateTo(0);
      if (_showVerseTab && i == 2 && _selectedChapter == null) {
        _tab.animateTo(_selectedBook == null ? 0 : 1);
      }
    });
  }

  void _toggleVerseTab() {
    final cur = _tab.index;
    final old = _tab;
    setState(() => _showVerseTab = !_showVerseTab);
    _initTab(idx: cur.clamp(0, _showVerseTab ? 2 : 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _selectBook(Map<String, dynamic> book) {
    setState(() {
      _selectedBook    = book;
      _selectedChapter = null;
      _verseCount      = 0;
    });
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
      else widget.onSelect(
          _selectedBook!['key'], _selectedBook!['name'], chapter);
    } catch (_) {
      widget.onSelect(
          _selectedBook!['key'], _selectedBook!['name'], chapter);
    }
  }

  void _selectVerse(int verse) => widget.onSelect(
      _selectedBook!['key'], _selectedBook!['name'],
      _selectedChapter!, verse: verse);

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);
    final primary = Theme.of(context).colorScheme.primary;
    final sub     = const Color(0xFF8E8E93);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize:     0.95,
      minChildSize:     0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: sub.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 4),
            // 탭바 + 절 토글
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
                      Tab(child: Text('장',
                          style: TextStyle(
                              color: _selectedBook != null
                                  ? primary : sub))),
                      if (_showVerseTab)
                        Tab(child: Text('절',
                            style: TextStyle(
                                color: _selectedChapter != null
                                    ? primary : sub))),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleVerseTab,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: _showVerseTab
                          ? primary.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.format_list_numbered_rounded,
                            size: 14,
                            color: _showVerseTab ? primary : sub),
                        const SizedBox(width: 3),
                        Text('절',
                            style: TextStyle(
                                fontSize: 11,
                                color: _showVerseTab ? primary : sub,
                                fontWeight: _showVerseTab
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
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
                  _BookTabWidget(
                      isDark: isDark,
                      selectedKey: _selectedBook?['key'],
                      onSelect: _selectBook),
                  _selectedBook != null
                      ? _ChapterTabWidget(
                          isDark: isDark,
                          book: _selectedBook!,
                          selectedChapter: _selectedChapter,
                          onSelect: _selectChapter)
                      : _EmptyHintWidget(
                          icon: Icons.auto_stories_rounded,
                          message: '권 탭에서 책을 선택해주세요',
                          isDark: isDark),
                  if (_showVerseTab)
                    _selectedChapter != null && _verseCount > 0
                        ? _VerseTabWidget(
                            isDark: isDark,
                            verseCount: _verseCount,
                            onSelect: _selectVerse)
                        : _EmptyHintWidget(
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

// ── 책 그리드 ──────────────────────────────────────────────────
class _BookTabWidget extends StatelessWidget {
  final bool isDark;
  final String? selectedKey;
  final ValueChanged<Map<String, dynamic>> onSelect;
  const _BookTabWidget({required this.isDark, required this.selectedKey,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final secBg   = isDark ? const Color(0xFF16213E) : const Color(0xFFEEEEEE);
    final secText = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    return ListView(children: [
      _secHeader('구약', secBg, secText),
      _grid(context, BookSelectPage.oldTestament),
      _secHeader('신약', secBg, secText),
      _grid(context, BookSelectPage.newTestament),
      const SizedBox(height: 40),
    ]);
  }

  Widget _secHeader(String t, Color bg, Color c) => Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(t, style: TextStyle(fontSize: 13,
          fontWeight: FontWeight.w600, color: c)));

  Widget _grid(BuildContext context, List<Map<String, dynamic>> books) {
    final cellBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final primary = Theme.of(context).colorScheme.primary;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, childAspectRatio: 1.0),
      itemCount: books.length,
      itemBuilder: (_, i) {
        final b   = books[i];
        final sel = b['key'] == selectedKey;
        final abbr = b['abbr'] as String;
        return GestureDetector(
          onTap: () => onSelect(b),
          child: Container(
            decoration: BoxDecoration(
              color: sel ? primary.withOpacity(0.08) : cellBg,
              border: Border.all(color: border, width: 0.5),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(abbr, style: TextStyle(
                  fontSize: abbr.length > 2 ? 13 : 18,
                  fontWeight: FontWeight.bold,
                  color: sel ? primary
                      : (isDark ? Colors.white : Colors.black))),
              const SizedBox(height: 2),
              Text(BibleBookNames.get(b['key'] as String, AppLocale.current), style: TextStyle(
                  fontSize: 9,
                  color: sel ? primary : Colors.grey.shade500),
                  textAlign: TextAlign.center,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      },
    );
  }
}

// ── 장 그리드 ──────────────────────────────────────────────────
class _ChapterTabWidget extends StatelessWidget {
  final bool isDark;
  final Map<String, dynamic> book;
  final int? selectedChapter;
  final ValueChanged<int> onSelect;
  const _ChapterTabWidget({required this.isDark, required this.book,
      required this.selectedChapter, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final chapters = book['chapters'] as int;
    final cellBg   = isDark ? const Color(0xFF1A1A2E) : Colors.white;
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
                color: sel ? primary
                    : (isDark ? Colors.white : Colors.black)))),
          ),
        );
      },
    );
  }
}

// ── 절 그리드 ──────────────────────────────────────────────────
class _VerseTabWidget extends StatelessWidget {
  final bool isDark;
  final int verseCount;
  final ValueChanged<int> onSelect;
  const _VerseTabWidget({required this.isDark, required this.verseCount,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cellBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final sub    = const Color(0xFF8E8E93);
    return Column(children: [
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
                  color: cellBg,
                  border: Border.all(color: border, width: 0.5),
                ),
                child: Center(child: Text('$v', style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black))),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// ── 빈 힌트 ───────────────────────────────────────────────────
class _EmptyHintWidget extends StatelessWidget {
  final IconData icon;
  final String   message;
  final bool     isDark;
  const _EmptyHintWidget({required this.icon, required this.message,
      required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 56,
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(message, style: TextStyle(fontSize: 14,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
    ]),
  );
}
