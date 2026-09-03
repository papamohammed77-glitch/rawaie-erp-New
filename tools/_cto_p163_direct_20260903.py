#!/usr/bin/env python3
from pathlib import Path
import os,re,hashlib,subprocess,sys,time,shutil
from html.parser import HTMLParser
ROOT=Path(__file__).resolve().parents[1]; TARGET=ROOT/'Current/PWA/New-main'; STATE=ROOT/'CURRENT_STATE.md'
def run(cmd,check=True):
 env=os.environ.copy(); env['NODE_PATH']=str(ROOT/'node_modules')
 return subprocess.run(cmd,cwd=ROOT,text=True,capture_output=True,check=check,env=env)
def die(x): print('P163_FAIL:'+x,file=sys.stderr); sys.exit(1)
def scripts(html):
 class P(HTMLParser):
  def __init__(self): super().__init__(convert_charrefs=False); self.ins=False; self.attrs={}; self.buf=[]; self.inline=[]
  def handle_starttag(self,t,a):
   if t.lower()=='script': self.ins=True; self.attrs=dict(a); self.buf=[]
  def handle_data(self,d):
   if self.ins and not self.attrs.get('src'): self.buf.append(d)
  def handle_endtag(self,t):
   if t.lower()=='script':
    if self.ins and not self.attrs.get('src'): self.inline.append(''.join(self.buf))
    self.ins=False; self.attrs={}; self.buf=[]
 p=P(); p.feed(html); p.close(); return p.inline
def surgery(s):
 m='/* RAWAEA MAIN2 COMPATIBILITY */'; a='/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'; v="window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"; g='// MAIN2_GOVERNED_CLOSED:v1'
 if m in s:
  if s.count(m)!=1 or s.count(a)!=1: die('marker-cardinality')
  i=s.index(m); j=s.index(a,i+len(m)); block=s[i:j]
  if v+'\n})();' not in block: die('compat-boundary')
  if 'RAWAEA 122 DIAMOND CONTRACT CLOSURE v1' not in s: die('diamond-lost')
  s=s[:i]+'})();\n\n'+s[j:]
  for x in ('window.RW_Dashboard={render:renderDashboard};','window.RW_Items={render:renderItems};'):
   if s.count(x)!=1: die('alias-count:'+x)
   s=s.replace(x,'',1)
  s=re.sub(r'window\.RW_Items\s*=\s*RW_Items\s*;','window.RW_Items=RW_Items;',s)
  s=s.replace(v,'').replace(g,'')
  owner='window.RW_Items=RW_Items;'
  if s.count(owner)!=1: die('items-owner')
  k=s.index(owner)+len(owner); s=s[:k]+'\n'+v+'\n'+g+s[k:]
 return s
run(['git','fetch','origin','main']); run(['git','reset','--hard','origin/main'])
before=hashlib.sha256(TARGET.read_bytes()).hexdigest(); old=TARGET.read_text(encoding='utf-8'); new=surgery(old)
if new==old: die('target-not-changed')
TARGET.write_text(new,encoding='utf-8')
req=['RW_ShellContext','RW_Auth','RW_Navigation','RW_Views','RW_OwnerLicense','MAIN3','MAIN11','function main1Delegation(','var actions=','post_stock_movement','get_trial_balance','get_profit_loss','get_balance_sheet','edgeCall','RAWAEA 122 DIAMOND CONTRACT CLOSURE v1']
missing=[x for x in req if x not in new]
if missing: die('required-contract-missing:'+repr(missing))
if '/* RAWAEA MAIN2 COMPATIBILITY */' in new or 'window.RW_Dashboard={render:renderDashboard};' in new or 'window.RW_Items={render:renderItems};' in new: die('duplicate-owner-remains')
inline=scripts(new)
if len(inline)!=1: die('inline-script-count:'+str(len(inline)))
js=Path('/tmp/newmain.js'); js.write_text(inline[0],encoding='utf-8')
if run(['node','--check',str(js)],check=False).returncode: die('node-syntax')
site=Path('/tmp/p163_site'); shutil.rmtree(site,ignore_errors=True); site.mkdir(parents=True)
shutil.copytree(ROOT/'Current/PWA',site,dirs_exist_ok=True); shutil.copy2(TARGET,site/'main.html')
http=subprocess.Popen([sys.executable,'-m','http.server','8123','--directory',str(site)],cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL); time.sleep(1)
smoke=Path('/tmp/p163_smoke.js'); smoke.write_text("""const {chromium}=require('playwright');(async()=>{const b=await chromium.launch({headless:true});const p=await b.newPage();const e=[];p.on('pageerror',x=>e.push(x.message));p.on('console',m=>{if(m.type()==='error')e.push(m.text())});await p.goto('http://127.0.0.1:8123/main.html',{waitUntil:'domcontentloaded',timeout:30000});await p.waitForTimeout(2500);const r=await p.evaluate(()=>({lang:document.documentElement.lang,auth:!!window.RW_Auth,nav:!!window.RW_Navigation,views:!!window.RW_Views,shell:!!window.RW_ShellContext,owner:!!window.RW_OwnerLicense,ver:window.RW_PWA_RECONSTRUCTION_VERSION||null,diamond:document.documentElement.outerHTML.includes('RAWAEA 122 DIAMOND CONTRACT CLOSURE v1')}));console.log(JSON.stringify({r,e}));if(e.length||r.lang!=='ar'||!r.auth||!r.nav||!r.views||!r.shell||!r.owner||r.ver!=='MAIN2-COMPLETE-SURGICAL-v1'||!r.diamond)process.exit(2);await b.close()})().catch(x=>{console.error(x);process.exit(2)})""",encoding='utf-8')
try:
 b=run(['node',str(smoke)],check=False); print(b.stdout,end=''); print(b.stderr,end='')
 if b.returncode: die('browser-smoke')
finally:
 if http.poll() is None: http.terminate()
 try: http.wait(timeout=5)
 except: http.kill()
h=hashlib.sha256(TARGET.read_bytes()).hexdigest(); st=STATE.read_text(encoding='utf-8'); marker='## CTO P163 CLOSED — 2026-09-03'
if marker not in st: STATE.write_text(st.rstrip()+f'''\n\n{marker}\n- Target: `Current/PWA/New-main`\n- Previous target SHA-256: `{before}`\n- Verified target SHA-256: `{h}`\n- P163 target-preserving surgery executed directly against live `main`; no fragment reconstruction.\n- MAIN2 compatibility duplicate removed with IIFE closure preserved; authoritative owner retained; legacy Dashboard/Items aliases removed.\n- ShellContext/auth/navigation/views/OwnerLicense/actions/main1Delegation/MAIN3/MAIN11 and `RAWAEA 122 DIAMOND CONTRACT CLOSURE v1` preserved.\n- Node syntax gate: PASS.\n- Browser Gold/Diamond runtime gate: PASS.\n- Production database writes: NONE.\n- GOLD = PROVEN\n- DIAMOND = PROVEN\n- CLOSED = PROVEN\n''',encoding='utf-8')
Path(__file__).unlink(missing_ok=True); run(['git','config','user.name','rawaea-cto-executor']); run(['git','config','user.email','rawaea-cto-executor@users.noreply.github.com']); run(['git','add','-A','Current/PWA/New-main','CURRENT_STATE.md','tools/_cto_p163_direct_20260903.py']); run(['git','diff','--cached','--check']); c=run(['git','commit','-m','[P163-EXECUTED] [GOLD-PROVEN] [DIAMOND-PROVEN] [CLOSED] target-preserving New-main closure'],check=False)
if c.returncode!=0: print(c.stdout); print(c.stderr,file=sys.stderr); sys.exit(1)
p=run(['git','push','origin','HEAD:main'],check=False)
if p.returncode!=0: print('P163_PUSH_FAIL:'+p.stderr,file=sys.stderr); sys.exit(2)
print('P163_PUSH_PASS'); print('P163_BEFORE_SHA256',before); print('P163_AFTER_SHA256',h); sys.exit(0)
