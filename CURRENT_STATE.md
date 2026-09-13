# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13

## GOVERNANCE
التقارير السابقة Historical/Reference فقط وليست الحالة الحالية.

الحالة المعتمدة:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

Source of Truth:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical reference only:
`Current/PWA/main2/*`
`Original/PWA/main/*`
`New-main`

Permanent rule:
`NO ASSUMPTION`
`ONE CLOSURE AT A TIME`
`CLOSE -> VERIFY -> DOCUMENT -> NEXT`

## CURRENT GIT — PARENT
Frontend repository:
`papamohammed77-glitch/erp-frontend`
Branch: `main`

HEAD:
`d0cfb6fefd1af960de336935d8eec6d831c2d101`

HEAD message:
`Implement sales returns management feature`

Direct Parent:
`aaebffbdd732b9861d96631f5d01c5a6697bd1e4`

Parent of Parent:
`3573c92026557cb56a7782babe6f6cf690243072`

Current main.html blob:
`4cc90ea87697b0e01a21900da289f3e86e1fefcb`

## FORENSIC ASSEMBLY
`forensic_main_assembly.yml` remains pointed to:
`erp-frontend/companies/company-1/main.html`

No historical fragment is Source of Truth.

## PRODUCTION DATABASE
Supabase project:
`fiilmooggumokxanwiyx`

Quote infrastructure currently present:
- `sales_quotes`
- `sales_quote_details`
- `sales_quote_status_history`

RLS = enabled and FORCE enabled on all three.

Production quote RPCs:
- `rawaea_quote_actor_ok`
- `create_sales_quote_atomic`
- `update_sales_quote_atomic`
- `change_sales_quote_status_atomic`
- `expire_due_sales_quotes_atomic`
- `convert_sales_quote_to_order_atomic`
- `list_sales_quotes`
- `get_sales_quote_detail`
- `get_sales_quote_summary`

Quote RPC ACL:
`PUBLIC/anon/authenticated = revoked`
`service_role = execute`

## QUOTE LIFECYCLE
```text
Draft -> Sent -> Accepted -> Converted -> Confirmed Order
             |       |
             |       +-> Rejected
             +-------> Expired / Cancelled
Draft ----------------> Cancelled
```

Quote is commercial only.
No stock reservation.
No stock deduction.
No direct inventory_log write.

Physical inventory contract remains:
`Physical Movement -> post_stock_movement -> stock_branches + inventory_log`

## QUOTE EDGE
`sales-quotes`
Status: `ACTIVE`
Version: `2`
`verify_jwt = true`

Capabilities:
`catalog / list / summary / detail / create / update / send / accept / reject / cancel / expire_due / convert`

Canonical Git source:
`Current/Edge_Functions/sales-quotes/index.ts`

Latest canonical Edge source commit:
`3ef10f9752d806563732790ca2fb34d5800c5888`

## QUOTE VERIFICATION
Production transactional tests passed:
- CREATE -> SEND -> ACCEPT -> CONVERT
- duplicate conversion retry
- create idempotency
- unauthorized actor rejection
- expiry
- no physical stock movement on conversion

Observed successful conversion:
`Quote total = 90`
`Order status = Confirmed`
`Order source = quote`
`Inventory logs = 0`

All test transactions were rolled back.
Persistent Production Quote rows after tests:
`sales_quotes = 0`
`sales_quote_details = 0`
`sales_quote_status_history = 0`

## OWNER UI STATUS
The canonical parent `main.html` currently contains Sales Returns Management, but no Quote route/module.

Required owner-side integration is documented in:
`doc/Draft/Reprots/Report166_CTO_QUOTE_LIFECYCLE_EXECUTION_20260913.md`

Owner patch module:
`Current/PWA/owner-patches/RW_SalesQuotes.js`

Owner must modify only:
`erp-frontend/companies/company-1/main.html`

Do not modify historical `main2` fragments.

## BROWSER E2E
`OPEN / NOT VERIFIED`

Backend/DB/Edge verification must not be promoted to Browser E2E PASS.
The browser chain remains:
`Login -> Sales -> Quotes -> Create -> Save -> Send -> Accept -> Convert -> Orders`
with Console/Network/DB verification required after owner merge.

## OTHER CLOSED AREAS
- Inventory Core: CLOSED
- POS/Telesales Operation Identity: VERIFIED / CLOSED
- Sales Returns Parent Management backend: CLOSED
- Sales Returns Parent Management UI: OWNER MERGE REQUIRED

## OPEN CONTRACTS
```text
Quote lifecycle backend          = CLOSED
Quote owner UI                   = OWNER MERGE REQUIRED
Browser click-by-click E2E       = OPEN / NOT VERIFIED
Price List engine                = OPEN
Promotion engine                 = OPEN
Multiple/Partial Payment         = OPEN
Installment lifecycle            = OPEN
Commission engine                = OPEN
Sales Targets engine             = OPEN
Loyalty transaction engine      = OPEN
Sales Decision Center           = OPEN
```

## NEXT CTO / ASSISTANT INSTRUCTIONS
Do not start from a report as state.
Start from:
`CURRENT GIT HEAD`
`-> DIRECT PARENT`
`-> CURRENT SOURCE`
`-> CURRENT DATABASE`
`-> CURRENT DEPLOYMENTS`
`-> CURRENT RUNTIME`
`-> Browser E2E`

Then:
`historical contract -> current behavior -> target contract -> actual gap -> surgical change -> test -> deploy -> Production verify -> runtime verify -> document -> close`

Do not reopen Quote backend without contradictory CURRENT evidence.
Do not introduce a second physical stock engine.
Do not convert Migration PASS or RPC PASS into Browser PASS.

## CURRENT CHECKPOINT
```text
CURRENT GIT                         = VERIFIED
CURRENT PARENT CHAIN               = VERIFIED
CURRENT main.html SOURCE            = VERIFIED
FORENSIC ASSEMBLY AUTHORITY         = CORRECT
QUOTE BACKEND                       = DEPLOYED + VERIFIED
QUOTE EDGE                          = DEPLOYED + VERIFIED
QUOTE INVENTORY SAFETY              = VERIFIED
QUOTE TRANSACTIONAL E2E             = VERIFIED
QUOTE OWNER UI                      = MERGE REQUIRED
BROWSER E2E                         = OPEN
```
