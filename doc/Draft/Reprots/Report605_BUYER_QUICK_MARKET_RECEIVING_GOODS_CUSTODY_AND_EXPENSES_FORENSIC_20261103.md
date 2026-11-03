# Report 605 — استكمال عقد Buyer: الشراء السوقي، استلام الفواتير، رصيد البضاعة، مرتجع المورد، ومصروفات العهدة

**التاريخ:** 2026-11-03 — Africa/Cairo  
**Checkpoint السابق:** LVE-2026-11-03-604  
**الحالة:** CURRENT-SOURCE / PRODUCTION FORENSIC REVIEW COMPLETE — BUSINESS CONTRACT RECONCILED — IMPLEMENTATION CHANGESETS NOT YET APPROVED — NO OPERATIONAL OR PRODUCTION WRITE  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` — `main`  
**مستودع التقارير والحالة:** `papamohammed77-glitch/rawaie-erp-New` — `main`

---

## 1. نقطة البداية والحالة المرجعية

بدأت من أعلى `CURRENT_STATE.md`، وكان LVE-2026-11-03-604 هو آخر Checkpoint. لم أتعامل مع التقارير القديمة على أنها الحالة الحالية؛ استخدمتها لتحديد نقاط الفحص، ثم أعدت التحقق من Git وProduction.

### Current Git

- Operational HEAD: `743c9b170bf2314a9e4d64fd4d8104f2cc1aee8c`.
- Parent: `2ce93c6d80ec4c38353bdf88880d06ae9e0abdde`.
- Buyer: `companies/company-1/purchasing/buyer.html`, blob `aee14e6a4edbccd5fb95dff24f21daf1c6d21fcc`, 1,047 lines.
- Receiver: `companies/company-1/warehouse/receiver.html`, blob `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`, 351 lines.
- Warehouse vouchers: `companies/company-1/warehouse/vouchers.html`, blob `85e709d0f41c189c6624a6160965d3b1a41960ba`, 6,676 lines.
- `core.js`: blob `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`.

### Current Production

- Supabase project: `fiilmooggumokxanwiyx` — SMART ERP.
- PostgreSQL 17.6.1.121; system currency EGP.
- Active `receive-purchase` Edge: v13, ACTIVE, `verify_jwt=true`.
- Active `save-purchase-order` Edge: v22, ACTIVE, `verify_jwt=true`.
- لا توجد بيانات اختبار أُنشئت في Production في هذه الجولة.
- Snapshot counts عند إعادة الفحص: purchase_invoices=3، purchase_returns=0، stock_vouchers من النوع SupplierReturn=0، receiving=0، buyer_custodies=0، buyer_custody_expenses=0.

### Governance sources re-read

- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`.
- `Report599_CTO_PROCUREMENT_RECEIVING_INVOICE_PAYMENT_ACCOUNTING_FLOW_20261103.md`.
- `Report585_BUYER_QUICK_PURCHASE_CUSTODY_PURCHASING_VEHICLE_CORRECTED_DESIGN_20261102.md`.
- `Report603_BUYER_RETURN_INTEGRITY_DEPLOYMENT_RECHECK_AND_CHANGE_GATE_20261103.md`.
- `Report604_BUYER_AVAILABLE_REPOSITORY_CONSUMER_SCAN_P0D_PREFLIGHT_AND_EDGE_SOURCE_PARITY_20261103.md`.

Master §77.1 و§77.4 يثبتان قاعدة عدم الأثر قبل التسليم/الاستلام الحقيقي، واعتماد سياسة الفاتورة السريعة بلا PO بشرط الاستلام الفعلي، وعدم اعتبار اعتماد السياسة موافقة تنفيذية عامة. §77.2 ما زالت تلزم بعرض كل تغيير مؤثر بنصه وأثره واختباراته وRollback وانتظار موافقة المالك على ذلك التغيير بعينه.

---

## 2. التوجيه الوظيفي المعتمد من المالك — الصياغة التنفيذية

تم تثبيت الفصل بين الدورات التالية:

1. **مورد معتمد:** كل فاتورة شراء ترتبط بمورد مسجل في النظام الأم ويظهر في بحث Buyer. لا يوجد مورد نقدي مجهول أو مورد مؤقت يتجاوز دليل الموردين.
2. **شراء سوقي سريع:** فاتورة Draft مستقلة بلا PO؛ لا مخزون ولا حساب مورد ولا قيد لمجرد إنشاء الفاتورة. تنتظر الاستلام الفعلي من أمين المخزن عبر Receiver بالبحث برقم فاتورة المورد/فاتورة الشراء.
3. **رصيدي:** دفتر عهدة بضاعة مسؤول المشتريات، صنفًا بصنف، وليس دفتر سيارة ولا دفتر العهدة النقدية. السيارة اختيارية، والتسليم اليدوي جائز.
4. **مرتجع المورد:** الأصل أن المورد يستلم المرتجع من المخزن. والاستثناء أن يُصرح لمسؤول المشتريات باستلامه من المخزن ممثلًا للمورد، ثم يقدم إثبات التسليم/القبول إلى الحسابات. لا يُخصم حساب المورد إلا عن الكمية التي قبلها المورد فعليًا.
5. **مصروفات العهدة:** منفصلة عن فواتير PO وعن حساب المورد وPayment. شراء البضاعة نقدًا من العهدة، ومصروف التشغيل، وفاتورة المورد على الحساب، والسداد الفعلي أربع حالات مختلفة.
6. **السداد:** لا أثر للخزينة أو حساب المورد إلا بعد إثبات تسليم النقدية فعليًا أو تسليم المستند المالي المعتمد، وبحركة واحدة غير مكررة.
7. **العهد النقدية:** تبقى على الكيان المركزي الحالي؛ لاحقًا يضاف في تطبيق الحسابات عرض إدارة عهد الموظفين وإصدارها ومتابعة تسويتها، مع ظهور العهدة تلقائيًا للموظف في «عهدتي». لا ننشئ دفترًا موازيًا أو نعيد بناء سجل العهد الحالي.

---

## 3. CONFIRMED — الشراء السريع ودليل الموردين

### 3.1 Buyer source

- `createPurchaseInvoice()` عند السطر 706 يقرأ الموردين النشطين من `suppliers` ويعرض بحثًا واختيارًا من السجل المركزي.
- أمر PO اختياري في النموذج، ولذلك يمكن إنشاء فاتورة Draft بلا PO.
- `quickPurchase()` عند السطر 762 ليس مسار شراء سوقي مستقلًا؛ هو مجرد alias إلى `createPurchaseInvoice()`.
- إنشاء الفاتورة يمر عبر `CREATE_INVOICE` ولا يقوم بذاته باستلام المخزون أو إثبات دفع نقدي.

### 3.2 Production supplier master

جدول `suppliers` يحتوي `supplier_type` و`payment_type` و`is_active`، ولا يحتوي حقلًا صريحًا باسم `approval_status`.

القيم الموجودة وقت الفحص في السجلات:
- `supplier_type`: `مورد عام` و`QA`.
- `payment_type`: `نقدي` و`آجل` و`credit`.

**النتيجة:** النقدي في النموذج الحالي صفة دفع `payment_type` وليس مبررًا لإنشاء مورد عام/مجهول أو تجاوز الموردين المسجلين. لم تظهر قيمة `مورد كاش` في القيم المفحوصة. أما هل `is_active=true` تعني اعتماد المورد رسميًا من الإدارة، فهذا غير مثبت من مخطط الجدول وحده؛ يلزم توثيق صلاحية الاعتماد في النظام الأم قبل الادعاء بوجود Workflow اعتماد كامل.

### 3.3 Production RPC

`purchase_create_invoice_atomic`:
- يتحقق من أن `supplier_id` يعود إلى مورد نشط داخل الشركة.
- يسمح بأن يكون `purchase_order_id` فارغًا.
- ينشئ الفاتورة Draft وبنودها.
- لا يرحّل مخزونًا أو خزينة أو Supplier Ledger أو Journal عند الإنشاء.

**الحكم:** لا نحتاج إلى إنشاء كيان «مورد كاش» خاص داخل Buyer. نحتاج إلى اختيار المورد المسجل، مع تحديد طريقة الشراء/التسوية على مستند الشراء نفسه، وعدم السماح بقيمة مورد حرة.

---

## 4. CONFIRMED — الفاتورة السريعة لا تملك مسار استلام في Receiver

### 4.1 Receiver الحالي

- `loadPurchaseOrders()` عند السطر 199 يقرأ `purchase_orders` فقط ويعرض الحالات Sent / Partially Received.
- Realtime في Receiver يشترك في `purchase_orders` فقط.
- لا يوجد بحث أو قائمة لفواتير الشراء السريعة.
- لا يوجد ربط بين شاشة Receiver ورقم فاتورة شراء بلا PO.
- `receive_purchase_atomic` يقبل `p_po_code` وليس `purchase_invoice_id`، ويقرأ `purchase_order_details` ويحدث `qty_received` في سطور PO.
- مسار الاستلام الحالي ينشئ `receiving.po_number`، ويستدعي `post_stock_movement('PurchaseIn')`، ثم ينشئ قيد Inventory/Supplier ويسجل Supplier Ledger. هذا عقد استلام PO، ولا يجوز إعادة استخدامه للفاتورة النقدية من العهدة دون فصل أثر المورد.

### 4.2 تعارض إضافي مثبت بين Receiver والمخطط

في `receiver.html`، دالة `loadPODetails()` عند السطر 251 تستعلم من `purchase_order_details` باستخدام `.eq('po_code', code)`. مخطط Production لجدول `purchase_order_details` يحتوي `po_id` ولا يحتوي `po_code`.

هذا **Source/Schema mismatch CONFIRMED**. لم ينفذ Browser E2E في هذه الجولة، ولذلك أثره التفاعلي النهائي UNVERIFIED؛ لكنه يحتاج تصحيحًا ضمن فحص Receiver قبل توسيع الشاشة إلى فواتير السوق.

### 4.3 الفاتورة السريعة والترحيل الحالي

`purchase_post_invoice_atomic` يرفض صراحةً الفاتورة التي لا تملك PO عبر:
`PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED`.

وبالتالي:
- إنشاء Draft بلا PO ممكن.
- ترحيلها لا يمر قبل إثبات الاستلام الفعلي.
- لا يوجد حاليًا مسار في Receiver يثبت ذلك الاستلام للفواتير غير المرتبطة بـPO.
- لا يجوز تجاوز الشرط أو جعل `purchase_post_invoice_atomic` يرحّل الفاتورة بمجرد ضغط زر.

### 4.4 فجوة مخطط الاستلام

Production `receiving` يحتوي `po_number` ولا يحتوي `purchase_invoice_id` أو `source_type`. و`receiving_details` لا يحتوي `purchase_invoice_detail_id` أو مرجع سطر فاتورة. بينما `purchase_invoice_details` يحتوي `received_qty`، لكنه لا يُدار من Receiver الحالي لمسار السوق.

**الحكم:** الفجوة ليست زر بحث فقط؛ يلزم عقد استلام سوقي مستقل ومربوط بفاتورة وبنودها، مع دعم الاستلام الجزئي، ومرجع العملية، والتكرار الآمن، والفرع، وهوية أمين المخزن.

### 4.5 Edge source parity

الـEdge النشط `receive-purchase` v13 يعمل على PO code فقط. مصدره الحي تمت قراءته من Production، لكن لا يوجد ملف مطابق له في المستودع التشغيلي `erp-frontend`. والنسخة المرجعية الموجودة في مستودع التقارير أقدم وغير مطابقة للـv13.

لا تنشأ Edge جديدة. يجب أولًا استعادة تطابق المصدر الحالي في Git كـChange Set مستقل، ثم إضافة مسار الفاتورة السريعة إلى نفس البوابة بعد المراجعة والموافقة.

---

## 5. CONFIRMED — دفتر عهدة بضاعة المشتريات / «رصيدي»

### 5.1 Buyer الحالي لا يملك الدفتر

`renderVehicleBalance()` عند السطر 617:
- يقرأ `fleet_vehicle_assignments` و`vehicles`.
- يبحث عن تعيين المركبة لسائق المستخدم.
- يعرض أن دفتر عهدة بضاعة المشتريات غير مفعّل.
- لا يعرض حركات صنف فعلية من المورد إلى مسؤول المشتريات أو من المخزن إليه أو منه.

هذا ليس دفتر عهدة بضاعة، ولا يجوز اعتبار Fleet أو سيارة توصيل أو Mobile Stock بديلًا عنه.

### 5.2 الموجود في stock_vouchers

جدول `stock_vouchers` يحتوي حقولًا يمكن الاستفادة منها في تكامل المرتجع، منها:
- `custodian_user_id`
- `vehicle_id` (اختياري في التصميم المستهدف)
- `purchase_invoice_id` و`purchase_order_id`
- `supplier_rma_ref` و`supplier_credit_note_ref`
- `return_reason_id` و`inspection_status` و`disposition`
- حقول إجمالي المرتجع والعملة.

لكن وجود هذه الحقول لا يعني أن عهدة مسؤول المشتريات مطبقة.

### 5.3 مانع Production مثبت

Trigger `trg_stock_vouchers_custodian` يستدعي `enforce_stock_voucher_custodian()`. الدالة الحالية:
- إذا كان النوع ليس `DirectSale` أو `DirectReturn` فإنها تضع `custodian_user_id=NULL` وتخرج.
- في النوعين المذكورين تشترط مركبة ومندوب بيع مباشر.

إذن لا يمكن حاليًا إسناد SupplierReturn إلى مسؤول مشتريات كأمين عهدة، كما أن نموذج المندوب/المركبة الحالي غير صالح لإعادة استخدامه.

### 5.4 التصميم الوظيفي المطلوب

دفتر «رصيدي» يجب أن يعرض لكل مسؤول مشتريات:
- الصنف والكود والوحدة.
- الكمية الداخلة إلى عهدته.
- الكمية التي سلّمها للمخزن وقبلها أمين المخزن.
- الكمية المصروفة من المخزن إليه كمرتجع مورد.
- الكمية التي سلّمها للمورد وقبلها المورد.
- الكمية المرفوضة من المورد وما زالت بعهدته.
- الكمية التي أعادها للمخزن.
- الرصيد الجاري لكل صنف، مع رقم المستند وتاريخه والفرع والجهة والمستلم/المسلّم وإثبات الحركة.

لا تُنشأ حركة عهدة لمجرد Draft أو PO أو فاتورة غير مثبت استلامها. السيارة اختيارية، ولا يمنع عدم وجود سيارة التسليم اليدوي. ويظل دفتر العهدة النقدية منفصلًا تمامًا عن هذا الدفتر.

**التوصية المعمارية:** إنشاء سجل حركات عهدة بضاعة مركزي Append-only داخل SMART ERP، لا جدول رصيد يدوي قابل للتعديل. تُنشأ الحركات فقط من عمليات مركزية موثقة مرتبطة بفاتورة شراء أو إذن مرتجع أو استلام مخزني، وتُحسب الأرصدة من صافي الحركات. هذا السجل هو ما يقرأه تبويب Buyer «رصيدي»؛ ولا يُنشأ تطبيق أو قاعدة بيانات مستقلة.

---

## 6. CONFIRMED — SupplierReturn الحالي لا يحقق تسليم المرتجع عبر مسؤول المشتريات

### 6.1 مسار Warehouse Vouchers الحالي

في `vouchers.html`:
- خيار SupplierReturn موجود.
- `routeHtml()` عند السطر 4563 يعرض Branch → Supplier فقط.
- لا يوجد اختيار مسؤول مشتريات كأمين عهدة، ولا مسار يدوي مستقل عن المركبة.
- `openSupplierReturnContract()` عند السطر 4772 يطلب السبب والعنوان ومراجع PO/Invoice والفحص والتصرف.
- العملة في الواجهة ثابتة `SAR`، كما أن `save_supplier_return_contract` يستخدم `SAR` كقيمة افتراضية إذا لم تُحدد العملة/فاتورة مرجعية. هذا يتعارض مع إعداد EGP المعتمد في النظام، خصوصًا في المرتجع غير المرتبط بفاتورة ذات عملة.

### 6.2 الأثر الحالي

- `send_stock_voucher_atomic_core_20260828` يرسل SupplierReturn كحركة `SupplierReturn` من الفرع إلى NULL عند SEND، فينخفض مخزون الفرع فور الإرسال.
- `complete_manual_stock_voucher_atomic_core_20260828` عند COMPLETE يسجل Supplier Ledger ويُنشئ Journal لمرتجع المورد.
- عقد التحقق الحالي لا يحتوي على كميات قبول جزئي/رفض لكل سطر ولا يتطلب إثبات قبول المورد الفعلي قبل الإكمال.
- لا يوجد في تفاصيل SupplierReturn حقل `supplier_accepted_qty` أو `supplier_rejected_qty`، ولا سجل أحداث قبول متعدد.
- شاشة الأذونات تسمح للمنشئ/المستخدم ذي الامتياز بإكمال SupplierReturn بعد الإرسال؛ لا يوجد شرط خادمي يثبت أن المورد استلم الكمية فعليًا أو أن مسؤول المشتريات قدم إشعار الاستلام/الإيصال المالي.

### 6.3 مساران حاليان لمرتجع المورد — تعارض تكاملي يجب حسمه

يوجد في Production مساران مختلفان:
1. `purchase_returns` و`purchase_return_details`: يستخدمهما Parent ويُنشئ/يرحل عبر `save-purchase-order` Edge وRPCs الخاصة بالشراء. مسار POST_RETURN الحالي ينقص المخزون ويخفض حساب المورد.
2. `stock_vouchers` من النوع `SupplierReturn`: يستخدمه تطبيق Warehouse Vouchers؛ SEND ينقص المخزون وCOMPLETE ينشئ Supplier Ledger وJournal.

لم يثبت وجود ربط ذري يمنع تنفيذ الأثر المخزني أو المالي مرتين إذا استُخدم المساران لنفس المرتجع. كلاهما حاليًا بلا بيانات Production وقت الفحص، لكن وجود المسارين في المصدر والعقود CONFIRMED.

**القرار المعماري المقترح:** الحفاظ على سجل `purchase_returns` كمرجع حالة المرتجع المالي/التجاري الذي يراه Parent، واستخدام SupplierReturn stock voucher كوثيقة الصرف الفعلي من المخزن ومسار عهدة مسؤول المشتريات. يجب ربطهما صراحةً بمفتاح واحد، وجعل هناك كاتبًا واحدًا فقط لكل أثر:
- خصم مخزون الفرع مرة واحدة عند إذن الصرف الفعلي من المخزن.
- إضافة عهدة البضاعة لمسؤول المشتريات عند تسليم المخزن له.
- تخفيض عهدته فقط عند قبول المورد للكمية المثبتة أو إعادتها للمخزن.
- تخفيض حساب المورد والقيد المالي عن الكمية المقبولة فقط، من خلال مسار مالي مركزي واحد.
- منع `purchase_post_return_atomic` و`complete_manual_stock_voucher_atomic` من تكرار نفس حركة المخزون أو Supplier Ledger/Journal.
- عند رفض المورد جزءًا من الكمية، تبقى الكمية المرفوضة بعهدة المسؤول إلى أن تُعاد للمخزن أو يصدر قرار موثق آخر.

هذا اقتراح تكاملي يحتاج Change Set كاملًا؛ لم يتم تطبيقه.

---

## 7. CONFIRMED — مصروفات العهدة الحالية مرتبطة خطأً بمسار PO/Payment بالنسبة إلى السياسة الجديدة

### 7.1 Buyer source

`submitCustodyExpense()` عند السطر 911:
- يقرأ purchase_invoices وpurchase_orders وreceiving وsuppliers.
- يعرض فقط فواتير Draft مرتبطة بـPO ومورد.
- يشترط وجود استلام مخزني مكتمل.
- لا يعرض تصنيفًا عامًا لمصروف تشغيل مثل وقود أو انتقال أو مصروف متنوع.

### 7.2 Production RPC

`buyer_custody_review_expense_atomic`:
- يفرض صلاحية Finance.
- لا يقبل إلا Expense Submitted.
- يشترط فاتورة Draft مرتبطة بمورد وPO.
- يطابق رقم فاتورة المورد وإجماليها وبنودها مع PO والاستلام.
- يشترط أن Supplier Ledger قد سجل التزام PO.
- ينشئ Journal: Dr Supplier AP / Cr Employee Custody.
- ينشئ `buyer_custody_payments`.
- يحول الفاتورة إلى Paid.
- ينشئ Supplier Ledger debit.

هذا المسار **سداد فاتورة مورد من العهدة** وليس مصروف تشغيل عام، وهو يخالف توجيه المالك بأن فاتورة PO يسددها الحسابات، وأن مصروفات العهدة لا ترتبط بمورد/PO على هذا النحو.

### 7.3 نقص المخطط

`buyer_custody_expenses` لا يحتوي على `expense_category` أو `expense_account_id` أو `payee_kind`. ولا يوجد فصل نوعي واضح بين شراء بضاعة نقدًا من العهدة ومصروف تشغيل وفاتورة مورد على الحساب.

### 7.4 العقد المطلوب

يجب الفصل إلى أربع معاملات:

| المعاملة | المخزون | Supplier AP / Ledger | Payment | Treasury |
|---|---|---|---|---|
| شراء بضاعة نقدًا من العهدة | يزيد عند استلام المخزن فقط | لا ينشأ AP إذا كانت الفاتورة مدفوعة نقدًا | لا يُنشأ Payment للمورد مرة ثانية | أثر صرف العهدة سبق عند تسليم النقدية |
| مصروف تشغيل من العهدة | لا | لا | لا | لا حركة جديدة؛ اعتماد المستند يسوي حساب العهدة |
| فاتورة مورد على الحساب | يزيد عند الاستلام المعتمد | ينشأ AP مرة واحدة | لا عند إنشاء/استلام الفاتورة | لا |
| سداد فعلي من الحسابات | لا | يخفض AP مرة واحدة | ينشأ Payment مرة واحدة | خروج نقدية بعد إثبات التسليم الفعلي |

- شراء السوق من العهدة لا يُرسل إلى RPC الحالي الذي يحول فاتورة PO إلى Paid ويخلق Supplier Payment.
- مصروف التشغيل يحتاج فئة وحساب مصروف معتمدًا ومرفق إثبات، ويقفل من حساب عهدة الموظف دون Supplier Ledger أو Purchase Payment.
- فاتورة المورد على الحساب تبقى في دورة PO/Invoice/Finance Payment.
- يجب أن يكون لكل واقعة مصدر واحد ومفتاح Idempotency ثابت يمنع تكرار AP أو Payment أو القيد.

---

## 8. قرارات التنفيذ المقترحة وترتيبها

### Workstream A — Supplier Master / Quick Market Purchase

1. إبقاء المورد إلزاميًا من دليل الموردين النشطين في النظام الأم.
2. استخدام `payment_type='نقدي'` لتحديد شرط الدفع النقدي، وعدم تحويله إلى مورد مجهول أو سجل افتراضي.
3. توثيق معنى `is_active` وهل يمثل اعتماد المورد؛ إن لم يكن كذلك، يلزم اعتماد مورد واضح قبل السماح بالفواتير.
4. إبقاء Quick Invoice Draft بلا PO، مع تحديد طريقة التسوية: Cash from Buyer Custody أو Supplier Credit.
5. لا يُسمح بالترحيل قبل Receiver acceptance.

### Workstream B — Receiver Quick Invoice Receipt

1. إضافة قائمة/بحث لفواتير السوق غير المستلمة، برقم فاتورة النظام ورقم فاتورة المورد واسم المورد.
2. إظهار البنود والكميات المطلوبة والمتبقي والمستلم سابقًا.
3. تسجيل استلام كامل/جزئي مع فروق وأسباب وإثباتات.
4. ربط receiving header/detail بفاتورة الشراء وسطرها، لا تخزين رقم الفاتورة في `po_number` كتحايل.
5. تحديث `purchase_invoice_details.received_qty` و`purchase_invoices.is_received/received_date` حسب الاستلام الفعلي.
6. زيادة stock_branches وinventory_log مرة واحدة فقط عند قبول أمين المخزن.
7. التحقق من الفرع وصلاحية Receiver وIdempotency على الخادم.
8. عدم إنشاء AP أو Payment في مسار شراء السوق المدفوع من العهدة.

### Workstream C — Buyer «رصيدي» / Goods Custody

1. استبدال مفهوم تبويب `vehicle` بدفتر `رصيدي` القائم على المستخدم، لا على تعيين السائق أو السيارة.
2. دعم حركات Supplier → Buyer، Buyer → Warehouse، Warehouse → Buyer، Buyer → Supplier.
3. السيارة/وسيلة النقل اختيارية metadata وليست شرطًا لصحة الحركة.
4. منع تعديل الرصيد يدويًا؛ الرصيد يُشتق من حركات موثقة ومراجعها.
5. ربط كل حركة بفاتورة/إذن/سطر/عملية، مع المستخدم والفرع والوقت والإثبات.

### Workstream D — Supplier Return / Supplier Acceptance

1. حسم الربط الذري بين `purchase_returns` و`stock_vouchers SupplierReturn` قبل تعديل أي منهما.
2. فصل Supplier Pickup (المسار الأصلي) عن Buyer as Authorized Representative (الاستثناء).
3. تسجيل مسؤول المشتريات كأمين عهدة دون اشتراط مركبة.
4. صرف المخزن يخفض رصيد الفرع مرة واحدة ويزيد رصيد المسؤول مرة واحدة.
5. قبول المورد الجزئي يسجل كمية مقبولة وإثباتًا/إشعارًا/إيصالًا وتاريخًا ومستلمًا.
6. لا يُخفض Supplier Ledger/GL إلا للكمية المقبولة.
7. الكمية المرفوضة تبقى بعهدة المسؤول حتى إعادتها للمخزن أو اعتماد تصرف موثق.
8. توحيد العملة مع إعدادات الشركة EGP وعدم تثبيت SAR في UI/RPC.

### Workstream E — Cash Custody Expenses

1. فصل Market Purchase عن Operating Expense.
2. إضافة Expense Category وحساب مصروف معتمد من Finance لكل فئة.
3. لا Supplier AP ولا Payment ولا Supplier Ledger لمصروف التشغيل.
4. لا تكرار Payment لفاتورة السوق التي سبق دفعها من العهدة.
5. الإبقاء على سجل العهد النقدية الحالي؛ لا ننشئ سجلًا موازيًا.

### Workstream F — Accounts / Employee Custody (Later Phase)

- تطبيق الحسابات لاحقًا يعرض دفتر عهد الموظفين المركزي، ويصدر العهدة عبر نفس RPC/الكيان الحالي.
- يتابع جدول حالة العهد: بانتظار إقرار الموظف، مستلمة، بها مستندات قيد المراجعة، مسواة، متبقي على الموظف/للشركة.
- العهدة الصادرة تظهر تلقائيًا في تطبيق الموظف ضمن «عهدتي».
- لا تعديل على Parent `main.html` في هذه المرحلة ولا إنشاء حسابات عهدة مستقلة.

---

## 9. CHANGE GATES — ما لا يجوز تنفيذه قبل العرض والموافقة

هذه الجولة تشخيص وتصميم فقط. لم يتم:
- تعديل Buyer أو Receiver أو Warehouse Vouchers.
- تعديل Parent `main.html`.
- تعديل Edge Function أو نشرها.
- تعديل جداول أو RPCs أو Triggers أو RLS أو ACL.
- إنشاء Migration أو بيانات اختبار.
- تعديل أرصدة أو قيود أو خزينة أو Supplier Ledger.

قبل التنفيذ، يجب تقديم Change Set مستقل لكل Workstream يتضمن:
- المصدر الحالي وSHA والعنصر المحدد.
- SQL/RPC/Edge/UI patch كاملًا.
- الأثر على المخزون والخزينة وSupplier AP وEmployee Custody والقيود.
- الاعتماديات والمستهلكين.
- اختبارات قبول ورفض وتكرار/تزامن واستلام جزئي.
- Rollback وخطة اختبار معزولة.

لا تُعتبر هذه الجولة موافقة على تلك التغييرات. كما تظل Change Gate الخاصة بـP0-D لصلاحيات purchase_returns في Report603/604 منفصلة ولا تُدمج تلقائيًا في أي Change Set جديد.

---

## 10. مصفوفة الحالة

| العنصر | الحالة | الدليل / الملاحظة |
|---|---|---|
| مورد معتمد من النظام الأم | CONFIRMED جزئيًا | Buyer يختار المورد النشط وRPC يتحقق منه؛ Workflow الاعتماد الرسمي UNKNOWN |
| مورد كاش مجهول/افتراضي | غير موجود في المسار المثبت | payment_type نقدي موجود؛ لا دليل على ضرورة supplier type مستقل باسم مورد كاش |
| Quick Invoice Draft بلا PO | CONFIRMED | Buyer وRPC يدعمان الإنشاء |
| Quick Invoice Receiver | GAP CONFIRMED | Receiver PO-only وRPC PO-only |
| Receiver invoice linkage schema | GAP CONFIRMED | receiving لا يحمل purchase_invoice_id |
| Receiver PO detail query | SOURCE/SCHEMA MISMATCH CONFIRMED | يستخدم po_code بينما الجدول يحمل po_id |
| رصيد بضاعة المشتريات | GAP CONFIRMED | Buyer يقرأ Fleet ولا يملك goods custody ledger |
| مركبة إلزامية للعهدة | لا | تعريف المالك يسمح بالتسليم اليدوي |
| SupplierReturn buyer custodian | GAP CONFIRMED | Trigger يمسح custodian_user_id للنوع SupplierReturn |
| SupplierReturn acceptance / partial qty | GAP CONFIRMED | لا accepted/rejected qty ولا إثبات قبول إلزامي |
| SupplierReturn dual path | INTEGRATION CONFLICT | purchase_returns وstock_vouchers SupplierReturn كلاهما لهما مسار مخزون/مال؛ الربط ومنع الازدواج غير مثبت |
| Currency SupplierReturn | CONFLICT CONFIRMED | UI/RPC default SAR مقابل EGP |
| Custody operating expenses | GAP CONFIRMED | RPC الحالي PO/supplier payment only؛ لا expense category/account mapping |
| Employee cash custody acknowledgment | Backend control CONFIRMED | يبقى؛ UI confirmation mismatch موثق في Report603 §10 |
| Accounts employee-custody management | FUTURE SCOPE | نفس الكيان المركزي الحالي، لا قاعدة موازية |
| Runtime/E2E / deployed artifact | UNVERIFIED | لا جلسة Receiver/Buyer مصادق عليها ولا Cloudflare artifact parity حديثة |

---

## 11. نقطة الاستكمال الدقيقة

**NEXT EXACT EXECUTION:**
1. بناء Change Set معماري/تقني كامل يربط `purchase_returns` مع `stock_vouchers SupplierReturn` دون تكرار حركة المخزون أو قيد المورد.
2. بالتوازي إعداد Change Set مستقل لمسار Market Invoice Receipt في Receiver، مع استعادة مصدر Edge `receive-purchase` v13 المطابق إلى Git قبل توسيعه.
3. إعداد Change Set لدفتر «رصيدي» كحركات عهدة بضاعة مركزية مستقلة عن النقد والسيارة.
4. إعداد Change Set لفصل Operating Expenses عن Market Purchases وSupplier AP/Payments.
5. عرض كل Change Set على المالك قبل أي تعديل مؤثر، وفق Master §77.2.

**STATUS:** BUYER BUSINESS CONTRACT RECONCILED / CURRENT GAPS CONFIRMED / ARCHITECTURE CHANGESETS OPEN / NO PRODUCTION OR OPERATIONAL SOURCE MUTATION / OVERALL BUYER OPEN — NOT PRODUCTION-READY.
