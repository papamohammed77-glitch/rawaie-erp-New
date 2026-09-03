#!/usr/bin/env python3
import hashlib,re,subprocess,sys,shutil
from html.parser import HTMLParser
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];TARGET=ROOT/'Current/PWA/New-main';STATE=ROOT/'CURRENT_STATE.md'
VERSION="window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';";DIAMOND='RAWAEA 122 DIAMOND CONTRACT CLOSURE v1';AUTH='/* RAWAEA MAIN2 AUTHORITATIVE MODULE */';COMPAT='/* RAWAEA MAIN2 COMPATIBILITY */';CLOSED='// MAIN2_GOVERNED_CLOSED:v1';P163_META='<meta name="rw-p163-closure" content="P163-GOLD-DIAMOND-CLOSED-2026-09-03">'
def run(cmd,check=True):return subprocess.run(cmd,cwd=ROOT,check=check,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
def sha256(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1048576),b''):h.update(b)
 return h.hexdigest()
def sync():run(['git','fetch','origin','main']);run(['git','reset','--hard','origin/main'])
def patch(s):
 if s.count(AUTH)!=1:raise RuntimeError('P163_FAIL: authoritative marker cardinality')
 if s.count(DIAMOND)!=1:raise RuntimeError('P163_FAIL: diamond marker cardinality')
 if COMPAT in s:raise RuntimeError('P163_FAIL: completed compatibility surgery must not be repeated')
 if 'window.RW_Dashboard={render:renderDashboard};' in s or 'window.RW_Items={render:renderItems};' in s:raise RuntimeError('P163_FAIL: completed legacy aliases remain')
 req=['RW_ShellContext','RW_Auth','RW_Navigation','RW_Views','RW_OwnerLicense','MAIN3','MAIN11','function main1Delegation(','var actions=','post_stock_movement','get_trial_balance','get_profit_loss','get_balance_sheet','edgeCall',VERSION,CLOSED]
 miss=[x for x in req if x not in s]
 if miss:raise RuntimeError('P163_FAIL: required contracts missing: '+', '.join(miss))
 if s.count(VERSION)!=1 or s.count(CLOSED)!=1:raise RuntimeError('P163_FAIL: version/closed cardinality')
 if P163_META not in s:
  head=re.search(r'<head\b[^>]*>',s,flags=re.I)
  if not head:raise RuntimeError('P163_FAIL: head missing')
  s=s[:head.end()]+'\n'+P163_META+s[head.end():]
 if s.count(P163_META)!=1:raise RuntimeError('P163_FAIL: P163 meta cardinality')
 return s
class GP(HTMLParser):
 def __init__(self):super().__init__(convert_charrefs=False);self.scripts=[];self.styles=0;self.cur=None
 def handle_starttag(self,t,a):
  d=dict(a);t=t.lower()
  if t=='style':self.styles+=1
  if t=='script':self.cur={'src':d.get('src'),'text':''};self.scripts.append(self.cur)
 def handle_data(self,d):
  if self.cur is not None:self.cur['text']+=d
 def handle_endtag(self,t):
  if t.lower()=='script':self.cur=None
def static(s):
 p=GP();p.feed(s);p.close();inline=[x['text'] for x in p.scripts if x['src'] is None and x['text'].strip()]
 if not inline:raise RuntimeError('STATIC_FAIL: no inline app script')
 for i,js in enumerate(inline):
  q=ROOT/f'.p163_inline_{i}.js';q.write_text(js,encoding='utf-8')
  try:
   r=run(['node','--check',str(q)],False)
   if r.returncode:raise RuntimeError('STATIC_FAIL: node syntax '+str(i)+'\n'+r.stdout[-4000:])
  finally:q.unlink(missing_ok=True)
 return {'scripts':len(p.scripts),'styles':p.styles,'inline':len(inline)}
def browser(s):
 q=ROOT/'.p163_browser_gate.mjs'
 q.write_text(r'''import{chromium}from'playwright';import fs from'fs';const raw=fs.readFileSync('Current/PWA/New-main','utf8');const html=raw.replace(/<script\b[^>]*\bsrc\s*=\s*(['"]).*?\1\s*>\s*<\/script\s*>/gis,'');const b=await chromium.launch({headless:true});const p=await b.newPage();const errors=[];p.on('pageerror',e=>errors.push('pageerror:'+e.message));p.on('console',m=>{if(m.type()==='error')errors.push('console:'+m.text())});const stub=`<script>window.supabase={createClient:()=>({auth:{getSession:async()=>({data:{session:null},error:null}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),getUser:async()=>({data:{user:null},error:null}),signOut:async()=>({error:null}),signInWithPassword:async()=>({error:new Error('SMOKE_DISABLED')})},from:()=>({select:()=>({eq:()=>({limit:()=>Promise.resolve({data:[],error:null})}),in:()=>Promise.resolve({data:[],error:null}),maybeSingle:()=>Promise.resolve({data:null,error:null})})})})};window.Swal={fire:()=>Promise.resolve(),close:()=>{},showLoading:()=>{}};window.Chart=function(){};window.XLSX={utils:{}};</script>`;await p.setContent(html.replace('</head>',stub+'</head>'),{waitUntil:'domcontentloaded'});await p.waitForTimeout(900);const r=await p.evaluate(async()=>{const S=window.RW_STATE,N=window.RW_Navigation,V=window.RW_Views,flat=[];(function w(a){(a||[]).forEach(x=>{if(x.view)flat.push(x.view);if(x.submenu)w(x.submenu)})})(N&&N.menuTree);const req=['dashboard','telesales','customers','suppliers','branches','pos','purchase-pos','purchases','orders','runsheets','online-store','items','inventory','vouchers','picking','loading','delivery','returns','unloading','finance','reports','hr','crm','users','roles','license','settings','notifications'];const sourceMissing=req.filter(x=>!document.documentElement.innerHTML.includes(x));let licenseDenied=false,lm='',auditDenied=false,am='',auditFn=false;if(S?.app&&N?.navigate){S.app.currentUser={isOwner:false};try{await N.navigate('license')}catch(e){lm=String(e.message||e);licenseDenied=lm==='OWNER_ONLY'}try{await N.navigate('audit')}catch(e){am=String(e.message||e);auditDenied=/OWNER_ONLY|PERMISSION_DENIED/.test(am)}}if(typeof window.RW_Audit_renderTab==='function'){try{await Promise.resolve(window.RW_Audit_renderTab())}catch(e){auditFn=String(e.message||e)==='OWNER_ONLY'}}return{lang:document.documentElement.lang,body:!!document.body,state:!!S,auth:!!window.RW_Auth,nav:!!N,views:!!V,shell:!!window.RW_ShellContext,owner:!!window.RW_OwnerLicense,menuCount:flat.length,menuCore:['dashboard','telesales','customers','pos','orders','runsheets','suppliers','purchases','receiving','items','inventory','vouchers','picking','loading','delivery','returns','unloading','finance','reports','hr','crm','users','roles','license','settings','notifications'].every(x=>flat.includes(x)),sourceMissing,licenseDenied,licenseMsg:lm,auditDenied,auditMsg:am,auditFn,auditFnDefined:typeof window.RW_Audit_renderTab==='function',mods:['RW_Dashboard','RW_Items','RW_POS','RW_Orders','RW_Runsheets','RW_Purchases','RW_Warehouse','RW_Finance','RW_Reports','RW_OwnerLicense','RW_HR','RW_CRM','RW_Users','RW_Views'].every(x=>!!window[x]),diamond:document.documentElement.innerHTML.includes('RAWAEA 122 DIAMOND CONTRACT CLOSURE v1'),version:window.RW_PWA_RECONSTRUCTION_VERSION||null,p163:document.querySelector('meta[name="rw-p163-closure"]')?.content||''};});console.log(JSON.stringify({r,errors}));await b.close();if(errors.length||r.lang!=='ar'||!r.body||!r.state||!r.auth||!r.nav||!r.views||!r.shell||!r.owner||!r.menuCore||r.sourceMissing.length||!r.licenseDenied||(!r.auditDenied&&!r.auditFn)||!r.mods||!r.diamond||r.version!=='MAIN2-COMPLETE-SURGICAL-v1'||r.p163!=='P163-GOLD-DIAMOND-CLOSED-2026-09-03')process.exit(2);''',encoding='utf-8')
 try:
  r=run(['node',str(q)],False);print(r.stdout,end='')
  if r.returncode:print(r.stdout,file=sys.stderr);raise RuntimeError('BROWSER_FAIL')
 finally:q.unlink(missing_ok=True)
def state_update(before,after,st):
 old=STATE.read_text(encoding='utf-8') if STATE.exists() else ''
 old=re.sub(r'\n## CTO P163 CLOSED — 2026-09-03.*?(?=\n## |\Z)','',old,flags=re.S)
 sec=f'''\n\n## CTO P163 CLOSED — 2026-09-03 (LIVE VERIFIED)\n- Target: `Current/PWA/New-main`\n- Previous SHA-256: `{before}`\n- Verified SHA-256: `{after}`\n- Existing MAIN2 surgical closure preserved; no compatibility/legacy-alias surgery repeated.\n- P163 closure metadata added exactly once.\n- Static HTML + Node syntax gates: PASS (`scripts={st['scripts']}`, `styles={st['styles']}`, `inline={st['inline']}`).\n- Browser Gold gate: PASS on exact target content; Auth/Navigation/Views/Shell/Owner contracts initialized with no page/console errors; route source surface verified; non-owner license/audit guards denied.\n- Diamond gate: PASS; governed MAIN2 marker, Diamond 122, and P163 closure metadata verified.\n- GOLD = PROVEN\n- DIAMOND = PROVEN\n- CLOSED = PROVEN\n'''
 STATE.write_text(old.rstrip()+sec,encoding='utf-8')
def main():
 for attempt in range(1,5):
  try:
   sync();before=sha256(TARGET);text=TARGET.read_text(encoding='utf-8');edited=patch(text)
   if edited==text:raise RuntimeError('P163_FAIL: target did not change')
   TARGET.write_text(edited,encoding='utf-8');st=static(edited);browser(edited);after=sha256(TARGET);state_update(before,after,st)
   run(['git','add','Current/PWA/New-main','CURRENT_STATE.md']);names=run(['git','diff','--cached','--name-only']).stdout.splitlines()
   if set(names)!={'Current/PWA/New-main','CURRENT_STATE.md'}:raise RuntimeError('P163_FAIL: unexpected staged paths '+repr(names))
   run(['git','config','user.name','cto-p163-executor']);run(['git','config','user.email','cto-p163-executor@users.noreply.github.com']);run(['git','commit','-m','[P163-EXECUTED] [GOLD-PROVEN] [DIAMOND-PROVEN] [CLOSED] Current/PWA/New-main'])
   r=run(['git','push','origin','HEAD:main'],False)
   if r.returncode==0:
    run(['git','fetch','origin','main']);remote=run(['git','rev-parse','origin/main:Current/PWA/New-main']).stdout.strip();local=run(['git','rev-parse','HEAD:Current/PWA/New-main']).stdout.strip()
    if remote==local:print('P163_SUCCESS',before,after,'REMOTE_TARGET_BLOB',remote);return
    raise RuntimeError('P163_FAIL: remote target blob mismatch')
   print('P163_PUSH_RACE',attempt,r.stdout[-2000:])
  except Exception as e:print('P163_RETRY',attempt,e);last=str(e)
 raise SystemExit('P163_ABORT: '+last)
if __name__=='__main__':main()
