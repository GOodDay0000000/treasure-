// lib/models/bookmark.dart

import 'verse_ref.dart';

class Bookmark {
  final String id;
  final VerseRef verseRef;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.verseRef,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'verseRef': verseRef.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'] as String,
        verseRef:
            VerseRef.fromJson(json['verseRef'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
