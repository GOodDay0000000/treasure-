// lib/pages/highlight_list_page.dart

import 'package:flutter/material.dart';
import '../models/highlight.dart';
import '../services/highlight_service.dart';
import 'bible_read_page.dart';
import 'book_select_page.dart';

class HighlightListPage extends StatefulWidget {
  const HighlightListPage({super.key});

  @override
  State<HighlightListPage> createState() => _HighlightListPageState();
}

class _HighlightListPageState extends State<HighlightListPage> {
  List<Highlight> _highlights = [];
  String? _selectedColorKey; // null = 전체

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _highlights = _selectedColorKey == null
          ? HighlightService.getAll()
          : HighlightService.getByColor(_selectedColorKey!);
    });
  }

  Future<void> _delete(String id) async {
    await HighlightService.delete(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F6F2);
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final secondary = const Color(0xFF8E8E93);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: const Text('형광펜',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── 색상 필터 탭
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // 전체 버튼
                _FilterChip(
                  label: '전체',
                  isSelected: _selectedColorKey == null,
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : Colors.grey.shade200,
                  selectedColor: isDark
                      ? const Color(0xFF4C4C4E)
                      : Colors.grey.shade400,
                  textColor: isDark ? Colors.white : Colors.black,
                  onTap: () {
                    setState(() => _selectedColorKey = null);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                // 색상별 필터 버튼
                ...HighlightColor.values.map((hc) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: hc.label,
                        isSelected: _selectedColorKey == hc.key,
                        color: hc.color.withOpacity(0.4),
                        selectedColor: hc.color,
                        textColor:
                            isDark ? Colors.white : Colors.black87,
                        onTap: () {
                          setState(() => _selectedColorKey == hc.key
                              ? _selectedColorKey = null
                              : _selectedColorKey = hc.key);
                          _load();
                        },
                      ),
                    )),
              ],
            ),
          ),

          // ── 목록
          Expanded(
            child: _highlights.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.highlight_rounded,
                            size: 64,
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _selectedColorKey == null
                              ? '저장된 형광펜이 없어요'
                              : '${HighlightColor.fromKey(_selectedColorKey!).label} 형광펜이 없어요',
                          style: TextStyle(
                              fontSize: 16, color: secondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '성경 읽기 중 절을 길게 눌러보세요',
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _highlights.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final hl = _highlights[index];
                      final hlColor = hl.highlightColor;

                      return Dismissible(
                        key: Key(hl.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        onDismissed: (_) => _delete(hl.id),
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
                                    version: hl.verseRef.version,
                                    bookKey: hl.verseRef.bookKey,
                                    bookName: hl.verseRef.bookName,
                                    chapter: hl.verseRef.chapter,
                                    totalChapters: BookSelectPage.getChapterCount(hl.verseRef.bookKey),
                                    highlightVerse: hl.verseRef.verse,
                                  ),
                                ),
                              ).then((_) => _load());
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  0, 14, 16, 14),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // 색상 인디케이터
                                  Container(
                                    width: 5,
                                    height: 60,
                                    margin: const EdgeInsets.only(
                                        left: 16, right: 12),
                                    decoration: BoxDecoration(
                                      color: hlColor.color,
                                      borderRadius:
                                          BorderRadius.circular(3),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 위치 레이블
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: hlColor.color
                                                    .withOpacity(0.3),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        6),
                                              ),
                                              child: Text(
                                                hlColor.label,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              hl.verseRef.label,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: isDark
                                                    ? Colors.grey.shade300
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // 구절 내용
                                        Text(
                                          hl.verseRef.verseText,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.5,
                                            color: isDark
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade700,
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
          ),
        ],
      ),
    );
  }
}

// ── 색상 필터 칩
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final Color selectedColor;
  final Color textColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.selectedColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
