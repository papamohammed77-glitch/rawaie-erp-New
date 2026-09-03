#!/usr/bin/env python3
from pathlib import Path
from html.parser import HTMLParser
import hashlib,re,subprocess,sys,shutil,time
ROOT=Path(__file__).resolve().parents[1]; TARGET=ROOT/'Current/PWA/New-main'; STATE=ROOT/'CURRENT_STATE.md'; WORKFLOW=ROOT/'.github/workflows/p163_main2_ownership_surgery_20260903.yml'
def sh(c,check=True): return subprocess.run(c,cwd=ROOT,text=True,capture_output=True,check=check)
def fail(m): print('P163_FAIL:'+m,file=sys.stderr); sys.exit(1)
class P(HTMLParser):
 def __init__(self): super().__init__(convert_charrefs=False); self.s={}; self.e={}; self.i=[]; self.on=False; self.src=False; self.b=[]
 def handle_starttag(self,t,a):
  t=t.lower(); self.s[t]=self.s.get(t,0)+1
  if t=='script': self.on=True; self.src=bool(dict(a).get('src')); self.b=[]
 def handle_data(self,d):
  if self.on and not self.src:self.b.append(d)
 def handle_endtag(self,t):
  t=t.lower(); self.e[t]=self.e.get(t,0)+1
  if t=='script':
   if self.on and not self.src:self.i.append(''.join(self.b))
   self.on=False; self.src=False; self.b=[]
def surgery(s):
 marker='/* RAWAEA MAIN2 COMPATIBILITY */'; auth='/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'; ver="window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"; gov='// MAIN2_GOVERNED_CLOSED:v1'
 if marker not in s:return s
 if s.count(marker)!=1 or s.count(auth)!=1:fail('owner-marker-cardinality')
 a=s.index(marker); b=s.index(auth,a+len(marker)); block=s[a:b]
 if ver+'\n})();' not in block:fail('compatibility-IIFE-boundary-not-proven')
 if 'RAWAEA 122 DIAMOND CONTRACT CLOSURE v1' not in s:fail('diamond-extension-missing')
 s=s[:a]+'})();\n\n'+s[b:]
 for x in ('window.RW_Dashboard={render:renderDashboard};','window.RW_Items={render:renderItems};'):
  if s.count(x)!=1:fail('legacy-alias-cardinality')
  s=s.replace(x,'',1)
 s=re.sub(r'window\.RW_Items\s*=\s*RW_Items\s*;','window.RW_Items=RW_Items;',s).replace(ver,'').replace(gov,'')
 owner='window.RW_Items=RW_Items;'
 if s.count(owner)!=1:fail('authoritative-items-owner-cardinality')
 i=s.index(owner)+len(owner); return s[:i]+'\n'+ver+'\n'+gov+s[i:]
def static(s):
 p=P();p.feed(s);p.close();c={'compat_removed':'/* RAWAEA MAIN2 COMPATIBILITY */' not in s,'auth_once':s.count('/* RAWAEA MAIN2 AUTHORITATIVE MODULE */')==1,'ver_once':s.count("window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';")==1,'gov_once':s.count('// MAIN2_GOVERNED_CLOSED:v1')==1,'dash_alias_absent':'window.RW_Dashboard={render:renderDashboard};' not in s,'items_alias_absent':'window.RW_Items={render:renderItems};' not in s,'shell':'window.RW_ShellContext' in s,'auth':'window.RW_Auth' in s,'nav':'window.RW_Navigation' in s,'views':'window.RW_Views' in s,'owner':'window.RW_OwnerLicense' in s and 'owner_profile' in s and 'license_status' in s,'stock':'post_stock_movement' in s and 'reserve_stock' in s,'finance':all(x in s for x in ('get_trial_balance','get_profit_loss','get_balance_sheet')),'edge':'edgeCall' in s,'supabase':'createClient' in s,'diamond':'RAWAEA 122 DIAMOND CONTRACT CLOSURE v1' in s,'doctype':s.lstrip().lower().startswith('<!doctype html>'),'html':p.s.get('html',0)==1 and p.e.get('html',0)==1,'body':p.s.get('body',0)==1 and p.e.get('body',0)==1,'script_balance':p.s.get('script',0)==p.e.get('script',0),'style_balance':p.s.get('style',0)==p.e.get('style',0),'single_inline':len(p.i)==1};print('P163_STATIC_CHECKS',c);bad=[k for k,v in c.items() if not v]
 if bad:fail('static:'+','.join(bad))
 Path('/tmp/newmain.js').write_text(p.i[0],encoding='utf-8')
def browser():
 web=ROOT/'_p163_web';shutil.rmtree(web,ignore_errors=True);shutil.copytree(ROOT/'Current/PWA',web);shutil.copy2(TARGET,web/'main.html');http=subprocess.Popen([sys.executable,'-m','http.server','8123','--directory',str(web)],cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);time.sleep(.5)
 try:
  js=Path('/tmp/p163_gold.js');js.write_text(r'''const{chromium}=require('playwright');
(async()=>{const b=await chromium.launch({headless:true});const p=await b.newPage();await p.route('**/*',async r=>{const u=r.request().url();if(u.includes('supabase.min.js'))return r.fulfill({status:200,contentType:'text/javascript',body:"window.supabase={createClient:()=>({auth:{onAuthStateChange:()=>({}),getSession:async()=>({data:{session:null}}),getUser:async()=>({data:{user:null},error:null}),signOut:async()=>({}),signInWithPassword:async()=>({error:new Error('SMOKE_NO_LOGIN')})}})};"});if(u.includes('chart.umd.js'))return r.fulfill({status:200,contentType:'text/javascript',body:'window.Chart=function(){};'});if(u.includes('sweetalert2'))return r.fulfill({status:200,contentType:'text/javascript',body:'window.Swal={fire:()=>Promise.resolve(),close:()=>{},showLoading:()=>{}};'});if(u.includes('xlsx.full.min.js'))return r.fulfill({status:200,contentType:'text/javascript',body:'window.XLSX={};'});if(u.includes('font-awesome'))return r.fulfill({status:200,contentType:'text/css',body:''});return r.continue()});const pe=[],ce=[];p.on('pageerror',e=>pe.push(e.message));p.on('console',m=>{if(m.type()==='error')ce.push(m.text())});await p.goto('http://127.0.0.1:8123/main.html',{waitUntil:'domcontentloaded',timeout:30000});await p.waitForTimeout(700);const r=await p.evaluate(async()=>{const S=window.RW_STATE,N=window.RW_Navigation,V=window.RW_Views,flat=[];(function w(a){(a||[]).forEach(x=>{if(x.view)flat.push(x.view);if(x.submenu)w(x.submenu)})})(N&&N.menuTree);const req=['dashboard','telesales','customers','suppliers','branches','pos','purchase-pos','purchases','orders','runsheets','online-store','items','inventory','vouchers','picking','loading','delivery','returns','unloading','finance','reports','hr','crm','users','roles','license','settings','notifications'];const missing=req.filter(x=>!Object.prototype.hasOwnProperty.call((V&&V.permissionMap)||{},x));let ld=false,ad=false;let lm='',am='';if(S?.app&&N?.navigate){S.app.currentUser={isOwner:false};try{await N.navigate('license')}catch(e){lm=String(e.message||e);ld=lm==='OWNER_ONLY'}try{await N.navigate('audit')}catch(e){am=String(e.message||e);ad=am==='OWNER_ONLY'}}return{lang:document.documentElement.lang,body:!!document.body,state:!!S,auth:!!window.RW_Auth,nav:!!N,views:!!V,shell:!!window.RW_ShellContext,owner:!!window.RW_OwnerLicense,menuCount:flat.length,missing,licenseDenied:ld,licenseMsg:lm,auditDenied:ad,auditMsg:am,mods:['RW_Dashboard','RW_Items','RW_POS','RW_Orders','RW_Runsheets','RW_Purchases','RW_Warehouse','RW_Finance','RW_Reports','RW_OwnerLicense','RW_HR','RW_CRM','RW_Users','RW_Views'].every(x=>!!window[x]),diamond:document.documentElement.outerHTML.includes('RAWAEA 122 DIAMOND CONTRACT CLOSURE v1'),version:window.RW_PWA_RECONSTRUCTION_VERSION||null};});console.log(JSON.stringify({r,pe,ce}));const bad=pe.length||ce.length||r.lang!=='ar'||!r.body||!r.state||!r.auth||!r.nav||!r.views||!r.shell||!r.owner||r.missing.length||!r.licenseDenied||!r.auditDenied||!r.mods||!r.diamond||r.version!=='MAIN2-COMPLETE-SURGICAL-v1';await b.close();if(bad)process.exit(2)})().catch(e=>{console.error(e);process.exit(2)});
''',encoding='utf-8');r=sh(['node',str(js)],check=False);print(r.stdout,end='');
  if r.returncode:print(r.stderr,file=sys.stderr);fail('browser-gold-diamond')
 finally:http.terminate();http.wait(timeout=5);shutil.rmtree(web,ignore_errors=True)
s=TARGET.read_text(encoding='utf-8');before=hashlib.sha256(s.encode()).hexdigest();s=surgery(s);static(s);TARGET.write_text(s,encoding='utf-8');q=sh(['node','--check','/tmp/newmain.js'],check=False)
if q.returncode:print(q.stderr,file=sys.stderr);fail('node-syntax')
browser();after=hashlib.sha256(TARGET.read_text(encoding='utf-8').encode()).hexdigest();st=STATE.read_text(encoding='utf-8');marker='## CTO P163 CLOSED — 2026-09-03'
entry=f'''\n\n{marker}\n- Target: `Current/PWA/New-main`\n- Previous target SHA-256: `{before}`\n- Verified target SHA-256: `{after}`\n- P163 target-preserving surgery executed; no fragment reconstruction.\n- MAIN2 compatibility duplicate removed; authoritative MAIN2 owner retained; target-resident Diamond 122 preserved.\n- Static HTML and Node syntax: PASS. Browser Gold/Diamond contract gate: PASS.\n- Production database writes: NONE.\n- GOLD = PROVEN\n- DIAMOND = PROVEN\n- CLOSED = PROVEN\n'''
if marker not in st:STATE.write_text(st.rstrip()+entry,encoding='utf-8')
if WORKFLOW.exists():WORKFLOW.unlink()
Path(__file__).unlink(missing_ok=True);sh(['git','config','user.name','rawaea-surgical-bot']);sh(['git','config','user.email','rawaea-surgical-bot@users.noreply.github.com']);sh(['git','add','-A','Current/PWA/New-main','CURRENT_STATE.md','tools/_cto_p163_executor_20260903.py','.github/workflows/p163_main2_ownership_surgery_20260903.yml']);sh(['git','diff','--cached','--check'])
if sh(['git','diff','--cached','--quiet'],check=False).returncode==0:print('P163_NO_NEW_CHANGES');sys.exit(0)
sh(['git','commit','-m','[P163-EXECUTED] [GOLD-PROVEN] [DIAMOND-PROVEN] [CLOSED] target-preserving New-main ownership closure']);r=sh(['git','push','origin','HEAD:main'],check=False);print(r.stdout,end='');print(r.stderr,end='');
if r.returncode:fail('push')
print('P163_PUSH_PASS')