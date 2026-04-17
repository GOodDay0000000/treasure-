// lib/services/book_info_service.dart
//
// 66권 메타정보 (저자/연대/주제/핵심구절/요약/태그).
// 에셋: assets/data/book_info.json

import 'dart:convert';
import 'package:flutter/services.dart';

class BookInfo {
  final String key;        // 'genesis' 등
  final String author;
  final String period;
  final String writtenAt;
  final String theme;
  final List<String> keyVerses; // ['1:1', '12:1-3']
  final String summary;
  final int chapters;
  final String testament;  // 'old' | 'new'
  final String region;     // MapRegion.id
  final String originalLang;
  final List<String> tags;

  const BookInfo({
    required this.key,
    required this.author,
    required this.period,
    required this.writtenAt,
    required this.theme,
    required this.keyVerses,
    required this.summary,
    required this.chapters,
    required this.testament,
    required this.region,
    required this.originalLang,
    required this.tags,
  });

  factory BookInfo.fromJson(String key, Map<String, dynamic> m) => BookInfo(
        key: key,
        author: m['author'] as String? ?? '',
        period: m['period'] as String? ?? '',
        writtenAt: m['writtenAt'] as String? ?? '',
        theme: m['theme'] as String? ?? '',
        keyVerses:
            (m['keyVerses'] as List?)?.cast<String>() ?? const <String>[],
        summary: m['summary'] as String? ?? '',
        chapters: m['chapters'] as int? ?? 0,
        testament: m['testament'] as String? ?? '',
        region: m['region'] as String? ?? '',
        originalLang: m['originalLang'] as String? ?? '',
        tags: (m['tags'] as List?)?.cast<String>() ?? const <String>[],
      );
}

class BookInfoService {
  static final BookInfoService _i = BookInfoService._();
  factory BookInfoService() => _i;
  BookInfoService._();

  Map<String, BookInfo>? _cache;

  Future<Map<String, BookInfo>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/book_info.json');
    final obj = jsonDecode(raw) as Map<String, dynamic>;
    _cache = {
      for (final e in obj.entries)
        e.key: BookInfo.fromJson(e.key, e.value as Map<String, dynamic>),
    };
    return _cache!;
  }

  Future<BookInfo?> get(String bookKey) async {
    final all = await loadAll();
    return all[bookKey];
  }
}
