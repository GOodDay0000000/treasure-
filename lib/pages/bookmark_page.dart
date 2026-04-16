// lib/pages/bookmark_page.dart
// BookmarkService 기반으로 전면 교체

import 'package:flutter/material.dart';
import '../models/bookmark.dart';
import '../services/bookmark_service.dart';
import 'bible_read_page.dart';
import 'book_select_page.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  List<Bookmark> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _bookmarks = BookmarkService.getAll());
  }

  Future<void> _delete(String id) async {
    await BookmarkService.delete(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F6F2);
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final secondary = const Color(0xFF8E8E93);
    final divider =
        isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: const Text('북마크',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded,
                      size: 64,
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('저장된 북마크가 없어요',
                      style: TextStyle(
                          fontSize: 16, color: secondary)),
                  const SizedBox(height: 8),
                  Text('성경 읽기 중 절을 길게 눌러보세요',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _bookmarks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final bm = _bookmarks[index];
                return Dismissible(
                  key: Key(bm.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _delete(bm.id),
                  child: Material(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    elevation: isDark ? 0 : 1,
                    shadowColor: Colors.black12,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BibleReadPage(
                              version: bm.verseRef.version,
                              bookKey: bm.verseRef.bookKey,
                              bookName: bm.verseRef.bookName,
                              chapter: bm.verseRef.chapter,
                              totalChapters: BookSelectPage.getChapterCount(bm.verseRef.bookKey), // ← 추가
                              highlightVerse: bm.verseRef.verse,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.bookmark_rounded,
                                color: Colors.amber.shade600, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bm.verseRef.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.grey.shade200
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bm.verseRef.verseText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: secondary, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
