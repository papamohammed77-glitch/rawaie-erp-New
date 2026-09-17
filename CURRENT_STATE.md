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

The three Revenue RPCs are executable by `authenticated`, `postgres`, and `service_role`.

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

The current Mother Revenue UI has two confirmed frontend defects remaining in the owner-controlled source:

### 1. SyntaxError in `_newReceipt()`

Confirmed malformed line, occurring twice:

```js
'onclick="RW_Finance.renderSubTab(\\'receipts\\')" ' +
```

Replace both occurrences with:

```js
'onclick="RW_Finance.renderSubTab(\'receipts\')" ' +
```

### 2. `_renderRevenues()` scope defect

`branchesForRevenue` is local to `_newReceipt()` but referenced by `_renderRevenues()`.

Do not promote it to global scope.

The complete replacement for `_renderRevenues()` is recorded in:

`doc/Draft/Reprots/Report227_MOTHER_LOGIN_REVENUE_FORENSIC_20260917.md`

The related `_newReceipt` / receipt block surgical package is recorded in:

`doc/Draft/Reprots/Report226`

The surgical handoff and current production proof are recorded in:

`doc/Draft/Reprots/Report228_MOTHER_REVENUE_E2E_CLOSURE_20260917.md`

Approximate target range for the receipt block in the referenced Mother version:

`15443 → 15542`

The delete boundary is the start of:

```js
async function _newReceipt() {
```

and the block ends immediately before:

```js
var _customerPaymentRealtimeChannel = null;
```

No partial deletion is allowed.

## Responsibility split

### Assistant

Production/database changes may be applied directly when a defect is proven.

### Owner

Mother frontend changes in:

`erp-frontend/companies/company-1/main.html`

must be applied by the owner.

No frontend modification was made by the assistant in this session.

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

Report update commit:

`5d8e2e9fa3552d5c31d484d196ef05aec62a3203`

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

Then:

```text
1. Resolve latest HEAD and direct parent.
2. Open the current Mother source, not main2.
3. Verify whether the owner already applied the Revenue surgical fixes.
4. Run JavaScript syntax validation.
5. Run authenticated browser E2E:
   Login → Finance → Revenues → New Revenue.
6. Test one Revenue line and multiple Revenue lines.
7. Verify list visibility and reload persistence.
8. Verify Journal + Cash Box + Treasury.
9. Test retry with the same operation_id.
10. Test Void/reversal.
11. Re-query Production in the same closure cycle.
12. Only then declare Revenue UI closed.
13. Move to the next actually-open Business Contract.
```

## Final current status

```text
Production Revenue Core       = CLOSED / VERIFIED
Revenue backend infrastructure= PRESENT / NO NEW BUILD REQUIRED
Mother Revenue UI             = OPEN / OWNER SURGERY
Mother browser E2E             = OPEN
Assembly Source of Truth       = VERIFIED
Historical fragments           = REFERENCE ONLY
Production Revenue data        = CLEAN / NO TEST DATA
Next action                    = Owner applies exact Mother surgery, then authenticated E2E
```
