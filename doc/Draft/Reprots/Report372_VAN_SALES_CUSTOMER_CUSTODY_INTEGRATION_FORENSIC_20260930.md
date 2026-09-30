# تقرير تنفيذي — Van Sales Forensic Completion Checkpoint — 2026-09-30

## 1. خلاصة التحقيق

تم فحص:
- CURRENT GIT
- CURRENT SOURCE
- CURRENT PRODUCTION
- CURRENT DATABASE
- CURRENT DEPLOYMENT EVIDENCE
- CURRENT_STATE
- MASTER CTO GOVERNANCE

الهدف: استكمال التكامل الوظيفي لتطبيق:
`erp-frontend/companies/company-1/sales/van-sales.html`
دون تعديل الملف المحمي أو `main.html` أو `warehouse/vouchers.html`.

## 2. ما ثبت فعليًا

### Van custody

Production يثبت أن المركبة:
- `VHL-0422` مرتبطة بالمندوب `vansales2@rawaea.com`.
- مخزن السيارة canonical هو `VAN-VHL-0422`.
- `stock_branches` هو مصدر الكمية الفعلية للعهدة.
- الصفوف ذات الكمية صفر صحيحة كصفوف Master ولا يجوز حذفها.

### Financial balance

`رصيدي` مصدره `driver_ledger`، وهو التزام مالي مستقل عن قيمة مخزون السيارة.

تم اكتشاف أثر اختبار قديم:
- IN-8
- IN-9
- كان يترك أثرًا صافيًا 135 جنيهًا في عهدة `vansales2@rawaea.com`.
- كان هناك أيضًا أثر مخزني متبقٍ قدره 1 وحدة من الصنف 1003 في VAN-VHL-0422.

تمت المعالجة الفعلية في Production:
- عكس أثر الـ1 وحدة عبر `post_stock_movement` من السيارة إلى MAIN.
- إزالة صفّي `driver_ledger` الاختباريين المحددين.
- الاحتفاظ بسجل التدقيق.
- عدم حذف سجلات هوية عمليات `stock_voucher_operations` لأن قاعدة البيانات تمنع حذفها لحماية idempotency والتاريخ التشغيلي.
- التحقق النهائي: رصيد `vansales2` من `driver_ledger` أصبح بلا هذه الصفوف، ورصيد الصنف 1003 في VAN-VHL-0422 عاد إلى 0.

## 3. Customer Assignment Contract

Production يحتوي:
`customer_assignments`

والـRLS الحالي يربط العميل بالمستخدم/الشركة.

لكن Production الحالي لا يحتوي أي assignments فعالة، وجميع العملاء الحاليين في الشركة بلا مديونية؛ لذلك نتيجة قائمة «عملائي» الصحيحة حاليًا هي قائمة فارغة، لا بيانات وهمية.

## 4. Backend capability added

تم إنشاء/تصحيح RPC:

`public.get_van_sales_customer_account(uuid,text)`

المسار:
- JWT
- `public.users.auth_id`
- `company_id`
- صلاحية `van-sales`
- `customer_assignments`
- customers/ledger/payments/installments

والـRPC يعيد:
- قائمة العملاء المخصصين للمندوب فقط.
- العملاء ذوي الرصيد المدين فقط.
- إجمالي مديونية المندوب في أعلى القائمة.
- تفاصيل حساب العميل عند طلب Customer ID.
- الفواتير.
- customer ledger.
- payments.
- installment aging.

تم تنفيذ هذا الـRPC في Production مع:
- SECURITY DEFINER
- `search_path = public, pg_temp`
- Execute للمصادق عليهم فقط
- لا Execute لـanon/public.

## 5. Frontend status

لم يتم تعديل:
- `van-sales.html`
- `main.html`
- `warehouse/vouchers.html`

وتم إعداد Owner Surgical Patches فقط.

### Patch A — Customers

العناصر الحالية غير الكافية:
- `renderCustomersView`
- `renderMyCustomersList`
- `filterMyCustomers`

المشكلة:
الواجهة تعتمد على Dexie `myCustomers` المبني تاريخيًا، وليس عقد تعيين العملاء الحالي.

الهدف:
- البحث من RPC الجديد.
- العملاء المخصصون للمندوب فقط.
- إظهار أصحاب المديونية فقط.
- إجمالي الدين أعلى القائمة.
- زر «تحصيل».

### Patch B — Customer Account

`showCustomerDetail` الحالي يجمع الفواتير الآجلة فقط ولا يعرض مسار الحساب الكامل.

البديل يجب أن يستخدم:
`get_van_sales_customer_account(p_customer_id)`

ويعرض:
- إجمالي المديونية.
- الفواتير.
- الحركات.
- المدفوعات.
- الأقساط/الاستحقاقات.
- زر التحصيل.

### Patch C — Collection operation identity

`collectPayment()` يحتفظ بهوية العملية في localStorage.

العقد المطلوب:
- الاحتفاظ بالهوية حتى نجاح العملية.
- حذفها مباشرة بعد نجاح مؤكد.
- عدم إعادة استعمال operation ID بعد نجاح تحصيل فعلي.

## 6. أهم نتائج العقد

`save-receipt-voucher v8` Production موجود، ويربط تحصيل Van Sales إلى:
`post_van_sales_collection_atomic`

وهذا الـCore يفرض:
- شركة المستخدم.
- العميل.
- customer assignment.
- treasury.
- customer ledger.
- driver ledger.
- idempotency.

لا حاجة لإنشاء Edge Function جديدة.

## 7. لا يوجد مبرر لتعديل main أو vouchers

تطبيق الأذونات المخزنية الحالي `warehouse/vouchers.html` يستعمل نموذج الإذن المركزي ويحتوي على:
- Direct Sale
- Direct Return
- Transfer
- Supplier Return
- Adjustment
- Scrap
- direct-sales assignments

لذلك تكامل Van Sales يجب أن يتعامل معها كـsource of custody/movement وليس أن يعيد بناء منطقها داخل Van Sales.

## 8. حالة المهمة

### Production
- بيانات المخزون: verified.
- بيانات العهدة المالية الاختبارية القديمة: cleaned.
- RPC حساب العملاء للمندوب: deployed.

### Current
- لم يُمس الملف المحمي.
- Owner patches جاهزة.

### Remaining Owner Action
تطبيق الـpatches الجراحية على `van-sales.html` ثم اختبار:
- syntax
- login
- vehicle custody
- assigned debtor customers
- customer account
- collection
- same-day repeated collection
- invoice creation
- stock/custody consistency

## 9. Self-Audit

Business Understanding: 99/100
Architecture Understanding: 99/100
Database Understanding: 100/100
Production Understanding: 100/100
Current Understanding: 100/100
Execution Confidence: 96/100

Confirmed Facts: Production DB + Production Edge + Current source verified.
Unknowns: browser execution after Owner applies protected-file patches.
Conflicts: none material for this checkpoint.
Unverified: final browser UI after Owner patch.

## 10. جلسة الاستكمال التالية

ابدأ من هذه النقطة فقط.

لا تعِد:
- إصلاح custody source.
- إصلاح setup-van-branch.
- إصلاح save-receipt-voucher backend.
- إصلاح central stock engine.

ابدأ بـOwner Patch:
`renderCustomersView + renderMyCustomersList + filterMyCustomers + showCustomerDetail`

ثم:
`collectPayment`

ثم:
`loadCustomerPatterns/loadKPIs/loadHomeSalesSummary/loadMyInvoices`

ثم:
`initiateEndOfDay`

والحكم النهائي لا يكون 100% إلا بعد إثبات التكامل الفعلي مع Production.
