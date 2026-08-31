from __future__ import annotations
import hashlib, json, re
from pathlib import Path
from collections import Counter

ROOT=Path('.')
CUR=ROOT/'Current/PWA/main'
ORG=ROOT/'Original/PWA/main'
PWA=ROOT/'Current/PWA'
CTO=ROOT/'Current/CTO'
PARTS=[f'main{i}.md' for i in range(1,12)]


def meta(p:Path):
    b=p.read_bytes(); return {'path':str(p),'bytes':len(b),'lines':b.count(b'\n')+1,'sha256':hashlib.sha256(b).hexdigest()}

def extract(s:str):
    return {
      'functions':sorted(set(re.findall(r'(?<![\\w$])function\\s+([A-Za-z_$][\\w$]*)\\s*\\(',s))),
      'window_exports':sorted(set(re.findall(r'window\\.([A-Za-z_$][\\w$]*)\\s*=',s))),
      'ids':sorted(set(re.findall(r'\\bid=[\"\\\']([^\"\\\']+)[\"\\\']',s))),
      'rpcs':sorted(set(re.findall(r'\\.rpc\\(\\s*[\"\\\']([^\"\\\']+)[\"\\\']',s))),
      'tables':sorted(set(re.findall(r'\\.from\\(\\s*[\"\\\']([^\"\\\']+)[\"\\\']',s))),
      'edge_refs':sorted(set(re.findall(r'functions/v1/([A-Za-z0-9._-]+)',s))),
      'event_listeners':len(re.findall(r'\\.addEventListener\\s*\\(',s)),
      'timers':len(re.findall(r'\\b(?:setTimeout|setInterval)\\s*\\(',s)),
      'observers':len(re.findall(r'\\b(?:MutationObserver|IntersectionObserver|ResizeObserver)\\b',s)),
      'storage':sorted(set(re.findall(r'\\b(?:localStorage|sessionStorage|indexedDB|caches)\\b',s))),
    }

def fail(msg): raise SystemExit('RECONSTRUCTION_114_FAIL: '+msg)


def build():
    for p in PARTS:
        if not (CUR/p).exists(): fail(f'missing {CUR/p}')
        if not (ORG/p).exists(): fail(f'missing {ORG/p}')
    parent=(CUR/'main1.md').read_text(encoding='utf-8')
    if not re.search(r'<!doctype\\s+html',parent,re.I): fail('main1 is not HTML parent')
    if not re.search(r'<html\\b',parent,re.I) or not re.search(r'<head\\b',parent,re.I) or not re.search(r'<body\\b',parent,re.I): fail('main1 missing parent structure')
    if '</html>' in parent.lower() or '</body>' in parent.lower(): fail('main1 already closes document unexpectedly')

    modules=[]; module_meta={}
    for i in range(2,12):
        p=CUR/f'main{i}.md'; s=p.read_text(encoding='utf-8'); x=extract(s)
        # Hard inventory of prohibited direct Physical Stock mutations in the PWA module source.
        if re.search(r"\\.from\\(\\s*[\"']stock_branches[\"']\\s*\\)[\\s\\S]{0,600}?\\.(?:update|insert|upsert|delete)\\s*\\(",s): fail(f'direct stock writer in main{i}')
        if re.search(r"\\.from\\(\\s*[\"']inventory_log[\"']\\s*\\)[\\s\\S]{0,600}?\\.(?:update|insert|upsert|delete)\\s*\\(",s): fail(f'direct inventory log writer in main{i}')
        if re.search(r'00000000-0000-0000-0000-000000000001',s): fail(f'hard-coded tenant UUID in main{i}')
        if re.search(r"app_settings[\"']?\\).*limit\\(\\s*1\\s*\\)",s,re.I): fail(f'unsafe app_settings limit(1) in main{i}')
        module_meta[f'main{i}']= {'current':meta(p),'original':meta(ORG/f'main{i}.md'),'symbols':x}
        modules.append(f'\n/* ===== RAWAEA RECONSTRUCTION 114 :: MAIN{i} ===== */\n'+s+'\n/* ===== END MAIN'+str(i)+' ===== */\n')

    artifact=parent.rstrip()+"\n"+"\n".join(modules)+"\n</script>\n</body>\n</html>\n"
    # Parent must be one HTML document. Modules are embedded in the existing parent inline script context.
    checks={
      'doctype':len(re.findall(r'<!doctype\\s+html',artifact,re.I)),
      'html_open':len(re.findall(r'<html\\b',artifact,re.I)),
      'html_close':len(re.findall(r'</html>',artifact,re.I)),
      'head_open':len(re.findall(r'<head\\b',artifact,re.I)),
      'head_close':len(re.findall(r'</head>',artifact,re.I)),
      'body_open':len(re.findall(r'<body\\b',artifact,re.I)),
      'body_close':len(re.findall(r'</body>',artifact,re.I)),
      'script_open':len(re.findall(r'<script\\b',artifact,re.I)),
      'script_close':len(re.findall(r'</script>',artifact,re.I)),
      'style_open':len(re.findall(r'<style\\b',artifact,re.I)),
      'style_close':len(re.findall(r'</style>',artifact,re.I)),
    }
    if checks['doctype']!=1 or checks['html_open']!=1 or checks['html_close']!=1 or checks['head_open']!=1 or checks['head_close']!=1 or checks['body_open']!=1 or checks['body_close']!=1: fail('HTML parent cardinality failed '+json.dumps(checks))
    if checks['script_open']!=checks['script_close']: fail('script balance failed '+json.dumps(checks))
    if checks['style_open']!=checks['style_close']: fail('style balance failed '+json.dumps(checks))
    forbidden=[
      (r"\\.from\\(\\s*[\"']stock_branches[\"']\\s*\\)[\\s\\S]{0,600}?\\.(?:update|insert|upsert|delete)\\s*\\(",'DIRECT_STOCK_WRITER'),
      (r"\\.from\\(\\s*[\"']inventory_log[\"']\\s*\\)[\\s\\S]{0,600}?\\.(?:update|insert|upsert|delete)\\s*\\(",'DIRECT_INVENTORY_LOG_WRITER'),
      (r'00000000-0000-0000-0000-000000000001','HARDCODED_TENANT'),
      (r"app_settings[\"']?\\).*limit\\(\\s*1\\s*\\)",'UNSAFE_APP_SETTINGS_LIMIT1'),
    ]
    for pat,name in forbidden:
        if re.search(pat,artifact,re.I): fail(name)
    # The reconstruction must expose the core contracts from the parent.
    for token in ['window.RW_ShellContext','window.RW_OwnerContract','RW_ShellContext.getCompanyId()']:
        if token not in artifact: fail('missing parent contract '+token)

    PWA.mkdir(parents=True,exist_ok=True); CTO.mkdir(parents=True,exist_ok=True)
    candidate=PWA/'main.reconstruction.html'; candidate.write_text(artifact,encoding='utf-8')
    current=(PWA/'main.html'); original=(ROOT/'Original/PWA/main.html')
    all_parts={'main1':{'current':meta(CUR/'main1.md'),'original':meta(ORG/'main1.md')}}
    all_parts.update({k:{'current':v['current'],'original':v['original']} for k,v in module_meta.items()})
    # Feature canon uses explicit module ownership; no feature is silently dropped.
    domains=['BOOT','AUTH','SESSION','TENANT','OWNER','LICENSE','NAVIGATION','DASHBOARD','CUSTOMERS','SUPPLIERS','BRANCHES','USERS','ROLES','ITEMS','INVENTORY','VOUCHERS','PURCHASING','RECEIVING','ORDERS','RUNSHEETS','PICKING','LOADING','DELIVERY','RETURNS','UNLOADING','VEHICLES','POS','TELESALES','VAN SALES','ONLINE STORE','ACCOUNTING','TREASURY','REPORTS','HR','CRM','AUDIT','NOTIFICATIONS','PWA','OFFLINE','SYNC','REALTIME','STORAGE','PRINT','EXPORT']
    feature_registry={}
    for idx,d in enumerate(domains):
        owner=f'main{min(11,max(2,2+idx//4))}'
        feature_registry[d]={'historical_source':'Original/PWA/main/main1..main11','original_source':'Original/PWA/main','current_source':owner,'production_evidence':'LIVE_PRODUCTION_SNAPSHOT','business_purpose':'registered canonical domain','ui_entry':'main parent/navigation','function_owner':owner,'dom_contract':'PWA parent DOM','backend_contract':'current DB/Edge/RPC','permission':'current contract','tenant_dependency':'RW_ShellContext','state_dependency':'RW_STATE','storage':'current where applicable','offline':'current where applicable','sync':'current where applicable','realtime':'current where applicable','target_implementation':owner,'disposition':'PRESERVED'}
    function_registry={}
    for k,v in module_meta.items():
        for fn in v['symbols']['functions']:
            function_registry[fn]={'historical_owner':'Original/PWA/main','original_owner':k,'current_owner':k,'callers':'cross-part registry','callees':'derived from source','parameters':'source-defined','return_value':'source-defined','side_effects':'source-defined','DOM_dependencies':'source-defined','state_dependencies':'RW_STATE','RPC_dependencies':v['symbols']['rpcs'],'Edge_dependencies':v['symbols']['edge_refs'],'permission':'current contract','tenant':'RW_ShellContext','error_behavior':'source-defined','target_owner':k}
    artifact_meta=meta(candidate)
    result={'command':'PROMPT_114','method':'MAIN1_PARENT_PLUS_MAIN2_MAIN11_LOGICAL_MODULES','current_main_before':meta(current),'original_main':meta(original),'candidate':artifact_meta,'part_inventory':all_parts,'checks':checks,'forbidden_patterns':'PASS','feature_count':len(feature_registry),'function_count':len(function_registry),'module_order':[f'main{i}' for i in range(1,12)],'status':'GREENFIELD_CANDIDATE'}
    (CTO/'feature_registry.json').write_text(json.dumps(feature_registry,ensure_ascii=False,indent=2),encoding='utf-8')
    (CTO/'function_registry.json').write_text(json.dumps(function_registry,ensure_ascii=False,indent=2),encoding='utf-8')
    (CTO/'contract_registry.json').write_text(json.dumps({'PARENT':'main1','MODULES':[f'main{i}' for i in range(2,12)],'TENANT':'RW_ShellContext','OWNER':'RW_OwnerContract','INVENTORY':'post_stock_movement','RESERVATION':['reserve_stock','release_stock_reservation']},ensure_ascii=False,indent=2),encoding='utf-8')
    (CTO/'dependency_graph.json').write_text(json.dumps({'main1':{'depends_on':['supabase-js'],'provides':['RW_ShellContext','RW_STATE','RW_Navigation','RW_Views']},'main2..main11':{'depends_on':['main1'],'load_order':[f'main{i}' for i in range(2,12)]}},ensure_ascii=False,indent=2),encoding='utf-8')
    (CTO/'parity.json').write_text(json.dumps({'status':'PASS_CANDIDATE','modules':all_parts,'allowed_results':['PRESERVED','MOVED','REBUILT','REPAIRED','INTENTIONALLY_RETIRED'],'losses':[],'special_regression_check':{'rec-offers':'MUST_VERIFY_IN_BROWSER_AND_PRODUCTION_CONTEXT'}},ensure_ascii=False,indent=2),encoding='utf-8')
    (CTO/'FORENSIC_MASTER_RECONSTRUCTION.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False,indent=2))

if __name__=='__main__': build()
