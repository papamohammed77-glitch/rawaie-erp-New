from pathlib import Path
import hashlib
import json
import re
import runpy
import shutil

ROOT=Path('.')
CURRENT=ROOT/'Current/PWA/main.html'
CANDIDATE=ROOT/'Current/PWA/main.reconstruction.html'
ORIGINAL=ROOT/'Original/PWA/main.html'
P0=ROOT/'tools/p0_main_shell_repair_v2.py'
CTO=ROOT/'Current/CTO'

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def symbols(s):
    return {
      'functions': sorted(set(re.findall(r'(?<![\\w$])function\\s+([A-Za-z_$][\\w$]*)\\s*\\(',s))),
      'ids': sorted(set(re.findall(r'\\bid=["\\']([^"\\']+)["\\']',s))),
      'rpcs': sorted(set(re.findall(r'\\.rpc\\(\\s*["\\']([^"\\']+)["\\']',s))),
      'tables': sorted(set(re.findall(r'\\.from\\(\\s*["\\']([^"\\']+)["\\']',s))),
      'edge_refs': sorted(set(re.findall(r'functions/v1/([A-Za-z0-9._-]+)',s))),
    }

def build():
    if not CURRENT.is_file() or not ORIGINAL.is_file(): raise SystemExit('SOURCE_MISSING')
    shutil.copyfile(CURRENT,CANDIDATE)
    tmp=Path('/tmp/p0_candidate_20260831.py')
    txt=P0.read_text(encoding='utf-8').replace('Current/PWA/main.html','Current/PWA/main.reconstruction.html')
    tmp.write_text(txt,encoding='utf-8')
    runpy.run_path(str(tmp),run_name='__main__')
    from tools.master_reconstruction_postprocess import restore_rec_offers
    s=CANDIDATE.read_text(encoding='utf-8')
    s,changed=restore_rec_offers(s)
    if changed: CANDIDATE.write_text(s,encoding='utf-8')
    return changed

def gate():
    s=CANDIDATE.read_text(encoding='utf-8'); o=ORIGINAL.read_text(encoding='utf-8')
    req=['window.RW_ShellContext','window.RW_OwnerContract','RW_ShellContext.getCompanyId()','rec-purchase','rec-offers']
    for x in req:
        if x not in s: raise SystemExit('MISSING_REQUIRED_CONTRACT:'+x)
    if "meta.permissions || ['*']" in s: raise SystemExit('OWNER_WILDCARD_FALLBACK')
    if re.search(r"\\.from\\(['\"]app_settings['\"]\\)\\.select\\([^;]*?\\)\\.limit\\(\\s*1\\s*\\)",s,re.S): raise SystemExit('UNSCOPED_APP_SETTINGS_LIMIT1')
    if re.search(r"\\.from\\(['\"]stock_branches['\"]\\)[\\s\\S]{0,500}?\\.(?:update|insert|upsert|delete)\\(",s): raise SystemExit('DIRECT_STOCK_WRITER')
    if re.search(r"\\.from\\(['\"]inventory_log['\"]\\)[\\s\\S]{0,500}?\\.(?:update|insert|upsert|delete)\\(",s): raise SystemExit('DIRECT_INVENTORY_LOG_WRITER')
    for n in ['<!doctype\\s+html','<html\\b','</html>','<head\\b','</head>','<body\\b','</body>']:
        if not re.search(n,s,re.I): raise SystemExit('HTML_STRUCTURE_FAIL:'+n)
    if s.lower().count('<script')!=s.lower().count('</script>'): raise SystemExit('SCRIPT_BALANCE_FAIL')
    if s.lower().count('<style')!=s.lower().count('</style>'): raise SystemExit('STYLE_BALANCE_FAIL')
    ss,oo=symbols(s),symbols(o)
    losses={k:sorted(set(oo[k])-set(ss[k])) for k in oo}
    if any(losses.values()): raise SystemExit('ORIGINAL_SYMBOL_PARITY_FAIL:'+json.dumps(losses,ensure_ascii=False))
    CTO.mkdir(parents=True,exist_ok=True)
    ledger={'generated_at':'2026-08-31','seed':{'path':str(CURRENT),'sha256':sha(CURRENT),'bytes':CURRENT.stat().st_size},'candidate':{'path':str(CANDIDATE),'sha256':sha(CANDIDATE),'bytes':CANDIDATE.stat().st_size},'original':{'path':str(ORIGINAL),'sha256':sha(ORIGINAL),'bytes':ORIGINAL.stat().st_size},'symbol_losses':losses,'candidate_symbols':{k:len(v) for k,v in ss.items()},'gates':{'html_structure':True,'required_contracts':True,'inventory_writer_prohibition':True,'tenant_guard':True,'owner_guard':True,'original_symbol_parity':True}}
    (CTO/'MAIN_HTML_CURRENT_CONTRACT_LEDGER.json').write_text(json.dumps(ledger,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(ledger,ensure_ascii=False))

if __name__=='__main__':
    changed=build(); gate(); print('FINAL_MAIN_CANDIDATE_BUILD_PASS',changed)
