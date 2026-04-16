// lib/services/memo_service.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/memo.dart';
import '../models/verse_ref.dart';

class MemoService {
  static const _boxName = 'bible_memos_v2';
  static late Box<String> _box;
  static const _uuid = Uuid();

  static Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  static Future<Memo> create({
    String title = '',
    String content = '',
    List<VerseRef>? initialVerses,
  }) async {
    final now = DateTime.now();
    final blocks = <MemoBlock>[];

    for (final ref in (initialVerses ?? [])) {
      blocks.add(MemoBlock(
        id: _uuid.v4(),
        type: MemoBlockType.verse,
        verseRef: ref,
      ));
    }

    if (content.isNotEmpty) {
      blocks.add(MemoBlock(
        id: _uuid.v4(),
        type: MemoBlockType.text,
        textContent: content,
      ));
    }

    final memo = Memo(
      id: _uuid.v4(),
      title: title,
      blocks: blocks,
      createdAt: now,
      updatedAt: now,
    );
    await _box.put(memo.id, json.encode(memo.toJson()));
    return memo;
  }

  static Future<void> save(Memo memo) async {
    await _box.put(memo.id, json.encode(memo.toJson()));
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  static Future<bool> addVerse(String memoId, VerseRef verseRef) async {
    final raw = _box.get(memoId);
    if (raw == null) return false;

    final memo = Memo.fromJson(json.decode(raw));
    final alreadyExists = memo.blocks.any((b) =>
        b.type == MemoBlockType.verse &&
        b.verseRef?.key == verseRef.key);
    if (alreadyExists) return false;

    final newBlocks = List<MemoBlock>.from(memo.blocks)
      ..add(MemoBlock(
        id: _uuid.v4(),
        type: MemoBlockType.verse,
        verseRef: verseRef,
      ));

    final updated = memo.copyWith(blocks: newBlocks, updatedAt: DateTime.now());
    await _box.put(memoId, json.encode(updated.toJson()));
    return true;
  }

  static Memo? getById(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    try {
      return Memo.fromJson(json.decode(raw));
    } catch (_) {
      return null;
    }
  }

  static List<Memo> getAll() {
    final result = <Memo>[];
    for (final raw in _box.values) {
      try {
        result.add(Memo.fromJson(json.decode(raw)));
      } catch (_) {}
    }
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  static List<Memo> search(String query) {
    if (query.trim().isEmpty) return getAll();
    final q = query.toLowerCase();
    return getAll().where((m) {
      if (m.title.toLowerCase().contains(q)) return true;
      if (m.content.toLowerCase().contains(q)) return true;
      // quillDelta plain text 검색
      if (m.quillDelta != null) {
        final plain = Memo.extractPlainText(m.quillDelta!).toLowerCase();
        if (plain.contains(q)) return true;
      }
      // 구절 검색 (null 안전)
      return m.verses.any((b) =>
          (b.verseRef?.bookName.contains(q) ?? false) ||
          (b.verseRef?.verseText.contains(q) ?? false));
    }).toList();
  }

  static Set<int> getVerseNumbersWithMemos(String bookKey, int chapter) {
    final result = <int>{};
    for (final memo in getAll()) {
      for (final block in memo.blocks) {
        if (block.type == MemoBlockType.verse &&
            block.verseRef?.bookKey == bookKey &&
            block.verseRef?.chapter == chapter) {
          result.add(block.verseRef!.verse);
        }
      }
    }
    return result;
  }

  static int get count => _box.length;
}
