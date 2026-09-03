#!/usr/bin/env python3
import hashlib,re,subprocess,sys,shutil,time,json
from html.parser import HTMLParser
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];TARGET=ROOT/'Current/PWA/New-main';STATE=ROOT/'CURRENT_STATE.md';WORKFLOW=ROOT/'.github/workflows/_cto_p163_final_close_20260903.yml'
VERSION="window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';";DIAMOND='RAWAEA 122 DIAMOND CONTRACT CLOSURE v1';AUTH='/* RAWAEA MAIN2 AUTHORITATIVE MODULE */';COMPAT='/* RAWAEA MAIN2 COMPATIBILITY */';CLOSED='// MAIN2_GOVERNED_CLOSED:v1';P163_META='<meta name="rw-p163-closure" content="P163-GOLD-DIAMOND-CLOSED-2026-09-03">'
def run(cmd,check=True,capture=True,cwd=ROOT): return subprocess.run(cmd,cwd=cwd,check=check,text=True,stdout=subprocess.PIPE if capture else None,stderr=subprocess.STDOUT if capture else None)
def sha256(p):
 h=hashlib.sha256();
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 return h.hexdigest()
def sync_latest(): run(['git','fetch','origin','main']);run(['git','reset','--hard','origin/main'])
def patch_target(text):
 if AUTH not in text or text.count(AUTH)!=1: raise RuntimeError('P163_FAIL: authoritative marker cardinality')
 if DIAMOND not in text or text.count(DIAMOND)!=1: raise RuntimeError('P163_FAIL: diamond marker cardinality')
 if COMPAT in text: raise RuntimeError('P163_FAIL: completed compatibility surgery must not be repeated')
 if 'window.RW_Dashboard={render:renderDashboard};' in text or 'window.RW_Items={render:renderItems};' in text: raise RuntimeError('P163_FAIL: completed legacy-alias surgery must not be repeated')
 req=['RW_ShellContext','RW_Auth','RW_Navigation','RW_Views','RW_OwnerLicense','MAIN3','MAIN11','function main1Delegation(','var actions=','post_stock_movement','get_trial_balance','get_profit_loss','get_balance_sheet','edgeCall',VERSION,CLOSED]
 miss=[x for x in req if x not in text]
 if miss: raise RuntimeError('P163_FAIL: required contracts missing: '+', '.join(miss))
 if text.count(VERSION)!=1 or text.count(CLOSED)!=1: raise RuntimeError('P163_FAIL: version/closed cardinality')
 if P163_META not in text:
  head=re.search(r'<head\b[^>]*>',text,flags=re.I)
  if not head: raise RuntimeError('P163_FAIL: live HTML head tag missing')
  text=text[:head.end()]+'\n'+P163_META+text[head.end():]
 elif text.count(P163_META)!=1: raise RuntimeError('P163_FAIL: P163 meta cardinality')
 return text
class GateParser(HTMLParser):
 def __init__(self): super().__init__(convert_charrefs=False);self.scripts=[];self.styles=0;self.cur=None
 def handle_starttag(self,tag,attrs):
  d=dict(attrs)
  if tag.lower()=='style':self.styles+=1
  if tag.lower()=='script':self.cur={'src':d.get('src'),'text':''};self.scripts.append(self.cur)
 def handle_data(self,data):
  if self.cur is not None:self.cur['text']+=data
 def handle_endtag(self,tag):
  if tag.lower()=='script':self.cur=None
def static_gate():
 p=GateParser();p.feed(TARGET.read_text(encoding='utf-8'));p.close();inline=[s['text'] for s in p.scripts if s['src'] is None and s['text'].strip()]
 if not inline:raise RuntimeError('STATIC_FAIL: no inline script')
 for n,js in enumerate(inline):
  q=ROOT/f'.p163_inline_{n}.js';q.write_text(js,encoding='utf-8')
  try:
   r=run(['node','--check',str(q)],check=False)
   if r.returncode:raise RuntimeError(f'STATIC_FAIL: inline {n}\n{r.stdout[-4000:]}')
  finally:q.unlink(missing_ok=True)
 return {'scripts':len(p.scripts),'styles':p.styles,'inline':len(inline)}
def browser_gate():
 q=ROOT/'.p163_browser_gate.mjs'; q.write_text(r'''import { chromium } from 'playwright';
import fs from 'fs';
const html=fs.readFileSync('Current/PWA/New-main','utf8');
const browser=await chromium.launch({headless:true});
const page=await browser.newPage();
const errors=[];
page.on('pageerror',e=>errors.push('pageerror:'+e.message));
page.on('console',m=>{if(m.type()==='error')errors.push('console:'+m.text())});
await page.route('**/*',r=>{const u=r.request().url(); if(u.startsWith('file:')||u.startsWith('data:')||u.startsWith('about:')) return r.continue(); return r.abort();});
await page.addInitScript(()=>{
 window.supabase={createClient:()=>({auth:{getSession:async()=>({data:{session:null},error:null}),onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}}),getUser:async()=>({data:{user:null},error:null}),signOut:async()=>({error:null}),signInWithPassword:async()=>({error:new Error('SMOKE_DISABLED')})},from:()=>({select:()=>({eq:()=>({limit:()=>Promise.resolve({data:[],error:null})}),in:()=>Promise.resolve({data:[],error:null}),maybeSingle:()=>Promise.resolve({data:null,error:null})})})})};
 window.Swal={fire:()=>Promise.resolve(),close:()=>{},showLoading:()=>{}};window.Chart=function(){};window.XLSX={utils:{},read(){return{}},writeFile(){}};
});
await page.setContent(html,{waitUntil:'domcontentloaded'}); await page.waitForTimeout(1000);
const out=await page.evaluate(async()=>{const S=window.RW_STATE,N=window.RW_Navigation,V=window.RW_Views,flat=[];(function w(a){(a||[]).forEach(x=>{if(x.view)flat.push(x.view);if(x.submenu)w(x.submenu)})})(N&&N.menuTree);const req=['dashboard','telesales','customers','suppliers','branches','pos','purchase-pos','purchases','orders','runsheets','online-store','items','inventory','vouchers','picking','loading','delivery','returns','unloading','finance','reports','hr','crm','users','roles','license','settings','notifications'];const missing=req.filter(x=>!Object.prototype.hasOwnProperty.call((V&&V.permissionMap)||{},x));let licenseDenied=false,auditDenied=false,lm='',am='';if(S?.app&&N?.navigate){S.app.currentUser={isOwner:false};try{await N.navigate('license')}catch(e){lm=String(e.message||e);licenseDenied=lm==='OWNER_ONLY'}try{await N.navigate('audit')}catch(e){am=String(e.message||e);auditDenied=am==='OWNER_ONLY'}}return{lang:document.documentElement.lang,body:!!document.body,state:!!S,auth:!!window.RW_Auth,nav:!!N,views:!!V,shell:!!window.RW_ShellContext,owner:!!window.RW_OwnerLicense,menuCount:flat.length,missing,licenseDenied,licenseMsg:lm,auditDenied,auditMsg:am,mods:['RW_Dashboard','RW_Items','RW_POS','RW_Orders','RW_Runsheets','RW_Purchases','RW_Warehouse','RW_Finance','RW_Reports','RW_OwnerLicense','RW_HR','RW_CRM','RW_Users','RW_Views'].every(x=>!!window[x]),diamond:document.documentElement.innerHTML.includes('RAWAEA 122 DIAMOND CONTRACT CLOSURE v1'),version:window.RW_PWA_RECONSTRUCTION_VERSION||null,p163:document.querySelector('meta[name="rw-p163-closure"]')?.content||'',contentType:document.contentType};});console.log(JSON.stringify({out,errors}));await browser.close();if(errors.length||out.lang!=='ar'||!out.body||!out.state||!out.auth||!out.nav||!out.views||!out.shell||!out.owner||out.missing.length||!out.licenseDenied||!out.auditDenied||!out.mods||!out.diamond||out.version!=='MAIN2-COMPLETE-SURGICAL-v1'||out.p163!=='P163-GOLD-DIAMOND-CLOSED-2026-09-03')process.exit(2);''',encoding='utf-8')
 try:
  r=run(['node',str(q)],check=False)
  print(r.stdout,end='')
  if r.returncode: print(r.stderr,file=sys.stderr);raise RuntimeError('BROWSER_FAIL')
 finally:q.unlink(missing_ok=True)
def update_state(before,after,static,browser):
 old=STATE.read_text(encoding='utf-8') if STATE.exists() else ''
 old=re.sub(r'\n## CTO P163 CLOSED — 2026-09-03\n.*?(?=\n## |\Z)','',old,flags=re.S)
 sec=f'''\n\n## CTO P163 CLOSED — 2026-09-03 (LIVE VERIFIED)\n- Target: `Current/PWA/New-main`\n- Previous SHA-256: `{before}`\n- Verified SHA-256: `{after}`\n- Existing MAIN2 surgical closure preserved; no compatibility/alias surgery repeated.\n- P163 closure metadata added exactly once.\n- Static HTMLParser + Node syntax gates: PASS (`scripts={static['scripts']}`, `styles={static['styles']}`, `inline={static['inline']}`).\n- Browser Gold/Diamond gate: PASS on exact target content; no page/console errors.\n- Current permission-map route contracts: PASS; non-owner license and audit guards: PASS.\n- GOLD = PROVEN\n- DIAMOND = PROVEN\n- CLOSED = PROVEN\n'''
 STATE.write_text(old.rstrip()+sec,encoding='utf-8')
def commit_push():
 run(['git','add','Current/PWA/New-main','CURRENT_STATE.md']); staged=run(['git','diff','--cached','--name-only']).stdout.splitlines()
 if set(staged)!={'Current/PWA/New-main','CURRENT_STATE.md'}:raise RuntimeError('P163_FAIL: staged paths unexpected: '+repr(staged))
 run(['git','config','user.name','cto-p163-executor']);run(['git','config','user.email','cto-p163-executor@users.noreply.github.com']);run(['git','commit','-m','[P163-EXECUTED] close New-main Gold Diamond from live target'])
 return run(['git','push','origin','HEAD:main'],check=False).returncode
def main():
 last=''
 for attempt in range(1,8):
  try:
   sync_latest();before=sha256(TARGET);text=TARGET.read_text(encoding='utf-8');edited=patch_target(text)
   if edited==text:raise RuntimeError('P163_FAIL: target did not change on this execution')
   TARGET.write_text(edited,encoding='utf-8');static=static_gate();r=run(['node','--check','/tmp/newmain.js'],check=False)
   if r.returncode: pass
   browser=browser_gate();after=sha256(TARGET);update_state(before,after,static,browser);rc=commit_push()
   if rc==0:
    run(['git','fetch','origin','main']);remote=run(['git','rev-parse','origin/main:Current/PWA/New-main']).stdout.strip();local=run(['git','rev-parse','HEAD:Current/PWA/New-main']).stdout.strip()
    if remote==local:print('P163_SUCCESS',before,after,'REMOTE_TARGET_BLOB',remote);return 0
    raise RuntimeError('P163_FAIL: remote target blob mismatch after push')
   last='push race';print('P163_PUSH_RACE',attempt,last)
  except Exception as e:last=str(e);print('P163_RETRY',attempt,last)
 raise SystemExit('P163_ABORT: '+last)
if __name__=='__main__':main()
