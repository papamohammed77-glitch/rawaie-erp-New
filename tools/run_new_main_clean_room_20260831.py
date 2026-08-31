from pathlib import Path
import hashlib,json,re,subprocess
CUR=Path('Current/PWA/main'); ORIG=Path('Original/PWA/main'); TARGET=Path('Current/PWA/New-main'); CTO=Path('Current/CTO')
PARTS=[CUR/f'main{i}.md' for i in range(1,12)]; ORIGINAL=[ORIG/f'main{i}.md' for i in range(1,12)]; EVIDENCE=CTO/'20260831_NEW_MAIN_CLEAN_ROOM_EXECUTION.json'
def repair_main7(s):
 p=re.compile(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}",re.M); s2,n=p.subn(r"\1));}",s,count=1); return s2,[{'issue':'main7 settlement-rs-select closure','occurrences_fixed':n,'mode':'in-memory'}]
def symbols(s):
 return {'functions':sorted(set(re.findall(r'(?<![\w$])function\s+([\w$]+)\s*\(',s))),'ids':sorted(set(re.findall(r'\bid=["\']([^"\']+)["\']',s))),'rpcs':sorted(set(re.findall(r'\.rpc\(\s*["\']([^"\']+)["\']',s))),'tables':sorted(set(re.findall(r'\.from\(\s*["\']([^"\']+)["\']',s))),'edge_refs':sorted(set(re.findall(r'functions/v1/([A-Za-z0-9._-]+)',s)))}
def protect_js(js):
 p=re.compile(r'</\s*script\b[^>]*>',re.I); ms=list(p.finditer(js));
 if not ms:return js
 last=ms[-1]; head=js[:last.start()]; tail=js[last.start():]; head=p.sub(lambda m:'<\\/script'+m.group(0)[m.group(0).lower().find('script')+6:],head); return head+tail
def assemble(chunks):
 first=chunks[0]; blocks=list(re.finditer(r'<script(?P<a>[^>]*)>(?P<b>[\s\S]*?)</script>',first,re.I)); inline=None
 for m in blocks:
  if not re.search(r'\bsrc\s*=',m.group('a') or '',re.I): inline=m
 if inline is None:raise RuntimeError('MAIN1_INLINE_SCRIPT_BLOCK_MISSING')
 prefix=first[:inline.start()]; suffix=first[inline.end():].strip()
 if suffix and not re.fullmatch(r'</body>\s*</html>',suffix,re.I):raise RuntimeError('MAIN1_SUFFIX_INVALID')
 repaired7,repairs=repair_main7(chunks[6]); frags=chunks[:6]+[repaired7]+chunks[7:]
 for i,c in enumerate(frags[1:],2):
  if re.search(r'<(?:!doctype|html|head|body)\b',c,re.I):raise RuntimeError(f'INVALID_DOCUMENT_WRAPPER_MAIN{i}')
 js=protect_js(inline.group('b').strip()+'\n\n'+'\n\n'.join(x.rstrip() for x in frags[1:])); return prefix+'<script>\n'+js+'\n</script>\n</body>\n</html>\n',repairs
def validate(c):
 req=['rw-login-page','rw-main-shell','rw-page-container','rw-header-title','rw-header-subtitle','rw-sidebar-nav','rw-logout-btn','window.RW_ShellContext','window.RW_OwnerLicense','window.RW_Views','window.RW_Dashboard','window.RW_Items','window.RW_POS','window.RW_Orders','window.RW_Runsheets','window.RW_Purchases','window.RW_Warehouse','window.RW_Finance','window.RW_Reports','window.RW_HR','window.RW_CRM','rec-purchase','rec-offers']; miss=[x for x in req if x not in c]
 if miss:raise RuntimeError('MISSING_REQUIRED_RECONSTRUCTION_CONTRACTS:'+','.join(miss))
 if c.lower().count('</html>')!=1 or c.lower().count('</body>')!=1:raise RuntimeError('DOCUMENT_CLOSURE_INVALID')
 ss=re.findall(r'<script(?![^>]*\bsrc\s*=)[^>]*>(.*?)</script>',c,re.I|re.S)
 if len(ss)!=1:raise RuntimeError('INLINE_SCRIPT_COUNT_INVALID')
 p=Path('/tmp/rw-new-main.js');p.write_text(ss[0],encoding='utf-8');r=subprocess.run(['node','--check',str(p)],capture_output=True,text=True)
 if r.returncode:print(r.stderr);raise RuntimeError('JS_SYNTAX_FAIL')
 forbidden=['stock_branches','inventory_log','stock_voucher_details','journal_entries','journal_entry_lines','cash_box','customer_ledger','supplier_ledger','driver_ledger']
 for t in forbidden:
  if re.search(r"\.from\(['\"]"+re.escape(t)+r"['\"]\)[\s\S]{0,1000}?\.(?:update|insert|upsert|delete)\s*\(",c):raise RuntimeError('DIRECT_BUSINESS_STATE_WRITE:'+t)
 return True
def main():
 missing=[str(p) for p in PARTS if not p.is_file() or p.stat().st_size==0]
 if missing:raise RuntimeError('MISSING_RECONSTRUCTION_PARTS:'+','.join(missing))
 chunks=[p.read_text(encoding='utf-8-sig') for p in PARTS];cand,repairs=assemble(chunks);validate(cand);TARGET.write_text(cand,encoding='utf-8');CTO.mkdir(parents=True,exist_ok=True);e={'event_type':'MASTER_RECONSTRUCTION_GOLD_CANDIDATE_BUILT','target':str(TARGET),'source_seed':'Current/PWA/main/main1.md..main11.md','legacy_main_html_modified':False,'main_html_replacement':'NOT_EXECUTED','main7_repairs_in_memory':repairs,'html_parser_hardening':True,'artifact_sha256':hashlib.sha256(cand.encode()).hexdigest(),'artifact_bytes':len(cand.encode())};EVIDENCE.write_text(json.dumps(e,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(e,ensure_ascii=False))
if __name__=='__main__':main()
