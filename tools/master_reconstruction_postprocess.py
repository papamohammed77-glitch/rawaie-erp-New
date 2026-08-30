from __future__ import annotations

import hashlib
import json
import re
import subprocess
from pathlib import Path

MAIN = Path('Current/PWA/main.html')
ORIGINAL = Path('Original/PWA/main.html')
CUR = Path('Current/PWA/main')
ORG = Path('Original/PWA/main')
CTO = Path('Current/CTO')
PARTS = [f'main{i}.md' for i in range(1,12)]


def sha(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def meta(p: Path) -> dict:
    b = p.read_bytes()
    return {'path': str(p), 'bytes': len(b), 'sha256': sha(b), 'lines': b.count(b'\n') + 1}


def symbols(s: str) -> dict:
    return {
        'functions': sorted(set(re.findall(r'(?<![\\w$])function\\s+([A-Za-z_$][\\w$]*)\\s*\\(', s))),
        'ids': sorted(set(re.findall(r'\\bid=["\']([^"\']+)["\']', s))),
        'rpcs': sorted(set(re.findall(r'\\.rpc\\(\\s*["\']([^"\']+)["\']', s))),
        'tables': sorted(set(re.findall(r'\\.from\\(\\s*["\']([^"\']+)["\']', s))),
        'edge_refs': sorted(set(re.findall(r'functions/v1/([A-Za-z0-9._-]+)', s))),
    }


def restore_rec_offers(s: str) -> tuple[str, bool]:
    marker = '// توصيات ذكية – مع فحص دفاعي'
    start = s.find(marker)
    if start < 0:
        return s, False
    end = s.find("        safeHTML(container, html);", start)
    if end < 0:
        return s, False
    # Replace only the recommendation renderer; keep the enclosing report intact.
    replacement = '''// توصيات الشراء — مستقلة
        if (types.indexOf('rec-purchase') !== -1) {
            var purchaseRecs = [];
            for (var j = 0; j < items.length; j++) {
                if (!items[j] || !items[j].id) continue;
                var available = Number(stockMap[items[j].id] || 0);
                var reorder = Number(items[j].reorder_point || 5);
                if (available <= reorder) {
                    purchaseRecs.push({ item: items[j].name || items[j].item_code, qty: available });
                    if (purchaseRecs.length >= 3) break;
                }
            }
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><h3 class="font-black text-lg mb-3"><i class="fa-solid fa-cart-shopping ml-2 text-indigo-600"></i> توصيات الشراء</h3>';
            if (purchaseRecs.length) {
                html += '<div class="space-y-3">';
                purchaseRecs.forEach(function(r){ html += '<div class="border-r-4 border-indigo-200 bg-indigo-50 p-4 rounded-lg"><span class="font-bold">' + _esc(r.item) + '</span><p class="text-sm text-gray-600">المخزون الحالي: ' + r.qty + '</p></div>'; });
                html += '</div>';
            } else html += '<div class="text-center py-4 text-gray-500">لا توجد توصيات شراء حالياً</div>';
            html += '</div>';
        }

        // توصيات العروض — مخزون راكد فعليًا بلا حركة بيع ضمن فترة التقرير
        if (types.indexOf('rec-offers') !== -1) {
            var soldCodesForOffers = {};
            for (var so = 0; so < details.length; so++) {
                if (details[so] && details[so].item_code) soldCodesForOffers[details[so].item_code] = true;
            }
            var offerCandidates = [];
            for (var oi = 0; oi < items.length; oi++) {
                var it = items[oi];
                if (!it || !it.id || !it.item_code) continue;
                var qtyInStock = Number(stockMap[it.id] || 0);
                if (qtyInStock <= 0 || soldCodesForOffers[it.item_code]) continue;
                var unitValue = Number(it.cost_price || it.sales_price || 0);
                offerCandidates.push({ item: it.name || it.item_code, code: it.item_code, qty: qtyInStock, value: qtyInStock * unitValue });
            }
            offerCandidates.sort(function(a,b){ return b.value - a.value; });
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><h3 class="font-black text-lg mb-3"><i class="fa-solid fa-tag ml-2 text-amber-600"></i> توصيات العروض</h3>';
            if (offerCandidates.length) {
                html += '<div class="space-y-3">';
                offerCandidates.slice(0, 5).forEach(function(r){ html += '<div class="border-r-4 border-amber-200 bg-amber-50 p-4 rounded-lg"><span class="font-bold">' + _esc(r.item) + '</span><p class="text-sm text-gray-600">مخزون راكد: ' + r.qty + ' — قيمة المخزون: ' + _fmtNum(r.value) + ' EGP</p></div>'; });
                html += '</div>';
            } else html += '<div class="text-center py-4 text-green-600">لا توجد أصناف راكدة مناسبة لعروض ترويجية حالياً</div>';
            html += '</div>';
        }

'''
    return s[:start] + replacement + s[end:], True


def main() -> None:
    subprocess.run(['python3', 'tools/p0_main_shell_repair_v2.py'], check=True)
    s = MAIN.read_text(encoding='utf-8')
    s, rec = restore_rec_offers(s)
    if rec:
        MAIN.write_text(s, encoding='utf-8')

    # Hard gates after reconstruction.
    required = ['window.RW_ShellContext', 'window.RW_OwnerContract', 'RW_ShellContext.getCompanyId()', 'rec-purchase', 'rec-offers']
    missing = [x for x in required if x not in s]
    if missing:
        raise SystemExit('missing required reconstruction contracts: ' + ', '.join(missing))
    if "meta.permissions || ['*']" in s:
        raise SystemExit('wildcard fallback remains')
    if re.search(r"\.from\(['\"]app_settings['\"]\)\.select\([^;]*?\)\.limit\(\s*1\s*\)", s, re.S):
        raise SystemExit('unscoped app_settings limit(1) remains')
    if re.search(r"\.from\(['\"]stock_branches['\"]\)[\s\S]{0,500}?\.(?:update|insert|upsert|delete)\(", s):
        raise SystemExit('direct stock_branches mutation remains')
    if re.search(r"\.from\(['\"]inventory_log['\"]\)[\s\S]{0,500}?\.(?:update|insert|upsert|delete)\(", s):
        raise SystemExit('direct inventory_log mutation remains')

    # Full original feature surface must survive in final main.
    osym = symbols(ORIGINAL.read_text(encoding='utf-8'))
    fsym = symbols(s)
    losses = {k: sorted(set(osym[k]) - set(fsym[k])) for k in osym}
    if any(losses[k] for k in losses):
        raise SystemExit('original feature-symbol parity loss: ' + json.dumps(losses, ensure_ascii=False))

    CTO.mkdir(parents=True, exist_ok=True)
    fragments = {p: {'current': meta(CUR/p), 'original': meta(ORG/p)} for p in PARTS}
    report = {
        'current_main_before_rebuild': None,
        'original_main': meta(ORIGINAL),
        'current_main_after_rebuild': meta(MAIN),
        'fragment_meta': fragments,
        'reconstruction': {'semantic_seed': 'Current/PWA/main.html', 'executor': 'tools/p0_main_shell_repair_v2.py', 'rec_offers_restored': rec, 'concat_used': False},
        'parity': {'original_symbol_losses': losses, 'original_main_symbols': {k: len(v) for k,v in osym.items()}, 'final_main_symbols': {k: len(v) for k,v in fsym.items()}},
        'browser_runtime': 'PENDING_SEPARATE_GATE',
    }
    (CTO/'FORENSIC_MASTER_RECONSTRUCTION.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')


if __name__ == '__main__':
    main()
