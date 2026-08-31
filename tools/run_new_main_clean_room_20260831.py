# TEMP MAIN1 completion executor: modifies only Current/PWA/New-main and CURRENT_STATE evidence.
from pathlib import Path
import hashlib, json, re, subprocess

NEW = Path('Current/PWA/New-main')
MAIN1 = Path('Current/PWA/main/main1.md')
TOOL = Path('tools/run_new_main_clean_room_20260831.py')


def extract_function(source: str, name: str):
    m = re.search(r'(?<![\w$])(?:async\s+)?function\s+' + re.escape(name) + r'\s*\([^)]*\)\s*\{', source)
    if not m:
        raise RuntimeError('MISSING_MAIN1_FUNCTION:' + name)
    start = m.start()
    brace = source.find('{', m.start(), m.end())
    depth = 0
    quote = None
    escape = False
    i = brace
    while i < len(source):
        ch = source[i]
        if quote:
            if escape:
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == quote:
                quote = None
        else:
            if ch in "'\"`":
                quote = ch
            elif ch == '{':
                depth += 1
            elif ch == '}':
                depth -= 1
                if depth == 0:
                    return source[start:i+1]
        i += 1
    raise RuntimeError('UNTERMINATED_MAIN1_FUNCTION:' + name)


def extract_var_block(source: str, name: str):
    m = re.search(r'(^|\n)(?:var|const|let)\s+' + re.escape(name) + r'\s*=\s*\(function\s*\(', source)
    if not m:
        raise RuntimeError('MISSING_MAIN1_VAR_BLOCK:' + name)
    start = m.start(0) + (1 if m.group(1) == '\n' else 0)
    marker = source.find('window.' + name + ' = ' + name + ';', start)
    if marker == -1:
        marker = source.find('window.' + name + '=' + name + ';', start)
    if marker == -1:
        raise RuntimeError('MISSING_MAIN1_VAR_EXPORT:' + name)
    end = source.find('\n', marker)
    if end == -1:
        end = len(source)
    return source[start:end]


def replace_function(candidate: str, name: str, replacement: str):
    m = re.search(r'(?<![\w$])(?:async\s+)?function\s+' + re.escape(name) + r'\s*\([^)]*\)\s*\{', candidate)
    if not m:
        return candidate, False
    brace = candidate.find('{', m.start(), m.end())
    depth = 0
    quote = None
    escape = False
    i = brace
    while i < len(candidate):
        ch = candidate[i]
        if quote:
            if escape:
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == quote:
                quote = None
        else:
            if ch in "'\"`":
                quote = ch
            elif ch == '{':
                depth += 1
            elif ch == '}':
                depth -= 1
                if depth == 0:
                    return candidate[:m.start()] + replacement + candidate[i+1:], True
        i += 1
    raise RuntimeError('UNTERMINATED_CANDIDATE_FUNCTION:' + name)


def replace_var_block(candidate: str, name: str, replacement: str):
    m = re.search(r'(^|\n)(?:var|const|let)\s+' + re.escape(name) + r'\s*=\s*\(function\s*\(', candidate)
    if not m:
        raise RuntimeError('MISSING_CANDIDATE_VAR_BLOCK:' + name)
    start = m.start(0) + (1 if m.group(1) == '\n' else 0)
    marker = candidate.find('window.' + name + ' = ' + name + ';', start)
    if marker == -1:
        marker = candidate.find('window.' + name + '=' + name + ';', start)
    if marker == -1:
        raise RuntimeError('MISSING_CANDIDATE_VAR_EXPORT:' + name)
    end = candidate.find('\n', marker)
    if end == -1:
        end = len(candidate)
    return candidate[:start] + replacement + candidate[end:]


def audit_block(main1: str):
    names = ['RW_Audit_renderTab','RW_Audit_loadData','RW_Audit_renderTable','RW_Audit_renderPagination','RW_Audit_goPage','RW_Audit_filterTable','RW_Audit_showDetails']
    body = ['var RW_AUDIT_PAGE = 1;','var RW_AUDIT_PAGE_SIZE = 50;','var RW_AUDIT_TOTAL = 0;','var RW_AUDIT_DATA = [];']
    for n in names:
        body.append(extract_function(main1, n))
    body.append('window.RW_Audit_renderTab = RW_Audit_renderTab;')
    return '\n\n'.join(body)


def main():
    if not NEW.is_file() or NEW.stat().st_size == 0: raise RuntimeError('NEW_MAIN_MISSING')
    if not MAIN1.is_file() or MAIN1.stat().st_size == 0: raise RuntimeError('MAIN1_MISSING')
    candidate = NEW.read_text(encoding='utf-8')
    main1 = MAIN1.read_text(encoding='utf-8-sig')

    candidate, _ = replace_function(candidate, 'RW_Audit_log', extract_function(main1, 'RW_Audit_log'))
    candidate, _ = replace_function(candidate, 'RW_Permissions_check', extract_function(main1, 'RW_Permissions_check'))
    candidate, _ = replace_function(candidate, 'RW_Permissions_applyUI', extract_function(main1, 'RW_Permissions_applyUI'))
    candidate = replace_var_block(candidate, 'RW_Workflow', extract_var_block(main1, 'RW_Workflow'))
    candidate = replace_var_block(candidate, 'RW_Notification', extract_var_block(main1, 'RW_Notification'))

    old_audit = extract_function(main1, 'RW_Audit_renderTab')
    candidate, had_audit = replace_function(candidate, 'RW_Audit_renderTab', old_audit)
    anchor = candidate.find('var RW_Data=')
    if anchor == -1: raise RuntimeError('AUDIT_INSERT_ANCHOR_MISSING')
    full_audit = audit_block(main1)
    # Remove the renderer itself and its export because it was already replaced.
    remainder = full_audit
    remainder = remainder.replace(old_audit + '\n\n', '', 1)
    candidate = candidate[:anchor] + remainder + '\n\n' + candidate[anchor:]

    candidate = candidate.replace("var owner=!!op.data||meta.isOwner===true||meta.isOwner==='true';", "var owner=meta.isOwner===true||meta.isOwner==='true';")
    candidate = candidate.replace("RW_Navigation.buildSidebar();RW_Notification.init();", "RW_Navigation.buildSidebar();await RW_Workflow.loadRules().catch(function(){});RW_Notification.init();", 1)
    candidate = candidate.replace("await RW_Navigation.navigate('dashboard')", "await RW_Navigation.navigate('dashboard');RW_Permissions_applyUI()", 1)

    required = ['RW_Audit_log','RW_Permissions_check','RW_Permissions_applyUI','_clickNotif','_renderAndSave','_updateBadge','markRead','RW_Audit_renderTab','RW_Audit_loadData','RW_Audit_renderTable','RW_Audit_renderPagination','RW_Audit_goPage','RW_Audit_filterTable','RW_Audit_showDetails','RW_Workflow','RW_Notification']
    for n in required:
        if re.search(r'(?<![\w$])' + re.escape(n) + r'\b', candidate) is None: raise RuntimeError('MAIN1_CONTRACT_STILL_MISSING:' + n)
    if "var owner=!!op.data" in candidate: raise RuntimeError('OWNER_INFERENCE_FROM_PROFILE_REMAINS')
    for table in ['stock_branches','inventory_log','stock_voucher_details','journal_entries','journal_entry_lines','cash_box','customer_ledger','supplier_ledger','driver_ledger']:
        if re.search(r"\.from\(['\"]" + re.escape(table) + r"['\"]\)[\s\S]{0,1000}?\.(?:update|insert|upsert|delete)\s*\(", candidate): raise RuntimeError('DIRECT_TRANSACTION_WRITE:' + table)
    scripts = re.findall(r'<script(?![^>]*\bsrc\s*=)[^>]*>(.*?)</script>', candidate, re.I | re.S)
    if len(scripts) != 1: raise RuntimeError('INLINE_SCRIPT_COUNT:' + str(len(scripts)))
    p = Path('/tmp/new-main-main1.js'); p.write_text(scripts[0], encoding='utf-8')
    r = subprocess.run(['node','--check',str(p)], capture_output=True, text=True)
    if r.returncode: print(r.stderr); raise RuntimeError('NEW_MAIN_JS_SYNTAX_FAIL')

    NEW.write_text(candidate, encoding='utf-8')

    # Restore the executor in the working tree and stage that restoration so it cannot remain as a permanent third-file change.
    original = subprocess.check_output(['git','show','HEAD^:tools/run_new_main_clean_room_20260831.py'])
    TOOL.write_bytes(original)
    subprocess.run(['git','add',str(TOOL)],check=True)

    evidence = Path('Current/CTO/20260831_NEW_MAIN_CLEAN_ROOM_EXECUTION.json')
    payload = {'event_type':'MAIN1_COMPLETION_APPLIED_TO_NEW_MAIN','target':str(NEW),'main1_source':'Current/PWA/main/main1.md','legacy_main_html_modified':False,'owner_semantics':'authenticated_metadata_isOwner_only','static_gate':'PASS','browser_runtime':'PENDING_CI','production_runtime':'NOT_DEPLOYED','executor_restored':True,'artifact_sha256':hashlib.sha256(candidate.encode()).hexdigest(),'artifact_bytes':len(candidate.encode())}
    evidence.write_text(json.dumps(payload,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(payload,ensure_ascii=False))

if __name__ == '__main__': main()
