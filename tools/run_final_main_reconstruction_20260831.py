from pathlib import Path
import re
import subprocess
import json
import hashlib

MAIN = Path('Current/PWA/main.html')
ORIGINAL = Path('Original/PWA/main.html')
CUR = Path('Current/PWA/main')
CTO = Path('Current/CTO')
PARTS = [CUR / f'main{i}.md' for i in range(1, 12)]

from tools.master_reconstruction_postprocess import symbols, meta


def fp(text: str) -> str:
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def assemble_clean_room() -> str:
    missing = [str(p) for p in PARTS if not p.is_file() or p.stat().st_size == 0]
    if missing:
        raise SystemExit('MISSING_RECONSTRUCTION_PARTS:' + ','.join(missing))
    chunks = [p.read_text(encoding='utf-8') for p in PARTS]
    first = chunks[0]
    if not first.lstrip().startswith('<!DOCTYPE html>'):
        raise SystemExit('MAIN1_IS_NOT_HTML_SHELL')
    if '</html>' in first.lower() or '</body>' in first.lower():
        raise SystemExit('MAIN1_ALREADY_CLOSED_DOCUMENT')
    for i, c in enumerate(chunks[1:], 2):
        low = c.lower()
        if '<!doctype html>' in low or '<html' in low or '<head' in low or '<body' in low:
            raise SystemExit(f'INVALID_FRAGMENT_DOCUMENT_WRAPPER_MAIN{i}')
        if '</script>' in low:
            raise SystemExit(f'INVALID_FRAGMENT_SCRIPT_CLOSE_MAIN{i}')
    candidate = first.rstrip() + '\n\n' + '\n\n'.join(c.rstrip() for c in chunks[1:]) + '\n\n</script>\n</body>\n</html>\n'
    if candidate.count('<html') != 1 or candidate.count('</html>') != 1:
        raise SystemExit('HTML_DOCUMENT_BOUNDARY_FAIL')
    opens = len(re.findall(r'<script(?:\s[^>]*)?>', candidate, re.I))
    closes = len(re.findall(r'</script>', candidate, re.I))
    if opens != closes:
        raise SystemExit(f'SCRIPT_BOUNDARY_FAIL:open={opens}:close={closes}')
    return candidate


def validate_candidate(s: str) -> dict:
    required = [
        'window.RW_ShellContext', 'window.RW_OwnerContract',
        'RW_ShellContext.getCompanyId()', 'rec-purchase', 'rec-offers',
        'window.RW_Dashboard', 'window.RW_Items', 'window.RW_POS',
        'window.RW_Orders', 'window.RW_Runsheets', 'window.RW_Purchases',
        'window.RW_Warehouse', 'window.RW_Finance', 'window.RW_Reports',
        'window.RW_OwnerLicense', 'window.RW_Views', 'window.RW_HR', 'window.RW_CRM'
    ]
    missing = [x for x in required if x not in s]
    if missing:
        raise SystemExit('MISSING_REQUIRED_RECONSTRUCTION_CONTRACTS:' + ','.join(missing))
    if "meta.permissions || ['*']" in s:
        raise SystemExit('OWNER_WILDCARD_FALLBACK_REMAINS')
    pat = re.compile(r"\.from\(['\"]app_settings['\"]\)(?P<chain>[^;\n]{0,1600}?)\.limit\(\s*1\s*\)", re.S)
    for m in pat.finditer(s):
        if not re.search(r"\.eq\(['\"]company_id['\"]\s*,", m.group('chain')):
            raise SystemExit('UNSCOPED_APP_SETTINGS_LIMIT1')
    if re.search(r"\.from\(['\"]stock_branches['\"]\)[\s\S]{0,800}?\.(?:update|insert|upsert|delete)\(", s):
        raise SystemExit('DIRECT_STOCK_WRITER_REMAINS')
    if re.search(r"\.from\(['\"]inventory_log['\"]\)[\s\S]{0,800}?\.(?:update|insert|upsert|delete)\(", s):
        raise SystemExit('DIRECT_INVENTORY_LOG_WRITER_REMAINS')
    original = ORIGINAL.read_text(encoding='utf-8')
    osym = symbols(original)
    fsym = symbols(s)
    losses = {k: sorted(set(osym[k]) - set(fsym[k])) for k in osym}
    if any(losses.values()):
        raise SystemExit('ORIGINAL_SYMBOL_PARITY_FAIL:' + json.dumps(losses, ensure_ascii=False))
    return losses


def main() -> None:
    # IMPORTANT: this is a clean-room reconstruction. The existing main.html is NOT
    # read as an implementation seed and is never repaired or transformed.
    candidate = assemble_clean_room()
    losses = validate_candidate(candidate)

    # Write candidate only after all deterministic source/contract gates pass.
    tmp = MAIN.with_suffix('.reconstructed.tmp')
    tmp.write_text(candidate, encoding='utf-8')
    tmp.replace(MAIN)

    CTO.mkdir(parents=True, exist_ok=True)
    report = {
        'event_type': 'FINAL_MAIN_HTML_RECONSTRUCTION_EXECUTED_CLEAN_ROOM',
        'source_seed': 'Current/PWA/main/main1.md..main11.md',
        'historical_main_used_as_seed': False,
        'historical_fragment_concatenation': True,
        'executor': 'tools/run_final_main_reconstruction_20260831.py',
        'main_sha256': fp(candidate),
        'main_bytes': len(candidate.encode('utf-8')),
        'original_symbol_losses': losses,
        'parts': [meta(p) for p in PARTS],
        'browser_runtime': 'PENDING_SEPARATE_GATE',
        'production_runtime': 'PENDING_SEPARATE_GATE'
    }
    (CTO / '20260831_MAIN_HTML_RECONSTRUCTION_EXECUTION.json').write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8'
    )
    print(json.dumps(report, ensure_ascii=False))


if __name__ == '__main__':
    main()
