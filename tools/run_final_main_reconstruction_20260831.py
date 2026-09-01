from pathlib import Path
import re
import json
import hashlib
import subprocess
import tempfile

MAIN = Path('Current/PWA/New-main')
CUR = Path('Current/PWA/main')
PARTS = [CUR / f'main{i}.md' for i in range(1, 12)]
SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpaWxtb29nZ3Vtb2t4YW53aXl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3MDkwOTIsImV4cCI6MjA5NDI4NTA5Mn0.LZScCxnCiRrTSCCBmTryszQpY1AwBgR2dkTBbC5kOc4'


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

    canonical_sw = "navigator.serviceWorker.register('./sw.js',{scope:'./'})"
    sw_pattern = re.compile(r"navigator\.serviceWorker\.register\(\s*['\"][^'\"]+['\"](?:\s*,\s*\{\s*scope\s*:\s*['\"][^'\"]+['\"]\s*\})?\s*\)", re.S)
    sw_matches = sw_pattern.findall(raw)
    if len(sw_matches) > 1:
        raise RuntimeError('RUNTIME_SW_REGISTRATION_COUNT:' + str(len(sw_matches)))
    if len(sw_matches) == 1:
        raw, n = sw_pattern.subn(canonical_sw, raw, count=1)
        if n != 1:
            raise RuntimeError('RUNTIME_SW_REPLACEMENT_COUNT:' + str(n))
        changes['service_worker_registration_replaced'] = True
    else:
        insertion = "if('serviceWorker' in navigator){navigator.serviceWorker.register('./sw.js',{scope:'./'}).catch(function(e){console.warn('SERVICE_WORKER',e)})}"
        close = raw.rfind('</script>')
        if close < 0:
            raise RuntimeError('RUNTIME_SW_INSERTION_SCRIPT_CLOSURE_MISSING')
        raw = raw[:close] + insertion + raw[close:]
        changes['service_worker_registration_inserted'] = True

    if "navigator.serviceWorker.register('../sw.js',{scope:'../'})" in raw:
        raise RuntimeError('LEGACY_PARENT_SERVICE_WORKER_REGISTRATION_REMAINS')
    return raw, changes


def validate_fragment(idx, raw):
    if idx == 1:
        if not re.match(r'^\s*<!DOCTYPE html>', raw, re.I):
            raise RuntimeError('MAIN1_HTML_DOCTYPE_MISSING')
        if not re.search(r'^\s*<html\b', raw, re.I | re.M):
            raise RuntimeError('MAIN1_HTML_ROOT_MISSING')
        if not re.search(r'<script\b', raw, re.I):
            raise RuntimeError('MAIN1_SCRIPT_MISSING')
        if re.search(r'</body>|</html>', raw, re.I):
            raise RuntimeError('MAIN1_DOCUMENT_ALREADY_CLOSED')
    else:
        if re.search(r'^\s*<!doctype\b', raw, re.I | re.M):
            raise RuntimeError(f'MAIN{idx}_DOCTYPE_FORBIDDEN')
        if re.search(r'^\s*</?(?:html|head|body)\b', raw, re.I | re.M):
            raise RuntimeError(f'MAIN{idx}_DOCUMENT_WRAPPER_FORBIDDEN')
        if re.search(r'</script>', raw, re.I):
            raise RuntimeError(f'MAIN{idx}_SCRIPT_CLOSURE_FORBIDDEN')


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
        validate_fragment(idx, raw)
        chunks.append(raw.rstrip())

    candidate = chunks[0] + '\n\n' + '\n\n'.join(chunks[1:]) + '\n\n</script>\n</body>\n</html>\n'
    candidate, runtime_changes = repair_runtime_contracts(candidate)
    return candidate, chunks, runtime_changes


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
    if "navigator.serviceWorker.register('./sw.js',{scope:'./'})" not in candidate:
        raise RuntimeError('SERVICE_WORKER_CANONICAL_REGISTRATION_MISSING')
    scripts = re.findall(r'<script(?![^>]*\bsrc\s*=)[^>]*>([\s\S]*?)</script>', candidate, re.I)
    if len(scripts) != 1:
        raise RuntimeError('INLINE_SCRIPT_COUNT_INVALID:' + str(len(scripts)))
    js_path = Path(tempfile.gettempdir()) / 'rawaea-new-main-assembly.js'
    js_path.write_text(scripts[0], encoding='utf-8')
    r = subprocess.run(['node','--check',str(js_path)], capture_output=True, text=True)
    if r.returncode:
        raise RuntimeError('JS_SYNTAX_FAIL:\n' + r.stderr)
    return fp(candidate)


def main():
    candidate, chunks, runtime_changes = assemble()
    digest = validate(candidate)
    tmp = MAIN.with_suffix('.reconstructed.tmp')
    tmp.write_text(candidate, encoding='utf-8')
    tmp.replace(MAIN)

    running = chunks[0]
    phases = [{'phase':1,'source':'Current/PWA/main/main1.md','script_sha256':fp(running),'bytes':len(running.encode('utf-8'))}]
    for idx in range(2,12):
        running += '\n\n' + chunks[idx-1]
        phases.append({'phase':idx,'source':f'Current/PWA/main/main{idx}.md','script_sha256':fp(running),'bytes':len(running.encode('utf-8'))})

    print(json.dumps({'status':'NEW_MAIN_ASSEMBLED_AND_VALIDATED','target':str(MAIN),'sha256':digest,'bytes':len(candidate.encode('utf-8')),'runtime_contracts':runtime_changes,'phases':phases,'main1_to_main11':True}, ensure_ascii=False))


if __name__ == '__main__':
    main()
