# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-16 — current Git / current Mother source / current Production / current Database / current Deployment evidence were rechecked for the Security Closure. The four-table Sales Decision RLS issue is now closed in Production.

## SOURCE OF TRUTH

Historical reports are reference-only. They are not current state.

The governing truth is:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

Full Browser/System E2E additionally requires:
`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

**Mother System Source of Truth:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical fragments only:
`Current/PWA/main2/*`
`Original/PWA/main/*`
`New-main`

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`

Current HEAD:
`befa657277fc013c4fe4d3e326ed8fc5d1040b7b`

HEAD message:
`Update HTML comment timestamp`

Direct parent:
`b6d35c5a1a362f381c9868bbc578de988b219c50`

Parent message:
`Fix button onclick syntax in main.html`

Current Mother blob:
`bc268b9bb350991df64221e7f99b958264fb8d5f`

HEAD diff is timestamp-only. Parent contains the previously required `_openPO` onclick syntax correction near source line 9577.

**Correction:** A prior context referenced Mother blob `68145f77b3edc98ac37b9ec2335359d825a4be52`. Direct CURRENT GIT verification shows that the actual blob for the current HEAD is `bc268b9bb350991df64221e7f99b958264fb8d5f`; the Git value is authoritative.

## CURRENT MOTHER

The current Mother source remains:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

The assistant did not modify the Mother HTML during the 2026-09-16 Security Closure.

Current PurchaseGold functions previously established by direct source review:

`createRequest()` — lines 9271–9323
`createRFQ()` — lines 9365–9414
`createQuotation()` — lines 9461–9531
`createInvoice()` — lines 9616–9686
`createReturn()` — lines 9730–9787
`createPayment()` — lines 9828–9906
`reports()` — lines 9908–9949
`settings()` — lines 9951–9977
`saveSettings()` — lines 9979–10001

Current Browser E2E of the updated Mother still requires Owner merge + fresh browser/console/network evidence. The 2026-09-16 Security Closure did not alter this status.

## CURRENT PURCHASE PRODUCTION

Project: `fiilmooggumokxanwiyx`

Current purchase capability layer:
`save-purchase-order` — ACTIVE — version 6 — verify_jwt=true.

Current Purchase schema and RPC infrastructure remain present.

## CURRENT SALES DECISION PRODUCTION

Security Closure unit:
`Sales Decision four-table RLS security closure`

The four Production tables are:

```text
public.sales_decision_approvals
public.sales_decision_evaluations
public.sales_decision_policies
public.sales_decision_policy_history
```

Current row counts checked during this closure:

```text
sales_decision_policies         = 1
sales_decision_evaluations      = 0
sales_decision_approvals        = 0
sales_decision_policy_history   = 1
```

Current Production security state:

```text
RLS enabled on all four tables       = TRUE
Explicit deny policy on all four     = TRUE
anon SELECT privilege                = FALSE
enticated SELECT privilege           = FALSE
```

Each table has exactly one explicit restrictive policy for `anon, authenticated` using:

```text
USING (false)
WITH CHECK (false)
```

The direct table API is intentionally closed. The controlled business path remains:

`sales_decision_engine_atomic(...)`

Current engine is `SECURITY DEFINER`, is Company/Actor scoped, and remained operational after RLS activation.

Current Sales Decision relationships remain:

```text
sales_decision_approvals.company_id
    → companies.id

sales_decision_approvals.evaluation_id
    → sales_decision_evaluations.id

sales_decision_evaluations.company_id
    → companies.id

sales_decision_evaluations.policy_id
    → sales_decision_policies.id

sales_decision_policies.company_id
    → companies.id

sales_decision_policy_history.company_id
    → companies.id

sales_decision_policy_history.policy_id
    → sales_decision_policies.id
```

Current Sales Decision triggers checked:

```text
trg_sales_decision_approval_audit
trg_sales_decision_policy_audit
trg_sales_decision_policy_updated_at
```

No trigger, audit function, business logic, Edge Function, or Mother HTML was changed by this Security Closure.

## SALES DECISION SECURITY CLOSURE — 2026-09-16

Production migrations applied directly:

1. `20260916042958_sales_decision_rls_security_closure_20260916`
2. `20260916043051_sales_decision_rls_explicit_deny_20260916`

Canonical Git files:

```text
supabase/migrations/20260916042958_sales_decision_rls_security_closure_20260916.sql
supabase/migrations/20260916043051_sales_decision_rls_explicit_deny_20260916.sql
```

Security verification:

- PostgreSQL confirmed RLS enabled on all four tables.
- PostgreSQL confirmed one restrictive deny policy per table.
- Direct `anon/authenticated` SELECT remained absent.
- Temporary `authenticated` SELECT grants were used inside a transaction only; all were rolled back.
- RLS test returned zero visible rows for the authenticated role on all four tables.
- `sales_decision_engine_atomic(..., 'GET_POLICY', ...)` returned `success=true` after the RLS change.
- Security Advisor no longer reports the four Sales Decision tables under `RLS Enabled No Policy`.
- Remaining Security Advisor findings belong to other unrelated units and remain open.

Closure status:

```text
Sales Decision four-table RLS closure = FULLY CLOSED
```

## CURRENT FORENSIC REPORTS

Latest relevant reports:

`doc/Draft/Reprots/Report204_PURCHASE_MODAL_CURRENT_CLOSURE_20260915.md`
`doc/Draft/Reprots/Report205`
`doc/Draft/Reprots/Report206_SALES_DECISION_RLS_SECURITY_CLOSURE_20260916.md`

Historical reports remain retained and are not current-state authority.

## FORENSIC METHOD — REQUIRED FOR NEXT SESSION

1. Treat reports as historical evidence, not current state.
2. Re-read CURRENT_STATE.
3. Re-open current Git HEAD and direct parent.
4. Re-open the current Mother source around the exact problem.
5. Re-open current Production RPCs, schema, RLS, triggers and Edge deployment.
6. Identify one Closure Unit.
7. Use historical code only to recover intent, never to replace current evidence.
8. Separate owner-only Mother work from Production work.
9. For Mother edits, provide exact full block with source start/end anchor and current line number.
10. For Production fixes, use canonical migration then re-read the deployed definition.
11. Do not create infrastructure that already exists.
12. Do not repair previously closed defects unless fresh evidence reopens them.
13. After the Owner merges Mother changes, re-read the current HEAD/blob again.
14. Run a fresh browser session and capture Console + PageError + Network.
15. Verify the RPC result, DB state, audit trail and realtime refresh for each critical operation.
16. Take the Production snapshot at the same time as the final report.
17. If a report conflicts with Production, Production wins.
18. Do not declare Gold/Diamond closure before Browser + Network + DB evidence is complete.

## CURRENT CLOSURE STATUS

```text
Current Git/Parent                         VERIFIED
Current Mother source                      VERIFIED
Current Mother blob                        VERIFIED = bc268b9bb350991df64221e7f99b958264fb8d5f
Current Production purchase schema         VERIFIED
Current Production purchase RPC layer     VERIFIED
Current save-purchase-order deployment    VERIFIED
Current Purchase Realtime publication     VERIFIED
Production report hardening               DEPLOYED + VERIFIED
Production settings hardening             DEPLOYED + VERIFIED
Production document-integrity hardening   DEPLOYED + VERIFIED
Current Purchase modal root cause         VERIFIED
Owner surgical patch                       READY
Fresh Browser Console                      NOT YET PROVEN
Fresh Browser Network                      NOT YET PROVEN
Full Purchase modal E2E                    OPEN
Gold/Diamond Purchase closure              OPEN UNTIL OWNER MERGE + FRESH E2E

Sales Decision RLS tables                 DEPLOYED + VERIFIED
Sales Decision explicit deny policies     DEPLOYED + VERIFIED
Sales Decision Engine after RLS           RUNTIME VERIFIED
Sales Decision Security Advisor finding   CLOSED
Sales Decision RLS closure                FULLY CLOSED
```

## FINAL SELF-AUDIT — 2026-09-16 SECURITY CLOSURE

### What is proven

- Current Git HEAD and direct parent were rechecked.
- Current Mother blob was rechecked directly; `bc268b9bb350991df64221e7f99b958264fb8d5f` is authoritative for the current HEAD.
- The four Sales Decision tables were verified directly in Production.
- Their schemas and Company relationships were verified.
- Their current consumers/callee engine was verified through `sales_decision_engine_atomic`.
- RLS was enabled on all four tables.
- Explicit restrictive deny policies were created and verified.
- Direct table SELECT access for `anon/authenticated` is not granted.
- RLS was runtime-tested through a temporary authenticated-role transaction.
- The Sales Decision Engine remained operational after the security change.
- Security Advisor no longer lists the four tables as `RLS Enabled No Policy`.
- The actual Production migrations are now represented canonically in Git.
- No Mother HTML change was made for this independent security issue.

### What is not proven

- Full Browser E2E of the PurchaseGold changes remains open until Owner merge and fresh Browser/Console/Network evidence.
- Other Security Advisor findings are not closed by this unit.
- The entire RAWAEA ERP mission is not closed; only this Sales Decision RLS Security Closure is closed.

### Next exact checkpoint

`Owner merge → fresh Mother HEAD/blob verification → fresh Browser E2E → continue next open Closure Unit`
