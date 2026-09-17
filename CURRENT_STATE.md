# RAWAEA ERP — CURRENT STATE

## 2026-09-17 — Mother Revenue Forensic / Production Closure

### Current Source of Truth

The current authoritative Mother file is:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical fragments under `Current/PWA/main2` are reference-only. `New-main` is not to be modified.

### Current Git baseline

`erp-frontend` latest HEAD:

`d7bf7ed138fa95b8dfdb88cc407827340954aa43`

Latest functional Mother parent:

`8fff8f4f05ba0c0d95a985a742b58a5890028fdb`

Current Mother blob verified:

`a271643a59e9eded1f535b2c6b60d8ccf4c532bd`

The latest HEAD above is a forensic-extract commit; it did not change the functional Mother code.

### Assembly governance

`forensic_main_assembly.yml` was independently checked and is correct:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

No assembly-file change was required.

## Revenue — Production state

Production project:

`fiilmooggumokxanwiyx`

Existing Revenue Core is present and is the canonical backend. No new Revenue table, Edge Function, or parallel engine was created in this session.

Verified Production objects:

- `finance_revenues`
- `finance_revenue_lines`
- `finance_revenue_categories`
- `finance_save_revenue`
- `finance_list_revenues_v2`
- `finance_void_revenue`

Verified behavior:

- Company context enforced.
- Branch and Treasury selected/scoped.
- One or multiple Revenue Accounts supported.
- Journal posting occurs.
- Cash Box entry occurs.
- Treasury balance is affected.
- Operation ID idempotency is enforced.
- Void/reversal path is available and was tested.

### Production E2E proof

A temporary transactional test was executed and rolled back:

```text
Line 1 = 10
Line 2 = 20
Total  = 30
```

Observed before rollback:

```text
Revenue header   = 1
Revenue lines    = 2
Journal entry    = created
Cash Box         = created
Treasury         = +30
Retry            = duplicate=true
Void             = success
```

After rollback:

```text
finance_revenues      = 0
finance_revenue_lines = 0
```

Original treasury balance remained unchanged.

**Production Revenue Core status: CLOSED / VERIFIED.**

## Mother Revenue status

The Mother Revenue UI exists in the latest functional parent but has a confirmed JavaScript parsing defect in `_newReceipt()`:

```js
'onclick="RW_Finance.renderSubTab(\\'receipts\\')" ' +
```

This occurs twice and must be replaced with:

```js
'onclick="RW_Finance.renderSubTab(\'receipts\')" ' +
```

The prior forensic finding also identified a scope defect where `branchesForRevenue` was local to `_newReceipt()` but referenced from `_renderRevenues()`.

### Owner-side Mother surgery

The assistant must not edit the Mother file directly. The owner must perform the exact surgical replacements documented in:

`doc/Draft/Reprots/Report228_MOTHER_REVENUE_E2E_CLOSURE_20260917.md`

and the full previous surgical replacement package remains in:

`doc/Draft/Reprots/Report226`

The `_newReceipt`/related block replacement target is approximately lines `15443 → 15542` in the referenced Mother version, ending immediately before:

```js
var _customerPaymentRealtimeChannel = null;
```

The owner must not partially delete a function. Delete the complete block and insert the complete replacement.

## Important separation of responsibility

### Assistant

Can modify Production directly when a current defect is proven.

### Owner

Must perform Mother frontend edits in:

`erp-frontend/companies/company-1/main.html`

No frontend changes were made by the assistant in this session.

## Previous inventory/governance context

The current inventory governance remains:

```text
PHYSICAL STOCK MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

The existing field operations, Order/Runsheet/Picking/Loading/Delivery/Return flow must not be disturbed merely while completing Finance UI.

## Session report

`doc/Draft/Reprots/Report228_MOTHER_REVENUE_E2E_CLOSURE_20260917.md`

## Next session start protocol

Do not trust this state file or earlier reports as current by themselves. Start by re-verifying:

```text
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
```

Then follow this sequence:

1. Resolve latest HEAD and functional parent.
2. Open the current Mother source.
3. Verify current Revenue functions/handlers, not historical copies.
4. Run browser Console/Network E2E.
5. If Revenue is already functioning, do not re-repair it.
6. If a defect appears, identify the exact function and exact line from current source.
7. Apply Production changes only when the defect is proven in Production.
8. After every E2E, re-query Production before declaring any percentage or closure.
9. Close Revenue only after owner merge + browser E2E + DB verification.
10. Move to the next actually-open Business Contract only after Revenue closure.

## Final current status

```text
Production Revenue Core       = CLOSED / VERIFIED
Mother Revenue UI             = OPEN / OWNER SURGERY
Mother browser E2E             = OPEN
Assembly Source of Truth       = VERIFIED
Historical fragments           = REFERENCE ONLY
Production Revenue data        = CLEAN / NO TEST DATA
Next action                    = Owner applies exact Mother surgery, then E2E
```
