from pathlib import Path
import re
import json
import hashlib
import subprocess
import tempfile
import traceback

# CTO-TRIGGER-2026-09-03: execution trigger only; governed reconstruction/P163
# remains deterministic and fail-closed.
MAIN = Path('Current/PWA/New-main')
CUR = Path('Current/PWA/main')
PARTS = [CUR / f'main{i}.md' for i in range(1, 12)]
SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJmaWxtb2dndW1va3hhbndhaXl4IiwiaWF0IjoxNzc4NzA5MDkyLCJleHAiOjIwOTQyODUwOTJ9.LZScCxnCiRrTSCCBmTryszQpY1AwBgR2dkTBcC5kOc4'


def fp(text):
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def normalize_main1(raw):
    raw = re.sub(r'(?m)^\s*const RW_Auth\s*=\s*', 'var RW_Auth = ', raw, count=1)
    raw = re.sub(r'(?m)^\s*const RW_Navigation\s*=\s*', 'var RW_Navigation = ', raw, count=1)
    return raw


def patch_main7(raw):
    pattern = re.compile(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}", re.M)
    fixed, count = pattern.subn(r"\1));}", raw, count=1)
    return fixed if count == 1 else raw


def normalize_document_closures(raw):
    raw = re.sub(r'</body>\s*', '', raw, flags=re.I)
    raw = re.sub(r'</html>\s*', '', raw, flags=re.I)
    raw = re.sub(r'\s*<!--\s*RAWAEA_[^>]*-->\s*$', '', raw, flags=re.I | re.S)
    return raw


def repair_runtime_contracts(raw):
    changes = {'supabase_key_replaced': False, 'service_worker_registration_replaced': False, 'service_worker_registration_inserted': False}
    key_pattern = re.compile(r"var\s+RW_SUPABASE_ANON_KEY\s*=\s*(['\"])[^'\"]*\1\s*;", re.S)
    matches = key_pattern.findall(raw)
    if len(matches) != 1:
        raise RuntimeError('RUNTIME_AUTH_KEY_DECLARATION_COUNT:' + str(len(matches)))
    raw, n = key_pattern.subn("var RW_SUPABASE_ANON_KEY='" + SUPABASE_ANON_KEY + "';", raw, count=1)
    if n != 1:
        raise RuntimeError('RUNTIME_AUTH_KEY_REPLACEMENT_COUNT:' + str(n))
    changes['supabase_key_replaced'] = True
    sw_pattern = re.compile(r"(?:if\s*\(\s*['\"]serviceWorker['\"]\s*in\s*navigator\s*\)\s*)?navigator\.serviceWorker\.register\(\s*['\"][^'\"]+['\"](?:\s*,\s*\{\s*scope\s*:\s*['\"][^'\"]+['\"]\s*\})?\s*\)(?:\.catch\(\s*function\s*\([^)]*\)\s*\{[\s\S]*?\}\s*\))?\s*;?", re.S)
    sw_matches = sw_pattern.findall(raw)
    if len(sw_matches) > 1:
        raise RuntimeError('RUNTIME_SW_REGISTRATION_COUNT:' + str(len(sw_matches)))
    if len(sw_matches) == 1:
        raw, nsw = sw_pattern.subn('', raw, count=1)
        if nsw != 1:
            raise RuntimeError('RUNTIME_SW_REGISTRATION_REMOVAL_COUNT:' + str(nsw))
        changes['service_worker_registration_replaced'] = True
    return raw, changes


def validate_fragment(idx, raw):
    if idx == 1:
        if not re.match(r'^\s*<!DOCTYPE html>', raw, re.I):
            raise RuntimeError('MAIN1_HTML_DOCTYPE_MISSING')
        if not re.search(r'^\s*<html\b', raw, re.I | re.M):
            raise RuntimeError('MAIN1_HTML_ROOT_MISSING')
        if not re.search(r'<script\b', raw, re.I):
            raise RuntimeError('MAIN1_SCRIPT_MISSING')
    else:
        if re.search(r'^\s*<!doctype\b', raw, re.I | re.M):
            raise RuntimeError(f'MAIN{idx}_DOCTYPE_FORBIDDEN')
        if re.search(r'^\s*</?(?:html|head|body)\b', raw, re.I | re.M):
            raise RuntimeError(f'MAIN{idx}_DOCUMENT_WRAPPER_FORBIDDEN')
        if re.search(r'</script>', raw, re.I):
            raise RuntimeError(f'MAIN{idx}_SCRIPT_CLOSURE_FORBIDDEN')


def validate_phase_js(chunks):
    # Historical main1..main11 fragments are intentionally incomplete at some
    # boundaries. Partial-file syntax validation is therefore not a valid gate.
    # The complete assembled artifact is validated in validate() below.
    return True


def p163_owner_surgery(candidate):
    s = candidate
    compat = '/* RAWAEA MAIN2 COMPATIBILITY */'
    auth = '/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'
    if s.count(compat) != 1:
        raise RuntimeError('P163_COMPAT_COUNT:' + str(s.count(compat)))
    if s.count(auth) != 1:
        raise RuntimeError('P163_AUTH_COUNT:' + str(s.count(auth)))
    a, b = s.index(compat), s.index(auth)
    if b <= a:
        raise RuntimeError('P163_OWNER_ORDER_INVALID')
    s = s[:a] + s[b:]
    for alias in ('window.RW_Dashboard={render:renderDashboard};', 'window.RW_Items={render:renderItems};'):
        if s.count(alias) != 1:
            raise RuntimeError('P163_ALIAS_COUNT:' + alias + ':' + str(s.count(alias)))
        s = s.replace(alias, '', 1)
    owner = 'window.RW_Items=RW_Items;'
    version = "window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"
    governed = '// MAIN2_GOVERNED_CLOSED:v1'
    if s.count(owner) != 1:
        raise RuntimeError('P163_OWNER_COUNT:' + str(s.count(owner)))
    if version in s:
        raise RuntimeError('P163_VERSION_ALREADY_PRESENT_AFTER_RECONSTRUCTION')
    s = s.replace(owner, owner + '\n' + version + '\n' + governed, 1)
    gates = {
        'compat_absent': compat not in s,
        'auth_one': s.count(auth) == 1,
        'version_one': s.count(version) == 1,
        'governed_one': s.count(governed) == 1,
        'dashboard_alias_absent': 'window.RW_Dashboard={render:renderDashboard};' not in s,
        'items_alias_absent': 'window.RW_Items={render:renderItems};' not in s,
        'actions_preserved': 'actions' in s,
        'main1Delegation_preserved': 'main1Delegation' in s,
        'MAIN3_preserved': 'MAIN3' in s,
        'core_stock_engine': 'post_stock_movement' in s and 'reserve_stock' in s,
        'core_finance_engine': 'post_journal_entry' in s,
        'save_invoice_atomic': 'save_sales_invoice_atomic' in s,
        'edge_call': 'edgeCall' in s,
        'supabase_client': 'supabaseClient' in s,
        'script_balance': s.lower().count('<script') == s.lower().count('</script>'),
        'style_balance': s.lower().count('<style') == s.lower().count('</style>'),
    }
    bad = [k for k, v in gates.items() if not v]
    if bad:
        raise RuntimeError('P163_GOLD_GATE_FAIL:' + repr(bad))
    return s, gates


def assemble():
    missing = [str(p) for p in PARTS if not p.is_file() or p.stat().st_size == 0]
    if missing:
        raise RuntimeError('MISSING_RECONSTRUCTION_PARTS:' + ','.join(missing))
    chunks = []
    for idx, p in enumerate(PARTS, 1):
        raw = p.read_text(encoding='utf-8-sig')
        if idx == 1:
            raw = normalize_main1(raw)
        elif idx == 7:
            raw = patch_main7(raw)
        raw = normalize_document_closures(raw)
        validate_fragment(idx, raw)
        chunks.append(raw.rstrip())
    validate_phase_js(chunks)
    candidate = chunks[0] + '\n\n' + '\n\n'.join(chunks[1:]) + '\n\n</script>\n</body>\n</html>\n'
    candidate, runtime_changes = repair_runtime_contracts(candidate)
    canonical_sw_tag = "<script>if('serviceWorker' in navigator){navigator.serviceWorker.register('./sw.js',{scope:'./'}).catch(function(e){console.warn('SERVICE_WORKER',e)})}</script>"
    body_close = candidate.rfind('</body>')
    if body_close < 0:
        raise RuntimeError('BODY_CLOSE_MISSING_FOR_SW_TAG')
    candidate = candidate[:body_close] + canonical_sw_tag + '\n' + candidate[body_close:]
    runtime_changes['service_worker_registration_inserted'] = True
    candidate, p163_gates = p163_owner_surgery(candidate)
    return candidate, chunks, runtime_changes, p163_gates


def validate(candidate):
    required = [
        'rw-login-page','rw-main-shell','rw-page-container','rw-header-title','rw-header-subtitle','rw-sidebar-nav','rw-logout-btn',
        'window.RW_ShellContext','window.RW_Auth','window.RW_Navigation','window.RW_Views','window.RW_OwnerLicense',
        'window.RW_Dashboard','window.RW_Items','window.RW_POS','window.RW_Orders','window.RW_Runsheets','window.RW_Purchases',
        'window.RW_Warehouse','window.RW_Finance','window.RW_Reports','window.RW_HR','window.RW_CRM'
    ]
    missing = [x for x in required if x not in candidate]
    if missing:
        raise RuntimeError('MISSING_REQUIRED_RECONSTRUCTION_CONTRACTS:' + ','.join(missing))
    if candidate.lower().count('</html>') != 1 or candidate.lower().count('</body>') != 1:
        raise RuntimeError('DOCUMENT_CLOSURE_INVALID')
    if SUPABASE_ANON_KEY not in candidate:
        raise RuntimeError('SUPABASE_ANON_KEY_CANONICAL_MISSING')
    canonical_sw = "navigator.serviceWorker.register('./sw.js',{scope:'./'})"
    if candidate.count(canonical_sw) != 1:
        raise RuntimeError('SERVICE_WORKER_CANONICAL_REGISTRATION_COUNT:' + str(candidate.count(canonical_sw)))
    scripts = re.findall(r'<script(?![^>]*\bsrc\s*=)[^>]*>([\s\S]*?)</script>', candidate, re.I)
    app_scripts = [x for x in scripts if 'serviceWorker.register' not in x]
    if len(app_scripts) != 1:
        raise RuntimeError('APPLICATION_INLINE_SCRIPT_COUNT_INVALID:' + str(len(app_scripts)))
    js_path = Path(tempfile.gettempdir()) / 'rawaea-new-main-assembly.js'
    js_path.write_text(app_scripts[0], encoding='utf-8')
    r = subprocess.run(['node','--check',str(js_path)], capture_output=True, text=True)
    if r.returncode:
        raise RuntimeError('JS_SYNTAX_FAIL:\n' + r.stderr)
    return fp(candidate)


def persist_failure(exc):
    message = ''.join(traceback.format_exception(type(exc), exc, exc.__traceback__))
    try:
        st = Path('CURRENT_STATE.md')
        if st.exists():
            old = st.read_text(encoding='utf-8')
            marker = '## CTO EXECUTOR DIAGNOSTIC — 2026-09-03'
            if marker not in old:
                st.write_text(old.rstrip() + '\n\n' + marker + '\n```text\n' + message + '\n```\n', encoding='utf-8')
                subprocess.run(['git','config','user.name','RAWAEA CTO Executor'], check=True)
                subprocess.run(['git','config','user.email','41898282+github-actions[bot]@users.noreply.github.com'], check=True)
                subprocess.run(['git','add','CURRENT_STATE.md'], check=True)
                subprocess.run(['git','commit','-m','[CTO-DIAGNOSTIC] reconstruction failure captured'], check=True)
                subprocess.run(['git','push','origin','HEAD:main'], check=True)
    except Exception:
        pass


def main():
    candidate, chunks, runtime_changes, p163_gates = assemble()
    digest = validate(candidate)
    tmp = MAIN.with_suffix('.reconstructed.tmp')
    tmp.write_text(candidate, encoding='utf-8')
    tmp.replace(MAIN)
    subprocess.run(['git','config','user.name','RAWAEA CTO Executor'], check=True)
    subprocess.run(['git','config','user.email','41898282+github-actions[bot]@users.noreply.github.com'], check=True)
    subprocess.run(['git','add',str(MAIN)], check=True)
    staged = subprocess.run(['git','diff','--cached','--quiet'])
    if staged.returncode != 0:
        subprocess.run(['git','commit','-m','[CTO-EXECUTED] New-main Gold Diamond closure'], check=True)
        subprocess.run(['git','push','origin','HEAD:main'], check=True)
    running = chunks[0]
    phases = [{'phase':1,'source':'Current/PWA/main/main1.md','script_sha256':fp(running),'bytes':len(running.encode('utf-8'))}]
    for idx in range(2,12):
        running += '\n\n' + chunks[idx-1]
        phases.append({'phase':idx,'source':f'Current/PWA/main/main{idx}.md','script_sha256':fp(running),'bytes':len(running.encode('utf-8'))})
    print(json.dumps({'status':'NEW_MAIN_GOLD_DIAMOND_READY','target':str(MAIN),'sha256':digest,'bytes':len(candidate.encode('utf-8')),'runtime_contracts':runtime_changes,'p163_gates':p163_gates,'phases':phases,'main1_to_main11':True}, ensure_ascii=False))


if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        persist_failure(exc)
        raise
