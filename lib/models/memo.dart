// lib/models/memo.dart

import 'dart:convert';
import 'dart:ui';
import 'verse_ref.dart';

// ─────────────────────────────────────────
// DrawStroke
// ─────────────────────────────────────────
class DrawStroke {
  final List<Offset> points;
  final int colorValue;
  final double width;

  Color get color => Color(colorValue);

  DrawStroke({
    required this.points,
    required this.colorValue,
    required this.width,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((o) => {'dx': o.dx, 'dy': o.dy}).toList(),
        'colorValue': colorValue,
        'width': width,
      };

  factory DrawStroke.fromJson(Map<String, dynamic> json) => DrawStroke(
        points: (json['points'] as List)
            .map((p) => Offset(
                  (p['dx'] as num).toDouble(),
                  (p['dy'] as num).toDouble(),
                ))
            .toList(),
        colorValue: (json['colorValue'] as num).toInt(),
        width: (json['width'] as num).toDouble(),
      );
}

// ─────────────────────────────────────────
// MemoBlock
// ─────────────────────────────────────────
enum MemoBlockType { text, verse, drawing }

class MemoBlock {
  final String id;
  final MemoBlockType type;
  String textContent;
  VerseRef? verseRef;
  List<DrawStroke> strokes;

  MemoBlock({
    required this.id,
    required this.type,
    this.textContent = '',
    this.verseRef,
    List<DrawStroke>? strokes,
  }) : strokes = strokes ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'textContent': textContent,
        'verseRef': verseRef?.toJson(),
        'strokes': strokes.map((s) => s.toJson()).toList(),
      };

  factory MemoBlock.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'text';
    final type = MemoBlockType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => MemoBlockType.text,
    );
    return MemoBlock(
      id: json['id'] as String,
      type: type,
      textContent: json['textContent'] as String? ?? '',
      verseRef: json['verseRef'] != null
          ? VerseRef.fromJson(json['verseRef'] as Map<String, dynamic>)
          : null,
      strokes: (json['strokes'] as List? ?? [])
          .map((s) => DrawStroke.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────
// Memo
// ─────────────────────────────────────────
class Memo {
  final String id;
  String title;
  List<MemoBlock> blocks;

  // QuillEditor delta JSON (rich text)
  // null이면 blocks의 plain text 사용
  String? quillDelta;

  final DateTime createdAt;
  DateTime updatedAt;

  Memo({
    required this.id,
    required this.title,
    required this.blocks,
    this.quillDelta,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── 하위 호환 접근자
  String get content => blocks
      .where((b) =>
          b.type == MemoBlockType.text &&
          !b.textContent.startsWith('__IMAGE__:') &&
          !b.textContent.startsWith('__QUILL__:'))
      .map((b) => b.textContent)
      .join('\n')
      .trim();

  List<MemoBlock> get verses =>
      blocks.where((b) => b.type == MemoBlockType.verse).toList();

  // ── Quill delta에서 plain text 추출 (미리보기용)
  static String extractPlainText(String quillDeltaJson) {
    try {
      final ops = jsonDecode(quillDeltaJson) as List;
      return ops
          .where((op) => op is Map && op['insert'] is String)
          .map((op) => op['insert'] as String)
          .join('')
          .replaceAll('\n', ' ')
          .trim();
    } catch (_) {
      return '';
    }
  }

  // ── 목록 미리보기
  String get previewTitle {
    if (title.isNotEmpty) return title;
    // quill delta에서 추출
    if (quillDelta != null && quillDelta!.isNotEmpty) {
      final text = extractPlainText(quillDelta!);
      if (text.isNotEmpty) {
        return text.split('\n').first.trim();
      }
    }
    // plain text blocks
    final firstText = blocks
        .where((b) =>
            b.type == MemoBlockType.text &&
            b.textContent.isNotEmpty &&
            !b.textContent.startsWith('__'))
        .map((b) => b.textContent.trim().split('\n').first)
        .firstOrNull;
    if (firstText != null) return firstText;
    final firstVerse = verses.firstOrNull;
    if (firstVerse != null) return firstVerse.verseRef?.label ?? '새 메모';
    return '새 메모';
  }

  String get previewContent {
    if (quillDelta != null && quillDelta!.isNotEmpty) {
      final text = extractPlainText(quillDelta!);
      if (text.isNotEmpty) {
        return text.length > 60 ? '${text.substring(0, 60)}...' : text;
      }
    }
    final textContent = content;
    if (textContent.isNotEmpty) {
      return textContent.length > 60
          ? '${textContent.substring(0, 60)}...'
          : textContent;
    }
    final hasImage = blocks.any((b) =>
        b.type == MemoBlockType.text &&
        b.textContent.startsWith('__IMAGE__:'));
    if (hasImage) return '📷 사진';
    final verseLabels = verses
        .map((b) => b.verseRef?.label ?? '')
        .where((s) => s.isNotEmpty)
        .join(' · ');
    if (verseLabels.isNotEmpty) return verseLabels;
    return '내용 없음';
  }

  String get versesLabel {
    final count = verses.length;
    return count == 0 ? '' : '구절 ${count}개';
  }

  // ── 직렬화
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'quillDelta': quillDelta,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Memo.fromJson(Map<String, dynamic> json) {
    // 구버전 호환
    if (json.containsKey('content') && !json.containsKey('blocks')) {
      return _fromLegacyJson(json);
    }
    return Memo(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      blocks: (json['blocks'] as List? ?? [])
          .map((b) => MemoBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      quillDelta: json['quillDelta'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static Memo _fromLegacyJson(Map<String, dynamic> json) {
    final blocks = <MemoBlock>[];
    final content = json['content'] as String? ?? '';
    if (content.isNotEmpty) {
      blocks.add(MemoBlock(
        id: 'legacy-text',
        type: MemoBlockType.text,
        textContent: content,
      ));
    }
    return Memo(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      blocks: blocks,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Memo copyWith({
    String? title,
    List<MemoBlock>? blocks,
    String? quillDelta,
    DateTime? updatedAt,
  }) =>
      Memo(
        id: id,
        title: title ?? this.title,
        blocks: blocks ?? this.blocks,
        quillDelta: quillDelta ?? this.quillDelta,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
