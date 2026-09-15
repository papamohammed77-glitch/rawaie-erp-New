# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 07:xx UTC

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
Latest HEAD after current-session metadata commit: `11b99cab424496b9691e5ad92b36bd83ed7c2664`
Functional mother source remains unchanged at blob: `dd5516ea75d75e01a95d4782ec92603ecf427d2e`
Functional Loyalty commit: `716ebf86b3c989a461cbf86151b37fcd0849b0c3`
Its direct parent: `13425725f48c7decba3403ee631d8e0f2d757b0f`

The `11b99cab...` commit is an accidental empty metadata-only commit; GitHub returned `diff=null` and `files=null`. It did not modify `main.html`.

## CURRENT MOTHER FILE EVIDENCE

تم فتح current mother file من Git blob مباشرة، وقراءة المحتوى إلى EOF. النهاية المثبتة:

```html
</script>
</body>
</html>
```

Current functional Loyalty UI is present in the mother file. Report189's statement that the mother file had no Loyalty UI is STALE and superseded by current Git.

### Current Loyalty anchors

- Sales navigation Loyalty entry: current source around line `1144`.
- `RW_LoyaltyMain` module starts at the current Loyalty insertion area after the existing Sales Target module.
- `RW_LoyaltyMain.render()` contains the faulty async ordering around current line `2064`.
- `window.RW_SalesTargetsMain = RW_SalesTargetsMain;` is after the inserted Loyalty module.
- Loyalty routing is present in `RW_Views.render`.
- Permission map contains `'loyalty': 'customers'`.

## FORENSIC ASSEMBLY

`doc/Draft/forensic_main_assembly.yml` is the canonical reconstruction contract.

It must continue to point to:
- repository = `papamohammed77-glitch/erp-frontend`
- path = `companies/company-1/main.html`
- ref = `main`
- mode = `published_main_is_authoritative`
- fragment_mode = `historical_reference_only`

Current verified functional source commit: `716ebf86b3c989a461cbf86151b37fcd0849b0c3`.
Current direct parent: `13425725f48c7decba3403ee631d8e0f2d757b0f`.
Current mother blob: `dd5516ea75d75e01a95d4782ec92603ecf427d2e`.

## PRODUCTION — LOYALTY

Supabase project:
`fiilmooggumokxanwiyx`

Name:
`SMART ERP`

Status:
`ACTIVE_HEALTHY`

Current core:
`loyalty_engine_atomic(uuid,text,text,jsonb,text)`

Current Edge capability:
`loyalty-engine`, version `1`, `verify_jwt=true`.

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
- `loyalty_transactions`
- `loyalty_points`

### Production integrity changes completed

1. Direct user grants removed from Loyalty tables.
2. Legacy permissive `loyalty_points` direct policy removed.
3. `loyalty_transactions_company_operation_uidx` exists for non-null operation IDs.
4. `trg_loyalty_on_invoiced_order()` exists as Security Definer trigger function.
5. `trg_orders_loyalty_auto_earn` exists as `AFTER INSERT OR UPDATE OF order_status`, `DEFERRABLE INITIALLY DEFERRED`.
6. Automatic earning operation identity is deterministic:
   `AUTO:EARN_ORDER:<company_id>:<order_id>`.
7. Audit triggers are active on the Loyalty tables.
8. Canonical production migration source was added to `rawaie-erp-New/supabase/migrations/`.

## LOYALTY FUNCTIONAL VERIFICATION

### PASS — Automatic EARN

A temporary transactional test created an `Invoiced` order + detail and an Active loyalty program. The deferred order trigger fired after `SET CONSTRAINTS ALL IMMEDIATE` and produced:

`EARN`, `points_delta=15`, `balance 0→15`.

The test was rolled back completely.

### PASS — Transaction cycle

Within a temporary transaction:

`SAVE_PROGRAM → LIST_PROGRAMS → AUTO EARN → SAVE_REWARD → DUPLICATE EARN → REDEEM → REVERSE → GET_ACCOUNT`

Result:
`points_balance=15`, `lifetime_earned=15`, `lifetime_redeemed=10`.

The transaction was rolled back.

### PASS — Production persistence hygiene

Final counts verified:

```text
loyalty_programs=0
loyalty_rewards=0
loyalty_accounts=0
loyalty_transactions=0
loyalty_points=0
```

No E2E data remains.

## CURRENT MOTHER UI GAP

Loyalty navigation, permission map, routing, module, backend capability, and transaction engine are present.

The remaining current UI defect is precise:
`renderConfig()` executes before `loadPrograms()` completes and is not re-executed after the program list arrives. This leaves the rewards configuration panel on `جاري التحميل...` when no Active program is present at first render.

### OWNER-ONLY SURGICAL PATCH

In `RW_LoyaltyMain.render()`, current area around line `2064`, replace this exact four-line block:

```javascript
loadPrograms().then(function(){ renderProgramSummary(); }).catch(function(e){ showToast(e.message,'error'); });
loadCustomerOptions();
renderConfig();
subscribeRealtime();
```

with:

```javascript
loadPrograms().then(function(){
    renderProgramSummary();
    renderConfig();
}).catch(function(e){ showToast(e.message,'error'); });
loadCustomerOptions();
subscribeRealtime();
```

The owner must apply this to the current published mother file and republish. No other Loyalty navigation/module duplication is authorized.

## IMPORTANT — AUTOMATIC LOYALTY + ORDER LIFECYCLE

Automatic `EARN_ORDER` is now implemented in Production as a deferred order trigger, so order details are available inside the same transaction.

No manual `Earn` operation should be introduced in the Mother UI without a real `order_id`.

Return → Loyalty reversal remains intentionally open until the historical return business contract is reconstructed and the exact reversal/sync rule is proven.

## SALES TARGETS

No current Production defect was found requiring rework of Sales Targets.

Do not rewrite Sales Targets unless a new current defect is proved.

## CURRENT EXECUTION INCIDENTS

1. A prior Loyalty engine incomplete replacement was detected and restored; documented historically in Report189.
2. A current-session accidental empty commit `11b99cab...` was created in `erp-frontend`; GitHub proved no diff and no file changes. It must not be treated as a source modification.

## OPEN WORK

1. Owner applies the single four-line Loyalty render ordering patch in current `main.html`.
2. Republish current mother file.
3. Run Browser Console/Network E2E against published current mother.
4. Verify Loyalty config panel leaves `جاري التحميل...`, LIST_PROGRAMS/LIST_REWARDS calls return, realtime refresh works, and no Console errors occur.
5. After Browser E2E closes Mother UI, move to `RETURN → LOYALTY REVERSAL POLICY` and reconstruct the historical contract before touching Production behavior.

## CLOSURE STATUS

```text
LOYALTY TRANSACTION ENGINE — PRODUCTION BACKEND = 100% CLOSED
LOYALTY DATABASE INTEGRITY = CLOSED
LOYALTY EDGE DEPLOYMENT = CLOSED
LOYALTY TRANSACTION E2E (DB) = PASS
LOYALTY MOTHER UI = OPEN / ONE SURGICAL PATCH
BROWSER E2E = OPEN
GLOBAL LOYALTY = NOT YET FULLY CLOSED
```

## NEXT EXACT RESUMPTION POINT

Do not start from zero.

Start by re-reading current `main.html` and verifying its then-current blob SHA. Confirm whether the four-line Loyalty render block still exists. If yes, the only Mother UI change is the four-line replacement above. After owner republish, perform Browser E2E.

When UI is closed, next exact backend/business closure is:
`RETURN → LOYALTY REVERSAL POLICY`.

The next CTO must not infer that Return should deduct loyalty points. First reconstruct historical Return behavior, order settlement, customer financial effect, and the intended loyalty contract.

## REPORTS

Current report:
`doc/Draft/Reprots/Report190_LOYALTY_TRANSACTION_ENGINE_CURRENT_FORENSIC_CLOSURE_20260915.md`

All previous reports remain historical/reference only.