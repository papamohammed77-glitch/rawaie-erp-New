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
P1_FORENSIC_MARKER = re.compile(r'(?m)^\s*<!--\s*RAWAEA_P1_FORENSIC_CLOSED:[^>]*-->\s*$', re.I)

def normalize_main1(raw):
    raw = raw.lstrip('\ufeff')
    raw = re.sub(r'(?m)^\s*const RW_Auth\s*=\s*', 'var RW_Auth = ', raw, count=1)
    raw = re.sub(r'(?m)^\s*const RW_Navigation\s*=\s*', 'var RW_Navigation = ', raw, count=1)
    opens = list(INLINE_RE.finditer(raw))
    if not opens: raise RuntimeError('MAIN1_INLINE_RUNTIME_OPENER_MISSING')
    app_open = opens[-1]
    prefix = raw[:app_open.start()]
    body = raw[app_open.start():]
    body = P1_FORENSIC_MARKER.sub('', body)
    body = HTML_COMMENT_TAIL.sub('', body)
    return prefix + body.rstrip()

def normalize_fragment(raw, idx):
    raw = raw.lstrip('\ufeff')
    if idx == 7:
        defect = ".join(''));}"
        count = raw.count(defect)
        if count != 1: raise RuntimeError('MAIN7_EXPECTED_SETTLEMENT_SYNTAX_DEFECT_COUNT:' + str(count))
        raw = raw.replace(defect, ".join('')));}", 1)
    return raw.rstrip()

def extract_main1_application_js(chunk):
    opens = list(INLINE_RE.finditer(chunk))
    if not opens: raise RuntimeError('MAIN1_INLINE_RUNTIME_MISSING')
    app_open = opens[-1]; close = chunk.rfind('</script>'); end = close if close >= app_open.end() else len(chunk)
    return chunk[app_open.end():end]

def p163(s):
    if s.count(COMPAT) > 1: raise RuntimeError('P163_COMPAT_DUPLICATE')
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
    legacy=re.compile(r"if\s*\(\s*['\"]serviceWorker['\"]\s*in\s*navigator\s*\)\s*navigator\.serviceWorker\.register\(\s*['\"]\./sw\.js['\"]\s*,\s*\{\s*scope\s*:\s*['\"]\./['\"]\s*\}\s*\)\s*\.catch\(\s*function\(e\)\s*\{\s*console\.warn\(\s*['\"]SERVICE_WORKER['\"]\s*,\s*e\s*\)\s*\}\s*\)\s*;?",re.I)
    s=legacy.sub('',s)
    bare=re.compile(r"navigator\.serviceWorker\.register\(\s*['\"]\./sw\.js['\"]\s*,\s*\{\s*scope\s*:\s*['\"]\./['\"]\s*\}\s*\)\s*;?",re.I)
    s=bare.sub('',s)
    if 'navigator.serviceWorker.register' in s: raise RuntimeError('UNEXPECTED_SERVICE_WORKER_REGISTRATION_FORM')
    body=s.lower().rfind('</body>')
    if body<0: raise RuntimeError('BODY_CLOSE_MISSING')
    tag="<script>if('serviceWorker' in navigator){navigator.serviceWorker.register('./sw.js',{scope:'./'}).catch(function(e){console.warn('SERVICE_WORKER',e)})}</script>\n"
    return s[:body]+tag+s[body:]

class StructureParser(HTMLParser):
    def __init__(self): super().__init__(convert_charrefs=False); self.starts=[]; self.ends=[]
    def handle_starttag(self,tag,attrs): self.starts.append(tag.lower())
    def handle_startendtag(self,tag,attrs): self.starts.append(tag.lower())
    def handle_endtag(self,tag): self.ends.append(tag.lower())

def validate_fragments(parts):
    if not parts or not parts[0].lstrip().lower().startswith('<!doctype html>'): raise RuntimeError('MAIN1_HTML_SHELL_MISSING')
    if not INLINE_RE.search(parts[0]): raise RuntimeError('MAIN1_OPEN_SCRIPT_BOUNDARY_MISSING')
    return [{'part':idx,'bytes':len(part.encode('utf-8')),'lines':part.count('\n')+1} for idx,part in enumerate(parts,1)]

def delimiter_diagnostics(js):
    # Diagnostic-only lexical scanner. Strings/comments/templates are ignored; JS regex literals
    # are treated as opaque where detectable to avoid counting braces inside regex character classes.
    pairs={')':'(',']':'[','}':'{'}; opens={'(','[','{'}; stack=[]
    state='code'; quote=''; esc=False; template_depth=0; line=1; col=0; i=0; regex_allowed=True
    ident_re=re.compile(r'[A-Za-z_$][\w$]*')
    while i<len(js):
        ch=js[i]; col+=1
        if ch=='\n': line+=1; col=0
        if state=='line_comment':
            if ch=='\n': state='code'
            i+=1; continue
        if state=='block_comment':
            if ch=='*' and i+1<len(js) and js[i+1]=='/': state='code'; i+=2; col+=1; continue
            i+=1; continue
        if state in ('single','double'):
            if esc: esc=False
            elif ch=='\\': esc=True
            elif ch==quote: state='code'; regex_allowed=False
            i+=1; continue
        if state=='regex':
            if esc: esc=False
            elif ch=='\\': esc=True
            elif ch=='[': regex_allowed=False
            elif ch==']': regex_allowed=True
            elif ch=='/' and regex_allowed:
                state='code'; regex_allowed=False; i+=1
                while i<len(js) and js[i].isalpha(): i+=1
                continue
            i+=1; continue
        if state=='template':
            if esc: esc=False; i+=1; continue
            if ch=='\\': esc=True; i+=1; continue
            if ch=='`' and template_depth==0: state='code'; regex_allowed=False; i+=1; continue
            if ch=='$' and i+1<len(js) and js[i+1]=='{': stack.append(('{',line,col,'template-expr')); template_depth+=1; state='code'; regex_allowed=True; i+=2; col+=1; continue
            i+=1; continue
        if ch=='/' and i+1<len(js) and js[i+1]=='/': state='line_comment'; i+=2; col+=1; continue
        if ch=='/' and i+1<len(js) and js[i+1]=='*': state='block_comment'; i+=2; col+=1; continue
        if ch in "'\"": quote=ch; state='single' if ch=="'" else 'double'; i+=1; continue
        if ch=='`': state='template'; template_depth=0; i+=1; continue
        if ch=='/' and regex_allowed:
            state='regex'; regex_allowed=False; i+=1; continue
        if ch in opens: stack.append((ch,line,col,'code')); regex_allowed=True
        elif ch in pairs:
            expected=pairs[ch]
            if not stack or stack[-1][0]!=expected:
                return {'status':'MISMATCH','at':(line,col,ch),'offending_line':js.splitlines()[line-1] if line-1<len(js.splitlines()) else '','top':stack[-12:]}
            opener=stack.pop()
            regex_allowed=False
            if opener[3]=='template-expr' and ch=='}':
                template_depth=max(0,template_depth-1)
                if template_depth==0: state='template'
        elif ch.strip():
            # Conservative token heuristic: after these tokens a slash may start a regex.
            if ch in '([{=,:;!&|?+-*%^~<>': regex_allowed=True
            elif js[i:i+3] in ('let','var','new'): regex_allowed=True
            else: regex_allowed=False
        i+=1
    return {'status':'UNBALANCED' if stack or state!='code' else 'BALANCED','stack':stack[-20:],'state':state,'template_depth':template_depth,'lines':line}

def _app_js(s):
    apps=[m.group(1) for m in re.finditer(r'<script(?![^>]*\bsrc\s*=)[^>]*>([\s\S]*?)</script>',s,re.I) if 'serviceWorker.register' not in m.group(1)]
    if len(apps)!=1: raise RuntimeError('APPLICATION_INLINE_SCRIPT_COUNT:'+str(len(apps)))
    return apps[0]

def validate(s):
    start=s.lstrip().lower(); required=['window.RW_Auth','window.RW_Navigation','window.RW_Views','window.RW_OwnerLicense','var RW_Dashboard','var RW_Items','window.RW_Items=RW_Items;','RW_SUPABASE_CLIENT','MAIN3']; missing=[x for x in required if x not in s]
    if missing: raise RuntimeError('CURRENT_CONTRACT_MISSING:'+repr(missing))
    parser=StructureParser(); parser.feed(s); parser.close(); ah=parser.starts.count('html'); eh=parser.ends.count('html'); ab=parser.starts.count('body'); eb=parser.ends.count('body'); ass=parser.starts.count('script'); ess=parser.ends.count('script'); ast=parser.starts.count('style'); est=parser.ends.count('style')
    gates={'doctype_start':start.startswith('<!doctype html>'),'one_html_root':ah==1 and eh==1,'one_body_root':ab==1 and eb==1,'script_balance':ass==ess,'style_balance':ast==est,'auth_one':s.count(AUTH)==1,'version_one':s.count(VERSION)==1,'governed_one':s.count(GOVERNED)==1,'compat_absent':COMPAT not in s,'dash_alias_absent':not re.search(r'window\.RW_Dashboard\s*=\s*\{\s*render\s*:\s*renderDashboard\s*\}',s),'items_alias_absent':not re.search(r'window\.RW_Items\s*=\s*\{\s*render\s*:\s*renderItems\s*\}',s),'dash_owner_one':len(re.findall(r'(?m)^\s*var\s+RW_Dashboard\s*=\s*',s))==1,'items_owner_one':len(re.findall(r'(?m)^\s*var\s+RW_Items\s*=\s*',s))==1,'items_export_one':s.count('window.RW_Items=RW_Items;')==1,'canonical_sw_one':s.count(CANONICAL_SW)==1,'rpc_present':'.rpc(' in s,'edge_present':'/functions/v1/' in s}; bad=[k for k,v in gates.items() if not v]
    if bad: raise RuntimeError(f'P163_GOLD_GATE_FAIL:{bad} structural html={ah}/{eh} body={ab}/{eb} script={ass}/{ess} style={ast}/{est}')
    js=_app_js(s); diag=delimiter_diagnostics(js)
    if diag['status']!='BALANCED': raise RuntimeError('JS_DELIMITER_DIAG:'+repr(diag))
    path=Path(tempfile.gettempdir())/'rawaea-new-main.js'; path.write_text(js,encoding='utf-8'); r=subprocess.run(['node','--check',str(path)],capture_output=True,text=True)
    if r.returncode: print(r.stderr); raise RuntimeError('FINAL_JS_SYNTAX_FAIL')
    return gates

def main():
    parts=[]
    for idx,p in enumerate(PARTS,1):
        if not p.is_file() or not p.stat().st_size: raise RuntimeError('MISSING_PART:'+str(p))
        raw=p.read_text(encoding='utf-8-sig'); parts.append(normalize_main1(raw) if idx==1 else normalize_fragment(raw,idx))
    phases=validate_fragments(parts); candidate=parts[0]+'\n\n'+'\n\n'.join(parts[1:])+'\n\n</script>\n</body>\n</html>\n'; candidate=p163(candidate); candidate=inject_canonical_sw(candidate); gates=validate(candidate)
    tmp=MAIN.with_suffix('.tmp'); tmp.write_text(candidate,encoding='utf-8'); tmp.replace(MAIN); print({'status':'NEW_MAIN_GOLD_DIAMOND_READY','target':str(MAIN),'sha256':hashlib.sha256(candidate.encode()).hexdigest(),'bytes':len(candidate.encode()),'gates':gates,'phase_report':phases})

if __name__=='__main__': main()
