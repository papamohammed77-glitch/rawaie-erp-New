# RAWAEA ERP — guarded surgical reconstruction executor
#
# Design rule:
#   Current/PWA/New-main is the patient/source-of-preservation.
#   Current/PWA/main/main1..main11 are authoritative logical contracts.
#   We merge contract blocks surgically into the existing artifact,
#   never replace the HTML/CSS shell blindly.
#
# Safety rule:
#   Nothing is written until every phase 1..11 passes structural, JS,
#   ownership and protected-main checks. A failed phase aborts atomically.

from pathlib import Path
import hashlib
import json
import re
import subprocess
import difflib

ROOT = Path('.')
CUR = ROOT / 'Current/PWA/main'
TARGET = ROOT / 'Current/PWA/New-main'
LEGACY = ROOT / 'Current/PWA/main.html'
CTO = ROOT / 'Current/CTO'
PARTS = [CUR / f'main{i}.md' for i in range(1, 12)]
EVIDENCE = CTO / '20260901_NEW_MAIN_SURGICAL_RECONSTRUCTION.json'

PROTECTED_IDS = {
    'rw-login-page', 'rw-main-shell', 'rw-page-container', 'rw-header-title',
    'rw-header-subtitle', 'rw-sidebar-nav', 'rw-logout-btn',
    'rw-login-form', 'rw-username', 'rw-password', 'rw-notification-btn',
    'rw-notification-badge'
}
PROTECTED_GLOBALS = {
    'RW_STATE', 'RW_ShellContext', 'RW_Navigation', 'RW_Views',
    'RW_Auth', 'RW_OwnerLicense', 'RW_Workflow', 'RW_Notification'
}
FORBIDDEN_WRITES = [
    'stock_branches', 'inventory_log', 'stock_voucher_details',
    'journal_entries', 'journal_entry_lines', 'cash_box',
    'customer_ledger', 'supplier_ledger', 'driver_ledger'
]


def sha(text: str) -> str:
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def js_inline(html: str) -> str:
    blocks = list(re.finditer(r'<script(?P<a>[^>]*)>(?P<b>[\s\S]*?)</script>', html, re.I))
    inline = [m for m in blocks if not re.search(r'\bsrc\s*=', m.group('a') or '', re.I)]
    if len(inline) != 1:
        raise RuntimeError(f'INLINE_SCRIPT_COUNT_INVALID:{len(inline)}')
    return inline[0].group('b')


def script_bounds(html: str):
    blocks = list(re.finditer(r'<script(?P<a>[^>]*)>(?P<b>[\s\S]*?)</script>', html, re.I))
    inline = [m for m in blocks if not re.search(r'\bsrc\s*=', m.group('a') or '', re.I)]
    if len(inline) != 1:
        raise RuntimeError(f'INLINE_SCRIPT_COUNT_INVALID:{len(inline)}')
    m = inline[0]
    return m.start('b'), m.end('b')


def find_balanced_end(source: str, start: int, opening: str, closing: str, include_semicolon=False):
    depth = 0
    quote = None
    escape = False
    line_comment = False
    block_comment = False
    i = start
    while i < len(source):
        ch = source[i]
        nxt = source[i + 1] if i + 1 < len(source) else ''
        if line_comment:
            if ch == '\n':
                line_comment = False
        elif block_comment:
            if ch == '*' and nxt == '/':
                block_comment = False
                i += 1
        elif quote:
            if escape:
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == quote:
                quote = None
        else:
            if ch == '/' and nxt == '/':
                line_comment = True
                i += 1
            elif ch == '/' and nxt == '*':
                block_comment = True
                i += 1
            elif ch in "'\"`":
                quote = ch
            elif ch == opening:
                depth += 1
            elif ch == closing:
                depth -= 1
                if depth == 0:
                    end = i + 1
                    if include_semicolon:
                        while end < len(source) and source[end].isspace():
                            end += 1
                        if end < len(source) and source[end] == ';':
                            end += 1
                    return end
        i += 1
    raise RuntimeError('UNTERMINATED_JS_BLOCK')


def extract_named_function(source: str, name: str):
    m = re.search(r'(?<![\w$])(?:async\s+)?function\s+' + re.escape(name) + r'\s*\([^)]*\)\s*\{', source)
    if not m:
        return None
    brace = source.find('{', m.start(), m.end())
    return source[m.start():find_balanced_end(source, brace, '{', '}', False)]


def extract_named_var(source: str, name: str):
    # Capture a top-level-ish var/let/const statement by balanced delimiters.
    pat = r'(?m)(?:^|\n)([ \t]*)(?:var|let|const)\s+' + re.escape(name) + r'\s*='
    m = re.search(pat, source)
    if not m:
        return None
    start = m.start(0)
    if source[start:start + 1] == '\n':
        start += 1
    # Find the first statement semicolon while respecting JS delimiters.
    i = m.end()
    stack = []
    quote = None
    escape = False
    line_comment = False
    block_comment = False
    while i < len(source):
        ch = source[i]
        nxt = source[i + 1] if i + 1 < len(source) else ''
        if line_comment:
            if ch == '\n': line_comment = False
        elif block_comment:
            if ch == '*' and nxt == '/': block_comment = False; i += 1
        elif quote:
            if escape: escape = False
            elif ch == '\\': escape = True
            elif ch == quote: quote = None
        else:
            if ch == '/' and nxt == '/': line_comment = True; i += 1
            elif ch == '/' and nxt == '*': block_comment = True; i += 1
            elif ch in "'\"`": quote = ch
            elif ch in '({[': stack.append(ch)
            elif ch in ')}]':
                if not stack: raise RuntimeError(f'JS_BLOCK_UNDERFLOW:{name}')
                stack.pop()
            elif ch == ';' and not stack:
                return source[start:i+1]
        i += 1
    raise RuntimeError('JS_VAR_TERMINATOR_MISSING:' + name)


def replace_named_function(target: str, name: str, replacement: str):
    current = extract_named_function(target, name)
    if current is None:
        return target, False
    target = target.replace(current, replacement, 1)
    return target, current != replacement


def replace_named_var(target: str, name: str, replacement: str):
    current = extract_named_var(target, name)
    if current is None:
        return target, False
    target = target.replace(current, replacement, 1)
    return target, current != replacement


def insert_block(target: str, block: str, anchor_names):
    if not block:
        return target, False
    # Never insert a duplicate declaration.
    first_line = re.search(r'(?m)(?:var|let|const)\s+([A-Za-z_$][\w$]*)\s*=', block)
    if first_line and extract_named_var(target, first_line.group(1)):
        return target, False
    for anchor in anchor_names:
        pos = target.find(anchor)
        if pos != -1:
            return target[:pos] + block + '\n\n' + target[pos:], True
    return target + '\n\n' + block + '\n', True


def top_level_names(source: str):
    funcs = sorted(set(re.findall(r'(?<![\w$])(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\(', source)))
    vars_ = sorted(set(re.findall(r'(?m)^(?:var|let|const)\s+([A-Za-z_$][\w$]*)\s*=', source)))
    return funcs, vars_


def extract_required_main_blocks(source: str):
    funcs, vars_ = top_level_names(source)
    blocks = []
    for name in funcs:
        block = extract_named_function(source, name)
        if block and (name.startswith('RW_') or name in {
            'applyAuthoritativeContext', 'currentCompanyId', 'syncState',
            'setHeader', 'delegated', 'moduleCards', 'renderList',
            'renderDashboard', 'renderCustomers', 'renderItems',
            'renderInventory', 'renderFinance', 'renderReports',
            'main1Delegation', 'globalSearch'
        }):
            blocks.append(('function', name, block))
    for name in vars_:
        if name.startswith('RW_') or name in {'actions'}:
            block = extract_named_var(source, name)
            if block:
                blocks.append(('var', name, block))
    return blocks


def surgical_merge(base_html: str, canonical_html: str, phase: int):
    # Protect the physical HTML/CSS shell byte-for-byte.
    b0, b1 = script_bounds(base_html)
    c0, c1 = script_bounds(canonical_html)
    if base_html[:b0] != canonical_html[:c0] or base_html[b1:] != canonical_html[c1:]:
        raise RuntimeError(f'NON_SCRIPT_SHELL_DIFF_AT_MAIN{phase}')
    base_js = base_html[b0:b1]
    canonical_js = canonical_html[c0:c1]
    before = base_js
    applied = []
    # First replace existing contract blocks, then insert genuinely missing blocks.
    for kind, name, block in extract_required_main_blocks(canonical_js):
        if kind == 'function':
            base_js, changed = replace_named_function(base_js, name, block)
            if changed:
                applied.append(f'replace:function:{name}')
            elif extract_named_function(base_js, name) is None:
                # Put newly introduced functions before the runtime tail.
                base_js, inserted = insert_block(base_js, block, ['function globalSearch', 'var RW_Auth=', '})();'])
                if inserted: applied.append(f'insert:function:{name}')
        else:
            base_js, changed = replace_named_var(base_js, name, block)
            if changed:
                applied.append(f'replace:var:{name}')
            elif extract_named_var(base_js, name) is None:
                base_js, inserted = insert_block(base_js, block, ['var RW_Data=', 'var RW_Navigation=', '})();'])
                if inserted: applied.append(f'insert:var:{name}')
    # Carry forward candidate-only window exports not already present.
    exports = sorted(set(re.findall(r'window\.([A-Za-z_$][\w$]*)\s*=\s*\1\s*;', canonical_js)))
    for name in exports:
        token = f'window.{name} = {name};'
        if token in canonical_js and token not in base_js:
            base_js = base_js.rstrip() + '\n' + token + '\n'
            applied.append(f'insert:export:{name}')
    merged = base_html[:b0] + base_js + base_html[b1:]
    if sha(before) == sha(base_js):
        raise RuntimeError(f'NO_SURGICAL_DELTA_MAIN{phase}')
    return merged, applied, sha(before), sha(base_js)


def repair_main7(s):
    p = re.compile(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}", re.M)
    s2, n = p.subn(r"\1));}", s, count=1)
    return s2, [{'issue': 'main7 settlement-rs-select closure', 'occurrences_fixed': n, 'mode': 'in-memory'}]


def assemble_canonical(chunks):
    first = chunks[0]
    repaired7, repairs = repair_main7(chunks[6])
    frags = chunks[:6] + [repaired7] + chunks[7:]
    inline = js_inline(first)
    b0, b1 = script_bounds(first)
    prefix = first[:b0]
    suffix = first[b1:]
    if suffix.strip() != '</script>\n</body>\n</html>' and not re.fullmatch(r'\s*</body>\s*</html>\s*', suffix):
        # first file may already contain its own closure around inline script.
        pass
    body = inline.strip() + '\n\n' + '\n\n'.join(x.rstrip() for x in frags[1:])
    return prefix + body + '\n' + suffix, repairs


def repair_owner_and_license(cand):
    repairs = []
    cand, n = re.subn(
        r"var owner=!!op\.data\|\|meta\.isOwner===true\|\|meta\.isOwner==='true';",
        "var owner=meta.isOwner===true||meta.isOwner==='true';", cand, count=1
    )
    if n:
        repairs.append('OWNER_MUST_COME_FROM_AUTH_METADATA')
    main10 = (CUR / 'main10.md').read_text(encoding='utf-8-sig')
    if 'btn-save-license-only' not in cand:
        block = extract_named_var(main10, 'RW_OwnerLicense')
        if block:
            anchor = cand.find('var RW_Views=')
            if anchor == -1: anchor = cand.find('var RW_Navigation=')
            if anchor == -1: raise RuntimeError('LICENSE_INSERT_ANCHOR_MISSING')
            cand = cand[:anchor] + block + '\n' + cand[anchor:]
            repairs.append('RESTORE_CANONICAL_MAIN10_OWNER_LICENSE_MODULE')
    if "{view:'license'" not in cand:
        needle = "{view:'audit',label:'سجل التدقيق',perm:'owner'},"
        if needle not in cand: raise RuntimeError('LICENSE_MENU_ANCHOR_MISSING')
        cand = cand.replace(needle, needle + "{view:'license',label:'إدارة الترخيص',perm:'owner'},", 1)
        repairs.append('ADD_LICENSE_OWNER_NAVIGATION')
    if 'license:RW_OwnerLicense.render' not in cand:
        needle = 'audit:RW_Audit_renderTab,'
        if needle not in cand: raise RuntimeError('LICENSE_ACTION_ANCHOR_MISSING')
        cand = cand.replace(needle, needle + 'license:RW_OwnerLicense.render,', 1)
        repairs.append('ADD_LICENSE_VIEW_ACTION')
    return cand, repairs


def validate(html, baseline_html=None):
    required = [
        'rw-login-page','rw-main-shell','rw-page-container','rw-header-title',
        'rw-header-subtitle','rw-sidebar-nav','rw-logout-btn',
        'window.RW_ShellContext','window.RW_OwnerLicense','window.RW_Views',
        'window.RW_Dashboard','window.RW_Items','window.RW_POS','window.RW_Orders',
        'window.RW_Runsheets','window.RW_Purchases','window.RW_Warehouse',
        'window.RW_Finance','window.RW_Reports','window.RW_HR','window.RW_CRM',
        'btn-save-license-only', "{view:'license'", 'license:RW_OwnerLicense.render',
        'RW_Audit_renderTab', 'RW_Permissions_check', 'RW_Permissions_applyUI',
        '_clickNotif', '_renderAndSave', '_updateBadge', 'markRead', 'RW_Workflow'
    ]
    missing = [x for x in required if x not in html]
    if missing:
        raise RuntimeError('MISSING_REQUIRED_RECONSTRUCTION_CONTRACTS:' + ','.join(missing))
    if "var owner=!!op.data" in html:
        raise RuntimeError('OWNER_INFERENCE_FROM_PROFILE_REMAINS')
    if html.lower().count('</html>') != 1 or html.lower().count('</body>') != 1:
        raise RuntimeError('DOCUMENT_CLOSURE_INVALID')
    if html.count('<!doctype') != 1:
        raise RuntimeError('DOCTYPE_INVALID')
    if baseline_html is not None:
        for item in PROTECTED_IDS:
            if item in baseline_html and item not in html:
                raise RuntimeError('PROTECTED_ID_REMOVED:' + item)
        for item in PROTECTED_GLOBALS:
            if item in baseline_html and item not in html:
                raise RuntimeError('PROTECTED_GLOBAL_REMOVED:' + item)
    scripts = [js_inline(html)]
    p = Path('/tmp/rw-new-main-surgical.js')
    p.write_text(scripts[0], encoding='utf-8')
    r = subprocess.run(['node', '--check', str(p)], capture_output=True, text=True)
    if r.returncode:
        print(r.stderr)
        raise RuntimeError('JS_SYNTAX_FAIL')
    for table in FORBIDDEN_WRITES:
        if re.search(r"\.from\(['\"]" + re.escape(table) + r"['\"]\)[\s\S]{0,1000}?\.(?:update|insert|upsert|delete)\s*\(", html):
            raise RuntimeError('DIRECT_BUSINESS_STATE_WRITE:' + table)
    return True


def phase_manifest(source):
    return {
        'bytes': len(source.encode('utf-8')),
        'sha256': sha(source),
        'functions': len(top_level_names(source)[0]),
        'vars': len(top_level_names(source)[1]),
    }


def main():
    if not TARGET.is_file() or TARGET.stat().st_size == 0: raise RuntimeError('NEW_MAIN_MISSING')
    if not LEGACY.is_file() or LEGACY.stat().st_size == 0: raise RuntimeError('LEGACY_MAIN_MISSING')
    missing = [str(p) for p in PARTS if not p.is_file() or p.stat().st_size == 0]
    if missing: raise RuntimeError('MISSING_RECONSTRUCTION_PARTS:' + ','.join(missing))

    baseline = TARGET.read_text(encoding='utf-8')
    legacy_sha_before = hashlib.sha256(LEGACY.read_bytes()).hexdigest()
    validate(baseline)

    chunks = [p.read_text(encoding='utf-8-sig') for p in PARTS]
    canonical, canonical_repairs = assemble_canonical(chunks)
    canonical, contract_repairs = repair_owner_and_license(canonical)
    canonical_repairs.extend(contract_repairs)
    validate(canonical, baseline_html=baseline)

    # Build the final artifact progressively: MAIN1 -> MAIN11.
    current = baseline
    phases = []
    for idx, source_html in enumerate(chunks, start=1):
        source_for_phase = source_html
        if idx == 7:
            source_for_phase, _ = repair_main7(source_for_phase)
        # Main1 is the actual HTML shell source; other modules are logical JS contracts.
        if idx == 1:
            # Use canonical assembled MAIN1 shell only if the existing target shell matches it.
            if baseline[:script_bounds(baseline)[0]] != canonical[:script_bounds(canonical)[0]]:
                raise RuntimeError('MAIN1_SHELL_MISMATCH')
        phase_candidate, applied, before_sha, after_sha = surgical_merge(current, canonical, idx)
        validate(phase_candidate, baseline_html=current)
        current = phase_candidate
        phases.append({
            'phase': idx,
            'source': str(PARTS[idx-1]),
            'source_manifest': phase_manifest(source_for_phase),
            'applied_operations': applied,
            'before_script_sha256': before_sha,
            'after_script_sha256': after_sha,
            'artifact_sha256': sha(current),
            'artifact_bytes': len(current.encode('utf-8')),
        })

    validate(current, baseline_html=baseline)
    legacy_sha_after = hashlib.sha256(LEGACY.read_bytes()).hexdigest()
    if legacy_sha_before != legacy_sha_after:
        raise RuntimeError('LEGACY_MAIN_HTML_CHANGED')
    if sha(current) == sha(baseline):
        raise RuntimeError('NO_TARGET_CHANGE_AFTER_MAIN1_MAIN11')

    # Final semantic safety: candidate must retain every baseline DOM id and protected global.
    removed_ids = sorted(set(re.findall(r'\bid=["\']([^"\']+)["\']', baseline)) - set(re.findall(r'\bid=["\']([^"\']+)["\']', current)))
    if removed_ids:
        raise RuntimeError('TARGET_DOM_IDS_REMOVED:' + ','.join(removed_ids[:40]))

    CTO.mkdir(parents=True, exist_ok=True)
    EVIDENCE.write_text(json.dumps({
        'event_type': 'MASTER_SURGICAL_RECONSTRUCTION_MAIN1_TO_MAIN11',
        'target': str(TARGET),
        'mode': 'SURGICAL_BLOCK_MERGE_ATOMIC',
        'backup_reference': 'git:HEAD-before-execution',
        'legacy_main_html_modified': False,
        'legacy_main_sha256': legacy_sha_after,
        'baseline_target_sha256': sha(baseline),
        'candidate_target_sha256': sha(current),
        'canonical_source_sha256': sha(canonical),
        'canonical_repairs': canonical_repairs,
        'phases': phases,
        'all_phases_validated_before_write': True,
        'write_commit_expected': '[new-main-clean-room-persist] persist single Golden New-main artifact',
    }, ensure_ascii=False, indent=2), encoding='utf-8')

    TARGET.write_text(current, encoding='utf-8')
    print(json.dumps({
        'status': 'READY_TO_PERSIST',
        'target': str(TARGET),
        'baseline_sha256': sha(baseline),
        'candidate_sha256': sha(current),
        'phases': len(phases),
        'repairs': canonical_repairs,
        'legacy_main_protected': legacy_sha_before == legacy_sha_after,
    }, ensure_ascii=False))


if __name__ == '__main__':
    main()
