# Report641 — Employee Custody Surgical ChangeSet / Live Revalidation

> **تصحيح المالك الملزم — 8 نوفمبر 2026:** التنفيذ والاختبار لهذا المشروع يتمان مباشرة على SMART ERP Production \`fiilmooggumokxanwiyx\` وعلى \`erp-frontend/main/companies/company-1\` فقط. لا تنشئ Supabase Staging أو Git branches أو نسخ تطبيق بديلة. يجوز إنشاء Fixtures اصطناعية مؤقتة على Production، بعلامة QA فريدة، مع baseline وIDs وخطة cleanup معروفة؛ استخدم BEGIN/ROLLBACK متى أمكن، وبعد E2E committed احذف كل Fixture والتابعات والمرفقات وتحقق أن الأرصدة والعدادات عادت إلى baseline. لا تلمس بيانات أعمال حقيقية ولا تترك أثر QA. هذا التصحيح يتجاوز كل عبارة «Staging فقط» أو «Production ليس بيئة اختبار» في هذا التقرير. لا يتجاوز بوابة اعتماد التغييرات الدائمة المنصوص عليها في الدستور §6.2/§6.4.

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
8. لا توجد Supabase Staging branch، وهذا متوافق مع نموذج العمل المعتمد وليس عائقًا. اختبارات هذه الدورة تتم على Production ببيانات QA اصطناعية مؤقتة وموسومة وقابلة للإزالة، أو داخل BEGIN/ROLLBACK، مع إثبات استعادة baseline قبل الإغلاق.

**لم يتم تنفيذ أي DDL أو RPC أو تعديل Edge أو HTML أو حركة نقدية/محاسبية أو بيانات اختبار في هذا التشغيل.** تم تنفيذ القراءة والتحقق فقط، وتوثيق ChangeSet وحالة الاستئناف.

## 2. الأدلة الحالية ونقطة الاستئناف

- Operational repository: papamohammed77-glitch/erp-frontend، branch main.
- آخر HEAD حي: b728c09e1bb4c482effc48a492546b393ff02c1f؛ لا يوجد Commit تشغيلي أحدث في سجل GitHub عند الفحص.
- Parent main.html blob: 59241e741abcbc318fa68d3c10775e40e2688927، 33,475 سطرًا.
- Core core.js blob: f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1.
- Buyer buyer.html blob: 5ab9f4e268cbf266e6ff950fe41bf5c9a4c9390a.
- Governance checkpoint السابق: LVE640؛ تقريره Report640.
- Supabase SMART ERP: fiilmooggumokxanwiyx، ACTIVE_HEALTHY، PostgreSQL 17.6.1.121.
- Supabase development branches: صفر؛ لا يُنشأ Staging أو فرع بديل وفق توجيه المالك. الاختبار المباشر على Production ببيانات QA مؤقتة ومضبوطة.
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
- يجوز إنشاء بيانات QA اصطناعية مؤقتة على Production وفق §6.4 من الدستور؛ يجب أن تكون موسومة وفريدة وقابلة للإزالة، مع إثبات cleanup وعودة الحالة إلى baseline. لا تنشأ بيانات في هذا التنفيذ التوثيقي.

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

## 12. خطة الاختبار والقبول على Production

تُنفّذ الاختبارات على SMART ERP Production نفسها وفق توجيه المالك §6.4، ولا يُنشأ مشروع أو فرع Staging أو نسخة بديلة. قبل أي Fixture: احفظ baseline للأعداد والأرصدة والقيود والمخزون والخزائن والجداول المتأثرة، وضع خطة cleanup كاملة ومعرّفات QA فريدة. استخدم BEGIN/ROLLBACK لاختبارات SQL/RPC التي يمكن إثباتها داخل معاملة واحدة. ولـBrowser E2E الذي يحتاج بيانات committed، أنشئ فقط سجلات QA اصطناعية معلّمة، لا تمس بيانات أعمال فعلية، واحذفها بعد الاختبار مع كل العلاقات والمرفقات والآثار التابعة المسموح بحذفها. لا تنفذ مسار ترحيل يُنتج أثرًا لا يمكن التراجع عنه أو إثبات تنظيفه. بعد كل تشغيل، طابق الأعداد والأرصدة مع baseline وأثبت عدم بقاء أي QA record أو أثر.

خطة الاختبار:

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

بعد اختبارات SQL/RPC وE2E المضبوطة مباشرة على Production مع rollback/cleanup: افحص RLS/ACL وSupabase advisors وJavaScript syntax، ثم تحقق من Cloudflare artifact ومطابقته للـcommit المنشور.

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
- الاختبارات ونتائج Production QA، وbaseline/cleanup proof، وخطة التراجع.
- تأكيد أن فرع BR-2 لديه خزينة Cash مفعلة وتمويل حقيقي قبل تفعيل الصرف عليه.

## 15. التقييم النهائي

**CONFIRMED:** أصل الحسابات 121/127، دفتر العهد الحالي، نقاط RPC، مسار المصروف العام، مصدر هوية المستخدم، عدم وجود Staging، الخزائن والفروع وأرصدة الخزائن وقت الفحص.

**CONFLICT:** إحصاء اكتمال allowed_branch_ids في Report640 لا يطابق استعلام العضوية الحالي؛ يلزم تطبيع/تأكيد قبل اعتماد تقرير اكتمال تعيين الفروع.

**UNKNOWN:** سياسة استثناء الخزينة المركزية، من هو أمين الصندوق الفعلي إذا اختلف عن منشئ العهدة، سياسة الأهلية الوظيفية للعهدة، due_date/cost center/mission mapping، Employee Payable، نشر Cloudflare، Browser E2E وRealtime Runtime.

**UNVERIFIED:** لم يطبق أي إصلاح بعد؛ لا توجد بيئة اختبار معزولة ولا E2E.

**الإغلاق:** ROOT CAUSE CONFIRMED — CHANGESET PREPARED / OWNER FILE CHANGE AND SPECIFIC PRODUCTION APPROVAL REQUIRED.  
لا تعلن الميزة مكتملة أو مفعلة حتى تطبيق جميع طبقاتها واجتياز E2E في بيئة معزولة.


---

## 16. الملحق التنفيذي A — نصوص الدوال المقترحة كاملة (غير منفذة)

النصوص التالية أعيد توليدها من pg_get_functiondef الحي في 8 نوفمبر 2026، مع الحفاظ على توقيعات الدوال وخصائص SECURITY DEFINER وsearch_path الحالية. التغيير داخل كل دالة محصور في حارس النوع/الفرع/الخزينة/التوقيت/Idempotency الموصوف أعلاه. لم تُنفذ هذه النصوص.

- finance_save_expense الأساسي: أضيف شرط account_type='expense' فقط.
- buyer_custody_issue_atomic: branch_id إلزامي، فحص نطاق الموظف والمنفذ، خزينة نقدية من نفس الفرع وليست POS، idempotency بمطابقة payload، وreceived_at=NULL عند الإنشاء.
- buyer_custody_acknowledge_atomic: فحص الخزينة قبل الصرف فقط، ثم تسجيل received_at بعد نجاح الترحيل.
- buyer_custody_add_advance_atomic: مطابقة payload عند retry وفحص الفرع والخزينة للزيادة الجديدة.
- buyer_custody_acknowledge_advance_atomic: فحص الخزينة والفرع قبل ترحيل الزيادة.
- buyer_custody_settle_atomic: فحص نطاق منفذ التسوية وخزينة رد النقد من نفس الفرع.

ملاحظة مهمة: CREATE OR REPLACE يحافظ على owner وACL القائمة في PostgreSQL، لكن يجب توثيقها قبل/بعد ومطابقتها بعد التنفيذ. لا يتضمن الملحق أي GRANT أو REVOKE أو DDL للجداول أو تغيير RLS.

### SQL المقترح

~~~sql
-- PROPOSED CHANGESET CS-EMP-CUSTODY-641. NOT EXECUTED.

-- Capture the existing function owner, ACL, volatility, and search_path before deployment.

-- Proposed QA validation on SMART ERP Production only: BEGIN/ROLLBACK when possible; otherwise use uniquely tagged disposable QA fixtures and prove complete cleanup. Do not touch real business records. This is a proposed patch and has NOT been executed.

BEGIN;

CREATE OR REPLACE FUNCTION public.finance_save_expense(p_company_id uuid, p_expense_id uuid, p_expense_code text, p_expense_date date, p_beneficiary_name text, p_category_id uuid, p_treasury_id uuid, p_description text, p_attachment_url text, p_reference text, p_created_by text, p_operation_id uuid, p_lines jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_existing public.finance_expenses%ROWTYPE; v_id uuid; x record; v_lines jsonb:='[]'::jsonb;
  v_total numeric:=0; v_tax numeric:=0; v_cash_account uuid; v_ap_account uuid; v_je jsonb; v_cash_box_id uuid;
  v_treasury public.treasury%ROWTYPE;
BEGIN
  IF app_private.current_user_company_id() IS DISTINCT FROM p_company_id THEN RAISE EXCEPTION 'FINANCE_COMPANY_CONTEXT_REQUIRED'; END IF;
  IF p_operation_id IS NULL THEN RAISE EXCEPTION 'EXPENSE_OPERATION_ID_REQUIRED'; END IF;
  IF p_expense_date IS NULL OR p_lines IS NULL OR jsonb_typeof(p_lines)<>'array' OR jsonb_array_length(p_lines)=0 THEN RAISE EXCEPTION 'EXPENSE_REQUIRED'; END IF;
  IF NULLIF(BTRIM(COALESCE(p_expense_code,'')),'') IS NULL THEN RAISE EXCEPTION 'EXPENSE_CODE_REQUIRED'; END IF;
  PERFORM finance_period_guard(p_company_id,p_expense_date);
  SELECT * INTO v_existing FROM public.finance_expenses WHERE company_id=p_company_id AND operation_id=p_operation_id FOR UPDATE;
  IF FOUND THEN
    RETURN jsonb_build_object('success',true,'duplicate',true,'id',v_existing.id,'expense_code',v_existing.expense_code,'journal_entry_id',v_existing.journal_entry_id);
  END IF;
  IF p_category_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.finance_expense_categories WHERE id=p_category_id AND company_id=p_company_id AND is_active) THEN
    RAISE EXCEPTION 'EXPENSE_CATEGORY_INVALID';
  END IF;
  IF p_treasury_id IS NOT NULL THEN
    SELECT * INTO v_treasury FROM public.treasury WHERE id=p_treasury_id AND company_id=p_company_id AND COALESCE(is_active,true) FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'EXPENSE_TREASURY_INVALID'; END IF;
    SELECT id INTO v_cash_account FROM public.chart_of_accounts WHERE company_id=p_company_id AND account_code='121' AND is_active ORDER BY id LIMIT 1;
    IF v_cash_account IS NULL THEN RAISE EXCEPTION 'EXPENSE_CASH_ACCOUNT_NOT_CONFIGURED'; END IF;
  ELSE
    SELECT id INTO v_ap_account FROM public.chart_of_accounts WHERE company_id=p_company_id AND account_code='211' AND is_active ORDER BY id LIMIT 1;
    IF v_ap_account IS NULL THEN RAISE EXCEPTION 'EXPENSE_AP_ACCOUNT_NOT_CONFIGURED'; END IF;
  END IF;

  FOR x IN SELECT * FROM jsonb_to_recordset(p_lines) AS z(account_id uuid,cost_center_id uuid,tax_code_id uuid,description text,amount numeric,tax_amount numeric) LOOP
    IF x.account_id IS NULL OR COALESCE(x.amount,0)<=0 OR COALESCE(x.tax_amount,0)<0 THEN RAISE EXCEPTION 'EXPENSE_LINE_INVALID'; END IF;
    IF NOT EXISTS(SELECT 1 FROM public.chart_of_accounts WHERE id=x.account_id AND company_id=p_company_id AND is_active AND account_type='expense') THEN RAISE EXCEPTION 'EXPENSE_ACCOUNT_INVALID'; END IF;
    IF x.cost_center_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.cost_centers WHERE id=x.cost_center_id AND is_active) THEN RAISE EXCEPTION 'EXPENSE_COST_CENTER_INVALID'; END IF;
    IF x.tax_code_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.finance_tax_codes WHERE id=x.tax_code_id AND company_id=p_company_id AND is_active) THEN RAISE EXCEPTION 'EXPENSE_TAX_CODE_INVALID'; END IF;
    v_lines:=v_lines||jsonb_build_array(jsonb_build_object('account_id',x.account_id,'debit',x.amount,'credit',0,'cost_center_id',x.cost_center_id,'notes',COALESCE(x.description,p_description)));
    v_total:=v_total+x.amount; v_tax:=v_tax+COALESCE(x.tax_amount,0);
    IF x.tax_code_id IS NOT NULL AND COALESCE(x.tax_amount,0)>0 THEN
      IF (SELECT purchase_account_id FROM public.finance_tax_codes WHERE id=x.tax_code_id AND company_id=p_company_id) IS NULL THEN RAISE EXCEPTION 'EXPENSE_INPUT_TAX_ACCOUNT_NOT_CONFIGURED'; END IF;
      v_lines:=v_lines||jsonb_build_array(jsonb_build_object('account_id',(SELECT purchase_account_id FROM public.finance_tax_codes WHERE id=x.tax_code_id AND company_id=p_company_id),'debit',x.tax_amount,'credit',0,'notes','ضريبة مدخلات'));
    END IF;
  END LOOP;
  IF v_total<=0 THEN RAISE EXCEPTION 'EXPENSE_AMOUNT_INVALID'; END IF;
  IF v_cash_account IS NOT NULL AND COALESCE(v_treasury.current_balance,0)<(v_total+v_tax) THEN RAISE EXCEPTION 'EXPENSE_INSUFFICIENT_TREASURY_BALANCE'; END IF;
  v_lines:=v_lines||jsonb_build_array(jsonb_build_object('account_id',COALESCE(v_cash_account,v_ap_account),'debit',0,'credit',v_total+v_tax,'notes',CASE WHEN v_cash_account IS NOT NULL THEN 'سداد مصروف' ELSE 'مصروف مستحق' END));

  v_je:=public.post_journal_entry(p_company_id,p_operation_id,p_expense_date,'Expense',COALESCE(NULLIF(BTRIM(p_reference),''),p_expense_code),COALESCE(NULLIF(BTRIM(p_description),''),'مصروف'),p_created_by,v_lines,NULL,now(),NULL);

  INSERT INTO public.finance_expenses(company_id,expense_code,expense_date,beneficiary_name,category_id,treasury_id,total_amount,tax_amount,status,description,attachment_url,reference,journal_entry_id,operation_id,created_by)
  VALUES(p_company_id,p_expense_code,p_expense_date,p_beneficiary_name,p_category_id,p_treasury_id,v_total,v_tax,'POSTED',p_description,p_attachment_url,p_reference,(v_je->>'entry_id')::uuid,p_operation_id,p_created_by)
  RETURNING id INTO v_id;

  FOR x IN SELECT * FROM jsonb_to_recordset(p_lines) AS z(account_id uuid,cost_center_id uuid,tax_code_id uuid,description text,amount numeric,tax_amount numeric) LOOP
    INSERT INTO public.finance_expense_lines(expense_id,company_id,account_id,cost_center_id,tax_code_id,description,amount,tax_amount)
    VALUES(v_id,p_company_id,x.account_id,x.cost_center_id,x.tax_code_id,x.description,x.amount,COALESCE(x.tax_amount,0));
    IF x.tax_code_id IS NOT NULL AND COALESCE(x.tax_amount,0)>0 THEN
      PERFORM public.finance_tax_post(p_company_id,x.tax_code_id,p_expense_date,'INPUT',x.amount,x.tax_amount,'EXPENSE',v_id,(v_je->>'entry_id')::uuid,p_operation_id,x.description,p_created_by);
    END IF;
  END LOOP;

  IF p_treasury_id IS NOT NULL THEN
    INSERT INTO public.cash_box(id,company_id,voucher_code,voucher_date,treasury_id,type,amount,source_type,source_id,source_name,reference,notes,status,user_email)
    VALUES(gen_random_uuid(),p_company_id,'EXP-'||p_expense_code,p_expense_date,p_treasury_id,'Payment',v_total+v_tax,'Expense',v_id,p_beneficiary_name,p_reference,p_description,'Active',p_created_by)
    RETURNING id INTO v_cash_box_id;
    UPDATE public.treasury SET current_balance=COALESCE(current_balance,0)-(v_total+v_tax),updated_at=now()
    WHERE id=p_treasury_id AND company_id=p_company_id;
  END IF;

  RETURN jsonb_build_object('success',true,'duplicate',false,'id',v_id,'expense_code',p_expense_code,'journal_entry_id',v_je->>'entry_id','cash_box_id',v_cash_box_id,'total',v_total+v_tax);
END; $function$;;


CREATE OR REPLACE FUNCTION public.buyer_custody_issue_atomic(p_company_id uuid, p_employee_id uuid, p_branch_id uuid, p_treasury_id uuid, p_purpose text, p_currency text, p_amount numeric, p_issued_date date, p_received_reference text, p_notes text, p_operation_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_actor public.users%rowtype; v_employee public.users%rowtype; v_row public.buyer_custodies%rowtype;
 v_currency text; v_cash_account uuid; v_custody_account uuid; v_cash_result jsonb; v_advance_id uuid;
 v_treasury public.treasury%rowtype; v_existing_advance public.buyer_custody_advances%rowtype; v_branch_code text;
begin
 select * into v_actor from public.users where auth_id=auth.uid() and company_id=p_company_id and coalesce(status,'Active')='Active';
 if not found then raise exception 'CUSTODY_AUTH_REQUIRED'; end if;
 if not (app_private.current_user_has_effective_permission('finance') or app_private.current_user_has_effective_permission('finance_manager')) then raise exception 'CUSTODY_FINANCE_PERMISSION_REQUIRED'; end if;
 if p_amount is null or p_amount<=0 or nullif(btrim(p_purpose),'') is null or nullif(btrim(p_operation_id),'') is null or p_treasury_id is null or p_branch_id is null then raise exception 'CUSTODY_INVALID_ISSUE'; end if;
 SELECT b.branch_code INTO v_branch_code FROM public.branches b WHERE b.id=p_branch_id AND b.company_id=p_company_id AND coalesce(b.is_active,true);
 IF NOT FOUND OR nullif(btrim(v_branch_code),'') IS NULL THEN RAISE EXCEPTION 'CUSTODY_BRANCH_INVALID'; END IF;
 IF NOT (COALESCE(v_actor.default_branch_id=p_branch_id,false) OR COALESCE(v_actor.allowed_branch_ids,'[]'::jsonb) ? v_branch_code OR COALESCE(v_actor.allowed_branch_ids,'[]'::jsonb) ? '*') THEN RAISE EXCEPTION 'CUSTODY_ACTOR_BRANCH_FORBIDDEN'; END IF;
 select * into v_employee from public.users where id=p_employee_id and company_id=p_company_id and coalesce(status,'Active')='Active';
 if not found then raise exception 'CUSTODY_EMPLOYEE_INVALID'; end if;
 if v_employee.id=v_actor.id then raise exception 'CUSTODY_SELF_ISSUE_FORBIDDEN'; end if;
 IF NOT (COALESCE(v_employee.default_branch_id=p_branch_id,false) OR COALESCE(v_employee.allowed_branch_ids,'[]'::jsonb) ? v_branch_code OR COALESCE(v_employee.allowed_branch_ids,'[]'::jsonb) ? '*') THEN RAISE EXCEPTION 'CUSTODY_EMPLOYEE_BRANCH_FORBIDDEN'; END IF;
 select coalesce(nullif(upper(btrim(a.currency)),''),'EGP') into v_currency from public.app_settings a where a.company_id=p_company_id order by a.created_at,a.id limit 1;
 if v_currency is null then raise exception 'SYSTEM_CURRENCY_NOT_CONFIGURED'; end if;
 select * into v_row from public.buyer_custodies where company_id=p_company_id and operation_id=p_operation_id FOR UPDATE;
 if found then
   SELECT * INTO v_existing_advance FROM public.buyer_custody_advances WHERE company_id=p_company_id AND custody_id=v_row.id AND advance_type='Initial' FOR UPDATE;
   IF NOT FOUND THEN RAISE EXCEPTION 'CUSTODY_OPERATION_ID_CONFLICT'; END IF;
   IF v_row.employee_id IS DISTINCT FROM p_employee_id
      OR v_row.branch_id IS DISTINCT FROM p_branch_id
      OR v_row.purpose IS DISTINCT FROM btrim(p_purpose)
      OR v_row.currency IS DISTINCT FROM v_currency
      OR (p_issued_date IS NOT NULL AND v_row.issued_date IS DISTINCT FROM p_issued_date)
      OR v_row.received_reference IS DISTINCT FROM nullif(btrim(p_received_reference),'')
      OR v_row.notes IS DISTINCT FROM nullif(btrim(p_notes),'')
      OR abs(v_existing_advance.amount-p_amount)>0.005
      OR v_existing_advance.treasury_id IS DISTINCT FROM p_treasury_id
      OR v_existing_advance.currency IS DISTINCT FROM v_currency
      OR (p_issued_date IS NOT NULL AND v_existing_advance.advance_date IS DISTINCT FROM p_issued_date) THEN
     RAISE EXCEPTION 'CUSTODY_OPERATION_ID_CONFLICT';
   END IF;
   RETURN to_jsonb(v_row)||jsonb_build_object('duplicate',true,'advance_id',v_existing_advance.id,'cash_disbursement_status',CASE WHEN v_existing_advance.cash_box_id IS NOT NULL THEN 'PostedAfterAcknowledgement' ELSE 'PendingEmployeeAcknowledgement' END);
 end if;
 SELECT * INTO v_treasury FROM public.treasury t WHERE t.id=p_treasury_id AND t.company_id=p_company_id AND coalesce(t.is_active,true) AND t.branch_id=p_branch_id AND t.type='Cash' AND t.account_code NOT LIKE 'POS-%' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'CUSTODY_TREASURY_BRANCH_MISMATCH'; END IF;
 select id into v_cash_account from public.chart_of_accounts where company_id=p_company_id and account_code='121' and is_active;
 select id into v_custody_account from public.chart_of_accounts where company_id=p_company_id and account_code='127' and is_active;
 if v_cash_account is null or v_custody_account is null then raise exception 'CUSTODY_ACCOUNT_MAPPING_MISSING'; end if;
 insert into public.buyer_custodies(company_id,custody_code,employee_id,branch_id,purpose,currency,issued_amount,issued_date,received_reference,received_at,issued_by,notes,operation_id)
 values(p_company_id,'BC-'||to_char(coalesce(p_issued_date,current_date),'YYYYMMDD')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),
 p_employee_id,p_branch_id,btrim(p_purpose),v_currency,p_amount,coalesce(p_issued_date,current_date),nullif(btrim(p_received_reference),''),NULL,v_actor.id,nullif(btrim(p_notes),''),p_operation_id
 returning * into v_row;
 insert into public.buyer_custody_advances(company_id,custody_id,employee_id,advance_type,amount,currency,advance_date,reference,notes,issued_by,operation_id,treasury_id)
 values(p_company_id,v_row.id,p_employee_id,'Initial',p_amount,v_currency,coalesce(p_issued_date,current_date),nullif(btrim(p_received_reference),''),nullif(btrim(p_notes),''),v_actor.id,p_operation_id||':INITIAL',p_treasury_id)
 returning id into v_advance_id;
 return to_jsonb(v_row)||jsonb_build_object('cash_disbursement_status','PendingEmployeeAcknowledgement','advance_id',v_advance_id);
end;
$function$;


CREATE OR REPLACE FUNCTION public.buyer_custody_acknowledge_atomic(p_company_id uuid, p_custody_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_actor public.users%rowtype; v_employee public.users%rowtype; v_custody public.buyer_custodies%rowtype;
  v_advance public.buyer_custody_advances%rowtype; v_cash_account uuid; v_custody_account uuid;
  v_cash_result jsonb; v_seen_initial boolean:=false; v_treasury public.treasury%rowtype;
BEGIN
  SELECT * INTO v_actor FROM public.users WHERE auth_id=auth.uid() AND company_id=p_company_id AND coalesce(status,'Active')='Active';
  IF NOT FOUND THEN RAISE EXCEPTION 'CUSTODY_AUTH_REQUIRED'; END IF;
  SELECT * INTO v_custody FROM public.buyer_custodies
   WHERE id=p_custody_id AND company_id=p_company_id AND employee_id=v_actor.id AND status='Issued' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'CUSTODY_ACKNOWLEDGE_NOT_ALLOWED'; END IF;
  SELECT * INTO v_employee FROM public.users WHERE id=v_custody.employee_id AND company_id=p_company_id;
  SELECT id INTO v_cash_account FROM public.chart_of_accounts WHERE company_id=p_company_id AND account_code='121' AND is_active;
  SELECT id INTO v_custody_account FROM public.chart_of_accounts WHERE company_id=p_company_id AND account_code='127' AND is_active;
  IF v_cash_account IS NULL OR v_custody_account IS NULL THEN RAISE EXCEPTION 'CUSTODY_ACCOUNT_MAPPING_MISSING'; END IF;

  FOR v_advance IN SELECT * FROM public.buyer_custody_advances
    WHERE custody_id=p_custody_id AND company_id=p_company_id AND advance_type='Initial' FOR UPDATE
  LOOP
    v_seen_initial:=true;
    IF (v_advance.cash_box_id IS NULL) <> (v_advance.journal_entry_id IS NULL) THEN RAISE EXCEPTION 'CUSTODY_ADVANCE_CASH_POSTING_INCONSISTENT'; END IF;
    IF v_advance.cash_box_id IS NULL AND v_advance.journal_entry_id IS NULL THEN
      IF v_custody.branch_id IS NULL OR v_advance.treasury_id IS NULL THEN RAISE EXCEPTION 'CUSTODY_TREASURY_REQUIRED_BEFORE_ACKNOWLEDGEMENT'; END IF;
      SELECT * INTO v_treasury FROM public.treasury t WHERE t.id=v_advance.treasury_id AND t.company_id=p_company_id AND coalesce(t.is_active,true) AND t.branch_id=v_custody.branch_id AND t.type='Cash' AND t.account_code NOT LIKE 'POS-%' FOR UPDATE;
      IF NOT FOUND THEN RAISE EXCEPTION 'CUSTODY_TREASURY_BRANCH_MISMATCH'; END IF;
    END IF;
    IF v_advance.acknowledged_at IS NULL THEN
      UPDATE public.buyer_custody_advances SET acknowledged_at=now(),acknowledged_by=v_actor.id
      WHERE id=v_advance.id AND company_id=p_company_id RETURNING * INTO v_advance;
    ELSIF v_advance.cash_box_id IS NULL THEN
      RAISE EXCEPTION 'CUSTODY_ACKNOWLEDGED_WITHOUT_CASH_POSTING_REQUIRES_RECONCILIATION';
    END IF;
    IF v_advance.cash_box_id IS NULL AND v_advance.journal_entry_id IS NULL THEN
      IF v_advance.treasury_id IS NULL THEN RAISE EXCEPTION 'CUSTODY_TREASURY_REQUIRED_BEFORE_ACKNOWLEDGEMENT'; END IF;
      v_cash_result:=public.post_cash_payment_atomic(
        p_company_id,v_advance.id,v_advance.treasury_id,v_cash_account,v_custody_account,v_advance.amount,
        v_advance.advance_date,coalesce(nullif(btrim(v_advance.reference),''),v_custody.custody_code),
        'تسليم عهدة مشتريات بعد إقرار الموظف بالاستلام',v_actor.email,v_employee.name,
        'BuyerCustodyAdvance',v_custody.id,nullif(btrim(v_advance.notes),''),null
      );
      UPDATE public.buyer_custody_advances SET cash_box_id=nullif(v_cash_result->>'cash_box_id','')::uuid,
        journal_entry_id=nullif(v_cash_result->>'entry_id','')::uuid
      WHERE id=v_advance.id AND company_id=p_company_id;
    END IF;
  END LOOP;
  IF NOT v_seen_initial THEN RAISE EXCEPTION 'CUSTODY_INITIAL_ADVANCE_NOT_FOUND'; END IF;
  UPDATE public.buyer_custodies SET received_at=coalesce(received_at,now()),acknowledged_at=coalesce(acknowledged_at,now()),updated_at=now()
   WHERE id=p_custody_id AND company_id=p_company_id RETURNING * INTO v_custody;
  RETURN to_jsonb(v_custody)||jsonb_build_object('cash_disbursement_status','PostedAfterAcknowledgement');
END;
$function$;


CREATE OR REPLACE FUNCTION public.buyer_custody_add_advance_atomic(p_company_id uuid, p_custody_id uuid, p_treasury_id uuid, p_amount numeric, p_advance_date date, p_reference text, p_notes text, p_operation_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_actor public.users%rowtype; v_custody public.buyer_custodies%rowtype; v_advance public.buyer_custody_advances%rowtype;
 v_cash_account uuid; v_custody_account uuid; v_cash_result jsonb; v_treasury public.treasury%rowtype; v_branch_code text;
begin
 select * into v_actor from public.users where auth_id=auth.uid() and company_id=p_company_id and coalesce(status,'Active')='Active';
 if not found then raise exception 'CUSTODY_AUTH_REQUIRED'; end if;
 if not (app_private.current_user_has_effective_permission('finance') or app_private.current_user_has_effective_permission('finance_manager')) then raise exception 'CUSTODY_FINANCE_PERMISSION_REQUIRED'; end if;
 if p_amount is null or p_amount<=0 or nullif(btrim(p_operation_id),'') is null or p_treasury_id is null then raise exception 'CUSTODY_ADVANCE_INVALID'; end if;
  IF NOT EXISTS (SELECT 1 FROM public.treasury t WHERE t.id=p_treasury_id AND t.company_id=p_company_id AND coalesce(t.is_active,true)) THEN RAISE EXCEPTION 'CUSTODY_TREASURY_INVALID'; END IF;
 select * into v_custody from public.buyer_custodies where id=p_custody_id and company_id=p_company_id for update;
 if not found then raise exception 'CUSTODY_NOT_OPEN'; end if;
 IF v_custody.branch_id IS NULL THEN RAISE EXCEPTION 'CUSTODY_BRANCH_REQUIRED'; END IF;
 SELECT b.branch_code INTO v_branch_code FROM public.branches b WHERE b.id=v_custody.branch_id AND b.company_id=p_company_id AND coalesce(b.is_active,true);
 IF NOT FOUND OR nullif(btrim(v_branch_code),'') IS NULL THEN RAISE EXCEPTION 'CUSTODY_BRANCH_INVALID'; END IF;
 IF NOT (COALESCE(v_actor.default_branch_id=v_custody.branch_id,false) OR COALESCE(v_actor.allowed_branch_ids,'[]'::jsonb) ? v_branch_code OR COALESCE(v_actor.allowed_branch_ids,'[]'::jsonb) ? '*') THEN RAISE EXCEPTION 'CUSTODY_ACTOR_BRANCH_FORBIDDEN'; END IF;
 select * into v_advance from public.buyer_custody_advances where company_id=p_company_id and operation_id=p_operation_id FOR UPDATE;
 if found then
   IF v_advance.custody_id IS DISTINCT FROM p_custody_id OR v_advance.employee_id IS DISTINCT FROM v_custody.employee_id OR v_advance.treasury_id IS DISTINCT FROM p_treasury_id OR abs(v_advance.amount-p_amount)>0.005 OR v_advance.currency IS DISTINCT FROM v_custody.currency OR (p_advance_date IS NOT NULL AND v_advance.advance_date IS DISTINCT FROM p_advance_date) OR v_advance.reference IS DISTINCT FROM nullif(btrim(p_reference),'') OR v_advance.notes IS DISTINCT FROM nullif(btrim(p_notes),'') OR v_advance.advance_type IS DISTINCT FROM 'Additional' THEN
     RAISE EXCEPTION 'CUSTODY_OPERATION_ID_CONFLICT';
   END IF;
   RETURN to_jsonb(v_advance)||jsonb_build_object('duplicate',true);
 end if;
 if v_custody.status not in ('Issued','UnderReview') then raise exception 'CUSTODY_NOT_OPEN'; end if;
 if v_custody.employee_id=v_actor.id then raise exception 'CUSTODY_SELF_ISSUE_FORBIDDEN'; end if;
 SELECT * INTO v_treasury FROM public.treasury t WHERE t.id=p_treasury_id AND t.company_id=p_company_id AND coalesce(t.is_active,true) AND t.branch_id=v_custody.branch_id AND t.type='Cash' AND t.account_code NOT LIKE 'POS-%' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'CUSTODY_TREASURY_BRANCH_MISMATCH'; END IF;
 select id into v_cash_account from public.chart_of_accounts where company_id=p_company_id and account_code='121' and is_active;
 select id into v_custody_account from public.chart_of_accounts where company_id=p_company_id and account_code='127' and is_active;
 if v_cash_account is null or v_custody_account is null then raise exception 'CUSTODY_ACCOUNT_MAPPING_MISSING'; end if;
 insert into public.buyer_custody_advances(company_id,custody_id,employee_id,advance_type,amount,currency,advance_date,reference,notes,issued_by,operation_id,treasury_id)
 values(p_company_id,p_custody_id,v_custody.employee_id,'Additional',p_amount,v_custody.currency,coalesce(p_advance_date,current_date),
 nullif(btrim(p_reference),''),nullif(btrim(p_notes),''),v_actor.id,p_operation_id,p_treasury_id) returning * into v_advance;
 update public.buyer_custodies set issued_amount=issued_amount+p_amount,updated_at=now() where id=p_custody_id and company_id=p_company_id;
 return to_jsonb(v_advance)||jsonb_build_object('cash_disbursement_status','PendingEmployeeAcknowledgement');
end;
$function$;


CREATE OR REPLACE FUNCTION public.buyer_custody_acknowledge_advance_atomic(p_company_id uuid, p_advance_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_actor public.users%rowtype; v_employee public.users%rowtype; v_custody public.buyer_custodies%rowtype;
  v_advance public.buyer_custody_advances%rowtype; v_cash_account uuid; v_custody_account uuid; v_cash_result jsonb; v_treasury public.treasury%rowtype;
BEGIN
  SELECT * INTO v_actor FROM public.users WHERE auth_id=auth.uid() AND company_id=p_company_id AND coalesce(status,'Active')='Active';
  IF NOT FOUND THEN RAISE EXCEPTION 'CUSTODY_AUTH_REQUIRED'; END IF;
  SELECT a.* INTO v_advance FROM public.buyer_custody_advances a
   JOIN public.buyer_custodies c ON c.id=a.custody_id AND c.company_id=a.company_id
   WHERE a.id=p_advance_id AND a.company_id=p_company_id AND a.employee_id=v_actor.id AND a.advance_type='Additional'
   FOR UPDATE OF a;
  IF NOT FOUND THEN RAISE EXCEPTION 'CUSTODY_ADVANCE_ACKNOWLEDGE_NOT_ALLOWED'; END IF;
  SELECT * INTO v_custody FROM public.buyer_custodies
   WHERE id=v_advance.custody_id AND company_id=p_company_id FOR UPDATE;
  IF NOT FOUND OR v_custody.status NOT IN ('Issued','UnderReview') THEN RAISE EXCEPTION 'CUSTODY_NOT_OPEN'; END IF;
  SELECT * INTO v_employee FROM public.users WHERE id=v_advance.employee_id AND company_id=p_company_id;
  SELECT id INTO v_cash_account FROM public.chart_of_accounts WHERE company_id=p_company_id AND account_code='121' AND is_active;
  SELECT id INTO v_custody_account FROM public.chart_of_accounts WHERE company_id=p_company_id AND account_code='127' AND is_active;
  IF v_cash_account IS NULL OR v_custody_account IS NULL THEN RAISE EXCEPTION 'CUSTODY_ACCOUNT_MAPPING_MISSING'; END IF;
  IF (v_advance.cash_box_id IS NULL) <> (v_advance.journal_entry_id IS NULL) THEN RAISE EXCEPTION 'CUSTODY_ADVANCE_CASH_POSTING_INCONSISTENT'; END IF;
  IF v_advance.cash_box_id IS NULL AND v_advance.journal_entry_id IS NULL THEN
    IF v_custody.branch_id IS NULL OR v_advance.treasury_id IS NULL THEN RAISE EXCEPTION 'CUSTODY_TREASURY_REQUIRED_BEFORE_ACKNOWLEDGEMENT'; END IF;
    SELECT * INTO v_treasury FROM public.treasury t WHERE t.id=v_advance.treasury_id AND t.company_id=p_company_id AND coalesce(t.is_active,true) AND t.branch_id=v_custody.branch_id AND t.type='Cash' AND t.account_code NOT LIKE 'POS-%' FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'CUSTODY_TREASURY_BRANCH_MISMATCH'; END IF;
  END IF;
  IF v_advance.acknowledged_at IS NULL THEN
    UPDATE public.buyer_custody_advances SET acknowledged_at=now(),acknowledged_by=v_actor.id
     WHERE id=v_advance.id AND company_id=p_company_id RETURNING * INTO v_advance;
  ELSIF v_advance.cash_box_id IS NULL THEN
    RAISE EXCEPTION 'CUSTODY_ACKNOWLEDGED_WITHOUT_CASH_POSTING_REQUIRES_RECONCILIATION';
  END IF;
  IF v_advance.cash_box_id IS NULL AND v_advance.journal_entry_id IS NULL THEN
    IF v_advance.treasury_id IS NULL THEN RAISE EXCEPTION 'CUSTODY_TREASURY_REQUIRED_BEFORE_ACKNOWLEDGEMENT'; END IF;
    v_cash_result:=public.post_cash_payment_atomic(
      p_company_id,v_advance.id,v_advance.treasury_id,v_cash_account,v_custody_account,v_advance.amount,
      v_advance.advance_date,coalesce(nullif(btrim(v_advance.reference),''),v_custody.custody_code),
      'زيادة عهدة مشتريات بعد إقرار الموظف بالاستلام',v_actor.email,v_employee.name,
      'BuyerCustodyAdvance',v_custody.id,nullif(btrim(v_advance.notes),''),null
    );
    UPDATE public.buyer_custody_advances SET cash_box_id=nullif(v_cash_result->>'cash_box_id','')::uuid,
      journal_entry_id=nullif(v_cash_result->>'entry_id','')::uuid
     WHERE id=v_advance.id AND company_id=p_company_id RETURNING * INTO v_advance;
  END IF;
  RETURN to_jsonb(v_advance)||jsonb_build_object('cash_disbursement_status','PostedAfterAcknowledgement');
END;
$function$;


CREATE OR REPLACE FUNCTION public.buyer_custody_settle_atomic(p_company_id uuid, p_custody_id uuid, p_treasury_id uuid, p_cash_returned numeric, p_finance_reference text, p_notes text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_custody public.buyer_custodies%ROWTYPE;
  v_employee public.users%ROWTYPE;
  v_approved numeric(14,2);
  v_pending integer;
  v_expected_return numeric(14,2);
  v_unacknowledged integer;
  v_open_qmp integer;
  v_settlement public.buyer_custody_settlements%ROWTYPE;
  v_cash_account uuid;
  v_custody_account uuid;
  v_cash_result jsonb;
  v_treasury public.treasury%ROWTYPE;
  v_branch_code text;
BEGIN
  SELECT * INTO v_actor
  FROM public.users
  WHERE auth_id=auth.uid() AND company_id=p_company_id AND COALESCE(status,'Active')='Active';
  IF NOT FOUND THEN RAISE EXCEPTION 'CUSTODY_AUTH_REQUIRED'; END IF;
  IF NOT (
    app_private.current_user_has_effective_permission('finance')
    OR app_private.current_user_has_effective_permission('finance_manager')
  ) THEN RAISE EXCEPTION 'CUSTODY_FINANCE_PERMISSION_REQUIRED'; END IF;
  SELECT * INTO v_custody
  FROM public.buyer_custodies
  WHERE id=p_custody_id AND company_id=p_company_id
  FOR UPDATE;
  IF NOT FOUND OR v_custody.status NOT IN ('Issued','UnderReview') THEN RAISE EXCEPTION 'CUSTODY_NOT_SETTLEABLE'; END IF;
  IF v_custody.employee_id=v_actor.id THEN RAISE EXCEPTION 'CUSTODY_SELF_SETTLEMENT_FORBIDDEN'; END IF;
  IF v_custody.branch_id IS NULL THEN RAISE EXCEPTION 'CUSTODY_BRANCH_REQUIRED'; END IF;
  SELECT b.branch_code INTO v_branch_code FROM public.branches b WHERE b.id=v_custody.branch_id AND b.company_id=p_company_id AND coalesce(b.is_active,true);
  IF NOT FOUND OR nullif(btrim(v_branch_code),'') IS NULL THEN RAISE EXCEPTION 'CUSTODY_BRANCH_INVALID'; END IF;
  IF NOT (COALESCE(v_actor.default_branch_id=v_custody.branch_id,false) OR COALESCE(v_actor.allowed_branch_ids,'[]'::jsonb) ? v_branch_code OR COALESCE(v_actor.allowed_branch_ids,'[]'::jsonb) ? '*') THEN RAISE EXCEPTION 'CUSTODY_ACTOR_BRANCH_FORBIDDEN'; END IF;
  SELECT * INTO v_employee FROM public.users WHERE id=v_custody.employee_id AND company_id=p_company_id;

  SELECT count(*) INTO v_pending
  FROM public.buyer_custody_expenses
  WHERE custody_id=p_custody_id AND company_id=p_company_id AND status='Submitted';
  IF v_pending>0 THEN RAISE EXCEPTION 'CUSTODY_EXPENSES_PENDING_REVIEW'; END IF;

  SELECT count(*) INTO v_unacknowledged
  FROM public.buyer_custody_advances
  WHERE custody_id=p_custody_id AND company_id=p_company_id AND acknowledged_at IS NULL;
  IF v_unacknowledged>0 THEN RAISE EXCEPTION 'CUSTODY_ADVANCES_NOT_ACKNOWLEDGED'; END IF;

  SELECT count(*) INTO v_open_qmp
  FROM public.purchase_invoices
  WHERE company_id=p_company_id AND cash_custody_id=p_custody_id
    AND purchase_source='QUICK_MARKET' AND settlement_source='EMPLOYEE_CUSTODY'
    AND status IN ('Draft','Posted','PartiallyPaid')
    AND settlement_status IN ('UNSETTLED','PENDING_FINANCE','AP_OPEN','PARTIALLY_SETTLED');
  IF v_open_qmp>0 THEN RAISE EXCEPTION 'CUSTODY_QUICK_MARKET_RESERVATIONS_OPEN:%',v_open_qmp; END IF;

  SELECT COALESCE(SUM(amount),0) INTO v_approved
  FROM public.buyer_custody_expenses
  WHERE custody_id=p_custody_id AND company_id=p_company_id AND status='Approved';

  IF v_approved>v_custody.issued_amount+0.005 THEN
    RAISE EXCEPTION 'CUSTODY_APPROVED_EXPENSES_EXCEED_ISSUED_FUNDS_EMPLOYEE_PAYABLE_NOT_CONFIGURED';
  END IF;
  v_expected_return:=greatest(v_custody.issued_amount-v_approved,0);
  IF COALESCE(p_cash_returned,0)<>v_expected_return THEN RAISE EXCEPTION 'CUSTODY_CASH_RETURN_MUST_RECONCILE'; END IF;

  IF p_treasury_id IS NOT NULL THEN
    SELECT * INTO v_treasury FROM public.treasury t WHERE t.id=p_treasury_id AND t.company_id=p_company_id AND coalesce(t.is_active,true) AND t.branch_id=v_custody.branch_id AND t.type='Cash' AND t.account_code NOT LIKE 'POS-%' FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'CUSTODY_TREASURY_BRANCH_MISMATCH'; END IF;
  END IF;
  IF v_expected_return>0 THEN
    IF p_treasury_id IS NULL THEN RAISE EXCEPTION 'CUSTODY_RETURN_TREASURY_REQUIRED'; END IF;
    SELECT id INTO v_cash_account FROM public.chart_of_accounts
    WHERE company_id=p_company_id AND account_code='121' AND is_active;
    SELECT id INTO v_custody_account FROM public.chart_of_accounts
    WHERE company_id=p_company_id AND account_code='127' AND is_active;
    IF v_cash_account IS NULL OR v_custody_account IS NULL THEN RAISE EXCEPTION 'CUSTODY_ACCOUNT_MAPPING_MISSING'; END IF;
    v_cash_result:=public.post_cash_receipt_atomic(
      p_company_id,gen_random_uuid(),p_treasury_id,v_cash_account,v_custody_account,v_expected_return,
      current_date,COALESCE(NULLIF(btrim(p_finance_reference),''),v_custody.custody_code),
      'رد نقدية متبقية من عهدة مشتريات',v_actor.email,v_employee.name,'BuyerCustodySettlement',
      v_custody.id,NULLIF(btrim(p_notes),''),NULL
    );
  END IF;

  INSERT INTO public.buyer_custody_settlements(
    company_id,custody_id,approved_expense_total,cash_returned,amount_due_employee,balance_due_company,
    finance_reference,notes,recorded_by,treasury_id,cash_box_id,journal_entry_id
  )
  VALUES(
    p_company_id,p_custody_id,v_approved,v_expected_return,0,0,
    NULLIF(btrim(p_finance_reference),''),NULLIF(btrim(p_notes),''),v_actor.id,p_treasury_id,
    NULLIF(v_cash_result->>'cash_box_id','')::uuid,NULLIF(v_cash_result->>'entry_id','')::uuid
  )
  RETURNING * INTO v_settlement;

  UPDATE public.buyer_custodies SET status='Settled',updated_at=now()
  WHERE id=p_custody_id AND company_id=p_company_id;

  RETURN to_jsonb(v_settlement);
END;
$function$;


COMMIT;
~~~

### مراجعة قبل اعتماد التنفيذ

1. لم تُختبر النصوص بعد. الاختبار التالي يكون مباشرة على SMART ERP Production داخل BEGIN/ROLLBACK حيث يمكن ذلك، أو ببيانات QA اصطناعية مؤقتة بعلامة فريدة عند الحاجة إلى Browser E2E.
2. قبل الاختبار، احفظ function signatures والـowner/ACL/search_path والـcounts/balances كـbaseline؛ وبعد الاختبار تحقق من مطابقتها أو من cleanup الكامل. لا تنشئ Staging أو فرعًا بديلًا.
3. يلزم تعديل Buyer UI ليجعل branch_id إلزاميًا ويصفّي Treasury حسب الفرع، وإلا ستظهر أخطاء رفض صحيحة من الخادم.
4. يلزم تفعيل خزينة Cash فعلية لفرع الإسكندرية BR-2 وتمويل خزائن الفروع من خلال تحويلات حقيقية موثقة قبل إطلاق الصرف.
5. لا تُفعّل أي صلاحية مركزية للخزينة CASH-01 ضمن هذه الحزمة.

