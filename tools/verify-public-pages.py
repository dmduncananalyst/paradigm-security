"""Read-only verification of the approved public inventory; never translates or publishes."""
from pathlib import Path
import json,re
from source_section_policy import inappropriate_spans
ROOT=Path(__file__).resolve().parents[1]
def verify():
    config=json.loads((ROOT/'tools/production-pages.json').read_text(encoding='utf-8'))
    routes=list(config['english'])+[language+'/'+route for language,entries in config['locales'].items() for route in entries]
    errors=[]
    for route in routes:
        f=ROOT/route
        if not f.is_file():errors.append('Missing approved page: '+route);continue
        source=f.read_text(encoding='utf-8-sig')
        if len(re.findall(r'https://(?:www\.)?clarity\.ms/tag/',source))!=1 or ('"'+config['clarity_project']+'"') not in source:errors.append('Clarity initialization mismatch: '+route)
        if inappropriate_spans(source,route):errors.append('Inappropriate source/resource section: '+route)
        if re.search(r'data-clarity-unmask|clarity\s*\(\s*["\']unmask',source,re.I):errors.append('Unexpected unmasking: '+route)
    if len(routes)!=len(set(routes)):errors.append('Duplicate approved route')
    print(json.dumps({'pages':len(routes),'project':config['clarity_project'],'errors':errors},indent=2))
    if errors:raise SystemExit(1)
if __name__=='__main__':verify()
