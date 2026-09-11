# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-12 — MAIN5 FORENSIC RECHECK

### GOVERNING TARGET — NON-NEGOTIABLE
هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع ولا يُتعامل معه كإضافات شكلية.

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
- Main3 owner surgeries remain open until applied and reverified.
- Main4 owner surgeries remain open until applied and reverified.

## MAIN5 — FORENSIC RESULT
Current source of truth: `Current/PWA/main2/main5.md`.
Current blob SHA at forensic read: `c4518d05ada50830e819563a55169843679d3e94`.
Current repository size reported: `75,289 bytes`.
EOF verified: final source closure is `window.RW_Runsheets = RW_Runsheets;`.

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

Full exact owner replacement blocks are recorded in:
`doc/Draft/Reprots/Report124_Main5_Forensic_Recheck_20260912.md`

## MAIN3 / MAIN4 OWNER STATE
- Main3: forensic review completed; owner source surgeries are required before source closure.
- Main4: forensic review completed; Production Roles security closure completed; owner source surgeries remain required.
- No Main3/Main4 source surgery was executed by the assistant in this checkpoint.

## CANONICAL MAIN2 FRAGMENTS
The canonical directory was checked directly and contains `main1.md` through `main11.md` under `Current/PWA/main2/` with current Git paths/SHAs.

Current known fragment SHAs:
- main1 `f68d47c7574c34f678cfba2aafa5ad294aadbfe5`
- main2 `65815e23b03e29c125957e6fe283cc1e253a7f7d`
- main3 `eeb56daf8cd01b31b8a7e5f5ada4f1a09df30bfe`
- main4 `e9f967859aeda729cd0811739a280ceec5266d7c`
- main5 `c4518d05ada50830e819563a55169843679d3e94`
- main6 `3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`
- main7 `a65969f6bdc919d4a8d62a6704a7c556b7d35e91`
- main8 `2131fbf3096d926b2486acb2ab58a4266ddd1bbc`
- main9 `b9f10ae4e727cb9495aaecbe2d752dabf13ec776`
- main10 `169025a6836c7fdc7281ea86523b975a84d889f1`
- main11 `2adfc787c3e5f0ca56abfcc85232e7a971773c3b`

`forensic_main_assembly.yml` was directly verified and is correct:
- `source_of_truth: Current/PWA/main2`
- `historical_reference: Original/PWA/main`
- forbidden: `Current/PWA/main`, `Current/PWA/New-main`
- assembly remains deferred.

## VALIDATION / FALSE-CLOSURE STATUS
- Main5 full sequential read through EOF: VERIFIED.
- Main5 structural closure: VERIFIED.
- Production append runtime transactional test: VERIFIED.
- Browser E2E for Main5 after owner surgeries: NOT PROVEN.
- CI `node --check` for final Main5 state: NOT PROVEN.
- Gold/Diamond completion of Main5: NOT CLOSED.
- Gold/Diamond completion of all 11 fragments: NOT CLOSED.
- Final assembly: DEFERRED.

## DATA / PRODUCTION SAFETY
No permanent business data was deleted or rewritten for Main5.
Temporary validation data was rolled back.
No speculative cross-company cleanup was performed.

## LAST VERIFIED CHECKPOINT
`MAIN5 PRODUCTION APPEND = PRODUCTION VERIFIED`
`MAIN5 SOURCE = OWNER SURGERIES REQUIRED`
`MAIN5 GOLD/DIAMOND = NOT CLOSED`

## NEXT EXACT RESUMPTION POINT
1. Owner applies `MAIN5-N1..N8` exactly from Report124.
2. Re-read `Current/PWA/main2/main5.md` to EOF.
3. Recalculate SHA and run the syntax/CI gate.
4. Recheck Production and run a real authenticated runsheet-driver update test.
5. Then open the next unclosed functional capability in Main5 without reopening already-proven contracts.
6. Keep Assembly deferred until all fragment owner work and integrated validation are complete.
