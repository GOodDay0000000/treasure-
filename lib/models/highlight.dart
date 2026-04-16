// lib/models/highlight.dart

import 'package:flutter/material.dart';
import 'verse_ref.dart';

/// 형광펜 색상 정의
class HighlightColor {
  final String key;       // 저장 키 ('yellow', 'green' 등)
  final Color color;      // 배경색
  final Color textColor;  // 글자색 (가독성용)
  final String label;     // 한글 이름

  const HighlightColor({
    required this.key,
    required this.color,
    required this.textColor,
    required this.label,
  });

  static const List<HighlightColor> values = [
    HighlightColor(
      key: 'yellow',
      color: Color(0xFFFFEF62),
      textColor: Color(0xFF1A1A1A),
      label: '노랑',
    ),
    HighlightColor(
      key: 'green',
      color: Color(0xFF90EE90),
      textColor: Color(0xFF1A1A1A),
      label: '초록',
    ),
    HighlightColor(
      key: 'blue',
      color: Color(0xFFADD8E6),
      textColor: Color(0xFF1A1A1A),
      label: '파랑',
    ),
    HighlightColor(
      key: 'pink',
      color: Color(0xFFFFB6C1),
      textColor: Color(0xFF1A1A1A),
      label: '분홍',
    ),
    HighlightColor(
      key: 'orange',
      color: Color(0xFFFFCC80),
      textColor: Color(0xFF1A1A1A),
      label: '주황',
    ),
  ];

  /// key로 HighlightColor 찾기
  static HighlightColor fromKey(String key) {
    return values.firstWhere(
      (c) => c.key == key,
      orElse: () => values.first,
    );
  }
}

/// 형광펜 데이터 모델
class Highlight {
  final String id;
  final VerseRef verseRef;
  final String colorKey;   // 'yellow', 'green', 'blue', 'pink', 'orange'
  final DateTime createdAt;
  DateTime updatedAt;

  Highlight({
    required this.id,
    required this.verseRef,
    required this.colorKey,
    required this.createdAt,
    required this.updatedAt,
  });

  HighlightColor get highlightColor => HighlightColor.fromKey(colorKey);

  Map<String, dynamic> toJson() => {
        'id': id,
        'verseRef': verseRef.toJson(),
        'colorKey': colorKey,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Highlight.fromJson(Map<String, dynamic> json) => Highlight(
        id: json['id'] as String,
        verseRef:
            VerseRef.fromJson(json['verseRef'] as Map<String, dynamic>),
        colorKey: json['colorKey'] as String? ?? 'yellow',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
