from pathlib import Path
import hashlib
import re
import subprocess
import tempfile

MAIN = Path('Current/PWA/New-main')
CUR = Path('Current/PWA/main')
PARTS = [CUR / f'main{i}.md' for i in range(1, 12)]


def normalize(raw, idx):
    if idx == 1:
        raw = re.sub(r'(?m)^\s*const RW_Auth\s*=\s*', 'var RW_Auth = ', raw, count=1)
        raw = re.sub(r'(?m)^\s*const RW_Navigation\s*=\s*', 'var RW_Navigation = ', raw, count=1)
    if idx == 7:
        raw = re.sub(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}", r"\1));}", raw, count=1)
    raw = re.sub(r'</body>\s*|</html>\s*', '', raw, flags=re.I)
    if idx > 1 and re.search(r'^\s*<!doctype\b|^\s*</?(?:html|head|body)\b|</script>', raw, re.I | re.M):
        raise RuntimeError(f'BAD_FRAGMENT_BOUNDARY:main{idx}')
    return raw.rstrip()


def p163(candidate):
    s = candidate
    compat = '/* RAWAEA MAIN2 COMPATIBILITY */'
    auth = '/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'
    if auth not in s:
        anchor = 'var RW_Dashboard ='
        if anchor not in s:
            raise RuntimeError('MAIN2_AUTHORITATIVE_ANCHOR_MISSING')
        s = s.replace(anchor, auth + '\n' + anchor, 1)
    if s.count(compat) > 1:
        raise RuntimeError('P163_COMPAT_DUPLICATE')
    if compat in s:
        a, b = s.index(compat), s.index(auth)
        if b <= a:
            raise RuntimeError('P163_OWNER_ORDER')
        s = s[:a] + s[b:]
    for alias in ('window.RW_Dashboard={render:renderDashboard};', 'window.RW_Items={render:renderItems};'):
        if alias in s:
            s = s.replace(alias, '', 1)
    owner = 'window.RW_Items=RW_Items;'
    version = "window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"
    governed = '// MAIN2_GOVERNED_CLOSED:v1'
    if s.count(owner) != 1:
        raise RuntimeError('P163_ITEMS_OWNER_COUNT:' + str(s.count(owner)))
    if version in s or governed in s:
        raise RuntimeError('P163_MARKER_ALREADY_PRESENT')
    s = s.replace(owner, owner + '\n' + version + '\n' + governed, 1)
    gates = {
        'compat_absent': compat not in s,
        'authoritative_one': s.count(auth) == 1,
        'version_one': s.count(version) == 1,
        'governed_one': s.count(governed) == 1,
        'dashboard_alias_absent': 'window.RW_Dashboard={render:renderDashboard};' not in s,
        'items_alias_absent': 'window.RW_Items={render:renderItems};' not in s,
        'actions_preserved': 'actions' in s,
        'main1Delegation_preserved': 'main1Delegation' in s,
        'MAIN3_preserved': 'MAIN3' in s,
        'stock_engine': 'post_stock_movement' in s and 'reserve_stock' in s,
        'journal_engine': 'post_journal_entry' in s,
        'invoice_engine': 'save_sales_invoice_atomic' in s,
        'edgeCall': 'edgeCall' in s,
        'supabaseClient': 'supabaseClient' in s,
        'script_balance': s.lower().count('<script') == s.lower().count('</script>'),
        'style_balance': s.lower().count('<style') == s.lower().count('</style>'),
    }
    bad = [k for k, v in gates.items() if not v]
    if bad:
        raise RuntimeError('P163_GOLD_GATE_FAIL:' + repr(bad))
    return s


def final_validate(s):
    if s.lower().count('<html') != 1 or s.lower().count('</html>') != 1:
        raise RuntimeError('HTML_ROOT_BALANCE')
    scripts = [m.group(1) for m in re.finditer(r'<script(?![^>]*\bsrc\s*=)[^>]*>([\s\S]*?)</script>', s, re.I)]
    if len(scripts) != 1:
        raise RuntimeError('INLINE_SCRIPT_COUNT:' + str(len(scripts)))
    js = Path(tempfile.gettempdir()) / 'rawaea-new-main.js'
    js.write_text(scripts[0], encoding='utf-8')
    r = subprocess.run(['node', '--check', str(js)], capture_output=True, text=True)
    if r.returncode:
        print(r.stderr)
        raise RuntimeError('FINAL_JS_SYNTAX_FAIL')
    return hashlib.sha256(s.encode('utf-8')).hexdigest()


def main():
    pieces = []
    for idx, p in enumerate(PARTS, 1):
        if not p.is_file() or not p.stat().st_size:
            raise RuntimeError('MISSING_PART:' + str(p))
        pieces.append(normalize(p.read_text(encoding='utf-8-sig'), idx))
    candidate = '\n\n'.join(pieces) + '\n\n</script>\n</body>\n</html>\n'
    candidate = p163(candidate)
    digest = final_validate(candidate)
    MAIN.write_text(candidate, encoding='utf-8')
    print({'status': 'NEW_MAIN_GOLD_DIAMOND_READY', 'target': str(MAIN), 'sha256': digest, 'bytes': len(candidate.encode('utf-8'))})


if __name__ == '__main__':
    main()
