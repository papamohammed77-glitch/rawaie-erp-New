# Report294 — WAREHOUSE VOUCHERS / CURRENT REALITY & DEPLOYMENT FORENSIC CLOSURE
## تاريخ الجلسة
2026-09-21

## 1. EXECUTIVE RESULT

هذه الجلسة بدأت من آخر حالة مثبتة في RAWAEA ERP ولم تُعد تنفيذ أي Closure سبق إغلاقه.

النتيجة التنفيذية:

- ملف الهدف الحالي في Git:
  `companies/company-1/warehouse/vouchers.html`
  موجود بالفعل بالوظائف المطلوبة.
- لا يوجد تعديل جديد مطلوب داخل `vouchers.html` لهذه النقطة.
- لا يوجد تعديل على `main.html`.
- لا يوجد تعديل على `van-sales.html`.
- لا يوجد إنشاء Edge Function جديد.
- Production الحالية لمسار الأذونات المخزنية متوافقة مع العقد المركزي الحالي.
- المطلوب في الـNew Voucher Workspace موجود بالفعل:
  - طي/توسيع الجزء العلوي.
  - اختيار كمية مباشرة من Modal تفاصيل الصنف.
  - +/- لكمية الصنف.
  - تمرير الكمية إلى السلة بدل إجبار الكمية = 1.
  - حفظ الإذن من خلال المسار الحالي الموجود وليس Writer مخزني جديد.
- الفجوة التي بقيت مفتوحة ليست فقدانًا للوظيفة في المصدر، بل عدم وجود دليل نشر حديث يطابق Git الحالي مع البيئة المنشورة.
- Browser E2E authenticated لم يُغلق؛ لا يجوز تحويل Source PASS إلى Browser PASS.

الحالة:
**CURRENT SOURCE = PASS**
**PRODUCTION BACKEND CONTRACT = PASS**
**NEW VOUCHER UX IN SOURCE = PASS**
**BROWSER E2E = OPEN**
**CURRENT DEPLOYMENT IDENTITY = NOT PROVEN**

---

# 2. AUTHORITATIVE CURRENT BASELINE

## System Repository

Repository:

`papamohammed77-glitch/rawaie-erp-New`

Current HEAD عند بداية هذه الجلسة:

`0abea914a4a385b888e2405dfa9eede5bd07a7f9`

Immediate parent:

`8f6da00213bcd7ea0b9e074b69fb41894f65dae6`

HEAD message:

`state: record Report293 warehouse vouchers UI closure`

هذا الـHEAD هو آخر حالة موثقة قبل إنشاء هذا التقرير.

## Mother / Frontend Repository

Repository:

`papamohammed77-glitch/erp-frontend`

Current target commit:

`0115399c79d5a9fc5ef9c92450cc42381d560f22`

Parent:

`4f4afdc102fe6293d9755a134bc692d8f44bb43f`

Target file blob:

`1bf0382d45bcc06f524eefccc962abe6dcbbe4f3`

Target file:

`companies/company-1/warehouse/vouchers.html`

Van Sales blob:

`8d61382a8e0025a0d079e71dd94f33d106d9088e`

Mother `main.html`:
**لم يتم تعديله.**

Van Sales:
**لم يتم تعديله.**

---

# 3. HISTORICAL RECONSTRUCTION — ROLE OF MANUAL STOCK VOUCHERS

المصدر التاريخي:

`rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`

العقد التاريخي يثبت أن Manual Stock Vouchers ليست Order/Runsheet engine.

دورها هو معالجة الحركات المخزنية غير المرتبطة مباشرة بدورة Order/Runsheet.

الأنواع التاريخية:

- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

الدورة الأساسية:

Draft
→
Sent
→
Received / Completed

أو:

Draft
→
Cancelled

معنى DirectSale:

Branch
→
Vehicle Mobile Stock

وهذه ليست عملية بيع للعميل.

إنها تسليم عهدة مخزنية للسيارة قبل أن ينفذ تطبيق Van Sales عملية البيع الفعلية.

معنى DirectReturn:

Vehicle Mobile Stock
→
Branch

وهذه دورة مستقلة عن Customer Order/Runsheet.

بالتالي:

**Warehouse Vouchers = Stock Custody / Transfer / Adjustment Control**

بينما:

**Van Sales = Customer Sale / Invoice / Vehicle Stock Sale**

ولا يجوز دمج المحركين في Application واحد أو إنشاء Physical Stock Engine ثانٍ.

---

# 4. INTEGRATION WITH THE MOTHER SYSTEM

النظام الأم يتحكم في الـnavigation / permissions / module visibility.

التطبيق المنفصل:

`warehouse/vouchers.html`

يمثل شاشة التنفيذ التشغيلية الخاصة بالأذونات المخزنية.

الربط الحالي الصحيح:

Mother
→
Warehouse Vouchers App
→
existing authenticated capability wrappers / RPC
→
central stock movement engine

Physical movement:

PHYSICAL MOVEMENT
→
public.post_stock_movement
→
stock_branches
+
inventory_log

ولا يوجد في هذه الجلسة أي Parallel Stock Engine.

---

# 5. INTEGRATION WITH VAN SALES

المصدر الحالي لـVan Sales:

`companies/company-1/sales/van-sales.html`

Current blob:

`8d61382a8e0025a0d079e71dd94f33d106d9088e`

Van Sales الحالي لا يستخدم Manual Voucher كبديل لفاتورة البيع.

الدورة الصحيحة:

1. Warehouse Vouchers:
   DirectSale
   Branch → Vehicle

2. Vehicle يصبح Mobile Stock Container مستقلًا.

3. Van Sales:
   Customer
   +
   Invoice
   +
   Payment
   +
   Sale from Vehicle Stock

4. مسار البيع الحالي يستخدم:
   `save-sales-invoice`

وبالتالي لا يجب جعل `vouchers.html` ينفذ Customer Sale بدلاً من Van Sales.

هذا الفصل المعماري محفوظ.

---

# 6. CURRENT vouchers.html — FORENSIC SOURCE CHECK

الـblob الحالي:

`1bf0382d45bcc06f524eefccc962abe6dcbbe4f3`

عدد الأسطر:

1826

عدد الأحرف التقريبي:

92.5K

Complete embedded JavaScript syntax parse:

**PASS**

تم التحقق من وجود:

- `toggleTopPanel:function`
- `wsTopPanel`
- `wsTopToggle`
- `add:function(code,requestedQty)`
- `itemDetails:function`
- `setDetailDraftQty:function`
- `adjustDetailDraftQty:function`
- `addFromDetail:function`
- `changeDetailCartQty:function`
- `renderCart:function`
- `inventory_control`
- `VOUCHER_AUDIT`
- `create-stock-voucher`
- `send-stock-voucher`
- `receive-stock-voucher`
- `complete-stock-voucher`
- `cancel-stock-voucher`
- `RW_SW.register('../sw.js')`

---

# 7. REQUESTED UI #1 — TOP PANEL COLLAPSE / EXPAND

المطلوب:

زر طي/توسيع القائمة العلوية في New Voucher Workspace لإتاحة مساحة أكبر لاختيار الأصناف.

هذا موجود بالفعل.

الدالة:

`toggleTopPanel:function()`

وتتحكم في:

`wsTopPanel`

و:

`wsTopToggle`

الحالة:

Expanded
↔
Collapsed

مع تحديث:

`aria-expanded`

والنص:

`توسيع الخيارات`

أو:

`طي الخيارات`

لا يوجد نقص جديد مثبت هنا.

**لا تعاد هذه العملية.**

---

# 8. REQUESTED UI #2 — DIRECT QUANTITY SELECTION

المطلوب:

تحديد الكمية قبل إضافة الصنف إلى سلة الإذن كما في Van Sales.

هذا موجود.

الدالة:

`itemDetails:function(id)`

تفتح Modal تفاصيل الصنف وتحتوي على:

- available quantity
- cart quantity
- input quantity
- minus
- plus
- add-to-cart

الحقل:

`detailQtyInput`

الدوال:

`setDetailDraftQty:function(value)`

`adjustDetailDraftQty:function(delta)`

`addFromDetail:function()`

والإضافة أصبحت:

`add:function(code,requestedQty)`

بدلاً من إجبار:

`qty = 1`

هذا هو الإصلاح الجراحي الصحيح.

---

# 9. REQUESTED UI #3 — CART QUANTITY CONTROL

المطلوب:

بعد الإضافة إلى السلة يمكن التحكم في الكمية.

هذا موجود:

`changeDetailCartQty:function(code,delta)`

و:

`inc`

و:

`dec`

والسلة تعرض:

- الكمية
- المتاح قبل
- المتاح المتوقع بعد

وبذلك لا يوجد نقص كمي واضح في Workspace الحالي بالنسبة للطلب المحدد.

---

# 10. WHY THE REQUEST MAY STILL APPEAR BROKEN IN THE PUBLISHED APP

هذا الجزء هو أهم نتيجة جنائية في الجلسة.

المصدر الحالي يحتوي الإصلاحات.

Commit:

`4f4afdc102fe6293d9755a134bc692d8f44bb43f`

ثم إصلاح escaping:

`0115399c79d5a9fc5ef9c92450cc42381d560f22`

والـblob الحالي:

`1bf0382d45bcc06f524eefccc962abe6dcbbe4f3`

لكن سجل النشر المتاح في GitHub لـCloudflare يثبت Deployments قديمة فقط مرتبطة بcommit:

`6afd68b360b85a18ec9b3638977d7578153199b2`

في يونيو 2026.

كما أن Cloudflare Worker configuration الموجود في PR #1 ما زال PR مفتوحًا، وليس لدينا في Git الحالي دليل يثبت أن:

`0115399...`

هو artifact المنشور حاليًا.

ولا توجد أداة تنفيذ Workflow متاحة في هذه الجلسة لبدء Browser E2E يدويًا على GitHub.

إذن:

### ما ثبت

**Current Git contains the fix.**

### ما لم يثبت

**Current public deployment serves the same current Git blob.**

### الاستنتاج الحذر

إذا كانت البيئة المنشورة ما زالت تعرض السلوك السابق رغم وجود الإصلاح في Git، فإن أول boundary يجب حسمه هو:

**DEPLOYMENT DRIFT**

وليس إعادة كتابة `vouchers.html`.

لا يجوز تسجيل هذا كحقيقة نهائية بنسبة 100% قبل الحصول على Deployment Identity حديثة تربط الـpublished artifact بالـblob الحالي.

---

# 11. CURRENT PRODUCTION — SAME-MOMENT SNAPSHOT

Production Supabase:

`fiilmooggumokxanwiyx`

Fresh Production snapshot:

`2026-09-21 18:20:22.413986+00`

النتائج:

- companies = 1
- branches = 3
- items = 17
- manual stock vouchers = 1
- stock_voucher_operations = 1
- inventory_log = 6
- audit_log = 2034
- orders = 0
- runsheets = 0
- vehicles = 1

Company:

`00000000-0000-0000-0000-000000000001`

Name:

الروائع

Current item 1001:

`7cf845d8-34b9-47d1-9b7f-d9f1f597dbf8`

Current BR-01 stock:

2.0000

No current bad company/branch relation was detected in the verified company-scoped stock check.

---

# 12. CURRENT MANUAL VOUCHER PRODUCTION STATE

Current persistent voucher:

`IN-1`

Type:

DirectSale

Status:

Cancelled

From:

BR-01

To:

VEH-TEST-260921

Custodian:

current persisted voucher custodian user

Details:

- 1001 × 1
- 1003 × 1
- 1004 × 1

Operation registry:

`DEMO-DS-260921-01`

No new Production voucher was created in this session.

No Production stock mutation was required in this session.

---

# 13. CURRENT EDGE / RPC PATH

لا يوجد Edge Function جديد.

Current relevant capabilities:

- `create-stock-voucher` — current deployed version 10
- `send-stock-voucher` — current deployed version 20
- `receive-stock-voucher` — current deployed version 22
- `complete-stock-voucher` — current deployed version 4
- `cancel-stock-voucher` — current deployed version 4

المسار الحالي:

Edge capability wrapper
→
authenticated user/company context
→
existing RPC
→
central movement/core

وهذا يحقق قيد المشروع الحالي:

**No new Edge Function**

ولا توجد حاجة إلى إنشاء Function جديدة لتغطية الـUI المطلوب.

---

# 14. SECURITY / TENANT CONTRACT

Current Production database confirms:

`items.item_code`

عليه:

`UNIQUE]

على مستوى Item Master الحالي.

و:

`stock_branches`

عليه:

`UNIQUE(branch_id,item_id)`

و:

`stock_branches.branch_id`

مرتبط بـ:

`branches.id`

و:

`stock_branches.item_id`

مرتبط بـ:

`items.id`

والـRPC الحالي يستعمل company/user/branch validation.

لا يوجد في هذه الجلسة سبب يبرر إعادة بناء Tenant layer.

---

# 15. AUDIT CONTRACT

Production الحالية تحتوي على:

`audit_log`

والـstock voucher audit trigger:

`trg_audit_stock_vouchers`

والـtrigger function:

`fn_audit_trigger()`

المسار الحالي يحفظ:

- actor email
- action
- table
- record id
- old data
- new data
- timestamp

ولا يوجد نقص مثبت يحتاج إلى إنشاء Audit Engine جديد لهذا التبويب.

---

# 16. COMPETITIVE GAP ANALYSIS

تمت مراجعة النمط الوظيفي مقابل المصادر الرسمية:

Odoo:
- Inventory adjustments
- barcode operations
- product quantity entry
- +/- quantity behavior

Dynamics 365:
- Movement
- Inventory adjustment
- Transfer
- Item arrival
- Counting
- From/To inventory dimensions

SAP:
- Goods movement
- Goods receipt
- Goods issue
- Stock transfer
- Material document traceability

Daftra:
- detailed inventory transactions
- transfer
- available before/after
- warehouse filtering
- stocktaking
- print/export

Manager:
- inventory transfer
- inventory write-on
- inventory write-off
- item and quantity handling
- from/to location model

الحالة الحالية لـRAWAEA تغطي في هذه الشاشة:

- product selection
- search
- barcode
- category filtering
- available stock
- available before
- expected after
- quantity entry
- quantity increment/decrement
- cart review
- source/destination routing
- direct-sale representative/vehicle linkage
- audit
- operation identity
- central stock movement

---

# 17. COMPETITIVE EXTENSIONS — NOT TO BE INVENTED HERE

هناك قدرات موجودة في أنظمة منافسة، لكن لا توجد حاليًا Business Contract موثقة وSchema Contract كافٍ لحقنها في نفس Closure Unit.

لذلك لا تُعتبر Bugs حالية.

Potential future Closure Units:

- lot / serial / expiry
- richer approval workflows
- print/export package
- in-transit stock
- advanced barcode counting
- richer warehouse audit trail
- dedicated stocktaking workflow

هذه ليست جزءًا من الإصلاح الحالي.

إدخالها الآن سيخلق Contract Debt وليس Closure.

---

# 18. SURGICAL PATCH DELIVERY

## Target file

`companies/company-1/warehouse/vouchers.html`

## PATCH STATUS

**NONE REQUIRED FOR THE REQUESTED FEATURES**

السبب:

الإصلاحات المطلوبة موجودة بالفعل في الـCurrent Source.

المواضع المرجعية الحالية:

- `toggleTopPanel:function()`
- `newWorkspace:function()`
- `renderWorkspace:function()`
- `add:function(code,requestedQty)`
- `itemDetails:function(id)`
- `setDetailDraftQty:function(value)`
- `adjustDetailDraftQty:function(delta)`
- `addFromDetail:function()`
- `changeDetailCartQty:function(code,delta)`

### Owner action

إذا كانت البيئة التي يراها المستخدم لا تحتوي هذه الوظائف:

لا تُنشئ Patch جديدًا.

لا تعيد كتابة هذه الدوال.

لا تخلط الإصلاح مع نسخة أقدم.

قم بتشغيل/نشر الـartifact الذي يطابق:

`erp-frontend/main`

Commit:

`0115399c79d5a9fc5ef9c92450cc42381d560f22`

والـtarget blob:

`1bf0382d45bcc06f524eefccc962abe6dcbbe4f3`

ثم أعد Browser E2E.

---

# 19. CRITICAL NON-ACTIONS

لم يتم في هذه الجلسة:

- تعديل `main.html`
- تعديل `vouchers.html`
- تعديل `van-sales.html`
- إنشاء Edge Function جديدة
- إنشاء Physical Stock engine
- إعادة تطبيق V-03
- إعادة تطبيق V-04
- إعادة تطبيق V-05
- إعادة تطبيق V-06
- إعادة تطبيق V-07
- إعادة تطبيق V-08
- إعادة تنفيذ DirectSale production migration
- إعادة تنفيذ DirectReturn production migration

هذا مقصود لمنع إعادة فتح Closed Units.

---

# 20. FINAL SELF-AUDIT

| Area | Status |
|---|---|
| Historical role reconstructed | PASS |
| Mother integration understood | PASS |
| Van Sales integration understood | PASS |
| Current vouchers source opened | PASS |
| Current source syntax | PASS |
| Collapse/Expand feature in source | PASS |
| Direct quantity modal in source | PASS |
| Cart quantity controls | PASS |
| Central stock integration | PASS |
| Current Production snapshot | PASS |
| Existing Edge/RPC path | PASS |
| No new Edge Function | PASS |
| No main.html change | PASS |
| No van-sales change | PASS |
| Requested vouchers source patch | NONE REQUIRED |
| Current published deployment identity | OPEN |
| Authenticated Browser E2E | OPEN |
| Visual acceptance | OPEN |

---

# 21. WHAT WAS PROVED

1. المطلوب الأساسي في Modal الأذونات المخزنية تم تنفيذه بالفعل في Current Git.
2. التنفيذ موجود في blob الحالي وليس مجرد تقرير تاريخي.
3. الـquantity UX أصبحت قابلة للإدخال والتعديل قبل وبعد الإضافة.
4. الـtop workspace أصبح قابلًا للطي والتوسيع.
5. الـcart يحافظ على available-before/expected-after.
6. Backend الحالي للأذونات يستعمل الـRPC/core path الحالي.
7. لا توجد حاجة لإنشاء Edge Function جديدة.
8. Physical Stock ما زال مركزيًا عبر `post_stock_movement`.
9. Van Sales لم يتحول إلى Warehouse Voucher engine.
10. لا توجد حاجة لإعادة بناء الـapplication من الصفر.

---

# 22. WHAT WAS NOT PROVED

لم يثبت في هذه الجلسة:

- أن الـartifact المنشور حاليًا في Cloudflare يطابق blob:
  `1bf0382d45bcc06f524eefccc962abe6dcbbe4f3`
- authenticated Browser E2E حقيقي على النسخة المنشورة.
- أن المستخدم النهائي يرى نفس الـCurrent Git build في المتصفح.

لذلك لا يجوز تسجيل:

**FULL UI = 100% CLOSED**

حتى يتم إثبات هذه الثلاثة.

---

# 23. ROOT CAUSE — FINAL FORM

العيب الذي كانت تدور حوله المهمة تم تشخيصه إلى Boundary محددة:

## Code layer

Current Source:
**Correct / already implemented**

## Database layer

Current Production:
**Compatible / no new backend change required**

## Deployment layer

Current evidence:
**Not synchronized/proven against current frontend HEAD**

### Therefore

المشكلة ليست مثبتة كـmissing code في `vouchers.html`.

الـblocker المتبقي هو:

**CURRENT SOURCE → CURRENT DEPLOYMENT IDENTITY → BROWSER RUNTIME**

والـclosure الصحيح التالي ليس Patch جديدًا للـUI، بل إثبات النشر ثم Browser E2E.

---

# 24. EXACT NEXT SESSION START

ابدأ بهذا الترتيب ولا تعيد أي Closure سابق:

1. Snapshot Production.
2. Verify System HEAD + parent.
3. Verify Mother HEAD + parent.
4. Verify `vouchers.html` blob.
5. Verify deployed artifact identity.
6. Run authenticated Browser E2E.
7. Test:
   New Voucher
   → DirectSale
   → collapse
   → expand
   → item detail
   → quantity = 5
   → add to cart
   → verify 5
   → +
   → -
8. Save Draft.
9. Send.
10. Verify resulting voucher.
11. Re-read audit.
12. Verify inventory movement.
13. Snapshot Production immediately at the end.
14. Only then close Browser E2E.

Do not:
- modify `main.html`
- modify `van-sales.html`
- recreate existing UI functions
- create another Edge Function
- reopen closed Writer/Closure Units.

---

# 25. GOVERNANCE HANDOFF

المساعد التالي يجب أن يبدأ من:

CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

ولا يعتبر أي تقرير تاريخي حقيقة حالية بمفرده.

الحقيقة الحالية لهذه الوحدة:

**VOUCHERS SOURCE = CURRENT**

**PRODUCTION CORE = CURRENT**

**DEPLOYMENT IDENTITY = OPEN**

**BROWSER E2E = OPEN**

وهذا هو الحد الصحيح للإغلاق في هذه اللحظة.

---

## Sources / Evidence

System:
`papamohammed77-glitch/rawaie-erp-New`

Frontend:
`papamohammed77-glitch/erp-frontend`

Historical voucher architecture:
`papamohammed77-glitch/rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`

Current governance:
`doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`

Current state:
`CURRENT_STATE.md`

Relevant official competitive sources:

Odoo:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

Dynamics 365:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

SAP:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html

Daftra:
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

Manager:
https://www2.manager.io/guides/10707
