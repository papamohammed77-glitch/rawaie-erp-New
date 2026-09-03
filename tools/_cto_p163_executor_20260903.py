#!/usr/bin/env python3
# CTO LIVE EXECUTION TRIGGER — reuse verified target-preserving executor; no fragment reconstruction.
from pathlib import Path
from html.parser import HTMLParser
import hashlib,re,subprocess,sys,os,time

ROOT=Path(__file__).resolve().parents[1]
TARGET=ROOT/'Current/PWA/New-main'
STATE=ROOT/'CURRENT_STATE.md'


def sh(cmd, check=True):
    return subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True, check=check)


def fail(msg):
    print('P163_FAIL:'+msg, file=sys.stderr); sys.exit(1)


def html_checks(s):
    class T(HTMLParser):
        def __init__(self):
            super().__init__(convert_charrefs=False); self.starts={}; self.ends={}; self.inline=[]; self._script=False; self._attrs={}; self._buf=[]
        def handle_starttag(self,tag,attrs):
            tag=tag.lower(); self.starts[tag]=self.starts.get(tag,0)+1
            if tag=='script': self._script=True; self._attrs=dict(attrs); self._buf=[]
        def handle_data(self,data):
            if self._script and not self._attrs.get('src'): self._buf.append(data)
        def handle_endtag(self,tag):
            tag=tag.lower(); self.ends[tag]=self.ends.get(tag,0)+1
            if tag=='script':
                if self._script and not self._attrs.get('src'): self.inline.append(''.join(self._buf))
                self._script=False; self._attrs={}; self._buf=[]
    t=T(); t.feed(s); t.close()
    return t


def surgical_edit(s):
    marker='/* RAWAEA MAIN2 COMPATIBILITY */'; auth='/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'
    version="window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"; governed='// MAIN2_GOVERNED_CLOSED:v1'
    if marker in s:
        if s.count(marker)!=1 or s.count(auth)!=1: fail('owner marker cardinality')
        a=s.index(marker); b=s.index(auth,a+len(marker)); block=s[a:b]
        if version+'\n})();' not in block: fail('compatibility IIFE boundary not proven')
        if 'RAWAEA 122 DIAMOND CONTRACT CLOSURE v1' not in s: fail('diamond extension missing')
        s=s[:a]+'})();\n\n'+s[b:]
        for alias in ('window.RW_Dashboard={render:renderDashboard};','window.RW_Items={render:renderItems};'):
            if s.count(alias)!=1: fail('alias cardinality '+alias)
            s=s.replace(alias,'',1)
        s=re.sub(r'window\.RW_Items\s*=\s*RW_Items\s*;','window.RW_Items=RW_Items;',s)
        s=s.replace(version,'').replace(governed,'')
        owner='window.RW_Items=RW_Items;'
        if s.count(owner)!=1: fail('authoritative items owner cardinality')
        i=s.index(owner)+len(owner); s=s[:i]+'\n'+version+'\n'+governed+s[i:]
    return s

s=TARGET.read_text(encoding='utf-8')
original_hash=hashlib.sha256(s.encode()).hexdigest()
s=surgical_edit(s)

checks={
'compat_removed':'/* RAWAEA MAIN2 COMPATIBILITY */' not in s,
'auth_once':s.count('/* RAWAEA MAIN2 AUTHORITATIVE MODULE */')==1,
'version_once':s.count("window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';")==1,
'governed_once':s.count('// MAIN2_GOVERNED_CLOSED:v1')==1,
'dash_alias_absent':'window.RW_Dashboard={render:renderDashboard};' not in s,
'items_alias_absent':'window.RW_Items={render:renderItems};' not in s,
'actions':'var actions=' in s,
'delegation':'function main1Delegation(' in s,
'main3':'MAIN3' in s,
'main11':'MAIN11' in s,
'shell':'window.RW_ShellContext' in s,
'auth':'window.RW_Auth' in s,
'nav':'window.RW_Navigation' in s,
'views':'window.RW_Views' in s,
'owner_license':'window.RW_OwnerLicense' in s and 'owner_profile' in s and 'license_status' in s,
'stock_engine':'post_stock_movement' in s and 'reserve_stock' in s,
'finance_reports':all(x in s for x in ('get_trial_balance','get_profit_loss','get_balance_sheet')),
'edge_call':'edgeCall' in s,
'supabase_client':'supabaseClient' in s or 'createClient' in s,
'diamond':'RAWAEA 122 DIAMOND CONTRACT CLOSURE v1' in s,
'doctype':s.lstrip().lower().startswith('<!doctype html>')}
t=html_checks(s)
checks.update({'html':t.starts.get('html',0)==1 and t.ends.get('html',0)==1,'body':t.starts.get('body',0)==1 and t.ends.get('body',0)==1,'script_balance':t.starts.get('script',0)==t.ends.get('script',0),'style_balance':t.starts.get('style',0)==t.ends.get('style',0)})
bad=[k for k,v in checks.items() if not v]
print('P163_STATIC_CHECKS',checks)
if bad: fail('static:'+','.join(bad))
TARGET.write_text(s,encoding='utf-8')

if len(t.inline)!=1: fail('inline application script count '+str(len(t.inline)))
Path('/tmp/newmain.js').write_text(t.inline[0],encoding='utf-8')
r=sh(['node','--check','/tmp/newmain.js'],check=False)
if r.returncode: print(r.stderr); fail('node syntax')

run=ROOT/'Current/PWA'
http=subprocess.Popen([sys.executable,'-m','http.server','8123','--directory',str(run)],cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
time.sleep(1)
try:
    smoke=Path('/tmp/p163_smoke.js')
    smoke.write_text(r'''const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch({headless:true});const p=await b.newPage();const pe=[],ce=[];p.on('pageerror',e=>pe.push(e.message));p.on('console',m=>{if(m.type()==='error')ce.push(m.text())});await p.goto('http://127.0.0.1:8123/New-main',{waitUntil:'domcontentloaded',timeout:30000});await p.waitForTimeout(2500);const r=await p.evaluate(()=>{const S=window.RW_STATE,N=window.RW_Navigation;const flat=[];(function walk(a){(a||[]).forEach(x=>{if(x.view)flat.push(x.view);if(x.submenu)walk(x.submenu)})})(N&&N.menuTree);const req=['dashboard','telesales','customers','online-store','pos','orders','runsheets','suppliers','purchase-pos','purchases','receiving','items','branches','picking','loading','delivery','return','unloading','transfer','direct-sale','direct-return','supplier-return','vouchers','vehicle-count','branch-count','general-count','settlement','reports-dashboard','reports-detailed','reports-comprehensive','hr','crm','users','roles','license','settings','audit-log','notifications'];const mods=['RW_Dashboard','RW_Items','RW_POS','RW_Orders','RW_Runsheets','RW_Purchases','RW_Warehouse','RW_Finance','RW_Reports','RW_OwnerLicense','RW_HR','RW_CRM','RW_Users','RW_Roles','RW_Views'];let denied=false;if(S&&S.app&&N&&N.navigate){S.app.currentUser={isOwner:false};try{N.navigate('license')}catch(e){denied=String(e.message||e).includes('OWNER_ONLY')}}return {lang:document.documentElement.lang,body:!!document.body,state:!!S,auth:!!window.RW_Auth,nav:!!N,views:!!window.RW_Views,shell:!!window.RW_ShellContext,owner:!!window.RW_OwnerLicense,critical:req.every(v=>flat.includes(v)),mods:mods.every(v=>!!window[v]),denied,count:flat.length,diamond:document.documentElement.outerHTML.includes('RAWAEA 122 DIAMOND CONTRACT CLOSURE v1'),version:window.RW_PWA_RECONSTRUCTION_VERSION||null};});console.log(JSON.stringify({r,pe,ce}));if(pe.length||ce.length||r.lang!=='ar'||!r.body||!r.state||!r.auth||!r.nav||!r.views||!r.shell||!r.owner||!r.critical||!r.mods||!r.denied||r.count<30||!r.diamond||r.version!=='MAIN2-COMPLETE-SURGICAL-v1')process.exit(2);await b.close();})().catch(e=>{console.error(e);process.exit(2)})();''',encoding='utf-8')
    r=sh(['node','/tmp/p163_smoke.js'],check=False)
    print(r.stdout,end='')
    if r.returncode: print(r.stderr); fail('browser smoke')
finally:
    http.terminate(); http.wait(timeout=5)

new_hash=hashlib.sha256(TARGET.read_text(encoding='utf-8').encode()).hexdigest()
st=STATE.read_text(encoding='utf-8'); marker='## CTO P163 CLOSED — 2026-09-03'
if marker not in st:
    STATE.write_text(st.rstrip()+f'''\n\n{marker}\n- Target: `Current/PWA/New-main`\n- Previous target SHA-256: `{original_hash}`\n- Verified target SHA-256: `{new_hash}`\n- Target-preserving P163 surgery executed without fragment reconstruction.\n- MAIN2 compatibility duplicate removed with IIFE closure preserved; authoritative owner retained; legacy Dashboard/Items aliases removed.\n- Current ShellContext/auth/navigation/views/OwnerLicense/actions/main1Delegation/MAIN3/MAIN11 and `RAWAEA 122 DIAMOND CONTRACT CLOSURE v1` preserved.\n- Parsed HTML structure gate: PASS.\n- Node syntax gate: PASS.\n- Browser Gold/Diamond runtime gate: PASS.\n- Production database writes: NONE.\n- GOLD = PROVEN\n- DIAMOND = PROVEN\n- CLOSED = PROVEN\n''',encoding='utf-8')

Path(__file__).unlink(missing_ok=True)
Path(ROOT/'.github/workflows/p163_main2_ownership_surgery_20260903.yml').unlink(missing_ok=True)
sh(['git','config','user.name','rawaea-surgical-bot'])
sh(['git','config','user.email','rawaea-surgical-bot@users.noreply.github.com'])
sh(['git','add','-A','Current/PWA/New-main','CURRENT_STATE.md','tools/_cto_p163_executor_20260903.py','.github/workflows/p163_main2_ownership_surgery_20260903.yml'])
sh(['git','diff','--cached','--check'])
if sh(['git','diff','--cached','--quiet'],check=False).returncode==0:
    print('P163_ALREADY_CLOSED'); sys.exit(0)
sh(['git','commit','-m','[P163-EXECUTED] [GOLD-PROVEN] [DIAMOND-PROVEN] [CLOSED] target-preserving New-main ownership closure'])
r=sh(['git','push','origin','HEAD:main'],check=False)
print(r.stdout,end=''); print(r.stderr,end='')
if r.returncode: fail('push')
print('P163_PUSH_PASS')