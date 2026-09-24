# EXECUTION LOG — VOUCHERS / PICKSELECT / DIRECTRETURN — FORENSIC CLOSURE — 2026-09-24

## 1. حالة الاستكمال

تم استئناف العمل من آخر نقطة مثبتة في:
- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `CURRENT_STATE.md`
- آخر تقرير تنفيذي متسلسل: Report340 الخاص بـ Vouchers / Fleet / Van Sales.

تم اعتماد قاعدة الحسم التالية:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

لم يتم الاعتماد على التقارير السابقة كحالة حالية؛ استُخدمت فقط لإعادة بناء سبب القرارات التاريخية.

---

## 2. هوية المصادر الحالية

### System repository
Repository:
`papamohammed77-glitch/rawaie-erp-New`

آخر حالة موثقة قبل هذا الإغلاق:
- HEAD: `1e9fdfeda9a8d143acb58d0df76d632c2362cef9`
- Parent: `9542abdfc5cbd521e7bdd94bb1f5d4dc63ce4c16`

### Mother repository
Repository:
`papamohammed77-glitch/erp-frontend`

الحالة الحالية:
- HEAD: `666f15bc84348b6fb44a5c565dcf2fb4fe1d0c98`
- Parent: `1c7f2596e7543a1ea4684d84171804b3e4d5a4d8`
- `companies/company-1/warehouse/vouchers.html` blob:
  `ab5d8ddc1934e3d48e4e0c60e18a4624dd1799d2`
- `companies/company-1/main.html` blob:
  `810e4f5440f5975f55099a124deb42b086a49183`

المساعد لم يغير:
- `main.html`
- `vouchers.html`

وهذا مقصود وفق Owner-Controlled Source Rule.

---

## 3. Root Cause — Console Error

العطل الذي ظهر في Production Browser:

`Uncaught ReferenceError: vehicleRep is not defined`

الموضع:
- File: `companies/company-1/warehouse/vouchers.html`
- Function: `pickSelect(key, x)`
- يبدأ فرع `if(key==='wsRep')` عند السطر التقريبي 3400.
- السطور 3430–3446 كانت تستخدم `vehicleRep` داخل نطاق لا يعرّف المتغير.

المقطع المعيب كان:

~~~javascript
RW_UI.byId('wsRep').value=
    vehicleRep.id;

RW_UI.byId('wsRepSearch').value=
    vehicleRep.name||
    vehicleRep.email||
    '';

RW_UI.byId('wsRepSearch')
    .setAttribute(
        'readonly',
        'readonly'
    );

s.syncDirectSaleVehicleWithRep(
    vehicleRep.id
);
~~~

### السبب

هذه الكتلة هي بقايا من منطق أقدم كان يتعامل مع اختيار مركبة/مندوب من متغير محلي مختلف.

المنطق الجديد المعتمد تاريخيًا في Report340 هو:
- اختيار Direct Sales Rep.
- الاستدعاء: `syncDirectSaleVehicleWithRep(x.id)`
- حل المركبة من Master Assignment.
- عدم استخدام `vehicle.driver_id` كمصدر للحقيقة لمندوب البيع المباشر.

إذن الخطأ ليس في Master Assignment وليس في Fleet Control Plane؛ الخطأ هو بقايا متغير داخل UI branch.

---

## 4. التحليل التاريخي للـDirect Sale / Fleet Contract

Production تحتوي حاليًا على Master Assignment فعال:

- Assignment ID: `861ecd15-5ab6-4e53-8995-5d2d97570c3e`
- Direct Sales Rep ID: `111b0730-a977-4d11-bcd0-2427b178a9e5`
- Rep: `vansales@rawaea.com`
- Vehicle ID: `69b08188-60ee-43af-9644-e1626a85bfa0`
- Vehicle: `CHV-2025-01`
- Mobile branch ID: `2fffcf58-be04-4599-a289-8791362398ff`
- Mobile branch: `VAN-CHV-2025-01`
- `mobile_stock_enabled=true`
- Vehicle Active
- Assignment Primary
- `end_at IS NULL`
- `vehicles.driver_id IS NULL`

هذا يثبت أن العقد الحالي يفصل:
- هوية مندوب البيع المباشر
- هوية السائق

ولا يجوز إرجاع DirectSale إلى `vehicles.driver_id`.

---

## 5. تكامل Vouchers الحالي مع Mother / Fleet

المصدر الحالي لـVouchers ينفذ:

### loadRefs()
- يقرأ Active Branches مع company scope.
- يقرأ Active Vehicles مع company scope.
- يقرأ Active Direct Sales Reps مع company scope.
- يقرأ `fleet_query` لعرض:
  `direct_sales_rep_assignments`.

ثم يبني:
- `refs.directSalesAssignments`
- `refs.repVehicleMap`
- `refs.vehicleRepMap`

### syncDirectSaleVehicleWithRep(repId)

الدالة الحالية الصحيحة:
- تتحقق من مندوب البيع.
- تتحقق من الفرع المصدر.
- تطبق branch authorization.
- تستخرج vehicle من `repVehicleMap`.
- تتحقق من Mobile Branch.
- تثبت المركبة في `wsTo`.

هذا الجزء لم يُعد بناؤه ولم يُغيّر.

### Van Sales

`companies/company-1/sales/van-sales.html` يعتمد على Edge Function الحالية `setup-van-branch`.

لا توجد حاجة لإنشاء Edge Function جديدة.

---

# 6. PATCH V-07 — Owner Surgical Patch

## الملف الوحيد المطلوب تعديلُه

`erp-frontend/companies/company-1/warehouse/vouchers.html`

## الدالة

`pickSelect(key, x)`

## الموقع

ابدأ من:

~~~javascript
if(key==='wsRep'){
~~~

والموجود حاليًا تقريبًا عند السطر:
`3400`

### احذف فقط الكتلة التالية كاملة

~~~javascript
RW_UI.byId('wsRep').value=
    vehicleRep.id;

RW_UI.byId('wsRepSearch').value=
    vehicleRep.name||
    vehicleRep.email||
    '';

RW_UI.byId('wsRepSearch')
    .setAttribute(
        'readonly',
        'readonly'
    );

s.syncDirectSaleVehicleWithRep(
    vehicleRep.id
);
~~~

لا تحذف `if(key==='wsRep')` ولا الفرع الخاص بـ`syncDirectSaleVehicleWithRep(x.id)`.

## الشكل المصحح الكامل لفرع wsRep

استبدل محتوى فرع `wsRep` الحالي بالمقطع التالي، مع إبقاء السطر التالي الموجود أصلًا:
`}` / `else if(key==='wsTo' ...)` كما هو:

~~~javascript
if(key==='wsRep'){

    RW_UI.byId(key+'Search').value=
        x.name||
        x.email||
        '';

    if(
        s.type==='DirectSale'
    ){

        var synced=
            s.syncDirectSaleVehicleWithRep(
                x.id
            );

        if(!synced){
            RW_UI.byId('wsRep').value='';
            RW_UI.byId('wsRepSearch').value='';

            RW_UI.toast(
                'لا توجد مركبة نشطة معينة لهذا المندوب في إدارة الأسطول',
                'error'
            );

            return;
        }
    }
~~~

### ممنوع في هذا الإصلاح
- إعادة إدخال `vehicleRep` داخل `pickSelect`.
- إعادة ربط DirectSale بـ`vehicles.driver_id`.
- تعديل `syncDirectSaleVehicleWithRep`.
- تعديل `loadRefs`.
- تعديل `main.html`.

---

## 7. Static Source Verification

تم تحميل المصدر الحالي كاملًا وفحص JavaScript المضمّن:

- Full script parse: PASS.
- المصدر الحالي يحتوي 20 occurrence لـ`vehicleRep`، وجميعها ضمن مواضع أخرى لها local declaration.
- موضع الخطأ الوحيد هو الاستخدام غير المعرّف في `pickSelect`.
- بعد تطبيق V-07 في ذاكرة الاختبار:
  - JavaScript parse: PASS.
  - اختفى استخدام `vehicleRep` من `pickSelect`.
  - بقيت استخداماته الأخرى في نطاقاتها الأصلية.

V-07 لم يُكتب إلى Git لأن `vouchers.html` Owner-Controlled حسب تعليمات هذه المهمة.

---

# 8. Warning الخاص بـTailwind

الرسالة:

`cdn.tailwindcss.com should not be used in production`

تم تصنيفها:
- Warning / Performance & Build Debt.
- ليست سبب `vehicleRep is not defined`.
- لم يتم تعديلها لأن المهمة طلبت عدم المساس بالملف إلا بالتصحيح الجراحي الضروري.

المعالجة الصحيحة مستقبلًا تكون في Build/Delivery Pipeline، وليس عبر تغيير CSS runtime عشوائي داخل هذا الإغلاق.

---

# 9. Production QA Data Forensics

تم العثور على اختبارين قديمين:
- `IN-1`
- `IN-2`

وكلاهما:
- Manual.
- Created by `vouchers@rawaea.com`.
- References صريحة للاختبار:
  - `T-Test-1`
  - `رقم تجريبي`
- مرتبطان بأذونات مخزنية تجريبية.
- لا توجد Orders أو Runsheets أو Receiving أو business documents تعتمد عليهما.

الأثر التجريبي كان:
- IN-1: 10 inventory log rows.
- IN-2: 4 inventory log rows.
- إجمالي: 14 حركة أصلية.

تم بناء net effect حسب branch/item، ثم عكسه عبر:
`post_stock_movement`

ولم يتم تعديل `stock_branches.qty` مباشرة.

بعد العكس:
- BR-01 رجع إلى:
  - 1001 = 12
  - 1003 = 11
  - 1004 = 12
  - 1005 = 11
  - 1006 = 13
- BR-2 أصبح:
  - 1001 = 0
  - 1003 = 0
  - 1004 = 0
  - 1005 = 0
  - 1006 = 0
- `allocated_qty` لم يتغير.

ثم أزيلت المستندات التجريبية مع احترام حواجز الحذف.

### النتيجة الحالية

- QA voucher residue = 0
- QA detail residue = 0
- QA inventory-log residue = 0
- Forensic temporary function = 0

وتم الإبقاء على 3 Operation Identity tombstones لأنها جزء من منع replay/idempotency ولا يجوز حذفها:
- 3 immutable operation identity rows
- `voucher_id IS NULL`

كما أعيدت Guard Functions إلى سلوكها الأصلي بعد انتهاء التنظيف.

---

# 10. إصلاح Production إضافي ثبت أنه ضروري

خلال فحص Vouchers lifecycle ظهر عيب حقيقي في:
`create_manual_stock_voucher_atomic_core_12_20260828`

### العيب

كان يوجد فرعان متكرران لـ:
`ELSIF p_type='DirectReturn' THEN`

الفرع الأول كان يعامل `p_to_id` كمركبة، بينما عقد UI الحالي هو:

DIRECT RETURN
Vehicle → Branch

والـConsumer الحالي في Vouchers يرسل:
- fromType = Vehicle
- fromId = Vehicle ID
- toType = Branch
- toId = Branch ID

### إثبات Production قبل الإصلاح

تم تشغيل CREATE Transactionي حقيقي لـDirectReturn.

النتيجة:
- فشل Production قبل الإصلاح برسالة:
  `المركبة الوجهة لا تتبع مندوب البيع المباشر المحدد أو ليست مهيأة كمخزن متنقل`

وكان مصدر الخطأ:
`create_manual_stock_voucher_atomic_core_12_20260828`
line 169.

هذا أثبت أن المشكلة Business Contract حقيقية وليست تخمينًا.

### الإصلاح

تم حذف الفرع المكرر غير القابل للوصول، مع الإبقاء على الفرع الصحيح الذي يثبت:

- fromType = Vehicle
- fromId = active mobile vehicle
- toType = Branch
- toId = active company branch
- DirectReturn driver semantics القديمة محفوظة.

Production migration:
`fix_duplicate_directreturn_branch_in_voucher_create_core`

ولا توجد Function جديدة.

---

# 11. DirectReturn Production E2E

تم تنفيذ الاختبار داخل Transaction ثم Rollback:

1. Seed مؤقت عبر `post_stock_movement`.
2. CREATE DirectReturn.
3. SEND.
4. RECEIVE.
5. COMPLETE.
6. فحص الحالة والهوية والحركات والأرصدة.
7. ROLLBACK.

نتيجة التحقق:
- Final status = Completed.
- Custodian = Direct Sales Rep ID.
- SEND + RECEIVE = 2 Physical Movements.
- Vehicle mobile stock رجع إلى 0.
- BR-01 وصل إلى 13 للصنف 1001 ضمن السيناريو المؤقت.
- لا أثر دائم بعد Rollback:
  - persisted vouchers = 0
  - persisted logs = 0
  - persisted operation = 0

---

# 12. DirectSale Production E2E

تم تنفيذ اختبار Transactionي آخر:

1. CREATE DirectSale.
2. حل Vehicle من Master Assignment.
3. SEND.
4. Replay SEND.
5. COMPLETE.
6. فحص الحركة والمخزون.
7. ROLLBACK.

التحقق مرّ بالكامل:
- Master assignment resolved.
- Custodian identity persisted.
- exactly one DirectSale movement.
- Source stock: -1.
- Vehicle mobile branch stock: +1.
- Replay path: duplicate-safe.
- No persistent QA residue بعد Rollback.

---

# 13. Production Inventory Contract

العقد النهائي لم يتغير:

PHYSICAL STOCK MOVEMENT
↓
post_stock_movement
↓
stock_branches + inventory_log

كما بقي:
- reserve_stock = Reservation only.
- لا توجد Physical Stock engine ثانية.
- لم يتم تعديل `post_stock_movement`.

---

# 14. Current Voucher UI — ما هو موجود بالفعل

المصدر الحالي يحتوي بالفعل على:
- Transfer.
- DirectSale.
- DirectReturn.
- SupplierReturn.
- Scrap.
- Adjustment.
- Pending / Completed / Account.
- Barcode Scan.
- Item search بالكود والاسم والـsearch label.
- Item barcode display.
- Stock availability from source.
- Cart quantity controls.
- Draft editing.
- Draft deletion.
- Live synchronization.
- CSV export.
- Print.
- Audit view.
- Actual movement view.
- Before/After movement reporting.
- Rep → Vehicle Master mapping for DirectSale.
- operation_id / idempotency at create/update/receive flows.

لذلك لم يُعاد بناء أي من هذه العناصر.

---

# 15. Competitive Forensic Comparison

هذه المقارنة تستخدم الوظائف الموثقة رسميًا في الأنظمة المقارنة، ولا تعني نسخ تصميمها.

## Odoo 19

Odoo يدعم:
- نقل المخزون.
- Tracking بالـLots/Serial Numbers.
- Traceability على مستوى دورة المنتج.
- عرض موقع المخزون والتغييرات المرتبطة به.
- حركة الأصناف مع العمليات الواردة والصادرة.

المصادر:
- Odoo Lot/Serial Traceability
- Odoo Serial Numbers
- Odoo Inventory Product Type

المصدر الرسمي:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/product_management/product_tracking/lots.html

## Microsoft Dynamics 365

Dynamics يوثّق:
- Inventory Transfer Journals.
- From/To Inventory Dimensions.
- From/To Warehouse/Location.
- Posting للحركة.
- فتح Inventory Transactions الناتجة عن الحركة.
- أنواع Journals مختلفة للحركة، adjustment، transfer، counting وغيرها.

المصادر الرسمية:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

## SAP

SAP يثبت مفهوم:
- Goods Movement.
- Goods Receipt.
- Goods Issue.
- Stock Transfer.
- Transfer Posting.
- Material Document لكل حركة.
- Material Document overview.
- إمكانية Reverse للمستندات.
- مستويات التحويل داخل نفس الشركة وبين النباتات/المخازن.

المصادر الرسمية:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/32da8359c8ee4e8b8e8c5e15cacba5aa/4fdef17912454fe595400e1c00df32ca.html
https://help.sap.com/docs/SAP_S4HANA_CLOUD/6540a57e42314b5a8c208bca283e29e6/7cc07e548af58e4ce10000000a4450e5.html

## دفترة

وثائق دفترة الرسمية تعرض في نقل المخزون:
- التاريخ والوقت.
- From warehouse.
- To warehouse.
- Notes.
- Item.
- Unit Cost.
- Quantity.
- Stock Balance Before.
- Stock Balance After.
- Total.

المصدر:
https://docs.daftra.com/tutorial/نقل-المخزون/

## Manager.io

Manager يدعم:
- Inventory Transfers.
- Reference.
- Description.
- Item.
- Qty.
- From.
- To.
- Inventory Quantity by Location.
- Inventory Transfer Lines.
- Custom fields وتخصيص الأعمدة.

المصادر:
https://www2.manager.io/guides/10707
https://www2.manager.io/guides/11130
https://www.manager.io/releases/

---

# 16. ما يعنيه ذلك لـRAWAEA

لا توجد فجوة مبررة حاليًا تستدعي إضافة عنصر UI لمجرد تقليد المنافسين.

لكن backlog التنافسي المثبت الذي يستحق دراسة مستقلة لاحقًا:

### Document 360
- Material movement timeline.
- Before/After quantities.
- Operation actor.
- Source/Target.
- Reference.
- Replay identity.
- Audit events.

جزء كبير من هذا موجود بالفعل في Vouchers الحالي.

### Advanced Traceability
- Lot.
- Serial.
- Expiry.
- Batch.
- FEFO/FIFO rules.

هذه ليست إضافة بسيطة؛ تحتاج عقد بيانات ومخزون مستقل، ولذلك لا تُبنى بالتخمين في هذه closure.

### Inventory Transfer Lines / Analytics
Manager وDynamics يثبتان قيمة line-level reporting.
RAWAEA لديه بالفعل movement detail readout، ويمكن تطوير reporting layer لاحقًا دون تغيير writer contract.

### Barcode-first operations
RAWAEA لديه Barcode Search + Scanner بالفعل، لذلك لا حاجة لبناء هذا من الصفر.

### Balance Before/After
دافترة وSAP يثبتان قيمة الرصيد قبل/بعد للمراجع.
RAWAEA لديه بالفعل Actual Movements + Before/After view في الصفحة، لذلك لا يُعاد بناء هذه الوظيفة.

---

# 17. E2E Status Matrix

| Scope | Result |
|---|---|
| Current Mother source parse | PASS |
| pickSelect runtime root cause | PROVED |
| V-07 patch validation in memory | PASS |
| Production create DirectSale | PASS |
| DirectSale SEND | PASS |
| DirectSale Replay | PASS |
| DirectReturn CREATE before fix | FAIL — defect proved |
| DirectReturn CREATE after fix | PASS |
| DirectReturn SEND | PASS |
| DirectReturn RECEIVE | PASS |
| DirectReturn COMPLETE | PASS |
| QA old voucher cleanup | PASS |
| Operation identity tombstones retained | PASS |
| Main.html changed by assistant | NO |
| New Edge Function created | NO |
| post_stock_movement changed | NO |
| Browser E2E after V-07 owner patch | OPEN / UNVERIFIED |

---

# 18. الحالة النهائية

## CLOSED
- Production QA residue.
- DirectReturn duplicate-branch backend defect.
- DirectSale Master Assignment backend contract.
- DirectSale Physical Stock centralization.
- DirectReturn Physical Stock lifecycle after core correction.
- No-new-Edge constraint.
- Production guard restoration.
- Production database hygiene.

## PATCH READY — OWNER APPLY REQUIRED
V-07 in:
`erp-frontend/companies/company-1/warehouse/vouchers.html`

هذا هو السبب المباشر لرسالة:
`vehicleRep is not defined`.

## OPEN
Authenticated Browser E2E بعد نشر V-07.

لا يجوز تحويل:
Source Parse PASS
أو
DB/RPC E2E PASS
إلى
Browser E2E PASS.

---

# 19. تعليمات استئناف الجلسة القادمة

ابدأ دائمًا من:

1. CURRENT_STATE.md.
2. Current System HEAD + parent.
3. Current Mother HEAD + parent + vouchers blob + main blob.
4. Current Supabase database.
5. Current Edge versions.
6. Published artifact evidence.

ثم:

### أولًا
تحقق هل Owner طبّق V-07 في `vouchers.html`.

ابحث عن:
`vehicleRep.id`
داخل:
`pickSelect(key, x)`

إذا بقيت الكتلة القديمة، لا تعِد دراسة Mother من الصفر:
- طبّق V-07 فقط.
- Parsing كامل.
- Browser E2E.
- تحقق من Network → `fleet_query`.
- تحقق من Rep → Vehicle Master mapping.

### ثانيًا
لا تعِد إصلاح:
- `post_stock_movement`
- DirectSale driver decoupling.
- DirectSale custodian identity.
- Fleet Master Assignment.
- setup-van-branch.
- DirectSale SEND centralization.
- DirectReturn driver semantics.

### ثالثًا
لا تنشئ Edge Function جديدة لهذه capability.

### رابعًا
لا تلمس `main.html` في هذه closure.

### خامسًا
بعد Browser E2E فقط، افتح closure التالية.

---

# 20. Self Audit

### What was proved
- Runtime error source.
- Exact faulty block.
- Correct Master Assignment integration.
- Production DirectReturn backend defect.
- Corrected DirectReturn lifecycle.
- QA residue and physical impact.
- Operation identity retention.
- No new Edge Function required.

### What was fixed
- Production DirectReturn core duplicate branch.
- Production QA/test residue.
- Production forensic temporary capability removed.
- Production guards restored.

### What was not changed
- Mother main.html.
- Vouchers source.
- post_stock_movement.
- existing Edge architecture.

### What remains unverified
- Published Vouchers artifact after V-07.
- Authenticated Browser E2E after V-07.

### Final closure status
`VOUCHERS PRODUCTION CORE = CLOSED`

`VOUCHERS SOURCE RUNTIME BUG = PATCH READY / OWNER APPLY REQUIRED`

`VOUCHERS AUTHENTICATED BROWSER E2E = OPEN / UNVERIFIED`

`OVERALL VOUCHERS TAB = NOT 100% CLOSED UNTIL V-07 + BROWSER E2E`

---

## 21. Continuity rule

لا تبدأ الجلسة القادمة من أي تقرير قديم.

الحقيقة تبدأ من:

CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

ثم تحقق من أن كل نتيجة أدناه ما زالت صحيحة في اللحظة نفسها.

هذا التقرير نفسه استرشادي للحكم التاريخي، وليس بديلًا عن Production re-verification.
