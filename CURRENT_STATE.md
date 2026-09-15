# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 17:10 UTC

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
Current HEAD: `f858fb2f909a074dfe97b90134ef5e05b5592cd9`
HEAD message: `Update comment timestamp in main.html`
Direct parent: `5767266ffdc853846193494db6d49ece19c3ef7f`
Parent message: `Refactor button generation loop in main.html`
Parent of parent: `9b39626e8679e35b8215adf2ba4977b838e1f5d2`

Current mother blob:
`a530b7adb2d590e0f7f476ce8c81f33dcd186e92`

The direct parent closed the earlier button-generation escaping defect. Do not reopen or repeat that fix without new current evidence.

## CURRENT MOTHER FILE EVIDENCE

تمت إعادة مطابقة الملف الأم الحالي من Current Git، مع اعتبار هذا الملف وحده مصدر التنفيذ.

EOF الحالي:

```html
</script>
</body>
</html>
```

لا يجوز استخدام أرقام أسطر من Report196 كمرجع حالي. أي surgical anchor يجب أن يُشتق من current mother source نفسه.

## CURRENT FORENSIC BLOCKER

Current Browser Console reports:

```text
main:9263 Uncaught SyntaxError: Unexpected string (at main:9263:65)
```

داخل `RW_PurchaseGold.createRequest()` يوجد anchor parser-level حول:

```javascript
raw.split('\
').forEach(function (line) {
```

والتصحيح الجراحي المحدد هو:

```javascript
raw.split('\n').forEach(function (line) {
```

لا يوجد دليل حالي يبرر Backend/Database change لهذا blocker.

Tailwind CDN warning is separate and non-blocking for this Closure.

## CURRENT ASSEMBLY

`forensic_main_assembly.yml` الحالي:

```yaml
version: 3
project: rawaea-erp
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

لا يوجد تعارض مثبت في Source of Truth path.

## CURRENT BROWSER E2E

Browser click-by-click E2E = OPEN.

The existing Browser gate is:
`.github/workflows/browser_e2e_mother_20260915.yml`

The older successful/in-progress run must not be promoted to current PASS when it targets an older mother state.

Closure for the current syntax blocker requires a fresh browser run after the owner applies the exact surgical edit and publishes the current mother.

## CURRENT PRODUCTION INVENTORY CONTEXT

Physical stock contract remains:

```text
PHYSICAL STOCK MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

No Production change was justified or made for the current mother parser blocker.

Previous Production inventory governance work remains closed unless a new current defect is proven.

## EXECUTION RECORD

Latest report:
`doc/Draft/Reprots/Report197_MOTHER_E2E_SYNTAX_BLOCKER_20260915.md`

Report196 remains Historical/Reference and is not a current-state authority.

## OWNER SURGICAL ACTION — CURRENT

In:
`companies/company-1/main.html`

Within:
`RW_PurchaseGold.createRequest()`

At current Console location:
`line 9263`

Find the complete two-line malformed element:

```javascript
raw.split('\
').forEach(function (line) {
```

Delete those two lines together and replace them with the complete two-line element:

```javascript
raw.split('\n').forEach(function (line) {
```

Do not alter the remainder of the function for this blocker.

## NEXT REQUIRED VERIFICATION

```text
Owner applies exact replacement
→ publish current main.html
→ verify published URL is current mother
→ run Browser E2E
→ SyntaxError = 0
→ Page Errors = 0
→ Login visible
→ Login succeeds
→ authenticated shell visible
→ first navigation succeeds
→ Network checked
→ current Git blob re-read
→ EOF re-verified
→ close blocker
→ move to next open E2E unit
```

## START-HERE — NEXT CTO

1. Read this CURRENT_STATE.md.
2. Reconcile CURRENT frontend HEAD and direct parent.
3. Verify current mother blob and EOF.
4. Verify `forensic_main_assembly.yml`.
5. Read current Browser/Console/Network evidence.
6. Locate the exact current source anchor; never reuse stale report line numbers.
7. For mother defects, provide owner-side exact delete/replace instructions; do not edit the mother directly.
8. For Production defects, implement directly only after current evidence proves the defect.
9. Never reopen a closed Closure without new evidence.
10. After current blocker closes, move directly to the next genuinely open E2E item.

## CURRENT CLOSURE

```text
Current Git/Parent Reconciliation       = VERIFIED
Current Mother Source / EOF             = VERIFIED
forensic_main_assembly                  = VERIFIED
Current SyntaxError                     = PROVEN
Surgical Fix                            = READY
Production Change for this blocker      = NOT REQUIRED
Owner Application                       = REQUIRED
Current Browser E2E                     = OPEN
Overall current session closure         = OPEN
```
