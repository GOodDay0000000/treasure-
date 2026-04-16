// lib/services/bookmark_service.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/bookmark.dart';
import '../models/verse_ref.dart';

class BookmarkService {
  static const _boxName = 'bible_bookmarks_v1';
  static late Box<String> _box;
  static const _uuid = Uuid();

  /// 앱 시작 시 한 번만 호출
  static Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    await _migrateFromSharedPreferences();
  }

  // ─── 기존 SharedPreferences 북마크 자동 마이그레이션 ───
  static Future<void> _migrateFromSharedPreferences() async {
    const doneKey = 'bookmark_migrated_v1';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(doneKey) == true) return;

    final oldList = prefs.getStringList('bookmarks') ?? [];
    for (final raw in oldList) {
      try {
        final map = Map<String, dynamic>.from(json.decode(raw));
        final ref = VerseRef(
          version: map['version'] as String? ?? 'krv',
          bookKey: (map['bookKey'] ?? map['key'] ?? '') as String,
          bookName: (map['bookName'] ?? map['name'] ?? '') as String,
          chapter: (map['chapter'] as num).toInt(),
          verse: (map['verse'] as num).toInt(),
          verseText: (map['text'] ?? map['verseText'] ?? '') as String,
        );
        if (ref.bookKey.isNotEmpty &&
            !hasBookmark(ref.bookKey, ref.chapter, ref.verse)) {
          await save(ref);
        }
      } catch (_) {}
    }
    await prefs.setBool(doneKey, true);
    // ※ SharedPreferences 'bookmarks' 키는 유지 (다른 레거시 코드 호환)
  }

  // ─── WRITE ───

  /// 북마크 저장 (이미 있으면 기존 반환)
  static Future<Bookmark> save(VerseRef verseRef) async {
    final existing =
        getByVerse(verseRef.bookKey, verseRef.chapter, verseRef.verse);
    if (existing != null) return existing;

    final bm = Bookmark(
      id: _uuid.v4(),
      verseRef: verseRef,
      createdAt: DateTime.now(),
    );
    await _box.put(bm.id, json.encode(bm.toJson()));
    return bm;
  }

  /// 북마크 삭제
  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// 북마크 토글 (있으면 삭제, 없으면 추가)
  static Future<bool> toggle(VerseRef verseRef) async {
    final existing =
        getByVerse(verseRef.bookKey, verseRef.chapter, verseRef.verse);
    if (existing != null) {
      await delete(existing.id);
      return false; // 제거됨
    } else {
      await save(verseRef);
      return true; // 추가됨
    }
  }

  // ─── READ ───

  /// 특정 절에 북마크 있는지 확인
  static bool hasBookmark(String bookKey, int chapter, int verse) =>
      getByVerse(bookKey, chapter, verse) != null;

  /// 특정 절의 북마크 조회
  static Bookmark? getByVerse(String bookKey, int chapter, int verse) {
    for (final raw in _box.values) {
      try {
        final b = Bookmark.fromJson(json.decode(raw));
        if (b.verseRef.bookKey == bookKey &&
            b.verseRef.chapter == chapter &&
            b.verseRef.verse == verse) {
          return b;
        }
      } catch (_) {}
    }
    return null;
  }

  /// 특정 장의 모든 북마크 (절번호 → Bookmark 맵)
  static Map<int, Bookmark> getByChapter(String bookKey, int chapter) {
    final result = <int, Bookmark>{};
    for (final raw in _box.values) {
      try {
        final b = Bookmark.fromJson(json.decode(raw));
        if (b.verseRef.bookKey == bookKey &&
            b.verseRef.chapter == chapter) {
          result[b.verseRef.verse] = b;
        }
      } catch (_) {}
    }
    return result;
  }

  /// 전체 북마크 (최신순)
  static List<Bookmark> getAll() {
    final result = <Bookmark>[];
    for (final raw in _box.values) {
      try {
        result.add(Bookmark.fromJson(json.decode(raw)));
      } catch (_) {}
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  static int get count => _box.length;
}
