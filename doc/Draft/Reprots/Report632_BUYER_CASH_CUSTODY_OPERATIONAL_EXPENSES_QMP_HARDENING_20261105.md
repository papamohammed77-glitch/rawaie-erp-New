# Report632 — Buyer Cash Custody, Operational Expenses and Quick Market Reservation Hardening
**التاريخ:** 5 نوفمبر 2026 — Africa/Cairo  
**نقطة البداية:** LVE631 / Report631  
**الموافقة:** موافقة المالك الصريحة على تنفيذ تعديلات Buyer ضمن النطاق الحالي.  
**النطاق:** عهدة Buyer النقدية، المصروفات التشغيلية، وحجوزات Quick Market، مع استخدام محرك المشتريات الحالي. لا تعديل في Parent/Core/Receiver/Vouchers.

## 1. القرار التنفيذي

تم تنفيذ Hardening للعهدة النقدية لمسؤول المشتريات، وإضافة مسار مستقل لمصروفات الانتقالات والوقود والرسوم التشغيلية، وإظهار فواتير Quick Market المفتوحة والحجوزات على كل عهدة.

**الحالة:**  
OPERATIONAL EXPENSE SUBMISSION ENABLED / FINANCE POSTING GATED BY COA CONFIGURATION / QMP RESERVATIONS VISIBLE / EDGE v29 ACTIVE / BUYER SOURCE COMMITTED / TAILWIND BUILD PASS / CLOUDFLARE UNVERIFIED / AUTHENTICATED BUYER E2E NOT RUN / SUPPLIER CASH REFUND FLOW OPEN.

المعالجة المعتمدة:
- Quick Market Draft يحجز قيمته من المتاح النقدي عندما يكون مصدر التسوية عهدة الموظف؛ الحجز ليس مصروفًا معتمدًا ولا قيدًا محاسبيًا.
- تقديم مصروف انتقالات أو وقود يضيف مستندًا إلى سجل مصروفات العهدة ويحجز قيمته من المتاح. لا ينشئ صرف خزينة أو مخزونًا أو ذمم مورد أو قيدًا عند التقديم.
- اعتماد المالية لمصروف تشغيلي ينشئ قيدًا واحدًا: مدين حساب المصروف المختار / دائن حساب عهدة الموظف 127. لا ينشئ صرف خزينة ثانيًا.
- رفض المصروف يحرر الحجز من الرصيد المتاح.
- لا تغلق العهدة مع مستند Submitted، أو زيادة لم يؤكد الموظف استلامها، أو فاتورة Quick Market مفتوحة، أو مصروفات معتمدة تتجاوز النقد المسلم.
- لا تُزاد العهدة بسبب مرتجع مورد بمجرد قبول البضاعة؛ يتطلب ذلك مستندات وربطًا مستقلًا كما في القسم 8.

## 2. Production Migration

- ملف التشغيل: supabase/migrations/20261104223538_buyer_custody_operational_expenses_20261105.sql
- اسم Migration: buyer_custody_operational_expenses_20261105
- الإصدار المسجل في Supabase: 20261104223538
- تم تطبيق Migration بنجاح، ثم أعيد التحقق من الأعمدة والقيود والفهارس والدوال.
- ChangeSet الحوكمة: Current/CTO/ChangeSets/20261105/01_buyer_cash_custody_operational_expenses_20261105.sql
- لم تُنشأ بيانات اختبار أو مصروفات أو قيود أو عهد تشغيلية.

### الأعمدة والقيود المضافة إلى buyer_custody_expenses
- expense_type: PURCHASE_INVOICE أو OPERATIONAL.
- expense_category: TRANSPORTATION أو FUEL أو TOLLS_PARKING أو OTHER للمصروف التشغيلي.
- expense_reference: رقم الإيصال أو المرجع.
- expense_account_id: حساب المصروف الذي تختاره المالية عند الاعتماد.

القيود تمنع خلط مصروف تشغيلي بفاتورة مورد، وتتطلب فئة صحيحة، وتربط حساب المصروف بدليل الحسابات. كما تمنع اعتماد مصروف تشغيلي من دون حساب وقيد محاسبي مرتبطين، وتضيف فهارس لقوائم المراجعة وحساب المصروف.

## 3. الدوال الذرية

### buyer_custody_submit_expense_atomic
بقيت لفواتير PO المرتبطة بمورد واستلام مخزني. تم تعزيز التحقق من idempotency بمطابقة كامل الطلب عند إعادة استخدام operation_id. أضيفت حجوزات Quick Market المفتوحة إلى فحص الرصيد المتاح؛ فلا يمكن صرف مبلغ محجوز لفاتورة سوق سريع في مصروف آخر. الدالة لا تقبل مصروف OPERATIONAL.

### buyer_custody_submit_other_expense_atomic
دالة جديدة SECURITY DEFINER وبـ search_path ثابت:
- تستخرج الشركة والموظف من auth.uid()، وتتحقق من أن العهدة تخص الموظف وحالتها مفتوحة وأن استلام النقد مؤكد.
- تتحقق من العملة والفئة والوصف والمبلغ والمرجع.
- تقبل PDF أو JPEG أو PNG أو WEBP حتى 10MB، وتتحقق من وجود الملف الفعلي في bucket الخاص employee-documents ومن MIME والحجم والمسار company/user/buyer-custody/custody-id.
- تحمي operation_id من التكرار أو إعادة الاستخدام مع محتوى مختلف.
- تحسب المتاح خادميًا: السلف المؤكدة ناقص المصروفات Submitted/Approved ناقص حجوزات Quick Market المفتوحة.
- ترفض تجاوز المتاح، وتضيف سطر OPERATIONAL بحالة Submitted.
- لا تنشئ قيدًا أو صرف خزينة أو حركة مخزون أو Supplier Ledger عند التقديم.

### buyer_custody_review_expense_atomic
أصبح يرفض سجلات OPERATIONAL ويحافظ على كونه مراجعًا خاصًا لفواتير PO والاستلام.

### buyer_custody_review_other_expense_atomic
- يتطلب Finance أو Finance Manager ويمنع المراجع من اعتماد مصروف عهدته بنفسه.
- الرفض يحرر الحجز.
- الاعتماد يتطلب حسابًا نشطًا من نوع expense، على مستوى حساب فرعي، داخل الشركة.
- يمنع الحسابات 51 تكلفة المبيعات و52 فروقات/توالف المخزون والحساب التجميعي 5.
- يرحل قيدًا واحدًا عبر post_journal_entry: مدين حساب المصروف المختار / دائن عهدة الموظف 127.
- لا ينشئ صرف خزينة ثانيًا، ولا يغير المخزون أو ذمم المورد.

### buyer_custody_settle_atomic
يحافظ على شروط فصل الواجبات، ويمنع إغلاق العهدة مع مصروفات معلقة أو سلف غير مؤكدة أو حجوزات Quick Market مفتوحة. كما يمنع إغلاقًا ينتج amount_due_employee دون إعداد مسار فعلي لسند صرف الموظف؛ في هذه الحالة يرفض برسالة EMPLOYEE_PAYABLE_NOT_CONFIGURED بدل تسجيل تسوية توحي بدفع لم يحدث.

## 4. Edge Function — save-purchase-order v29

- الإصدار الحي: v29 ACTIVE.
- verify_jwt=true.
- SHA-256: 35caa4f2759ba608a7f3bf86640b4773280bc84447872267d6e4d53896743e04.
- المصدر الحي 39,545 حرفًا.
- العمليات المضافة: SUBMIT_OTHER_CUSTODY_EXPENSE، REVIEW_OTHER_CUSTODY_EXPENSE، VERIFY_CUSTODY_EXPENSE_OPERATION، GET_OTHER_CUSTODY_EXPENSE_ACCOUNTS (مالية فقط).
- لم تُنشأ Edge Function جديدة.
- أرشيف v29 محفوظ في Current/CTO/EdgeSnapshots/20261105/save-purchase-order_v29/index.ts، مع Deployment Manifest.
- تم مزامنة supabase/functions/save-purchase-order/index.ts مع النسخة الحية، ثم تأكد التطابق الحرفي بين Live Supabase وGitHub والأرشيف.

## 5. Buyer UI

الملف الوحيد للواجهة: companies/company-1/purchasing/buyer.html.

Commit Buyer: 21c35a5d02d36c32ecb3304f5cecb6f157911741  
Blob: 5ab9f4e268cbf266e6ff950fe41bf5c9a4c9390a

التغييرات:
1. عرض فواتير Quick Market المفتوحة على كل عهدة: رقم الفاتورة، المورد، رقم فاتورة المورد، التاريخ، الحالة والمبلغ المتبقي المحجوز.
2. بيان أن الحجز ليس مصروفًا معتمدًا أو قيدًا، ولا يخصم ثانية عند تقديم المستند.
3. فصل زر تقديم فاتورة PO عن زر المصروفات التشغيلية.
4. نافذة مصروفات أخرى: النوع، التاريخ، مرجع الإيصال، الوصف، المبلغ والملف الداعم.
5. منع التقديم قبل تأكيد استلام العهدة أو بعد إغلاقها.
6. عند نتيجة RPC مجهولة، تحتفظ الواجهة بالملف وتتحقق من operation_id؛ لا تحذف الإثبات ولا تعيد العملية تلقائيًا.
7. عرض المصروفات التشغيلية حسب الفئة والمرجع والملف، وتوجيه مراجعتها إلى العملية المالية الجديدة.
8. شاشة Finance تطلب حساب مصروف فرعي صحيح؛ إذا لم يوجد حساب صالح تُبقي المستند Submitted.
9. منع إظهار زر إقفال العهدة عند وجود فاتورة Quick Market مفتوحة أو مستند مصروف معلق أو زيادة غير مؤكدة أو تجاوز المصروفات المعتمدة للنقد المسلم.
10. تصحيح وصف وتأكيد التسوية بحيث لا تُسمى مصروفات الوقود والانتقالات «مدفوعات موردين».

## 6. التخزين والصلاحيات

لم تُنشأ Storage policy عامة ولم يصبح bucket عامًا. أعيد فحص سياسات buyer_custody_docs_insert/select/delete القائمة؛ وهي تقيد الملفات بمسار العهدة والموظف والشركة، وتسمح للمالية ومدير المالية بقراءة مستندات العهدة في نفس نطاق الشركة. لذلك لم يكن توسيع الوصول ضروريًا.

ACL للدالتين الجديدتين تمت مراجعته، وكانت الأدوار الممنوحة authenticated وservice_role وpostgres، دون anon/Public.

## 7. COA prerequisite — يمنع الاعتماد المالي حاليًا

الحسابات النشطة من نوع expense في الشركة حاليًا:
- 5 — المصروفات وتكلفة المبيعات (تجميعي).
- 51 — تكلفة المبيعات.
- 52 — فروقات وتسويات المخزون والتوالف.

لا يوجد حساب فرعي صالح للانتقالات أو الوقود أو رسوم الطرق والمواقف. لذلك يستطيع Buyer تقديم المستند وحجز قيمته، ويمكن للمالية رفضه لتحرير الحجز، لكن اعتماد المصروف وترحيله ينتظر إعداد حسابات تشغيلية صحيحة في دليل الحسابات. لا نختلق كود حساب ولا نستخدم 51/52؛ فهذا يخلط تكلفة البضاعة بالمصروفات التشغيلية.

## 8. رد نقدية المورد بعد المرتجع — لم يُنفذ بعد

طلب المالك أن تزيد عهدة Buyer عندما يسلم بضاعة مرتجعة للمورد نيابة عنه ويستلم نقدية مستردة مع إيصال. هذا المسار لم يُنفذ لأن دورة SupplierReturn الحالية لا تسند هذا الربط:

- SupplierReturn في النظام الحالي Branch→Supplier.
- trigger enforce_stock_voucher_custodian يمسح custodian_user_id لهذا النوع؛ لذلك لا يكفي إضافة اختيار Buyer في واجهة فقط.
- assert_supplier_return_contract يفرض to_type='Supplier'.
- complete_manual_stock_voucher_atomic_core_20260828 يرحل الأثر المالي على كامل قيمة المرتجع عند إكمال الإذن؛ ولا يوجد قبول جزئي للمورد.
- Reports615/619 أوضحت أن قبول المورد يحدد القيمة المقبولة وأن تدفق Buyer المفوض يجب أن يسجل حيازة ثم تسليم/قبول، مع قيد مورد مرة واحدة فقط.
- إذا كانت الفاتورة الأصلية مدفوعة من عهدة الموظف، فقد يكون رد المورد نقدًا فعليًا أو Credit Note أو Offset مستقبليًا. لا يجوز افتراض وجود Supplier AP أو زيادة العهدة بمجرد قبول البضاعة.

ما لم يتغير:
- لا تعديل في trigger أو وظائف stock vouchers.
- لا تفويض SupplierReturn إلى Buyer.
- لا حدث Buyer→Supplier أو supplier acceptance batch.
- لا سند قبض نقدي مرتبط بمرتجع ولا ترحيل لحسابات الرد.
- لم تزد أي عهدة في SMART ERP.

المرحلة الصحيحة لإغلاق هذا المسار: ربط purchase_returns بإذن SupplierReturn واحد، إضافة تفويض المخزن إلى Buyer، أحداث حيازة وتسليم وقبول مورد بكميات جزئية، ثم تحديد المخرج المالي (نقد فعلي أو Credit Note/Offset) مع مستند الإثبات، وترحيل الأثر مرة واحدة. يبقى Receiver مؤجلًا كما قرر المالك.

## 9. الاختبارات والتحقق

| الاختبار | النتيجة |
|---|---|
| تطبيق Migration 20261104223538 | PASS |
| فحص الأعمدة والقيود والفهارس والدوال بعد التطبيق | PASS |
| Quick Market reservation ضمن فحص available cash | PASS |
| Storage object/path/MIME/size/idempotency guards | PASS |
| Finance-only operational posting وفصل المراجعة | PASS |
| self-review guard | PASS |
| Edge v29 ACTIVE وverify_jwt=true | PASS |
| Live Edge = Git source = archived source | PASS |
| Buyer inline JavaScript parse-only | PASS |
| Buyer Tailwind CSS production workflow | PASS |
| Authenticated Buyer E2E | NOT RUN |
| Cloudflare artifact parity | UNVERIFIED |
| Supplier refund / delegated SupplierReturn | NOT IMPLEMENTED |

### Tailwind and source verification
GitHub Action Buyer Tailwind Production CSS: run 41927675334، conclusion success، للـcommit 21c35a5. CSS blob 271d669599ddc23a914ca4ddb2f0b803264468f4، 19,694 bytes؛ classes المستخدمة في مصروفات أخرى متوفرة.

### عدم الأثر على بيانات التشغيل
بعد التغيير:
- العملة EGP.
- buyer_custodies=0.
- buyer_custody_advances=0.
- buyer_custody_expenses=0.
- buyer_goods_custody_events=0.
- purchase_invoices=3.
- QUICK_MARKET invoices=0.
لم تُنشأ بيانات اختبار، ولم تتغير مخزونات أو خزائن أو أرصدة موردين أو قيود مالية نتيجة هذه الدفعة.

## 10. حدود التنفيذ

- لا تغيير في main.html أو core.js.
- لا تغيير في Receiver أو Vouchers أو التطبيقات الأخرى.
- لا Edge Function جديدة.
- لا بيانات تشغيلية تجريبية.
- لا تغيير في الأرصدة أو القيود.
- لا تنظيف للفواتير التاريخية.
- لا إعلان عن اكتمال Buyer أو E2E.

## 11. نقطة الاستئناف

1. إعداد حسابات مصروفات تشغيلية فرعية وصحيحة في COA من خلال حوكمة الدليل المحاسبي، ثم اختبار اعتماد المصروف وقيده.
2. التحقق من Cloudflare Pages deployment للـcommit 21c35a5، ثم تشغيل Buyer E2E مصادق عليها ببيانات اختبار قابلة للإزالة.
3. إعداد ChangeSet موحد لمسار supplier return delegation/acceptance/refund بما يتضمن المخزن وBuyer/Finance ومنع ازدواج stock/AP/GL؛ لا زيادة نقدية قبل إثبات النقد الفعلي والقرار المالي.
4. إبقاء Receiver مؤجلًا إلى أن يكتمل اعتماد Buyer والعقد المادي المرتبط به.

**الخلاصة:** تبويب عهدتي يدعم الآن تقديم مصروفات الانتقالات والوقود بإيصالات وحجز نقدي ومراجعة مالية آمنة، ويعرض حجوزات Quick Market ويمنع التسوية المبكرة. ترحيل المصروفات ينتظر حسابات COA صحيحة. زيادة العهدة من رد المورد عن المرتجع لم تُنفذ بعد؛ فهي تتطلب دورة مورد/مخزن/مالية موحدة لا يجوز اختزالها إلى إدخال مبلغ أو صورة إيصال.
