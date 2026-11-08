# Report660 — سبب اختفاء مديونية الموظف من سلف الموارد البشرية وChangeSet التكامل المالي

**التاريخ:** 9 نوفمبر 2026  
**Checkpoint السابق:** LVE-2026-11-08-659  
**الحالة:** ROOT CAUSE CONFIRMED — OWNER FILE / RPC CHANGE REQUIRED  
**النطاق:** HR Advances + Employee Financial Subledger + Buyer Operational Custody  
**البيئة:** SMART ERP Production `fiilmooggumokxanwiyx`، ومستودع التشغيل `papamohammed77-glitch/erp-frontend`، الفرع `main`.

---

## 1. ملخص القرار

المديونية لا تختفي من قاعدة البيانات ولا من الحسابات. السبب هو **انفصال عقد تقرير الموارد البشرية عن دفتر الأستاذ الفرعي المركزي للموظف**:

- تبويب HR » السلف يستدعي `hr_query('advances')`.
- هذا الفرع في RPC يقرأ `hr_salary_advances` فقط ويعيد `rows` فقط.
- العهد التشغيلية التي ينشئها Buyer تُسجل في `buyer_custodies` ومستنداتها، ويظهر أثرها المالي الفعلي في `journal_lines` الموسومة بالطرف Employee.
- المصدر المالي الموحد هو `v_employee_financial_balances` المشتق من `v_employee_financial_ledger`.
- شاشة Finance » Employee Financial 360 تقرأ هذه الـViews، لكن وحدة HR لا تستدعيها في تقرير السلف ولا في ملف الموظف Employee 360.

**الإثبات الحي في Production:** تحت سياق مستخدم HR موجود فعليًا، أعاد `hr_query('advances')` قائمة فارغة (`rows=[])، بينما أعادت `v_employee_financial_balances` صفًا واحدًا بدين مدين قدره **5,000.00 EGP** على موظف المشتريات، تحت الحساب 127 «عهد الموظفين» وطبيعة `OPERATIONAL_CUSTODY`.

لذلك فالخلل ليس نقص حساب 127، ولا فقدان قيد، ولا خطأ احتساب في الدفتر. الخلل في **مستهلك HR الذي لا يقرأ دفتر الموظف المالي**، ويضاف إليه قصور في Realtime لأن قناة HR الحالية لا تستمع إلى مصادر تغيّر الدفتر المالي.

لم يتم تعديل `main.html` أو RPC أو بيانات Production خلال هذا التحقيق. أُعد ChangeSet محدد وفق بوابة موافقة المالك في الدستور.

## 2. استعادة نقطة الاستئناف والمراجع

### LAST VERIFIED EVENT

- `CURRENT_STATE.md` يبدأ بـ `LVE-2026-11-08-659`، ثم LVE658 وLVE657 وLVE656.
- SHA الحالي لملف الحالة قبل هذا التقرير: `9920742ea519ddcbdec5b16963b0e9ef274e3844`، وحجمه في GitHub 994,590 bytes.
- الدستور التشغيلي الدائم: `3a6b1e220af8509e314e94df76563bbc6f84910d`.
- ملف `writing-block-8-10.md` تمت قراءته كاملًا، وكذلك الدستور التشغيلي الدائم كاملًا.
- تمت مراجعة Report658 كاملًا وReport659 كاملًا. تقريرا 657/658 يثبتان أن المعمارية المركزية قائمة، وأن Employee Financial 360 والدفاتر الفرعية ليست فكرة جديدة ينبغي إعادة بنائها.
- نقطة LVE659 ما زالت أحدث نقطة حالة مسجلة قبل Report660؛ لم يظهر Commit تشغيلي أحدث يمس HR.

### GitHub الحالي

- Operational HEAD: `940ae61a00c9b6bb3d14544510328afdbadcd2bf`.
- آخر تغيير تشغيلي في هذا HEAD هو بناء CSS لـBuyer بعد Commit `314fab568f4aa8be8caa7d49c03473add3f906e2`.
- ملف Parent `companies/company-1/main.html` الحالي على `main` ما زال Blob SHA `c11e749c0d3620609e219ca3eea6e37bd9fff104`، مطابقًا للمصدر الذي استُخرج منه مقطع HR الحالي.
- ملف الاستخراج الجنائي `_forensic_current_main_extract.md` SHA `46789fc548d88cd14f5f133b8bed6fafbe8a5bbb` يوثق أن المصدر المستخرج طوله 34,009 سطرًا و1,987,341 byte، وبصمة المصدر SHA-256 `04b86e00c77827c36532d6e9bde1ad38e30028f3daaf2642e9b7c753140785ac`.

### Supabase

- المشروع `SMART ERP` / `fiilmooggumokxanwiyx` حالته `ACTIVE_HEALTHY`.
- لا يوجد تغيير على المخطط أو السجلات أو الصلاحيات في هذه المهمة.
- لا توجد حاجة لإنشاء جدول أو View أو حساب GL جديد؛ العقود الحالية تكفي لإظهار المديونية.

## 3. السبب الجذري — دليل الكود

### 3.1 RPC الحالي

تعريف `public.hr_query(text,jsonb)` الحالي:

- `SECURITY DEFINER`.
- `v_company := app_private.current_user_company_id()`.
- `v_hr := app_private.current_user_has_permission('hr')`.
- يحدد هوية الموظف الحالية من `users.auth_id = auth.uid()`.

فرع `p_view='advances'` الحالي، كما استُخرج من Production:

```sql
ELSIF p_view='advances' THEN
  IF NOT v_hr AND ((p_payload->>'employee_id') IS NULL OR (p_payload->>'employee_id')::uuid<>v_employee_uid) THEN
    RETURN jsonb_build_object('success',false,'code','ADVANCE_SCOPE');
  END IF;
  SELECT coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) INTO v_rows FROM (
    SELECT a.*,u.name employee_name
    FROM hr_salary_advances a
    JOIN users u ON u.id=a.employee_id AND u.company_id=v_company
    WHERE a.company_id=v_company
      AND (v_hr OR a.employee_id=v_employee_uid)
    ORDER BY a.created_at DESC
    LIMIT 100
  ) x;
  RETURN jsonb_build_object('success',true,'rows',v_rows);
```

**النتيجة:** لا يوجد في هذا الفرع أي استعلام إلى `v_employee_financial_balances` أو `v_employee_financial_ledger` أو `buyer_custodies`. وبالتالي فإن العهد التشغيلية والذمم الناتجة عن المستندات المركزية لا يمكن أن تظهر في هذه الاستجابة مهما كانت أرصدتها صحيحة في الأستاذ.

### 3.2 Parent HR UI

المصدر الحالي `companies/company-1/main.html`:

- `RW_HR.advancesTab(cn)` عند السطر 32032 يستدعي `q('advances')` ثم يبني الجدول من `d.rows` فقط.
- `RW_HR.open360(id)` عند السطر 32047 يستدعي `q('advances',{employee_id:id}))، ثم يعرض `av` الناتجة عن `z[7].rows` في بطاقة «السلف».
- لا يطلب Employee Financial 360 أو دفتر الأستاذ الفرعي عند فتح بطاقة الموظف.
- `RW_HR.realtime()` عند السطر 32072 يشترك في `hr_salary_advances`، لكنه لا يشترك في `journal_lines` أو `cash_box` أو `buyer_custodies`. لذلك لن ينعكس تغيّر العهدة التشغيلية في تقرير HR تلقائيًا حتى بعد إضافة قراءة المديونية ما لم يُستكمل الاشتراك.

### 3.3 المرجع المالي الموجود بالفعل

- `v_employee_financial_ledger` يقرأ القيود المرحلة فقط (`journal_entries.status='Posted'`) التي تحمل `party_type='Employee'`، ويستخرج `employee_id` من `journal_lines.party_id` و`party_nature` من سطر القيد.
- `v_employee_financial_balances` يجمع المدين والدائن والرصيد بحسب الشركة والموظف وطبيعة الذمة والحساب.
- الـViews من نوع `security_invoker=true`، وممنوحة لـauthenticated، وغير ممنوحة لـanon. شرط الرؤية يسمح لصلاحيات Finance/Finance Manager/HR أو الموظف نفسه، مع نطاق الشركة.
- معنى الرصيد: `debit - credit`. الرصيد الموجب مدين على الموظف؛ والرصيد السالب دائن ومستحق للموظف. يجب عدم مقاصة النوعين لإظهار «صافي» مضلل.

## 4. إثبات السبب من Production — قراءة فقط

### 4.1 سياق HR

الموظف الموجود فعلًا في جدول `users` بصلاحية HR:

- `users.id = 67552c18-144e-453f-b0e8-5b7730b929d6`.
- الدور: `موظف الموارد البشرية`.
- الحالة: `Active`.
- تم ضبط `request.jwt.claim.sub` داخل استعلام قراءة فقط إلى `auth_id` الخاص بهذا المستخدم؛ وأعاد النظام `current_user_company_id` للشركة الصحيحة، و`current_user_has_permission('hr') = true` و`current_user_has_effective_permission('hr') = true`.

هذا اختبار سياق SQL محاكى بهوية موجودة، وليس ادعاءً بأن جلسة Browser مصادق عليها قد اختُبرت.

### 4.2 نتيجة المقارنة في نفس سياق HR

نتيجة استدعاء `hr_query('advances','{}')`:

```json
{"success":true,"rows":[]}
```

وعدد مستندات `hr_salary_advances` للشركة = **0**.

وفي نفس سياق HR، نتيجة `v_employee_financial_balances`:

```json
{
  "employee_id": "7d0f21ed-8952-45c1-b00f-e58c61607d56",
  "party_nature": "OPERATIONAL_CUSTODY",
  "account_code": "127",
  "account_name": "عهد الموظفين",
  "total_debit": 5000.00,
  "total_credit": 0.00,
  "outstanding_balance": 5000.00
}
```

إجمالي المبالغ المدينة على الموظفين في هذا الاستعلام = **5,000.00 EGP**، وإجمالي الأرصدة الدائنة لهم = **0.00 EGP**.

### 4.3 المستند التشغيلي المقابل

السجل الحالي في `buyer_custodies`:

- `custody_code = BC-20261108-28F7B364`.
- `employee_id = 7d0f21ed-8952-45c1-b00f-e58c61607d56`.
- الغرض: مشتريات مباشرة.
- `issued_amount = 5,000.00`.
- `paid_amount = 5,000.00`.
- `returned_amount = 0.00`.
- `acknowledged_at` موجود.
- `status = Issued`، أي أن سجل العهدة ما زال مفتوحًا وفق حالته الحالية.

الربط المالي يستخدم `users.id` نفسه باعتباره Employee Party ID؛ وحقل `users.employee_id` النصي ليس مفتاح هذه العلاقة ولا يجوز استخدامه بدلًا منه.

**الاستنتاج:** الموظف لديه عهدة نقدية تشغيلية مسلمة ومثبتة ماليًا بالكامل، ولم يرد منها شيء حتى لقطة الفحص. لا توجد سلفة HR منفصلة في `hr_salary_advances` لهذا الموظف. لهذا لا تظهر المديونية في تقرير HR الحالي.

### 4.4 Realtime

الجداول التالية موجودة حاليًا في `supabase_realtime` publication:

- `buyer_custodies`
- `buyer_custody_advances`
- `cash_box`
- `journal_entries`
- `journal_lines`
- `hr_salary_advances`

أما `buyer_custody_returns` و`hr_salary_advance_repayments` فليسا في القائمة الحالية. لا نحتاج إضافتهما حتمًا إذا كان التحديث المالي المنشور يطلق الحدث على `journal_lines` و`cash_box`، لكن يجب اختبار ذلك بعد التغيير. لا تجرِ تعديل Publication أو RLS دون دليل واختبار مستقل.

## 5. التصميم الأقل مخاطرة

لا ننشئ «مديونية HR» موازية ولا نحسب العهد من `buyer_custodies` إلى جانب الأستاذ العام؛ لأن ذلك قد يكرر الدين. مصدر القيمة المعتمدة في التقرير هو **الرصيد المرحّل** في `v_employee_financial_balances`، مع إظهار المستند المصدر كمرجع تفصيلي.

يُفصل التقرير إلى مجموعتين واضحتين:

1. **المديونية المرحلة على الموظف:** مجموع الأرصدة الموجبة بحسب الموظف وطبيعة الذمة والحساب، من الدفتر الفرعي. وتشمل العهد التشغيلية (127)، والسلف المؤقتة (128)، وسلف الرواتب (129)، وقروض الموظفين (130)، وأي طبيعة مدينة أخرى تظهر في الدفتر.
2. **مستحقات الموظف لدى الشركة:** مجموع القيم السالبة منفصلة، مثل مستحقات وتعويضات الموظف (212). لا تخصم من مديونيته لإخفاء ما عليه أو ما له.

طلبات السلف غير المصروفة أو غير المرحلة تبقى في جدول HR الحالي كطلبات وحالات، ولا تُضاف إلى مديونية الموظف قبل إثبات Payment الفعلي. الاستقطاعات من الرواتب تخفض الذمة وفق قيد Payroll المعتمد، وليست Receipt نقديًا.

## 6. ChangeSet — جاهز للمراجعة، غير مطبق

### CS-660-A — Supabase RPC: إكمال عقد HR advances

**المستودع/Production:** `fiilmooggumokxanwiyx`  
**المكوّن:** `public.hr_query(text,jsonb)`  
**الموضع:** فرع `p_view='advances'` فقط.  
**التعديل المقترح:** الإبقاء على `rows` الحالي كما هو، وتوسيع كائن الاستجابة بإضافة `financial_balances` من View الدفتر المالي. عند تمرير `employee_id` من Employee 360، يُعاد أيضًا `financial_ledger` لهذا الموظف بحد أقصى 200 حركة مرتبة بالأحدث.

البديل المقترح لسطر الإرجاع الحالي:

```sql
RETURN jsonb_build_object(
  'success', true,
  'rows', v_rows,
  'financial_balances', (
    SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.employee_name,x.party_nature,x.account_code),'[]'::jsonb)
    FROM (
      SELECT b.*,u.name employee_name,u.email,u.status employee_status
      FROM public.v_employee_financial_balances b
      JOIN public.users u ON u.id=b.employee_id AND u.company_id=v_company
      WHERE b.company_id=v_company
        AND (v_hr OR b.employee_id=v_employee_uid)
        AND (NULLIF(p_payload->>'employee_id','') IS NULL
             OR b.employee_id=(p_payload->>'employee_id')::uuid)
    ) x
  ),
  'financial_ledger', CASE
    WHEN NULLIF(p_payload->>'employee_id','') IS NULL THEN '[]'::jsonb
    ELSE (
      SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.entry_date DESC,x.entry_code DESC),'[]'::jsonb)
      FROM (
        SELECT l.*
        FROM public.v_employee_financial_ledger l
        WHERE l.company_id=v_company
          AND (v_hr OR l.employee_id=v_employee_uid)
          AND l.employee_id=(p_payload->>'employee_id')::uuid
        ORDER BY l.entry_date DESC,l.entry_code DESC
        LIMIT 200
      ) x
    )
  END
);
```

**حدود التغيير:** لا يغير هذا الاقتراح قيمة أي رصيد، ولا ينشئ قيودًا، ولا يضيف حسابًا أو View أو جدولًا. يستعمل نفس company/user scope الموجود في RPC والـViews. يجب مراجعة تعريف Production مرة أخرى مباشرة قبل تطبيقه، واختبار فرع الموظف الذاتي وفرع HR.

### CS-660-B — Parent HR: إظهار الذمم في تبويب السلف

**الملف:** `companies/company-1/main.html`  
**Blob الحالي:** `c11e749c0d3620609e219ca3eea6e37bd9fff104`  
**الموضع:** `RW_HR.advancesTab(cn)` قرب السطر 32032.

الإضافة المقترحة بعد استلام `d`:

- قراءة `d.financial_balances || []`.
- إظهار بطاقة/جدول مستقل بعنوان «المديونيات المرحلة على الموظفين».
- أعمدة: الموظف، حالة الموظف، طبيعة الذمة، حساب المراقبة، إجمالي المدين، إجمالي الدائن، الرصيد واتجاهه.
- مؤشرات منفصلة: «إجمالي المديونية على الموظفين» = مجموع `greatest(outstanding_balance,0))، و«مستحقات الموظفين» = مجموع `abs(least(outstanding_balance,0))`.
- لا تستخدم `hr_salary_advances.remaining_balance` بديلًا عن دفتر الأستاذ، ولا تجمع الطلبات غير المصروفة مع الدين المرحّل.
- حافظ على جدول طلبات السلف الحالي وإجراءاته كما هي؛ يضاف جدول المديونية ولا يستبدلها.

### CS-660-C — Parent Employee 360: عرض تفاصيل الموظف

**الموضع:** `RW_HR.open360(id)` قرب السطر 32047.

الاستدعاء الحالي `q('advances',{employee_id:id})` سيعيد البيانات الإضافية من CS-660-A دون إنشاء طلب RPC جديد. يُضاف إلى ملف الموظف:

- الرصيد بحسب كل `party_nature` والحساب.
- إجمالي المدين وإجمالي الدائن كل على حدة.
- آخر الحركات المالية المرتبطة بالموظف من `financial_ledger` (200 كحد أعلى)، مع التاريخ ورقم القيد والحساب والمدين والدائن والمرجع.
- بيان واضح أن الرصيد الموجب على الموظف، والسالب مستحق له.

### CS-660-D — Realtime HR

**الموضع:** `RW_HR.realtime()` قرب السطر 32072.

الاشتراكات المقترحة، بعد التأكد من أن Publication والـRLS الحاليين كما ثبتا:

- `journal_lines` مع filter `party_type=eq.Employee`؛ وهو مصدر تغيّر الدفتر المرحّل.
- `cash_box` مع filter `party_type=eq.Employee`؛ لتحديث ربط السندات النقدية.
- `buyer_custodies` مع filter الشركة الحالية؛ لتحديث حالة العهدة التشغيلية.
- الإبقاء على اشتراك `hr_salary_advances` الحالي.

يعاد استعمال مؤقت `H.timer` و`render()` الحاليين لمنع تكرار التحديثات. لا تضف اشتراكًا غير مفلتر على كل القيود في الشركة. إذا لم يثبت وصول أحداث Journal Lines/Cash Box للمستخدم HR في الاختبار، يُسجل ذلك كفجوة منفصلة ولا يُوسّع Realtime أو RLS تلقائيًا.

## 7. قواعد العرض والتسوية والاستقالة

- الدين النقدي على الموظف يساوي الرصيد المدين المرحّل بحسب الطرف والنوع، وليس مجموع طلبات السلف.
- لا يُخصم أي مبلغ من مستحقات نهاية الخدمة أو الراتب تلقائيًا من هذا التقرير.
- لا يُغلق سجل العهدة لأن الموظف بدأ طلب استقالة؛ الإغلاق المالي يحتاج مستند Receipt أو تسوية/قيد معتمد وفق طبيعة الحركة.
- العهد المادية/البضائع/الأصول والمهمات المسلمة للموظف يجب أن تبقى في قائمة إخلاء طرف غير نقدية منفصلة، ولا تحول قيمتها إلى ذمم مالية دون مستند اعتماد.
- مرحلة لاحقة مطلوبة: «مخالصة/إخلاء طرف نهاية الخدمة» تربط الحالة الوظيفية بموافقة HR والمالية والمخازن/الأصول ومركبات/عهد الميدان. لا تُنفذ ضمن إصلاح التقرير الحالي ولا تمنع الاستقالة برقم مالي غير موثق.

## 8. اختبارات القبول المطلوبة بعد الموافقة

| الاختبار | معيار النجاح |
|---|---|
| HR reads advances | تستمر قائمة مستندات HR الحالية دون تغيير |
| HR financial summary | يظهر 5,000 EGP للموظف الحالي تحت OPERATIONAL_CUSTODY/127 |
| Nature split | تظهر 128/129/130 بحسب بياناتها المرحلة، كل نوع مستقل |
| Employee payable | يظهر 212 منفصلًا كرصيد دائن، ولا يخفض المديونية المدينة |
| Unpaid request | طلب سلفة معتمد غير مصروف لا يظهر كمديونية مرحلة |
| Posted Payment | يزيد الرصيد المدين مرة واحدة عند الصرف الفعلي |
| Receipt partial | يخفض الرصيد المدين بمبلغ القبض الفعلي فقط |
| Payroll deduction | يخفض الرصيد بالقيد المعتمد دون إنشاء Receipt نقدي |
| Cross-employee scope | موظف لا يرى إلا بياناته؛ HR يرى الشركة وفق صلاحية HR |
| Cross-company scope | لا تظهر أي بيانات لشركة أخرى |
| Employee 360 | يعرض الأرصدة والحركات لنفس employee_id |
| Realtime | تتحدث البطاقة بعد حركة Employee المنشورة دون إعادة تحميل يدوي |
| Inactive employee | لا تختفي المديونية التاريخية لمجرد تعطيل المستخدم |
| No side effects | لا يتغير Cash Box أو Treasury أو GL أو Stock من القراءة فقط |

## 9. الاختبارات التي نُفذت فعلًا

**CONFIRMED**

1. قراءة كاملة لتعريف `hr_query` واستخراج فرع `advances` الحالي.
2. قراءة تعريف `v_employee_financial_ledger` و`v_employee_financial_balances` و`v_finance_employee_directory`.
3. التحقق من grants: authenticated لديه SELECT وanon لا يملك SELECT على الـViews، وauthenticated يستطيع تنفيذ `hr_query`.
4. تحقق سياق HR عبر `auth.uid()` محاكى بمستخدم HR موجود: direct HR permission وeffective HR permission = true.
5. استدعاء `hr_query('advances')` تحت هذا السياق: `rows=[]`.
6. استدعاء `v_employee_financial_balances` في السياق نفسه: صف واحد بقيمة 5,000 EGP.
7. فحص مستند `buyer_custodies` المقابل: 5,000 مدفوعة، صفر مرتجع، عهدة مفتوحة.
8. فحص Realtime Publication للجداول ذات الصلة.
9. فحص GitHub HEAD وBlob الحالي لملف Parent.

**ما لم يُنفذ:** لم يُطبق أي ChangeSet، ولم تُنشأ Fixtures، ولم تُستدعَ عمليات Payment/Receipt، ولم يحدث DML/DDL، ولم تُختبر واجهة HR بحساب مصادق عليه في Browser. لا يوجد ادعاء بأن إصلاح UI أو E2E قد اكتمل.

## 10. حدود التحقق والمخاطر

- صفحة Cloudflare الحالية `https://rawaea-erp.pages.dev/companies/company-1/main` فُتحت في Browser، لكنها تعرض شاشة تسجيل الدخول ولا توجد جلسة HR مصادق عليها. لذلك DOM التبويب والتفاعل الفعلي وConsole/Network في HR = **UNVERIFIED**.
- لا نملك دليل نشر يربط Build Cloudflare الحالي بواجهة HR بعد تغيير غير مطبق؛ فلا يوجد تغيير نشر أصلًا في هذه المهمة.
- Browser منع قراءة محادثة ChatGPT سابقة بعنوان «إصلاح مديونية الموظفين» بسبب سياسة النطاق؛ لم تتم محاولة تجاوز هذا المنع. لم يمنع ذلك استعادة نقطة LVE659 من مستودعات المشروع.
- مصدر الدفتر يعتمد على القيود Posted والموسومة بـEmployee Party. أي قيد قديم لا يحمل party_type/party_id أو لم يمر بالمزامنة المركزية لن يظهر؛ لا تُصلحه جماعيًا قبل تدقيق منفصل لسجلات orphan.
- `hr_query employees` يستبعد المستخدمين Inactive؛ لذلك يجب اختبار عرض الأرصدة التاريخية لموظف معطل، وعدم جعل ظهور المديونية تابعًا لقائمة الموظفين النشطين.

## 11. حالة الأعمال

| المجال | الحكم |
|---|---|
| سبب عدم ظهور المديونية في HR | CONFIRMED |
| مبلغ المديونية الموجود في اللقطة | 5,000 EGP CONFIRMED |
| وجود المديونية في دفتر الأستاذ المرحّل | CONFIRMED تحت سياق HR المحاكى |
| خلل عقد HR RPC | CONFIRMED |
| خلل استهلاك HR UI | CONFIRMED من المصدر الحالي |
| قصور Realtime HR | CONFIRMED من قائمة الاشتراكات الحالية |
| تعديل Source/Production | NOT EXECUTED — يحتاج اعتماد ChangeSet |
| Browser HR E2E | UNVERIFIED |
| جاهزية الخطوة التالية | READY WITH LIMITATIONS |

## 12. القرار التنفيذي ونقطة الاستئناف التالية

**السبب الجذري محسوم.** لا تعِد فتح تحقيق في سبب اختفاء الرصيد ما لم يتغير المصدر أو المخطط؛ انتقل إلى ChangeSet CS-660-A إلى CS-660-D.

بموجب الدستور §6.2 و§7 و§9 و§10، يتطلب التطبيق:

1. موافقة المالك الصريحة على بديل RPC في CS-660-A قبل أي تعديل في SMART ERP.
2. تطبيق المالك تغييرات Parent في `main.html` من CS-660-B/C/D؛ هذا الملف تشغيلي ومالك النظام هو من يطبق التعديل.
3. بعد التطبيق، إعادة استخراج المصدر وRPC، ثم تنفيذ اختبار القراءة تحت مستخدم HR وموظف ذاتي، واختبارات العهد والسلف والـRealtime، ثم Browser E2E بحساب HR.

**LAST VERIFIED EVENT — LVE-2026-11-09-660:** تم تأكيد أن HR advances يقرأ مستندات HR فقط ويتجاهل أرصدة Employee Subledger؛ رصيد عهدة تشغيلية حقيقي مرحّل قدره 5,000 EGP موجود في الحساب 127 على الموظف `7d0f21ed-8952-45c1-b00f-e58c61607d56`. لم يجر تعديل تشغيلي أو مالي.  
