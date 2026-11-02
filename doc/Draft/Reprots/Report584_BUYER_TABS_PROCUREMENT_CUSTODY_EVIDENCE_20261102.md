# Report584 — إعادة تدقيق Buyer / دورة عهدة المشتريات والمركبة / فواتيري وعروض الأسعار

**التاريخ:** 2026-11-02 — Africa/Cairo  
**المعرف:** LVE-2026-11-02-584  
**المستودع التشغيلي:** papamohammed77-glitch/erp-frontend — main  
**آخر HEAD مرصود مباشرة:** aa8cbffbfa8d42253726381080dcfc24eaea838b  
**Supabase Production:** SMART ERP — fiilmooggumokxanwiyx  
**الحالة:** التبويبات الأربعة موجودة؛ فواتيري وعروض الأسعار وعهدتي لها أساس وظيفي؛ رصيد السيارة لا يملك دفتر عهدة مشتريات؛ عقد انتقال البضاعة المورد → المشتري/المركبة → المخزن غير موجود؛ فجوات إثبات التسليم النقدي والتكامل قائمة؛ لا تعديل تشغيلي أو إنتاجي في هذه الجولة؛ NOT CLOSED.

---

## 1. نقطة البداية — LAST VERIFIED EVENT وهدف هذه الجولة

بدأت من CURRENT_STATE.md كاملًا قبل فتح تقارير المهمة أو ملفات التطبيق.

**LAST VERIFIED EVENT السابق — LVE-2026-11-02-583:**
- سجل Buyer يفتح تفاصيل الفاتورة عند الضغط على الصف.
- التبويبات الأربعة محل الطلب موجودة بالفعل في Buyer.
- رصيد السيارة الحالي واجهة توضيحية لا تمثل عهدة مشتريات.
- الأرصدة والحركات المرئية في فروع السيارات الحالية تخص التوصيل/البيع المباشر، لا تسليم مشتريات للمشتري.
- لا توجد تعيينات مشتريات للمركبات ولا stock vouchers مرتبطة بعهدة مشتريات.
- فجوات إثبات الدفع الفعلي للمورد وتسليم/استلام النقد للعهدة ما زالت مفتوحة.

**نقطة البداية المسجلة:** CURRENT_STATE blob قبل التحديث = e45c9297df742fa703537b8643ab9610f30fe58c (619,528 حرفًا / 3,996 سطرًا).  
**الهدف الحالي:** إثبات ما تنفذه التبويبات الأربعة بالفعل، واستعادة بقية المتطلبات السابقة، وتتبع المستهلكين والعقود في Buyer وDriver وEdge وSupabase، ثم تحديد ما يلزم تغييره دون خلط عهدة المشتريات بعهدة مندوب التوصيل أو إحداث أثر مالي/مخزني غير مثبت.

**المراجع التاريخية المهمة التي أُعيد فتحها:** Reports 342/343 (SupplierReturn)، 368/372 (Van Sales custody and vehicle balance), 567، 569، 570، 571، 574، 579، 580، 581، 583، إضافة إلى MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS §77.

## 2. CONFIRMED — الحالة الحالية في المصدر والقاعدة

### 2.1 GitHub / Source

- Operational repository: papamohammed77-glitch/erp-frontend؛ branch main.
- تم جلب commit الفرع main مباشرةً: aa8cbffbfa8d42253726381080dcfc24eaea838b — message: build: compile Buyer Tailwind CSS — 2026-11-02T15:16:44Z.
- Buyer الحالي: companies/company-1/purchasing/buyer.html — blob 73d746571a10b1720bdd31631004abce0ac9afa1 — 1,047 سطرًا.
- Driver الحالي: companies/company-1/delivery/driver.html — blob 92ae03678b6516345a61d30bb5967046096d8cce — 1,761 سطرًا.
- app router: companies/company-1/app.html — blob 2e47a68fe83956e27d569e786a08dcee91af2924.
- Edge source: supabase/functions/save-purchase-order/index.ts — blob bc038be8c60a3d593f604c7b2ae445e807bacf57 — 23,077 حرفًا.
- تم جلب Edge function المنشورة من Supabase ومقارنتها بالمصدر: save-purchase-order v22 ACTIVE / verify_jwt=true / exact_content_match=true / SHA-256 = a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb.
- التطبيق الأم يوجه صلاحية purchases إلى Buyer، وصلاحية delivery إلى Driver؛ لكل منهما مسار تشغيل مستقل. لم تُعد كتابة Parent أو Core أو Driver.
- لا توجد مجلدات مصدر تشغيلية في supabase/functions لمجموعة create/send/receive/complete/cancel-stock-voucher، رغم وجود هذه الوظائف في Production. توجد نسخ تاريخية جزئية في rawaie-erp-New/Current/Edge_Functions؛ لا تكفي لاعتبارها مصدر النشر الحالي، وبعضها ناقص/قديم. يجب استعادة المصدر المنشور الصحيح إلى operational repo قبل توسيع هذه العقود أو تعديلها.

### 2.2 التبويبات الأربعة — الموجود مقابل الناقص

| التبويب | CONFIRMED — الموجود في Buyer | الفجوة المثبتة |
|---|---|---|
| فواتيري | قائمة وفلاتر وبحث؛ تفاصيل الفاتورة؛ الضغط على الصف يفتح نافذة التفاصيل؛ إنشاء Draft؛ تعديل/حذف Draft فقط؛ لا حذف Posted/PartiallyPaid/Paid | لا تزال دورة الشراء السريع بلا PO محجوبة عند الترحيل حتى وجود عقد استلام معتمد؛ اختبار المتصفح المصادق غير منفذ |
| عروض أسعار | إنشاء/list/detail؛ قبول quotation؛ تحويل المقبول إلى PO | لا توجد شاشة مقارنة الموردين؛ Buyer لا يشير إلى view purchase_quotation_comparison رغم وجودها في قاعدة البيانات وGET_DATA allow-list |
| عهدتي | إصدار عهدة؛ إقرار الموظف؛ إضافة سلفة؛ إقرار الزيادة؛ تقديم مستند فاتورة المورد وإذن الاستلام؛ مراجعة مالية؛ تسوية | إثبات قبض المورد النقدية غير موجود كشرط قبل Paid/AP debit؛ إثبات تسليم النقد للموظف والزيادة والمرتجع غير مكتمل؛ مرجع العملية قد يكون اختياريًا؛ الحركات النقدية الحالية تقع قبل إثبات الإقرار الفعلي |
| رصيد السيارة | واجهة وعنوان وتنبيه بأن دفتر عهدة بضاعة المشتريات غير مفعّل؛ تعرض المركبة من fleet_vehicle_assignments | ليست دفتر عهدة؛ تبحث عن driver_user_id للمستخدم الحالي؛ لا تعيين Buyer للمركبة؛ لا Supplier→Vehicle custody ولا Vehicle→Warehouse acceptance ولا SupplierReturn عبر مركبة المشتري |

**فواتيري:** التعديل الذي أُنجز في LVE583 محفوظ في commit 37d4e95e030bf3085c232655bdec6f059a335ca1. لا يعاد بناؤه ولا تُستبدل نافذة التفاصيل.

**عروض الأسعار:** جدول/عرض المقارنة موجود بالفعل في Production. أعمدة view تشمل الشركة وRFQ وquotation والمورد والأصناف والكميات وسعر الوحدة والخصم والضريبة والإجمالي وأقل سعر وحدة وprice_rank. إعداد view هو security_invoker=true، وسياسات المصدرين purchase_quotations وpurchase_quotation_details مقيدة بالشركة. لكن Buyer الحالي لا يستعلم عن purchase_quotation_comparison إطلاقًا (0 references في source). وEdge GET_DATA allow-list يتضمن الاسم بالفعل. view يرتب أقل سعر وحدة، لا أفضل عرض إجمالي ولا أفضل مورد؛ فلا تعرض الشاشة "الأفضل" دون حساب landed cost والضريبة والخصم والنقل ومدة التوريد وشروط الدفع وجودة المورد. عدد purchase_quotations في Production عند الفحص = 0، لذلك لا يوجد dataset حي لاختبار المقارنة.

### 2.3 رصيد السيارة — فصل عهدة المشتريات عن التوصيل

- fleet_vehicle_assignments يتضمن vehicle_id وfleet_driver_id وdriver_user_id وstart_at/end_at ونوع/أولوية التعيين؛ لا يوجد buyer_user_id أو procurement custodian field.
- vehicles يتضمن mobile_branch_id وfleet_driver_id؛ لا يتضمن مخزنًا خاصًا بعهدة مشتريات.
- Buyer renderVehicleBalance يربط المركبة من fleet_vehicle_assignments باستخدام driver_user_id = currentUser.id؛ هذا تعيين سائق، وليس تعيين مشتري مسؤول عن عهدة البضاعة.
- Driver app renderStock يتعامل مع run_sheet_details (qty_ordered/qty_loaded/qty_delivered)، وrenderBalance يتعامل مع orders/order_details وqty_loaded/qty_delivered/qty_returned وقيم التحصيل/التوصيل. هذا دفتر حركة/مسؤولية توصيل، لا يصلح مصدرًا لعهدة المشتريات.
- Production snapshot الحالي:
  - stock_vouchers = 0
  - fleet_vehicle_assignments = 0
  - buyer_custodies = 0
  - purchase_invoices = 3
  - purchase_quotations = 0
  - mobile_stock_enabled vehicles = 2
- حركات inventory_log المرتبطة بالمركبتين:
  - CHV-2025-01: Loading = 15 rows / qty 39؛ Unloading = 10 rows / qty 26.
  - VHL-0422: DirectReturn = 1 row / qty 1؛ Loading = 12 rows / qty 12؛ Unloading = 6 rows / qty 6.
  - لا توجد حركة مشتريات SupplierReceipt أو استلام مشتريات من مورد في هذه العينة.
- النتيجة: لا يجوز جمع stock_branches للـmobile_branch_id وعرضه للمشتري باعتباره رصيد عهدته. هذا يخلط مخزون سيارة التوصيل بمخزون تحت مسؤولية مشتري، ويعطي رقمًا غير صحيح لصاحب المسؤولية.
- توجد في stock_vouchers حقول ذات صلة مثل vehicle_id وcustodian_user_id وpurchase_order_id وpurchase_invoice_id، وفي stock_voucher_details qty وreceived_qty وunit_price. هذه مكونات يمكن دراستها للتكامل، وليست دليلًا على وجود دورة مشتريات مركبة جاهزة.

### 2.4 محرك أذونات المخزون — ما يمكن وما لا يمكن إعادة استخدامه

Production create_manual_stock_voucher_atomic_core_12_20260828 يقبل حاليًا الأنواع:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn

ويفرض قواعد مسارات حسب النوع. DirectSale مرتبط بفرع → مركبة ومندوب بيع مباشر؛ SupplierReturn مرتبط بفرع → مورد. لا يوجد نوع Supplier → Vehicle / Buyer custody أو Vehicle → Warehouse procurement handover.

Production complete_manual_stock_voucher_atomic_core_20260828:
- يتوقع حالات مختلفة لكل نوع.
- SupplierReturn ينفذ assert_supplier_return_contract، ثم يحسب قيمة المرتجع ويرحل supplier_ledger وGL.
- لا يمرر SupplierReturn الحالي عبر مرحلة مركبة المشتري؛ اكتماله يؤدي إلى الأثر المالي الخاص بمرتجع المورد.

**الحقيقة المعمارية:** يوجد محرك مركزي مفيد يمكن توسيعه، ولكن تمرير type جديد إلى Edge الحالي لن يكفي؛ قاعدة البيانات نفسها سترفض النوع غير الموجود في whitelist. يجب توسيع create/send/receive/complete/lifecycle contracts مع الحفاظ على DirectSale وDirectReturn وTransfer وSupplierReturn دون تغيير سلوكها الحالي.

### 2.5 عقد شراء/فاتورة/PO الحالي

- purchase_orders يحتوي expected_delivery_date وpayment_terms بالفعل؛ لكنه لا يحتوي approved_by أو sent_at.
- Edge v22 يحتوي CREATE_PO، ولا يحتوي SEND_PO أو APPROVE_PO. CREATE_PO ينشئ Draft ولا يغير أرصدة.
- PO lifecycle في الواجهة الحالية لا يوفر اعتمادًا/إرسالًا للمورد من خلال Edge.
- quotation → PO موجود، لكن لا توجد مقارنة عروض داخل Buyer.
- purchase_post_invoice_atomic:
  - PO-linked invoice: يفرض currency = app_settings، ويتحقق من completed receiving، ومطابقة المورد والصنف والكمية المستلمة والسعر؛ يرفض discount/tax غير المدعومين؛ ثم يغير حالة الفاتورة إلى Posted دون إعادة حركة stock أو supplier liability التي رحلها الاستلام.
  - Unlinked quick invoice: يرفض الترحيل بـ PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED. لا توجد حاليًا direct receiving contract معتمد يغلق مسار الفاتورة العاجلة بلا PO.
- purchase_update_draft_invoice_atomic وpurchase_delete_draft_invoice_atomic موجودتان في Production، SECURITY DEFINER/search_path empty؛ EXECUTE service_role فقط، لا anon/authenticated. وهما محصورتان في مسودات غير مستلمة/غير مرحّلة/غير مدفوعة وبدون downstream stock/finance links.
- عملة الشركة في app_settings = EGP.
- Edge v22 المصدر المنشور يطابق Git؛ هذا لا يثبت أن Cloudflare Pages يخدم Buyer الحالي.

### 2.6 عقد عهدتي والأثر المالي الحالي

**إصدار العهدة — buyer_custody_issue_atomic:**
- يتطلب مستخدمًا نشطًا في الشركة وصلاحية finance/finance_manager، وموظفًا نشطًا، ويمنع إصدار العهدة لنفس المستخدم.
- يقرأ عملة النظام من app_settings.
- ينشئ buyer_custodies وInitial advance.
- يستدعي post_cash_payment_atomic عند تسجيل الإصدار، ويكتب cashbox/journal IDs.
- received_reference اختياري، received_at يسجل عند الإنشاء، بينما acknowledged_at للموظف يحدث لاحقًا عبر RPC منفصل.
**الأثر:** صرف الخزينة قد يكون تم تسجيله قبل وجود إقرار الموظف؛ الإقرار الحالي لا يؤخر الحركة النقدية ولا يشترط مستند استلام منفصل.

**زيادة العهدة — buyer_custody_add_advance_atomic:**
- يسجل Additional advance ويزيد issued_amount ويستدعي post_cash_payment_atomic.
- employee acknowledgement لاحق مستقل؛ reference اختياري.
**الأثر:** يجب التمييز بين تسجيل أمر الزيادة، التسليم الفعلي للنقد، وإقرار الموظف، لا استخدام الحالة وحدها لإثبات انتقال النقد.

**تقديم المصروف واعتماد المورد — buyer_custody_submit_expense_atomic وbuyer_custody_review_expense_atomic:**
- تقديم المصروف يشترط فاتورة مورد ومسودة purchase invoice مرتبطة بـPO، ومستند الفاتورة ومستند إذن استلام المخزن، وoperation ID، ويطابق البنود والكميات والأسعار/العملة.
- اعتماد Finance يتحقق من الفاتورة/الـPO/الاستلام ومن وجود التزام للمورد في supplier_ledger.
- عند Approved، يقوم RPC حاليًا بإنشاء journal، وإدخال buyer_custody_payments، وتحديث purchase_invoices إلى Paid، وكتابة debit في supplier_ledger يخفض AP.
- reference في buyer_custody_payments يساوي رقم فاتورة المورد؛ ليس إيصال قبض نقدية من المورد. لا يوجد في schema الحالي مرفق منفصل لإثبات أن المورد استلم النقد/التحويل فعليًا.
**الأثر الحاسم:** اعتماد المستندات يؤدي إلى سداد المورد محاسبيًا وتخفيض AP وإظهار Paid، مع أن إثبات تسليم قيمة العهدة للمورد غير ممثل كشرط مستقل. هذا يتعارض مع سياسة المالك في section 77.1/77.4: Invoice أو approval ليس Cash Paid دون handover evidence.

**تسوية العهدة — buyer_custody_settle_atomic:**
- يتحقق من عدم وجود مصروفات Submitted، وعدم وجود advances غير مُقر بها، ويشترط أن cash_returned = issued_amount - approved_expenses.
- يستدعي post_cash_receipt_atomic ويرحل المقبوض للخزينة.
- finance_reference اختياري ولا يوجد مستند إثبات مستقل في schema.
**الأثر:** يوجد أثر خزينة عند التسوية، لكن المستند/مرجع قبض النقد المرتجع ليس إلزاميًا.

**وسائل الدفع:**
- purchase_payments.payment_method موجود كعمود non-null default Cash.
- RPC purchase_post_payment_atomic لا يستقبل p_payment_method، وEdge POST_PAYMENT لا يمرر payment_method، لذلك القيمة المرسلة من الواجهة لا تصل إلى العقد وتظل Cash default.
- RPC الحالي يرحل cash payment ويخفض supplier ledger؛ لا توجد في هذا المسار حزمة إثبات موحدة لطريقة الدفع/رقم التحويل/الشيك/إيصال المورد.

### 2.7 قاعدة الموردين والتكاملات المحيطة

- suppliers الحالي يحتوي phone/location/address/supplier_type/payment_type/accounts_payable/contact_person/purchase_rep/notes/is_active؛ لا يوجد email أو supplier grade A/B/C أو rating fields.
- لم يظهر جدول supplier_visits أو supplier_ratings في schema المفحوص.
- لا يجوز إعادة فتح عيب SupplierReturn القديم: تقرير 342/343 يثبت أن تطبيق Warehouse Vouchers لديه بالفعل SupplierReturn مباشر Branch → Supplier مع مستند/سبب وحقول مرجع PO/Invoice اختيارية، ومراحل Send → physical movement → Complete → Supplier Ledger → GL → Audit. يجب الحفاظ على هذا المسار الحالي، وإضافة مرحلة مركبة/مسؤول عهدة فقط إذا كانت دورة المشتري مطلوبة، دون إعادة بناء SupplierReturn أو ربطه إجباريًا بـPO.
- LVE579 أثبت إزالة ازدواج Supplier AP triggers واختيار كاتب مركزي واحد. التحقق الحي الحالي يؤكد وجود trigger نشط واحد: supplier_ledger_sync_accounts_payable → app_private.sync_supplier_accounts_payable().
- التحقق الحي الحالي يؤكد أن TRUNCATE على public.suppliers غير متاح لـanon/authenticated.
- سياسة buyer_custody_payments_scoped_select الحالية تربط c.company_id بـ buyer_custody_payments.company_id؛ تم إصلاح التناقض الذي ظهر في Report575. لا تُسجل هذا كـopen defect.
- لا تعديل على main.html أو driver.html في هذه الجولة.

## 3. متطلبات سابقة لا يجوز إسقاطها

من Reports 569/570/571/574 ومن السجل التاريخي، تبقى المتطلبات التالية ضمن نطاق تطبيق مسئول المشتريات أو تكامله:

1. **Dashboard / اليوم:** تنبيهات طلبات PR المتأخرة، عروض الأسعار المستحقة، PO حسب موعد التوريد، فواتير الموردين المستحقة، العهدة النقدية، ومستندات/بضائع قيد عهدة المشتري. لا يمكن حساب PO overdue بدقة دون الاعتماد على expected_delivery_date والتأكد من status/receiving.
2. **PR:** list/details/timeline وSubmit/Approve/Reject وRFQ؛ department_id غير موجود؛ لا تحسب received/remaining من PR مباشرة، بل من PO/receiving المرتبطين.
3. **RFQ/Quotations:** إنشاء وإرسال RFQ، استقبال عرض كل مورد، مقارنة أسعار البنود، الصلاحية، الخصم والضريبة والإجمالي وشروط التوريد، ثم قبول عرض وتحويله إلى PO.
4. **PO:** إنشاء/تحرير Draft، expected delivery/payment terms موجودان، لكن موافقة/إرسال المورد وحفظ من اعتمد ومتى وأثر تاريخ الحالة غير مكتمل. إنشاء/اعتماد/إرسال PO لا يغير مخزونًا أو ذممًا بحد ذاته.
5. **Invoices:** قائمة وفلاتر وتفاصيل؛ Draft edit/delete مضبوط؛ Posted/Paid غير قابل للحذف؛ مسار سريع بلا PO لا يترحل قبل استلام معتمد؛ فاتورة المورد وإذن استلام المخزن والـPO يجب أن تتطابق.
6. **Supplier Master:** الاسم والكود والهاتف والعنوان وشروط/نوع التوريد ورصيد المورد ومندوب المشتريات موجودة. البريد والتصنيف A/B/C والتقييم وزيارات الموردين غير موجودة في schema؛ لا تظهر حقولًا شكلية بلا جدول/صلاحيات/سجل زيارة.
7. **Buyer cash custody:** عهدة افتتاحية، زيادات، إقرار استلام كل دفعة، مستندات المصروف (فاتورة المورد + إذن الاستلام)، إثبات سداد المورد فعليًا، اعتماد المالية، تسوية النقد المرتجع وإثبات الاستلام، مستحق الموظف، وسجل تدقيق.
8. **Vehicle goods custody:** المورد → المشتري/المركبة، ثم المشتري/المركبة → المخزن، وفروقات الاستلام، وعودة البضاعة من المخزن → المركبة/المشتري → المورد مع إثبات استلام المورد. يجب الفصل عن Driver assignment وعن van stock.
9. **Payment method:** Cash/Bank transfer/Cheque أو غيرها بحسب أنواع النظام الفعلية، مع رقم المرجع/المستند وإثبات التسليم؛ يجب أن يصل اختيارها عبر UI → Edge → RPC → purchase_payments/journal/treasury.
10. **Search & scale:** البحث بالكود والباركود والاسم موجود لبعض قوائم الأصناف؛ لا يزال GET_DATA بحد 500 وسيرفر pagination/search غير مكتمل.
11. **Attachments / OCR:** مرفقات مستندات الشراء مطلوبة؛ OCR لم يثبت كخدمة موجودة. لا تعرض زر OCR أو كاميرا كميزة تشغيلية قبل توفير backend ومراجعة بشرية.
12. **Account / reports / roles:** حساب المستخدم والصلاحيات والتقارير والإعدادات موجودة؛ يجب عدم عرض اعتماد أو ترحيل إلا للمستخدم صاحب effective permission الموثوقة، لا اعتمادًا على إخفاء زر.
13. **Realtime:** Buyer لديه اشتراك Realtime على جداول دورة الشراء والعهدة؛ لكن وصول WebSocket/reconnect من المتصفح لم يُثبت في هذه الجولة.
14. **Parent/other apps:** لا تعديل على main.html أو driver.html أو van-sales أو warehouse vouchers في أي patch دون ضرورة عقدية واضحة؛ حافظ على التطبيقات المستقلة وعلى مصدر البيانات المركزي.

## 4. UNKNOWN — قرارات أعمال لا ينبغي التخمين فيها

- هل يعين مدير المشتريات/الأسطول المشتري للمركبة مسبقًا بمدة محددة، أم يختار المشتري مركبة من قائمة مصرح بها لكل عملية؟ التوصية الهندسية: تعيين مركبة/مشتري زمني مستقل عن السائق، بصلاحية إدارة واضحة، لكن سياسة الجهة المعتمدة يجب تثبيتها قبل DDL.
- متى تنتقل ملكية/مسؤولية البضاعة محاسبيًا: عند تسليم المورد للمشتري، أم بعد قبول المخزن؟ هذا يتأثر بعقد المورد وشروط التسليم. لا يجوز إنشاء قيد/زيادة مخزون قابل للبيع عند مجرد استلام مؤقت أو بضاعة تحت الفحص.
- عند استلام المشتري من المورد، هل كل كمية تدخل عهدة المشتري مباشرة، أم توجد حالة رفض/فحص/تالف قبل قبولها؟ يلزم تحديد المسؤول عن الفروقات والتالف.
- هل شراء العهدة النقدية للمورد يتم كاش فقط، أم نقد/تحويل/شيك؟ ومن يثبت قبض المورد؟ وكيف تُعامل المصروفات التي لم تُدفع للمورد بعد؟
- ما مستند الاستلام المقبول من المورد عند تسليم النقد/الشيك/التحويل؟ وهل يُطلب توقيع/اسم مستلم/رقم إيصال/صورة؟
- هل يحتاج النظام إلى اعتماد مالي مستقل قبل تعيين buyer/vehicle، ومن يملك إغلاق فروق الكمية؟
- لا توجد بيانات quotations حية (0 rows) ولا stock vouchers/vehicle assignments/buyer custody في الشركة وقت الفحص، لذلك لا يمكن التحقق من سيناريوهات تشغيلية موجودة حاليًا بالمتصفح.

## 5. CONFLICT — مصدران/عقدان لا يتطابقان

1. **تصور التماثل مع Driver مقابل نموذج البيانات:** Driver vehicle stock يقرأ run_sheet_details/تحميل/تسليم، بينما Buyer vehicle balance يحاول استخدام driver_user_id. هذه عقود توصيل وليست procurement custody. نسخ UI أو استعلام Driver إلى Buyer سيعطي إسنادًا خاطئًا للمستخدم ورصيدًا خاطئًا للبضاعة.
2. **مبدأ سداد المورد مقابل تنفيذ RPC الحالي:** سياسة المالك تشترط handover proof قبل تخفيض AP وتحديد invoice Paid؛ لكن buyer_custody_review_expense_atomic ينفذ supplier AP debit وPaid عند اعتماد المستندات دون إثبات قبض المورد. يجب تغيير العقد بعد عرض SQL/diff وموافقة محددة.
3. **SupplierReturn الحالي مقابل دورة المرتجع المطلوبة عبر المشتري:** SupplierReturn الحالي Branch→Supplier مكتمل وظيفيًا ولا يتوسطه Buyer Vehicle. لا يجوز تعديل معناه أو ترحيل supplier credit عند تسليم البضاعة للمشتري بدل استلام المورد لها.
4. **Stock voucher Engine مقابل أنواع المشتريات المطلوبة:** Core whitelist لا يقبل Supplier→Vehicle أو Vehicle→Warehouse procurement stages. Edge wrapper موجود لكنه ليس كافيًا؛ التغيير يحتاج RPC/core/lifecycle/audit/permissions/idempotency.
5. **PO lifecycle مقابل مطالبات التشغيل:** schema يحوي expected_delivery_date/payment_terms لكن Edge لا يحتوي SEND_PO/APPROVE_PO؛ فلا يمكن إعلان إرسال/اعتماد PO من الواجهة حتى يوجد عقد خادمي معتمد.
6. **وسائل الدفع:** DB column payment_method موجود، لكن RPC/Edge لا يمررانها؛ اختيار Cash/Bank في الواجهة وحده لا يغير طريقة الدفع الفعلية.

## 6. UNVERIFIED — حدود ما لم يختبر

- Cloudflare Pages served Buyer artifact/commit lineage/cache/headers لم تُقرأ من صفحة النشر في هذه الجولة.
- لم ينفذ Browser authenticated E2E بحساب مشتريات أو مالية أو موظف عهدة.
- لم يُختبر رفع/تحميل/حذف مستند binary فعليًا من Storage API.
- لم تُختبر أحداث Buyer Realtime أو reconnect بعد النشر في متصفح فعلي.
- لم تُختبر مقارنة العروض على بيانات حقيقية لأن عدد quotations = 0.
- لم يُنفذ Buyer assignment أو استلام مشتريات أو تسليم للمخزن أو مرتجع عبر مركبة؛ لا توجد سجلات حاليًا لهذه العمليات.
- لم يُختبر دفع نقدي للمورد أو استلام المورد له عبر عهدة المشتري؛ البيانات الحالية لا تحمل supplier receipt proof في contract.
- لم يُختبر أثر cash custody issue/top-up/settlement في متصفح مصادق عليه.
- لم تُجر اختبارات static parse جديدة لـBuyer في هذه الجولة؛ لا يُعاد استخدام parse سابق على blob مختلف.

## 7. مصفوفة التحقق

| الطبقة | النتيجة | المرجع |
|---|---|---|
| GitHub/source | CONFIRMED | main HEAD aa8cbff؛ Buyer blob 73d7465؛ Driver blob 92ae036؛ app router 2e47a68؛ Edge blob bc038be |
| Supabase Production | CONFIRMED + CONTRACT CONFLICT | app_settings EGP؛ RPC/voucher/custody definitions؛ current schema/RLS/ACL؛ counts؛ no procurement-specific voucher types |
| Deployed artifact | PARTIAL CONFIRMED | save-purchase-order v22 byte-match؛ Cloudflare Pages UNVERIFIED |
| Runtime/E2E | UNVERIFIED | لا جلسة authenticated ولا Console/Network/Storage/Reatime E2E |
| Business-data effects | CONFIRMED READ-ONLY SNAPSHOT | invoices 3؛ quotations 0؛ stock_vouchers 0؛ fleet assignments 0؛ buyer_custodies 0؛ vehicle movements delivery-only؛ لا كتابة جديدة |

## 8. ما تم فعليًا في هذه الجولة

1. قراءة CURRENT_STATE.md كاملًا أولًا وتثبيت LVE583.
2. قراءة التقارير الحاكمة/السابقة ذات العلاقة: 342/343 و368/372 و567 و569/570/571 و574 و579 و580/581/583.
3. قراءة Master CTO Governance §77، خصوصًا شرط المراجعة/الموافقة قبل أي تغيير مؤثر، وسياسة Physical Handover.
4. جلب HEAD الحالي من operational main وBuyer/Driver/app/Edge source.
5. جلب Edge save-purchase-order v22 من Production ومقارنته حرفيًا بملف Git.
6. قراءة Production schema/columns/RPC definitions/RLS policies/ACL/trigger list/counts، كلها SELECT/read-only.
7. مطابقة Driver stock/balance contract مع Buyer vehicle placeholder.
8. جلب snapshots التاريخية للـstock-voucher Edge endpoints من مستودع الحالة، وملاحظة عدم وجود source directories لها في operational repo؛ لم تُستخدم تلك النسخ القديمة للتعديل أو النشر.
9. بحث رسمي مختصر لمقارنة سياسة المطابقة/الاستلام/الموردين في Dynamics 365 وSAP وOdoo؛ المصادر أدناه.
10. لم يحدث تعديل Buyer/Driver/main/Core/Edge، ولم يحدث DDL أو RLS/grants أو business row writes أو نشر.

## 9. التصميم التنفيذي المقترح — ليس تنفيذًا Production بعد

### 9.1 فواتيري
الحفاظ على السلوك الحالي الذي تم إثباته في LVE583. لا إعادة كتابة للصفوف أو modal. يظل الحذف/التعديل للمسودات غير المستلمة وغير المرحّلة فقط. أي مستند Posted/Paid يتطلب cancellation/reversal مع audit، وليس حذفًا.

### 9.2 عروض أسعار
توصيل Buyer إلى view purchase_quotation_comparison الموجود عبر GET_DATA الحالي. تصميم جدول مقارنة حسب RFQ + item، مع أعمدة لكل مورد: Unit Price، Discount، Tax، Line Total، Valid Until، Delivery Terms، وPrice Rank. يظهر أقل Unit Price كإشارة ضيقة فقط؛ لا تُصدر توصية أفضل مورد حتى يتوافر landed cost ومقاييس التوريد/الجودة والالتزام. لا تغيير DB مطلوب لعرض المقارنة الأولي؛ يسبقه test للسياسات والفرز والبيانات في staging/fixture بعد الموافقة.

### 9.3 عهدتي — فصل الوثيقة عن التسليم الفعلي
الحفاظ على سجل العهدة الحالي، لكن يلزم فصل الحالات:
- Cash custody issued/requested
- Cash physically handed over + employee acknowledged
- Expense submitted with supplier invoice + warehouse receipt
- Supplier actually received the money/instrument, proven by receipt/reference and acknowledged recipient
- Finance approval and supplier AP/journal posting
- Cash returned and received by finance/treasury with evidence
لا ينتقل invoice إلى Paid ولا يُخفض supplier AP عند مجرد اعتماد مستند الفاتورة/الاستلام؛ يجب إثبات قبض المورد للمبلغ. كما لا يثبت قيد الخزينة أن الموظف استلم النقد دون تأكيد/مستند handover.

### 9.4 رصيد السيارة / عهدة بضاعة المشتريات
الاقتراح الفني:
- تعيين مشتري/مسؤول عهدة مركبة مستقل عن fleet_driver assignment. يُفضل جدول assignment منفصل time-bounded مع company_id وvehicle_id وbuyer_user_id وeffective from/to والجهة المعتمدة وسجل التدقيق وRLS؛ لا نضيف buyer_user_id إلى driver semantics دون دراسة أثر التطبيقات.
- الاستفادة من stock_vouchers/stock_voucher_details وحقول custodian_user_id/vehicle_id/PO/Invoice الموجودة، مع توسيع Core lifecycle الحالي بعقود procurement-specific stages بعد استعادة المصدر المنشور canonical من Production إلى operational repo.
- Supplier → Buyer/Vehicle: إثبات تسليم المورد/packing slip، الأصناف والكميات والتكلفة والـPO/Invoice (إن وجد)، المشتري والسيارة، إقرار الاستلام، وتسجيل الكميات في حالة custody/in-transit غير قابلة للبيع.
- Buyer/Vehicle → Warehouse: أمين المخزن يثبت الكمية المقبولة فعليًا لكل صنف؛ المقبول فقط يتحول مرة واحدة إلى مخزون الفرع القابل للبيع عبر central stock movement؛ فرق النقص/الزيادة/التالف يبقى مفتوحًا تحت مسؤولية صاحبه مع discrepancy workflow.
- Warehouse → Buyer/Vehicle → Supplier: صرف مرتجع معتمد من مخزون الفرع إلى custody/transit، ثم إثبات استلام المورد/إيصال RMA/credit note/replacement؛ لا تخفيض AP أو supplier credit عند مجرد خروج البضاعة من المخزن، بل بعد تحقق الاستلام/الاعتماد المالي المناسب.
- إبقاء SupplierReturn الحالي Branch → Supplier سليمًا كمسار مباشر عندما يكون التسليم من المخزن للمورد بلا مرحلة مشتري/مركبة. لا إعادة بنائه ولا إجباريته إلى PO.
- لا تُجمع كميات عهدة المشتري مع mobile_branch_id الخاص بالتوصيل ولا تُدخل في sellable stock قبل قبول المخزن. لا نستخدم stock_branches vehicle row نفسها لإخفاء انتقالات غير متجانسة.

### 9.5 PO / Supplier / Payment / Search
- PO: الحفاظ على expected_delivery_date/payment_terms الموجودين؛ إعداد عقد server-side للموافقة والإرسال والتدقيق قبل عرض أزرار تنفيذية؛ لا أرصدة تتغير عند Draft/Approved/Sent.
- Supplier profile: لا تُضاف حقول email/grade/rating/visits إلى الواجهة قبل عقد schema وRPC/RLS وسجل الزيارات/التقييم.
- Payment: إضافة payment_method إلى contract end-to-end (UI→Edge→RPC→purchase_payments→cash/treasury/journal) مع الأدلة/رقم المرجع الخاص بالتحويل أو الشيك؛ منع fallback إلى Cash عندما يختار المستخدم غيره.
- Search/scale: الإبقاء على barcode search حيث يعمل؛ إعداد pagination/server-side search قبل اعتبار حد 500 كافيًا.
- OCR: لا UI/زر OCR حتى يتم اختيار خدمة موثوقة وحفظ نتيجة قابلة للمراجعة مرتبطة بمسودة لا تُرحّل تلقائيًا.

### 9.6 ترتيب التغيير المطلوب بعد الموافقة
1. استعادة وcommit مصدر Edge stock voucher المنشور create/send/receive/complete/cancel من Production إلى operational repo ومطابقته حرفيًا؛ نسخ Current/Edge_Functions التاريخية ليست مرجع نشر.
2. إعداد migration/RPC changes لassignment منفصل ومراحل SupplierReceipt/BuyerCustody/WarehouseReceipt/SupplierReturnTransit وفق قرار انتقال الملكية/المسؤولية.
3. تعديل existing stock voucher Core/Edge (لا Edge Function جديدة) مع idempotency, tenant, authorization, audit, reversal, discrepancy, partial receiving, RLS/grants.
4. إصلاح إثباتات النقد: issue/top-up, supplier receipt, settlement, payment method، ثم tests no-effect-before-handover/one-time-effect-after-handover.
5. ربط Buyer quotations comparison view وPO lifecycle بعد تثبيت صلاحياتها وعقودها.
6. static/contract tests، SQL transaction rollback tests، staging/browser E2E بحسابات حقيقية، ثم deployed artifact وProduction data verification.

## 10. المراجعة التنافسية — المعيار الذي ينبغي الاقتداء به

- **Microsoft Dynamics 365:** تسجيل استلام المنتجات من PO يثبت الكمية الفعلية ومعرف مستند الاستلام/packing slip؛ يسمح بتسجيل نقص/زيادة التوريد، وقد توجد مرحلة preregistration أو quality management قبل Received. كما أن invoice matching يقارن PO وproduct receipt وvendor invoice قبل الموافقة على الدفع.
  - Product receipt: https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/product-receipt-against-purchase-orders
  - Three-way matching: https://learn.microsoft.com/en-us/dynamics365/finance/accounts-payable/tasks/record-vendor-invoice-match-against-received-quantity

- **SAP S/4HANA:** Goods Receipt مرتبط بأمر الشراء وdelivery note؛ receipt لا يُستنتج من الفاتورة، ويوجد goods-receipt-based invoice verification يربط الفاتورة بإيصال الاستلام/مستند التسليم. هذا يؤيد فصل مرحلة عهدة/نقل البضاعة عن إثبات الاستلام النهائي.
  - Goods Receipt for PO: https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/a663bd534f22b44ce10000000a174cb4.html
  - Goods Receipt Determination: https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/ed84b70c199d4470ae2e5ccb93b2e45b/3c6fb6531de6b64ce10000000a174cb4.html

- **Odoo:** 3-way matching يضمن عدم دفع vendor bill إلا بعد استلام بعض/كل المنتجات وفق السياسة؛ bill control policy يمكن أن تكون ordered quantities أو received quantities. كما لا تظهر إلا خطوط PO المستلمة في Purchase Matching.
  - 3-way matching and received quantities: https://www.odoo.com/documentation/18.0/applications/inventory_and_mrp/purchase/manage_deals/manage.html
  - Vendor bill purchase matching: https://www.odoo.com/documentation/18.0/applications/finance/accounting/vendor_bills.html

**التطبيق على RAWAEA:** Three-way matching ليس مجرد مقارنة قيم على الشاشة؛ هو عقد يربط PO line بالاستلام الفعلي والفاتورة وبالكمية المقبولة والذمم. وكذلك لا يعد رصيد السيارة مخزونًا قابلًا للبيع لمجرد وجود كمية على مركبة؛ يجب تحديد location/custodian/status والإثبات والحالة النهائية.

## 11. ما لم يُنفذ ولماذا

- لم يتم تعديل buyer.html أو driver.html أو main.html أو core.js؛ لأن تغيير دورة العهدة/المركبة يؤثر في الأرصدة ومخزون المستودع ودفتر الموردين والقيود.
- لم يتم تعديل RPC أو Trigger أو RLS/grants أو Migration؛ لأن المالك يلزم عرض SQL الكامل وأثره وخطة الاختبار/التراجع قبل أي تنفيذ مؤثر.
- لم يتم نشر Edge أو Cloudflare؛ deployed Edge v22 موجود ومطابق للمصدر، لكن source stock voucher endpoints غير محفوظ في operational repo.
- لم يتم تنفيذ اختبارات أعمال ببيانات Production؛ لا توجد سجلات حقيقية للـvehicle procurement flow في Production، والبيانات التجريبية لا تُنشأ دون بيئة معزولة/موافقة.
- لم يتم عرض المخزون الحالي للمركبات للمشتري؛ الحركات الحالية مرتبطة بالتوصيل.
- لم يتم تفعيل توصية "أفضل مورد"؛ view الموجود يحسب price rank على unit_price فقط، والبيانات الفعلية للـquotations = 0.
- لم تُنفذ تغييرات SupplierReturn الحالية التي أغلقت في Reports 342/343؛ ستُحفظ كما هي.

## 12. بوابة الموافقة التنفيذية — المطلوب قبل أي تغيير يمس Production

وفق Master CTO Governance §77.2 و§77.4:
- لا يُعد طلب المهمة موافقة عامة على كل DDL/RPC/Edge/UI changes.
- اعتمد المالك سياسة الشراء/العهدة (عدم الأثر قبل التسليم الفعلي)؛ لكنه لم يعتمد حتى الآن diff/SQL بعينه لهذه الجولة.
- قبل التنفيذ يجب عرض مجموعة التغييرات المحددة: source files/diffs، migration SQL كاملة، signatures/grants/RLS، business-data effects، dependencies، acceptance tests، negative tests، rollback plan. وتكون الموافقة صريحة على نفس الحزمة.
- لا يُعاد سؤال المالك عن السياسة التي اعتمدها؛ الأسئلة المفتوحة محصورة في تعيين المشتري للمركبة ونقطة انتقال ملكية/مسؤولية البضاعة وشكل إثبات قبض المورد.

## 13. NEXT SINGLE PRIORITY

**استعادة المصدر الحي الكامل لخمسة stock-voucher Edge functions إلى operational repository والتحقق من lineage مع Production، ثم إعداد عقد Procurement Custody Change Set واحد** يربط assignment والرحلتين Supplier→Vehicle→Warehouse وWarehouse→Vehicle→Supplier والإثباتات المالية. هذا يزيل أكبر blocker قبل كتابة RPC أو UI، ويمنع تعديل نسخ Edge تاريخية/ناقصة أو كسر SupplierReturn/DirectSale/DirectReturn القائم.

**الإغلاق:** FOUNDATIONS EXIST / FOUR TABS PRESENT / INVOICE ROW DETAIL PATCH RETAINED / QUOTATION COMPARISON VIEW EXISTS BUT UI DISCONNECTED / BUYER CASH CUSTODY PROOF GAP CONFIRMED / PROCUREMENT VEHICLE CUSTODY CONTRACT MISSING / DRIVER STOCK IS NOT BUYER STOCK / STOCK VOUCHER CORE NEEDS PROCUREMENT EXTENSION / EDGE v22 BYTE-MATCHED / CLOUDFARE + AUTHENTICATED BROWSER E2E UNVERIFIED / NO PRODUCTION MUTATION / OWNER EXACT-CHANGE APPROVAL REQUIRED / NOT CLOSED.
