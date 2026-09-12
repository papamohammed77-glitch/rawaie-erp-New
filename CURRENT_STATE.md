# RAWAEA ERP — CURRENT STATE

**Last updated:** 2026-09-12
**Current checkpoint:** Main7 forensic recheck completed; owner surgical replacements prepared; Main7 source itself not edited by the assistant.

## Governing Rules

- Production is a first-class source of truth and must be rechecked at the time of every report.
- Reports are evidence, not truth.
- `NO EVIDENCE = NO CLAIM`.
- `NO FUNCTIONAL TEST = NO FUNCTIONAL VERIFICATION`.
- `NO PRODUCTION CHECK = NO PRODUCTION VERIFICATION`.
- `NO CROSS-MODULE TRACE = NO BUSINESS COMPLETION`.
- `NO DATA CHECK = NO DATA CLOSURE`.
- Study/history reconstruction precedes surgical change.
- Owner edits the `Current/PWA/main2/main1..main11.md` source fragments; assistant performs Production DB/Edge/data verification and changes when a proven Production gap exists.
- Assembly remains deferred until all eleven fragments are owner-verified.

## Gold/Diamond Mission

هناك نقص شديد في كل التبويبات ، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا تتعامل معه كإضافات شكلية.
وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.

## Source of Truth

- `Current/PWA/main2/main1.md`
- `Current/PWA/main2/main2.md`
- `Current/PWA/main2/main3.md`
- `Current/PWA/main2/main4.md`
- `Current/PWA/main2/main5.md`
- `Current/PWA/main2/main6.md`
- `Current/PWA/main2/main7.md`
- `Current/PWA/main2/main8.md`
- `Current/PWA/main2/main9.md`
- `Current/PWA/main2/main10.md`
- `Current/PWA/main2/main11.md`

Historical reference only:
`Original/PWA/main/*`

Forbidden/retired sources:
`Current/PWA/main/*`
`Current/PWA/New-main/*`

`forensic_main_assembly.yml` remains correctly configured for `Current/PWA/main2` with `Original/PWA/main` as historical reference and assembly deferred until all fragments are owner-verified.

## Fragment SHAs

- main1 `f68d47d7574c34f678cfba2aafa5ad294aadbfe5`
- main2 `65815e23b03e29c125957e6fe283cc1e253a7f7d`
- main3 `eeb56daf8cd01b31b8a7e5f5ada4f1a09df30bfe`
- main4 `e9f967859aeda729cd0811739a280ceec5266d7c`
- main5 `800ad51c88a2e80d060480990836a3c975c7435a`
- main6 `3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`
- main7 `a65969f6bdc919d4a8d62a6704a7c556b7d35e91` before owner changes
- main8 `2131fbf3096d926b2486acb2ab58a4266ddd1bbc`
- main9 `b9f10ae4e727cb9495aaecbe2d752dabf13ec776`
- main10 `169025a6836c7fdc7281ea86523b975a84d889f1`
- main11 `2adfc787c3e5f0ca56abfcc85232e7a971773c3b`

## Previous Checkpoint

Report125 established Main6 forensic recheck and owner replacement status. Main6 remains an owner-action checkpoint and was not superseded by any assembly.

## Main7 — 2026-09-12

Current source:
`Current/PWA/main2/main7.md`
Current SHA:
`a65969f6bdc919d4a8d62a6704a7c556b7d35e91`

Main7 was read sequentially through EOF and its historical counterpart `Original/PWA/main/main7.md` was also inspected.

### Confirmed Main7 findings

1. `loadReceiving()` displayed `itemsCount` although the authoritative count is in `receiving_details`.
2. `_saveAndSendVoucher()` did not send `operation_id`, despite Production supporting idempotent voucher creation.
3. `loadUnloading()` listed `Open/New`, while Production unloading requires `Loaded`.
4. `_showUnloadingDetails()` was an explicit `قيد التطوير` skeleton.
5. `_startBarcodeScanner()` was referenced by UI buttons but not defined/exported.
6. `_saveInvCount()` expected `voucherId`; Production returns `count_id`, and the current code always refreshed the vehicle-count panel (`vc`) even for branch/general counts.
7. `_onSettlementRsChange()` did not mirror the authoritative Production shortage formula.
8. `_saveSettlement()` did not send the required `operation_id`.
9. `_openPickingModal()` did not send the supported `operation_id` for `complete-picking` retries.

### Confirmed correct and intentionally preserved

- Main7 has no direct `stock_branches` writer.
- Main7 has no direct `inventory_log` writer.
- Physical stock remains centralized through `post_stock_movement`.
- `reserve_stock` remains a reservation engine, not a Physical Stock Movement engine.
- `loadPicking()` uses `Open/Confirmed` and matches Production.
- `loadLoading()` uses `Loaded` and matches Production.
- `_receiveVoucher()` already sends an operation identity and idempotency key; no redundant rewrite.
- Order-by-order delivery flow is preserved.
- Inventory counts remain count/snapshot records; no conversion to a direct stock-adjustment writer.

## Production Verification Snapshot

Verified against Production during this checkpoint:

- `start-picking` v34 ACTIVE, JWT required.
- `complete-picking` v17 ACTIVE, JWT required, supports `operation_id` and `erp_operation_registry`.
- `unload-runsheet` v6 ACTIVE, JWT required, calls `complete_runsheet_unloading`.
- `save-inventory-count` v2 ACTIVE, JWT required, returns `count_id`.
- `save-daily-settlement` v4 ACTIVE, JWT required, requires `operation_id`.
- `create-stock-voucher` v10 ACTIVE, JWT required, supports `rep_id` and `operation_id`.
- `post_daily_settlement_atomic` is the authoritative settlement calculation and uses `qty_loaded - qty_delivered - qty_returned`.
- `complete_runsheet_unloading` requires `Loaded` and routes physical movement through `post_stock_movement`.
- `complete_runsheet_picking` supports UUID `p_operation_id` and registry-based idempotency.
- `items.item_code` is globally UNIQUE in the current schema.

## Main7 Owner Change Set

Full owner-ready replacements were committed to:

- `doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Receiving_20260912.js`
- `doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_VoucherSave_20260912.js`
- `doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Unloading_20260912.js`
- `doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Inventory_20260912.js`
- `doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Settlement_20260912.js`
- `doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Picking_20260912.js`

Exact surgery is documented in:
`doc/Draft/Reprots/Report126_Main7_Forensic_Recheck_20260912.md`

### Required Owner Surgeries

- Replace `loadReceiving()` before `function _applyReceiving()`.
- Replace `_saveAndSendVoucher()` before the VOUCHERS LIST section.
- Replace `loadUnloading() + _applyUnloading() + _showUnloadingDetails()` before the COUNT/SETTLEMENT section.
- Add `_startBarcodeScanner(prefix)` immediately above `function _searchInvItem(prefix, query)`.
- Replace `_saveInvCount()` immediately before `loadBranchCount()`.
- Replace `_onSettlementRsChange()` immediately before `_saveSettlement()`.
- Replace `_saveSettlement()` immediately before `_openPickingModal()`.
- Replace `_openPickingModal()` immediately before `_openLoadingModal()`.
- Add `_startBarcodeScanner: _startBarcodeScanner,` immediately above `_searchInvItem: _searchInvItem,` in the final return object.

## Syntax Status

All six owner replacement artifacts passed `node --check` after correction of one generated HTML/onclick escaping error during preparation.

The final assembled Main7 fragment has **not** received final syntax verification because the owner must apply the surgeries to the source fragment first.

## Production Change Status

No new Production migration was required specifically by the Main7 forensic findings after current Production contracts were rechecked. Existing Production capabilities already support the needed operation identities and centralized movement contracts.

## Closure Status

```text
MAIN7 FORENSIC READ = PASS
MAIN7 HISTORICAL TRACE = PASS
MAIN7 PRODUCTION CONTRACT TRACE = PASS
MAIN7 RELATED APP TRACE = PASS
MAIN7 DIRECT PHYSICAL WRITERS = 0
MAIN7 SURGICAL REPLACEMENTS = PREPARED
MAIN7 REPLACEMENT SYNTAX = PASS
MAIN7 OWNER SOURCE APPLY = PENDING
MAIN7 FINAL SOURCE SYNTAX = PENDING
MAIN7 RUNTIME E2E = PENDING
MAIN7 GOLD/DIAMOND = NOT CLOSED
ASSEMBLY = DEFERRED
```

## Next Session Gate

After owner applies the Main7 changes:

1. Re-read Main7 from first character through EOF.
2. Compute new SHA.
3. Run syntax validation on the complete Main7.
4. Check duplicate declarations and delimiter balance.
5. Verify Main6/Main7/Main8 interfaces and shared contracts.
6. Run authenticated E2E for Picking, Unloading, Inventory Count, Settlement, and Voucher Create/Send.
7. Repeat retry/idempotency tests.
8. Re-sync Production immediately before the final report.
9. Only then declare Main7 closed and continue toward assembly.

Historical detailed evidence remains in `Report125_Main6_Forensic_Recheck_20260912.md` and `Report126_Main7_Forensic_Recheck_20260912.md`.