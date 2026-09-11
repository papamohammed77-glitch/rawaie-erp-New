# تقرير 121 — المراجعة الجنائية النهائية لـ Main2
## RAWAEA ERP — Main2 Forensic Recheck / Gold-Diamond Functional Gate

### 0. الهدف الحاكم — إعادة التأكيد
هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.

وهذا متسق حرفيًا مع مبدأ الحوكمة:
الدراسة أولًا → إعادة بناء العقد التاريخي → تتبع السلوك الحالي → تتبع البيانات والصلاحيات والتدفق → تحديد الفجوة الفعلية → التعديل الجراحي → الاختبار → التحقق من Production → التوثيق.

---

## 1. بيانات التنفيذ

- التاريخ: 2026-09-11
- Current Git HEAD عند نهاية التحقيق: `ecc5a33c55520cb0d9233d7934ed0423fe3a9ef7`
- Main2 current blob SHA: `baee3cc02ae5701e6fbcbad12e57e2930afc4ae4`
- آخر commit غيّر Main2: `625e7a8df17042f8701dc288f98eae381bdc3e82`
- آخر Main2 commit: `2026-09-10 15:21:12 +03`
- Main2 source of truth: `Current/PWA/main2/main2.md`
- Historical reference only: `Original/PWA/main/main2.md`
- ممنوع الرجوع إلى: `Current/PWA/New-main`
- Assembly: مؤجل.

---

## 2. المصادر التي تمت مراجعتها

تمت إعادة مراجعة المصادر التالية قبل الحكم:

1. `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
2. `MAIN1_FORENSIC_RECHECK_20260911_R5.md`
3. `OWNER_CHANGESETS_20260911_MAIN1_R5.md`
4. `Report119_Main2_Reality_Reconciliation_20260910.md`
5. `Report118_Main2_Surgical_Execution_20260910.md`
6. `Report120_Main1_Main11_Verification_Directive_20260910.md`
7. `CURRENT_STATE.md`
8. `Current/PWA/main2/main2.md`
9. `Original/PWA/main/main2.md`
10. Git history والـcommits المرتبطة بـMain2.
11. Production Supabase الحالية والدوال المرتبطة مباشرة بقدرات Main2.

### ملاحظة حوكمة
التقارير التاريخية استُخدمت كأدلة واتجاهات، ولم تُعتمد كحقيقة حالية دون مطابقة Git/Production.

---

## 3. Fresh Production Snapshot

تم قياس Production مباشرة في:

`2026-09-11 20:16:24.49657 UTC`

النتيجة:

- companies = 1
- branches = 2
- users = 24
- items = 17
- customers = 3
- orders = 0
- purchase_orders = 0
- stock_branches = 20
- inventory_log = 3
- audit_log = 1869

لا يوجد تغير في أعداد بيانات الأعمال ناتج عن اختبارات هذه الجلسة.

---

## 4. Main2 Reality Reconciliation

### 4.1 نتائج R118/R119 القديمة

العيوب التي كانت مسجلة سابقًا في Report118 لم تعد هي الحقيقة الحالية.

ثبت من Git الحالي أن:

- `RW_Dashboard.loadAll()` يستخدم `get_profit_loss` كمصدر صافي الربح المحاسبي Production.
- `_loadCategoriesIntoSelect()` أصبح يحتوي `var companyId = _rwCompanyId();` مع حارس للسياق.
- `_openCategoryModal()` أصبح company-scoped.
- `_deleteCategory()` أصبح company-scoped.
- `_buildCategoryFilterFromDB()` أصبح company-scoped.
- `_renderUploadPreview()` أصبح company-scoped.

هذه التغييرات مثبتة في Main2 الحالي وليست مطلوبة للإعادة.

### 4.2 Contract الحركة المخزنية

تعريف Production الحالي لـ`post_stock_movement` يثبت أن أنواع الحركة المادية المقبولة هي:

`PurchaseIn, TransferOut, TransferIn, POSSale, VanSale, DirectSale, SalesReturn, DirectReturn, SupplierReturn, InventoryIncrease, InventoryDecrease, Loading, Unloading`

وأن تحديث `stock_branches` وكتابة `inventory_log` تتم داخل هذا المحرك المركزي.

كما أن `create_item_with_opening_stock` يمرر الرصيد الافتتاحي إلى `post_stock_movement` بحركة `InventoryIncrease`، وبالتالي لا يوجد Writer موازٍ للرصد الافتتاحي في هذه القدرة.

### 4.3 Movement Report

`_loadMovementReport()` في Main2 يستخدم نفس مجموعة أنواع الحركة الحالية التي يقبلها Production `post_stock_movement`، ويقرأ `inventory_log` company-scoped وitem-scoped، ويحسب أثر الفرع من `source_branch_id` / `target_branch_id`.

لم تثبت هنا حاجة إلى إعادة كتابة هذا المسار.

### 4.4 Bulk Stock Adjustment

Production الحالية كانت بالفعل على version 6 من `bulk-stock-adjustment` وتستخدم:

`users.auth_id → company_id`

وليس `app_settings LIMIT 1`.

لذلك لم يتم إعادة نشرها أو تعديلها مرة أخرى.

كما أن Main2 الحالي يحتوي بالفعل على `_uploadOperationId` و`_uploadOperationFingerprint` ويعيد تحميل الأصناف والأرصدة بعد النجاح.

---

## 5. Production Repairs Executed Directly

هذه التعديلات نُفذت مباشرة في Production لأنها خارج Owner Source Boundary لـMain2.

### 5.1 `save-item` — Production version 13

تم إغلاق فجوة صلاحيات حقيقية:

- التحقق من المستخدم عبر `auth_id`.
- استخراج `company_id` من `public.users`.
- رفض المستخدم Inactive.
- احترام Owner semantics.
- فرض صلاحية `items` أو `*` للمستخدم غير المالك.
- الإبقاء على `create_item_with_opening_stock` كالمسار الحاكم للرصد الافتتاحي.

Production verification:

`save-item version = 13`

### 5.2 `delete-item` — Production version 4

تم إغلاق فجوة خطيرة كانت تسمح بالحذف باستخدام `item_code` دون company scope.

التصحيح المطبق:

- استخراج `company_id` من المستخدم المصادق عليه.
- رفض Inactive.
- فرض صلاحية `items` أو `*` للمستخدم غير المالك.
- الحذف أصبح:
  `company_id + item_code`

Production verification:

`delete-item version = 4`

### 5.3 `save-category` — Production version 4

تم إغلاق ثلاث فجوات:

- إنشاء التصنيف كان يكتب Company ID ثابتًا.
- التعديل والحذف لم يكونا company-scoped بصورة كافية.
- نقل الأصناف عند تغيير التصنيف لم يكن مقيدًا بالشركة.

الإصلاح الحالي:

- استخراج `company_id` من المستخدم.
- Owner/permission semantics محفوظة.
- create/update/delete/replacement جميعها company-scoped.
- تحديث الأصناف المرتبطة company-scoped.

Production verification:

`save-category version = 4`

---

## 6. Main2 — Defect مثبت حاليًا

### MAIN2-D1 — Top Items Detail Navigation

#### السبب في اعتباره Defect وليس اقتراحًا
في واجهة Dashboard الحالية، العنوان المقدم للمستخدم هو:

`أفضل 10 أصناف (اضغط للتفاصيل)`

لكن داخل `renderTopItemsChart(details)` عند النقر الحالي يتم فقط:

`RW_Navigation.navigate('items');`

ويتم حساب `itemName` دون استخدامه لتحديد الصنف.

إذن النص يعد بتفاصيل لصنف محدد، بينما السلوك الحالي ينقل المستخدم إلى صفحة الأصناف العامة فقط.

هذا تعارض مباشر بين UI Contract والسلوك الفعلي، ولا يحتاج إلى افتراض Business Rule جديد.

---

## 7. Owner Source Surgery — المطلوب من المالك

### MAIN2-D1

**موضع العنصر في `Current/PWA/main2/main2.md`: الأسطر 352–387.**

ابحث عن السطر:

`function renderTopItemsChart(details) {`

احذف الدالة كاملة حتى آخر سطر لها:

`    }`

الموجود مباشرة قبل:

`    function renderTopCustomersChart(orders) {`

ثم استبدل الدالة كاملة بالنص التالي:

```javascript
    function renderTopItemsChart(details) {
        var canvas = byId('chart-items');
        if (!canvas) return;
        var ctx = canvas.getContext('2d');
        if (!ctx) return;

        var map = {};

        for (var i = 0; i < details.length; i++) {
            var code = details[i].item_code || details[i].item_name;
            var name = details[i].item_name || code;
            var total =
                (Number(details[i].qty) || 0) *
                (Number(details[i].unit_price) || 0);

            if (!map[code]) {
                map[code] = {
                    name: name,
                    total: 0,
                    code: code
                };
            }

            map[code].total += total;
        }

        var arr = [];

        for (var k in map) {
            arr.push(map[k]);
        }

        arr.sort(function(a, b) {
            return b.total - a.total;
        });

        arr = arr.slice(0, 10);

        if (typeof Chart === 'undefined') return;

        _charts['chart-items'] = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: arr.map(function(a) {
                    return a.name;
                }),
                datasets: [{
                    label: 'الإجمالي (EGP)',
                    data: arr.map(function(a) {
                        return a.total;
                    }),
                    backgroundColor: '#8b5cf6'
                }]
            },
            options: {
                indexAxis: 'y',
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                onClick: function(e, elements) {
                    if (elements.length > 0) {
                        var index = elements[0].index;
                        var itemCode = arr[index].code;

                        if (!itemCode) return;

                        RW_Navigation.navigate('items');

                        setTimeout(function() {
                            RW_Items.openItemPage(itemCode);
                        }, 500);
                    }
                }
            }
        });
    }
```

### سبب هذا الاستبدال
لا يغير Contract البيانات أو المحاسبة أو المخزون.
هو فقط ينقل `itemCode` الذي تم بناؤه بالفعل في الرسم إلى `RW_Items.openItemPage(itemCode)`، وبالتالي يحقق فعليًا معنى "اضغط للتفاصيل" باستخدام الوظيفة الموجودة أصلًا.

---

## 8. عناصر لم يتم تعديلها عمدًا

### لا تغيير في Dashboard Profit
لا يوجد سبب لإعادة لمس `get_profit_loss` بعد إثبات Production contract الحالي.

### لا تغيير في Movement Report
الأنواع الحالية متطابقة مع Contract الحركة المخزنية في Production.

### لا تغيير في Bulk Upload
وجود Operation ID/Fingerprint وإعادة تحميل البيانات بعد النجاح مثبت في المصدر الحالي.

### لا تغيير في Matrix Branch Filter
الفلتر الحالي يعرض الأصناف التي لها رصيد موجب عند اختيار فرع. هذا قد يكون قابلًا لتطوير تدقيقي لاحقًا لإظهار الصفر/العجز، لكن لا توجد هنا قرائن تاريخية كافية تسمح بتحويل semantics الفلتر الآن دون اختراع Business Contract جديد.

### لا تغيير في Item Opening Balance
المسار الحالي يمر عبر `create_item_with_opening_stock` ثم `post_stock_movement`.

---

## 9. Syntax / Runtime Gate

يوجد في GitHub workflow:

`.github/workflows/validate-main2-fragments.yml`

وهو مصمم لتشغيل `node --check` على:

`Current/PWA/main2/main1.md` إلى `main11.md`

لكن لم يثبت وجود Workflow Run مرتبط بالـMain2 commit الحالي؛ لذلك:

- Full Main2 parser PASS = `NOT PROVEN`
- Browser Runtime = `NOT PROVEN`
- Assembly Runtime = `NOT PROVEN`
- Production UI Smoke = `NOT PROVEN`

لم يتم تحويل غياب خطأ مثبت إلى ادعاء PASS.

---

## 10. Gold / Diamond Functional Gate

Main2 الحالي يحتوي وظائف حقيقية وليس مجرد HTML هيكلي في:

- Dashboard KPIs
- Dashboard date filtering
- P&L RPC integration
- Sales/region/top-items/top-customers charts
- Items list/search/filter/sort
- Category management
- Item create/edit/delete
- Image upload
- Branch stock matrix
- Central movement report
- Bulk stock adjustment
- Excel export

لكن `Gold/Diamond = NOT CLOSED` لأن:

1. MAIN2-D1 ما زال يحتاج Owner Source Surgery.
2. Full-file parser PASS غير مثبت.
3. Browser/PWA runtime غير مثبت.
4. Assembly النهائي لم يبدأ.
5. Functional closure للـ11 fragments لم يكتمل.

---

## 11. Final Status

`MAIN2 SOURCE = CURRENT AND RECONCILED`

`REPORT118 = STALE`

`REPORT119 = HISTORICAL / RECONCILED`

`PRODUCTION SUPPORT REPAIRS = DEPLOYED`

`MAIN2-D1 = OPEN — OWNER ACTION`

`MAIN2 SOURCE MODIFICATION BY ASSISTANT = 0`

`MAIN2 FULL SYNTAX = NOT PROVEN`

`MAIN2 BROWSER RUNTIME = NOT PROVEN`

`ASSEMBLY = DEFERRED`

`MAIN2 GOLD/DIAMOND = OPEN`

---

## 12. Final Self-Audit

### ما تم إثباته

- Main2 الحالي تم مطابقة SHA الخاص به مباشرة مع Git.
- آخر Main2 source change محدد ومعلوم.
- إصلاحات Report118/R119 القديمة مثبتة في المصدر الحالي وعدم تكرارها مقصود.
- Production الحالية تمت قراءتها Fresh.
- `post_stock_movement` هو Physical Movement engine الحالي.
- `create_item_with_opening_stock` لا يتجاوز المحرك المركزي.
- `save-item` تم تأمينه company/permission scoped في Production.
- `delete-item` تم تأمينه company/permission scoped في Production.
- `save-category` تم تأمينه company scoped في Production.
- `bulk-stock-adjustment` كان بالفعل مصححًا في Production ولم تتم إعادة ترقيعه.
- تم إثبات عيب واحد حاليًا في Main2 دون افتراض: Top Items details navigation.

### ما لم يتم إثباته

- Full Main2 parser execution PASS.
- Browser/PWA runtime PASS.
- Assembly PASS.
- Full Parent Main1–Main11 functional closure.
- Gold/Diamond final closure.

### ما تم منعه

- لم يتم تعديل Main2 بواسطة المساعد.
- لم يتم إعادة تطبيق إصلاحات تاريخية قديمة.
- لم يتم تعديل Original.
- لم يتم لمس New-main.
- لم يتم الإعلان عن نسبة أو Closure بدون Production synchronization.

---

## 13. نقطة الاستئناف الدقيقة

بعد Owner Source Surgery في Main2-D1:

1. إعادة فتح `Current/PWA/main2/main2.md` كاملًا من البداية إلى EOF.
2. تنفيذ Syntax Gate على Main2.
3. إعادة مطابقة Main2 الحالي مع Production والـGit.
4. عدم الانتقال إلى Assembly قبل إغلاق أي defect مثبت.
5. بعد إغلاق Main2 ينتقل الدور إلى Main3 بنفس المنهجية.

لا توجد جراحة أخرى مؤكدة على Main2 حاليًا سوى MAIN2-D1.
