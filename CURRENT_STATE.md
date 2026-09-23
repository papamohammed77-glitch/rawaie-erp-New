# RAWAEA ERP — CURRENT STATE
## Authoritative Forensic Checkpoint — 2026-09-23

Canonical report: doc/Draft/Reprots/Report316_WAREHOUSE_VOUCHERS_FORENSIC_SURGICAL_CLOSURE_20260923.md

### Git
- System HEAD before this state update: 2f676b5a7d4af08fbeb978b3d1b8a59ea8acd969
- Parent: 165adb8304a5d39d8747a347211ae0939b189af1
- Frontend HEAD: 2da3d6d9ae6b3e84ea0920998ecdefa94ed4d8e3
- Frontend parent: 751f6175675ffe99023337e523501bd35e9553c6
- vouchers.html blob: 62cbca833be1a6b4885d6522ca15cdd8b7b2e04c
- van-sales.html blob: 8d61382a8e0025a0d079e71dd94f33d106d9088e

### Production final snapshot
- companies=1
- branches=1354
- active_branches=1352
- vehicles=1202
- active_vehicles=1200
- direct_sales_reps=10001
- suppliers_total=501
- suppliers_active=500
- stock_vouchers=42
- inventory_log=45
- audit_log=3950
- active_legacy_qa_drafts=0

### Persistent QA
IN-38 Transfer Completed
IN-39 DirectSale Completed
IN-40 DirectReturn Completed
IN-41 SupplierReturn Completed
IN-42 Transfer Reverse Completed

### Production E2E
- Transfer Create -> Send -> Receive -> Complete PASS
- Transfer reverse PASS
- DirectSale Create -> Send -> Complete PASS
- DirectReturn Create -> Send -> Receive -> Complete PASS
- DirectReturn same operation_id replay returned duplicate=true with no second movement PASS
- SupplierReturn Create -> Send -> Complete plus journal and supplier ledger PASS

### Safe cleanup
18 old pre-IN-32 QA/DEMO Draft records with zero inventory movement were moved to Cancelled.
Physical DELETE was not bypassed because guard_stock_voucher_delete_integrity() forbids deletion of stock documents.
Historical movement-bearing records remain.

### Closed surfaces — do not repeat
loadRefs pagination
norm
vehicleBranch
allowedBranch Transfer authorization
pickSelect vehicle -> rep auto-binding
central Physical Stock routing
DirectReturn SEND backend capability
van-sales integration path

### Current source defects
File: companies/company-1/warehouse/vouchers.html
App.pickArr(key), around line 1811:
- DirectSale vehicle picker requires Rep first.
- DirectReturn warehouse vehicle candidates are over-filtered.
- non-Transfer source branch candidates are too broad.
- Transfer includes inactive branches.

App.pickSearch(key,q), around line 1905:
- unauthorized branch rows can occupy the first 15 results before filtering.

### Owner patch
Apply only PATCH-316-01 and PATCH-316-02 from Report316 to companies/company-1/warehouse/vouchers.html.

Do not modify:
main.html
van-sales.html
loadRefs()
norm()
vehicleBranch()
allowedBranch()
pickSelect()
routeHtml()
submit()
prepare()

### Backend
No new Edge Function.
No new RPC.
No new table.
No RLS change.
No Physical Stock engine change.
Only safe QA cleanup and E2E data execution occurred in this session.

### Closure
Production backend voucher lifecycle = CLOSED / E2E VERIFIED
Production QA cleanup = CLOSED
Frontend forensic root cause = PROVEN
Frontend surgical patch = READY FOR OWNER
Published artifact identity = OPEN
Authenticated browser E2E = OPEN

### Next session exact sequence
1. Verify frontend HEAD and vouchers.html blob.
2. Apply PATCH-316-01 and PATCH-316-02 only.
3. Static parse.
4. Verify candidate counts on current Production scale.
5. Publish frontend.
6. Verify served artifact identity.
7. Run authenticated browser E2E for Transfer, DirectSale, DirectReturn, SupplierReturn.
8. Verify Draft creation has zero Physical Stock movements.
9. Capture fresh Production snapshot in the same reporting window.
10. Close browser/published-artifact status only after those proofs.

### Governance
Reports are historical clues only.
Current truth is CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
