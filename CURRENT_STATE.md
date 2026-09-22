# CURRENT STATE — UPDATED AFTER REPORT313
## Session: 2026-09-22
## Current scope: Warehouse Vouchers Smart Search / Reference Directory
## Canonical report commit: a352eb94bf0a5e25be60365347876e5bd848c00f

### Authoritative current heads
- System repo HEAD at checkpoint creation: 23ff77cf170771221293163e938d708c51ea5032
- System repo parent: a352eb94bf0a5e25be60365347876e5bd848c00f
- Frontend repo HEAD: f42bc0ae0c2e88a6ebf66e54b6a9ff8e1057c5e3
- Frontend parent: 7a11af9ecba59da29fd6d8aad17053678d75c2e6
- vouchers.html current blob: 55250e74f271e18cb0dfdfb00f1c1c3ec37489c3
- van-sales.html current blob: 8d61382a8e0025a0d079e71dd94f33d106d9088e

### Session result
- Previous parser regression is CLOSED in current HEAD; do not repeat parser surgery.
- Current proven branch-search defect: App.pickArr(wsFrom) returns vehicles only for DirectReturn and lacks the normal fallback return of all company branches.
- Current proven scalability defect: loadRefs() performs unpaginated reference SELECTs. This can truncate large branch/vehicle/supplier/rep/purchase-order directories under Supabase's default 1000-row response ceiling.
- Surgical owner patch prepared in Report313; no modification was made to main.html, vouchers.html, or van-sales.html by the system.
- Production backend was intentionally not changed because the current defect is in frontend reference loading/selection, not in the central stock contract.
- Persistent QA records IN-23..IN-27 remain in Production and were not deleted.
- QA inventory movements for IN-23..IN-27 remain 0.
- Static JS parse of current vouchers.html = PASS.
- Patched-script syntax test = PASS.
- Synthetic scale test = PASS: 150 branches, 1,205 vehicles, 1,200 suppliers, 10,005 reps using 500-row pagination.
- Authenticated real-browser E2E remains OPEN and must not be labeled PASS without a real authenticated browser run.

### Production snapshot for this session
- companies = 1
- branches = 4
- active_branches = 4
- vehicles = 2
- active_vehicles = 2
- suppliers = 1
- active_suppliers = 1
- direct_reps = 1
- stock_vouchers = 27
- stock_voucher_details = 29
- inventory_log = 26
- audit_log = 695

### Owner action
Apply only PATCH-313-01, PATCH-313-02, PATCH-313-03 from:
doc/Draft/Reprots/Report313_WAREHOUSE_VOUCHERS_SMART_SEARCH_FORENSIC_SCALABILITY_CLOSURE_20260922.md
to:
companies/company-1/warehouse/vouchers.html

Do not modify main.html or van-sales.html.

### Next-session sequence
CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → DEPLOYMENT EVIDENCE → owner patch verification → authenticated browser E2E → fresh Production snapshot → final closure report.

---

# CURRENT STATE — AUTHORITATIVE FORENSIC CHECKPOINT — 2026-09-22

## 1. Authoritative sources