# Report606 — تعليمات المالك الجديدة: توحيد مورد النظام الأم، فاتورة السوق، الاستلام، رصيد البضاعة، والإنفاق من العهدة

**التاريخ:** 2026-11-03 — Africa/Cairo  
**نقطة البداية:** LVE-2026-11-03-605.  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main`.  
**المصدر الأساسي:** `companies/company-1/purchasing/buyer.html`.  
**Production:** SMART ERP — `fiilmooggumokxanwiyx`.  
**التصنيف:** OWNER REQUIREMENTS RECONCILED / CURRENT SOURCE + PRODUCTION READ-ONLY REVALIDATED / IMPLEMENTATION CHANGESETS PREPARED / NO OPERATIONAL OR PRODUCTION WRITE.

## 1. قرار المالك الذي يحكم هذه الدورة

تضيف تعليمات المالك الحالية قواعد أوضح من الافتراضات السابقة، ويجب أن تُبنى عليها التغييرات التالية:

1. كل فاتورة شراء يجب أن ترتبط بمورد موجود في دليل الموردين المركزي بالنظام الأم؛ لا مورد حر ولا مورد وهمي ولا Supplier افتراضي ينشأ من Buyer.
2. «مورد كاش» هو وصف تجاري ورد من المالك. لا يجوز تحويله إلى سجل مورد عام أو Payee غير معتمد. يجب أن يبقى المورد سجلًا مركزيًا، وأن يُفصل نوع المورد عن طريقة التسوية النقدية.
3. فاتورة السوق المباشرة تنشأ أولًا كمسودة بلا أثر مالي أو مخزني، ثم يبحث أمين المخزن عنها برقم الفاتورة في Receiver، ويستلم الفعلي المقبول من مسؤول المشتريات وفق آلية الاستلام المركزية نفسها المستخدمة في PO.
4. تبويب Buyer الذي يسمى حاليًا «رصيد السيارة» يجب أن يصبح «رصيدي»: دفتر حيازة أصناف على مسؤول المشتريات، سواء استلمها بسيارة أم يدويًا. `vehicle_id` اختياري وليس شرطًا.
5. الأصل أن المورد يستلم مرتجعه بنفسه من المخزن. الاستثناء أن يفوض مسؤول المشتريات صراحةً لاستلامه نيابةً عنه؛ عندئذ يسجل المخزن التفويض والتسليم، ثم يقدم مسؤول المشتريات دليل تسليم المورد وإشعار/إيصال القبول إلى الحسابات. لا يُخفض رصيد المورد إلا للكميات التي قبلها المورد فعلًا.
6. يجب الفصل بين شراء البضاعة نقدًا من العهدة، ومصروف التشغيل، وفاتورة المورد الآجلة، والسداد الفعلي. لا يجوز تحويل مصروف نقدي إلى AP أو Supplier Payment مرة ثانية.
7. إصدار النقدية ومتابعة عهد الموظفين ستكون في تطبيق الحسابات لاحقًا، لكن يجب أن تستخدم نفس دفتر العهدة الحالي وRPCs المركزية؛ لا ننشئ دفترًا موازيًا. يبقى تطبيق الموظف مستهلكًا لنفس «عهدتي».
8. لا تعديل لـ`companies/company-1/main.html`، ولا Edge Function جديدة. تُمدد البوابات والعقود الحالية فقط بعد اعتماد التغييرات المحددة.

## 2. ما تم التحقق منه الآن مقابل المصدر الحي

### 2.1 Git / Buyer / Receiver

| العنصر | القيمة الحالية |
|---|---|
| Operational HEAD | `743c9b170bf2314a9e4d64fd4d8104f2cc1aee8c` |
| Parent commit | `2ce93c6d80ec4c38353bdf88880d06ae9e0abdde` |
| Buyer blob | `aee14e6a4edbccd5fb95dff24f21daf1c6d21fcc` |
| Core blob | `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1` |
| Receiver blob | `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6` |
| Warehouse Vouchers blob | `85e709d0f41c189c6624a6160965d3b1a41960ba` |

Buyer ما زال يحتوي التبويبات التسعة القائمة: اليوم، الموردون، طلبات PR، عروض الأسعار، أوامر PO، فواتيري، عهدتي، رصيد السيارة، حسابي. لا إعادة بناء للتبويبات ولا استبدال للتطبيق.

### 2.2 Supplier Master — تعارض مؤكد داخل Buyer

في Buyer الحالي:
- `renderSuppliers()` يعرض زر «مورد جديد».
- `supplierForm()` يسمح بإنشاء وتعديل بيانات المورد.
- الحفظ يرسل `SAVE_SUPPLIER` إلى بوابة `save-purchase-order`.
- مسار اختيار المورد في إنشاء الفاتورة يقرأ قائمة الموردين ويقبل كل سجل لا تكون قيمته `is_active === false`؛ أي أن واجهة الاختيار ليست مطابقة تمامًا لشرط الفعالية الصريح في RPC.

في النظام الأم `main.html`:
- توجد شاشة `RW_Suppliers` مستقلة لإدارة دليل الموردين، وبها إضافة وتعديل وحذف.
- هذا هو الموضع المركزي الحالي لإدارة الموردين، ويجب أن يكون هو مصدر الإنشاء/التعديل وليس Buyer.

في Production:
- جدول `suppliers` يفصل بين `supplier_type` و`payment_type`، ويحتوي `is_active` و`accounts_payable`.
- `save_supplier_atomic(uuid,uuid,text,jsonb,boolean,text)` يتحقق من الشركة وصلاحية `suppliers`/`purchases`، ثم ينشئ المورد الجديد بـ`is_active=true`.
- لا يوجد عمود `approval_status` أو سجل موافقة مستقل في المخطط الذي تمت مراجعته. لذلك المعنى الرسمي لـ`is_active` بوصفه اعتمادًا لم يُثبت؛ يجب عدم تسميته «اعتمادًا» دون قرار من مالك دليل الموردين.
- واجهة Parent تعرض حاليًا خيارات `supplier_type`: مورد عام / مصنع / مورد خارجي، وخيارات `payment_type`: نقدي / أجل. لا يظهر خيار مستقل اسمه «مورد كاش» في هذه القائمة.
- عينة Production المجمعة أظهرت `supplier_type` بقيم `QA` و`مورد عام`، و`payment_type` بقيم `credit` و`آجل` و`نقدي`. لم يظهر سجل خاص بقيمة `supplier_type='مورد كاش'` في العينة الحالية.

**القرار التنفيذي المحافظ:** Buyer يتحول إلى قارئ/باحث في سجل الموردين المركزي فقط، ويختار سجلًا فعالًا معتمدًا وفق حالة الاعتماد التي يثبتها النظام الأم. لا إنشاء ولا تعديل ولا حذف مورد من Buyer. ولا ينشأ مورد نقدي عام أو اسم مورد حر. أما «مورد كاش» كنوع مستقل فيلزم أولًا أن يكون قيمة معتمدة ومدارة في النظام الأم؛ لا يمكن أن نضيف خيارًا جديدًا إلى Parent مع التزام عدم لمس `main.html`. وفي الوقت الحالي يبقى `payment_type='نقدي'` شرط تسوية للمورد المركزي المسجل، ولا يخلط مع `supplier_type`.

### 2.3 Quick Market Purchase — الحالة الفعلية

- `quickPurchase()` لا ينفذ دورة سوق؛ إنه alias مباشر لـ`createPurchaseInvoice()`.
- إنشاء الفاتورة بلا PO ممكن، لكنه ينتج `Draft` فقط.
- `purchase_create_invoice_atomic` يتحقق من أن المورد موجود ونشط داخل الشركة، ويتحقق من الفرع والعملة والأصناف، ثم ينشئ المسودة وبنودها. لا ينشئ حركة مخزون أو AP أو خزينة أو Journal.
- `purchase_post_invoice_atomic` يرفض الفاتورة بلا PO حاليًا بالخطأ `PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED`.
- لا يوجد حاليًا حقل مصدر/نوع يميز شراء السوق عن فاتورة عامة بلا PO، ولا مصدر تسوية صريح يميز نقدية العهدة عن الشراء الآجل.
- `purchase_invoice_details.notes` موجود ويمكن أن يحمل مواصفات البند نصيًا؛ أما صور الفاتورة وصور كل بند فتحتاج عقد مرفقات وStorage آمنًا.

### 2.4 Receiver — العائق الحقيقي

- `receiver.html` يعرض حاليًا أوامر PO فقط بحالات Sent/Partially Received.
- يستدعي Edge `receive-purchase` v13 بمدخل `po_code` و`itemsReceived` فقط.
- RPC `receive_purchase_atomic(uuid,text,text,jsonb,uuid)` يقبل PO code فقط، ويقفل PO وسطورها، ويتحقق من الكميات والفرع والصلاحية، ثم يكتب receiving/details وحركة `PurchaseIn` والمخزون والدفتر المالي/المورد وفق عقد PO.
- جدول `receiving` لا يحتوي `purchase_invoice_id` أو `source_type`، وجدول `receiving_details` لا يحمل `purchase_invoice_detail_id`.
- في `loadPODetails()`، عند السطر التقريبي 254، يستخدم المصدر `.eq('po_code', code)` على `purchase_order_details` رغم أن العمود الرابط في Production هو `po_id`. هذا تعارض مصدر/مخطط مثبت، ويجب إصلاحه ضمن تعديل Receiver.
- ملف المصدر التشغيلي لـ`receive-purchase` v13 غير موجود في `erp-frontend`، واللقطة الموجودة في مستودع الحوكمة أقدم وغير مطابقة لبصمة Production.

**النتيجة:** لا يمكن إضافة بحث سريع في Buyer وحده والادعاء أن المخزن يستطيع استلام فاتورة السوق. يجب استعادة مصدر Edge v13 الحي مطابقًا إلى Git أولًا، ثم توسيع Edge الحالية وRPC الحالي/المعتمد ليميز PO عن Quick Invoice مع حفظ مسار PO كما هو. ممنوع إنشاء Edge Function جديدة.

### 2.5 «رصيدي» / Goods Custody

- `renderVehicleBalance()` يقرأ `fleet_vehicle_assignments` و`vehicles` اعتمادًا على `driver_user_id` للمستخدم الحالي.
- يعرض المصدر صراحة أن دفتر عهدة بضاعة المشتريات غير مفعل.
- هذا ليس رصيد المشتري: تعيين سائق أو وجود مركبة Delivery لا يثبت تسليم البضاعة إلى مسؤول المشتريات.
- Production لا يحتوي في المخطط المفحوص على دفتر حركات مستقل لعهدة بضاعة المشتريات.
- Trigger `enforce_stock_voucher_custodian()` يمسح `custodian_user_id` لسند SupplierReturn، ولا يسمح بالعهدة إلا في DirectSale/DirectReturn، ويشترط فيهما مندوبًا ومركبة.

**القرار:** رصيد المستخدم من مجموع حركات بضائع موثقة، لا من Fleet ولا من سيارة بيع. السيارة/المركبة وسيلة نقل اختيارية، والتسليم اليدوي مسموح. يجب أن يكون الدفتر Append-only وتُشتق الأرصدة منه، ولا تعدل كمية الرصيد مباشرة.

### 2.6 SupplierReturn — ازدواج حقيقي في مسارات النظام

يوجد مساران حاليان:
1. `purchase_returns` و`purchase_return_details` عبر Parent و`save-purchase-order` وRPCs المشتريات.
2. `stock_vouchers.SupplierReturn` عبر Warehouse Vouchers.

المسار الأول يخصم المخزون ويخفض Supplier AP عند POST_RETURN. والمسار الثاني يخصم مخزون الفرع عند SEND ويولد دفتر مورد وقيدًا ماليًا كاملًا عند COMPLETE. لم يثبت ربط ذري يمنع تكرار المخزون أو AP/GL إذا استُخدم المساران لنفس المرتجع.

لا يتوفر حاليًا accepted/rejected qty على مستوى كل بند، ولا إلزام لإثبات استلام المورد قبل إكمال الخصم المالي. كما أن Trigger عهدة السند يمنع تعيين مسؤول المشتريات كحائز في SupplierReturn. واجهة Warehouse Vouchers/العقد الحاليان يستخدمان افتراضي SAR في مسار المرتجع رغم أن عملة الشركة EGP.

**القرار:** مرجع تجاري واحد للمرتجع، وكاتب واحد لحركة المخزون، وكاتب واحد لخفض المورد/القيد. إصدار المخزن إلى المشتري ينقل الكمية من مخزون الفرع إلى عهدة المشتري فقط. قبول المورد يسجل accepted_qty ويخفض رصيد المورد مرة واحدة على هذه الكمية. المرفوض يبقى بعهدة المشتري إلى أن يعاد للمخزن أو يسوى بتصرف موثق. عند استلام المورد بنفسه، يسجل المخزن واقعة التسليم والقبول مباشرة. لا يُعتمد المساران القديمان بالتوازي دون مفتاح ربط idempotent.

### 2.7 Cash Custody — الفرق بين العهدة النقدية ومصروفها

الموجود في Production:
- جداول `buyer_custodies`, `buyer_custody_advances`, `buyer_custody_expenses`, `buyer_custody_payments`, `buyer_custody_settlements` وRPCs مركزية موجودة.
- إصدار العهدة والزيادة ينتظران إقرار الموظف؛ الأثر النقدي/المحاسبي لا يحدث إلا بعد إقرار صاحب العهدة.
- `buyer_custody_review_expense_atomic` الحالي ليس مراجعة مصروف عام: يشترط Supplier + PO + Draft Invoice + Receiving، ثم ينشئ Supplier Payment، ويحول الفاتورة Paid، ويسجل Supplier Ledger debit وJournal Dr Supplier AP / Cr Employee Custody.
- `buyer_custody_expenses` لا يحتوي `expense_category` أو `expense_account_id` أو `payee_kind`.
- دليل التخزين الحالي هو bucket خاص `employee-documents` بسياسات لمسارات `buyer-custody`؛ لا يوجد مسار Buyer purchase attachments آمن مثبت. `purchase_attachments` جدول metadata موجود، و`purchase_document_links` موجود، لكن وجود الجدول لا يثبت أن تخزين الصورة وقراءتها ورفعها وحذفها محكومة وآمنة.
- الحسابات الحالية في COA تشمل 121 النقدية، 124 المخزون، 127 عهد الموظفين، 211 الموردين، 5 المصروفات وتكلفة المبيعات، 51 تكلفة المبيعات، 52 فروقات/تسويات المخزون. لا توجد في قائمة الحسابات المفحوصة حسابات مستقلة صريحة للوقود والنقل.

**القرار:**
- PURCHASE من العهدة: يربط بالفاتورة وبإذن استلام فعلي؛ المقبول فقط يدخل المخزون، ويقابل حساب عهدة الموظف، دون إنشاء AP أو Supplier Payment ثانيًا إذا كان المورد قد حصل على النقد بالفعل.
- FUEL/TRANSPORT/OTHER: مصروف تشغيل؛ لا مخزون ولا Supplier Ledger افتراضيًا ولا Payment مورد. يلزم حساب مصروف نشط معتمد من المالية لكل فئة قبل الترحيل.
- Supplier Credit: التزام مورد على الحساب، ويظل ضمن مسار المشتريات/الفاتورة/الاستلام، ثم سداد مستقل بعد دليل التسليم الفعلي للنقد أو المستند المالي.
- يجب عدم خصم النقدية من Treasury مرتين: الصرف الأصلي للعهدة حدث منفصل عن تسوية المصروف من رصيد Employee Custody.

## 3. بيئة الاختبار — هل يوجد مكان آمن للبيانات التجريبية؟

تم التحقق من المشاريع المتاحة في Supabase:

| المشروع | الحالة | الملاحظات |
|---|---|---|
| SMART ERP (`fiilmooggumokxanwiyx`) | ACTIVE_HEALTHY | Production الحالي، 737 migrations، EGP |
| rawaea-staging (`hfzznsiprnwkpayskzhu`) | ACTIVE_HEALTHY | 62 migrations فقط، 70 جدولًا عامًا، ولا يحتوي `purchase_invoices` أو `purchase_invoice_details` أو جداول عهدة Buyer |

في `rawaea-staging` توجد جداول PO وReceiving وStock Vouchers، لكن مخططه أقدم ولا يطابق دورة مشتريات Buyer الحالية. لذلك ليس بيئة E2E صالحة لهذه المهمة الآن. لا يجوز نسخ معاملات Production إلى بيئة أخرى أو إنشاء fixtures في Production لمجرد تجاوز هذه الفجوة. يلزم إعادة تأسيس/مزامنة Staging من النسخ المعتمدة بعد موافقة مستقلة وخطة إخفاء البيانات، أو توفير اختبار محلي/فرع معزول يطابق مخطط Production.

## 4. PR #10 — ما الذي يمكن الاستفادة منه؟

- PR #10 في `erp-frontend` ما زال Draft / Open / Not Merged.
- Branch: `cto/buyer-field-workbench-lve-587`; head: `209c318f2324d741e61b0dceaf5253f830af8c2e`.
- التغيير يقتصر على Buyer ويضيف تحسينات موبايل/بحث واختيار الأصناف وبعض الفلاتر؛ لا ينفذ استلام فاتورة السوق ولا دفتر عهدة البضاعة ولا تصنيف المصروفات.
- جزء فلترة الفواتير بـ`created_by` للمستخدم الحالي لا يحقق الرقابة الموحدة المطلوبة؛ سيحجب فواتير الموظفين الآخرين عن المالية/المحققين ما لم يكن هناك Server-side role-scoped oversight.
- Branch/PR base أقدم من Operational HEAD الحالي؛ لا يدمج مباشرة. يمكن إعادة استخدام أجزاء UX النافعة بعد rebase وفحص الأثر والصلاحيات.

**القرار:** لا Merge ولا إسقاط لعمل PR10. يعاد استخدام الأجزاء الجيدة بعد مراجعة دقيقة، وتُرفض فلترة «فواتيري» على المستخدم فقط؛ المطلوب عرض بحسب الدور والصلاحية، مع صلاحية رقابية مركزية لFinance/Audit.

## 5. البنية الوظيفية المقترحة — القلب المركزي الموحد

### 5.1 Workstream A — Master Supplier Authority + Buyer read-only

1. حذف قدرة Buyer على إنشاء/تعديل/حذف الموردين؛ يبقى تبويب الموردين عرضًا وبحثًا وسجلًا تشغيليًا للمورد المركزي.
2. يجب أن يرجع بحث المورد فقط سجلات الشركة التي `is_active=true` وبعد تثبيت معنى الاعتماد في Master Data. لا تعتمد الواجهة وحدها؛ RPC إنشاء الفاتورة يظل يتحقق من المورد/الشركة/الفعالية.
3. يظهر في نتيجة المورد: الكود والاسم والنوع وشروط الدفع ورقم الاتصال والمنطقة والفرع/المندوب إن وجد، مع بيان واضح نقدي/آجل من Master Data.
4. لا تنشئ «مورد كاش» آليًا ولا Supplier وهميًا. إذا كان `مورد كاش` تصنيفًا تجاريًا مستقلًا، يجب إدراجه مركزيًا في Supplier Master أولًا. وبما أن تعديل `main.html` ممنوع، لا ننفذ خيارًا جديدًا من Buyer يغيّر سجل Master.

### 5.2 Workstream B — Quick Market Invoice

الكيان يظل `purchase_invoices` نفسه حتى لا تصبح كل عملية سوق جزيرة منفصلة. يضاف له تمييز مصدر صريح مثل `purchase_source` (PO / QUICK_MARKET) و`settlement_source` (SUPPLIER_CREDIT / EMPLOYEE_CUSTODY / TREASURY_CASH) وفق سياسة مالك الحسابات. يبقى `supplier_id` إلزاميًا حسب تعليمات المالك؛ لا Payee حر في هذا المسار.

حقول رأس الفاتورة التي يلزم إكمالها عند السوق: رقم المورد، رقم الفاتورة، تاريخها، الفرع/المخزن، مسؤول المشتريات، نوع المصدر، طريقة التسوية، مرجع العهدة إن كانت من العهدة، العملة من إعدادات النظام (EGP)، الخصم والضريبة، الإجمالي، ملاحظات. حقول البند: item_id/code/name، وصف ومواصفات، الوحدة، الكمية، سعر المورد الفعلي، الخصم، الضريبة، accepted/received/rejected qty، ملاحظات البند، وصور المنتج/الفاتورة عند الحاجة.

كل إنشاء يحفظ Draft فقط. لا stock ولا supplier ledger ولا treasury ولا journal. Operation ID ثابت على مستوى محاولة المستخدم ويحفظ لإعادة المحاولة ذاتها؛ لا يولد مفتاح جديد عند retry.

### 5.3 Workstream C — Receiver Quick Invoice Receipt

1. توسيع Receiver الحالي ليعرض PO وفواتير السوق غير المستلمة في قائمتي بحث متصلتين/موحدتين.
2. البحث برقم الفاتورة الداخلي، رقم فاتورة المورد، أو اسم/كود المورد؛ اختيار السجل يرجع إلى الفاتورة المسجلة في النظام لا إلى إدخال رقم حر.
3. تحميل سطور الفاتورة من `purchase_invoice_details` عبر invoice_id، وإظهار ordered / received / remaining / accepted / rejected.
4. إضافة علاقات صريحة في `receiving` و`receiving_details` تربط رأس الاستلام بالفاتورة وسطورها، مع `source_type` و`purchase_invoice_id` و`purchase_invoice_detail_id` وoperation_id/fingerprint.
5. دعم الاستلام الجزئي والتكرار الآمن، والتحقق من الشركة والفرع وهوية أمين الاستلام/دوره ونطاقه؛ تصحيح PO detail query من `po_code` إلى العلاقة الفعلية `po_id` دون كسر PO الحالي.
6. زيادة مخزون الفرع للكميات المقبولة التي اعتمدها أمين المخزن فقط. لا تدخل المرفوضة/التالفة في available_qty. يكتب `inventory_log` مرة واحدة عبر محرك المخزون المركزي.
7. تمييز المقابل المالي بحسب settlement_source: شراء نقدي من عهدة الموظف لا ينشئ Supplier AP أو Supplier Payment؛ الشراء الآجل يعترف بالالتزام مرة واحدة في حدثه المعتمد؛ دفع Treasury لا يحدث إلا مع دليل تسليم نقد/مستند فعلي.
8. توسيع `receive-purchase` v13 وRPC الحالي/العقد المركزي المطلوب فقط؛ لا Function جديدة. يجب أولًا إدراج مصدر v13 الحي المطابق لبصمته في operational Git.

### 5.4 Workstream D — Buyer «رصيدي» / Goods Custody Ledger

تصميم دفتر حركات مركزي Append-only، مثل `buyer_goods_custody_events` + `buyer_goods_custody_event_lines` (الأسماء المقترحة لا تعني إنشاءها الآن). يحتوي على:

- company_id, custodian_user_id, branch_id, vehicle_id NULLABLE.
- movement_type: SUPPLIER_TO_BUYER, BUYER_TO_WAREHOUSE, WAREHOUSE_TO_BUYER_RETURN, BUYER_TO_SUPPLIER, BUYER_RETURN_TO_WAREHOUSE.
- source_document_type/id, supplier_id, purchase_invoice_id أو purchase_return_id، item_id, item_code, unit, qty, unit_cost/currency عند الحاجة.
- from_party/to_party، warehouse/branch، actor، event_at، acknowledged_by/at، notes، evidence_path، operation_id، payload fingerprint.

قواعد الحركة:
- المورد→المشتري: إثبات انتقال الحيازة للمشتري؛ لا تزيد مخزون الفرع لمجرد هذه الحركة.
- المشتري→المخزن: أمين المخزن يقبل الفعلي؛ المخزون يزيد بالمقبول فقط، وتقل عهدة المشتري بالمقبول.
- المخزن→المشتري لمرتجع: stock decreases عند إذن الصرف المادي؛ عهدة المشتري تزيد بالكمية المصروفة.
- المشتري→المورد: لا تُغلق عهدة المرتجع ولا ينخفض AP إلا بالكمية التي أثبت المورد قبولها؛ المقبول الجزئي فقط هو الذي ينتقل ماليًا.
- إرجاع المرفوض للمخزن: stock increases عند قبول أمين المخزن؛ تخفض عهدة المشتري مرة واحدة.
- المركبة اختيارية؛ عدم وجود سيارة لا يمنع التسجيل.

الرصيد في Buyer يشتق من صافي الأحداث، مع عرض الكمية تحت الحيازة، المقبولة بالمخزن، المصروفة كمرتجع، المقبولة من المورد، المرفوضة، والمعادة للمخزن لكل صنف ووحدة/مستند.

### 5.5 Workstream E — Supplier Return Single Writer

يظل Parent يرى `purchase_returns` كمرجع تجاري، ويظل Warehouse يسجل الإذن المادي، لكن يجب ربطهما بمفتاح أصل واحد `purchase_return_id`/source key. يجب تحديد كاتب واحد فقط لحركة Stock Writer وكاتب واحد فقط لتخفيض Supplier AP/GL؛ لا يُسمح أن ينفذ `POST_RETURN` و`complete_manual_stock_voucher_atomic` الأثر نفسه مرتين.

يدعم العقد: Supplier Pickup (المورد يستلم مباشرة من المخزن) أو Buyer Representative (تفويض صريح للمشتري). يثبت المخزن نوع التسليم والجهة المستلمة والكمية الفعلية، ويُلزم إيصال المورد/إشعار الاستلام/الإشعار الدائن أو المستند المالي المعتمد. كل سطر يحمل requested, issued, accepted, rejected, returned_to_warehouse quantities. ويطبق cumulative return guard على إجمالي المرتجع مقابل الكمية المستلمة الأصلية مع قفل وتزامن وoperation_id ثابت.

لا يرحل تخفيض المورد إلا على accepted_qty وبما لا يتجاوز صافي الكمية المؤهلة بعد المرتجعات السابقة. يظل المرفوض بعهدة المشتري حتى التسوية. العملة تُقرأ من إعدادات النظام ولا تثبت SAR.

### 5.6 Workstream F — Custody Expenses / Cash Custody

حقول وتصنيفات مقترحة في نفس دفتر العهدة الحالي: `expense_category` = PURCHASE / FUEL / TRANSPORT / OTHER، و`payee_kind`، و`expense_account_id`، مع مستندات ومرفقات ومرجع عهدة وbranch/cost center وreviewer/review date وoperation_id.

- PURCHASE: يربط فاتورة السوق وإذن الاستلام؛ عند قبول البضاعة يسجل المخزون والمقابل من أصل العهدة. لا Supplier AP/Payment إذا كان المورد قد حصل على النقد.
- FUEL / TRANSPORT / OTHER: لا مخزون ولا Supplier AP افتراضيًا؛ لا تنشئ Supplier Payment. يعتمد المصروف المالي على حساب مصروف نشط ومعتمد من Finance.
- Supplier Credit / PO: تبقى فاتورة المورد على الحساب في دورة AP؛ مراجعة سند عهدة لا تحولها تلقائيًا إلى Paid.
- Cash Custody issue/advance/ack/settlement تظل عبر الجداول والـRPCs الحالية. لاحقًا يضيف Accounts modal إصدار/متابعة الموظفين فوق نفس الكيان، ويظهر لموظف المشتريات في `عهدتي`. لا جدول نقدي موازي.

**قيد محاسبي مهم:** COA الحالي في Production يعيد 121، 124، 127، 211، 5، 51، 52 فقط في قائمة الحسابات المفحوصة؛ لا توجد حسابات مستقلة ظاهرة للوقود/النقل. لا نخترع mappings. يجب على Finance إعداد حسابات المصروفات/مراكز التكلفة مركزيًا ثم يعتمد RPC الفئة على account_id صالح من نوع expense.

## 6. إصلاحات Buyer المباشرة المطلوبة بعد اعتماد Change Set

| الموضع الحالي | التعديل المطلوب |
|---|---|
| `renderSuppliers()` | إزالة زر «مورد جديد»، عرض سجلات Master فقط، بحث خادمي/ترقيم، إظهار الحالة والنوع/شروط الدفع من المصدر المركزي |
| `supplierForm()` و`openSupplier()` | إزالة الإنشاء/التعديل/الحذف من Buyer؛ الاحتفاظ بملف مورد للقراءة فقط مع انتقال إلى واجهة Master المعتمدة عند الحاجة |
| اختيارات المورد في `createQuotation()` و`createPO()` و`createPurchaseInvoice()` | لا تعرض إلا الموردين الصالحين مركزيًا، ولا تسمح بتحديد حر أو حفظ supplier_id غير فعال؛ Server validation يظل هو الحاكم |
| `quickPurchase()` | إنشاء تجربة Quick Market Purchase مستقلة مرتبطة بكيان الفاتورة نفسه، وليست alias إلى فاتورة عامة |
| `createPurchaseInvoice()` | حقول المصدر/التسوية/المواصفات/المرفقات ومفتاح retry ثابت؛ تظل Draft بلا أثر حتى الاستلام |
| `renderVehicleBalance()` / tab `vehicle` | تحويل الاسم والعرض إلى «رصيدي» ويقرأ دفتر حيازة الأصناف لا Fleet assignments |
| `submitCustodyExpense()` | نماذج حسب نوع المصروف؛ لا تفرض PO لكل عملية؛ لا تستخدم RPC المخصصة لدفع فاتورة مورد على أنها مصروف عام |
| `issueCustody()` / `acknowledgeCustody()` | تصحيح رسالة الواجهة والـtoast لتوضيح أن الإصدار Pending حتى إقرار الموظف؛ نقل تحكم إصدار العهدة إلى Accounts عند توفره دون فقد سجل Buyer الحالي |
| `renderInvoices()` | عرض رقابي بحسب الصلاحية؛ لا تقصر فواتير النظام على `created_by` فقط؛ Pagination/Search server-side |

لا يطبق أي صف في هذا الجدول على operational `main` في هذه الدورة؛ هذه قائمة تغييرات مصدرية دقيقة للمراجعة. كما لا يعاد تنفيذ إصلاح السعر الفارغ/عدم استخدام cost_price و`operation_id` الموجود بالفعل في Buyer.

## 7. PR #10 — الحفاظ على العمل السابق دون اعتماد أخطائه

PR #10 ما زال Draft / Open / Not Merged، في ملف Buyer فقط، وعلى فرع `cto/buyer-field-workbench-lve-587` وبـhead `209c318f2324d741e61b0dceaf5253f830af8c2e`. يقدم تحسينات موبايل وبحث الأصناف والصورة/الباركود والفلاتر، لكنه لا يغلق عقود Receiver أو Goods Custody أو Expense. فرعه مبني على base أقدم من Operational HEAD الحالي، لذلك لا يدمج مباشرة. كما أن حصر `renderInvoices()` في `created_by` للمستخدم الحالي يمنع Finance/Audit من رؤية الدورة كاملة، ويتعارض مع الرقابة الموحدة. تُعاد الاستفادة من تحسينات UX بعد rebase وتعديل نموذج الصلاحيات.

## 8. مصفوفة E2E المطلوبة بعد تجهيز Staging صالح

1. Supplier: مورد Master نشط/معتمد يظهر؛ مورد غير فعال/شركة أخرى لا يظهر ولا تقبله RPC؛ لا إنشاء مورد من Buyer.
2. Draft: إنشاء Quick Market Invoice برقم المورد وتفاصيله وEGP ومرفقاته؛ يجب ألا يتغير stock_branches أو inventory_log أو supplier_ledger أو journal_entries أو treasury/cash_box.
3. Receiver: البحث برقم الفاتورة الداخلي ورقم المورد؛ قبول جزئي؛ رفض/تالف؛ إعادة المحاولة بنفس operation_id؛ no duplicate receiving/stock/GL.
4. Branch: مقارنة stock_branches قبل/بعد؛ المقبول فقط يزيد المخزون؛ الفارق المرفوض لا يزيد available_qty.
5. Cash Purchase: استلام سوق مدفوع من عهدة المشتري؛ المخزون يقابل حساب العهدة حسب السياسة، ولا Supplier AP أو Supplier Payment مزدوج.
6. Supplier Credit: استقبال بضاعة على الحساب ينشئ الالتزام مرة واحدة حسب السياسة؛ invoice posting لاحق لا يكرر inventory/AP.
7. Goods custody: Supplier→Buyer→Warehouse؛ ثم Warehouse→Buyer→Supplier أو Warehouse→Supplier مباشرة؛ vehicle_id nullable؛ hand carry works.
8. Supplier Return: قبول كامل/جزئي/رفض؛ تخفيض AP فقط accepted_qty؛ rejected qty remains in buyer balance or returns to warehouse; retry and concurrent submissions cannot exceed source received qty.
9. Cash Expenses: FUEL/TRANSPORT/OTHER؛ إثبات وموافقة Finance؛ حساب مصروف صالح؛ لا Supplier Ledger/Payment؛ no duplicate Treasury event.
10. Cash Custody: issue لا يرحل قبل employee ACK؛ الآخرون مرفوضون؛ settlement cash returned equals acknowledged advances less accepted expenses; receipt evidence required.
11. Authorization/Tenant: no permission, wrong company, wrong branch, wrong employee/custodian, unauthorized Buyer acting for supplier; all rejected without side effects.
12. Regression: PO receipt current path, Buyer, Receiver, Parent reads, Supplier Ledger, finance reports, warehouse vouchers, delivery/driver/van-sales, Realtime.
13. Runtime: source and deployed Cloudflare blob parity, authenticated Browser session, console/network checks, and DB snapshots before/after.

لا تجرى هذه الاختبارات على Production ببيانات مالية أو مخزنية حقيقية أو تجريبية.

## 9. لماذا لا يمكن الادعاء بأن E2E اكتمل الآن؟

- Production مناسب للعمل الحقيقي ولا يجوز أن نخلق فيه فواتير/حركات/قيود اختبارية لمجرد إثبات الواجهة.
- مشروع `rawaea-staging` الحالي يحتوي 62 migration و70 جدولًا عامًا، ولا يحتوي purchase_invoices أو purchase_invoice_details أو buyer_custody_*؛ لذلك لا يمثل نسخة مخطط Production الحالية ولا يصلح لاختبار دورة Buyer كما هي.
- لم يتم حتى الآن مزامنة Staging إلى مخطط Production الحالي أو توفير test fixtures بمستخدمي Receiver/Buyer/Finance في بيئة معزولة.
- لا توجد في هذه الدورة جلسة Browser مصادق عليها لاختبار Buyer وReceiver، ولا artifact Cloudflare مطابق للـBuyer blob مثبت.

إذًا static/source/schema analysis مكتمل لهذا النطاق، لكن authenticated E2E وبيانات workflow الفعلية لم تُنفذ. أي ادعاء بعكس ذلك غير صحيح.

## 10. ما أُنجز في هذه الدورة وما لم يُنفذ

### أُنجز
- تحديث السياق من LVE-605 وReports603/604/605 وMaster CTO.
- إعادة جلب Buyer/Receiver/Parent blobs والـEdge live versions وProduction schema/RPC/RLS/ACL/COA/Storage.
- إثبات أن Buyer يسمح بإدارة الموردين بنفسه رغم أن المالك حصر Master في النظام الأم.
- التحقق من وجود Supplier CRUD مستقل في النظام الأم، لكن دون approval_status منفصل ظاهر في المخطط.
- التحقق من أن Staging غير مكافئ لمخطط Production ولا يصلح لاختبارات Buyer الحالية.
- تثبيت التصميم المتكامل المطلوب لحركة السوق والاستلام وحيازة البضاعة والمرتجع والمصروف النقدي.
- إعداد Report606 وتحديث CURRENT_STATE وExecution Log وProject Memory.

### لم يُنفذ
- لم يُعدل `buyer.html` أو Receiver أو Warehouse Vouchers أو `main.html`.
- لم يُعدل save-purchase-order v22 أو receive-purchase v13، ولم تنشأ Edge Function جديدة.
- لم تُنفذ Migration/RPC/Trigger/RLS/ACL/Grant ولا أي تحديث بيانات في Production أو Staging.
- لم تُنشأ بيانات اختبار ولم تُغير stock_branches أو supplier_ledger أو journal_entries أو treasury أو cash_box.
- لم يتم merge لـPR #10، ولم يتم نشر Cloudflare، ولم يجر authenticated E2E.

## 11. بوابة التنفيذ التالية وفق Master §77.2

هذه الدورة حسمت التصميم التجاري وحددت المواضع المتعارضة، لكنها لم تنتج بعد حزمة `SQL + source diff + effects + tests + rollback` النهائية كاملة لكل Workstream. ولذلك لا يُكتب على `erp-frontend/main` ولا يُغير Production الآن.

التنفيذ الصحيح التالي مقسم إلى Change Sets مترابطة:

- **A — Buyer Master Authority & UI:** Buyer supplier list becomes read-only, central active supplier lookup only, no local creation/edit/delete; rebase usable PR10 UX changes without user-only invoice visibility.
- **B — Quick Market Invoice + Receiver:** source/settlement fields, invoice & line attachments, Receiver no-PO receive through existing `receive-purchase` v13 + authenticated RPC; restore v13 source parity first; preserve PO route.
- **C — Buyer Goods Custody / «رصيدي»:** append-only item custody event ledger, optional vehicle, warehouse acceptance, supplier return handover and return-to-warehouse.
- **D — Supplier Return Single Writer:** unify `purchase_returns` + SupplierReturn stock voucher; cumulative qty control; supplier accepted/rejected partial quantities; acceptance evidence; one stock writer and one AP/GL writer.
- **E — Cash Custody Expense Types:** PURCHASE/FUEL/TRANSPORT/OTHER, central expense account mapping, custody review/settlement without supplier AP/Payment duplication; later Accounts UI reuses same custody entity.

كل حزمة تعرض قبل التنفيذ: الملف/الدالة/العلامة، Full diff، SQL/Migration، أثر المخزون والخزينة والمورد والعهدة والقيود، الاعتماديات والفشل والتزامن، قبول/رفض، rollback وخطة E2E في Staging مطابق. بعد ذلك يلزم اعتماد المالك الصريح للتغيير المحدد.

**أولوية المصدر الآمنة:** يبدأ Change Set A بإلغاء إدارة الموردين من Buyer وجعله قارئًا لسجل النظام الأم، مع عدم المساس بـ`main.html`. ولا تُفتح Quick Market/Receiving حتى يتضمن نفس الحزمة عقد الاستلام والمقابل المحاسبي ومنع الازدواج.

## 12. الاستمرارية لمساعد CTO التالي

ابدأ من LVE-606 في أعلى `CURRENT_STATE.md`، ثم هذا التقرير، ثم Master CTO §§29 و32 و58–60 و77.1–77.4. ارجع إلى Report605 للتصميم التجاري، Report604 لإثبات مستهلكي المرتجعات، Report603 لفجوة التراكم والقبول، Report602 للمطابقة السابقة. أعد جلب Operational HEAD والـblobs وProduction Edge/RPC/schema قبل أي تنفيذ.

لا تعِد P0 controls المطبقة في 20261103155029 و20261103155444 و20261103160902. لا تدمج PR #10 كما هو. لا تعتبر `is_active` اعتمادًا رسميًا قبل تثبيت معناه في Master. لا تخلق موردًا افتراضيًا ولا Payee حرًا. لا تحسب Fleet/Delivery Van Stock على أنه رصيد مشتريات. لا ترحل مرتجعًا على كامل الكمية قبل إثبات قبول المورد. لا تستخدم Staging الحالي لـE2E Buyer قبل مواءمة المخطط. لا تلمس `main.html` ولا تنشئ Edge جديدة.

**الحكم النهائي:** تمت مطابقة تعليمات المالك الجديدة مع المصدر والـProduction، وأصبح مسار التنفيذ محددًا. لكن Buyer لم يُعدّل في operational Git ولم يتم تنفيذ مخطط أو E2E. الحزم A–E جاهزة للانتقال إلى إعداد diffs/SQL كاملة واعتمادها واحدةً تلو الأخرى. **STATUS: CHANGESETS REQUIRED / APPROVAL GATE OPEN / BUYER NOT PRODUCTION-READY.**