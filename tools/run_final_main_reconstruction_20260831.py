from pathlib import Path
import re
import subprocess
import json
import hashlib

MAIN=Path('Current/PWA/main.html')
ORIGINAL=Path('Original/PWA/main.html')
CTO=Path('Current/CTO')

subprocess.run(['python3','tools/p0_main_shell_repair_v2.py'],check=True)

# Reuse the governed recommendation post-processor without changing the historical tool.
from tools.master_reconstruction_postprocess import restore_rec_offers, symbols, meta
s=MAIN.read_text(encoding='utf-8')
s,rec=restore_rec_offers(s)
if rec:
    MAIN.write_text(s,encoding='utf-8')
    s=MAIN.read_text(encoding='utf-8')

required=['window.RW_ShellContext','window.RW_OwnerContract','RW_ShellContext.getCompanyId()','rec-purchase','rec-offers']
missing=[x for x in required if x not in s]
if missing: raise SystemExit('MISSING_REQUIRED_RECONSTRUCTION_CONTRACTS:'+','.join(missing))
if "meta.permissions || ['*']" in s: raise SystemExit('OWNER_WILDCARD_FALLBACK_REMAINS')

# Semantic tenant gate: LIMIT 1 is allowed only after an explicit company_id predicate.
pat=re.compile(r"\\.from\\(['\"]app_settings['\"]\\)(?P<chain>[^;\\n]{0,1200}?)\\.limit\\(\\s*1\\s*\\)",re.S)
for m in pat.finditer(s):
    if not re.search(r"\\.eq\\(['\"]company_id['\"]\\s*,",m.group('chain')):
        raise SystemExit('UNSCOPED_APP_SETTINGS_LIMIT1')

if re.search(r"\\.from\\(['\"]stock_branches['\"]\\)[\\s\\S]{0,500}?\\.(?:update|insert|upsert|delete)\\(",s):
    raise SystemExit('DIRECT_STOCK_WRITER_REMAINS')
if re.search(r"\\.from\\(['\"]inventory_log['\"]\\)[\\s\\S]{0,500}?\\.(?:update|insert|upsert|delete)\\(",s):
    raise SystemExit('DIRECT_INVENTORY_LOG_WRITER_REMAINS')

def fp(text):
    return hashlib.sha256(text.encode('utf-8')).hexdigest()
osym=symbols(ORIGINAL.read_text(encoding='utf-8'))
fsym=symbols(s)
losses={k:sorted(set(osym[k])-set(fsym[k])) for k in osym}
if any(losses.values()):
    raise SystemExit('ORIGINAL_SYMBOL_PARITY_FAIL:'+json.dumps(losses,ensure_ascii=False))

CTO.mkdir(parents=True,exist_ok=True)
report={
  'event_type':'FINAL_MAIN_HTML_RECONSTRUCTION_EXECUTED',
  'source_seed':'Current/PWA/main.html before P0 transform',
  'executor':'tools/p0_main_shell_repair_v2.py + tools/master_reconstruction_postprocess.py::restore_rec_offers',
  'historical_fragment_concatenation':False,
  'main_sha256':fp(s),
  'main_bytes':len(s.encode('utf-8')),
  'original_symbol_losses':losses,
  'semantic_tenant_gate':True,
  'owner_wildcard_fallback_blocked':True,
  'direct_physical_stock_writer_blocked':True,
  'browser_runtime':'PENDING',
  'production_runtime':'PENDING'
}
(CTO/'20260831_MAIN_HTML_RECONSTRUCTION_EXECUTION.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
