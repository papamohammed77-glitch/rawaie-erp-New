from __future__ import annotations

import hashlib
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path('.')
MAIN = ROOT / 'Current/PWA/main.html'
CANDIDATE = ROOT / 'Current/PWA/main.reconstruction.html'
ORIGINAL = ROOT / 'Original/PWA/main.html'
FRAG = ROOT / 'Current/PWA/main'
ORG_FRAG = ROOT / 'Original/PWA/main'
CTO = ROOT / 'Current/CTO'
PARTS = [f'main{i}.md' for i in range(1, 12)]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def meta(path: Path) -> dict:
    b = path.read_bytes()
    return {'path': str(path), 'bytes': len(b), 'lines': b.count(b'\n') + 1, 'sha256': hashlib.sha256(b).hexdigest()}


def symbols(text: str) -> dict:
    return {
        'functions': sorted(set(re.findall(r'(?<![\\w$])function\\s+([A-Za-z_$][\\w$]*)\\s*\\(', text))),
        'ids': sorted(set(re.findall(r'\\bid=["\']([^"\']+)["\']', text))),
        'rpcs': sorted(set(re.findall(r'\\.rpc\\(\\s*["\']([^"\']+)["\']', text))),
        'tables': sorted(set(re.findall(r'\\.from\\(\\s*["\']([^"\']+)["\']', text))),
        'edge_refs': sorted(set(re.findall(r'functions/v1/([A-Za-z0-9._-]+)', text))),
        'modules': sorted(set(re.findall(r'(?<![\\w$])(?:var|let|const)\\s+(RW_[A-Za-z0-9_$]+)\\s*=', text)) |
                          set(re.findall(r'window\\.(RW_[A-Za-z0-9_$]+)\\s*=', text))),
    }


def static_checks(text: str) -> dict:
    checks = {
        'doctype': bool(re.search(r'<!doctype\\s+html', text, re.I)),
        'html_open': bool(re.search(r'<html\\b', text, re.I)),
        'html_close': bool(re.search(r'</html>', text, re.I)),
        'head_open': bool(re.search(r'<head\\b', text, re.I)),
        'head_close': bool(re.search(r'</head>', text, re.I)),
        'body_open': bool(re.search(r'<body\\b', text, re.I)),
        'body_close': bool(re.search(r'</body>', text, re.I)),
        'script_balance': len(re.findall(r'<script\\b', text, re.I)) == len(re.findall(r'</script>', text, re.I)),
        'style_balance': len(re.findall(r'<style\\b', text, re.I)) == len(re.findall(r'</style>', text, re.I)),
        'shell_context': 'window.RW_ShellContext' in text and 'RW_ShellContext.getCompanyId()' in text,
        'owner_contract': 'window.RW_OwnerContract' in text,
        'rec_purchase': 'rec-purchase' in text,
        'rec_offers': 'rec-offers' in text,
        'no_direct_stock_writer': not bool(re.search(r"\\.from\\(['\"]stock_branches['\"]\\)[\\s\\S]{0,700}?\\.(?:update|insert|upsert|delete)\\(", text)),
        'no_direct_inventory_log_writer': not bool(re.search(r"\\.from\\(['\"]inventory_log['\"]\\)[\\s\\S]{0,700}?\\.(?:update|insert|upsert|delete)\\(", text)),
        'no_unscoped_app_settings_limit1': not bool(re.search(r"\\.from\\(['\"]app_settings['\"]\\)\\s*\\.select\\([^;]*?\\)\\s*\\.limit\\(\\s*1\\s*\\)", text, re.S)),
        'no_hardcoded_root_company': '00000000-0000-0000-0000-000000000001' not in text,
        'no_legacy_wildcard_fallback': "meta.permissions || ['*']" not in text,
    }
    return checks


def node_script_syntax(text: str) -> dict:
    scripts = re.findall(r'<script(?![^>]*\\bsrc=)[^>]*>(.*?)</script>', text, re.S | re.I)
    failures = []
    with tempfile.TemporaryDirectory() as td:
        for i, body in enumerate(scripts, 1):
            p = Path(td) / f'script-{i}.js'
            p.write_text(body, encoding='utf-8')
            r = subprocess.run(['node', '--check', str(p)], text=True, capture_output=True)
            if r.returncode:
                failures.append({'script': i, 'stderr': r.stderr[-4000:]})
    return {'count': len(scripts), 'failures': failures}


def restore_rec_offers(text: str) -> tuple[str, bool]:
    marker = '// توصيات ذكية – مع فحص دفاعي'
    start = text.find(marker)
    if start < 0:
        return text, False
    end = text.find('        safeHTML(container, html);', start)
    if end < 0:
        return text, False
    replacement = '''// توصيات الشراء — مستقلة\n        if (types.indexOf('rec-purchase') !== -1) {\n            var purchaseRecs = [];\n            for (var j = 0; j < items.length; j++) {\n                if (!items[j] || !items[j].id) continue;\n                var available = Number(stockMap[items[j].id] || 0);\n                var reorder = Number(items[j].reorder_point || 5);\n                if (available <= reorder) {\n                    purchaseRecs.push({ item: items[j].name || items[j].item_code, qty: available });\n                    if (purchaseRecs.length >= 3) break;\n                }\n            }\n            html += '<div class=\"bg-white rounded-2xl shadow-sm border p-5\"><h3 class=\"font-black text-lg mb-3\"><i class=\"fa-solid fa-cart-shopping ml-2 text-indigo-600\"></i> توصيات الشراء</h3>';\n            if (purchaseRecs.length) {\n                html += '<div class=\"space-y-3\">';\n                purchaseRecs.forEach(function(r){ html += '<div class=\"border-r-4 border-indigo-200 bg-indigo-50 p-4 rounded-lg\"><span class=\"font-bold\">' + _esc(r.item) + '</span><p class=\"text-sm text-gray-600\">المخزون الحالي: ' + r.qty + '</p></div>'; });\n                html += '</div>';\n            } else html += '<div class=\"text-center py-4 text-gray-500\">لا توجد توصيات شراء حالياً</div>';\n            html += '</div>';\n        }\n\n        // توصيات العروض — مخزون راكد بلا حركة بيع ضمن فترة التقرير\n        if (types.indexOf('rec-offers') !== -1) {\n            var soldCodesForOffers = {};\n            for (var so = 0; so < details.length; so++) {\n                if (details[so] && details[so].item_code) soldCodesForOffers[details[so].item_code] = true;\n            }\n            var offerCandidates = [];\n            for (var oi = 0; oi < items.length; oi++) {\n                var it = items[oi];\n                if (!it || !it.id || !it.item_code) continue;\n                var qtyInStock = Number(stockMap[it.id] || 0);\n                if (qtyInStock <= 0 || soldCodesForOffers[it.item_code]) continue;\n                var unitValue = Number(it.cost_price || it.sales_price || 0);\n                offerCandidates.push({ item: it.name || it.item_code, code: it.item_code, qty: qtyInStock, value: qtyInStock * unitValue });\n            }\n            offerCandidates.sort(function(a,b){ return b.value - a.value; });\n            html += '<div class=\"bg-white rounded-2xl shadow-sm border p-5\"><h3 class=\"font-black text-lg mb-3\"><i class=\"fa-solid fa-tag ml-2 text-amber-600\"></i> توصيات العروض</h3>';\n            if (offerCandidates.length) {\n                html += '<div class=\"space-y-3\">';\n                offerCandidates.slice(0, 5).forEach(function(r){ html += '<div class=\"border-r-4 border-amber-200 bg-amber-50 p-4 rounded-lg\"><span class=\"font-bold\">' + _esc(r.item) + '</span><p class=\"text-sm text-gray-600\">مخزون راكد: ' + r.qty + ' — قيمة المخزون: ' + _fmtNum(r.value) + ' EGP</p></div>'; });\n                html += '</div>';\n            } else html += '<div class=\"text-center py-4 text-green-600\">لا توجد أصناف راكدة مناسبة لعروض ترويجية حالياً</div>';\n            html += '</div>';\n        }\n\n'''
    return text[:start] + replacement + text[end:], True


def gap_registry(frag_texts: dict[str, str], candidate: str) -> dict:
    candidate_symbols = symbols(candidate)
    gaps = {}
    for name in ['main3.md','main5.md','main7.md','main8.md','main9.md','main10.md']:
        fs = symbols(frag_texts[name])
        losses = {k: sorted(set(fs[k]) - set(candidate_symbols[k])) for k in ('functions','ids','rpcs','tables','edge_refs','modules')}
        gaps[name] = losses
    return gaps


def main() -> None:
    CTO.mkdir(parents=True, exist_ok=True)
    baseline = {
        'gate': 0,
        'git_head': subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip(),
        'current_main': meta(MAIN),
        'original_main': meta(ORIGINAL),
        'fragments': {},
    }
    for p in PARTS:
        c = FRAG / p
        o = ORG_FRAG / p
        baseline['fragments'][p] = {'current': meta(c), 'original': meta(o) if o.exists() else None}
    (CTO/'RECONSTRUCTION_BASELINE.json').write_text(json.dumps(baseline, ensure_ascii=False, indent=2), encoding='utf-8')

    # Gate 3: create candidate without touching the tracked main.html.
    with tempfile.TemporaryDirectory() as td:
        backup = Path(td)/'main.html'
        shutil.copy2(MAIN, backup)
        shutil.copy2(MAIN, CANDIDATE)
        # Existing governed shell repair is designed around main.html; use it only in a temporary workspace state.
        shutil.copy2(MAIN, MAIN)
        subprocess.run(['python3','tools/p0_main_shell_repair_v2.py'], check=True)
        rebuilt = MAIN.read_text(encoding='utf-8')
        rebuilt, rec = restore_rec_offers(rebuilt)
        CANDIDATE.write_text(rebuilt, encoding='utf-8')
        shutil.copy2(backup, MAIN)

    candidate = CANDIDATE.read_text(encoding='utf-8')
    frag_texts = {p: (FRAG/p).read_text(encoding='utf-8') for p in PARTS}
    st = static_checks(candidate)
    syntax = node_script_syntax(candidate)
    original_symbols = symbols(ORIGINAL.read_text(encoding='utf-8'))
    cand_symbols = symbols(candidate)
    original_losses = {k: sorted(set(original_symbols[k]) - set(cand_symbols[k])) for k in original_symbols}
    gap_losses = gap_registry(frag_texts, candidate)

    required_gap_modules = {k:v for k,v in gap_losses.items() if any(v[x] for x in v)}
    report = {
        'gate0': baseline,
        'gate1': {
            'original_symbols': {k: len(v) for k,v in original_symbols.items()},
            'candidate_symbols': {k: len(v) for k,v in cand_symbols.items()},
            'fragment_symbols': {p: {k: len(v) for k,v in symbols(t).items()} for p,t in frag_texts.items()},
        },
        'gate2': {
            'gap_analysis': gap_losses,
            'unresolved_fragment_surface': required_gap_modules,
            'note': 'A fragment difference is not automatically a required final symbol; it is retained as evidence for semantic disposition.'
        },
        'gate3': {'candidate': meta(CANDIDATE), 'rec_offers_restored': rec},
        'gate4': {'static_checks': st, 'javascript_syntax': syntax, 'original_symbol_losses': original_losses},
        'gate7': {'candidate_matches_current_main_seed': sha256(CANDIDATE) == baseline['current_main']['sha256'], 'current_main_unchanged': sha256(MAIN) == baseline['current_main']['sha256']},
    }
    (CTO/'parity.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')

    failures = []
    for k,v in st.items():
        if not v: failures.append('STATIC:' + k)
    if syntax['failures']: failures.append('JS_SYNTAX')
    if any(original_losses[k] for k in original_losses): failures.append('ORIGINAL_SYMBOL_PARITY')
    # The six named fragment gaps must be explicitly closed in the final artifact; fail fast until semantics are actually present.
    if required_gap_modules:
        failures.append('FRAGMENT_GAP_SURFACE')
    if sha256(MAIN) != baseline['current_main']['sha256']:
        failures.append('MAIN_WAS_MUTATED')
    if failures:
        print(json.dumps({'status':'FAIL','failures':failures,'report':'Current/CTO/parity.json'}, ensure_ascii=False, indent=2))
        raise SystemExit(1)
    print(json.dumps({'status':'PASS','candidate':str(CANDIDATE),'sha256':sha256(CANDIDATE)}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
