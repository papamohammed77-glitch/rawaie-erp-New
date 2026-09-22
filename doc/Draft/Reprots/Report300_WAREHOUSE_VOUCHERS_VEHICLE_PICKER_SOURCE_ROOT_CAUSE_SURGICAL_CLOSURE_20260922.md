# تقرير 300 — التحقيق الجنائي النهائي لسبب عدم ظهور المركبة في إذن مخزني جديد
## التاريخ
2026-09-22

## 1. نطاق المهمة والقيود

Closure Unit:
Warehouse Management → Stock Vouchers → New Voucher → DirectSale → Vehicle Picker

الملفات المرجعية:
- النظام الأم: `Current/PWA/main.html`
- التطبيق المستقل: `companies/company-1/warehouse/vouchers.html`
- تطبيق البيع المباشر: `companies/company-1/sales/van-sales.html`

القيود:
- لم يتم تعديل `main.html`.
- لم يتم تعديل `erp-frontend/.../warehouse/vouchers.html`.
- لم يتم تعديل `van-sales.html`.
- لم يتم إنشاء Edge Function جديدة.
- أي بنية Production غير لازمة لم تُنشأ.
- لا إعادة فتح للإصلاحات المغلقة سابقًا.
- بيانات QA التي أنشئت في Production تُترك ولا تُحذف.

---

## 2. هرم الحقيقة المستخدم

الحالة الحالية اعتمدت على:

CURRENT PRODUCTION
+
CURRENT DATABASE / RLS / RPC
+
CURRENT DEPLOYMENT EVIDENCE
+
CURRENT GIT / PARENT
+
CURRENT SOURCE

التقارير التاريخية استُخدمت لإعادة بناء السبب والسياق فقط، ولم تُعامل كحالة حالية مستقلة.

تمت قراءة `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` حتى النهاية؛ 2606 سطرًا.
وتمت مراجعة أحدث سلسلة تقارير الأذونات المخزنية: Reports 295–299، ثم إعادة فحص المصدر وProduction مباشرة.

---

## 3. CURRENT GIT

### System Repository
Repository:
`papamohammed77-glitch/rawaie-erp-New`

آخر Commit مثبت قبل كتابة هذا التقرير:
`e882f7c1808d6d4b0c43f6b1c55608f977198670`

Message:
`docs: update CURRENT_STATE with Report299 voucher vehicle closure`

هذا الـcommit وثائقي.

### Frontend Repository
Repository:
`papamohammed77-glitch/erp-frontend`

Current HEAD:
`745a615ccd0baff09ad2619b0316e46507a862e9`

Parent:
`29cd6e08056b50545db05a4bff220424127126c5`

Target file:
`companies/company-1/warehouse/vouchers.html`

Current blob:
`d02d3696d9ca1af8014fbb61c680c04c09c39b7e`

آخر تغييرات Frontend ذات الصلة:
- `29cd6e...`: نقل Catalog Search/Categories من داخل `wsTopPanel`.
- `745a615...`: إخراج `s.routeHtml()` من `wsTopPanel` وإبقاؤه في Workspace Header.

هذه التغييرات السابقة مغلقة ولا تُعاد.

---

## 4. CURRENT SOURCE — ما هو موجود فعلًا

### 4.1 loadRefs — السطر 28
المركبات تُقرأ مباشرة من جدول Production:

`vehicles`

والـquery الحالي:
- `company_id = s.company`
- `status = 'Active'`

والحقول:
- id
- vehicle_code
- license_plate
- model
- driver_id
- status
- mobile_branch_id
- mobile_stock_enabled

إذن لا يوجد Text Mock ولا List ثابتة ولا قراءة من Branches بدل Vehicles.

### 4.2 vehicleBranch — السطر 820
الربط الحالي:
1. `mobile_branch_id`
2. fallback موثق إلى `VAN-vehicle_code`

ويشترط:
- نفس الشركة.
- الفرع Active.
- mobile stock غير معطل.

### 4.3 pickSearch — السطر 991
نوع الحقل DirectSale → Vehicle.
البحث يطابق:
- vehicle_code
- license_plate
- model

### 4.4 pickSelect — السطر 992
عند اختيار المركبة:
- تحفظ UUID الحقيقي في `wsTo`.
- تعرض vehicle_code/license_plate/model.
- تستخرج الـrep من `vehicle.driver_id`.
- تتحقق من فرع المصدر والـrep.

### 4.5 renderWorkspace — السطر 1150
الـroute موجود حاليًا خارج:
`wsTopPanel`

أي أن إصلاح clipping السابق موجود بالفعل.

---

# 5. CURRENT PRODUCTION

Fresh snapshot أثناء هذه الجلسة:

- companies = 1
- branches = 3
- items = 17
- vehicles = 1
- active vehicles = 1
- stock_vouchers = 2
- stock_voucher_details = 4
- stock_voucher_operations = 2
- inventory_log = 6
- audit_log = 2035

## المركبة الفعلية

- vehicle_id:
  `5fe9d0b6-fc54-4cc6-9bff-ede0e8557dd8`
- vehicle_code:
  `VEH-TEST-260921`
- license_plate:
  `س ن ر 6021`
- model:
  `Suzuki Carry 2024`
- company:
  `00000000-0000-0000-0000-000000000001`
- status:
  `Active`
- driver_id:
  `111b0730-a977-4d11-bcd0-2427b178a9e5`
- mobile_stock_enabled:
  `true`
- mobile_branch_id:
  `5372503d-f638-4e7f-808d-bda585825b2f`
- mobile branch:
  `VAN-VEH-TEST-260921`
- mobile branch Active:
  `true`

## مندوب البيع المباشر الفعلي

- id:
  `111b0730-a977-4d11-bcd0-2427b178a9e5`
- email:
  `vansales@rawaea.com`
- role:
  `مندوب بيع مباشر`
- status:
  `Active`
- company:
  `00000000-0000-0000-0000-000000000001`
- allowed_branch_ids:
  `BR-01`
- permissions:
  [`van-sales`]

## مستخدم الأذونات

- email:
  `vouchers@rawaea.com`
- role:
  `مخزني`
- status:
  `Active`
- company:
  `00000000-0000-0000-0000-000000000001`
- allowed_branch_ids:
  `BR-01`
- permissions:
  [`warehouse`]
- default_branch_id:
  `NULL`

---

# 6. الإثبات الرقمي للسبب

تم تنفيذ نفس predicate الذي تعتمد عليه `pickArr('wsTo')` على بيانات Production الحالية.

النتائج:

- عدد Active Vehicles للشركة = `1`
- عدد المركبات الصالحة فعليًا لـDirectSale مع شروط Mobile Stock + Rep + Branch = `1`
- عدد مرشحي Vehicle Picker عندما تكون `wsFrom` فارغة = `0`
- عدد مرشحي Vehicle Picker عندما تكون `wsFrom = BR-01` = `1`

وهذه ليست نتيجة تقرير تاريخي؛ بل نتيجة Query مباشر على Production الحالية.

---

# 7. ROOT CAUSE — السبب الجذري الحقيقي

## العنصر المسؤول

الدالة:

`newWorkspace:function()`

الموضع الحالي:
السطر `795`

الدالة الحالية تجهز الحالة ثم تنفذ:

`prepare()`
→
`renderWorkspace()`

لكنها لا تضع قيمة ابتدائية لـ:

`wsFrom`

## النتيجة

عند فتح:

New Voucher → DirectSale

يبقى:

`wsFrom = ''`

وعند فتح حقل المركبة:

`pickArr('wsTo')`

يبحث عن:

`b = branch(wsFrom)`

وبما أن:

`wsFrom = ''`

فتكون:

`b = null`

ثم شرط Vehicle Picker الحالي يحتوي:

`!!b`

فيستبعد كل المركبات.

إذن:

**Vehicle Query = صحيح**

**Vehicle Table = صحيح**

**RLS = صحيح**

**Vehicle ↔ Rep = صحيح**

**Vehicle ↔ Mobile Branch = صحيح**

**Vehicle Picker predicate = صحيح لكنه يعتمد على Source Branch**

**المشكلة هي أن Workspace لا يبدأ بسياق Source Branch صالح.**

---

# 8. لماذا ظهرت المشكلة للمستخدم الحالي بالذات؟

Production تثبت:

- `vouchers@rawaea.com` مسموح له بفرع واحد فقط: `BR-01`
- `default_branch_id = NULL`

إذن هناك Branch Context واحد صالح للمستخدم، لكن التطبيق لا يستفيد منه عند فتح DirectSale.

هذا يجعل:

`Source Branch = empty`

ثم:

`Vehicle Candidates = 0`

رغم أن:

`Production Vehicle Candidates = 1`

---

# 9. لماذا لا نغير pickArr أو Vehicle Query؟

لأنهما يطبقان Contract صحيحًا:

Vehicle must be valid for:
- same company
- active vehicle
- mobile stock enabled
- valid mobile branch
- valid direct-sales rep
- user-allowed source branch
- rep allowed on source branch
- optional selected rep match

فتح مركبات عشوائية قبل تحديد السياق كان سيضعف:
- Branch isolation
- Rep binding
- Vehicle custody
- operational clarity

لذلك الإصلاح الصحيح هو **إكمال Source Context**، وليس إزالة القيود.

---

# 10. SURGICAL FIX — الملف المطلوب تعديله

## الملف

`papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/vouchers.html`

## لا تعدل من التالي

لا تلمس:
- `loadRefs`
- `vehicleBranch`
- `pickArr`
- `pickSearch`
- `pickSelect`
- `routeHtml`
- `submit`
- `main.html`
- `van-sales.html`

## العنصر المطلوب حذفه بالكامل

ابحث داخل الدالة:

`newWorkspace:function()`

عن الدالة الحالية الكاملة:

```javascript
newWorkspace:function(){
    var s=this;
    this.topPanelCollapsed=false;
    this.cart=[];
    this.cat='الكل';
    this.createOpId=null;
    this.createFingerprint=null;
    try{
        if(s.company&&s.type){
            
        }
    }catch(e){}
    RW_UI.showLoader('جاري تجهيز مساحة العمل...');
    Promise.resolve()
        .then(function(){return s.prepare()})
        .then(function(){
            s.renderWorkspace();
            RW_UI.hideLoader();
        })
        .catch(function(e){
            RW_UI.hideLoader();
            RW_UI.showError(e.message||'تعذر تجهيز الكتالوج');
        });
},
```

## استبدلها بالكامل بهذه الدالة

```javascript
newWorkspace:function(){
    var s=this;

    this.topPanelCollapsed=false;
    this.cart=[];
    this.cat='الكل';
    this.createOpId=null;
    this.createFingerprint=null;

    RW_UI.showLoader('جاري تجهيز مساحة العمل...');

    Promise.resolve()
        .then(function(){
            return s.prepare();
        })
        .then(function(){

            s.renderWorkspace();

            /*
             * DirectSale requires a source branch before the
             * vehicle picker can safely resolve its candidates.
             *
             * Use the user's explicit default branch when it is
             * valid and authorized. When no default branch exists
             * and the user has exactly one authorized active branch,
             * use that branch as the deterministic source context.
             *
             * Do NOT auto-select when multiple authorized branches
             * exist. In that case the operator must select explicitly.
             */
            if(s.type==='DirectSale'){

                var allowedBranches=
                    (s.refs.branches||[])
                    .filter(function(branch){
                        return s.allowedBranch(
                            s.user,
                            branch
                        );
                    });

                var selectedBranch=null;

                var defaultBranchId=
                    s.user &&
                    s.user.default_branch_id
                        ?String(s.user.default_branch_id)
                        :'';

                if(defaultBranchId){

                    selectedBranch=
                        allowedBranches.find(function(branch){
                            return String(branch.id)===defaultBranchId;
                        })||null;
                }

                if(
                    !selectedBranch &&
                    allowedBranches.length===1
                ){
                    selectedBranch=
                        allowedBranches[0];
                }

                if(selectedBranch){

                    var from=
                        RW_UI.byId('wsFrom');

                    var fromSearch=
                        RW_UI.byId('wsFromSearch');

                    if(from){
                        from.value=
                            selectedBranch.id;
                    }

                    if(fromSearch){
                        fromSearch.value=
                            selectedBranch.name||
                            selectedBranch.branch_code||
                            '';
                    }
                }
            }

            /*
             * Recalculate the workspace after Source Branch
             * initialization so product availability and
             * Vehicle candidates use the same current context.
             */
            s.updateSource();

            RW_UI.hideLoader();
        })
        .catch(function(e){

            RW_UI.hideLoader();

            RW_UI.showError(
                e.message||
                'تعذر تجهيز الكتالوج'
            );
        });
},
```

---

# 11. وظيفة الإصلاح بدقة

الإصلاح لا يغير Vehicle Contract.

بل يجعل الـWorkspace يبدأ هكذا في الحالة المثبتة:

`vouchers@rawaea.com`

↓ authorized branches

`BR-01`

↓

`wsFrom = BR-01`

↓

`pickArr('wsTo')`

↓

`vehicle candidates = 1`

↓

`VEH-TEST-260921`

↓

`vehicle.driver_id = vansales@rawaea.com`

↓

`vehicle.mobile_branch_id = VAN-VEH-TEST-260921`

هذا هو المسار الذي كان ينقص فقط.

---

# 12. السلامة عند تعدد الفروع

الدالة الجديدة لا تختار فرعًا من نفسها إذا كانت للمستخدم عدة فروع صالحة.

الحالات:

### Default Branch صالح
يتم استخدامه.

### لا يوجد Default Branch + فرع صالح واحد
يتم استخدام الفرع الوحيد.

### لا يوجد Default Branch + أكثر من فرع
لا يتم auto-selection.

### Default Branch غير صالح
لا يتم استخدامه.

وبالتالي:
لا Bypass للصلاحيات.
لا cross-branch inference.
لا تغيير في Authorization Contract.

---

# 13. Production / Database decision

## لا يوجد Production Schema defect مثبت

لذلك:

**لا Migration جديدة.**

## لا يوجد Vehicle RPC defect مثبت

لذلك:

**لا RPC جديدة.**

## لا يوجد Edge Function مطلوبة

لذلك:

**لا Edge Function جديدة.**

## لا يوجد تعديل لازم على RLS

لأن:

`vehicles_select_company`

يعمل بالسياق الصحيح.

والـDirect Rep Visibility policy الحالية تفتح فقط:
- company match
- Active
- role = مندوب بيع مباشر
- permission = van-sales
- caller = warehouse-capable

---

# 14. QA DATA — تم إنشاؤها وتركها

حسب طلب المهمة، تم إنشاء سجل QA دائم في Production وعدم حذفه:

### Voucher
`IN-2`

### Reference
`QA-VEHICLE-PICKER-20260922`

### Type
`DirectSale`

### Status
`Draft`

### Source
`BR-01`

### Destination
`VEH-TEST-260921`

### Rep
`vansales@rawaea.com`

### Item
`1001 — جو كيك 5ج`

### Qty
`1`

### operation_id
`QA-VOUCHER-VEHICLE-PICKER-20260922`

### QA أثر الحركة

`inventory_log` لهذا الإذن:
`0`

لأن Draft لا ينفذ Physical Movement.

### Registry
Operation Registry row:
`1`

### Audit
Audit row:
`1`

إذن سجل QA:
- يثبت الربط بين Branch + Vehicle + Rep + Item.
- لا يغير Physical Stock.
- لا يجب حذفه.

---

# 15. Production CREATE proof

تم استدعاء الـ12-argument Production RPC الحقيقي:

`create_manual_stock_voucher_atomic`

بالتالي:
- company صحيح.
- actor صحيح.
- rep صحيح.
- branch صحيح.
- vehicle صحيح.
- item صحيح.
- operation_id محفوظ.

النتيجة:

`success = true`

وتم إنشاء:
`IN-2`

وهذا يثبت أن الـBackend يستقبل نفس هوية المركبة التي يعتمدها Frontend.

---

# 16. Source-Level E2E للـPatch

تم تنفيذ اختبار JavaScript معزول للدالة البديلة.

المعطيات:
- type = DirectSale
- default_branch_id = null
- allowed_branch_ids = BR-01
- authorized branches = 1

النتيجة:
- `wsFrom = B1`
- `wsFromSearch = الفرع الرئيسي`
- `updateSource = called`

النتيجة:
**PASS**

مع Production data الحالية:
`B1 = BR-01`

إذن الـpatched flow يؤدي مباشرة إلى predicate الذي أثبتنا أنه يعيد مركبة واحدة.

---

# 17. Browser E2E الحقيقي

لم يتم تسجيل Browser E2E على الـpublished artifact كـPASS لأن:

- ملف `vouchers.html` owner-managed ولم يُعدل في المستودع هنا.
- لا يجوز إعلان deployment جديد للمصدر قبل تطبيق patch من المالك.
- current published artifact identity لم تُثبت مساواتها للـpatched source.

الحالة الصحيحة:

**SOURCE PATCH = READY**

**PRODUCTION DATA/BACKEND = VERIFIED**

**PUBLISHED BROWSER E2E = OPEN**

ولا يتم تحويلها إلى CLOSED قبل النشر ثم اختبار المتصفح الحقيقي.

---

# 18. التكامل مع النظام الأم

`main.html` يثبت رسميًا:
- stock_vouchers = delegated capability
- inventory = read-only view
- vouchers = `./vouchers.html`
- navigation تحت `المخازن والمخزون`

الدور الصحيح:

Mother System
→ Control / Navigation / Monitoring

Voucher App
→ Operational Voucher Execution

Production Core
→ Transaction Truth / Physical Stock

لذلك لا يلزم إدخال Vehicle picker logic داخل النظام الأم.

---

# 19. التكامل مع Van Sales

المصدر الحالي لـVan Sales:
`companies/company-1/sales/van-sales.html`

يثبت:
- `vehicle_id`
- `vehicle_code`
- `driver_id`
- `vanBranchId`
- source = `van-sales`
- البيع يستخدم `save-sales-invoice`

التدفق:

DirectSale Voucher
→ Branch Stock ↓
→ Vehicle Mobile Stock ↑
→ Van Sales
→ Customer Sale
→ Vehicle Mobile Stock ↓

DirectSale ليس Customer Sale.

DirectReturn ليس Customer Return.

هذا الفصل محفوظ.

---

# 20. المقارنة التنافسية — ما الذي يهم هذه الشاشة

## Odoo

Odoo يربط العمليات المخزنية بالـlocations والمنتجات والكميات، ويدعم Barcode Inventory Adjustments، وإسناد مهام الجرد لمستخدم، وإدخال الكمية يدويًا مع +1/-1. كما يمنع ظهور المنتجات في بعض سيناريوهات العد إذا لم يوجد تكليف/سياق موقع. هذا يدعم مبدأ RAWAEA الحالي: **السياق التشغيلي يجب أن يسبق اختيار العنصر المخزني**.

مصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

## Dynamics 365

Inventory Journals تفصل:
- Movement
- Inventory adjustment
- Transfer
- Counting
- Item arrival

والـTransfer يحتاج From/To inventory dimensions.

مصدر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

## SAP

Goods Movement يغطي:
- Goods Issue
- Goods Receipt
- Stock Transfer
- Transfer Posting

مع مستند للحركة.

مصدر:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/9d078d90fbbb4a298fbfc0a35047ec23/37a3bf4dc6d946afb42cd90f76843eca.html

## Daftra

Transfer form يقدم:
- Date
- From Warehouse
- To Warehouse
- Notes
- Item
- Quantity
- Available Before
- Available After

كما يقدم تقارير تفصيلية للحركات حسب المنتج والمخزن والنوع مع التصدير.

مصادر:
https://docs.daftra.com/en/tutorial/transferring-stock/
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

## Manager

Inventory Transfers تفصل:
- Date
- Reference
- Description
- Item
- Qty
- From
- To

وتعدّل كميات المواقع تلقائيًا.

مصدر:
https://www2.manager.io/guides/10707

---

# 21. تقييم RAWAEA أمام هذه الأنماط

المساحة الحالية تغطي:
- Branch/Location context
- Vehicle/Mobile Stock context
- Representative binding
- Reference
- Notes
- Item Search
- Barcode
- Category
- Quantity
- Available Before
- Expected After
- Cart
- Audit
- Operation Identity
- Central Physical Movement

والنقاط التي تصلح كClosure Units مستقلة مستقبلًا:
- editable transaction date/time
- attachments/evidence
- approval workflow
- lot/serial/expiry
- richer discrepancy taxonomy
- assigned cycle-count sessions
- richer movement reports

هذه ليست أخطاء مثبتة في Closure الحالية، ولا يجوز حقنها هنا بدون Contract مستقل.

---

# 22. لماذا لم نضف Features تنافسية الآن؟

لأن هذا الـclosure محدد في:

**Vehicle Picker / New DirectSale Workspace**

إضافة Approval / Lot / Serial / Attachment / Count Sessions الآن ستخلق:
- Schema contracts
- lifecycle contracts
- reporting contracts
- accounting consequences

وذلك يخالف قاعدة:
**أغلق العيب المحدد أولًا، ولا تُنشئ دينًا جديدًا أثناء الإغلاق.**

---

# 23. FINAL SELF-AUDIT

## Confirmed Facts
- Current System HEAD verified.
- Current Frontend HEAD verified.
- Frontend parent verified.
- Current vouchers SHA verified.
- Current main.html verified.
- Current van-sales source verified.
- Production vehicle verified.
- Production mobile branch verified.
- Production Direct Rep verified.
- Production RLS verified.
- Vehicle picker candidate with BR-01 = 1.
- Vehicle picker candidate with empty wsFrom = 0.
- Persistent QA DirectSale voucher created.
- QA voucher has zero inventory_log movement.
- QA voucher has operation registry.
- QA voucher has audit record.
- Replacement newWorkspace tested in isolated JavaScript harness.

## Unknowns
- Published browser artifact after applying the owner patch.

## Conflicts
- Older Reports 295–299 describe the previous clipping defect as the vehicle display problem.
- Current source proves that clipping fix is already present.
- Current direct reproduction identifies a second, distinct source defect: missing source-branch initialization.

## Unverified
- Real browser E2E on the newly patched and deployed artifact.

## Not Changed
- main.html
- vouchers.html
- van-sales.html
- vehicles table
- branches table
- RLS
- Edge Functions
- physical stock engine

---

# 24. FINAL CLOSURE STATE

### CLOSED
- Vehicle database linkage
- Vehicle RLS visibility
- Vehicle ↔ Rep
- Vehicle ↔ Mobile Branch
- Vehicle search fields
- Vehicle picker contract
- Historical clipping defect
- Current-source clipping fix
- DirectSale Production RPC contract
- Persistent QA vehicle-linked voucher

### OPEN
- Owner application of the exact `newWorkspace` surgical patch
- Deployment of the patched frontend
- Authenticated browser E2E against the deployed artifact

---

# 25. FINAL ROOT CAUSE

## السبب النهائي

ليس:
- عدم وجود مركبة في قاعدة البيانات.
- عدم الربط بجدول vehicles.
- RLS.
- Edge Function.
- Vehicle Query.

السبب هو:

`newWorkspace()`

لا يهيئ `wsFrom` رغم أن المستخدم الحالي لديه **فرع صالح واحد فقط**.

ثم:

`pickArr('wsTo')`

يستبعد المركبات عندما:
`wsFrom = ''`

فتصبح:
`Vehicle Candidates = 0`

بينما Production الفعلية تثبت:
`Vehicle Candidates = 1`
عند:
`wsFrom = BR-01`

إذن الجراحة الصحيحة هي:

**تهيئة Source Branch آليًا من Default Branch الصالح، أو من الفرع الوحيد المسموح به، ثم إعادة حساب السياق.**

وليس إزالة قيود Vehicle Picker.

---

# 26. نقطة الاستكمال الدقيقة للمساعد التالي

1. Snapshot Production أولًا.
2. Verify System HEAD + parent.
3. Verify Frontend HEAD + parent + vouchers blob.
4. لا تعيد V-03/V-04 أو clipping patch.
5. طبّق فقط replacement الخاص بـ`newWorkspace` أعلاه في:
   `erp-frontend/companies/company-1/warehouse/vouchers.html`.
6. افتح DirectSale.
7. تأكد أن:
   - wsFrom = BR-01
   - Vehicle picker يعرض `VEH-TEST-260921`
   - Rep = `vansales@rawaea.com`
8. نفذ Browser E2E.
9. عند النجاح، تحقق من:
   - voucher
   - operation
   - audit
   - inventory_log
10. لا ترسل DirectSale للاختبار النهائي إلا ببيانات QA واضحة.
11. بعد النشر خذ Production snapshot جديد في نفس لحظة التقرير.
12. فقط بعد إثبات runtime الحقيقي، أغلق Browser E2E.

---

# نهاية تقرير 300
