from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path('.')
MAIN = ROOT / 'Current/PWA/main.html'
ORIGINAL_MAIN = ROOT / 'Original/PWA/main.html'
CURRENT_FRAG_DIR = ROOT / 'Current/PWA/main'
ORIGINAL_FRAG_DIR = ROOT / 'Original/PWA/main'
CTO = ROOT / 'Current/CTO'

PARTS = [f'main{i}.md' for i in range(1, 12)]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def file_meta(path: Path) -> dict:
    b = path.read_bytes()
    return {'path': str(path), 'bytes': len(b), 'sha256': sha256(b), 'lines': b.count(b'\n') + 1}


def must(path: Path) -> bytes:
    if not path.exists():
        raise SystemExit(f'MISSING_REQUIRED_SOURCE: {path}')
    return path.read_bytes()


def add_company_scope_to_chained_selects(s: str, table: str) -> tuple[str, int]:
    # Only alter statements that have no company_id filter in their own chain.
    pat = re.compile(
        rf"\.from\(['\"]{re.escape(table)}['\"]\)\.select\((?P<select>.*?)\)(?P<chain>(?:\\s*\\.[A-Za-z_$][\\w$]*\\([^;]*?\\)){{0,8}})",
        re.S,
    )
    changed = 0
    def repl(m: re.Match) -> str:
        whole = m.group(0)
        if re.search(r"\.eq\(\s*['\"]company_id['\"]", whole):
            return whole
        nonlocal changed
        changed += 1
        return f".from('{table}').select({m.group('select')}).eq('company_id', RW_ShellContext.getCompanyId()){m.group('chain')}"
    return pat.sub(repl, s), changed


def add_company_scope_to_app_settings(s: str) -> tuple[str, int]:
    pat = re.compile(
        r"\.from\(['\"]app_settings['\"]\)\.select\((?P<select>.*?)\)(?P<chain>(?:\\s*\.[A-Za-z_$][\\w$]*\\([^;]*?\\)){{0,8}})",
        re.S,
    )
    changed = 0
    def repl(m: re.Match) -> str:
        whole = m.group(0)
        if re.search(r"\.eq\(\s*['\"]company_id['\"]", whole):
            return whole
        if '.limit(1)' not in whole and '.single()' not in whole and '.maybeSingle()' not in whole:
            return whole
        nonlocal changed
        changed += 1
        return f".from('app_settings').select({m.group('select')}).eq('company_id', RW_ShellContext.getCompanyId()){m.group('chain')}"
    return pat.sub(repl, s), changed


def replace_rec_recommendations(s: str) -> tuple[str, bool]:
    marker = '// توصيات ذكية – مع فحص دفاعي'
    start = s.find(marker)
    if start < 0:
        return s, False
    safe = s.find("        safeHTML(container, html);", start)
    if safe < 0:
        return s, False
    block_end = safe
    replacement = r'''// توصيات شراء — مستقلة عن توصيات العروض
        if (types.indexOf('rec-purchase') !== -1) {
            var purchaseRecs = [];
            for (var j = 0; j < items.length; j++) {
                if (!items[j] || !items[j].id) continue;
                var available = Number(stockMap[items[j].id] || 0);
                var reorder = Number(items[j].reorder_point || 5);
                if (available <= reorder) {
                    purchaseRecs.push({
                        type: 'شراء',
                        item: items[j].name || items[j].item_code,
                        reason: 'المخزون منخفض (' + available + ')'
                    });
                    if (purchaseRecs.length >= 3) break;
                }
            }
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><h3 class="font-black text-lg mb-3"><i class="fa-solid fa-lightbulb ml-2 text-amber-500"></i> توصيات الشراء</h3>';
            if (purchaseRecs.length > 0) {
                html += '<div class="space-y-3">';
                for (var pr = 0; pr < purchaseRecs.length; pr++) {
                    html += '<div class="border-r-4 border-indigo-200 bg-indigo-50 p-4 rounded-lg"><div class="flex items-center gap-2 mb-1"><i class="fa-solid fa-cart-shopping"></i><span class="font-bold">' + _esc(purchaseRecs[pr].item) + '</span></div><p class="text-sm text-gray-600">' + purchaseRecs[pr].reason + '</p></div>';
                }
                html += '</div>';
            } else {
                html += '<div class="text-center py-4 text-gray-500">لا توجد توصيات شراء حالياً</div>';
            }
            html += '</div>';
        }

        // توصيات العروض — العقد التاريخي المستقل: مخزون راكد بلا حركة بيع
        if (types.indexOf('rec-offers') !== -1) {
            var offerSoldCodes = {};
            for (var od = 0; od < details.length; od++) {
                if (details[od] && details[od].item_code) offerSoldCodes[details[od].item_code] = true;
            }
            var offerCandidates = [];
            for (var oi = 0; oi < items.length; oi++) {
                var oiItem = items[oi];
                if (!oiItem || !oiItem.id || !oiItem.item_code) continue;
                var offerQty = Number(stockMap[oiItem.id] || 0);
                if (offerQty > 0 && !offerSoldCodes[oiItem.item_code]) {
                    var offerUnitValue = Number(oiItem.cost_price || oiItem.sales_price || 0);
                    offerCandidates.push({
                        item: oiItem.name || oiItem.item_code,
                        code: oiItem.item_code,
                        qty: offerQty,
                        value: offerQty * offerUnitValue
                    });
                }
            }
            offerCandidates.sort(function(a,b){ return b.value - a.value; });
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><h3 class="font-black text-lg mb-3"><i class="fa-solid fa-tags ml-2 text-amber-600"></i> توصيات العروض</h3>';
            if (offerCandidates.length > 0) {
                html += '<div class="space-y-3">';
                for (var orc = 0; orc < Math.min(offerCandidates.length, 5); orc++) {
                    var offer = offerCandidates[orc];
                    html += '<div class="border-r-4 border-amber-200 bg-amber-50 p-4 rounded-lg"><div class="flex items-center gap-2 mb-1"><i class="fa-solid fa-tag"></i><span class="font-bold">' + _esc(offer.item) + '</span></div><p class="text-sm text-gray-600">مخزون راكد: ' + offer.qty + ' — قيمة مخزون تقريبية: ' + _fmtNum(offer.value) + ' EGP</p></div>';
                }
                html += '</div>';
            } else {
                html += '<div class="text-center py-4 text-green-600">لا توجد أصناف مناسبة لعروض ترويجية حالياً</div>';
            }
            html += '</div>';
        }

        // keep the original container boundary unchanged
'''
    return s[:start] + replacement + s[safe:], True


def inject_shell_contract(s: str) -> tuple[str, bool]:
    if 'window.RW_ShellContext' in s:
        return s, False
    anchor = 'window.RW_STATE = RW_STATE;'
    if anchor not in s:
        raise SystemExit('RECON_ABORT: RW_STATE anchor missing')
    block = r'''
// ============================================================
// RAWAEA — Canonical Shell/Tenant Contract (Reconstructed 2026-08-30)
// Tenant authority: authenticated Supabase user -> users.auth_id -> users.company_id.
// This helper is intentionally single-owner and is not a second tenant architecture.
// ============================================================
var RW_ShellContext = (function () {
    var companyId = null;
    var appUserId = null;
    var authUserId = null;
    var resolving = null;

    function resolve() {
        if (companyId) return Promise.resolve(companyId);
        if (resolving) return resolving;
        resolving = supabase.auth.getUser().then(function (authRes) {
            if (authRes.error || !authRes.data || !authRes.data.user) throw new Error('AUTH_USER_UNAVAILABLE');
            var authUser = authRes.data.user;
            authUserId = authUser.id;
            return supabase.from('users')
                .select('id,company_id,name,role,status,isOwner,permissions,auth_id')
                .eq('auth_id', authUser.id)
                .eq('status', 'Active')
                .maybeSingle();
        }).then(function (r) {
            if (r.error || !r.data || !r.data.company_id) throw new Error('TENANT_CONTEXT_UNAVAILABLE');
            companyId = r.data.company_id;
            appUserId = r.data.id || null;
            RW_STATE.app.companyId = companyId;
            RW_STATE.app.userId = appUserId;
            if (!RW_STATE.app.currentUser) RW_STATE.app.currentUser = {};
            RW_STATE.app.currentUser.id = appUserId;
            RW_STATE.app.currentUser.auth_id = authUserId;
            RW_STATE.app.currentUser.company_id = companyId;
            if (r.data.name) RW_STATE.app.currentUser.name = r.data.name;
            if (r.data.role) RW_STATE.app.currentUser.role = r.data.role;
            if (r.data.isOwner === true) RW_STATE.app.currentUser.isOwner = true;
            if (Array.isArray(r.data.permissions)) RW_STATE.permissions = r.data.permissions.slice();
            return companyId;
        }).finally(function () { resolving = null; });
        return resolving;
    }

    function getCompanyId() {
        if (!companyId && RW_STATE.app && RW_STATE.app.companyId) companyId = RW_STATE.app.companyId;
        if (!companyId) throw new Error('TENANT_CONTEXT_UNAVAILABLE');
        return companyId;
    }
    function getUserId() {
        if (appUserId) return appUserId;
        if (RW_STATE.app && RW_STATE.app.userId) return RW_STATE.app.userId;
        return null;
    }
    return { resolve: resolve, getCompanyId: getCompanyId, getUserId: getUserId, hasCompany: function () { return !!companyId; } };
})();
window.RW_ShellContext = RW_ShellContext;

var RW_OwnerContract = (function () {
    function isOwner() {
        var u = RW_STATE.app && RW_STATE.app.currentUser ? RW_STATE.app.currentUser : {};
        return u.isOwner === true && Array.isArray(RW_STATE.permissions) && RW_STATE.permissions.indexOf('*') !== -1;
    }
    return { isOwner: isOwner };
})();
window.RW_OwnerContract = RW_OwnerContract;

'''
    return s.replace(anchor, anchor + block, 1), True


def wrap_enter_system(s: str) -> tuple[str, bool]:
    marker = 'enterSystem: function() {'
    if marker not in s or 'RW_Auth.enterSystem=function' in s:
        return s, False
    return s.replace(marker, marker + "\n    if (window.RW_ShellContext && !RW_ShellContext.hasCompany()) { RW_ShellContext.resolve().then(function () { RW_Auth.enterSystem(); }).catch(function (e) { hideLoader(); showToast('تعذر تحديد شركة المستخدم', 'error'); console.error(e); }); return; }", 1), True


def main() -> None:
    started = datetime.now(timezone.utc).isoformat()
    current_bytes = must(MAIN)
    original_bytes = must(ORIGINAL_MAIN)
    current = current_bytes.decode('utf-8')
    original = original_bytes.decode('utf-8')

    # Read all 22 fragment sources fully; the script executes on the runner filesystem,
    # so no model preview/truncation is involved.
    frag_meta = {}
    for part in PARTS:
        cp = CURRENT_FRAG_DIR / part
        op = ORIGINAL_FRAG_DIR / part
        frag_meta[part] = {'current': file_meta(cp), 'original': file_meta(op)}
        must(cp); must(op)

    # Greenfield semantic reconstruction: behavioral seed from the current full artifact,
    # then deterministic contract hardening. We never concatenate fragments.
    rebuilt = current
    changes = []

    rebuilt, did = inject_shell_contract(rebuilt)
    if did: changes.append('canonical RW_ShellContext + RW_OwnerContract')

    rebuilt, did = wrap_enter_system(rebuilt)
    if did: changes.append('fail-closed tenant gate on enterSystem')

    if "meta.permissions || ['*']" in rebuilt:
        rebuilt = rebuilt.replace("meta.permissions || ['*']", "Array.isArray(meta.permissions) ? meta.permissions.slice() : []")
        changes.append('removed wildcard permission fallback')

    rebuilt, n = add_company_scope_to_app_settings(rebuilt)
    if n: changes.append(f'company-scoped app_settings chains: {n}')

    for table in ('customers', 'suppliers', 'branches', 'users', 'roles', 'purchase_orders', 'stock_vouchers'):
        rebuilt, n = add_company_scope_to_chained_selects(rebuilt, table)
        if n: changes.append(f'company-scoped {table} chains: {n}')

    rebuilt, did = replace_rec_recommendations(rebuilt)
    if did: changes.append('restored independent rec-purchase / rec-offers semantics')

    # Explicit security/architecture assertions before publishing.
    forbidden_direct_stock = re.search(r"\.from\(['\"]stock_branches['\"]\)[\s\S]{0,500}?\.(?:update|insert|upsert|delete)\(", rebuilt)
    forbidden_inventory_log = re.search(r"\.from\(['\"]inventory_log['\"]\)[\s\S]{0,500}?\.(?:update|insert|upsert|delete)\(", rebuilt)
    if forbidden_direct_stock or forbidden_inventory_log:
        raise SystemExit('RECON_ABORT: direct physical stock/inventory_log writer remains in reconstructed main')

    required = [
        'window.RW_ShellContext',
        'window.RW_OwnerContract',
        'RW_ShellContext.getCompanyId()',
        "app_settings",
        'rec-offers',
        'rec-purchase',
    ]
    for token in required:
        if token not in rebuilt:
            raise SystemExit(f'RECON_ABORT: missing required contract token: {token}')

    if re.search(r"\.from\(['\"]app_settings['\"]\)\.select\([^;]*?\)\.limit\(\s*1\s*\)", rebuilt, re.S):
        raise SystemExit('RECON_ABORT: unscoped app_settings limit(1) remains')

    # Structural checks. Full browser E2E is handled as a separate, explicitly labelled gate.
    checks = {
        'doctype': bool(re.search(r'<!doctype\\s+html', rebuilt, re.I)),
        'html_open': '<html' in rebuilt.lower(),
        'html_close': '</html>' in rebuilt.lower(),
        'head_open': '<head' in rebuilt.lower(),
        'head_close': '</head>' in rebuilt.lower(),
        'body_open': '<body' in rebuilt.lower(),
        'body_close': '</body>' in rebuilt.lower(),
        'script_balance': rebuilt.lower().count('<script') == rebuilt.lower().count('</script>'),
        'style_balance': rebuilt.lower().count('<style') == rebuilt.lower().count('</style>'),
    }
    if not all(checks.values()):
        raise SystemExit('RECON_ABORT: structural HTML gate failed: ' + json.dumps(checks))

    # Build/record parity surface.
    def symbols(s: str) -> dict:
        funcs = sorted(set(re.findall(r'(?<![\\w$])function\\s+([A-Za-z_$][\\w$]*)\\s*\\(', s)))
        ids = sorted(set(re.findall(r'\\bid=["\']([^"\']+)["\']', s)))
        rpcs = sorted(set(re.findall(r'\\.rpc\\(\\s*["\']([^"\']+)["\']', s)))
        tables = sorted(set(re.findall(r'\\.from\\(\\s*["\']([^"\']+)["\']', s)))
        edges = sorted(set(re.findall(r'functions/v1/([A-Za-z0-9._-]+)', s)))
        return {'functions': funcs, 'ids': ids, 'rpcs': rpcs, 'tables': tables, 'edge_refs': edges}

    parity = {}
    final_symbols = symbols(rebuilt)
    main_symbols = symbols(original)
    for part in PARTS:
        cp = (CURRENT_FRAG_DIR / part).read_text(encoding='utf-8')
        op = (ORIGINAL_FRAG_DIR / part).read_text(encoding='utf-8')
        cs, os = symbols(cp), symbols(op)
        parity[part] = {
            'original': {k: len(v) for k, v in os.items()},
            'current_fragment': {k: len(v) for k, v in cs.items()},
            'final_main': {k: len(v) for k, v in final_symbols.items()},
            'original_missing_in_final': {k: sorted(set(os[k]) - set(final_symbols[k])) for k in os},
            'current_fragment_not_in_final': {k: sorted(set(cs[k]) - set(final_symbols[k])) for k in cs},
        }

    if any(parity[p]['original_missing_in_final'][k] for p in parity for k in parity[p]['original_missing_in_final']):
        raise SystemExit('RECON_ABORT: original symbol parity loss detected')

    # Make deterministic build marker replacement.
    rebuilt = re.sub(r'<!-- RAWAEA ERP — MAIN PWA RECONSTRUCTION BUILD:.*? -->', '', rebuilt, count=1)
    marker = '<!-- RAWAEA ERP — MAIN PWA RECONSTRUCTION BUILD: GOLD/DIAMOND SEMANTIC RECONSTRUCTION 2026-08-30 -->\n'
    rebuilt = marker + rebuilt

    MAIN.write_text(rebuilt, encoding='utf-8', newline='')
    final_meta = file_meta(MAIN)

    CTO.mkdir(parents=True, exist_ok=True)
    baseline = {
        'generated_at': started,
        'git_head_expected_at_start': None,
        'current_main_before': file_meta_from_bytes(current_bytes),
        'original_main': file_meta_from_bytes(original_bytes),
        'fragments': frag_meta,
        'changes': changes,
        'final_main': final_meta,
        'structural_checks': checks,
        'final_symbols': {k: len(v) for k, v in final_symbols.items()},
        'original_main_symbols': {k: len(v) for k, v in main_symbols.items()},
        'parity': parity,
        'browser_runtime': 'NOT_EXECUTED_BY_THIS SCRIPT',
    }
    (CTO / 'CURRENT_RECONSTRUCTION_BASELINE.json').write_text(json.dumps(baseline, ensure_ascii=False, indent=2), encoding='utf-8')


def file_meta_from_bytes(b: bytes) -> dict:
    return {'bytes': len(b), 'sha256': sha256(b), 'lines': b.count(b'\n') + 1}


if __name__ == '__main__':
    main()
