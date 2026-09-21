# تقرير 291 — الإغلاق الجنائي الحالي لتطبيق الأذونات المخزنية / DirectSale
## 2026-09-21

> **نطاق التقرير**
> - إدارة المخازن والمخزون → الأذونات المخزنية.
> - `companies/company-1/warehouse/vouchers.html`
> - التكامل مع `companies/company-1/sales/van-sales.html`.
> - العلاقة مع النظام الأم `main.html`.
> - Production / Supabase / RPC / Edge Functions ذات الصلة.
>
> **قاعدة الحقيقة:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> التقارير السابقة استرشادية فقط، ولا تحل محل التحقيق الحالي.

---

## 1. الحالة المرجعية عند بدء الجلسة

### System Repository
- المستودع: `papamohammed77-glitch/rawaie-erp-New`
- أحدث HEAD الذي سبق هذا التقرير: `0620265ce4e2e7cd3cfb4a8a6789a986b8e7408a`
- parent: `9ec16aeaace0cfea046b5a2c01e41db064ec9a2b`
- الـparent التنفيذي السابق الذي يحتوي آخر التغييرات الوظيفية ذات العلاقة: `9ec16aeaace0cfea046b5a2c01e41db064ec9a2b`
- الـcommit `0620265...` توثيقي فقط؛ لم يغيّر كود المخزون أو التطبيق.

### Mother / Frontend Repository
- المستودع: `papamohammed77-glitch/erp-frontend`
- HEAD: `f59bce9bac6b4d76fda2b16e6889f5d8b1e2466d`
- parent: `bab20ca64b359045bbaae7a47b7eee6e4b538a1b`
- `vouchers.html` الحالي: blob `570a4a952b7645e5ef7674e80d5238b65f8cd9eb`
- آخر commitين على الملف كانا تغيير timestamp فقط؛ لا تغيير في جسم منطق التطبيق.

### Governance
تمت مراجعة:
- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS`
- `CURRENT_STATE.md`
- سلسلة التقارير 280–290 ذات العلاقة.
- التعريف التاريخي للأذونات المخزنية اليدوية.
- commits والـparents المرتبطة بنطاق الأذونات وDirectSale.

---

## 2. إعادة بناء دور التطبيق

### دور vouchers.html

التطبيق ليس محرك أوامر/رانشيتات.

هو **Execution Surface** لعمليات المخزون اليدوية غير المرتبطة مباشرة بـorder/runsheet، وأهمها:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- وأعمال Scrap / Adjustment عبر محرك التسوية الحالي.

### DirectSale

العقد الحالي المثبت:
`Branch → Vehicle`

المعنى التشغيلي:
- نقل عهدة بضاعة إلى مخزن السيارة قبل البيع.
- السيارة ليست alias للمندوب.
- `vehicle.driver_id` يربط السيارة بمندوب البيع المباشر.
- المخزون المتنقل يمثل حاوية مخزنية مستقلة.

### DirectReturn

العقد الحالي:
`Vehicle → Branch`

التنفيذ الحالي ثنائي المرحلة:
- SEND يزيل المخزون من مخزن السيارة.
- RECEIVE يضيفه إلى فرع الاستلام.
- لا يجوز تفسير SEND وحده كإضافة إلى الفرع.

### العلاقة مع Van Sales

Van Sales لا ينشئ محرك مخزون جديدًا.
هو يبيع من المخزن المتنقل المعتمد للسيارة، ثم يرسل البيع إلى `save-sales-invoice`، بينما Physical Stock يبقى تحت `post_stock_movement`.

المصدر الحالي يستخدم:
- `setup-van-branch`
- `vanBranchId`
- `vanBranch.branch_code`
- operation identity للمبيعات
- `save-sales-invoice`.

### العلاقة مع Mother

Mother هي طبقة التحكم/التوجيه والرقابة.
التطبيق المنفصل هو طبقة التنفيذ.
لا تم تغيير Mother في هذه الجولة.

---

## 3. Production forensic snapshot

لقطة Production النهائية في نفس لحظة التقرير:

- companies = 1
- branches = 3
- vehicles = 1
- stock_vouchers = 1
- stock_voucher_operations = 1
- inventory_log = 6
- audit_log = 2034
- direct sales reps = 1
- active mobile-stock vehicles = 1
- MAIN / item 1001 = 2

الهوية التشغيلية الحالية:
- warehouse operator: `vouchers@rawaea.com`
- active warehouse role: `أذونات`
- permission: `warehouse`
- direct sales rep: `vansales@rawaea.com`
- vehicle: `VEH-TEST-260921`
- mobile branch: `VAN-VEH-TEST-260921`
- mobile stock: `true`

---

## 4. Production Security — verified

السياسة الحالية على `public.users` تحتوي مسارًا مخصصًا:

`users_select_direct_reps_warehouse`

وتسمح فقط بـ:
- نفس الشركة.
- user Active.
- role = `مندوب بيع مباشر`.
- caller لديه permission `warehouse`.

اختبار فعلي داخل PostgreSQL تحت role `authenticated` وبـJWT subject للمستخدم المخزني أعاد:
- direct sales representatives visible = 1.

إذًا مشكلة RLS القديمة **مغلقة في Production**، ولا يوجد سبب لإعادة فتحها.

---

## 5. Production Writer / RPC integrity

المسار الحالي:

PHYSICAL STOCK
→ `post_stock_movement`
→ `stock_branches`
→ `inventory_log`

تطبيق الأذونات لا يملك Physical Writer مستقل.

المسار الحالي:
- `create-stock-voucher` Edge version 10 → RPC canonical create.
- `send-stock-voucher` Edge version 20 → `send_stock_voucher_atomic`.
- `receive-stock-voucher` Edge version 22 → `post_manual_stock_voucher_atomic`.
- `complete-stock-voucher` Edge version 4.
- `cancel-stock-voucher` Edge version 4.

لا تم إنشاء Edge Function جديدة في هذه الجولة.

---

## 6. السبب التاريخي الذي تسبب في مشكلة DirectSale

### Root Cause A — Production

كان caller:
`vouchers@rawaea.com`

يملك:
`warehouse`

ولا يملك:
`users`

والسياسة القديمة كانت تجعل استعلام المستخدمين الظاهر للـvoucher app تابعًا لـpermission `users`.

النتيجة التاريخية:
- direct reps query = 0
- vehicle candidates = 0

تم إغلاق هذا السبب سابقًا في Production بواسطة:
`allow_warehouse_direct_rep_lookup_for_vouchers`

ولا توجد ضرورة لإعادة هذا الإصلاح.

### Root Cause B — Current Source UX

في المصدر الحالي ثبت وجود V-03 وV-04 بالفعل.

الـcurrent `pickArr('wsTo')`:
- يعرض المركبة حتى قبل اختيار المندوب.
- يستخدم `mobile_branch_id`.
- يقيّد المركبة بالشركة.
- يقيّدها بمندوب صحيح.
- لا يعتمد على اختيار المندوب أولًا.

والـcurrent `pickSelect('wsTo', ...)`:
- يثبت vehicle id.
- يحل `vehicle.driver_id`.
- يضع المندوب داخل `wsRep`.
- يتيح vehicle-first selection.

إذن **V-03/V-04 لا يجب إعادة إصلاحهما**.

### Root Cause C — الخروج التلقائي من التسجيل

العنصر الحالي المعيب مثبت حرفيًا في:

**File**
`companies/company-1/warehouse/vouchers.html`

**Function**
`handleKeys:function(e)`

**Current line**
تقريبًا: **1643**

**Current behavior**
عند أي `Escape` داخل Workspace:
- إذا لم تكن نتيجة البحث النصي مفتوحة.
- وإذا لم يكن drawer مفتوحًا.
- يتم تنفيذ:
`this.back()`

وبالتالي يمكن لـEscape الصادر من عنصر إدخال أو قائمة ذكية أن يغلق Workspace بالكامل.

تم إثبات ذلك بمحاكاة المصدر الحالي:
- Escape على INPUT
- `back()` calls = 1.

هذا عيب حقيقي في المصدر الحالي وليس افتراضًا.

---

## 7. Save path — forensic result

مسار DirectSale الحالي في المصدر:
- validates source branch.
- validates representative.
- validates vehicle.
- validates `vehicle.driver_id === rep.id`.
- validates `vehicleBranch(v)`.
- creates operation identity.
- sends `rep_id` and `operation_id`.
- calls existing `create-stock-voucher`.

Production RPC canonical validates:
- company context.
- active actor.
- DirectSale Branch→Vehicle.
- representative role/company.
- vehicle/company/status/mobile stock.
- vehicle.driver_id = representative.
- source branch authorization.
- operation registry.

لذلك لم يثبت في التحقيق الحالي أي defect جديد في save engine نفسه.

السبب التاريخي الذي كان يجعل الحفظ يبدو متعطلًا عند غياب representative visibility كان RLS، وقد أُغلق في Production.

**لا توجد ضرورة لتغيير RPC أو Edge save path الآن.**

---

## 8. Current source static gate

تم تحليل script الكامل داخل `vouchers.html` بالـcurrent blob.

النتيجة:
- JavaScript parse = PASS.
- V-03 source checks = present.
- V-04 source checks = present.
- `rep_id` passed to create path = present.
- `operation_id` passed to create path = present.
- `mobile_branch_id` support = present.

تم تشغيل محاكاة source-level باستخدام هويات Production الحالية:

### DirectSale
- rep candidates = 1
- vehicle candidates without rep selection = 1
- vehicle code = `VEH-TEST-260921`

### Vehicle-first binding
- `vehicle.driver_id` resolved to current direct-sales rep.
- current handler then places that rep into `wsRep`.

إذًا dropdown/search chain الخاصة بالمندوب والمركبة موجودة وصحيحة في المصدر الحالي.

---

## 9. الإصلاح الجراحي المطلوب — OWNER ONLY

### الملف
`companies/company-1/warehouse/vouchers.html`

### لا تلمس
- `main.html`
- `loadRefs:function(){`
- `vehicleBranch:function(v){`
- `pickArr:function(key){`
- `pickSelect:function(key,id){`
- `pickSearch:function(key,q){`
- `routeHtml:function(){`
- `submit:function(){`
- `van-sales.html`

هذه العناصر مثبتة كـcurrent aligned أو closed.

### العنصر المعيب

ابحث **حرفيًا** عن:

`handleKeys:function(e){if(!this.mode)return;if(e.key==='F2'){e.preventDefault();this.focusSearch()}if(e.key==='Escape'){var p=RW_UI.byId('wsResults');if(p&&!p.classList.contains('hidden'))p.classList.add('hidden');else if(RW_UI.byId('drawer')&&RW_UI.byId('drawer').classList.contains('open'))this.closeDrawer();else this.back()}}`

**احذف هذا العنصر بالكامل.**

### استبدله بالكامل بهذا:

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

### أثر التعديل

- Escape داخل input لا يغلق Workspace.
- Escape مع smart menu مفتوحة يغلق القائمة فقط.
- Escape مع item-result popup مفتوحة يغلقها فقط.
- Escape مع mobile drawer مفتوح يغلق الـdrawer فقط.
- Escape خارج عناصر الإدخال يمكنه العودة من Workspace.
- لا تغيير في Business Contract.
- لا تغيير في Production movement.
- لا تغيير في DirectSale semantics.

---

## 10. Production action في هذه الجولة

**لم يتم تنفيذ DDL/DML جديد في Production.**

السبب مثبت:
- RLS fix المطلوب كان موجودًا وفعالًا.
- canonical create RPC موجود ويعمل.
- send/receive RPCs موجودة.
- physical movement centralization موجودة.
- لا يوجد Writer جديد.
- لا يوجد Production defect جديد يستدعي migration إضافية.

هذا ليس توقفًا عن التنفيذ؛ بل نتيجة التحقيق أن Production already satisfies the contract، بينما العيب الجديد الوحيد المثبت في هذه الجولة frontend-only.

---

## 11. Edge Function capacity / gateway constraint

تم فحص قائمة Edge Functions الحالية.

القاعدة المعتمدة:
- لا Function جديدة.
- لا duplicate endpoint.
- إعادة الاستخدام من خلال RPCs الحالية.
- Production backend في هذه الجولة لم يحتج Function جديدة أصلًا.

---

## 12. Van Sales integration

Current `van-sales.html`:
- يعتمد على `setup-van-branch`.
- يحدد مخزن السيارة canonical.
- يستخدم `vanBranchId`.
- يحتفظ بالـoperation identity للمبيعات.
- يرسل الفاتورة إلى `save-sales-invoice`.
- لا ينشئ مخزنًا أو Physical Stock Engine موازيًا.

تكامل DirectSale الصحيح:

Vouchers:
`Branch → Vehicle`

ثم Van Sales:
`Vehicle Stock → Customer Sale`

ثم Physical Stock:
`post_stock_movement`

وهذا يحافظ على فصل:
- نقل العهدة.
- البيع.
- التسوية.

---

## 13. Competitive capability review

تمت مراجعة المصادر الرسمية الحالية على مستوى capability وليس نسخ المنتج.

### Odoo 19
Odoo يدعم Barcode-based inventory adjustments وعمليات التحويل، مع مراجعة/تأكيد للعد الفعلي، ويعرض منطق المواقع والمنتجات والـbarcode ضمن العملية. 
مصادر:
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html

### Microsoft Dynamics 365
Dynamics يميز بين Movement وInventory adjustment وTransfer وItem arrival وCounting وTag counting، ويعتمد From/To inventory dimensions في عمليات التحويل. 
مصادر:
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

### SAP
نمط Goods Movement يميز بين issue/receipt/transfer posting، وهو متوافق مع الفصل التشغيلي الموجود في RAWAEA.

### Daftra
نمط تحويل المخزون وتقارير حركات المخزون يركز على المستودع المصدر/الوجهة والكمية والتاريخ والتاريخ التشغيلي للحركة.

### النتيجة الخاصة بـ RAWAEA

المسار الحالي أصبح قويًا في:
- source/target context.
- vehicle mobile stock.
- representative/vehicle binding.
- centralized movement engine.
- idempotent operation identity.
- auditability.
- available stock context.
- مستقلية تطبيقات التنفيذ.

الفجوات التنافسية التي ظهرت في المقارنة ولكنها **ليست Business Contracts مثبتة بعد**:
- lot/serial/expiry.
- richer attachments/evidence.
- richer approval workflow.
- print/export variants.
- dedicated in-transit transfer when the business model requires it.

لم يتم إدخال هذه العناصر في هذه الجولة حتى لا يتم اختراع عقد أعمال أو تغيير نظام ناضج دون إثبات.

---

## 14. E2E status

### Production
تم الاعتماد على E2E السابق المغلق في Report290 لأن:
- Production contract لم يتغير.
- current frontend body لم يتغير بعد Report290؛ commits الأخيرة غيّرت timestamp فقط.
- لا يوجد regression مثبت في Production.

### Source-level current simulation
PASS:
- rep lookup.
- vehicle lookup.
- vehicle-first rep binding.
- full JavaScript parse.

### Browser E2E
OPEN.

لم يتم الادعاء بوجود Browser PASS دون browser evidence حقيقي.

السبب:
لا تتوافر في هذه الجلسة قناة browser execution فعلية للنظام المنشور، ولذلك لا يجوز تحويل source simulation إلى browser closure.

---

## 15. Closure Matrix

| Item | Current Result | Closure |
|---|---|---|
| Production RLS direct reps | policy active + authenticated test returns 1 | CLOSED |
| DirectSale backend | canonical RPC path | CLOSED |
| DirectSale vehicle candidate provider | current source already correct | CLOSED |
| Vehicle-first rep binding | current source already correct | CLOSED |
| Smart search mechanism | present in current source | CLOSED |
| Physical stock centralization | post_stock_movement | CLOSED |
| Van Sales integration | current canonical mobile branch | CLOSED |
| Automatic Escape exit | current source defect found | OWNER PATCH |
| Save backend | no current backend defect proved | CLOSED |
| New Edge Function | not required | CLOSED |
| main.html | untouched | CLOSED |
| Browser E2E | not executable in this environment | OPEN |

---

## 16. Self Audit

### What I Proved
- latest System HEAD and parent.
- current Mother HEAD and parent.
- exact current vouchers blob.
- current Production direct-rep RLS policy.
- authenticated visibility of the direct-sales representative.
- actual Production vehicle/mobile branch identity.
- current source contains V-03/V-04.
- current source parses.
- current source produces a vehicle candidate before rep selection.
- current source binds vehicle.driver_id to representative.
- current save path sends rep_id + operation_id.
- no current Production Writer defect was found.
- no new Edge Function is required.
- Van Sales current source preserves the canonical vehicle/mobile-branch contract.

### What I Did Not Prove
- authenticated browser execution on the actually served/deployed frontend.

### What I Fixed in Production
- Nothing new; Production was already aligned for this scope.

### What I Fixed in Source
- No direct source commit was made because this file is owner-managed.
- One new surgical owner patch was identified for the exact current Escape defect.

### What I Initially Had To Distinguish
- The old DirectSale visibility defect was a Production/RLS problem and is already closed.
- The current automatic-exit defect is a separate frontend event-handling defect.
- Treating both as one bug would have caused an unnecessary backend rewrite.

### What Could Still Be Wrong
- The deployed frontend may still be serving a cached/older blob.
- Browser E2E may reveal an additional runtime-only issue after the owner patch.
- No such issue is asserted without evidence.

### Final status
- Production contract: CLOSED
- Physical stock core: CLOSED
- DirectSale integration: CLOSED
- Smart rep/vehicle lookup source: CLOSED
- Current automatic-exit defect: OWNER PATCH READY
- Browser E2E: OPEN
- Global Inventory Core: NOT REOPENED

---

## 17. Continuity instructions for next session

1. Snapshot Production first.
2. Verify System HEAD and parent.
3. Verify Frontend HEAD and `vouchers.html` blob.
4. Do not repeat V-03/V-04.
5. Do not repeat the DirectSale RLS migration.
6. Do not touch `main.html`.
7. Apply only the `handleKeys:function(e)` surgical replacement above.
8. Parse the complete file.
9. Execute authenticated Browser E2E:
   - login
   - New Voucher
   - DirectSale
   - BR-01
   - rep search
   - vehicle search
   - vehicle-first binding
   - add item
   - save
   - verify resulting Draft voucher
10. If browser reveals a new failure, open a new Closure Unit; do not reopen closed units.
11. Re-snapshot Production at the exact end of the test.
12. Update CURRENT_STATE only from that verified final snapshot.

# END OF REPORT 291
