// lib/pages/hymn_page.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/hymn_service.dart';
import '../l10n/app_strings.dart';

// ── HymnPage ──────────────────────────────────────────────────
class HymnPage extends StatefulWidget {
  const HymnPage({super.key});
  @override
  State<HymnPage> createState() => _HymnPageState();
}

class _HymnPageState extends State<HymnPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 새찬송가
  bool   _isDownloaded  = false;
  bool   _isDownloading = false;
  double _progress      = 0.0;
  String _status        = '';
  bool   _isChecking    = true;
  bool   _showSearch    = false;
  String _searchQuery   = '';
  final  _searchCtrl    = TextEditingController();

  // 내 악보
  List<File> _myScores = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    if (!kIsWeb) {
      _checkDownload();
      _loadMyScores();
    } else {
      setState(() => _isChecking = false);
    }
  }

  // 영문 탭(index=2)은 저작권 문제로 사용 불가 → 탭 자체를 되돌리고 다이얼로그만 표시.
  // TabBar.onTap에서 호출 — 실제 탭 전환 전에 가로채서 다이얼로그 띄움.
  int _prevTabIndex = 0;
  void _handleTabTap(int i) {
    if (i == 2) {
      _showCopyrightDialog();
      // TabBar가 내부적으로 animateTo(2)를 예약하므로 다음 프레임에서 snap-back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _tabController.animateTo(_prevTabIndex,
            duration: Duration.zero);
      });
    } else {
      _prevTabIndex = i;
    }
  }

  void _showCopyrightDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B2D3F) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copyright_rounded, size: 20, color: primary),
            const SizedBox(width: 8),
            Text('저작권 안내',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: text)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '다국어 찬송가는 저작권 문제로\n현재 지원이 어렵습니다.',
              style: TextStyle(fontSize: 14, color: text, height: 1.6),
            ),
            const SizedBox(height: 10),
            Text(
              'Due to copyright restrictions,\nmultilingual hymns are not\ncurrently supported.',
              style: TextStyle(fontSize: 12, color: sub, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(color: primary)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkDownload() async {
    final ok = await HymnService.isDownloaded();
    if (mounted) setState(() { _isDownloaded = ok; _isChecking = false; });
  }

  Future<void> _startDownload() async {
    setState(() { _isDownloading = true; _progress = 0.0; _status = '준비 중...'; });
    try {
      await HymnService.downloadAndExtract(
        onProgress: (pr, st) {
          if (mounted) setState(() { _progress = pr; _status = st; });
        },
      );
      if (mounted) setState(() { _isDownloaded = true; _isDownloading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        _snack('다운로드 실패: $e', error: true);
      }
    }
  }

  Future<void> _reDownload() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B2D3F) : Colors.white,
        title: const Text('찬송가 재다운로드',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('기존 데이터를 삭제하고 새로 다운로드할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('재다운로드')),
        ],
      ),
    );
    if (ok != true) return;
    await HymnService.deleteAll();
    setState(() => _isDownloaded = false);
    _startDownload();
  }

  // ── 내 악보 ───────────────────────────────────────────────
  Future<Directory> _myScoreDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir  = Directory(p.join(base.path, 'my_scores'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  bool _isImage(String path) =>
      ['.jpg', '.jpeg', '.png', '.webp']
          .contains(p.extension(path).toLowerCase());

  Future<void> _loadMyScores() async {
    try {
      final dir   = await _myScoreDir();
      final files = dir.listSync().whereType<File>()
          .where((f) => _isImage(f.path)).toList()
        ..sort((a, b) =>
            b.statSync().modified.compareTo(a.statSync().modified));
      if (mounted) setState(() => _myScores = files);
    } catch (_) {}
  }

  Future<void> _pickGallery() async {
    final imgs = await ImagePicker().pickMultiImage(imageQuality: 90);
    if (imgs.isEmpty) return;
    final dir = await _myScoreDir();
    for (final img in imgs) {
      final name = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(img.path)}';
      await File(img.path).copy(p.join(dir.path, name));
    }
    await _loadMyScores();
    _snack('${imgs.length}개 추가됐어요');
  }

  Future<void> _pickCamera() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 90);
    if (img == null) return;
    final dir  = await _myScoreDir();
    final name = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(img.path)}';
    await File(img.path).copy(p.join(dir.path, name));
    await _loadMyScores();
    _snack('악보가 추가됐어요');
  }

  Future<void> _deleteScore(File file) async {
    await file.delete();
    await _loadMyScores();
    _snack('삭제됐어요');
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : null,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  List<int> get _filteredHymns {
    final total = HymnService.totalHymns;
    if (_searchQuery.isEmpty) return List.generate(total, (i) => i + 1);
    return List.generate(total, (i) => i + 1)
        .where((n) => n.toString().contains(_searchQuery.trim()))
        .toList();
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bg      = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);
    final sub     = const Color(0xFF8E8E93);
    final curTab  = _tabController.index;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: false,
        title: _showSearch
            ? TextField(
          controller: _searchCtrl, autofocus: true,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
              hintText: '장 번호 검색',
              hintStyle: TextStyle(color: sub),
              border: InputBorder.none),
          keyboardType: TextInputType.number,
          onChanged: (v) => setState(() => _searchQuery = v),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.anchor_rounded, size: 18, color: primary),
            const SizedBox(width: 6),
            Text('Treasure',
                style: GoogleFonts.dancingScript(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: primary)),
          ],
        ),
        centerTitle: !_showSearch,
        actions: [
          if (curTab == 0 && _isDownloaded && !_showSearch)
            IconButton(
              icon: Icon(Icons.search_rounded, color: sub),
              onPressed: () => setState(() => _showSearch = true),
            ),
          if (curTab == 0 && _isDownloaded && !_showSearch)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: sub),
              onPressed: _reDownload,
              tooltip: '재다운로드',
            ),
          if (_showSearch)
            IconButton(
              icon: Icon(Icons.close_rounded, color: sub),
              onPressed: () => setState(() {
                _showSearch = false;
                _searchQuery = '';
                _searchCtrl.clear();
              }),
            ),
        ],
        bottom: !_showSearch
            ? TabBar(
          controller: _tabController,
          onTap: _handleTabTap,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: sub,
          tabs: [
            Tab(
                icon: const Icon(Icons.music_note_rounded, size: 18),
                text: AppLocale.s.koreanHymns),
            Tab(
                icon: const Icon(Icons.queue_music_rounded, size: 18),
                text: AppLocale.s.myScore),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.language_rounded,
                    size: 16,
                    color: curTab == 2 ? primary : sub),
                const SizedBox(width: 4),
                Text('영문',
                    style: TextStyle(
                        color: curTab == 2 ? primary : sub)),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: sub.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('준비중',
                      style: TextStyle(fontSize: 9, color: sub)),
                ),
              ]),
            ),
          ],
        )
            : null,
      ),
      body: kIsWeb
          ? _buildWebMsg(isDark, primary)
          : TabBarView(
        controller: _tabController,
        children: [
          _buildKoreanTab(isDark, primary, sub),
          _buildMyScoreTab(isDark, primary, sub),
          _buildComingSoon(isDark, primary, sub),
        ],
      ),
    );
  }

  // ── 새찬송가 탭 ───────────────────────────────────────────
  Widget _buildKoreanTab(bool isDark, Color primary, Color sub) {
    if (_isChecking)   return const Center(child: CircularProgressIndicator());
    if (_isDownloading) return _buildDownloading(isDark, primary);
    if (_isDownloaded)  return _buildHymnGrid(isDark, primary, sub);
    return _buildDownloadPrompt(isDark, primary, sub);
  }

  Widget _buildHymnGrid(bool isDark, Color primary, Color sub) {
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final border = isDark ? const Color(0xFF2C3E50) : const Color(0xFFE5E5EA);
    final text   = isDark ? Colors.white : Colors.black;
    final hymns  = _filteredHymns;

    if (hymns.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48,
              color: sub.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('검색 결과가 없어요', style: TextStyle(color: sub)),
        ],
      ));
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, childAspectRatio: 1.1,
        crossAxisSpacing: 8, mainAxisSpacing: 8,
      ),
      itemCount: hymns.length,
      itemBuilder: (context, i) {
        final number = hymns[i];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => HymnViewerPage(
              initialIndex: number - 1,
              totalCount:   HymnService.totalHymns,
              getFile: (idx) async {
                final path = await HymnService.getHymnPath(idx + 1);
                return path == null ? null : File(path);
              },
              labelBuilder: (idx) => '${idx + 1}장',
            ),
          )),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 0.5),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 4, offset: const Offset(0, 2),
              )],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note_rounded,
                    size: 13, color: primary.withOpacity(0.4)),
                const SizedBox(height: 4),
                Text('$number',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: text)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 내 악보 탭 ────────────────────────────────────────────
  Widget _buildMyScoreTab(bool isDark, Color primary, Color sub) {
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final border = isDark ? const Color(0xFF2C3E50) : const Color(0xFFE5E5EA);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Expanded(child: _AddBtn(
            icon: Icons.photo_library_rounded,
            label: '사진첩에서',
            color: primary, isDark: isDark,
            onTap: _pickGallery,
          )),
          const SizedBox(width: 10),
          Expanded(child: _AddBtn(
            icon: Icons.camera_alt_rounded,
            label: '카메라 촬영',
            color: primary, isDark: isDark,
            onTap: _pickCamera,
          )),
        ]),
      ),
      if (_myScores.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Row(children: [
            Text('${_myScores.length}개',
                style: TextStyle(fontSize: 12, color: sub,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('길게 눌러 삭제',
                style: TextStyle(
                    fontSize: 11, color: sub.withOpacity(0.6))),
          ]),
        ),
      Expanded(
        child: _myScores.isEmpty
            ? Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music_rounded,
                size: 64, color: sub.withOpacity(0.25)),
            const SizedBox(height: 20),
            Text('악보를 추가해보세요',
                style: TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w600, color: sub)),
            const SizedBox(height: 8),
            Text('새찬송가에 없는 CCM이나\n악보를 사진으로 추가할 수 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: sub.withOpacity(0.7), height: 1.6)),
          ],
        ))
            : GridView.builder(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, childAspectRatio: 0.72,
            crossAxisSpacing: 8, mainAxisSpacing: 8,
          ),
          itemCount: _myScores.length,
          itemBuilder: (context, i) {
            final file = _myScores[i];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => HymnViewerPage(
                  initialIndex: i,
                  totalCount:   _myScores.length,
                  getFile: (idx) async => _myScores[idx],
                  labelBuilder: (idx) =>
                      p.basenameWithoutExtension(
                          _myScores[idx].path)
                          .replaceAll(RegExp(r'^\d+_'), ''),
                ),
              )),
              onLongPress: () => _confirmDelete(file),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 0.5),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(file, fit: BoxFit.cover),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  void _confirmDelete(File file) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? const Color(0xFF1B2D3F) : Colors.white,
        title: const Text('삭제할까요?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(p.basenameWithoutExtension(file.path)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          TextButton(
            onPressed: () { Navigator.pop(context); _deleteScore(file); },
            child: const Text('삭제',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── 준비중 탭 ─────────────────────────────────────────────
  Widget _buildComingSoon(bool isDark, Color primary, Color sub) {
    final text = isDark ? Colors.white : Colors.black;
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.language_rounded,
              size: 40, color: primary.withOpacity(0.5)),
        ),
        const SizedBox(height: 24),
        Text('영문 찬송',
            style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.bold, color: text)),
        const SizedBox(height: 12),
        Text('준비하고 있어요',
            style: TextStyle(fontSize: 14, color: sub)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Coming Soon',
              style: TextStyle(fontSize: 13, color: primary,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    ));
  }

  // ── 다운로드 화면들 ───────────────────────────────────────
  Widget _buildDownloadPrompt(bool isDark, Color primary, Color sub) {
    final text = isDark ? Colors.white : Colors.black;
    return Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.download_for_offline_rounded,
            size: 72, color: primary.withOpacity(0.7)),
        const SizedBox(height: 24),
        Text('새찬송가 악보 다운로드',
            style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.bold, color: text)),
        const SizedBox(height: 10),
        Text('645장 전체 악보를 다운로드하여\n오프라인으로 사용할 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: sub, height: 1.6)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('약 78MB · 최초 1회만 다운로드',
              style: TextStyle(fontSize: 12, color: primary)),
        ),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Icons.download_rounded),
            label: Text(AppLocale.s.downloadHymns,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 저작권 안내 (한/영)
        Text(
          '새찬송가는 한국 저작권 규정에 따라\n'
          '개인 사용 목적으로만 제공됩니다.\n'
          '다국어 찬송가는 저작권 문제로\n'
          '현재 지원이 어렵습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: sub, height: 1.7),
        ),
        const SizedBox(height: 8),
        Text(
          'Korean Hymns only. Due to copyright\n'
          'restrictions, multilingual hymns are\n'
          'not currently supported.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11,
              color: sub.withOpacity(0.7),
              height: 1.7),
        ),
      ]),
    ));
  }

  Widget _buildDownloading(bool isDark, Color primary) {
    final text = isDark ? Colors.white : Colors.black;
    final sub  = const Color(0xFF8E8E93);
    return Center(child: Padding(padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.downloading_rounded, size: 72, color: primary),
        const SizedBox(height: 32),
        Text('찬송가 다운로드 중',
            style: TextStyle(fontSize: 20,
                fontWeight: FontWeight.bold, color: text)),
        const SizedBox(height: 8),
        Text(_status, style: TextStyle(fontSize: 13, color: sub)),
        const SizedBox(height: 28),
        ClipRRect(borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: _progress, minHeight: 10,
              backgroundColor: primary.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(primary)),
        ),
        const SizedBox(height: 12),
        Text('${(_progress * 100).toInt()}%',
            style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.bold, color: primary)),
        const SizedBox(height: 16),
        Text('앱을 종료하지 말고 기다려주세요',
            style: TextStyle(fontSize: 12, color: sub)),
      ]),
    ));
  }

  Widget _buildWebMsg(bool isDark, Color primary) {
    final text = isDark ? Colors.white : Colors.black;
    final sub  = const Color(0xFF8E8E93);
    return Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.smartphone_rounded,
            size: 80, color: primary.withOpacity(0.5)),
        const SizedBox(height: 24),
        Text('모바일 전용 기능',
            style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.bold, color: text)),
        const SizedBox(height: 12),
        Text('찬송가는 앱(APK)에서만 사용할 수 있어요',
            style: TextStyle(fontSize: 14, color: sub)),
      ]),
    ));
  }
}

// ── 추가 버튼 ─────────────────────────────────────────────────
class _AddBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final bool     isDark;
  final VoidCallback onTap;

  const _AddBtn({required this.icon, required this.label,
    required this.color, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color,
            fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ── 뷰어 ────────────────────────────────────────────────────
// 주어진 index에 대한 원본 파일을 돌려준다. 없으면 null.
typedef HymnFileResolver = Future<File?> Function(int index);

class HymnViewerPage extends StatefulWidget {
  final int   initialIndex;
  final int   totalCount;
  final HymnFileResolver getFile;
  final String Function(int) labelBuilder;

  const HymnViewerPage({
    super.key,
    required this.initialIndex,
    required this.totalCount,
    required this.getFile,
    required this.labelBuilder,
  });

  @override
  State<HymnViewerPage> createState() => _HymnViewerPageState();
}

// 최대한 단순화한 뷰어 — AppBar/터치 충돌 없이 Image.memory로 직접 렌더링.
// 각 페이지는 _HymnPage가 자체 FutureBuilder로 파일을 읽어와 표시.
class _HymnViewerPageState extends State<HymnViewerPage> {
  late PageController _pageCtrl;
  late int _curIdx;

  @override
  void initState() {
    super.initState();
    _curIdx = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _prev() {
    if (_curIdx > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }
  }

  void _next() {
    if (_curIdx < widget.totalCount - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }
  }

  void _showJumpDialog() {
    final primary = Theme.of(context).colorScheme.primary;
    final ctrl = TextEditingController(text: '${_curIdx + 1}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('장 번호로 이동',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '1 ~ ${widget.totalCount}',
            hintStyle: const TextStyle(color: Colors.white38),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text);
              if (n != null && n >= 1 && n <= widget.totalCount) {
                Navigator.pop(context);
                _pageCtrl.jumpToPage(n - 1);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black),
            child: const Text('이동'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 터치 이벤트 충돌을 막기 위해 extendBodyBehindAppBar를 끄고
      // AppBar / body / bottomNavigationBar를 완전히 분리.
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: Colors.white),
          tooltip: '뒤로',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.labelBuilder(_curIdx),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.totalCount,
        onPageChanged: (i) => setState(() => _curIdx = i),
        itemBuilder: (_, index) => _HymnPageItem(
          key: ValueKey('hymn-$index'),
          index: index,
          getFile: widget.getFile,
          label: widget.labelBuilder(index),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.black,
          height: 54,
          child: Row(
            children: [
              IconButton(
                onPressed: _curIdx > 0 ? _prev : null,
                icon: Icon(Icons.arrow_back_ios_rounded,
                    color: _curIdx > 0 ? Colors.white : Colors.white30),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showJumpDialog,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.music_note_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(widget.labelBuilder(_curIdx),
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _curIdx < widget.totalCount - 1 ? _next : null,
                icon: Icon(Icons.arrow_forward_ios_rounded,
                    color: _curIdx < widget.totalCount - 1
                        ? Colors.white
                        : Colors.white30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 개별 찬송가 페이지 — 독립 FutureBuilder로 읽기/디코딩.
// 캐시 없음, ResizeImage 없음, 코덱 직접 호출 없음. 최대한 표준 경로.
class _HymnPageItem extends StatefulWidget {
  final int index;
  final HymnFileResolver getFile;
  final String label;

  const _HymnPageItem({
    required Key key,
    required this.index,
    required this.getFile,
    required this.label,
  }) : super(key: key);

  @override
  State<_HymnPageItem> createState() => _HymnPageItemState();
}

class _HymnPageItemState extends State<_HymnPageItem> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Uint8List?> _load() async {
    try {
      final file = await widget.getFile(widget.index);
      if (file == null) return null;
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        final bytes = snap.data;
        if (bytes == null) {
          return _buildError('이미지를 불러올 수 없어요');
        }
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Center(
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, err, __) =>
                  _buildError('디코딩 실패: $err'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported_rounded,
              size: 56, color: Colors.white54),
          const SizedBox(height: 12),
          Text('${widget.label} · $msg',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh_rounded,
                size: 16, color: Colors.white70),
            label: const Text('다시 시도',
                style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
