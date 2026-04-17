// lib/pages/sheets/commentary_sheet.dart

import 'package:flutter/material.dart';
import '../../services/commentary_service.dart';
import '../../l10n/app_strings.dart';
import '../book_select_page.dart';

/// 특정 장의 주석을 보여주는 DraggableScrollableSheet.
///
/// 사용:
///   showModalBottomSheet(
///     context: context,
///     backgroundColor: Colors.transparent,
///     isScrollControlled: true,
///     builder: (_) => CommentarySheet(
///       bookKey: 'genesis', chapter: 1, highlightVerse: 3),
///   );
class CommentarySheet extends StatelessWidget {
  final String bookKey;
  final int chapter;
  final int? highlightVerse;

  const CommentarySheet({
    super.key,
    required this.bookKey,
    required this.chapter,
    this.highlightVerse,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final divColor = isDark ? const Color(0xFF2C3E50) : const Color(0xFFE5E5EA);
    final bookName = BibleBookNames.get(bookKey, AppLocale.current);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: sub.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Icon(Icons.menu_book_rounded, color: primary, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$bookName $chapter장 주석',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: text)),
                    const SizedBox(height: 2),
                    Text('Church Fathers (Public Domain)',
                        style: TextStyle(fontSize: 11, color: sub)),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: divColor),
            // 본문
            Expanded(
              child: FutureBuilder<ChapterCommentary?>(
                future: CommentaryService().getChapter(bookKey, chapter),
                builder: (_, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final ch = snap.data;
                  if (ch == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 48, color: sub.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text('이 장의 주석이 아직 없어요',
                                style: TextStyle(color: sub, fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  }
                  final entries = ch.sortedEntries();
                  return ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final isHighlight = _matchHighlight(e.key);
                      return _VerseEntry(
                        label: e.key,
                        body: e.value,
                        isHighlight: isHighlight,
                        primary: primary,
                        text: text,
                        sub: sub,
                        isDark: isDark,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchHighlight(String key) {
    final hv = highlightVerse;
    if (hv == null) return false;
    if (key == '$hv') return true;
    final dash = key.indexOf('-');
    if (dash < 0) return false;
    final lo = int.tryParse(key.substring(0, dash));
    final hi = int.tryParse(key.substring(dash + 1));
    return lo != null && hi != null && hv >= lo && hv <= hi;
  }
}

class _VerseEntry extends StatelessWidget {
  final String label, body;
  final bool isHighlight, isDark;
  final Color primary, text, sub;

  const _VerseEntry({
    required this.label,
    required this.body,
    required this.isHighlight,
    required this.isDark,
    required this.primary,
    required this.text,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isHighlight
        ? primary.withOpacity(isDark ? 0.15 : 0.08)
        : Colors.transparent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: isHighlight
            ? Border(left: BorderSide(color: primary, width: 3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$label절',
                style: TextStyle(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(
                  fontSize: 13.5,
                  color: text,
                  height: 1.65)),
        ],
      ),
    );
  }
}
