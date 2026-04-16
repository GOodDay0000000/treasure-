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
              getImageProvider: (idx) async {
                final path = await HymnService.getHymnPath(idx + 1);
                if (path == null) return null;
                return FileImage(File(path));
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
                  getImageProvider: (idx) async =>
                      FileImage(_myScores[idx]),
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
class HymnViewerPage extends StatefulWidget {
  final int   initialIndex;
  final int   totalCount;
  final Future<ImageProvider?> Function(int) getImageProvider;
  final String Function(int) labelBuilder;

  const HymnViewerPage({
    super.key,
    required this.initialIndex,
    required this.totalCount,
    required this.getImageProvider,
    required this.labelBuilder,
  });

  @override
  State<HymnViewerPage> createState() => _HymnViewerPageState();
}

class _HymnViewerPageState extends State<HymnViewerPage> {
  late PageController _pageCtrl;
  late int _curIdx;
  bool _showBars = true;
  // 이미지 캐시
  final Map<int, Uint8List?> _cache = {};

  @override
  void initState() {
    super.initState();
    _curIdx   = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    // 현재 + 앞뒤 이미지 미리 로드
    _preload(widget.initialIndex);
  }

  Future<void> _preload(int idx) async {
    for (int i = idx - 1; i <= idx + 1; i++) {
      if (i < 0 || i >= widget.totalCount) continue;
      if (_cache.containsKey(i)) continue;
      try {
        final provider = await widget.getImageProvider(i);
        if (provider is FileImage) {
          final bytes = await provider.file.readAsBytes();
          if (mounted) setState(() => _cache[i] = bytes);
        } else {
          if (mounted) setState(() => _cache[i] = null);
        }
      } catch (_) {
        if (mounted) setState(() => _cache[i] = null);
      }
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = Colors.black;
    final primary = Theme.of(context).colorScheme.primary;
    final div     = const Color(0xFF2C2C2E);

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: _showBars
          ? AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.labelBuilder(_curIdx),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showBars = !_showBars),
        child: PageView.builder(
          controller:    _pageCtrl,
          itemCount:     widget.totalCount,
          onPageChanged: (i) {
            setState(() => _curIdx = i);
            _preload(i);
          },
          itemBuilder: (_, index) {
            final bytes = _cache[index];
            // 아직 로드 안됨
            if (!_cache.containsKey(index)) {
              _preload(index);
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            // 파일 없음
            if (bytes == null) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_not_supported_rounded,
                      size: 64, color: Colors.white54),
                  const SizedBox(height: 12),
                  Text('\${index + 1}장 이미지 없음',
                      style: const TextStyle(color: Colors.white54)),
                ],
              ));
            }
            // 이미지 표시 (InteractiveViewer + Image.memory)
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Image.memory(
                  bytes,
                  fit:          BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded,
                        size: 64, color: Colors.white54),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _showBars
          ? Container(
        color: Colors.black.withOpacity(0.6),
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 12),
        child: SafeArea(top: false,
          child: Row(children: [
            IconButton(
              onPressed: _curIdx > 0
                  ? () => _pageCtrl.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut)
                  : null,
              icon: Icon(Icons.arrow_back_ios_rounded,
                  color: _curIdx > 0
                      ? Colors.white : Colors.white30),
            ),
            Expanded(child: GestureDetector(
              onTap: () => _showJumpDialog(context, primary),
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.music_note_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(widget.labelBuilder(_curIdx),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ]),
              )),
            )),
            IconButton(
              onPressed: _curIdx < widget.totalCount - 1
                  ? () => _pageCtrl.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut)
                  : null,
              icon: Icon(Icons.arrow_forward_ios_rounded,
                  color: _curIdx < widget.totalCount - 1
                      ? Colors.white : Colors.white30),
            ),
          ]),
        ),
      )
          : null,
    );
  }

  void _showJumpDialog(BuildContext context, Color primary) {
    final ctrl = TextEditingController(text: '${_curIdx + 1}');
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      title: const Text('장 번호로 이동',
          style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.bold, color: Colors.white)),
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
        TextButton(onPressed: () => Navigator.pop(context),
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
    ));
  }
}
