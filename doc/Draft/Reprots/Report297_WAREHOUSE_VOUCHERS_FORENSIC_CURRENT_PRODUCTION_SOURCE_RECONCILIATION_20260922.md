# Report297 — الأذونات المخزنية / المركبة / Picker / Van Sales
## Forensic Current-State Reconciliation + Production E2E
### التاريخ
2026-09-22

> هذا التقرير لا يعتمد على التقارير السابقة كحالة حالية. تم استخدام التقارير كسجل تاريخي فقط، ثم أعيدت مطابقة النقاط محل المهمة مع CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

---

## 1. Scope Lock

النطاق الفعلي لهذه الجلسة:
- إدارة المخازن والمخزون → الأذونات المخزنية.
- الملف التشغيلي:
  `companies/company-1/warehouse/vouchers.html`
- التكامل مع:
  - النظام الأم `companies/company-1/main.html`
  - `companies/company-1/warehouse/picker.html`
  - `companies/company-1/sales/van-sales.html`
  - Supabase Production / RPC / Edge Functions
- التحقق من مشكلة ظهور المركبات في Modal إذن جديد.
- التحقق من زر إلغاء الإذن.
- التحقق من التكامل DirectSale / DirectReturn مع Vehicle Mobile Stock.
- التحقق من أن التطبيق مخصص للحركات المخزنية غير المبنية على Order/Runsheet.
- مراجعة المزايا الذهبية في Picker، خصوصًا Timer / Reopen / Cancel، وتحديد ما ينتقل معماريًا وما لا ينتقل.
- تنفيذ E2E Production transactional verification بدون ترك Test Residue.
- تحديث الحالة المرجعية للجلسة التالية.

قيود تم احترامها:
- لم يتم تعديل `main.html`.
- لم يتم تعديل `vouchers.html` مباشرة في هذا الإجراء.
- لم يتم تعديل `van-sales.html`.
- لم يتم إنشاء Edge Function جديدة.
- لم يتم إعادة إصلاح أي Closure مثبت إغلاقه.
- أي اختبار كتابي جديد على Production نُفذ داخل Transaction مع `ROLLBACK`.

---

## 2. Governance Baseline

تمت مراجعة:
- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` حتى النهاية.
- `doc/Draft/medhat/تقرير مبادئ حاكمة`.
- `doc/Draft/medhat/برومبت استكمال مهام`.
- أحدث التقارير ذات الصلة في `doc/Draft/Reprots`.

القواعد الحاكمة المستخدمة:
1. التقرير ليس حالة Production.
2. CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE هي طبقة الحقيقة.
3. دراسة التاريخ تسبق أي تغيير.
4. Business Capability هي وحدة الإغلاق.
5. لا Commit = Deployment.
6. لا Deployment = Runtime Success.
7. لا Runtime Success = Browser E2E.
8. لا يجوز إعادة إصلاح Closure مغلق.
9. Physical Stock Contract:
   `PHYSICAL STOCK MOVEMENT → post_stock_movement → stock_branches + inventory_log`.
10. `reserve_stock` Reservation Engine فقط.
11. لا New Edge Function إذا كان يمكن إغلاق القدرة عبر الموجود.
12. كل Closure يجب أن ينتهي بنتيجة Production قابلة للإثبات أو يبقى مفتوحًا.

---

## 3. CURRENT GIT — System Repository

Repository:
`papamohammed77-glitch/rawaie-erp-New`

Current HEAD:
`b2f440f1e655108a10328cb6720ff494b77c43da`

Immediate parent:
`096350cdb40fac825ffd1fa100c7480fedcff782`

طبيعة آخر Commit:
- توثيق/تحديث حالة تقريرية.
- لم يغير Business Contract للأذونات في Production.

تم الرجوع إلى Parent وليس HEAD فقط لتجنب اعتبار التغيير التوثيقي الحالي أصلًا معماريًا جديدًا.

---

## 4. CURRENT GIT — Frontend Repository

Repository:
`papamohammed77-glitch/erp-frontend`

Current HEAD:
`745a615ccd0baff09ad2619b0316e46507a862e9`

Parent:
`29cd6e08056b50545db05a4bff220424127126c5`

التغيير في HEAD الحالي:
- تعديل واحد في `companies/company-1/warehouse/vouchers.html`.
- نقل Route Selector إلى خارج `wsTopPanel`.
- هذا هو Patch Report296 الخاص بمشكلة clipping الخاصة بالـsmart menus.

الاستنتاج:
- Patch Report296 ليس Pending.
- هو مطبق فعليًا في CURRENT SOURCE.
- لا يجوز إعادة تنفيذه.

---

## 5. CURRENT SOURCE — vouchers.html

الملف الحالي:
`companies/company-1/warehouse/vouchers.html`

مؤشرات المواضع الرئيسية في النسخة الحالية:
- `loadRefs:function` — line 28.
- `cards:function` — line 284.
- `cancel:function` — line 755.
- `prepare:function` — line 771.
- `pickArr:function` — line 864.
- `pickSearch:function` — line 991.
- `pickSelect:function` — line 992.
- `renderWorkspace:function` — line 1150.
- `submit:function` — line 1370.
- `handleScan:function` — line 1656.

هذه المواضع محسوبة من CURRENT SOURCE نفسه، وليست أرقامًا من تقرير قديم.

---

## 6. Forensic Review — Vehicle Binding

### 6.1 CURRENT SOURCE

`loadRefs:function` يقرأ جدول `vehicles` مباشرة عبر:
- `id`
- `vehicle_code`
- `license_plate`
- `model`
- `driver_id`
- `status`
- `mobile_branch_id`
- `mobile_stock_enabled`

ومقيد بـ:
- `company_id = s.company`
- `status = Active`

إذن المصدر الحالي ليس قائمة نصية ولا قائمة وهمية؛ المركبة تُحل من جدول `vehicles` إلى UUID.

### 6.2 Vehicle Search

في `pickArr:function`:
- DirectSale → vehicles فقط إذا:
  - المركبة Active.
  - لها mobile branch صالح.
  - mobile stock ليس معطلًا.
  - لها Direct Sales Rep صالح.
  - الفرع المصدر صالح.
  - المندوب صالح على الفرع.
  - عند اختيار مندوب محدد يتم ربط المركبة بـ `vehicle.driver_id`.

في `pickSearch:function`:
- نوع الحقل DirectSale/Vehicle هو `vehicle`.
- البحث يتم على:
  - `vehicle_code`
  - `license_plate`
  - `model`

في `pickSelect:function`:
- يتم حفظ UUID المركبة في الحقل المخفي.
- يتم عرض كود/لوحة المركبة.
- يتم إثبات أن `vehicle.driver_id` يساوي المندوب الصحيح.
- يتم ضبط حقل المندوب إلى Readonly بعد نجاح الربط.

### 6.3 DirectReturn

في نفس المصدر:
- المركبة هي المصدر.
- المندوب يستخرج من `vehicle.driver_id`.
- الفرع الوجهة يحدد من قائمة الفروع المسموح بها للمندوب.
- المركبة يجب أن تملك Mobile Stock صالحًا.

النتيجة:
**Vehicle Binding موجود بالفعل ومتكامل.**

---

## 7. CURRENT SOURCE — Cancel Voucher

في CURRENT SOURCE:
`cards:function` تعرض زر:
`إلغاء`
للإذن في حالة Draft.

الزر يستدعي:
`App.cancel(v.voucher_code)`

و:
`cancel:function(code)`
تستدعي:
`cancel-stock-voucher`

والـEdge الحالية موجودة في Production:
`cancel-stock-voucher` — ACTIVE — current version 4.

كما تم اختبار RPC الإلغاء داخل Transaction:
- إنشاء DirectSale مؤقت.
- Cancel.
- النتيجة: `status = Cancelled`.
- ROLLBACK كامل.

النتيجة:
**ميزة إلغاء الإذن موجودة ومتصلة Backend، ولا يوجد نقص مثبت يبرر إعادة بناء زر الإلغاء.**

---

## 8. CURRENT PRODUCTION — Snapshot

Snapshot UTC:
`2026-09-22 05:59:22.015707+00`

ثم تم التحقق مرة أخرى بعد آخر E2E:
`2026-09-22 06:01:01.914602+00`

العدادات النهائية:
- companies = 1
- branches = 3
- items = 17
- vehicles = 1
- stock_vouchers = 1
- stock_voucher_details = 3
- stock_voucher_operations = 1
- inventory_log = 6
- audit_log = 2034
- orders = 0
- runsheets = 0

لم يتغير هذا الخط الأساسي نتيجة اختبارات الجلسة.

---

## 9. CURRENT PRODUCTION — Vehicle Evidence

المركبة الإنتاجية الحالية:
- vehicle_code = `VEH-TEST-260921`
- license_plate = `س ن ر 6021`
- status = `Active`
- driver_id = `111b0730-a977-4d11-bcd0-2427b178a9e5`
- mobile_stock_enabled = `true`
- mobile_branch_id = `5372503d-f638-4e7f-808d-bda585825b2f`

Mobile branch:
- branch_code = `VAN-VEH-TEST-260921`
- company_id = `00000000-0000-0000-0000-000000000001`

المندوب:
- `vansales@rawaea.com`
- role = `مندوب بيع مباشر`
- active.
- driver_id للمركبة = public user id للمندوب.

مسئول الأذونات:
- `vouchers@rawaea.com`
- active_warehouse_role = `أذونات`
- allowed branch = `BR-01`

الفرع الرئيسي:
- `BR-01`
- active.
- company-aligned.

النتيجة:
**Production نفسها تحتوي كل الكيانات المطلوبة لظهور المركبة وربطها بالمندوب والمخزن المتنقل.**

---

## 10. CURRENT PRODUCTION — RPC Contract

Production تحتوي حاليًا:
- `post_stock_movement` — overload 9 args.
- `post_stock_movement` — overload 10 args مع idempotency key.
- `create_manual_stock_voucher_atomic` — legacy 10 args.
- `create_manual_stock_voucher_atomic` — canonical 12 args مع:
  - `p_rep_id`
  - `p_operation_id`
- `create_manual_stock_voucher_atomic_core_12_20260828`
- `post_manual_stock_voucher_atomic_core_20260828`
- `send_stock_voucher_atomic`
- `cancel_manual_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`

الدوال التشغيلية الحالية ترسل Physical Movement إلى:
`post_stock_movement`

لا يوجد Physical Stock engine مستقل داخل Voucher lifecycle.

---

## 11. Production E2E — DirectSale

اختبار Transactional حقيقي على Production:

المدخلات:
- company = current company.
- type = DirectSale.
- source = BR-01.
- destination = current vehicle.
- rep = current Direct Sales Rep.
- item = 1001.
- qty = 1.
- operation_id ثابت.

الاختبار الأول:
- `create_manual_stock_voucher_atomic(12 args)`
- النتيجة:
  - success = true
  - company_id صحيح
  - rep_id صحيح
  - operation_id محفوظ
  - voucher_id صدر.
- ROLLBACK.

اختبار E2E أعمق:
1. إنشاء DirectSale مؤقت.
2. إرسال الإذن عبر `send_stock_voucher_atomic`.
3. قراءة حالته.
4. قراءة حركة `inventory_log`.
5. قراءة رصيد الفرع ومخزن السيارة.
6. ROLLBACK.

قبل وبعد الاختبار:
- Item 1001 في BR-01 عاد إلى نفس الخط الأساسي.
- Item 1001 في mobile branch عاد إلى نفس الخط الأساسي.
- لا توجد حركة `IN-2` بعد الاختبار.
- لا زادت vouchers.
- لا زادت inventory_log.

النتيجة:
**CREATE → SEND → Physical Stock integration اجتاز الاختبار المعاملي دون Test Residue.**

---

## 12. Production E2E — Cancel

داخل Transaction:
1. إنشاء DirectSale.
2. استدعاء `cancel_manual_stock_voucher_atomic`.
3. قراءة الحالة.

النتيجة:
`Cancelled`

ثم:
`ROLLBACK`

لا Test Residue.

---

## 13. سبب مشكلة ظهور المركبة — التحقيق الجنائي

### ما كان يُظن
كان يمكن تفسير عدم ظهور المركبة بأنه:
- لا توجد Vehicles.
- فشل query.
- خطأ في company scope.
- خطأ في Vehicle/Rep binding.
- خطأ في Production data.
- Edge Function ناقصة.

تم فحص هذه المسارات واحدًا واحدًا.

### ما ثبت

Production:
- المركبة موجودة.
- Active.
- لها Mobile Stock.
- لها Mobile Branch.
- لها driver_id صحيح.
- المندوب موجود.
- المندوب Active.
- الفرع موجود.
- صلاحيات الفرع موجودة.
- الـRPC يقبل Vehicle destination.
- E2E DirectSale يعمل.

CURRENT SOURCE:
- `loadRefs` يجلب المركبة.
- `pickArr` يحولها إلى قائمة Vehicle.
- `pickSearch` يبحث فيها.
- `pickSelect` يربطها بالـRep.
- `submit` يرسل `to_type='Vehicle'` و `to_id=vehicle.id`.

إذن المشكلة لم تكن Database Binding.

### Root Cause

في النسخة السابقة من `renderWorkspace:function()`:
- `s.routeHtml()` كان داخل `wsTopPanel`.
- `wsTopPanel` قابل للطي.
- CSS للـpanel كان يستخدم `overflow:hidden`.
- Smart menus الخاصة بالفرع/المندوب/المركبة كانت descendants داخل نفس panel.

عند فتح قائمة المركبات:
- القائمة تُولد فعليًا.
- لكنها تُقص داخل حدود الـpanel.
- فيظهر للمستخدم عمليًا وكأن المركبات غير موجودة.

### الإصلاح الذي أُنجز بالفعل

Commit:
`745a615ccd0baff09ad2619b0316e46507a862e9`

الإصلاح:
`s.routeHtml()` خرج من `wsTopPanel`.

نتيجة ذلك:
- Vehicle menu لم يعد طفلًا داخل clipping container.
- Route controls أصبحت مستقلة عن Top panel collapse.
- لا تغيّر في business logic.
- لا تغيّر في backend.
- لا تغيّر في vehicle contract.

**هذه النقطة مغلقة على مستوى CURRENT SOURCE.**

---

## 14. لماذا قد لا يظهر الإصلاح للمستخدم رغم أنه موجود في Git

تم التحقق من مسار النشر:

Repository README:
- Hosting = Cloudflare Pages.

Redirect:
`/vouchers → /companies/company-1/warehouse/vouchers.html`

Service Worker الحالي:
- HTML/navigation لا يتم تخزينه في Cache.
- API/runtime لا يتم تخزينه في Cache.
- Service Worker يطلب HTML من الشبكة.
- `register-sw.js` ينفذ `registration.update()` دوريًا.
- SW activation يعيد تحميل الصفحات.

إذن:
**Browser SW HTML cache ليس تفسيرًا مقبولًا للإبقاء على النسخة القديمة.**

الحالة الوحيدة التي لم يمكن إثباتها من الأدوات المتاحة:
**Published Cloudflare artifact / deployed browser runtime.**

لا توجد في هذه الجلسة أداة Cloudflare deployment runtime للتحقق من أن Pages cutover الحالي يساوي HEAD:
`745a615...`

لذلك:
- Source closure = VERIFIED.
- Production backend closure = VERIFIED.
- Deployed browser runtime = NOT VERIFIED.

ولا يجوز تحويل هذه الحالة إلى Browser E2E PASS.

---

## 15. Owner Surgical Patch Status

### الملف المحدد
`companies/company-1/warehouse/vouchers.html`

### حالة Patch المركبة

Patch Report296 موجود بالفعل.

لا يجب على Owner الآن:
- حذف أي `renderWorkspace` block.
- إعادة نقل `s.routeHtml()`.
- إعادة إصلاح clipping.
- إعادة بناء vehicle search.

**لا يوجد Surgical Patch جديد مطلوب من Owner في vouchers.html في هذه النقطة.**

إذا كانت الصفحة المنشورة تعرض النسخة القديمة:
- الإجراء المطلوب ليس تعديلًا آخر في الملف.
- الإجراء المطلوب هو نشر CURRENT GIT HEAD:
  `745a615ccd0baff09ad2619b0316e46507a862e9`

---

## 16. Picker — Historical Gold Features

تمت مراجعة `companies/company-1/warehouse/picker.html`.

المزايا المثبتة:
- `renderActiveSession()` يعرض الزمن المنقضي.
- `startTimer()` يحدث الزمن كل ثانية.
- بداية المهمة مأخوذة من `picker_start`.
- `completePicking()` يقفل دورة المهمة.
- `cancelPicking()` يلغي التحضير.
- `reopenPicking()` يعيد فتح المهمة للمستخدم صاحب المهمة بعد التحقق.
- توجد حالات Pending / Completed / Account.
- توجد progress representation.

### القرار المعماري

لا ننقل Picker كما هو إلى vouchers.

السبب:
Picker = Field Task Executor.

Voucher = Transaction Document / Stock Control.

Timer الخاص بـPicker يقيس:
- أداء موظف ميداني داخل Task Session.

Voucher lifecycle يملك بالفعل:
- created_at
- sent_date
- received_date
- completed_at

إذن المقابل الصحيح في Voucher ليس Timer واجهة أثناء إنشاء المستند، بل:
**Cycle Time KPI مشتق من Document Lifecycle timestamps.**

هذا يسمح مستقبلًا بإظهار:
- Draft aging.
- Send-to-receive cycle.
- Receive-to-complete cycle.
- Total document cycle.
- Responsible user.
- Vehicle/Branch cycle time.

بدون خلط Document UI مع Field Task UI.

---

## 17. Picker Gold Feature That Can Be Reused Architecturally

ما يستحق إعادة الاستخدام على مستوى التصميم وليس نسخ الكود:

### Task Session Pattern
- Start timestamp.
- Active session.
- Visible elapsed time.
- Completion timestamp.
- Cancel transition.
- Reopen transition.
- Resume/recovery.

هذا Pattern يصلح:
- Picking.
- Loading.
- Counting.
- Receiving.
- Delivery.
- Return handling.

لكن يجب أن يظل:
- في التطبيقات الميدانية التي تمثل Task.
- أو في Engine مشترك مستقبلي إن تم اعتماد Generic Task Lifecycle Contract.

لا يتم إدخال Timer حي إلى Voucher Modal بدون Business Contract مستقل.

---

## 18. Van Sales Integration

Current Van Sales architecture:
- User يدخل بصلاحية `van-sales`.
- السيارة تحدد mobile branch.
- المخزون في Mobile Branch هو Physical Vehicle Stock.
- DirectSale Voucher ينقل المخزون من Branch إلى Vehicle.
- Van Sales يقوم بالبيع الفعلي للعملاء.
- البيع يمر عبر `save-sales-invoice`.
- Production `save_sales_invoice_atomic` يستعمل:
  `post_stock_movement(...,'VanSale',...)`
- Accounting/ledger تتم في نفس دورة الفاتورة.

DirectReturn:
- Vehicle → Branch.
- الحركة تبدأ من Vehicle Mobile Stock.
- ثم Receive في الفرع.

النتيجة:
Voucher وVan Sales ليسا جزيرتين.
هما مرحلتان متتاليتان في Mobile Stock lifecycle.

---

## 19. Current Van Sales — No New Defect Proven

تمت مراجعة:
`companies/company-1/sales/van-sales.html`

النتيجة في هذه الجلسة:
- لا Defect جديد مثبت يبرر تعديل source.
- عيوب Report287 السابقة لا يعاد إصلاحها.
- التحقق الحالي يثبت أن:
  - operation identity موجودة في المسار المغلق سابقًا.
  - company scope موجود في المسار المغلق سابقًا.
  - offline startup closure موجود.
  - count refresh closure موجود.
  - direct sale يستخدم mobile stock architecture.

لذلك:
**لا Patch جديد على van-sales.html.**

---

## 20. Mother Integration

`main.html` لم يُلمس.

دور النظام الأم في هذه المساحة:
- Navigation / Control Plane.
- قراءة ومراقبة.
- إدارة صلاحيات.
- الوصول إلى التبويب.
- مراقبة نتائج العمليات.

دور `vouchers.html`:
- Operational Plane للأذونات المخزنية.

دور `van-sales.html`:
- Operational Field Plane للبيع المباشر من المخزون المحمول.

دور Picker:
- Operational Field Plane للتحضير.

هذا التقسيم هو سبب عدم إدخال:
- Picker Timer
- Van Sales customer sale logic
- Order/Runsheet logic

إلى Voucher document workspace.

---

## 21. Manual Voucher Contract — Historical Meaning

الدراسة التاريخية تؤكد أن الأذونات المخزنية اليدوية أنشئت لمعالجة حركة البضاعة غير المبنية على:
- Order
- Runsheet
- Customer delivery workflow

القدرات:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

والتمييز الحاسم:
**DirectSale في Voucher = نقل مخزون إلى مخزن سيارة البيع المباشر، وليس فاتورة بيع العميل.**

وبالتالي:
- Voucher يخلق Physical Stock availability للمندوب.
- Van Sales ينشئ Customer Sale بعد ذلك.
- هذا يحافظ على الفصل الصحيح بين Supply/Custody وCustomer Revenue.

---

## 22. Competitor Benchmark

### Odoo
الوثائق الحالية تدعم:
- Inventory Adjustments.
- Internal Moves.
- Physical Inventory.
- Product/Location selection.
- Barcode workflows.
- History / revert.

مصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/count_products.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html

### Microsoft Dynamics 365
يدعم Inventory Journals للحركة والتسوية والتحويل والعد، مع From/To inventory dimensions، وعمليات Transfer/Movement/Adjustment/Counting.

مصدر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

### SAP S/4HANA
Goods Movement يغطي:
- Goods Receipt.
- Goods Issue.
- Stock Transfer.
- Transfer Posting.
مع traceable material-document history.

مصدر:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html

### Daftra
يوفر:
- Transfer.
- Date/time.
- From/To warehouse.
- Quantity.
- Stock before/after.
- Stocktaking.
- Revert/adjustment workflows.

مصدر:
https://docs.daftra.com/en/tutorial/transferring-stock/
https://docs.daftra.com/en/user_manual/how-to-do-a-stocktaking-adjustment-for-a-product-or-for-the-stock/

### Manager.io
Inventory Transfer يشمل:
- Date.
- Reference.
- Description.
- Item.
- Quantity.
- From.
- To.

مصدر:
https://www2.manager.io/guides/10707

---

## 23. Competitive Gaps That Are Real but Not Safe to Invent in This Closure

المقارنة تكشف فرصًا مستقبلية حقيقية:
1. Lot / Serial / Expiry traceability.
2. Attachments / evidence for sensitive stock vouchers.
3. Formal approval workflow لبعض الحركات.
4. Official before/after stock snapshot.
5. In-transit transfer object إذا تقرر اعتماد انتقال مرحلي.
6. Richer discrepancy reason taxonomy.
7. Movement timeline أكثر عمقًا حسب:
   - branch
   - vehicle
   - custodian
   - operator
   - operation_id

لم تُبنَ هذه المزايا داخل `vouchers.html` في هذه الجلسة لأنها تحتاج Business Contract مستقل، وإدخالها الآن سيكون بناءً على “المنافس يملكها” وليس بناءً على contract RAWAEA مثبت.

---

## 24. Zero-Debt Inventory Relation

ضمن المسارات التي تم فحصها:
- Physical Stock remains centralized through `post_stock_movement`.
- Voucher cores لا تكتب `stock_branches.qty` مباشرة.
- Voucher cores لا تكتب `inventory_log` كـPhysical writer مستقل.
- Reservation semantics لم يتم خلطها مع stock mutation.

وهذا يحافظ على العقد:
`Physical Movement → post_stock_movement → stock_branches + inventory_log`

---

## 25. Production Change Decision

**لم تكن هناك حاجة إلى تعديل Production جديد في هذه الجلسة.**

السبب:
- Vehicle table موجودة.
- Vehicle/mobile branch موجودان.
- Rep binding موجود.
- RPC canonical موجود.
- Cancel RPC موجود.
- Existing Edge Functions موجودة.
- DirectSale E2E نجح.
- Cancel E2E نجح.
- Production final snapshot = baseline.

أي DDL جديد هنا كان سيعيد بناء بنية موجودة بالفعل.

---

## 26. Deployment Gate

Current Source:
**PASS**

Current Production:
**PASS**

Production transactional E2E:
**PASS**

Cancel transactional E2E:
**PASS**

Vehicle binding:
**PASS**

Physical stock centralization for tested voucher path:
**PASS**

Browser E2E on deployed Cloudflare artifact:
**OPEN / NOT VERIFIED**

Published Cloudflare Pages runtime:
**OPEN / NOT VERIFIED**

لا يجوز كتابة:
`100% Closed`
قبل إثبات published browser runtime.

---

## 27. What Was Not Changed

- `companies/company-1/main.html` — لم يُلمس.
- `companies/company-1/warehouse/vouchers.html` — لم يُلمس في هذه الجلسة لأن الإصلاح موجود بالفعل.
- `companies/company-1/sales/van-sales.html` — لم يُلمس.
- Picker — لم يُلمس.
- لم تُنشأ Edge Function جديدة.
- لم تُحذف بيانات Production.
- لم تبقَ بيانات اختبار.

---

## 28. Current Source Instruction for Owner

### File
`papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/vouchers.html`

### Action
**لا تعدّل شيئًا الآن.**

سبب القرار:
- المركبة binding صحيح.
- cancel موجود.
- clipping patch موجود.
- current source هو الحالة الصحيحة.

إذا كانت النسخة المنشورة لا تزال تعرض المشكلة:
**انقل المشكلة إلى Deployment Cutover، لا إلى Source Patch.**

---

## 29. Next Session — Exact Truth Sequence

ابدأ بالترتيب التالي:

1. Read current system `CURRENT_STATE.md`.
2. Read current system HEAD and immediate parent.
3. Read current frontend HEAD and immediate parent.
4. Re-fetch current `vouchers.html`.
5. Verify `renderWorkspace` still places `s.routeHtml()` outside `wsTopPanel`.
6. Verify current Production snapshot.
7. Verify current active vehicle + mobile branch + driver.
8. Verify current `create_manual_stock_voucher_atomic` 12-arg contract.
9. Verify current `cancel-stock-voucher`.
10. Only then inspect deployed frontend runtime.
11. Do not reopen Report296.
12. Do not create a new Edge Function.
13. Do not touch `main.html`.
14. If deployed runtime differs from Git HEAD, classify as Deployment Drift.
15. Only after published runtime is confirmed proceed to the next open Business Contract.

---

## 30. PRE-SWEEP SELF-AUDIT

### Business Understanding
Confirmed.

### Architecture Understanding
Confirmed.

### Database Understanding
Confirmed.

### Historical Understanding
Confirmed for current voucher/vehicle/van/picker boundary.

### Production Understanding
Confirmed.

### Current Source Understanding
Confirmed from current Git HEAD.

### Execution Confidence
High for:
- backend vehicle binding;
- voucher lifecycle;
- cancel;
- DirectSale transaction;
- physical stock centralization.

### Unknowns
- Published Cloudflare artifact equality to current Git HEAD.
- Live authenticated browser E2E against the deployed URL.

### Conflicts
- Older reports reference older Git blobs/HEADs.
- Current Git overrides those values.

### Unverified claims
- Browser deployed runtime.

---

## 31. FINAL SELF-AUDIT

### What I Proved
- Current vehicle exists in Production.
- Vehicle belongs to current company.
- Vehicle is Active.
- Vehicle has Mobile Stock.
- Vehicle has valid Mobile Branch.
- Vehicle driver maps to Direct Sales Rep.
- Voucher source resolves Vehicle correctly.
- DirectSale canonical RPC exists.
- DirectSale CREATE succeeded transactionally.
- DirectSale SEND succeeded transactionally.
- Physical stock returned to baseline after rollback.
- Cancel succeeded transactionally.
- Cancel returned Draft → Cancelled.
- Current voucher clipping patch exists in Git HEAD.
- No new source patch is necessary.
- No new Edge Function is necessary.
- No Production residue remains.

### What I Did Not Prove
- Published Cloudflare browser runtime is identical to current Git HEAD.
- Live browser authenticated E2E on the published frontend.

### What I Fixed
في هذه الجلسة الحالية:
- لا يوجد Source Fix جديد؛ لأن إصلاح النقطة المطلوبة موجود مسبقًا في CURRENT GIT.
- تم إغلاق التحقق Production/E2E للـVehicle Voucher path.
- تم تثبيت سبب بقاء المشكلة إن ظهرت للمستخدم على أنه Deployment/Published Runtime gap وليس missing Vehicle data.

### What Was Initially Open
- Browser deployed-runtime closure.

### What Could Still Be Wrong
- Cloudflare Pages publication/cutover قد لا يساوي HEAD الحالي.

### Final Closure Status

**VOUCHER VEHICLE DATA = CLOSED**

**VOUCHER VEHICLE ↔ REP CONTRACT = CLOSED**

**DIRECTSALE CREATE/SEND PRODUCTION E2E = CLOSED**

**CANCEL VOUCHER PRODUCTION E2E = CLOSED**

**VOUCHER SOURCE CLIPPING FIX = CLOSED**

**MAIN.HTML = UNTOUCHED**

**NO NEW EDGE FUNCTION = VERIFIED**

**PUBLISHED BROWSER RUNTIME = OPEN / NOT VERIFIED**

---

# سبب الخطأ — النتيجة النهائية

المشكلة التي جعلت المستخدم يرى أن المركبات “لا تظهر” لم تكن:
- نقصًا في جدول المركبات.
- نقصًا في Production data.
- نقصًا في RPC.
- نقصًا في company scope.
- نقصًا في Rep/Vehicle binding.

السبب الجذري كان **UI clipping داخل `renderWorkspace:function()`**:

`s.routeHtml()`
كان داخل:
`wsTopPanel`

و`wsTopPanel` كان حاوية قابلة للطي ذات:
`overflow:hidden`

فتُنشئ قائمة المركبات فعليًا، لكن حدود الحاوية تقص القائمة المرئية.

الإصلاح الجراحي الصحيح كان:
- إخراج `s.routeHtml()` من `wsTopPanel`.
- إبقاء نفس IDs.
- إبقاء نفس functions.
- إبقاء نفس RPC contract.
- إبقاء نفس Vehicle/Rep binding.
- دون تغيير Business Logic.

هذا الإصلاح موجود بالفعل في CURRENT GIT:
`745a615ccd0baff09ad2619b0316e46507a862e9`

لذلك **أي إعادة تعديل الآن على vouchers.html لإصلاح نفس المشكلة ستكون Regression Risk وليست علاجًا**.

النقطة الوحيدة التي تظل مفتوحة هي إثبات أن Cloudflare Pages المنشور فعليًا يعرض نفس HEAD الحالي.

---

## End of Report297
