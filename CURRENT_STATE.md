# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 12:58 UTC

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
Latest known application HEAD before test-infrastructure commit: `66ed7f2c58fc1cd97526d6ea5b12116961102c9f`
Direct parent: `27cfa8c580565942c5497ebf5ffe623eb0768aaa`
Parent of parent: `24e0124bedf6356103cb28bf365cef8e46be8027`
Current mother blob at the application HEAD: `3cd3af5cd32891e88ed32b70f1d42db06fa35667`

A new test-infrastructure commit was added after that application HEAD:
`afbdd46b2bcf503bcf3b92b5ad1da97ed2495ebd`

It adds only `.github/workflows/browser_e2e_mother_20260915.yml` and does NOT modify `companies/company-1/main.html`.

## CURRENT MOTHER FILE EVIDENCE

تم تثبيت current mother blob مباشرة من Git.

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

لا يجوز اختراع line numbers لملف ضخم عندما لا يعيد connector range موثوقًا؛ استخدم exact textual anchors من current source.

## CURRENT ASSEMBLY

`forensic_main_assembly.yml` الحالي يثبت:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

لا يوجد تعارض مثبت في Source of Truth path.

## CURRENT SALES DECISION CENTER

HEAD الحالي أضاف في Navigation:

```javascript
{ view: 'sales-decision-center', label: 'مركز قرار المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] }
```

كما أضاف module مستقل: `RW_SalesDecisionCenter`.

Production snapshot verified previously:

```text
sales_decision_policies      = 1
sales_decision_evaluations   = 0
sales_decision_approvals     = 0
sales_decision_pending       = 0
```

## CURRENT LOYALTY STATUS

Production Loyalty backend/engine remain CLOSED by prior verified evidence unless new current evidence proves otherwise.

Current mother requires owner-side Browser-facing E2E verification of the published Loyalty UI before any new Loyalty patch is justified.

Current-source anchors:

```javascript
function renderConfig(){
```

through the complete function ending immediately before:

```javascript
function renderRewards(){
```

Do NOT recreate Loyalty tables, Edge Functions, or backend engine without new proven defect evidence.

## BROWSER E2E

`Browser click-by-click E2E = OPEN`.

A real Browser E2E infrastructure gate has now been created in:

```text
.github/workflows/browser_e2e_mother_20260915.yml
```

Test-infrastructure commit:
`afbdd46b2bcf503bcf3b92b5ad1da97ed2495ebd`

First run:
`34971719855`

Last verified state:

```text
Checkout current Source of Truth = SUCCESS
Setup Node                        = SUCCESS
Install Playwright               = IN PROGRESS
```

The final browser conclusion was not available within the execution window used for this state update.

Therefore:

```text
Browser infrastructure = CREATED
Browser click-by-click E2E = OPEN
```

Static/Git/DB evidence must never be promoted to Browser PASS.

## TEST SCOPE OF NEW BROWSER GATE

The new Playwright gate:

- checks the exact current mother source from Git when no deployed URL is supplied;
- supports an explicit deployed URL through `workflow_dispatch`;
- captures HTTP status, title, visible buttons, login form presence, console errors, and page errors;
- rejects incomplete markers;
- keeps the mother file unchanged.

This is a repeatable execution gate, not a claim that the published Production browser flow is already closed.

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

Verified schema facts include:
- `items.item_code` UNIQUE globally.
- `stock_branches` UNIQUE `(branch_id,item_id)`.
- `receiving.operation_id` UNIQUE.

Previous cross-company item metadata anomalies remain data-hygiene evidence and must be revalidated before destructive cleanup.

## EXECUTION RECORD

Latest report:
`doc/Draft/Reprots/Report194_BROWSER_E2E_EXECUTION_20260915.md`

Previous reports remain unchanged and Historical/Reference only.

## START-HERE — NEXT CTO

1. Read this CURRENT_STATE.md.
2. Get CURRENT frontend HEAD and direct parent.
3. Verify current mother blob SHA and EOF.
4. Verify `forensic_main_assembly.yml`.
5. Query current Production for the exact feature under test.
6. Run the new Browser E2E gate.
7. Never convert static/source/DB PASS into Browser PASS.
8. For mother defects, derive exact current anchors and provide a complete owner-side delete/replace block; do not edit the mother directly.
9. For Production defects, implement directly, test transactionally, then runtime-verify.
10. After Browser E2E closes with Browser + Console + Network evidence, move directly to the next open roadmap unit.
11. Do not reopen already-closed backend work without new evidence.

## CURRENT CLOSURE

```text
Git/Source Reconciliation            = VERIFIED
Production SDC Snapshot              = VERIFIED
Mother EOF                           = VERIFIED
forensic_main_assembly               = VERIFIED
Placeholder scan                     = VERIFIED (0 exact matches)
Browser E2E infrastructure            = CREATED
Browser E2E run 34971719855           = IN PROGRESS at last verified poll
Browser Click-by-Click E2E            = OPEN
Overall current session closure       = OPEN
```
