// lib/data/bible_timeline.dart
//
// 성경 연대기 이벤트.
// 지역(region) id는 [treasure_map_page.dart]의 MapRegion.id와 일치해야 함.
// 연도는 서력 기준 (BC는 음수, AD는 양수).

class BibleEvent {
  final int year;
  final String event;
  final String region;      // MapRegion.id 와 매칭
  final List<String> books; // BookSelectPage.allBooks 의 key와 매칭
  final String desc;

  const BibleEvent({
    required this.year,
    required this.event,
    required this.region,
    required this.books,
    required this.desc,
  });

  bool get isBC => year < 0;
  String get displayYear => isBC ? 'BC ${-year}' : 'AD $year';
}

// 날짜는 개신교 보수 진영에서 널리 사용되는 추정치(Ussher/MacArthur 등) 기반.
// 학파에 따라 ±수백 년 차이 있을 수 있음.
const List<BibleEvent> bibleTimeline = [

  // ── 원역사 & 족장 시대 ─────────────────────────────────
  BibleEvent(year: -2166, event: '아브라함 출생', region: 'mesopotamia',
      books: ['genesis'],
      desc: '갈대아 우르에서 데라의 아들로 태어남. 믿음의 조상이 될 부르심을 받음.'),
  BibleEvent(year: -2091, event: '아브라함, 가나안 이주', region: 'canaan',
      books: ['genesis'],
      desc: '"너는 너의 본토 친척 아비 집을 떠나 내가 지시할 땅으로 가라" (창 12:1)'),
  BibleEvent(year: -2066, event: '이삭 출생', region: 'canaan',
      books: ['genesis'],
      desc: '아브라함 100세, 사라 90세에 약속의 아들 탄생.'),
  BibleEvent(year: -2006, event: '야곱·에서 출생', region: 'canaan',
      books: ['genesis'],
      desc: '이삭의 쌍둥이 아들. 야곱이 후일 "이스라엘"로 개명됨.'),
  BibleEvent(year: -1876, event: '요셉과 야곱 가족, 이집트 이주', region: 'egypt',
      books: ['genesis'],
      desc: '7년 기근을 피해 애굽으로 내려감. 이스라엘 400년 체류 시작.'),

  // ── 출애굽 & 광야 ──────────────────────────────────────
  BibleEvent(year: -1526, event: '모세 출생', region: 'egypt',
      books: ['exodus'],
      desc: '파라오의 영아 살해령 중 갈대 상자에 숨겨짐. 공주의 양자가 됨.'),
  BibleEvent(year: -1446, event: '출애굽 · 홍해 도하', region: 'egypt',
      books: ['exodus', 'leviticus', 'numbers'],
      desc: '10가지 재앙, 유월절. 약 200만 명의 이스라엘이 바다를 건넘.'),
  BibleEvent(year: -1446, event: '시내산 십계명 수여', region: 'sinai',
      books: ['exodus', 'leviticus'],
      desc: '언약의 체결. 성막 제작과 제사 제도의 설립.'),
  BibleEvent(year: -1406, event: '모세의 고별 설교 · 가나안 입성 직전', region: 'sinai',
      books: ['deuteronomy'],
      desc: '신명기 전체. 모세가 느보산에서 약속의 땅을 바라본 후 죽음.'),

  // ── 정복 & 사사 시대 ───────────────────────────────────
  BibleEvent(year: -1406, event: '여호수아의 가나안 정복', region: 'canaan',
      books: ['joshua'],
      desc: '여리고 성벽 붕괴. 12지파 기업 분배.'),
  BibleEvent(year: -1375, event: '사사 시대 개막', region: 'canaan',
      books: ['judges', 'ruth'],
      desc: '옷니엘부터 삼손까지. "그 때에 이스라엘에 왕이 없었다."'),

  // ── 통일 왕국 ──────────────────────────────────────────
  BibleEvent(year: -1050, event: '사울, 초대 왕 즉위', region: 'jerusalem',
      books: ['1samuel'],
      desc: '사무엘의 기름부음. 이스라엘 왕정 시작.'),
  BibleEvent(year: -1010, event: '다윗, 유다 왕 즉위', region: 'jerusalem',
      books: ['2samuel', 'psalms'],
      desc: '골리앗 격파 후 도망자 시절을 거쳐 왕이 됨. 예루살렘 점령.'),
  BibleEvent(year: -970, event: '솔로몬 즉위 · 성전 건축', region: 'jerusalem',
      books: ['1kings', '2chronicles', 'proverbs', 'ecclesiastes', 'songofsolomon'],
      desc: '7년에 걸친 제1성전 완공. 지혜의 전성기.'),
  BibleEvent(year: -930, event: '왕국 분열 (북 이스라엘 / 남 유다)', region: 'jerusalem',
      books: ['1kings', '2chronicles'],
      desc: '솔로몬 사후 르호보암 vs 여로보암. 12지파가 둘로 나뉨.'),

  // ── 선지자 시대 ────────────────────────────────────────
  BibleEvent(year: -780, event: '요나, 니느웨 전도', region: 'prophets',
      books: ['jonah', 'amos', 'hosea'],
      desc: '물고기 뱃속에서 3일. 앗수르 제국 수도의 회개.'),
  BibleEvent(year: -740, event: '이사야 소명', region: 'prophets',
      books: ['isaiah', 'micah'],
      desc: '"거룩하다 거룩하다 거룩하다 만군의 여호와여" (사 6). 메시아 예언.'),
  BibleEvent(year: -722, event: '북 이스라엘 멸망 (앗수르에 의해)', region: 'prophets',
      books: ['2kings'],
      desc: '사마리아 함락. 10지파 흩어짐. 선지자들의 경고 성취.'),

  // ── 포로기 & 귀환 ──────────────────────────────────────
  BibleEvent(year: -605, event: '1차 바벨론 포로 (다니엘 포함)', region: 'babylon',
      books: ['daniel', 'jeremiah'],
      desc: '느부갓네살의 침공. 다니엘과 세 친구가 끌려감.'),
  BibleEvent(year: -586, event: '예루살렘 함락 · 성전 파괴', region: 'babylon',
      books: ['2kings', '2chronicles', 'lamentations', 'ezekiel'],
      desc: '바벨론의 최종 함락. 70년 포로기 시작. 예레미야의 애가.'),
  BibleEvent(year: -538, event: '고레스 칙령 · 1차 귀환', region: 'jerusalem',
      books: ['ezra', 'haggai', 'zechariah'],
      desc: '페르시아 고레스 왕의 명령으로 포로들이 본토로 귀환. 성전 재건 시작.'),
  BibleEvent(year: -516, event: '제2성전 완공', region: 'jerusalem',
      books: ['ezra', 'haggai', 'zechariah'],
      desc: '스룹바벨 성전. 학개·스가랴의 격려로 70년만에 재건 완료.'),
  BibleEvent(year: -458, event: '에스라의 개혁', region: 'jerusalem',
      books: ['ezra', 'nehemiah'],
      desc: '율법 교사 에스라의 귀환. 혼합 결혼 정리.'),
  BibleEvent(year: -445, event: '느헤미야, 예루살렘 성벽 재건', region: 'jerusalem',
      books: ['nehemiah', 'malachi'],
      desc: '52일 만에 성벽 완성. 말라기를 끝으로 400년 침묵기 시작.'),

  // ── 신약 · 예수 그리스도 ───────────────────────────────
  BibleEvent(year: -4, event: '예수 그리스도 탄생', region: 'galilee',
      books: ['matthew', 'luke'],
      desc: '베들레헴에서 동정녀 마리아에게서 태어남. 동방박사와 목자들의 경배.'),
  BibleEvent(year: 27, event: '공생애 시작 · 세례', region: 'galilee',
      books: ['matthew', 'mark', 'luke', 'john'],
      desc: '요단강에서 세례 요한에게 세례 받음. 12제자 부르심. 산상수훈.'),
  BibleEvent(year: 30, event: '십자가 죽음과 부활', region: 'jerusalem_nt',
      books: ['matthew', 'mark', 'luke', 'john'],
      desc: '유월절에 십자가 처형. 사흘 만에 부활. 40일 후 승천.'),
  BibleEvent(year: 30, event: '오순절 성령 강림', region: 'jerusalem_nt',
      books: ['acts'],
      desc: '예루살렘 다락방에 성령 임재. 베드로의 설교로 3천 명 회심. 교회의 탄생.'),

  // ── 초대 교회 & 바울 ──────────────────────────────────
  BibleEvent(year: 34, event: '바울(사울)의 회심', region: 'jerusalem_nt',
      books: ['acts'],
      desc: '다메섹 도상의 빛 체험. 기독교 박해자가 이방인의 사도로 변화.'),
  BibleEvent(year: 47, event: '바울 1차 선교여행', region: 'asia_minor',
      books: ['acts', 'galatians'],
      desc: '안디옥→구브로→소아시아 남부. 갈라디아 교회 설립.'),
  BibleEvent(year: 50, event: '예루살렘 공의회', region: 'jerusalem_nt',
      books: ['acts', 'galatians'],
      desc: '이방인 신자의 할례 문제 결정. 복음의 자유 선포.'),
  BibleEvent(year: 50, event: '바울 2차 선교여행 · 고린도 체류', region: 'corinth',
      books: ['acts', '1thessalonians', '2thessalonians'],
      desc: '빌립보·데살로니가·아덴·고린도. 18개월 고린도 체류 중 데살로니가 서신 기록.'),
  BibleEvent(year: 53, event: '바울 3차 선교여행 · 에베소 3년', region: 'asia_minor',
      books: ['acts', '1corinthians', '2corinthians', 'romans'],
      desc: '에베소에서 두란노 서원 강론. 고린도·로마서 기록.'),
  BibleEvent(year: 59, event: '바울, 로마 호송 · 멜리데 난파', region: 'mediterranean',
      books: ['acts'],
      desc: '유라굴로 광풍을 만나 14일 표류. 멜리데 섬 난파 후 전원 생존.'),
  BibleEvent(year: 60, event: '바울, 로마 1차 구금 (옥중서신)', region: 'rome',
      books: ['ephesians', 'philippians', 'colossians', 'philemon'],
      desc: '가택 연금 상태로 2년 복음 전파. 옥중 서신 4편 기록.'),
  BibleEvent(year: 62, event: '히브리서·야고보서 기록', region: 'epistles',
      books: ['hebrews', 'james'],
      desc: '박해받는 유대인 그리스도인을 위한 서신. 행함 있는 믿음 강조.'),
  BibleEvent(year: 64, event: '로마 대화재 · 네로 박해 시작', region: 'rome',
      books: ['1peter', '2peter', '1timothy', '2timothy', 'titus'],
      desc: '네로가 기독교인에게 누명. 베드로·목회서신 기록.'),
  BibleEvent(year: 67, event: '베드로 · 바울 순교', region: 'rome',
      books: ['2timothy', '2peter'],
      desc: '베드로는 거꾸로 십자가에, 바울은 참수. 사도 시대의 종말.'),
  BibleEvent(year: 70, event: '예루살렘 함락 · 제2성전 파괴', region: 'jerusalem_nt',
      books: ['matthew', 'mark', 'luke'],
      desc: '로마 티투스 장군의 포위. 예수님의 예언(마 24) 성취.'),
  BibleEvent(year: 90, event: '요한, 밧모섬 유배 · 요한계시록', region: 'patmos',
      books: ['1john', '2john', '3john', 'jude', 'revelation'],
      desc: '도미티아누스 황제의 박해. 노년의 요한에게 종말의 계시.'),
];

// region id → 해당 지역에서 발생한 이벤트 목록
List<BibleEvent> eventsInRegion(String regionId) =>
    bibleTimeline.where((e) => e.region == regionId).toList();
