# MAIN1 forensic executor: source is Current/PWA/main/main1.md..main11.md; target is New-main only.
from pathlib import Path
import hashlib,json,re,subprocess
CUR=Path('Current/PWA/main'); TARGET=Path('Current/PWA/New-main'); CTO=Path('Current/CTO')
PARTS=[CUR/f'main{i}.md' for i in range(1,12)]; EVIDENCE=CTO/'20260831_NEW_MAIN_CLEAN_ROOM_EXECUTION.json'

def repair_main7(s):
 p=re.compile(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}",re.M); s2,n=p.subn(r"\1));}",s,count=1); return s2,[{'issue':'main7 settlement-rs-select closure','occurrences_fixed':n,'mode':'in-memory'}]
def protect_js(js):
 p=re.compile(r'</\s*script\b[^>]*>',re.I); ms=list(p.finditer(js));
 if not ms:return js
 last=ms[-1]; return js[:last.start()]+p.sub(lambda m:'<\\/script'+m.group(0)[m.group(0).lower().find('script')+6:],js[last.start():],count=1)
def find_main1_runtime(first):
 blocks=list(re.finditer(r'<script(?P<a>[^>]*)>(?P<b>[\s\S]*?)</script>',first,re.I))
 for m in blocks:
  attrs=(m.group('a') or '').lower()
  if not re.search(r'\bsrc\s*=',attrs,re.I): return m,blocks
 m=re.search(r'<script\s*>(?P<b>[\s\S]*?)</script>',first,re.I)
 if m:return m,blocks
 raise RuntimeError('MAIN1_INLINE_SCRIPT_BLOCK_MISSING:count='+str(len(blocks)))
def assemble(chunks):
 first=chunks[0]; inline,blocks=find_main1_runtime(first); prefix=first[:inline.start()]; suffix=first[inline.end():].strip()
 if suffix and not re.fullmatch(r'</body>\s*</html>',suffix,re.I):raise RuntimeError('MAIN1_SUFFIX_INVALID')
 repaired7,repairs=repair_main7(chunks[6]); frags=chunks[:6]+[repaired7]+chunks[7:]
 for i,c in enumerate(frags[1:],2):
  if re.search(r'<(?:!doctype|html|head|body)\b',c,re.I):raise RuntimeError(f'INVALID_DOCUMENT_WRAPPER_MAIN{i}')
 js=protect_js(inline.group('b').strip()+'\n\n'+'\n\n'.join(x.rstrip() for x in frags[1:])); return prefix+'<script>\n'+js+'\n</script>\n</body>\n</html>\n',repairs

def extract_var_block(source,name):
 m=re.search(r'(?:^|\n)(?:var|const|let)\s+'+re.escape(name)+r'\s*=\s*\(function\s*\(\)\s*\{',source)
 if not m: raise RuntimeError('MISSING_VAR_BLOCK:'+name)
 start=m.start(); brace=source.find('{',m.start(),m.end()); depth=0; quote=None; esc=False; i=brace
 while i<len(source):
  ch=source[i]
  if quote:
   if esc: esc=False
   elif ch=='\\': esc=True
   elif ch==quote: quote=None
  else:
   if ch in "'\"`": quote=ch
   elif ch=='{': depth+=1
   elif ch=='}':
    depth-=1
    if depth==0:
     end=source.find(';',i)
     if end==-1: raise RuntimeError('VAR_BLOCK_TERMINATOR_MISSING:'+name)
     return source[start:end+1]
  i+=1
 raise RuntimeError('UNTERMINATED_VAR_BLOCK:'+name)
def repair_owner_and_license(cand):
 repairs=[]
 cand2,n=re.subn(r"var owner=!!op\.data\|\|meta\.isOwner===true\|\|meta\.isOwner==='true';","var owner=meta.isOwner===true||meta.isOwner==='true';",cand,count=1)
 if n:cand=cand2;repairs.append('OWNER_MUST_COME_FROM_AUTH_METADATA')
 main10=(CUR/'main10.md').read_text(encoding='utf-8-sig')
 if 'btn-save-license-only' not in cand or 'license:RW_OwnerLicense' not in cand:
  block=extract_var_block(main10,'RW_OwnerLicense'); marker='window.RW_OwnerLicense=RW_OwnerLicense;'
  if marker not in cand:
   anchor=cand.find('var RW_Views=')
   if anchor==-1: anchor=cand.find('var RW_Navigation=')
   if anchor==-1: raise RuntimeError('LICENSE_INSERT_ANCHOR_MISSING')
   cand=cand[:anchor]+block+'\n'+marker+'\n\n'+cand[anchor:]; repairs.append('RESTORE_CANONICAL_MAIN10_OWNER_LICENSE_MODULE')
 if "{view:'license'" not in cand:
  needle="{view:'audit',label:'سجل التدقيق',perm:'owner'},"
  if needle not in cand: raise RuntimeError('LICENSE_MENU_ANCHOR_MISSING')
  cand=cand.replace(needle,needle+"{view:'license',label:'إدارة الترخيص',perm:'owner'},",1); repairs.append('ADD_LICENSE_OWNER_NAVIGATION')
 if 'license:RW_OwnerLicense.render' not in cand:
  needle='audit:RW_Audit_renderTab,'
  if needle not in cand: raise RuntimeError('LICENSE_ACTION_ANCHOR_MISSING')
  cand=cand.replace(needle,needle+'license:RW_OwnerLicense.render,',1); repairs.append('ADD_LICENSE_VIEW_ACTION')
 return cand,repairs
def validate(c):
 req=['rw-login-page','rw-main-shell','rw-page-container','rw-header-title','rw-header-subtitle','rw-sidebar-nav','rw-logout-btn','window.RW_ShellContext','window.RW_OwnerLicense','window.RW_Views','window.RW_Dashboard','window.RW_Items','window.RW_POS','window.RW_Orders','window.RW_Runsheets','window.RW_Purchases','window.RW_Warehouse','window.RW_Finance','window.RW_Reports','window.RW_HR','window.RW_CRM','btn-save-license-only',"{view:'license'",'license:RW_OwnerLicense.render']; miss=[x for x in req if x not in c]
 if miss:raise RuntimeError('MISSING_REQUIRED_RECONSTRUCTION_CONTRACTS:'+','.join(miss))
 if "var owner=!!op.data" in c:raise RuntimeError('OWNER_INFERENCE_FROM_PROFILE_REMAINS')
 if c.lower().count('</html>')!=1 or c.lower().count('</body>')!=1:raise RuntimeError('DOCUMENT_CLOSURE_INVALID')
 ss=re.findall(r'<script(?![^>]*\bsrc\s*=)[^>]*>(.*?)</script>',c,re.I|re.S)
 if len(ss)!=1:raise RuntimeError('INLINE_SCRIPT_COUNT_INVALID')
 p=Path('/tmp/rw-new-main.js');p.write_text(ss[0],encoding='utf-8');r=subprocess.run(['node','--check',str(p)],capture_output=True,text=True)
 if r.returncode:print(r.stderr);raise RuntimeError('JS_SYNTAX_FAIL')
 forbidden=['stock_branches','inventory_log','stock_voucher_details','journal_entries','journal_entry_lines','cash_box','customer_ledger','supplier_ledger','driver_ledger']
 for t in forbidden:
  if re.search(r"\.from\(['\"]"+re.escape(t)+r"['\"]\)[\s\S]{0,1000}?\.(?:update|insert|upsert|delete)\s*\(",c):raise RuntimeError('DIRECT_BUSINESS_STATE_WRITE:'+t)
def main():
 missing=[str(p) for p in PARTS if not p.is_file() or p.stat().st_size==0]
 if missing:raise RuntimeError('MISSING_RECONSTRUCTION_PARTS:'+','.join(missing))
 chunks=[p.read_text(encoding='utf-8-sig') for p in PARTS];cand,repairs=assemble(chunks);cand,contract_repairs=repair_owner_and_license(cand);repairs.extend(contract_repairs);validate(cand);TARGET.write_text(cand,encoding='utf-8');CTO.mkdir(parents=True,exist_ok=True);e={'event_type':'MASTER_RECONSTRUCTION_GOLD_CANDIDATE_BUILT','target':str(TARGET),'source_seed':'Current/PWA/main/main1.md..main11.md','legacy_main_html_modified':False,'main_html_replacement':'NOT_EXECUTED','repairs':repairs,'html_parser_hardening':True,'artifact_sha256':hashlib.sha256(cand.encode()).hexdigest(),'artifact_bytes':len(cand.encode())};EVIDENCE.write_text(json.dumps(e,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(e,ensure_ascii=False))
if __name__=='__main__':main()
