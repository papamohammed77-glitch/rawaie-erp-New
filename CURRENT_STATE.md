# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14

## GOVERNANCE / SOURCE OF TRUTH

الحالة الحالية لا تُستمد من التقارير السابقة؛ التقارير Historical/Reference فقط.

الحقيقة المعتمدة:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

**أهم نقطة تنفيذية:** الهدف الجاري هو E2E لملف النظام الأم الحالي:
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

Latest relevant Git facts:
- `8392edda...` already added Commission management functionality.
- Therefore old reports claiming Commission UI is absent are STALE.
- `3398d095...` added `forensic_main_assembly.yml` at frontend repository root.

## FORENSIC SOURCE-OF-TRUTH METADATA

Current file:
`erp-frontend/forensic_main_assembly.yml`

Current contents:
```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

File blob SHA:
`228de0a8adce8d09988d58ce5594d0c3a3dcea25`

## MASTER SOURCE READ STATUS

`main.html` exists and current blob/size are proven from Git.

The GitHub content API path available in this environment returns empty content for the ~1.09MB file, and direct raw download from the execution environment is blocked by DNS/network restrictions.

Therefore:

`FULL MAIN.HTML LINE-BY-LINE EOF READ = NOT PROVEN`

Do not invent current line numbers or surgical anchors until the full current source is readable.

## CURRENT PRODUCTION DATABASE

Supabase project:
`fiilmooggumokxanwiyx`

Status:
`ACTIVE_HEALTHY`

Region:
`eu-west-1`

PostgreSQL:
`17.6.1.121`

Current public tables were rechecked after the Sales Targets work.

There are currently **no** Production tables named:

`p_sales_target_*` / `sales_target_*`

Existing relevant tables include:

- `users`
- `orders`
- `order_details`
- `branches`
- `items`
- `commission_plans`
- `commission_rules`
- `commission_assignments`
- `commission_runs`
- `commission_run_lines`

Current relevant source fields proven:

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

`order_details.line_amount` is generated and must not be written manually.

## COMMISSION — DO NOT REPAIR AGAIN

Commission backend and current frontend history already exist.

Latest frontend parent:
`8392edda... Add commission management functionality`

Old Report172 state is STALE regarding Commission UI absence.

Do not re-add or re-fix Commission UI unless current source/runtime proves a new defect.

## SALES TARGETS — CURRENT CLOSURE UNIT

Status:
`OPEN`

### Git canonical backend source created

Migration:
`supabase/migrations/20260914040000_sales_target_engine_gold.sql`

Commit:
`7ed413df7031e2d6e4a9c32dbe1b7572b0220440`

Edge source:
`Current/Edge_Functions/sales-target-engine/index.ts`

Commit:
`ecad3f3be5b688f7a40ff29dce4b0f533ea265fe`

These are Git artifacts only. They are **not** Production deployment evidence.

### Designed data model

- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

### Designed RPC

`public.sales_target_engine_atomic`

Operations designed:

- `LIST_PLANS`
- `LIST_ASSIGNMENTS`
- `LIST_RUNS`
- `SAVE_PLAN`
- `SAVE_ASSIGNMENT`
- `APPROVE_PLAN`
- `PREVIEW`
- `POST`

### Designed controls

- Company scoping.
- Sales rep / branch identity guards.
- RLS read policies.
- Audit triggers.
- Realtime publication.
- `operation_id` idempotency for POST.
- Actuals sourced from Invoiced orders and net quantities (`qty - qty_returned`).

## SALES TARGETS — PRODUCTION DEPLOYMENT RESULT

Production DDL was attempted through the Supabase migration path.

The execution environment security checks blocked the DDL operation.

The block was reproduced across simplified attempts and was not bypassed.

Therefore:

`PRODUCTION SALES TARGET TABLES = NOT CREATED`
`PRODUCTION SALES TARGET RPC = NOT CREATED`
`PRODUCTION SALES TARGET EDGE = NOT DEPLOYED`
`PRODUCTION SALES TARGET E2E = NOT VERIFIED`

The Edge Function was not deployed intentionally because its database dependency is not present in Production. Deploying it early would create a half-solution.

## CURRENT EDGE DEPLOYMENT

Production `sales-target-engine` lookup currently returns:
`Function not found`

This is the correct current classification until the DB migration is applied.

## OWNER MASTER UI STATUS

The master file remains under owner surgery responsibility.

No direct edit was made to:
`erp-frontend/companies/company-1/main.html`

Exact surgical insertion points for Sales Targets are **not yet proven** because full current master content cannot be read in this execution environment.

Do not use stale line numbers from Report172 for Sales Targets.

## E2E STATUS

Current required closure:

`DATABASE -> RPC -> EDGE -> MASTER UI -> BROWSER E2E -> REALTIME -> DATA/AUDIT VERIFY`

Current state:

- Production DB: OPEN / not deployed.
- Production RPC: OPEN / not deployed.
- Production Edge: OPEN / not deployed.
- Master UI: OWNER / exact surgery not yet proven.
- Browser E2E: OPEN.
- Production runtime E2E: OPEN.

## HISTORICAL REPORT STATUS

Reports are clues only.

Latest historical report used for context:
`Report172_COMMISSION_ENGINE_GOLD_CLOSURE_20260914.md`

New report written this session:
`Report173_SALES_TARGET_ENGINE_GOLD_RECON_20260914.md`

Neither report substitutes for current Production evidence.

## SESSION CHECKPOINT — 2026-09-14

### Verified

`CURRENT GIT`
- HEAD `3398d095...`
- Parent `8392edda...`
- main.html blob `66c7c9...`

`CURRENT SOURCE`
- current master identified by exact path and blob.
- full line-level read not proven due environment limits.

`CURRENT DATABASE`
- current public table inventory checked.
- Sales Target tables absent.
- required order/user/item fields present.

`CURRENT DEPLOYMENT`
- `sales-target-engine` absent from Production.

`CURRENT DEPLOYMENT METADATA`
- `forensic_main_assembly.yml` now points exactly to published master.

### Not closed

`SALES TARGETS = OPEN`

Reason:
`Production deployment unavailable in this execution environment + Master UI full-read unavailable + Browser E2E not run`

## NEXT ASSISTANT RESUMPTION RULE

لا تبدأ من تقرير سابق كحالة حالية.

ابدأ بهذا الترتيب:

```text
CURRENT FRONTEND HEAD
-> DIRECT PARENT
-> CURRENT MASTER main.html
-> FULL MASTER SOURCE TO EOF
-> CURRENT SUPABASE TABLES
-> CURRENT RPC DEFINITIONS
-> CURRENT EDGE DEPLOYMENTS
-> CURRENT REALTIME
-> CURRENT RLS / TRIGGERS / CONSTRAINTS
-> CURRENT PRODUCTION DATA
-> CURRENT BROWSER / CONSOLE
```

ثم:

```text
HISTORICAL CONTRACT
-> CURRENT BEHAVIOR
-> ACTUAL GAP
-> SURGICAL DESIGN
-> PRODUCTION CHANGE
-> TEST
-> DEPLOY
-> PRODUCTION VERIFY
-> MASTER UI OWNER SURGERY
-> BROWSER E2E
-> DATA RECONCILIATION
-> AUDIT
-> UPDATE CURRENT_STATE
-> CLOSE
```

### Sales Targets exact next steps

1. Do not recreate anything already proven in Commission.
2. Apply the canonical Sales Target migration from Git to Production using a permitted migration channel.
3. Recheck tables/constraints/RLS/triggers/realtime directly in Production.
4. Deploy `sales-target-engine` only after the RPC exists.
5. Run transactional Production E2E: SAVE_PLAN -> SAVE_ASSIGNMENT -> APPROVE_PLAN -> PREVIEW -> POST -> repeat POST with same operation_id.
6. Obtain a complete readable copy of current `companies/company-1/main.html` and verify it to EOF.
7. Locate exact current Sales/Finance/navigation anchors and only then produce Owner surgical delete/replace instructions with full blocks and exact ending lines.
8. Owner publishes the master.
9. Run Browser E2E against the published master and inspect Console/network/runtime.
10. Verify Realtime, data integrity, audit records, and no duplicate operations.
11. Update this file again and close the Sales Targets closure unit only after all required evidence exists.

## ABSOLUTE RULES

- No report is current truth.
- No commit equals deployment.
- No deployment equals runtime success.
- No runtime success equals Browser E2E closure.
- No full read equals no exact surgical claim.
- No evidence equals no claim.
- No assumptions.
- Do not repair already-closed work without current evidence.
