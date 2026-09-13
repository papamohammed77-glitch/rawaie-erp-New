# Report156 — CTO E2E للنظام الأم — Current Gaps

## الهدف الحاكم — يُقرأ بعناية
الهدف هو اختبار E2E لملف النظام الأم الحالي واستكماله وظيفيًا، وليس إعادة بناء الملفات التاريخية.

Source of Truth:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

الحالة المعتمدة فقط:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

## CURRENT GIT
HEAD: `5bdb2863570085edd19265465937aea3c674b52c`
DIRECT PARENT: `02166a9f8e94ac0b2cc15257eb0aec8e039848bd`
PARENT OF PARENT: `06264f8eefc5e0d5281538c80e9c7aaa454ecf9b`

الـparent أزال قوس إغلاق `_renderTable()`، وHEAD الحالي أصلح regression. لا تعاد إصلاحات Report154 الخاصة بالـSyntax.

## FORENSIC ASSEMBLY
`forensic_main_assembly.yml` صحيح:
`source_of_truth.repository = papamohammed77-glitch/erp-frontend`
`source_of_truth.path = companies/company-1/main.html`
`source_of_truth.ref = main`
`assembly_status = reference_only; published_main_is_authoritative`
لا تعديل.

## PRODUCTION SNAPSHOT
Project: `fiilmooggumokxanwiyx`
Latest migration: `20260913082923`
Company 1: `00000000-0000-0000-0000-000000000001`
Categories=5, Items=17, unresolved category links=0, active branches=2, active direct-sales reps=1, active vehicles=0.

Deployment: create-stock-voucher v10, send-stock-voucher v20, receive-stock-voucher v22, bulk-stock-adjustment v6, save-item v13, save-category v4, receive-purchase v12, complete-return v25, complete-order-delivery v14.

## ITEMS / CATEGORIES
المصدر الحالي يملك List/Search/Category filter/Sorting/Branch matrix/Movement/Excel export/CSV-XLS-XLSX upload/Bulk adjustment/Category CRUD/Item CRUD.

Category lookup الحالي Company-scoped، وProduction تثبت 5 تصنيفات وعدم وجود item.category غير مربوط بـcategory_id. لا Patch لهذه الجزئية.

## UPDATE BALANCES — ROOT CAUSE مثبت
في `_renderUploadPreview()`، السطور الحالية 3358–3359:
```javascript
                            entry._valid =
                                !!item && !status;
```

هذا يعكس المنطق: الصف الصحيح يملك `status = '✅ صالح'` وبالتالي يصبح `_valid=false`.

### تعليمات المالك
ابحث عن الدالة `function _renderUploadPreview()`، ثم ابحث عن المقطع أعلاه واحذفه بالكامل واستبدله:
```javascript
                            entry._valid =
                                !!item &&
                                !duplicateBarcodeMap[entry.barcode] &&
                                status === '✅ صالح';
```

## DETAILED REPORTS — ROOT CAUSE مثبت
### itemSales
داخل `_loadDetailedReports()`، السطر 12860 تقريبًا:
```javascript
        if (types.indexOf('sales-by-item') !== -1) {
            var itemSales = {};
```
لاحقًا يستخدم `Object.keys(itemSales)` في `inventory-top` حتى دون اختيار `sales-by-item`.

### تعليمات المالك
استبدل المقطع بالكامل بـ:
```javascript
        var itemSales = {};

        if (types.indexOf('sales-by-item') !== -1) {
```

### inventoryRows
داخل `_loadDetailedReports()`، السطر 13022 تقريبًا:
```javascript
        if (
            types.indexOf('inventory-low') !== -1 ||
            types.indexOf('inventory-top') !== -1 ||
            types.indexOf('inventory-dormant') !== -1
        ) {
            var inventoryRows = [];
```
لاحقًا يتم تنفيذ `inventoryRows.length` داخل `rec-purchase/rec-offers` حتى لو لم يتم اختيار تقارير inventory؛ وهذا يفسر مباشرة:
`Cannot read properties of undefined (reading 'length')`

### تعليمات المالك
استبدل المقطع بالكامل بـ:
```javascript
        var inventoryRows = [];

        if (
            types.indexOf('inventory-low') !== -1 ||
            types.indexOf('inventory-top') !== -1 ||
            types.indexOf('inventory-dormant') !== -1
        ) {
```

## WAREHOUSE TRANSFERS
العقد الحالي مثبت في Production:
`Transfer = Branch → Branch`
`DirectSale = Branch → Vehicle`
`DirectReturn = Vehicle → Branch`
`SupplierReturn = Branch → Supplier`

الواجهة Company-scoped صحيحة، والـcore يدعم Vehicle contract. عدم ظهور السيارات سببه Production الحالية: `active_vehicles=0`، وليس query ناقصًا. لا إنشاء بيانات وهمية ولا Patch.

## PHYSICAL STOCK
يوجد overload تاريخي 9-arg لـ`post_stock_movement` لكنه غير قابل للتنفيذ من `service_role`; الـ10-arg هو السطح الحالي المفعّل. لم يحذف في هذه الجلسة لأنه ليس سببًا مثبتًا لمشاكل E2E الحالية.

## CAPABILITY GATES
`rec-customers` و`rec-expansion` يعرضان Capability Gate بدل Business Rule آلية. لا يجوز اختراع سياسة جديدة دون Contract/Production evidence. لذلك لا تعتبر هاتان القدرتان Gold/Diamond مكتملتين بعد.

## SELF-AUDIT
### مثبت
HEAD/parent chronology، Source of Truth، Production deployment versions، Category integrity، Vehicle reality، Update Balances root cause، Detailed Reports root causes.

### غير مثبت
Browser click-by-click E2E بعد تطبيق patch؛ Excel real-browser execution؛ اكتمال كل تقارير Gold/Diamond خارج هذا closure.

لا توجد قناة Browser Automation فعلية في بيئة هذه الجلسة، لذلك لا يجوز الادعاء Browser PASS.

## إرشادات المساعد القادم
ابدأ دائمًا:
`CURRENT GIT → PARENT COMMITS → CURRENT SOURCE → CURRENT PRODUCTION/DB → CURRENT DEPLOYMENT/RUNTIME → exact symptom → exact line/function → root cause → surgical fix → reread → verify → report`.

لا تبدأ من تقرير قديم، ولا تعيد إصلاح ما ثبت أنه صحيح، ولا تخترع بيانات أو Business Rules، ولا تعتبر Staging/Static PASS = Production PASS.

**الحقيقة الحالية أولًا، ثم الإصلاح المثبت، ثم التحقق.**
