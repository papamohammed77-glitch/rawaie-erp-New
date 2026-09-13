# تقرير 172 — إغلاق Commission Engine — Gold Closure / Production / E2E

**التاريخ:** 14 سبتمبر 2026

> **النقطة الأهم:** هدف هذه الجلسة هو الوصول إلى اختبار E2E الفعلي لملف النظام الأم الحالي:
> `https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`
>
> وهو **Source of Truth الوحيد للنظام الأم**. أما `Current/PWA/main2/*` و`New-main` والتقارير السابقة فهي Historical/Reference فقط.

## 1. قاعدة الحقيقة

تم التعامل مع الحالة الحالية فقط من:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولم تُعامل أي نسبة أو حالة من تقرير سابق باعتبارها حقيقة حالية دون مطابقتها بالمصادر الحالية.

## 2. مراجعة Git الحالية

تمت مراجعة أحدث حالة في مستودع النظام الأم، مع مراجعة الـHEAD والـparent:

- Repository: `papamohammed77-glitch/erp-frontend`
- Branch: `main`
- HEAD: `48714c33d5fc12646d0c2ea38033d902a52c4d1a`
- HEAD message: `Initialize customer payment real-time updates`
- Direct parent: `c379674711d6e67d5c2c01305ae8449dd3c0947e`
- Parent message: `Add real-time customer payment updates functionality`
- Current main.html blob: `0bd8dd2fce45802f2383f6157e3e43aea51483f0`

المراجعة أثبتت أن إصلاح customer-payment realtime موجود بالفعل في الـHEAD، ولم تتم إعادة بنائه أو تغييره.

## 3. Current Source للمشروع الأم

تم فتح الـblob الحالي من `main.html` وتحليل المواضع اللازمة للتكامل.

الحالة الحالية المثبتة:

- `RW_Navigation.menuTree` موجود.
- `RW_Finance.renderSubTab(subTab)` موجود.
- المالية تحتوي حاليًا على Treasury / Accounts / Journal / Receipts / Payments / Transfers / Reports / Installments / Budgets.
- `installments` موجود في Current Source بالفعل.
- لا يوجد `Commission` أو `commission` في Current Source؛ البحث أعاد صفر نتائج.
- `forensic_main_assembly.yml` صحيح بالفعل ويشير إلى:
  - repository = `papamohammed77-glitch/erp-frontend`
  - path = `companies/company-1/main.html`
  - ref = `main`
  - mode = `published_main_is_authoritative`
  - fragment_mode = `historical_reference_only`

**قرار:** لا يوجد أي تعديل مطلوب على `forensic_main_assembly.yml`.

## 4. Current Production / Database قبل التنفيذ

Supabase Production:

`fiilmooggumokxanwiyx`

قبل إنشاء Commission Engine لم توجد أي جداول أو Functions تحمل Commission في Production.

بيانات المصدر التي يعتمد عليها المحرك حاليًا:

- `orders.company_id`
- `orders.order_status`
- `orders.order_date`
- `orders.sales_rep_id`
- `order_details.qty`
- `order_details.qty_returned`
- `order_details.unit_price`
- `items.cost_price`
- `users.company_id`

وتم التحقق من أن `order_details.line_amount` هو generated column، لذلك لا تتم الكتابة اليدوية إليه.

عدد مندوبي المبيعات النشطين في الشركة الأساسية وقت التنفيذ: **3**.

عدد الطلبات الحالية المرتبطة بمندوب مبيعات قبل اختبار Commission: **0**.

## 5. التصميم المنفذ

تم تنفيذ Commission Engine كطبقة موحدة وليس كتعديلات مشتتة داخل الواجهة.

### الجداول

1. `commission_plans`
   - تعريف خطة العمولة.
   - شركة، كود، اسم، نوع الأساس، Metric، طريقة الدفع، نسبة أساسية، Target، صلاحية زمنية، حالة اعتماد.

2. `commission_rules`
   - شرائح العمولة حسب Achievement %.
   - دعم حد أدنى وحد أقصى ونسبة أو مبلغ ثابت.

3. `commission_assignments`
   - ربط الخطة بمندوب مبيعات محدد.
   - Target مستقل للمندوب عند الحاجة.
   - حماية Company Scope.

4. `commission_runs`
   - سجل تشغيل رسمي للعمولة.
   - Posted / Approved / Paid / Reversed.
   - Operation ID حتمي من جهة العميل لمنع الازدواجية.
   - دعم Reversal كدفتر عكسي مستقل.

5. `commission_run_lines`
   - التفاصيل الفعلية لكل Order ومندوب.
   - يحتفظ بـSource Snapshot للخطة والـperiod والـmetric.

### العلاقات والقيود

- جميع جداول Commission مرتبطة بـ`companies`.
- الخطط والقواعد والتخصيصات والدفاتر كلها Company-scoped.
- `sales_rep_id` مرتبط بـ`users` مع guard يتحقق من نفس الشركة.
- `commission_run_lines` مرتبط بـ`orders` و`users`.
- Unique operation identity على `(company_id, operation_id)`.
- Unique run line على `(run_id, order_id, sales_rep_id)`.
- Reversal مرتبط بالدفتر الأصلي.

### RLS / Audit / Realtime

- تم تفعيل RLS على جميع جداول Commission.
- الكتابة التشغيلية مقيدة بـ`service_role`.
- تم إنشاء audit triggers على جميع جداول Commission.
- تم ربط التغييرات بسجل `audit_log`.
- تمت إضافة:
  - `commission_plans`
  - `commission_assignments`
  - `commission_runs`
  - `commission_run_lines`
  إلى `supabase_realtime`.

## 6. Commission Core RPC

تم إنشاء Production RPC:

`public.commission_engine_atomic`

التوقيع الحالي:

`p_company_id uuid, p_operation text, p_user_email text, p_plan_id uuid, p_plan_payload jsonb, p_rule_payload jsonb, p_assignment_payload jsonb, p_period_start date, p_period_end date, p_sales_rep_id uuid, p_operation_id uuid, p_run_id uuid, p_reason text, p_payment_reference text`

Security:

- `SECURITY DEFINER = true`
- `EXECUTE` متاح لـ`service_role` فقط.

العمليات التي يدعمها:

`PLAN_SAVE`
`PLAN_APPROVE`
`PLAN_ASSIGN`
`PREVIEW`
`POST`
`APPROVE_RUN`
`MARK_PAID`
`REVERSE_RUN`

## 7. منطق الاحتساب

المحرك لا يعتمد على قيمة يدويّة مخزّنة للعمولة، وإنما يعيد الحساب من بيانات المبيعات الفعلية.

### Metrics

- `invoiced_amount`
- `gross_profit`
- `invoiced_qty`

والكمية المستخدمة هي صافي الكمية:

`qty - qty_returned`

والتقييم محصور في:

`order_status = 'Invoiced'`

مع Company Scope وPeriod Scope وSales Rep Scope.

### Achievement

`achievement % = base / target * 100`

ثم يتم اختيار أعلى Rule متوافق مع Achievement.

### Idempotency

`POST` يقبل `operation_id` ثابتًا من المستهلك.

عند إعادة نفس العملية بنفس Company وOperation ID، يعيد المحرك النتيجة الموجودة مع:

`duplicate = true`

ولا ينشئ دفتر عمولة ثانيًا.

## 8. Edge Function

تم إنشاء ونشر:

`commission-engine`

Production deployment:

- status = `ACTIVE`
- version = `1`
- `verify_jwt = true`
- deployment id = `1c84ef81-16d8-4ae6-8ded-394e4db5588e`
- SHA = `9683d13b7c59ce41c78cdf18a6aad29e9a77ec10972a2fc3f2583d149eaf29fe`

الـEdge لا يثق في `company_id` من المتصفح.

بل يستخرج:

`Authorization JWT -> auth user -> users.auth_id -> users.company_id`

ثم يرسل السياق المثبت إلى RPC.

## 9. Production E2E — النتيجة

تم تشغيل دورة Commission فعلية على Production باستخدام بيانات اختبار مؤقتة.

السيناريو:

- Target = `100`
- Base = `200`
- Achievement = `200%`
- أعلى Tier = `4%`
- Commission = `8`

النتائج:

### PREVIEW

`success = true`

`total_base = 200`

`achievement_pct = 200`

`rate = 4`

`commission_amount = 8`

`line_count = 1`

### POST

تم إنشاء:

`run_id = 1bc9be3b-6afb-4d49-80ed-3e7c40e2e205`

`status = Posted`

`total_base = 200`

`total_commission = 8`

### DUPLICATE POST

تم تنفيذ نفس Operation ID مرة ثانية.

النتيجة:

`duplicate = true`

ولم يتم إنشاء دفتر إضافي.

### APPROVE

`status = Approved`

### MARK PAID

`status = Paid`

مرجع الدفع الاختباري:

`E2E-COMM-PAY-001`

### REVERSE

تم إنشاء دفتر عكسي مستقل:

`reversal_run_id = 21fb93de-672b-4c93-a393-031f779fad2f`

وأصبح الدفتر الأصلي:

`status = Reversed`

## 10. تنظيف Production بعد الاختبار

تم حذف بيانات الاختبار التشغيلية:

- Test Commission Plan
- Test Rules
- Test Assignment
- Test Runs
- Test Run Lines
- Test Order
- Test Order Detail

التحقق النهائي:

`commission_plans = 0`
`commission_rules = 0`
`commission_assignments = 0`
`commission_runs = 0`
`commission_run_lines = 0`
`E2E-COMM test orders = 0`

أما آثار التدقيق في `audit_log` فلم تُحذف، للحفاظ على تاريخ ما تم تنفيذه فعليًا.

## 11. الأخطاء التي ظهرت أثناء التنفيذ

### الخطأ الأول — استدعاء RPC positional غير صحيح

حدث أثناء أول محاولة E2E لأن استدعاء `commission_engine_atomic` مرر عددًا/أنواعًا لا تطابق التوقيع.

**المعالجة:** تم التحول إلى named parameters، ثم نجح Runtime execution بالكامل.

### الخطأ الثاني — الكتابة إلى Generated Column

أول محاولة لإدخال Test `order_details` حاولت الكتابة في:

`line_amount`

والـProduction Schema يثبت أن هذا العمود Generated Always.

**المعالجة:** تمت إعادة الإدخال دون `line_amount`، ونجح الاختبار.

### الخطأ الثالث — عدم وجود Browser HTTP Token داخل أداة التنفيذ

تم التحقق من Edge deployment وSource وJWT enforcement، لكن لم يتم تنفيذ HTTP authenticated browser call من جلسة مستخدم حقيقية من خلال هذه الجلسة.

**النتيجة:**

`Production RPC Runtime = VERIFIED`

`Edge Deployment = VERIFIED`

`Authenticated Browser HTTP E2E = OPEN`

ولا يجوز تحويل هذه الثلاثة إلى ادعاء واحد بأن Browser E2E مغلق.

## 12. Current Frontend Status

تم **عدم تعديل** `erp-frontend/companies/company-1/main.html`، التزامًا بفصل المسؤوليات المحدد من المالك.

Current Source أثبت أن:

- Installments موجودة بالفعل.
- Commission غير موجودة.

إذن الإغلاق الحقيقي للواجهة يحتاج **جراحة واحدة فقط** لإضافة Commission UI، وليس إعادة إصلاح Finance أو Installments.

## 13. التعليمات الجراحية المطلوبة في main.html

### التعديل 1 — Finance Navigation

ابحث عن العنصر الكامل:

`{ action: 'showFinanceTab', arg: 'installments', label: 'التقسيط والتحصيل الآجل', perm: ['finance', 'finance_manager'] }, { view: 'settlement', label: 'إغلاق اليومية' }] },`

احذفه واستبدله بـ:

`{ action: 'showFinanceTab', arg: 'installments', label: 'التقسيط والتحصيل الآجل', perm: ['finance', 'finance_manager'] }, { action: 'showFinanceTab', arg: 'commission', label: 'العمولات', perm: ['finance', 'finance_manager'] }, { view: 'settlement', label: 'إغلاق اليومية' }] },`

الموضع المثبت في Current Source: داخل `RW_Navigation.menuTree` بعد عنصر Installments مباشرة.

### التعديل 2 — Finance Tabs

داخل `function renderSubTab(subTab)` ابحث عن السطر الكامل:

`{ id: 'reports', label: 'التقارير المالية' }, { id: 'installments', label: 'التقسيط والتحصيل الآجل' }, { id: 'budgets', label: 'الموازنات' }`

احذفه واستبدله بـ:

`{ id: 'reports', label: 'التقارير المالية' }, { id: 'installments', label: 'التقسيط والتحصيل الآجل' }, { id: 'commission', label: 'العمولات' }, { id: 'budgets', label: 'الموازنات' }`

الموضع المثبت: `RW_Finance.renderSubTab` في Current Source قرب بداية قسم Finance.

### التعديل 3 — تبويب Commission Dispatch

ابحث عن السطر الكامل:

`else if (tab === 'installments') _renderInstallments();`

احذفه واستبدله بـ:

`else if (tab === 'installments') _renderInstallments();
else if (tab === 'commission') _renderCommission();`

### التعديل 4 — إضافة Commission UI كامل

ابحث عن السطر الكامل:

`function _renderBudgets() {`

أضف **فوقه مباشرة** كتلة Commission UI كاملة.

الكتلة يجب أن تشمل:

- `_commissionEndpoint()`
- `_commissionOperationId()`
- `_commissionFetch()`
- `_renderCommission()`
- `_loadCommissionReps()`
- `_saveCommissionPlan()`
- `_approveCommissionPlan()`
- `_assignCommissionRep()`
- `_previewCommission()`
- `_postCommission()`
- `_loadCommissionRuns()`

ويجب أن تنفذ:

1. تعريف Plan Code / Name.
2. اختيار Basis Type.
3. اختيار Basis Metric.
4. Default Rate.
5. Target Amount.
6. Effective Dates.
7. Rules متعددة الشرائح.
8. اعتماد الخطة.
9. اختيار Sales Rep.
10. Target للمندوب.
11. Preview.
12. Post مع Operation ID ثابت من المتصفح.
13. عرض دفاتر العمولة السابقة.
14. عرض الحالة Posted / Approved / Paid / Reversed.
15. Realtime subscription على:
   - `commission_plans`
   - `commission_assignments`
   - `commission_runs`
   - `commission_run_lines`

Endpoint:

`RW_SUPABASE_URL + '/functions/v1/commission-engine'`

### التعديل 5 — Export

في ذيل `RW_Finance` ابحث عن آخر عنصرين كاملين:

`_supplierAging: _supplierAging,
_costCenterProfitLoss: _costCenterProfitLoss`

واستبدلهما بالكامل بـ:

`_supplierAging: _supplierAging,
_costCenterProfitLoss: _costCenterProfitLoss,
_renderCommission: _renderCommission,
_loadCommissionReps: _loadCommissionReps,
_saveCommissionPlan: _saveCommissionPlan,
_approveCommissionPlan: _approveCommissionPlan,
_assignCommissionRep: _assignCommissionRep,
_previewCommission: _previewCommission,
_postCommission: _postCommission,
_loadCommissionRuns: _loadCommissionRuns`

## 14. E2E Browser المطلوب بعد جراحة المالك

بعد دمج `main.html` ونشره:

1. فتح نسخة Incognito جديدة.
2. تسجيل الدخول بمستخدم لديه Finance permission.
3. فتح:
   `إدارة الحسابات والمالية -> العمولات`
4. إنشاء خطة اختبار.
5. تعريف Tier.
6. ربط الخطة بمندوب.
7. تشغيل Preview.
8. التحقق من Total Base / Achievement / Commission.
9. تشغيل Post.
10. إعادة Post بنفس Operation ID.
11. التحقق من `duplicate = true`.
12. فحص Console بحثًا عن أي Error.
13. فحص Realtime refresh.
14. فحص دفتر العمولة.

هذه الخطوة لم ينفذها المساعد لأن تعديل Master UI مسؤولية المالك.

## 15. الحالة النهائية للمهمة

```text
Commission Production Schema              = CLOSED
Commission Production RPC                 = CLOSED
Company Isolation                          = CLOSED
Plan / Rule / Assignment Model             = CLOSED
Idempotent POST                            = VERIFIED
Preview Calculation                        = VERIFIED
Tier Calculation                           = VERIFIED
Approve Lifecycle                          = VERIFIED
Paid Lifecycle                             = VERIFIED
Reversal Lifecycle                         = VERIFIED
Audit                                       = DEPLOYED
Realtime                                    = DEPLOYED
Commission Edge Function                   = DEPLOYED
Canonical Git Migration                    = ADDED
Canonical Git Edge Source                  = ADDED
Master Frontend UI                         = OWNER SURGERY REQUIRED
Browser E2E                                 = OPEN
```

**الحكم:** Commission Engine backend أصبح Production-ready ومغلقًا من جهة Database/RPC/Edge، لكن **المهمة الكلية لا تحمل 100% Closed بعد** لأن `main.html` ما زال يحتاج جراحة الواجهة ثم Browser E2E.

## 16. تعليمات البداية للمساعد القادم

لا تبدأ من هذا التقرير كحالة حالية؛ هو سجل تنفيذ.

ابدأ دائمًا بهذا التسلسل:

`CURRENT FRONTEND HEAD`
`-> DIRECT PARENT`
`-> CURRENT MASTER main.html`
`-> CURRENT SUPABASE SCHEMA`
`-> CURRENT COMMISSION FUNCTIONS`
`-> CURRENT EDGE DEPLOYMENT`
`-> CURRENT RLS / TRIGGERS / REALTIME`
`-> CURRENT PRODUCTION COUNTS`
`-> CURRENT BROWSER / CONSOLE`

ثم اسأل:

`ما الذي ثبت أنه CLOSED؟`
`ما الذي ثبت أنه OPEN؟`
`هل يوجد Drift منذ آخر HEAD أو Deployment؟`

بعدها فقط:

`historical contract`
`-> `current behavior`
`-> `actual gap`
`-> `surgical change`
`-> `test`
`-> `deploy`
`-> `Production verify`
`-> `runtime verify`
`-> `document`
`-> `close`

لا تعيد إصلاح ما ثبت إغلاقه.
لا تثق بتقرير باعتباره Current State.
لا تستخدم `Current/PWA/main2` أو `New-main` كـSource of Truth.
لا تعتبر وجود جدول أو RPC مساويًا لاكتمال الـBusiness Lifecycle.
لا تعتبر Browser E2E مغلقًا من مجرد نجاح RPC.
لا تترك مسؤولية Business دون Owner واضح بين Frontend / Edge / RPC / Database.

## 17. المبدأ النهائي

الهدف ليس إنشاء جدول عمولات فقط.

الهدف هو إنشاء دورة عمولة متكاملة:

`Sales Orders`
→ `Actual Sales Base`
→ `Target / Achievement`
→ `Commission Rules`
→ `Preview`
→ `Post`
→ `Approve`
→ `Paid`
→ `Reverse / Clawback`
→ `Audit`
→ `Realtime`
→ `Management UI`
→ `Browser E2E`

وهذه هي الوحدة التي يجب أن تُعتبر Commission Engine مكتملة عليها، وليس بمجرد توفر الـschema.
