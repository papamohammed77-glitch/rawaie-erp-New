# MASTER CTO QUALIFICATION TEST — COMPLETE ANSWERS
## RAWAEA ERP — INVENTORY RESCUE / LIVE-RECONCILED RE-ANSWER

**Test source:** `doc/اختبار` at commit `52d70934dc0d20d40a2cb66a3d9a6d11338d82e8`

**Mode:** Qualification / forensic answer only. No Production or source-code mutation was performed while answering.

> **Evidence rule:** Production facts must come from Live Supabase at the time of the claim. Current/Original/Historical are source and provenance evidence, not Production runtime truth. `ezbr_sha256` is a deployed/runtime artifact hash, not a Git commit SHA unless an explicit provenance record proves the relationship.

---

# PRELIMINARY SELF-AUDIT

**Business Understanding:** HIGH for Inventory Rescue and its connected warehouse/sales/purchasing lifecycle.

**Architecture Understanding:** HIGH. Physical Movement, Reservation, Fulfillment/Lifecycle, Orchestration, Accounting, Derived Data, and Initialization are treated as separate responsibilities.

**Database Understanding:** HIGH for the active Inventory/Warehouse scope. Live schema confirms `public.users.id` is the application PK, `public.users.auth_id` is UNIQUE and references `auth.users.id`, and runsheet user foreign keys reference `public.users.id`.

**Historical Understanding:** HIGH for the rescue path.

**Production Understanding:** HIGH, with one explicit unresolved observation conflict for `start-picking` described below.

**Current Understanding:** HIGH as Development Source of Truth, but Current is never promoted to Production truth without deployment evidence.

**Execution Confidence:** HIGH for this qualification answer; not a claim of project-wide zero debt.

**Confirmed:** central movement Core exists; Reservation is separate; Picking uses Reservation; `post_manual_stock_voucher_atomic` is an orchestrator when it delegates to the central engine; `setup_van_stock` is initialization; Loading/Unloading are movement events.

**Unknown / Conflict:** exact live `start-picking` identity is contradictory between two live observations; full Git→deployed provenance is incomplete; inventory-wide PWA consumer tracing and absolute global writer certification are not closed.

---

# PHASE 1 — SOURCE-OF-TRUTH TEST

## 1. Historical Edge Functions

Repository: `papamohammed77-glitch/rawaie-erp-review`  
Branch: `main`  
Path family: `Edge_Functions/original/`

Example: `Edge_Functions/original/02_picking/start-picking.ts`.

Historical source establishes original responsibility, not runtime Production truth.

## 2. Historical PWA

Repository: `papamohammed77-glitch/rawaie-erp-review`  
Branch: `main`  
Path: `PWA/warehouse/picker.html`

This is the historical real Picker consumer.

## 3. Original Edge Functions

Repository: `papamohammed77-glitch/rawaie-erp-New`  
Branch: `main`  
Path family: `Original/Edge Functions/`

Verified blob SHAs:

- `Original/Edge Functions/start-picking.ts` → `ba03d87e2db3ca68a08e3a0ca170200fcf9ab700`
- `Original/Edge Functions/complete-picking.ts` → `c981efef28e9c3e65a0729400f648bbff857a21c`

The Original layer contains the Legacy responsibility distribution.

## 4. Current Edge Functions

Repository: `papamohammed77-glitch/rawaie-erp-New`  
Branch: `main`  
Path: `Current/Edge_Functions/`

Verified blob SHAs:

- `Current/Edge_Functions/start-picking` → `723014a4adcae73fc82ef0e4bd5d9d831671d9c7`
- `Current/Edge_Functions/complete-picking` → `f89f6c468f72a8423f7de7298fb04b1f5e23f674`
- `Current/Edge_Functions/complete-loading` → `473280fe29613bb27c8b99677897c91779d828c8`

Important: Current `complete-loading` is still Legacy-heavy. It therefore cannot be treated as the same artifact as the Core-driven Production implementation.

## 5. Current PWA

Repository: `papamohammed77-glitch/rawaie-erp-New`  
Branch: `main`  
Path family: `Current/PWA/`

The historical `PWA/warehouse/picker.html` path must not be assumed to exist in Current merely because it exists in Historical.

## 6. Archived Edge Functions

Repository: `papamohammed77-glitch/rawaie-erp-review`  
Branch: `main`  
Path: `Edge_Functions/archive/`

Archive is evidence/recovery material, not automatic Current/Production truth.

## 7. Current migrations

Repository: `papamohammed77-glitch/rawaie-erp-New`  
Branch: `main`  
Path: `supabase/migrations/`

Visible main-tree examples include:

- `20260811_add_stock_voucher_completed_by.sql`
- `20260813_task019_receive_manual_stock_voucher_v2.sql`
- `20260815_cancel_picking_trigger_and_legacy_branch_fix.sql`

Task-028 migrations may exist on task/recovery branches. Therefore migration truth is cumulative, not filename-based.

## 8. Production Edge Functions

Production Supabase project: `SMART ERP` / ref `fiilmooggumokxanwiyx`.

Live registry is authoritative for slug, version, status, `verify_jwt`, deployed source/hash, and update time.

Directly observed in the accessible Live Supabase registry:

### `complete-picking`
- version `13`
- status `ACTIVE`
- `verify_jwt=true`
- `ezbr_sha256=ca595c1ffabaebfe996b6f573a26201f15f1ef3b6735e9341e665afe429ca036`

### `start-picking`
The accessible live connector observation returned:
- version `29`
- status `ACTIVE`
- `verify_jwt=false`
- `ezbr_sha256=f630a32fbf9887b8ea28e63864d46f7bfe6cbea46123c5b20e704697ffabc3ed`

However, an independent owner-side live observation reports `v14 / verify_jwt=true`. Because two live observations conflict, the correct classification is:

**`start-picking Production Identity = CONFLICT`**

No single version is asserted by inference.

## 9. Production PostgreSQL Core

Live public functions include:

`post_stock_movement`  
`reserve_stock`  
`release_stock_reservation`  
`complete_runsheet_picking`  
`complete_runsheet_loading`  
`complete_runsheet_unloading`  
`complete_runsheet_reopen_loading`  
`post_inventory_adjustment_atomic`  
`post_manual_stock_voucher_atomic`  
`setup_van_stock`

## 10. Reports / Architecture / Warning records

The CTO/Governance documentation is evidence and intent/history. It cannot override Live Production runtime evidence.

---

# PHASE 2 — SYSTEM VISION TEST

## 1. Core architectural problem

The rescue exists because Inventory business logic was distributed among multiple independent Edge paths.

## 2. Distributed Business Logic

The same business responsibility can be implemented independently in multiple executable places instead of one authoritative engine. In this project that included physical stock updates, inventory logging, reservations, lifecycle updates, and downstream side effects.

## 3. Why multiple writers are dangerous

They create inconsistent balances, duplicate movements/logs, divergent retry semantics, different locking, and tenant-isolation defects that are very difficult to reconstruct after the fact.

## 4. Central contract

```text
Physical Stock Movement
        ↓
post_stock_movement
        ↓
stock_branches.qty
        +
inventory_log
```

Reservation is separate:

```text
reserve_stock / release_stock_reservation
        ↓
stock_branches.allocated_qty
```

## 5. `post_stock_movement`

It owns the transactional Physical Movement boundary: movement validation, company/item/branch checks, row locking, source availability, physical stock changes, inventory-log posting, and movement idempotency where required.

It does not own UI rendering, PWA behavior, generic HTTP application logic, or unrelated lifecycle/accounting orchestration.

## 6. `reserve_stock`

It reserves available stock by changing `allocated_qty`; it does not represent a physical movement and must not deduct physical `qty` merely because an item was picked.

## 7. `setup_van_stock`

It initializes missing VAN stock rows. It becomes dangerous if it starts copying real stock, creating movement history, or acting as a hidden transfer engine instead of initialization.

---

# PHASE 3 — INVENTORY SEMANTICS TEST

| Event | Physical qty | allocated_qty | inventory_log | Accounting |
|---|---|---|---|---|
| Picking | No physical deduction | Increase by Reservation | Not a Physical Movement event | Not automatically COGS |
| Loading | MAIN ↓ / VAN ↑ | Reservation reconciled by Loading contract | `Loading` | Not automatically COGS |
| VanSale | VAN ↓ | Business/custody dependent | `VanSale` | Sales/COGS at its defined accounting boundary |
| Unloading | VAN ↓ / MAIN ↑ | Reconciled with cycle/reservation contract | `Unloading` | Not automatically a sale |
| Return | Depends on return type/custody | Contract dependent | Return movement where physical | Return accounting depends on event |
| Purchase | Branch ↑ | Normally not a Picking reservation | `PurchaseIn` | Inventory/accrual/valuation contract |
| Adjustment | Physical ↑/↓ via Core | Separate reservation semantics | `InventoryIncrease/Decrease` | Adjustment accounting policy |

Explicit conclusions:

```text
Picking ≠ Physical Movement
Loading = MAIN → VAN
Unloading = VAN → MAIN
COGS ≠ automatically recognized at Loading
```

---

# PHASE 4 — RUNSHEET LIFECYCLE TEST

```text
Open
→ Confirmed
→ Picking
→ Picked
→ Loading
→ Loaded
→ Reopen
→ Loading
→ Reload
→ Loaded
→ Unloading
→ Picked
```

## Picking

`complete_runsheet_picking` validates the run-sheet state, tenant/user context and item quantities, calls `reserve_stock`, updates picked quantities, and transitions to `Picked`. It does not call `post_stock_movement`.

## Loading

Loading is the physical transfer:

```text
MAIN → VAN
```

through the Loading Core and `post_stock_movement('Loading',...)`.

## Reopen

Reopen is the inverse movement for the prior loading cycle:

```text
VAN → MAIN
```

A new `loading_cycle_id` is required because it identifies a new operational cycle and therefore a new logical event namespace.

## Why not reuse idempotency

Idempotency means the same logical event gets the same key. Reload after Reopen is a new event; reusing the previous key would incorrectly turn a legitimate reload into a duplicate.

## `qty_loaded` / `allocated_qty`

Reopen must reverse the physical Loading event according to the deployed Core contract while preserving the lifecycle information needed for the next Loading cycle. Reservation is not a substitute for the physical transfer.

## Backorder / Partial Loading

The lifecycle must preserve the difference between ordered, picked, loaded, and remaining quantities. `fulfillment_backorders` is the explicit remainder record. Partial Loading must use the same central movement/idempotency contract.

---

# PHASE 5 — HIDDEN DEFECT TEST

Historical/Original `start-picking` used an email lookup and inserted a new `public.users` row when no record was found. The live schema has `public.users.email UNIQUE`.

Therefore:

```text
wrong lookup
→ false "not found"
→ INSERT
→ users_email_key collision
```

The actual identity bridge in the live schema is:

```text
auth.users.id
    ↓
public.users.auth_id
    ↓
public.users.id
    ↓
public.users.company_id
```

`public.users.id` is the application PK. `public.users.auth_id` is the UNIQUE bridge to Supabase Auth.

`company_id` must come from the trusted application-user/tenant context, not arbitrary client input.

---

# PHASE 6 — REAL APPLICATION TEST

Historical PWA:

`rawaie-erp-review/PWA/warehouse/picker.html`

The actual workflow contains login/session handling and warehouse actions.

## Start Picking

Function: `startPicking`

HTTP:
`POST`

Authorization:
`Bearer <Supabase access token>`

Payload:

```json
{"runsheet_code":"..."}
```

## Complete Picking

The consumer uses the HTTP function with a payload of the form:

```json
{
  "runsheet_code":"...",
  "items":[
    {"itemCode":"...","pickedQty":0,"notes":"..."}
  ]
}
```

The Current Edge adapter normalizes both camelCase and snake_case item fields before invoking the Core.

## Cancel / Reopen

The Picker workflow also exposes Cancel and Reopen lifecycle actions using authenticated HTTP requests and a `runsheet_code`.

## Where was the `users_email_key` problem?

The root defect belongs to `start-picking` server-side identity resolution, not the Picker UI. The Original Edge source proves the email lookup plus insert behavior that could collide with the global unique email constraint.

The UI is a consumer of the capability; changing the UI would not repair the identity invariant.

---

# PHASE 7 — COMPLETE-PICKING TEST

## Original

`Original/Edge Functions/complete-picking.ts` SHA:
`c981efef28e9c3e65a0729400f648bbff857a21c`

Responsibilities included body/auth handling, branch/item lookup, logical locking, direct `inventory_log` Picking entries, `reserve_stock`, order-detail updates, and run-sheet lifecycle updates.

## Current

`Current/Edge_Functions/complete-picking` SHA:
`f89f6c468f72a8423f7de7298fb04b1f5e23f674`

The Current adapter:
- parses HTTP input,
- authenticates,
- obtains company context,
- normalizes items,
- calls `complete_runsheet_picking`,
- serializes the result.

## Core

`complete_runsheet_picking` owns the transactional business operation: tenant/user validation, runsheet lock/state, item/quantity validation, reservation call, picked quantity updates, and lifecycle transition.

## Reservation

`reserve_stock` owns `allocated_qty` changes.

## Physical stock

Picking does not call `post_stock_movement`, so Picking itself does not deduct Physical `qty`.

### Byte parity trap

Current and Production need semantic/contract/provenance compatibility; byte identity is not required unless the deployment record explicitly proves it.

---

# PHASE 8 — COMPLETE-LOADING TEST

The desired Core chain is:

```text
complete-loading
→ complete_runsheet_loading
→ post_stock_movement
```

## Historical Original

`Original/Edge Functions/complete-loading` directly handled:
- physical stock mutation,
- `inventory_log`,
- order/run-sheet quantities,
- Backorder,
- Journal Entries / COGS,
- lifecycle state.

## Current

`Current/Edge_Functions/complete-loading` SHA:
`473280fe29613bb27c8b99677897c91779d828c8`

It still contains Legacy-heavy direct business logic. Therefore `Current` must not be mistaken for the already deployed Core-driven Production implementation.

## Production/Core

The deployed Production Loading path is Core-oriented:

```text
complete-loading
→ complete_runsheet_loading
→ post_stock_movement('Loading', ...)
```

## Loading idempotency

The central engine uses an operation/cycle/item-specific identity for Loading/Unloading events so an exact duplicate logical request cannot apply the physical movement twice.

## `loading_cycle_id`

It identifies an operational Loading cycle. Reopen creates a new cycle identity; the next Loading is not the same logical event.

## Backorder

`fulfillment_backorders` tracks remaining fulfillment quantities against order/order-detail/runsheet/item.

## Partial Loading

Must preserve ordered vs picked vs loaded vs remaining quantities and must remain inside the central physical movement/idempotency contract.

## Reopen / Reload / Unloading

Reopen reverses the prior Loading physically (`VAN → MAIN`), then creates a new cycle for future Loading (`MAIN → VAN`).

## COGS boundary

Loading is a warehouse custody/movement event. It is not automatically the COGS recognition event merely because stock leaves MAIN.

## Migration trap

`FINAL_RELEASE.sql` is a historical migration event, not automatically the final database truth. The final DB state is the cumulative result of all applicable migrations and later corrections; the live Production object definition is the final runtime evidence.

---

# PHASE 9 — PRODUCTION REALITY TEST

If:

```text
Current = Correct
Staging = PASS
Production = Old
```

then the system is **NOT repaired**.

Definitions:

- **THEORETICAL:** design only.
- **CURRENT:** exists in development source.
- **STAGING VERIFIED:** staging runtime tested.
- **PRODUCTION DEPLOYED:** deployment exists.
- **PRODUCTION RUNTIME VERIFIED:** deployed Production behavior executed and verified.
- **100% CLOSED:** all required historical/source/core/consumer/static/staging/HTTP/Production/security/provenance/governance/baseline evidence is complete.

---

# PHASE 10 — CENTRAL WRITER TEST

Live Production classifications:

### Central Movement
`post_stock_movement`

Owns physical stock movement and the corresponding inventory log.

### Reservation
`reserve_stock`
`release_stock_reservation`

They change `allocated_qty` rather than representing a physical movement.

### Initialization
`setup_van_stock`

Initializes missing VAN stock rows.

### Orchestrator
`post_inventory_adjustment_atomic`

Determines the adjustment event and delegates the physical movement to `post_stock_movement`.

`post_manual_stock_voucher_atomic`

Voucher orchestration that delegates the actual physical movement to the central movement engine; the name alone is not evidence of a parallel engine.

`complete_runsheet_reopen_loading`

Orchestrates the reverse Loading event and delegates the physical `Unloading` movement to the central engine.

### Legacy Parallel Engine
Only a function that directly implements an independent Physical Stock algorithm outside `post_stock_movement` qualifies. That classification cannot be made from names alone; source must be read.

### Current global state
The central movement model is strongly implemented, but a final whole-system `One Physical Stock Writer` certification requires the complete Edge/source/dynamic-SQL/consumer sweep.

---

# PHASE 11 — LOSS / GAIN TEST

## `complete-picking` Responsibility Matrix

| Responsibility | Legacy | Current | Core | Production | Target | Classification |
|---|---|---|---|---|---|---|
| HTTP parsing | Edge | Edge | No | Adapter | Edge | RETAINED |
| Authentication | Edge | Edge | Validation | Adapter + Core | Boundary | HARDENED |
| Company context | Weak/legacy | Adapter | Core validation | Production | Trusted tenant context | HARDENED |
| Runsheet lock | Edge | No | Yes | Yes | Core | MOVED |
| Item/quantity validation | Edge | No | Yes | Yes | Core | MOVED |
| Reservation | Edge | No | `reserve_stock` | Yes | Core | MOVED |
| Physical qty deduction | Not valid for Picking | No | No | No | None | INTENTIONALLY REMOVED |
| `qty_picked` | Edge | No | Core | Yes | Core | MOVED |
| State transition | Edge | No | Core | Yes | Core | MOVED |
| Response serialization | Edge | Edge | No | Adapter | Edge | RETAINED |

No responsibility is called Lost merely because it disappeared from Edge; it is MOVED when the evidence identifies the new owner.

---

# PHASE 12 — ORIGINAL / CURRENT TEST

## `start-picking`

**Original**  
Path: `Original/Edge Functions/start-picking.ts`  
SHA: `ba03d87e2db3ca68a08e3a0ca170200fcf9ab700`

**Current**  
Path: `Current/Edge_Functions/start-picking`  
SHA: `723014a4adcae73fc82ef0e4bd5d9d831671d9c7`

**Production**  
Accessible Live observation: v29 / ACTIVE / `verify_jwt=false` / `ezbr_sha256=f630a32fbf9887b8ea28e63864d46f7bfe6cbea46123c5b20e704697ffabc3ed`.

**Conflicting live observation:** v14 / `verify_jwt=true`.

Therefore the Production identity is deliberately classified `CONFLICT` rather than guessed.

## `complete-picking`

**Original**  
Path: `Original/Edge Functions/complete-picking.ts`  
SHA: `c981efef28e9c3e65a0729400f648bbff857a21c`

**Current**  
Path: `Current/Edge_Functions/complete-picking`  
SHA: `f89f6c468f72a8423f7de7298fb04b1f5e23f674`

**Production**  
v13 / ACTIVE / `verify_jwt=true` / `ezbr_sha256=ca595c1ffabaebfe996b6f573a26201f15f1ef3b6735e9341e665afe429ca036`

## `complete-loading`

**Original**  
Path: `Original/Edge Functions/complete-loading`  
Legacy implementation with direct stock/log/accounting responsibilities.

**Current**  
Path: `Current/Edge_Functions/complete-loading`  
SHA: `473280fe29613bb27c8b99677897c91779d828c8`

**Production**  
Live Production Loading capability is Core-driven and must be identified by the current live function registry and deployed source; an `ezbr_sha256` must not be presented as a Git commit SHA.

## Is Current the development Source of Truth?

YES.

## Must Production match Current before Release?

Production must be traceable to the approved development source/release artifact and must satisfy the Target Contract. Byte-for-byte equality is not required. Untracked Production drift is not acceptable.

---

# PHASE 13 — ERROR-HANDLING TEST

Required method:

```text
FOUND DEFECT
→ ROOT CAUSE
→ Historical / Original research
→ Current / Production reconciliation
→ Industry benchmark where applicable
→ Surgical repair
→ Static verification
→ Staging
→ HTTP E2E
→ Deploy
→ Production runtime verify
→ Baseline restore
→ Provenance + governance close
```

Broken dependency → repair it.  
Missing file → search Current/Original/Historical/archive/Git history/deployed source.  
Administrative obstacle → identify the exact owner action and continue all other executable work.

`BLOCKED` is not a substitute for investigation.

---

# PHASE 14 — INDUSTRY BENCHMARK TEST

Use SAP / Dynamics 365 / Odoo when dealing with stable ERP invariants such as:
- reservation,
- internal transfer,
- returns,
- warehouse lifecycle,
- stock valuation,
- COGS boundaries,
- accounting recognition,
- idempotency/transaction semantics,
- tenant/security patterns.

Process:

```text
Mature ERP principle
→ identify invariant
→ compare with RAWAEA contract
→ adapt to RAWAEA
```

Do not copy competitor implementation literally.

---

# PHASE 15 — SECURITY / DATA INTEGRITY TEST

## RLS

Operational Production tables in the inspected scope have RLS enabled.

## SECURITY DEFINER

Core Inventory/fulfillment functions use `SECURITY DEFINER` where the architecture requires trusted transactional execution.

## search_path

The inspected Core functions use `search_path=public`.

## Tenant isolation

`company_id` is present across the core business tables and Core functions validate company ownership instead of trusting arbitrary client tenant input.

## Identity

Live schema:

```text
auth.users.id
    ↓
public.users.auth_id
    ↓
public.users.id
```

and runsheet picker/loader/deliverer/driver references point to `public.users.id`.

## Unique constraints

`public.users.email` is UNIQUE.  
`public.users.auth_id` is UNIQUE.

## Foreign keys

Operational stock/order/runsheet/voucher/accounting tables use explicit FK relationships to enforce identity and tenant structure.

## Generated available quantity

```text
available_qty = qty - allocated_qty
```

is generated from the two authoritative columns.

## Real security debt

Live inspection identified ACL exposure on some central/orchestrator RPCs, including:
- `post_inventory_adjustment_atomic`
- `post_manual_stock_voucher_atomic`
- `setup_van_stock`

where `anon/authenticated EXECUTE` remains present in the inspected state.

That is a genuine Production security finding.

---

# PHASE 16 — DEPLOYMENT GOVERNANCE TEST

```text
ACTIVE + HTTP 410
```

is not:

```text
DELETED
```

Deployment = runtime object exists.  
Verification = runtime behavior proved.  
Retirement = no longer used/intended.  
Deletion = runtime object is actually absent from the registry.

Therefore `ACTIVE + INERT` is still not Deleted.

---

# PHASE 17 — EXECUTION DISCIPLINE TEST

If Closure Unit A = 95% and B is ready:

# DO NOT START B.

Finish A.

Otherwise the project carries hidden debt and destroys the meaning of `CLOSED`.

---

# PHASE 18 — OWNER VISION TEST

The final target is not "repair an Edge Function".

It is:

```text
ERP coherent
+
Single Source of Truth
+
Central Inventory Engine
+
Atomic Transactions
+
Reliable Accounting
+
Stable Applications
+
Production Reality
```

Each Closure Unit proves that one business responsibility has moved from distributed/ambiguous ownership to authoritative, transactional, traceable, verified ownership.

The correct system chain remains:

```text
Application
→ Edge capability
→ Core
→ Database
→ Derived data
→ Accounting / Fulfillment
→ Runtime
→ Governance
```

---

# PHASE 19 — SELF-AUDIT TEST

## Confirmed

- Central Physical Movement Core exists.
- Reservation is separate.
- Picking does not physically deduct stock through the central movement Core.
- Loading and Unloading are Physical Movement semantics.
- Original code demonstrates the legacy distributed responsibilities.
- Current code demonstrates responsibility migration for complete-picking.
- `public.users.auth_id` is the Auth bridge to the application user.
- `post_manual_stock_voucher_atomic` is an orchestrator when it delegates to `post_stock_movement`.
- Current and Production are different evidence layers.
- Cumulative DB state is the final database truth, not a migration filename.

## Unknown / Unverified

- Complete Git commit → deployed Production artifact provenance for every Edge Function.
- Exhaustive Inventory-wide PWA consumer mapping.
- Absolute proof against every possible dynamic/external direct SQL path.
- Final governance deletion proof for every temporary harness.

## Conflict

`start-picking` Production identity is contradictory between two live observations:

```text
Live connector observation: v29 / verify_jwt=false
Independent owner live observation: v14 / verify_jwt=true
```

The correct treatment is `CONFLICT`, not selecting one by assumption.

## 100% rule

Because the test explicitly rejects 100% when required evidence is missing or conflicting, I do NOT declare the entire project or all closure units 100% closed here.

---

# FINAL ANSWER

The project is architecturally understood, the Inventory rescue contract is understood, and the distinction between source/provenance/runtime is explicit.

The most important operational rule demonstrated by this answer is:

> **Live Production + cumulative DB state + Original/Historical responsibility + real PWA trace = the evidence basis for a closure decision.**

A previous report is never allowed to override a fresh Production observation.

At the same time, when two supposedly live observations conflict, the correct CTO action is to mark `CONFLICT`, reconcile the runtime identity, and only then publish a single Production claim.

No Production or Git implementation change was performed while answering this test.
