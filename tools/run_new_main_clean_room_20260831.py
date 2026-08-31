from pathlib import Path
import re
import json
import hashlib

CUR = Path('Current/PWA/main')
ORIG = Path('Original/PWA/main')
NEW = Path('Current/PWA/New-main')
CTO = Path('Current/CTO')
PARTS = [CUR / f'main{i}.md' for i in range(1, 12)]
ORIGINAL_PARTS = [ORIG / f'main{i}.md' for i in range(1, 12)]


def fp(text: str) -> str:
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def symbols(s: str) -> dict:
    return {
        'functions': sorted(set(re.findall(r'(?<![\w$])function\s+([A-Za-z_$][\w$]*)\s*\(', s))),
        'ids': sorted(set(re.findall(r'\bid=["\']([^"\']+)["\']', s))),
        'rpcs': sorted(set(re.findall(r'\.rpc\(\s*["\']([^"\']+)["\']', s))),
        'tables': sorted(set(re.findall(r'\.from\(\s*["\']([^"\']+)["\']', s))),
        'edge_refs': sorted(set(re.findall(r'functions/v1/([A-Za-z0-9._-]+)', s))),
    }


def repaired_fragment(path: Path) -> str:
    s = path.read_text(encoding='utf-8-sig')
    if path.name == 'main7.md':
        # Verified CI defect: one missing ')' in the settlement runsheet selector.
        pattern = re.compile(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}", re.M)
        s2, n = pattern.subn(r"\1));}", s, count=1)
        if n == 1:
            s = s2
        elif not re.search(r"safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\)\)\);}", s, re.M):
            raise RuntimeError('MAIN7_VERIFIED_SYNTAX_REPAIR_NOT_FOUND')
    return s


def assemble(chunks: list[str]) -> str:
    first = chunks[0]
    if not re.match(r'^\s*<!DOCTYPE html>', first, re.I):
        raise RuntimeError('MAIN1_IS_NOT_HTML_SHELL')
    if not re.search(r'^\s*<html\b', first, re.I | re.M):
        raise RuntimeError('MAIN1_HTML_ROOT_MISSING')

    # The current main1 fragment owns the full document shell and deliberately leaves
    # its single inline runtime <script> open. main2..main11 continue inside it.
    opening = re.search(r'<script(?![^>]*\bsrc\s*=)[^>]*>', first, re.I | re.S)
    if not opening:
        raise RuntimeError('MAIN1_INLINE_SCRIPT_OPEN_MISSING')
    prefix = first[:opening.end()]
    script_body = first[opening.end():].rstrip()

    for idx, fragment in enumerate(chunks[1:], 2):
        if re.search(r'</script>', fragment, re.I):
            raise RuntimeError(f'INVALID_FRAGMENT_SCRIPT_CLOSE_MAIN{idx}')
        if re.search(r'<(?:!doctype|html|head|body)\b', fragment, re.I):
            raise RuntimeError(f'INVALID_FRAGMENT_DOCUMENT_WRAPPER_MAIN{idx}')

    return prefix + script_body + '\n\n' + '\n\n'.join(x.rstrip() for x in chunks[1:]) + '\n</script>\n</body>\n</html>\n'


def validate(candidate: str) -> dict:
    required = [
        'window.RW_ShellContext', 'RW_ShellContext.getCompanyId()',
        'window.RW_OwnerLicense', 'RW_Views',
        'window.RW_Dashboard', 'window.RW_Items', 'window.RW_POS',
        'window.RW_Orders', 'window.RW_Runsheets', 'window.RW_Purchases',
        'window.RW_Warehouse', 'window.RW_Finance', 'window.RW_Reports',
        'window.RW_HR', 'window.RW_CRM',
        'rec-purchase', 'rec-offers'
    ]
    missing = [x for x in required if x not in candidate]
    if missing:
        raise RuntimeError('MISSING_REQUIRED_CONTRACTS:' + ','.join(missing))

    forbidden = [
        'stock_branches', 'inventory_log', 'stock_voucher_details',
        'journal_entries', 'journal_entry_lines', 'cash_box',
        'customer_ledger', 'supplier_ledger', 'driver_ledger',
        'treasury', 'chart_of_accounts'
    ]
    for table in forbidden:
        pat = r"\.from\(['\"]" + re.escape(table) + r"['\"]\)[\s\S]{0,1000}?\.(?:update|insert|upsert|delete)\s*\("
        if re.search(pat, candidate):
            raise RuntimeError('DIRECT_BUSINESS_STATE_WRITE:' + table)

    for m in re.finditer(r"\.from\(['\"]app_settings['\"]\)", candidate):
        tail = candidate[m.end():m.end()+2200]
        lim = re.search(r"\.limit\(\s*1\s*\)", tail)
        if lim and not re.search(r"\.eq\(\s*['\"]company_id['\"]\s*,", tail[:lim.start()]):
            raise RuntimeError('UNSCOPED_APP_SETTINGS_LIMIT1')

    if candidate.lower().count('</html>') != 1 or candidate.lower().count('</body>') != 1:
        raise RuntimeError('DOCUMENT_CLOSURE_INVALID')
    if len(re.findall(r'<script(?![^>]*\bsrc\s*=)[^>]*>', candidate, re.I)) != 1:
        raise RuntimeError('INLINE_SCRIPT_COUNT_INVALID')

    union = {'functions': set(), 'ids': set(), 'rpcs': set(), 'tables': set(), 'edge_refs': set()}
    parity = {}
    for idx, (op, cp) in enumerate(zip(ORIGINAL_PARTS, PARTS), 1):
        if not op.is_file() or not cp.is_file():
            raise RuntimeError(f'MISSING_PARITY_PART_MAIN{idx}')
        current = repaired_fragment(cp)
        for k, vals in symbols(current).items():
            union[k].update(vals)
        original = symbols(op.read_text(encoding='utf-8-sig'))
        parity[f'main{idx}.md'] = {k: sorted(set(original[k]) - set(symbols(current)[k])) for k in original}

    candidate_symbols = symbols(candidate)
    losses = {k: sorted(vals - set(candidate_symbols[k])) for k, vals in union.items() if vals - set(candidate_symbols[k])}
    if any(losses.values()):
        raise RuntimeError('CURRENT_SYMBOL_LOSS:' + json.dumps(losses, ensure_ascii=False, sort_keys=True))
    return parity


def main():
    chunks = [repaired_fragment(p) for p in PARTS]
    candidate = assemble(chunks)
    parity = validate(candidate)
    NEW.write_text(candidate, encoding='utf-8')
    CTO.mkdir(parents=True, exist_ok=True)
    evidence = {
        'event_type': 'NEW_MAIN_CLEAN_ROOM_RECONSTRUCTION_EXECUTED',
        'source_seed': 'Current/PWA/main/main1.md..main11.md',
        'target': 'Current/PWA/New-main',
        'main_html_modified': False,
        'composition_mode': 'verified_main1_open_inline_script_plus_main2_main11',
        'source_fragment_repairs': ['main7.md verified settlement selector syntax repair in-memory'],
        'new_main_sha256': fp(candidate),
        'new_main_bytes': len(candidate.encode('utf-8')),
        'fragment_parity': parity,
        'static_gates': 'PASS_BUILDER_VALIDATION',
        'browser_runtime': 'PENDING_CI'
    }
    (CTO / '20260831_NEW_MAIN_CLEAN_ROOM_EXECUTION.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(evidence, ensure_ascii=False))


if __name__ == '__main__':
    main()
