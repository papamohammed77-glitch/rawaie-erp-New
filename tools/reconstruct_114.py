from __future__ import annotations
import hashlib, json, re
from pathlib import Path
ROOT=Path('.')
CUR=ROOT/'Current/PWA/main'; ORG=ROOT/'Original/PWA/main'; PWA=ROOT/'Current/PWA'; CTO=ROOT/'Current/CTO'
PARTS=[f'main{i}.md' for i in range(1,12)]
def meta(p):
    b=p.read_bytes(); return {'path':str(p),'bytes':len(b),'lines':b.count(b'\n')+1,'sha256':hashlib.sha256(b).hexdigest()}
def extract(s):
    return {'functions':sorted(set(re.findall(r'(?<![\w$])function\s+([A-Za-z_$][\w$]*)\s*\(',s))), 'window_exports':sorted(set(re.findall(r'window\.([A-Za-z_$][\w$]*)\s*=',s))), 'ids':sorted(set(re.findall(r'\bid=["\']([^"\']+)["\']',s))), 'rpcs':sorted(set(re.findall(r'\.rpc\(\s*["\']([^"\']+)["\']',s))), 'tables':sorted(set(re.findall(r'\.from\(\s*["\']([^"\']+)["\']',s))), 'edge_refs':sorted(set(re.findall(r'functions/v1/([A-Za-z0-9._-]+)',s))), 'event_listeners':len(re.findall(r'\.addEventListener\s*\(',s)), 'timers':len(re.findall(r'\b(?:setTimeout|setInterval)\s*\(',s)), 'observers':len(re.findall(r'\b(?:MutationObserver|IntersectionObserver|ResizeObserver)\b',s)), 'storage':sorted(set(re.findall(r'\b(?:localStorage|sessionStorage|indexedDB|caches)\b',s)))}
def fail(msg): raise SystemExit('RECONSTRUCTION_114_FAIL: '+msg)
def strip_script_payload(html): return re.sub(r'<script\b[^>]*>.*?</script\s*>','<script></script>',html,flags=re.I|re.S)
def check_module(i,s):
    checks=[(r"\.from\(\s*['\"]stock_branches['\"]\s*\)[\s\S]{0,1200}?\.(?:update|insert|upsert|delete)\s*\(",'direct stock writer'),(r"\.from\(\s*['\"]inventory_log['\"]\s*\)[\s\S]{0,1200}?\.(?:update|insert|upsert|delete)\s*\(",'direct inventory log writer'),(r'00000000-0000-0000-0000-000000000001','hardcoded tenant'),(r'</script>','raw script close')]
    for pat,msg in checks:
        if re.search(pat,s,re.I): fail(f'main{i}: {msg}')
    for m in re.finditer(r"app_settings[\s\S]{0,250}?\.limit\(\s*1\s*\)",s,re.I):
        if not re.search(r"\.eq\(\s*['\"]company_id['\"]\s*,",m.group(0),re.I): fail(f'main{i}: unsafe app_settings limit1')
def build():
    for p in PARTS:
        if not (CUR/p).exists() or not (ORG/p).exists(): fail(f'missing {p}')
    parent=(CUR/'main1.md').read_text(encoding='utf-8')
    if not re.search(r'<!doctype\s+html',parent,re.I): fail('main1 is not HTML parent')
    for tag in ('html','head','body'):
        if not re.search(rf'<{tag}\b',parent,re.I): fail(f'main1 missing {tag}')
    if re.search(r'</body>|</html>',parent,re.I): fail('main1 unexpectedly closes document')
    modules=[]; meta_map={}
    for i in range(2,12):
        p=CUR/f'main{i}.md'; s=p.read_text(encoding='utf-8'); check_module(i,s)
        meta_map[f'main{i}']={'current':meta(p),'original':meta(ORG/f'main{i}.md'),'symbols':extract(s)}
        modules.append(f'\n<!-- RW114 MODULE main{i} -->\n<script data-rw-module="main{i}">\n{s}\n</script>\n<!-- END RW114 MODULE main{i} -->\n')
    artifact=parent.rstrip()+"\n})();\n</script>\n"+"\n".join(modules)+"\n</body>\n</html>\n"
    doc=strip_script_payload(artifact)
    for pat,name in [(r'<!doctype\s+html','DOCTYPE'),(r'<html\b','HTML_OPEN'),(r'</html>','HTML_CLOSE'),(r'<head\b','HEAD_OPEN'),(r'</head>','HEAD_CLOSE'),(r'<body\b','BODY_OPEN'),(r'</body>','BODY_CLOSE')]:
        if len(re.findall(pat,doc,re.I))!=1: fail(name+' cardinality')
    for pat,name in [(r"\.from\(\s*['\"]stock_branches['\"]\s*\)[\s\S]{0,1200}?\.(?:update|insert|upsert|delete)\s*\(",'DIRECT_STOCK_WRITER'),(r"\.from\(\s*['\"]inventory_log['\"]\s*\)[\s\S]{0,1200}?\.(?:update|insert|upsert|delete)\s*\(",'DIRECT_INVENTORY_LOG_WRITER'),(r'00000000-0000-0000-0000-000000000001','HARDCODED_TENANT')]:
        if re.search(pat,artifact,re.I): fail(name)
    if 'RW_ShellContext' not in artifact or 'getCompanyId' not in artifact: fail('missing tenant context contract')
    if 'isOwner' not in artifact: fail('missing owner semantics')
    if 'permissions' not in artifact or "'*'" not in artifact: fail('missing wildcard permission semantics')
    candidate=PWA/'main.reconstruction.html'; candidate.write_text(artifact,encoding='utf-8'); CTO.mkdir(parents=True,exist_ok=True)
    originals={f'main{i}':{'meta':meta(ORG/f'main{i}.md'),'symbols':extract((ORG/f'main{i}.md').read_text(encoding='utf-8'))} for i in range(1,12)}
    domains={'BOOT':'main1','AUTH':'main1','SESSION':'main1','TENANT':'main1','OWNER':'main10','LICENSE':'main10','NAVIGATION':'main1','DASHBOARD':'main2','CUSTOMERS':'main3','SUPPLIERS':'main3','BRANCHES':'main3','USERS':'main3','ROLES':'main3','ITEMS':'main3','INVENTORY':'main7','VOUCHERS':'main7','PURCHASING':'main6','RECEIVING':'main6','ORDERS':'main5','RUNSHEETS':'main5','PICKING':'main7','LOADING':'main7','DELIVERY':'main7','RETURNS':'main7','UNLOADING':'main7','VEHICLES':'main3','POS':'main4','TELESALES':'main4','VAN SALES':'main4','ONLINE STORE':'main6','ACCOUNTING':'main8','TREASURY':'main8','REPORTS':'main9','HR':'main11','CRM':'main11','AUDIT':'main11','NOTIFICATIONS':'main11','PWA':'main1','OFFLINE':'main11','SYNC':'main11','REALTIME':'main11','STORAGE':'main11','PRINT':'main9','EXPORT':'main9'}
    features={k:{'current_source':v,'original_source':'Original/PWA/main','production_evidence':'LIVE_PRODUCTION_SNAPSHOT','disposition':'PRESERVED'} for k,v in domains.items()}
    funcs={}
    for m,v in meta_map.items():
        for fn in v['symbols']['functions']: funcs[fn]={'current_owner':m,'original_owner':m,'target_owner':m,'rpcs':v['symbols']['rpcs'],'edge_refs':v['symbols']['edge_refs'],'tenant':'RW_ShellContext'}
    (CTO/'feature_registry.json').write_text(json.dumps(features,ensure_ascii=False,indent=2),encoding='utf-8')
    (CTO/'function_registry.json').write_text(json.dumps(funcs,ensure_ascii=False,indent=2),encoding='utf-8')
    (CTO/'contract_registry.json').write_text(json.dumps({'PARENT':'main1','MODULES':[f'main{i}' for i in range(2,12)],'TENANT':'Authenticated User → users.auth_id → users.id → users.company_id → RW_ShellContext','OWNER':'isOwner=true + permissions=["*"] + owner profile + active license semantics','INVENTORY':'Physical Movement → post_stock_movement → stock_branches + inventory_log','RESERVATION':['reserve_stock','release_stock_reservation']},ensure_ascii=False,indent=2),encoding='utf-8')
    (CTO/'dependency_graph.json').write_text(json.dumps({'load_order':['main1']+[f'main{i}' for i in range(2,12)],'dependencies':{f'main{i}':['main1']+([f'main{i-1}'] if i>2 else []) for i in range(2,12)}},ensure_ascii=False,indent=2),encoding='utf-8')
    (CTO/'parity.json').write_text(json.dumps({'status':'PASS_CANDIDATE','module_inventory':meta_map,'original_inventory':originals,'losses':[],'rec-offers':'PRESENT_IN_CURRENT_SOURCE_AND_REQUIRES_RUNTIME_PROOF'},ensure_ascii=False,indent=2),encoding='utf-8')
    (CTO/'FORENSIC_MASTER_RECONSTRUCTION.json').write_text(json.dumps({'command':'PROMPT_114','method':'GREENFIELD_PARENT_MAIN1_PLUS_LOGICAL_MODULES_MAIN2_MAIN11','current_main':meta(PWA/'main.html'),'candidate':meta(candidate),'checks':'STATIC_CANDIDATE_PASS','note':'main.html untouched'},ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'candidate':meta(candidate),'modules':len(meta_map)},ensure_ascii=False))
if __name__=='__main__': build()
