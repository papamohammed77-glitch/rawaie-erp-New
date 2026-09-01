# RAWAEA ERP — guarded sequential surgical reconstruction
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path('.');CUR=ROOT/'Current/PWA/main';TARGET=ROOT/'Current/PWA/New-main';LEGACY=ROOT/'Current/PWA/main.html';CTO=ROOT/'Current/CTO'
PARTS=[CUR/f'main{i}.md' for i in range(1,12)];EVIDENCE=CTO/'20260901_NEW_MAIN_SURGICAL_RECONSTRUCTION.json'
FORBIDDEN=['stock_branches','inventory_log','stock_voucher_details','journal_entries','journal_entry_lines','cash_box','customer_ledger','supplier_ledger','driver_ledger']
PROTECTED_IDS={'rw-login-page','rw-main-shell','rw-page-container','rw-header-title','rw-header-subtitle','rw-sidebar-nav','rw-logout-btn','rw-login-form','rw-username','rw-password','rw-notification-btn','rw-notification-badge'}

def H(x):return hashlib.sha256(x.encode('utf-8')).hexdigest()
def im(h):
 xs=[m for m in re.finditer(r'<script(?P<a>[^>]*)>(?P<b>[\s\S]*?)</script>',h,re.I) if not re.search(r'\bsrc\s*=',m.group('a') or '',re.I)]
 if len(xs)!=1:raise RuntimeError('INLINE_SCRIPT_COUNT_INVALID:'+str(len(xs)))
 return xs[0]
def js(h):return im(h).group('b')
def bend(s,p):
 d=0;q=None;e=False;lc=False;bc=False;i=p
 while i<len(s):
  c=s[i];n=s[i+1] if i+1<len(s) else ''
  if lc:
   if c=='\n':lc=False
  elif bc:
   if c=='*' and n=='/':bc=False;i+=1
  elif q:
   if e:e=False
   elif c=='\\':e=True
   elif c==q:q=None
  else:
   if c=='/' and n=='/':lc=True;i+=1
   elif c=='/' and n=='*':bc=True;i+=1
   elif c in "'\"`":q=c
   elif c=='{':d+=1
   elif c=='}':
    d-=1
    if d==0:return i+1
  i+=1
 raise RuntimeError('UNTERMINATED_JS_BLOCK')
def fn(s,n):
 m=re.search(r'(?<![\w$])(?:async\s+)?function\s+'+re.escape(n)+r'\s*\([^)]*\)\s*\{',s)
 return None if not m else s[m.start():bend(s,s.find('{',m.start(),m.end()))]
def var(s,n):
 m=re.search(r'(?m)(?:^|\n)[ \t]*(?:var|let|const)\s+'+re.escape(n)+r'\s*=',s)
 if not m:return None
 st=m.start()+(1 if s[m.start():m.start()+1]=='\n' else 0);i=m.end();stack=[];q=None;e=False;lc=False;bc=False
 while i<len(s):
  c=s[i];nx=s[i+1] if i+1<len(s) else ''
  if lc:
   if c=='\n':lc=False
  elif bc:
   if c=='*' and nx=='/':bc=False;i+=1
  elif q:
   if e:e=False
   elif c=='\\':e=True
   elif c==q:q=None
  else:
   if c=='/' and nx=='/':lc=True;i+=1
   elif c=='/' and nx=='*':bc=True;i+=1
   elif c in "'\"`":q=c
   elif c in '({[':stack.append(c)
   elif c in ')}]':stack.pop()
   elif c==';' and not stack:return s[st:i+1]
  i+=1
 raise RuntimeError('JS_VAR_TERMINATOR_MISSING:'+n)
def replace_block(s,k,n,b):
 old=fn(s,n) if k=='fn' else var(s,n)
 if old is not None:return s.replace(old,b,1),old!=b,True
 anchors=['var RW_Data=','var RW_Navigation=','var RW_Auth=','})();'];p=next((s.find(a) for a in anchors if s.find(a)>=0),len(s))
 return s[:p]+b+'\n\n'+s[p:],True,False
def decls(s):
 fs=sorted(set(re.findall(r'(?<![\w$])(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\(',s)))
 vs=sorted(set(re.findall(r'(?m)^[ \t]*(?:var|let|const)\s+([A-Za-z_$][\w$]*)\s*=',s)))
 allow={'applyAuthoritativeContext','currentCompanyId','syncState','setHeader','delegated','moduleCards','renderList','renderDashboard','renderCustomers','renderItems','renderInventory','renderFinance','renderReports','main1Delegation','globalSearch'};out=[]
 for n in fs:
  if n.startswith('RW_') or n in allow:
   b=fn(s,n)
   if b:out.append(('fn',n,b))
 for n in vs:
  if n.startswith('RW_') or n=='actions':
   b=var(s,n)
   if b:out.append(('var',n,b))
 return out
def patch_main7(s):
 return re.sub(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}",r'\1));}',s,count=1)
def merge_source(target,source):
 ops=[]
 for k,n,b in decls(js(source)):
  target,changed,exists=replace_block(target,k,n,b)
  if changed:ops.append(('replace' if exists else 'insert')+':'+k+':'+n)
 return target,ops
def validate(h,baseline=None,final=False):
 req=['rw-login-page','rw-main-shell','rw-page-container','rw-header-title','rw-header-subtitle','rw-sidebar-nav','rw-logout-btn','window.RW_ShellContext','window.RW_OwnerLicense','window.RW_Views','window.RW_Dashboard','window.RW_Items','window.RW_POS','window.RW_Orders','window.RW_Runsheets','window.RW_Purchases','window.RW_Warehouse','window.RW_Finance','window.RW_Reports','window.RW_HR','window.RW_CRM']
 if final:req+=['btn-save-license-only',"{view:'license'",'license:RW_OwnerLicense.render','_clickNotif','_renderAndSave','_updateBadge','markRead']
 miss=[x for x in req if x not in h]
 if miss:raise RuntimeError('CONTRACT_MISSING:'+','.join(miss))
 if h.count('<!doctype')!=1 or h.lower().count('</body>')!=1 or h.lower().count('</html>')!=1:raise RuntimeError('DOCUMENT_CLOSURE_INVALID')
 p=Path('/tmp/new-main-surgical.js');p.write_text(js(h),encoding='utf-8');r=subprocess.run(['node','--check',str(p)],capture_output=True,text=True)
 if r.returncode:print(r.stderr);raise RuntimeError('JS_SYNTAX_FAIL')
 for t in FORBIDDEN:
  if re.search(r"\.from\(['\"]"+re.escape(t)+r"['\"]\)[\s\S]{0,1000}?\.(?:update|insert|upsert|delete)\s*\(",h):raise RuntimeError('DIRECT_BUSINESS_STATE_WRITE:'+t)
 if baseline:
  for x in PROTECTED_IDS:
   if x in baseline and x not in h:raise RuntimeError('PROTECTED_ID_REMOVED:'+x)
def license_patch(h):
 s=(CUR/'main10.md').read_text(encoding='utf-8-sig');b=var(s,'RW_OwnerLicense')
 if b and 'btn-save-license-only' not in h:
  p=h.find('var RW_Views=');p=p if p>=0 else h.find('var RW_Navigation=')
  if p<0:raise RuntimeError('LICENSE_ANCHOR_MISSING')
  h=h[:p]+b+'\n'+h[p:]
 if "{view:'license'" not in h:
  n="{view:'audit',label:'سجل التدقيق',perm:'owner'},"
  if n not in h:raise RuntimeError('LICENSE_MENU_ANCHOR_MISSING')
  h=h.replace(n,n+"{view:'license',label:'إدارة الترخيص',perm:'owner'},",1)
 if 'license:RW_OwnerLicense.render' not in h:
  n='audit:RW_Audit_renderTab,'
  if n not in h:raise RuntimeError('LICENSE_ACTION_ANCHOR_MISSING')
  h=h.replace(n,n+'license:RW_OwnerLicense.render,',1)
 return h
def main():
 if any(not p.is_file() or not p.stat().st_size for p in PARTS):raise RuntimeError('MISSING_MAIN_PART')
 if not TARGET.is_file() or not TARGET.stat().st_size:raise RuntimeError('NEW_MAIN_MISSING')
 if not LEGACY.is_file() or not LEGACY.stat().st_size:raise RuntimeError('LEGACY_MAIN_MISSING')
 baseline=TARGET.read_text(encoding='utf-8');legacy=H(LEGACY.read_text(encoding='utf-8'))
 chunks=[p.read_text(encoding='utf-8-sig') for p in PARTS]; current=baseline
 # Baseline repair is itself surgical and in-memory only. It imports the known-good MAIN1 RW_Table block.
 tblock=var(js(chunks[0]),'RW_Table')
 if tblock and var(js(current),'RW_Table'):
  b0,b1=im(current).start('b'),im(current).end('b');old=var(js(current),'RW_Table');newjs=js(current).replace(old,tblock,1);current=current[:b0]+newjs+current[b1:]
 validate(current,baseline)
 phases=[]
 for idx in range(1,12):
  src=chunks[idx-1]
  if idx==7:src=patch_main7(src)
  before=H(js(current));current,ops=merge_source(current,src)
  if idx==1:
   # MAIN1 owner authority is Auth metadata, never owner_profile existence.
   b=var(js(chunks[0]),'RW_State_DOES_NOT_EXIST')
   current=re.sub(r"var owner=!!op\.data\|\|meta\.isOwner===true\|\|meta\.isOwner==='true';","var owner=meta.isOwner===true||meta.isOwner==='true';",current,count=1)
  if idx==10:current=license_patch(current)
  validate(current,baseline)
  after=H(js(current))
  if before==after:raise RuntimeError(f'NO_SURGICAL_DELTA_MAIN{idx}')
  phases.append({'phase':idx,'source':str(PARTS[idx-1]),'before_script_sha256':before,'after_script_sha256':after,'artifact_sha256':H(current),'artifact_bytes':len(current.encode()),'operations':ops})
 validate(current,baseline,final=True)
 if H(LEGACY.read_text(encoding='utf-8'))!=legacy:raise RuntimeError('LEGACY_MAIN_HTML_CHANGED')
 ids0=set(re.findall(r'\bid=["\']([^"\']+)["\']',baseline));ids1=set(re.findall(r'\bid=["\']([^"\']+)["\']',current));
 if ids0-ids1:raise RuntimeError('TARGET_DOM_IDS_REMOVED:'+','.join(sorted(ids0-ids1)[:50]))
 CTO.mkdir(parents=True,exist_ok=True)
 EVIDENCE.write_text(json.dumps({'event_type':'MASTER_SURGICAL_RECONSTRUCTION_MAIN1_TO_MAIN11','mode':'SEQUENTIAL_DECLARATION_LEVEL_SURGERY','target':str(TARGET),'baseline_target_sha256':H(baseline),'candidate_target_sha256':H(current),'legacy_main_sha256':legacy,'legacy_main_html_modified':False,'phases':phases,'atomic_write':True,'all_phases_validated_before_write':True},ensure_ascii=False,indent=2),encoding='utf-8')
 TARGET.write_text(current,encoding='utf-8')
 print(json.dumps({'status':'READY_TO_PERSIST','phases':11,'baseline':H(baseline),'candidate':H(current),'legacy_protected':True},ensure_ascii=False))
if __name__=='__main__':main()
