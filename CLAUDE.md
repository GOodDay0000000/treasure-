# 보물 (Treasure) - 성경 앱 Claude Code 컨텍스트
> 마지막 업데이트: 2026-04-17

---

## 앱 정체성
- **앱 이름**: 보물 (Treasure)
- **컨셉**: "말씀이라는 보물을 찾아 항해합니다"
- **슬로건**: "말씀을 읽는 것이 아니라, 보물을 발견하는 항해"
- **플랫폼**: Flutter (Android/iOS/Web)
- **웹 배포**: https://goodday0000000.github.io/treasure-/
- **GitHub**: https://github.com/GOodDay0000000/treasure-.git

---

## 디자인 시스템

### 색상
```
다크모드 (딥오션):
  배경: #0D1B2A / 카드: #1B2D3F
  포인트: #C9A84C (골드) / 텍스트: #E8E3D8 / 보조: #7A90A4

라이트모드:
  배경: #F7F9FC / 카드: #FFFFFF
  포인트: #1B4F72 (네이비) / 텍스트: #1A1A1A

성경 읽기 화면: 라이트 #FFF8F0 / 다크 #1A2535
활동/마이페이지: 라이트 #F8F6F2 / 다크 #1A1A2E
```

### 로고
- 폰트: Google Fonts Dancing Script (필기체)
- 아이콘: Icons.anchor_rounded
- "Treasure" + 닻 아이콘 조합

---

## 파일 구조
```
lib/
├── l10n/app_strings.dart         (15개 언어, BibleBookNames 66권)
├── data/
│   ├── map_regions.dart          (보물지도 지역 - 공용)
│   └── bible_timeline.dart       (40개 연대기 이벤트)
├── main.dart
├── pages/
│   ├── main_navigation_page.dart (4탭: 성경|보물지도|연구소|활동)
│   │   MainNavigationPageState.goToTab(index) → 탭전환 공용 API
│   ├── book_select_page.dart     (메인 홈)
│   ├── bible_read_page.dart      (성경 읽기)
│   ├── search_page.dart          (구절 검색)
│   ├── treasure_map_page.dart    (보물지도)
│   ├── lab_page.dart             (연구소 - 9섹션)
│   ├── book_info_page.dart       (성경 66권 상세)
│   ├── hymn_page.dart            (찬송가)
│   ├── my_page.dart              (마이페이지)
│   ├── activity_page.dart        (활동)
│   └── dictionary_page.dart      (원어사전 - 4탭)
└── services/
    ├── hymn_service.dart
    ├── bookmark_service.dart / highlight_service.dart / memo_service.dart
    ├── commentary_service.dart   (교부 주석)
    ├── cross_reference_service.dart
    └── book_info_service.dart
```

---

## 에셋 구조
```
assets/
├── bible/{version}/{bookKey}/{chapter}.json
├── data/
│   ├── hebrew_dict.json      (1.9MB - Strong's 100%)
│   ├── greek_dict.json       (1.3MB - Strong's 99%)
│   ├── hebrew_alphabet.json  (22자)
│   ├── greek_alphabet.json   (24자)
│   ├── cross_references.json (6.2MB - 386,905 참조)
│   ├── book_info.json        (66권 메타)
│   ├── topics.json           (20주제 + 원어)
│   ├── background.json       (49항목)
│   └── bible_stats.json      (22개 통계)
├── commentary/{bookKey}/{chapter}.json (14MB - 교부주석, 창세기1장만 한글)
└── images/bible_map.png      (GPT 생성 고대지도)
```

---

## 완료된 기능

### 성경 읽기 (bible_read_page.dart)
- 장 스와이프 + 절 탭 토글 on/off
- 다중 절 선택 (탭 토글 누적, _anchorVerse 없음)
- 교차참조: 1절만 선택 시 활성화
- 클래식 모드 / 폰트 크기 (SharedPreferences)
- AppBar: 절탭토글(고정) + T±T + ⋮(클래식/주석)
- 주석: CommentarySheet (교부 공개도메인)
- 마지막 읽은 구절 저장

### 보물지도 (treasure_map_page.dart)
- GPT 생성 실제 지도 이미지 위에 인터랙션 레이어
- 안개 효과 (FogPainter - saveLayer + BlendMode.dstOut)
- 15개 지역 / 66권 매핑
- 골드 마커 + 펄스 애니메이션
- 지역 탭 → 상세 패널 (story/reward 포함)
- 미니맵 + 진행률 뱃지
- data/map_regions.dart로 공용 분리

### 연구소 (lab_page.dart) - 9섹션
모든 섹션: 미리보기 2~3개 + "더 알아보기 →" 패턴
1. 📖 성경 66권 정보
2. 🔤 원어 사전
3. 📝 주석 미리보기
4. 🔗 교차참조 미리보기
5. ⏰ 타임라인
6. 🗺️ 지도 탐험 (보물지도 탭 연동)
7. 📊 통계 22개
8. 🔍 주제별 탐구 20주제
9. 🏛️ 배경 백과 49항목

### 원어 사전 (dictionary_page.dart)
- 4탭: 히브리어 / 헬라어 / 히브리알파벳 / 헬라알파벳
- 원어 32sp + 음역 + 한글뜻 + 정의 + KJV 용례
- 카드 탭 → 확장, 알파벳 탭 → 96sp 상세

### 찬송가 (hymn_page.dart)
- 새찬송가 645장 / Image.memory 방식 (검은화면 해결)
- 저작권 안내 / 영문탭 다이얼로그

---

## 다음 작업 목록

### 🔴 즉시 처리
```
1. 본문 슬라이드 후 로딩 느림 → 성능 개선
   (다음 장 미리 프리로드)

2. 본문 UI 재배치
   - 클래식모드/주석 버튼 분리
   - 형광펜/북마크 UI 아이덴티티 재해석
   - 주석 버튼 실제 작동 확인 (준비중 표시 제거)

3. 연구소
   - 성경66권 / 원어사전 섹션 "더알아보기" 제거
   - 주석/해설 섹션 → "오늘의 말씀 해설" 형태로 개선
```

### 🟡 중기
```
4. 스플래시 화면
   이미지: assets/images/splash_dark.png / splash_light.png
   (사용자가 GPT로 생성 예정)
   - 다크: 야간바다 + 별 + 골드 Treasure
   - 라이트: 새벽바다 + 햇살 + 네이비 Treasure
   - 하단: 닻 + "Treasure" + "말씀이라는 보물을 찾아 항해합니다"
   - 다크/라이트 선택 버튼

5. 온보딩 (첫 설치 이벤트)
   스플래시 → 환영 → 언어선택 → 번역본선택 → 알림허용 → 시작
   SharedPreferences 'onboarding_done' 키로 재진입 방지

6. 마이페이지 항해자 등급 시스템
   등급: 돗단배 → 범선 → 쾌속선 → 요트 → 방주
   - 퀘스트/바이블트래커 경험치 연동
   - 고인물용 초기화 옵션
   - 나중에 구글/카카오 계정 연동 예정

7. 바이블 트래커
   - 읽기 플랜 중심 (사용자 도움에 비중)
   - 30일/90일/1년 플랜
   - 퀘스트 시스템
   - 항해자 등급과 연동

8. 보물지도 강화
   - 미점령 지역 밝기 조정 (너무 어두움)
   - 다크/라이트 모드별 안개 차별화
   - 모험 게임 느낌 강화
   - 지역 퀘스트 연동

9. 활동 탭 기능 구현
   - 그룹 기능
   - CCM 플레이리스트 (심플 UI, 유튜브뮤직 참고)
   - 바이블 트래커 연동
   - 설교 → 추후 유튜브 채널 연동

10. 어린이 성경 추가
```

### 🟢 추후
```
- 오디오 성경
- CCM 인기차트 연동
- 주석 한글 번역 완성 (1224장 중 1장 완료)
- 다국어 UI 최종 완성
- 구글/카카오 계정 연동
- 설교 유튜브 채널 연동
```

---

## 작업 규칙
- flutter analyze 에러 0건 필수
- 다크모드 항상 고려
- 모든 데이터는 GitHub 오픈소스 우선 활용
- Google Fonts Dancing Script 로고 유지

## 웹 배포
```
flutter build web --release --base-href /treasure-/
xcopy /E /I build\web docs
git add docs && git commit -m "update" && git push
```
