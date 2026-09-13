# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13
**Checkpoint:** Report157 — CTO E2E للنظام الأم — التحويلات المخزنية.

## GOVERNANCE

التقارير السابقة Historical/Reference فقط وليست حالة حالية.
الحالة المعتمدة هي فقط:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`.

**الهدف الحاكم — يُقرأ بعناية:** الهدف هو اختبار E2E لملف النظام الأم المنشور الحالي واستكماله وظيفيًا، وليس إعادة بناء الملفات التاريخية.

Source of Truth للواجهة:
`https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`

`Current/PWA/main2/*` و`Original/PWA/main/*` = historical/reference only.

## CURRENT GIT

Repository: `papamohammed77-glitch/erp-frontend`

HEAD:
`5bdb2863570085edd19265465937aea3c674b52c`

Direct parent:
`02166a9f8e94ac0b2cc15257eb0aec8e039848bd`

Parent of parent:
`06264f8eefc5e0d5281538c80e9c7aaa454ecf9b`

Current `main.html` blob:
`3c48e91d7d5359b3a1befe12ab56eb052c628b0e`

HEAD/parent chronology concerns the already-closed `_renderTable()` syntax/escaping regression. Do not repeat that repair unless fresh current evidence reopens it.

## FORENSIC ASSEMBLY

`rawaie-erp-New/forensic_main_assembly.yml` is currently correct:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

No change was required in this session.

## CURRENT PRODUCTION / DATABASE

Project: `fiilmooggumokxanwiyx`
Status: `ACTIVE_HEALTHY`
Latest migration observed: `20260913082923`
Company: `00000000-0000-0000-0000-000000000001` (`MAIN` / `الروائع`)

Current facts relevant to Transfer E2E:
- active branches = 2
- active direct-sales reps = 1
- active vehicles = 0
- items = 17
- stock_vouchers = 0
- orders = 0
- runsheets = 0

Current branches:
- `BR-01` — `الفرع الرئيسي` — Active
- `BR-2` — `فرع إسكندرية` — Active

`app_settings.main_branch_id` points to `BR-01`.

Current `branches` schema contains `name`, not `branch_name`.
No `public` table currently exposes a `branch_name` column.

## WAREHOUSE TRANSFERS — CURRENT TRUTH

Canonical contract:
- `Transfer = Branch → Branch`
- `DirectSale = Branch → Vehicle`
- `DirectReturn = Vehicle → Branch`
- `SupplierReturn = Branch → Supplier`

Relevant current Edge deployments:
- `create-stock-voucher` v10 — ACTIVE — JWT enabled
- `send-stock-voucher` v20 — ACTIVE — JWT enabled

Production transactional verification:
`BR-01 → BR-2 → item 1001 → create_manual_stock_voucher_atomic → send_stock_voucher_atomic`

Result: `create=success`, `send=success`, `status=Sent`, `movement_count=1`.
Transaction was rolled back; no permanent test data remains.

Therefore the current reported Transfer failure is frontend/schema-query related, not a proven Production Transfer Core failure.

## TRANSFER FRONTEND ROOT CAUSE

Current Source of Truth function:
`async function _loadVoucherEntityOptions(type)`

Current location: approximately lines **8157–8174**.

Exact defective line:
```javascript
.select('id, branch_code, name, branch_name')
```

Production has no `branch_name`. This directly explains:
`Column branches.branch_name doesn’t exist`

The historical `Current/PWA/main2/main7.md` contains the same bad query; therefore this is historical carryover, not proven to have been introduced by final assembly.

## OWNER PATCH — PENDING PUBLICATION

The owner must patch the published `main.html`; this automation did not modify that file.

Target function:
`async function _loadVoucherEntityOptions(type)`

Delete the complete `Transfer` branch block, beginning:
```javascript
    if (type === 'Transfer') {
```
and ending with its closing `}` immediately before:
```javascript
    if (type === 'SupplierReturn') {
```

Replace with:
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

## VEHICLES / REPS

The transfer selector for vehicle-based documents is data-dependent.
Production currently has zero active vehicles. This is not a proven query bug and must not be “fixed” by inserting fake Production vehicles.

## PRODUCTION CHANGE STATUS FOR THIS SESSION

Production schema changes: **0**
Production permanent data changes: **0**
Production Edge deployment changes for Transfer: **0**
Transactional test data: **ROLLBACK**

No Production repair was justified for the reported Transfer error after direct core verification.

## OTHER KNOWN OPEN FRONTEND PATCHES

These remain from the previous E2E investigation and were not reworked here because they were already proven independently:

1. `_renderUploadPreview()` around lines 3358–3359: `_valid` logic patch.
2. `_loadDetailedReports()` around line 12860: `itemSales` scope patch.
3. `_loadDetailedReports()` around line 13022: `inventoryRows` scope patch.

Do not assume these are applied until the current Source of Truth is re-read after owner publication. Do not redo them merely because they appear in older reports.

## E2E STATUS

Current status:
- Git/source/database/deployment evidence = VERIFIED
- Transfer backend = PRODUCTION TRANSACTION VERIFIED
- Transfer frontend root cause = PROVEN
- Owner frontend patch = READY
- Browser click-by-click E2E after patch = NOT YET PROVEN
- Global Gold/Diamond completion = NOT CLOSED

No Browser PASS is claimed because this environment has no Browser Automation channel.

## SESSION ARTIFACT

Report:
`doc/Draft/Reprots/Report157_CTO_E2E_Main_Transfers_20260913.md`

Commit:
`050c7614ab01de5ed29dc94a58bbe96b63d00410`

## NEXT SESSION START RULE

Start from live evidence in this exact order:

`CURRENT GIT HEAD → DIRECT PARENT → PARENT OF PARENT when material → CURRENT SOURCE OF TRUTH → CURRENT DB SCHEMA → CURRENT DB DATA → CURRENT EDGE DEPLOYMENTS/SOURCE → CURRENT RUNTIME/LOG EVIDENCE → reproduce exact symptom → exact line/function/query → historical reconstruction only to explain the contract → surgical fix → reread current source → Production transactional/runtime verification → report + CURRENT_STATE`

Never:
- treat an old report as current state;
- use `main2` as Source of Truth;
- redo a repair already proven closed;
- invent Production data to make E2E green;
- modify Production when the Production component is already verified;
- claim Browser PASS without actual browser evidence;
- batch unrelated Writer/Function closures.

**الحقيقة الحالية أولًا، ثم العقد، ثم الفجوة المثبتة، ثم الإصلاح الجراحي، ثم التحقق، ثم الإغلاق.**
