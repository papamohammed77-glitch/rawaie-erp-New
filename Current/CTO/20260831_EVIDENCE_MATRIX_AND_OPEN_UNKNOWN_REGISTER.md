# RAWAEA ERP — EVIDENCE MATRIX & OPEN UNKNOWN REGISTER

**Date:** 2026-08-31  
**Purpose:** Readiness evidence required by the Master CTO Onboarding & Continuity Protocol  
**Production mutation:** None.

## EVIDENCE MATRIX

| Control / Claim | Direct Evidence | Current Status | Confidence | Closure |
|---|---|---|---|---|
| Production project identity | Supabase direct project inspection | SMART ERP / `fiilmooggumokxanwiyx` | HIGH | CLOSED |
| Git current source | GitHub direct repository/branch/file inspection | `main` observed; active changes continue | HIGH | CLOSED |
| Historical source | `rawaie-erp-review` direct docs/code | Historical architecture and contracts reconstructed | HIGH | CLOSED |
| Fresh Production snapshot | Direct SQL + Edge runtime inspection | Timestamped structural/data/security/runtime snapshot | HIGH | CLOSED |
| Stock invariants | Direct SQL | All tested invariants clean | HIGH | CLOSED FOR SNAPSHOT |
| Physical stock writer | Production function definition | `post_stock_movement` is current canonical writer for inspected movements | HIGH | CLOSED FOR IDENTIFIED CORE |
| Reservation engine | Production function catalog/definition | `reserve_stock`, `release_stock_reservation` | HIGH | CLOSED FOR IDENTIFIED CORE |
| Journal writer | Production function definition | `post_journal_entry` enforces balance/company/idempotency/audit | HIGH | CLOSED FOR IDENTIFIED CORE |
| Supplier ledger gap history | Historical workflow + current RPC | Historical gap now addressed in `receive_purchase_atomic` | HIGH | CLOSED |
| Tenant context | Production `app_private` functions + current Edge code | `auth.uid → users.auth_id → users.company_id` | HIGH | CLOSED |
| Tenant RLS on order tables | Production policy/grant query | Broad policy/grants remain | HIGH | OPEN P0 |
| Tenant RLS on settlements | Production policy/grant query | `USING true / WITH CHECK true` with SELECT exposure | HIGH | OPEN P0 |
| Critical Edge source/deployment presence | Supabase deployed source + Git source | Current deployed versions retrieved | HIGH | CLOSED FOR INVENTORY |
| Git→Production release lineage | Git + Supabase comparison | Wrapper-level parity observed; full release chain not proven | MEDIUM-HIGH | OPEN |
| Runtime 410 traffic | Direct Edge logs + Git workflows | Stale verification/CI traffic strongly indicated | HIGH | CLOSED AS CLASSIFICATION; CLEANUP OPEN |
| New-main candidate status | Git source + PR #61 | Candidate; not replacement-certified | HIGH | OPEN |
| Active user without auth_id | Production SQL | One row | HIGH | OPEN PROVEN DATA CONDITION |
| Empty cancelled void journal headers | Production SQL + journal semantics | Two rows, cancelled VoidInvoice, zero lines | HIGH | OPEN PROVEN DATA CONDITION |
| Two-tenant authorization proof | No current Production fixture; staging not mirror | Not demonstrated | HIGH | OPEN |

## OPEN UNKNOWN REGISTER

### U-001 — Complete active consumer graph

Needed: every critical capability mapped to its current UI/Edge/RPC consumer, including legacy/test callers.

### U-002 — Global inventory writer exclusivity

Needed: exhaustive evidence that no active path outside `post_stock_movement` mutates `stock_branches.qty` or inserts physical inventory movement records.

### U-003 — Global accounting writer exclusivity

Needed: exhaustive evidence that all active journal/ledger writers use the canonical financial engines.

### U-004 — Git-to-Production deployment lineage

Needed: commit → build/deployment artifact → Production version mapping for critical functions and Cloudflare application artifacts.

### U-005 — Two-tenant RLS test harness

Needed: controlled fixture proving cross-tenant SELECT/INSERT/UPDATE/DELETE denial and valid same-tenant behavior for orders, details, runsheets, settlements, and stock.

### U-006 — Active user auth provenance

Needed: determine whether the single non-inactive user without `auth_id` is intended pre-provisioning, a legacy row, or a real identity integrity defect.

### U-007 — Void journal provenance

Needed: identify the creator path and intended accounting contract for the two cancelled empty `VoidInvoice` journal headers.

### U-008 — Current stock provenance

Needed: reconstruct how the current 31 units entered Production given only three current inventory-log rows.

### U-009 — New-main runtime certification

Needed: browser-level auth, tenant context, module navigation, offline/reconnect, and key workflow certification before any `main.html` replacement decision.

### U-010 — Runtime retirement completion

Needed: trace all 410 endpoint callers, retire confirmed stale workflows, then remeasure runtime logs.

## BLOCKING CONDITIONS

The following are sufficient to block Production Engineering Mode:

1. P0 tenant-isolation policy/grant findings remain open.
2. No two-tenant authorization regression fixture exists.
3. Complete active consumer graph is not proven.
4. Full deployment lineage is not proven.
5. New-main replacement is not runtime-certified.

## STATUS RULE

No percentage readiness score is calculated. The protocol explicitly forbids percentage claims until the closure definition and evidence matrix are complete; even now, unresolved P0 blockers make a percentage misleading.

## CURRENT EXECUTION STATE

`FORENSIC EXECUTION = READY`

`PRODUCTION ENGINEERING = BLOCKED`

`PHASE 15 = NOT ENTERED`
