# RAWAEA ERP — sequential surgical MAIN1..MAIN11 merger
# Only the existing New-main inline runtime is edited. The surrounding HTML/CSS shell is preserved verbatim.
from pathlib import Path
import hashlib,json,re,subprocess

ROOT=Path('.'); CUR=ROOT/'Current/PWA/main'; TARGET=ROOT/'Current/PWA/New-main'; LEGACY=ROOT/'Current/PWA/main.html'; CTO=ROOT/'Current/CTO'
PARTS=[CUR/f'main{i}.md' for i in range(1,12)]; EVIDENCE=CTO/'20260901_NEW_MAIN_SURGICAL_RECONSTRUCTION.json'
FORBIDDEN=['stock_branches','inventory_log','stock_voucher_details','journal_entries','journal_entry_lines','cash_box','customer_ledger','supplier_ledger','driver_ledger']
PROTECTED_IDS={'rw-login-page','rw-main-shell','rw-page-container','rw-header-title','rw-header-subtitle','rw-sidebar-nav','rw-logout-btn','rw-login-form','rw-username','rw-password','rw-notification-btn','rw-notification-badge'}

def H(s): return hashlib.sha256(s.encode('utf-8')).hexdigest()
def im(html):
 xs=[m for m in re.finditer(r'<script(?P<a>[^>]*)>(?P<b>[\s\S]*?)</script>',html,re.I) if not re.search(r'\bsrc\s*=',m.group('a') or '',re.I)]
 if len(xs)!=1: raise RuntimeError(f'INLINE_SCRIPT_COUNT_INVALID:{len(xs)}')
 return xs[0]
def js(html): return im(html).group('b')
def balanced(s,start):
 depth=0; quote=None; esc=False; line=False; block=False; i=start
 while i<len(s):
  c=s[i]; n=s[i+1] if i+1<len(s) else ''
  if line:
   if c=='\n': line=False
  elif block:
   if c=='*' and n=='/': block=False; i+=1
  elif quote:
   if esc: esc=False
   elif c=='\\': esc=True
   elif c==quote: quote=None
  else:
   if c=='/' and n=='/': line=True; i+=1
   elif c=='/' and n=='*': block=True; i+=1
   elif c in "'\"`": quote=c
   elif c=='{': depth+=1
   elif c=='}':
    depth-=1
    if depth==0:return i+1
  i+=1
 raise RuntimeError('UNTERMINATED_JS_BLOCK')
def fn(s,name):
 m=re.search(r'(?<![\w$])(?:async\s+)?function\s+'+re.escape(name)+r'\s*\([^)]*\)\s*\{',s)
 if not m:return None
 return s[m.start():balanced(s,s.find('{',m.start(),m.end()))]
def var(s,name):
 m=re.search(r'(?m)(?:^|\n)[ \t]*(?:var|let|const)\s+'+re.escape(name)+r'\s*=',s)
 if not m:return None
 start=m.start()+ (1 if s[m.start():m.start()+1]=='\n' else 0); i=m.end(); stack=[]; quote=None; esc=False; line=False; block=False
 while i<len(s):
  c=s[i]; n=s[i+1] if i+1<len(s) else ''
  if line:
   if c=='\n':line=False
  elif block:
   if c=='*' and n=='/':block=False;i+=1
  elif quote:
   if esc:esc=False
   elif c=='\\':esc=True
   elif c==quote:quote=None
  else:
   if c=='/' and n=='/':line=True;i+=1
   elif c=='/' and n=='*':block=True;i+=1
   elif c in "'\"`":quote=c
   elif c in '({[':stack.append(c)
   elif c in ')}]':
    if not stack:raise RuntimeError('JS_BLOCK_UNDERFLOW:'+name)
    stack.pop()
   elif c==';' and not stack:return s[start:i+1]
  i+=1
 raise RuntimeError('JS_VAR_TERMINATOR_MISSING:'+name)
def declarations(s):
 funcs=sorted(set(re.findall(r'(?<![\w$])(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\(',s)))
 vars_=sorted(set(re.findall(r'(?m)^[ \t]*(?:var|let|const)\s+([A-Za-z_$][\w$]*)\s*=',s)))
 out=[]
 allow={'applyAuthoritativeContext','currentCompanyId','syncState','setHeader','delegated','moduleCards','renderList','renderDashboard','renderCustomers','renderItems','renderInventory','renderFinance','renderReports','main1Delegation','globalSearch'}
 for n in funcs:
  if n.startswith('RW_') or n in allow:
   b=fn(s,n)
   if b:out.append(('fn',n,b))
 for n in vars_:
  if n.startswith('RW_') or n=='actions':
   b=var(s,n)
   if b:out.append(('var',n,b))
 return out
def replace_or_insert(target,kind,name,block):
 old=fn(target,name) if kind=='fn' else var(target,name)
 if old is not None:return target.replace(old,block,1),old!=block,True
 anchors=['var RW_Data=','var RW_Navigation=','var RW_Auth=','})();']
 p=next((target.find(a) for a in anchors if target.find(a)!=-1),-1)
 if p<0:p=len(target)
 return target[:p]+block+'\n\n'+target[p:],True,False
def repair_main7(s):
 p=re.compile(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}",re.M); return p.sub(r'\1));}',s,count=1)
def patch_owner(s):
 s,n=re.subn(r"var owner=!!op\.data\|\|meta\.isOwner===true\|\|meta\.isOwner==='true';","var owner=meta.isOwner===true||meta.isOwner==='true';",s,count=1); return s,n
def license_patch(s):
 source=(CUR/'main10.md').read_text(encoding='utf-8-sig'); b=var(source,'RW_OwnerLicense')
 if b and 'btn-save-license-only' not in s:
  p=s.find('var RW_Views='); p=p if p>=0 else s.find('var RW_Navigation=')
  if p<0:raise RuntimeError('LICENSE_ANCHOR_MISSING')
  s=s[:p]+b+'\n'+s[p:]
 if "{view:'license'" not in s:
  needle="{view:'audit',label:'سجل التدقيق',perm:'owner'},"
  if needle not in s:raise RuntimeError('LICENSE_MENU_ANCHOR_MISSING')
  s=s.replace(needle,needle+"{view:'license',label:'إدارة الترخيص',perm:'owner'},",1)
 if 'license:RW_OwnerLicense.render' not in s:
  needle='audit:RW_Audit_renderTab,'
  if needle not in s:raise RuntimeError('LICENSE_ACTION_ANCHOR_MISSING')
  s=s.replace(needle,needle+'license:RW_OwnerLicense.render,',1)
 return s

def validate(html,baseline=None,final=False):
 req=['rw-login-page','rw-main-shell','rw-page-container','rw-header-title','rw-header-subtitle','rw-sidebar-nav','rw-logout-btn','window.RW_ShellContext','window.RW_OwnerLicense','window.RW_Views','window.RW_Dashboard','window.RW_Items','window.RW_POS','window.RW_Orders','window.RW_Runsheets','window.RW_Purchases','window.RW_Warehouse','window.RW_Finance','window.RW_Reports','window.RW_HR','window.RW_CRM']
 if final:req+=['btn-save-license-only',"{view:'license'",'license:RW_OwnerLicense.render','_clickNotif','_renderAndSave','_updateBadge','markRead']
 miss=[x for x in req if x not in html]
 if miss:raise RuntimeError('CONTRACT_MISSING:'+','.join(miss))
 if html.lower().count('</html>')!=1 or html.lower().count('</body>')!=1:raise RuntimeError('DOCUMENT_CLOSURE_INVALID')
 if html.count('<!doctype')!=1:raise RuntimeError('DOCTYPE_INVALID')
 p=Path('/tmp/new-main-surgical.js');p.write_text(js(html),encoding='utf-8'); r=subprocess.run(['node','--check',str(p)],capture_output=True,text=True)
 if r.returncode:print(r.stderr);raise RuntimeError('JS_SYNTAX_FAIL')
 for t in FORBIDDEN:
  if re.search(r"\.from\(['\"]"+re.escape(t)+r"['\"]\)[\s\S]{0,1000}?\.(?:update|insert|upsert|delete)\s*\(",html):raise RuntimeError('DIRECT_BUSINESS_STATE_WRITE:'+t)
 if baseline is not None:
  for x in PROTECTED_IDS:
   if x in baseline and x not in html:raise RuntimeError('PROTECTED_ID_REMOVED:'+x)
 return True

def main():
 if not TARGET.is_file() or not TARGET.stat().st_size:raise RuntimeError('NEW_MAIN_MISSING')
 if not LEGACY.is_file() or not LEGACY.stat().st_size:raise RuntimeError('LEGACY_MAIN_MISSING')
 if any(not p.is_file() or not p.stat().st_size for p in PARTS):raise RuntimeError('MISSING_MAIN_PART')
 baseline=TARGET.read_text(encoding='utf-8'); legacy=H(LEGACY.read_text(encoding='utf-8'))
 validate(baseline)
 current=baseline; phases=[]
 for idx,pth in enumerate(PARTS,1):
  source=pth.read_text(encoding='utf-8-sig')
  if idx==7:source=repair_main7(source)
  if idx==1:source,n=patch_owner(source)
  before=H(js(current)); ops=[]
  for kind,name,block in declarations(js(source)):
   current,changed,exists=replace_or_insert(current,kind,name,block)
   if changed:ops.append(('replace' if exists else 'insert')+':'+kind+':'+name)
  if idx==10:current=license_patch(current);ops.append('license:canonical-main10')
  validate(current,baseline)
  after=H(js(current))
  if before==after:raise RuntimeError(f'NO_SURGICAL_DELTA_MAIN{idx}')
  phases.append({'phase':idx,'source':str(pth),'before_script_sha256':before,'after_script_sha256':after,'artifact_sha256':H(current),'artifact_bytes':len(current.encode()),'operations':ops})
 validate(current,baseline,final=True)
 if H(LEGACY.read_text(encoding='utf-8'))!=legacy:raise RuntimeError('LEGACY_MAIN_HTML_CHANGED')
 old_ids=set(re.findall(r'\bid=["\']([^"\']+)["\']',baseline)); new_ids=set(re.findall(r'\bid=["\']([^"\']+)["\']',current));
 if old_ids-new_ids:raise RuntimeError('TARGET_DOM_IDS_REMOVED:'+','.join(sorted(old_ids-new_ids)[:50]))
 CTO.mkdir(parents=True,exist_ok=True)
 EVIDENCE.write_text(json.dumps({'event_type':'MASTER_SURGICAL_RECONSTRUCTION_MAIN1_TO_MAIN11','mode':'SEQUENTIAL_SURGICAL_DECLARATION_MERGE','target':str(TARGET),'baseline_target_sha256':H(baseline),'candidate_target_sha256':H(current),'legacy_main_sha256':legacy,'legacy_main_html_modified':False,'phases':phases,'atomic_write':True,'all_phases_validated_before_write':True},ensure_ascii=False,indent=2),encoding='utf-8')
 TARGET.write_text(current,encoding='utf-8')
 print(json.dumps({'status':'READY_TO_PERSIST','phases':11,'baseline':H(baseline),'candidate':H(current),'legacy_protected':True},ensure_ascii=False))
if __name__=='__main__':main()
