# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13
**Current checkpoint:** Report163 — CTO Current-Reality + Browser E2E + Sales Contracts Forensic Checkpoint.

## GOVERNANCE — اقرأ هذه القاعدة أولًا

التقارير السابقة Historical/Reference فقط وليست حالة حالية.

الحالة المعتمدة فقط:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

**Source of Truth الحالي هو:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

لا تعاد أي Closure أغلقت، إلا بدليل CURRENT متناقض.

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

Current HEAD:
`aaebffbdd732b9861d96631f5d01c5a6697bd1e4`

HEAD message:
`Refactor orderHeader creation with operation IDs`

Direct Parent:
`3573c92026557cb56a7782babe6f6cf690243072`

Parent of Parent:
`28f39b351bb44a4cd885ba784d505aadaeb13cf1`

HEAD patch touches only `companies/company-1/main.html` and fixes persistent Operation Identity in:
- `RW_POS.save()`
- `RW_TeleSales._saveOrder()`

## SOURCE OF TRUTH

Path:
`companies/company-1/main.html`

Current blob SHA:
`1cc6f17b8531a8353b28f89acdfde2e992774931`

Historical/reference only:
- `Current/PWA/main2/*`
- `Original/PWA/main/*`
- `Current/PWA/New-main`

`forensic_main_assembly.yml` continues to point to the published `erp-frontend` parent file as authoritative.

## CURRENT PRODUCTION / DATABASE

Supabase project:
`fiilmooggumokxanwiyx`

Current row counts from direct Production schema inspection:

- companies = 1
- branches = 2
- users = 24
- items = 17
- stock_branches = 20
- customers = 3
- suppliers = 1
- orders = 0
- order_details = 0
- runsheets = 0
- run_sheet_details = 0
- purchase_orders = 0
- purchase_order_details = 0
- inventory_log = 3
- stock_vouchers = 0
- stock_voucher_details = 0
- journal_entries = 2
- treasury = 1
- customer_ledger = 0
- supplier_ledger = 0
- installments = 0
- installment_details = 0
- loyalty_points = 0
- coupons = 0
- credit_notes = 0
- receiving = 0
- receiving_details = 0
- audit_log = 1904
- erp_operation_registry = 2
- stock_voucher_operations = 0

Current schema facts:
- `items.item_code` is globally UNIQUE.
- `stock_branches(branch_id,item_id)` is UNIQUE.
- `receiving.operation_id` is UNIQUE.
- `orders.operation_id` exists.
- `credit_notes.operation_key` exists.
- `installments` and `installment_details` are partial primitives, not a complete installment contract.
- `loyalty_points` is a partial points table and has no company_id.
- `coupons` exists but is not a full Promotion Engine.

## CURRENT EDGE DEPLOYMENTS

Verified current versions include:

```text
save-sales-invoice      = v15
confirm-order           = v4
delete-order            = v9
create-runsheet         = v26
start-picking           = v34
complete-picking        = v17
start-loading           = v5
complete-loading        = v11
start-delivery          = v7
complete-delivery       = v4
start-return            = v4
complete-return         = v26
unload-runsheet         = v6
create-stock-voucher    = v10
send-stock-voucher      = v20
receive-stock-voucher   = v22
complete-stock-voucher  = v4
cancel-stock-voucher    = v4
save-purchase-order     = v3
receive-purchase        = v12
save-journal-entry      = v8
save-receipt-voucher    = v7
save-payment-voucher    = v5
save-transfer-voucher   = v4
complete-order-delivery = v14
create-credit-note      = v3
bulk-stock-adjustment   = v6
update-order            = v3
manage-runsheet         = v1
```

Historical canary/harness functions may still exist and may return 410. Do not treat them as business runtime without current consumer evidence.

## INVENTORY CORE — CLOSED

Physical movement contract remains:

`Physical Movement → post_stock_movement → stock_branches + inventory_log`

No contradictory CURRENT evidence reopened this closure.

## POS / TELESALES OPERATION ID — VERIFIED

Current source contains persistent operation identity and clears it only after success.

No new Parent main.html patch was issued in Report163.

## SALES BACKEND

Current Return/Credit backend remains CLOSED based on current Production evidence.

Do not reopen without contradictory CURRENT runtime/database evidence.

## CURRENT SALES BUSINESS CONTRACTS — OPEN

```text
Sales Returns Parent Management UI           = OPEN
Quote lifecycle                               = OPEN
Price List engine                             = OPEN
Promotion engine                              = OPEN
Multiple/Partial Payment allocation           = OPEN
Installment lifecycle                         = OPEN
Commission engine                             = OPEN
Sales Targets engine                          = OPEN
Loyalty transaction engine                    = OPEN
Sales Decision Center                         = OPEN
Browser click-by-click E2E                    = OPEN
```

Current Production schema inspection confirms that Quotes, Price Lists, full Promotions, Payment Allocation, Commission Rules/Entries and Sales Targets do not currently have dedicated complete domain models.

## BROWSER E2E

`Browser click-by-click E2E = OPEN / NOT VERIFIED`

The available environment does not provide reliable authenticated browser automation, so no user-visible browser PASS was claimed.

Source/Deployment/DB verification is not equivalent to Browser E2E.

## PRODUCTION CHANGES IN REPORT163

No new Production DDL was executed in this checkpoint.

Production DDL attempts for new Sales contracts were blocked by the platform security layer. No false deployment or closure is recorded.

## CURRENT SECURITY ADVISOR

Current Supabase security advisor reports 8 `SECURITY DEFINER` functions executable by `authenticated`, plus disabled leaked-password protection.

These are Current security findings and remain backlog items; they are not being silently classified as fixed.

## LATEST REPORT

`doc/Draft/Reprots/Report163_CTO_CURRENT_REALITY_E2E_AND_SALES_CONTRACTS_20260913.md`

Report162 remains historical pointer only.

## NEXT EXACT SEQUENCE

```text
CURRENT GIT HEAD
→ DIRECT PARENT
→ CURRENT main.html
→ CURRENT Production schema
→ CURRENT Deployments
→ CURRENT Runtime evidence
→ Browser click-by-click E2E
→ Sales Returns Parent Management UI
→ Quote contract
→ Price List contract
→ Promotion contract
→ Multiple/Partial Payment contract
→ Installment contract
→ Commission contract
→ Sales Target contract
→ Loyalty transaction contract
→ Sales Decision Center
→ final Browser E2E
→ Production reconciliation
→ final closure
```

## INSTRUCTIONS TO NEXT CTO / ASSISTANT

ابدأ من Production/Git الحالي، ولا تثق في التقرير كحالة.

استخدم التقرير كـpointer فقط.

قبل أي تعديل:

`historical contract → current behavior → target contract → actual gap → surgical design`

ثم:

`IMPLEMENT → TEST → DEPLOY → PRODUCTION VERIFY → RUNTIME VERIFY → DOCUMENT → CLOSE`

واحدة فقط في كل مرة.

لا تنقل Operational execution من التطبيقات المنفصلة إلى Parent لمجرد زيادة التبويبات.

لا تبنِ Business Contract فوق UI غير مدعوم بـDomain Model وIdentity وState وSecurity وAudit وAccounting.

## FINAL STATE

```text
CURRENT GIT                         = VERIFIED
CURRENT PARENT / PARENT CHAIN      = VERIFIED
CURRENT main.html SOURCE            = VERIFIED
CURRENT DATABASE                    = VERIFIED
CURRENT EDGE DEPLOYMENTS            = VERIFIED
INVENTORY CORE                      = CLOSED
POS/Telesales Operation Identity    = VERIFIED
SALES RETURN/CREDIT BACKEND         = CLOSED
BUSINESS SALES CONTRACTS             = OPEN
BROWSER CLICK-BY-CLICK E2E          = OPEN
PRODUCTION SALES DDL THIS SESSION   = NOT EXECUTED (PLATFORM BLOCK)
CURRENT REALITY RECONSTRUCTION      = UPDATED
```
