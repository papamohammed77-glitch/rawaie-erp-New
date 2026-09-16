# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-16 — current Git / current Mother source / current Production / current Database / current Deployment evidence were rechecked for the Inventory Forensic / Daftra Gap Closure. Historical reports remain reference-only.

## SOURCE OF TRUTH

Historical reports are reference-only. They are not current state.

The governing truth is:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

Full Browser/System E2E additionally requires:
`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

**Mother System Source of Truth:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical fragments only:
`Current/PWA/main2/*`
`Original/PWA/main/*`
`New-main`

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`

Current HEAD:
`b673fa4c7b29d2ea6118aaf5c38a8bc2e1187af2`

HEAD message:
`Expand mother inventory forensic source mapping`

Direct parent:
`9d8fa07215d5e84f5672abb8b36c218de87559eb`

The current HEAD modifies only the forensic E2E workflow; it does not modify the Mother HTML.

Earlier Mother-related code commit verified during this closure:
`cff8399547277eb1db83fbd0ce809837471f2b64`
`Refactor purchase functions and realtime channel setup`

Current Mother blob read from Git:
`1e496d643d588bb2e92ea14cb8876cd9837b3e6b`

## CURRENT MOTHER

Current Mother source:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

The assistant did **not** modify Mother HTML during this Inventory closure.

Current inventory menu anchor proven in the tested source:
`line 1145`

Current inventory dispatcher anchors proven in the tested source:

`20953` → picking → `RW_Warehouse.loadPicking()`
`20954` → loading → `RW_Warehouse.loadLoading()`
`20955` → delivery → `RW_Warehouse.loadDelivery()`
`20956` → return → `RW_Warehouse.loadReturn()`
`20961` → unloading → `RW_Warehouse.loadUnloading()`
`20962` → receiving → `RW_Warehouse.loadReceiving()`
`20963` → vouchers → `RW_Warehouse.loadVouchers()`
`20964` → transfer → `RW_Warehouse.loadVoucherForm('Transfer')`
`20965` → direct-sale → `RW_Warehouse.loadVoucherForm('DirectSale')`
`20966` → direct-return → `RW_Warehouse.loadVoucherForm('DirectReturn')`
`20967` → supplier-return → `RW_Warehouse.loadVoucherForm('SupplierReturn')`
`20968` → vehicle-count → `RW_Warehouse.loadVehicleCount()`
`20969` → branch-count → `RW_Warehouse.loadBranchCount()`
`20970` → general-count → `RW_Warehouse.loadGeneralCount()`
`20971` → settlement → `RW_Warehouse.loadSettlement()`

No placeholder marker was found by the current static E2E check for:
`قيد التطوير / جاري التطوير / TODO / FIXME`

## CURRENT BROWSER E2E — MOTHER

Workflow:
`.github/workflows/inventory_mother_forensic_e2e_20260916.yml`

Run:
`35058149973`

Job:
`104672563318`

Result:
`SUCCESS`

Proven:
- inventory contract static audit = PASS
- source map = PASS
- browser load = PASS
- Console errors = 0
- Page errors = 0
- Mother Browser Smoke = PASS

This is still a Browser Smoke, not full authenticated business E2E against Production.

## FORENSIC ASSEMBLY GUARD

Created in `erp-frontend`:
`.github/workflows/forensic_main_assembly.yml`

Purpose:
protect the canonical Mother Source of Truth path:
`companies/company-1/main.html`

`Current/PWA/main2/*` remains historical/reference-only and is not treated as Source of Truth.

## CURRENT PRODUCTION

Supabase project:
`fiilmooggumokxanwiyx`

Current live Company evidence was rechecked directly. Historical reports that listed additional companies were not used as current state.

## INVENTORY CONTROL PRODUCTION — 2026-09-16

### Central Physical Stock Contract

```text
PHYSICAL MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

`reserve_stock` and `release_stock_reservation` remain reservation-only engines.

No independent Physical Stock Writer was found in the current Production function scan outside setup/bootstrap behavior.

### Inventory Read/Intelligence

Deployed and verified:

`inventory_stock_snapshot(...)`
`inventory_replenishment_report(...)`
`inventory_movement_report(...)`

These are Company/Actor scoped and use current stock/inventory_log data.

Low-stock semantics require `reorder_point > 0`.

Recommended replenishment uses `max_qty` when it is a meaningful target above reorder point; otherwise reorder point is used as the minimum safe replenishment target.

### Inventory Count Engine

Deployed and verified:

`inventory_count_engine(...)`

Operations:
`CREATE`
`GET`
`POPULATE`
`UPSERT_LINE`
`REFRESH`
`FINALIZE`
`CANCEL`

`counted_qty` has no default so an uncounted item cannot silently become zero.

Identity:
`count_id + branch_id + item_id`

Physical variance adjustment always calls:
`post_stock_movement`

`stock_discrepancies` was intentionally not reused for general inventory count variances because its current contract belongs to runsheet discrepancy handling.

### Stock Request Engine

Created and verified:

`inventory_stock_requests`
`inventory_stock_request_details`

Engine:
`inventory_stock_request_engine(...)`

Operations:
`CREATE`
`GET`
`APPROVE`
`REJECT`
`CONVERT`
`CANCEL`

Conversion creates a stock voucher; it does not mutate physical stock by itself.

### Existing Edge Gateway

A new Edge Function was initially attempted but Production rejected the creation because the project reached its Edge Function capacity limit.

The correct infrastructure decision was to reuse:
`save-inventory-count`

Current gateway deployment:
`save-inventory-count` — active — verify_jwt=true

It now exposes:

`COUNT_*`
`REQUEST_*`
`SNAPSHOT`
`MOVEMENTS`
`REPLENISHMENT`

while preserving the previous count request compatibility path.

### Realtime

Relevant inventory tables were added to the current realtime publication:

`inventory_log`
`inventory_counts`
`inventory_count_details`
`stock_discrepancies`

## INVENTORY PRODUCTION E2E RESULTS

### Snapshot

PASS for current Company and active warehouse actor.

### Count

Transactional E2E verified:

`CREATE`
→ `UPSERT_LINE`
→ `FINALIZE`

The test checked stock delta and inventory log creation, then rolled back.

### Stock Request

Transactional E2E verified:

`CREATE`
→ `APPROVE`
→ `CONVERT`

The test confirmed conversion itself did not create an inventory movement, then rolled back.

### Data pollution check

After transactional tests:

`inventory_counts = 0`
`inventory_count_details = 0`
`inventory_stock_requests = 0`
`inventory_stock_request_details = 0`

No test fixture was intentionally left in Production.

Production snapshot used for final state:
`2026-09-16 05:07:19.211078+00`

## CURRENT FORENSIC REPORTS

Latest relevant reports now include:

`doc/Draft/Reprots/Report204_PURCHASE_MODAL_CURRENT_CLOSURE_20260915.md`
`doc/Draft/Reprots/Report205`
`doc/Draft/Reprots/Report206_SALES_DECISION_RLS_SECURITY_CLOSURE_20260916.md`
`doc/Draft/Reprots/Report207_INVENTORY_FORENSIC_DAFTRA_GAP_CLOSURE_20260916.md`

Reports remain historical evidence only.

## REQUIRED METHOD FOR NEXT SESSION

1. Re-read this file first.
2. Re-open current Git HEAD and direct parent.
3. Re-open current Mother source and read the exact target block.
4. Re-read the current Mother blob SHA before any patch.
5. Take a fresh Production snapshot at the same time as the work.
6. Do not trust any older report as current state.
7. Do not recreate already-verified Production inventory engines.
8. Continue from the open checkpoint: Mother Consumer Integration of the new inventory capabilities.
9. Keep all field-execution flows intact: picking, loading, delivery, return, unloading, runsheets and settlement.
10. Any physical stock mutation must remain under `post_stock_movement`.
11. Any Owner-only Mother change must be supplied as an exact full surgical block with start/end anchors and current line numbers.
12. After Owner merge, re-read current Git/blob again before E2E.
13. Capture Browser + Console + Network + DB + Realtime evidence.
14. Do not declare Gold/Diamond before all critical evidence is current.

## CURRENT CLOSURE STATUS

```text
Current Git / Parent                         VERIFIED
Current Mother source                        VERIFIED
Current Mother blob                          VERIFIED
Mother HTML modified by assistant            NO
Mother Browser Smoke                         PASS
Mother Console errors                        0 in smoke
Mother PageErrors                            0 in smoke
Inventory physical writer centralization     VERIFIED
Inventory read/intelligence engine           DEPLOYED + VERIFIED
Inventory count engine                       DEPLOYED + VERIFIED
Inventory stock request engine               DEPLOYED + VERIFIED
Inventory realtime publication               DEPLOYED
Inventory Edge gateway                       DEPLOYED + VERIFIED
Forensic Mother E2E workflow                 ACTIVE + PASS
Forensic Mother assembly guard               CREATED
Full authenticated inventory E2E             OPEN
Mother → inventory capability integration    OPEN
Daftra-level functional inventory completion OPEN
Gold/Diamond Inventory UI                    OPEN
Next Closure Unit                            MOTHER CONSUMER INTEGRATION
```

## SELF-AUDIT — 2026-09-16 INVENTORY FORENSIC CLOSURE

### What I proved

- Current Git was rechecked, including the direct parent.
- Current Mother source was directly inspected.
- Mother was not modified by the assistant.
- Current Mother inventory menu/dispatcher anchors were verified.
- Current Mother Browser Smoke passed with zero Console/Page errors.
- Current Production inventory schema and physical stock contract were inspected.
- Physical stock has one central mutation engine: `post_stock_movement`.
- Inventory snapshot/replenishment/movement capabilities exist in Production.
- Inventory counting has a controlled lifecycle and physical adjustment through the central movement engine.
- Stock request workflow has a controlled lifecycle separated from physical movement.
- Realtime publication was extended for inventory control.
- A new Edge Function was not created because capacity was exhausted; an existing gateway was reused instead.
- Transactional tests left no test data behind.

### What I did not prove

- Full authenticated E2E of every warehouse subtab inside the Mother.
- Production Network evidence for every Mother inventory action.
- Mother UI integration with the newly deployed Inventory Intelligence / Count / Request engines.
- Complete Daftra-equivalent inventory feature parity including every reporting/export/import surface.
- Final Gold/Diamond closure of the Mother Inventory UI.

### What was initially missed and corrected

- Uncounted inventory lines could be interpreted as zero because of an unsuitable default.
- A partial unique index was not compatible with the required UPSERT identity.
- Historical fixture branch data was not valid current Production evidence.
- Edge Function capacity prevented adding a new gateway, so an existing appropriate function was reused.

### What could still be wrong

- The Mother `RW_Warehouse` consumer paths may still use legacy read/write patterns until explicitly reconnected to the new capability layer.
- `receive-purchase` still requires a stable client operation identity from the Mother for complete retry semantics.
- Field-operation closures such as complete return and complete order delivery remain separate Writer Closure Units.

## NEXT EXACT CHECKPOINT

```text
Fresh current Git/blob verification
→ open full RW_Warehouse block
→ map each inventory tab to current capability API
→ prepare exact Owner-only surgical replacements
→ Owner merge
→ fresh browser/console/network
→ Production DB + realtime verification
→ close Mother Inventory capability integration
```
