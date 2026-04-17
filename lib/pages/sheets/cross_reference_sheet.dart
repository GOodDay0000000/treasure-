// lib/pages/sheets/cross_reference_sheet.dart
//
// 특정 구절의 교차참조 목록을 보여주는 바텀 시트.
// 탭하면 onSelect(ref) 콜백 호출 — 부모가 네비게이션 처리.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/cross_reference_service.dart';
import '../../l10n/app_strings.dart';

class CrossReferenceSheet extends StatelessWidget {
  final String version;      // 현재 번역본
  final String bookKey;
  final int chapter;
  final int verse;
  final void Function(CrossRef) onSelect;

  const CrossReferenceSheet({
    super.key,
    required this.version,
    required this.bookKey,
    required this.chapter,
    required this.verse,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final divColor = isDark ? const Color(0xFF2C3E50) : const Color(0xFFE5E5EA);
    final cardBg = isDark ? const Color(0xFF16213E) : const Color(0xFFF7F9FC);
    final bookName = BibleBookNames.get(bookKey, AppLocale.current);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.35,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Icon(Icons.hub_rounded, color: primary, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('교차 참조',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: text)),
                    const SizedBox(height: 2),
                    Text('$bookName $chapter:$verse 과 연결된 구절',
                        style: TextStyle(fontSize: 11, color: sub)),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: divColor),
            Expanded(
              child: FutureBuilder<List<CrossRef>>(
                future: CrossReferenceService()
                    .getReferences(bookKey, chapter, verse),
                builder: (_, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final refs = snap.data ?? const [];
                  if (refs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_off_rounded,
                                size: 48, color: sub.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text('이 구절의 교차참조가 없어요',
                                style: TextStyle(color: sub, fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                    itemCount: refs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _RefCard(
                      version: version,
                      ref: refs[i],
                      cardBg: cardBg,
                      primary: primary,
                      text: text,
                      sub: sub,
                      onTap: () => onSelect(refs[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefCard extends StatelessWidget {
  final String version;
  final CrossRef ref;
  final Color cardBg, primary, text, sub;
  final VoidCallback onTap;

  const _RefCard({
    required this.version,
    required this.ref,
    required this.cardBg,
    required this.primary,
    required this.text,
    required this.sub,
    required this.onTap,
  });

  Future<String?> _loadVerseText() async {
    try {
      final path = 'assets/bible/$version/${ref.bookKey}/${ref.chapter}.json';
      final raw = await rootBundle.loadString(path);
      final list = jsonDecode(raw) as List;
      final idx = ref.verse - 1;
      if (idx >= 0 && idx < list.length) return list[idx].toString();
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bookName = BibleBookNames.get(ref.bookKey, AppLocale.current);
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.arrow_forward_rounded, size: 14, color: primary),
              const SizedBox(width: 8),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$bookName ${ref.chapter}:${ref.verse}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primary)),
                  const SizedBox(height: 4),
                  FutureBuilder<String?>(
                    future: _loadVerseText(),
                    builder: (_, snap) {
                      final t = snap.data ?? '...';
                      return Text(t,
                          style: TextStyle(
                              fontSize: 12, color: text, height: 1.5),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis);
                    },
                  ),
                ],
              )),
              Icon(Icons.chevron_right_rounded, color: sub, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
