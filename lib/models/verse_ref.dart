// lib/models/verse_ref.dart
// 북마크, 형광펜, 메모가 공통으로 사용하는 구절 정보

class VerseRef {
  final String version;   // 'krv', 'niv' 등
  final String bookKey;   // 'genesis'
  final String bookName;  // '창세기'
  final int chapter;      // 1
  final int verse;        // 1
  final String verseText; // "태초에 하나님이..."

  const VerseRef({
    required this.version,
    required this.bookKey,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.verseText,
  });

  /// 유일 키 (검색/비교용)
  String get key => '${version}_${bookKey}_${chapter}_${verse}';

  /// 화면 표시용 레이블
  String get label => '$bookName $chapter:$verse';

  Map<String, dynamic> toJson() => {
        'version': version,
        'bookKey': bookKey,
        'bookName': bookName,
        'chapter': chapter,
        'verse': verse,
        'verseText': verseText,
      };

  factory VerseRef.fromJson(Map<String, dynamic> json) => VerseRef(
        version: json['version'] as String? ?? 'krv',
        bookKey: json['bookKey'] as String,
        bookName: json['bookName'] as String,
        chapter: (json['chapter'] as num).toInt(),
        verse: (json['verse'] as num).toInt(),
        verseText: json['verseText'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is VerseRef && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
