// lib/services/commentary_service.dart
//
// 장별 주석 JSON을 lazy-load + 메모리 캐시.
// 에셋: assets/data/commentary/{bookKey}/{chapter}.json
// 빌드 스크립트: tools/build_commentary.py (교부 주석, Public Domain)

import 'dart:convert';
import 'package:flutter/services.dart';

class ChapterCommentary {
  final String book;
  final int chapter;
  final String source;
  // key: 절 번호 문자열 (예: "1") 또는 범위 ("1-5") → 영문 원본
  final Map<String, String> verses;
  // 동일 key → 한글 번역 (있는 entry만)
  final Map<String, String> koreanVerses;

  const ChapterCommentary({
    required this.book,
    required this.chapter,
    required this.source,
    required this.verses,
    this.koreanVerses = const {},
  });

  factory ChapterCommentary.fromJson(Map<String, dynamic> m) =>
      ChapterCommentary(
        book: m['book'] as String,
        chapter: m['chapter'] as int,
        source: m['source'] as String? ?? '',
        verses: {
          for (final e in (m['verses'] as Map<String, dynamic>).entries)
            e.key: e.value as String,
        },
        koreanVerses: {
          if (m['korean_verses'] != null)
            for (final e in (m['korean_verses'] as Map<String, dynamic>).entries)
              e.key: e.value as String,
        },
      );

  bool get hasKorean => koreanVerses.isNotEmpty;

  /// 한글 우선, 없으면 영문. 단일 절 + 범위 키 모두 검색.
  String? textForVerse(int verse) => _pickBestForVerse(verse, prefer: true);

  /// 영문만.
  String? englishForVerse(int verse) =>
      _pickBestForVerse(verse, prefer: false);

  String? _pickBestForVerse(int verse, {required bool prefer}) {
    String? fromMap(Map<String, String> m) {
      if (m.containsKey('$verse')) return m['$verse'];
      for (final e in m.entries) {
        final dash = e.key.indexOf('-');
        if (dash < 0) continue;
        final lo = int.tryParse(e.key.substring(0, dash));
        final hi = int.tryParse(e.key.substring(dash + 1));
        if (lo != null && hi != null && verse >= lo && verse <= hi) {
          return e.value;
        }
      }
      return null;
    }
    if (prefer) return fromMap(koreanVerses) ?? fromMap(verses);
    return fromMap(verses);
  }

  /// 정렬된 (라벨, 한글_or_영문) 리스트 — UI 표시용. 한글이 있는 키는 한글, 없으면 영문.
  List<MapEntry<String, String>> sortedEntries() {
    int startOf(String k) {
      final dash = k.indexOf('-');
      return int.tryParse(dash < 0 ? k : k.substring(0, dash)) ?? 0;
    }
    final merged = <String, String>{
      ...verses,
      ...koreanVerses, // 한글이 있으면 덮어쓰기
    };
    final list = merged.entries.toList()
      ..sort((a, b) => startOf(a.key).compareTo(startOf(b.key)));
    return list;
  }

  /// 특정 key가 한글 번역이 있는지.
  bool isKorean(String key) => koreanVerses.containsKey(key);
}

class CommentaryService {
  static final CommentaryService _i = CommentaryService._();
  factory CommentaryService() => _i;
  CommentaryService._();

  final Map<String, ChapterCommentary?> _cache = {};

  String _cacheKey(String bookKey, int chapter) => '$bookKey:$chapter';

  /// 장 전체 주석 로드. 없으면 null.
  Future<ChapterCommentary?> getChapter(String bookKey, int chapter) async {
    final key = _cacheKey(bookKey, chapter);
    if (_cache.containsKey(key)) return _cache[key];
    try {
      final path = 'assets/data/commentary/$bookKey/$chapter.json';
      final raw = await rootBundle.loadString(path);
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final parsed = ChapterCommentary.fromJson(obj);
      _cache[key] = parsed;
      return parsed;
    } catch (_) {
      _cache[key] = null;
      return null;
    }
  }

  /// 특정 구절 주석만 (해당 장이 없으면 null).
  Future<String?> getVerse(String bookKey, int chapter, int verse) async {
    final ch = await getChapter(bookKey, chapter);
    return ch?.textForVerse(verse);
  }
}
