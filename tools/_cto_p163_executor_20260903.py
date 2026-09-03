#!/usr/bin/env python3
from pathlib import Path
from html.parser import HTMLParser
import hashlib,re,subprocess,sys,shutil,time
ROOT=Path(__file__).resolve().parents[1]; TARGET=ROOT/'Current/PWA/New-main'; STATE=ROOT/'CURRENT_STATE.md'; WORKFLOW=ROOT/'.github/workflows/p163_main2_ownership_surgery_20260903.yml'
def sh(c,check=True): return subprocess.run(c,cwd=ROOT,text=True,capture_output=True,check=check)
def fail(m): print('P163_FAIL:'+m,file=sys.stderr); sys.exit(1)
class Parser(HTMLParser):
 def __init__(self): super().__init__(convert_charrefs=False); self.starts={}; self.ends={}; self.inline=[]; self.on=False; self.src=False; self.buf=[]
 def handle_starttag(self,t,a):
  t=t.lower(); self.starts[t]=self.starts.get(t,0)+1
  if t=='script': self.on=True; self.src=bool(dict(a).get('src')); self.buf=[]
 def handle_data(self,d):
  if self.on and not self.src: self.buf.append(d)
 def handle_endtag(self,t):
  t=t.lower(); self.ends[t]=self.ends.get(t,0)+1
  if t=='script':
   if self.on and not self.src: self.inline.append(''.join(self.buf))
   self.on=False; self.src=False; self.buf=[]
def surgery(s):
 marker='/* RAWAEA MAIN2 COMPATIBILITY */'; auth='/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'; version="window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"; governed='// MAIN2_GOVERNED_CLOSED:v1'
 if marker not in s: return s
 if s.count(marker)!=1 or s.count(auth)!=1: fail('owner-marker-cardinality')
 a=s.index(marker); b=s.index(auth,a+len(marker)); block=s[a:b]
 if version+'\n})();' not in block: fail('compatibility-IIFE-boundary-not-proven')
 if 'RAWAEA 122 DIAMOND CONTRACT CLOSURE v1' not in s: fail('diamond-extension-missing')
 s=s[:a]+'})();\n\n'+s[b:]
 for alias in ('window.RW_Dashboard={render:renderDashboard};','window.RW_Items={render:renderItems};'):
  if s.count(alias)!=1: fail('legacy-alias-cardinality')
  s=s.replace(alias,'',1)
 s=re.sub(r'window\.RW_Items\s*=\s*RW_Items\s*;','window.RW_Items=RW_Items;',s).replace(version,'').replace(governed,'')
 owner='window.RW_Items=RW_Items;'
 if s.count(owner)!=1: fail('authoritative-items-owner-cardinality')
 i=s.index(owner)+len(owner); return s[:i]+'\n'+version+'\n'+governed+s[i:]
def static_gate(s):
 p=Parser(); p.feed(s); p.close(); checks={'compat_removed':'/* RAWAEA MAIN2 COMPATIBILITY */' not in s,'auth_once':s.count('/* RAWAEA MAIN2 AUTHORITATIVE MODULE */')==1,'version_once':s.count("window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';")==1,'governed_once':s.count('// MAIN2_GOVERNED_CLOSED:v1')==1,'dash_alias_absent':'window.RW_Dashboard={render:renderDashboard};' not in s,'items_alias_absent':'window.RW_Items={render:renderItems};' not in s,'shell':'window.RW_ShellContext' in s,'auth':'window.RW_Auth' in s,'nav':'window.RW_Navigation' in s,'views':'window.RW_Views' in s,'owner':'window.RW_OwnerLicense' in s and 'owner_profile' in s and 'license_status' in s,'stock':'post_stock_movement' in s and 'reserve_stock' in s,'finance':all(x in s for x in ('get_trial_balance','get_profit_loss','get_balance_sheet')),'edge':'edgeCall' in s,'supabase':'supabaseClient' in s or 'createClient' in s,'diamond':'RAWAEA 122 DIAMOND CONTRACT CLOSURE v1' in s,'doctype':s.lstrip().lower().startswith('<!doctype html>'),'html':p.starts.get('html',0)==1 and p.ends.get('html',0)==1,'body':p.starts.get('body',0)==1 and p.ends.get('body',0)==1,'script_balance':p.starts.get('script',0)==p.ends.get('script',0),'style_balance':p.starts.get('style',0)==p.ends.get('style',0),'single_inline_app':len(p.inline)==1}
 print('P163_STATIC_CHECKS',checks); bad=[k for k,v in checks.items() if not v]
 if bad: fail('static:'+','.join(bad))
 Path('/tmp/newmain.js').write_text(p.inline[0],encoding='utf-8')
def browser_gate():
 web=ROOT/'_p163_web'; shutil.rmtree(web,ignore_errors=True); shutil.copytree(ROOT/'Current/PWA',web); shutil.copy2(TARGET,web/'main.html');
 http=subprocess.Popen([sys.executable,'-m','http.server','8123','--directory',str(web)],cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL); time.sleep(.8)
 try:
  js=Path('/tmp/p163_gold.js'); js.write_text(r'''const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch({headless:true});const p=await b.newPage();const pe=[],ce=[];p.on('pageerror',e=>pe.push(e.message));p.on('console',m=>{if(m.type()==='error')ce.push(m.text())});await p.goto('http://127.0.0.1:8123/main.html',{waitUntil:'domcontentloaded',timeout:30000});await p.waitForTimeout(1800);const r=await p.evaluate(async()=>{const S=window.RW_STATE,N=window.RW_Navigation,V=window.RW_Views,flat=[];(function walk(a){(a||[]).forEach(x=>{if(x.view)flat.push(x.view);if(x.submenu)walk(x.submenu)})})(N&&N.menuTree);const required=['dashboard','telesales','customers','suppliers','branches','pos','purchase-pos','purchases','orders','runsheets','online-store','items','inventory','vouchers','picking','loading','delivery','returns','unloading','finance','reports','hr','crm','users','roles','license','settings','notifications'];const perms=Object.keys((V&&V.permissionMap)||{}),missing=required.filter(x=>!perms.includes(x));let licenseDenied=false,licenseMsg='',auditDenied=false;if(S&&S.app&&N&&N.navigate){S.app.currentUser={isOwner:false};try{await N.navigate('license')}catch(e){licenseMsg=String(e&&e.message||e);licenseDenied=licenseMsg==='OWNER_ONLY'}try{await N.navigate('audit')}catch(e){auditDenied=String(e&&e.message||e)==='OWNER_ONLY'}}return {lang:document.documentElement.lang,body:!!document.body,state:!!S,auth:!!window.RW_Auth,nav:!!N,views:!!V,shell:!!window.RW_ShellContext,owner:!!window.RW_OwnerLicense,menuCount:flat.length,menuCore:required.slice(0,21).every(x=>flat.includes(x)),permCount:perms.length,missing,licenseDenied,licenseMsg,auditDenied,mods:['RW_Dashboard','RW_Items','RW_POS','RW_Orders','RW_Runsheets','RW_Purchases','RW_Warehouse','RW_Finance','RW_Reports','RW_OwnerLicense','RW_HR','RW_CRM','RW_Users','RW_Views'].every(x=>!!window[x]),diamond:document.documentElement.outerHTML.includes('RAWAEA 122 DIAMOND CONTRACT CLOSURE v1'),version:window.RW_PWA_RECONSTRUCTION_VERSION||null};});console.log(JSON.stringify({r,pe,ce}));const bad=pe.length||ce.length||r.lang!=='ar'||!r.body||!r.state||!r.auth||!r.nav||!r.views||!r.shell||!r.owner||r.menuCount<20||!r.menuCore||r.missing.length||!r.licenseDenied||!r.auditDenied||!r.mods||!r.diamond||r.version!=='MAIN2-COMPLETE-SURGICAL-v1';await b.close();if(bad)process.exit(2)})().catch(e=>{console.error(e);process.exit(2)});
''',encoding='utf-8')
  r=sh(['node',str(js)],check=False); print(r.stdout,end='');
  if r.returncode: print(r.stderr,file=sys.stderr); fail('browser-gold-diamond')
 finally: http.terminate(); http.wait(timeout=5); shutil.rmtree(web,ignore_errors=True)
s=TARGET.read_text(encoding='utf-8'); before=hashlib.sha256(s.encode()).hexdigest(); s=surgery(s); TARGET.write_text(s,encoding='utf-8'); print('P163_TARGET_BEFORE_SHA256='+before); print('P163_TARGET_AFTER_SHA256='+hashlib.sha256(s.encode()).hexdigest()); static_gate(s); r=sh(['node','--check','/tmp/newmain.js'],check=False)
if r.returncode: print(r.stderr,file=sys.stderr); fail('node-syntax')
browser_gate(); new_hash=hashlib.sha256(TARGET.read_text(encoding='utf-8').encode()).hexdigest(); marker='## CTO P163 CLOSED — 2026-09-03'; st=STATE.read_text(encoding='utf-8')
if marker not in st: STATE.write_text(st.rstrip()+f'''\n\n{marker}\n- Target: `Current/PWA/New-main`\n- Previous target SHA-256: `{before}`\n- Verified target SHA-256: `{new_hash}`\n- Target-preserving P163 surgery completed without fragment reconstruction.\n- MAIN2 compatibility duplicate removed; authoritative MAIN2 owner retained; legacy Dashboard/Items aliases removed.\n- ShellContext/auth/navigation/views/OwnerLicense/actions/main1Delegation/MAIN3/MAIN11 and `RAWAEA 122 DIAMOND CONTRACT CLOSURE v1` preserved.\n- Static structure + Node syntax: PASS.\n- Browser Gold/Diamond contract gate: PASS.\n- Production database writes: NONE.\n- GOLD = PROVEN\n- DIAMOND = PROVEN\n- CLOSED = PROVEN\n''',encoding='utf-8')
if WORKFLOW.exists(): WORKFLOW.unlink()
Path(__file__).unlink(missing_ok=True); sh(['git','config','user.name','rawaea-surgical-bot']); sh(['git','config','user.email','rawaea-surgical-bot@users.noreply.github.com']); sh(['git','add','-A','Current/PWA/New-main','CURRENT_STATE.md','tools/_cto_p163_executor_20260903.py','.github/workflows/p163_main2_ownership_surgery_20260903.yml']); sh(['git','diff','--cached','--check'])
if sh(['git','diff','--cached','--quiet'],check=False).returncode==0: print('P163_ALREADY_CLOSED'); sys.exit(0)
sh(['git','commit','-m','[P163-EXECUTED] [GOLD-PROVEN] [DIAMOND-PROVEN] [CLOSED] target-preserving New-main ownership closure'])
r=sh(['git','push','origin','HEAD:main'],check=False); print(r.stdout,end=''); print(r.stderr,end='')
if r.returncode: fail('push')
print('P163_PUSH_PASS')