# تقرير 292 — استكمال التحقيق الجراحي لتطبيق الأذونات المخزنية / DirectSale
## الحالة الحالية الفعلية — 2026-09-21

> هذا التقرير يخص Closure Unit واحدة: **Warehouse Vouchers → New Voucher → DirectSale**.
> لا يعيد فتح الإغلاقات السابقة، ولا يعيد تطبيق V-03/V-04، ولا يلمس `main.html` أو `vouchers.html` أو `van-sales.html`.

---

## 1. أمر التنفيذ

تم إيقاف أي مسار سابق والتركيز على:

- إدارة المخازن والمخزون.
- تطبيق الأذونات المخزنية:
  `companies/company-1/warehouse/vouchers.html`
- مسار:
  `New Voucher → DirectSale`
- التكامل مع:
  - الفرع المصدر.
  - مندوب البيع المباشر.
  - المركبة.
  - المخزن المتنقل للمركبة.
  - Van Sales.
  - محرك Physical Stock المركزي.
  - النظام الأم.

القيد التنفيذي:
- لا تعديل في `main.html`.
- لا تعديل مباشر في `vouchers.html` من طرف CTO.
- لا إنشاء Edge Function جديدة.
- Production/Supabase تُعدّل مباشرة فقط عند وجود عقد أو خلل مثبت.

---

## 2. هرم مصادر الحقيقة

تم اعتماد الترتيب:

CURRENT PRODUCTION
↓
CURRENT DATABASE / RLS / RPC
↓
CURRENT DEPLOYMENTS / RUNTIME
↓
CURRENT GIT
↓
CURRENT SOURCE
↓
HISTORICAL REPORTS / ARCHITECTURE

التقارير السابقة استُخدمت لفهم التاريخ فقط ولم تُعامل كحالة حالية.

---

# 3. CURRENT GIT

## 3.1 النظام الأم

Repository:

`papamohammed77-glitch/rawaie-erp-New`

قبل هذه الجولة:

- HEAD:
  `0620265ce4e2e7cd3cfb4a8a6789a986b8e7408a`
- parent:
  `9ec16aeaace0cfea046b5a2c01e41db064ec9a2b`

تم تسجيل Migration جديدة في Git لهذه الجولة:

`supabase/migrations/20260921200800_direct_sales_voucher_rep_permission_guard.sql`

Commit التسجيل:

`f9b2637697b03ded4b188c63803b86e05c6bb0a0`

هذه الـMigration لا تنشئ Writer مخزنيًا جديدًا ولا Edge Function جديدة.

## 3.2 Mother Frontend

Repository:

`papamohammed77-glitch/erp-frontend`

الحالة الحالية:

- HEAD:
  `f59bce9bac6b4d76fda2b16e6889f5d8b1e2466d`
- parent:
  `bab20ca64b359045bbaae7a47b7eee6e4b538a1b`

Target:

`companies/company-1/warehouse/vouchers.html`

Current blob:

`570a4a952b7645e5ef7674e80d5238b65f8cd9eb`

Van Sales:

`companies/company-1/sales/van-sales.html`

Current blob:

`8d61382a8e0025a0d079e71dd94f33d106d9088e`

---

# 4. CURRENT PRODUCTION SNAPSHOT

تمت مطابقة Production مباشرة قبل التنفيذ وبعده.

الحالة الحالية:

- companies = 1
- branches = 3
- vehicles = 1
- stock_vouchers = 1
- stock_voucher_operations = 1
- inventory_log = 6
- audit_log = 2034
- orders = 0
- runsheets = 0

Direct Sales Representative:

- email = `vansales@rawaea.com`
- role = `مندوب بيع مباشر`
- status = `Active`
- permissions = [`van-sales`]
- user id =
  `111b0730-a977-4d11-bcd0-2427b178a9e5`

Warehouse voucher operator:

- email = `vouchers@rawaea.com`
- role = `مخزني`
- active_warehouse_role = `أذونات`
- permissions = [`warehouse`]

Vehicle:

- vehicle_code = `VEH-TEST-260921`
- license_plate = `س ن ر 6021`
- status = `Active`
- driver_id =
  `111b0730-a977-4d11-bcd0-2427b178a9e5`
- mobile_branch_id =
  `5372503d-f638-4e7f-808d-bda585825b2f`
- mobile_stock_enabled = true

Main branch:

- BR-01
- id =
  `a38332b6-6cea-480a-ada1-6eb6ab0590db`

Item test identity:

- item_code = `1001`
- item_id =
  `7cf845d8-34b9-47d1-9b7f-d9f1f597dbf8`
- name = `جو كيك 5ج`

Main stock before test:

- item 1001 = 2

---

# 5. التاريخ المعماري الذي يحكم DirectSale

الملف التاريخي:

`rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`

يثبت أن الأذونات اليدوية ليست بديلًا للأوردر أو الرانشيت.

هي مخصصة للحركات المخزنية التي لا تبدأ من:

- Order
- Runsheet

ومنها:

- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

## DirectSale

التعريف التشغيلي:

`Branch`
→
`Vehicle / Mobile Stock`

والهدف هو إنشاء/تحميل عهدة المندوب قبل البيع.

بعد ذلك يعمل Van Sales من مخزن السيارة نفسه.

إذن الفصل بين:

- Vouchers App
- Van Sales App
- Mother

ليس انفصالًا وظيفيًا؛ بل فصل للتشغيل مع اشتراك في Database Core.

---

# 6. العلاقة مع النظام الأم

النظام الأم مسؤول عن:

- navigation
- permission/control
- supervision
- reporting
- إدارة التطبيقات المنفصلة

التطبيق المنفصل مسؤول عن التنفيذ التشغيلي المخصص للدور.

في هذه Closure:

**Mother Contract لم يحتج تعديلًا.**

لم يتم تغيير `main.html`.

---

# 7. العلاقة مع Van Sales

Van Sales يعتمد على نفس العقد:

`vehicle.driver_id`
→
مندوب البيع المباشر

و:

`vehicle.mobile_branch_id`
→
Mobile Stock Branch

وهو يحافظ على التشغيل الميداني المنفصل:

- البيع.
- الفواتير.
- العهدة.
- الجرد.
- قراءة مخزن السيارة.

لا يوجد دليل حالي يبرر تغيير هذا العقد.

لم يتم تعديل `van-sales.html`.

---

# 8. التحقيق الجنائي في البلاغ الحالي

البلاغ:

- DirectSale لا يستجيب.
- القائمة لا تظهر بصورة عملية.
- المركبة لا تظهر.
- التسجيل يخرج تلقائيًا.
- الحفظ يبدو غير مستجيب.

التحقيق فصل البلاغ إلى ثلاث طبقات مستقلة.

---

## 8.1 العيب الأول — Production RLS

الواجهة الحالية كانت تطلب Active Direct Sales Reps بشكل صحيح، ولكن سياسة `users` الأصلية لم تكن تفتحهم لمستخدم الأذونات.

المستخدم:

`vouchers@rawaea.com`

لا يملك:

`users`

ويملك:

`warehouse`

فكان Query المندوبين يعود فارغًا تحت سياق المستخدم.

ولأن قائمة المركبات في DirectSale تشترط مركبة مرتبطة بمندوب صالح:

`refs.reps = []`
↓
`vehicle candidates = 0`

إذن:

**العطل لم يكن Search Engine.**

كان:

**Authorization / Visibility Contract mismatch.**

هذا الإغلاق كان موجودًا قبل هذه الجولة، وتمت المحافظة عليه.

---

# 9. Production Hardening الجديد في هذه الجولة

تم تثبيت العقد نفسه server-side بصورة أقوى.

Migration:

`20260921200800_direct_sales_voucher_rep_permission_guard.sql`

## 9.1 RLS

تم تضييق:

`users_select_direct_reps_warehouse`

لتصبح القائمة متاحة فقط إذا كان:

- نفس الشركة.
- Active.
- role = `مندوب بيع مباشر`.
- caller لديه `warehouse`.
- المستخدم لديه `van-sales`.

وبالتالي:

Warehouse user
→
Active Direct Sales Reps
→
Only Van-Sales authorized reps

وليس:

Warehouse user
→
All company users.

## 9.2 Server-side guard

تم تحديث overload الحالي ذي 12 معاملًا:

`create_manual_stock_voucher_atomic(..., p_rep_id uuid, p_operation_id text)`

ليفرض عند:

- DirectSale
- DirectReturn

أن:

1. `p_rep_id` موجود.
2. المستخدم موجود في نفس الشركة.
3. المستخدم Active.
4. role = `مندوب بيع مباشر`.
5. permissions تحتوي `van-sales`.

بعد ذلك فقط يستمر المسار إلى:

`create_manual_stock_voucher_atomic_core_12_20260828`

أي أن الواجهة لا تملك صلاحية تجاوز العقد.

---

# 10. لماذا لم ننشئ Edge Function؟

لأن:

- `create-stock-voucher` موجود.
- `send-stock-voucher` موجود.
- RPC الحالي موجود.
- Physical stock engine موجود.
- الـFunction limit/spend constraint مثبت.
- الطلب يمكن إغلاقه بالكامل داخل PostgreSQL RPC.

إذن:

**NO NEW EDGE FUNCTION**

---

# 11. Production E2E بعد Hardening

تم تنفيذ:

`DirectSale`
→
`Branch BR-01`
→
`Vehicle VEH-TEST-260921`
→
`Rep vansales@rawaea.com`
→
`Item 1001`

داخل Transaction.

### النتيجة الإيجابية

الـRPC أعاد:

- success = true
- company_id صحيح
- rep_id صحيح
- voucher created
- operation_id صحيح

ثم أعيد نفس الطلب بنفس `operation_id`.

النتيجة:

- success = true
- duplicate = true
- نفس voucher id
- نفس operation id

ثم تم:

`ROLLBACK`

ولا بقي أي Test Voucher.

---

# 12. Production Negative Guard Test

تم اختبار السيناريو المعاكس داخل Transaction:

تمت إزالة `van-sales` مؤقتًا من صلاحيات المندوب داخل Transaction فقط.

ثم استدعاء نفس DirectSale RPC.

النتيجة المتوقعة تحققت:

`مندوب البيع المباشر غير صالح أو لا يملك صلاحية تطبيق البيع المباشر`

ثم:

`ROLLBACK`

وعادت صلاحية Production إلى:

`[\"van-sales\"]`

هذا يثبت أن:

- RLS ليس مجرد فلتر واجهة.
- RPC يمنع bypass.
- DirectSale identity أصبحت مرتبطة فعليًا بصلاحية تشغيل Van Sales.

---

# 13. العيب الثاني — Automatic Exit

هذا هو العيب الجديد المثبت في المصدر الحالي.

الملف:

`companies/company-1/warehouse/vouchers.html`

الدالة:

`handleKeys:function(e)`

السطر التقريبي:

**1643**

السلوك الحالي:

إذا كان:

- Workspace مفتوحًا.
- لا توجد نتائج بحث item popup.
- ولا mobile drawer.

فإن:

`Escape`
→
`this.back()`

تم اختبار ذلك source-level:

**Escape على INPUT**
→
`back() = 1`

إذن:

### السبب المباشر للخروج التلقائي من التسجيل

هو:

**Global Escape handler كان يتعامل مع INPUT على أنه أمر رجوع من Workspace.**

هذا ليس تخمينًا.

هو مثبت من المصدر الحالي.

---

# 14. العيب الثالث — Rep Search Order

الدالة الحالية:

`pickArr:function(key){`

تحتوي:

`if(key==='wsRep')`

والسلوك الحالي يتطلب وجود Branch محدد مسبقًا.

إذا لم يتم تحديد:

`wsFrom`

فإن:

`b = null`

وتصبح قائمة المندوبين:

`[]`

وهذا يجعل:

**Rep-first search غير ممكن.**

الطلب الحالي يستهدف تجربة أكثر إنتاجية:

- Branch-first
- Rep-first

مع بقاء القيود التنظيمية.

تم اختبار أن:

- Current source:
  rep-first candidate count = 0

والتعديل المقترح:

- rep-first candidate count = 1

باستخدام Production identities الحالية.

---

# 15. العيب الرابع — تغيير الفرع يمسح المندوب الصحيح

داخل:

`pickSelect:function(key,id)`

يوجد block خاص:

`if(key==='wsFrom'&&s.type==='DirectSale')`

وكان يقوم بمسح:

- `wsRep`
- `wsRepSearch`
- `wsTo`
- `wsToSearch`

حتى لو كان المندوب المختار صالحًا للفرع الجديد.

هذا يكسر workflow:

`Select Rep`
→
`Select Branch`

لأنه يحول اختيار المندوب إلى اختيار مؤقت غير قابل للحفظ.

المطلوب ليس منع المسح تمامًا.

المطلوب:

**Preserve Rep if still valid for selected branch; always invalidate Vehicle because vehicle is downstream of branch + rep.**

---

# 16. العيب الخامس — Browser Source Gate

أحدث Browser E2E:

Workflow:

`.github/workflows/warehouse_vouchers_browser_e2e_20260920.yml`

Run:

`35622535768`

HEAD:

`f59bce9bac6b4d76fda2b16e6889f5d8b1e2466d`

النتيجة:

**failure**

ولكنه لم يصل إلى Browser Smoke.

الـGate فشل قبل تشغيل المتصفح بسبب:

`CANONICAL_SW_PATH_MISSING`

الـworkflow ينتظر:

`RW_SW.register('../sw.js')`

لكن Current blob:

`570a4a...`

لا يحتويه.

---

# 17. السبب التاريخي لفجوة Service Worker

Commit سابق مثبت:

`8e30320dbec24a1ea962c9616cd1b07f6702d706`

message:

`Update event listeners and service worker registration`

كان يثبت:

`RW_SW.register('../sw.js')`

ثم جاء:

`76e5b12fb88f85f5df1ab4f758dbacb5f7af9ae1`

وخرج منه tail بدون هذا السطر.

الفحص المباشر لنسخة الملف على Commit `8e303...`:

**SW registration = present**

الفحص المباشر لنفس الملف على Commit `76e5...`:

**SW registration = absent**

إذن Regression معروف ومحدد المصدر.

---

# 18. قرار التعديل في vouchers.html

لم يتم تعديل الملف مباشرة.

السبب:

هذا الملف owner-managed في هذه Closure.

التعديل المطلوب تم تحويله إلى:

**OWNER SURGICAL PATCH**

وتم اختباره source-level قبل التسليم.

---

# 19. PATCH V-05 — Rep-first Smart Search

### الملف

`companies/company-1/warehouse/vouchers.html`

### الدالة

`pickArr:function(key){`

### العنصر المطلوب البحث عنه حرفيًا

`if(key==='wsRep'){

        return (s.refs.reps||[]).filter(function(r){

            return (
                !!b &&
                s.allowedBranch(s.user,b) &&
                s.allowedBranch(r,b)
            );
        });
    }`

### احذف هذا العنصر بالكامل.

### واستبدله بالكامل بـ:

```javascript
if(key==='wsRep'){

        var candidateBranches = b
            ? [b]
            : userBranches;

        return (s.refs.reps||[]).filter(function(r){

            return candidateBranches.some(function(branch){

                return (
                    !!branch &&
                    s.allowedBranch(r,branch)
                );
            });
        });
    }
```

### النتيجة

- Branch-first يظل مدعومًا.
- Rep-first أصبح مدعومًا.
- لا يتم عرض مندوب خارج فروع المستخدم.
- لا يتم كسر Rep branch scope.
- لا تعديل في backend contract.

---

# 20. PATCH V-06 — Preserve valid Rep after Branch selection

### الملف

`companies/company-1/warehouse/vouchers.html`

### الدالة

`pickSelect:function(key,id){`

### العنصر المطلوب البحث عنه حرفيًا

```javascript
if(key==='wsFrom'&&s.type==='DirectSale'){

        RW_UI.byId('wsRep').value='';
        RW_UI.byId('wsRepSearch').value='';
        RW_UI.byId('wsRepSearch').removeAttribute('readonly');

        RW_UI.byId('wsTo').value='';
        RW_UI.byId('wsToSearch').value='';
    }
```

### احذف هذا العنصر بالكامل.

### واستبدله بالكامل بـ:

```javascript
if(key==='wsFrom'&&s.type==='DirectSale'){

        var selectedRepId=
            (RW_UI.byId('wsRep')||{}).value||'';

        var selectedRep=
            (s.refs.reps||[]).find(function(rp){
                return rp.id===selectedRepId;
            });

        var keepRep=
            !!selectedRep &&
            s.allowedBranch(selectedRep,x);

        if(!keepRep){

            RW_UI.byId('wsRep').value='';
            RW_UI.byId('wsRepSearch').value='';
        }

        RW_UI.byId('wsRepSearch').removeAttribute('readonly');

        RW_UI.byId('wsTo').value='';
        RW_UI.byId('wsToSearch').value='';
    }
```

### النتيجة

- اختيار Branch لا يمسح Rep صالحًا.
- Vehicle يعاد ضبطه دائمًا.
- لا يحدث mismatch بين Branch وVehicle.
- يحافظ على DirectSale dependency order.

---

# 21. PATCH V-07 — منع الخروج التلقائي

### الملف

`companies/company-1/warehouse/vouchers.html`

### الدالة

`handleKeys:function(e)`

### العنصر الحالي الكامل

```javascript
handleKeys:function(e){if(!this.mode)return;if(e.key==='F2'){e.preventDefault();this.focusSearch()}if(e.key==='Escape'){var p=RW_UI.byId('wsResults');if(p&&!p.classList.contains('hidden'))p.classList.add('hidden');else if(RW_UI.byId('drawer')&&RW_UI.byId('drawer').classList.contains('open'))this.closeDrawer();else this.back()}}
```

### احذف هذا العنصر بالكامل.

### واستبدله بالكامل بـ:

```javascript
handleKeys:function(e){

    if(!this.mode){
        return;
    }

    var target=e&&e.target;

    var tag=
        target&&target.tagName
            ?String(target.tagName).toLowerCase()
            :'';

    var isFormField=
        tag==='input'||
        tag==='textarea'||
        tag==='select';

    if(
        e.key==='F2'&&
        !isFormField
    ){
        e.preventDefault();
        this.focusSearch();
        return;
    }

    if(e.key!=='Escape'){
        return;
    }

    var p=RW_UI.byId('wsResults');

    if(
        p&&
        !p.classList.contains('hidden')
    ){
        p.classList.add('hidden');
        e.preventDefault();
        return;
    }

    var smart=
        document.querySelector(
            '.smart-menu:not(.hidden)'
        );

    if(smart){
        smart.classList.add('hidden');
        e.preventDefault();
        return;
    }

    var drawer=RW_UI.byId('drawer');

    if(
        drawer&&
        drawer.classList.contains('open')
    ){
        this.closeDrawer();
        e.preventDefault();
        return;
    }

    if(isFormField){
        e.preventDefault();
        return;
    }

    this.back();
},
```

### النتيجة

- Escape داخل INPUT لا يغلق Workspace.
- Escape داخل textarea لا يغلق Workspace.
- Escape داخل select لا يغلق Workspace.
- Escape يغلق popup المفتوح قبل التنقل.
- Escape يغلق smart menu المفتوحة قبل التنقل.
- Escape يغلق drawer المفتوح قبل التنقل.
- Escape خارج الحقول يستطيع العودة.

---

# 22. PATCH V-08 — إصلاح Regression الـService Worker

### الملف

`companies/company-1/warehouse/vouchers.html`

### ابحث عن:

``document.addEventListener('DOMContentLoaded',function(){``

وقبلها مباشرة أضف:

```javascript
RW_SW.register('../sw.js');
```

### يجب أن يصبح ذيل الملف:

```javascript
RW_SW.register('../sw.js');document.addEventListener('DOMContentLoaded',function(){if(location.hash&&/type=recovery|access_token=.*type=recovery/i.test(location.hash)){App.showRecovery()}else App.init()});
```

ولا تضف:

`<script src="register-sw.js"></script>`

ولا تستخدم:

`RW_SW.register('sw.js')`

---

# 23. ما لم يتم تعديله عمدًا

لا تعدل:

- `loadRefs:function(){`
- `prepare:function(){`
- `pickSearch:function(key,q)`
- `routeHtml:function()`
- `submit:function()`
- `vehicleBranch:function(v)`
- `main.html`
- `van-sales.html`

ولا تعيد V-03/V-04.

ولا تضيف:

- Edge Function جديدة.
- Writer جديد.
- جدول بيانات موازي.
- Session cache موازي للمندوبين.

---

# 24. هل Save Engine نفسه معيب؟

التحقيق الحالي لم يثبت ذلك.

Current source:

`submit:function()`

يفعل:

- cart validation
- reference validation
- source validation
- target validation
- DirectSale rep validation
- vehicle validation
- vehicle/rep consistency
- branch authorization
- operation identity
- `rep_id`
- `operation_id`
- `create-stock-voucher`

Production E2E أثبت أن:

**Create DirectSale succeeds.**

وإعادة نفس العملية:

**duplicate = true**

إذن:

**لا إعادة كتابة لـ save engine.**

---

# 25. لماذا يبدو أن التسجيل يخرج بعد الحفظ؟

داخل `submit` يوجد عمدًا:

`s.back()`

بعد نجاح:

`j.success`

أي:

`SAVE SUCCESS`
→
toast
→
back to pending list

هذا ليس Bug حفظ مثبتًا.

إذا ثبت لاحقًا أن المطلوب UX مختلف ويجب البقاء في Workspace بعد الحفظ، فهذا Business UX change مستقل وليس إصلاحًا لهذا العطل.

لا يُفتح الآن.

---

# 26. اختبار التعديلات على المصدر قبل التسليم

تم تطبيق V-05 + V-06 + V-07 + V-08 على **نسخة تحليلية مؤقتة من Current Blob فقط** دون Commit ودون تعديل المستودع.

النتائج:

- replacements found = 3 exact source blocks
- JavaScript parse/compile = PASS
- `RW_SW.register('../sw.js')` = present after patch simulation
- Rep-first candidate using current Production identity = 1
- Old Rep-first candidate = 0
- Escape on INPUT:
  - before = back()
  - after = no back()
  - preventDefault = true

هذا يثبت سلامة التعديل الجراحي source-level.

---

# 27. Browser E2E

الحالة:

**OPEN**

وليس:

PASS

السبب ليس نقصًا في SQL/RPC.

السبب الحالي المباشر:

Browser workflow gate يتطلب `RW_SW.register('../sw.js')` بينما Current source لا يحتويه.

بعد تطبيق V-08 في المصدر المملوك وتشغيل CI يمكن تنفيذ:

1. Login.
2. New Voucher.
3. DirectSale.
4. اختيار BR-01.
5. Rep search.
6. Vehicle search.
7. Vehicle-first binding.
8. إضافة item.
9. Save.
10. Verify voucher state.
11. Verify audit/operation identity.
12. إعادة المحاولة بنفس operation_id.
13. Verify no duplicate stock movement.

لا يجوز تحويل source-level PASS إلى browser PASS.

---

# 28. Benchmark — الفائدة التنافسية التي يجب الحفاظ عليها

### Odoo 19

Odoo يربط عمليات الجرد بالـBarcode، ويتيح تعيين عدادات، وإظهار expected quantity حسب السيناريو، والتأكيد النهائي قبل تثبيت adjustment.

المبدأ المفيد لـRAWAEA:

**Operational UI صغيرة + source/location context + confirmation + scan/search.**

المصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

### Dynamics 365

Dynamics يفصل Inventory Journals إلى:

- Movement
- Adjustment
- Transfer
- Item arrival
- Counting

والـTransfer يعتمد From/To inventory dimensions.

المصدر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

### SAP

SAP يدعم one-step / two-step transfer posting ويُظهر أهمية الفصل بين issue/receipt عندما تكون دورة النقل مستقلة.

المصدر:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/9905622a5c1f49ba84e9076fc83a9c2c/c864bd534f22b44ce10000000a174cb4.html

### Manager.io

Manager يحافظ في Inventory Transfer على:

- Date
- Reference
- Description
- Item
- Qty
- From
- To

المصدر:
https://www2.manager.io/guides/10707

RAWAEA يملك هذه البنية أصلًا، ويضيف عليها:

- vehicle/mobile stock
- direct-rep custody
- field apps
- central movement engine
- audit
- operation identity

لذلك لم يتم توسيع النموذج بلا عقد.

---

# 29. Business Contract Closure

| العقد | الحقيقة الحالية | الحالة |
|---|---|---|
| Manual Voucher is non-order/non-runsheet | مثبت تاريخيًا وحاليًا | CLOSED |
| DirectSale Branch → Vehicle | مثبت Production | CLOSED |
| Vehicle → Direct Rep relation | مثبت | CLOSED |
| Mobile Branch identity | مثبت | CLOSED |
| Physical stock central writer | `post_stock_movement` | CLOSED |
| Direct rep visibility | RLS + server guard | CLOSED |
| Direct rep Van Sales permission | enforced | CLOSED |
| Duplicate create protection | operation registry | CLOSED |
| Current auto-exit on Escape | source defect | OWNER PATCH READY |
| Rep-first smart search | current gap | OWNER PATCH READY |
| Preserve valid rep on branch change | current gap | OWNER PATCH READY |
| SW registration regression | current source/CI gap | OWNER PATCH READY |
| Browser authenticated E2E | not executed | OPEN |

---

# 30. Production/Data Integrity

لم يتم إدخال أي Test voucher دائم في هذه الجولة.

لم يتم حذف أو تصحيح أي سجل تشغيلي لأنه لم يثبت وجود Data Corruption جديدة مرتبطة بهذه Closure.

كل اختبارات الحركة الجديدة كانت transactional وتم rollback لها.

الحالة الحالية:
- stock_vouchers = 1
- stock_voucher_operations = 1
- inventory_log = 6
- item 1001 in BR-01 = 2

ولا يوجد Test residue من هذه الجولة.

---

# 31. Self Audit

## What I Proved

- Current system HEAD/parent.
- Current frontend HEAD/parent.
- Current vouchers blob.
- Current Van Sales blob.
- Current Production identities.
- Current RLS behavior under authenticated role.
- Existing V-03/V-04 presence.
- Actual Escape auto-exit defect.
- Actual Rep-first limitation.
- Actual branch-selection reset.
- Actual Service Worker regression.
- Production DirectSale Create success.
- Duplicate idempotency.
- Server-side rep permission guard.
- No new Edge Function.
- No new physical stock writer.
- No persistent test residue.

## What I Did Not Prove

- Authenticated browser click-through after owner source patch.
- Actual production-serving URL cache state.
- Physical mobile-browser rendering.

## What I Changed in Production

- strengthened direct-rep RLS visibility.
- strengthened DirectSale/DirectReturn representative server guard.
- recorded migration source in canonical Git.

## What I Changed in vouchers.html

**Nothing directly.**

Only owner-ready surgical replacements were prepared and source-level tested.

## What I Did Not Change

- main.html
- van-sales.html
- V-03
- V-04
- save engine
- Edge count

---

# 32. Final Closure State

## PRODUCTION DIRECTSALE CONTRACT

**CLOSED**

## DIRECT REP AUTHORIZATION

**CLOSED**

## PHYSICAL STOCK CORE

**CLOSED**

## SMART REP/VEHICLE SOURCE BASE

**CLOSED**

## AUTOMATIC EXIT DEFECT

**OWNER PATCH READY**

## REP-FIRST SEARCH

**OWNER PATCH READY**

## BRANCH/REP CONTEXT RETENTION

**OWNER PATCH READY**

## SERVICE WORKER REGRESSION

**OWNER PATCH READY**

## AUTHENTICATED BROWSER E2E

**OPEN**

---

# 33. تعليمات الجلسة التالية

ابدأ من:

1. Snapshot Production.
2. Verify current policy and 12-arg DirectSale RPC.
3. Verify current frontend HEAD:
   `f59bce9...`
4. Verify vouchers blob:
   `570a4...`
5. Check whether V-05/V-06/V-07/V-08 were applied.
6. لا تعيد RLS migration.
7. لا تعيد V-03/V-04.
8. لا تلمس main.html.
9. Parse full vouchers file.
10. Run Browser E2E الحقيقي.
11. Verify Draft voucher creation.
12. Verify duplicate retry.
13. Verify no stock duplication.
14. Snapshot Production فور انتهاء الاختبار.
15. افتح Closure جديدة فقط إذا أثبت Browser E2E عيبًا جديدًا.

---

# 34. قاعدة التحقيق المستقبلي

لا تبدأ من عبارة:

`الواجهة لا تعمل`

ابدأ:

`ما الذي حدث فعليًا؟`

ثم:

CURRENT SOURCE
→ EVENT
→ STATE
→ AUTH
→ DATA
→ RPC
→ DB
→ DEPLOYMENT
→ RUNTIME

ولا تُحوّل:

- source PASS
إلى
- browser PASS

ولا تُحوّل:

- staging PASS
إلى
- production PASS

ولا تُعيد إصلاح:

- already closed contracts.

---

# END OF REPORT 292
