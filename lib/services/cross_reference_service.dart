// lib/services/cross_reference_service.dart
//
// 구절 교차참조 서비스.
// 에셋: assets/data/cross_references.json
// 포맷: {"genesis:1:1": ["exodus:20:11", ...], ...}

import 'dart:convert';
import 'package:flutter/services.dart';

class CrossRef {
  final String bookKey;
  final int chapter;
  final int verse;

  const CrossRef({
    required this.bookKey,
    required this.chapter,
    required this.verse,
  });

  /// "matthew:1:1" → CrossRef
  static CrossRef? parse(String raw) {
    final parts = raw.split(':');
    if (parts.length != 3) return null;
    final c = int.tryParse(parts[1]);
    final v = int.tryParse(parts[2]);
    if (c == null || v == null) return null;
    return CrossRef(bookKey: parts[0], chapter: c, verse: v);
  }

  String get key => '$bookKey:$chapter:$verse';
  String get label => '$bookKey $chapter:$verse';
}

class CrossReferenceService {
  static final CrossReferenceService _i = CrossReferenceService._();
  factory CrossReferenceService() => _i;
  CrossReferenceService._();

  Map<String, List<String>>? _index;
  bool _loading = false;

  Future<void> _ensureLoaded() async {
    if (_index != null) return;
    // 동시 호출 시 한 번만 로드
    while (_loading) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    if (_index != null) return;
    _loading = true;
    try {
      final raw = await rootBundle.loadString('assets/data/cross_references.json');
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      _index = {
        for (final e in obj.entries)
          e.key: (e.value as List).cast<String>(),
      };
    } catch (_) {
      _index = {};
    } finally {
      _loading = false;
    }
  }

  /// 특정 구절의 교차참조. 없으면 빈 리스트.
  Future<List<CrossRef>> getReferences(
      String bookKey, int chapter, int verse) async {
    await _ensureLoaded();
    final key = '$bookKey:$chapter:$verse';
    final raw = _index?[key] ?? const [];
    return raw.map(CrossRef.parse).whereType<CrossRef>().toList();
  }
}
