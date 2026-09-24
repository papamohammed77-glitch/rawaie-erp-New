# EXECUTION LOG — 2026-09-24
## Warehouse Vouchers Draft Update Duplicate Guard Closure

Truth hierarchy:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

### Evidence collected
- Report329 and Report330 reviewed as historical context.
- Current vouchers.html fetched from current Mother repository.
- Current Mother commit verified: 53b254de274af504022d0acf13becc40378bd4aa.
- Parent verified: 80e42653a4a83874ab739b8a87e7ddc4f407e6e4.
- Current vouchers blob: 287f9900efdf1ee595f6537e9d230ef06e347c06.
- Full inline JavaScript parse: PASS.
- Current create-stock-voucher Edge: Version 12, ACTIVE.
- Current Production UPDATE RPC inspected directly.

### Defect proven
Production duplicate guard used:
jsonb_to_recordset(p_items) AS x(itemCode text)

PostgreSQL normalizes unquoted itemCode to itemcode.
Current JSON payload uses itemCode.
The guard therefore grouped NULL values and rejected any multi-line update as duplicate.

### Production changes executed
1. Migration 20260924113537:
   fix_manual_voucher_update_itemcode_duplicate_guard
   Changed only duplicate guard to use jsonb_array_elements(p_items) and z.value->>'itemCode'.

2. Migration 20260924113616:
   add_stock_voucher_detail_unique_item_guard
   Added UNIQUE(voucher_id,item_id) after verifying existing duplicate count = 0.

### Test evidence
Positive:
- Production user: vouchers@rawaea.com
- five unique items: 1001,1003,1004,1005,1006
- UPDATE RPC succeeded.
- detail_rows = 5
- distinct_items = 5
- transaction rolled back.

Negative:
- temporary transaction submitted two 1001 rows.
- UPDATE RPC rejected with:
  لا يجوز تكرار الصنف داخل نفس الإذن
- transaction rolled back.

### Data repair
Current Production contained QA vouchers:
IN-1 and IN-2.
IN-1 had five TransferOut movements and had no Order/Runsheet references.
The five movements were reversed through post_stock_movement / InventoryIncrease.
IN-1 and IN-2 were removed using the official voucher delete capability.
Audit repair record inserted with approved action delete.

Cleanup result:
voucher residue = 0
QA inventory_log residue = 0
linked operation residue = 0
duplicate detail keys = 0

### Production snapshot after closure
companies = 1
branches = 4
items = 16
stock_vouchers = 0
stock_voucher_details = 0
stock_voucher_operations = 13
inventory_log = 11
stock_branches = 48
audit_log = 2171

BR-01 repaired stock:
1001=12
1003=11
1004=12
1005=11
1006=13

### Source / file policy
- vouchers.html was NOT modified.
- main.html was NOT modified.
- No Edge Function was created.
- No new table was created.
- Production movement remained centralized through post_stock_movement.

### Canonical Git documentation
Commit 1674614e50e4790ffb6d06bed4e2b09394a1d972:
supabase/migrations/20260924_fix_manual_voucher_update_itemcode_duplicate_guard.sql

Commit 86e87aeb8cc4d5fcab3b3b19b238c47f441fbbe1:
supabase/migrations/20260924_add_stock_voucher_detail_unique_item_guard.sql

Report:
doc/Draft/Reprots/Report331_WAREHOUSE_VOUCHERS_DRAFT_UPDATE_DUPLICATE_GUARD_FORENSIC_CLOSURE_20260924.md
Commit: bf43432089ba2b512c237e22550a6fa31b3fd5a6

### Open boundary
Authenticated browser E2E remains unverified because no authenticated browser execution surface was available.
Do not convert RPC/static E2E into Browser E2E.

### Next exact action
Use CURRENT_STATE plus this log to resume.
Do not repeat the Production fix.
Do not modify vouchers.html or main.html for this incident.
