# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-10 — Report117 Main2 Surgical Review

### GOVERNING TARGET — NON-NEGOTIABLE
**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.**

الحوكمة التنفيذية:

UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH CONTROL FLOW → IDENTIFY ACTUAL GAP → SURGICAL FIX → TEST → PRODUCTION VERIFY.

### SOURCE-OF-TRUTH GOVERNANCE
- Current verified reality outranks historical reports.
- Production Runtime / Database is the execution reference.
- Historical reports are evidence, not current truth.
- `CURRENT_STATE.md` is a continuity checkpoint and must be reconciled against Git/Production.
- Unknown != bug; Unknown != remove.
- One Closure Unit at a time.
- Parent editable source = `Current/PWA/main2/main1.md ... main11.md`.
- `Original/PWA/main/*` = historical reference only.
- `Current/PWA/New-main` = generated assembly target only.
- `.github/workflows/forensic_main_assembly.yml` remains the governed assembly path.
- Physical Stock contract = `post_stock_movement -> stock_branches + inventory_log`.
- `reserve_stock` / `release_stock_reservation` = Reservation-only.

## CURRENT GIT TRUTH
- Latest verified repository HEAD: `f2731924ea708cc6617a873e18d896f96122f532`
- Latest commit message: `docs: add Report117 Main2 surgical review 20260910`
- Current Main2: `Current/PWA/main2/main2.md`
- Current Main2 blob SHA: `a4a9e8499a65ba182673a964f82671e68372cac8`
- Main2 remains Owner Source Surgery territory; assistant must not directly edit the source file under the active governing directive.

## CURRENT MAIN2 STATUS
- `RW_Dashboard.loadAll()` = OPEN / `companyId` is locally derived correctly from `_rwCompanyId()`.
- `RW_Dashboard` profit KPI = OPEN / current source labels the value `صافي الربح` but computes `sales - purchase_orders.total_amount`; the authoritative Production P&L source is `get_profit_loss(p_from_date,p_to_date)`.
- `RW_Items._loadCategoriesIntoSelect()` = OPEN / `companyId` referenced without a local declaration.
- `RW_Items._openCategoryModal()` = OPEN / `companyId` referenced without a local declaration.
- `RW_Items._deleteCategory()` = OPEN / `companyId` referenced without a local declaration.
- `RW_Items._buildCategoryFilterFromDB()` = OPEN / `companyId` referenced without a local declaration.
- `RW_Items._renderUploadPreview()` = OPEN / `companyId` referenced without a local declaration.
- Main2 full-file syntax = NOT PROVEN in current environment.
- Main2 assembly/runtime = NOT RUN after Owner Source Surgery.

## CURRENT PRODUCTION SNAPSHOT — DIRECT VERIFICATION
Verified at UTC `2026-09-10 11:50:56.024836+00`:
- companies = 1
- branches = 2
- users = 24
- items = 17
- customers = 3
- orders = 0
- purchase_orders = 0
- stock_branches = 20
- inventory_log = 3
- posted journal_entries = 0
- audit_log = 1869

## CURRENT PRODUCTION FINANCE CONTRACTS — DIRECTLY VERIFIED
- `get_profit_loss(p_from_date,p_to_date)` exists and derives current authenticated company context.

## CURRENT DATABASE CONTRACTS
- `items.item_code` is globally UNIQUE.
- `stock_branches` has no `company_id`; tenant scope is through `branch_id -> branches.company_id`.
- `inventory_log` is company-scoped and item-scoped through `company_id + item_id`.
- Main2 company context is `RW_STATE.app.company.id` via `_rwCompanyId()`.
- Current Main2 `RW_Items` inventory movement reporting uses the centralized `inventory_log.company_id + item_id` identity pattern.
- Current supported physical return semantics include `SalesReturn` and `DirectReturn`; plain `Return` must not be used as a proven movement type.

## INVENTORY CORE
- `post_stock_movement` remains the authoritative Physical Movement Writer.
- `reserve_stock` / `release_stock_reservation` are reservation writers only.
- No new Main2 finding justifies an Inventory Core rewrite.

## ASSEMBLY GOVERNANCE
- Canonical editable source: `Current/PWA/main2/main1.md` through `main11.md`.
- Historical source: `Original/PWA/main/*` only.
- Generated target: `Current/PWA/New-main`.
- Main2 full assembly remains blocked until Owner Source Surgery and validation gates pass.

## REPORTING GOVERNANCE
- `RW_STATE.data.*` is not authoritative report data when direct Production queries are available.
- Finance reports use authoritative current Production finance RPCs when applicable.
- The `dash-net-profit` KPI must not present `sales - purchases` as net profit.

## LATEST REPORT
`doc/Draft/Reprots/Report117_Main2_Surgical_Review_20260910.md`

## VALIDATION STATUS
- MASTER current directive reopened and read to `END OF MASTER DIRECTIVE`.
- Report115 reopened as historical evidence only.
- Report116 reopened as historical evidence only and found stale relative to current Main2 source SHA.
- Current Main2 source reopened through EOF.
- Current Git HEAD refreshed directly.
- Current Production snapshot refreshed directly.
- Production `get_profit_loss` definition refreshed directly.
- No Main2 source file was modified by the assistant.
- Report117 was written to Git.
- Current state was updated to record the Main2 findings.
- Main2 Owner Source Surgery = NOT YET EXECUTED.
- Main2 full-file syntax = NOT PROVEN.
- Main2 assembly = NOT RUN.
- Browser/PWA smoke = NOT RUN for this Main2 cycle.
- Gold/Diamond parent closure = NOT PROVEN.

## LAST VERIFIED EVENT
- EVENT: `MAIN2-SURGICAL-REVIEW-20260910-REPORT117`
- UTC timestamp: `2026-09-10 11:50:56.024836`
- Git HEAD before state update: `cd19caed9ef639c51c295691ced7c57d13d68e6c`
- Main2 SHA: `a4a9e8499a65ba182673a964f82671e68372cac8`
- Production snapshot: `2026-09-10 11:50:56.024836 UTC`
- Result: current Main2 contains five proven `companyId` scope defects in RW_Items plus one proven dashboard semantic defect for the `صافي الربح` KPI. No Physical Stock writer parallelism was introduced or justified by these findings.
- Report: `Report117_Main2_Surgical_Review_20260910.md`
- Next authorized action: Owner applies the exact surgical replacements to current Main2 only; then Main2 is reread to EOF, syntax-checked, matched against current parent contracts, assembled, runtime-tested, and Production UI-smoked.

## SELF-AUDIT
### What was proved
- Master current directive was read to the end.
- Report115 and Report116 were reopened and treated as historical evidence.
- Current Main2 source was reopened to EOF.
- Current Git HEAD and Main2 source SHA were refreshed directly.
- Current Production snapshot was refreshed directly.
- Current Production `get_profit_loss` was inspected directly.
- Five Main2 `companyId` references lacking local declarations were confirmed.
- The dashboard `صافي الربح` calculation was confirmed to be `sales - purchases`.
- Syntax PASS was proven only for the proposed replacement fragments, not for the complete Main2 file.

### What was not proved
- Full-file Main2 parser success after surgery.
- Owner application of Main2 source surgery.
- Post-surgery assembly and browser/runtime success.
- Production UI smoke success.

### False-closure protections
- No historical Report115/116 claim was promoted to current truth.
- No Main2 source rewrite was performed by the assistant.
- No Production Inventory Core rewrite was performed.
- No `Return` movement semantic was introduced.
- No Gold/Diamond or 100% closure was declared.

## FINAL CLOSURE
`MAIN2 = OWNER ACTION REQUIRED`
`MAIN2 SOURCE = NOT MODIFIED BY ASSISTANT`
`MAIN2 FORMAL SYNTAX = NOT PROVEN`
`PRODUCTION INVENTORY CORE = VERIFIED / NO NEW REWRITE JUSTIFIED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
