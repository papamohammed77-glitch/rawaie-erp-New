# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14

## GOVERNANCE / SOURCE OF TRUTH

التقارير السابقة Historical/Reference فقط. لا تُستخدم كبديل عن Production.

الحقيقة المعتمدة دائمًا:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

**أهم نقطة تنفيذية:** الهدف الجاري هو **E2E لملف النظام الأم الحالي**:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

وهذا الملف وحده هو Source of Truth للنظام الأم.

Historical reference only:
`Current/PWA/main2/*`, `Original/PWA/main/*`, `New-main`.

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
HEAD: `3398d0952ea723d1de42b076ad93ae19c025bfa3`
HEAD message: `Fix forensic master source-of-truth path`
Direct Parent: `8392edda5c766fa69c5faea768ca35e35b498b94`
Parent message: `Add commission management functionality`
Parent of Parent: `faf18cae4b629e1b1f87fca7414a147f6befb541`
Current `companies/company-1/main.html` blob: `66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`
Current main.html size: `1,087,515 bytes`

Commission functionality is already represented in current frontend history. Do not re-add it without new current evidence.

## FORENSIC SOURCE-OF-TRUTH METADATA

Current file:
`erp-frontend/forensic_main_assembly.yml`

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

Blob SHA:
`228de0a8adce8d09988d58ce5594d0c3a3dcea25`

## MASTER SOURCE READ STATUS

The current master file exists and its blob/size are proven, but the GitHub content API available in this environment returns empty content for this ~1.09MB file and raw retrieval is unavailable.

Therefore:
`FULL MAIN.HTML LINE-BY-LINE EOF READ = NOT PROVEN`

Do not invent current line numbers or surgical anchors.

## CURRENT PRODUCTION DATABASE

Supabase project:
`fiilmooggumokxanwiyx`

Status: `ACTIVE_HEALTHY`
Region: `eu-west-1`
PostgreSQL: `17.6.1.121`

### Sales Targets Production state

Created and verified:

- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

Current persistent rows after transactional E2E rollback:

- plans = `0`
- assignments = `0`
- runs = `0`
- run_lines = `0`

Required source fields proven:

- `orders.company_id`
- `orders.order_status`
- `orders.order_date`
- `orders.branch_id`
- `orders.sales_rep_id`
- `order_details.item_id`
- `order_details.qty`
- `order_details.qty_returned`
- `order_details.unit_price`
- `items.cost_price`

`order_details.line_amount` remains generated and must not be written manually.

## SALES TARGETS — CURRENT CLOSURE UNIT

Production backend is now implemented.

### Git canonical source

Base migration:
`supabase/migrations/20260914040000_sales_target_engine_gold.sql`
Commit:
`7ed413df7031e2d6e4a9c32dbe1b7572b0220440`

Hardening migration:
`supabase/migrations/20260914_sales_target_engine_hardening.sql`
Commit:
`84aefa26b86eca43b9e14d348eaa55748d7cf490`

Audit trigger fix:
`supabase/migrations/20260914_sales_target_audit_trigger_fix.sql`
Commit:
`b4d4f8726caef468fcf479e06163f28c7846a141`

Edge source:
`Current/Edge_Functions/sales-target-engine/index.ts`
Current source blob:
`d10b57448bc850386523f22600561d1ea4b2316b`

Latest backend documentation/report:
`doc/Draft/Reprots/Report174_SALES_TARGET_ENGINE_GOLD_RUNTIME_CLOSURE_20260914.md`
Commit:
`711ebb99db5207afd99e138fb0ebbf6ba470d774`

### Production RPC

`public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)`

Core operations now implemented:

- `LIST_PLANS`
- `LIST_ASSIGNMENTS`
- `LIST_RUNS`
- `SAVE_PLAN`
- `SAVE_ASSIGNMENT`
- `APPROVE_PLAN`
- `CLOSE_PLAN`
- `CANCEL_PLAN`
- `PREVIEW`
- `POST`
- `APPROVE_RUN`
- `REVERSE_RUN`

### Controls

- Company-scoped actor validation.
- Existing permission semantics including `permissions=["*"]` for Owner.
- Sales Manager / Sales Supervisor / General Manager permissions handled without replacing Owner wildcard semantics.
- RLS read policies.
- Audit triggers.
- Realtime publication.
- Explicit FK indexes.
- POST idempotency via `(company_id, operation_id)`.
- Actuals from Invoiced orders using net quantity `qty - qty_returned`.

## CURRENT EDGE DEPLOYMENT

Production Edge Function:
`sales-target-engine`

Status: `ACTIVE`
Version: `1`
`verify_jwt = true`

Runtime contract:
`JWT → users.auth_id → company_id → sales_target_engine_atomic`

The browser does not supply trusted company_id.

## PRODUCTION E2E / RUNTIME EVIDENCE

Transactional E2E executed in Production database and rolled back completely.

Sequence:
`SAVE_PLAN → SAVE_ASSIGNMENT → APPROVE_PLAN → PREVIEW → POST → POST_RETRY → APPROVE_RUN → REVERSE_RUN`

Results:

- SAVE_PLAN = PASS
- SAVE_ASSIGNMENT = PASS
- APPROVE_PLAN = PASS
- PREVIEW = PASS
- POST = PASS
- POST_RETRY = PASS (`duplicate=true`)
- APPROVE_RUN = PASS
- REVERSE_RUN = PASS
- persistent test residue = `0`

A real Audit trigger defect was discovered during the first run (`NEW` field mismatch) and fixed before the successful rerun.

## MASTER UI / BROWSER STATUS

No direct edit was made to:
`erp-frontend/companies/company-1/main.html`

The owner remains responsible for master-file surgery.

Full current master content is not readable line-by-line in this environment, so exact current-line surgical instructions are not yet proven.

Browser E2E against the current published master was not executable in this environment.

Therefore the authoritative current classification is:

`DATABASE = CLOSED`
`RPC = CLOSED`
`EDGE = CLOSED`
`REALTIME = CLOSED`
`AUDIT = CLOSED`
`PRODUCTION BACKEND = CLOSED`
`MASTER UI = OWNER OPEN`
`BROWSER E2E = OPEN`
`SYSTEM-LEVEL SALES TARGETS CLOSURE = OPEN`

Do not convert backend PASS into Browser/System PASS.

## HISTORICAL / STALE DATA CLEANUP RULE

Any questionable cross-company item/stock rows must not be deleted based on appearance alone. The current schema proves `items.item_code` is globally UNIQUE, so an Item can be referenced by another company only if the business contract treats Item Master as global. Such rows require provenance/fixture evidence before mutation.

## NEXT SESSION START ORDER — MANDATORY

1. Capture a fresh Production snapshot first.
2. Re-check current frontend HEAD, Parent, Parent of Parent, master blob and `forensic_main_assembly.yml`.
3. Read the current `main.html` fully to EOF before proposing any surgical UI edit.
4. Inspect current deployed Edge + RPC + DB + RLS + Realtime + Audit again; do not trust this file as a substitute for current runtime.
5. Do not re-fix Sales Target backend; it is already deployed and transactionally verified unless fresh evidence shows regression.
6. Use `main.html` only for current UI truth; use `Current/PWA/main2/*` only for historical contract reconstruction.
7. Find the exact current Sales Target tab/function block, record exact start/end lines and last full line, then prepare one complete Owner replacement.
8. Owner applies the master surgery and publishes the current `main.html`.
9. Run real browser E2E, inspect Console, exercise the real JWT Edge path, verify Realtime refresh and Audit records.
10. Reconcile Production again in the same reporting moment and only then change the closure state.
11. Add a new report; never overwrite historical reports.

## FINAL CURRENT STATE

`CURRENT GIT = VERIFIED`
`CURRENT SOURCE = MASTER IDENTIFIED / FULL EOF READ UNPROVEN`
`CURRENT PRODUCTION = VERIFIED`
`CURRENT DATABASE = VERIFIED`
`CURRENT DEPLOYMENT = VERIFIED`
`SALES TARGET BACKEND = CLOSED`
`MASTER UI = OPEN`
`BROWSER E2E = OPEN`
`OVERALL SALES TARGET CLOSURE = OPEN`
