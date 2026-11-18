# RAWAEA ERP — تقرير الاستئناف الجنائي CTO
## LVE-2026-11-18-732 — Parent PO contract, PO-invoice guards and Buyer custody reconciliation

**التاريخ:** 2026-11-18 (Africa/Cairo)  
**الحالة:** READY WITH LIMITATIONS للتحليل والتوثيق؛ BLOCKED للتغييرات التشغيلية المؤثرة حتى موافقة المالك على ChangeSet محدد.  
**نقطة الاستئناف:** LVE-2026-11-18-731 / Report731.  
**نطاق الإنتاج الوحيد:** SMART ERP — Supabase project ref `fiilmooggumokxanwiyx`.  
**نطاق Git التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main` / `companies/company-1`.

---

## 1. ملخص تنفيذي

استُكمل التحقيق من LVE731 دون إعادة البدء. تمت مطابقة آخر HEAD والملفات التشغيلية في GitHub مع عقود Supabase المنشورة وبيانات قراءة فقط من SMART ERP.

النتائج الجديدة المؤكدة:

1. مسار نقطة الشراء القديم في النظام الأم ما زال يرسل بنية طلب متقادمة إلى Edge Function v44، بينما Edge الحالي يشترط `operation/payload/operation_id`. هذا يفسر فشل حفظ أوامر الشراء من هذا المسار تحديدًا، ولا يثبت وجود خلل في منشئ PO الحديث.
2. فلتر فواتير PO في Parent أوسع من Buyer؛ Parent يعرض Draft/Confirmed/Approved/Partially Received/Received، بينما Buyer الحالي يلتزم بـApproved وبلا استلام سابق. أحدث commit يثبت أن فلتر Buyer قرار مقصود، وليس سهوًا عارضًا.
3. دالة Production `purchase_create_po_invoice_atomic` لا تفرض على الخادم شرط Approved أو عدم وجود استلام أو مطابقة كل بند فاتورة لبنود PO عند إنشاء المسودة. لا يجوز الاعتماد على فلتر الواجهة كحاجز أعمال/أمن.
4. حالة `PO-20260928` في Production مؤكدة: PO مستلم بقيمة 700 EGP، بلا فاتورة مرتبطة، مع قيد استلام Dr 124 / Cr 211 ودائن 700 في Supplier Ledger. لم يُعدّل أو يُعكس أي أثر؛ توقيت نشوء ذمة المورد (عند الاستلام أم عند فاتورة المورد) ما زال قرارًا محاسبيًا يجب حسمه قبل تغيير هذا المسار.
5. مسار Quick Market الممول من عهدة الموظف له آلية تسوية مستقلة متماسكة: بعد استلام فعلي ومستنداته، تقدم مطالبة للمالية، وعند اعتمادها يُسجل Dr 124 / Cr 127 دون AP مورد أو حركة خزينة ثانية. الفواتير الأربع في Production ما زالت Draft/RECEIVED/UNSETTLED وبلا مطالبة مصروف مرتبطة؛ لا تُسوّى آليًا.
6. رصيد حيازة بضاعة المشتري يُبنى جزئيًا من إسقاط افتراضي مصدره فاتورة السوق السريع، وتُخصم منه استلامات المخزن. لذلك غياب حدث موجب محفوظ لا يعني رصيدًا سالبًا. لكن RPC تفاصيل تقدم الحيازة يعرض الكمية كلها كـ`handed_over_qty` حتى عند غياب حدث إثبات تسليم فعلي؛ يجب فصل «حيازة مشتقة من الفاتورة» عن «تسليم موثق بدليل».
7. لم تُحذف أي من تبويبات Buyer التسعة، ولم يُدمج الدفتر النقدي «عهدتي» مع دفتر البضاعة «عهدة بضاعتي». `vehicle_id` اختياري وليس شرطًا للحيازة.
8. لم تُنفذ كتابة تشغيلية أو DDL/DML أو نشر Edge أو اختبار E2E يغير بيانات. جميع قراءات Supabase كانت SELECT / catalog reads.

**لا يوجد إصلاح تشغيلي معلن كمكتمل في هذه الجولة.** الجاهز هو تحديد ChangeSets محددة بأدلتها وحدود أثرها.

---

## 2. مصادر الحقيقة ومطابقة النسخ

### 2.1 التكليف والدستور والحالة

- التكليف: `doc/Draft/Reprots/writing-block-8888-10.md`, SHA `928a98e94624e1c0a5bf4b3e97aaff560c33fcd8`.
- الدستور التشغيلي الدائم: `doc/Draft/Reprots/الدستور التشغيلي الدائم.md`, SHA `3a6b1e220af8509e314e94df76563bbc6f84910d`.
- CURRENT_STATE قبل هذا التقرير: SHA `557f4dca1339079aa19d259623b2515351f76860`; أعلى نقطة كانت LVE731.
- Report731: `Report731_CTO_BUYER_HISTORICAL_OPERATING_MODEL_AND_STAGED_REPAIR_20261118.md`, SHA `d73ec17f03b6f2e57edc19fa98a27f687abee1fe`.

### 2.2 GitHub

- HEAD `ebb2a01d07c8dc1460bd4f577962a7b8c26be920`.
- Commit HEAD: `fix(buyer): show only approved POs with no warehouse receipt`, بتاريخ 2026-11-16 17:06:05Z.
- Parent `companies/company-1/main.html`: 34,668 lines / نحو 1.93MB، تمت قراءة النسخة الحالية كاملة عبر Contents API.
- Buyer `companies/company-1/purchasing/buyer.html`: Blob `db1d311966a676dd2c7210895afefef5b5d2a954`, 2,657 lines.
- Edge `save-purchase-order` في Production: version 44، SHA `0bf7e223babdf1bf9ee61c3d90148b86934fdfcebe16015004b1a030be9f0791`.

### 2.3 Supabase Production

- المشروع الوحيد المستخدم: `fiilmooggumokxanwiyx`, اسم SMART ERP، الحالة ACTIVE_HEALTHY.
- لم يُستخدم `rawaea-staging` أو أي مشروع آخر.
- أحدث migration المقروء: `20261116144311_receiving_rls_context_and_fk_index_opt_20261116`.
- إعدادات `purchase_settings` الحالية: EGP؛ `require_request_approval=true`؛ `require_receiving_before_invoice=false`؛ `require_invoice_before_payment=true`؛ `require_inventory_on_invoice=true`؛ `require_inventory_voucher_on_return=true`.

---

## 3. تفسير نموذج Buyer وعدم حذف التبويبات

Buyer يحتوي تسعة تبويبات مستقلة:
`today`, `suppliers`, `requests`, `quotations`, `orders`, `invoices`, `custody`, `vehicle`, `account`.

- `custody` = دفتر العهدة النقدية «عهدتي».
- `vehicle` = دفتر حيازة البضائع «عهدة بضاعتي»؛ الاسم الداخلي التاريخي لا يعني أن الحيازة مشروطة بسيارة.
- `vehicle_id` metadata اختيارية.
- أنواع الملكية التي يمثلها دفتر البضاعة: `SUPPLIER_OWNED`، `COMPANY_OWNED_SUPPLIER_RETURN`، و`UNCLASSIFIED`.
- تطور التاريخ يثبت أن رصيد السيارة بدأ Placeholder في commit `02b5f00`، ثم استُبدل بدفتر بضاعة فعلي في `2c421a9`. لا يجوز حذف التبويب أو دمجه مع النقد أو مع Van Sales.
- 32 موضع `Swal.fire` في Buyer هي إجراءات ونماذج/تأكيدات مختلفة؛ العدد وحده ليس دليل تكرار وظيفي. توحيد shell/forms/timeline مستقبلًا يكون مع الاحتفاظ بالحقول والإجراءات والتحققات.
- محرك `inventory_count_engine` الموجود يعالج جرد الفرع/المركبة/المخزون العام؛ لا يطابق ملكية ومصدر دفتر حيازة المشتري، ولا يُعاد استخدامه لهذا الغرض.

---

## 4. العيوب المؤكدة في Parent وEdge

### 4.1 نقطة شراء — عقد حفظ PO القديم غير متوافق

**الموضع:** `main.html`، `RW_Purchases.savePO()`، السطر 12189 وما حوله.

المسار الحالي يرسل إلى `save-purchase-order`:
`{orderHeader: ..., itemsList: cart}`.

لكن Edge v44 يشترط:
`{operation, payload, operation_id}`.

كما أن cart الحالي يستخدم:
`{code,name,price,unit,qty}`.

بينما RPC `purchase_create_po_atomic` يتطلب داخل `payload.items`:
`{item_code,qty,unit_price,notes}`.

النتيجة المتوقعة من العقد الحالي هي رفض الطلب لغياب `operation` برسالة «عملية المشتريات مطلوبة»؛ لم أرسل طلبًا تجريبيًا لتجنب إنشاء/تعديل مستند Production.

**مهم:** المسار الحديث `RW_PurchaseGold.api()` يبني الشكل الصحيح، و`CREATE_PO` يكتب PO Draft فقط. كما أن `RW_PurchaseGold.render` مربوط فعليًا بـ`RW_Purchases.renderOrders`. العيب في مسار `purchase-pos` القديم تحديدًا، وليس سببًا لإزالة شاشة نقطة الشراء.

### 4.2 أهلية فاتورة PO — Parent/Buyer/Server غير متطابقين

- Parent `createInvoice()` قرب السطر 13664 يجلب حالات `Draft, Confirmed, Approved, Partially Received, Received`.
- Buyer `poEligible()` قرب السطر 1118 يسمح بمسودة PO الحالية كمرجع مقفول، أما الفاتورة الجديدة فتتطلب `Approved`، وجود تفاصيل، وصفر كميات مستلمة.
- commit `ebb2a01` أضاف هذا الشرط عمدًا في 2026-11-16، وReport729 يثبّت أنه قاعدة المالك آنذاك. لا تُرفع القيود لمجرد تمكين إنشاء فاتورة إضافية.

**فجوة الخادم:** الدالة `purchase_create_po_invoice_atomic` تفحص هوية PO والمورد والعملة وعدم الإلغاء فقط. لا تفرض `status='Approved'`، ولا تفحص عدم وجود استلام عند إنشاء مسودة جديدة، ولا تتحقق أن كل `item_code/item_id` في `p_items` موجود في تفاصيل PO. صلاحية الواجهة ليست بديلًا لحاجز RPC.

أما `purchase_post_invoice_atomic` فتتحقق عند الترحيل من انتماء بند الفاتورة للـPO، ومن عدم تجاوز الكمية المقبولة بعد خصم المفوتر سابقًا، ومن وحدة القياس والسعر والضرائب/الخصم. هذا تحقق متأخر؛ الحاجز الخادمي مطلوب أيضًا في إنشاء/تعديل المسودة.

### 4.3 سياسة توقيت ذمة المورد لم تُحسم

Production `receive_purchase_atomic` الحالي ينشئ حركة `PurchaseIn` ويكتب قيدًا Dr 124 / Cr 211 ويضيف Supplier Ledger Credit أثناء استلام PO. مسار ترحيل فاتورة PO لاحقًا لا ينشئ المخزون أو ذمة المورد مرة ثانية.

هذه آلية accrual عند الاستلام، لكنها ليست بالضرورة خطأً محاسبيًا قبل معرفة السياسة المعتمدة: هل تستحق ذمة المورد عند استلام البضاعة، أم عند مطابقة فاتورة المورد واعتمادها؟ لا يُغير أحد الطرفين منفردًا.

**الحالة الفعلية:** `PO-20260928` بقيمة 700 EGP؛ الحالة Received؛ 15 وحدة مستلمة؛ لا فاتورة مرتبطة؛ مستند استلام واحد؛ قيد استلام واحد Posted؛ Supplier Ledger net credit = 700. لم ألمس الأمر أو القيد أو دفتر المورد. أي تغيير يتطلب حزمة P0 ذرية للطرفين وقرار توقيت AP، لا عكسًا منفردًا.

---

## 5. Quick Market — فصل النقد والبضاعة

### 5.1 مسار EMPLOYEE_CUSTODY

- إنشاء الفاتورة يحجز القيمة على العهدة النقدية.
- Receiver يضيف المخزون بالكمية المقبولة فقط ويخصم المقابل من دفتر الحيازة.
- المشتري يرسل مطالبة مالية مرتبطة بالفاتورة وإذن الاستلام والمستندات.
- اعتماد المالية ينشئ قيد Dr 124 / Cr 127، ويحدث `paid_amount/settlement_status`؛ لا ينشئ AP المورد ولا حركة خزينة جديدة.
- `POST_INVOICE` العادي يرفض Quick Market عمدًا حتى لا يعيد ترحيل المخزون؛ ليس زر الترحيل العادي هو مسار تسوية هذه الفواتير.

### 5.2 وضع السجلات الحالية

Production يعرض أربع فواتير Quick Market:
- PINV-1002 — 1,000 EGP.
- PINV-1003 — 430 EGP.
- PINV-1004 — 2,240 EGP.
- PINV-1005 — 100 EGP.

جميعها `Draft / RECEIVED / UNSETTLED` مع `paid_amount=0`، ولا توجد لها مطالبات في `buyer_custody_expenses`. سجلات الاستلام المرتبطة موجودة، والكميات المقبولة عبرها 20 و9 و5 و5 = 39 وحدة. هذا يثبت بقاء التسوية المالية مفتوحة؛ لا يثبت وجود خطأ يبيح التسوية التلقائية. العهدة النقدية المرتبطة حالتها UnderReview، ومطلوب اتباع دورة المطالبة والمراجعة.

### 5.3 مصدر التمويل SUPPLIER_CREDIT

إنشاء فاتورة Quick Market يسمح حاليًا بمصدري `EMPLOYEE_CUSTODY` و`SUPPLIER_CREDIT`. لكن قائمة Receiver ودالة `receive_quick_market_purchase_atomic` تقبلان `EMPLOYEE_CUSTODY` فقط، كما أن الترحيل المالي لا يملك فرعًا لـQMP Supplier Credit.

هذه فجوة عقدية مؤكدة في المصدر المعروض؛ لا توجد في Production فواتير Quick Market من هذا المصدر. لا يُفعّل هذا المسار إلا بحزمة تشمل Queue + Receiver + AP-only posting بعد الاستلام المقبول، مع منع تكرار المخزون والخزينة.

### 5.4 إسقاط دفتر الحيازة — توضيح لازم

`buyer_goods_custody_get_balances_atomic` ينشئ أحداثًا افتراضية مشتقة من فاتورة Quick Market:
- موجب افتراضي `SUPPLIER_TO_BUYER_QUICK_MARKET` للكمية غير المثبتة كحدث صريح.
- سالب افتراضي/إسقاط `BUYER_TO_WAREHOUSE_ACCEPTED` للاستلام المقبول غير الممثل بحدث فعلي.

لذلك عدم وجود حدث موجب محفوظ لا يجعل الرصيد سالبًا؛ إسقاط الفاتورة يحافظ على الرصيد ويمنع ازدواج احتساب الحدث الفعلي. هذا التصحيح يحل الاشتباه الذي ظهر أثناء التحقيق.

لكن `buyer_goods_custody_get_invoice_handover_progress_atomic` يعيد `handed_over_qty=d.qty` و`remaining_qty=0` دائمًا في تفاصيل الفاتورة، بينما قائمة `events` تعرض فقط أحداث التسليم الصريحة المخزنة. هذه التسمية قد توحي بوجود دليل تسليم كامل رغم أن الكمية قد تكون مشتقة من الفاتورة فقط.

**التعديل المقترح:** إظهار حقليْن منفصلين: `invoice_derived_custody_qty` و`evidence_backed_supplier_handover_qty`، وتسمية سجل الإثبات بوضوح. تغيير قراءة/عرض فقط، بلا تغيير رصيد أو حركة.

---

## 6. المرتجعات وجرد الحيازة

### 6.1 مرتجع المورد

- مسار Quick Market المباشر: المشتري يثبت تسليم المرتجع للمورد مع الدليل، وحدث القبول يخفض حيازته. لا يخصم من مخزون الفرع إن لم تدخل البضاعة إليه.
- مسار SupplierReturn الصادر من المخزن: حاليًا Trigger يثبت انتقال البضاعة إلى عهدة المشتري عند Draft→Sent، ويشترط القبول الكامل عند Sent→Completed؛ القبول الجزئي يُرفض.
- إكمال القبول الجزئي يتطلب عملية append-only لكل دفعة قبول، ومستندًا منفصلًا لعودة الجزء المرفوض إلى المخزن بعد استلامه فعليًا. يجب تعديل Trigger + RPC + financial core كوحدة واحدة؛ تعديل Trigger فقط غير آمن.

### 6.2 جرد عهدة بضاعتي

لا توجد جلسة جرد مخصصة لدفتر حيازة المشتري. جداول `inventory_counts` و`inventory_count_details` والمحرك الحالي خاصّة بمخزون الفرع/المركبة/المخزون العام. المطلوب لاحقًا جلسة Snapshot/Actual/Variance، ثم مراجعة واعتماد، ثم أحداث تصحيح append-only؛ لا ينشأ تعديل حيازة أو مخزون بمجرد إدخال العدّ الفعلي.

---

## 7. ChangeSets المطلوبة — لم تطبق

| المعرّف | النطاق | التغيير المطلوب | أثره / حاجز السلامة |
|---|---|---|---|
| CS-732-01 | Parent `main.html`، `RW_Purchases.savePO` | استبدال payload القديم بعقد Edge v44 `CREATE_PO`، وتحويل cart إلى `item_code/qty/unit_price`، مع operation_id وIdempotency-Key، وقراءة `code` من الاستجابة | ينشئ PO Draft فقط؛ لا مخزون/AP/GL/خزينة. يحتاج تطبيق المالك بسبب §10.1 |
| CS-732-02 | Parent `createInvoice` + Buyer + `purchase_create_po_invoice_atomic` وUpdate counterpart | توحيد اختيار PO وفق قاعدة المالك الحالية Approved + تفاصيل + صفر استلام للمسودات الجديدة، وتطبيق الحاجز خادميًا على إنشاء/تعديل الفاتورة وفحص line membership | لا ترحيل عند إنشاء Draft؛ يتطلب ChangeSet كاملًا واعتماد المالك |
| CS-732-03 | Quick Market Supplier Credit | إكمال Queue/Receiver/Finance AP-only posting لمصدر Supplier Credit بعد الاستلام المقبول | لا حركة مخزون ثانية ولا خزينة؛ لا توجد بيانات قائمة بهذا المصدر، ويستلزم اعتماد عقد AP |
| CS-732-04 | Buyer goods custody detail RPC | فصل الحيازة المشتقة من الفاتورة عن التسليم المثبت بالدليل في استجابة تفاصيل التقدم | تغيير عرض/قراءة فقط؛ لا تغيير أرصدة أو أحداث |
| CS-732-05 | SupplierReturn | قبول جزئي append-only + مسار رد الجزء المرفوض إلى المخزن بعد استلامه، وتحديث trigger/RPC/financial core ذريًا | حساس للمخزون والمورد والضرائب؛ لا تعديل منفرد |
| CS-732-06 | Buyer goods count | جلسة جرد Snapshot/Actual/Variance ومراجعة واعتماد وأحداث تصحيح بعد الموافقة | لا DML على المخزون/الحيازة قبل اعتماد نتيجة الجرد |
| CS-732-07 | سياسة PO receiving/AP | قرار توقيت نشوء ذمة المورد (receipt accrual أم supplier-invoice matching) ثم إصلاح الطرفين معًا | يمنع ازدواج AP؛ لا عكس للقيد الحالي ولا تعديل PO-20260928 قبل القرار |

**ملاحظة:** لا يكفي عرض تغيير UI وحده لإغلاق فجوة الخادم. وكل SQL function replacement يجب أن يتضمن النص الكامل، overloads، callers، privileges/ACL، trigger dependencies، rollback، واختبارًا لا يترك أثرًا.

---

## 8. التحقق والاختبارات المنفذة

### منفذ
- قراءة التكليف والدستور وCURRENT_STATE وReport731.
- قراءة Parent `main.html` الحالي كاملًا من Contents API، وBuyer الحالي.
- التحقق من HEAD وcommit الذي أدخل فلتر Buyer.
- قراءة Edge `save-purchase-order` v44 ومقارنة عقده بالاستدعاءات الحالية.
- قراءة تعريفات RPC ذات الصلة في SMART ERP: إنشاء PO، إنشاء/ترحيل فواتير PO، استلام PO وQuick Market، تسوية عهدة السوق السريع، دفتر حيازة المشتري وتقدم الحيازة.
- استعلامات SELECT على PO/Receiving/Invoices/Journal/Supplier Ledger/Custody Events لتحديد الوضع الحالي.

### غير منفذ
- لا تعديل Source أو SQL أو DDL/DML أو Edge deployment.
- لا إنشاء Fixtures.
- لا Browser session مصادق عليه، ولا Cloudflare deployed-artifact parity، ولا اختبارات E2E تفاعلية.
- لا ادعاء بأن المسارات اجتازت E2E أو أن الإصلاحات طبقت.

### ضمانات هذه الجولة
- لا تغيير في المخزون أو الخزينة أو Supplier Ledger أو Journal Entries.
- لم يُعكس أو يُصحح PO-20260928.
- لم تُنشأ بيانات اختبار دائمة أو مستندات QA.
- لم يُستخدم مشروع Staging أو أي مشروع آخر.

---

## 9. Last Verified Event / Resume

- **LVE:** `LVE-2026-11-18-732`.
- **Readiness:** READY WITH LIMITATIONS للتحليل؛ BLOCKED لأي تعديل تشغيلي ينتظر ChangeSet محدد واعتماد المالك.
- **المثبت:** Parent PO save contract mismatch؛ Parent/Buyer PO invoice eligibility mismatch؛ missing server PO eligibility guards؛ live PO-20260928 receiving/AP effect؛ QMP employee-custody settlement model؛ QMP supplier-credit gap؛ virtual goods custody projections and misleading detail field.
- **لم يتغير:** HEAD في هذا التحقيق؛ Production schema/data/Edge versions؛ جميع ملفات التطبيقات المنشورة؛ أرصدة المخزون والنقد ودفاتر الموردين والقيود.
- **الخطوة التالية:** عرض CS-732-01 وCS-732-02 أولًا كتغييري مصدر واضحين، مع الحفاظ على بوابة Owner review؛ يليهما CS-732-03/04 وقرار سياسة AP للحزمة CS-732-07. لا تبدأ بتغيير SupplierReturn أو جرد الحيازة قبل تجهيز replacement set الكامل واختبارات rollback/fixture.

---

## 10. المراجع

- التكليف: [writing-block-8888-10.md](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/writing-block-8888-10.md)
- الدستور: [الدستور التشغيلي الدائم.md](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/الدستور%20التشغيلي%20الدائم.md)
- الحالة السابقة: [Report731](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report731_CTO_BUYER_HISTORICAL_OPERATING_MODEL_AND_STAGED_REPAIR_20261118.md)
- Parent: [main.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html)
- Buyer: [buyer.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/purchasing/buyer.html)
- HEAD commit: [ebb2a01](https://github.com/papamohammed77-glitch/erp-frontend/commit/ebb2a01d07c8dc1460bd4f577962a7b8c26be920)
- تقرير دورة PR/PO: [Report729](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report729_DAILY_CTO_REVIEW_PROCUREMENT_SERVER_GUARDS_AND_RLS_EXPANSION_20261116.md)
- تقرير lifecycle: [Report728](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report728_DAILY_CTO_REVIEW_PR_PO_LIFECYCLE_20261116.md)
- تقرير census: [Report730](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report730_DAILY_CTO_REVIEW_DIRECT_DML_CENSUS_AND_PO_GUARDS_20261117.md)
