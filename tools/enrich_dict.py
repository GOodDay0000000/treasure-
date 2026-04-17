"""
사전 에셋을 openscriptures/strongs 데이터로 풍부화.

입력 (기존 에셋):
  assets/data/{hebrew,greek}_dict.json
  - 한글 pronunciation(음역) + meaning(뜻)만 신뢰할 수 있는 값으로 유지
  - 구식 'original'(ASCII transliteration) / 'section' 필드는 제거

병합 소스 (openscriptures Strong's, .js):
  tools/_strongs_src/{hebrew,greek}.js
  - lemma → hebrew / greek (실제 유니코드)
  - xlit / translit → transliteration (라틴 음역)
  - strongs_def → strongsDef (Strong's 영문 정의)
  - kjv_def → kjvDef (KJV 번역 용례)

출력: 기존 에셋 덮어쓰기 (필드 슬림화 + enrichment 적용)

실행: python tools/enrich_dict.py
"""
import json, io, sys, pathlib

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

ROOT = pathlib.Path(__file__).resolve().parent.parent
ASSETS = ROOT / 'assets' / 'data'
STRONGS = ROOT / 'tools' / '_strongs_src'

def parse_strongs_js(path, var_name):
    text = path.read_text(encoding='utf-8')
    start = text.find('{', text.find(f'var {var_name}'))
    end = text.rfind('};')
    if start < 0 or end < 0:
        raise RuntimeError(f'failed to find var body in {path.name}')
    return json.loads(text[start:end + 1])

def clean(s):
    return s.strip() if s else None

def enrich(lang):
    prefix = 'H' if lang == 'hebrew' else 'G'
    var = 'strongsHebrewDictionary' if lang == 'hebrew' else 'strongsGreekDictionary'
    src_file = STRONGS / f'{lang}.js'

    print(f'▸ parsing {src_file.name} ...')
    strongs = parse_strongs_js(src_file, var)
    print(f'  openscriptures {lang}: {len(strongs)} entries')

    asset_path = ASSETS / f'{lang}_dict.json'
    with open(asset_path, encoding='utf-8') as f:
        entries = json.load(f)
    print(f'  existing asset: {len(entries)} entries')

    matched = 0
    out = []
    for e in entries:
        key = f'{prefix}{e["id"]}'
        src = strongs.get(key, {})

        lemma = clean(src.get('lemma'))
        xlit = clean(src.get('xlit') or src.get('translit'))
        sdef = clean(src.get('strongs_def'))
        kdef = clean(src.get('kjv_def'))

        if lemma:
            matched += 1

        # 슬림화된 엔트리 (구식 'original'/'section' 제거)
        record = {
            'id': e['id'],
            'sub': e.get('sub'),
            'pronunciation': e.get('pronunciation', ''),
            'meaning': e.get('meaning', ''),
            'hebrew': lemma if lang == 'hebrew' else None,
            'greek': lemma if lang == 'greek' else None,
            'transliteration': xlit,
            'strongsDef': sdef,
            'kjvDef': kdef,
        }
        # null 값 제거해서 용량 절약
        record = {k: v for k, v in record.items() if v is not None and v != ''}
        out.append(record)

    print(f'  lemma matched: {matched}/{len(entries)} ({matched * 100 // len(entries)}%)')

    with open(asset_path, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, separators=(',', ':'))
    size_kb = asset_path.stat().st_size // 1024
    print(f'  wrote {asset_path.name} ({size_kb} KB)')

    # 샘플
    s = out[0]
    print(f'  sample: {json.dumps(s, ensure_ascii=False)[:250]}')

enrich('hebrew')
enrich('greek')
print('✓ done')
