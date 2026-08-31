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

# Execution marker: clean-room build is intentionally isolated from main.html.

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
        pattern = re.compile(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}", re.M)
        s2, n = pattern.subn(r"\1));}", s, count=1)
        if n == 1:
            return s2
        corrected = re.search(r"safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\)\)\);}", s, re.M)
        if corrected:
            return s
        raise RuntimeError('VERIFIED_MAIN7_SYNTAX_REPAIR_NOT_FOUND')
    return s


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

    for idx, c in enumerate(chunks[1:], 2):
        if re.search(r'^\s*<!doctype\b', c, re.I | re.M):
            raise RuntimeError(f'INVALID_FRAGMENT_DOCTYPE_MAIN{idx}')
        if re.search(r'^\s*</?(?:html|head|body)\b[^>]*>\s*$', c, re.I | re.M):
            raise RuntimeError(f'INVALID_FRAGMENT_DOCUMENT_WRAPPER_MAIN{idx}')
        if re.search(r'</script>', c, re.I):
            raise RuntimeError(f'INVALID_FRAGMENT_SCRIPT_CLOSE_MAIN{idx}')

    candidate = first.rstrip() + '\n\n' + '\n\n'.join(c.rstrip() for c in chunks[1:]) + '\n\n</script>\n</body>\n</html>\n'

    required = [
        'window.RW_ShellContext',
        'RW_ShellContext.getCompanyId()',
        'window.RW_OwnerLicense',
        'RW_Views',
        'rec-purchase',
        'rec-offers',
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
    if 'meta.permissions || [\'*\']' in candidate:
        raise RuntimeError('OWNER_WILDCARD_FALLBACK_REMAINS')
    if re.search(r"\.from\(['\"]stock_branches['\"]\)[\s\S]{0,1000}?\.(?:update|insert|upsert|delete)\(", candidate):
        raise RuntimeError('DIRECT_STOCK_WRITER_REMAINS')
    if re.search(r"\.from\(['\"]inventory_log['\"]\)[\s\S]{0,1000}?\.(?:update|insert|upsert|delete)\(", candidate):
        raise RuntimeError('DIRECT_INVENTORY_LOG_WRITER_REMAINS')
    if re.search(r"\.from\(['\"]app_settings['\"]\)[\s\S]{0,1600}?\.limit\(\s*1\s*\)", candidate):
        raise RuntimeError('UNSCOPED_APP_SETTINGS_LIMIT1_IN_CANDIDATE')

    parity = {}
    for idx, (op, cp) in enumerate(zip(ORIGINAL_PARTS, PARTS), 1):
        if not op.is_file() or op.stat().st_size == 0:
            raise RuntimeError(f'MISSING_ORIGINAL_PARITY_PART_MAIN{idx}')
        osym = symbols(op.read_text(encoding='utf-8-sig'))
        csym = symbols(repaired_source(cp))
        parity[f'main{idx}.md'] = {k: sorted(set(osym[k]) - set(csym[k])) for k in osym}

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
        'new_main_sha256': sha256(candidate.encode('utf-8')),
        'new_main_bytes': len(candidate.encode('utf-8')),
        'source_fragment_repairs': ['main7.md safeHTML settlement select closing parenthesis'] if 'settlement-rs-select' in candidate else [],
        'fragment_symbol_parity': parity,
        'static_gates': 'PENDING_CI_BROWSER_GATE'
    }
    EVIDENCE.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(payload, ensure_ascii=False))


if __name__ == '__main__':
    main()
