# تقرير 296 — إغلاق جنائي لمشكلة قائمة المركبة في الأذونات المخزنية

## 1. الحالة المرجعية الفعلية

### Current System Git
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- HEAD: `1b91cbd7782e7e14d01733e6d0d626932e078ece`
- Parent: `337b0ac827aa2c55784c09673fc7b776ccdf53d5`
- آخر commit: `state: record Report295 vouchers forensic closure`
- Parent commit أضاف تقرير Report295.
- لا يوجد دليل على commit أحدث من ذلك في System HEAD وقت هذه الجلسة.

### Current Frontend Git
- Repository: `papamohammed77-glitch/erp-frontend`
- HEAD: `29cd6e08056b50545db05a4bff220424127126c5`
- Parent: `0115399c79d5a9fc5ef9c92450cc42381d560f22`
- آخر commit: `Refactor HTML structure in vouchers.html`
- هذا الـcommit عدّل فقط `companies/company-1/warehouse/vouchers.html` ونقل Product Search إلى رأس الـCatalog.
- vouchers current blob: `a22b4014603f44c12820ec4a769e7e0138abd854`
- van-sales current blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`
- `main.html` لم يُلمس.
- `van-sales.html` لم يُلمس.

### Governance
تمت قراءة `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP` كاملًا؛ 2606 سطرًا.
تم الالتزام بقاعدة:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
التقارير التاريخية استُخدمت لإعادة بناء السياق فقط، لا كبديل عن Production الحالية.

---

## 2. Current Production Snapshot

Production project:
`fiilmooggumokxanwiyx`

النتيجة الحالية المثبتة:
- companies = 1
- branches = 3
- items = 17
- vehicles = 1
- stock_vouchers = 1
- stock_voucher_operations = 1
- inventory_log = 6
- audit_log = 2034
- orders = 0
- runsheets = 0

المركبة الحالية:
- vehicle_code = `VEH-TEST-260921`
- status = Active
- driver = `vansales@rawaea.com`
- mobile_stock_enabled = true
- mobile_branch_id = `5372503d-f638-4e7f-808d-bda585825b2f`
- mobile branch = `VAN-VEH-TEST-260921`
- mobile branch active = true

المستخدم المسؤول عن الأذونات:
- `vouchers@rawaea.com`
- role = `مخزني`
- status = Active
- allowed_branch_ids = `BR-01`

مندوب البيع المباشر المرتبط بالمركبة:
- `vansales@rawaea.com`
- role = `مندوب بيع مباشر`
- status = Active
- allowed_branch_ids = `BR-01`

### Production predicate verification

تمت مطابقة شروط DirectSale التي يستخدمها المصدر:
- Vehicle Active = true
- mobile_stock_enabled != false
- mobile branch موجودة
- mobile branch تابعة لنفس الشركة
- mobile branch Active
- driver موجود
- driver = `vansales@rawaea.com`

النتيجة:
`active_matching_directsale = 1`

إذن Production تحتوي بالفعل على مركبة صالحة واحدة يمكن أن تظهر في سياق DirectSale.

---

## 3. إعادة بناء دور تطبيق الأذونات

العقد المثبت تاريخيًا وحاليًا:

### Transfer
Branch → Branch

### DirectSale
Branch → Vehicle

والمعنى الصحيح هنا:
DirectSale داخل تطبيق الأذونات **ليس فاتورة بيع للعميل**.
هو نقل فعلي للبضاعة من مخزن الفرع إلى المخزن المتنقل المرتبط بالمركبة، تمهيدًا لقيام `van-sales.html` بالبيع المباشر.

### DirectReturn
Vehicle → Branch

إعادة البضاعة من المخزن المتنقل للمركبة إلى الفرع.

### SupplierReturn
Branch → Supplier

### Scrap / Adjustment
Adjustment Engine.

وهذا يحافظ على الفصل المعماري:
- النظام الأم = Control / Navigation / Monitoring Plane.
- تطبيق الأذونات = Operational Plane للحركات المخزنية غير المرتبطة بالأوردر/الرانشيت.
- التطبيقات الميدانية = Field Execution Plane.
- `post_stock_movement` = Physical Stock Engine المركزي.

---

## 4. التاريخ المعماري ولماذا وصل التصميم إلى هذه الصورة

الملف التاريخي:
`rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`

يثبت أن الأذونات نشأت كطبقة مستقلة للحركات المخزنية المباشرة، مع فصل واضح بين:
- document lifecycle
- stock movement
- field execution
- accounting
- control/read model.

هذا الفصل لم يكن نقصًا في التصميم.
بل كان مقصودًا لحماية دورة الميدان:
Branch → Vehicle → Van Sales
و:
Vehicle → Branch
و:
Branch → Branch

والحفاظ على التطبيقات التشغيلية المنفصلة ميزة أساسية في RAWAEA وليست شيئًا يجب اختزاله داخل `main.html`.

---

## 5. الفحص الجنائي لملف vouchers.html الحالي

الملف:
`papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/vouchers.html`

الحالة الحالية = 1830 سطرًا.

### Vehicle source path

`loadRefs:function()` يقرأ:

`vehicles`
- id
- vehicle_code
- license_plate
- model
- driver_id
- status
- mobile_branch_id
- mobile_stock_enabled

مع:
- company scope
- status = Active

إذن الربط ليس Text-only.
الحقل يحتفظ بـUUID المركبة.

### Vehicle semantic path

`vehicleBranch:function(v)`
يربط:
`vehicles.mobile_branch_id`
بـbranch النشط.

مع fallback تاريخي:
`VAN-<vehicle_code>`

### DirectSale filter

`pickArr:function(key)`
عند:
`key==='wsTo' && type==='DirectSale'`

يفرض:
- مركبة Active
- مخزن متنقل صالح
- mobile stock enabled
- driver صالح كمندوب بيع مباشر
- branch source موجود
- المستخدم مسموح على branch
- المندوب مسموح على branch
- عند اختيار مندوب محدد: vehicle.driver_id = rep.id

هذا يعني أن عدم ظهور المركبة **ليس ناتجًا عن عدم ربط المركبة بجدول vehicles**.

---

## 6. السبب الجذري الحقيقي للمشكلة الحالية

### العنصر المعيب

في CSS:

`.ws-top-panel`

يحتوي على:

`overflow:hidden`

وفي:

`renderWorkspace:function()`

تم وضع:

`s.routeHtml()`

داخل:

`wsTopPanel`

و`routeHtml()` يحتوي على:

- wsFrom
- wsRep
- wsTo
- wsFromSearch
- wsRepSearch
- wsToSearch
- smart menus

### النتيجة

`.smart-menu` للقوائم المنسدلة الخاصة بالفرع/المندوب/المركبة هو عنصر absolute.

وجوده داخل parent:
`.ws-top-panel`

مع:
`overflow:hidden`

يجعل القائمة التي تخرج خارج حدود الـpanel تُقص بصريًا.

وهذا يفسر الحالة بدقة:

- بيانات المركبة موجودة.
- query صحيح.
- vehicleBranch صحيح.
- filter صحيح.
- UUID صحيح.
- backend صحيح.
- المشكلة UI clipping.

### لماذا هذه النتيجة أقوى من تفسير Cache أو Production؟

لأننا أثبتنا مباشرة في Production أن هناك مركبة واحدة مطابقة بالكامل لسياق DirectSale.

وأثبتنا في المصدر أن lookup نفسه يقرأ جدول `vehicles` ويطبّق شروط الشركة والحالة والمخزن المتنقل والمندوب.

إذن Defect المثبت في المصدر هو حدود الـoverflow.

---

## 7. نقطة مهمة لا يجب تغييرها

المصدر الحالي يفرض وجود branch source قبل أن يعرض Vehicles في DirectSale.

الشرط هو:

`!!b`

حيث `b` = الفرع المختار من `wsFrom`.

هذا ليس خطأ جديدًا مثبتًا.
العقد الحالي هو:

Branch → Vehicle

لذلك لا نعيد تصميم ترتيب الاختيارات إلى Vehicle-first إلا بعد إثبات عقد مستقل لذلك.

كما أن V-03/V-04/V-05/V-06/V-07/V-08 سبق إغلاقها ولا يجوز إعادة بنائها.

---

## 8. Product Search

تم بالفعل تطبيق Report295 في commit:

`29cd6e08056b50545db05a4bff220424127126c5`

بحيث أصبح:
- wsSearch
- wsResults
- wsScanBtn
- wsCats

داخل Catalog header الثابت، خارج `wsTopPanel`.

لا يُعاد هذا الإصلاح.

الإصلاح الجديد في Report296 منفصل:
إخراج Route/Vehicle controls نفسها من `wsTopPanel`.

---

## 9. Cancel Voucher

### الحالة الحالية

زر الإلغاء موجود بالفعل داخل:
`cards:function(rows,scope)`

وعند:
`scope==='pending'`
و:
`status==='Draft'`

يظهر:
`إلغاء`

ويرتبط بـ:

`App.cancel(voucher_code)`

والدالة:
`cancel:function(code)`

تستخدم:

`cancel-stock-voucher`

### Production verification

Edge Function:
`cancel-stock-voucher`
- status = ACTIVE
- version = 4
- verify_jwt = true

وتستدعي:
`cancel_manual_stock_voucher_atomic`

إذن لا توجد جراحة جديدة مطلوبة لزر الإلغاء.

لا نكرر هذا الإصلاح.

---

## 10. picker.html

الملف الحالي:
`companies/company-1/warehouse/picker.html`

تمت مراجعته على مستوى المصدر الحالي، 925 سطرًا.

الوظيفة التاريخية والتشغيلية المثبتة:
- field execution
- runsheet execution
- cancel/reopen lifecycle
- quantity handling
- operational warehouse workflow
- mobile-first interaction.

الاستفادة الأساسية من Picker في هذا الإغلاق:
- إبقاء التطبيق المختص Operational.
- عدم نقل منطق التنفيذ الميداني إلى vouchers.
- الحفاظ على منطق lifecycle الموجود بالفعل.

لم يثبت في هذه الجلسة Defect جديد في Picker يبرر فتح Closure Unit إضافية.

---

## 11. van-sales.html

الملف:
`companies/company-1/sales/van-sales.html`

الحالة الحالية:
- 2297 سطرًا.
- Direct Customer Sale application.
- يعتمد على mobile branch canonical للمركبة.
- يستخدم cart / customer / stock.
- `source='van-sales'`.
- Invoiced path في Production يستخدم `post_stock_movement(...,'VanSale',...)`.
- لا يحتاج Order/Runsheet قبل البيع المباشر.

لم يثبت في هذه الجلسة Defect جديد يبرر تعديل `van-sales.html`.

لذلك لم يُلمس.

---

## 12. Production Core

العقد المركزي المثبت:
`post_stock_movement`

ثم:

`stock_branches`
+
`inventory_log`

و:
`reserve_stock`
Reservation Engine فقط.

لا Writer مستقل جديد.

### Related capabilities currently deployed

- create-stock-voucher v10
- send-stock-voucher v20
- receive-stock-voucher v22
- complete-stock-voucher v4
- cancel-stock-voucher v4

لا حاجة إلى New Edge Function.

لا حاجة إلى تغيير gateway/function count.

---

## 13. المقارنة التنافسية

### Odoo

Odoo 19 يدعم:
- Barcode operations
- assigned inventory counts
- manual product addition
- quantity editing
- +1 / -1
- location/product selection
- validation

Official:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

### Dynamics 365

يوفر Inventory Journals للـ:
- Movement
- Adjustment
- Transfer
- Counting

ويحدد From/To dimensions.

Official:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

### SAP S/4HANA

Goods Movement يغطي:
- Goods Receipt
- Goods Issue
- Stock Transfer
- Transfer Posting

مع material/document trail.

Official:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html

### Daftra

Detailed Inventory Transactions يوفر:
- Date
- Product
- Warehouse
- Type
- source/reference
- inward/outward
- notes
- print/export

كما أن stocktaking منفصل ويمكن أن يكون موجهًا للمنتجات/المخازن.

Official:
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/
https://docs.daftra.com/en/user_manual/the-inventory-stocktaking-method-used-in-the-system-and-its-features/

### Manager.io

لم يظهر مصدر رسمي قابل للتحقق في lookup الحالي، لذلك لم تُبنَ على Manager.io أي دعوى current-specific في هذا التقرير.

### النتيجة المعمارية

الأنظمة المنافسة تؤكد صحة فصل:
- document route/dimensions
- product selection
- inventory movement
- inventory audit/reporting

ولا تبرر إدخال Contract جديد داخل vouchers فقط من أجل التشابه الشكلي.

---

## 14. الفجوة الحالية المثبتة

الفجوة ليست:

- vehicles table
- Production vehicle binding
- DirectSale RPC
- cancel RPC
- Product Search function
- stock engine

الجديد المثبت فقط:

**Route/Vehicle lookup UI يعيش داخل collapsible container مع overflow:hidden.**

---

# 15. OWNER SURGICAL PATCH

## الملف المطلوب تعديله

`papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/vouchers.html`

## الدالة

`renderWorkspace:function()`

## الموضع

الكتلة الحالية التي تبدأ تقريبًا عند:
`'<div id="wsTopPanel"...`

ويظهر داخلها:

`'<div>'+s.routeHtml()+'</div>'+ `

### ابحث عن الكتلة التالية كاملة واحذفها

```text
            '<div id="wsTopPanel" class="ws-top-panel mt-3'+(topCollapsed?' ws-top-collapsed':'')+'">'+
              '<div>'+s.routeHtml()+'</div>'+
              '<div class="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-2"><input id="wsRef" class="smart-input" placeholder="المرجع الإجباري"><input id="wsNotes" class="smart-input" placeholder="'+(engine?'السبب الإجباري':'ملاحظات (اختياري)')+'"></div>'+
              (engine&&this.type==='Adjustment'?'<select id="wsMode" class="smart-input mt-2"><option value="replace">تسوية إلى الرصيد الفعلي</option><option value="add">زيادة</option><option value="deduct">نقص</option></select>':'')+
            '</div>'+
          '</div>'+
```

### واستبدلها بالكامل بالآتي

```text
            '<div class="mt-3">'+s.routeHtml()+'</div>'+
            '<div id="wsTopPanel" class="ws-top-panel mt-3'+(topCollapsed?' ws-top-collapsed':'')+'">'+
              '<div class="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-2"><input id="wsRef" class="smart-input" placeholder="المرجع الإجباري"><input id="wsNotes" class="smart-input" placeholder="'+(engine?'السبب الإجباري':'ملاحظات (اختياري)')+'"></div>'+
              (engine&&this.type==='Adjustment'?'<select id="wsMode" class="smart-input mt-2"><option value="replace">تسوية إلى الرصيد الفعلي</option><option value="add">زيادة</option><option value="deduct">نقص</option></select>':'')+
            '</div>'+
          '</div>'+
```

### ما لم يتغير

- `routeHtml()`
- `wsFrom`
- `wsRep`
- `wsTo`
- `wsFromSearch`
- `wsRepSearch`
- `wsToSearch`
- `pickArr()`
- `pickSearch()`
- `pickSelect()`
- `vehicleBranch()`
- `DirectSale`
- `DirectReturn`
- `App.search()`
- `App.searchKey()`
- `App.openScanner()`
- Cart
- Submit
- RPCs
- Permissions
- Production data.

### لماذا هذه الجراحة

`workspace-head` الحالي لديه:

`overflow:visible`

بينما `ws-top-panel` لديه:

`overflow:hidden`

بعد النقل تصبح Vehicle/Rep/Branch smart menus تحت الحاوية المرئية، فلا تُقص.

وفي الوقت نفسه يظل:
`wsTopPanel`

مسؤولًا فقط عن:
- المرجع
- الملاحظات
- Adjustment Mode

أي أن وظيفة الـcollapse أصبحت مرتبطة بالـoptional document metadata، لا بالـRoute identity ولا بالـVehicle selection.

---

## 16. Static verification target

بعد التطبيق يجب إثبات:

- file parses successfully.
- `wsSearch` count = 1.
- `wsCats` count = 1.
- `wsFrom` count = 1.
- `wsRep` count = 1.
- `wsTo` count = 1.
- `routeHtml()` موجودة مرة واحدة في `renderWorkspace()`.
- `wsTopPanel` لا يحتوي `s.routeHtml()`.
- `wsToMenu` يقع تحت `workspace-head` وليس تحت `ws-top-panel`.
- no duplicate ids.
- main.html unchanged.
- van-sales.html unchanged.

---

## 17. Production action in this closure

لا يوجد Production schema change مطلوب.

لا Edge Function جديدة.

لا Edge Function modification.

لا stock mutation.

لا voucher mutation.

لا order mutation.

لا runsheet mutation.

لا vehicle data mutation.

Production is already structurally capable of the requested vehicle flow.

---

## 18. E2E status

### Production transactional evidence

Vehicle/Rep/Branch/Item DirectSale contract سبق إثباته Transactionally بنجاح مع rollback كامل.

### Browser E2E

ظل مفتوحًا لأن بيئة هذه الجلسة لا توفر authenticated click-through browser execution.

لا يُسجل PASS وهمي.

الـE2E المطلوب بعد تطبيق Patch:

New Voucher
→ DirectSale
→ اختيار BR-01
→ فتح حقل المندوب
→ فتح حقل المركبة
→ ظهور VEH-TEST-260921
→ اختيار المركبة
→ ظهور vehicle/rep binding
→ إغلاق/فتح Route metadata panel
→ بقاء route controls مرئية
→ اختيار Item
→ Quantity
→ Save Draft
→ Send
→ Verify voucher state in Production
→ Verify `inventory_log`
→ Verify `stock_branches`
→ Verify audit
→ Re-snapshot Production.

---

## 19. Final Self-Audit

### What was proved
- Current System HEAD and parent.
- Current Frontend HEAD and parent.
- Current vouchers blob.
- Current Production vehicle.
- Current users/rep permissions.
- Vehicle → mobile branch relationship.
- Vehicle → rep relationship.
- DirectSale predicate matches one current production vehicle.
- Current voucher source already has vehicle table integration.
- Current source already has cancel action.
- Current cancel Edge Function is deployed and JWT protected.
- Product Search Report295 surgery is already present.
- Root cause of the current vehicle-list UI defect is source-level overflow clipping.
- Exact surgical patch is isolated to `renderWorkspace()`.

### What was not proved
- Authenticated browser click-through against the published frontend artifact.
- Published artifact identity against the current frontend Git HEAD.

### What was not changed
- main.html.
- van-sales.html.
- vouchers.html source.
- Production business schema.
- Production vehicle data.
- Edge Function count.

### Remaining open boundary
Only owner source application + published artifact/runtime Browser E2E.

---

## 20. Exact next-session instructions

ابدأ من:

1. Verify frontend HEAD:
   `29cd6e08056b50545db05a4bff220424127126c5`

2. Verify current vouchers blob:
   `a22b4014603f44c12820ec4a769e7e0138abd854`

3. Apply فقط Report296 surgical replacement داخل:
   `renderWorkspace:function()`

4. Parse complete file.

5. Verify:
   `routeHtml()` خارج `wsTopPanel`.

6. Verify published artifact identity.

7. Execute authenticated browser E2E.

8. Re-snapshot Production في نفس لحظة نهاية الاختبار.

9. لا تعيد V-03/V-04/V-05/V-06/V-07/V-08.

10. لا تعيد Report295 Product Search surgery.

11. لا تغيّر Production إلا إذا ظهر Regression جديد مثبت.

---

# FINAL STATUS

**PRODUCTION CONTRACT VERIFIED**

**VEHICLE DATA VERIFIED**

**CANCEL CAPABILITY VERIFIED**

**REPORT295 SEARCH SURGERY PRESERVED**

**CURRENT DEFECT = VEHICLE/ROUTE SMART-MENU CLIPPING**

**SOURCE SURGICAL PATCH = READY FOR OWNER**

**NO NEW EDGE FUNCTION**

**NO PRODUCTION SCHEMA CHANGE**

**BROWSER E2E = OPEN**

**MAIN.HTML = UNTOUCHED**

**VAN-SALES.HTML = UNTOUCHED**

---

## 21. Post-session documentation amendment

بعد إنشاء هذا التقرير وتحديث `CURRENT_STATE.md` تم تسجيل commit توثيقي جديد في System repo:

- Final documentation HEAD: `096350cdb40fac825ffd1fa100c7480fedcff782`
- Parent: `bf81536877e4580beb46e25c258425c49902c169`
- Message: `state: record Report296 vehicle picker clipping closure`

هذا الـcommit يخص `CURRENT_STATE.md` فقط، ولا يغيّر كود تطبيق الأذونات أو Production.

القاعدة عند استئناف العمل:
**لا تعتمد على رقم HEAD الموجود في تقرير سابق؛ أعد قراءة Git HEAD/parent وCurrent Source وCurrent Production أولًا.**

**Report296 remains the authoritative forensic record for the vehicle picker clipping defect; owner source application and authenticated Browser E2E remain the only open closure boundaries.**

