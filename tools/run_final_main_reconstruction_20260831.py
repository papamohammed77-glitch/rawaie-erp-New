from pathlib import Path
import hashlib
import re
import subprocess
import tempfile

MAIN = Path('Current/PWA/New-main')
CUR = Path('Current/PWA/main')
PARTS = [CUR / f'main{i}.md' for i in range(1, 12)]

VERSION = "window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"
GOVERNED = '// MAIN2_GOVERNED_CLOSED:v1'
AUTH = '/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'
COMPAT = '/* RAWAEA MAIN2 COMPATIBILITY */'
CANONICAL_SW = "navigator.serviceWorker.register('./sw.js',{scope:'./'})"
INLINE_OPEN_RE = re.compile(r'<script(?![^>]*\bsrc\s*=)[^>]*>', re.I)


def normalize(raw, idx):
    if idx == 1:
        raw = re.sub(r'(?m)^\s*const RW_Auth\s*=\s*', 'var RW_Auth = ', raw, count=1)
        raw = re.sub(r'(?m)^\s*const RW_Navigation\s*=\s*', 'var RW_Navigation = ', raw, count=1)
        # Current main1 keeps the application inline script open through EOF;
        # later fragments are its continuation. If it is explicitly closed,
        # remove that single application closure so the eleven parts remain one program.
        opens = list(INLINE_OPEN_RE.finditer(raw))
        if not opens:
            raise RuntimeError('MAIN1_INLINE_SCRIPT_OPENER_MISSING')
        app_open = opens[-1]
        close = raw.find('</script>', app_open.end())
        if close >= 0:
            raw = raw[:close] + raw[close + len('</script>'):]
    if idx == 7:
        raw = re.sub(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}", r"\1));}", raw, count=1)
    raw = re.sub(r'</body>\s*|</html>\s*', '', raw, flags=re.I)
    if idx > 1 and re.search(r'^\s*<!doctype\b|^\s*</?(?:html|head|body)\b|</script>', raw, re.I | re.M):
        raise RuntimeError(f'BAD_FRAGMENT_BOUNDARY:main{idx}')
    return raw.rstrip()


def p163(candidate):
    s = candidate
    # Current governed fragments are already de-duplicated. A compatibility
    # block is removed only if present; its absence is the expected current state.
    if s.count(COMPAT) > 1:
        raise RuntimeError('P163_COMPAT_DUPLICATE')
    if COMPAT in s:
        a = s.index(COMPAT)
        b = s.find(AUTH, a + len(COMPAT))
        if b < 0:
            raise RuntimeError('P163_AUTH_AFTER_COMPAT_MISSING')
        s = s[:a] + s[b:]

    # Bind the current Main2 implementation to one explicit authoritative owner.
    if AUTH not in s:
        anchor = re.search(r'(?m)^\s*var\s+RW_Dashboard\s*=', s)
        if not anchor:
            raise RuntimeError('MAIN2_DASHBOARD_ANCHOR_MISSING')
        s = s[:anchor.start()] + AUTH + '\n' + s[anchor.start():]
    elif s.count(AUTH) != 1:
        raise RuntimeError('P163_AUTH_DUPLICATE')

    # Remove only the two documented Main1 compatibility aliases.
    s = re.sub(r'window\.RW_Dashboard\s*=\s*\{\s*render\s*:\s*renderDashboard\s*\}\s*;?', '', s, count=1)
    s = re.sub(r'window\.RW_Items\s*=\s*\{\s*render\s*:\s*renderItems\s*\}\s*;?', '', s, count=1)

    # Normalize only the authoritative Main2 item export, then place the governed
    # reconstruction marker immediately beneath it.
    s = re.sub(r'window\.RW_Items\s*=\s*RW_Items\s*;', 'window.RW_Items=RW_Items;', s, count=1)
    s = s.replace(VERSION, '').replace(GOVERNED, '')
    owners = list(re.finditer(r'window\.RW_Items=RW_Items;', s))
    if len(owners) != 1:
        raise RuntimeError('P163_ITEMS_OWNER_COUNT:' + str(len(owners)))
    pos = owners[0].end()
    s = s[:pos] + '\n' + VERSION + '\n' + GOVERNED + s[pos:]
    return s


def inject_service_worker(s):
    reg = re.compile(r"(?:if\s*\(\s*['\"]serviceWorker['\"]\s*in\s*navigator\s*\)\s*)?navigator\.serviceWorker\.register\([\s\S]*?\)(?:\.catch\(\s*function\s*\([^)]*\)\s*\{[\s\S]*?\}\s*\))?\s*;?", re.S)
    s = reg.sub('', s)
    body = s.rfind('</body>')
    if body < 0:
        raise RuntimeError('BODY_CLOSE_MISSING')
    tag = "<script>if('serviceWorker' in navigator){navigator.serviceWorker.register('./sw.js',{scope:'./'}).catch(function(e){console.warn('SERVICE_WORKER',e)})}</script>\n"
    s = s[:body] + tag + s[body:]
    if s.count(CANONICAL_SW) != 1:
        raise RuntimeError('SERVICE_WORKER_CANONICAL_COUNT')
    return s


def validate(s):
    required = [
        'rw-login-page','rw-main-shell','rw-page-container','rw-sidebar-nav','rw-logout-btn',
        'window.RW_Auth','window.RW_Navigation','window.RW_Views','window.RW_OwnerLicense',
        'window.RW_Dashboard','window.RW_Items','window.RW_POS','window.RW_Orders','window.RW_Runsheets',
        'window.RW_Purchases','window.RW_Warehouse','window.RW_Finance','window.RW_Reports','window.RW_HR','window.RW_CRM',
        'RW_SUPABASE_CLIENT'
    ]
    missing = [x for x in required if x not in s]
    if missing:
        raise RuntimeError('RECONSTRUCTION_CONTRACT_MISSING:' + repr(missing))
    gates = {
        'doctype': s.lower().count('<!doctype html>') == 1,
        'html_root': s.lower().count('<html') == 1 and s.lower().count('</html>') == 1,
        'body_root': s.lower().count('<body') == 1 and s.lower().count('</body>') == 1,
        'script_balance': s.lower().count('<script') == s.lower().count('</script>'),
        'style_balance': s.lower().count('<style') == s.lower().count('</style>'),
        'auth_one': s.count(AUTH) == 1,
        'version_one': s.count(VERSION) == 1,
        'governed_one': s.count(GOVERNED) == 1,
        'compat_absent': COMPAT not in s,
        'dashboard_legacy_alias_absent': not re.search(r'window\.RW_Dashboard\s*=\s*\{\s*render\s*:\s*renderDashboard\s*\}', s),
        'items_legacy_alias_absent': not re.search(r'window\.RW_Items\s*=\s*\{\s*render\s*:\s*renderItems\s*\}', s),
        'dashboard_export_one': s.count('window.RW_Dashboard=RW_Dashboard;') == 1,
        'items_export_one': s.count('window.RW_Items=RW_Items;') == 1,
        'supabase_client': 'RW_SUPABASE_CLIENT' in s,
        'rpc_usage': '.rpc(' in s,
        'edge_usage': '/functions/v1/' in s,
        'main3_preserved': 'MAIN3' in s,
    }
    bad = [k for k, v in gates.items() if not v]
    if bad:
        raise RuntimeError('P163_GOLD_GATE_FAIL:' + repr(bad))

    app_scripts = [m.group(1) for m in re.finditer(r'<script(?![^>]*\bsrc\s*=)[^>]*>([\s\S]*?)</script>', s, re.I) if 'serviceWorker.register' not in m.group(1)]
    if len(app_scripts) != 1:
        raise RuntimeError('APPLICATION_INLINE_SCRIPT_COUNT:' + str(len(app_scripts)))
    js = Path(tempfile.gettempdir()) / 'rawaea-new-main.js'
    js.write_text(app_scripts[0], encoding='utf-8')
    r = subprocess.run(['node','--check',str(js)], capture_output=True, text=True)
    if r.returncode:
        print(r.stderr)
        raise RuntimeError('FINAL_JS_SYNTAX_FAIL')
    return gates


def main():
    pieces = []
    for idx, p in enumerate(PARTS, 1):
        if not p.is_file() or not p.stat().st_size:
            raise RuntimeError('MISSING_PART:' + str(p))
        pieces.append(normalize(p.read_text(encoding='utf-8-sig'), idx))

    candidate = pieces[0] + '\n\n' + '\n\n'.join(pieces[1:]) + '\n\n</script>\n</body>\n</html>\n'
    candidate = p163(candidate)
    candidate = inject_service_worker(candidate)
    gates = validate(candidate)

    tmp = MAIN.with_suffix('.tmp')
    tmp.write_text(candidate, encoding='utf-8')
    tmp.replace(MAIN)
    print({'status': 'NEW_MAIN_GOLD_DIAMOND_READY', 'target': str(MAIN), 'sha256': hashlib.sha256(candidate.encode('utf-8')).hexdigest(), 'bytes': len(candidate.encode('utf-8')), 'gates': gates})


if __name__ == '__main__':
    main()
