from pathlib import Path
import hashlib
import re
import subprocess
import tempfile

TARGET = Path('Current/PWA/New-main')
LEGACY = Path('Current/PWA/main.html')
CURRENT_MAIN1 = Path('Current/PWA/main/main1.md')
ORIGINAL_MAIN1 = Path('Original/PWA/main/main1.md')

REQUIRED = [
    'rw-login-page','rw-main-shell','rw-page-container','rw-header-title','rw-header-subtitle',
    'rw-sidebar-nav','rw-logout-btn','window.RW_ShellContext','window.RW_OwnerLicense','window.RW_Views',
    'window.RW_Dashboard','window.RW_Items','window.RW_POS','window.RW_Orders','window.RW_Runsheets',
    'window.RW_Purchases','window.RW_Warehouse','window.RW_Finance','window.RW_Reports','window.RW_HR','window.RW_CRM',
    '_clickNotif','_renderAndSave','_updateBadge','markRead','bulk-stock-adjustment'
]


def sha_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inline_scripts(html: str):
    return [m for m in re.finditer(r'<script(?P<a>[^>]*)>(?P<b>[\s\S]*?)</script>', html, re.I)
            if not re.search(r'\bsrc\s*=\s*', m.group('a') or '', re.I)]


def validate_target(html: str):
    missing = [x for x in REQUIRED if x not in html]
    if missing:
        raise RuntimeError('TARGET_CONTRACT_MISSING:' + ','.join(missing))

    scripts = inline_scripts(html)
    if len(scripts) != 1:
        raise RuntimeError('INLINE_SCRIPT_COUNT_INVALID:' + str(len(scripts)))

    # Count document-closing tags only in markup, not inside JavaScript string literals.
    markup = re.sub(r'<script(?P<a>[^>]*)>[\s\S]*?</script>', '', html, flags=re.I)
    if markup.lower().count('</html>') != 1 or markup.lower().count('</body>') != 1:
        raise RuntimeError('DOCUMENT_CLOSURE_INVALID')

    js = Path(tempfile.gettempdir()) / 'rawaea_new_main.js'
    js.write_text(scripts[0].group('b'), encoding='utf-8')
    r = subprocess.run(['node', '--check', str(js)], capture_output=True, text=True)
    if r.returncode:
        print(r.stderr)
        raise RuntimeError('TARGET_JS_SYNTAX_FAIL')

    # Main PWA must never mutate physical stock directly.
    for op in ('insert','update','upsert','delete'):
        if re.search(r"supabase\.from\(['\"]stock_branches['\"]\)\s*\." + op + r"\s*\(", html, re.I):
            raise RuntimeError('NEW_MAIN_DIRECT_STOCK_WRITER_DETECTED:' + op)


def patch_bulk_stock_item_identity(html: str) -> tuple[str, bool]:
    changed = False
    pattern1 = re.compile(r"if\s*\(\s*mappedItem\s*\)\s*_uploadFileData\[f\]\.item_code\s*=\s*mappedItem\.item_code\s*;", re.S)
    replacement1 = "if(mappedItem){_uploadFileData[f].item_code=mappedItem.item_code;_uploadFileData[f].item_id=mappedItem.id;}"
    html, n1 = pattern1.subn(replacement1, html, count=1)
    changed |= n1 > 0
    if n1 == 0 and '_uploadFileData[f].item_id=mappedItem.id' not in html:
        raise RuntimeError('UPLOAD_ID_MAPPING_GAP_UNRECOGNIZED')

    pattern2 = re.compile(r"items\.push\(\{\s*item_code\s*:\s*_uploadFileData\[u\]\.item_code\|\|_uploadFileData\[u\]\.barcode\s*,\s*qty\s*:\s*_uploadFileData\[u\]\.qty\s*\}\s*\);", re.S)
    replacement2 = "items.push({item_id:_uploadFileData[u].item_id||null,item_code:_uploadFileData[u].item_code||_uploadFileData[u].barcode,qty:_uploadFileData[u].qty});"
    html, n2 = pattern2.subn(replacement2, html, count=1)
    changed |= n2 > 0
    if n2 == 0 and 'items.push({item_id:_uploadFileData[u].item_id||null' not in html:
        raise RuntimeError('UPLOAD_ID_PAYLOAD_GAP_UNRECOGNIZED')
    return html, changed


def compare_main1_sources(target: str):
    current = CURRENT_MAIN1.read_text(encoding='utf-8')
    original = ORIGINAL_MAIN1.read_text(encoding='utf-8')
    for name, source in [
        ('RW_ShellContext', target), ('RW_Auth', current), ('RW_Notification', current),
        ('RW_Workflow', current), ('RW_Audit_log', current), ('RW_Permissions_check', current),
        ('RW_Data', current), ('RW_Navigation', current)
    ]:
        if name not in source:
            raise RuntimeError('SOURCE_CONTRACT_MISSING:' + name)
    for name in ('RW_Auth','RW_Notification','RW_Workflow','RW_Audit_log','RW_Permissions_check'):
        if name not in original or name not in current or name not in target:
            raise RuntimeError('MAIN1_PARITY_CONTRACT_MISSING:' + name)


def run():
    if not TARGET.is_file() or TARGET.stat().st_size == 0:
        raise RuntimeError('NEW_MAIN_MISSING')
    if not LEGACY.is_file() or LEGACY.stat().st_size == 0:
        raise RuntimeError('LEGACY_MAIN_MISSING')
    if not CURRENT_MAIN1.is_file() or not ORIGINAL_MAIN1.is_file():
        raise RuntimeError('MAIN1_SOURCE_MISSING')

    baseline = TARGET.read_text(encoding='utf-8')
    legacy_before = sha_file(LEGACY)
    compare_main1_sources(baseline)
    candidate, changed = patch_bulk_stock_item_identity(baseline)
    validate_target(candidate)
    if sha_file(LEGACY) != legacy_before:
        raise RuntimeError('LEGACY_MAIN_HTML_CHANGED')

    if changed:
        TARGET.write_text(candidate, encoding='utf-8')
    print({
        'status': 'SURGICAL_REPAIR_READY',
        'changed': changed,
        'target_sha256': sha_file(TARGET),
        'legacy_sha256': legacy_before,
        'browser_e2e': 'PAUSED_BY_DIRECTIVE',
        'mode': 'NO_RECONSTRUCTION_NO_OVERLAY'
    })


if __name__ == '__main__':
    run()
