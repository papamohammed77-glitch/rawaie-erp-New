# RAWAEA ERP — FOUNDATIONAL SYSTEM & APPLICATION RESPONSIBILITY CONTRACT

**Status:** MANDATORY KNOWLEDGE RECORD  
**Date:** 2026-08-19  
**Scope:** System-wide understanding, data authority, application responsibilities, surgical change policy, inventory-rescue context

---

## 1. Purpose

This document records foundational business and architectural concepts that every future CTO, assistant, developer, or reviewer must understand **before making changes** to RAWAEA ERP.

This is a knowledge/contract record only. It is not a Production deployment instruction and does not authorize code or database mutation by itself.

The project is under active reconstruction and rescue. Existing Production data is **experimental/test-oriented**, and historical artifacts may contain obsolete, conflicting, or superseded behavior. No source is authoritative merely because it is old or because it exists.

The mandatory truth hierarchy remains the one defined in `CTO/00_MASTER_CONTEXT.md`:

1. Latest explicitly identified Production SQL evidence.
2. Actual deployed PostgreSQL/RPC definitions.
3. Actual deployed Edge Function behavior.
4. Current application source.
5. Approved architecture/ADR contracts.
6. Historical documentation.
7. Unreleased migrations/designs as target candidates only.

Conflicts must be recorded, not guessed away.

---

## 2. Experimental Data Hygiene

The system is still being established. Test and historical data may confuse a future CTO or assistant if it is mistaken for authoritative business state.

Therefore:

- Identify experimental/test fixtures explicitly.
- Remove obsolete test data when safe and justified.
- Do not use experimental records as business truth without classification.
- Preserve necessary audit evidence before cleanup.
- Never destroy real operational evidence merely because it looks old.
- Cleanup must be traceable and reversible where practical.

The objective is to leave the project with a clean, comprehensible baseline for future maintainers.

---

## 3. Product / Item Master Authority

### 3.1 Core principle

Products/items are a **central master-data domain**.

The intended RAWAEA model is:

`Central Item Master`
→ available to all branches/departments
→ searchable/scannable by barcode
→ consumed by operational applications

Items are **not conceptually owned by a branch merely because that branch carries stock**.

Stock belongs to branch/location inventory state; item identity and item master data belong to the central master-data domain.

### 3.2 Creation authority

The system's primary item-creation authority is the **system/master-data side**, not operational PWA clients.

A purchasing user may discover an item that does not yet exist while preparing a Purchase Order. The purchasing workflow should be able to **request central item coding/creation**, not silently create an uncontrolled master item from a branch PWA.

Once centrally approved/coded, the item becomes available to:

- purchasing,
- warehouses,
- sales,
- delivery,
- reporting,
- other approved departments.

### 3.3 Operational consequence

A branch or user application may search, scan, select, and transact against an item, but should not become an uncontrolled competing Item Master authority.

This is a **source-of-truth rule**, not merely a UI preference.

---

## 4. PWA Responsibility Model

Operational PWA applications are **functional user applications**.

They are not miniature ERP administration systems.

### They may:

- authenticate approved users,
- execute their assigned operational task,
- submit controlled business events,
- read authorized master/transaction data,
- display operational status.

### They must not become uncontrolled authorities for:

- creating master user accounts,
- creating central product master records directly,
- inventing major business events outside their contract,
- silently changing master-data ownership,
- bypassing centralized business rules.

The general principle is:

> **PWA = execution surface; ERP/Core = authority surface.**

Operational users are executors within an approved role boundary.

---

## 5. Application/Domain Responsibility Inventory

Every assistant must maintain a live understanding of the entire application topology, even when working on only one closure unit.

### 5.1 System of record / main application

`main.html`

Role:

- central ERP operating surface,
- administration and master-data operations,
- broad system visibility,
- coordination of major workflows,
- central management functions that should not be delegated to every PWA.

It is the application in which the complete system role model becomes visible.

### 5.2 Manual Warehouse Vouchers

`vouchers.html`

Must be studied as a separate warehouse-operation domain, including:

- the number and types of manual stock authorizations,
- which operations are independent of Runsheets,
- SEND / RECEIVE / COMPLETE / CANCEL semantics,
- branch/location effects,
- inventory effects,
- authorization and audit implications,
- interaction with the central stock engine.

The exact operation matrix must be derived from the actual application, Current source, Historical source, Production definitions, and Production evidence.

### 5.3 Van Sales

`van-sales.html`

This is a major dependent domain and must be understood as a complete daily lifecycle, not a single sales screen.

The analysis must cover at minimum:

- opening/start of the day,
- vehicle and mobile-stock context,
- route/run assignment,
- customer coverage,
- sales transactions,
- cash/credit behavior,
- customer receivables,
- representative personal liability/settlement,
- vehicle merchandise balance,
- collected cash balance,
- target/achievement tracking,
- customer and route exceptions,
- complaints and representative issues,
- end-of-day settlement,
- interaction with warehouse stock,
- interaction with accounting and ledgers.

The vehicle is not automatically a generic branch in every context. Its role must be understood as the project's approved **mobile stock container / operational location model**, and that conclusion must be reconciled against the historical architecture records and actual Production schema.

### 5.4 Sales Channels

The system contains multiple sales paths. Each must have its own authority boundary and stock/accounting semantics.

At minimum study:

- `POS.html`
- `Telesales.html`
- `Order-taker.html`
- `store/index.html`
- `van-sales.html`

The assistant must understand how orders originate, how they are confirmed, how fulfillment begins, when stock is reserved, when physical stock moves, when revenue/accounting occurs, and which system/domain owns each transition.

### 5.5 Runsheet Warehouse Operations

Study the complete lifecycle and responsibilities of:

- `picker.html`
- `loader.html`
- `returns.html`
- `driver.html`
- `unloader.html`

These are not interchangeable views. Each represents a specific operational stage in the Runsheet lifecycle.

The assistant must understand the full lifecycle and state transitions before modifying any one of them.

### 5.6 Physical Inventory / Counting

`counter.html`

Must be studied to determine:

- its exact operational role,
- what kinds of stock counts it performs,
- how many distinct inventory-count operations it supports,
- how count results affect stock,
- whether adjustments are generated directly or through a centralized mechanism,
- its relationship to inventory logs and audit trails.

### 5.7 Vehicle as Mobile Stock Container

The vehicle concept must be studied historically and currently.

The assistant must reconcile:

- Vehicle entity,
- branch/location semantics,
- VAN inventory state,
- driver/representative ownership,
- Loading,
- Van Sales,
- Unloading,
- settlement.

Do not infer `Vehicle = Branch` or `Vehicle != Branch` from one file. Use the full historical and current architecture record.

---

## 6. Architectural State of Applications

Not every application has the same maturity.

The assistant must distinguish at least:

- **Advanced / near-complete applications** — contain substantial business logic and months of accumulated behavior.
- **Partially implemented applications** — significant functionality exists but closure work remains.
- **Structural / skeleton applications** — mostly scaffolding and therefore less behaviorally authoritative.

No application may be judged or rewritten purely from file length or visual appearance.

Before changing an application, determine its maturity and preserve established working capabilities.

---

## 7. Inventory Rescue Architecture

The current rescue direction is:

### ONE CORE / ONE SOURCE OF TRUTH

Physical stock movements must be centralized.

Conceptual boundary:

`Physical Stock Movement`
→ `post_stock_movement`
→ stock state + inventory evidence

Reservation is distinct:

`Reservation`
→ `reserve_stock`
→ `allocated_qty`

Picking is not itself a physical stock movement merely because stock is being prepared.

Loading, Unloading, Sales, Returns, Manual Stock Movements, Purchase Receiving, Adjustments, and other physical stock events must be reconciled to the central movement engine.

No parallel Physical Stock Engine may survive merely because it is historical.

---

## 8. Production vs Current vs Historical

The assistant must always distinguish:

- **Production:** what is actually deployed/running now.
- **Current:** official development source where final approved changes must live.
- **Original:** baseline source in the main repository when present.
- **Historical review repository:** recovery source when Original/Current artifacts are missing.
- **Target candidate:** intended architecture not yet proven deployed.

A result that exists only in Current is not a Production result.

A Production result that is not represented in Current is a **source-of-truth drift** that must be repaired.

---

## 9. Application Change Law — Surgical Modification

This is mandatory for advanced/near-complete application files.

### Never replace the whole application file casually.

A six-month development history may contain valuable functionality that is not visible from the defect being investigated.

Therefore:

1. Read the full relevant file.
2. Compare it with the original/historical source.
3. Identify the exact defective function, block, or line.
4. Preserve all working capabilities.
5. Replace the smallest possible defective unit.
6. Re-check all dependent functions and consumers.
7. Test before and after behavior.

The default is:

> **Add capability, preserve working capability, remove only proven defects.**

### Controlled refactor is allowed when necessary

A broader reorganization may be justified if the existing organization prevents correctness, but it must still preserve business capability and UX intent.

The purpose is not merely to make code shorter.

The purpose is to make it:

- more correct,
- more reliable,
- more maintainable,
- more secure,
- more coherent with the central architecture,
- and better for the user.

Never simplify by deleting proven working behavior.

---

## 10. Incremental Excellence Principle

Every approved application change should follow:

`Existing capability`
+ `targeted correction`
+ `new value`
− `no unexplained loss`

The target is not merely "not breaking the app".

The target is to **preserve what already works and improve the system's correctness, attractiveness, usability, and operational value**.

---

## 11. Database and Workflow Impact Study

Before modifying any application or Edge Function, the assistant must study its impact on:

- PostgreSQL tables,
- RPCs/functions,
- triggers,
- constraints,
- RLS/security,
- Edge Function consumers,
- application consumers,
- workflow transitions,
- inventory state,
- accounting/ledger state,
- audit evidence.

A local code fix that breaks a downstream workflow is not a successful fix.

---

## 12. Evidence and Recording Rule

These concepts are now a permanent project record.

Every future CTO/assistant must read this document as part of its system initialization and must incorporate the concepts into its self-audit and pre-change responsibility map.

The next assistant must explicitly acknowledge in its Self-Audit that it understands:

- central Item Master authority,
- PWA execution-only role,
- application topology and domain boundaries,
- Vehicle/mobile-stock semantics,
- sales-path separation,
- Runsheet warehouse lifecycle,
- inventory counting responsibilities,
- experimental-data hygiene,
- ONE CORE / ONE SOURCE OF TRUTH,
- surgical application modification,
- and preservation-plus-enhancement of working capabilities.

---

## 13. Mandatory Working Sequence

For any future application/function closure unit:

`PRE-CHANGE SELF-AUDIT`
→ `READ COMPLETE FILE`
→ `READ HISTORICAL / ORIGINAL SOURCES`
→ `READ PRODUCTION REALITY`
→ `MAP RESPONSIBILITIES`
→ `MAP CONSUMERS / DEPENDENCIES`
→ `LOSS / GAIN MATRIX`
→ `TARGET DECISION`
→ `SURGICAL PATCH`
→ `TEST`
→ `PRODUCTION VERIFICATION`
→ `CLOSE 100%`
→ `NEXT UNIT`

No report may be treated as a substitute for execution.

---

## 14. Governance Rule for Future CTOs

Any assistant that repeatedly:

- invents missing information,
- ignores available source repositories,
- rewrites advanced applications unnecessarily,
- removes proven features without evidence,
- mixes operational execution with master-data authority,
- treats PWA clients as system administrators,
- bypasses the central Inventory Core,
- or declares completion without Production proof

is failing the project's execution standard.

The required response is corrective supervision and, if repeated, replacement.

---

## 15. Final Principle

RAWAEA ERP is not being rebuilt from zero.

It is being **reconciled, rescued, hardened, centralized, and improved** while preserving the accumulated value of months of development.

The correct engineering posture is:

> **Do not lose what works. Do not preserve what is wrong. Centralize what must be centralized. Improve what can be improved. Prove what you claim.**
