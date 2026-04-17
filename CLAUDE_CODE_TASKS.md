# Claude Code 작업 지시서
> 아래 작업들을 순서대로 처리해줘

---

## 1. bible_read_page.dart - 절 탭 on/off 버그 수정

- 절 선택 액션바 on/off 토글 버튼 추가 (AppBar 또는 하단 바에)
- 상태를 SharedPreferences로 저장 ('verse_tap_enabled' 키)
- 절 탭 off 상태에서 절을 터치해도 아무 반응 없어야 함 (빨간 화면 에러 수정)
- 폰트 확대와 PageView 슬라이드 연동 에러 수정
- pinch zoom 완전 제거 (GestureDetector의 onScaleUpdate 등 관련 코드 전부)

---

## 2. book_select_page.dart - 바로가기에 찬송가 추가

allShortcuts 맵에 추가:
```dart
'hymn': {'label': '찬송가', 'icon': Icons.music_note_rounded, 'available': true},
```

기본 shortcuts 리스트에 'hymn' 포함:
```dart
?? ['search', 'memo', 'bookmark', 'hymn']
```

탭 처리:
```dart
case 'hymn':
  Navigator.push(context, MaterialPageRoute(builder: (_) => const HymnPage()));
  break;
```

HymnPage import 추가 필요

---

## 3. hymn_page.dart - 뒤로가기 버튼 추가

AppBar에 leading 버튼 추가:
```dart
leading: IconButton(
  icon: const Icon(Icons.arrow_back_ios_rounded),
  onPressed: () => Navigator.pop(context),
),
```

또는 automaticallyImplyLeading: false 제거

---

## 4. treasure_map_page.dart - 다크/라이트 모드 지원 + 66권 매핑

### 4-1. 다크/라이트 모드
현재 하드코딩된 색상들을 Theme 기반으로:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final bgColor = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);
final cardColor = isDark ? const Color(0xFF1B2D3F) : Colors.white;
final textColor = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
final subColor = isDark ? const Color(0xFF7A90A4) : Colors.grey.shade600;
```

단, 지도 이미지 위 마커/안개는 항상 다크 톤 유지 (지도가 어두운 색이라)

### 4-2. 성경 66권 전체 지역 매핑
_regions 리스트를 아래로 교체:

```dart
final List<MapRegion> _regions = [
  // ── 구약 ──────────────────────────────────────
  MapRegion(
    id: 'mesopotamia', name: '메소포타미아', period: 'BC 2000~',
    desc: '에덴동산, 아브라함의 고향 우르, 바벨탑이 있던 인류 문명의 발원지',
    bookKeys: ['genesis', 'job'],
    position: const Offset(0.78, 0.28), color: const Color(0xFFC9A84C),
  ),
  MapRegion(
    id: 'egypt', name: '이집트', period: 'BC 1876~1446',
    desc: '요셉이 총리가 된 곳, 이스라엘 400년 노예 생활, 모세의 출애굽',
    bookKeys: ['exodus', 'leviticus', 'numbers'],
    position: const Offset(0.38, 0.68), color: const Color(0xFFC9A84C),
  ),
  MapRegion(
    id: 'sinai', name: '시나이 광야', period: 'BC 1446~1406',
    desc: '모세가 십계명을 받은 시나이산, 이스라엘 40년 광야 방랑',
    bookKeys: ['deuteronomy'],
    position: const Offset(0.50, 0.72), color: const Color(0xFF7A90A4),
  ),
  MapRegion(
    id: 'canaan', name: '가나안', period: 'BC 1406~',
    desc: '하나님이 약속하신 땅, 여호수아의 정복 전쟁, 사사들의 시대, 룻의 이야기',
    bookKeys: ['joshua', 'judges', 'ruth'],
    position: const Offset(0.56, 0.50), color: const Color(0xFF7A90A4),
  ),
  MapRegion(
    id: 'jerusalem', name: '예루살렘', period: 'BC 1010~586',
    desc: '다윗의 왕도, 솔로몬의 성전, 이스라엘/유다 왕국, 시편과 지혜문학',
    bookKeys: ['1samuel', '2samuel', '1kings', '2kings',
               '1chronicles', '2chronicles', 'ezra', 'nehemiah',
               'esther', 'psalms', 'proverbs', 'ecclesiastes', 'songofsolomon'],
    position: const Offset(0.57, 0.53), color: const Color(0xFFC9A84C),
  ),
  MapRegion(
    id: 'babylon', name: '바벨론', period: 'BC 605~539',
    desc: '유다 왕국 멸망 후 포로기, 다니엘·에스겔·예레미야의 활동지',
    bookKeys: ['daniel', 'ezekiel', 'jeremiah', 'lamentations'],
    position: const Offset(0.80, 0.40), color: const Color(0xFF7A90A4),
  ),
  MapRegion(
    id: 'prophets', name: '선지자의 땅', period: 'BC 760~430',
    desc: '이사야부터 말라기까지, 이스라엘/유다 전역에서 활동한 선지자들',
    bookKeys: ['isaiah', 'hosea', 'joel', 'amos', 'obadiah',
               'jonah', 'micah', 'nahum', 'habakkuk', 'zephaniah',
               'haggai', 'zechariah', 'malachi'],
    position: const Offset(0.59, 0.47), color: const Color(0xFF7A90A4),
  ),

  // ── 신약 ──────────────────────────────────────
  MapRegion(
    id: 'galilee', name: '갈릴리', period: 'AD 4~30',
    desc: '예수님이 자라신 나사렛, 12제자를 부르신 갈릴리 바다, 산상수훈',
    bookKeys: ['matthew', 'mark', 'luke', 'john'],
    position: const Offset(0.59, 0.44), color: const Color(0xFFC9A84C),
  ),
  MapRegion(
    id: 'jerusalem_nt', name: '예루살렘 (신약)', period: 'AD 30~70',
    desc: '예수님의 십자가와 부활, 오순절 성령강림, 초대교회 시작',
    bookKeys: ['acts'],
    position: const Offset(0.576, 0.537), color: const Color(0xFFC9A84C),
  ),
  MapRegion(
    id: 'asia_minor', name: '소아시아', period: 'AD 47~68',
    desc: '바울의 1~3차 선교여행, 에베소·갈라디아·골로새·빌립보, 일곱 교회',
    bookKeys: ['ephesians', 'galatians', 'colossians', 'philippians'],
    position: const Offset(0.50, 0.22), color: const Color(0xFF7A90A4),
  ),
  MapRegion(
    id: 'corinth', name: '고린도', period: 'AD 50~52',
    desc: '바울이 18개월 머문 그리스 도시, 고린도 교회에 두 편지를 보냄',
    bookKeys: ['1corinthians', '2corinthians'],
    position: const Offset(0.33, 0.28), color: const Color(0xFF7A90A4),
  ),
  MapRegion(
    id: 'rome', name: '로마', period: 'AD 57~68',
    desc: '바울의 최종 목적지이자 순교지, 디모데·디도·빌레몬에게 보낸 서신',
    bookKeys: ['romans', '1timothy', '2timothy', 'titus', 'philemon'],
    position: const Offset(0.14, 0.18), color: const Color(0xFF7A90A4),
  ),
  MapRegion(
    id: 'mediterranean', name: '지중해 항로', period: 'AD 47~60',
    desc: '바울의 선교 항해 루트, 멜리데 섬 난파 사건, 로마까지의 여정',
    bookKeys: ['acts'],
    position: const Offset(0.28, 0.32), color: const Color(0xFF7A90A4),
  ),
  MapRegion(
    id: 'epistles', name: '서신서 지역', period: 'AD 49~96',
    desc: '데살로니가·히브리·야고보·베드로·요한·유다 서신이 쓰여진 각지',
    bookKeys: ['1thessalonians', '2thessalonians', 'hebrews',
               'james', '1peter', '2peter', '1john', '2john', '3john', 'jude'],
    position: const Offset(0.42, 0.20), color: const Color(0xFF7A90A4),
  ),
  MapRegion(
    id: 'patmos', name: '밧모섬', period: 'AD 95',
    desc: '사도 요한이 유배된 섬, 요한계시록 기록. 소아시아 근처 에게해',
    bookKeys: ['revelation'],
    position: const Offset(0.38, 0.30), color: const Color(0xFF7A90A4),
  ),
];
```

---

## 5. dictionary_page.dart - 원어 표기 추가

### 5-1. 히브리어/헬라어 데이터 다운로드 방법

openscriptures/strongs GitHub에서 JSON 데이터 다운로드:
- 히브리어: https://raw.githubusercontent.com/openscriptures/strongs/master/hebrew/strongs-hebrew-dictionary.json
- 헬라어: https://raw.githubusercontent.com/openscriptures/strongs/master/greek/strongs-greek-dictionary.json

앱 첫 실행 시 또는 설정에서 다운로드하는 방식으로 구현

### 5-2. DictionaryEntry 모델에 원어 필드 추가

```dart
class DictionaryEntry {
  final int id;
  final String? sub;
  final String original;      // 번호/한글 의미
  final String pronunciation; // 발음
  final String meaning;       // 한글 의미
  final String? hebrew;       // 히브리어 원문 (예: אֱלֹהִים)
  final String? greek;        // 헬라어 원문 (예: θεός)
  final String? transliteration; // 음역 (예: Elohim)
}
```

### 5-3. 엔트리 카드에 원어 표시

_EntryCard 위젯에 원어 문자 크게 표시:
```dart
// 원어가 있으면 카드 상단에 크게 표시
if (entry.hebrew != null || entry.greek != null)
  Text(
    entry.hebrew ?? entry.greek ?? '',
    style: TextStyle(
      fontSize: 28,
      color: primary,
      fontWeight: FontWeight.w300,
    ),
  ),
```

---

## 6. 보물지도 - 주석 연계 준비 (기반만)

treasure_map_page.dart 지역 상세 패널에
"이 지역 주석 보기" 버튼 추가 (현재는 준비중 표시):
```dart
TextButton.icon(
  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('주석 기능 준비 중이에요'))),
  icon: const Icon(Icons.menu_book_rounded, size: 14),
  label: const Text('이 지역 주석 보기'),
),
```

---

## 작업 우선순위
1번 → 2번 → 3번 → 4번 → 5번 → 6번 순서로 처리해줘.
각 작업 완료 후 flutter analyze로 에러 없는지 확인해줘.
