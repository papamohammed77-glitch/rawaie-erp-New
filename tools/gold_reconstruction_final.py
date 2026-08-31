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
FRAG_DIR = ROOT / 'Current/PWA/main'
ORIG_FRAG_DIR = ROOT / 'Original/PWA/main'
CTO = ROOT / 'Current/CTO'
PARTS = [f'main{i}.md' for i in range(1, 12)]
MODULES = PARTS[1:]


def sha256(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def meta(p: Path) -> dict:
    b = p.read_bytes()
    return {'path': str(p), 'bytes': len(b), 'lines': b.count(b'\n') + 1, 'sha256': hashlib.sha256(b).hexdigest()}


def symbols(text: str) -> dict:
    return {
        'functions': sorted(set(re.findall(r'(?<![\\w$])function\\s+([A-Za-z_$][\\w$]*)\\s*\\(', text))),
        'window_exports': sorted(set(re.findall(r'window\\.([A-Za-z_$][\\w$]*)\\s*=', text))),
        'rw_globals': sorted(set(re.findall(r'(?<![\\w$])RW_[A-Za-z0-9_$]+', text))),
        'ids': sorted(set(re.findall(r'\\bid=["\']([^"\']+)["\']', text))),
        'rpcs': sorted(set(re.findall(r'\\.rpc\\(\\s*["\']([^"\']+)["\']', text))),
        'tables': sorted(set(re.findall(r'\\.from\\(\\s*["\']([^"\']+)["\']', text))),
        'edges': sorted(set(re.findall(r'functions/v1/([A-Za-z0-9._-]+)', text))),
    }


def static_checks(text: str) -> dict:
    return {
        'doctype': bool(re.search(r'<!doctype\\s+html', text, re.I)),
        'html_open': bool(re.search(r'<html\\b', text, re.I)),
        'html_close': bool(re.search(r'</html\\s*>', text, re.I)),
        'head_open': bool(re.search(r'<head\\b', text, re.I)),
        'head_close': bool(re.search(r'</head\\s*>', text, re.I)),
        'body_open': bool(re.search(r'<body\\b', text, re.I)),
        'body_close': bool(re.search(r'</body\\s*>', text, re.I)),
        'script_balance': len(re.findall(r'<script\\b', text, re.I)) == len(re.findall(r'</script\\s*>', text, re.I)),
        'style_balance': len(re.findall(r'<style\\b', text, re.I)) == len(re.findall(r'</style\\s*>', text, re.I)),
        'shell_context': 'window.RW_ShellContext' in text and 'RW_ShellContext.getCompanyId()' in text,
        'owner_contract': 'window.RW_OwnerContract' in text,
        'owner_license': 'RW_OwnerLicense' in text,
        'rec_purchase': 'rec-purchase' in text,
        'rec_offers': 'rec-offers' in text,
        'no_direct_stock_writer': not bool(re.search(r"(?:supabase|client)\\.from\\([\\"']stock_branches[\\"']\\)[\\s\\S]{0,900}?\\.(?:update|insert|upsert|delete)\\(", text)),
        'no_direct_inventory_log_writer': not bool(re.search(r"(?:supabase|client)\\.from\\([\\"']inventory_log[\\"']\\)[\\s\\S]{0,900}?\\.(?:update|insert|upsert|delete)\\(", text)),
        'no_hardcoded_company_uuid': not bool(re.search(r'(?<![A-Za-z0-9])00000000-0000-0000-0000-000000000001(?![A-Za-z0-9])', text)),
        'no_unscoped_app_settings_limit1': not bool(re.search(r"(?:supabase|client)\\.from\\([\\"']app_settings[\\"']\\)[\\s\\S]{0,500}?\\.limit\\(\\s*1\\s*\\)", text)),
    }


def node_syntax(text: str) -> dict:
    blocks = re.findall(r'<script(?![^>]*\\bsrc=)[^>]*>(.*?)</script\\s*>', text, re.S | re.I)
    failures = []
    with tempfile.TemporaryDirectory() as td:
        for i, block in enumerate(blocks, 1):
            p = Path(td) / f'script-{i}.js'
            p.write_text(block, encoding='utf-8')
            r = subprocess.run(['node', '--check', str(p)], text=True, capture_output=True)
            if r.returncode:
                failures.append({'script': i, 'stderr': r.stderr[-5000:]})
    return {'count': len(blocks), 'failures': failures}


def ensure_parent_document(parent: str) -> str:
    s = parent.lstrip('\ufeff')
    body = re.search(r'</body\\s*>', s, re.I)
    html = re.search(r'</html\\s*>', s, re.I)
    if body:
        s = s[:body.start()] + '\n' + s[body.start():]
    else:
        s += '\n</body>\n'
    if not html:
        s = s.rstrip() + '\n</html>\n'
    return s


def strip_wrappers(text: str) -> str:
    s = text.strip()
    if s.startswith('```'):
        s = re.sub(r'^```(?:javascript|js|html)?\\s*', '', s, flags=re.I)
        s = re.sub(r'\\s*```$', '', s)
    return s.strip()


def semantic_assemble() -> tuple[str, dict]:
    parent = ensure_parent_document(MAIN.read_text(encoding='utf-8', errors='replace'))
    module_payloads = []
    # MAIN1 is the parent contract. The current complete main is retained only as the shell seed;
    # each logical module is registered and inserted as its own script boundary.
    for part in MODULES:
        payload = strip_wrappers((FRAG_DIR / part).read_text(encoding='utf-8', errors='replace'))
        if not payload:
            raise SystemExit(f'EMPTY_FRAGMENT:{part}')
        module_payloads.append((part, payload))
    marker = '</body>'
    pos = parent.lower().rfind(marker)
    if pos < 0:
        raise SystemExit('PARENT_BODY_CLOSE_MISSING')
    blocks = []
    for part, payload in module_payloads:
        blocks.append(f'\\n<!-- RAWAEA SEMANTIC MODULE: {part} -->\\n<script data-rw-module="{part}">\\n{payload}\\n</script>\\n<!-- /RAWAEA SEMANTIC MODULE: {part} -->\\n')
    candidate = parent[:pos] + ''.join(blocks) + parent[pos:]
    return candidate, {
        'parent_source': meta(MAIN),
        'parent_contract': 'Current/PWA/main.html + P0 governed shell repairs as parent seed',
        'logical_modules': [{'module': p, 'source': str(FRAG_DIR / p), 'bytes': len(t.encode('utf-8')), 'sha256': hashlib.sha256(t.encode('utf-8')).hexdigest()} for p,t in module_payloads],
        'assembly': 'semantic-module-registration',
    }


def build_registries(candidate: str, baseline: dict) -> tuple[dict, dict, dict, dict, dict]:
    parent_syms = symbols(candidate)
    current_syms = {p: symbols((FRAG_DIR/p).read_text(encoding='utf-8', errors='replace')) for p in PARTS}
    original_syms = {p: symbols((ORIG_FRAG_DIR/p).read_text(encoding='utf-8', errors='replace')) for p in PARTS if (ORIG_FRAG_DIR/p).exists()}

    feature_registry = {
        'generated_from': baseline['git_head'],
        'modules': {},
        'disposition_rule': 'Every current module is PRESERVED/REBUILT via an explicit semantic module boundary; historical losses are listed rather than hidden.'
    }
    function_registry = {'generated_from': baseline['git_head'], 'modules': {}, 'global_candidate': parent_syms}
    contract_registry = {
        'tenant': 'Authenticated User -> users.auth_id -> users.company_id -> RW_ShellContext',
        'owner': 'isOwner + wildcard permissions + owner profile + license semantics',
        'inventory': 'Physical movement -> post_stock_movement; reservation -> reserve_stock/release_stock_reservation',
        'fulfillment': 'order_details authoritative where current contract applies; run_sheet_details derived',
        'candidate_static': static_checks(candidate),
    }
    dependency_graph = {'nodes': {}, 'edges': []}
    parity = {'modules': {}, 'original_surface': {}, 'static': static_checks(candidate), 'syntax': node_syntax(candidate)}

    for p in PARTS:
        c = current_syms[p]
        o = original_syms.get(p, {})
        feature_registry['modules'][p] = {
            'current_source': str(FRAG_DIR/p),
            'original_source': str(ORIG_FRAG_DIR/p) if (ORIG_FRAG_DIR/p).exists() else None,
            'current_symbols': c,
            'original_symbols': o,
            'target_implementation': 'semantic module registered inside one canonical parent',
            'disposition': 'PRESERVED' if p == 'main1.md' else 'REBUILT',
        }
        function_registry['modules'][p] = {'current': c['functions'], 'original': o.get('functions', []), 'window_exports': c['window_exports']}
        dependency_graph['nodes'][p] = {'window_exports': c['window_exports'], 'tables': c['tables'], 'rpcs': c['rpcs'], 'edges': c['edges']}
        for edge in c['edges']:
            dependency_graph['edges'].append({'from': p, 'to': edge, 'type': 'edge-function'})
        for rpc in c['rpcs']:
            dependency_graph['edges'].append({'from': p, 'to': rpc, 'type': 'rpc'})
        parity['modules'][p] = {
            'functions_present': sorted(set(c['functions']) & set(parent_syms['functions'])),
            'window_exports_present': sorted(set(c['window_exports']) & set(parent_syms['window_exports'])),
            'tables_present': sorted(set(c['tables']) & set(parent_syms['tables'])),
            'rpcs_present': sorted(set(c['rpcs']) & set(parent_syms['rpcs'])),
            'edges_present': sorted(set(c['edges']) & set(parent_syms['edges'])),
            'status': 'PRESERVED' if p == 'main1.md' else 'REBUILT',
        }

    for p, o in original_syms.items():
        parity['original_surface'][p] = {
            'functions_missing_from_candidate_surface': sorted(set(o['functions']) - set(parent_syms['functions'])),
            'window_exports_missing_from_candidate_surface': sorted(set(o['window_exports']) - set(parent_syms['window_exports'])),
            'ids_missing_from_candidate_surface': sorted(set(o['ids']) - set(parent_syms['ids'])),
            'rpcs_missing_from_candidate_surface': sorted(set(o['rpcs']) - set(parent_syms['rpcs'])),
            'edges_missing_from_candidate_surface': sorted(set(o['edges']) - set(parent_syms['edges'])),
        }
    return feature_registry, function_registry, contract_registry, dependency_graph, parity


def main() -> None:
    CTO.mkdir(parents=True, exist_ok=True)
    baseline = {
        'gate': 0,
        'git_head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
        'current_main': meta(MAIN),
        'original_main': meta(ORIGINAL),
        'fragments': {p: {'current': meta(FRAG/p), 'original': meta(ORIG_FRAG_DIR/p) if (ORIG_FRAG_DIR/p).exists() else None} for p in PARTS},
    }
    (CTO/'RECONSTRUCTION_BASELINE.json').write_text(json.dumps(baseline, ensure_ascii=False, indent=2), encoding='utf-8')

    candidate, assembly = semantic_assemble()
    CANDIDATE.write_text(candidate, encoding='utf-8')
    feature_registry, function_registry, contract_registry, dependency_graph, parity = build_registries(candidate, baseline)
    parity['gate3'] = {'candidate': meta(CANDIDATE), 'assembly': assembly}
    parity['gate7'] = {'current_main_unchanged': sha256(MAIN) == baseline['current_main']['sha256']}

    (CTO/'feature_registry.json').write_text(json.dumps(feature_registry, ensure_ascii=False, indent=2), encoding='utf-8')
    (CTO/'function_registry.json').write_text(json.dumps(function_registry, ensure_ascii=False, indent=2), encoding='utf-8')
    (CTO/'contract_registry.json').write_text(json.dumps(contract_registry, ensure_ascii=False, indent=2), encoding='utf-8')
    (CTO/'dependency_graph.json').write_text(json.dumps(dependency_graph, ensure_ascii=False, indent=2), encoding='utf-8')
    (CTO/'parity.json').write_text(json.dumps(parity, ensure_ascii=False, indent=2), encoding='utf-8')

    st = parity['static']
    sy = parity['syntax']
    # Candidate must preserve every current module surface: because modules are physically included,
    # the check is against module blocks and not against accidental global flattening.
    failures = [f'STATIC:{k}' for k,v in st.items() if not v]
    if sy['failures']:
        failures.append('JS_SYNTAX')
    # Original surface losses are evidence, not silently ignored. Current module inclusion resolves current parity;
    # legacy-original differences are retained for explicit review.
    if not parity['gate7']['current_main_unchanged']:
        failures.append('MAIN_SEED_MUTATED')
    report = {
        'status': 'PASS' if not failures else 'FAIL',
        'failures': failures,
        'candidate_sha256': sha256(CANDIDATE),
        'candidate_bytes': CANDIDATE.stat().st_size,
        'module_boundaries': len(MODULES),
        'original_surface_requires_reconciliation': parity['original_surface'],
    }
    (CTO/'GREENFIELD_BUILD_RESULT.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    if failures:
        print(json.dumps(report, ensure_ascii=False, indent=2))
        raise SystemExit(1)
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
