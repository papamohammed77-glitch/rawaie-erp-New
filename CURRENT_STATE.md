# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13
**Current checkpoint:** Report165 — Sales Returns Parent Management Production/backend closure completed; Parent UI merge remains owner-side; browser click-by-click E2E remains unverified.

## GOVERNANCE — اقرأ هذه القاعدة أولًا

التقارير السابقة Historical/Reference فقط وليست حالة حالية.

الحالة المعتمدة فقط:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

**Source of Truth الحالي هو:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

الملفات `Current/PWA/main2/*` و`Original/PWA/main/*` و`Current/PWA/New-main` تاريخية/مرجعية فقط.

القاعدة الدائمة:
`REPORT = POINTER`
`PRIMARY SOURCE = AUTHORITY`
`CURRENT PRODUCTION = TRUTH`
`NO ASSUMPTION`
`NO SPECULATIVE UI`
`NO CLOSED-CLOSURE REOPEN`
`ONE CLOSURE AT A TIME`
`CLOSE → VERIFY → DOCUMENT → NEXT`

## CURRENT GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`

Current HEAD verified before this closure:
`aaebffbdd732b9861d96631f5d01c5a6697bd1e4`

HEAD message:
`Refactor orderHeader creation with operation IDs`

Direct Parent:
`3573c92026557cb56a7782babe6f6cf690243072`

Parent of Parent:
`28f39b351bb44a4cd885ba784d505aadaeb13cf1`

HEAD touches only `companies/company-1/main.html` and its POS/Telesales operation-identity change remains verified and closed.

## CURRENT SOURCE OF TRUTH

Path:
`companies/company-1/main.html`

Current blob SHA verified:
`1cc6f17b8531a8353b28f89acdfde2e992774931`

Current source header:
`<!-- 2026-09-13 13:00 UTC -->`

No owner-side UI patch was applied in this closure.

## FORENSIC ASSEMBLY AUTHORITY

`forensic_main_assembly.yml` is now version 3.

Published parent:
`erp-frontend/companies/company-1/main.html`

is authoritative.

`Current/PWA/main2/*` is historical reference only.

## CURRENT PRODUCTION / DATABASE

Supabase project:
`fiilmooggumokxanwiyx`

Direct facts checked for this closure:
- `credit_notes` persistent rows = 0 after all transactional tests.
- `sales_return_reviews` persistent rows = 0 after all transactional tests.
- `sales_return_review_events` persistent rows = 0 after all transactional tests.
- `items.item_code` is globally UNIQUE.
- `stock_branches(branch_id,item_id)` is UNIQUE.
- `credit_notes.operation_key` exists.
- `audit_log` exists and `stock_vouchers` is audited by `trg_audit_stock_vouchers` → `fn_audit_trigger()`.
- New Parent Management APIs derive company context from authenticated `users.auth_id` and enforce company membership + permission `return` or `*`.

## SALES RETURNS PARENT MANAGEMENT — CLOSED BACKEND / OWNER UI MERGE

### Existing operational return screen
`RW_Warehouse.loadReturn()` remains the field/warehouse Return screen.

Current route remains:
`if (view === 'return') { RW_Warehouse.loadReturn(); return; }`

It was not replaced or moved.

### New Production infrastructure
Tables:
- `sales_return_reviews`
- `sales_return_review_events`

RPCs:
- `get_sales_return_management_summary`
- `list_sales_return_management`
- `get_sales_return_management_detail`
- `save_sales_return_review`

Security:
- SECURITY DEFINER
- search_path = public
- execution revoked from PUBLIC/anon/authenticated
- executable by service_role
- actor/company/permission checks enforced inside RPCs

Edge Function:
`sales-return-management`

Current deployed version:
`v2`

`verify_jwt = true`.

Capabilities:
`list`, `summary`, `detail`, `review`, `assignees`.

### Verification
PASS:
- Production summary/list.
- Transactional Credit Note → Review → Detail → List → Event flow with ROLLBACK.
- Unauthorized actor rejection.
- Production function existence/security posture.
- Edge deployment.

The only implementation failure was a PL/pgSQL alias/record-name collision in the first Summary version. It was corrected and retested successfully.

### Parent UI status
`BACKEND CLOSED / OWNER UI MERGE REQUIRED`

Exact owner-side surgical instructions and the full `RW_SalesReturnsManagement` module are in:
`doc/Draft/Reprots/Report165_CTO_SALES_RETURNS_PARENT_MANAGEMENT_EXECUTION_20260913.md`

Required owner-side changes are limited to the authoritative `erp-frontend/companies/company-1/main.html`:
- add `sales-returns` to Sales Management navigation;
- map `sales-returns` to permission `return`;
- add `sales-returns` title;
- add the `sales-returns` route;
- insert the complete `RW_SalesReturnsManagement` module immediately before the exact `// EVENTS & BOOT` marker.

No historical fragment should be edited.

## INVENTORY CORE

Still CLOSED.

Physical movement contract remains:
`Physical Movement → post_stock_movement → stock_branches + inventory_log`

No contradictory evidence from this closure reopened it.

## BROWSER E2E

`OPEN / NOT VERIFIED`.

The environment did not provide reliable authenticated browser automation for the required real click-by-click login/interaction/network/console correlation.

No Source/DB/Deployment pass has been promoted to Browser E2E pass.

## CURRENT CURATED REPOSITORY CHANGES

Added:
`Current/Edge_Functions/sales-return-management/index.ts`

Added:
`supabase/migrations/20260913_sales_returns_parent_management.sql`

Added:
`supabase/migrations/20260913_sales_return_summary_alias_fix.sql`

Updated:
`forensic_main_assembly.yml`

Added:
`doc/Draft/Reprots/Report165_CTO_SALES_RETURNS_PARENT_MANAGEMENT_EXECUTION_20260913.md`

These are canonical records of the backend closure and its implementation evidence.

## OPEN SALES CONTRACTS AFTER THIS CLOSURE

```text
Sales Returns Parent Management Backend     = CLOSED
Sales Returns Parent Management UI          = OWNER MERGE REQUIRED
Browser click-by-click E2E                   = OPEN / NOT VERIFIED
Quote lifecycle                              = OPEN
Price List engine                            = OPEN
Promotion engine                             = OPEN
Multiple/Partial Payment allocation          = OPEN
Installment lifecycle                        = OPEN
Commission engine                            = OPEN
Sales Targets engine                         = OPEN
Loyalty transaction engine                   = OPEN
Sales Decision Center                       = OPEN
```

## NEXT CTO / ASSISTANT INSTRUCTIONS

Do not start from reports.

Start from direct evidence:

`CURRENT GIT HEAD`
`→ DIRECT PARENT`
`→ CURRENT SOURCE OF TRUTH`
`→ CURRENT PRODUCTION SCHEMA`
`→ CURRENT DEPLOYMENTS`
`→ CURRENT RUNTIME`
`→ BROWSER E2E`

Then for each closure:

`historical contract`
`→ `current behavior`
`→ `target contract`
`→ `actual gap`
`→ `surgical design`
`→ `implement`
`→ `test`
`→ `deploy`
`→ `Production verify`
`→ `runtime verify`
`→ `document`
`→ `close`

Do not reopen a closed closure without contradictory CURRENT evidence.

For Sales Returns, preserve the separation:
`Operational Return Execution ≠ Parent Management`.

Before the next contract, re-read the actual published parent file and its latest commit chain rather than relying on historical fragments.

## FINAL STATE

```text
CURRENT GIT                         = VERIFIED
CURRENT PARENT / PARENT CHAIN      = VERIFIED
CURRENT main.html SOURCE            = VERIFIED
FORENSIC ASSEMBLY AUTHORITY         = CORRECTED
SALES RETURN MANAGEMENT BACKEND    = DEPLOYED + VERIFIED
SALES RETURN MANAGEMENT DATA        = CLEAN AFTER ROLLBACK TESTS
SALES RETURN MANAGEMENT UI          = OWNER MERGE REQUIRED
INVENTORY CORE                      = CLOSED
POS/Telesales Operation Identity    = VERIFIED / CLOSED
BROWSER CLICK-BY-CLICK E2E          = OPEN / NOT VERIFIED
```
