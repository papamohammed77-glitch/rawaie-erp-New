#!/usr/bin/env python3
import hashlib, http.server, os, re, socketserver, subprocess, threading, time
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / 'Current' / 'PWA' / 'New-main'
STATE = ROOT / 'CURRENT_STATE.md'
WORKFLOW = ROOT / '.github' / 'workflows' / 'p163_final_close_20260903.yml'
VERSION = "window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"
DIAMOND = 'RAWAEA 122 DIAMOND CONTRACT CLOSURE v1'
AUTH = '/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'
COMPAT = '/* RAWAEA MAIN2 COMPATIBILITY */'
CLOSED = '// MAIN2_GOVERNED_CLOSED:v1'

def run(cmd, check=True, capture=True, cwd=ROOT):
    return subprocess.run(cmd, cwd=cwd, check=check, text=True, stdout=subprocess.PIPE if capture else None, stderr=subprocess.STDOUT if capture else None)
def git(*args, check=True): return run(['git',*args],check=check)
def sha256(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
    return h.hexdigest()
def sync_latest():
    run(['git','fetch','origin','main']); run(['git','reset','--hard','origin/main'])

def surgical_edit(text):
    if AUTH not in text or text.count(AUTH)!=1: raise RuntimeError('P163_FAIL: authoritative marker cardinality')
    if DIAMOND not in text: raise RuntimeError('P163_FAIL: diamond marker missing')
    if COMPAT not in text: raise RuntimeError('P163_FAIL: compatibility surface absent before surgery')
    a=text.index(COMPAT); b=text.index(AUTH,a+len(COMPAT)); block=text[a:b]
    if VERSION not in block: raise RuntimeError('P163_FAIL: compatibility version missing')
    closes=list(re.finditer(r'\}\)\(\);',block))
    if not closes: raise RuntimeError('P163_FAIL: compatibility IIFE close missing')
    if 'renderDashboard' not in block[:closes[-1].start()] and 'renderItems' not in block[:closes[-1].start()]: raise RuntimeError('P163_FAIL: compatibility shape unexpected')
    replacement=block[closes[-1].start():closes[-1].end()]
    text=text[:a]+replacement+'\n\n'+text[b:]
    text=text.replace('window.RW_Dashboard={render:renderDashboard};','').replace('window.RW_Items={render:renderItems};','')
    text=re.sub(r'window\.RW_Items\s*=\s*RW_Items\s*;','window.RW_Items=RW_Items;',text)
    text=text.replace(VERSION,'').replace(CLOSED,'')
    i=text.index(AUTH)+len(AUTH); text=text[:i]+'\n'+VERSION+'\n'+CLOSED+'\n'+text[i:]
    if COMPAT in text: raise RuntimeError('P163_FAIL: compatibility remains')
    if text.count(AUTH)!=1 or text.count(DIAMOND)!=1: raise RuntimeError('P163_FAIL: marker cardinality')
    if text.count(VERSION)!=1 or text.count(CLOSED)!=1: raise RuntimeError('P163_FAIL: version/closed cardinality')
    if 'window.RW_Dashboard={render:renderDashboard};' in text or 'window.RW_Items={render:renderItems};' in text: raise RuntimeError('P163_FAIL: legacy aliases remain')
    required=['RW_ShellContext','RW_Auth','RW_Navigation','RW_Views','RW_OwnerLicense','MAIN3','MAIN11','function main1Delegation(','var actions=','post_stock_movement','get_trial_balance','get_profit_loss','get_balance_sheet','edgeCall',DIAMOND]
    missing=[x for x in required if x not in text]
    if missing: raise RuntimeError('P163_FAIL: required contracts missing: '+', '.join(missing))
    return text

class GateParser(HTMLParser):
    def __init__(self): super().__init__(convert_charrefs=False); self.scripts=[]; self.styles=0; self.cur=None
    def handle_starttag(self,tag,attrs):
        d=dict(attrs)
        if tag.lower()=='style': self.styles+=1
        if tag.lower()=='script': self.cur={'src':d.get('src'),'text':''}; self.scripts.append(self.cur)
    def handle_data(self,data):
        if self.cur is not None: self.cur['text']+=data
    def handle_endtag(self,tag):
        if tag.lower()=='script': self.cur=None

def static_gate():
    p=GateParser(); p.feed(TARGET.read_text(encoding='utf-8')); p.close()
    inline=[s['text'] for s in p.scripts if s['src'] is None and s['text'].strip()]
    if not inline: raise RuntimeError('STATIC_FAIL: no inline script')
    for n,js in enumerate(inline):
        q=ROOT/f'.p163_inline_{n}.js'; q.write_text(js,encoding='utf-8')
        try:
            r=run(['node','--check',str(q)],check=False)
            if r.returncode: raise RuntimeError(f'STATIC_FAIL: inline {n}\n{r.stdout[-4000:]}')
        finally: q.unlink(missing_ok=True)
    return {'scripts':len(p.scripts),'styles':p.styles,'inline':len(inline)}

def browser_gate():
    import json
    port=8123
    class Handler(http.server.SimpleHTTPRequestHandler):
        def log_message(self,*args): pass
    os.chdir(ROOT); srv=socketserver.TCPServer(('127.0.0.1',port),Handler); threading.Thread(target=srv.serve_forever,daemon=True).start(); time.sleep(.3)
    q=ROOT/'.p163_browser_gate.mjs'
    q.write_text("""
import { chromium } from 'playwright';
const browser=await chromium.launch({headless:true}); const page=await browser.newPage(); const errors=[];
page.on('pageerror',e=>errors.push('pageerror:'+e.message)); page.on('console',m=>{if(m.type()==='error')errors.push('console:'+m.text())});
await page.goto('http://127.0.0.1:8123/Current/PWA/New-main',{waitUntil:'domcontentloaded',timeout:30000}); await page.waitForTimeout(1200);
const out=await page.evaluate(()=>({lang:document.documentElement.lang,auth:!!window.RW_Auth,nav:!!window.RW_Navigation,views:!!window.RW_Views,shell:!!window.RW_ShellContext,owner:!!window.RW_OwnerLicense,version:window.RW_PWA_RECONSTRUCTION_VERSION,diamond:document.documentElement.innerHTML.includes('RAWAEA 122 DIAMOND CONTRACT CLOSURE v1'),compat:document.documentElement.innerHTML.includes('RAWAEA MAIN2 COMPATIBILITY'),governed:document.documentElement.innerHTML.includes('MAIN2_GOVERNED_CLOSED:v1')}));
console.log(JSON.stringify({out,errors})); await browser.close();
""",encoding='utf-8')
    try:
        r=run(['node',str(q)],check=False)
        if r.returncode: raise RuntimeError('BROWSER_FAIL: '+r.stdout[-4000:])
        data=json.loads(r.stdout.strip().splitlines()[-1]); o=data['out']; errors=data['errors']
        if errors: raise RuntimeError('BROWSER_FAIL: '+repr(errors))
        exp={'lang':'ar','auth':True,'nav':True,'views':True,'shell':True,'owner':True,'version':'MAIN2-COMPLETE-SURGICAL-v1','diamond':True,'compat':False,'governed':True}
        if any(o.get(k)!=v for k,v in exp.items()): raise RuntimeError('BROWSER_FAIL: '+repr(o))
        return o
    finally: q.unlink(missing_ok=True); srv.shutdown(); srv.server_close()

def update_state(before,after,static,browser):
    old=STATE.read_text(encoding='utf-8') if STATE.exists() else ''
    old=re.sub(r'\n## CTO P163 CLOSED — 2026-09-03\n.*?(?=\n## |\Z)','',old,flags=re.S)
    old=re.sub(r'\n## GOLD / DIAMOND STATUS\n```text\n.*?```','\n## GOLD / DIAMOND STATUS\n```text\nGOLD    = PROVEN\nDIAMOND = PROVEN\nCLOSED  = PROVEN\n```',old,flags=re.S)
    sec=f"""

## CTO P163 CLOSED — 2026-09-03 (DIRECTLY VERIFIED)
- Target: `Current/PWA/New-main`
- Previous SHA-256: `{before}`
- Verified SHA-256: `{after}`
- Target-preserving surgical ownership closure executed against latest fetched `origin/main`; no fragment reconstruction.
- Compatibility overlay removed while preserving its IIFE closure; authoritative MAIN2 owner retained exactly once.
- Legacy Dashboard/Items aliases removed; governed/version markers normalized exactly once.
- Static HTMLParser + Node syntax gates: PASS (`scripts={static['scripts']}`, `styles={static['styles']}`, `inline={static['inline']}`).
- Browser Gold contract gate: PASS (`lang=ar`; Auth/Navigation/Views/Shell/Owner globals present; exact version; no page/console errors).
- Diamond closure marker preserved exactly once; compatibility marker absent at runtime.
- GOLD = PROVEN
- DIAMOND = PROVEN
- CLOSED = PROVEN
"""
    STATE.write_text(old.rstrip()+sec,encoding='utf-8')

def commit_push():
    if WORKFLOW.exists(): WORKFLOW.unlink()
    Path(__file__).unlink(missing_ok=True)
    run(['git','add','Current/PWA/New-main','CURRENT_STATE.md','.github/workflows/p163_final_close_20260903.yml','tools/_cto_p163_direct_20260903.py'])
    staged=git('diff','--cached','--name-only').stdout.splitlines()
    expected={'Current/PWA/New-main','CURRENT_STATE.md','.github/workflows/p163_final_close_20260903.yml','tools/_cto_p163_direct_20260903.py'}
    if set(staged)!=expected: raise RuntimeError('P163_FAIL: staged paths unexpected: '+repr(staged))
    run(['git','config','user.name','cto-p163-executor']); run(['git','config','user.email','cto-p163-executor@users.noreply.github.com'])
    git('commit','-m','[P163-EXECUTED] close New-main target-preserving Gold Diamond')
    r=run(['git','push','origin','HEAD:main'],check=False); return r.returncode,r.stdout

def main():
    last=''
    for attempt in range(1,9):
        try:
            sync_latest(); before=sha256(TARGET); text=TARGET.read_text(encoding='utf-8'); edited=surgical_edit(text)
            if edited==text: raise RuntimeError('P163_FAIL: target did not change')
            TARGET.write_text(edited,encoding='utf-8'); static=static_gate(); browser=browser_gate(); after=sha256(TARGET)
            if before==after: raise RuntimeError('P163_FAIL: SHA unchanged')
            update_state(before,after,static,browser); rc,out=commit_push()
            if rc==0: print('P163_SUCCESS',before,after); return 0
            last=out[-4000:]; print('P163_PUSH_RACE',attempt,last)
        except Exception as e: last=str(e); print('P163_RETRY',attempt,last)
    raise SystemExit('P163_ABORT: '+last)
if __name__=='__main__': main()
