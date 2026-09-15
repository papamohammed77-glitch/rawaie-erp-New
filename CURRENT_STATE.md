# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 current session

## SOURCE OF TRUTH

التقارير Historical/Reference فقط، ولا تُعامل كحالة حالية.

الحقيقة المعتمدة:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولإغلاق Browser/System E2E يلزم أيضًا:
`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

**Source of Truth للنظام الأم:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical fragments only:
`Current/PWA/main2/*`, `Original/PWA/main/*`, `New-main`.

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
HEAD: `13425725f48c7decba3403ee631d8e0f2d757b0f`
Direct parent: `05ebb2d67b29dfe26ad77b6f314942c502e0dd8f`
Current mother blob: `5267f261f2febcbafeafdce0bb9da89a4a6bc894`

HEAD message: `Refactor KPI card layout and styles`.

The previous state file contained stale Git identifiers and is now reconciled.

## CURRENT MOTHER FILE EVIDENCE

Current blob was fetched directly from Git.

Important limitation: the available GitHub connector does not reliably expose the complete 40K+ line blob as line-addressable chunks, and the execution container had no external DNS path for raw GitHub. Therefore this session deliberately issued **no new surgical frontend patch using inherited line numbers**.

No claim of fresh full manual line-by-line EOF reading is made until an exact current-file line-addressable artifact is available.

## FORENSIC ASSEMBLY

Logical Source of Truth remains:

```text
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

No safe path edit to a physically located `forensic_main_assembly.yml` was performed in this session because a current line-addressable file target was not established.

## PRODUCTION — LOYALTY TRANSACTION ENGINE

Supabase project:
`fiilmooggumokxanwiyx`

New Production tables:
- `loyalty_programs`
- `loyalty_rewards`
- `loyalty_accounts`
- `loyalty_transactions`

New Production RPC:
- `loyalty_engine_atomic(uuid,text,text,jsonb,text)`

New Production Edge Function:
- `loyalty-engine`
- `verify_jwt = true`

Security:
- RLS enabled on all four Loyalty tables.
- Direct anon/authenticated table access denied.
- RPC exposed only to `service_role`.
- Audit triggers connected to existing `fn_audit_trigger()`.

Identity:
- Loyalty source of truth = `loyalty_accounts + loyalty_transactions`.
- `customers.loyalty_points` is compatibility cache only.

Supported operations:
- LIST_PROGRAMS
- LIST_REWARDS
- GET_ACCOUNT
- LIST_TRANSACTIONS
- SAVE_PROGRAM
- SAVE_REWARD
- REDEEM
- EARN_ORDER
- SYNC_ORDER
- ADJUST
- EXPIRE
- REVERSE

Integrity controls:
- Company-scoped actor validation.
- Customer tenant validation.
- Order tenant validation.
- One Active program per company.
- Account/advisory locking.
- Operation-level idempotency.
- Double-reversal prevention.
- Non-negative balance enforcement.

## LOYALTY E2E STATUS

Transactionally verified in Production without retaining test data:

- Program creation: PASS.
- Earn from Invoiced order: PASS.
- Repeated Earn operation: duplicate protection PASS.
- Redeem: PASS.
- Repeated Redeem operation: duplicate protection PASS.
- Reverse redemption: PASS.
- Test data rolled back.

## PRODUCTION — SALES TARGETS

Existing tables:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

Existing RPCs:
- `sales_target_engine_gateway`
- `sales_target_engine_atomic`
- `sales_target_dashboard_atomic`

Current engine supports dynamic target control.

A real defect was found and repaired in `SAVE_ASSIGNMENT` update path: `branch_id` ambiguity between PL/pgSQL variable scope and table column scope.

Final Production function preserves full lifecycle including:
- SAVE_PLAN
- CLONE_PLAN
- SAVE_ASSIGNMENT
- SET_ASSIGNMENT_ACTIVE
- APPROVE_PLAN
- CLOSE_PLAN
- CANCEL_PLAN
- PREVIEW
- POST
- APPROVE_RUN
- REVERSE_RUN
- LIST operations

## SALES TARGET E2E STATUS

Transactionally verified:

- Create target = 10,000: PASS.
- Change assignment target = 15,000: PASS.
- Approve plan: PASS.
- Preview: PASS.
- POST: PASS.
- Repeated POST with same operation_id: duplicate protection PASS.
- Clone plan and assignments: PASS.
- Test data rolled back.

## INVENTORY / PHYSICAL STOCK

Canonical Physical Stock engine remains:

`post_stock_movement`

No change to that contract in this session.

Previously established stock identity facts remain:
- `items.item_code` is globally UNIQUE.
- `stock_branches` is UNIQUE on `(branch_id,item_id)`.

No speculative mass cleanup of the previously observed cross-company fixture-like rows was executed.

## IMPORTANT OPEN ITEMS

1. Mother System `main.html` still needs fresh, exact, current-file anchors before any surgical Loyalty/Sales Targets frontend patch.
2. Fresh browser-incognito Console/Network evidence is still not available from this environment.
3. Loyalty Edge/Production engine exists, but the Mother UI integration is not proven closed.
4. Loyalty integration with the final invoice/return lifecycle is not yet proven as end-to-end in the live browser path.
5. Canonical Git migration/source records for the new Loyalty Production objects still need explicit repository reconciliation before repository reproducibility can be called complete.
6. `forensic_main_assembly.yml` logical contract is known, but physical current file target was not safely line-addressed in this session.

## NEXT CLOSURE ORDER

1. Re-acquire exact current `main.html` body through EOF with line-addressable evidence.
2. Find current exact Loyalty/Sales Targets UI anchors in that version only.
3. Produce owner-executed surgical frontend patch with exact start/end markers and current line numbers.
4. Wire Mother UI to `loyalty-engine`.
5. Verify invoice/return integration with Loyalty in Production.
6. Browser E2E: Console + Network + DB outcome.
7. Reconcile canonical Git migrations and Edge source.
8. Only then update status to 100% Closed.

## REPORT

Current session report:
`doc/Draft/Reprots/Report188_LOYALTY_TRANSACTION_ENGINE_AND_SALES_TARGETS_CLOSURE_20260915.md`

Previous reports are historical and remain untouched.
