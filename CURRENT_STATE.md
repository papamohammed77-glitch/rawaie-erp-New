# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 08:xx UTC

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
Latest HEAD: `24e0124bedf6356103cb28bf365cef8e46be8027`
Direct parent: `1f7928e0fa0320670df92c6e944afab0f28e2c0d`
Current mother blob: `324b0deb53b6a58b379b08748d063d40a2aef92b`

HEAD `24e0124...` only moved `window.RW_SalesTargetsMain = RW_SalesTargetsMain;` before the Loyalty module. The functional parent `1f7928...` contains the async ordering repair that invokes `renderConfig()` after `loadPrograms()` resolves.

## CURRENT MOTHER FILE EVIDENCE

تم فتح الـmother source من Git blob الحالي مباشرة، وتم التحقق من نهايته:

```html
</script>
</body>
</html>
```

Current Loyalty module is present in the published mother file.

### Current Loyalty anchors

- Loyalty navigation: around source line `1144`.
- `RW_LoyaltyMain.render()` async area: around source line `2064`.
- `renderConfig()` is inside `RW_LoyaltyMain` and currently leaves `جاري التحميل...` when no Active program exists.
- The exact downstream anchor is:

```javascript
function renderRewards(){
```

The current published source must remain the only reconstruction/source-of-truth file.

## FORENSIC ASSEMBLY

`doc/Draft/forensic_main_assembly.yml` is the canonical reconstruction contract.

It must point to:
- repository = `papamohammed77-glitch/erp-frontend`
- path = `companies/company-1/main.html`
- ref = `main`
- mode = `published_main_is_authoritative`
- fragment_mode = `historical_reference_only`

Current verified HEAD:
`24e0124bedf6356103cb28bf365cef8e46be8027`

Current direct parent:
`1f7928e0fa0320670df92c6e944afab0f28e2c0d`

Current mother blob:
`324b0deb53b6a58b379b08748d063d40a2aef92b`

## PRODUCTION — LOYALTY

Supabase project:
`fiilmooggumokxanwiyx`

Name:
`SMART ERP`

Current core:
`loyalty_engine_atomic(uuid,text,text,jsonb,text)`

Current Edge capability:
`loyalty-engine`

Current source of truth:
`loyalty_accounts + loyalty_transactions`

Compatibility cache:
`customers.loyalty_points`

Legacy compatibility table:
`loyalty_points`

### Production Loyalty schema verified

- `loyalty_programs`
- `loyalty_rewards`
- `loyalty_accounts`
- `loyalty_points`
- `loyalty_transactions`

### Production state verified in this session

```text
loyalty_programs     = 0
loyalty_rewards      = 0
loyalty_accounts     = 0
loyalty_points       = 0
loyalty_transactions = 0
```

`LIST_PROGRAMS` was executed directly through `loyalty_engine_atomic` and returned:

```text
success=true
program_count=0
```

Therefore empty program configuration is a valid Production state; it is not a loading/error condition.

### Automatic order Loyalty trigger

`trg_orders_loyalty_auto_earn` is verified in PostgreSQL as:

```text
tgdeferrable = true
tginitdeferred = true
```

The trigger function uses deterministic identity:

`AUTO:EARN_ORDER:<company_id>:<order_id>`

## LOYALTY TRANSACTION VERIFICATION

A temporary Production transaction was executed and fully rolled back.

Verified sequence:

```text
SAVE_PROGRAM
→ SAVE_REWARD
→ create customer + Draft order + order detail
→ set order Invoiced
→ deferred auto-earn
→ EARN_ORDER idempotency path
→ REDEEM
→ duplicate REDEEM with same operation_id
→ REVERSE
→ ROLLBACK
```

No E2E data remained after rollback.

Final persistent counts remained:

```text
loyalty_programs     = 0
loyalty_rewards      = 0
loyalty_accounts     = 0
loyalty_points       = 0
loyalty_transactions = 0
```

## CURRENT MOTHER UI DEFECT

The earlier four-line async repair is already present in the current parent/HEAD and must not be repeated.

The remaining defect is the no-Active-program branch inside `renderConfig()`:

```javascript
safeHTML(out,'...<div id="rw-loyalty-rewards-grid" ...><div class="text-gray-400">جاري التحميل...</div></div>');
var active=currentPrograms.find(function(x){return x.status==='Active';});
if(active) loadRewards(active.id).then(renderRewards).catch(function(e){showToast(e.message,'error');});
```

With Production currently containing zero programs, `active` is null and the placeholder never transitions to a terminal state.

### OWNER-ONLY SURGICAL PATCH — UPDATED

In current `main.html`, delete the complete `renderConfig()` function from:

```javascript
function renderConfig(){
```

through the closing brace immediately before:

```javascript
function renderRewards(){
```

Replace it with the complete function recorded in `Report191_LOYALTY_MOTHER_UI_FORENSIC_CLOSURE_20260915.md`.

The replacement must explicitly render:

```text
لا يوجد برنامج ولاء نشط حاليًا
```

when no Active program exists, and must render an explicit error state on `LIST_REWARDS` failure instead of leaving an infinite loading message.

No duplicate Loyalty module, navigation, permission map, routing, or alternate engine is authorized.

## CURRENT FORENSIC CONCLUSION

```text
LOYALTY DATABASE = CLOSED
LOYALTY RPC ENGINE = CLOSED
LOYALTY EDGE CAPABILITY = CLOSED
LOYALTY TRANSACTION E2E (DB) = PASS
LOYALTY PRODUCTION DATA HYGIENE = PASS
LOYALTY MOTHER UI = ONE OWNER SURGICAL REPLACEMENT REQUIRED
BROWSER E2E = OPEN
GLOBAL LOYALTY = OPEN ONLY UNTIL OWNER PATCH + BROWSER E2E
```

This is not a backend infrastructure gap. Do not create new Loyalty tables or a second Edge Function unless a new current defect proves that the existing contract is insufficient.

## NEXT WORK AFTER LOYALTY UI CLOSES

After the owner applies the `renderConfig()` replacement, republishes the current mother file, and Browser/Console/Network E2E proves the UI path, move directly to:

`RETURN → LOYALTY REVERSAL POLICY`

Before any Production change there, reconstruct the historical Return contract, including order/runsheet settlement and customer financial effects. Do not infer that every return must reverse loyalty.

## EXECUTION RECORD

Current detailed report:
`doc/Draft/Reprots/Report191_LOYALTY_MOTHER_UI_FORENSIC_CLOSURE_20260915.md`

Previous reports remain unchanged and historical/reference only.

## START-HERE INSTRUCTIONS FOR THE NEXT CTO/ASSISTANT

1. Ignore prior numeric percentages and stale report claims until re-verified.
2. Read current Git HEAD, direct parent, and current mother blob.
3. Confirm `companies/company-1/main.html` is still the Source of Truth and reaches EOF.
4. Search the current source itself for `renderConfig()`; never inherit line anchors from stale reports.
5. Check current Production counts and call `loyalty_engine_atomic LIST_PROGRAMS` before changing anything.
6. Confirm the deployed `loyalty-engine` and the deferred `trg_orders_loyalty_auto_earn` still exist.
7. Apply no new backend structure if current Production already satisfies the contract.
8. Close the single owner-side `renderConfig()` defect, then perform real Browser/Console/Network E2E against the newly published current file.
9. Only after Browser E2E passes may Loyalty be marked fully closed.
10. Then continue to `RETURN → LOYALTY REVERSAL POLICY` and reconstruct the historical business contract before changing Production behavior.

**Never start from a report. Start from current Git + current source + current Production + current database + current deployment evidence.**
