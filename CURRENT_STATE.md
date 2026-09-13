# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13
**Current checkpoint:** Sales Returns Parent Management backend execution completed; Parent UI merge remains owner-side; browser click-by-click E2E remains unverified.

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

HEAD touches only `companies/company-1/main.html` and its operation identity changes in POS/Telesales were verified and were not reopened.

## CURRENT SOURCE OF TRUTH

Path:
`companies/company-1/main.html`

Current blob SHA verified:
`1cc6f17b8531a8353b28f89acdfde2e992774931`

Current source header:
`<!-- 2026-09-13 13:00 UTC -->`

No owner-side UI patch was applied by this session.

## FORENSIC ASSEMBLY AUTHORITY

`forensic_main_assembly.yml` has been updated to version 3.

The published `erp-frontend/companies/company-1/main.html` is authoritative.
`Current/PWA/main2/*` is explicitly historical reference only, not a source of truth.

## CURRENT PRODUCTION / DATABASE

Supabase project:
`fiilmooggumokxanwiyx`

Direct current facts used in this closure:
- `credit_notes` = 0 persistent rows after transactional tests.
- `sales_return_reviews` = 0 persistent rows after transactional tests.
- `sales_return_review_events` = 0 persistent rows after transactional tests.
- `items.item_code` is globally UNIQUE.
- `stock_branches(branch_id,item_id)` is UNIQUE.
- `credit_notes.operation_key` exists.
- `audit_log` exists and `stock_vouchers` is audited by `trg_audit_stock_vouchers` → `fn_audit_trigger()`.
- Current production contains multiple company contexts; all new Sales Return Management APIs derive company context from the authenticated user and require the requested actor to belong to that company.

## SALES RETURNS PARENT MANAGEMENT — CURRENT CLOSURE

### Existing operational return screen
The existing `RW_Warehouse.loadReturn()` remains the field/warehouse operational Returns screen. It was **not moved, replaced, or rewritten**.

Current source route remains:
`if (view === 'return') { RW_Warehouse.loadReturn(); return; }`

This is intentionally separate from Parent Management.

### New Production infrastructure deployed
Created in Production:
- `sales_return_reviews`
- `sales_return_review_events`

Created and deployed RPC capabilities:
- `get_sales_return_management_summary`
- `list_sales_return_management`
- `get_sales_return_management_detail`
- `save_sales_return_review`

All four are `SECURITY DEFINER`, `search_path=public`, denied to `PUBLIC/anon/authenticated`, and executable by `service_role` only.

Created and deployed Edge Function:
`sales-return-management`

Current deployed version:
`v1`

`verify_jwt = true`.

The Edge Function exposes:
- `list`
- `summary`
- `detail`
- `review`

It obtains `company_id` only from the authenticated `users.auth_id` record and does not accept a caller-supplied company context as authority.

### Verification
Direct Production RPC tests passed:
- owner summary/list with zero current credit notes.
- transactional create → review → detail → list flow, followed by `ROLLBACK`; no persistent test rows remained.
- unauthorized actor test failed as intended with `غير مصرح بإدارة المرتجعات`.

A first implementation attempt of the summary RPC failed because a PL/pgSQL record variable `r` conflicted with a table alias. The function was corrected and retested successfully.

### Parent UI status
`Sales Returns Parent Management UI = BACKEND READY / UI MERGE REQUIRED`

The published parent file is owner-controlled and was deliberately not modified by this session.

Required owner-side UI work is documented in Report165:
1. Add `sales-returns` to the Sales Management navigation submenu.
2. Add `sales-returns` to `RW_Views.permissionMap` with permission `return`.
3. Add its title to `RW_Views` titles.
4. Add the `sales-returns` route to `RW_Views.render()`.
5. Insert the complete `RW_SalesReturnsManagement` module before the exact `// EVENTS & BOOT` marker.

The module is designed as Parent Management only: KPIs, filters, list, detail, review assignment/status, review history, and refresh/live synchronization. It does not execute field returns or mutate `stock_branches` directly.

## INVENTORY CORE

Still CLOSED.

Physical movement contract remains:
`Physical Movement → post_stock_movement → stock_branches + inventory_log`

No current evidence in this closure reopened Inventory Core.

## BROWSER E2E

`OPEN / NOT VERIFIED`.

Source, RPC, Production and Deployment verification must not be represented as click-by-click Browser E2E PASS.

The current environment did not provide reliable authenticated browser automation for the required real login/click/Network/Console correlation.

## CURRENT MAIN COMMIT CHAIN

Latest verified chain before this closure:
`28f39b... → 3573c9... → aaebff...`

No closed POS/Telesales operation-identity closure was reopened.

## OPEN SALES CONTRACTS AFTER THIS CLOSURE

```text
Sales Returns Parent Management UI     = BACKEND READY / UI MERGE REQUIRED
Browser click-by-click E2E             = OPEN / NOT VERIFIED
Quote lifecycle                         = OPEN
Price List engine                       = OPEN
Promotion engine                        = OPEN
Multiple/Partial Payment allocation     = OPEN
Installment lifecycle                   = OPEN
Commission engine                       = OPEN
Sales Targets engine                    = OPEN
Loyalty transaction engine              = OPEN
Sales Decision Center                   = OPEN
```

## NEXT CTO / ASSISTANT INSTRUCTIONS

Start from direct current evidence, not report numbers:

`CURRENT GIT HEAD`
`→ DIRECT PARENT`
`→ CURRENT SOURCE OF TRUTH`
`→ CURRENT PRODUCTION SCHEMA`
`→ CURRENT EDGE DEPLOYMENTS`
`→ CURRENT RUNTIME`
`→ BROWSER E2E`

For any new closure:
`historical contract → current behavior → target contract → actual gap → surgical design → implement → test → deploy → Production verify → runtime verify → document → close`

Do not reopen a closure that has no contradictory CURRENT evidence.

For Parent Management, do not transfer field execution from operational apps into the parent merely to make the parent screen look complete.

The next owner-side action is to merge the exact UI patch from Report165 into the authoritative `erp-frontend/companies/company-1/main.html`, then run real browser E2E and correlate the results with Production.

## FINAL STATE

```text
CURRENT GIT                         = VERIFIED
CURRENT PARENT / PARENT CHAIN      = VERIFIED
CURRENT main.html SOURCE            = VERIFIED
FORENSIC ASSEMBLY AUTHORITY         = CORRECTED
SALES RETURN MANAGEMENT BACKEND    = DEPLOYED + RPC VERIFIED
SALES RETURN MANAGEMENT DATA        = CLEAN AFTER ROLLBACK TESTS
SALES RETURN MANAGEMENT UI          = OWNER MERGE REQUIRED
INVENTORY CORE                      = CLOSED
POS/Telesales Operation Identity    = VERIFIED / CLOSED
BROWSER CLICK-BY-CLICK E2E          = OPEN / NOT VERIFIED
```
