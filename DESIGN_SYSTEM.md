# 보물 (Treasure) 디자인 시스템
> 마지막 업데이트: 2026-04-08

---

## 앱 정체성

```
앱 이름:  보물 (Treasure)
컨셉:     말씀을 찾아 항해하는 경험
슬로건:   "말씀을 읽는 것이 아니라, 보물을 발견하는 항해"

세계관:
  성경 = 바다
  말씀 = 보물
  사용자 = 항해자
  읽기 = 항해
```

---

## 아이콘 / 로고

```
아이콘:   닻 + 십자가 (소망의 닻)
          - 닻의 세로 기둥 = 십자가
          - 기독교 초대교회 상징
          - 히브리서 6:19 "영혼의 닻"
          - 심플하고 의미 깊음

로고 텍스트: "Treasure"
폰트:     Google Fonts - Dancing Script (필기체)
          - 부드럽고 흘러가는 느낌
          - 인스타그램 감성
          - fontWeight: w700, fontSize: 22~26

아이콘 심볼: Icons.anchor_rounded
```

---

## 색상 팔레트

### 라이트 모드
```
배경 (홈/찬송가/검색/사전):  #F7F9FC  (연한 블루그레이)
배경 (활동/마이페이지):       #F8F6F2  (원래 크림)
배경 (성경 읽기):             #FFF8F0  (따뜻한 크림 - 종이책 느낌)

카드:                         #FFFFFF
포인트:                       #1B4F72  (네이비)
텍스트:                       #1A1A1A
보조 텍스트:                  #8E8E93
구분선:                       #E5E5EA
```

### 다크 모드
```
배경 (홈/찬송가/검색/사전):  #0D1B2A  (깊은 바다)
배경 (활동/마이페이지):       #1A1A2E  (원래 다크)
배경 (성경 읽기):             #1A2535  (살짝 밝은 네이비)

카드 (홈/찬송가):             #1B2D3F  (파도 아래)
카드 (활동/마이페이지):       #16213E  (원래 카드)
카드 (성경 읽기):             #1E2E42

포인트:                       #C9A84C  (골드 - 보물)
텍스트:                       #E8E3D8  (따뜻한 흰색)
보조 텍스트:                  #7A90A4  (안개)
구분선:                       #2C3E50
```

---

## 페이지별 색상 적용

| 페이지 | 라이트 배경 | 다크 배경 | 비고 |
|--------|------------|----------|------|
| 홈 (book_select) | #F7F9FC | #0D1B2A | 보물 컨셉 |
| 성경 읽기 | #FFF8F0 | #1A2535 | 크림 - 가독성 |
| 검색 | #F7F9FC | #0D1B2A | 홈과 통일 |
| 찬송가 | #F7F9FC | #0D1B2A | 홈과 통일 |
| 사전 | #F7F9FC | #0D1B2A | 홈과 통일 |
| 활동 | #F8F6F2 | #1A1A2E | 원래 색 유지 |
| 마이페이지 | #F8F6F2 | #1A1A2E | 원래 색 유지 |

---

## 타이포그래피

```
로고:       Dancing Script Bold (Google Fonts)
앱바 제목:  System Font Bold, 17px
본문:       System Font, 20px (기본, 조절 가능)
보조:       System Font, 13px
절 번호:    System Font Bold, 작은 크기
```

---

## ThemeData 요약

### 라이트
```dart
primary:   Color(0xFF1B4F72)  // 네이비
secondary: Color(0xFFC9A84C)  // 골드 포인트
surface:   Color(0xFFFFFFFF)
scaffold:  Color(0xFFF7F9FC)
```

### 다크
```dart
primary:   Color(0xFFC9A84C)  // 골드
secondary: Color(0xFF7A90A4)  // 안개
surface:   Color(0xFF1B2D3F)
scaffold:  Color(0xFF0D1B2A)
```

---

## 컴포넌트 스타일

```
카드:       BorderRadius 16, elevation 0
버튼:       BorderRadius 14, filled
탭바:       포인트 색상 언더라인
바텀시트:   BorderRadius top 20
아이콘버튼: 포인트 색상
```

---

## 미완료 디자인 작업

- [ ] 앱 아이콘 실제 제작 (닻+십자가 SVG)
- [ ] 스플래시 스크린
- [ ] 온보딩 화면 디자인
- [ ] 빈 상태(Empty State) 일러스트
- [ ] 로딩 애니메이션
- [ ] 마이크로 인터랙션 (절 선택, 북마크 등)
- [ ] 항해 테마 일러스트 (메인화면 배경 등)
