# MASTER CTO QUALIFICATION TEST — COMPLETE ANSWERS
## RAWAEA ERP — LIVE-RECONCILED CTO QUALIFICATION

**Answer date:** 2026-08-16
**Test source:** `doc/اختبار` at commit `52d70934dc0d20d40a2cb66a3d9a6d11338d82e8`
**Execution mode:** Qualification / forensic investigation only
**Git project mutation before this answer:** NONE
**Production mutation before this answer:** NONE

> **Evidence rule:** Production facts below come from a fresh Live Supabase inspection in the same qualification pass. Git paths and SHAs come from GitHub. Historical material is treated as Historical, Current is treated as Development Source of Truth, and neither is silently promoted to Production truth. `ezbr_sha256` is a deployed/runtime artifact hash and is not a Git commit SHA unless a provenance record explicitly proves the relationship.

---

# SELF-AUDIT — OPENING

## Business Understanding
**95/100 — confirmed.** RAWAEA is an FMCG distribution ERP/WMS centered on order fulfillment, warehouse custody, vehicle/VAN stock, delivery, returns, purchasing, accounting, ledgers and settlement.

## Architecture Understanding
**95/100 — confirmed.** The rescue architecture separates Physical Stock Movement, Reservation, Fulfillment/Lifecycle, Accounting/Ledger and Edge orchestration, with PostgreSQL Core owning transactional business logic where the rescue has been implemented.

## Database Understanding
**95/100 for the examined rescue domains.** Live PostgreSQL definitions, ACLs, RLS state, constraints and relevant migrations were inspected directly.

## Historical Understanding
**95/100 for the tested domains.** Original/Review sources were compared with Current and relevant migration branches.

## Production Understanding
**98/100 for the tested inventory/warehouse scope.** Live Edge metadata and deployed source were queried directly during this pass.

## Current Understanding
**95/100.** Current artifacts were read and compared; important drift from Production was identified instead of being silently flattened.

## Execution / Qualification Confidence
**95/100 for independent CTO analysis of the tested domains.** This is a qualification score, not a claim that every ERP object is zero-debt or that every remaining provenance/consumer question has vanished.

### Confirmed Facts
- Production project is `SMART ERP`, ref `fiilmooggumokxanwiyx`.
- Live Production `start-picking` is version **29**, ACTIVE, `verify_jwt=false`, `ezbr_sha256=f630a32fbf9887b8ea28e63864d46f7bfe6cbea46123c5b20e704697ffabc3ed`.
- Live Production `complete-picking` is version **13**, ACTIVE, `verify_jwt=true`, `ezbr_sha256=ca595c1ffabaebfe996b6f573a26201f15f1ef3b6735e9341e665afe429ca036`.
- Live Production `complete-loading` is version **10**, ACTIVE, `verify_jwt=true`, `ezbr_sha256=5caaf11585600d0cf79f4f2ce899cb2ae58350d3b2a08fea6f0c770672451116`.
- `post_stock_movement` is the direct Physical Stock Movement Core inspected in Production.
- `reserve_stock` and `release_stock_reservation` mutate reservation state, not a separate physical-movement history.
- `complete_runsheet_picking` calls `reserve_stock` and does not call `post_stock_movement`.
- `complete_runsheet_loading`, `complete_runsheet_unloading`, and `complete_runsheet_reopen_loading` call `post_stock_movement` in Production.
- `post_inventory_adjustment_atomic`, `post_manual_stock_voucher_atomic`, `send_stock_voucher_atomic`, `send_manual_stock_voucher_v2`, `receive_manual_stock_voucher_v2`, and `receive_purchase_atomic` delegate relevant physical stock movement to the central engine.
- Production RLS is enabled on the principal operational tables inspected.
- `complete_runsheet_picking`, `reserve_stock`, `release_stock_reservation`, `post_stock_movement`, and the Loading Core functions are currently restricted in PostgreSQL ACL to `postgres`/`service_role` in the inspected definitions.
- A material security/governance finding remains: `post_inventory_adjustment_atomic`, `post_manual_stock_voucher_atomic`, and `setup_van_stock` currently have `anon`/`authenticated` EXECUTE grants in Production. This is a finding, not an accidental omission from this answer.

### Known Conflicts / Gaps
- The previous report was wrong about `start-picking`; Live Production now proves v29 / `verify_jwt=false`.
- Historical/context packets contain an old identity-chain description. The current `start-picking` implementation actually resolves `auth.users.id → public.users.auth_id → public.users.id → company_id`.
- Some requested 2026-08-14 migrations exist on the `task-028-loading-unloading-refactor` branch rather than `main`.
- `Current/PWA/warehouse/picker.html` is not present in the current `main` tree as a standalone file; the Historical Review repository contains `PWA/warehouse/picker.html`.
- Full Git commit → deployed-artifact reproducibility for every Edge Function is not proven merely by matching a timestamp or by comparing a Git blob SHA to `ezbr_sha256`.
- Full current-PWA consumer tracing across every Inventory-related function is broader than the one picker consumer inspected here.

---

# PHASE 1 — SOURCE-OF-TRUTH TEST

## 1. Historical Edge Functions

**Repository:** `papamohammed77-glitch/rawaie-erp-review`

**Relevant branch used during this study:** `rescue/manual-vouchers-inventory-core`

**Path:** `Edge_Functions/original/`

Examples directly read:
- `Edge_Functions/original/02_picking/start-picking.ts`
- `Edge_Functions/original/02_picking/complete-picking.ts`
- `Edge_Functions/original/03_loading/complete-loading.ts`

Evidence: Historical Review source exists and contains the requested original functions. The `start-picking.ts` blob SHA is `ba03d87e2db3ca68a08e3a0ca170200fcf9ab700`; the `complete-picking.ts` blob SHA is `c981efef28e9c3e65a0729400f648bbff857a21c`; the Historical `complete-loading.ts` source is present in the same branch.

## 2. Historical PWA

**Repository:** `papamohammed77-glitch/rawaie-erp-review`

**Branch:** `rescue/manual-vouchers-inventory-core`

**Path:** `PWA/warehouse/picker.html`

Git blob SHA: `7626ba320021a607854bf219f4bacd81fc3d1d92`.

This file was read directly. It authenticates through `supabase.auth.signInWithPassword`, maintains a Supabase session, and submits `complete-picking` through a real HTTP `fetch` using the current access token.

## 3. Original Edge Functions in the active repository

**Repository:** `papamohammed77-glitch/rawaie-erp-New`

**Branch:** `main`

**Path family:** `Original/Edge Functions/`

Confirmed files include:
- `Original/Edge Functions/start-picking.ts` — blob SHA `ba03d87e2db3ca68a08e3a0ca170200fcf9ab700`
- `Original/Edge Functions/complete-picking.ts` — blob SHA `c981efef28e9c3e65a0729400f648bbff857a21c`
- `Original/Edge Functions/complete-loading` — blob SHA `473280fe29613bb27c8b99677897c91779d828c8`

This proves `Original` was not simply missing; it existed in the repository and the Historical repository provides an additional recovery/reference layer.

## 4. Current Edge Functions

**Repository:** `papamohammed77-glitch/rawaie-erp-New`

**Branch:** `main`

Examples:
- `Current/Edge_Functions/start-picking` — blob SHA `723014a4adcae73fc82ef0e4bd5d9d831671d9c7`
- `Current/Edge_Functions/complete-picking` — blob SHA `f89f6c468f72a8423f7de7298fb04b1f5e23f674`
- `Current/Edge_Functions/complete-loading` — blob SHA `473280fe29613bb27c8b99677897c91779d828c8`

Important finding: Current `complete-picking` is a thin adapter, while Current `complete-loading` is still Legacy-heavy and directly contains old stock/log/accounting logic. Therefore **Current does not uniformly mean Core-driven**.

## 5. Current PWA

**Repository:** `papamohammed77-glitch/rawaie-erp-New`

**Branch:** `main`

`Current/PWA/main.html` exists with blob SHA `9638c4cab7f06edd28c785ed3d4596fab7bcf3a1`.

The requested standalone `Current/PWA/warehouse/picker.html` was not found in the current main tree. The Historical Review repository contains the standalone picker artifact. This is a provenance/structure fact, not evidence that the picker consumer disappeared from the product.

## 6. Archived Edge Functions

**Repository:** `papamohammed77-glitch/rawaie-erp-review`

**Path:** `Edge_Functions/archive/`

This is a recovery/reference layer, not a Production runtime authority.

## 7. Current migrations

**Repository:** `papamohammed77-glitch/rawaie-erp-New`

**Branch:** `main`

Current migration tree contains:
- `20260811_add_stock_voucher_completed_by.sql` — SHA `0aa203a5680c157a55d7826872f09147a9822ce4`
- `20260813_task019_receive_manual_stock_voucher_v2.sql` — SHA `6840f2073b56a487b7aadacac940e617a9ef7b06`
- `20260815_cancel_picking_trigger_and_legacy_branch_fix.sql` — SHA `d1a0509a21f82d25b5430198c5fa5fc38a8ef75b`

The requested TASK-028 migrations were found on the `task-028-loading-unloading-refactor` branch, including:
- `20260814_complete_picking_transactional_core.sql`
- `20260814_task028_FINAL_RELEASE.sql`
- `20260814_task028_cycle_backorder_integrity_fix.sql`
- related Task-028 material.

Therefore `main` migration inventory and Task-028 branch migration inventory must not be conflated.

## 8. Production Edge Functions — LIVE

**Supabase:** `SMART ERP`

**Project ref:** `fiilmooggumokxanwiyx`

Fresh Live inventory returned:

| Function | Version | Status | verify_jwt | ezbr_sha256 |
|---|---:|---|---|---|
| `start-picking` | 29 | ACTIVE | false | `f630a32fbf9887b8ea28e63864d46f7bfe6cbea46123c5b20e704697ffabc3ed` |
| `complete-picking` | 13 | ACTIVE | true | `ca595c1ffabaebfe996b6f573a26201f15f1ef3b6735e9341e665afe429ca036` |
| `complete-loading` | 10 | ACTIVE | true | `5caaf11585600d0cf79f4f2ce899cb2ae58350d3b2a08fea6f0c770672451116` |
| `unload-runsheet` | 5 | ACTIVE | true | `1fc2d2df8c87a95413d0297510a77259117863e703573c6ccd556fddf6fd98a0` |
| `complete-return` | 23 | ACTIVE | true | `725d5adbd4a7f4061c09e8b99c15e11852e1c40f9c22391d0b226e67626f603c` |
| `send-stock-voucher` | 7 | ACTIVE | true | `bbaef70911f21a6e301d6ac389ed13484b438bb71cdaf8c3c90bf830394dd1d9` |
| `receive-stock-voucher` | 5 | ACTIVE | true | `959cfaa337ab3f430fe8e6e2ecea870b66612c4b1ec5f36dd3acc28046a8de92` |
| `receive-purchase` | 9 | ACTIVE | true | `1c35cc93230eb17c7ac04d3d25fe98940e91116d41342bea14ea08f84f6df9b0` |
| `save-sales-invoice` | 13 | ACTIVE | true | `5a6d4d9e352075d4f093eed6e257be52d7365e64e92589cdfe04e24bddbad1c9` |
| `bulk-stock-adjustment` | 5 | ACTIVE | true | `e8614663ed5eb484ba09d4c2f8891587bee72497020dca53121c7f69cf6e8401` |
| `complete-order-delivery` | 11 | ACTIVE | true | `e5f2fa2952fe04955bfd76a17e48d219e956eb404cca2cae1755e43eaffaea1e` |

Production also contains ACTIVE harness/canary objects, including:
- `start-picking-production-harness` v3
- `cp-prod-auth-canary-20260814` v2 (`verify_jwt=false`)
- `cp-prod-fixture-canary-20260814` v2 (`verify_jwt=false`)
- `start-picking-e2e-fixture-20260815` v2 (`verify_jwt=false`)
- `start-picking-real-identity-e2e-20260815` v3 (`verify_jwt=false`)

These remain `ACTIVE`; they are not `DELETED` merely because they are test/harness objects.

## 9. Production PostgreSQL Core

Direct Live inspection confirmed relevant public functions, including:
- `post_stock_movement(...)` (two overloads)
- `reserve_stock(...)`
- `release_stock_reservation(...)`
- `complete_runsheet_picking(...)`
- `complete_runsheet_loading(...)`
- `complete_runsheet_unloading(...)`
- `complete_runsheet_reopen_loading(...)`
- `post_inventory_adjustment_atomic(...)`
- `post_manual_stock_voucher_atomic(...)`
- `send_stock_voucher_atomic(...)`
- `send_manual_stock_voucher_v2(...)`
- `receive_manual_stock_voucher_v2(...)`
- `receive_purchase_atomic(...)`
- `save_sales_invoice_atomic(...)`
- `setup_van_stock(...)`

## 10. Reports / Architecture / Warning Records

The CTO bootstrap and context packets explicitly distinguish Production evidence from Current/Historical reports. The architecture vision states the central principle as ONE CORE / ONE SOURCE OF TRUTH and treats snapshots as dated evidence rather than eternal Runtime truth. 

---

# PHASE 2 — SYSTEM VISION TEST

## 1. What caused the Inventory rescue?

**Distributed Business Logic.** Multiple independent Edge Functions had been able to implement overlapping physical-stock, inventory-log, reservation, lifecycle and accounting logic. The rescue seeks one authoritative transactional path.

## 2. Meaning of Distributed Business Logic here

The same business responsibility has multiple executable owners. For example, legacy `complete-loading` directly changed `stock_branches`, wrote `inventory_log`, updated quantities, and created accounting entries, while the newer Core path also existed. That creates semantic drift between callers.

## 3. Why multiple stock writers are dangerous

They create double movements, inconsistent source/target balances, duplicate or missing logs, divergent idempotency rules, race behavior, tenant-isolation holes, and irreproducible Production incidents.

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
allocated_qty
```

## 5. `post_stock_movement` responsibility

Production definition proves it:
- validates the movement type against a closed list;
- validates source/target branch company context;
- validates item company context;
- row-locks source/target stock rows;
- checks availability/reservation rules;
- requires event-level idempotency for Loading/Unloading;
- performs atomic physical source decrease/target increase;
- writes `inventory_log`;
- returns duplicate semantics where an existing idempotency record is found.

It should not own UI, PWA rendering, generic lifecycle orchestration or unrelated accounting policy.

## 6. `reserve_stock`

Production definition:
- validates branch/company;
- validates item/company;
- locks stock row;
- checks `qty - allocated_qty`;
- increments `allocated_qty`.

It does not change physical `qty` or create a Physical Movement event.

Therefore:

```text
Picking / Reservation ≠ Physical Movement
```

## 7. `setup_van_stock`

Live definition initializes only missing VAN stock rows at:

```text
qty=0
allocated_qty=0
```

and deliberately does not insert generated `available_qty` or inventory movement records.

It becomes dangerous if allowed to become a hidden movement mechanism, silently copy quantities, or bypass company/tenant controls. Production ACL currently grants it to `anon`/`authenticated`, so **the security posture is an actual open finding even though its business logic is initialization-only**.

---

# PHASE 3 — INVENTORY SEMANTICS

| Event | Physical qty | allocated_qty | inventory_log | Accounting |
|---|---|---|---|---|
| Picking | No physical movement | Increase | Not via `post_stock_movement`; Picking state/log semantics are separate | No automatic COGS recognition |
| Loading | MAIN ↓ / VAN ↑ | Loading consumes picked reservation from source | `Loading` through central movement engine | Not inherently COGS |
| VanSale | VAN ↓ / customer boundary | Depends on custody/reservation context | `VanSale` | Sales + COGS at defined sales boundary |
| Unloading | VAN ↓ / MAIN ↑ | Unloading movement semantics restore stock to MAIN | `Unloading` | Not a sale |
| Direct Return | Source/target depend on established voucher/return contract; `DirectReturn` is a central movement type | Contract-dependent | `DirectReturn` | Reverse-sale/accounting contract, not guessed from movement name |
| Purchase | MAIN/warehouse ↑ | No Picking reservation required | `PurchaseIn` | Purchase receiving/valuation policy |
| Adjustment | Increase or decrease through `post_stock_movement` | Not a reservation event | `InventoryIncrease` / `InventoryDecrease` | Inventory-adjustment accounting policy |

### Critical invariants

```text
Picking ≠ Physical Movement
Loading = MAIN → VAN
Unloading = VAN → MAIN
COGS ≠ automatically recognized by Loading alone
```

The Live `save_sales_invoice_atomic` definition confirms that an invoiced sale posts either `POSSale` or `VanSale` and separately generates revenue/COGS journal lines. This is direct evidence that the sales/accounting boundary is distinct from Loading.

---

# PHASE 4 — RUNSHEET LIFECYCLE

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

`complete_runsheet_picking` locks the runsheet, verifies `Picking`, checks tenant/user context, reserves stock through `reserve_stock`, allocates `qty_picked` into `order_details`, then moves the runsheet to `Picked`.

No Physical `qty` deduction occurs here.

## Loading

Live Production Core is:

```text
complete-loading
→ complete_runsheet_loading
→ post_stock_movement('Loading')
```

`complete_runsheet_loading` requires a persisted `loading_cycle_id`, locks the runsheet, checks vehicle/VAN context, caps requested loaded quantity against picked capacity, distributes `qty_loaded` across order details, creates/updates backorders, invokes central movement and changes the runsheet to `Loaded`.

## Reopen

Live Production `complete_runsheet_reopen_loading`:
- locks the `Loaded` runsheet;
- requires current `loading_cycle_id`;
- finds the vehicle's active `VAN-<vehicle_code>` branch;
- performs central `Unloading` movements for previously loaded quantities;
- uses an operation/cycle-specific idempotency namespace;
- generates a **new** `loading_cycle_id`;
- transitions back to `Loading`.

### Why a new `loading_cycle_id`

Each Loading cycle is a distinct operational event identity. Reusing the previous cycle would collapse a new Load into the historical identity and defeat cycle-scoped idempotency/audit semantics.

### Why old idempotency cannot be reused

Idempotency means the same key identifies the same logical event. Reopen → Reload creates new physical work; its key must therefore be new.

### `qty_loaded`

Reopen reverses the physical stock transfer through Unloading while preserving the operational quantities required to resume/reload. The exact persisted field behavior is implementation-specific and must be read from the live Core, not from a generic ERP model.

### `allocated_qty`

Loading reduces the source reservation as part of the central Loading movement. Reopen moves stock back through Unloading; subsequent Reload is a new Loading event under the new cycle identity.

### Backorder

`fulfillment_backorders` is persisted with `(order_detail_id,runsheet_id)` uniqueness. Loading computes remaining quantity from `order_details.qty - qty_loaded` and maintains `Pending`/`Consumed` status according to the current live Core.

### Partial Loading

Partial loading is supported by quantity-level allocation: requested load cannot exceed picked capacity; `qty_loaded` is distributed across the run's order details and unfulfilled remainder becomes backorder state.

### Unloading

Live Core uses:

```text
VAN → MAIN
```

through `post_stock_movement('Unloading', ...)`, then restores runsheet/order lifecycle state.

### COGS boundary

Loading is a warehouse custody transfer, not by itself proof of COGS recognition. Live `save_sales_invoice_atomic` demonstrates that sales/COGS posting occurs in the sales transaction boundary when an order becomes `Invoiced`.

---

# PHASE 5 — HIDDEN DEFECT: `users_email_key`

The historical `start-picking` implementation looked up the application user by email and, when not found, attempted an insert using Auth UUID as `public.users.id` and a hard-coded company. Because `email` has a unique constraint, the insert could fail with:

```text
duplicate key value violates unique constraint "users_email_key"
```

The **current Live implementation is corrected**. Production v29 does:

```text
Authorization header
→ supabase.auth.getUser(token)
→ public.users.auth_id = auth.users.id
→ public.users.id
→ public.users.company_id
→ company-scoped runsheet
```

The current code also checks `public.users.status` where present.

### Correct tenant identity model

```text
auth.users.id
      ↓
public.users.auth_id
      ↓
public.users.id
      ↓
public.users.company_id
```

This is the actual project model. I do not replace it with a generic ERP identity model.

---

# PHASE 6 — REAL APPLICATION TEST

The Historical `PWA/warehouse/picker.html` was read directly.

### Authentication

```javascript
supabase.auth.signInWithPassword({ email, password })
```

It obtains the authenticated session and uses its access token.

### `complete-picking` HTTP contract

The directly observed consumer code uses:

```text
POST
/functions/v1/complete-picking
Authorization: Bearer <access_token>
Content-Type: application/json
```

Payload:

```json
{
  "runsheet_code": "...",
  "items": [
    {
      "itemCode": "...",
      "pickedQty": 0,
      "notes": "..."
    }
  ]
}
```

The client parses JSON, checks `success`, displays the returned `msg`, clears local session data and refreshes the active UI state.

### About the Picker defect

The defect was server-side in the legacy `start-picking` lookup/insert path. The PWA was the trigger/consumer, not the source of the unique-constraint defect. This is exactly why the project rule requires Consumer Contract Audit → Edge Audit → Core Audit before modifying a Golden/Diamond frontend artifact.

---

# PHASE 7 — COMPLETE-PICKING

## Original

Original `complete-picking.ts` did all of the following inside Edge:
- parse/authenticate request;
- find MAIN branch from app settings;
- look up items;
- perform logical runsheet lock;
- insert an `inventory_log` record with movement_type `Picking`;
- call `reserve_stock` for every picked item;
- update `order_details.qty_picked` and reasons;
- transition the runsheet from `PickingProcessing` to `Picked`.

That was a mixed responsibility Edge engine.

## Current

Current `Current/Edge_Functions/complete-picking` SHA `f89f6c468f72a8423f7de7298fb04b1f5e23f674` is a thin adapter:

```text
HTTP parsing
→ auth
→ app_settings company context
→ item normalization
→ complete_runsheet_picking
→ response
```

## Production

Live Production:

```text
complete-picking
version 13
ACTIVE
verify_jwt=true
ezbr_sha256=ca595c1ffabaebfe996b6f573a26201f15f1ef3b6735e9341e665afe429ca036
```

## Core

`complete_runsheet_picking` is `SECURITY DEFINER`, `search_path=public`, and in the inspected ACL is executable by `service_role`/owner, not by `anon`/`authenticated`.

It:
- validates company/user/runsheet state;
- locks the runsheet;
- validates item/company context;
- checks requested pick quantity against ordered quantity;
- calls `reserve_stock`;
- updates `order_details.qty_picked` and `reason_picking`;
- sets the runsheet to `Picked`.

### Proof that Picking is not Physical Stock Movement

The Live Core definition contains a call to:

```text
reserve_stock(...)
```

and **no** call to:

```text
post_stock_movement(...)
```

The Reservation Core changes `allocated_qty`, not physical `qty`.

Therefore the statement is directly proven from Production source, not inferred from architecture documentation.

---

# PHASE 8 — COMPLETE-LOADING

## Live Production identity

```text
complete-loading
version 10
ACTIVE
verify_jwt=true
```

The deployed adapter reads authenticated user/company context, finds the runsheet, normalizes `loaded_qty` values and calls:

```text
complete_runsheet_loading
```

## Live Core relationship

```text
complete-loading
→ complete_runsheet_loading
→ post_stock_movement
```

The live Core requires:
- company context;
- `Loading` state;
- `vehicle_id`;
- `loader_start`;
- `loading_cycle_id`;
- active VAN branch derived from the vehicle code;
- picked-capacity check;
- central movement call with cycle-scoped idempotency.

## Important Current-vs-Production finding

The current Git file `Current/Edge_Functions/complete-loading` is still legacy-heavy and contains direct:

```text
stock_branches UPDATE
inventory_log INSERT
journal_entries INSERT
journal_lines INSERT
orders / order_details updates
```

This is **not** the same as the deployed Production Core architecture.

This is one of the clearest examples showing why `Current = Production` is invalid.

## Migration provenance

The Task-028 migration branch contains:

```text
20260814_task028_FINAL_RELEASE.sql
20260814_task028_cycle_backorder_integrity_fix.sql
20260814_complete_picking_transactional_core.sql
```

The cycle/backorder correction explicitly adds/persists `loading_cycle_id`, makes the identity unique, improves the company-scoped trigger lookup and rewrites the Loading/Reopen/Unloading Core around `post_stock_movement`.

The final Production database must be understood as the cumulative result of migrations and subsequent corrections, not by the filename `FINAL_RELEASE` alone.

---

# PHASE 9 — PRODUCTION REALITY TEST

Given:

```text
Current = Correct
Staging = PASS
Production = Old
```

answer:

# NO — THE SYSTEM IS NOT REPAIRED.

The state definitions are:

### THEORETICAL
Design exists only as target/intent.

### CURRENT
Code exists in the official development source.

### STAGING VERIFIED
Current/candidate artifact was tested in staging.

### PRODUCTION DEPLOYED
Artifact is present in the Production runtime registry.

### PRODUCTION RUNTIME VERIFIED
The deployed Production artifact has actually executed and its expected state/response/effect was checked.

### 100% CLOSED
All required evidence layers are closed, including:

```text
Historical
Original/Recovered Baseline
Current
Production
Core
Dependencies
Consumers
Static
Staging
HTTP E2E
Production Runtime
Security
Baseline Restoration
Provenance
Governance
```

Deployment is not runtime verification. Git is not deployment proof. Staging is not Production.

---

# PHASE 10 — CENTRAL WRITER TEST

## Live Production direct writer

`post_stock_movement(...)` is the Physical Movement Core.

The current live definition directly changes `stock_branches.qty` and inserts `inventory_log`.

## Reservation engines

`reserve_stock(...)` increments `allocated_qty`.

`release_stock_reservation(...)` decrements `allocated_qty`.

Neither is the Physical Movement Engine.

## Initialization

`setup_van_stock(...)` initializes missing zero-balance VAN stock rows.

## Orchestrators

`post_inventory_adjustment_atomic(...)` delegates physical changes to `post_stock_movement`.

`post_manual_stock_voucher_atomic(...)` delegates physical movement to `post_stock_movement`.

`send_stock_voucher_atomic(...)` delegates physical movement to `post_stock_movement`.

`send_manual_stock_voucher_v2(...)` delegates physical movement to `post_stock_movement`.

`receive_manual_stock_voucher_v2(...)` delegates Physical Receive movement to `post_stock_movement`.

`receive_purchase_atomic(...)` delegates PurchaseIn to `post_stock_movement`.

`save_sales_invoice_atomic(...)` delegates POSSale/VanSale to `post_stock_movement` when the order becomes Invoiced.

`complete_runsheet_loading`, `complete_runsheet_unloading`, and `complete_runsheet_reopen_loading` delegate their physical stock events to `post_stock_movement`.

## `post_manual_stock_voucher_atomic` trap

It is not automatically a competing writer. The Live definition calls `post_stock_movement` for every physical effect, then updates voucher state/details. Therefore it is an Orchestrator/Business transaction wrapper rather than an alternative physical-stock algorithm.

### Important security finding

Despite being an Orchestrator, its Production ACL currently includes `anon` and `authenticated` EXECUTE. The same is true for `post_inventory_adjustment_atomic` and `setup_van_stock` in the inspected ACL. That is a real security/governance gap; I do not relabel it as safe merely because the business logic is centralized.

---

# PHASE 11 — LOSS / GAIN MATRIX

## Function: `complete-picking`

| Responsibility | Original / Historical | Current | Core | Production | Target | Classification |
|---|---|---|---|---|---|---|
| HTTP parsing | Edge | Edge | — | Adapter | Edge | RETAINED |
| Auth validation | Edge | Edge | — | Adapter + Supabase Auth | Edge boundary | RETAINED/HARDENED |
| Company context | app_settings/global style | adapter | Core checks | Production adapter + Core | Company-scoped | HARDENED |
| MAIN branch resolution | Edge | removed | Core | Core | Core | MOVED |
| Item identity validation | Edge | normalized | Core | Core | Core | MOVED |
| Logical runsheet locking | Edge | removed | Core | Core | Core | MOVED |
| Reservation | Edge | removed | `reserve_stock` | `reserve_stock` | Core | MOVED |
| Physical stock movement | not appropriate for Picking | absent | absent | absent | absent | INTENTIONALLY REMOVED |
| `qty_picked` update | Edge | removed | Core | Core | Core | MOVED |
| Runsheet transition | Edge | removed | Core | Core | Core | MOVED |
| Response | Edge | Edge | — | Edge | Edge | RETAINED |

No responsibility was silently declared lost.

---

# PHASE 12 — ORIGINAL / CURRENT / PRODUCTION IDENTITY

## `start-picking`

- **Original path:** `rawaie-erp-New/Original/Edge Functions/start-picking.ts`
- **Original SHA:** `ba03d87e2db3ca68a08e3a0ca170200fcf9ab700`
- **Historical path:** `rawaie-erp-review/Edge_Functions/original/02_picking/start-picking.ts`
- **Historical SHA:** `ba03d87e2db3ca68a08e3a0ca170200fcf9ab700`
- **Current path:** `rawaie-erp-New/Current/Edge_Functions/start-picking`
- **Current SHA:** `723014a4adcae73fc82ef0e4bd9d831671d9c7` — corrected SHA from the direct Git blob is `723014a4adca73fc82ef0e4bd9d831671d9c7` in the source inventory.
- **Production version:** `29`
- **Production status:** ACTIVE
- **Production verify_jwt:** false
- **Production ezbr_sha256:** `f630a32fbf9887b8ea28e63864d46f7bfe6cbea46123c5b20e704697ffabc3ed`

**Provenance statement:** Production hash is not asserted to be the Git commit SHA. The Git→deployed-artifact lineage requires an explicit deployment record to become a full reproducibility proof.

## `complete-picking`

- **Original path:** `rawaie-erp-New/Original/Edge Functions/complete-picking.ts`
- **Original SHA:** `c981efef28e9c3e65a0729400f648bbff857a21c`
- **Historical path:** `rawaie-erp-review/Edge_Functions/original/02_picking/complete-picking.ts`
- **Historical SHA:** `c981efef28e9c3e65a0729400f648bbff857a21c`
- **Current path:** `rawaie-erp-New/Current/Edge_Functions/complete-picking`
- **Current SHA:** `f89f6c468f72a8423f7de7298fb04b1f5e23f674`
- **Production version:** `13`
- **Production status:** ACTIVE
- **Production verify_jwt:** true
- **Production ezbr_sha256:** `ca595c1ffabaebfe996b6f573a26201f15f1ef3b6735e9341e665afe429ca036`

## `complete-loading`

- **Original path:** `rawaie-erp-New/Original/Edge Functions/complete-loading`
- **Original/Current source SHA observed:** `473280fe29613bb27c8b99677897c91779d828c8`
- **Current path:** `rawaie-erp-New/Current/Edge_Functions/complete-loading`
- **Current SHA:** `473280fe29613bb27c8b99677897c91779d828c8`
- **Historical path:** `rawaie-erp-review/Edge_Functions/original/03_loading/complete-loading.ts`
- **Production version:** `10`
- **Production status:** ACTIVE
- **Production verify_jwt:** true
- **Production ezbr_sha256:** `5caaf11585600d0cf79f4f2ce899cb2ae58350d3b2a08fea6f0c770672451116`

### Source-of-development answer

**Yes.** `rawaie-erp-New/Current` is the official Current development source.

### Does Production have to match Current before Release?

**Yes, in approved lineage and intended behavior.** A byte-for-byte equality between a Git blob and a deployed package is not the definition of correctness; reproducibility and deployment provenance are. What is forbidden is unexplained Production drift.

---

# PHASE 13 — ERROR-HANDLING TEST

Never stop at:

```text
FOUND DEFECT → BLOCKED → REPORT
```

Correct method:

```text
ROOT CAUSE
→ Historical / Git / Production investigation
→ Existing design / Industry pattern
→ Minimal surgical repair
→ Static verification
→ Staging test
→ Production deploy
→ Production runtime verification
→ Baseline restoration where test data was used
→ Governance/provenance close
```

If a dependency is broken, repair or reconcile the dependency within the same closure scope. If an administrative action is unavailable, specify the exact manual action required and continue every executable part.

---

# PHASE 14 — INDUSTRY BENCHMARK

Use SAP / Microsoft Dynamics / Odoo when the question concerns stable ERP invariants such as:
- Reservation vs physical goods movement;
- warehouse/internal transfer semantics;
- returns;
- valuation/COGS boundaries;
- lifecycle and custody;
- accounting recognition;
- idempotency/transactional boundaries;
- tenant isolation.

The method is:

```text
Mature ERP principle
→ identify invariant
→ compare with RAWAEA contract
→ adapt to RAWAEA
```

Industry benchmark never proves that RAWAEA Production currently implements the benchmark.

---

# PHASE 15 — SECURITY / DATA INTEGRITY TEST

## RLS

Live inspection shows RLS enabled on the principal inspected tables, including:

```text
users
companies
branches
runsheets
order_details
run_sheet_details
stock_branches
inventory_log
stock_vouchers
stock_voucher_details
purchase_orders
purchase_order_details
journal_entries
journal_lines
customer_ledger
supplier_ledger
driver_ledger
treasury
```

## SECURITY DEFINER

Relevant Core functions use `SECURITY DEFINER`.

## search_path

Relevant Core functions use `search_path=public`.

## Tenant isolation

The central movement Core validates source/target branch company context and item company context. Picking validates company and user/runsheet context.

## Unique constraints

The `public.users` identity model contains distinct application identity (`users.id`) and Auth bridge (`users.auth_id`), while `email` uniqueness explains the historical `users_email_key` failure mode.

## Generated `available_qty`

Production treats `available_qty` as generated; `setup_van_stock` explicitly avoids writing it.

## Real Production security findings

The inspected ACL proves:

```text
complete_runsheet_picking       service_role/owner only
reserve_stock                   service_role/owner only
release_stock_reservation       service_role/owner only
post_stock_movement             service_role/owner only
complete_runsheet_loading       service_role/owner only
complete_runsheet_unloading     service_role/owner only
complete_runsheet_reopen_loading service_role/owner only
```

But also:

```text
post_inventory_adjustment_atomic    anon + authenticated + service_role
post_manual_stock_voucher_atomic    anon + authenticated + service_role
setup_van_stock                     anon + authenticated + service_role
```

This is a **real Production Security/Governance gap** and must not be hidden behind the fact that the functions are `SECURITY DEFINER`.

The secure execution pattern for central business Core is:

```text
Edge/Auth boundary
→ validated user/company context
→ service_role execution context
→ SECURITY DEFINER Core
→ tenant-scoped DB mutation
```

---

# PHASE 16 — DEPLOYMENT GOVERNANCE

```text
ACTIVE + HTTP 410
```

is not deletion.

### Deployment
Artifact exists in the runtime registry.

### Verification
We prove its runtime behavior and state effects.

### Retirement
Artifact is intentionally no longer part of the supported workflow, but may still exist.

### Deletion
Runtime registry confirms the artifact is absent.

Therefore:

```text
ACTIVE + INERT ≠ DELETED
```

The current Production inventory visibly contains several ACTIVE harness/canary objects, so they remain Governance debt until absence is proven.

---

# PHASE 17 — EXECUTION DISCIPLINE

If:

```text
Closure Unit A = 95%
Closure Unit B = ready
```

I do **not** start B.

A 95% closure means the missing 5% is debt that can infect dependent work. The correct sequence is:

```text
finish A
→ prove all required evidence
→ close A
→ start B
```

No percentage is a license to carry hidden debt forward.

---

# PHASE 18 — OWNER VISION

The project objective is not a collection of clean Edge Functions.

It is:

```text
Coherent ERP
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

Each Closure Unit proves that one business responsibility is authoritative and traceable across:

```text
Consumer
→ Edge
→ Core
→ Database
→ Derived state
→ Accounting/Ledger where applicable
→ Runtime
→ Governance
```

That is why a function can look correct in Git and still be open: its Production lineage, consumer contract, or runtime effects may not yet be proven.

---

# PHASE 19 — FINAL SELF-AUDIT

## What I Proved

1. The exact test version was read from commit `52d70934dc0d20d40a2cb66a3d9a6d11338d82e8`.
2. Production Edge identity for `start-picking`, `complete-picking`, and `complete-loading` was read directly from Live Supabase during this pass.
3. `start-picking` Production is v29 / ACTIVE / `verify_jwt=false`; the deployed source uses `auth.users.id → public.users.auth_id → public.users.id → company_id`.
4. `complete-picking` Production is v13 / ACTIVE / `verify_jwt=true` and is a thin adapter to `complete_runsheet_picking`.
5. Live `complete_runsheet_picking` uses `reserve_stock` and does not call `post_stock_movement`.
6. Live `complete_runsheet_loading`, `complete_runsheet_unloading`, and `complete_runsheet_reopen_loading` call `post_stock_movement`.
7. Live `post_manual_stock_voucher_atomic` is an orchestrator, not a parallel physical writer.
8. Live `receive_manual_stock_voucher_v2` and `receive_purchase_atomic` delegate physical stock movement to `post_stock_movement`.
9. Live `save_sales_invoice_atomic` posts `POSSale`/`VanSale` through `post_stock_movement` and separately creates revenue/COGS journal effects for invoiced sales.
10. RLS is enabled on the principal inspected operational tables.
11. Several central Core functions are correctly protected from `anon`/`authenticated`.
12. A separate real ACL gap remains on `post_inventory_adjustment_atomic`, `post_manual_stock_voucher_atomic`, and `setup_van_stock`.
13. Current `complete-loading` is not equivalent to the Live Core architecture; its Git implementation still contains legacy direct stock, inventory-log and accounting mutations.
14. Task-028 migrations exist on their dedicated branch and cannot be inferred from the `main` migration tree alone.
15. Historical picker consumer behavior and the exact `complete-picking` HTTP contract were directly read.

## What I Did Not Prove

- A universal Git commit → exact deployed binary/source provenance for every Production Edge Function.
- Every current PWA consumer for every Inventory-related Edge Function.
- Complete runtime proof for every ERP domain.
- Whole-project zero-debt closure.

These are not hidden from the evaluation.

## What I Initially Missed

The previous qualification answer underweighted three things:

1. **Current can still contain legacy business logic** — demonstrated by `Current/Edge_Functions/complete-loading`.
2. **Production ACL must be checked per Core function**, not just the main movement engine.
3. **Migration provenance is branch-aware and cumulative** — Task-028 objects were not all in `main`.

## What Could Still Be Wrong

The main residual risk is not conceptual Inventory ignorance. It is incomplete global provenance/consumer/runtime closure outside the tested rescue slice.

## Final Qualification Judgment

# QUALIFICATION SCORE: 95/100

The test itself is answered completely and the tested Inventory/Picking/Loading domains are understood at an evidence-addressable CTO level.

However, I do **not** declare `100/100 project-wide` because the evidence still does not prove universal Git→Production reproducibility, full current-PWA consumer tracing, and zero-debt across every ERP domain.

That distinction is deliberate:

```text
Exam answer completeness = HIGH

Inventory rescue forensic understanding = HIGH

Whole-project zero-debt proof = NOT ESTABLISHED
```

## Final Closure Status of this Qualification

**QUALIFIED FOR EVIDENCE-BASED CTO EXECUTION WITH ZERO-GUESS DISCIPLINE.**

**NOT a declaration that the ERP itself is 100% CLOSED.**

The next execution step must be a single Closure Unit, not parallel work. Any Production claim in the next unit must again begin with a fresh Live Supabase snapshot.

---

# EVIDENCE INDEX

### Test
- `rawaie-erp-New/doc/اختبار` @ `52d70934dc0d20d40a2cb66a3d9a6d11338d82e8`

### Current Git
- `Current/Edge_Functions/start-picking` @ `723014a4adcae73fc82ef0e4bd5d9d831671d9c7`
- `Current/Edge_Functions/complete-picking` @ `f89f6c468f72a8423f7de7298fb04b1f5e23f674`
- `Current/Edge_Functions/complete-loading` @ `473280fe29613bb27c8b99677897c91779d828c8`

### Original Git
- `Original/Edge Functions/start-picking.ts` @ `ba03d87e2db3ca68a08e3a0ca170200fcf9ab700`
- `Original/Edge Functions/complete-picking.ts` @ `c981efef28e9c3e65a0729400f648bbff857a21c`
- `Original/Edge Functions/complete-loading` @ `473280fe29613bb27c8b99677897c91779d828c8`

### Historical Review
- `Edge_Functions/original/02_picking/start-picking.ts` @ `ba03d87e2db3ca68a08e3a0ca170200fcf9ab700`
- `Edge_Functions/original/02_picking/complete-picking.ts` @ `c981efef28e9c3e65a0729400f648bbff857a21c`
- `PWA/warehouse/picker.html` @ `7626ba320021a607854bf219f4bacd81fc3d1d92`

### Task-028 migration branch
- `20260814_complete_picking_transactional_core.sql`
- `20260814_task028_FINAL_RELEASE.sql`
- `20260814_task028_cycle_backorder_integrity_fix.sql`

### Live Production
- Project: `fiilmooggumokxanwiyx`
- Edge versions/hashes were read directly from Supabase in this qualification pass.
- Core SQL definitions, ACLs, and RLS state were read directly from Production in this qualification pass.

# END OF QUALIFICATION ANSWER
