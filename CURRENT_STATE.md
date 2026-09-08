# RAWAEA ERP — CURRENT STATE PACK

## Checkpoint — 2026-09-08

### 1. Governance
العمل محكوم بمبادئ Engineering Governance المثبتة في ملفات MASTER وتقارير المراجعة:
- Production الحالية هي المرجع التنفيذي.
- لا تعديل قبل فهم التاريخ والعقد والسلوك الحالي.
- UNKNOWN لا يساوي BUG ولا يبرر الحذف.
- يتم العمل بوحدات Closure منفصلة، ولا ينتقل العمل إلى الوحدة التالية قبل إغلاق السابقة.
- Physical Stock Contract:
  `Physical Stock Movement -> post_stock_movement -> stock_branches + inventory_log`
- `reserve_stock` / `release_stock_reservation` مسؤولية Reservation فقط.
- ملفات `Current/PWA/main2/main1..main11` هي Source of Truth للعمل اليدوي على الأجزاء الأم.
- `Current/PWA/main/*` مرحلة مختلفة/تاريخية ولا تُستخدم كمصدر assembly canonical.
- `Current/PWA/New-main` ناتج تجميع generated target وليس مصدرًا يدويًا مستقلًا.

### 2. Current Git Reality
Repository: `papamohammed77-glitch/rawaie-erp-New`
Branch: `main`
Current latest session commits include:
- `97968baccaa20f42888506b1bc0e1fb5bd1c278d` — reconstruction tool pointed to `Current/PWA/main2`.
- `cd1f022d945ca62bb7668afe78027ea6d7bdcb52` — forensic assembly workflow pointed to `Current/PWA/main2`.
- `27740512c1da8531869e0a31cc6cee1575c25635` — controlled assembly execution trigger.
- `a707f55afd76b8c9d23ebaca8de06f0cb5a0bad9` — Report86 forensic status and closure record.

### 3. Main2 fragments
المصدر الجاري العمل عليه يدويًا بواسطة المالك هو:
`Current/PWA/main2/main1.md ... main11.md`

Current fragment identities recorded before this session remain:
- main1: `4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade`
- main2: `58dd0da232ccca4c62bc17d87220bf8b705d85e8`
- main3: `479060e3d4bea5e2203c87f822b1dbc0e2f7d456`
- main4: `e89d29e4164c68784c109292f27d4d77df240557`
- main5: `c4518d05ada50830e819563a55169843679d3e94`
- main6: `3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`
- main7: `6f7aef60ac137cd7f6b74281a17835dbd29595be`
- main8: `20f77481133d3e55ced949de16f88dadb0a69980`
- main9: `288b642d050f8b5ddeb6d43a7fd2a992fb05bb03`
- main10: `d57cef3bd7e42f7ba7ddc90bde81bdbabd5579a1`
- main11: `cad8bafa94da839ffb3a61f1a4581f52b98289f4`

### 4. Main6 Closure
Target: `Current/PWA/main2/main6.md`
Current blob at last verified source checkpoint: `3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`

Report84 surgeries M6-01..M6-09 were verified in the actual current source:
- Online Store settings company-scoped.
- Track Order company-scoped and uses `order_details.order_id`.
- Purchase Orders list company-scoped.
- Open Receive company-scoped and guards PO before details.
- Suppliers company-scoped.
- Purchase refresh company-scoped.
- Receive dialog uses remaining quantity.
- Track Order item name escaped.
- savePO explicitly guards missing session token.

Main6 EOF was inspected; the `RW_OnlineStore` and `RW_Purchases` closures are intact.

### 5. Report85 -> Report86 reconciliation
Report85 established the main2/main assembly source conflict.
Report86 continued from that point and performed a fresh Production reconciliation plus Main7 forensic review.

### 6. Production Reality — 2026-09-08
Supabase project: `fiilmooggumokxanwiyx`

Production checkpoint taken directly before the current execution:
- timestamp: `2026-09-08 06:12:44.498422+00`
- companies: 1
- branches: 2
- users: 24
- items: 17
- stock_branches: 20
- orders: 0
- order_details: 0
- purchase_orders: 0
- purchase_order_details: 0
- stock_vouchers: 0
- inventory_log: 3

No persistent operational Order/PO/Stock Voucher fixture was present, so no permanent business-flow fixture was created.

### 7. Production Inventory Core Closure
A fresh PostgreSQL writer scan was performed.

Result:
`direct_physical_writers_outside_allowed = 0`

Allowed responsibilities confirmed:
- `post_stock_movement` — Physical Stock Engine.
- `reserve_stock` / `release_stock_reservation` — Reservation only.
- `setup_van_stock` / `create_vehicle_atomic` — stock-row initialization, not operational movement.
- `complete_runsheet_picking` changes fulfillment/reservation and does not independently mutate `stock_branches.qty`.

Legacy executable capabilities were explicitly closed with Production migration:
`revoke_legacy_inventory_core_execution_20260908`

Revoked from `service_role` and other roles:
- `post_manual_stock_voucher_atomic_core_20260828`
- `send_stock_voucher_atomic_core_20260828`

The legacy definitions were not deleted; history remains available.

### 8. Current Production return/delivery contracts
- `complete-return` Production v25 authenticates the user, derives company from `users.auth_id`, and calls `complete_return_atomic`.
- `complete_return_atomic` performs physical return through `post_stock_movement`.
- `complete-order-delivery` Production v14 calls `complete_order_delivery_atomic` for one order and its item quantities.
- `complete_order_delivery_atomic` uses `erp_operation_registry` for idempotent order-delivery operations and does not mutate physical stock.
- `complete-delivery` Production v4 transitions the runsheet from `Delivering` to `Delivered` and handles meter/tracking state; it does not consume `ordersData` as a fulfillment writer.

### 9. Assembly Source-of-Truth correction
The reconstruction tool was changed from:
`Current/PWA/main/`
to:
`Current/PWA/main2/`

The forensic assembly workflow was also changed to:
- trigger on `Current/PWA/main2/**`;
- assert main2 fragments exist;
- audit main2 fragments against `Original/PWA/main/*` as historical evidence;
- record `Current/PWA/main2` as canonical editable source;
- record `Current/PWA/New-main` as generated target.

This is now the configured source path in Git.

### 10. Assembly verification status
A controlled execution commit `27740512c1da8531869e0a31cc6cee1575c25635` was pushed with `[CTO_EXECUTE_P163]`.

A historical one-shot workflow named:
`CTO Single Controlled New-main UX 2026-09-03`
was also triggered by the push and reported:
- run: `34193895898`
- conclusion: `failure`
- jobs API returned `total_count: 0`

No causal root cause was inferred from this evidence.

Therefore:
`MAIN2 RECONSTRUCTION SOURCE PATH = CLOSED`
`FULL MAIN2 ASSEMBLY = OPEN / NOT PROVEN`

### 11. Main7 Forensic Status
Target:
`Current/PWA/main2/main7.md`

Current blob:
`6f7aef60ac137cd7f6b74281a17835dbd29595be`

The source was read directly and its current end-of-file closure is structurally intact:
`})();`
followed by:
`window.RW_Warehouse = RW_Warehouse;`

The following defects are proven and remain OPEN in Main7 source:
- M7-00: exact settlement syntax repair still needs source-side confirmation: `.join(''));}` -> `.join('')));}`.
- M7-01: `loadReceiving()` lacks `company_id` scope.
- M7-02: receiving details flow should validate the receiving record in current company context before loading details.
- M7-03: driver lookup for DirectSale/DirectReturn lacks company scope.
- M7-04: `loadVouchers()` lacks `company_id` scope.
- M7-05: voucher details are queried by `voucher_code` directly although voucher uniqueness is `(company_id, voucher_code)`; source should resolve voucher by company then query details by `voucher_id`.
- M7-06: `_receiveVoucher()` does not send an operation identity / `Idempotency-Key` and currently defaults to full sent quantity rather than explicitly limiting entry to remaining quantity.
- M7-07: `_openNewVoucherModal()` attempts to create an empty voucher with `items: []`, contrary to the canonical create contract that requires at least one item; modal should open the existing itemized voucher form instead.
- M7-08: Picking/Loading/Delivery/Return list views use stale lifecycle states (`Picked`, `Loaded`, `Delivered`, `Returned`) instead of the verified active-stage states (`Picking`, `Loading`, `Delivering`, `Returning`).
- M7-09: `_openDeliveryModal()` builds delivery quantities from all runsheet items for every order and calls `complete-delivery` with `ordersData`, while current Production fulfillment is order-specific through `complete-order-delivery`; this is a real semantic defect.
- M7-10: settlement `countedQty` remains hardcoded to zero; authoritative inventory-count linkage is not yet sufficiently proven to prescribe final source surgery.
- M7-11: `_showUnloadingDetails()` is explicitly placeholder behavior; no new business behavior will be invented before contract proof.

### 12. Main7 ownership rule
The assistant must NOT modify `Current/PWA/main2/main7.md`.
The owner performs the source surgery manually.
Production and governance files may be corrected by the assistant when proven necessary.

### 13. Reports
Latest session report:
`doc/Draft/Reprots/Report86_Main7_Forensic_Surgery_and_Main2_Assembly_Path_20260908.md`

Previous:
`doc/Draft/Reprots/Report85_Main6_Recheck_and_Assembly_Boundary_20260908.md`

Previous reports are preserved and must not be deleted.

### 14. Next controlled action
Before full parent assembly can become Gold/Diamond:
1. Owner applies exact M7-00..M7-09 source surgeries to `Current/PWA/main2/main7.md`.
2. Re-read Main7 SOF->EOF and verify structural balance.
3. Run the canonical reconstruction from `Current/PWA/main2/main1..main11`.
4. Pass static/source gates, Node syntax, and browser smoke.
5. Verify resulting Parent against current Production contracts.
6. Deploy only after evidence supports it, then perform Production runtime verification.

### 15. Closure statement
`PRODUCTION INVENTORY WRITER CORE = CLOSED`
`LEGACY INVENTORY CORE EXECUTION = CLOSED`
`MAIN2 RECONSTRUCTION SOURCE PATH = CLOSED`
`MAIN6 SOURCE SURGERY = CLOSED`
`MAIN7 SOURCE SURGERY = OPEN / OWNER ACTION REQUIRED`
`FULL MAIN2 ASSEMBLY = OPEN / CI VERIFICATION FAILED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
