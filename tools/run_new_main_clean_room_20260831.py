# RAWAEA ERP — guarded sequential surgical reconstruction
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path('.');CUR=ROOT/'Current/PWA/main';TARGET=ROOT/'Current/PWA/New-main';LEGACY=ROOT/'Current/PWA/main.html';CTO=ROOT/'Current/CTO'
PARTS=[CUR/f'main{i}.md' for i in range(1,12)];EVIDENCE=CTO/'20260901_NEW_MAIN_SURGICAL_RECONSTRUCTION.json'
FORBIDDEN=['stock_branches','inventory_log','stock_voucher_details','journal_entries','journal_entry_lines','cash_box','customer_ledger','supplier_ledger','driver_ledger']
PROTECTED_IDS={'rw-login-page','rw-main-shell','rw-page-container','rw-header-title','rw-header-subtitle','rw-sidebar-nav','rw-logout-btn','rw-login-form','rw-username','rw-password','rw-notification-btn','rw-notification-badge'}
IGNORE_VARS={'supabase','RW_SUPABASE_URL','RW_SUPABASE_ANON_KEY','RW_STATE'}
SAFE_RW_TABLE="""var RW_Table=(function(){
var state={};
function paginate(tableBodyId,data,page,perPage,renderRowFn){
 if(!data||!data.length){safeHTML(byId(tableBodyId),'<tr><td colspan=\"10\" style=\"text-align:center;padding:30px;color:#94a3b8\">لا توجد بيانات</td></tr>');return;}
 page=Math.max(1,Math.min(page||1,Math.ceil(data.length/(perPage||50))));
 var pp=perPage||50,start=(page-1)*pp,end=Math.min(start+pp,data.length),html='';
 for(var i=start;i<end;i++)html+=renderRowFn(data[i],i);
 safeHTML(byId(tableBodyId),html);
 state[tableBodyId]={data:data,page:page,perPage:pp,totalPages:Math.ceil(data.length/pp),renderRowFn:renderRowFn};
 renderControls(tableBodyId);
}
function renderControls(id){
 var st=state[id],pc=byId(id+'-controls');
 if(!st||!pc||st.totalPages<=1){if(pc)safeHTML(pc,'');return;}
 var h='<div style=\"display:flex;justify-content:center;gap:6px;align-items:center;margin-top:10px;font-size:11px;color:#64748b\">';
 if(st.page>1)h+='<button class=\"rw-btn rw-btn-ghost\" data-rw-page=\"'+(st.page-1)+'\">السابق</button>';
 h+='<span>صفحة '+st.page+' من '+st.totalPages+'</span>';
 if(st.page<st.totalPages)h+='<button class=\"rw-btn rw-btn-ghost\" data-rw-page=\"'+(st.page+1)+'\">التالي</button>';
 h+='</div>';safeHTML(pc,h);
 pc.querySelectorAll('[data-rw-page]').forEach(function(btn){btn.onclick=function(){goPage(id,Number(btn.getAttribute('data-rw-page')));};});
}
function goPage(id,page){var st=state[id];if(st)paginate(id,st.data,page,st.perPage,st.renderRowFn);}
return{paginate:paginate,renderControls:renderControls,goPage:goPage};
})();
window.RW_Table=RW_Table;
"""
def H(x):return hashlib.sha256(x.encode('utf-8')).hexdigest()
def im(h):
 xs=[m for m in re.finditer(r'<script(?P<a>[^>]*)>(?P<b>[\s\S]*?)</script>',h,re.I) if not re.search(r'\bsrc\s*=',m.group('a') or '',re.I)]
 if len(xs)!=1:raise RuntimeError('INLINE_SCRIPT_COUNT_INVALID:'+str(len(xs)))
 return xs[0]
def js(h):return im(h).group('b')
def source_js(raw):
 try:return js(raw)
 except RuntimeError:
  s=raw.lstrip('\ufeff');s=re.sub(r'^\s*```(?:html|javascript|js)?\s*\n','',s,flags=re.I);s=re.sub(r'\n\s*```\s*$','',s,flags=re.I);return s
def bend(s,p):
 d=0;q=None;e=False;lc=False;bc=False;regex=False;charclass=False;i=p;prev_sig=''
 while i<len(s):
  c=s[i];n=s[i+1] if i+1<len(s) else ''
  if line:=lc:
   if c=='\n':lc=False
  elif block:=bc:
   if c=='*' and n=='/':bc=False;i+=1
  elif q:
   if e:e=False
   elif c=='\\':e=True
   elif c==q:q=None
  elif regex:
   if e:e=False
   elif c=='\\':e=True
   elif charclass:
    if c==']':charclass=False
   elif c=='[':charclass=True
   elif c=='/':
    regex=False
    j=i+1
    while j<len(s) and s[j].isalpha():j+=1
    i=j-1
  else:
   if c=='/' and n=='/':lc=True;i+=1
   elif c=='/' and n=='*':bc=True;i+=1
   elif c in "'\"`":q=c
   elif c=='{':d+=1
   elif c=='}':
    d-=1
    if d==0:return i+1
   elif c=='/':
    # Regex literal starts where a JavaScript expression can begin.
    if not prev_sig or prev_sig in '=([{,:;!?&|+*-%^~<>':regex=True
   elif not c.isspace():prev_sig=c
  i+=1
 raise RuntimeError('UNTERMINATED_JS_BLOCK')
def expr_end(s,start):
 stack=[];q=None;e=False;lc=False;bc=False;regex=False;charclass=False;i=start;prev_sig=''
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
  elif regex:
   if e:e=False
   elif c=='\\':e=True
   elif charclass:
    if c==']':charclass=False
   elif c=='[':charclass=True
   elif c=='/':
    regex=False;j=i+1
    while j<len(s) and s[j].isalpha():j+=1
    i=j-1
  else:
   if c=='/' and n=='/':lc=True;i+=1
   elif c=='/' and n=='*':bc=True;i+=1
   elif c in "'\"`":q=c
   elif c=='/':
    if not prev_sig or prev_sig in '=([{,:;!?&|+*-%^~<>':regex=True
   elif c in '([{':stack.append(c)
   elif c in ')]}':
    if not stack:raise RuntimeError('EXPR_UNDERFLOW')
    stack.pop()
    if not stack:
     j=i+1
     while j<len(s) and s[j].isspace():j+=1
     if j<len(s) and s[j]==';':return j+1
   elif not c.isspace():prev_sig=c
  i+=1
 j=s.find(';',start);return j+1 if j!=-1 else len(s)
def fn(s,n):
 m=re.search(r'(?<![\w$])(?:async\s+)?function\s+'+re.escape(n)+r'\s*\([^)]*\)\s*\{',s)
 return None if not m else s[m.start():bend(s,s.find('{',m.start(),m.end()))]
def var(s,n):
 m=re.search(r'(?m)(?:^|\n)[ \t]*(?:var|let|const)\s+'+re.escape(n)+r'\s*=',s)
 if not m:return None
 st=m.start()+(1 if s[m.start():m.start()+1]=='\n' else 0);return s[st:expr_end(s,m.end())]
def replace_block(s,k,n,b):
 old=fn(s,n) if k=='fn' else var(s,n)
 if old is not None:return s.replace(old,b,1),old!=b,True
 anchors=['var RW_Data=','var RW_Navigation=','var RW_Auth=','})();'];p=next((s.find(a) for a in anchors if s.find(a)>=0),len(s));return s[:p]+b+'\n\n'+s[p:],True,False
def decls(s):
 fs=sorted(set(re.findall(r'(?<![\w$])(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\(',s)));vs=sorted(set(re.findall(r'(?m)^[ \t]*(?:var|let|const)\s+([A-Za-z_$][\w$]*)\s*=',s)));out=[]
 for n in fs:
  b=fn(s,n)
  if b:out.append(('fn',n,b))
 for n in vs:
  if n not in IGNORE_VARS:
   b=var(s,n)
   if b:out.append(('var',n,b))
 return out
def merge_source(target,source):
 ops=[]
 for k,n,b in decls(source_js(source)):
  target,changed,exists=replace_block(target,k,n,b)
  if changed:ops.append(('replace' if exists else 'insert')+':'+k+':'+n)
 return target,ops
def license_patch(h):
 s=source_js((CUR/'main10.md').read_text(encoding='utf-8-sig'));b=var(s,'RW_OwnerLicense')
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
def main():
 if any(not p.is_file() or not p.stat().st_size for p in PARTS):raise RuntimeError('MISSING_MAIN_PART')
 if not TARGET.is_file() or not TARGET.stat().st_size:raise RuntimeError('NEW_MAIN_MISSING')
 if not LEGACY.is_file() or not LEGACY.stat().st_size:raise RuntimeError('LEGACY_MAIN_MISSING')
 baseline=TARGET.read_text(encoding='utf-8');legacy=H(LEGACY.read_text(encoding='utf-8'));chunks=[p.read_text(encoding='utf-8-sig') for p in PARTS];current=repair_baseline(baseline,chunks[0]);validate(current,baseline)
 phases=[]
 for idx,pth in enumerate(PARTS,1):
  before=H(js(current));src=pth.read_text(encoding='utf-8-sig')
  if idx==7:src=patch_main7(src)
  current,ops=merge_source(current,src)
  if idx==1:
   current,n=re.subn(r"var owner=!!op\.data\|\|meta\.isOwner===true\|\|meta\.isOwner==='true';","var owner=meta.isOwner===true||meta.isOwner==='true';",current,count=1)
   if n:ops.append('owner:auth-metadata-only')
  if idx==10:current=license_patch(current);ops.append('license:main10-owner-module')
  validate(current,baseline);after=H(js(current))
  if before==after:raise RuntimeError(f'NO_SURGICAL_DELTA_MAIN{idx}')
  phases.append({'phase':idx,'source':str(pth),'before_script_sha256':before,'after_script_sha256':after,'artifact_sha256':H(current),'artifact_bytes':len(current.encode()),'operations':ops})
 validate(current,baseline,final=True)
 if H(LEGACY.read_text(encoding='utf-8'))!=legacy:raise RuntimeError('LEGACY_MAIN_HTML_CHANGED')
 ids0=set(re.findall(r'\bid=["\']([^"\']+)["\']',baseline));ids1=set(re.findall(r'\bid=["\']([^"\']+)["\']',current));removed=sorted(ids0-ids1)
 if removed:raise RuntimeError('TARGET_DOM_IDS_REMOVED:'+','.join(removed[:50]))
 CTO.mkdir(parents=True,exist_ok=True)
 EVIDENCE.write_text(json.dumps({'event_type':'MASTER_SURGICAL_RECONSTRUCTION_MAIN1_TO_MAIN11','mode':'SEQUENTIAL_DECLARATION_LEVEL_SURGERY','target':str(TARGET),'baseline_target_sha256':H(baseline),'candidate_target_sha256':H(current),'legacy_main_sha256':legacy,'legacy_main_html_modified':False,'phases':phases,'atomic_write':True,'all_phases_validated_before_write':True},ensure_ascii=False,indent=2),encoding='utf-8')
 TARGET.write_text(current,encoding='utf-8')
 print(json.dumps({'status':'READY_TO_PERSIST','phases':11,'baseline':H(baseline),'candidate':H(current),'legacy_protected':True},ensure_ascii=False))
if __name__=='__main__':main()
