# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 12:36 UTC

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
Latest HEAD: `66ed7f2c58fc1cd97526d6ea5b12116961102c9f`
Direct parent: `27cfa8c580565942c5497ebf5ffe623eb0768aaa`
Parent of parent: `24e0124bedf6356103cb28bf365cef8e46be8027`
Current mother blob: `3cd3af5cd32891e88ed32b70f1d42db06fa35667`

HEAD `66ed7f2...` = `Update sales decision center and navigation structure`.
Direct parent `27cfa8...` = Loyalty `renderConfig()` terminal-state repair.

## CURRENT MOTHER FILE EVIDENCE

تم فتح current mother blob مباشرة من Git.

EOF الحالي:

```html
</script>
</body>
</html>
```

Current blob search:

```text
قيد التطوير  = 0 matches
جاري التطوير = 0 matches
```

تم رفض اختراع line numbers عندما لا يعيد GitHub connector range موثوقًا لملف الـblob الضخم. استخدم exact textual anchors من current source، وليس أرقام التقارير القديمة.

## CURRENT ASSEMBLY

`forensic_main_assembly.yml` الحالي:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

لا يوجد تعارض في Source of Truth path.

## CURRENT SALES DECISION CENTER

HEAD الحالي أضاف في Navigation:

```javascript
{ view: 'sales-decision-center', label: 'مركز قرار المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] }
```

كما أضاف module مستقل:
`RW_SalesDecisionCenter`

Production snapshot verified at:
`2026-09-15 12:36:02.254148+00`

```text
sales_decision_policies      = 1
sales_decision_evaluations   = 0
sales_decision_approvals     = 0
sales_decision_pending       = 0
```

## CURRENT LOYALTY STATUS

Production Loyalty backend/engine remain CLOSED by prior verified evidence unless new current evidence proves otherwise.

Current mother still requires the owner-side Browser-facing E2E verification of the published Loyalty UI.

Current owner-side exact anchors:

```javascript
function renderConfig(){
```

through the complete function ending immediately before:

```javascript
function renderRewards(){
```

The current Production state with zero active programs requires a terminal empty-state, not an infinite loading placeholder.

Do NOT recreate Loyalty tables, Edge Functions, or backend engine without a new proven defect.

## BROWSER E2E

`Browser click-by-click E2E = OPEN`.

سبب بقاء الحالة مفتوحة:
بيئة التنفيذ الحالية لا توفر جلسة browser automation / live Chromium قابلة لتنفيذ النقرات الفعلية ومراقبة Console + Network بصورة متزامنة.

Static/Git/DB evidence لا تُحوّل إلى Browser PASS.

## PRODUCTION INVENTORY GOVERNANCE CONTEXT

Physical stock contract remains:

```text
PHYSICAL STOCK MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

No new parallel Physical Stock Engine is authorized.

Recent verified constraints include:
- `items.item_code` UNIQUE globally.
- `stock_branches` UNIQUE `(branch_id,item_id)`.
- `receiving.operation_id` UNIQUE.

Earlier Production anomalies around cross-company item metadata remain historical/data-hygiene evidence and must be revalidated before any cleanup mutation.

## EXECUTION RECORD

Latest report:
`doc/Draft/Reprots/Report193_BROWSER_E2E_FORENSIC_CLOSURE_20260915.md`

Previous reports remain unchanged and Historical/Reference only.

## START-HERE — NEXT CTO

1. Re-read CURRENT Git HEAD and its direct parent.
2. Open the current mother blob and verify SHA + EOF.
3. Re-verify `forensic_main_assembly.yml`.
4. Query current Production state for the exact feature under test.
5. Never reuse stale line numbers; derive anchors from current source.
6. Do not modify historical fragments.
7. For mother-file defects, give owner a complete exact delete/replace block; never edit the mother directly.
8. For Production defects, implement directly, test transactionally, then verify runtime.
9. Browser/Console/Network verification is a separate closure gate and cannot be inferred from source or DB PASS.
10. After Browser E2E closes, move to the next open roadmap unit. Do not reopen already-closed backend work without new evidence.

## CURRENT CLOSURE

```text
Git/Source Reconciliation           = VERIFIED
Production SDC Snapshot             = VERIFIED
Mother EOF                          = VERIFIED
forensic_main_assembly              = VERIFIED
Placeholder scan                    = VERIFIED (0 exact matches)
Browser Click-by-Click E2E          = OPEN
Overall current session closure     = OPEN
```
