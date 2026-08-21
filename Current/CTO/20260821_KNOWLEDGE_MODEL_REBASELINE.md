# RAWAEA ERP — KNOWLEDGE MODEL REBASELINE
## Evidence-Grade Project Onboarding / Autonomous CTO Readiness

**Date:** 2026-08-21  
**Production Supabase:** SMART ERP (`fiilmooggumokxanwiyx`)  
**Production snapshot used:** 2026-08-21T01:19:06.857673Z  
**Current Git main HEAD at re-baseline:** `66caaf2831b116dc35452114ac3915307651d63e`  
**Primary historical sequence:** Hussin Prompts 11–45 + Appendix 29  
**Project plan:** `doc/Draft/Hussin/الخطة العامة الكبرى لـ RAWAEA ERP`  
**Governing directives:** `MASTER_CTO_CONTINUITY_DIRECTIVE_RAWAEA_ERP.md` + `MASTER_RAWAEA_ERP_AUTONOMOUS_CTO_READINESS_CONTINUITY_DIRECTIVE.md`

---

# 1. PURPOSE

This record replaces the previous knowledge snapshot as the current onboarding baseline.

It is not a progress percentage report and it is not a historical closure claim. It is the current evidence-grade model of the system after:

1. Re-reading the historical Hussin execution sequence from Prompt 11 through Prompt 39 using the maintained historical consolidation and direct late-sequence source files.
2. Direct review of Prompts 40, 41, 42, 43, 44, and 45 and their execution records.
3. Direct review of the project-wide execution plan.
4. Direct Production Supabase inspection.
5. Direct Current Git source inspection.
6. Direct current `vouchers.html` and `driver.html` inspection.
7. Direct re-baselining of schema, functions, grants, RLS, triggers, migration history, stock integrity, tenant state and critical accounting/ledger writers.

Historical reports remain evidence about what was believed, requested, or proven at that historical point. They do not override current Production.

---

# 2. CURRENT TRUTH HIERARCHY

When sources disagree, use this order:

1. Current Production runtime/schema/RPC/Edge/data/RLS/grants/logs.
2. Current Git canonical source on `main`.
3. Current CTO/evidence records.
4. Historical/original source and prior Git history.
5. Previous prompts and reports.

No stale closure claim survives contradiction by newer Production evidence.

---

# 3. PROJECT-WIDE EXECUTION MODEL

The project plan is explicitly larger than Inventory rescue.

The intended sequence is:

Inventory
→ Inventory Lifecycle
→ Accounting Core
→ Ledger Engines
→ Fulfillment / Order State
→ Multi-Tenancy / Identity
→ Security
→ Edge / Consumers
→ Deployment Discipline
→ Global Regression / Concurrency
→ Zero-Debt Sweep

The target architecture is:

`UI / PWA → Edge Capability Boundary → PostgreSQL Domain RPC/Core → authoritative state → audit/accounting/ledger effects`

The ERP is not an Inventory system only.

---

# 4. HISTORICAL EXECUTION MODEL — HUSSIN 11→45

## 4.1 Prompt 11–18: Manual Voucher Forensics and First Stabilization

The sequence began by reconstructing the manual-voucher domain and deliberately separating historical language from Production capability.

Historical six-type vocabulary:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

The historical series established that the first four are genuine Manual Voucher lifecycle concepts, while Scrap and Adjustment are better understood as Adjustment Engine operations unless a real Production Voucher lifecycle is proven.

Prompts 12–17 then moved the Voucher UI toward Company-scoped source/target selection, Vehicle-aware DirectSale/DirectReturn, required reference, partial receive, lifecycle operations, and a Gold/Diamond workspace. Prompt 16 is particularly important because it disproved an earlier “complete” implementation by directly exposing missing `chooseEngineType()` and an account-tab handler mismatch. Prompt 17 repaired these surgically.

Prompt 18 established a broader project lesson: `NO_SESSION` from the shared auth layer is not equivalent to an expired session. The UI had incorrectly converted a first-time no-session state into a blocking error.

Durable rule from this period:

**Historical UI completeness claims must be re-tested against the executable blob.**

## 4.2 Prompt 19–26: Warehouse Identity, Roles, Scope and Runtime Friction

Prompt 19 introduced and hardened the warehouse workforce model:
- base warehouse role = `مخزني`
- dynamic operational role = `active_warehouse_role`

Warehouse Supervisor access and task assignment became backend-enforced, not UI-only.

Prompts 20–25 exposed a series of independent failure modes:
- malformed JavaScript generated an `App is not defined` cascade.
- `public.users.id` was confused with `public.users.auth_id` in one application consumer.
- branch scope had to be enforced in the RPC, not merely in JavaScript.
- an apparently empty team was actually an RLS/read-scope problem and required `get_warehouse_team()`.

Prompt 26 proved a real Auth credential problem for one user and correctly used the supported password-recovery flow rather than guessing or forcing password changes.

These prompts established an important operational model:

`auth.users.id → public.users.auth_id → public.users.id → company_id → branch/role/permission scope`

## 4.3 Prompt 27: Main Application Tenant Isolation

Prompt 27 was a major expansion beyond Inventory.

The investigation found hard-coded or weakly scoped company context in main application capabilities including:
- save-employee
- save-item
- save-branch
- save-customer
- save-supplier
- save-role
- save-settings
- save-journal-entry

The durable contract established by that investigation is:

`Authenticated user → public.users.auth_id → public.users.company_id → tenant-scoped CRUD`

The financial account path was also explicitly brought into company scope.

This is now a foundational identity/security contract, but it still requires global re-verification across all current consumers and not only the functions historically touched by Prompt 27.

## 4.4 Prompt 28: Central Inventory Engine Governance

Prompt 28 explicitly generalized the central inventory rule across business operations:

`Business Operation → Domain RPC → post_stock_movement → stock_branches + inventory_log`

Reservation remained separate:

`reserve_stock → allocated_qty`

A key historical discovery was Git drift: the current source still contained an old `complete-loading` implementation that directly wrote stock while Production had already moved to the centralized engine. The source was corrected.

This is the historical origin of the now-proven current rule that Git and Production must be checked independently.

## 4.5 Prompt 29–35: Voucher Workspace / Gold Master / Single-File Discipline

Prompt 29 introduced a POS-like workspace for voucher selection and operations.

Prompt 30 fixed operational controls, scroll/filter behavior, Receive identity persistence, Smart Pickers and company-scoped reads.

Prompt 31 rejected the simplistic assumption that a smaller file is automatically a broken file; function/contract comparison is the valid method.

Prompt 32 restored missing Gold Master dependencies including:
- receive operation identity persistence
- password recovery
- Dexie compatibility
- separation of true Voucher lifecycle from Adjustment Engine operations

Prompts 33–35 continued forensic cleanup and established a critical deployment discipline: the final voucher experience should live in one directly deployable `Current/PWA/vouchers.html`, rather than a fragmented dependency tree.

## 4.6 Prompt 36–39: Warehouse-Safe UX and Transfer / Field-Binding Forensics

Prompt 36 explicitly removed commercial-sensitive price fields from warehouse item views.

Prompt 37 focused on `target stock row missing`, demonstrating again that target-row guarantees belong to the stock-engine contract rather than a browser-side workaround.

Prompt 38 returned to field-by-field data binding and explicitly refused to invent unsupported schema fields such as a Representative field in `stock_vouchers`.

Prompt 39 continued the final forensic closure sequence.

## 4.7 Prompt 40: DirectSale Production Bug Discovery

Prompt 40 is one of the most important historical milestones.

It proved that DirectSale had a real Production backend defect: the vehicle branch was identified but the stock movement was previously sent without the target branch.

Historical intended relationship:

`Branch → Representative → Vehicle`

Physical inventory movement:

`Branch → Vehicle stock context`

Prompt 40 corrected the Production RPC so the target vehicle branch was passed to the central stock engine.

It also recorded that there were no existing active DirectSale manual vouchers requiring permanent data repair at that point.

This demonstrates the correct CTO pattern:

**UI symptom → Production RPC trace → core movement bug → surgical backend repair.**

## 4.8 Prompt 41: Branch / Representative / Vehicle / Supplier Field Model

Prompt 41 tightened voucher field relationships and kept the actual data model authoritative.

DirectSale:
- Branch-scoped Representative.
- Vehicle selection validated against the Representative relationship where that relationship is actually proven.

DirectReturn:
- Vehicle and branch are independently validated.
- Representative is derived only where the underlying relationship is established.

Supplier Return:
- No invented `suppliers.branch_id` field.
- When a branch-specific supplier relationship is not actually present, the application must not silently widen to an unsafe “all suppliers” list.

Prompt 41 also explicitly refused to claim browser click-through E2E because the execution environment lacked a real interactive authenticated browser session.

## 4.9 Prompt 42: Parser Failure and Auth Identity Reconciliation

Prompt 42 proved a syntax error in `App.pickSearch` as the real blocker. `App is not defined` was a downstream parser consequence.

A historically important correction was also made: the current Production identity relationship was rechecked directly and demonstrated that:

`public.users.auth_id = auth.users.id`

is the valid relationship. Therefore any older report suggesting a generic `.eq('id', authUserId)` replacement cannot be applied blindly.

This is a central lesson for the present onboarding:

**The same-looking identity bug may change direction as the deployed schema and data evolve. Always verify the live relationship.**

## 4.10 Prompt 43: Vehicle as Mobile Stock Container / Supplier Data Gap

Prompt 43 moved the model toward:

`Vehicle ≠ Representative`

and toward:

`Vehicle = mobile stock container / mobile branch context`

It also established a genuine data-model gap:

- `suppliers.branch_id` does not exist.
- Production had no established `supplier_id + branch_id` master relationship outside `purchase_orders`.
- Current Production therefore could not justify a new permanent Supplier↔Branch mapping.

The correct historical behavior was to avoid inventing that mapping.

## 4.11 Prompt 44: Surgical Mobile Branch Semantics

Prompt 44 continued the above model and placed the Vehicle→Mobile Branch translation in the application boundary for the affected voucher paths, while still relying on the central inventory engine for physical mutation.

It also recorded a real regression caught within the repair layer itself: helper functions used by a late override had not been preserved. The issue was found before closure and corrected.

This is an important precedent for current work:

**A repair layer can itself introduce defects; every added override must be reviewed as executable code, not trusted because it is “small.”**

## 4.12 Prompt 45: Driver UX Influence + Final Voucher Reconciliation

Prompt 45 asked for selective transfer of useful warehouse interaction patterns from `Current/PWA/driver.html` into `vouchers.html`, while explicitly preserving Voucher as a warehouse application rather than turning it into a sales application.

The recorded implementation added continuous barcode scan, maintained the voucher workspace, and performed Production transactional smoke tests for DirectSale and DirectReturn.

It also recorded a critical later semantic correction to the preceding repair layer: one late repair had drifted toward `Branch → VAN Branch` semantics where the historical/current contract required `Branch → Vehicle` for the Voucher entity and Vehicle→Branch for DirectReturn.

Therefore Prompt 45 should be understood as an historical finality claim that was itself superseded by later current Production work where Production changed again. It is not current truth.

---

# 5. CURRENT PRODUCTION SNAPSHOT

Captured directly from SMART ERP at `2026-08-21T01:19:06.857673Z`.

Database:
- PostgreSQL 17.6.

Current structural counts:
- public tables: 62
- public functions: 42
- RLS policies: 102
- public triggers: 13

Current data counts in the baseline snapshot:
- companies: 3
- users: 26
- branches: 5
- items: 50
- stock_branches: 26
- inventory_log: 62
- stock_vouchers: 1
- stock_voucher_details: 3
- orders: 0
- order_details: 0
- runsheets: 0
- run_sheet_details: 0
- purchase_orders: 0
- purchase_order_details: 0
- journal_entries: 2
- journal_lines: 0
- audit_log: 1772
- customer_ledger: 0
- supplier_ledger: 0
- driver_ledger: 0

Important current fact: the captured production state contains multiple companies, and the only voucher present in the snapshot belongs to the company with id `00000000-0000-0000-0000-000000000001`. This means historical test/business records cannot be treated as generic enterprise truth.

---

# 6. CURRENT INVENTORY CORE — VERIFIED

## 6.1 Physical Stock Writer

Current Production forensic sweep proves:

- `post_stock_movement(10 args)` is the only active physical stock writer.
- Physical stock writer count = 1.
- Direct `inventory_log` insert definition count outside that engine = 0.
- Stock mutation triggers = 0.
- Negative physical stock = 0.
- Negative allocated stock = 0.
- Over-allocation = 0.

The 9-argument legacy `post_stock_movement` object still exists but has no execution privilege for the application roles. It is therefore legacy residue, not an active parallel stock writer.

## 6.2 Reservation Boundary

`reserve_stock` and `release_stock_reservation` mutate `allocated_qty` only and use row locks/CAS-style updates.

They are not physical movement engines.

## 6.3 Initialization Boundary

`setup_van_stock` remains an initialization capability.

Separately, current `post_stock_movement` now performs atomic inbound target-row initialization for a target branch when needed.

This is a post-20-August change and supersedes older assumptions that the target row must always be pre-created by setup alone.

---

# 7. CURRENT VOUCHER CONTRACT — RECONCILED

Current Production exposes:

### Real Voucher lifecycle paths
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn

### Engine operations
- Scrap / Adjustment via inventory adjustment engine, not as fake Voucher lifecycles.

### Current DirectSale Production path

The current `send_stock_voucher_atomic` and `post_manual_stock_voucher_atomic` definitions now resolve a vehicle destination branch and pass it into the central stock engine.

Current migration lineage includes:
- `20260820_fix_direct_sale_voucher_target_stock`
- `20260820_voucher_vehicle_lifecycle_contract_fix_20260820`
- `20260820_send_voucher_retry_idempotency`
- `20260820_inventory_target_stock_row_autoinit`
- `20260820_disable_legacy_manual_stock_voucher_v2`

Therefore older Prompt 45 claims about a remaining DirectSale contract direction must not be copied forward without rechecking the current Production RPC.

### Current legacy Voucher V2

`send_manual_stock_voucher_v2` and `receive_manual_stock_voucher_v2` are still present as PostgreSQL objects, but their application execution grants have been removed. They are legacy execution residues, not the active Voucher path.

---

# 8. ACCOUNTING KNOWLEDGE — NOW PARTIALLY VERIFIED AT ERP LEVEL

The previous onboarding report understated this domain by treating Accounting as broadly “unknown”. Current Production proves significant live accounting behavior.

Current functions that write Journal entries include at least:
- `save_sales_invoice_atomic`
- `receive_purchase_atomic`
- `complete_return_atomic`
- `save_opening_balance_atomic`
- `save_receipt_atomic`
- `save_expense_atomic`
- `save_journal_entry_atomic`

Current ledger-affecting functions include at least:
- `save_sales_invoice_atomic`
- `receive_purchase_atomic`
- `complete_return_atomic`
- `save_expense_atomic`

Observed current event relationships:

### Sales
`save_sales_invoice_atomic`
→ sales order
→ physical stock through `post_stock_movement`
→ Journal Entry
→ Customer Ledger when credit
→ Driver Ledger for relevant Van Sales credit path.

### Purchase Receiving
`receive_purchase_atomic`
→ PurchaseIn via `post_stock_movement`
→ receiving records
→ Journal Entry
→ Supplier Ledger.

### Sales Return
`complete_return_atomic`
→ good-condition `SalesReturn` through `post_stock_movement`
→ Journal Entry when relevant accounts exist
→ Customer Ledger for customer-return value
→ Driver liability processing for run-sheet returns.

### Important limitation
This proves active domain accounting logic; it does **not** prove a single centralized accounting posting engine.

The current state therefore remains:

**Accounting Understanding = PARTIALLY VERIFIED / CENTRALIZATION OPEN**

The project plan still explicitly calls for a future central `post_journal_entry` boundary. Current Production still shows multiple domain functions embedding journal/ledger mutations directly.

---

# 9. LEDGER KNOWLEDGE — PARTIALLY VERIFIED

Current ledger schema contains:
- customer_ledger
- supplier_ledger
- driver_ledger
- treasury
- daily_settlements

But the current posting model is distributed across domain operations rather than proven as one authoritative ledger engine.

Consequences:

- We understand several current posting paths.
- We do not yet have a complete event→ledger dependency graph for the whole ERP.
- Treasury and Daily Settlement relationships are not yet proven at the same depth as Customer/Supplier/Driver flows.

Status:

**Ledger Understanding = PARTIALLY VERIFIED / OPEN**

---

# 10. FULFILLMENT KNOWLEDGE — STRONGER THAN BEFORE, NOT YET COMPLETE

Production schema confirms the fulfillment state chain:

`orders`
→ `order_details`
→ `runsheets`
→ `run_sheet_details`

`order_details` contains authoritative operational quantities:
- qty
- qty_picked
- qty_loaded
- qty_delivered
- qty_refused
- qty_returned
- driver_liability

`run_sheet_details` carries aggregated fulfillment state.

Current RPCs include:
- `create_runsheet_atomic`
- `complete_runsheet_picking`
- `complete_runsheet_loading`
- `complete_order_delivery_atomic`
- `complete_return_atomic`
- `complete_runsheet_unloading`
- reopen/cancel paths.

The current Delivery RPC explicitly reads/locks `order_details` and updates `run_sheet_details` from its aggregate state.

Therefore the current verified rule is:

**`order_details` is the fulfillment authority; `run_sheet_details` is derived operational aggregation.**

Remaining open work:
- full lifecycle reconciliation across all transitions.
- Backorder semantics.
- Reopen/Cancel interactions across all stages.
- independent-session concurrency proofs on critical fulfillment transitions.

---

# 11. IDENTITY / SECURITY MODEL — CURRENT GRAPH

Current Production identity data model includes:

`auth.users.id`
→ `public.users.auth_id`
→ `public.users.id`
→ `public.users.company_id`
→ role / permissions / active warehouse role / branch scope

`public.users.auth_id` is UNIQUE and foreign-keyed to `auth.users(id)`.
`public.users.email` is globally UNIQUE.

This live constraint is important because it means a current `users.email → company_id` lookup is not inherently ambiguous by email uniqueness, although authorization still requires explicit identity/company validation at the business boundary.

Current RLS is widely enabled, and current policies use company context helper functions such as:
- `app_private.current_user_company_id()`
- `app_private.current_user_has_permission(...)`

Sensitive Core RPCs use `SECURITY DEFINER` and `search_path=public`.

Direct application roles are denied direct physical stock mutation capability.

### Security remains OPEN at global ERP level
The current knowledge is strong in Inventory/Voucher/Warehouse scope, but not every current Edge/PWA consumer has been normalized into a single authentication→authorization matrix.

---

# 12. CONSUMER GRAPH — CURRENT STATE

The critical graph is now understood as:

`PWA → Edge Capability → RPC → Core → Tables → Audit / Accounting / Ledger`

Key current consumers include:

- `vouchers.html` → voucher Edge/API/RPC paths.
- `picker.html` / `complete-picking` → reservation/picking Core.
- loading UI / `complete-loading` → loading Core.
- unloader → unloading Core.
- receiving UI / `receive-purchase` → purchase receipt Core.
- POS / Van Sales → `save_sales_invoice_atomic`.
- delivery UI → `complete_order_delivery_atomic`.
- return UI → `complete_return_atomic`.
- warehouse supervisor → `get_warehouse_team` + `set_active_warehouse_role`.
- main application → multiple tenant-safe CRUD Edge capabilities.

### Critical Consumer Gap
The graph is not yet fully closed for every non-critical Edge Function and every historical consumer.

Specifically open:
- exact production deployment mapping for each Edge version to a Git SHA.
- browser runtime proof for the current Voucher UI.
- consumer-level replay/timeout behavior across all ERP capabilities.
- complete Current/Original/Historical lineage for every Edge artifact, not only the critical rescue set.

---

# 13. DEPLOYMENT REALITY

Three states remain formally separate:

1. Git source.
2. Production deployed code/DB.
3. Browser/hosting runtime.

The historical sequence repeatedly documented the difference.

The current Git branch is `main` with HEAD:
`66caaf2831b116dc35452114ac3915307651d63e` at this re-baseline.

The Production DB migration ledger is already beyond the 19-August state and includes several 20-August voucher/tenant changes.

Therefore:

**Git latest ≠ Production latest ≠ Browser latest**

unless independently proved.

Browser visual/runtime E2E remains unproven from the present execution environment.

---

# 14. DATA INTEGRITY / DATA REPAIR — CURRENT KNOWLEDGE

The historical series dealt with:
- cross-company stock metadata observations.
- fixture-like records.
- users with problematic authentication.
- warehouse role repairs.
- stale/incorrect voucher UI contracts.
- missing target stock rows.

Current Production forensic re-baseline now proves:

- cross-company stock metadata mismatch count = 0 in the current checked condition.
- cross-company inventory-log metadata mismatch count = 0 in the current checked condition.
- companies without app_settings = 0 in the current checked condition.
- negative stock = 0.
- negative allocated stock = 0.
- over-allocation = 0.

This is a critical example of why historical evidence must not be copied into current status.

The previous existence of a data anomaly is historical context; current state must be measured again.

---

# 15. CONCURRENCY ENGINEERING — OPEN

Current Core functions show real concurrency controls:
- `FOR UPDATE`
- conditional/CAS updates
- idempotency registries
- operation identity keys
- advisory lock for sales order-code allocation.

However, the evidence does not establish independent-session concurrency proof for every critical ERP path.

Therefore:

**Concurrency contract = PARTIALLY PROVEN**

**Concurrency test coverage = OPEN**

Sequential retry tests are not treated as concurrency proof.

---

# 16. GLOBAL WRITER / ENGINE STATUS

## Physical Stock
PROVEN centralized.

## Journal Writing
Not centralized yet; multiple domain RPCs can create Journal entries.

## Ledger Writing
Not centralized yet; multiple domain operations write ledger rows.

## Duplicate Engines
Inventory duplicate Physical engines: none active.
Accounting/Ledger duplicate posting engines: not yet fully swept globally.

## Hidden Triggers
Physical stock/inventory-log triggers: none.
General audit/sync triggers still exist for business tables and must not be mislabeled as stock engines.

## Legacy RPCs
Legacy overloads and V2 functions remain as PostgreSQL objects in some cases, but several are execution-blocked. They remain lineage/cleanup debt until classified and safely retired where compatibility permits.

---

# 17. KNOWLEDGE GRAPH — CURRENT RELATIONS

## Identity / Authorization Graph

`auth.users`
→ `public.users.auth_id`
→ `public.users.id`
→ `company_id`
→ `role / permissions / active_warehouse_role`
→ `default_branch_id / allowed_branch_ids`
→ Edge authorization
→ RPC authorization
→ RLS.

## Fulfillment Graph

`orders`
→ `order_details`
→ `runsheets`
→ `reserve_stock`
→ `qty_picked`
→ `complete_runsheet_loading`
→ `post_stock_movement(Loading)`
→ VAN/mobile stock context
→ `save_sales_invoice_atomic(VanSale)` / delivery flow
→ return
→ `post_stock_movement(SalesReturn)` where appropriate
→ unload
→ settlement / driver liability.

## Inventory Graph

Business event
→ domain RPC
→ `post_stock_movement`
→ `stock_branches.qty`
→ `inventory_log`
→ audit / accounting when the domain event requires it.

## Accounting Graph

Inventory/commercial event
→ Journal Entry
→ Journal Lines
→ Customer/Supplier/Driver Ledger where applicable
→ Treasury/Settlement for downstream financial flows.

This last graph is the least centralized and the highest remaining architectural-knowledge gap.

---

# 18. CONTRACT REGISTRY — CURRENTLY ESTABLISHED

| Contract | Current evidence | Status |
|---|---|---|
| Physical stock mutation | `post_stock_movement(10)` | VERIFIED |
| Reservation | `reserve_stock` | VERIFIED |
| Reservation release | `release_stock_reservation` | VERIFIED |
| Target inbound stock-row initialization | current `post_stock_movement` | VERIFIED |
| Manual Voucher lifecycle | Transfer / DirectSale / DirectReturn / SupplierReturn | VERIFIED CORE |
| Scrap / Adjustment | Adjustment Engine, not fake Voucher lifecycle | VERIFIED |
| Item identity | `item_id` + globally unique `item_code` | VERIFIED |
| Fulfillment authority | `order_details` | VERIFIED CORE |
| Run-sheet aggregation | `run_sheet_details` | VERIFIED CORE |
| Vehicle mobile-stock context | Production vehicle → VAN branch mapping exists | VERIFIED CORE |
| Supplier↔Branch master mapping | no direct `supplier.branch_id`; historical mapping via purchase-order evidence only | OPEN |
| Accounting authority | multiple domain RPC writers | OPEN CENTRALIZATION |
| Ledger authority | distributed by domain | OPEN CENTRALIZATION |
| Browser runtime truth | not directly proven here | OPEN |

---

# 19. KNOWN TRAPS — LIVING REGISTER

1. Historical report marked CLOSED while the source was later broken.
2. Git commit mistaken for live runtime state.
3. Production migration assumed deployed solely because it existed in Git.
4. `auth.users.id` confused with `public.users.id` instead of `public.users.auth_id`.
5. RLS can appear as an empty-data bug.
6. Hard-coded company context in older Edge/UI code.
7. `LIMIT 1` used where tenant context matters.
8. Tailwind CDN warning mistaken for JavaScript root cause.
9. Direct stock writers hidden inside stale Git copies.
10. Legacy overload existence mistaken for an active engine.
11. Operation identity derived from mutable business state.
12. Historical six-type Voucher vocabulary mistaken for six identical Production lifecycle contracts.
13. Vehicle confused with Representative.
14. Supplier↔Branch relationship invented because the UI wanted a selector.
15. Repair-layer override introduced without preserving its base helpers.
16. Missing Browser E2E described as proven because code/syntax/database tests passed.
17. Cross-company metadata anomaly copied forward after the current data was already clean.
18. Large file shrinkage treated as proof of lost functionality without behavior comparison.
19. Temporary workflow treated as a permanent application dependency.
20. Production data repaired by assumption instead of provenance + invariant proof.

---

# 20. UNKNOWN REGISTER — MATERIAL ITEMS

The following remain materially open:

1. Complete ERP-wide Deployment Map: every critical Edge/PWA artifact to exact Production version/SHA and runtime consumer.
2. Full Consumer Map across every current Edge Function, including historical consumers and retry/timeout expectations.
3. Complete Accounting Posting Registry across all financial events.
4. Complete Ledger authority/reconciliation registry.
5. Complete Treasury and Daily Settlement dependency graph.
6. Full Fulfillment state-machine closure including backorder/reopen/cancel interactions.
7. Independent-session concurrency proof for all high-risk transitions.
8. Full Browser/Client runtime proof for critical PWAs.
9. Global Journal/Ledger Writer Sweep across all domains.
10. Full Data Repair provenance registry for historical anomalies.
11. Global Zero-Debt reconciliation of all legacy Edge/RPC surfaces and temporary harnesses.
12. Supplier↔Branch master-data contract remains unresolved because the current schema does not prove such a master relationship.

---

# 21. CONFLICT REGISTER — CURRENTLY IMPORTANT

## Conflict A — DirectSale semantics across historical layers
Older historical repair layers alternated between:
- Voucher entity destination = Vehicle
- Physical stock destination = VAN Branch

Current Production now explicitly resolves the Vehicle to its stock branch before calling the central movement engine.

Therefore the current truth is not the textual direction of any one historical UI patch; it is the deployed Production RPC behavior plus the current Voucher consumer contract.

## Conflict B — Identity lookup examples in historical reports
Some historical prompts suggested changing `auth_id` lookups to `id` lookups. Current Production constraints and live mappings prove `users.auth_id → auth.users.id`; therefore the historical suggestion cannot be globally reused.

## Conflict C — Supplier branch filtering
Historical UX wanted branch-linked supplier selection, but current Production schema does not contain `suppliers.branch_id` and there are no current purchase-order-derived mappings to support a full branch-specific master list. No invented relationship is permitted.

---

# 22. PENDING FINDINGS — DO NOT YET TREAT AS CLOSED DEFECTS

These findings are preserved for the next evidence-driven workstream:

- `driver.html` contains a fallback path that inserts a `public.users` row with a hard-coded company id when an authenticated user is not found. Because the current `users.email` is globally unique and the exact expected onboarding semantics of that fallback are not fully reconstructed, it is classified **OPEN FORENSIC REVIEW**, not an auto-fix target.
- `save_sales_invoice_atomic` derives company context from the unique `public.users.email`; this is not inherently ambiguous under the current unique constraint, but the full authentication-to-company authorization proof should still be normalized across all Edge consumers.
- Legacy execution-blocked RPCs remain present as database objects and should be classified before deletion.

No destructive production change is justified by these findings alone.

---

# 23. AUTONOMOUS CTO READINESS SCORECARD

| Domain | Current status |
|---|---|
| Business Understanding | STRONG / NOT FULLY VERIFIED ERP-WIDE |
| Architecture Understanding | STRONG / inventory-core verified |
| Database Understanding | STRONG |
| Historical Understanding | STRONG / sequence 11–45 reconstructed |
| Production Understanding | STRONG / current baseline verified |
| Current Git Understanding | STRONG |
| Consumer Understanding | PARTIAL |
| Deployment Understanding | PARTIAL |
| Security Understanding | STRONG in core domains / ERP-wide open |
| Accounting Understanding | PARTIALLY VERIFIED |
| Ledger Understanding | PARTIALLY VERIFIED |
| Fulfillment Understanding | STRONG CORE / lifecycle open |
| Identity/Tenant Understanding | STRONG CORE / global consumer sweep open |
| Data Repair Understanding | STRONG in investigated domains / global registry open |
| Concurrency Understanding | PARTIAL |
| Runtime Understanding | PARTIAL |
| Global Zero-Debt Governance | OPEN |
| Autonomous CTO Ready | **NO** |

---

# 24. FINAL SELF-AUDIT

## What was proven
- Current Production baseline rebuilt directly.
- Physical Stock centralization remains real.
- Reservation boundary remains separate.
- Current Voucher core has evolved beyond the 19-August snapshot.
- Current Production includes DirectSale target-stock correction and target-row auto-initialization.
- Legacy V2 Voucher execution is disabled.
- Accounting and Ledger effects are present in multiple domain RPCs.
- Fulfillment state authority is concentrated in `order_details` with `run_sheet_details` acting as aggregation.
- Tenant/identity relationships are supported by explicit current constraints.
- Current checked data integrity is clean for the stock/cross-company conditions measured.

## What was corrected in the knowledge model
- Inventory is no longer treated as the whole ERP.
- Accounting is no longer labeled “unknown”; it is partially proven but decentralized.
- Historical DirectSale/Vehicle claims were demoted where later Production contradicted them.
- Historical cross-company data anomalies were not carried into current status without remeasurement.
- Historical identity suggestions were re-validated against current constraints.

## What remains unproven
- Full ERP-wide Consumer Map.
- Full deployment lineage.
- Full accounting centralization.
- Full ledger centralization/reconciliation.
- Full browser/client E2E.
- Complete concurrency test coverage.
- Complete global Zero-Debt sweep beyond the Inventory domain.

## What could still be wrong
- A non-critical consumer may still drift from a current RPC contract.
- A legacy execution-disabled function may still have an undocumented compatibility consumer.
- Accounting/Ledger may contain additional writers not yet included in the current sweep.
- Browser/service-worker hosting state may lag Git.

---

# 25. CURRENT STATION / MEMORY ANCHOR

```text
CURRENT STATION
2026-08-21 — Knowledge Model Rebaseline

WHAT IS CLOSED
- Production Inventory Core integrity
- Physical stock writer centralization
- Reservation boundary
- Current item identity rule
- Core voucher movement boundaries
- Core tenant/data constraints in reviewed domains

WHAT IS OPEN
- ERP-wide Accounting/Ledger centralization and reconciliation
- Full Fulfillment lifecycle graph
- Full Consumer Map
- Deployment lineage
- Browser/Client E2E
- Concurrency proof
- Global Zero-Debt sweep
- Supplier↔Branch master-data contract

WHY IT IS OPEN
Because current Production proves distributed financial/ledger writers and the available evidence does not yet establish every consumer/runtime/deployment relation.

PRODUCTION VERSION / SNAPSHOT
2026-08-21T01:19:06.857673Z
PostgreSQL 17.6

CURRENT GIT
main @ 66caaf2831b116dc35452114ac3915307651d63e

LAST VERIFIED TIME
2026-08-21T01:19:06.857673Z UTC

NEXT REQUIRED INVESTIGATION
Accounting + Ledger forensic writer sweep and event→journal→ledger dependency graph, followed by complete Consumer/Deployment Map.

KNOWN TRAPS
Historical reports, stale Git source, RLS empty-result illusion, auth_id/id confusion, mobile vehicle vs representative, invented supplier relations, execution-disabled legacy RPCs, Browser E2E overclaiming.

DO NOT REPEAT
Do not reopen Inventory Writer discovery as if it were unknown. Re-base it only when Production changes.
```

---

# 26. FINAL STATUS

**PROJECT KNOWLEDGE BASE:** SUBSTANTIALLY RECONSTRUCTED

**INVENTORY DOMAIN KNOWLEDGE:** EVIDENCE-GRADE / VERIFIED CORE

**VOUCHER CORE KNOWLEDGE:** EVIDENCE-GRADE / CURRENT PRODUCTION RECONCILED

**FULFILLMENT CORE:** STRONG / NOT GLOBALLY CLOSED

**ACCOUNTING:** PARTIALLY VERIFIED / DECENTRALIZED

**LEDGERS:** PARTIALLY VERIFIED / DECENTRALIZED

**CONSUMERS:** PARTIAL

**DEPLOYMENT LINEAGE:** PARTIAL

**RUNTIME:** PARTIAL

**CONCURRENCY:** PARTIAL

**GLOBAL ZERO-DEBT:** OPEN

**AUTONOMOUS CTO READY:** NO

The correct next state is therefore not to re-explore Inventory from zero, and not to trust the historical “final” Voucher report. The correct continuation point is the ERP-wide financial/fulfillment/consumer graph, with Production as the active authority and the Hussin sequence used strictly as chronological evidence.
