# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-12 — MAIN6 FORENSIC RECHECK

### GOVERNING TARGET — NON-NEGOTIABLE
هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع ولا يُتعامل معه كإضافات شكلية.

**ويجب تكرار الهدف صراحة:** المطلوب استكمال التبويبات والوظائف **وظيفيًا** وليس شكليًا فقط، والوصول بها إلى مستوى منافس حقيقي للأنظمة العالمية، مع احترام دورة العمل التاريخية والعمليات الميدانية الخاصة بالروائع.

الحوكمة الحاكمة: الدراسة أولًا → إعادة بناء العقد التاريخي → تتبع السلوك الحالي → تتبع البيانات والصلاحيات والتدفق → تحديد الفجوة الفعلية → التعديل الجراحي → الاختبار → التحقق من Production → التوثيق.

## SOURCE-OF-TRUTH GOVERNANCE
- Production الحالية هي حقيقة التنفيذ.
- Git هو المصدر القانوني القابل لإعادة الإنتاج، وليس بديلًا عن Production.
- التقارير التاريخية أدلة جنائية وليست حقيقة حالية.
- Source of Truth التحريري للملف الأم: `Current/PWA/main2/main1.md ... main11.md`.
- `Original/PWA/main/*` مرجع تاريخي فقط.
- `Current/PWA/New-main` مرحلة تاريخية موقوفة وليست مصدر مراجعة حالي.
- `forensic_main_assembly.yml` يتبع `Current/PWA/main2` ولا يجب أن يعود إلى `Current/PWA/main`.
- Final assembly remains deferred until all owner fragment work and final integrated validation are complete.

## PREVIOUS CHECKPOINTS
- Report121: `doc/Draft/Reprots/Report121_Main2_Forensic_Recheck_20260911.md`.
- Report122: `doc/Draft/Reprots/Report122_Main3_Forensic_Recheck_20260911.md`.
- Report123: `doc/Draft/Reprots/Report123_Main4_Forensic_Recheck_20260912.md`.
- Report124: `doc/Draft/Reprots/Report124_Main5_Forensic_Recheck_20260912.md`.
- Main3 owner surgeries remain open until applied and reverified.
- Main4 owner surgeries remain open until applied and reverified.

## MAIN5 — FORENSIC RESULT
Current source of truth: `Current/PWA/main2/main5.md`.
**Current blob SHA verified from the canonical main2 directory:** `800ad51c88a2e80d060480990836a3c975c7435a`.
EOF previously verified in Report124; Main5 remains owner-action pending.

### MAIN5 FUNCTIONAL AREAS
- `RW_Orders` — sales order listing, filtering, confirmation, deletion, details, printing, runsheet creation/append, refresh and realtime.
- `RW_Runsheets` — runsheet listing, filtering, driver/vehicle assignment, details, delete/cancel, status capability, printing and realtime.

### MAIN5 HISTORICAL CONTRACT
`Original/PWA/main/main5.md` was opened as historical reference only. The core historical responsibility remains the Orders → Runsheets operational axis. Current source was not replaced merely because the historical file differs.

## MAIN5 PRODUCTION CLOSURE — APPEND RUNSHEET
A real Production defect was proven in the previous `append-to-runsheet` implementation: it performed multiple independent writes to `run_sheet_details`, `orders`, and `runsheets.total_amount`, leaving a Partial-Success window.

### Executed Production fix
- New RPC: `public.append_orders_to_runsheet_atomic(uuid,text,text[],text)`.
- Transactional locking and company-scoped validation are centralized in the RPC.
- Item identity is checked against the current Global Item Master contract.
- Orders, derived runsheet details and runsheet total are changed in one transaction.
- Retry of the same already-linked append returns `duplicate=true` and does not add quantity or value again.
- `append-to-runsheet` Edge Function is now a thin capability wrapper.
- Production Edge version: `v8`, ACTIVE, JWT required.
- Production deployment SHA: `1225b25e21f36c94aa60ce6afacb3933d62e8f3f12f853466ca1fe448c0aa23c`.

### Runtime verification
Temporary test records were created inside one DB transaction and rolled back.
Verified result:
- `create_runsheet_atomic` PASS.
- first append PASS.
- quantity after first append = `3.0000`.
- total after first append = `30.00`.
- identical retry returned `success=true, duplicate=true`.
- quantity after retry remained `3.0000`.
- total after retry remained `30.00`.
- no permanent test data retained.

The first test attempt failed only because the test tried to write to generated column `order_details.line_amount`; the retry used the real schema correctly and passed.

## MAIN5 PRODUCTION CONTRACTS VERIFIED
- `runsheets.driver_id` is `uuid` and references `users.id`.
- `runsheets.vehicle_id` references `vehicles.id`.
- `orders.runsheet_id` references `runsheets.id`.
- `create_runsheet_atomic` exists and remains the central Create Runsheet transaction.
- `manage_runsheet_atomic` exists and requires `p_driver_id` to be a valid active `users.id` within the same company.
- `create-runsheet` Edge v26 ACTIVE is a wrapper over `create_runsheet_atomic`.
- `confirm-order` Edge v4 ACTIVE is company-scoped and JWT-protected.

## MAIN5 PROVEN SOURCE DEFECTS — OWNER SURGERIES REQUIRED
### MAIN5-N1 — `RW_Runsheets.loadHelpers()`
Current block around lines `814–821` selects only `email,name` for drivers. It must select `id,email,name,status` so the UI can honor the Production FK contract.

### MAIN5-N2 — `RW_Runsheets._renderTable()`
Current comparison uses `driversCache[i].email === r.driver_id`. This is wrong because `r.driver_id` is `users.id` UUID.

### MAIN5-N3 — `RW_Runsheets._details()`
Current driver `<option value>` uses email. It must use `users.id` UUID and select against `rs.driver_id`.

### MAIN5-N4 — `RW_Runsheets._apply()`
Current driver filter searches raw UUID text only. It must search driver name/email/UUID using the corrected cache.

### MAIN5-N5 — `RW_Orders._applyFilters()`
Current runsheet filter searches `runsheet_id` UUID although the user enters the runsheet code. It must search `_runsheetCode`.

### MAIN5-N6 — `RW_Orders._confirm()`
Current code does not guard a missing access token before calling `confirm-order`.

### MAIN5-N7 — `RW_Orders._delete()`
Current code does not guard a missing access token before calling `delete-order`.

### MAIN5-N8 — `RW_Orders._renderTable()`
`customer_name` and `area` are emitted without the existing `esc()` helper, unlike the details path. They require output escaping.

Full exact owner replacement blocks are recorded in `Report124`.

## MAIN6 — FORENSIC RECHECK 2026-09-12
Current source: `Current/PWA/main2/main6.md`.
Current SHA: `3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`.
Current size: `29,172 bytes`.
Current EOF verified after line `439`; final source line:
`window.RW_Purchases = RW_Purchases;`

Historical source reviewed: `Original/PWA/main/main6.md`.

Main6 contains:
- `RW_OnlineStore` — online catalog/cart/order submission/tracking.
- `RW_Purchases` — purchase-order list/create and purchase receiving.

### MAIN6 PRODUCTION CONTRACTS VERIFIED
- `submit-online-order` v9 ACTIVE JWT required → `submit_online_order_atomic(..., p_operation_id uuid)`.
- `submit_online_order_atomic` uses `company_id + operation_id` as idempotent order identity.
- `save-purchase-order` v3 ACTIVE JWT required → `save_purchase_order_atomic`.
- `save_purchase_order_atomic` requires `p_supplier_id uuid` and company-scopes the supplier.
- `receive-purchase` v12 ACTIVE JWT required → `receive_purchase_atomic`.
- `receive_purchase_atomic` requires `p_operation_id uuid` and uses `receiving.operation_id` as UNIQUE operation identity.
- `items.item_code` has a global UNIQUE constraint in Production, so the current Global Item Master contract is real and not inferred.

### MAIN6 PROVEN FUNCTIONAL GAPS
1. Online order UI does not explicitly send `operation_id` / `Idempotency-Key`.
2. Online Store ignores existing `discount_percent / discount_start / discount_end` for display.
3. Online Store ignores existing `min_invoice_amount` in UI validation.
4. Online Store does not enforce `max_qty_per_order` client-side.
5. Online Store HTML output escaping is inconsistent.
6. Purchase supplier `<option>` currently uses `supplier_code`, while Production save RPC requires supplier UUID.
7. Purchase item cart currently uses `sales_price` as the initial purchase price instead of `cost_price`.
8. Purchase item search is name-only; code/barcode are excluded.
9. Purchase-order list is thin and lacks search/status filtering and detailed order view.
10. Receive screen does not expose previous received / remaining quantities clearly enough and lacks per-line reason capture.
11. Receive operation identity is generated per submit attempt instead of being an explicit stable execution identity held by the UI flow.

### MAIN6 OWNER ARTIFACTS CREATED
- `doc/Draft/Reprots/MAIN6_OWNER_REPLACEMENT_OnlineStore_20260912.js`
- `doc/Draft/Reprots/MAIN6_OWNER_REPLACEMENT_Purchases_20260912.js`

Both replacements were independently checked using `node --check` and returned `SYNTAX_OK`.

### MAIN6 EXACT OWNER SURGERIES
**MAIN6-O1**
- File: `Current/PWA/main2/main6.md`
- Delete **lines 1–269 inclusive**.
- Start marker:
`// ============================================================`
- End marker:
`window.RW_OnlineStore = RW_OnlineStore;`
- Replace the entire deleted block with:
`doc/Draft/Reprots/MAIN6_OWNER_REPLACEMENT_OnlineStore_20260912.js`

**MAIN6-O2**
- File: `Current/PWA/main2/main6.md`
- Delete **lines 270–439 inclusive**.
- Start marker:
`// RW_Purchases – المشتريات (أمر شراء + استلام)`
- End marker:
`window.RW_Purchases = RW_Purchases;`
- Replace the entire deleted block with:
`doc/Draft/Reprots/MAIN6_OWNER_REPLACEMENT_Purchases_20260912.js`

Do not modify any other line in `main6.md` during this surgery.

### MAIN6 PRODUCTION DECISION
No new Production mutation was made in this checkpoint.
Reason: the required Backend contracts are already present and correctly centralized; the proven defects are in the owner source's use of those contracts. Changing Production without proof would violate the governance rule against speculative modification.

## CANONICAL MAIN2 FRAGMENTS
The canonical directory was checked directly and contains `main1.md` through `main11.md` under `Current/PWA/main2/`.

Current known fragment SHAs:
- main1 `f68d47c7574c34f678cfba2aafa5ad294aadbfe5`
- main2 `65815e23b03e29c125957e6fe283cc1e253a7f7d`
- main3 `eeb56daf8cd01b31b8a7e5f5ada4f1a09df30bfe`
- main4 `e9f967859aeda729cd0811739a280ceec5266d7c`
- main5 `800ad51c88a2e80d060480990836a3c975c7435a`
- main6 `3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`
- main7 `a65969f6bdc919d4a8d62a6704a7c556b7d35e91`
- main8 `2131fbf3096d926b2486acb2ab58a4266ddd1bbc`
- main9 `b9f10ae4e727cb9495aaecbe2d752dabf13ec776`
- main10 `169025a6836c7fdc7281ea86523b975a84d889f1`
- main11 `2adfc787c3e5f0ca56abfcc85232e7a971773c3b`

## ASSEMBLY GOVERNANCE
`forensic_main_assembly.yml` was directly verified and remains correct:
- `source_of_truth: Current/PWA/main2`
- `historical_reference: Original/PWA/main`
- forbidden: `Current/PWA/main`, `Current/PWA/New-main`
- assembly remains deferred.

## VALIDATION / FALSE-CLOSURE STATUS
- Governance/OS source reviewed: VERIFIED.
- Report124 opened directly: VERIFIED.
- CURRENT_STATE opened directly: VERIFIED.
- `forensic_main_assembly.yml` opened directly: VERIFIED.
- Main6 full sequential read to EOF: VERIFIED.
- Original Main6 historical source reviewed: VERIFIED.
- Main2 directory path/11-fragment presence checked: VERIFIED.
- Main6 owner replacements `node --check`: VERIFIED.
- Final Main6 source syntax after owner surgery: PENDING.
- Browser E2E after owner surgery: PENDING.
- Main6 Gold/Diamond completion: NOT CLOSED.
- Gold/Diamond completion of all 11 fragments: NOT CLOSED.
- Final assembly: DEFERRED.

## DATA / PRODUCTION SAFETY
- No permanent business data was deleted or rewritten for Main6.
- No Main6-specific cleanup of cross-company Inventory data was performed.
- No speculative Production mutation was introduced.

## CURRENT MISSION
Complete RAWAEA ERP functionally toward Gold/Diamond while preserving the proven historical operational core, especially field operations, Orders → Runsheets → Picking → Loading → Delivery → Return → Settlement and centralized inventory movement.

## NEXT EXACT RESUMPTION POINT — MAIN6
1. Owner applies `MAIN6-O1` exactly.
2. Owner applies `MAIN6-O2` exactly.
3. Re-read `Current/PWA/main2/main6.md` from first character to EOF.
4. Recalculate SHA.
5. Run final `node --check` on Main6.
6. Check duplicate module declarations and delimiter balance.
7. Run authenticated Online Order E2E with retry.
8. Run authenticated Purchase Order create → Receive E2E and verify no duplicate receive.
9. Close Main6 only if every gate passes.
10. Open the next proven Functional Capability Gap.

## FINAL CLOSURE RULE
No assembly, no Gold/Diamond claim, and no final project closure until the owner changes are applied and the integrated system passes the required source, syntax, Production, and runtime gates.
