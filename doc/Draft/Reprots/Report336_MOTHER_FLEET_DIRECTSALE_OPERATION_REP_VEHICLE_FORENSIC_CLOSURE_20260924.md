
# تقرير 336 — إغلاق جنائي لمسار إدارة الأسطول وربط المركبة بالبيع المباشر
## 2026-09-24

## 1. نطاق التنفيذ
هذه الجولة عالجت الفجوة الفعلية بين:
- النظام الأم Mother.
- تطبيق الأذونات والمخزون.
- Fleet Control Plane.
- Production Supabase.

قاعدة الحقيقة:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE

التقارير السابقة استُخدمت كسجل تاريخي لفهم سبب وصول النظام إلى حالته الحالية، وليس كبديل عن فحص Production الحالية.

## 2. الحالة المرجعية التي بدأ منها التحقيق

### Mother
المستودع: papamohammed77-glitch/erp-frontend
HEAD المستخدم: 111a6876ddf38394989896f64767170b77c3231e
Parent: 26d4d4d347be477b69482e75627154aa6565d5ac
main.html blob: 3d1ac970c0e81d0a581045ce79b140708ccfa3af

### System
HEAD المستخدم قبل توثيق هذه الجولة: 38caa3016bbd528620cee10243485a5c76a65611
Parent: e6e96b34289dcb14186453ddd6ee323164b2fdc2

### Production
Supabase project: fiilmooggumokxanwiyx
الشركة الفعالة: 1
المركبات النشطة ذات Mobile Stock: 2
المركبتان الحاليتان ثبت أن driver_id لهما NULL.
مندوبا البيع المباشر النشطان المثبتان:
- van-sales2@rawaea.com
- vansales@rawaea.com

## 3. إعادة بناء التاريخ قبل التعديل

Commit 160ab6c41491e90bbd8f5cae690e0aee0c74c373 أثبت انتقال عقد DirectSale إلى هوية تشغيلية على مستوى العملية:
custodian_user_id = Direct Sales Representative للعملية.

التغيير التاريخي أزال اشتقاق custodian من vehicles.driver_id وجعل هوية العهدة مرتبطة بالعملية نفسها.

هذا مهم لأن:
- السيارة أصل Fleet ويمكن أن لا تحمل مندوبًا ثابتًا في سجل vehicle.driver_id.
- عملية DirectSale تحتاج إلى مندوب البيع الفعلي المسؤول عن العهدة في تلك العملية.

## 4. السبب الجذري الأول

Core:
create_manual_stock_voucher_atomic_core_12_20260828

كان يحتوي داخل تحقق DirectSale على:
AND v.driver_id=p_rep_id

Production الحالية أثبتت أن المركبات Mobile Stock النشطة ليس لها driver_id.

النتيجة:
المركبة صحيحة.
Mobile Branch صحيحة.
مندوب البيع صحيح.
لكن DirectSale CREATE كان يُرفض بسبب ارتباط قديم بين السائق الثابت ومندوب العملية.

هذا Defect حقيقي مثبت من:
- Production vehicle rows.
- Production RPC definition.
- التاريخ المعماري في Commit 160ab6....

## 5. العلاج الأول المنفذ في Production

Migration:
20260924155735_decouple_directsale_operation_rep_from_vehicle_driver_20260924

تم تنفيذ تعديل جراحي في وظيفتين فقط:

1. create_manual_stock_voucher_atomic_core_12_20260828
- إزالة شرط vehicle.driver_id = p_rep_id من DirectSale CREATE.

2. update_manual_stock_voucher_atomic
- إزالة شرط vehicle.driver_id <> p_rep_id من DirectSale UPDATE فقط.
- إبقاء شرط DirectReturn دون تغيير.

لم يتغير:
- Physical Stock engine.
- Mobile Branch contract.
- Company scope.
- DirectReturn semantics.
- Fleet Control Plane.
- Van Sales contract.

## 6. السبب الجذري الثاني

بعد انتقال custodian إلى هوية العملية، كان Trigger الحالي:
enforce_stock_voucher_custodian

يشترط:
- custodian_user_id موجود.
- same company.
- Active.
- role = مندوب بيع مباشر.
- van-sales permission.

لكن Core CREATE لم يكن يكتب custodian_user_id في INSERT.

إذًا كان هناك Drift واضح بين:
validation contract
و
persistence contract

والـE2E الأول بعد العلاج الأول أثبت هذا التعارض مباشرة من Production:
Mobile voucher custodian is required.

## 7. العلاج الثاني المنفذ

Migration:
20260924155822_persist_directsale_operation_custodian_on_create_20260924

تم تعديل INSERT في create_manual_stock_voucher_atomic_core_12_20260828 لإضافة:
custodian_user_id

وقيمته:
p_rep_id
لـDirectSale وDirectReturn.

وبذلك أصبح:
Rep validation
+
Rep persistence
+
Custodian trigger
متسقة داخل نفس العقد.

## 8. لماذا main.html لم يتغير

تم فحص main.html الحالي مباشرة.

العناصر المثبتة حاليًا:
- زر ربط المركبة بالعملية موجود.
- openVehicleOperationLinkForm موجود.
- direct sale payload يرسل voucher_id.
- direct sale payload يرسل direct_sales_rep_id.
- operation_id موجود.
- VEHICLE_OPERATION_BIND موجود.
- تفاصيل المركبة تعرض direct_sales.
- fleet_query يقرأ direct_sales من voucher.to_id وcustodian_user_id.

إذن لم يثبت عيب حالي في Mother يستلزم Patch جديدًا.

لذلك:
لا يوجد تعديل جراحي جديد مطلوب في main.html.

إعادة تعديل main.html في هذه الجولة كانت ستكرر إصلاحًا مثبتًا وتزيد Regression Risk.

## 9. نقطة المرونة التي أصبحت صحيحة

تم اختبار سيناريو عملي:

CREATE
→ DirectSale Draft

ثم:
VEHICLE_OPERATION_BIND
→ تغيير المركبة في المسودة
→ تغيير مندوب العملية

ثم:
إعادة نفس bind
→ duplicate=true

ثم:
SEND
→ DirectSale

الاختبار استخدم مركبات حالية driver_id = NULL.

نجح الربط على أساس:
- vehicle identity للعملية.
- direct sales representative identity للعملية.
- custodian_user_id للعهدة.

ولم يعد السائق الثابت للمركبة شرطًا غير مناسب لهذه العملية.

## 10. Production E2E الكامل

تم تنفيذ الاختبار داخل Transaction واحدة ثم Rollback.

### CREATE
- type: DirectSale
- المصدر: BR-01
- Item: 1001
- quantity: 1
- إنشاء بواسطة: vouchers@rawaea.com
- operation_id: QA-CREATE-DS-20260924
- result: success=true

### BIND
VEHICLE_OPERATION_BIND
- vehicle: FRD-2025-02 TEST
- direct sales rep: vansales@rawaea.com
- status: Draft
- result: success=true

### REPLAY
نفس operation_id:
- result: success=true
- duplicate=true

### SEND
- result: success=true
- duplicate=false
- status: Sent
- movement_count: 1
- custody_ledger: true
- custody_value: 1
- custodian_user_id = vansales@rawaea.com

## 11. Physical Stock E2E

النتيجة الفعلية داخل Transaction:

BR-01:
- delta = -1

Mobile Vehicle Branch:
- delta = +1

inventory_log:
- delta = +1

السجل الناتج:
- movement_type = DirectSale
- qty = 1
- source_branch_id = BR-01
- target_branch_id = Mobile Vehicle Branch
- user_email = vouchers@rawaea.com
- idempotency_key = StockVoucherSend:<company>:<voucher>:<item>

إذن العقد المركزي ظل:
Physical Stock
→ post_stock_movement
→ stock_branches + inventory_log

ولم يتم إنشاء Physical Stock Writer جديد.

## 12. التأثير المحاسبي والمالي

DirectSale في هذه المرحلة هو تحميل عهدة مبيعات متنقلة، وليس Customer Sale محاسبيًا.

في الاختبار:
- journal_entries delta = 0
- journal_lines delta = 0
- driver_ledger delta = +1

سجل العهدة:
- driver_email = vansales@rawaea.com
- debit = 1
- credit = 0
- reference = IN-3
- description = تحميل عهدة مبيعات مباشرة – IN-3

وهذا يحافظ على الفصل بين:
1. تحميل العهدة.
2. البيع الفعلي للعميل من Van Sales.
3. التسوية اللاحقة.

## 13. تأثير فرع المخزون

تم قياس الرصيد قبل وبعد نفس العملية:
- فرع المصدر ينخفض بالكمية المنقولة.
- مخزن السيارة يزيد بنفس الكمية.
- الفارق الصافي للمؤسسة في إجمالي الكمية = صفر.
- لا يوجد تعديل في allocation.

بعد Rollback:
- BR-01 item 1001 = 11
- Mobile Vehicle Branch item 1001 = 0

ولا يوجد أثر QA دائم.

## 14. تكامل إدارة الأسطول والتقارير

fleet_query الحالية تقرأ من المصدر الصحيح:

في vehicle_detail:
- vehicle_id = stock_vouchers.to_id
- direct_sales_rep_id = stock_vouchers.custodian_user_id
- direct_sales_rep_name من users

وحركة المخزن تعتمد على:
inventory_log

بالتالي يصبح الربط التشغيلي:

Vehicle
← voucher.to_id

Direct Sales Rep / Custodian
← voucher.custodian_user_id

Physical Movement
← inventory_log

وهذا يسمح للنظام الأم بعرض العملية في تفاصيل المركبة دون تكرار منطق المخزون.

## 15. دور النظام الأم

العقد المعماري لم يتغير:

Mother:
- Control Plane
- Navigation
- Fleet monitoring
- operation linking
- reporting surface

Standalone applications:
- Execution Surface
- transaction entry
- field workflow

Supabase:
- transactional truth
- authorization
- lifecycle
- physical stock
- accounting/ledger contracts

لم يتم نقل Physical Stock logic إلى main.html.

## 16. Edge Function capacity

لم تُنشأ Edge Function جديدة.

الحل اعتمد على:
- RPC موجود.
- Database migration.
- Fleet RPC الحالي.

وهذا يحترم قيد gateway/spend cap.

## 17. Data cleanup

اختبار QA كان Transactional.

Post-rollback verification:
- QA vouchers = 0
- QA stock_voucher_operations = 0
- QA inventory_log = 0
- QA driver_ledger = 0
- QA fleet registry = 0
- BR-01 item 1001 = 11
- mobile branch item 1001 = 0

لا يوجد اختبار ترك بيانات تجريبية في Production.

## 18. Browser Runtime

لم تتوفر قناة Browser authenticated execution حقيقية في هذه الجلسة.

إذن:
- Production RPC E2E = PASS
- Production database assertions = PASS
- Current Source inspection = PASS
- Mother source inspection = PASS
- Published Browser E2E = OPEN / UNVERIFIED

لا يجوز تحويل أي من الحالات الثلاث الأولى إلى Browser PASS.

## 19. المنافسة وما لا يجب إدخاله الآن

المقارنة السابقة مع Odoo وDynamics وSAP وDaftra وManager.io تدعم أن فصل:
- vehicle asset
- driver/operator
- movement
- custody
- reporting
هو اتجاه معماري طبيعي للأنظمة المؤسسية.

لكن هذه الجولة لا تضيف عقودًا جديدة مثل:
- lot/serial/expiry
- formal approvals
- attachments
- in-transit stock
- cost/km
- fuel economics
- advanced trip costing

هذه عناصر roadmap مستقلة.

## 20. Closure Matrix

| البند | الحالة |
|---|---|
| Vehicle master | CLOSED |
| Mobile Branch | CLOSED |
| Direct Sales Rep identity | CLOSED |
| DirectSale no longer tied to vehicle.driver_id | CLOSED / PRODUCTION |
| custodian_user_id persisted at CREATE | CLOSED / PRODUCTION |
| Draft vehicle/rep rebind | CLOSED / E2E |
| Bind replay idempotency | CLOSED / E2E |
| DirectSale SEND | CLOSED / E2E |
| Physical stock | CLOSED / E2E |
| Inventory log | CLOSED / E2E |
| Driver custody ledger | CLOSED / E2E |
| G/L effect at loading stage | CLOSED / zero by contract |
| main.html | NO PATCH REQUIRED |
| New Edge Function | NOT REQUIRED |
| QA residue | 0 |
| Browser authenticated E2E | OPEN / UNVERIFIED |

## 21. Self Audit

### ما تم إثباته
- Production vehicle rows.
- driver_id = NULL للمركبات الحالية.
- historical DirectSale custodian convergence.
- current custodian trigger.
- current create/update Core.
- سبب العطل الأول.
- سبب العطل الثاني.
- تنفيذ migration الأول في Production.
- تنفيذ migration الثاني في Production.
- CREATE/BIND/REPLAY/SEND E2E.
- physical stock delta.
- inventory_log.
- driver ledger.
- zero G/L delta.
- rollback cleanup.
- current main.html inspection.
- عدم الحاجة إلى تعديل Mother في هذه النقطة.

### ما لم يثبت
- authenticated Browser E2E على الـpublished artifact.

### ما لم يتم تغييره
- main.html
- Fleet Control Plane
- fleet_query
- vehicle_operation_candidates
- post_stock_movement
- DirectReturn driver coupling
- Van Sales
- أي Edge Function جديدة

## 22. إرشاد الجلسة التالية

ابدأ من CURRENT GIT الحالي، وليس من أي hash داخل تقرير أقدم.

ثم:
1. اقرأ Report336 كاملًا.
2. تحقق من آخر System HEAD وParent.
3. تحقق من Mother HEAD والـmain.html blob.
4. تحقق من Production definitions التالية:
   - create_manual_stock_voucher_atomic_core_12_20260828
   - update_manual_stock_voucher_atomic
   - enforce_stock_voucher_custodian
   - fleet_command_atomic
   - fleet_query
5. لا تعيد إدخال vehicle.driver_id = DirectSale Rep.
6. لا تعيد تطبيق Report334.
7. لا تعدل main.html دون contradictory current-source evidence.
8. لا تنشئ Edge Function جديدة لهذه القدرة.
9. إذا توفر Browser runtime ابدأ مباشرة من published artifact identity ثم authenticated E2E.
10. اجعل أي تقرير جديد مبنيًا على snapshot واحد متزامن من Production.

## 23. Final Status

DIRECTSALE OPERATION-LEVEL VEHICLE/REP FLEXIBILITY
= CLOSED / PRODUCTION E2E VERIFIED

PHYSICAL STOCK CENTRALIZATION
= CLOSED

CUSTODY + DRIVER LEDGER EFFECT
= VERIFIED

MOTHER main.html
= NO NEW PATCH REQUIRED

BROWSER PUBLISHED RUNTIME
= OPEN / UNVERIFIED
