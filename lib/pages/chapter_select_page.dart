// lib/pages/chapter_select_page.dart

import 'package:flutter/material.dart';
import 'bible_read_page.dart';

class ChapterSelectPage extends StatelessWidget {
  final String version;
  final String bookKey;
  final String bookName;
  final int chapterCount;

  const ChapterSelectPage({
    super.key,
    required this.version,
    required this.bookKey,
    required this.bookName,
    required this.chapterCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(bookName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: chapterCount,
        itemBuilder: (context, index) {
          final int chapter = index + 1;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BibleReadPage(
                    version: version,
                    bookKey: bookKey,
                    bookName: bookName,
                    chapter: chapter,
                    totalChapters: chapterCount, // ← 추가
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F3460)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$chapter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.grey.shade200
                        : Colors.grey.shade800,
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
