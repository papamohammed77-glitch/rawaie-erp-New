# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-10 — Report119 Main2 Reality Reconciliation

### GOVERNING TARGET — NON-NEGOTIABLE
الهدف هو استكمال المشروع وظيفيًا وتشغيليًا وفق Gold/Diamond، وليس مجرد إكمال UI. الدراسة تسبق التعديل، وCurrent Verified Reality تتفوق على Production ثم Database Contracts ثم Deployments ثم Git/Source، بينما التقارير التاريخية أدلة لا تمثل الحقيقة الحالية وحدها.

الحوكمة التنفيذية:

UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH CONTROL FLOW → IDENTIFY ACTUAL GAP → SURGICAL FIX → TEST → PRODUCTION VERIFY → DOCUMENT → UPDATE STATE.

### SOURCE-OF-TRUTH GOVERNANCE
- Current verified reality outranks historical reports.
- Production Database/Runtime is the execution reference.
- Historical reports are evidence, not current truth.
- `CURRENT_STATE.md` is a continuity checkpoint and must be reconciled against current Git/Production.
- Unknown != bug; Unknown != remove.
- One Closure Unit at a time.
- Parent editable source = `Current/PWA/main2/main1.md ... main11.md`.
- `Original/PWA/main/*` = historical reference only.
- `Current/PWA/New-main` = generated assembly target only.
- Physical Stock contract = `post_stock_movement -> stock_branches + inventory_log`.
- `reserve_stock` / `release_stock_reservation` = Reservation-only.

## CURRENT GIT TRUTH
- Latest verified repository HEAD: `331775e261534ed841f521cb4a922e032b018041`
- Latest commit message: `docs: add Report119 current Main2 reality reconciliation`
- Current Main2: `Current/PWA/main2/main2.md`
- Current Main2 blob SHA: `baee3cc02ae5701e6fbcbad12e57e2930afc4ae4`
- Report118 Main2 blob SHA was `a4a9e8499a65ba182673a964f82671e68372cac8` and is stale relative to current source.
- Main2 remains Owner Source Surgery territory; assistant did not directly modify the source file.

## CURRENT MAIN2 STATUS
- `RW_Dashboard.loadAll()` current source derives `companyId` locally via `_rwCompanyId()`.
- `RW_Dashboard` profit KPI current source uses Production `get_profit_loss` RPC; the obsolete `sales - purchase_orders.total_amount` calculation from Report118 is no longer present in the current source.
- `RW_Items._loadCategoriesIntoSelect()` current source declares `var companyId = _rwCompanyId();` and guards missing context.
- `RW_Items._openCategoryModal()` current source declares `var companyId = _rwCompanyId();` and guards missing context.
- `RW_Items._deleteCategory()` current source declares `var companyId = _rwCompanyId();` and guards missing context.
- `RW_Items._buildCategoryFilterFromDB()` current source declares `var companyId = _rwCompanyId();` and guards missing context.
- `RW_Items._renderUploadPreview()` current source declares `var companyId = _rwCompanyId();` and guards missing context.
- Git commit `625e7a8df17042f8701dc288f98eae381bdc3e82` dated `2026-09-10 12:21:12 UTC` proves insertion of the five Company Context fixes.
- Git commit `cd19caed9ef639c51c295691ced7c57d13d68e6c` proves the Dashboard Company Context / profit-path change that preceded the latest Main2 fixes.

## CURRENT PRODUCTION SNAPSHOT — DIRECT VERIFICATION
Verified at UTC `2026-09-10 12:25:20.655319`:
- companies = 1
- branches = 2
- users = 24
- items = 17
- customers = 3
- orders = 0
- purchase_orders = 0
- stock_branches = 20
- inventory_log = 3
- audit_log = 1869

## CURRENT DATABASE CONTRACTS
- `items.item_code` is globally UNIQUE.
- `stock_branches` has no `company_id`; tenant scope is through `branch_id -> branches.company_id`.
- `inventory_log` is company-scoped and item-scoped through `company_id + item_id`.
- Main2 company context is `RW_STATE.app.company.id` via `_rwCompanyId()`.
- `get_profit_loss(p_from_date,p_to_date)` exists in Production and is the current finance source used by the Main2 dashboard.

## INVENTORY CORE
- `post_stock_movement` remains the authoritative Physical Movement Writer.
- `reserve_stock` / `release_stock_reservation` are reservation-only.
- No Main2 finding in this reconciliation justified an Inventory Core rewrite.

## ASSEMBLY GOVERNANCE
- Canonical editable source: `Current/PWA/main2/main1.md` through `main11.md`.
- Historical source: `Original/PWA/main/*` only.
- Generated target: `Current/PWA/New-main`.
- Main2 assembly/runtime remain unproven after the latest Owner Source updates.

## REPORTING GOVERNANCE
- Historical reports must be reconciled against current source and Production.
- Report118 is now stale relative to the current Main2 SHA.
- The `dash-net-profit` KPI must not present `sales - purchases` as net profit.

## LATEST REPORT
`doc/Draft/Reprots/Report119_Main2_Reality_Reconciliation_20260910.md`

## VALIDATION STATUS
- MASTER current directive reopened and read to `END OF MASTER DIRECTIVE`.
- Report118 reopened and read completely.
- Current Main2 source was reread across its current source ranges and EOF was reached.
- Current Git HEAD refreshed directly.
- Current Main2 blob SHA refreshed directly.
- Git history refreshed directly and proved Report118's five Company Context fixes were applied after Report118.
- Current Production snapshot refreshed directly.
- No `Current/PWA/main2/main2.md` source modification was made by the assistant.
- Report119 written to Git.
- Current state updated to record the reconciliation.
- Main2 surgical replacements from Report118 are NOT required on the current source.
- Main2 full-file syntax = NOT PROVEN in this environment.
- Main2 assembly = NOT PROVEN.
- Browser/PWA runtime = NOT PROVEN.
- Parent Gold/Diamond closure = NOT PROVEN.

## LAST VERIFIED EVENT
- EVENT: `MAIN2-REALITY-RECON-20260910-REPORT119`
- UTC timestamp: `2026-09-10 12:25:20.655319`
- Git HEAD at documentation completion: `331775e261534ed841f521cb4a922e032b018041`
- Current Main2 SHA: `baee3cc02ae5701e6fbcbad12e57e2930afc4ae4`
- Production snapshot: `2026-09-10 12:25:20.655319 UTC`
- Result: all six findings stated as OPEN by Report118 were rechecked against current Main2; the six Report118 defects are no longer present in current source. No new Main2 defect was proven by this reconciliation.
- Report: `Report119_Main2_Reality_Reconciliation_20260910.md`
- Next authorized action: any new Main2 surgery must be based on the current Main2 SHA and current Production evidence, not on Report118's stale defect list.

## SELF-AUDIT
### What was proved
- MASTER was read to the end.
- Report118 was read completely.
- Current Main2 source was reopened and the relevant current source sections were verified.
- Current Git HEAD and current Main2 SHA were refreshed directly.
- Git history proved the five Company Context fixes after Report118.
- Current dashboard profit logic now uses `get_profit_loss` in the current source.
- Current Production snapshot was refreshed directly.

### What was not proved
- Full-file JavaScript parser success after the owner-applied Main2 changes.
- Browser/PWA smoke success.
- Main2 assembly success.
- Production UI smoke success.
- Gold/Diamond parent closure.

### False-closure protections
- No Report118 claim was promoted to current truth without source reconciliation.
- No stale replacement was issued.
- No Main2 source file was modified by the assistant.
- No Gold/Diamond or Fully Closed status was declared.

## FINAL CLOSURE
`REPORT118 = STALE RELATIVE TO CURRENT MAIN2 SOURCE`
`MAIN2 CURRENT SOURCE = RECONCILED`
`REPORT118 DEFECTS CURRENTLY PROVEN = 0`
`MAIN2 SURGERY FROM REPORT118 = NOT REQUIRED`
`MAIN2 FULL SYNTAX = NOT PROVEN`
`MAIN2 ASSEMBLY = NOT PROVEN`
`MAIN2 BROWSER RUNTIME = NOT PROVEN`
`PRODUCTION SNAPSHOT = VERIFIED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
