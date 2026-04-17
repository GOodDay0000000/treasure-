"""
주석 한글 번역 추가 스크립트.

동작:
  assets/data/commentary/ 폴더를 순회하며 각 JSON 파일의 `verses` 맵을
  검사. 각 절에 아직 'korean_verses' 필드가 없으면 번역 대상으로 표기.

번역 방식:
  본 스크립트는 **대상 목록을 출력**만 하고, 실제 번역은 Claude가
  대화 세션에서 직접 각 파일을 Edit/Write로 수정하는 방식으로 진행한다.
  (LLM 번역을 파이썬 스크립트 안에서 실행할 수 없음)

번역된 파일 형식:
  {
    "book": "genesis",
    "chapter": 1,
    "source": "Church Fathers (Public Domain)",
    "verses": {...영문 원본...},
    "korean_verses": {
      "1": "...한글 번역...",
      "2": "..."
    }
  }

스킵 규칙:
  - 파일에 이미 "korean_verses" 필드가 있으면 전체 스킵
  - 번역 대상 파일 목록을 pending.txt로 출력하여 작업 우선순위 파악
"""
import json, io, sys, pathlib, glob

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

ROOT = pathlib.Path(__file__).resolve().parent.parent
COMM = ROOT / 'assets' / 'data' / 'commentary'

# 순서: 창세기→요한계시록 (book_info.json 순서로)
# 각 문서의 66권 순서는 book_select_page.dart의 oldTestament + newTestament 참고
BOOK_ORDER = [
    'genesis','exodus','leviticus','numbers','deuteronomy',
    'joshua','judges','ruth','1samuel','2samuel',
    '1kings','2kings','1chronicles','2chronicles',
    'ezra','nehemiah','esther','job','psalms','proverbs',
    'ecclesiastes','songofsolomon','isaiah','jeremiah','lamentations',
    'ezekiel','daniel','hosea','joel','amos','obadiah','jonah','micah',
    'nahum','habakkuk','zephaniah','haggai','zechariah','malachi',
    'matthew','mark','luke','john','acts','romans',
    '1corinthians','2corinthians','galatians','ephesians','philippians',
    'colossians','1thessalonians','2thessalonians','1timothy','2timothy',
    'titus','philemon','hebrews','james','1peter','2peter',
    '1john','2john','3john','jude','revelation',
]

def analyze():
    pending = []
    done = []
    for book in BOOK_ORDER:
        book_dir = COMM / book
        if not book_dir.exists(): continue
        chapter_files = sorted(book_dir.glob('*.json'),
            key=lambda p: int(p.stem))
        for cf in chapter_files:
            with open(cf, encoding='utf-8') as f:
                d = json.load(f)
            verse_count = len(d.get('verses', {}))
            if 'korean_verses' in d and d['korean_verses']:
                done.append((book, cf.stem, verse_count))
            else:
                pending.append((book, cf.stem, verse_count))

    print(f'done: {len(done)} files')
    print(f'pending: {len(pending)} files')
    total_verses = sum(c for _, _, c in pending)
    print(f'total verse entries pending: {total_verses}')
    print()
    print('--- first 20 pending files ---')
    for b, ch, n in pending[:20]:
        print(f'  {b}/{ch}.json ({n} verses)')

    # pending.txt로 목록 저장
    out = ROOT / 'tools' / 'translation_pending.txt'
    with open(out, 'w', encoding='utf-8') as f:
        for b, ch, n in pending:
            f.write(f'{b}/{ch}.json\t{n}\n')
    print(f'\nwrote {out.name} ({len(pending)} files)')

if __name__ == '__main__':
    analyze()
