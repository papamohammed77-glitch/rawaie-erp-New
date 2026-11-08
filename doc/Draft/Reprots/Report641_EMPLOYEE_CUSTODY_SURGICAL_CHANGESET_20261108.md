# Report641 — Employee Custody Surgical ChangeSet / Live Revalidation
**التاريخ:** 8 نوفمبر 2026 — Africa/Cairo  
**نقطة البداية:** LVE-2026-11-07-640 / Report640  
**نوع العمل:** مراجعة حية، تحليل جذري، تجهيز ChangeSet جراحي، دون كتابة على Production أو المصدر التشغيلي  
**الحالة:** CHANGESET PREPARED — SPECIFIC OWNER APPROVAL REQUIRED

---

## 1. الخلاصة التنفيذية

تم استكمال الدراسة من LVE640 دون إعادة بناء ما سبق. الاتجاه المعماري المعتمد سليم: دفتر مساعد واحد لعهد الموظفين تحت حساب الأستاذ العام 127، مع رصيد فرعي تحليلي لكل موظف/عهدة، وعدم إنشاء حساب GL مستقل لكل موظف، وعدم إنشاء جداول عهد موازية أو Edge Function جديدة.

لكن الفحص الحي في 8 نوفمبر كشف نقاطًا إضافية يجب إغلاقها قبل إطلاق الميزة:

1. سند الصرف العام يستدعي finance_save_expense، والدالة تقبل أي حساب أستاذ نشط دون فحص account_type؛ لذلك يمكن تمرير 127 كأنه مصروف عام، وهذا خلل تصنيفي محاسبي مؤكد.
2. دوال إصدار العهدة والزيادة والتسوية لا تفرض تطابق خزينة العهدة مع فرعها، وإصدار العهدة يسمح بفرع فارغ.
3. buyer_custody_issue_atomic يكتب received_at وقت الإنشاء، قبل إقرار الموظف بالاستلام؛ وهذا توقيت غير صحيح دلاليًا.
4. Issue وAdd Advance تعيدان السجل الموجود عند تكرار operation_id دون مطابقة كامل بيانات العملية؛ إعادة استخدام المفتاح بمحتوى مختلف قد تُخفي طلبًا جديدًا.
5. واجهة Buyer الحالية تجعل الفرع اختياريًا وتعرض الخزائن دون تصفية حسب الفرع؛ يلزم تعديلها من المالك.
6. لا توجد خزينة نشطة لفرع الإسكندرية BR-2، كما أن خزائن BR-01 النقدية العادية رصيدها صفر وقت الفحص. خزينة POS الوحيدة ذات رصيد 190 جنيهًا لا يجوز استعمالها كخزينة صرف عهدة.
7. واجهة الموظف العامة غير مكتملة: جداول العهد تسمح بقراءة الموظف لسجلاته، لكن Edge GET_CUSTODY الحالي يقيد غير الماليين بصلاحيات المشتريات/المالية. لذلك لا نستخدم هذا المسار لتطبيقات الموظفين العامة؛ القراءة الذاتية تتم عبر RLS، والإقرار/المطالبة عبر RPCs القائمة التي تتحقق من auth.uid() وملكية السجل.
8. لا توجد بيئة Staging متاحة في مشروع Supabase؛ لا يجوز اختبار هذه الدورة بإنشاء عهدة أو تحريك خزينة أو قيد في Production.

**لم يتم تنفيذ أي DDL أو RPC أو تعديل Edge أو HTML أو حركة نقدية/محاسبية أو بيانات اختبار في هذا التشغيل.** تم تنفيذ القراءة والتحقق فقط، وتوثيق ChangeSet وحالة الاستئناف.

## 2. الأدلة الحالية ونقطة الاستئناف

- Operational repository: papamohammed77-glitch/erp-frontend، branch main.
- آخر HEAD حي: b728c09e1bb4c482effc48a492546b393ff02c1f؛ لا يوجد Commit تشغيلي أحدث في سجل GitHub عند الفحص.
- Parent main.html blob: 59241e741abcbc318fa68d3c10775e40e2688927، 33,475 سطرًا.
- Core core.js blob: f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1.
- Buyer buyer.html blob: 5ab9f4e268cbf266e6ff950fe41bf5c9a4c9390a.
- Governance checkpoint السابق: LVE640؛ تقريره Report640.
- Supabase SMART ERP: fiilmooggumokxanwiyx، ACTIVE_HEALTHY، PostgreSQL 17.6.1.121.
- Supabase development branches: صفر؛ Staging غير متاح.
- سجل migrations وفق آخر نقطة موثقة LVE640: 755، آخر إصدار مسجل 20261104223538.
- save-purchase-order: ACTIVE v30، verify_jwt=true، SHA-256 838f8c05d5e64f040dc4a346eae52816877d635bab41684d32d77eebeae304e6.
- لم يظهر أي تعديل على Parent/Core/Buyer منذ HEAD التشغيلي أعلاه.

## 3. الحالة المحاسبية الفعلية

- 127 «عهد الموظفين»: حساب Asset / Debit نشط.
- 121 «النقدية (الخزينة الرئيسية)»: حساب Asset / Debit نشط.
- لا توجد حسابات GL فرعية تحت 127، ولا journal_lines مرحلة على 127 في لقطة الفحص.
- لا توجد أرصدة أو حركات عهد في buyer_custodies أو buyer_custody_advances أو buyer_custody_expenses أو buyer_custody_settlements أو buyer_custody_payments.
- الحسابات النشطة من نوع Expense ما زالت 5 و51 و52 فقط؛ لا يوجد حساب تشغيلي فرعي واضح للانتقالات/الوقود/الرسوم. لا يجوز استخدام 51 أو52 بدل حساب مصروف تشغيلي صحيح، ولا يجوز اختراع كود.
- finance_save_expense overload الأساسي يقبل كل حساب نشط في chart_of_accounts، ولا يشترط account_type='expense'. الـoverload الذي يستقبل branch_id يستدعي الدالة الأساسية، وبالتالي يرث الخلل.
- لا يجوز استخدام finance_save_expense لإصدار عهدة؛ فهي تنشئ finance_expenses وقيود Expense وتخفض الخزينة، وليست عقد عهدة موظف.

## 4. حالة الخزائن والفروع — مانع تشغيل فعلي

لقطة الخزائن النشطة:

| الخزينة | الفرع | الرصيد وقت الفحص | القرار |
|---|---|---:|---|
| CASH-01 — الخزينة الرئيسية | مركزية، branch_id فارغ | 10,685 EGP | لا تستخدم لعهدة فرع دون استثناء مركزي معتمد |
| CASH-... — كاشير1 الفرع الرئيسي | BR-01 | 0 EGP | لا يمكن الصرف قبل تمويلها فعليًا |
| CASH-... — كاشير2 الفرع الرئيسي | BR-01 | 0 EGP | لا يمكن الصرف قبل تمويلها فعليًا |
| POS-... — خزينة جهاز POS | BR-01 | 190 EGP | مستبعدة من صرف العهد |

الفروع النشطة تشمل BR-01 بثلاث خزائن، وBR-2 «فرع الإسكندرية» دون أي خزينة نشطة، إضافة إلى فروع مركبات دون خزائن. لذلك لا يمكن اعتبار ميزة عهدة الفروع جاهزة ميدانيًا بمجرد إضافة الشاشة. يجب أولًا إنشاء/تفعيل خزينة نقدية مناسبة لكل فرع من خلال إجراء إدارة الخزائن المعتمد، وتمويلها بتحويل فعلي موثق. لا تنشأ خزائن أو أرصدة تجريبية تلقائيًا.

**قرار الأمان للمرحلة الأولى:** لا يسمح باستخدام CASH-01 المركزية لعهدة فرع، ولا خزائن POS. يسمح فقط بخزينة Cash نشطة مرتبطة بنفس branch_id. أي استثناء مركزي يحتاج صلاحية مستقلة وسببًا موثقًا وتغييرًا منفصلًا.

## 5. هوية الموظف ونطاق الفرع

- المصدر التشغيلي للموظفين هو public.users؛ شاشة HR وsave-employee v10 يستخدمان users.
- employee_profiles فارغ، ولا يجوز بناء شاشة المالية على حقوله الحساسة.
- users.id هو المفتاح المرجعي الحالي للموظف في دفاتر العهد.
- يوجد تعارض بين إحصاء Report640 السابق لعدد سجلات allowed_branch_ids غير الفارغة وبين الفحص الحالي لعضوية branch_code عبر JSONB operator ?. الفحص الحالي وجد 28 مستخدمًا يطابقون BR-01، و2 يطابقون wildcard، و3 لديهم default_branch_id؛ كما أن allowed_branch_ids ليست موحدة الشكل (JSON scalar string أو array). لا نعمم إحصاء التغطية قبل تطبيع/تأكيد هذا الحقل.
- سياسة الربط المقترحة: مقارنة branch_id مع users.default_branch_id، أو ترجمة الفرع إلى branch_code ثم اختبار allowed_branch_ids على branch_code؛ لا تقارن UUID مباشرة بحقل يحتوي أكواد BR-01/BR-2.
- يجب أن يتحقق RPC من نطاق الموظف المستلم ونطاق الموظف المالي المنفذ داخل الخادم، وليس في الواجهة فقط.
- أي موظف بلا إسناد فرع صالح لا يصدر له عهدة حتى يستكمل HR/إدارة المستخدمين بيانات نطاقه.

## 6. عقود قاعدة البيانات الحالية

الجداول القائمة التي يجب الحفاظ عليها وإعادة استخدامها:
- buyer_custodies
- buyer_custody_advances
- buyer_custody_expenses
- buyer_custody_settlements
- buyer_custody_payments
- buyer_goods_custody_events (مفهوم منفصل لحيازة البضاعة)

الكتابات تمر عبر RPCs؛ لا تمنح الواجهة DML مباشرًا على جداول العهد. جداول العهد الخمسة مفعّل عليها RLS ولكل منها سياسة قراءة مخصصة. صلاحيات anon غير ممنوحة لدوال العهد، وauthenticated/service_role لديهما EXECUTE وفق العقود الحالية. لا نوسع GRANT ولا نضعف RLS.

RPCs الحية ذات الصلة:
- buyer_custody_issue_atomic(uuid,uuid,uuid,uuid,text,text,numeric,date,text,text,text)
- buyer_custody_acknowledge_atomic(uuid,uuid)
- buyer_custody_add_advance_atomic(uuid,uuid,uuid,numeric,date,text,text,text)
- buyer_custody_acknowledge_advance_atomic(uuid,uuid)
- buyer_custody_submit_expense_atomic(...)
- buyer_custody_submit_other_expense_atomic(...)
- buyer_custody_review_expense_atomic(...)
- buyer_custody_review_other_expense_atomic(...)
- buyer_custody_settle_atomic(uuid,uuid,uuid,numeric,text,text)
- post_cash_payment_atomic(...)
- post_cash_receipt_atomic(...)

لا ننشئ RPC أو Edge Function موازية قبل استنفاد العقود الحالية. لا نكتب مباشرة إلى treasury أو cash_box أو journal_entries/journal_lines.

## 7. ChangeSet CS-EMP-CUSTODY-641 — تعديلات Production المطلوبة

### 7.1 حماية مسار المصروف العام

الملف/الدالة: public.finance_save_expense overload الأساسي، ويستفيد منه overload الفرع.

الموضع الأصلي داخل حلقة بنود المصروف:
~~~sql
IF NOT EXISTS(SELECT 1 FROM public.chart_of_accounts
              WHERE id=x.account_id AND company_id=p_company_id AND is_active) THEN
  RAISE EXCEPTION 'EXPENSE_ACCOUNT_INVALID';
END IF;
~~~

الاستبدال الجراحي:
~~~sql
IF NOT EXISTS(SELECT 1 FROM public.chart_of_accounts
              WHERE id=x.account_id
                AND company_id=p_company_id
                AND is_active
                AND account_type='expense') THEN
  RAISE EXCEPTION 'EXPENSE_ACCOUNT_INVALID';
END IF;
~~~

الأثر: يمنع تمرير 127 أو أي Asset/Liability/Revenue كحساب مصروف. لا يغير قيود المصروفات الصحيحة ذات account_type='expense'. تبقى واجهة Parent مطالبة بتصفية قائمة الحسابات إلى Expense فقط، لكن الحماية الخادمية هي المرجع النهائي.

### 7.2 حارس الفرع والخزينة في Issue

في buyer_custody_issue_atomic:
- branch_id يصبح إلزاميًا.
- استرجاع branch_code من branches للشركة.
- التحقق من نطاق actor المالي ونطاق الموظف المستلم باستخدام default_branch_id أو allowed_branch_ids ? branch_code أو wildcard.
- قفل الخزينة المحددة والتحقق من: company_id صحيح، active، type='Cash'، account_code لا يبدأ POS-، وtreasury.branch_id يساوي p_branch_id.
- رفض الخزينة المركزية branch_id=NULL في المرحلة الأولى.
- إبقاء فحص الشركة والمستخدم النشط ومنع self-issue وفحص 121/127 كما هو.
- عدم تغيير كاتب القيد المركزي أو اتجاه القيد.

### 7.3 تصحيح توقيت الاستلام

في INSERT buyer_custodies:
- اجعل received_at NULL عند إنشاء طلب/سجل العهدة.
- لا تكتب received_at قبل إقرار الموظف.
في buyer_custody_acknowledge_atomic:
- عند إقرار الموظف وتسجيل عملية الصرف المركزية بنجاح، حدّث received_at وacknowledged_at إلى وقت الاستلام الفعلي.
- لا تسجل received_at عند Draft أو Issue غير مؤكد.

### 7.4 سلامة Idempotency

في buyer_custody_issue_atomic:
- عند العثور على operation_id سابق، اقرأ السلفة Initial المرتبطة.
- طابق employee_id وbranch_id وpurpose وcurrency وissued_date وreceived_reference وnotes، ثم amount وtreasury_id في Initial advance.
- إذا تطابق payload: أعد السجل كـduplicate.
- إذا اختلف أي عنصر: ارفع CUSTODY_OPERATION_ID_CONFLICT، ولا تعد سجلًا قديمًا بصمت.

في buyer_custody_add_advance_atomic:
- طابق custody_id وemployee_id وtreasury_id وamount وcurrency وadvance_date وreference وnotes مع السجل الموجود.
- نفس payload يعاد كـduplicate؛ اختلاف payload يرفض.
- لا تزيد issued_amount مرة ثانية عند retry.

### 7.5 الحارس في بقية نقاط الترحيل

أضف تحقق تطابق Treasury.branch_id مع custody.branch_id ونوع Cash واستبعاد POS في:
- buyer_custody_add_advance_atomic قبل تسجيل الزيادة.
- buyer_custody_acknowledge_atomic قبل post_cash_payment_atomic.
- buyer_custody_acknowledge_advance_atomic قبل post_cash_payment_atomic.
- buyer_custody_settle_atomic قبل post_cash_receipt_atomic عندما يكون cash_returned أكبر من صفر.

لا يسمح بإدخال branch_id فارغ. لا يسمح بالتحايل عبر اختيار خزينة من فرع آخر. لا يسمح بالـPOS. لا تغير post_cash_payment_atomic أو post_cash_receipt_atomic العامة حتى لا تؤثر على دورات أخرى؛ الحارس يضاف داخل عقد العهدة.

### 7.6 ما لا يتغير في هذه الحزمة

- لا تغيير في 121 أو127 أو شجرة الحسابات.
- لا إنشاء حساب GL لكل موظف.
- لا تغيير في القيود المركزية Dr127/Cr121 عند الإقرار، Dr Expense/Cr127 عند اعتماد المصروف، Dr121/Cr127 عند رد النقد فعليًا.
- لا تغيير في قواعد مشتريات البضاعة أو Receiving أو Supplier AP أو المخزون.
- لا تغيير في جداول Buyer أو RLS أو ACL أو Storage.
- لا Edge Function جديدة ولا تغيير في save-purchase-order v30 ضمن هذه الحزمة.
- لا مسار Employee Payable أو خصم رواتب؛ المصروف الزائد يظل محجوبًا كما هو حتى إعداد حساب التزام ومسار سداد مستقل.
- لا إنشاء بيانات اختبار في Production.

ملاحظة تنفيذية: PostgreSQL لا يتيح تعديل جزء من PL/pgSQL function body مباشرة؛ عند اعتماد SQL يجب إصدار CREATE OR REPLACE لكل دالة مع الحفاظ على نصها الحالي كاملًا وتغيير المقاطع المحددة أعلاه فقط. هذا لا يعني إعادة تصميم الدوال أو استبدال منطقها.

## 8. ChangeSet المالك — Parent Finance

المصدر الحالي: main.html blob 59241e741abcbc318fa68d3c10775e40e2688927.

- RW_Finance.renderSubTab: الأسطر 18558–18611.
- قائمة التبويبات: 18564–18584.
- توجيه التبويبات: 18592–18610.
- _newPayment: 20794–20866.
- _addPaymentLine: 20868–20882.
- _savePayment: 20912–20960.

التعديل المقترح:
1. إضافة تبويب «عهد الموظفين» بعد سندات الصرف، بمعرّف employee-custody.
2. إضافة handler واحد يستدعي _renderEmployeeCustody دون تغيير أي renderer موجود.
3. بناء شاشة عهدة منفصلة؛ لا تخلط العهدة مع مصروفات _newPayment.
4. تعرض ملخص الأرصدة حسب الموظف والفرع والعهدة، والحركات، والسلف غير المؤكدة، والمصروفات Submitted/Approved/Rejected، والتسويات، وعمر العهدة.
5. إصدار عهدة جديدة من خزينة الفرع، واختيار موظف نشط ذي نطاق فرع صحيح، والغرض والمبلغ والمرجع. لا تسمح باختيار CASH-01 أو POS في المرحلة الأولى.
6. عند اختيار الموظف/الفرع، لا تعرض إلا خزائن Cash النشطة المرتبطة بنفس الفرع.
7. استخدام RPC العهدة القائمة، وليس finance_save_expense.
8. _addPaymentLine يعرض account_type='expense' فقط. الحماية الخادمية في 7.1 تظل إلزامية حتى مع تصفية الواجهة.
9. عدم تعديل _savePayment أو استبدال _newPayment بالكامل؛ فصل مسار العهدة في تبويب مستقل هو أقل مخاطرة.

هذا تغيير على ملف تشغيلي يطبقه المالك. يجب استخراج المقاطع الحالية مرة أخرى وقت التطبيق إذا تغير HEAD.

## 9. ChangeSet المالك — Buyer

Buyer الحالي هو المستهلك النقدي الوحيد لدفتر buyer_custody_*، ويجب الحفاظ عليه دون كسر مشتريات السوق السريع أو فواتير المورد أو حيازة البضاعة.

التغييرات المحددة:
- جعل اختيار الفرع إلزاميًا في مودال إصدار العهدة.
- عند تغيير الفرع، إعادة بناء قائمة الخزائن من خزائن الشركة النشطة حيث branch_id يساوي الفرع وtype='Cash' واستبعاد account_code POS-.
- لا تعرض خزينة مركزية في إصدار عهدة فرعية.
- إظهار رسالة مفهومة عند عدم وجود خزينة مناسبة: لا توجد خزينة نقدية نشطة لهذا الفرع؛ أنشئ/فعّل الخزينة أو نفذ تحويلًا ماليًا موثقًا.
- نفس التصفية في مودال الزيادة ومودال رد النقد.
- لا تغير رصيد السيارة/حيازة البضاعة؛ هذا دفتر منفصل.

## 10. تطبيق الموظف — التكامل الموحد

لا نضيف Edge Function جديدة ولا نعيد استخدام Edge المشتريات كواجهة عامة لكل الموظفين.

النهج الآمن:
- القراءة الذاتية عبر جداول العهد الموجودة مع RLS، مقيدة بـemployee_id المطابق للمستخدم الحالي.
- إقرار الاستلام عبر buyer_custody_acknowledge_atomic، وإقرار الزيادة عبر buyer_custody_acknowledge_advance_atomic؛ RPC نفسها تتحقق من auth.uid() وملكية العهدة.
- تقديم المصروفات عبر RPC الحالي بعد رفع المستند إلى bucket الحالي وبنفس مسار التخزين والتحقق؛ لا كتابة مباشرة في جدول expenses.
- تعرض الوحدة المشتركة «عهدتي النقدية» داخل تطبيق الموظف، منفصلة عن «رصيد السيارة/عهدة البضاعة».
- Core هو المرشح للوحدة المشتركة، لكن لا نضيفها إلى core.js في هذه الحزمة قبل تحديد نقاط دمج الواجهة واختبار كل تطبيق مستهلك؛ core.js محمّل في التطبيقات كلها وأي تغيير فيه عالي الأثر.
- يبدأ التفعيل بعد اختبار Buyer ثم يوسع إلى تطبيقات المندوبين والتوصيل والموظفين المؤهلين. لا نعرضها للمستخدمين الذين لا يملكون عهدًا، ولا نمنحهم صلاحية مالية بسبب ظهور التبويب.

## 11. سياسة الأثر المحاسبي والمخزني

| الحدث | الأثر |
|---|---|
| إنشاء طلب/عهدة أو اعتمادها | لا نقد ولا قيد |
| تسليم النقد فعليًا وإقرار الموظف | Dr 127 / Cr 121 مرة واحدة |
| تقديم إيصال مصروف | حجز/مطالبة فقط، لا قيد نهائي |
| اعتماد المصروف من المالية | Dr حساب Expense صالح / Cr 127 |
| رد نقد فعلي للخزينة | Dr 121 / Cr 127 |
| شراء بضاعة | يظل Purchase Invoice + Receiving + Supplier/AP حسب العقد الحالي؛ لا يصنف مصروف انتقالات |
| زيادة عهدة | Dr127/Cr121 فقط بعد تسليم فعلي وإقرار مستقل |
| مصروف أكبر من العهدة | محجوب حاليًا؛ لا رصيد دائن غير مفسر على127 ولا خصم رواتب تلقائي |

## 12. خطة الاختبار المطلوبة قبل Production

لا توجد Staging branch حاليًا. لا ننشئ فرعًا مدفوعًا أو نبدأ اختبارات تتكلف دون عرض التكلفة. بعد توفير Staging معزول:

1. اختبار رفض حساب 127 و121 و211 في finance_save_expense، وقبول حساب Expense صالح.
2. اختبار رفض branch_id فارغ.
3. اختبار رفض Treasury من فرع آخر.
4. اختبار رفض CASH-01 المركزي وPOS في المسار الفرعي.
5. اختبار رفض مستخدم غير مخول بنطاق الفرع.
6. اختبار أن received_at يظل NULL قبل الإقرار، ثم يساوي وقت الإقرار بعد التسليم الفعلي.
7. اختبار إعادة نفس operation_id بنفس payload: duplicate بلا حركة إضافية.
8. اختبار إعادة operation_id بمبلغ/موظف/فرع/خزينة مختلفة: CUSTODY_OPERATION_ID_CONFLICT.
9. اختبار الزيادة الإضافية وتأكيدها من الموظف.
10. اختبار المصروف المقدم لا ينشئ قيدًا قبل اعتماد المالية.
11. اختبار المصروف المعتمد يرحل Dr Expense/Cr127 مرة واحدة.
12. اختبار رد النقد الفعلي يرحل Dr121/Cr127 مرة واحدة.
13. اختبار تسوية العهدة ورفض overspend.
14. اختبار أن الموظف لا يرى عهدة زميله ولا يستطيع الإقرار أو تقديم مصروف عليها.
15. اختبار أن Parent Finance يعرض رصيد كل موظف ومجموعه يطابق رصيد 127.
16. اختبار عدم تأثر Buyer Quick Market/Receiving/المخزون/حساب المورد.
17. اختبار عدم تكرار أي cash_box أو journal_entry أو treasury delta عند retry.
18. اختبار إغلاق/إلغاء قبل الصرف دون أثر مالي.

بعد Staging فقط: فحص RLS/ACL، Supabase advisors، JavaScript syntax، Browser E2E، ثم نشر Owner-approved files ومطابقة Cloudflare artifact مع commit.

## 13. خطة التراجع

- لا يوجد backfill أو تغيير في أرصدة قائمة.
- SQL rollback: استعادة نصوص الدوال الأصلية حرفيًا من pg_get_functiondef المحفوظ قبل التطبيق، مع إعادة التحقق من ACL/owner/search_path. لا DROP للجداول أو القيود.
- UI rollback: حذف التبويب والـhandler الجديدين فقط وإرجاع مرشح الحسابات إلى النص السابق إذا لزم، مع الإبقاء على الحارس الخادمي بعد التأكد من عدم وجود استخدام صحيح لحساب غير Expense.
- لا يتم عكس أي قيد مالي أو حركة خزينة تلقائيًا؛ أي حركة تم ترحيلها تتطلب مستند عكس مستقل وفق سياسة المحاسبة.
- لا rollback لـBuyer/Core/main.html إلا عبر استرجاع commit/patch المحدد بعد فحص diff.

## 14. بوابة الاعتماد

موافقة المالك السابقة تثبت الاتجاه المعماري، لكنها لا تعتبر موافقة تنفيذية على SQL أو نشر غير معروض. هذا هو شرط الدستور التشغيلي 6.2 و7 و9 و14.

الحزمة التنفيذية النهائية قبل أي كتابة Production يجب أن تعرض:
- النص الكامل الحالي لكل function من المصدر الحي.
- النص الكامل بعد التعديل، مع تغييرات داخلية محدودة فقط.
- grants/owner/search_path قبل وبعد.
- مقاطع HTML الأصلية والبديلة الدقيقة للمالك.
- الاختبارات ونتائج Staging وخطة التراجع.
- تأكيد أن فرع BR-2 لديه خزينة Cash مفعلة وتمويل حقيقي قبل تفعيل الصرف عليه.

## 15. التقييم النهائي

**CONFIRMED:** أصل الحسابات 121/127، دفتر العهد الحالي، نقاط RPC، مسار المصروف العام، مصدر هوية المستخدم، عدم وجود Staging، الخزائن والفروع وأرصدة الخزائن وقت الفحص.

**CONFLICT:** إحصاء اكتمال allowed_branch_ids في Report640 لا يطابق استعلام العضوية الحالي؛ يلزم تطبيع/تأكيد قبل اعتماد تقرير اكتمال تعيين الفروع.

**UNKNOWN:** سياسة استثناء الخزينة المركزية، من هو أمين الصندوق الفعلي إذا اختلف عن منشئ العهدة، سياسة الأهلية الوظيفية للعهدة، due_date/cost center/mission mapping، Employee Payable، نشر Cloudflare، Browser E2E وRealtime Runtime.

**UNVERIFIED:** لم يطبق أي إصلاح بعد؛ لا توجد بيئة اختبار معزولة ولا E2E.

**الإغلاق:** ROOT CAUSE CONFIRMED — CHANGESET PREPARED / OWNER FILE CHANGE AND SPECIFIC PRODUCTION APPROVAL REQUIRED.  
لا تعلن الميزة مكتملة أو مفعلة حتى تطبيق جميع طبقاتها واجتياز E2E في بيئة معزولة.
