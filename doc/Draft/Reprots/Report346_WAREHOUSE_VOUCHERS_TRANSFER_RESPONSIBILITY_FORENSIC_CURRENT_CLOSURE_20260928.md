# Report346 — WAREHOUSE VOUCHERS / TRANSFER RESPONSIBILITY — FORENSIC CURRENT CLOSURE
## 2026-09-28

### 1. نطاق التنفيذ

النطاق المقصور في هذه الجلسة:
- تبويب الأذونات المخزنية.
- Transfer بين فرعين.
- تثبيت مسؤول الإرسال ومسؤول الاستلام.
- منع تداخل الصلاحيات والعمليات بين المرسل والمستلم.
- الاستلام الكلي والجزئي.
- التكامل مع المخزون وسجل الحركة.
- مراجعة التكامل مع النظام الأم وتطبيقي Van Sales وPicker.
- عدم تعديل `companies/company-1/main.html`.
- عدم تعديل `companies/company-1/warehouse/vouchers.html` مباشرة؛ المصدر الحالي عُدّل بالفعل من المالك، والمطلوب المتبقي موضح كـ surgical patch أدناه.
- لا إنشاء Edge Function جديدة.

---

## 2. مصادر الحقيقة الحالية

### النظام الأم
Repository:
`papamohammed77-glitch/rawaie-erp-New`

Current HEAD:
`66151de0f0a594c5842afa1f9fef6fb521cfd316`

Parent:
`f5e47a191603403363bfe0b0dbdf490da0eff955`

آخر Commit هو حالة Report345/Current-State فقط، ولم يُثبت تعديلًا في Production.

### المصدر التشغيلي
Repository:
`papamohammed77-glitch/erp-frontend`

Current HEAD:
`cc35f3a9da6ababf4c8cd87b05ab93539cdae087`

Parent:
`4e67a7dde2b01d6810a247f62f193c8d2dc4202a`

مقارنة HEAD مع Parent أثبتت أن التعديل الأخير محصور في:
`companies/company-1/warehouse/vouchers.html`

504 additions / 25 deletions.

Current vouchers blob:
`b9b34b91a3c33f0689a20a493432e69c8e1c5f0c`

عدد الأسطر الحالي: 6078.

### النظام الأم المصدر الحالي
`main.html`
- Blob: `810e4f5440f5975f55099a124deb42b086a49183`
- تم جلب الـblob كاملًا: 32,316 سطرًا.
- تبويب إدارة المخازن والمخزون موجود.
- المجموعة الفرعية "الأذونات المخزنية" تحتوي: تحويل مخزني، صرف سيارة بيع مباشر، استلام مرتجع سيارة، مرتجع لمورد، عرض الأذونات.
- route الخاص بـ`vouchers` يمر عبر `RW_Warehouse.loadVouchers()`.
- المصدر الأم لم يُعدّل.

ملاحظة معمارية مهمة:
الـMother الحالي يحتوي أيضًا على implementation داخلي قديم لقائمة الأذونات، لكنه ليس نفس الـPWA التشغيلي المستهدف في هذه الجلسة. لم يُمس حفاظًا على قيد الجلسة. أمان العمليات الفعلي لا يعتمد على UI الأم؛ الـRPC/trigger هو مصدر الحماية النهائي.

### Van Sales
`companies/company-1/sales/van-sales.html`
- Blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`
- 2294 سطرًا.
- يحدد مخزن السيارة المعتمد عبر `setup-van-branch`.
- يحفظ فواتير البيع المباشر عبر `save-sales-invoice`.
- يقوم بالمزامنة من Supabase، ولا يعتمد Transfer بين الفروع كبديل لدورة البيع.
- لم يثبت وجود رابط ينبغي دمجه داخل Transfer؛ لذلك لا تعديل.

### Picker
`companies/company-1/warehouse/picker.html`
- Blob: `c7ad267d852d415b680aed7716833eea9bcffdf6`
- 924 سطرًا.
- التحضير يحفظ `qty_picked` لكل سطر، يسمح بالكمية الجزئية، ويطلب سبب النقص عند الحاجة.
- هذا هو النمط التشغيلي المرجعي الذي يبرر الاستلام التفصيلي في Transfer: نفس المفهوم line-level actual quantity مقابل expected quantity.

### CURRENT_STATE
Current blob:
`a4bc6f1005e5b225dcc8e12fe1680761e98c431d`

تمت قراءة الحالة الحالية، ثم مراجعة Parent/HEAD الفعليين والمصدر الفعلي وProduction.

---

## 3. تاريخ البناء الذي يجب عدم كسره

الأذونات المخزنية ليست جزءًا من دورة Order/Run Sheet التشغيلية.

الدور الفعلي:
- Transfer: Branch -> Branch.
- DirectSale: Branch -> Vehicle.
- DirectReturn: Vehicle -> Branch.
- SupplierReturn: Branch -> Supplier.

Transfer:
`Draft -> Sent -> Received -> Completed`

الآثار:
1. Draft لا يغير الرصيد.
2. Send يخصم من مخزون الفرع المصدر عبر `post_stock_movement`.
3. البضاعة تصبح في حالة انتقال منطقي بين الفروع.
4. Receive يضيف الكمية الفعلية إلى الفرع الوجهة ويحدث `received_qty`.
5. الاستلام يمكن أن يكون جزئيًا.
6. عند اكتمال جميع الكميات ينتقل الإذن إلى `Received`.
7. Complete يغلق دورة الإذن.

لا يوجد مبرر لتحويل هذا إلى Order/Run Sheet؛ ذلك سيكسر الفصل المعماري بين العمليات المخزنية المستقلة وسلسلة العمليات الميدانية.

---

## 4. نتيجة التحقيق الجنائي في المسؤوليات

Production يحتوي فعليًا على:
- `stock_vouchers.receiver_user_id`
- `stock_vouchers.receiver_assigned_at`
- FK إلى `public.users`
- index لمسؤول الاستلام.
- Trigger:
  `trg_transfer_responsibility_contract`

الـtrigger:
- عند Draft -> Sent يحدد مسؤول استلام واحدًا فقط.
- يشترط أن يكون:
  - مستخدمًا فعالًا من نفس الشركة.
  - role = `مخزني`.
  - active_warehouse_role = `أذونات`.
  - default_branch_id = فرع الوجهة.
  - ليس نفس منشئ/مرسل التحويل.
  - نطاق فروعه يسمح بفرع الوجهة.
- يرفض صفر مستقبلين.
- يرفض أكثر من مستقبل واحد.
- يجعل مسؤول الاستلام Snapshot غير قابل للتغيير بعد التثبيت.
- عند Sent -> Sent/Received لا يسمح بالتنفيذ إلا لـ receiver_user_id.
- عند Received -> Completed يفرض منشئ الإذن أو الإدارة المخزنية وفق العقد الحالي.
- Delete بعد الإرسال ممنوع.

وبالتالي:
**الأمان موجود على Production/DB وليس مجرد إخفاء أزرار.**

كما أن `stock_vouchers` في Production لا يملك authenticated UPDATE/DELETE policy؛ توجد SELECT policy فقط. التنفيذ التشغيلي يمر عبر RPCs/SECURITY DEFINER الموجودة أصلًا.

---

## 5. لا حاجة إلى تعديل Production في هذه النقطة

تمت مراجعة:
- `receive-stock-voucher` Edge Function — version 22، موجودة بالفعل.
- `post_manual_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic_core_20260828`
- `complete_manual_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic_core_20260828`
- Trigger المسؤوليات.

الاستنتاج:
- لا توجد ثغرة تستوجب إنشاء Edge Function جديدة.
- لا توجد Migration إضافية لازمة لمسؤول الاستلام.
- إعادة بناء authorization داخل الـcore فوق الـtrigger ليست مطلوبة وستكرر منطقًا موجودًا.
- النموذج الحالي يطابق قاعدة "UI للتجربة + DB للحماية".

لذلك لم يتم إجراء أي تعديل Production في هذه الجلسة، وتم الاكتفاء باختبارات transactional rolled-back.

---

## 6. بيانات الاختبار

تم استخدام Fixture مؤقت:
`QA-TR-RCV-20260928`
ثم نسخة ثانية:
`QA-TR-RCV-20260928-R2`

المسار:
- الشركة: company-1.
- المصدر: BR-01.
- الوجهة: BR-2.
- الصنف: 1001 — جو كيك 5ج.
- الكمية: 2.

كل الاختبارات نفذت داخل Transaction وانتهت بـ ROLLBACK.

التحقق الحالي من Production:
- لا توجد Transfer QA fixtures متبقية.
- يوجد فقط سجل SupplierReturn اختباري قديم `QA-SR-UI-CONTRACT-20260927-01` وهو خارج نطاق Transfer الحالي، ولم يُمس لتجنب العبث بسلسلة مالية سبق استخدامها في مراجعة مستقلة.

---

## 7. نتائج E2E المعتمد عليها

### PASS
- Sender creates Draft.
- Send succeeds.
- Receiver gets responsibility snapshot.
- Sender attempting RECEIVE is rejected:
  `لا يملك هذا المستخدم مسؤولية استلام تحويل الفرع`
- Assigned receiver performs partial receive.
- Partial replay with same operation_id returns duplicate.
- Receiver receives remaining quantity.
- Status transitions to Received.
- Creator completes.
- Receiver identity is immutable after send by the DB trigger.

اختبار سابق في Report345 أثبت أيضًا:
- non-creator draft update rejected.
- delete blocked under executed contract.
- Transfer fixtures cleanup.

ملاحظة اختبارية:
كانت هناك assertion واحدة في أول Transaction تقرأ receiver_user_id قبل تنفيذ Send، فظهرت FAIL في harness فقط. لم تكن Fail في المنتج. والدليل الحاسم هو trigger + نتيجة رفض sender على أساس عدم امتلاك مسؤولية الاستلام + نتائج Receive/Complete اللاحقة.

---

## 8. ما تم بالفعل في المصدر الحالي

Commit:
`cc35f3a9da6ababf4c8cd87b05ab93539cdae087`

تم دمج:
### T-01
`actionFor:function(v)`
أصبح يميز:
- منشئ Draft.
- مسؤول الاستلام في Sent.
- منشئ Received للإكمال.

### T-02
في قائمة الأذونات:
- منشئ المسودة: تعديل + حذف + إرسال.
- Transfer receiver: زر "فتح واستلام".
- لا يوجد استلام لمرسل التحويل.

### T-03
أضيف:
`exitVoucherDetails:function()`
ورسالة الخروج:
"هل أنت متأكد من الخروج بدون حفظ"

### T-04
`receive:function(code,full)`
أصبح يدعم:
- استلام كلي.
- استلام تفصيلي.
- remaining quantities.
- idempotency.
- التشغيل عبر Edge Function الموجودة.
- عدم إنشاء Edge جديدة.

هذه التعديلات موجودة بالفعل ولا يجوز إعادة تنفيذها.

---

# 9. العيب الحالي المحدد — T-05

## الملف المطلوب تعديله
`companies/company-1/warehouse/vouchers.html`

## الدالة
`details:function(code)`

## موضع العيب
حوالي السطر 1935 في الـblob الحالي.

يوجد قبلها مباشرة كائن صحيح اسمه:

`var topActions=`

وهو يبني أزرار مسؤول الاستلام:

- استلام كلي.
- استلام تفصيلي.
- طباعة.
- خروج.

لكن هذا الكائن **غير مستخدم**.

عدد التعريفات:
`topActions = 1`

عدد الاستخدامات الحالية:
`topActions+ = 0`

والـtoolbar القديم ما زال داخل `var h=` ويعرض فقط:
- طباعة.
- تصدير CSV.

إذن:
**العيب ليس في receiver logic ولا في Production.**
العيب في عدم ربط الـtoolbar المصحح بالـHTML النهائي للمودال.

---

# 10. التعديل الجراحي المطلوب — T-05

### ابحث عن هذا العنصر بالتحديد داخل:
`details:function(code)`

وهو العنصر الموجود مباشرة بعد:

`var h=`

النص الحالي:

```javascript
'<div class="flex flex-wrap justify-end gap-2 mb-3 no-print">'+
'<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
'<button type="button" onclick="App.exportVoucher()" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">⇩ تصدير CSV</button>'+
'</div>'+
```

### احذف هذا العنصر كاملًا.

### واستبدله بالكامل بـ:

```javascript
topActions+
```

ولا تعدل أي شيء آخر في `details:function(code)`.

### النتيجة

عندما يكون:
`v.type==='Transfer'`
و:
`v.status==='Sent'`
و:
`s.user.id===v.receiver_user_id`

سيظهر أسفل الإذن:

1. استلام كلي.
2. استلام تفصيلي.
3. طباعة.
4. خروج.

أما المستخدم غير المسؤول عن الاستلام فسيظهر له toolbar القراءة فقط، بدون Receive.

---

## 11. لماذا لا نحذف `var topActions`

لا تحذف:
`var topActions=`

لأنه هو العنصر المصحح الموجود بالفعل في المصدر الحالي.

الخطأ هو فقط عدم استعماله.

---

## 12. لا توجد تعديلات إضافية مطلوبة في vouchers.html

لا تعدل:
- `actionFor`
- `cards`
- `receive`
- `exitVoucherDetails`
- `submit`
- DirectSale mapping.
- SupplierReturn contract.
- idempotency.
- stock calculation.
- realtime.

كلها ثبتت في المصدر الحالي أو في Production.

---

## 13. تكامل Van Sales

Van Sales يبقى:
`DirectSale`
Branch -> Vehicle.

Production يحل Vehicle stock إلى mobile branch canonical context.

Van Sales:
- يحدد mobile stock branch بواسطة `setup-van-branch`.
- ينفذ البيع بواسطة `save-sales-invoice`.
- لا يستعمل Transfer لاستبدال عملية البيع.
- لذلك لا يوجد تعديل مطلوب في `van-sales.html`.

هذا يحافظ على الفصل:
- Voucher = movement/custody.
- Van Sales = direct sale.
- Order/Run Sheet = field delivery/order lifecycle.

---

## 14. تكامل Picker

Picker يستخدم expected vs actual quantities:
`qty_ordered`
مقابل
`qty_picked`

وتوجد معالجة صريحة للنقص وسبب النقص.

نفس المبدأ مطبق في Transfer Receive:
`qty`
مقابل
`received_qty`

مع السماح بالاستلام الجزئي.

لا نعيد بناء Picker ولا ننشئ workflow جديدًا.

---

## 15. موضع النظام الأم في المعمارية

Mother Control Plane:
- يدير views والكيانات والوظائف الإدارية.
- يربط إدارة المخازن والمخزون.
- يسجل الأذونات.
- يفتح `RW_Warehouse.loadVouchers()`.

Operational PWA:
`warehouse/vouchers.html`

هو Execution Plane الخاص بالأذونات المخزنية.

Supabase:
Transaction/Data Plane.

وبالتالي:
`main.html`
لا ينبغي أن يصبح مكانًا لإعادة تنفيذ authorization الخاصة بكل تطبيق تشغيلي.

الحماية المركزية الصحيحة هي:
UI guards + RPC + DB trigger.

---

## 16. مقارنة تنافسية

### Odoo
Odoo Internal Transfers تستخدم Source وDestination وProduct Lines، وتدعم Detailed Operations، وتسمح بتعديل الكمية المنفذة لكل line، كما تدعم معالجة التحويل بواسطة Barcode/Scanner. هذا يؤكد صحة فصل expected عن actual في الاستلام.  
Official:
https://www.odoo.com/documentation/17.0/applications/inventory_and_mrp/barcode/operations/transfers_scratch.html

### Microsoft Dynamics 365
Transfer Order Receiving يفصل بين التسجيل والاستلام، ويدعم line receiving وpartial quantities عبر Warehouse Management mobile flows.  
Official:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process

### SAP
SAP يصف Stock Transfer in Two Steps كحركة تتكون من Goods Issue ثم Goods Receipt بين الوحدات التنظيمية.  
Official:
https://help.sap.com/docs/SAP_ERP/75c4b203fca64320b998cc04e2eb1468/719bc7536e8e2a4be10000000a174cb4.html

### Manager.io
Inventory Transfer ينقل المخزون بين locations، مع Date/Reference/Description/Item/Qty/From/To، وتُحدّث الكميات في الموقعين تلقائيًا.  
Official:
https://www2.manager.io/guides/10707

### Daftra
لم يتم العثور في هذه المراجعة على صفحة رسمية مناسبة يمكن الاعتماد عليها لإثبات تفاصيل Transfer/Receiving؛ لذلك لم تُنسب له وظيفة غير مثبتة.

### النتيجة الوظيفية
RAWAEA يمتلك بالفعل:
- source/destination.
- two-step Send/Receive.
- partial receive.
- actual quantities.
- immutable responsibility snapshot.
- atomic stock movement.
- idempotency.
- operational PWA.
- Mother control.

ولا توجد حاجة إلى نسخ شكل منافس دون الحاجة الوظيفية.

---

## 17. فجوات مستقبلية حقيقية — خارج إغلاق هذه النقطة

هذه ليست أسبابًا لفتح العمل من جديد الآن:
- barcode scan على Transfer Receive.
- discrepancy reason field مستقل لكل line عند اختلاف الاستلام.
- attachment/photo proof للاستلام عند الحاجة.
- receiver acknowledgement timestamp display في UI.
- in-transit quantity report منفصل.
- aging/SLA للتحويلات المفتوحة.
- branch-to-branch reconciliation report.
- audit dashboard للمخزن والمحقق والحسابات.

لا تُنفذ هذه العناصر ضمن T-05.

---

## 18. معيار الإغلاق الحالي

### Production
CLOSED.

### DB security
CLOSED.

### Business Contract
CLOSED.

### Transfer lifecycle
CLOSED.

### Partial/full receiving backend
CLOSED.

### UI responsibility list
CLOSED بعد T-01/T-02.

### Receiver modal actions
OPEN — T-05 فقط.

### Main.html
UNCHANGED حسب القيد.

### vouchers.html
OWNER PATCH REQUIRED — عنصر واحد فقط.

---

## 19. تعليمات البداية للجلسة التالية

ابدأ بهذا الترتيب فقط:

1. تحقق من Git HEAD.
2. تحقق من current vouchers blob SHA.
3. تحقق من أن T-01/T-02/T-03/T-04 ما زالت موجودة.
4. تحقق من أن `var topActions=` موجودة.
5. تحقق أن `topActions+` أصبح مستخدمًا مرة واحدة بعد `var h=`.
6. نفّذ authenticated browser E2E.
7. لا تُعد أي Migration أو Edge Function أو QA fixture.
8. لا تعُد إلى إصلاح Transfer backend إلا إذا ظهرت Production evidence جديدة تثبت خللًا.

---

## 20. الخلاصة التنفيذية

الـBusiness Contract الخاص بمسؤولية Transfer أصبح مثبتًا مركزيًا في Production/DB.

المصدر الحالي دمج فعليًا معظم التعديل المطلوب.

العيب الوحيد المثبت في المصدر الحالي هو أن:
`topActions`
يُنشأ لكنه لا يُحقن في `details()`.

التعديل المطلوب للمصدر:
**احذف toolbar القراءة القديم الواقع بعد `var h=` واستبدله بـ`topActions+`.**

لا توجد أي خطوة أخرى مطلوبة في هذا الملف.

