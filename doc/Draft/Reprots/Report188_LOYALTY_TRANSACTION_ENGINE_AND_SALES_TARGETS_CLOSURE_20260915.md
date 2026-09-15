# تقرير 188 — إغلاق Loyalty Transaction Engine وتثبيت Sales Targets الديناميكية

**التاريخ:** 2026-09-15
**الحالة المرجعية:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE

> **قاعدة حاكمة:** هذا التقرير توثيق لما تم إثباته وتنفيذه في Production في هذه الجلسة، وليس مصدر الحقيقة بحد ذاته. أي جلسة لاحقة يجب أن تعيد المصادقة على الحالة الحالية مباشرة.

---

## 1. نقطة البداية الصحيحة

تمت مراجعة مبادئ الحوكمة وأمر الاستكمال، وتم التعامل مع التقارير السابقة كمصادر تاريخية/استرشادية فقط.

تمت مطابقة أحدث Commit الخاص بملف النظام الأم في المستودع `erp-frontend` مباشرة من Git:

- **HEAD:** `13425725f48c7decba3403ee631d8e0f2d757b0f`
- **Parent:** `05ebb2d67b29dfe26ad77b6f314942c502e0dd8f`
- **Current mother blob:** `5267f261f2febcbafeafdce0bb9da89a4a6bc894`
- Commit HEAD يعدّل KPI layout/timestamps مقارنة بالـParent، ولا يجوز استخدام `CURRENT_STATE.md` القديم كبديل لهذه الحقيقة.

### ملاحظة إلزامية عن ملف النظام الأم

المطلوب كان قراءة `companies/company-1/main.html` حتى EOF واستخراج anchors وأرقام الأسطر من النسخة الحالية نفسها قبل أي تعديل جراحي.

تم إثبات الوصول إلى **الـcurrent blob نفسه**، وتمت مطابقة SHA الحالي، كما تم فحص أجزاء من المصدر الحالي. لكن واجهة GitHub المتاحة في هذه الجلسة لم تسمح بإخراج كامل الـblob الكبير مع line-addressable ranges في جلسة واحدة؛ والـraw download من بيئة التنفيذ لم يكن متاحًا بسبب عدم توفر DNS الخارجي.

لذلك **لم يتم اختلاق أي line numbers جديدة**، ولم يتم إصدار Patch جراحي لملف `main.html` في هذه الجلسة اعتمادًا على أرقام قديمة. هذا قرار حوكمة صحيح، وليس نقصًا في التحقق.

---

## 2. ما تم إثباته في Production قبل التعديل

### 2.1 Sales Targets

تم إثبات أن Production تحتوي بالفعل على:

- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

وأنها مرتبطة بـ:

- `sales_target_engine_atomic`
- `sales_target_engine_gateway`
- `sales_target_dashboard_atomic`

وبالتالي لم تتم إعادة بناء Sales Targets من الصفر.

### 2.2 Loyalty

لم يكن هناك في Production قبل هذه الجلسة Ledger تشغيلي مكتمل للولاء؛ لذلك كانت عبارة:

`Loyalty transaction engine = OPEN`

صحيحة من واقع Production.

---

# 3. تنفيذ Loyalty Transaction Engine

تم تنفيذ البنية الأساسية في Production مباشرة.

## 3.1 الجداول المنشأة

### `loyalty_programs`

يحتوي على:

- company scope
- program code/name
- Active/Draft/Inactive lifecycle
- priority
- earn rules
- redeem rules
- minimum redemption
- maximum redemption percent
- expiry configuration
- approval metadata

تم فرض:

`UNIQUE(company_id, program_code)`

وتم إنشاء:

`uq_loyalty_programs_active_company`

بحيث يوجد برنامج Active واحد فقط لكل شركة.

### `loyalty_rewards`

يدعم:

- discount
- credit
- free shipping
- free product

مع:

- points_cost
- reward_value
- optional product reference
- max_discount
- active state

وتم فرض صحة `free_product` بحيث يكون هناك `product_id`.

### `loyalty_accounts`

هو الرصيد التشغيلي لكل عميل:

- company_id
- customer_id
- points_balance
- lifetime_earned
- lifetime_redeemed
- status

مع:

`UNIQUE(company_id, customer_id)`

### `loyalty_transactions`

هو Ledger الحركات غير القابل للاعتماد على Cache فقط، ويحتوي على:

- EARN
- SYNC
- REDEEM
- ADJUST
- EXPIRE
- REVERSE

مع:

- balance_before
- balance_after
- operation_id
- order_id
- reward/program references
- reversal_of_transaction_id
- actor
- reason
- metadata

تم فرض idempotency على مستوى الشركة عبر `operation_id`.

---

## 3.2 Source of Truth

تم إبقاء `customers.loyalty_points` كـCompatibility Cache فقط.

مصدر الحقيقة التشغيلي للولاء أصبح:

`loyalty_accounts + loyalty_transactions`

ويتم تحديث Cache بعد كل mutation ناجح.

---

## 3.3 الأمان

تم تفعيل RLS على جداول Loyalty الجديدة ومنع الوصول المباشر من `anon/authenticated`، مع تنفيذ العمليات عبر:

`SECURITY DEFINER loyalty_engine_atomic`

وتم منح EXECUTE إلى:

`service_role`

فقط.

كما تمت إضافة Audit Triggers على:

- loyalty_programs
- loyalty_rewards
- loyalty_accounts
- loyalty_transactions

باستخدام `fn_audit_trigger()` القائم.

---

## 3.4 الـRPC المركزي

تم إنشاء/تثبيت:

`public.loyalty_engine_atomic(uuid,text,text,jsonb,text)`

والعمليات التي يضمها:

- LIST_PROGRAMS
- LIST_REWARDS
- GET_ACCOUNT
- LIST_TRANSACTIONS
- SAVE_PROGRAM
- SAVE_REWARD
- REDEEM
- EARN_ORDER
- SYNC_ORDER
- ADJUST
- EXPIRE
- REVERSE

تمت إضافة:

- company-scoped actor validation
- customer tenant validation
- order tenant validation
- permission checks
- account row locks
- advisory lock per company/customer
- operation idempotency
- double reversal prevention
- non-negative balance protection

---

## 3.5 Edge Function

تم إنشاء Edge Function:

`loyalty-engine`

بـ:

`verify_jwt = true`

ويقوم بـ:

1. التحقق من Bearer token.
2. Resolve `auth_id -> users -> company_id`.
3. رفض user غير النشط.
4. تمرير operation/payload/operation_id إلى الـRPC المركزي.
5. دعم `Idempotency-Key`.

وهكذا أصبح الـEdge Layer Capability Wrapper وليس Business Logic Engine موازيًا.

---

# 4. Loyalty E2E Production Transaction Test

تم تنفيذ اختبار E2E داخل Transaction واحدة ثم Rollback كامل حتى لا يتم تلويث Production ببيانات الاختبار.

التسلسل:

1. إنشاء Customer مؤقت.
2. إنشاء Invoiced Order مؤقت.
3. إضافة Order Detail فعلي.
4. إنشاء Program Active.
5. EARN_ORDER.
6. إعادة نفس EARN operation_id.
7. REDEEM.
8. إعادة نفس REDEEM operation_id.
9. REVERSE لعملية REDEEM.
10. التحقق من الرصيد.
11. ROLLBACK.

النتيجة المثبتة في الجلسة:

**PASS**

- EARN نجح.
- EARN retry أعاد duplicate ولم يكرر الرصيد.
- REDEEM نجح.
- REDEEM retry أعاد duplicate.
- REVERSE أعاد الحركة العكسية.
- تم الحفاظ على عدم سلبية الرصيد.
- لم تبق بيانات الاختبار بعد Rollback.

---

# 5. أخطاء ظهرت أثناء التنفيذ وكيف تم إغلاقها

## 5.1 خطأ في اختبار RECEIVE PURCHASE

الاختبار الأول لم يكن مناسبًا لإثبات idempotency لأن الاختبار نفسه أعاد ترتيب الفحص بطريقة جعلت retry يصطدم بفحص المتبقي قبل الوصول إلى duplicate detection.

تم عدم تحويل فشل الـharness إلى حكم خاطئ على Production.

القاعدة المستخلصة:

`operation identity -> duplicate check -> business validation -> mutation`

وليس العكس.

## 5.2 خطأ Sales Targets في SAVE_ASSIGNMENT

تم اكتشاف ambiguity حقيقي في تحديث assignment بسبب استخدام `branch_id` في سياق يوجد فيه متغير PL/pgSQL واسم عمود.

تم إصلاحه عبر alias صريح للجدول:

`UPDATE public.sales_target_assignments sta ...`

بحيث أصبح `sta.branch_id` منفصلًا عن متغيرات PL/pgSQL.

ثم تمت استعادة كامل دورة Sales Targets وعدم الاحتفاظ بنسخة مختصرة أسقطت مسؤوليات موجودة.

## 5.3 خطأ E2E harness الخاص بـLoyalty

النسخة الأولى من الـCTE كانت تسمح بتقييم العمليات بترتيب غير مقصود، فظهر `Insufficient loyalty points` رغم أن ترتيب العمل الصحيح يجب أن يكون Program -> Earn -> Redeem.

تمت إعادة الاختبار على خطوات متسلسلة صريحة، وأصبح الـE2E PASS.

## 5.4 الحذر من اختلاق anchors

لم يتم استخدام line numbers القديمة من `CURRENT_STATE.md` كأنها current. تم التحقق من أن الـblob الحالي تغير بعد أحدث Commit.

هذا مهم جدًا لأن أي تعديل جراحي على ملف 40K+ سطر بأرقام تاريخية قد يسبب حذفًا أو استبدالًا في الموضع الخطأ.

---

# 6. Sales Targets — Dynamic Target E2E

تم اختبار أن الهدف ليس Static Contract.

داخل Transaction واحدة:

1. إنشاء Target Plan.
2. تحديد Target = `10,000`.
3. تعديل نفس Assignment إلى `15,000`.
4. اعتماد الخطة.
5. Preview.
6. POST.
7. تكرار POST بنفس operation_id.
8. Clone للخطة.
9. التأكد من نقل الـassignments.
10. Rollback.

النتيجة:

**PASS**

وبالتالي تم إثبات أن:

- Sales Target قابل للتغيير قبل اعتماد الخطة.
- Assignment قابل للتعديل.
- يوجد lifecycle للـPlan.
- POST idempotent.
- Clone ينقل التوزيعات.

ولا توجد حاجة لإعادة بناء Sales Targets كهيكل جديد.

---

# 7. ما لم يتم تغييره عمدًا

لم يتم تغيير:

- `post_stock_movement`
- رحلة Picking/Loading/Delivery/Return الأساسية
- order_details كـfulfillment source
- run_sheet_details كمشتق aggregate
- أي legacy fragment historical
- `New-main`
- ملف النظام الأم `erp-frontend/main.html`

لأن الأدلة الحالية لم تثبت أن ذلك مطلوب لهذه الـClosure Unit.

---

# 8. Tenant / Identity Findings

أثبتت Production أن:

- `items.item_code` لديه UNIQUE عالميًا.
- `stock_branches` له UNIQUE على `(branch_id,item_id)`.

وبناءً على ذلك، تم رفض فكرة اختراع Company-scoped item identity في كل مكان دون دليل، وتم استخدام الهوية الرسمية الموجودة في Schema.

في المقابل، Customers ليست مضمونة بــtenant FK مركب، لذلك تم إضافة صراحة داخل Loyalty Engine:

`customer.id + customer.company_id`

قبل أي mutation.

---

# 9. Frontend Mother System Status

المطلوب في هذه المرحلة ليس إعادة بناء split parts.

Source of Truth الوحيد هو:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

ولم يتم إصدار أي تعديل له في هذه الجلسة لأن شرط الحوكمة يطلب exact current anchors من الـcurrent blob، وأداة الوصول للـblob الكبير لم تُعطِ line-addressable EOF/ranges موثوقة لهذه النسخة.

هذا يمنع الخطأ التالي:

- استعمال line 1309/1423/1900 من State قديم.
- تعديل موضع تغير بعد آخر KPI commits.

لا يوجد أي claim في هذا التقرير أن Frontend Loyalty UI اكتمل.

هذا يعني أن Closure الـProduction لا يساوي Closure الـMother UI.

---

# 10. Forensic Assembly

تمت مراجعة `CURRENT_STATE.md` ولاحظت أنه كان يسجل HEAD أقدم:

`dddf1aaf5a6e2fe6be7b3d89451dede9c1387258`

بينما Git الحالي يثبت:

`13425725f48c7decba3403ee631d8e0f2d757b0f`

لذلك لا يجوز استخدام State القديم كمرجع Git.

ولم يتم تعديل `forensic_main_assembly.yml` في هذه الجلسة دون العثور على نسخة موجودة line-addressable تسمح بتحديثها بأمان.

الـSource of Truth المنطقي المعتمد هو:

```text
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

---

# 11. FINAL SELF-AUDIT

## What I Proved

- Current mother Git HEAD and parent from Git مباشرة.
- Current mother blob SHA.
- Production Loyalty tables did not exist before this Closure.
- Loyalty ledger/account/program/reward architecture now exists in Production.
- Loyalty RPC exists and is service-role gated.
- Loyalty Edge Function exists and verifies JWT.
- Loyalty E2E Earn/Redeem/Reverse + duplicate protection passed transactionally.
- Sales Targets are already architected dynamically.
- Sales Target assignment update ambiguity was fixed.
- Sales Target lifecycle E2E passed transactionally.

## What I Did Not Prove

- Full line-addressable manual reading of all ~40K lines of current `main.html` in this environment.
- Fresh browser-incognito Console/Network capture.
- Served-source byte hash from the user's browser after the latest frontend commit.
- Final frontend wiring of Loyalty UI to the new Edge Function.

## What I Fixed

- Loyalty Production engine and supporting schema/security.
- Sales Target `SAVE_ASSIGNMENT` ambiguity.
- Sales Target lifecycle preservation after repair.
- Tenant checks داخل Loyalty.
- Production E2E idempotency behavior for Loyalty and Sales Targets.

## What I Initially Missed

- The need to treat operation identity as first-class state rather than deriving all retries implicitly.
- The possibility that a shortened Sales Target repair could drop lifecycle responsibilities; the final Production function was therefore restored to include the full lifecycle.

## What Could Still Be Wrong

- Mother System may still not expose the Loyalty engine/UI.
- The current frontend source has not yet been given a new surgical patch because exact current anchors were not safely retrievable.
- Canonical Git migration/source records for the new Production Loyalty objects must be reconciled against live Production before calling repository reproducibility complete.

## Final Confidence

**Production Loyalty Engine:** HIGH — E2E transactionally verified.

**Production Sales Targets dynamic behavior:** HIGH — E2E transactionally verified.

**Mother System Frontend Closure:** INCOMPLETE — exact current-file anchors and fresh browser evidence still required.

**Overall Gold/Diamond Closure:** NOT YET CLOSED.

---

# 12. إرشادات المساعد التالي للوصول إلى الحقيقة

ابدأ دائمًا بهذا الترتيب ولا تعكسه:

1. اقرأ Git الحالي مباشرة.
2. خذ HEAD ثم Parent ثم blob الحالي للـSource of Truth.
3. لا تثق في CURRENT_STATE قبل مطابقة SHA مع Git.
4. احسب/تحقق من الـblob نفسه، ثم افتح `main.html` حتى EOF.
5. استخرج anchors من النسخة الحالية فقط، ولا تستخدم أرقامًا من تقرير قديم.
6. افحص Production RPCs/Functions/Tables/Triggers/Grants قبل أي تعديل.
7. استخدم transaction-only E2E harness عندما لا توجد بيانات اختبار مضمونة.
8. عند اكتشاف defect لا تختصر function كاملة إذا لم تُثبت مسؤولياتها كلها؛ استرجع التعريف الكامل من Production أولًا.
9. كل mutation يجب أن يكون idempotent حيث يلزم.
10. افصل Source of Truth عن Compatibility Cache.
11. بعد كل Closure أعد الفحص من Production قبل الانتقال للوحدة التالية.
12. لا تعيد إصلاح ما ثبت أنه Closed.
13. لا تعلن 100% إلا إذا تحقق Production + Deployment + Runtime + Source alignment.

### أول سؤال يجب طرحه على نفسك

> **ما الحقيقة الحالية التي أثبتها Git وProduction الآن، وليس ما قاله تقرير سابق؟**

ثم فقط:

`UNDERSTAND -> TRACE -> PROVE -> FIX -> TEST -> DEPLOY -> VERIFY -> CLOSE`

---

# 13. نقطة الانطلاق للجلسة القادمة

الأولوية التالية ليست إعادة بناء Sales Targets.

الأولوية هي:

**Mother System E2E + Loyalty UI Integration**

ثم:

**ربط Loyalty بإغلاق فاتورة البيع والمرتجع من خلال boundary آمنة لا تضيف Business Engine موازيًا.**

وبعد ذلك فقط:

**إعادة فحص الـfrontend tab-by-tab لاستكمال النقص Gold/Diamond.**
