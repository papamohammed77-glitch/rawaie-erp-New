from pathlib import Path
import re
import json
import hashlib

CUR = Path('Current/PWA/main')
ORIG = Path('Original/PWA/main')
TARGET = Path('Current/PWA/main.reconstruction.html')
CTO = Path('Current/CTO')
PARTS = [CUR / f'main{i}.md' for i in range(1, 12)]
ORIGINAL_PARTS = [ORIG / f'main{i}.md' for i in range(1, 12)]
EVIDENCE = CTO / '20260831_NEW_MAIN_CLEAN_ROOM_EXECUTION.json'


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def symbols(s: str) -> dict:
    return {
        'functions': sorted(set(re.findall(r'(?<![\w$])function\s+([A-Za-z_$][\w$]*)\s*\(', s))),
        'ids': sorted(set(re.findall(r'\bid=["\']([^"\']+)["\']', s))),
        'rpcs': sorted(set(re.findall(r'\.rpc\(\s*["\']([^"\']+)["\']', s))),
        'tables': sorted(set(re.findall(r'\.from\(\s*["\']([^"\']+)["\']', s))),
        'edge_refs': sorted(set(re.findall(r'functions/v1/([A-Za-z0-9._-]+)', s))),
    }


def repair_main7_in_memory(s: str) -> tuple[str, list]:
    pattern = re.compile(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}", re.M)
    s2, n = pattern.subn(r"\1));}", s, count=1)
    if n == 1:
        return s2, [{'issue': 'main7 settlement-rs-select missing closing parenthesis', 'occurrences_fixed': 1, 'mode': 'in-memory'}]
    if re.search(r"safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\)\)\);}", s, re.M):
        return s, []
    return s, [{'issue': 'main7 settlement-rs-select verified correction not found in expected forms', 'occurrences_fixed': 0, 'mode': 'none'}]


def assemble(chunks: list[str]) -> tuple[str, list]:
    first, repairs = repair_main7_in_memory(chunks[6])
    chunks = chunks[:6] + [first] + chunks[7:]
    if not re.match(r'^\s*<!DOCTYPE html>', chunks[0], re.I):
        raise RuntimeError('MAIN1_IS_NOT_HTML_SHELL')
    if not re.search(r'^\s*<html\b', chunks[0], re.I | re.M):
        raise RuntimeError('MAIN1_HTML_ROOT_MISSING')
    opening = re.search(r'<script(?![^>]*\bsrc\s*=)[^>]*>', chunks[0], re.I | re.S)
    if not opening:
        raise RuntimeError('MAIN1_INLINE_SCRIPT_OPEN_MISSING')
    prefix = chunks[0][:opening.end()]
    body = chunks[0][opening.end():].rstrip()
    for idx, fragment in enumerate(chunks[1:], 2):
        if re.search(r'</script>', fragment, re.I):
            raise RuntimeError(f'INVALID_FRAGMENT_SCRIPT_CLOSE_MAIN{idx}')
        if re.search(r'<(?:!doctype|html|head|body)\b', fragment, re.I):
            raise RuntimeError(f'INVALID_FRAGMENT_DOCUMENT_WRAPPER_MAIN{idx}')
    candidate = prefix + body + '\n\n' + '\n\n'.join(x.rstrip() for x in chunks[1:] if x.strip()) + '\n</script>\n</body>\n</html>\n'
    return candidate, repairs


def validate(candidate: str) -> dict:
    required = [
        'window.RW_ShellContext', 'RW_ShellContext.getCompanyId()', 'window.RW_OwnerLicense',
        'RW_Views', 'rec-purchase', 'rec-offers', 'window.RW_Dashboard', 'window.RW_Items',
        'window.RW_POS', 'window.RW_Orders', 'window.RW_Runsheets', 'window.RW_Purchases',
        'window.RW_Warehouse', 'window.RW_Finance', 'window.RW_Reports', 'window.RW_HR', 'window.RW_CRM'
    ]
    missing = [x for x in required if x not in candidate]
    if missing:
        raise RuntimeError('MISSING_REQUIRED_RECONSTRUCTION_CONTRACTS:' + ','.join(missing))
    forbidden = [
        'stock_branches', 'inventory_log', 'stock_voucher_details', 'journal_entries',
        'journal_entry_lines', 'cash_box', 'customer_ledger', 'supplier_ledger', 'driver_ledger',
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
    current_union = {'functions': set(), 'ids': set(), 'rpcs': set(), 'tables': set(), 'edge_refs': set()}
    parity = {}
    for idx, (op, cp) in enumerate(zip(ORIGINAL_PARTS, PARTS), 1):
        if not op.is_file() or not cp.is_file():
            raise RuntimeError(f'MISSING_PARITY_PART_MAIN{idx}')
        current = cp.read_text(encoding='utf-8-sig')
        if idx == 7:
            current, _ = repair_main7_in_memory(current)
        cs = symbols(current)
        for k in current_union: current_union[k].update(cs[k])
        os = symbols(op.read_text(encoding='utf-8-sig'))
        parity[f'main{idx}.md'] = {k: sorted(set(os[k]) - set(cs[k])) for k in os}
    cand_sym = symbols(candidate)
    loss = {k: sorted(v - set(cand_sym[k])) for k, v in current_union.items() if v - set(cand_sym[k])}
    if any(loss.values()):
        raise RuntimeError('CURRENT_SYMBOL_LOSS:' + json.dumps(loss, ensure_ascii=False))
    return parity


def main():
    chunks = [p.read_text(encoding='utf-8-sig') for p in PARTS]
    candidate, repairs = assemble(chunks)
    parity = validate(candidate)
    TARGET.write_text(candidate, encoding='utf-8')
    CTO.mkdir(parents=True, exist_ok=True)
    evidence = {
        'event_type': 'MASTER_RECONSTRUCTION_GOLD_CANDIDATE_BUILT',
        'source_seed': 'Current/PWA/main/main1.md..main11.md',
        'historical_main_used_as_seed': False,
        'target': str(TARGET),
        'legacy_main_html_modified': False,
        'main_html_replacement': 'NOT_EXECUTED',
        'composition_mode': 'main1_open_inline_script_plus_main2_main11_single_script',
        'main7_repairs_in_memory': repairs,
        'artifact_sha256': sha256(candidate.encode('utf-8')),
        'artifact_bytes': len(candidate.encode('utf-8')),
        'fragment_parity': parity,
        'builder_gate': 'PASS'
    }
    EVIDENCE.write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(evidence, ensure_ascii=False))


if __name__ == '__main__':
    main()
