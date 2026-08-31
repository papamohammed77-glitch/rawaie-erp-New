from pathlib import Path
import hashlib
import json
import re

CUR = Path('Current/PWA/main')
ORIG = Path('Original/PWA/main')
NEW = Path('Current/PWA/New-main')
EVIDENCE = Path('Current/CTO/20260831_NEW_MAIN_CLEAN_ROOM_EXECUTION.json')
PARTS = [CUR / f'main{i}.md' for i in range(1, 12)]
ORIGINAL_PARTS = [ORIG / f'main{i}.md' for i in range(1, 12)]

# 2026-08-31 continuation: executor remains the sole composition authority for New-main.
# Do not edit Current/PWA/main.html; only Current/PWA/New-main may be produced here.


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


def repaired_source(path: Path) -> str:
    s = path.read_text(encoding='utf-8-sig')
    if path.name == 'main7.md':
        broken = ".join(''));}\n  async function _onSettlementRsChange()"
        fixed = ".join('')));\n  async function _onSettlementRsChange()"
        if broken in s:
            return s.replace(broken, fixed, 1)
    return s


def compose_document(first: str, fragments: list[str]) -> str:
    """Keep main1's real HTML shell, but move its inline runtime script body to one final script."""
    m = list(re.finditer(r'<script(?![^>]*\bsrc\s*=)[^>]*>(.*?)</script>', first, re.I | re.S))
    if not m:
        raise RuntimeError('MAIN1_INLINE_SCRIPT_MISSING')
    if len(m) != 1:
        raise RuntimeError(f'MAIN1_EXPECTS_ONE_INLINE_SCRIPT_FOUND_{len(m)}')
    script_match = m[0]
    prefix = first[:script_match.start()]
    suffix = first[script_match.end():]
    if not re.fullmatch(r'\s*</body>\s*</html>\s*', suffix, re.I | re.S):
        raise RuntimeError('MAIN1_SHELL_SUFFIX_NOT_STANDARD')
    script_body = script_match.group(1).strip()
    for idx, fragment in enumerate(fragments, 2):
        if re.search(r'</script>', fragment, re.I):
            raise RuntimeError(f'INVALID_FRAGMENT_SCRIPT_CLOSE_MAIN{idx}')
        if re.search(r'^\s*</?(?:html|head|body)\b[^>]*>\s*$', fragment, re.I | re.M):
            raise RuntimeError(f'INVALID_FRAGMENT_DOCUMENT_WRAPPER_MAIN{idx}')
        if re.search(r'^\s*<!doctype\b', fragment, re.I | re.M):
            raise RuntimeError(f'INVALID_FRAGMENT_DOCTYPE_MAIN{idx}')
    combined = '\n\n'.join([script_body] + [f.rstrip() for f in fragments if f.strip()])
    return prefix + '<script>\n' + combined + '\n</script>\n</body>\n</html>\n'


def build() -> tuple[str, dict]:
    missing = [str(p) for p in PARTS if not p.is_file() or p.stat().st_size == 0]
    if missing:
        raise RuntimeError('MISSING_RECONSTRUCTION_PARTS:' + ','.join(missing))

    chunks = [repaired_source(p) for p in PARTS]
    first = chunks[0]
    if not re.match(r'^\s*<!DOCTYPE html>', first, re.I):
        raise RuntimeError('MAIN1_IS_NOT_HTML_SHELL')
    if not re.search(r'^\s*<html\b', first, re.I | re.M):
        raise RuntimeError('MAIN1_HTML_ROOT_MISSING')

    candidate = compose_document(first, chunks[1:])

    required = [
        'window.RW_ShellContext',
        'RW_ShellContext.getCompanyId()',
        'window.RW_OwnerLicense',
        'RW_Views',
        'window.RW_Dashboard',
        'window.RW_Items',
        'window.RW_POS',
        'window.RW_Orders',
        'window.RW_Runsheets',
        'window.RW_Purchases',
        'window.RW_Warehouse',
        'window.RW_Finance',
        'window.RW_Reports',
        'window.RW_HR',
        'window.RW_CRM',
    ]
    missing_required = [x for x in required if x not in candidate]
    if missing_required:
        raise RuntimeError('MISSING_REQUIRED_CONTRACTS:' + ','.join(missing_required))

    if re.search(r"meta\.permissions\s*\|\|\s*\[\s*['\"]\*['\"]\s*\]", candidate):
        raise RuntimeError('OWNER_WILDCARD_FALLBACK_REMAINS')

    forbidden_transaction_writes = [
        'stock_branches', 'inventory_log', 'stock_voucher_details',
        'journal_entries', 'journal_entry_lines', 'cash_box',
        'customer_ledger', 'supplier_ledger', 'driver_ledger'
    ]
    for table in forbidden_transaction_writes:
        pat = r"\.from\(['\"]" + re.escape(table) + r"['\"]\)[^;\n]{0,700}?\.(?:update|insert|upsert|delete)\s*\("
        if re.search(pat, candidate):
            raise RuntimeError('DIRECT_TRANSACTION_WRITE:' + table)

    for m in re.finditer(r"\.from\(['\"]app_settings['\"]\)", candidate):
        tail = candidate[m.end():m.end()+2200]
        lim = re.search(r"\.limit\(\s*1\s*\)", tail)
        if lim:
            scoped = re.search(r"\.eq\(\s*['\"]company_id['\"]\s*,", tail[:lim.start()])
            if not scoped:
                raise RuntimeError('UNSCOPED_APP_SETTINGS_LIMIT1_IN_CANDIDATE')

    parity = {}
    current_union = {'functions': set(), 'ids': set(), 'rpcs': set(), 'tables': set(), 'edge_refs': set()}
    for idx, (op, cp) in enumerate(zip(ORIGINAL_PARTS, PARTS), 1):
        if not op.is_file() or op.stat().st_size == 0:
            raise RuntimeError(f'MISSING_ORIGINAL_PARITY_PART_MAIN{idx}')
        current_symbols = symbols(repaired_source(cp))
        for k in current_union:
            current_union[k].update(current_symbols[k])
        osym = symbols(op.read_text(encoding='utf-8-sig'))
        parity[f'main{idx}.md'] = {k: sorted(set(osym[k]) - set(current_symbols[k])) for k in osym}

    candidate_symbols = symbols(candidate)
    current_missing = {k: sorted(v - set(candidate_symbols[k])) for k, v in current_union.items() if v - set(candidate_symbols[k])}
    if any(current_missing.values()):
        raise RuntimeError('CURRENT_FRAGMENT_SYMBOL_LOSS:' + json.dumps(current_missing, ensure_ascii=False, sort_keys=True))

    return candidate, parity


def main() -> None:
    candidate, parity = build()
    NEW.write_text(candidate, encoding='utf-8')
    EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        'event_type': 'NEW_MAIN_CLEAN_ROOM_RECONSTRUCTION_EXECUTED',
        'source_seed': 'Current/PWA/main/main1.md..main11.md',
        'historical_main_used_as_seed': False,
        'target': 'Current/PWA/New-main',
        'legacy_target_modified': False,
        'main_html_modified': False,
        'composition_mode': 'main1_document_shell_plus_single_combined_inline_script',
        'new_main_sha256': sha256(candidate.encode('utf-8')),
        'new_main_bytes': len(candidate.encode('utf-8')),
        'source_fragment_repairs': ['main7.md settlement-rs-select closing parenthesis repaired during composition'],
        'fragment_symbol_parity': parity,
        'static_gates': 'PENDING_CI_BROWSER_GATE'
    }
    EVIDENCE.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(payload, ensure_ascii=False))


if __name__ == '__main__':
    main()
