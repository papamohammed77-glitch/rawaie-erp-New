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
    version = "window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"
    governed = '// MAIN2_GOVERNED_CLOSED:v1'

    # The eleven current governed fragments are already de-duplicated. Main2's
    # historical compatibility marker is therefore not required to exist.
    if s.count(compat) > 1:
        raise RuntimeError('P163_COMPAT_DUPLICATE')
    if compat in s:
        a = s.index(compat)
        b = s.find(auth, a + len(compat))
        if b < 0:
            raise RuntimeError('P163_AUTH_AFTER_COMPAT_MISSING')
        s = s[:a] + s[b:]

    # Normalize the one Main2 authoritative boundary. Current main2.md uses
    # whitespace around '=', while earlier assemblies used the compact form.
    if s.count(auth) == 0:
        anchor_re = re.compile(r'(?m)^\s*var\s+RW_Dashboard\s*=')
        m = anchor_re.search(s)
        if not m:
            raise RuntimeError('MAIN2_AUTHORITATIVE_ANCHOR_MISSING')
        s = s[:m.start()] + auth + '\n' + s[m.start():]
    elif s.count(auth) > 1:
        raise RuntimeError('P163_AUTH_DUPLICATE')

    # Remove only the two Main1 legacy aliases, accepting harmless formatting
    # differences but refusing to remove other RW_* exports.
    alias_patterns = (
        r'window\.RW_Dashboard\s*=\s*\{\s*render\s*:\s*renderDashboard\s*\}\s*;',
        r'window\.RW_Items\s*=\s*\{\s*render\s*:\s*renderItems\s*\}\s*;'
    )
    for pat in alias_patterns:
        s = re.sub(pat, '', s, count=1)

    # Normalize the authoritative Main2 export and closure. Any pre-existing
    # closure metadata is stripped first so reconstruction remains idempotent.
    s = re.sub(r'window\.RW_Items\s*=\s*RW_Items\s*;', 'window.RW_Items=RW_Items;', s, count=1)
    s = s.replace(version, '').replace(governed, '')
    owner_matches = list(re.finditer(r'window\.RW_Items=RW_Items;', s))
    if len(owner_matches) != 1:
        raise RuntimeError('P163_ITEMS_OWNER_COUNT:' + str(len(owner_matches)))
    owner = owner_matches[0]
    end = owner.end()
    s = s[:end] + '\n' + version + '\n' + governed + s[end:]

    gates = {
        'compat_absent': compat not in s,
        'authoritative_one': s.count(auth) == 1,
        'version_one': s.count(version) == 1,
        'governed_one': s.count(governed) == 1,
        'dashboard_alias_absent': not re.search(alias_patterns[0], s),
        'items_alias_absent': not re.search(alias_patterns[1], s),
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
