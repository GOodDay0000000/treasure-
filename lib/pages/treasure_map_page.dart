// lib/pages/treasure_map_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/map_regions.dart';
import '../l10n/app_strings.dart';
import '../services/experience_service.dart';
import 'bible_read_page.dart';
import 'book_select_page.dart';

// 지역 데이터는 lib/data/map_regions.dart 에서 공용으로 제공
final List<MapRegion> _regions = bibleMapRegions;


// ── TreasureMapPage ───────────────────────────────────────────
class TreasureMapPage extends StatefulWidget {
  const TreasureMapPage({super.key});

  @override
  State<TreasureMapPage> createState() => _TreasureMapPageState();
}

class _TreasureMapPageState extends State<TreasureMapPage>
    with TickerProviderStateMixin {

  final TransformationController _transformCtrl = TransformationController();
  MapRegion? _selectedRegion;
  late AnimationController _fogCtrl;
  late AnimationController _pulseCtrl;

  // 읽은 책 — ExperienceService에서 로드 (한 장이라도 읽은 책)
  Set<String> _readBooks = {};

  @override
  void initState() {
    super.initState();
    _fogCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadReadBooks();
  }

  Future<void> _loadReadBooks() async {
    final books = await ExperienceService.getReadBooks();
    if (!mounted) return;
    setState(() => _readBooks = books);
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _fogCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool _isUnlocked(MapRegion r) =>
      r.bookKeys.any((k) => _readBooks.contains(k));

  String _bookName(String key) =>
      BookSelectPage.allBooks.firstWhere(
        (b) => b['key'] == key,
        orElse: () => {'name': key},
      )['name'] as String;

  int get _unlockedCount => _regions.where(_isUnlocked).length;
  int get _totalBooks => 66;
  int get _readBooksCount => _readBooks.length;

  void _onRegionTap(MapRegion region) {
    HapticFeedback.mediumImpact();
    setState(() => _selectedRegion = region);
    _fogCtrl.forward(from: 0);
  }

  Future<void> _goReadFirst(MapRegion region) async {
    if (region.bookKeys.isEmpty) return;
    final bookKey = region.bookKeys.first;
    final bookName = BibleBookNames.get(bookKey, AppLocale.current);
    setState(() => _selectedRegion = null);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BibleReadPage(
          version: 'krv',
          bookKey: bookKey,
          bookName: bookName,
          chapter: 1,
          totalChapters: BookSelectPage.getChapterCount(bookKey),
        ),
      ),
    );
    // 돌아오면 읽은 책 갱신 (장을 읽었을 수 있음)
    await _loadReadBooks();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // ignore: unused_local_variable
    final primary = Theme.of(context).colorScheme.primary;
    final scaffoldBg = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // ── 지도 메인 ───────────────────────────────────────
          GestureDetector(
            onTapUp: (details) {
              // 빈 곳 탭하면 선택 해제
              setState(() => _selectedRegion = null);
            },
            child: InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 0.8,
              maxScale: 4.0,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Stack(
                      children: [
                        // 지도 이미지
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/bible_map.png',
                            fit: BoxFit.cover,
                          ),
                        ),

                        // 안개 레이어 (미탐험 지역)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _FogPainter(
                              regions: _regions,
                              readBooks: _readBooks,
                              mapSize: Size(w, h),
                              isDark: isDark,
                            ),
                          ),
                        ),

                        // 지역 마커들
                        ..._regions.map((r) {
                          final unlocked = _isUnlocked(r);
                          final selected = _selectedRegion?.id == r.id;
                          final x = r.position.dx * w;
                          final y = r.position.dy * h;

                          return Positioned(
                            left: x - 24,
                            top: y - 24,
                            child: GestureDetector(
                              onTap: () => _onRegionTap(r),
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (unlocked)
                                      AnimatedBuilder(
                                        animation: _pulseCtrl,
                                        builder: (_, __) => Container(
                                          width: 32 + _pulseCtrl.value * 8,
                                          height: 32 + _pulseCtrl.value * 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFC9A84C)
                                                .withOpacity(0.15 * (1 - _pulseCtrl.value)),
                                          ),
                                        ),
                                      ),
                                    unlocked
                                        ? Container(
                                            width: selected ? 22 : 16,
                                            height: selected ? 22 : 16,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFFC9A84C),
                                              border: Border.all(
                                                color: const Color(0xFFE8C85A),
                                                width: selected ? 2.5 : 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFC9A84C)
                                                      .withOpacity(0.5),
                                                  blurRadius: selected ? 12 : 6,
                                                ),
                                              ],
                                            ),
                                          )
                                        // 미점령 = 희미한 닻 아이콘
                                        : Opacity(
                                            opacity: 0.3,
                                            child: Icon(
                                              Icons.anchor_rounded,
                                              size: selected ? 22 : 18,
                                              color: isDark
                                                  ? const Color(0xFFE8E3D8)
                                                  : const Color(0xFF1A1A1A),
                                            ),
                                          ),
                                    // 지역명
                                    Positioned(
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          r.name,
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: unlocked
                                                ? const Color(0xFFC9A84C)
                                                : const Color(0xFF3A5068),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // ── 상단 헤더 ─────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? Colors.black : Colors.white)
                        .withOpacity(isDark ? 0.8 : 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 12, 20, 24),
              child: Row(
                children: [
                  const Icon(Icons.anchor_rounded,
                      color: Color(0xFFC9A84C), size: 20),
                  const SizedBox(width: 8),
                  const Text('보물지도',
                      style: TextStyle(
                          color: Color(0xFFC9A84C),
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white)
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFC9A84C).withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFFC9A84C), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$_readBooksCount / $_totalBooks권',
                        style: const TextStyle(
                            color: Color(0xFFC9A84C),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // ── 하단 지역 상세 패널 ───────────────────────────
          if (_selectedRegion != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildDetailPanel(_selectedRegion!),
            ),

          // ── 미니맵 (우측 하단) ────────────────────────────
          if (_selectedRegion == null)
            Positioned(
              bottom: 20, right: 16,
              child: _buildMiniMap(),
            ),

          // ── 진행률 (하단 좌측) ────────────────────────────
          if (_selectedRegion == null)
            Positioned(
              bottom: 20, left: 16,
              child: _buildProgressBadge(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(MapRegion region) {
    final unlocked = _isUnlocked(region);
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final gold     = const Color(0xFFC9A84C);
    final panelBg  = (isDark ? const Color(0xFF0D1B2A) : Colors.white).withOpacity(0.97);
    final panelBorder = isDark ? const Color(0xFF2C3E50) : const Color(0xFFE0E6ED);
    final textColor   = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final subColor    = isDark ? const Color(0xFF7A90A4) : Colors.grey.shade600;
    final chipBg      = isDark ? const Color(0xFF1B2D3F) : const Color(0xFFF2F4F7);
    final lockedTextColor = isDark ? const Color(0xFF3A5068) : Colors.grey.shade500;

    return AnimatedBuilder(
      animation: _fogCtrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, 200 * (1 - _fogCtrl.value)),
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked ? gold.withOpacity(0.4) : panelBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
              blurRadius: 16, offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked ? gold.withOpacity(0.15) : chipBg,
                  border: Border.all(
                    color: unlocked ? gold.withOpacity(0.4) : panelBorder,
                  ),
                ),
                child: unlocked && region.emoji.isNotEmpty
                    ? Center(child: Text(region.emoji,
                        style: const TextStyle(fontSize: 20)))
                    : Icon(
                        unlocked ? Icons.location_on_rounded : Icons.lock_rounded,
                        color: unlocked ? gold : lockedTextColor,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(region.name,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: unlocked ? gold : textColor)),
                Text(region.period,
                    style: TextStyle(fontSize: 12, color: subColor)),
              ]),
              const Spacer(),
              if (unlocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gold.withOpacity(0.3)),
                  ),
                  child: Text('점령 ✓',
                      style: TextStyle(fontSize: 11, color: gold)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: panelBorder),
                  ),
                  child: Text('미탐험',
                      style: TextStyle(fontSize: 11, color: lockedTextColor)),
                ),
            ]),
            const SizedBox(height: 12),
            Text(region.desc,
                style: TextStyle(
                    fontSize: 13, color: textColor, height: 1.5)),
            // 퀘스트 스토리
            if (region.story.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? gold.withOpacity(0.08)
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: gold.withOpacity(0.2)),
                ),
                child: Text(
                  region.story,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? textColor : Colors.brown.shade700,
                    height: 1.6,
                  ),
                ),
              ),
            ],
            // 완독 보상
            if (unlocked && region.reward.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Text('✨ ', style: TextStyle(fontSize: 14)),
                  Expanded(child: Text(
                    region.reward,
                    style: TextStyle(
                      fontSize: 11,
                      color: gold,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            // 관련 성경책
            Wrap(spacing: 6, runSpacing: 6,
              children: region.bookKeys.map((key) {
                final bookName = _bookName(key);
                final read = _readBooks.contains(key);
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedRegion = null);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: read ? gold.withOpacity(0.15) : chipBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: read ? gold.withOpacity(0.4) : panelBorder,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        read ? Icons.check_rounded : Icons.book_rounded,
                        size: 11,
                        color: read ? gold : lockedTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(bookName,
                          style: TextStyle(
                              fontSize: 11,
                              color: read ? gold : lockedTextColor)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // 이 지역 주석 보기 (준비중)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('주석 기능 준비 중이에요'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
                icon: Icon(Icons.menu_book_rounded, size: 14, color: subColor),
                label: Text('이 지역 주석 보기',
                    style: TextStyle(fontSize: 12, color: subColor)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            if (!unlocked) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _goReadFirst(region),
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: Text('${_bookName(region.bookKeys.first)} 읽으러 가기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: const Color(0xFF0D1B2A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMap() {
    return Container(
      width: 100, height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFFC9A84C).withOpacity(0.3)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 8,
        )],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Image.asset('assets/images/bible_map.png',
                width: 100, height: 70, fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.3)),
            // 점령 지역 표시
            ..._regions.where(_isUnlocked).map((r) => Positioned(
              left: r.position.dx * 100 - 3,
              top: r.position.dy * 70 - 3,
              child: Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFC9A84C),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBadge() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold   = const Color(0xFFC9A84C);
    final badgeBg = (isDark ? const Color(0xFF0D1B2A) : Colors.white).withOpacity(0.92);
    final subColor = isDark ? const Color(0xFF7A90A4) : Colors.grey.shade600;
    final trackBg  = isDark ? const Color(0xFF1B2D3F) : const Color(0xFFE5E5EA);

    final otKeys = BookSelectPage.oldTestament.map((b) => b['key'] as String).toSet();
    final ntKeys = BookSelectPage.newTestament.map((b) => b['key'] as String).toSet();
    final otRead = _readBooks.where(otKeys.contains).length;
    final ntRead = _readBooks.where(ntKeys.contains).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold.withOpacity(0.3)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
          blurRadius: 6,
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.local_fire_department_rounded, color: gold, size: 14),
            const SizedBox(width: 4),
            Text('항해 진행률',
                style: TextStyle(fontSize: 11, color: subColor)),
          ]),
          const SizedBox(height: 6),
          _MiniProgress(
            label: '구약', read: otRead, total: 39,
            gold: gold, trackBg: trackBg, subColor: subColor,
          ),
          const SizedBox(height: 5),
          _MiniProgress(
            label: '신약', read: ntRead, total: 27,
            gold: gold, trackBg: trackBg, subColor: subColor,
          ),
          const SizedBox(height: 5),
          Text('총 $_readBooksCount / $_totalBooks권 '
              '(${(_readBooksCount / _totalBooks * 100).toInt()}%)',
              style: TextStyle(
                  fontSize: 10, color: gold, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── 구약/신약 미니 프로그레스 ───────────────────────────────
class _MiniProgress extends StatelessWidget {
  final String label;
  final int read;
  final int total;
  final Color gold, trackBg, subColor;

  const _MiniProgress({
    required this.label,
    required this.read,
    required this.total,
    required this.gold,
    required this.trackBg,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : read / total;
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: subColor,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$read/$total',
                style: TextStyle(fontSize: 10, color: gold)),
          ]),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: trackBg,
              valueColor: AlwaysStoppedAnimation(gold),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 안개 페인터 ───────────────────────────────────────────────
class _FogPainter extends CustomPainter {
  final List<MapRegion> regions;
  final Set<String> readBooks;
  final Size mapSize;
  final bool isDark;

  _FogPainter({
    required this.regions,
    required this.readBooks,
    required this.mapSize,
    required this.isDark,
  });

  bool _isUnlocked(MapRegion r) =>
      r.bookKeys.any((k) => readBooks.contains(k));

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(bounds, Paint());

    // 다크: 밤바다 짙은 안개 0.50 / 라이트: 옅은 푸른 안개 0.60
    final fogColor = isDark
        ? const Color(0xFF0A1218).withOpacity(0.50)
        : const Color(0xFFE8EFF5).withOpacity(0.60);
    canvas.drawRect(bounds, Paint()..color = fogColor);

    // 점령 지역은 안개를 뚫어 밝게
    for (final region in regions) {
      if (!_isUnlocked(region)) continue;
      final cx = region.position.dx * size.width;
      final cy = region.position.dy * size.height;
      const radius = 90.0;

      final shader = const RadialGradient(
        colors: [
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..shader = shader
          ..blendMode = BlendMode.dstOut,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FogPainter old) =>
      old.readBooks != readBooks || old.isDark != isDark;
}
