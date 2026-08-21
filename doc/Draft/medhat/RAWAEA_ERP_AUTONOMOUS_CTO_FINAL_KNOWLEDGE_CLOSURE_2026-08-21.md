# RAWAEA ERP — AUTONOMOUS CTO FINAL KNOWLEDGE CLOSURE

**Date:** 2026-08-21  
**Mode:** Production Forensic CTO / Knowledge Closure  
**Rule:** Production first; Git current second; Historical/Original for contract reconstruction only; reports are historical navigation, not truth.

---

## EXECUTIVE GATE

**AUTONOMOUS CTO READY:** `NO`

The current evidence materially advances the ERP-wide model, but five critical closure domains remain unproven:

1. Accounting Core centralization.
2. Ledger Core centralization.
3. Complete Consumer-to-Core mapping.
4. Git → artifact → deployment → runtime lineage.
5. True concurrent-session proof.

This is not a capability judgment. It is an evidence gate.

---

# A. CURRENT PRODUCTION SNAPSHOT

Production project: `SMART ERP`  
Supabase ref: `fiilmooggumokxanwiyx`  
Status: `ACTIVE_HEALTHY`  
PostgreSQL: 17.6.1.121

| Metric | Current Production |
|---|---:|
| public tables | 62 |
| public functions | 42 |
| RLS policies | 102 |
| triggers | 13 |
| companies | 3 |
| users | 26 |
| branches | 5 |
| items | 50 |
| stock rows | 26 |
| inventory_log | 3 |
| stock_vouchers | 0 |
| orders | 0 |
| runsheets | 0 |
| purchase_orders | 0 |

Latest Production migrations include:

- `20260821023458 remove_orphan_e2e_inventory_logs_20260821`
- `20260821023348 remove_confirmed_duplicate_indexes_20260821_v2`
- `20260821023255 production_data_cleanup_test_voucher_and_orphan_company_20260821_v3`
- `20260821023150 company_license_settings_integrity_20260821`
- `20260820183912 20260820_fix_direct_sale_voucher_target_stock`
- `20260820180154 voucher_vehicle_lifecycle_contract_fix_20260820`
- `20260820155958 20260820_send_voucher_retry_idempotency`
- `20260820154957 20260820_inventory_target_stock_row_autoinit`
- `20260820035950 20260820_tenant_safe_main_crud`
- `20260820030942 20260820_warehouse_supervisor_team_read_scope`

Historical counts that differ from the above are explicitly stale for the current production snapshot.

---

# B. TRUTH HIERARCHY

```text
PRODUCTION RUNTIME / LIVE DB
        ↓
DEPLOYED EDGE / RPC DEFINITIONS
        ↓
CURRENT GIT main
        ↓
CURRENT BRANCH / COMMIT HISTORY
        ↓
HISTORICAL / ORIGINAL / ARCHITECTURE
        ↓
PREVIOUS REPORTS
```

A historical claim is accepted as current only after re-verification.

---

# C. HISTORICAL CONTRACT MAP

The Hussin sequence 11→45 documents the transition from manual-voucher UI repair into ERP-wide transactional governance.

The most stable business contracts reconstructed from history and surviving current Production evidence are:

### Inventory

`Business Operation → Domain Core → post_stock_movement → stock_branches + inventory_log`

### Reservation

`Picking → reserve_stock / release_stock_reservation → allocated_qty`

### Fulfillment

`Order → Order Details → Runsheet → Picking → Loading → Delivery → Return → Unloading`

### Manual Voucher

Current lifecycle contract remains:

- Transfer: Branch → Branch
- DirectSale: Branch → Vehicle/VAN
- DirectReturn: Vehicle/VAN → Branch
- SupplierReturn: Branch → Supplier

`Scrap` and `Adjustment` currently exist as engine operations, not as proven four-stage Manual Voucher lifecycle peers.

No new business contract is inferred from UI appearance alone.

---

# D. CURRENT ARCHITECTURE

## Inventory Core

Canonical Production function surfaces prove:

- `post_stock_movement(...10 args...)` exists as the current idempotent Physical Movement engine.
- `post_inventory_adjustment_atomic` delegates to the inventory core.
- `post_manual_stock_voucher_atomic` exists as a domain operation and delegates to the physical core.
- Purchase receiving, sales, returns, loading and unloading have current core paths that converge on inventory movement rather than performing independent physical stock mutations.

## Reservation

`reserve_stock` and `release_stock_reservation` are separate from Physical Movement.

## Sales

`save-sales-invoice` Production v15 delegates to `save_sales_invoice_atomic` and accepts an operation identity/idempotency key.

## Purchase

`receive-purchase` Production v12 is present with operation-aware production history; the exact consumer-to-core lineage is still not completely closed in Git-to-runtime form.

## Fulfillment

Production currently contains separate operation boundaries for picking, loading, delivery, return and unloading.

## Tenant / Identity

The current architectural pattern is:

`auth.users.id → public.users.auth_id → public.users.company_id → tenant-scoped operation`

This corrected several earlier production defects.

---

# E. TARGET ARCHITECTURE

The target architecture stated by the project plan remains:

```text
Consumer / PWA
      ↓
Edge Capability
      ↓
Domain Core RPC
      ↓
Transactional Engine
      ↓
Authoritative Tables
      ↓
Audit / Operation Registry
```

For inventory:

```text
Business Event
→ post_stock_movement
→ stock state + inventory history
```

For finance, the target has not yet been proven as implemented at the same maturity level:

```text
Business Financial Event
→ post_journal_entry
→ Journal Core
→ Ledger Engines
```

The absence of this proven central financial boundary is the main architectural gap after Inventory.

---

# F. ACCOUNTING WRITER MATRIX

| Writer / Consumer | Current evidence | Status |
|---|---|---|
| `save-journal-entry` | Edge v6 directly inserts `journal_entries` and `journal_lines` after tenant check | `DIRECT WRITER / NOT CENTRAL ENGINE` |
| `save-receipt-voucher` | Edge v5 directly inserts `cash_box`, `journal_entries`, `journal_lines`, updates `treasury`, and optionally `driver_ledger`; hard-coded company ID is present | `CRITICAL DRIFT` |
| `save-payment-voucher` | Edge v3 directly inserts `cash_box`, `journal_entries`, `journal_lines`, updates `treasury`; hard-coded company ID is present | `CRITICAL DRIFT` |
| `save-daily-settlement` | Edge v3 directly inserts `daily_settlements` and, for shortage, directly inserts `journal_entries` + `journal_lines`; hard-coded company ID is present | `CRITICAL DRIFT` |
| Sales Core | Production evidence shows Accounting effects inside `save_sales_invoice_atomic` | `CORE-CENTRALIZATION PARTIAL` |
| Purchase Receiving | Production evidence shows PurchaseIn and accounting impacts in domain core | `CORE-CENTRALIZATION PARTIAL` |
| Return Core | Production evidence indicates Accounting and customer-ledger effects inside `complete_return_atomic` | `CORE-CENTRALIZATION PARTIAL` |

### Finding

The project **does not yet have an Accounting Writer Matrix that closes at one central posting engine**.

The most serious live evidence is not theoretical: `save-receipt-voucher`, `save-payment-voucher`, and `save-daily-settlement` contain direct accounting/tresury/ledger mutation logic.

### Safe-change decision

No new `post_journal_entry` Contract was invented in Production during this closure because the exact intended canonical signature and existing Business Event contract have not yet been established across all accounting consumers.

The safe next closure unit is therefore **ACCOUNTING CORE CONTRACT RECONSTRUCTION**, not a blind mass rewrite.

---

# G. LEDGER WRITER MATRIX

| Ledger | Direct/indirect writer evidence | Current closure |
|---|---|---|
| Customer Ledger | Return/Sales domain evidence exists; complete writer inventory still incomplete | `OPEN` |
| Supplier Ledger | Purchase domain evidence exists; complete writer inventory still incomplete | `OPEN` |
| Driver Ledger | `update-driver-ledger` directly inserts `driver_ledger`; receipt voucher may also insert it directly | `CRITICAL DUPLICATE WRITER` |
| Treasury | Receipt/Payment functions directly update `treasury.current_balance` | `CRITICAL DUPLICATE WRITER` |
| Daily Settlement | `save-daily-settlement` directly inserts settlement + journal side effects | `PARTIAL / DUPLICATE ACCOUNTING` |

### Direct finding

`update-driver-ledger` is currently a thin API around a direct `driver_ledger` insert. It is not demonstrated as a centralized Ledger Engine.

---

# H. CONSUMER MATRIX

Production currently has a large Edge surface including:

- Main CRUD functions.
- Sales / Orders.
- Runsheets / Picking / Loading / Delivery / Return / Unloading.
- Manual Vouchers.
- Purchase Receiving.
- Journal / Financial reporting.
- Daily Settlement.
- Inventory Count.
- Adjustment.
- Recovery / E2E / canary / harness functions.

The complete matrix:

```text
PWA/main
PWA/warehouse apps
PWA/vouchers
PWA/picker
PWA/driver
other consumers
   ↓
Edge
   ↓
RPC / Core
   ↓
Tables
   ↓
Audit / registry
   ↓
Runtime endpoint
```

is **not yet fully proven operation-by-operation**.

Known positive closures include the major Warehouse Supervisor/Voucher/Inventory paths. The ERP-wide matrix remains open because several finance and legacy consumers still bypass a common core contract.

---

# I. SECURITY MATRIX

## Production positives

- Edge JWT verification exists for many production functions.
- Tenant-safe Main CRUD migrations are present.
- Warehouse team scope is enforced through backend RPCs.
- Inventory write boundaries have explicit migrations.
- Operation identity/unique keys exist in several core paths.

## Current advisor findings

Production security advisor currently reports WARN findings including callable `SECURITY DEFINER` functions such as:

- `enforce_van_branch_company_context()`
- `get_warehouse_team()`
- `set_active_warehouse_role(...)`

These may be intentional capability boundaries, but their exposure is still an explicit Security Matrix item and is not treated as closed automatically.

Leaked-password protection is currently disabled in Supabase Auth.

## Performance/security debt visible now

The Production performance advisor reports numerous:

- unindexed foreign keys
- RLS init-plan warnings
- multiple permissive policies
- unused indexes

These are not all P0 business blockers, but the list proves that `ZERO-DEBT` is not yet achieved.

---

# J. DEPLOYMENT LINEAGE MATRIX

| Layer | Evidence | Status |
|---|---|---|
| Git main commit | Available | `VERIFIED` |
| Current source path | Available for major artifacts | `PARTIAL` |
| Production Edge version | Available directly from Supabase | `VERIFIED` |
| Production Edge SHA | Available (`ezbr_sha256`) | `VERIFIED` |
| Git SHA ↔ deployed Edge SHA mapping | Not fully reconciled function-by-function | `OPEN` |
| PWA artifact SHA | Git evidence exists | `PARTIAL` |
| Hosting deployment event | Not proven for every PWA | `OPEN` |
| Browser runtime exact artifact | Not globally proven | `OPEN` |

The branch landscape itself is non-trivial and includes active/historical repair branches such as:

`cto-continuity-20260821`, `inventory-rescue-20260815`, `gold-master-vouchers-closure-20260820`, `task-028-loading-unloading-refactor`, and multiple `ctorepair-*` branches.

This is evidence that deployment/lineage governance still requires consolidation and explicit closure.

---

# K. CONCURRENCY RESULTS

### Proven structurally

- Row locking exists in core inventory movement.
- Unique operation identities exist in several domains.
- Transactional RPCs exist.
- Idempotency registries/keys exist.

### Not yet proven empirically

A true two-session race test has not been completed for the entire critical matrix.

Therefore:

`locks + unique indexes + transaction = NOT EQUAL TO concurrency proof`

The current status is:

**CONCURRENCY GATE = OPEN**

No sequential retry test is accepted as a substitute.

---

# L. DATA INTEGRITY MATRIX

| Area | Current evidence | Status |
|---|---|---|
| Companies | 3 current companies | `VERIFIED` |
| Users | 26 | `VERIFIED` |
| Branches | 5 | `VERIFIED` |
| Items | 50 | `VERIFIED` |
| Stock rows | 26 | `VERIFIED` |
| Inventory logs | 3 after explicit cleanup migrations | `VERIFIED CURRENT` |
| Stock vouchers | 0 | `VERIFIED CURRENT` |
| E2E orphan inventory evidence | Cleanup migration present | `CLEANUP APPLIED` |
| Test voucher/orphan company | Cleanup migration present | `CLEANUP APPLIED` |
| Accounting data integrity | No full event→journal→ledger reconciliation completed | `OPEN` |

---

# M. LEGACY / DEBT MATRIX

### Closed / materially retired

- Legacy `post_stock_movement` execution surface retired from application permissions.
- Legacy manual voucher receive path disabled in current Production history.
- Test/orphan inventory evidence cleaned from Production.
- Main CRUD hard-coded tenant path substantially remediated.
- Warehouse team scope tightened.

### Still open

- Direct receipt/payment accounting writers.
- Direct daily-settlement journal writer.
- Direct driver-ledger writer.
- Full Customer/Supplier Ledger writer convergence.
- Function-by-function Git/Production lineage.
- Browser/deployment proof.
- True concurrency proof.
- Remaining RLS/performance/security-advisor debt.

---

# N. KHALID CLAIM CORRECTIONS

A repository-wide search for the literal Arabic name `خالد` did not return a source file that can establish a Khalid-specific technical claim from the current repository.

Therefore no Khalid-specific correction is invented.

Claims from older reports are treated only as historical navigation unless their exact source is recovered and re-verified.

**Status: OPEN SOURCE ATTRIBUTION GAP**

---

# O. HYTHAM CLAIM CORRECTIONS

A repository-wide search for the literal Arabic name `هيثم` did not return a source file that can establish a Hytham-specific technical claim from the current repository.

Therefore no Hytham-specific correction is invented.

The only safe correction currently established is temporal: newer Production migrations supersede older snapshots when describing present Production state.

**Status: OPEN SOURCE ATTRIBUTION GAP**

---

# P. ALL OPEN DECISIONS

1. Canonical Accounting Posting Engine signature and transaction contract.
2. Canonical Customer Ledger engine and write boundary.
3. Canonical Supplier Ledger engine and write boundary.
4. Canonical Driver Ledger engine and whether existing direct writer becomes a facade or is retired.
5. Treasury posting contract and whether `current_balance` remains materialized state or becomes derived.
6. Daily Settlement accounting contract.
7. Security policy for deliberately callable `SECURITY DEFINER` capability functions.
8. Deployment authority for PWA artifacts and exact runtime promotion mechanism.
9. Concurrency scenario list and safe production/staging evidence policy.
10. Legacy harness retention vs archival/removal policy.

None of these decisions is silently assumed.

---

# Q. ALL REMAINING UNKNOWN

Critical unknowns are now narrowed but not eliminated:

- Exact complete Accounting Writer inventory across every Edge/RPC/trigger/consumer.
- Exact complete Ledger Writer inventory across every domain.
- Full PWA → Edge → RPC → Core → Table mapping for every critical operation.
- Exact Git SHA → deployed Edge SHA mapping for all production functions.
- Exact PWA artifact → runtime deployment proof.
- True multi-session concurrency evidence for each critical race class.
- Full event-to-journal-to-ledger reconciliation with real controlled business events.
- Full adversarial cross-tenant proof for every sensitive financial writer.

---

# R. READINESS GATE

| Gate | Status |
|---|---|
| Historical reconstruction | `PASS` |
| Production freshness | `PASS` |
| Inventory core | `PASS / FOUNDATION` |
| Voucher domain | `PASS / FOUNDATION` |
| Tenant / Identity | `PASS / STRONG` |
| Main CRUD | `PASS / PARTIAL ZERO-DEBT` |
| Accounting core | `FAIL — DIRECT WRITERS REMAIN` |
| Ledger core | `FAIL — DIRECT WRITERS REMAIN` |
| Consumers | `FAIL — MATRIX INCOMPLETE` |
| Security | `FAIL — ADVISOR DEBT REMAINS` |
| Deployment lineage | `FAIL — NOT FULLY PROVEN` |
| Concurrency | `FAIL — NOT EMPIRICALLY PROVEN` |
| Data integrity | `PASS CURRENT SNAPSHOT / ACCOUNTING OPEN` |
| Global zero-debt | `FAIL` |
| Autonomous CTO Ready | **`NO`** |

---

# CRITICAL FORENSIC FINDINGS

## Finding F-ACCT-001 — Direct Receipt Accounting Writer

Production Edge `save-receipt-voucher` v5 directly writes:

- `cash_box`
- `journal_entries`
- `journal_lines`
- `treasury`
- optionally `driver_ledger`

and contains a hard-coded `company_id`.

This violates the target centralized Accounting/Ledger direction and the tenant-safety discipline established elsewhere.

## Finding F-ACCT-002 — Direct Payment Accounting Writer

Production Edge `save-payment-voucher` v3 directly writes:

- `cash_box`
- `journal_entries`
- `journal_lines`
- `treasury`

and contains the same hard-coded company ID pattern.

## Finding F-LEDGER-001 — Direct Driver Ledger Writer

`update-driver-ledger` v1 is a direct `driver_ledger.insert(...)` API rather than a proven centralized Ledger engine.

## Finding F-SETTLE-001 — Daily Settlement Contains Accounting Side Effects

`save-daily-settlement` v3 directly creates journal entries and journal lines when shortage exists, and also contains a hard-coded company ID.

## Finding F-SEC-001 — Production Security Advisor Debt

Production Security Advisor reports callable `SECURITY DEFINER` functions and disabled leaked-password protection. These remain explicit security gates.

---

# SAFE EXECUTION DECISION

No blind Production business-contract rewrite was performed in this closure.

Reason:

The exact central Accounting/Ledger contract is **not yet proven across all consumers**. Creating a new `post_journal_entry` API by assumption would violate the directive.

The correct next Closure Unit is:

```text
ACCOUNTING CORE FORENSIC
→ reconstruct exact event/posting contracts
→ map all direct writers
→ prove account/tenant scope
→ design canonical central posting boundary only from evidence
→ stage
→ test
→ production deploy
→ production verify
→ close
```

Then immediately:

```text
LEDGER CORE FORENSIC
→ Customer
→ Supplier
→ Driver
→ Treasury
→ Daily Settlement
```

---

# SELF-AUDIT

## Proven

- Current Production project and current snapshot.
- Latest Production migration lineage relevant to the current state.
- Current Production Edge Function versions for major domains.
- Inventory core centrality at the current surface.
- Direct accounting/ledger writers that prevent autonomous closure.
- Security advisor findings.
- Current branch landscape.

## Not Proven

- Full accounting/ledger central core.
- Complete consumer graph.
- Complete deployment artifact lineage.
- true concurrency races across all critical operations.
- Complete Khalid/Hytham source attribution.

## Final

**AUTONOMOUS CTO NOT READY**

The project is materially closer. The next responsible step is not to restart Inventory; it is to close the financial core and then adversarially attempt to break the resulting ERP-wide closure claims.
