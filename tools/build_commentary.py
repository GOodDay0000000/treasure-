"""
HistoricalChristianFaith/Commentaries-Database 의 sqlite 덤프에서
교부 주석을 장별 JSON으로 추출.

출력: assets/data/commentary/{bookKey}/{chapter}.json
포맷:
  {
    "chapter": 1,
    "book": "genesis",
    "source": "Church Fathers (Public Domain)",
    "verses": {
      "1": "...",
      "1-5": "...",
      ...
    }
  }

용량 제어:
  - 선호 교부만 (Chrysostom, Augustine, Aquinas, Jerome, Bede, Origen, Ambrose)
  - txt 길이 [150, 700] 범위로 절삭/필터
  - 구절마다 1명 주석만 (선호도 순)
"""
import sqlite3, json, io, sys, pathlib, re
from collections import defaultdict

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

ROOT = pathlib.Path(__file__).resolve().parent.parent
DB = ROOT / 'tools' / '_src' / 'commentaries.sqlite'
OUT = ROOT / 'assets' / 'data' / 'commentary'

# 우선순위(앞일수록 먼저 채택)
PREFERRED_FATHERS = [
    'John Chrysostom', 'Augustine of Hippo', 'Thomas Aquinas',
    'Jerome', 'Bede', 'Origen of Alexandria', 'Ambrose of Milan',
    'Cyril of Alexandria', 'Gregory the Dialogist',
    'Theophylact of Ohrid', 'Theodoret of Cyrus',
    'Tertullian', 'Irenaeus',
]
FATHER_RANK = {f: i for i, f in enumerate(PREFERRED_FATHERS)}

MAX_LEN = 700
MIN_LEN = 120

def decode_location(loc):
    """location = chapter * 1000000 + verse. 반환: (chapter, verse)"""
    if loc is None: return (None, None)
    chapter = loc // 1000000
    verse = loc % 1000000
    return (chapter, verse)

def clean(txt):
    """불필요한 공백·인용·마크업 제거, 길이 제한."""
    if not txt: return ''
    t = txt.strip()
    # "quote" 또는 성경 인용만 많은 앞부분 제거
    t = re.sub(r'^\[[^\]]+\]\s*', '', t)
    t = re.sub(r'\s+', ' ', t)
    if len(t) > MAX_LEN:
        # 문장 경계에서 자르기
        cut = t.rfind('.', 0, MAX_LEN)
        if cut < MIN_LEN: cut = MAX_LEN
        t = t[:cut + 1] + ' ...'
    return t

def key_for_locs(loc_start, loc_end):
    """verse key — 단일은 '1', 범위는 '1-5'."""
    c1, v1 = decode_location(loc_start)
    c2, v2 = decode_location(loc_end)
    if c1 != c2 or v1 is None:
        return None, None  # 장 건너뛰는 주석은 무시
    if v1 == v2:
        return c1, str(v1)
    return c1, f'{v1}-{v2}'

def main():
    conn = sqlite3.connect(str(DB))
    c = conn.cursor()
    c.execute('''
      SELECT father_name, book, location_start, location_end, txt
      FROM commentary
      WHERE txt IS NOT NULL AND book IS NOT NULL
    ''')

    # (book, chapter, verseKey) → (rank, father, cleaned_text)
    picked = {}
    total = 0
    kept = 0
    for father, book, ls, le, txt in c.fetchall():
        total += 1
        if father not in FATHER_RANK:
            continue
        chapter, verse_key = key_for_locs(ls, le)
        if chapter is None: continue
        cleaned = clean(txt)
        if len(cleaned) < MIN_LEN: continue
        key = (book, chapter, verse_key)
        rank = FATHER_RANK[father]
        existing = picked.get(key)
        if existing is None or rank < existing[0]:
            picked[key] = (rank, father, cleaned)
            kept += 1

    # 책별 장별 그룹핑
    by_chapter = defaultdict(lambda: defaultdict(dict))
    for (book, ch, vkey), (_, father, txt) in picked.items():
        by_chapter[book][ch][vkey] = txt

    # 출력
    OUT.mkdir(parents=True, exist_ok=True)
    # 기존 파일 정리
    for p in OUT.rglob('*.json'):
        p.unlink()
    for d in sorted(OUT.rglob('*'), key=lambda p: -len(str(p))):
        if d.is_dir() and not list(d.iterdir()):
            d.rmdir()

    chapter_count = 0
    for book, chapters in by_chapter.items():
        book_dir = OUT / book
        book_dir.mkdir(parents=True, exist_ok=True)
        for ch, verses in chapters.items():
            if not verses: continue
            out_file = book_dir / f'{ch}.json'
            payload = {
                'book': book,
                'chapter': ch,
                'source': 'Church Fathers (Public Domain)',
                'verses': verses,
            }
            with open(out_file, 'w', encoding='utf-8') as f:
                json.dump(payload, f, ensure_ascii=False, separators=(',', ':'))
            chapter_count += 1

    # 통계
    total_size = sum(p.stat().st_size for p in OUT.rglob('*.json'))
    print(f'source rows: {total}, kept: {kept}')
    print(f'unique book-chapter files: {chapter_count}')
    print(f'total size: {total_size / 1024:.1f} KB ({total_size / 1024 / 1024:.2f} MB)')
    if 'genesis' in by_chapter and 1 in by_chapter['genesis']:
        sample = by_chapter['genesis'][1]
        first_key = next(iter(sample))
        print(f'sample genesis 1 {first_key}: {sample[first_key][:200]}')

main()
