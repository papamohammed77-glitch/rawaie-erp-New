from pathlib import Path
import hashlib
import re
import subprocess
import tempfile
from html.parser import HTMLParser

MAIN = Path('Current/PWA/New-main')
CUR = Path('Current/PWA/main')
PARTS = [CUR / f'main{i}.md' for i in range(1, 12)]
AUTH = '/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'
COMPAT = '/* RAWAEA MAIN2 COMPATIBILITY */'
VERSION = "window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"
GOVERNED = '// MAIN2_GOVERNED_CLOSED:v1'
CANONICAL_SW = "navigator.serviceWorker.register('./sw.js',{scope:'./'})"
INLINE_RE = re.compile(r'<script(?![^>]*\bsrc\s*=)[^>]*>', re.I)
HTML_COMMENT_TAIL = re.compile(r'<!--(?:[\s\S]*?)-->\s*$', re.I)

def normalize_main1(raw):
    raw = raw.lstrip('\ufeff')
    raw = re.sub(r'(?m)^\s*const RW_Auth\s*=\s*', 'var RW_Auth = ', raw, count=1)
    raw = re.sub(r'(?m)^\s*const RW_Navigation\s*=\s*', 'var RW_Navigation = ', raw, count=1)
    # main1 is intentionally an open application <script> fragment; main2..main11
    # continue the same program and the final assembler closes the script. Therefore
    # looking for a closing </script> inside main1 is incorrect and was the cause of
    # the prior false boundary failure.
    opens = list(INLINE_RE.finditer(raw))
    if not opens:
        raise RuntimeError('MAIN1_INLINE_RUNTIME_OPENER_MISSING')
    app_open = opens[-1]
    raw = raw[app_open.start():]
    raw = HTML_COMMENT_TAIL.sub('', raw)
    return raw.rstrip()

def normalize_fragment(raw, idx):
    raw = raw.lstrip('\ufeff')
    raw = re.sub(r'</body>\s*|</html>\s*', '', raw, flags=re.I)
    if re.search(r'^\s*<!doctype\b|^\s*</?(?:html|head|body)\b|</script>', raw, re.I | re.M):
        raise RuntimeError(f'BAD_FRAGMENT_BOUNDARY:main{idx}')
    if idx == 7:
        raw = re.sub(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}", r"\1));}", raw, count=1)
    return raw.rstrip()

def p163(s):
    if s.count(COMPAT) > 1:
        raise RuntimeError('P163_COMPAT_DUPLICATE')
    if COMPAT in s:
        a=s.index(COMPAT); b=s.find(AUTH,a+len(COMPAT))
        if b<0: raise RuntimeError('P163_AUTH_AFTER_COMPAT_MISSING')
        s=s[:a]+s[b:]
    if AUTH not in s:
        m=re.search(r'(?m)^\s*var\s+RW_Dashboard\s*=\s*',s)
        if not m: raise RuntimeError('MAIN2_DASHBOARD_ANCHOR_MISSING')
        s=s[:m.start()]+AUTH+'\n'+s[m.start():]
    if s.count(AUTH)!=1: raise RuntimeError('P163_AUTH_COUNT:'+str(s.count(AUTH)))
    s=re.sub(r'window\.RW_Dashboard\s*=\s*\{\s*render\s*:\s*renderDashboard\s*\}\s*;?','',s,count=1)
    s=re.sub(r'window\.RW_Items\s*=\s*\{\s*render\s*:\s*renderItems\s*\}\s*;?','',s,count=1)
    s=re.sub(r'window\.RW_Items\s*=\s*RW_Items\s*;','window.RW_Items=RW_Items;',s,count=1)
    s=s.replace(VERSION,'').replace(GOVERNED,'')
    if s.count('window.RW_Items=RW_Items;')!=1: raise RuntimeError('P163_ITEMS_OWNER_COUNT:'+str(s.count('window.RW_Items=RW_Items;')))
    owner=s.index('window.RW_Items=RW_Items;')+len('window.RW_Items=RW_Items;')
    return s[:owner]+'\n'+VERSION+'\n'+GOVERNED+s[owner:]

def inject_canonical_sw(s):
    reg=re.compile(r"(?:if\s*\(\s*['\"]serviceWorker['\"]\s*in\s*navigator\s*\)\s*)?navigator\.serviceWorker\.register\([^;\n]*\)(?:\.catch\([^;\n]*\))?\s*;?",re.I)
    s=reg.sub('',s); body=s.lower().rfind('</body>')
    if body<0: raise RuntimeError('BODY_CLOSE_MISSING')
    tag="<script>if('serviceWorker' in navigator){navigator.serviceWorker.register('./sw.js',{scope:'./'}).catch(function(e){console.warn('SERVICE_WORKER',e)})}</script>\n"
    return s[:body]+tag+s[body:]

class StructureParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=False); self.starts=[]; self.ends=[]
    def handle_starttag(self,tag,attrs): self.starts.append(tag.lower())
    def handle_startendtag(self,tag,attrs): self.starts.append(tag.lower())
    def handle_endtag(self,tag): self.ends.append(tag.lower())

def _app_js(s):
    apps=[m.group(1) for m in re.finditer(r'<script(?![^>]*\bsrc\s*=)[^>]*>([\s\S]*?)</script>',s,re.I) if 'serviceWorker.register' not in m.group(1)]
    if len(apps)!=1: raise RuntimeError('APPLICATION_INLINE_SCRIPT_COUNT:'+str(len(apps)))
    return apps[0]

def validate_phase_js(parts):
    # main1 deliberately contains an OPEN script with no closing tag. Extract exactly
    # its JS payload and then validate the cumulative program after every fragment.
    if not parts or not parts[0].lstrip().lower().startswith('<script'):
        raise RuntimeError('MAIN1_OPEN_SCRIPT_BOUNDARY_MISSING')
    m=re.match(r'<script[^>]*>([\s\S]*)$',parts[0],re.I)
    if not m:
        raise RuntimeError('MAIN1_SCRIPT_PAYLOAD_MISSING')
    js_body = m.group(1)
    phase_report=[]
    for idx in range(1, len(parts)+1):
        if idx > 1:
            js_body += '\n\n' + parts[idx-1]
        temp=Path(tempfile.gettempdir())/f'rawaea-phase-{idx}.js'
        temp.write_text(js_body, encoding='utf-8')
        r=subprocess.run(['node','--check',str(temp)],capture_output=True,text=True)
        phase_report.append((idx,len(js_body.encode('utf-8'))))
        if r.returncode:
            tail='\n'.join(js_body.splitlines()[-60:])
            raise RuntimeError('JS_PHASE_SYNTAX_FAIL:main%d\n%s\n---TAIL---\n%s' % (idx,r.stderr,tail))
    return phase_report

def validate(s):
    start=s.lstrip().lower()
    required=['window.RW_Auth','window.RW_Navigation','window.RW_Views','window.RW_OwnerLicense','var RW_Dashboard','var RW_Items','window.RW_Items=RW_Items;','RW_SUPABASE_CLIENT','MAIN3']
    missing=[x for x in required if x not in s]
    if missing: raise RuntimeError('CURRENT_CONTRACT_MISSING:'+repr(missing))
    parser=StructureParser(); parser.feed(s); parser.close()
    ah=parser.starts.count('html'); eh=parser.ends.count('html'); ab=parser.starts.count('body'); eb=parser.ends.count('body'); ass=parser.starts.count('script'); ess=parser.ends.count('script'); ast=parser.starts.count('style'); est=parser.ends.count('style')
    gates={'doctype_start':start.startswith('<!doctype html>'),'one_html_root':ah==1 and eh==1,'one_body_root':ab==1 and eb==1,'script_balance':ass==ess,'style_balance':ast==est,'auth_one':s.count(AUTH)==1,'version_one':s.count(VERSION)==1,'governed_one':s.count(GOVERNED)==1,'compat_absent':COMPAT not in s,'dash_alias_absent':not re.search(r'window\.RW_Dashboard\s*=\s*\{\s*render\s*:\s*renderDashboard\s*\}',s),'items_alias_absent':not re.search(r'window\.RW_Items\s*=\s*\{\s*render\s*:\s*renderItems\s*\}',s),'dash_owner_one':len(re.findall(r'(?m)^\s*var\s+RW_Dashboard\s*=\s*',s))==1,'items_owner_one':len(re.findall(r'(?m)^\s*var\s+RW_Items\s*=\s*',s))==1,'items_export_one':s.count('window.RW_Items=RW_Items;')==1,'canonical_sw_one':s.count(CANONICAL_SW)==1,'rpc_present':'.rpc(' in s,'edge_present':'/functions/v1/' in s}
    bad=[k for k,v in gates.items() if not v]
    if bad: raise RuntimeError(f'P163_GOLD_GATE_FAIL:{bad} structural html={ah}/{eh} body={ab}/{eb} script={ass}/{ess} style={ast}/{est}')
    js=_app_js(s)
    path=Path(tempfile.gettempdir())/'rawaea-new-main.js'; path.write_text(js,encoding='utf-8')
    r=subprocess.run(['node','--check',str(path)],capture_output=True,text=True)
    if r.returncode: print(r.stderr); raise RuntimeError('FINAL_JS_SYNTAX_FAIL')
    return gates

def main():
    parts=[]
    for idx,p in enumerate(PARTS,1):
        if not p.is_file() or not p.stat().st_size: raise RuntimeError('MISSING_PART:'+str(p))
        raw=p.read_text(encoding='utf-8-sig'); parts.append(normalize_main1(raw) if idx==1 else normalize_fragment(raw,idx))
    phases=validate_phase_js(parts)
    candidate=parts[0]+'\n\n'+'\n\n'.join(parts[1:])+'\n\n</script>\n</body>\n</html>\n'
    candidate=p163(candidate); candidate=inject_canonical_sw(candidate); gates=validate(candidate)
    tmp=MAIN.with_suffix('.tmp'); tmp.write_text(candidate,encoding='utf-8'); tmp.replace(MAIN)
    print({'status':'NEW_MAIN_GOLD_DIAMOND_READY','target':str(MAIN),'sha256':hashlib.sha256(candidate.encode()).hexdigest(),'bytes':len(candidate.encode()),'gates':gates,'phase_bytes':phases})

if __name__=='__main__': main()