from pathlib import Path
import hashlib,re,subprocess,tempfile

PARTS=Path('Current/PWA/main')
TARGET=Path('Current/PWA/New-main')
LEGACY=Path('Current/PWA/main.html')

# CTO-EXECUTE-2026-09-03: canonical eleven-part reconstruction; no auxiliary app file.

def sha(s): return hashlib.sha256(s.encode('utf-8')).hexdigest()

def main():
    chunks=[]
    for i in range(1,12):
        p=PARTS/f'main{i}.md'
        if not p.is_file() or not p.stat().st_size: raise RuntimeError('MISSING_PART:'+str(p))
        s=p.read_text(encoding='utf-8-sig')
        if i==1:
            s=re.sub(r'(?m)^\s*const RW_Auth\s*=\s*','var RW_Auth = ',s,count=1)
            s=re.sub(r'(?m)^\s*const RW_Navigation\s*=\s*','var RW_Navigation = ',s,count=1)
        if i==7:
            s=re.sub(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}",r"\1));}",s,count=1)
        if i>1 and re.search(r'^\s*<!doctype\b|^\s*</?(?:html|head|body)\b|</script>',s,re.I|re.M):
            raise RuntimeError('BAD_WRAPPER_MAIN'+str(i))
        s=re.sub(r'</body>\s*|</html>\s*','',s,flags=re.I)
        chunks.append(s.rstrip())
    s='\n\n'.join(chunks)+'\n\n</script>\n</body>\n</html>\n'
    if not LEGACY.exists() or not LEGACY.stat().st_size: raise RuntimeError('LEGACY_MAIN_MISSING')
    compat='/* RAWAEA MAIN2 COMPATIBILITY */'; auth='/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'
    cc=s.count(compat)
    if cc not in (0,1): raise RuntimeError('P163_COMPAT_COUNT:'+str(cc))
    if s.count(auth)!=1: raise RuntimeError('P163_AUTH_COUNT:'+str(s.count(auth)))
    if cc:
        a,b=s.index(compat),s.index(auth)
        if b<=a: raise RuntimeError('P163_OWNER_ORDER')
        s=s[:a]+s[b:]
    for x in ('window.RW_Dashboard={render:renderDashboard};','window.RW_Items={render:renderItems};'): s=s.replace(x,'')
    owner='window.RW_Items=RW_Items;'; ver="window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"; gov='// MAIN2_GOVERNED_CLOSED:v1'
    if s.count(owner)!=1: raise RuntimeError('P163_OWNER_EXPORT_COUNT:'+str(s.count(owner)))
    if ver in s or gov in s: raise RuntimeError('P163_MARKER_ALREADY_PRESENT')
    s=s.replace(owner,owner+'\n'+ver+'\n'+gov,1)
    s=s.replace('</body>','<script>window.RW_GOLD_DIAMOND={version:"v7",target:"Current/PWA/New-main",reconstruction:"MAIN1-MAIN11",owner:"strict",p163:"closed"};</script>\n</body>',1)
    if s.lower().count('<script')!=s.lower().count('</script>'): raise RuntimeError('SCRIPT_BALANCE')
    if s.lower().count('<style')!=s.lower().count('</style>'): raise RuntimeError('STYLE_BALANCE')
    inline=[m.group('b') for m in re.finditer(r'<script(?P<a>[^>]*)>(?P<b>[\s\S]*?)</script>',s,re.I) if not re.search(r'\bsrc\s*=',m.group('a') or '',re.I)]
    apps=[x for x in inline if 'RW_GOLD_DIAMOND' not in x]
    if len(apps)!=1: raise RuntimeError('INLINE_APP_SCRIPT_COUNT:'+str(len(apps)))
    f=Path(tempfile.gettempdir())/'rawaea-new-main.js';f.write_text(apps[0],encoding='utf-8')
    r=subprocess.run(['node','--check',str(f)],capture_output=True,text=True)
    if r.returncode:
        print(r.stderr); raise RuntimeError('FINAL_JS_SYNTAX_FAIL')
    TARGET.write_text(s,encoding='utf-8')
    print({'status':'READY_TO_PERSIST','sha256':sha(s),'bytes':len(s.encode()),'p163':'closed','gold_diamond':'v7'})

if __name__=='__main__': main()
