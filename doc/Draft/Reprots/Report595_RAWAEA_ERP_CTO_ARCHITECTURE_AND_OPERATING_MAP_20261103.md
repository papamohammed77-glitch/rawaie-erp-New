# RAWAEA ERP — خريطة CTO المعمارية والتشغيلية الشاملة

**Checkpoint:** LVE-2026-11-03-595  
**التاريخ:** 2026-11-03  
**الحالة:** ARCHITECTURE MAP CONSOLIDATED / CRITICAL CONTRACTS OPEN / INITIALIZATION NOT COMPLETE  
**نقطة البداية:** LVE-594.

---

## 1. الغرض

هذا التقرير يجمع خريطة النظام المستعادة من:
- CURRENT_STATE والتقارير التاريخية بوصفها خيوطًا وأدلة.
- المستودع التشغيلي الحالي.
- Supabase Production وStaging.
- Edge Functions المنشورة.
- مخطط PostgreSQL وRLS وRPCs وTriggers.
- تطبيقات Parent وPWAs المستقلة.

لا يمثل هذا التقرير ادعاء أن كل وظيفة أو كل مسار Runtime قد تم اختباره؛ بل هو خريطة معمارية موثقة تحدد ما هو معروف وما بقي مفتوحًا.

---

## 2. الرؤية التشغيلية للنظام

RAWAEA ERP هو نظام توزيع FMCG/Hypermarket متعدد القنوات والفروع، وليس مجموعة صفحات منفصلة.

الرؤية المعمارية:
1. Parent ERP هو مركز القيادة والحوكمة والإعدادات والبيانات الرئيسية والتقارير.
2. تطبيقات الموظفين PWAs هي واجهات تشغيل مخصصة لأدوار العمل، لكنها ليست قواعد بيانات أو أنظمة مستقلة.
3. Supabase هو مصدر الحقيقة المركزي للهوية والشركة والفروع والأصناف والعملاء والموردين والمخزون والطلبات والمالية.
4. Edge Functions هي بوابات العمليات التجارية؛ RPCs ذرية تنفذ انتقالات الحالة والحركات؛ RLS/grants تحدد الوصول للبيانات.
5. Cloudflare يستضيف الواجهات، GitHub يحفظ المصدر والتاريخ، وSupabase يحفظ Production data/runtime contracts.
6. القيمة التنافسية ليست شكل الواجهة فقط؛ بل اتساق دورة الطلب والمخزون والخزينة والدفاتر والتوصيل والمشتريات عبر كل القنوات.

المبدأ غير القابل للتفاوض: لا توجد جزيرة تشغيلية مستقلة. كل تطبيق يستهلك نفس العقود المركزية، وأي حركة لها أثر متسلسل يجب أن تترك سجلًا قابلًا للتدقيق.

---

## 3. خريطة التطبيقات

المستودع التشغيلي: papamohammed77-glitch/erp-frontend  
الفرع: main  
HEAD عند آخر إعادة تحقق: 7a14d51b4d4c225240b215879abf6b77b99888d3

ملفات HTML الحالية في companies/company-1: 30 ملفًا:
- index.html: بوابة الدخول واختيار النظام.
- app.html: المصادقة وتوجيه المستخدم حسب الشركة والدور والصلاحيات.
- main.html: النظام الأم.
- 27 واجهة تشغيلية مستقلة:

| المجال | عدد الملفات | الوظائف |
|---|---:|---|
| Sales | 6 | POS، Telesales، Order Taker، Van Sales، Supervisor، Manager |
| Warehouse | 10 | Picker، Loader، Receiver، Unloader، Returns، Counter، Vouchers، Supervisor، Manager، Data Entry |
| Delivery | 2 | Driver، Supervisor |
| Purchasing | 2 | Buyer، Purchasing Supervisor |
| Office | 5 | Accountant، Finance Manager، General Manager، HR، Owner |
| Store | 2 | Storefront، Order Tracking |

الأعداد تصف ملفات الواجهة الحالية؛ لا تثبت اكتمال كل رحلة تشغيل أو كل صلاحية.

### 3.1 النواة المشتركة

core.js الحالي:
- 1,008 أسطر.
- وحدات: RW_Auth، RW_DB، RW_API، RW_UI، RW_ImageCache، RW_SW، RW_Realtime.
- مسؤولة عن المصادقة والبيانات وAPI والواجهة والصور وتسجيل/تحديث Service Worker وRealtime.

Parent main.html:
- 33,358 سطرًا / 1,800,879 حرفًا.
- 46 RW_ module/namespace.
- 1,016 تصريح function.
- 48 literal table references، 41 RPC references، 48 Edge endpoint references في static scan.
- Parent يحتوي وحدات قديمة وحديثة متعايشة؛ مثال المشتريات: RW_PurchaseGold يحل محل renderOrders القديم، بينما purchase-pos يظل route منفصلًا. لا يجوز تعديل أحد المسارين على افتراض أنه الآخر.

Service Worker:
- لا ينبغي أن يخزن HTML أو JS أو API business responses كنسخة دائمة.
- ملفات static assets لها caching policy.
- _headers يضع no-cache للصفحات وملفات Service Worker ذات الصلة.
- هذا لا يثبت أن Cloudflare يقدم نفس artifact؛ يلزم فحص deployed runtime.

---

## 4. خريطة Supabase Production

Project ref: fiilmooggumokxanwiyx  
PostgreSQL: 17.6.1.121

| العنصر | العدد الحالي |
|---|---:|
| Public tables | 186 |
| Public functions | 297 |
| RLS-enabled tables | 186 |
| Public RLS policies | 247 |
| Public triggers | 304 |
| Applied migrations | 734 |
| Edge Functions | 100 |

### 4.1 توزيع الجداول حسب المجال

التقسيم التالي حسب أسماء الجداول، وقد توجد جداول cross-domain:

| المجال | عدد الجداول | أمثلة |
|---|---:|---|
| System / Identity | 5 | companies, app_settings, users, roles, role_permissions |
| Branches / Vehicles | 6 | branches, vehicles, vehicle_tracking, maintenance |
| Buyer / Custody | 5 | buyer_custodies, advances, expenses, payments, settlements |
| Customers | 4 | customers, customer_ledger, assignments, followups |
| Delivery | 4 | delivery_agents, route_plans, route_stops, collection_receipts |
| Driver / Van | 2 | driver_ledger, driver_liabilities |
| Finance | 20 | chart_of_accounts, journal_entries/lines, treasury, cash_box, expenses, revenues, tax, bank, cheques, periods |
| HR | 25 | employees, profiles, attendance, contracts, schedules, leave, payroll, payslips |
| Inventory | 10 | stock_branches, inventory_log, counts, discrepancies, stock_vouchers, stock requests |
| Purchasing | 19 | purchase requests/RFQs/quotations/POs/invoices/payments/returns/attachments/settings/status history |
| Runsheet / Warehouse | 2 | runsheets, run_sheet_details |
| Sales / Orders | 17 | orders, order_details, quotes, payment allocations, returns, targets, decisions |
| Other / Enterprise | 65 | POS shifts, fleet, commissions, loyalty, promotions, installments, assets, budgets, complaints, workflows, notifications, audit |

### 4.2 توزيع وظائف PostgreSQL

حسب تصنيف الاسم:
- Finance: 57.
- Warehouse/Inventory: 53.
- Sales/Customers: 49.
- Purchasing/Suppliers: 42.
- Delivery/Driver: 16.
- HR: 15.
- Identity/Security: 4.
- Other/Enterprise/Reporting: 61.

هذا الجرد يثبت اتساع النطاق، لكنه ليس dependency graph كاملًا؛ يجب تتبع كل function إلى Edge/UI/trigger/table قبل تغييرها.

### 4.3 Edge Functions

Production يحتوي 100 Edge Function. الوظائف موزعة على:
- Procurement/Suppliers.
- Warehouse/Stock.
- Sales/Orders/POS.
- Finance/Cash.
- Delivery/Fleet.
- HR.
- System/Reporting/Other.

بعض الوظائف أحدث وتطبق effective permissions؛ وبعض الوظائف التاريخية تكتفي بـJWT + active user + company ثم تستدعي service_role RPC. هذا التفاوت هو مصدر عدد من المخاطر المثبتة في LVE-590 إلى LVE-593.

لا تعتبر verify_jwt=true كافيًا: JWT يثبت الهوية، ولا يثبت صلاحية العملية.  
ولا تعتبر verify_jwt=false تلقائيًا ثغرة إذا كان هناك custom auth صحيح؛ يجب فحص endpoint نفسه.

---

## 5. خريطة دورات الأعمال

### 5.1 Sales / POS

- POS invoiced: إنشاء فاتورة وخصم مخزون مباشر وفق المسار المعتمد.
- Telesales / Order Taker: Draft/Confirmed دون خصم مخزون قبل Runsheet/Loading.
- Van Sales: مخزن سيارة، عملاء مخصصون، تحصيلات، دفتر مندوب، وتسوية.
- Online Store: طلبات عامة/معلقة تخضع لعقد storefront مستقل.
- Sales Quotes: عروض أسعار تتحول إلى طلبات بعد شروط الموافقة.
- Sales Returns: مراجعة واعتماد وإشعار دائن وحركة مرتجع.

ضوابط جيدة موجودة في save-sales-invoice وsales-payment-allocation وsales-return-management وsales-target-engine. توجد فجوات في confirm-order وRunsheet creation/append، وتعارض direct permissions في Sales Quotes.

### 5.2 Warehouse / Runsheet

- الطلبات المؤكدة تُربط بالـRunsheet.
- Picking يحجز allocated_qty ولا يساوي خصم المخزون الفعلي.
- Loading ينقل المخزون من branch المخزن إلى mobile branch للمركبة.
- Delivery يثبت الكميات المسلمة/المرفوضة.
- Return يعالج المرتجع.
- Unloading يعيد الكمية المتبقية في حالة Runsheet Loaded.
- Daily Settlement يعالج العهدة/العجز/الزيادة والتسوية المالية.

الخلل الحرج الحالي: بعض Edge/RPC لا تفرض صلاحية التحميل/الاستلام/التفريغ/التسليم/التسوية على الخادم، كما أن مسار التسليم والمرتجع لا يظهر فيه خصم vehicle stock متكامل.

### 5.3 Procurement / Buyer

- PR → RFQ → Quotation → PO → Receiving → Invoice → Payment.
- لا أثر مخزني أو مالي من Draft أو PO بمجرد إنشائه.
- الفاتورة السريعة من السوق يجب أن ترتبط بمستند شراء/عهدة واستلام فعلي.
- فواتير Draft قابلة للتحرير/الحذف وفق الصلاحية والحالة.
- الفواتير المرحلة لا تحذف؛ التصحيح عبر عكس معتمد.
- عهدة السيارة/النقد منفصلة عن مركبة التوصيل وVan Sales.
- PR #10 Buyer field-workbench ما زال Draft.

### 5.4 Finance / Accounting

- Chart of Accounts.
- Journal Entries / Lines.
- Treasury / Cash Box.
- Payment / Receipt / Transfer vouchers.
- Customer / Supplier / Driver ledgers.
- Tax, bank reconciliation, cheques, periods, budgets, fixed assets.
- Finance operations يجب أن تكون مرتبطة بعملية مصدرها، مع operation_id، ودفتر فرعي، وقيد متوازن، وصلاحية خادمية.

الفجوات المثبتة: Edge/RPC wrappers في manual journal، payment voucher، generic receipt، treasury transfer، driver ledger، وcash-flow لا تطبق finance permission بشكل موحد.

### 5.5 HR / Fleet / Enterprise

توجد بنية فعلية لـ:
- الموظفين والملفات والعقود والدوام والإجازات والرواتب والسلف.
- المركبات والصيانة والوقود والتتبع والحوادث وعقود المركبات وأداء السائق.
- العمولات والولاء والعروض والتقسيط والأصول والميزانيات والشكاوى والإشعارات وسجلات التدقيق والـworkflows.

لم يتم في هذه الجولة تتبع كل هذه الوحدات حتى آخر consumer وRPC؛ لا تعتبر خريطة المجال إثباتًا لاكتمال التنفيذ.

---

## 6. مبادئ البيانات والعمليات

1. company_id هو حد العزل الأعلى، لكن يجب أيضًا فحص branch_id والفاعل والدور والتعيين.
2. effective permissions مصدرها get_my_effective_profile، الذي يجمع users.permissions وroles.permissions وrole_permissions.
3. لا تعتمد على users.permissions وحدها إذا كانت العملية تعتمد role-derived permissions.
4. allowed_branch_ids يحدد نطاق الفروع ولا يجب أن يحل محل permission.
5. qty وallocated_qty وqty_loaded وqty_delivered وqty_returned ليست مترادفات.
6. حركة المخزون يجب أن تكون ذرية ومسجلة في inventory_log ومتسقة مع stock_branches.
7. حركة الخزينة يجب أن تقابلها حركة دفتر/قيد صحيح، ولا يُسجل السداد قبل ثبوت الدفع المادي.
8. operation_id يجب أن يكون فريدًا لكل محاولة منطقية وثابتًا عند retry، لا hash payload دائمًا يمنع عملية مستقبلية متطابقة.
9. لا تستخدم service_role دون authorization check للمستخدم النهائي.
10. لا تضع مستندات مالية في public product-images؛ استخدم storage bucket خاصًا مع path ownership/RLS.
11. لا تنظف QA fixtures دون معرفة الغرض منها وموافقة المالك.
12. لا تعتبر UI gating أو status field بديلًا عن التحقق الخادمي.

---

## 7. أهم التناقضات المفتوحة حسب الأولوية

| الأولوية | التناقض | الدليل |
|---|---|---|
| Critical | Finance Edge/RPC wrappers تسمح بعمليات مالية دون finance permission | LVE-591 |
| Critical | Loading/Receiving/Delivery/Settlement permission/assignment gaps | LVE-590 |
| Critical | Vehicle stock لا يظهر له خصم delivery/return متكامل | LVE-590 |
| High | Stock vouchers send/complete/cancel/legacy create تعتمد branch wildcard أو active company بدل permission | LVE-593 |
| High | setup-van-branch لا يربط actor بالمندوب ولا يطلب fleet permission | LVE-593 |
| High | purchase_invoices/details تسمح authenticated DML خارج central gateway | LVE-589 |
| High | Receiver يستخدم po_code غير موجود في purchase_order_details | LVE-589 |
| High | legacy purchase-pos payload لا يطابق save-purchase-order v22 | LVE-589 |
| High | confirm-order وcreate/append Runsheet لا تفرض effective permission | LVE-590/LVE-592 |
| High | Sales Quotes direct permission check لا يرى orders الموروثة لمدير عام | LVE-594 |
| High | save-customer/delete-customer تطلب is_owner غير الموجود في users | LVE-593/LVE-594 |
| Medium | operation_id payload-derived قد يمنع partial action متكررًا بنفس الكمية | LVE-590 |
| Medium | Production migration ledger لا يطابق Git filenames/timestamps واحدًا لواحد | LVE-589 |
| Medium | Staging لا يحتوي Buyer tables/Edge | LVE-589 |

هذه التناقضات لم تُصلح؛ لا يوجد ادعاء إغلاق.

---

## 8. منهج CTO للتعديل والتطوير

### قبل أي تغيير

1. CURRENT_STATE أولًا، ثم تعليماته التشغيلية.
2. تحديد الهدف الحالي والـcheckpoint وآخر حالة مغلقة.
3. فتح المصدر الحالي والـcommit والـdiff.
4. فحص كل المستهلكين والمسارات والـRPCs والـEdge والجداول والـRLS/Triggers/Grants ذات الصلة.
5. مطابقة Git مع Production.
6. فحص artifact/runtime عندما تتوفر أداة فعلية.
7. صياغة فرضيات قابلة للاختبار، لا قرارات مسبقة.

### عند اكتشاف عيب

- حدد السبب الجذري لا العرض.
- حدد أصغر نقطة تغيير.
- افحص الآثار الجانبية على بقية التطبيقات.
- افصل source fix عن DB migration وعن data repair وعن deployment.
- اختبر الطبقة المناسبة.
- تحقق من النتيجة بعد التنفيذ.
- لا تعلن الإغلاق إلا بالدليل المناسب.

### شكل الرقعة المقدمة للمالك

- الملف/المسار.
- الدالة/الـRPC/Edge.
- محدد البحث أو السطر.
- النص الحالي.
- النص البديل كاملًا.
- سبب التغيير.
- المستهلكون والعقود المتأثرة.
- الأثر على البيانات والمخزون والدفاتر.
- الاختبارات الإيجابية والسلبية.
- خطة rollback.

### حدود Production

Master §77.2 هو بوابة موافقة إلزامية. لا DDL، لا DML، لا RLS/grants، لا trigger/RPC change، لا Edge deployment، لا merge/publish قبل عرض diff/SQL والأثر والاختبار والتراجع وانتظار موافقة المالك.

---

## 9. كيف تتم مقارنة الأنظمة العالمية

عند طلب ميزة محددة، لا يكفي ذكر أسماء SAP أو Dynamics أو Oracle أو Odoo. يجب:
1. تحديد العملية التجارية نفسها.
2. الرجوع إلى وثائق رسمية حديثة للمنتج المقارن.
3. تحديد الضوابط والـworkflow والـdata model والـaudit trail في النظام المقارن.
4. فصل ما يناسب حجم وتكلفة RAWAEA عن enterprise overhead غير الضروري.
5. ترجمة النتيجة إلى عقد RAWAEA الحالي بدل نسخ واجهة أو إضافة module موازي.
6. ذكر المصدر والتاريخ والاختلافات والقرار المقترح.

في Procurement مثلًا، يجب مقارنة PO/Receipt/Invoice matching وapproval وattachment provenance وpayment status، وليس مجرد شكل شاشة الفاتورة.

---

## 10. حدود التهيئة المتبقية

لا تزال مرحلة التهيئة غير مكتملة للأسباب التالية:

1. لم يتم تتبع كل 100 Edge Function إلى كل مستهلك وRPC وDB effect.
2. لم يتم تتبع كل 297 public function وكل 186 جدولًا إلى lineage كامل.
3. Migration lineage بين 734 Production migrations و47 operational Git SQL و216 governance SQL لم يُحسم بالكامل.
4. Staging غير متكافئ مع Production في Buyer/Procurement.
5. Cloudflare served artifact وheaders وConsole/Network وBrowser E2E لم تُفحص مباشرة.
6. لم تُنفذ E2E آمنة للدورات Sales → Runsheet → Picking → Loading → Delivery → Return → Settlement.
7. لم تُنفذ E2E آمنة للدورة PR/RFQ/PO → Receiving → Invoice → Payment.
8. لم تُحسم سياسة المالك النهائية لمصفوفة الصلاحيات المالية والمخزنية والتوصيل.
9. لم تُعالج التناقضات الحرجة، ولا يجوز إعلان النظام Production Ready.
10. بعض السجلات الحالية QA fixtures؛ يجب الحفاظ عليها حتى حسم استخدامها.

---

## 11. الحكم النهائي لهذه الجولة

تم بناء خريطة عليا متماسكة للمشروع، وتحديد حدود المسؤولية بين Parent وPWAs وEdge/RPC وProduction، واستعادة قواعد العمل والحوكمة، وتحديد أخطر التناقضات في التفويض والمخزون والمالية والمشتريات.

لكن هذه الخريطة ليست بديلًا عن استكمال dependency graph والـRuntime E2E. لذلك:

**PHASE 1: ADVANCED / NOT COMPLETE.**  
**لا تُرسل عبارة «تم الفهم الكامل للمشروع» بعد.**  
**الحالة: CTO INITIALIZATION CONTINUES / CRITICAL FINDINGS OPEN / NO PRODUCTION MUTATION.**
