// lib/services/experience_service.dart
//
// 항해자 등급·경험치 시스템
// - 경험치 지급은 sync-less가 아님에 주의: fire-and-forget 패턴으로 서비스 내부에서 호출
// - 등급: 🛶 돗단배 → ⛵ 범선 → 🚤 쾌속선 → 🛥️ 요트 → 🚢 방주

import 'package:shared_preferences/shared_preferences.dart';

class VoyagerGrade {
  final String key;       // 저장 키
  final String name;      // 한글 이름
  final String emoji;
  final int minExp;       // 이 등급 최소 경험치
  final int maxExp;       // 다음 등급까지 상한 (방주는 매우 큰 값)

  const VoyagerGrade({
    required this.key,
    required this.name,
    required this.emoji,
    required this.minExp,
    required this.maxExp,
  });

  static const List<VoyagerGrade> all = [
    VoyagerGrade(key: 'raft',    name: '돗단배', emoji: '🛶', minExp: 0,    maxExp: 100),
    VoyagerGrade(key: 'sail',    name: '범선',   emoji: '⛵', minExp: 100,  maxExp: 300),
    VoyagerGrade(key: 'speed',   name: '쾌속선', emoji: '🚤', minExp: 300,  maxExp: 600),
    VoyagerGrade(key: 'yacht',   name: '요트',   emoji: '🛥️', minExp: 600,  maxExp: 1000),
    VoyagerGrade(key: 'ark',     name: '방주',   emoji: '🚢', minExp: 1000, maxExp: 1 << 31),
  ];

  static VoyagerGrade fromExp(int exp) {
    for (int i = all.length - 1; i >= 0; i--) {
      if (exp >= all[i].minExp) return all[i];
    }
    return all.first;
  }
}

class ExperienceService {
  static const _kExp       = 'voyager_exp';
  static const _kNickname  = 'voyager_nickname';
  static const _kReadChSet = 'voyager_read_chapters'; // "book:chapter" set

  // 경험치 지급량 (단일 소스)
  static const int expPerChapterRead = 10;
  static const int expPerBookmark    = 2;
  static const int expPerMemo        = 5;
  static const int expPerHighlight   = 1;

  /// 경험치 추가. 음수 방지.
  static Future<int> addExp(int amount) async {
    if (amount <= 0) return await getExp();
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getInt(_kExp) ?? 0;
    final next = cur + amount;
    await prefs.setInt(_kExp, next);
    return next;
  }

  static Future<int> getExp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kExp) ?? 0;
  }

  static Future<VoyagerGrade> getGrade() async {
    return VoyagerGrade.fromExp(await getExp());
  }

  static Future<String> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNickname) ?? '항해자';
  }

  static Future<void> setNickname(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNickname, name.trim().isEmpty ? '항해자' : name.trim());
  }

  /// 장 완독 체크 — 처음 읽은 장이면 +10 지급하고 true 반환
  static Future<bool> markChapterRead(String bookKey, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$bookKey:$chapter';
    final set = (prefs.getStringList(_kReadChSet) ?? <String>[]).toSet();
    if (set.contains(key)) return false;
    set.add(key);
    await prefs.setStringList(_kReadChSet, set.toList());
    await addExp(expPerChapterRead);
    return true;
  }

  static Future<Set<String>> getReadChapters() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kReadChSet) ?? <String>[]).toSet();
  }

  /// 읽은 책 key 집합 (한 장이라도 읽은 책)
  static Future<Set<String>> getReadBooks() async {
    final chapters = await getReadChapters();
    return chapters.map((e) => e.split(':').first).toSet();
  }

  /// 모든 항해 기록 초기화
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kExp);
    await prefs.remove(_kNickname);
    await prefs.remove(_kReadChSet);
  }
}
