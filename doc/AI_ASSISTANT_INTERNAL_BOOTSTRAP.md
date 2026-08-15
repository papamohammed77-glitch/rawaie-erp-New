# RAWAEA ERP — INTERNAL AI ASSISTANT BOOTSTRAP

## Purpose

This document prepares a new AI assistant that will work **only through internal messages/files** and has **no direct access to GitHub, Supabase, PostgreSQL, Edge Functions, or external web systems**.

The assistant must therefore receive the files below, in the exact priority order shown, so it can understand the project without external queries.

> **Important:** This file is a navigation/bootstrapping index. It is not itself a substitute for the source files listed below.

---

# 1. REQUIRED READING ORDER

## TIER 1 — MASTER CONTEXT / AUTHORITY

### 1. `CTO/00_MASTER_CONTEXT.md`
**Role:** Master institutional context, truth hierarchy, project scope, architecture principle, rescue scope, confirmed production facts, and mandatory CTO working rule.

Main concepts:
- ONE CORE / ONE SOURCE OF TRUTH / controlled domain execution
- Inventory-first execution order
- Production truth hierarchy
- Historical vs Current vs Target distinction
- Evidence → Reconciliation → Target Decision → Minimal Patch → Tests → Review → Production GO → Post-Deploy Verification

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/00_MASTER_CONTEXT.md

### 2. `CTO/01_SOURCE_AUTHORITY_MAP.md`
**Role:** Exact authority map showing which repository folders and evidence sources are authoritative for Production truth, Current source, Historical reference, and Target candidates.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/01_SOURCE_AUTHORITY_MAP.md

### 3. `doc/CTO VISION REPORT.md`
**Role:** Owner/CTO vision, long-term architectural direction, business intent, and system goals.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/CTO%20VISION%20REPORT.md

### 4. `doc/CTO RECONSTRUCTION REPORT.md`
**Role:** Reconstruction of the project context and historical development decisions.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/CTO%20RECONSTRUCTION%20REPORT.md

### 5. `doc/تقرير CTO الشامل.md`
**Role:** Broad consolidated CTO report covering architecture, implementation history, and project-wide context.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20CTO%20%D8%A7%D9%84%D8%B4%D8%A7%D9%85%D9%84.md

---

# 2. EXECUTION PLAN / CURRENT POSITION

### 6. `CTO/PLAN-STATUS-CURRENT.md`
**Role:** Current execution map and staged task order.

This is essential for knowing:
- what was closed,
- what is active,
- what is queued,
- what must not be considered started merely by reading it,
- the Inventory → Voucher → Loading/Unloading → Van Sales → Edge Functions → Accounting → Final Proof sequence.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/PLAN-STATUS-CURRENT.md

### 7. `CTO/03_CURRENT_STATUS.md`
**Role:** Current reconciliation status, confirmed Production blockers, current Inventory architecture facts, and explicitly unapproved changes.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/03_CURRENT_STATUS.md

### 8. `CTO/02_EXECUTION_LOG.md`
**Role:** Chronological execution record. Use it to understand what was actually attempted, changed, tested, rejected, or deployed.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/02_EXECUTION_LOG.md

### 9. `CTO/MASTER-EXECUTION-LOG.md`
**Role:** Higher-level master execution ledger across the rescue effort.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/MASTER-EXECUTION-LOG.md

### 10. `CTO/RESCUE-RECONCILIATION-2026-08-15.md`
**Role:** **Latest rescue-state reconciliation and most important current progress snapshot.** It contains the latest closure state for `complete-picking`, the current `send-stock-voucher` patch state, Production reality distinctions, and the current Zero-Debt closure queue.

At the time this bootstrap was created, it records:
- `complete-picking` = 100% CLOSED / Production Runtime Verified
- `send-stock-voucher` = patched in rescue branch; review/verification gate next
- remaining queue = receive-stock-voucher → receive-purchase → bulk-stock-adjustment → save-sales-invoice → complete-return → complete-order-delivery → global writer sweep → Accounting

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/RESCUE-RECONCILIATION-2026-08-15.md

---

# 3. HISTORICAL KNOWLEDGE / HANDOVER

### 11. `CTO/02_HISTORICAL_KNOWLEDGE_INDEX.md`
**Role:** Navigation index for historical knowledge and source files.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CTO/02_HISTORICAL_KNOWLEDGE_INDEX.md

### 12. `Edge_Function_Reports/_HISTORICAL/RAWAEA ERP HANDOVER.md`
**Role:** Institutional handover covering the ERP as a whole, legacy architecture, business flows, known issues, and historical design intent.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/Edge_Function_Reports/_HISTORICAL/RAWAEA%20ERP%20HANDOVER.md

### 13. Historical Edge Function repository
`papamohammed77-glitch/rawaie-erp-review/Edge_Functions/`

This source is essential for recovering original Edge Function behavior when a file is missing from `rawaie-erp-New/Original` or `Current`.

Subareas:
- `Edge_Functions/original/` — historical/original function implementations
- `Edge_Functions/current/` — current/reference function set in the historical review repository
- `Edge_Functions/archive/` — archived material

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-review/tree/rescue/manual-vouchers-inventory-core/Edge_Functions

> The new assistant has no direct repository access, so the operator should provide the actual contents of any historical function required for a closure unit.

---

# 4. ARCHITECTURE / PROCESS CONTROL

### 14. Architecture Constitution
Find and provide the active architecture constitution referenced by `CTO/01_SOURCE_AUTHORITY_MAP.md`.

Expected role:
- governing architecture laws,
- One-Core rule,
- source-of-truth boundaries,
- domain ownership,
- non-negotiable invariants.

### 15. Execution Protocol
Find and provide the active execution protocol referenced by `CTO/01_SOURCE_AUTHORITY_MAP.md`.

Expected role:
- evidence hierarchy,
- surgical patch discipline,
- test/deployment gates,
- production verification rules.

### 16. Domain Execution Order
Find and provide the active domain execution order referenced by `CTO/01_SOURCE_AUTHORITY_MAP.md`.

Expected role:
- Inventory-first sequencing,
- dependency ordering,
- preventing premature work on later domains.

> The paths for these three documents are referenced by the source-authority map but were not individually captured in this bootstrap because the repository layout has evolved. The operator must supply their current contents before treating any guessed path as authoritative.

---

# 5. CURRENT APPLICATION / SOURCE ARTIFACTS

### 17. `Current/`
**Role:** Official current development source. This is the place where the final approved Edge Functions and application files must exist.

Important subareas:
- `Current/Edge_Functions/`
- `Current/PWA/`
- any current SQL or migration source needed for the active closure unit

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/tree/main/Current

### 18. `Original/`
**Role:** Baseline source in the main project repository.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/tree/main/Original

### 19. `supabase/`
**Role:** SQL/migration source. Distinguish clearly between deployed Production truth and unreleased migration candidates.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/tree/main/supabase

### 20. `SQL_Evidence/`
**Role:** Persisted Production evidence snapshots and diagnostic exports.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/tree/main/SQL_Evidence

### 21. `Inventory/`
**Role:** Inventory-specific contracts, findings, and rescue material.

Link:
https://github.com/papamohammed77-glitch/rawaie-erp-New/tree/main/Inventory

---

# 6. OPERATOR-PROVIDED CURRENT PRODUCTION SNAPSHOTS

Because this assistant cannot query Supabase directly, the operator must periodically provide the latest Production evidence for the current closure unit:

1. Deployed Edge Function source/version/hash.
2. Relevant deployed PostgreSQL RPC definitions.
3. Relevant table schemas/constraints/triggers.
4. Relevant Production runtime logs.
5. Consumer/application source used by the function.
6. Post-deployment verification results.

The assistant must never treat an old snapshot as timeless Production truth.

---

# 7. REQUIRED WORKING METHOD FOR THE NEW ASSISTANT

For every single Closure Unit:

`PRE-CHANGE SELF-AUDIT`
→ `READ SOURCES`
→ `RECONCILE HISTORICAL / ORIGINAL / CURRENT / PRODUCTION SNAPSHOT`
→ `LOSS / GAIN MATRIX`
→ `TARGET DECISION`
→ `SURGICAL PATCH`
→ `TEST`
→ `PRODUCTION EVIDENCE REVIEW`
→ `CLOSE 100%`
→ `NEXT UNIT`

The assistant must work one closure unit at a time. It must not attempt to "solve the whole ERP" in one response.

It must never:
- invent missing facts;
- confuse Historical, Current, Staging, and Production;
- claim deployment from Git alone;
- claim 100% with unknown/unverified items;
- stop at a defect without first trying to resolve it;
- wait for the operator to locate a source that can be found from the supplied repository materials;
- create parallel source-of-truth repositories or uncontrolled copies.

---

# 8. IMMEDIATE RESCUE CONTEXT TO LOAD

The new assistant should begin with this understanding:

### Project
RAWAEA ERP is an FMCG/distribution ERP on Supabase/PostgreSQL + Edge Functions + PWA clients.

### Current rescue scope
Inventory / Manual Stock Vouchers / Warehouse / Van Sales.

### Core architectural goal
**ONE CORE / ONE SOURCE OF TRUTH / controlled domain execution.**

### Inventory rescue invariant
- `stock_branches.qty` = physical stock state.
- `stock_branches.allocated_qty` = reservation state.
- `post_stock_movement` = central Physical Stock Movement engine.
- `reserve_stock` = Reservation engine, not Physical Movement.
- Picking must not decrement physical stock merely because items are picked.
- Physical movement functions must not bypass the central movement engine.

### Current closure queue
Use the latest `CTO/RESCUE-RECONCILIATION-2026-08-15.md` as the starting execution position, not an older report.

---

# 9. FILE PACKET RECOMMENDATION FOR A MESSAGE-ONLY ASSISTANT

If the assistant must be initialized using a finite packet rather than the whole repository, provide these first:

1. `CTO/00_MASTER_CONTEXT.md`
2. `CTO/01_SOURCE_AUTHORITY_MAP.md`
3. `doc/CTO VISION REPORT.md`
4. `doc/CTO RECONSTRUCTION REPORT.md`
5. `doc/تقرير CTO الشامل.md`
6. `CTO/PLAN-STATUS-CURRENT.md`
7. `CTO/03_CURRENT_STATUS.md`
8. `CTO/02_EXECUTION_LOG.md`
9. `CTO/MASTER-EXECUTION-LOG.md`
10. `CTO/RESCUE-RECONCILIATION-2026-08-15.md`
11. `CTO/02_HISTORICAL_KNOWLEDGE_INDEX.md`
12. `Edge_Function_Reports/_HISTORICAL/RAWAEA ERP HANDOVER.md`
13. `doc/Prompt`
14. The current and historical Edge Function file(s) for the active Closure Unit
15. The relevant Current PWA consumer file(s)
16. The relevant Production SQL evidence/exports for the active Closure Unit
17. The relevant deployed Edge Function source/version/hash snapshot

This packet gives the assistant the project context, execution method, current state, historical knowledge, source authority, and enough technical evidence to work without external queries.

---

# 10. NON-NEGOTIABLE FINAL RULE

The assistant is a **message-only execution reviewer/implementer**.

It may reason from the supplied artifacts, compare them, identify gaps, prepare precise patches, and produce closure reports.

It must not claim access to GitHub or Supabase it does not actually have.

When evidence is missing, it must explicitly identify the exact file/snapshot needed from the operator rather than inventing it.

The objective remains:

# ZERO-DEBT INVENTORY RESCUE

with no hidden gaps carried into later phases.
