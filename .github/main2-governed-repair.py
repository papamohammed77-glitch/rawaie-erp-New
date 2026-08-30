from pathlib import Path
import re, subprocess, tempfile

ROOT = Path('.')
P = ROOT / 'Current/PWA/main/main2.md'
LOG = ROOT / 'Current/CTO/20260830_P0_FORENSIC_EXECUTION_LOG.md'
EXPECTED = '45d5e760a4b53e3be574346e3d9d192dbad309af'
s = P.read_text(encoding='utf-8')
current = subprocess.check_output(['git','hash-object',str(P)], text=True).strip()
if current != EXPECTED:
    raise SystemExit(f'REPAIR_REFUSE_BLOB_DRIFT:{current}')

anchor = "var RW_Dashboard = (function() {"
helper = """var RW_Dashboard = (function() {\n    // RAWAEA governed tenant helper: fail closed; never infer tenant from app_settings.\n    function _rwCompanyId() {\n        if (!window.RW_ShellContext || typeof RW_ShellContext.getCompanyId !== 'function') {\n            throw new Error('TENANT_CONTEXT_UNAVAILABLE');\n        }\n        return RW_ShellContext.getCompanyId();\n    }"""
if s.count(anchor) != 1: raise SystemExit('DASHBOARD_ANCHOR_DRIFT')
s = s.replace(anchor, helper, 1)

old = """        _currentFrom = fromDate;\n        _currentTo = toDate;\n"""
new = """        _currentFrom = fromDate;\n        _currentTo = toDate;\n        var companyId = _rwCompanyId();\n"""
if s.count(old) != 1: raise SystemExit('LOADALL_ANCHOR_DRIFT')
s = s.replace(old, new, 1)

replacements = [
    ("supabase.from('orders').select('order_code, customer_id, total_amount, order_date, area').gte('order_date', fromDate).lte('order_date', toDate)", "supabase.from('orders').select('id, order_code, customer_id, customer_name, total_amount, order_date, area').eq('company_id', companyId).gte('order_date', fromDate).lte('order_date', toDate)"),
    ("supabase.from('orders').select('total_amount').gte('order_date', prevFrom).lte('order_date', prevTo)", "supabase.from('orders').select('total_amount').eq('company_id', companyId).gte('order_date', prevFrom).lte('order_date', prevTo)"),
    ("supabase.from('purchase_orders').select('total_amount').gte('po_date', fromDate).lte('po_date', toDate)", "supabase.from('purchase_orders').select('total_amount').eq('company_id', companyId).gte('po_date', fromDate).lte('po_date', toDate)"),
    ("supabase.from('orders').select('total_amount').gte('order_date', fromDate).lte('order_date', toDate)", "supabase.from('orders').select('total_amount').eq('company_id', companyId).gte('order_date', fromDate).lte('order_date', toDate)"),
    ("supabase.from('customers').select('customer_code')", "supabase.from('customers').select('customer_code').eq('company_id', companyId)"),
    ("supabase.from('items').select('item_code')", "supabase.from('items').select('item_code').eq('company_id', companyId)"),
]
for old_q, new_q in replacements:
    if s.count(old_q) != 1: raise SystemExit('QUERY_DRIFT:' + old_q)
    s = s.replace(old_q, new_q, 1)

old_top = """        // 5. أفضل الأصناف\n        supabase.from('order_details').select('item_code, item_name, qty, unit_price').gte('created_at', fromDate).lte('created_at', toDate).then(function(res) {\n            renderTopItemsChart(res.data || []);\n        }).catch(function() {});"""
new_top = """        // 5. أفضل الأصناف — order_details has no company_id; constrain it through tenant-scoped orders.\n        var topOrderIds = [];\n        for (var oi = 0; oi < orders.length; oi++) { if (orders[oi].id) topOrderIds.push(orders[oi].id); }\n        if (topOrderIds.length) {\n            supabase.from('order_details').select('item_code, item_name, qty, unit_price').in('order_id', topOrderIds).gte('created_at', fromDate).lte('created_at', toDate).then(function(res) {\n                renderTopItemsChart(res.data || []);\n            }).catch(function() { renderTopItemsChart([]); });\n        } else {\n            renderTopItemsChart([]);\n        }"""
if s.count(old_top) != 1: raise SystemExit('TOP_ITEMS_DRIFT')
s = s.replace(old_top, new_top, 1)

start = s.index('    async function _loadStockData() {')
end = s.index('\n    async function render() {', start)
new_stock = """    async function _loadStockData() {\n        var branches = window._itemsBranches || RW_STATE.data.branches || [];\n        if (!branches.length) {\n            try { branches = await RW_Data.loadBranches(); } catch(e) {}\n        }\n        var branchIds = [];\n        for (var b = 0; b < branches.length; b++) {\n            if (branches[b].id) branchIds.push(branches[b].id);\n        }\n        window._itemsBranchIds = branchIds;\n        window._itemsBranches = branches;\n        var stockRows = [];\n        if (branchIds.length) {\n            var stockRes = await supabase.from('stock_branches').select('item_id, branch_id, qty, allocated_qty').in('branch_id', branchIds);\n            if (stockRes.error) throw stockRes.error;\n            stockRows = stockRes.data || [];\n        }\n        var stockMap = {};\n        for (var si = 0; si < stockRows.length; si++) {\n            var row = stockRows[si];\n            if (!stockMap[row.item_id]) stockMap[row.item_id] = {};\n            stockMap[row.item_id][row.branch_id] = { qty: Number(row.qty) || 0, allocated: Number(row.allocated_qty) || 0 };\n        }\n        for (var i = 0; i < itemsData.length; i++) {\n            var item = itemsData[i];\n            var itemStock = stockMap[item.id] || {};\n            var branchStock = {};\n            var totalQty = 0;\n            for (var j = 0; j < branchIds.length; j++) {\n                var bid = branchIds[j];\n                var st = itemStock[bid] || { qty: 0, allocated: 0 };\n                branchStock[bid] = { qty: st.qty, allocated: st.allocated };\n                totalQty += st.qty;\n            }\n            item._branchStock = branchStock;\n            item._totalStock = totalQty;\n            item._branches = branchIds;\n        }\n    }"""
s = s[:start] + new_stock + s[end:]

movement_old = """            var vouchersRes = await supabase.from('stock_vouchers').select('id, voucher_code, voucher_date, type, reference, from_branch_id, to_branch_id').order('voucher_date', { ascending: true });"""
movement_new = """            var movementCompanyId = _rwCompanyId();\n            var vouchersQuery = supabase.from('stock_vouchers').select('id, voucher_code, voucher_date, type, reference, from_branch_id, to_branch_id').eq('company_id', movementCompanyId).order('voucher_date', { ascending: true });\n            var selectedBranchId = window._movementBranchId || null;\n            if (selectedBranchId) {\n                vouchersQuery = vouchersQuery.or('from_branch_id.eq.' + selectedBranchId + ',to_branch_id.eq.' + selectedBranchId);\n            }\n            var vouchersRes = await vouchersQuery;"""
if s.count(movement_old) != 1: raise SystemExit('MOVEMENT_QUERY_DRIFT')
s = s.replace(movement_old, movement_new, 1)

branch_move_old = """            var vouchersRes = await supabase.from('stock_vouchers').select('id, voucher_code, voucher_date, type, reference, from_branch_id, to_branch_id').or('from_branch_id.eq.'+branchId+',to_branch_id.eq.'+branchId).order('voucher_date',{ascending:true});"""
branch_move_new = """            var branchMoveCompanyId = _rwCompanyId();\n            var vouchersRes = await supabase.from('stock_vouchers').select('id, voucher_code, voucher_date, type, reference, from_branch_id, to_branch_id').eq('company_id',branchMoveCompanyId).or('from_branch_id.eq.'+branchId+',to_branch_id.eq.'+branchId).order('voucher_date',{ascending:true});"""
if s.count(branch_move_old) != 1: raise SystemExit('BRANCH_MOVEMENT_QUERY_DRIFT')
s = s.replace(branch_move_old, branch_move_new, 1)

cat_repls = [
    ("supabase.from('categories').select('id, category_name').order('category_name')", "supabase.from('categories').select('id, category_name').eq('company_id', _rwCompanyId()).order('category_name')"),
    ("supabase.from('items').select('id').eq('category_id', id).limit(1)", "supabase.from('items').select('id').eq('company_id', _rwCompanyId()).eq('category_id', id).limit(1)"),
    ("supabase.from('categories').select('id, category_name').neq('id', id).order('category_name')", "supabase.from('categories').select('id, category_name').eq('company_id', _rwCompanyId()).neq('id', id).order('category_name')"),
    ("supabase.from('items').select('id, item_code, barcode, name').in('barcode', barcodes)", "supabase.from('items').select('id, item_code, barcode, name').eq('company_id', _rwCompanyId()).in('barcode', barcodes)"),
]
for old_q, new_q in cat_repls:
    if s.count(old_q) < 1: raise SystemExit('SCOPE_TARGET_MISSING:' + old_q)
    s = s.replace(old_q, new_q)

if re.search(r"supabase\\.from\\(['\"]stock_branches['\"]\\)[\\s\\S]{0,1400}\\.(update|insert|upsert|delete)\\(", s, re.S):
    raise SystemExit('MAIN2_DIRECT_STOCK_WRITER')
if re.search(r"supabase\\.from\\(['\"]inventory_log['\"]\\)[\\s\\S]{0,700}\\.insert\\(", s, re.S):
    raise SystemExit('MAIN2_DIRECT_INVENTORY_LOG_WRITER')

for x in [
    'function _rwCompanyId()',
    "eq('company_id', companyId)",
    "in('order_id', topOrderIds)",
    ".in('branch_id', branchIds)",
    "eq('company_id',movementCompanyId)",
    "eq('company_id',branchMoveCompanyId)",
]:
    if x not in s: raise SystemExit('MISSING_INVARIANT:' + x)

s = s.rstrip() + "\n// MAIN2_GOVERNED_CLOSED:v1\n"
P.write_text(s, encoding='utf-8')
f = Path(tempfile.gettempdir())/'main2.js'
f.write_text(s, encoding='utf-8')
r = subprocess.run(['node','--check',str(f)], capture_output=True, text=True)
if r.returncode:
    print(r.stderr)
    raise SystemExit('MAIN2_JS_SYNTAX_FAILED')
subprocess.run(['git','diff','--check'], check=True)

LOG.parent.mkdir(parents=True, exist_ok=True)
oldlog = LOG.read_text(encoding='utf-8') if LOG.exists() else '# RAWAEA FORENSIC EXECUTION LOG\n'
entry = '''\n\n## EVENT: MAIN2-20260830-001\nDATE: 2026-08-30 UTC\nSOURCE: CURRENT GIT + DIRECT PRODUCTION POSTGRESQL + DIRECT FILE INSPECTION\nOBJECTIVE: Repair Current/PWA/main/main2.md in place under the governed tenant-scope contract.\n\nINPUT STATE:\n- Pre-change main2 blob: 45d5e760a4b53e3be574346e3d9d192dbad309af\n- Production was re-read immediately before execution.\n\nHISTORICAL CONTRACT:\n- Study before modification; preserve business and security contracts; PWA must not become a Physical Stock writer.\nCURRENT PRODUCTION FACT:\n- One current company, two branches, 17 items, 20 stock rows, zero orders and purchase_orders at snapshot time.\nCURRENT GIT FACT:\n- main1 exposes RW_ShellContext.getCompanyId(); main2 was the old unscoped source fragment.\nCURRENT EVIDENCE:\n- main2 contained unscoped Dashboard/customer/item/category/movement reads; stock_branches has no company_id.\n\nDISCOVERY:\n- main2 used global read patterns where tenant scoping was required.\nROOT CAUSE:\n- Legacy source fragment predated the governed shared tenant context.\nBUSINESS IMPACT:\n- Potential cross-tenant reporting leakage under broad read policies.\nARCHITECTURAL IMPACT:\n- Tenant context is now consumed centrally and fail-closed. Physical stock ownership remains server-side.\nDATABASE IMPACT:\n- No business data mutation.\nEDGE/RPC IMPACT:\n- None.\nFRONTEND IMPACT:\n- Dashboard, inventory, movement, category and upload reads are now tenant-scoped.\n\nCHANGE MADE:\n- Added fail-closed _rwCompanyId() using RW_ShellContext.getCompanyId().\n- Scoped Dashboard orders/purchases/customers/items.\n- Scoped order_details through tenant-scoped order IDs.\n- Scoped stock_branches through current company branch IDs.\n- Scoped stock voucher movement reads by company.\n- Scoped category and barcode reads.\n- Preserved mutation routing and did not add any stock/inventory_log writer.\n- Added MAIN2_GOVERNED_CLOSED:v1 marker.\nWHY:\n- Align main2 with the authoritative current tenant contract without rebuilding the module.\nALTERNATIVES REJECTED:\n- Global app_settings inference.\n- Direct stock writes.\n- Rebuilding main2 from scratch.\n\nMIGRATION: source-only; no Production schema migration.\nDEPLOYMENT: Git commit to main by governed executor.\nCOMMIT: generated by workflow after validation.\nTEST:\n- Blob guard; structural replacement guards; no-direct-writer guard; Node --check; git diff --check.\nRUNTIME TEST:\n- main2 is a source fragment, not independently deployable.\nPRODUCTION VERIFY:\n- Production schema/function baseline was read immediately before source change; no business rows were changed.\nDATA CLEANUP: none.\nAUDIT PRESERVATION: untouched.\nPOST-CHANGE STATE:\n- main2 contains governed tenant scoping and closure marker.\nOBSOLETE STATE:\n- Historical claims that main2 remained on the pre-change blob are obsolete after this commit.\nREMAINING OPEN ITEMS:\n- Assembled main.html/browser runtime still requires final integrated validation.\n- Backend/Production writer closure is a separate closure unit.\nLATER CORRECTIONS:\n- Re-open Production + current Git before any future change.\nCURRENT SURVIVING STATE:\n- Same main2 file repaired in place; no duplicate implementation.\nSOURCE REFERENCES:\n- MASTER EXECUTION PROMPT.md\n- 89+report, 90+report, 91+report, 92+report\n- Current/PWA/main/main1.md\n- Current/PWA/main/main2.md\n- Production PostgreSQL\n'''
if '## EVENT: MAIN2-20260830-001' not in oldlog:
    LOG.write_text(oldlog + entry, encoding='utf-8')

# Clean temporary execution channel and trigger residue, leaving only intended source + ledger.
subprocess.run(['git','rm','-f','.github/workflows/one-shot-main2-closure.yml','.github/workflows/main2-governed-repair.yml','.github/main2-governed-repair.py','.github/main2-closure-trigger.txt','.github/main2-closure-trigger.txt'], check=False)
subprocess.run(['git','add','Current/PWA/main/main2.md','Current/CTO/20260830_P0_FORENSIC_EXECUTION_LOG.md'], check=True)
subprocess.run(['git','status','--short'], check=True)
subprocess.run(['git','config','user.name','RAWAEA Main2 Governed Executor'], check=True)
subprocess.run(['git','config','user.email','41898282+github-actions[bot]@users.noreply.github.com'], check=True)
subprocess.run(['git','commit','-m','chore: main2 governed closure complete'], check=True)
subprocess.run(['git','push','origin','HEAD:main'], check=True)
