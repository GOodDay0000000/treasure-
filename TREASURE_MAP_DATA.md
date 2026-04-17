# 보물지도 데이터 강화 작업
> Claude Code에 전달할 지시서

---

## 작업 1. dictionary_page.dart 웹 에러 수정

DictEnrichService에서 kIsWeb 체크 추가:
```dart
import 'package:flutter/foundation.dart' show kIsWeb;

// getApplicationDocumentsDirectory 호출 전에:
if (kIsWeb) return; // 웹에서는 enrichment 비활성화
```

_buildEnrichBanner도 kIsWeb이면 null 반환:
```dart
if (kIsWeb) return const SizedBox.shrink();
```

---

## 작업 2. treasure_map_page.dart - 지역 데이터 완전 강화

MapRegion 클래스에 필드 추가:
```dart
class MapRegion {
  final String id;
  final String name;
  final String period;       // 시대
  final String desc;         // 설명
  final String story;        // 핵심 이야기 (게임 퀘스트처럼)
  final String reward;       // 이 지역 완독 보상 문구
  final List<String> bookKeys;
  final Offset position;
  final Color color;
  final String emoji;        // 지역 대표 이모지
}
```

_regions 전체 교체 (아래 데이터로):

```dart
final List<MapRegion> _regions = [

  // ── 구약 7개 지역 ──────────────────────────────────────────

  MapRegion(
    id: 'mesopotamia',
    name: '메소포타미아',
    period: 'BC 2000년경',
    desc: '에덴동산이 있던 곳, 아브라함의 고향 우르, 바벨탑의 땅',
    story: '🔱 항해자여! 이곳은 인류의 시작점이다.\n아브라함이 "가라"는 음성을 듣고 떠난 땅,\n욥이 극한의 고통 속에서도 하나님을 신뢰한 땅.\n창세기를 읽고 이 땅의 비밀을 밝혀라!',
    reward: '창조의 비밀을 얻었다! (+창세기, 욥기)',
    bookKeys: ['genesis', 'job'],
    position: const Offset(0.78, 0.28),
    color: const Color(0xFFC9A84C),
    emoji: '🌿',
  ),

  MapRegion(
    id: 'egypt',
    name: '이집트',
    period: 'BC 1876~1446년',
    desc: '요셉이 총리가 된 곳, 이스라엘의 400년 노예 생활, 10가지 재앙',
    story: '🔱 항해자여! 강력한 파라오의 제국이다.\n요셉이 노예에서 총리로, 모세가 왕자에서 목자로.\n하나님은 가장 낮은 곳에서 역사를 시작하신다.\n출애굽기를 읽고 자유의 항해를 시작하라!',
    reward: '자유의 땅을 점령했다! (+출애굽기, 레위기, 민수기)',
    bookKeys: ['exodus', 'leviticus', 'numbers'],
    position: const Offset(0.38, 0.68),
    color: const Color(0xFFC9A84C),
    emoji: '🏺',
  ),

  MapRegion(
    id: 'sinai',
    name: '시나이 광야',
    period: 'BC 1446~1406년',
    desc: '불타는 떨기나무, 십계명, 40년 광야 방랑의 땅',
    story: '🔱 항해자여! 광야는 훈련의 장이다.\n200만 명이 40년을 방랑한 이 땅에서\n하나님은 만나로 먹이고 구름기둥으로 인도하셨다.\n신명기를 읽고 광야의 지혜를 얻어라!',
    reward: '광야의 지혜를 얻었다! (+신명기)',
    bookKeys: ['deuteronomy'],
    position: const Offset(0.50, 0.72),
    color: const Color(0xFF7A90A4),
    emoji: '🔥',
  ),

  MapRegion(
    id: 'canaan',
    name: '가나안',
    period: 'BC 1406~1010년',
    desc: '젖과 꿀이 흐르는 약속의 땅, 여호수아의 정복, 사사들의 시대',
    story: '🔱 항해자여! 400년을 기다린 약속의 땅이다.\n여호수아가 여리고 성벽을 무너뜨리고,\n드보라가 전쟁을 이끌고, 룻이 사랑을 선택했다.\n이 땅의 이야기를 완성하라!',
    reward: '약속의 땅을 점령했다! (+여호수아, 사사기, 룻기)',
    bookKeys: ['joshua', 'judges', 'ruth'],
    position: const Offset(0.56, 0.50),
    color: const Color(0xFF7A90A4),
    emoji: '⚔️',
  ),

  MapRegion(
    id: 'jerusalem',
    name: '예루살렘',
    period: 'BC 1010~586년',
    desc: '다윗의 왕도, 솔로몬의 성전, 시편과 지혜서의 탄생지',
    story: '🔱 항해자여! 세상의 중심, 거룩한 성이다.\n다윗이 골리앗을 쓰러뜨리고 왕이 되었고,\n솔로몬이 성전을 세워 하나님의 영광이 임했다.\n예루살렘의 13권을 읽고 지혜의 보물을 얻어라!',
    reward: '왕국의 보물을 획득했다! (+13권)',
    bookKeys: ['1samuel', '2samuel', '1kings', '2kings',
               '1chronicles', '2chronicles', 'ezra', 'nehemiah',
               'esther', 'psalms', 'proverbs', 'ecclesiastes', 'songofsolomon'],
    position: const Offset(0.57, 0.53),
    color: const Color(0xFFC9A84C),
    emoji: '👑',
  ),

  MapRegion(
    id: 'babylon',
    name: '바벨론',
    period: 'BC 605~539년',
    desc: '포로기의 땅, 사자굴의 다니엘, 에스겔의 환상',
    story: '🔱 항해자여! 포로가 된 이스라엘의 눈물이다.\n예루살렘이 무너지고 백성이 끌려온 이 땅에서도\n하나님은 포기하지 않으셨다.\n다니엘처럼 믿음을 지켜라!',
    reward: '포로기의 비밀을 밝혔다! (+다니엘, 에스겔, 예레미야, 예레미야애가)',
    bookKeys: ['daniel', 'ezekiel', 'jeremiah', 'lamentations'],
    position: const Offset(0.80, 0.40),
    color: const Color(0xFF7A90A4),
    emoji: '🏛️',
  ),

  MapRegion(
    id: 'prophets',
    name: '선지자의 땅',
    period: 'BC 760~430년',
    desc: '이사야부터 말라기까지, 12소선지서의 활동 지역',
    story: '🔱 항해자여! 하나님의 음성이 메아리치는 땅이다.\n이사야는 오실 메시아를 예언하고,\n요나는 고래 뱃속에서 기도했다.\n13명의 선지자 이야기를 완성하라!',
    reward: '예언의 보물을 획득했다! (+이사야~말라기 13권)',
    bookKeys: ['isaiah', 'hosea', 'joel', 'amos', 'obadiah',
               'jonah', 'micah', 'nahum', 'habakkuk', 'zephaniah',
               'haggai', 'zechariah', 'malachi'],
    position: const Offset(0.59, 0.47),
    color: const Color(0xFF7A90A4),
    emoji: '📯',
  ),

  // ── 신약 8개 지역 ──────────────────────────────────────────

  MapRegion(
    id: 'galilee',
    name: '갈릴리',
    period: 'AD 4~30년',
    desc: '예수님이 자라신 나사렛, 12제자를 부르신 갈릴리 바다, 산상수훈',
    story: '🔱 항해자여! 구원의 항해가 시작된 땅이다.\n가난한 어부들이 "나를 따르라"는 말 한마디에\n모든 것을 버리고 일어났다.\n복음서 4권을 읽고 예수님의 발자취를 따라가라!',
    reward: '복음의 보물을 얻었다! (+마태, 마가, 누가, 요한)',
    bookKeys: ['matthew', 'mark', 'luke', 'john'],
    position: const Offset(0.59, 0.44),
    color: const Color(0xFFC9A84C),
    emoji: '✝️',
  ),

  MapRegion(
    id: 'jerusalem_nt',
    name: '예루살렘 (신약)',
    period: 'AD 30~70년',
    desc: '십자가와 부활, 오순절 성령강림, 초대교회의 시작',
    story: '🔱 항해자여! 역사가 바뀐 곳이다.\n예수님이 십자가에서 죽으시고 3일만에 부활하셨다.\n오순절 성령강림으로 교회가 시작되었다.\n사도행전을 읽고 성령의 항해를 시작하라!',
    reward: '부활의 비밀을 얻었다! (+사도행전)',
    bookKeys: ['acts'],
    position: const Offset(0.576, 0.537),
    color: const Color(0xFFC9A84C),
    emoji: '🕊️',
  ),

  MapRegion(
    id: 'asia_minor',
    name: '소아시아',
    period: 'AD 47~96년',
    desc: '바울의 선교 거점, 에베소·골로새·갈라디아, 요한계시록 일곱 교회',
    story: '🔱 항해자여! 복음이 세계로 퍼진 땅이다.\n바울이 1~3차 선교여행을 하며 교회를 세웠고,\n요한이 일곱 교회에 마지막 경고를 보냈다.\n소아시아의 서신들을 읽고 항해를 넓혀라!',
    reward: '선교의 보물을 획득했다! (+에베소, 갈라디아, 골로새, 빌립보)',
    bookKeys: ['ephesians', 'galatians', 'colossians', 'philippians'],
    position: const Offset(0.50, 0.22),
    color: const Color(0xFF7A90A4),
    emoji: '⛪',
  ),

  MapRegion(
    id: 'corinth',
    name: '고린도',
    period: 'AD 50~52년',
    desc: '바울이 18개월 머문 그리스 항구 도시, 두 편지의 수신지',
    story: '🔱 항해자여! 혼란 속에서도 사랑이 빛난 곳이다.\n화려한 항구 도시 고린도에서 교회가 분쟁했지만,\n바울은 "사랑은 오래 참고..." 를 가르쳤다.\n고린도서를 읽고 사랑의 보물을 얻어라!',
    reward: '사랑의 보물을 얻었다! (+고린도전서, 고린도후서)',
    bookKeys: ['1corinthians', '2corinthians'],
    position: const Offset(0.33, 0.28),
    color: const Color(0xFF7A90A4),
    emoji: '💌',
  ),

  MapRegion(
    id: 'rome',
    name: '로마',
    period: 'AD 57~68년',
    desc: '바울의 최종 목적지이자 순교지, 세계 복음화의 발판',
    story: '🔱 항해자여! 제국의 심장부다.\n바울은 죄수로 끌려왔지만 오히려 복음을 전했다.\n"복음은 모든 믿는 자에게 구원을 주시는 하나님의 능력"\n로마서를 읽고 최고의 보물을 발견하라!',
    reward: '복음의 핵심을 발견했다! (+로마서, 목회서신)',
    bookKeys: ['romans', '1timothy', '2timothy', 'titus', 'philemon'],
    position: const Offset(0.14, 0.18),
    color: const Color(0xFF7A90A4),
    emoji: '🏛️',
  ),

  MapRegion(
    id: 'mediterranean',
    name: '지중해 항로',
    period: 'AD 47~60년',
    desc: '바울의 3차 선교여행 항로, 멜리데 난파, 로마까지의 항해',
    story: '🔱 항해자여! 이것이 진짜 항해다!\n바울은 폭풍과 난파를 겪으면서도 복음을 포기하지 않았다.\n죄수로 배를 타고도 모든 선원을 살려냈다.\n사도행전의 항해 이야기를 완성하라!',
    reward: '항해자의 용기를 얻었다! (+사도행전 27-28장)',
    bookKeys: ['acts'],
    position: const Offset(0.28, 0.32),
    color: const Color(0xFF7A90A4),
    emoji: '⛵',
  ),

  MapRegion(
    id: 'epistles',
    name: '서신서 지역',
    period: 'AD 49~96년',
    desc: '데살로니가·히브리·베드로·요한·야고보·유다 서신이 전달된 곳',
    story: '🔱 항해자여! 믿음의 편지들이 날아간 땅이다.\n박해받는 성도들에게 베드로가 위로를 보내고,\n요한이 "서로 사랑하라"고 권면했다.\n일반 서신 10권을 읽고 지혜를 모아라!',
    reward: '믿음의 편지를 완성했다! (+히브리서~유다서 10권)',
    bookKeys: ['1thessalonians', '2thessalonians', 'hebrews',
               'james', '1peter', '2peter', '1john', '2john', '3john', 'jude'],
    position: const Offset(0.42, 0.20),
    color: const Color(0xFF7A90A4),
    emoji: '📜',
  ),

  MapRegion(
    id: 'patmos',
    name: '밧모섬',
    period: 'AD 95년',
    desc: '사도 요한이 유배된 작은 섬, 요한계시록 기록지',
    story: '🔱 항해자여! 마지막 보물이 숨겨진 섬이다.\n노인이 된 요한이 유배된 이 작은 섬에서\n하늘의 문이 열리고 최후의 계시가 임했다.\n요한계시록을 읽고 최후의 보물을 열어라!',
    reward: '🏆 전설의 항해자! 66권 완독! (+요한계시록)',
    bookKeys: ['revelation'],
    position: const Offset(0.38, 0.30),
    color: const Color(0xFFC9A84C),
    emoji: '🏝️',
  ),
];
```

---

## 작업 3. 지역 상세 패널 UI 강화

_buildDetailPanel에서 story와 reward 표시:

```dart
// desc 아래에 story 추가
if (region.story.isNotEmpty) ...[
  const SizedBox(height: 12),
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isDark 
          ? const Color(0xFFC9A84C).withOpacity(0.08)
          : Colors.amber.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: const Color(0xFFC9A84C).withOpacity(0.2)),
    ),
    child: Text(
      region.story,
      style: TextStyle(
        fontSize: 12,
        color: isDark ? const Color(0xFFE8E3D8) : Colors.brown.shade700,
        height: 1.6,
      ),
    ),
  ),
],

// 점령 완료 시 reward 표시
if (unlocked && region.reward.isNotEmpty) ...[
  const SizedBox(height: 8),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFC9A84C).withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      const Text('✨ ', style: TextStyle(fontSize: 14)),
      Expanded(child: Text(
        region.reward,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFC9A84C),
          fontWeight: FontWeight.w600,
        ),
      )),
    ]),
  ),
],
```

---

## 작업 4. 전체 진행 상황 표시 강화

_buildProgressBadge에 구약/신약 분리 표시:
```dart
// 구약 진행률
final otBooks = ['genesis','exodus',...]; // 39권
final ntBooks = ['matthew','mark',...];   // 27권
final otRead = _readBooks.intersection(otBooks.toSet()).length;
final ntRead = _readBooks.intersection(ntBooks.toSet()).length;

// 두 개의 progress bar로 분리 표시
Text('구약 $otRead/39'),
LinearProgressIndicator(value: otRead/39, ...),
Text('신약 $ntRead/27'),  
LinearProgressIndicator(value: ntRead/27, ...),
```

---

## 주의사항
- MapRegion 클래스에 story, reward, emoji 필드 추가 필요
- 기존 position 좌표는 유지 (지도 이미지 기준)
- flutter analyze 에러 없는지 확인
