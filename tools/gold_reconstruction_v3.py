import hashlib,json,re,subprocess,tempfile,shutil
from pathlib import Path
R=Path('.'); C=R/'Current/CTO'; M=R/'Current/PWA/main.html'; Q=R/'Current/PWA/main.reconstruction.html'; O=R/'Original/PWA/main.html'; F=R/'Current/PWA/main'; parts=[f'main{i}.md' for i in range(1,12)]
def h(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def m(p):
 b=p.read_bytes(); return {'path':str(p),'bytes':len(b),'lines':b.count(b'\n')+1,'sha256':h(p)}
def rx(t,p): return sorted(set(re.findall(p,t)))
def ex(t):
 return {'functions':rx(t,r'(?<![\w$])function\s+([A-Za-z_$][\w$]*)\s*\('),'rw':rx(t,r'(?<![\w$])RW_[A-Za-z0-9_$]+'),'rpcs':rx(t,r'\.rpc\(\s*["\']([^"\']+)["\']'),'edges':rx(t,r'functions/v1/([A-Za-z0-9._-]+)'),'tables':rx(t,r'\.from\(\s*["\']([^"\']+)["\']')}
def static(t):
 return {'doctype':bool(re.search(r'<!doctype\s+html',t,re.I)),'shell_context':'RW_ShellContext' in t and 'getCompanyId' in t,'owner':'RW_OwnerContract' in t,'owner_license':'RW_OwnerLicense' in t,'rec_purchase':'rec-purchase' in t,'rec_offers':'rec-offers' in t,'no_root_company':'00000000-0000-0000-0000-000000000001' not in t,'no_direct_stock':not bool(re.search(r"\.from\(['\"]stock_branches['\"]\)[\s\S]{0,1200}?\.(?:update|insert|upsert|delete)\(",t)),'no_direct_inventory_log':not bool(re.search(r"\.from\(['\"]inventory_log['\"]\)[\s\S]{0,1200}?\.(?:update|insert|upsert|delete)\(",t)),'no_unscoped_settings':not bool(re.search(r"\.from\(['\"]app_settings['\"]\)[\s\S]{0,800}?\.limit\(\s*1\s*\)",t))}
def syntax(t):
 blocks=re.findall(r'<script(?![^>]*\bsrc=)([^>]*)>(.*?)</script>',t,re.S|re.I); bad=[]
 with tempfile.TemporaryDirectory() as d:
  for i,(a,x) in enumerate(blocks):
   p=Path(d)/('x.mjs' if re.search(r'\btype=["\']module["\']',a,re.I) else 'x.js'); p.write_text(x,encoding='utf-8'); r=subprocess.run(['node','--check',str(p)],capture_output=True,text=True)
   if r.returncode: bad.append({'script':i+1,'stderr':r.stderr[-4000:]})
 return {'count':len(blocks),'failures':bad}
def main():
 C.mkdir(parents=True,exist_ok=True); frag={p:(F/p).read_text(encoding='utf-8',errors='replace') for p in parts}; original=O.read_text(encoding='utf-8',errors='replace')
 base={'git_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'current_main':m(M),'original_main':m(O),'fragments':{p:m(F/p) for p in parts}}
 (C/'RECONSTRUCTION_BASELINE.json').write_text(json.dumps(base,ensure_ascii=False,indent=2),encoding='utf-8')
 with tempfile.TemporaryDirectory() as d:
  b=Path(d)/'main'; shutil.copy2(M,b)
  try:
   subprocess.run(['python3','tools/p0_main_shell_repair_v2.py'],check=True)
   cand=M.read_text(encoding='utf-8',errors='replace')
  finally: shutil.copy2(b,M)
 Q.write_text(cand,encoding='utf-8')
 ce,oe=ex(cand),ex(original); fg={p:ex(t) for p,t in frag.items()}; cov={p:{k:[x for x in fg[p][k] if x in cand] for k in ('rw','functions','rpcs','edges')} for p in parts}
 losses={p:{k:[x for x in fg[p][k] if x not in cov[p][k]] for k in ('rw','functions','rpcs','edges')} for p in parts}; losses={p:v for p,v in losses.items() if any(v.values())}
 ol={k:[x for x in oe[k] if x not in ce[k]] for k in ('rw','functions','rpcs','edges')}; st=static(cand); sy=syntax(cand)
 freg={'generated_from':base['git_head'],'fragments':{p:{'meta':base['fragments'][p],'contracts':fg[p],'coverage':cov[p]} for p in parts}}
 (C/'feature_registry.json').write_text(json.dumps(freg,ensure_ascii=False,indent=2),encoding='utf-8')
 (C/'function_registry.json').write_text(json.dumps({'original':oe,'candidate':ce,'fragments':fg},ensure_ascii=False,indent=2),encoding='utf-8')
 (C/'contract_registry.json').write_text(json.dumps({'tenant':'users.auth_id -> users.company_id -> RW_ShellContext','owner':'RW_OwnerContract + RW_OwnerLicense','inventory':'post_stock_movement only; reserve_stock reservation only','fulfillment':'order_details authoritative; run_sheet_details derived','static':st},ensure_ascii=False,indent=2),encoding='utf-8')
 (C/'dependency_graph.json').write_text(json.dumps({'candidate':ce,'edges':{'tables':ce['tables'],'rpcs':ce['rpcs'],'edge_functions':ce['edges']}},ensure_ascii=False,indent=2),encoding='utf-8')
 report={'gate0':base,'gate1':'PASS','gate2':{'semantic_losses':losses},'gate3':m(Q),'gate4':{'static':st,'syntax':sy,'original_surface_loss':ol}}
 (C/'parity.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 fail=['STATIC:'+k for k,v in st.items() if not v]
 if sy['failures']: fail.append('JS_SYNTAX')
 if losses: fail.append('FRAGMENT_SEMANTIC_LOSS')
 if any(ol.values()): fail.append('ORIGINAL_SURFACE_LOSS')
 if h(M)!=base['current_main']['sha256']: fail.append('MAIN_MUTATED')
 print(json.dumps({'status':'PASS' if not fail else 'FAIL','failures':fail,'candidate_sha256':h(Q)},ensure_ascii=False,indent=2))
 if fail: raise SystemExit(1)
if __name__=='__main__': main()
