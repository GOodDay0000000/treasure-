// lib/pages/ccm_page.dart
//
// CCM 플레이리스트 — 4 카테고리(찬양/경배/기도/묵상) · 유튜브 연결
// 정적 큐레이션 (한국 CCM 인기곡 중 공개 채널 대표곡)

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CcmTrack {
  final String title;
  final String artist;
  final String youtubeUrl;
  const CcmTrack({
    required this.title,
    required this.artist,
    required this.youtubeUrl,
  });
}

class CcmCategory {
  final String id;
  final String name;
  final String emoji;
  final List<CcmTrack> tracks;
  const CcmCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tracks,
  });

  static const List<CcmCategory> all = [
    // ── 찬양 ─────────────────────────────────────────
    CcmCategory(id: 'praise', name: '찬양', emoji: '🎵', tracks: [
      CcmTrack(
          title: '주 품에', artist: '마커스워십',
          youtubeUrl: 'https://www.youtube.com/results?search_query=마커스+주+품에'),
      CcmTrack(
          title: '주 은혜임을', artist: '어노인팅',
          youtubeUrl: 'https://www.youtube.com/results?search_query=어노인팅+주+은혜임을'),
      CcmTrack(
          title: '당신은 사랑받기 위해 태어난 사람',
          artist: '이민섭',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=당신은+사랑받기+위해+태어난+사람'),
      CcmTrack(
          title: '부흥', artist: '고형원',
          youtubeUrl: 'https://www.youtube.com/results?search_query=부흥+고형원'),
      CcmTrack(
          title: '은혜', artist: '손경민',
          youtubeUrl: 'https://www.youtube.com/results?search_query=손경민+은혜'),
    ]),
    // ── 경배 ─────────────────────────────────────────
    CcmCategory(id: 'worship', name: '경배', emoji: '🙌', tracks: [
      CcmTrack(
          title: '주께 가오니', artist: '어노인팅',
          youtubeUrl: 'https://www.youtube.com/results?search_query=어노인팅+주께+가오니'),
      CcmTrack(
          title: '주님의 은혜로', artist: '위러브',
          youtubeUrl: 'https://www.youtube.com/results?search_query=위러브+주님의+은혜로'),
      CcmTrack(
          title: '오 거룩하신 주님', artist: 'J-US',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=j-us+오+거룩하신+주님'),
      CcmTrack(
          title: '거룩하신 주님께', artist: '어노인팅',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=어노인팅+거룩하신+주님께'),
      CcmTrack(
          title: '주님 다시 오실 때까지', artist: '마커스워십',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=마커스+주님+다시+오실+때까지'),
    ]),
    // ── 기도 ─────────────────────────────────────────
    CcmCategory(id: 'prayer', name: '기도', emoji: '🙏', tracks: [
      CcmTrack(
          title: '나의 기도하는 것보다', artist: '어노인팅',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=어노인팅+나의+기도하는+것보다'),
      CcmTrack(
          title: '나를 향한 주의 사랑', artist: '심종호',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=심종호+나를+향한+주의+사랑'),
      CcmTrack(
          title: '주 예수의 이름', artist: '소진영',
          youtubeUrl: 'https://www.youtube.com/results?search_query=소진영+주+예수의+이름'),
      CcmTrack(
          title: '주만 바라볼지라', artist: '박성호',
          youtubeUrl: 'https://www.youtube.com/results?search_query=박성호+주만+바라볼지라'),
    ]),
    // ── 묵상 ─────────────────────────────────────────
    CcmCategory(id: 'meditation', name: '묵상', emoji: '🕊️', tracks: [
      CcmTrack(
          title: '주 사랑 안에 나 안식하네', artist: '위러브',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=위러브+주+사랑+안에+나+안식하네'),
      CcmTrack(
          title: '잠잠하라', artist: '장재원',
          youtubeUrl: 'https://www.youtube.com/results?search_query=장재원+잠잠하라'),
      CcmTrack(
          title: '고요함으로 오시네', artist: '어노인팅',
          youtubeUrl: 'https://www.youtube.com/results?search_query=어노인팅+고요함'),
      CcmTrack(
          title: '주의 임재', artist: '그리심',
          youtubeUrl: 'https://www.youtube.com/results?search_query=그리심+주의+임재'),
    ]),
  ];
}

class CcmPage extends StatefulWidget {
  const CcmPage({super.key});

  @override
  State<CcmPage> createState() => _CcmPageState();
}

class _CcmPageState extends State<CcmPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: CcmCategory.all.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _open(CcmTrack t) async {
    final uri = Uri.parse(t.youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('유튜브 앱을 열 수 없어요'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);
    final primary = Theme.of(context).colorScheme.primary;
    const gold = Color(0xFFC9A84C);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('CCM 플레이리스트',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: gold,
          labelColor: gold,
          unselectedLabelColor:
              isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          tabs: CcmCategory.all
              .map((c) => Tab(text: '${c.emoji} ${c.name}'))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: CcmCategory.all
            .map((c) => _CategoryList(
                  category: c,
                  onTapTrack: _open,
                  isDark: isDark,
                ))
            .toList(),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final CcmCategory category;
  final void Function(CcmTrack) onTapTrack;
  final bool isDark;
  const _CategoryList({
    required this.category,
    required this.onTapTrack,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    const gold = Color(0xFFC9A84C);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: category.tracks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = category.tracks[i];
        return GestureDetector(
          onTap: () => onTapTrack(t),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: gold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(t.artist,
                        style: TextStyle(fontSize: 12, color: sub)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 16, color: sub),
            ]),
          ),
        );
      },
    );
  }
}
