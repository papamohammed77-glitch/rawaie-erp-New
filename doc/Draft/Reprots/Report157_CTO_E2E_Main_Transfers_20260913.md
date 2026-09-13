# Report157 — CTO E2E للنظام الأم — التحويلات المخزنية

## 0. الهدف الحاكم — يُقرأ بعناية
**الهدف هو اختبار E2E لملف النظام الأم الحالي `main.html` واستكماله وظيفيًا، وليس إعادة بناء الملفات التاريخية.** والحالة المعتمدة فقط هي: `CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`.

Source of Truth: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html

## 1. CURRENT GIT
HEAD: `5bdb2863570085edd19265465937aea3c674b52c`
DIRECT PARENT: `02166a9f8e94ac0b2cc15257eb0aec8e039848bd`
PARENT OF PARENT: `06264f8eefc5e0d5281538c80e9c7aaa454ecf9b`

HEAD/parent changes concern `RW_Items._renderTable()` syntax/escaping. No commit in this chain proves creation of the current Transfer `branch_name` defect. Do not repeat the already-closed `_renderTable()` syntax repair.

Current `main.html` blob: `3c48e91d7d5359b3a1befe12ab56eb052c628b0e`.

## 2. CURRENT SOURCE — ROOT CAUSE
Current function: `async function _loadVoucherEntityOptions(type)`.
Current Transfer block is around lines 8157–8174. The exact offending line is approximately **8159**:

```javascript
.select('id, branch_code, name, branch_name')
```

The same Transfer block later contains the unnecessary fallback `branches[i].branch_name`.

Production `public.branches` has `id, company_id, branch_code, name, location, manager, phone, is_active, created_at, updated_at`; it has no `branch_name` column.

Therefore the browser error `Column branches.branch_name doesn’t exist` is directly explained by the current source and current schema.

## 3. HISTORICAL RECONSTRUCTION
`Current/PWA/main2/main7.md` contains the same Transfer query with `branch_name`. Therefore this is a historical carryover, not proven to be introduced by the final assembly. `main2` remains reference-only; the published `main.html` remains authoritative.

## 4. PRODUCTION DATA REALITY
Current Production company: `00000000-0000-0000-0000-000000000001`.

Active branches:
- `BR-01` — `الفرع الرئيسي`
- `BR-2` — `فرع إسكندرية`

Active direct-sales reps: `1`.
Active vehicles: `0`.

Thus after fixing the Transfer branch query, the branch selector should show 2 active branches. A vehicle selector remaining empty is currently explained by Production data; do not create fake vehicle data to make the test pass.

## 5. FORENSIC ASSEMBLY
`rawaie-erp-New/forensic_main_assembly.yml` is already correct:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

No change required.

## 6. CURRENT PRODUCTION / DEPLOYMENT
Latest Production migration observed: `20260913082923`.

Relevant active Edge deployments include:
- `create-stock-voucher` v10, JWT enabled.
- `send-stock-voucher` v20, JWT enabled.

These wrappers resolve company context from the authenticated user and use the manual stock voucher RPCs. No Production Edge change is justified for the reported Transfer UI error.

## 7. PRODUCTION RUNTIME VERIFICATION
A direct transactional Production test was executed:

`BR-01 → BR-2 → item 1001 → create_manual_stock_voucher_atomic → send_stock_voucher_atomic`

Result:

```text
create = success
send = success
status = Sent
movement_count = 1
```

The transaction was rolled back. No permanent test data remains.

This proves the current Warehouse Transfer backend core is operational for the tested contract. The reported error is therefore a frontend schema-query defect.

## 8. OWNER SURGICAL PATCH — ONLY FRONTEND CHANGE REQUIRED NOW
Do **not** modify `erp-frontend/companies/company-1/main.html` through automation. The owner performs this patch.

### Exact target
Function:
```javascript
async function _loadVoucherEntityOptions(type)
```

Current location: around lines **8157–8174** in current `main.html` blob `3c48e91d7d5359b3a1befe12ab56eb052c628b0e`.

### Delete this COMPLETE block
Start:
```javascript
    if (type === 'Transfer') {
```
End with the `return;` and closing `}` immediately before:
```javascript
    if (type === 'SupplierReturn') {
```

### Replace it with this COMPLETE block
```javascript
    if (type === 'Transfer') {
        var branchRes = await supabase.from('branches')
            .select('id, branch_code, name')
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('name');
        if (branchRes.error) { showToast(branchRes.error.message, 'error'); return; }

        var branchHtml = '<option value="">-- اختر فرعاً --</option>';
        var branches = branchRes.data || [];
        for (var i = 0; i < branches.length; i++) {
            branchHtml += '<option value="' + branches[i].id + '">' +
                (branches[i].name || branches[i].branch_code || '') +
                '</option>';
        }
        safeHTML(select, branchHtml);
        return;
    }
```

Do not modify `SupplierReturn`, `DirectSale`, or `DirectReturn` in this surgery.

## 9. WHAT MUST NOT BE PATCHED
Do not repeat:
- `_renderTable()` syntax repair already present in HEAD.
- `forensic_main_assembly.yml`.
- `Current/PWA/main2/*`.
- Production Transfer RPC/Core, which passed the transactional test.
- Vehicle master data merely to satisfy E2E.
- Other `branch_name` property fallbacks unless their own query is proven to request a nonexistent DB column.

## 10. BROWSER E2E — NOT YET CLOSED
After the owner applies the exact patch and publishes `main.html`:
1. Open a fresh private browser.
2. Confirm the served source is the new `main.html`.
3. Open warehouse stock vouchers/transfers.
4. Select `تحويل مخزني`.
5. Verify the 2 branches appear.
6. Verify the `branch_name` error is gone.
7. Select destination branch.
8. Add item `1001`.
9. Execute `حفظ وإرسال`.
10. Verify the call path reaches `create-stock-voucher` then `send-stock-voucher` and final status `Sent`.

No Browser PASS is claimed in this report because no browser automation channel is available in this environment.

## 11. E2E / CLOSURE STATUS
```text
CURRENT GIT = VERIFIED
CURRENT SOURCE = VERIFIED
CURRENT DATABASE SCHEMA = VERIFIED
CURRENT PRODUCTION DATA = VERIFIED
CURRENT DEPLOYMENTS = VERIFIED
TRANSFER BACKEND = PRODUCTION TRANSACTION VERIFIED
TRANSFER FRONTEND ROOT CAUSE = PROVEN
FRONTEND OWNER PATCH = READY
PRODUCTION PATCH = NOT REQUIRED
BROWSER E2E = OPEN UNTIL OWNER DEPLOYS PATCH
GLOBAL GOLD/DIAMOND = NOT PART OF THIS CLOSURE
```

## 12. SELF-AUDIT
### What I proved
- Latest HEAD and direct parent chain.
- Current published source and current blob.
- Current `branches` schema and absence of `branch_name`.
- Two active branches.
- Zero active vehicles.
- One active direct-sales representative.
- Historical carryover of the same bad query.
- Correct `forensic_main_assembly.yml` Source of Truth.
- Production Transfer create/send path succeeds transactionally and leaves no test data.

### What I did not prove
- Click-by-click Browser E2E after owner publication.
- Completion of every other parent tab as Gold/Diamond; that is outside this Transfer closure.
- Any requirement that Production must contain vehicles; current database proves the opposite.

### Errors encountered during investigation
- Earlier state files/reports pointed to stale blob values; the current source proved the live blob is `3c48...`.
- A backend test using an invalid actor was rejected by the Production authorization contract, as expected.
- No permanent Production test data was retained.

## 13. FINAL GUIDANCE TO THE NEXT CTO / ASSISTANT
Always begin from live evidence, never from report status:

```text
CURRENT GIT HEAD
→ DIRECT PARENT
→ PARENT OF PARENT when material
→ CURRENT SOURCE OF TRUTH
→ CURRENT PRODUCTION DATABASE SCHEMA
→ CURRENT PRODUCTION DATA
→ CURRENT EDGE DEPLOYMENTS / VERSIONS / SOURCE
→ CURRENT RUNTIME / LOG EVIDENCE
→ REPRODUCE THE EXACT SYMPTOM
→ IDENTIFY EXACT LINE / FUNCTION / QUERY
→ HISTORICAL RECONSTRUCTION ONLY TO EXPLAIN THE CONTRACT
→ IDENTIFY THE ACTUAL GAP
→ APPLY ONE SURGICAL CLOSURE ONLY
→ REREAD CURRENT SOURCE
→ TRANSACTIONAL PRODUCTION TEST
→ RUNTIME VERIFICATION
→ REPORT + CURRENT_STATE UPDATE
```

Never:
- trust a stale report as current state;
- re-fix a defect already proven fixed;
- use `main2` as Source of Truth;
- create fake Production data to obtain a green E2E;
- change Production when the Production component is already proven correct;
- infer a bug from empty data when the live database explains the emptiness;
- close a percentage or claim E2E PASS before matching the current Production state in the same investigation;
- batch unrelated Writer/Function closures.

**الحقيقة الحالية أولًا، ثم العقد، ثم الفجوة المثبتة، ثم الإصلاح الجراحي، ثم تحقق Production، ثم الإغلاق.**