// lib/pages/memo_list_page.dart

import 'package:flutter/material.dart';
import '../models/memo.dart';
import '../services/memo_service.dart';
import 'memo_detail_page.dart';

class MemoListPage extends StatefulWidget {
  const MemoListPage({super.key});

  @override
  State<MemoListPage> createState() => _MemoListPageState();
}

class _MemoListPageState extends State<MemoListPage> {
  List<Memo> _memos = [];
  List<Memo> _filtered = [];
  final _searchCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _memos = MemoService.getAll();
      _filtered = List.from(_memos);
      _isLoading = false;
    });
  }

  void _onSearch(String q) {
    setState(() => _filtered = MemoService.search(q));
  }

  Future<void> _delete(String id) async {
    await MemoService.delete(id);
    _load();
  }

  Map<String, List<Memo>> _grouped() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    final groups = <String, List<Memo>>{
      '오늘': [],
      '어제': [],
      '이전 7일': [],
      '이전 30일': [],
      '오래된 항목': [],
    };

    for (final m in _filtered) {
      final d = DateTime(m.updatedAt.year, m.updatedAt.month, m.updatedAt.day);
      if (!d.isBefore(today)) {
        groups['오늘']!.add(m);
      } else if (!d.isBefore(yesterday)) {
        groups['어제']!.add(m);
      } else if (d.isAfter(weekAgo)) {
        groups['이전 7일']!.add(m);
      } else if (d.isAfter(monthAgo)) {
        groups['이전 30일']!.add(m);
      } else {
        groups['오래된 항목']!.add(m);
      }
    }

    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) {
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? '오후' : '오전';
      return '$ampm $h:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}. ${dt.day}.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final primary = isDark ? Colors.white : Colors.black;
    final secondary = const Color(0xFF8E8E93);
    final divider = isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6);
    final accentColor = Theme.of(context).colorScheme.primary;

    final groups = _grouped();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 (뒤로가기 + 제목)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  // 뒤로가기 버튼
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: accentColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text('메모',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primary)),
                  const Spacer(),
                  Text('${_memos.length}개',
                      style: TextStyle(fontSize: 13, color: secondary)),
                ],
              ),
            ),

            // ── 검색창
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C1E)
                      : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  style: TextStyle(color: primary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '검색',
                    hintStyle: TextStyle(color: secondary),
                    prefixIcon: Icon(Icons.search, color: secondary, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              _onSearch('');
                              FocusScope.of(context).unfocus();
                            },
                            child: Icon(Icons.cancel, color: secondary, size: 18),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            // ── 목록
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _memos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.note_alt_outlined,
                                  size: 60,
                                  color: isDark
                                      ? const Color(0xFF3A3A3C)
                                      : const Color(0xFFD1D1D6)),
                              const SizedBox(height: 16),
                              Text(
                                '성경 읽기 중 절을 탭해서\n메모를 남겨보세요',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: secondary,
                                    fontSize: 15,
                                    height: 1.6),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          children: [
                            ...groups.entries.map((entry) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 6),
                                    child: Text(entry.key,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: secondary)),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: List.generate(
                                        entry.value.length,
                                        (i) {
                                          final memo = entry.value[i];
                                          final isLast =
                                              i == entry.value.length - 1;
                                          return Column(
                                            children: [
                                              _MemoCell(
                                                memo: memo,
                                                timeText: _timeLabel(
                                                    memo.updatedAt),
                                                isDark: isDark,
                                                accentColor: accentColor,
                                                onTap: () async {
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          MemoDetailPage(
                                                              existingMemo:
                                                                  memo),
                                                    ),
                                                  );
                                                  _load();
                                                },
                                                onDelete: () =>
                                                    _delete(memo.id),
                                              ),
                                              if (!isLast)
                                                Divider(
                                                    height: 1,
                                                    color: divider,
                                                    indent: 16),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            const SizedBox(height: 80),
                          ],
                        ),
            ),
          ],
        ),
      ),

      // 하단 바 (새 메모 버튼)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
          border: Border(top: BorderSide(color: divider, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text('${_memos.length}개의 메모',
                    style: TextStyle(color: secondary, fontSize: 13)),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MemoDetailPage()),
                    );
                    _load();
                  },
                  child: Icon(
                    Icons.edit_square,
                    color: Theme.of(context).colorScheme.primary,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoCell extends StatelessWidget {
  final Memo memo;
  final String timeText;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MemoCell({
    required this.memo,
    required this.timeText,
    required this.isDark,
    required this.accentColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? Colors.white : Colors.black;
    final secondary = const Color(0xFF8E8E93);

    return Dismissible(
      key: Key(memo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('메모 삭제'),
                content: Text('"${memo.previewTitle}" 메모를 삭제할까요?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('취소')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('삭제',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(memo.previewTitle,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: primary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text(timeText,
                            style:
                                TextStyle(fontSize: 13, color: secondary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(memo.previewContent,
                        style: TextStyle(fontSize: 13, color: secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: secondary),
            ],
          ),
        ),
      ),
    );
  }
}
