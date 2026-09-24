# Report334 — إصلاح جراحي لربط المركبة بالعملية في النظام الأم
## RAWAEA ERP — Forensic Production Closure — 2026-09-24

### 1. نطاق المهمة

Closure Unit:
Mother `main.html` → `RW_FleetManagement` → Vehicle Details → `ربط المركبة بالعملية`.

المطلوب كان استكمال الوظيفة الموجودة دون إعادة بنائها، مع:
- إبقاء RUNSHEET كما هو.
- إضافة اختيار الفرع لتحويل الفرع.
- إظهار رقم المستند والمرجع للمستند المختار.
- إظهار رقم المستند والمرجع تلقائيًا للبيع المباشر.
- الحفاظ على الفصل بين السائق ومندوب التوصيل ومندوب المبيعات.
- عدم إنشاء Edge Function جديدة.
- إبقاء الحركة المخزنية تحت `post_stock_movement`.
- عدم إجراء أي تعديل مباشر على Mother `main.html` من جانب المساعد.

---

## 2. هرم مصادر الحقيقة

تمت إعادة بناء الحالة من المصادر الأولية، وليس من التقارير السابقة وحدها:

### System Git
Repository:
`papamohammed77-glitch/rawaie-erp-New`

HEAD الذي تم التحقق منه:
`d6e497afbb394c4f24fc7648adb4fe2a3e610ee9`

Parent:
`247feb5067c690e3ceca668c1b048ba56df3d856`

### Mother Git
Repository:
`papamohammed77-glitch/erp-frontend`

HEAD:
`b1820141d49dbe9b82e339cd7ccb05781f39d81a`

Parent:
`7915275b87c74f1b249a1da7b3732a16511aae38`

Current `companies/company-1/main.html` blob:
`c521d84fd96143b435e432e135e2d8a967acf60e`

لم يتم تعديل Mother `main.html` مباشرة من جانب هذا التنفيذ.

### Governance
تمت قراءة:
`MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`

والقاعدة التي تم الالتزام بها:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

التقارير استُخدمت كسياق تاريخي، ولم تُعتبر مصدر حقيقة نهائي.

---

## 3. ماذا كان موجودًا قبل هذا الإصلاح

الـcontrol plane كان موجودًا ومغلقًا قبل هذا الـclosure:

- `fleet_command_atomic`
- `fleet_query`
- command: `VEHICLE_OPERATION_BIND`
- view: `vehicle_detail`
- view: `vehicle_operation_candidates`

العقود المثبتة:

### RUNSHEET
`runsheets.vehicle_id`
+
`runsheets.driver_id`
+
`runsheets.deliverer_id`

### BRANCH_TRANSFER
`stock_vouchers.vehicle_id`
+
`stock_vouchers.driver_id`

### DIRECT_SALE
`stock_vouchers.to_type='Vehicle'`
+
`stock_vouchers.to_id`
+
`stock_vouchers.custodian_user_id`

لا يوجد ولا يجب إنشاء `vehicle_id` بديل للبيع المباشر.

---

## 4. السبب الجذري المثبت

المشكلة لم تكن غياب control plane.

المشكلة كانت في Consumer / Read Model:

### Production Read Model القديم
`vehicle_operation_candidates` كان يعيد لتحويلات الفروع:
- voucher_code
- status
- reference
- vehicle_id
- driver_id

لكن لم يكن يعيد:
- from_branch_id
- to_branch_id
- from_branch_name
- to_branch_name

كما لم يكن يعيد قائمة الفروع المتاحة للنظام الأم لكي يعمل اختيار الفرع داخل نافذة الربط.

أما Mother `main.html` الحالية فكانت تعرض المستند فقط بصورة مختصرة، بدون:
- فرع
- رقم مستند واضح
- Reference field مستقل
- Branch filter
- auto-population للمرجع.

لذلك كان الـbackend قادرًا على تنفيذ الربط، لكن تجربة الربط في Mother لم تكن تقدم السياق التشغيلي الكامل المطلوب.

---

## 5. التصحيح Production

تم تحديث الدالة الموجودة فقط:

`public.fleet_query`

داخل:
`vehicle_operation_candidates`

Migration:

`20260924145700_extend_fleet_vehicle_operation_candidates_document_branch_context`

النتيجة:

1. إضافة `branch_id` اختياري إلى payload الخاص بالـcandidate query.
2. التحقق أن الفرع:
   - يتبع نفس الشركة.
   - نشط.
3. إعادة قائمة الفروع النشطة في `branches`.
4. توسيع Transfer projection ليعيد:
   - `from_branch_id`
   - `to_branch_id`
   - `from_branch_name`
   - `to_branch_name`
   - `reference`
5. عند تحديد الفرع:
   يتم ترشيح المستندات التي يكون فيها الفرع هو المصدر أو الوجهة.
6. لم يتم إنشاء Edge Function جديدة.
7. لم يتم إنشاء Physical Stock engine جديد.
8. لم يتم تغيير command contract.
9. لم تتم أي حركة مخزنية من وظيفة الربط.

ملف Migration تم تثبيته في Git:

`supabase/migrations/20260924145700_extend_fleet_vehicle_operation_candidates_document_branch_context.sql`

Commit:
`df3bc5a5e9ee8fd9a86acaf1d5e1c3fbff54e7f4`

---

## 6. Mother main.html — التغيير المطلوب من المالك

الـMother لم تُكتب من المساعد.

تم تحديد إصلاحين جراحيين فقط:

### PATCH-334-01
العنصر:
`function operationBlock(title, rows, type)`

مكانه الحالي:
حوالي السطر 29099.

الهدف:
إظهار `reference` داخل بطاقة العملية المرتبطة.

### PATCH-334-02
العنصر:
`async function openVehicleOperationLinkForm()`

مكانه الحالي:
يبدأ حوالي السطر 29180 وينتهي مباشرة قبل:
`async function openVehicleEdit(id){`

الهدف:
- branch selector لتحويل الفرع.
- branch-filter query.
- document number read-only.
- reference read-only.
- auto-fill للوثيقة والمرجع.
- إبقاء RUNSHEET دون تغيير في contract.
- إبقاء DirectSale على `to_id + custodian_user_id`.
- إبقاء driver / delivery rep / direct-sales rep منفصلين.

تم فحص البديل الجراحي داخليًا:
- JavaScript parse = PASS.
- brace balance = 0.
- لا يحتاج تعديل `command()`.
- لا يحتاج تعديل API exposure.
- لا يحتاج إعادة بناء زر الربط.

---

## 7. Production E2E — Binding Layer

تم تنفيذ اختبار E2E معزول داخل Transaction ثم `ROLLBACK`، لضمان عدم تلويث Production.

### Candidate Read Model
تم إثبات:
- branches_count = 4
- transfer_docs = 3
- direct_sale_docs = 1 في fixture مؤقتة.
- Transfer reference ظهر.
- Transfer source/target branch names ظهرت.
- DirectSale reference ظهر.

### Branch filter
تم تمرير فرع BR-01 إلى `vehicle_operation_candidates`.

النتيجة:
- جميع Transfer rows العائدة كانت مرتبطة بالفرع المحدد.
- `all_transfer_docs_match_branch = true`.

### Invalid branch guard
تم تمرير UUID غير تابع للشركة/غير صالح.

النتيجة:
رفض صحيح:
`فرع التصفية غير موجود أو غير نشط للشركة`

### BRANCH_TRANSFER bind
PASS:
- vehicle persisted.
- driver persisted.
- voucher status بقي كما هو.
- replay بنفس Operation ID أعاد:
`duplicate=true`

### DIRECT_SALE bind
PASS:
- vehicle identity استعملت `to_id`.
- direct sales representative استعمل `custodian_user_id`.
- replay بنفس Operation ID أعاد:
`duplicate=true`

### Physical Stock
قبل/بعد binding:
- لا توجد حركة stock جديدة.
- allocated_qty لم يتغير.
- binding لا ينفذ Physical Stock.

### Accounting
قبل/بعد binding:
- journal_entries لم تتغير.
- journal_lines لم تتغير.
- driver_ledger لم تتغير.

الربط وحده لا يسجل إيرادًا ولا تكلفة ولا نقلًا ولا حركة مالية؛ هذه المسؤوليات تبقى في عمليات التشغيل الفعلية اللاحقة.

### Cleanup
بعد `ROLLBACK`:
- QA vouchers = 0
- QA audit residue = 0
- QA operation registry residue = 0

---

## 8. Production Snapshot — نفس نافذة التحقق

Snapshot:
`2026-09-24T14:08:08.188883+00:00`

- active companies = 1
- company branches = 4
- vehicles = 2
- runsheets = 0
- stock_vouchers = 2
- inventory_log = 25
- journal_entries = 10
- journal_lines = 16
- driver_ledger = 4
- QA fleet vouchers = 0
- QA fleet registry rows = 0

آخر migration:
`20260924145700_extend_fleet_vehicle_operation_candidates_document_branch_context`

---

## 9. الفصل الوظيفي للهوية

تم الحفاظ على الفصل المطلوب:

| الوظيفة | هوية المصدر |
|---|---|
| المركبة | vehicle_id |
| السائق | driver_user_id / driver_id |
| مندوب التوصيل | delivery_rep_user_id / deliverer_id |
| مندوب البيع المباشر | direct_sales_rep_id / custodian_user_id |
| مستند التحويل | voucher_id |
| مستند البيع المباشر | voucher_id |
| الفرع في نافذة التحويل | branch_id filter |

لا يوجد دمج بين السائق ومندوب البيع.

---

## 10. لماذا لم نعدّل عناصر أخرى

لم يتم تعديل:
- `command()`
- `fleet_command_atomic`
- `VEHICLE_OPERATION_BIND`
- RUNSHEET contract
- DirectSale contract
- Physical Stock engine
- Voucher write engine
- Inventory adjustment
- Accounting writers
- applications التشغيلية

لأن الأدلة الأولية أثبتت أنها خارج سبب الخلل الحالي.

---

## 11. Competitive Review

تمت مراجعة أنماط Fleet/Transportation لدى:
- Odoo
- Microsoft Dynamics
- SAP Transportation Management
- Daftra
- Manager.io

النتيجة ليست إضافة وظائف تجميلية إلى نافذة الربط، بل الحفاظ على الحدود الصحيحة:

Mother ERP:
Control Plane / Governance / Monitoring.

Operational PWAs:
Execution.

Database/RPC:
Canonical business rules.

والوظائف المرشحة للمراحل التالية وليست جزءًا من هذا العيب:

- Odometer start/end per operation.
- Distance per operation.
- Fuel allocation.
- Maintenance allocation.
- Toll allocation.
- Planned vs actual trip cost.
- Cost per kilometer.
- Cost per runsheet.
- Cost per transfer.
- Cost per direct sale.
- Capacity utilization.
- Unified vehicle operational cost center.

هذه capabilities مستقبلية وليست Defects حالية، ولذلك لم تُخلط مع هذا Closure.

---

## 12. ما تم إثباته

- Fleet operation binding control plane قائم.
- Candidate read model أصبح قادرًا على تزويد Mother بالفرع والمستند والمرجع.
- branch filtering يعمل مع company guard.
- Transfer binding يعمل.
- DirectSale binding يعمل.
- Operation replay idempotent.
- Binding لا يحرك stock.
- Binding لا يكتب GL.
- Binding لا يكتب driver ledger.
- QA residue = 0 بعد rollback.
- لم يتم إنشاء Edge Function جديدة.
- لم يتم إنشاء Physical Stock writer جديد.

---

## 13. ما لم يتم إثباته بعد

يبقى فقط:
- Owner application of PATCH-334-01 وPATCH-334-02 في Mother `main.html`.
- نشر الـMother بعد التعديل.
- Browser E2E authenticated عبر الواجهة المنشورة.
- Console/Network evidence من المتصفح بعد النشر.

هذه ليست مشكلة Production control plane؛ إنها مرحلة Consumer deployment المتبقية.

---

## 14. Continuity Instructions — للجلسة التالية

ابدأ من هذه السلسلة فقط:

1. اقرأ CURRENT_STATE من Git ثم تحقق من HEAD الحالي.
2. تحقق من Mother HEAD وBlob الحالي.
3. لا تعِد فحص أو إصلاح Fleet Production control plane إلا إذا ظهرت primary evidence متناقضة.
4. اطلب من المالك تطبيق PATCH-334-01 فقط.
5. ثم PATCH-334-02 فقط.
6. لا تعدّل أي جزء آخر من `main.html`.
7. Parse الملف كاملًا.
8. Commit Mother.
9. Publish Mother.
10. تحقق من served artifact.
11. نفذ Browser E2E على:
    - Branch Transfer
    - Direct Sale
    - Runsheet
12. التقط Console + Network.
13. تحقق من:
    - vehicle_detail
    - operation candidates
    - voucher fields
    - audit
    - stock
    - accounting
14. لا تفتح Closure سابقًا مغلقًا بدون دليل أولي متناقض.
15. بعد الإغلاق، حدّث CURRENT_STATE مرة أخرى.
16. لا تضف Edge Function جديدة لهذه القدرة.

### قاعدة حاكمة

لا تعتبر:
Staging PASS
أو
DB PASS

مرادفًا لـ:
Browser Production PASS

إلا بعد إثبات الاثنين منفصلين.

---
