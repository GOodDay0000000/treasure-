// lib/services/highlight_service.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/highlight.dart';
import '../models/verse_ref.dart';

class HighlightService {
  static const _boxName = 'bible_highlights_v1';
  static late Box<String> _box;
  static const _uuid = Uuid();

  /// 앱 시작 시 한 번만 호출
  static Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  // ─── WRITE ───

  /// 형광펜 저장 (이미 있으면 색상 업데이트)
  static Future<Highlight> save(VerseRef verseRef, String colorKey) async {
    final existing =
        getByVerse(verseRef.bookKey, verseRef.chapter, verseRef.verse);
    final now = DateTime.now();

    if (existing != null) {
      // 같은 색상이면 제거 (토글)
      if (existing.colorKey == colorKey) {
        await delete(existing.id);
        // 삭제됐음을 알리기 위해 id를 빈 문자열로 반환
        return Highlight(
          id: '',
          verseRef: verseRef,
          colorKey: colorKey,
          createdAt: now,
          updatedAt: now,
        );
      }
      // 다른 색상이면 색상 변경
      final updated = Highlight(
        id: existing.id,
        verseRef: existing.verseRef,
        colorKey: colorKey,
        createdAt: existing.createdAt,
        updatedAt: now,
      );
      await _box.put(updated.id, json.encode(updated.toJson()));
      return updated;
    }

    // 새로 추가
    final highlight = Highlight(
      id: _uuid.v4(),
      verseRef: verseRef,
      colorKey: colorKey,
      createdAt: now,
      updatedAt: now,
    );
    await _box.put(highlight.id, json.encode(highlight.toJson()));
    return highlight;
  }

  /// 형광펜 삭제
  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  // ─── READ ───

  /// 특정 절의 형광펜 조회
  static Highlight? getByVerse(String bookKey, int chapter, int verse) {
    for (final raw in _box.values) {
      try {
        final h = Highlight.fromJson(json.decode(raw));
        if (h.verseRef.bookKey == bookKey &&
            h.verseRef.chapter == chapter &&
            h.verseRef.verse == verse) {
          return h;
        }
      } catch (_) {}
    }
    return null;
  }

  /// 특정 장의 모든 형광펜 (절번호 → Highlight 맵)
  /// BibleReadPage 배경색 표시용
  static Map<int, Highlight> getByChapter(String bookKey, int chapter) {
    final result = <int, Highlight>{};
    for (final raw in _box.values) {
      try {
        final h = Highlight.fromJson(json.decode(raw));
        if (h.verseRef.bookKey == bookKey &&
            h.verseRef.chapter == chapter) {
          result[h.verseRef.verse] = h;
        }
      } catch (_) {}
    }
    return result;
  }

  /// 전체 형광펜 (최신순)
  static List<Highlight> getAll() {
    final result = <Highlight>[];
    for (final raw in _box.values) {
      try {
        result.add(Highlight.fromJson(json.decode(raw)));
      } catch (_) {}
    }
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  /// 색상별 필터
  static List<Highlight> getByColor(String colorKey) {
    return getAll().where((h) => h.colorKey == colorKey).toList();
  }

  static int get count => _box.length;
}
