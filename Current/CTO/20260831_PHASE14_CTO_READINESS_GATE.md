# RAWAEA ERP — PHASE 14 CTO READINESS GATE

**Date:** 2026-08-31  
**Phase:** 14 — CTO Readiness Gate  
**Status:** CLOSED — NOT READY FOR PRODUCTION ENGINEERING  
**Production mutation:** None.

## READINESS QUESTIONS

### BUSINESS — ما دورة حياة النظام؟

**Answered with evidence:** نعم.

The current/historical business model is understood as sales-channel → order → runsheet/fulfillment → picking/reservation → loading/physical movement → delivery → return/settlement, plus purchase receiving and accounting/ledger consequences. Historical workflow evidence establishes the business state model, while current database functions establish the hardened transaction path. fileciteturn40file0L2-L2

### ARCHITECTURE — من يملك كل Business Responsibility؟

**Answered at critical-core level:** نعم.

Current Production shows specialized Edge Function orchestrators and database-side atomic writers. Physical stock is delegated to `post_stock_movement`; accounting and ledger responsibilities are delegated to dedicated writers.

### DATABASE — ما Source of Truth لكل كيان؟

**Answered for critical entities:** نعم.

Current FK/RLS/schema inspection establishes `companies`, `users`, `branches`, `items`, `orders`, `order_details`, `runsheets`, stock tables, purchasing tables, and journal/ledger tables and their relationship graph.

### INVENTORY — من يكتب Physical Stock؟

**Answered for inspected movement engine:** نعم.

`post_stock_movement` is the proven current physical stock movement authority for the inspected movement families. Complete writer exclusivity across every function is still an open closure unit.

### ACCOUNTING — من ينشئ Journal؟

**Answered for the current posting core:** نعم.

`post_journal_entry` is the current database-side balanced journal writer for the inspected accounting path.

### LEDGER — من يكتب كل Ledger؟

**Answered for current known writers:** نعم.

Dedicated customer/supplier/driver ledger writers exist. Full writer matrix across all historical/current consumers remains open.

### AUTH — من يحدد Tenant؟

**Answered:** نعم.

Current critical code resolves authenticated Supabase identity through `public.users.auth_id` to `company_id`; `app_private.current_user_company_id()` is the database-side tenant resolver.

### SECURITY — من يستطيع تنفيذ كل capability؟

**Answered with blocking finding:** نعم، والنتيجة غير مرضية.

The authorization architecture contains sound tenant-context functions and many correctly company-scoped policies, but core order/fulfillment policies are too broad:

- `orders`: authenticated users are allowed by a broad `ALL` policy based only on `auth.role()='authenticated'`; direct table grants are also broad.
- `order_details`: same class of broad authenticated `ALL` policy.
- `run_sheet_details`: same class of broad authenticated `ALL` policy.
- `daily_settlements`: `ALL` policy with `USING true` / `WITH CHECK true`, while anon/authenticated have SELECT grants.

These are structural tenant-isolation defects. Current Production contains only one company, so no cross-tenant leakage is observed in the current dataset, but the security design is not safe for multi-tenant expansion.

### CONSUMERS — من يستدعي كل capability؟

**Partially answered:** not complete.

Critical consumer paths have been traced for sales, purchase, loading, stock vouchers, and the governed main fragments. Full all-function/all-PWA consumer coverage remains open.

### DEPLOYMENT — ما الموجود فعلًا في Production؟

**Answered for inspected critical Edge functions:** نعم.

Production versions and deployment SHA-256 artifacts were retrieved directly. Current Git source was retrieved separately. Full cryptographic Git→Production lineage remains open.

### DATA — ما الحالات الشاذة الحالية؟

**Answered:** نعم.

Current anomalies:
- one active/non-inactive `users` row without `auth_id`;
- two cancelled `VoidInvoice` journal headers with zero lines;
- three `VoidInvoice` inventory-log rows.

The first two are not repaired because provenance is not yet proven.

### HISTORY — لماذا يوجد كل Legacy مهم؟

**Answered at major-contract level:** نعم.

Historical architecture/ADR/workflow/security records were reconstructed and reconciled against current Production. Historical claims were not promoted to current truth without fresh proof. fileciteturn39file0L2-L2 fileciteturn41file0L2-L2 fileciteturn42file0L2-L2

### TARGET — إلى أين يجب أن يصل النظام؟

**Answered:** نعم, at evidenced target direction.

The target direction is tenant-safe specialized PWAs, canonical Edge/RPC transaction writers, centralized physical stock movement, atomic accounting/ledger posting, idempotency, auditability, and retirement of stale consumers without breaking active workflows.

## READINESS BLOCKERS

### BLOCKER 1 — P0 Tenant Isolation

The four security findings recorded in Phase 6 are not closed.

### BLOCKER 2 — Direct Table Grant Exposure

Core order/fulfillment tables retain broad anon/authenticated table grants. Safe least-privilege remediation requires consumer-matrix proof first.

### BLOCKER 3 — Complete Consumer Graph Not Proven

The protocol requires `CONSUMER → CAPABILITY → FUNCTION → TABLE` for every critical business flow. The current investigation covers critical paths but does not claim exhaustive all-function proof.

### BLOCKER 4 — Deployment Lineage Incomplete

Current Git and Production Edge source match at wrapper level for the inspected functions, but a complete release/commit/deployment artifact chain is not proven.

### BLOCKER 5 — Two-Tenant Authorization Harness Missing

Because Production contains only one company, the broad-policy defect cannot be exercised against real multi-tenant data. A controlled non-production two-tenant fixture is required before Production policy changes.

### BLOCKER 6 — New-main Runtime Replacement Not Certified

The clean-room New-main shell remains a candidate. It is not certified as the current production UI replacement.

## WHAT IS READY

`READY FOR FORENSIC EXECUTION`

The project has sufficient direct evidence for disciplined forensic engineering and targeted design work.

## WHAT IS NOT READY

`NOT READY FOR PRODUCTION ENGINEERING`

No Production DDL/DML or deployment change is authorized by this readiness gate.

## PHASE 15 DECISION

The protocol requires Phase 15 Execution Mode only after the CTO Readiness Gate is passed.

Because this gate is **NOT READY**, Phase 15 is intentionally **NOT ENTERED**.

No Production policy, code, deployment, or business data was changed as a workaround for the failed gate.

## EXIT GATE

`PHASE 14 CLOSED`

`CTO READINESS = NOT READY FOR PRODUCTION ENGINEERING`

`FORENSIC EXECUTION = READY`

`PRODUCTION EXECUTION = BLOCKED`
