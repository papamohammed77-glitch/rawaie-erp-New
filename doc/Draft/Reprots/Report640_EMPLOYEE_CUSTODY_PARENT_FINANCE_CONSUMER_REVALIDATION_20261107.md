# Report640 — Employee Custody / Parent Finance / Cross-App Contract Revalidation
**التاريخ:** 7 نوفمبر 2026 — Africa/Cairo  
**نقطة البداية:** LVE-2026-11-07-639 / Report639  
**نوع التشغيل:** Read-only source, Production schema/data and contract revalidation  
**النطاق:** Employee Cash Custody، تبويب الحسابات والمالية في Parent، Buyer custody consumers، هوية الموظف ونطاق الفرع.  
**النتيجة:** READY WITH LIMITATIONS — التصميم قابل للاستكمال، لكن لا يجوز توصيله بكل التطبيقات قبل إغلاق هوية الموظف ونطاق الفرع وحماية مسار سند الصرف.

---

## 1. نقطة البداية والمراجع الحاكمة

- CURRENT_STATE: blob `81a4f7b67fe4ce8142474d8c7c25e72ae17daf70`؛ أحدث نقطة مسجلة LVE-2026-11-07-639.
- الدستور التشغيلي الدائم: blob `d2afa896514b1cb6abd247d2af7a862251ce0604`؛ تمت قراءته كاملًا قبل فحص الكود أو Production.
- Report639: commit `fd6d1d41b01399409f90dd49a33fdbb179e0ec5a`، blob `9d1771cf1d2e97db6d3a78593510109665c2efce`.
- Report632: blob `47124a58200c347c8c96ba9786198f59e2d865c5`؛ مرجع دورة Buyer النقدية والمصروفات التشغيلية وحجوزات Quick Market.
- Project memory: `Current/CTO/RAWAEA_PROJECT_MEMORY_117-02.md`، blob `3e25c8ab714a5cd32efdeeb0e383cd9f5bbb2f8c`.
- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`, latest HEAD `b728c09e1bb4c482effc48a492546b393ff02c1f`. آخر Commit تشغيلي ما زال إصلاح Receiver، ولم يظهر Commit أحدث يغيّر Parent/Core/Buyer.
- Governance repository: أحدث Commit ظاهر `05665c187c5ede4ecea3e9c1642d944d67edebea` لتحديث Project Memory؛ Commit `beead06207597e6bc86fb4a3a68aef7b897146ad` حدّث CURRENT_STATE إلى LVE639.

## 2. CONFIRMED — النظام الأم وCore

### Parent `companies/company-1/main.html`
- الملف الحي من GitHub blob: `59241e741abcbc318fa68d3c10775e40e2688927`، 33,475 سطرًا / 1,807,487 حرفًا.
- `RW_Finance.renderSubTab` عند الأسطر 18558–18611 يعرض التبويبات الحالية: الخزائن والبنوك، دليل الحسابات، القيود، سندات القبض، سندات الصرف، الإيرادات، المصروفات، التحويلات، الشيكات، المطابقة، الضرائب، الأصول، الموازنات، الفترات والتقارير. لا يوجد تبويب عهد الموظفين.
- `_renderPayments` عند 20775–20792 يعرض سجلات `cash_box` من النوع Payment.
- `_newPayment` عند 20794–20866 ينشئ سندًا عامًا: فرع، خزينة، مستفيد نصي، مرجع، وبنود حسابات.
- `_loadAllData` عند 18485–18520 يحمل كل الحسابات النشطة من `chart_of_accounts` إلى `_cache.accountsFlat` دون قصرها على نوع Expense.
- `_addPaymentLine` عند 20868–20882 يعرض كل `_cache.accountsFlat` في قائمة الحسابات.
- `_savePayment` عند 20912–20960 يستدعي `finance_save_expense` مباشرة، ويمرر الفرع والخزينة والبنود إلى دالة المصروف العامة.
- لا توجد أي إشارة إلى `buyer_custody` أو Employee Custody في الملف الحالي. لا يوجد ربط بين سند الصرف في Parent وبين سجل عهدة الموظف.
- قائمة الخزائن تُحمّل كل الخزائن النشطة؛ لا يوجد في الواجهة فلتر يربط اختيار الفرع بالخزينة التابعة له.

### Core `companies/company-1/core.js`
- blob: `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`، 1,008 أسطر.
- الوحدات الحالية: `RW_Auth`, `RW_DB`, `RW_API`, `RW_UI`, `RW_ImageCache`, `RW_SW`, `RW_Realtime`.
- لا توجد وحدة مالية أو `RW_EmployeeCustody` مشتركة. يمكن أن يكون Core نقطة تكامل خدمة مشتركة لاحقًا، لكن إضافة وحدة أعمال إليه تغيير عالي الأثر يتطلب ChangeSet وموافقة.

## 3. CONFIRMED — تطبيق Buyer وخريطة المستهلكين

- Buyer blob: `5ab9f4e268cbf266e6ff950fe41bf5c9a4c9390a`.
- Buyer وحده في تطبيقات الشركة الحالية يستخدم دورة العهدة النقدية `buyer_custodies` و`buyer_custody_advances` و`buyer_custody_expenses` و`buyer_custody_settlements` و`buyer_custody_payments`.
- تم فحص ملفات HTML التشغيلية الـ29 الأخرى في `companies/company-1` بحثًا عن عمليات وجداول العهدة النقدية. لم يظهر مستهلك آخر لها. ملف `sales/van-sales.html` يحتوي عبارة «عهدتي الآن»، لكنها تخص رصيد/حيازة البضاعة في السيارة، وليست عهدة نقدية؛ يجب عدم دمج المفهومين.
- Buyer يستدعي `save-purchase-order` Edge، ويستخدم العمليات: `GET_CUSTODY`, `ISSUE_CUSTODY`, `ACKNOWLEDGE_CUSTODY`, `ADD_CUSTODY_ADVANCE`, `ACKNOWLEDGE_CUSTODY_ADVANCE`, `SUBMIT_CUSTODY_EXPENSE`, `SUBMIT_OTHER_CUSTODY_EXPENSE`, `REVIEW_OTHER_CUSTODY_EXPENSE`, `SETTLE_CUSTODY`.
- Buyer يملك شاشة عهدة نقدية ومراجعة مصروفات، لكنه لا يملك عقدًا عامًا لكل موظفي الشركة.
- `issueCustody` في Buyer يعرض جميع الخزائن النشطة دون فلترة حسب الفرع، ويجعل الفرع اختياريًا («بدون تحديد»). نص الواجهة يطلب أن تكون النقدية قد سُلّمت فعليًا، ثم يطلب تأكيد الموظف. دالة Production نفسها تسمح بـbranch_id فارغ.
- Buyer Realtime يشترك في جداول العهدة الستة، ويضبط `reconcileMs:15000` مع debounce 400ms. هذا يثبت إعدادًا في المصدر فقط؛ لا يثبت وصول الأحداث أو زمن المزامنة في Runtime.

### Edge contracts
- `save-purchase-order` حي ACTIVE v30، `verify_jwt=true`, SHA-256 `838f8c05d5e64f040dc4a346eae52816877d635bab41684d32d77eebeae304e6`.
- بوابة Edge الحالية:
  - ISSUE / ADD_ADVANCE / REVIEW / SETTLE: `finance` أو `finance_manager`.
  - ACKNOWLEDGE / SUBMIT_EXPENSE / SUBMIT_OTHER_EXPENSE / VERIFY: `purchases` أو `finance` أو `finance_manager`.
  - GET_CUSTODY: `purchases` أو `finance` أو `finance_manager`.
- لذلك مندوب المبيعات أو التوصيل الذي لا يحمل صلاحية `purchases` أو `finance` لا يستطيع استعمال مسار Edge الحالي لتأكيد عهده أو تقديم مصروفاته، حتى لو كانت العهدة مسجلة باسمه.
- `GET_CUSTODY` في Finance view يقرأ الموظفين من `users` بشرط `status='Active'`، ويعيد حقولًا محدودة: id/name/email/employee_id/default_branch_id. لا يطبق حاليًا علم أهلية عهدة مستقلًا.
- فُحصت Edge functions المالية/الموظفين/الشراء ذات الصلة: `save-payment-voucher` v7، `save-receipt-voucher` v8، `save-journal-entry` v8، `save-employee` v10، `delete-employee` v4، `receive-purchase` v14، `get-cash-flow` v1، `sales-payment-allocation` v2. لم يظهر فيها مسار آخر يكتب Buyer Custody. `save-payment-voucher` يستخدم `finance_save_expense` وليس عهدة موظف.

## 4. CONFIRMED — Production Database / Accounting

Supabase SMART ERP:
- Project ref: `fiilmooggumokxanwiyx`.
- الحالة: `ACTIVE_HEALTHY`; PostgreSQL 17.6.1.121.
- عدد Migrations المسجلة: 755؛ آخرها `20261104223538 buyer_custody_operational_expenses_20261105`.
- لا توجد Supabase Staging branches حاليًا.

### دليل الحسابات والخزائن
- الحساب 127 «عهد الموظفين» موجود ونشط، نوعه Asset وطبيعته Debit.
- الحساب 121 «النقدية (الخزينة الرئيسية)» موجود ونشط، نوعه Asset وطبيعته Debit.
- لا توجد حسابات GL فرعية تحت 127، ولا توجد `journal_lines` مرحّلة على 127 حاليًا.
- الحسابات النشطة من نوع Expense حاليًا: 5 التجميعي، 51 تكلفة المبيعات، 52 فروقات وتسويات المخزون والتوالف. لا يوجد حساب فرعي صالح للانتقالات/الوقود/الرسوم؛ لذلك اعتماد المصروف التشغيلي في Buyer يظل محجوبًا حتى إعداد حسابات صحيحة. لا تستخدم 51 أو 52 ولا تخترع كودًا.
- توجد أربع خزائن نشطة: خزينة رئيسية `CASH-01` بلا `branch_id`، وثلاث خزائن مرتبطة بفرع. لا يوجد في دوال العهدة الحالية تحقق يفرض تطابق فرع العهدة مع فرع الخزينة، ولا استثناء مركزي محكوم بصلاحية منفصلة.

### بيانات العهدة
- `buyer_custodies=0`
- `buyer_custody_advances=0`
- `buyer_custody_expenses=0`
- `buyer_custody_settlements=0`
- `buyer_custody_payments=0`
- `buyer_goods_custody_events=0`
- `cash_box`: 3 Payment و5 Receipt في اللقطة الحالية.
- لا توجد بيانات عهدة أو قيود على 127 من هذه الدورة؛ لم تُنشأ بيانات QA أو أعمال اختبار.

### العقود والصلاحيات
- جداول العهدة تمنح `authenticated` صلاحية SELECT فقط، و`service_role` صلاحيات DML؛ لا توجد صلاحية جدول لـanon.
- دوال `buyer_custody_*` SECURITY DEFINER، وEXECUTE ممنوح لـauthenticated/service_role، وغير ممنوح لـanon.
- RLS يسمح للموظف بقراءة عهدته، ولـFinance/Finance Manager بقراءة النطاق المالي للشركة. لا توجد صلاحية كتابة مباشرة من الواجهة على جداول العهدة؛ الكتابة تمر عبر RPCs المركزية.
- `buyer_custody_issue_atomic` و`buyer_custody_add_advance_atomic` و`buyer_custody_settle_atomic` لا تتحقق من تطابق `treasury.branch_id` مع `custody.branch_id`.
- `buyer_custody_issue_atomic` يسمح بـ`branch_id=NULL`، ويتحقق فقط من أن الفرع المرسل - إن وجد - يتبع الشركة.
- `buyer_custody_issue_atomic` يضع `received_at=now()` وقت إنشاء العهدة، قبل أن يثبت الموظف الاستلام في `acknowledged_at`. هذا تناقض دلالي في التوقيت يجب تصحيحه؛ `acknowledged_at` هو الحقل الذي يتغير عند إقرار الموظف.
- حقول `buyer_custody_advances` تسجل `issued_by` و`acknowledged_by`، لكنها لا تسجل هوية أمين الصندوق/المسلّم الفعلي بحقل مستقل. لا يوجد `handed_over_by` أو `cashier_user_id`.
- دالتا Issue وAdd Advance تعيدان السجل السابق عند تكرار `operation_id` دون مقارنة كامل payload؛ يلزم رفض إعادة استخدام المفتاح بمحتوى مختلف.
- `buyer_custody_settle_atomic` يمنع إغلاق العهدة إذا تجاوزت المصروفات المعتمدة الأموال المستلمة؛ يرفض `EMPLOYEE_PAYABLE_NOT_CONFIGURED` بدل تسجيل دفع لم يحدث. هذا سلوك حماية صحيح، لكنه يترك مسار مستحق الموظف غير مكتمل.
- `buyer_custodies` لا يحتوي `due_date` أو `cost_center_id` أو `mission_id` أو حقول اعتماد إداري منفصلة؛ `purpose` نص حر فقط.

## 5. تصحيح فهم مصدر الموظف — HR / Identity

تم فحص `office/hr.html` (blob `ca4175ba414962855ed2fa95def942afbe570f65`) وEdge `save-employee` v10 (SHA `f1ff0999d1e5bef8423ebeaff580e35d16da505134a09087054725bb89480e75`):
- واجهة HR الحالية تقرأ وتعرض `users`، وEdge `save-employee` ينشئ/يحدّث سجلات `users`. لذلك فراغ `employee_profiles` لا يعني أن شاشة HR بلا موظفين، ولا يجب فرض `employee_profiles` كشرط تقني قبل أي عهدة.
- في Production: 31 user، جميعهم Active؛ `employee_profiles=0`؛ `users.employee_id` فارغ في 31/31؛ `default_branch_id` موجود لدى 3/31 فقط؛ `allowed_branch_ids` غير فارغ لدى 9/31.
- المفتاح التقني الحالي للموظف هو `users.id`، وهو ما تستخدمه دوال العهدة الحالية. لكن لا يوجد حتى الآن كود موظف بشري أو تغطية فرع مكتملة لكل الحسابات. يجب تحديد أهلية استلام العهدة وإكمال تعيين الفرع/النطاق قبل التوسع إلى كل الموظفين.
- `employee_profiles` يتضمن بيانات حساسة مثل الراتب والرقم القومي والعنوان وبيانات الطوارئ، وRLS يقصره على HR أو الموظف نفسه. لا ينبغي أن تعتمد شاشة المالية على قراءة هذا الجدول أو كشف هذه الحقول؛ استخدم دليل موظفين محدودًا من `users` أو RPC/عرضًا يعيد الحد الأدنى فقط.

## 6. فجوة خطيرة في سند الصرف العام

- Parent يحمّل كل الحسابات النشطة في `_cache.accountsFlat`، ويعرضها كلها في `_addPaymentLine`.
- `_savePayment` يرسل البنود إلى `finance_save_expense`.
- الدالة الحالية تتحقق من وجود الحساب ونشاطه، لكنها لا تفرض أن يكون `account_type='expense'` لكل بند. لذلك الحساب 127، وهو Asset، ظاهر وقابل للاختيار في واجهة سند الصرف العامة ويمكن أن يمر في مستند `finance_expenses` بدل إنشاء `buyer_custodies` وسجل موظف.
- النتيجة المحتملة: قيد مدين 127/دائن 121 مع مستند مصروف عام، دون employee_id أو custody_id أو عرض في تطبيق الموظف. هذا لا يمثل عهدة صحيحة حتى لو اتفق اتجاه القيد.
- يمنع استخدام هذا الالتفاف. يلزم في ChangeSet حماية عامة لمسار المصروف بحيث لا يقبل حسابًا غير Expense، ومسار منفصل واضح لوجهة «عهدة موظف» يستخدم RPC العهدة المركزي.
- دالة `finance_save_expense` ذات overload يمرر branch_id وتخزن الفرع، لكنها لا تتحقق من أن الخزينة المختارة تابعة للفرع المختار. يجب ألا يُورث هذا الخلل إلى المسار الجديد.

## 7. التقييم المعماري والتصميم المستهدف

### القرار المحاسبي
استخدم حساب 127 كحساب رقابي تجميعي واحد، وتحته دفتر مساعد (Subledger) للموظفين. يظهر للمستخدم في Parent كأنه شجرة:
- 127 — عهد الموظفين
  - اسم الموظف / رقمه الداخلي
    - عهدة المهمة 001
    - عهدة المهمة 002
    - السلف الإضافية
    - المصروفات المعتمدة
    - النقد المرتجع
    - الرصيد المفتوح / المتأخر

هذه «حسابات فرعية» من منظور العرض والتقارير، وليست حسابات GL فعلية منفصلة لكل موظف. لا أنصح بإنشاء حساب GL لكل موظف افتراضيًا؛ فهذا يضخم دليل الحسابات ويعقد النقل والتعطيل والتسويات. يبقى مجموع أرصدة دفاتر الموظفين مطابقًا لحساب 127، مع إمكانية إنشاء حسابات فعلية منفصلة فقط إذا فرضت سياسة محاسبية موثقة ذلك.

### واجهة Parent Finance
1. إضافة تبويب مستقل «عهد الموظفين» تحت الحسابات والمالية لعرض الموظفين وأرصدتهم المفتوحة، الفروع، المهام، المتأخر، المصروفات المعلقة، والتسويات.
2. في سند الصرف الحالي، إضافة نوع وجهة:
   - «مصروف مباشر» — يبقى على مسار المصروفات الحالي وبنود Expense فقط.
   - «عهدة موظف» — يختفي جدول بنود المصروف، ويظهر الموظف، الفرع، خزينة الفرع، الغرض/المهمة، تاريخ الاستحقاق، المبلغ، مركز التكلفة والمرجع/المرفقات.
3. عند اختيار «عهدة موظف»، يثبت النظام الحساب 127 تلقائيًا؛ لا يختاره المستخدم كبند مصروف.
4. لا يسمح باختيار خزينة فرع مختلف. الخزينة المركزية ذات `branch_id=NULL` لا تُقبل إلا بصلاحية استثناء مركزية وسبب موثق.
5. عند إصدار العهدة، تنشأ وثيقة عهدة وسلفة أولية بحالة انتظار تأكيد التسليم/الاستلام؛ لا يحدث أثر مالي لمجرد المسودة أو الموافقة.
6. بعد إثبات تسليم النقدية وتأكيد الموظف، ينفذ الكاتب المركزي مرة واحدة: Dr 127 / Cr 121، ويرتبط القيد وسند الصرف بالخزينة والعهدة والموظف.
7. مصروف الموظف المقدم بإيصال يظل Submitted/Reserved بلا قيد؛ اعتماد المالية يرحل Dr حساب المصروف الفرعي / Cr 127 مرة واحدة.
8. النقد المتبقي لا يخفض 127 إلا عند استلامه فعليًا في الخزينة: Dr 121 / Cr 127.
9. مشتريات البضاعة ليست مصروف انتقالات؛ تبقى في مسار Purchase/Receiving/Invoice/Buyer الحالي مع منع أي تكرار للمخزون أو Supplier AP أو السداد.
10. إذا زادت المصروفات المعتمدة على النقد المسلم، لا يُسجل عكس رصيد تلقائيًا. إما إعداد مسار Employee Payable كالتزام مستقل ثم سند سداد فعلي، أو إبقاء الإغلاق محجوبًا برسالة واضحة.

### واجهة الموظف
- إضافة مكوّن موحد باسم «عهدتي النقدية» داخل التطبيق الذي يستخدمه الموظف، بنفس عقد البيانات والـRPCs.
- يعرض: الرصيد المسلم والمؤكد، السلف الإضافية، المتاح، المصروفات المعلقة والمعتمدة والمرفوضة، النقد المطلوب رده، تاريخ الاستحقاق، المرفقات، سجل الحركة وحالة التسوية.
- يرى الموظف سجلاته فقط عبر RLS/ownership؛ لا يرى عهد زملائه أو أرصدة الخزائن.
- يظل «رصيد السيارة/عهدة البضاعة» منفصلًا عن «العهدة النقدية».
- Buyer يحتفظ بمسارات فواتير الموردين وQuick Market وحيازة البضاعة؛ لا نكسر وظيفته المتخصصة عند تعميم دفتر النقدية.

### الخدمة المركزية
- إعادة استخدام جداول `buyer_custody_*` وRPCs الحالية كبداية، مع توسيع عقدها تدريجيًا أو تقديم واجهة عامة متوافقة؛ لا تنشئ مجموعة جداول موازية ولا Edge Function جديدة.
- استخدم `users.id` كالمفتاح التقني الحالي، ولا تعتمد على `employee_profiles` الفارغ أو تكشف حقوله الحساسة.
- يمكن إضافة خدمة UI مشتركة في Core أو ملف مشترك بعد فحص المستهلكين؛ لا تكرر قواعد الترحيل في كل تطبيق.
- بوابة Edge الحالية ليست عامة لكل الموظفين؛ يجب إما توفير self-service عبر RPCs المصادق عليها مع ownership checks/RLS، أو تعديل بوابة API القائمة دون تخفيف الحماية ودون جعل عمليات Finance متاحة للموظف.
- لا كتابة مباشرة على جداول العهدة، ولا قيود أو تحديث أرصدة من الواجهة.

## 8. Benchmarking رسمي مختصر

- **Daftra:** دليل عهد الموظفين يربط العهدة بالموظف، رقم العهدة، تاريخها، تاريخ استحقاق التسوية، المبلغ، حساب عهدة الموظف وحساب النقدية/البنك، ثم يسجل التسويات ويعرض الرصيد والحالة. كما يعرض سند الصرف حساب عهدة الموظف كحساب فرعي. نستفيد من وضوح الموظف/المهمة/الاستحقاق والتسوية، لا من إنشاء حساب GL منفصل لكل موظف بالضرورة.
  - https://docs.daftra.com/user_manual/دليل شامل لدورة عهد الموظفين/
  - https://docs.daftra.com/tutorial/إنشاء سند صرف/
- **Microsoft Dynamics 365 Project Operations:** Cash Advance request يمر بطلب ثم Workflow approval ثم دفع المحاسب؛ يربط Expense Report بالسلفة المدفوعة، ويطلب رد المتبقي أو يسجل استحقاق تعويض الموظف عند زيادة المصروف، ويدعم معالجة فروق العملات. هذا معيار مهم لفصل الطلب والموافقة والدفع والتسوية.
  - https://learn.microsoft.com/en-us/dynamics365/project-operations/expense/cash-advance
  - https://learn.microsoft.com/en-us/dynamics365/project-operations/expense/set-up-workflows
- **ERPNext / Frappe HR:** Employee Advance له حالات Draft/Unpaid/Paid/Claimed/Returned/Partly Claimed and Returned/Cancelled. إنشاء الطلب لا ينشئ GL؛ القيد يظهر عند اعتماد Payment Entry/Journal Entry. يدعم الدفعات المتعددة والمرتجعات والتسوية مع Expense Claim، وتقرير Employee Advance Summary يجمع المطلوب والمدفوع والمطالب به والمرتجع والمتبقي حسب الموظف/القسم/الفرع.
  - https://docs.frappe.io/hr/employee-advance
  - https://docs.frappe.io/hr/reports/employee-advance-summary
- **SAP ERP Travel Management:** السلفة ترتبط بالرقم الوظيفي وطلب/رحلة الموظف، وتُدخل قيمتها وعملتها، ثم تدخل نتائج التسوية في مسار الترحيل للمحاسبة.
  - https://help.sap.com/docs/SAP_ERP_SPV/3cdfa583374d45c4be333f3286ddc211/720bcb5389d37214e10000000a174cb4.html

**الخلاصة التنافسية:** RAWAEA يجب أن تجمع وضوح Daftra في دفتر الموظف، وفصل دورة الموافقة والدفع والتسوية في Dynamics، وحالات السلفة والتقرير التجميعي والدفعات الجزئية في ERPNext، وربط الموظف/المهمة بالتسوية كما في SAP. لا ننسخ شكل الحسابات دون ضبط دفتر الأستاذ والمخاطر.

## 9. الفجوات والأولوية

### P1
1. Parent لا يحتوي تبويب عهد الموظفين ولا مسار صرف لعهدة الموظف.
2. الحساب 127 يمكن اختياره في سند الصرف العام، و`finance_save_expense` لا يفرض account_type=expense؛ قد ينشأ مستند مصروف عام غير مربوط بالموظف.
3. Issue/Add Advance/Settlement لا تطابق فرع الخزينة بفرع العهدة، والفرع اختياري في Issue UI/RPC.
4. API الحالي يقصر GET/ACK/Submit على مشتريات أو مالية؛ بقية الموظفين لا يستطيعون استخدام الخدمة من تطبيقاتهم.
5. دليل المستخدمين لا يوفر تغطية فرع كافية: 3/31 default branch و9/31 allowed branches، ولا توجد employee_id بشرية في 31/31. يلزم حسم أهلية الموظف ونطاق الفرع قبل التعميم.

### P2
1. `received_at` يسجل وقت إصدار العهدة لا وقت تأكيد استلامها.
2. لا يوجد حقل مستقل لمن سلّم النقدية فعليًا (Cashier/Handover Actor).
3. Issue/Add Advance يعيدان نتيجة operation_id السابق دون مقارنة payload كاملًا.
4. لا توجد due_date/aging أو cost_center/mission_id منظّمة في رأس العهدة.
5. لا يوجد مسار Employee Payable عند زيادة المصروف المعتمد؛ الإغلاق محجوب حاليًا.
6. لا توجد حسابات Expense فرعية نشطة للانتقالات/الوقود/الرسوم، فيظل اعتماد المصروف التشغيلي محجوبًا.

## 10. الاختبارات وعدم الأثر

- تم تنفيذ قراءات فقط من GitHub وSupabase؛ لا DDL ولا DML ولا Edge deploy ولا تعديل ملفات تشغيلية.
- لم تُنشأ بيانات QA أو عهد أو مصروفات أو قيود.
- تم التحقق من وجود RLS وSELECT-only grants على جداول العهدة، وعدم وجود EXECUTE لـanon على دوال العهدة.
- لم يُنفذ Browser E2E أو اختبار مستخدم مصادق عليه؛ لا توجد Supabase Staging branches.
- رابط Cloudflare Pages لم يكن متاحًا عبر أداة الويب في هذه المراجعة، وسياق Browser غير متاح؛ لذلك Artifact/Runtime parity غير مثبت.
- إعداد Realtime في Buyer ظاهر في المصدر (15 ثانية reconciliation) لكن وصول الأحداث والـlatency لم يُختبرا.

## 11. مصفوفة التحقق والتغطية

| الطبقة | النتيجة | الدليل/الحد |
|---|---|---|
| GitHub Source | CONFIRMED | HEAD b728c09؛ Parent blob 59241؛ Core f4c6؛ Buyer 5ab9 |
| Supabase Production | CONFIRMED | ACTIVE_HEALTHY؛ 755 migrations؛ عقود وجداول/RLS/ACL ولقطة البيانات |
| Deployed Artifact | UNVERIFIED | Cloudflare URL غير متاح عبر Web |
| Runtime / Browser E2E | UNVERIFIED | لا جلسة Browser مصادق عليها |
| Business Data Effects | CONFIRMED (عدم وجود عهد) | كل buyer_custody_* = 0 وjournal_lines على 127 = 0 |
| Staging | UNKNOWN / unavailable | لا Supabase Staging branches |

**نطاق فُحص اليوم:** Parent Finance، Core، Buyer، HR source، 29 ملف HTML آخر للبحث عن مستهلك العهدة النقدية، مصادر Edge ذات الصلة، جداول/دوال/RLS/ACL/COA/Treasury في Production.  
**لم يُفحص اليوم وظيفيًا:** كامل دورات POS/warehouse/delivery/sales/stock/BI؛ لم يظهر تغيير يمسها ضمن هذا النطاق، ولا يُعلن سلامتها بناءً على هذا الفحص.

## 12. مصفوفة النضج — نطاق عهدة الموظف فقط

| المجال | التقييم | السبب |
|---|---:|---|
| السلامة التقنية والمعمارية | 2/5 | كاتب مركزي وRLS موجودان، لكن الخدمة Buyer-specific |
| تكامل التطبيقات والبيانات | 1/5 | Buyer فقط؛ لا مكوّن مشترك لبقية الموظفين |
| العمليات التجارية | 2/5 | دورة Buyer جزئية: تسليم/إقرار/مصروف/تسوية، بلا طلب عام ومهام |
| الرقابة المالية | 2/5 | 127 وقيود مركزية موجودة؛ فرع الخزينة وحماية سند الصرف ناقصان |
| المخزون وسلاسل الإمداد | UNKNOWN | خارج نطاق الفحص الوظيفي اليوم |
| التوزيع والعمل الميداني | 1/5 | لا عهدة نقدية في تطبيقات المندوبين/السائقين |
| التخطيط والتنبؤ | UNKNOWN | لم يُفحص |
| التقارير وBI | 1/5 | لا تقرير موحد لعهد كل الموظفين/الأعمار |
| الأمان والصلاحيات والتدقيق | 2/5 | RLS وownership checks موجودة؛ Edge gate ونطاق الفرع غير مكتملين |
| الأداء والاستقرار | UNKNOWN | لا قياس Runtime/E2E |
| تجربة المستخدم والإنتاجية | 2/5 | Buyer لديه UI، Parent وبقية التطبيقات لا |
| الجاهزية التشغيلية والتنافسية | 1/5 | لا تعميم ولا E2E ولا نشر مثبت |

## 13. خطة ChangeSet المطلوبة — لم تُطبق

1. **Contract/DB:** تحقق فرع الموظف والخزينة، منع branch null للعهدة الفرعية، استثناء مركزي بصلاحية صريحة، تصحيح received_at، إضافة handover actor/time، idempotency payload fingerprint، due_date/cost center/mission عند اعتمادها، مع الحفاظ على الكاتب المركزي.
2. **Parent Finance:** إضافة تبويب عهد الموظفين ومسار Destination=Direct Expense/Employee Custody في سند الصرف؛ منع حساب 127 من بنود المصروف العام؛ عدم تغيير سلوك المصروفات الصحيحة.
3. **Employee apps:** خدمة واجهة مشتركة للعهدة النقدية مع self-only visibility، وربط التطبيقات التي يستخدمها الموظفون دون دمجها مع عهدة البضاعة.
4. **Expense/Settlement:** إعداد حسابات Expense leaf الصحيحة، ثم استكمال Employee Payable بمستند سداد فعلي؛ لا يُفتح المسار قبل تصميم محاسبي.
5. **Acceptance:** اختبارات Staging فقط: عدم الأثر قبل handover/ack، قيد واحد Dr127/Cr121 بعدهما، مصروف Submitted بلا قيد، اعتماد DrExpense/Cr127 مرة واحدة، رد نقدي Dr121/Cr127، رفض Treasury branch mismatch، self-only RLS، منع self-review، idempotency conflict، منع تكرار الأثر، وتطابق مجموع دفتر الموظفين مع GL 127.

**لا توجد موافقة تنفيذية على أي تعديل تشغيلي في هذا التقرير.** لم يتغير Parent أو Core أو Buyer أو Edge أو Production. يتطلب التطبيق ChangeSet محددًا بالنص الأصلي والبديل والاعتماديات والاختبارات والتراجع ثم موافقة صريحة قبل أي كتابة أو نشر.

## 14. الحكم ونقطة الاستئناف

**READY WITH LIMITATIONS.** استعيدت LVE639، وقُرئ الدستور، وتحققت المصادر الحية اللازمة لتصميم عهدة الموظفين. يمكن إعداد ChangeSet دقيق. لا يمكن إعلان الجاهزية للنشر أو التشغيل الميداني بسبب غياب Staging وBrowser E2E وCloudflare artifact verification.

**الخطوة التالية الوحيدة ذات الأولوية:** إعداد ChangeSet تنفيذي جراحي للمرحلة الأولى: هوية الموظف/الفرع/الخزينة + حماية `finance_save_expense` من حسابات غير Expense + مسار «عهدة موظف» في Parent، مع إبقاء Buyer متوافقًا. لا تنفيذ على Production أو ملفات التشغيل قبل اعتماد المالك.

**الخلاصة:** الحساب 127 موجود بالفعل ويجب أن يكون حساب الرقابة العام. المطلوب ليس إنشاء حسابات GL كثيرة، بل دفتر مساعد موحد لكل موظف ومهمة، مربوط بسند الصرف والخزينة والقيد، وتظهر نفس العهدة في تطبيق الموظف، مع فصل صارم بين العهدة النقدية وعهدة البضاعة والمصروفات المباشرة.
