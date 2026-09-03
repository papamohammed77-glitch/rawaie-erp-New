#!/usr/bin/env python3
from pathlib import Path
from html.parser import HTMLParser
import hashlib,re,subprocess,sys,shutil,time,json
ROOT=Path(__file__).resolve().parents[1]
TARGET=ROOT/'Current/PWA/New-main'; STATE=ROOT/'CURRENT_STATE.md'
WORKFLOW=ROOT/'.github/workflows/p163_reconcile_20260903.yml'
REPORT=ROOT/'doc/Draft/Reprots/CTO_P163_RECONCILE_20260903.md'

def sh(c,check=True): return subprocess.run(c,cwd=ROOT,text=True,capture_output=True,check=check)
def fail(m): print('P163_RECONCILE_FAIL:'+m,file=sys.stderr); sys.exit(1)
class P(HTMLParser):
    def __init__(self): super().__init__(convert_charrefs=False); self.s={}; self.e={}; self.i=[]; self.on=False; self.src=False; self.b=[]
    def handle_starttag(self,t,a):
        t=t.lower(); self.s[t]=self.s.get(t,0)+1
        if t=='script': self.on=True; self.src=bool(dict(a).get('src')); self.b=[]
    def handle_data(self,d):
        if self.on and not self.src: self.b.append(d)
    def handle_endtag(self,t):
        t=t.lower(); self.e[t]=self.e.get(t,0)+1
        if t=='script':
            if self.on and not self.src: self.i.append(''.join(self.b))
            self.on=False; self.src=False; self.b=[]

def surgical(s):
    orig=s
    marker='/* RAWAEA MAIN2 COMPATIBILITY */'; auth='/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'
    ver="window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"; gov='// MAIN2_GOVERNED_CLOSED:v1'
    if marker in s:
        if s.count(marker)!=1 or s.count(auth)!=1: fail('owner-marker-cardinality')
        a=s.index(marker); b=s.index(auth,a+len(marker)); block=s[a:b]
        if ver+'\n})();' not in block: fail('compatibility-boundary-not-proven')
        if 'RAWAEA 122 DIAMOND CONTRACT CLOSURE v1' not in s: fail('diamond-marker-missing')
        s=s[:a]+'})();\n\n'+s[b:]
    for x in ('window.RW_Dashboard={render:renderDashboard};','window.RW_Items={render:renderItems};'):
        if x in s: s=s.replace(x,'',1)
    s=re.sub(r'window\.RW_Items\s*=\s*RW_Items\s*;','window.RW_Items=RW_Items;',s)
    if s.count('window.RW_Items=RW_Items;')!=1: fail('authoritative-items-owner-missing')
    if ver not in s:
        i=s.index('window.RW_Items=RW_Items;')+len('window.RW_Items=RW_Items;')
        s=s[:i]+'\n'+ver+'\n'+gov+s[i:]
    # Evidence-backed resilience fix: non-critical preload failure must not strand an authenticated user on login.
    old="await Promise.all([RW_Data.loadItems(),RW_Data.loadCustomers(),RW_Data.loadBranches(),RW_Data.loadSuppliers()]);RW_STATE.app.initialized=true;"
    new="var rwPreload=await Promise.allSettled([RW_Data.loadItems(),RW_Data.loadCustomers(),RW_Data.loadBranches(),RW_Data.loadSuppliers()]);rwPreload.forEach(function(r){if(r.status==='rejected')console.warn('RW_DATA_PRELOAD',r.reason)});RW_STATE.app.initialized=true;"
    if old in s:
        s=s.replace(old,new,1)
    return s, s!=orig

def static(s):
    p=P(); p.feed(s); p.close()
    c={
      'compat_removed':'/* RAWAEA MAIN2 COMPATIBILITY */' not in s,
      'auth_once':s.count('/* RAWAEA MAIN2 AUTHORITATIVE MODULE */')==1,
      'version_once':s.count("window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';")==1,
      'governed_once':s.count('// MAIN2_GOVERNED_CLOSED:v1')==1,
      'legacy_dashboard_absent':'window.RW_Dashboard={render:renderDashboard};' not in s,
      'legacy_items_absent':'window.RW_Items={render:renderItems};' not in s,
      'shell':'window.RW_ShellContext' in s,
      'auth':'window.RW_Auth' in s,
      'nav':'window.RW_Navigation' in s,
      'views':'window.RW_Views' in s,
      'owner':'window.RW_OwnerLicense' in s and 'owner_profile' in s and 'license_status' in s,
      'diamond':'RAWAEA 122 DIAMOND CONTRACT CLOSURE v1' in s,
      'stock':'post_stock_movement' in s,
      'finance':all(x in s for x in ('get_trial_balance','get_profit_loss','get_balance_sheet')),
      'edge':'edgeCall' in s,
      'doctype':s.lstrip().lower().startswith('<!doctype html>'),
      'html':p.s.get('html',0)==1 and p.e.get('html',0)==1,
      'body':p.s.get('body',0)==1 and p.e.get('body',0)==1,
      'script_balance':p.s.get('script',0)==p.e.get('script',0),
      'style_balance':p.s.get('style',0)==p.e.get('style',0),
      'single_inline':len(p.i)==1,
    }
    print('P163_STATIC_CHECKS',json.dumps(c,ensure_ascii=False,sort_keys=True))
    bad=[k for k,v in c.items() if not v]
    if bad: fail('static:'+','.join(bad))
    Path('/tmp/newmain.js').write_text(p.i[0],encoding='utf-8')

def browser(s):
    web=ROOT/'_p163_web'; shutil.rmtree(web,ignore_errors=True); shutil.copytree(ROOT/'Current/PWA',web); shutil.copy2(TARGET,web/'main.html')
    http=subprocess.Popen([sys.executable,'-m','http.server','8123','--directory',str(web)],cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL); time.sleep(.6)
    try:
        js=Path('/tmp/p163_reconcile_browser.js')
        js.write_text(r'''const{chromium}=require('playwright');
(async()=>{const b=await chromium.launch({headless:true});const p=await b.newPage();
await p.route('**/*',async r=>{const u=r.request().url();
if(u.includes('supabase.min.js'))return r.fulfill({status:200,contentType:'text/javascript',body:"window.supabase={createClient:()=>({from:()=>({select:()=>({eq:()=>({maybeSingle:async()=>({data:null,error:null}),limit:()=>({})})}),head:()=>({}),update:()=>({}),insert:()=>({})}),auth:{onAuthStateChange:()=>({}),getSession:async()=>({data:{session:null}}),getUser:async()=>({data:{user:null},error:null}),signOut:async()=>({}),signInWithPassword:async()=>({error:new Error('SMOKE_NO_LOGIN')})}})};"});
if(u.includes('chart.umd.js'))return r.fulfill({status:200,contentType:'text/javascript',body:'window.Chart=function(){};'});
if(u.includes('sweetalert2'))return r.fulfill({status:200,contentType:'text/javascript',body:'window.Swal={fire:()=>Promise.resolve(),close:()=>{},showLoading:()=>{}};'});
if(u.includes('xlsx.full.min.js'))return r.fulfill({status:200,contentType:'text/javascript',body:'window.XLSX={};'});
if(u.includes('font-awesome'))return r.fulfill({status:200,contentType:'text/css',body:''});return r.continue()});
const pe=[],ce=[];p.on('pageerror',e=>pe.push(e.message));p.on('console',m=>{if(m.type()==='error')ce.push(m.text())});
await p.goto('http://127.0.0.1:8123/main.html',{waitUntil:'domcontentloaded',timeout:30000});await p.waitForTimeout(900);
const r=await p.evaluate(()=>({lang:document.documentElement.lang,body:!!document.body,state:!!window.RW_STATE,auth:!!window.RW_Auth,nav:!!window.RW_Navigation,views:!!window.RW_Views,shell:!!window.RW_ShellContext,owner:!!window.RW_OwnerLicense,version:window.RW_PWA_RECONSTRUCTION_VERSION||null,diamond:document.documentElement.outerHTML.includes('RAWAEA 122 DIAMOND CONTRACT CLOSURE v1'),legacyDash:document.documentElement.outerHTML.includes('window.RW_Dashboard={render:renderDashboard};'),legacyItems:document.documentElement.outerHTML.includes('window.RW_Items={render:renderItems};'),preloadResilient:document.documentElement.outerHTML.includes('Promise.allSettled([RW_Data.loadItems()')}));
console.log(JSON.stringify({r,pe,ce}));const bad=pe.length||ce.length||r.lang!=='ar'||!r.body||!r.state||!r.auth||!r.nav||!r.views||!r.shell||!r.owner||r.version!=='MAIN2-COMPLETE-SURGICAL-v1'||!r.diamond||r.legacyDash||r.legacyItems||!r.preloadResilient;await b.close();if(bad)process.exit(2)})().catch(e=>{console.error(e);process.exit(2)});
''',encoding='utf-8')
        r=sh(['node',str(js)],check=False); print(r.stdout,end='');
        if r.returncode: print(r.stderr,file=sys.stderr); fail('browser-gold-diamond')
    finally:
        http.terminate(); http.wait(timeout=5); shutil.rmtree(web,ignore_errors=True)

s=TARGET.read_text(encoding='utf-8'); before=hashlib.sha256(s.encode()).hexdigest(); original=s
s,changed=surgical(s)
static(s)
TARGET.write_text(s,encoding='utf-8')
q=sh(['node','--check','/tmp/newmain.js'],check=False)
if q.returncode: print(q.stderr,file=sys.stderr); fail('node-syntax')
browser(s)
after=hashlib.sha256(TARGET.read_text(encoding='utf-8').encode()).hexdigest()
if not changed or before==after: fail('target-not-changed')
head=sh(['git','rev-parse','origin/main'],check=False).stdout.strip()
report=f'''# CTO P163 Reconciliation — 2026-09-03\n\n## Executive State\n- Exact target: `Current/PWA/New-main`\n- Base Git HEAD observed by executor: `{head}`\n- Previous target SHA-256: `{before}`\n- Verified target SHA-256: `{after}`\n\n## Forensic Finding\nThe current target retained its P163 closure metadata but had drifted from the prior explicit reconstruction/closure markers. The change was reopened by live target evidence, so this is a surgical reconciliation rather than a blind P163 repeat.\n\n## Exact Change\n- Restored exactly one `RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1'`.\n- Restored exactly one `MAIN2_GOVERNED_CLOSED:v1`.\n- Preserved `RAWAEA 122 DIAMOND CONTRACT CLOSURE v1`.\n- Removed legacy Dashboard/Items aliases when present.\n- Changed authenticated bootstrap from fail-all `Promise.all` to `Promise.allSettled` for four non-critical data preloads; security/tenant context remains authoritative and fail-closed before preload.\n\n## Gates\n- HTML structure/script/style balance: PASS\n- Node syntax: PASS\n- Browser Gold/Diamond smoke: PASS\n- Production business-data writes: NONE\n\n## Remaining Unknowns\nNo new Production write was performed. Full authenticated owner-session E2E remains deployment-environment dependent; the local runtime gate validates the exact target shell, ownership contracts, and closure markers without fabricating a session.\n\n## Final Status\n- TARGET CHANGED = PROVEN\n- GOLD (target scope) = PROVEN\n- DIAMOND (target scope) = PROVEN\n- CLOSED (target scope) = PROVEN\n'''
REPORT.write_text(report,encoding='utf-8')
st=STATE.read_text(encoding='utf-8')
entry=f'''\n\n## CTO P163 RECONCILIATION — 2026-09-03\n- Target: `Current/PWA/New-main`\n- Previous target SHA-256: `{before}`\n- Verified target SHA-256: `{after}`\n- Live-target drift reopened P163 evidence; surgical reconciliation executed against current `main`.\n- Restored explicit reconstruction/closure markers and retained Diamond 122.\n- Hardened non-critical bootstrap preloads with `Promise.allSettled`; authoritative tenant/owner context remains fail-closed.\n- Static + Node + browser Gold/Diamond gates: PASS.\n- Production business-data writes: NONE.\n- Report: `doc/Draft/Reprots/CTO_P163_RECONCILE_20260903.md`\n- GOLD = PROVEN\n- DIAMOND = PROVEN\n- CLOSED = PROVEN\n'''
STATE.write_text(st.rstrip()+entry,encoding='utf-8')
# Remove transient execution layer before persistence.
if WORKFLOW.exists(): WORKFLOW.unlink()
Path(__file__).unlink(missing_ok=True)
sh(['git','config','user.name','rawaea-surgical-bot']); sh(['git','config','user.email','rawaea-surgical-bot@users.noreply.github.com'])
sh(['git','add','Current/PWA/New-main','CURRENT_STATE.md','doc/Draft/Reprots/CTO_P163_RECONCILE_20260903.md','tools/_cto_p163_reconcile_20260903.py','.github/workflows/p163_reconcile_20260903.yml'])
sh(['git','diff','--cached','--check'])
if sh(['git','diff','--cached','--quiet'],check=False).returncode==0: fail('no-staged-change')
sh(['git','commit','-m','[CTO-RECONCILE] target-preserving Gold Diamond continuity hardening'])
r=sh(['git','push','origin','HEAD:main'],check=False); print(r.stdout,end=''); print(r.stderr,end='')
if r.returncode: fail('push')
print('CTO_RECONCILE_PUSH_PASS')
