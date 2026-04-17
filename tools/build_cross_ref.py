"""
josephilipraja/bible-cross-reference-json 를 앱 bookKey 포맷으로 변환.
출력: assets/data/cross_references.json
포맷: {"genesis:1:1": ["exodus:20:11", "john:1:1", ...], ...}
"""
import json, io, sys, os, pathlib, glob

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'tools' / '_src' / 'xrefs'
OUT = ROOT / 'assets' / 'data' / 'cross_references.json'

# OSIS 3-letter abbreviation → 앱 bookKey
OSIS = {
    'GEN':'genesis','EXO':'exodus','LEV':'leviticus','NUM':'numbers','DEU':'deuteronomy',
    'JOS':'joshua','JDG':'judges','RUT':'ruth','1SA':'1samuel','2SA':'2samuel',
    '1KI':'1kings','2KI':'2kings','1CH':'1chronicles','2CH':'2chronicles',
    'EZR':'ezra','NEH':'nehemiah','EST':'esther','JOB':'job','PSA':'psalms',
    'PRO':'proverbs','ECC':'ecclesiastes','SNG':'songofsolomon','SOS':'songofsolomon',
    'ISA':'isaiah','JER':'jeremiah','LAM':'lamentations','EZE':'ezekiel','EZK':'ezekiel',
    'DAN':'daniel','HOS':'hosea','JOE':'joel','JOL':'joel','AMO':'amos','AMS':'amos',
    'OBA':'obadiah','JON':'jonah','MIC':'micah','MCH':'micah',
    'NAH':'nahum','NAM':'nahum','HAB':'habakkuk','ZEP':'zephaniah','ZPH':'zephaniah',
    'HAG':'haggai','ZEC':'zechariah','MAL':'malachi',
    'MAT':'matthew','MAR':'mark','MRK':'mark','LUK':'luke','JOH':'john','JHN':'john',
    'ACT':'acts','ROM':'romans',
    '1CO':'1corinthians','2CO':'2corinthians','GAL':'galatians',
    'EPH':'ephesians','PHI':'philippians','PHP':'philippians','COL':'colossians',
    '1TH':'1thessalonians','2TH':'2thessalonians',
    '1TI':'1timothy','2TI':'2timothy','TIT':'titus','PHM':'philemon',
    'HEB':'hebrews','JAM':'james','JAS':'james',
    '1PE':'1peter','2PE':'2peter','1JO':'1john','1JN':'1john',
    '2JO':'2john','2JN':'2john','3JO':'3john','3JN':'3john',
    'JUD':'jude','JDE':'jude','REV':'revelation',
}

def convert_ref(s):
    """e.g. 'GEN 1 1' → 'genesis:1:1'. None if unknown book."""
    parts = s.strip().split()
    if len(parts) != 3: return None
    b = OSIS.get(parts[0].upper())
    if not b: return None
    return f'{b}:{parts[1]}:{parts[2]}'

merged = {}
stats = {'entries': 0, 'refs': 0, 'unknown': 0}

for src_path in sorted(glob.glob(str(SRC / '*.json'))):
    try:
        with open(src_path, encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f'skip {src_path}: {e}')
        continue
    for _, entry in data.items():
        src_key = convert_ref(entry.get('v', ''))
        if not src_key: stats['unknown'] += 1; continue
        refs_dict = entry.get('r', {})
        refs = []
        for _, ref in refs_dict.items():
            target = convert_ref(ref)
            if target:
                refs.append(target)
            else:
                stats['unknown'] += 1
        if refs:
            merged[src_key] = refs
            stats['entries'] += 1
            stats['refs'] += len(refs)

OUT.parent.mkdir(exist_ok=True, parents=True)
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(merged, f, ensure_ascii=False, separators=(',', ':'))

size_kb = OUT.stat().st_size // 1024
print(f'entries={stats["entries"]} refs={stats["refs"]} unknown={stats["unknown"]}')
print(f'wrote {OUT.name} ({size_kb} KB)')
# 샘플
sample_key = 'genesis:1:1'
if sample_key in merged:
    print(f'sample {sample_key}: {merged[sample_key][:5]}...')
