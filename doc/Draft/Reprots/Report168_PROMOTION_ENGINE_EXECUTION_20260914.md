# تقرير 168 — تنفيذ Promotion Engine

## 0) نقطة البداية والقاعدة الحاكمة

**تنبيه مهم:** الهدف في هذه الدورة لم يكن كتابة تقرير عن Promotion Engine، بل تنفيذ القدرة فعليًا في Production وإنشاء البنية اللازمة لها، ثم إعداد ما تبقى على ملف النظام الأم وفق فصل المسؤوليات.

الحالة الحالية لا تُستمد من أي تقرير سابق. جميع التقارير السابقة استُخدمت فقط كدلائل تاريخية للوصول إلى المصادر الأولية.

الحالة المعتمدة في هذه الدورة:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

والمبدأ الحاكم المتكرر في التقرير وفي العمل:

`REPORTS ARE CLUES — NEVER CURRENT STATE`

---

## 1) مصادر الحقيقة التي تم فتحها والتحقق منها

### 1.1 Master Governance
تمت قراءة ملف:

`doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`

حتى EOF عبر القراءة المتتابعة، وتم التحقق من القواعد الحاكمة، وأهمها:

- `NO EVIDENCE = NO CLAIM`
- `NO EOF = NO FULL READ`
- Production مصدر حقيقة من الدرجة الأولى
- `CURRENT_STATE.md` يجب إعادة بنائه من الواقع وليس تصديقه Blindly
- Business Capability هي وحدة الإغلاق وليست مجرد Tab أو Function
- لا Skeleton Completion
- لا Stub / Placeholder / fake success
- كل Transaction حرجة تفحص للـretry والـduplicate والـpartial success
- كل Lookup حساس يجب أن يراعي Company / Branch / User / Auth / Resource Ownership
- الفرق بين COMMIT وDEPLOYMENT وRUNTIME وPRODUCTION VERIFIED
- التعديل الجراحي، وOwner Change Set الكامل عند تعديل النظام الأم

### 1.2 Report167
تمت قراءة `Report167_PRICE_LIST_ENGINE_EXECUTION_20260913.md` كاملًا حتى EOF لاستخدامه كمرجع تاريخي فقط.

أهم ما تم استخراجه تاريخيًا:

- ملف النظام الأم المعتمد هو:
  `erp-frontend/companies/company-1/main.html`
- `Current/PWA/main2/*` و`New-main` تاريخية وليست Source of Truth
- Price List Engine كان مفتوحًا جزئيًا، وتم نشر Backend وEdge، بينما Owner UI وBrowser E2E بقيا مفتوحين
- كانت الخطوة التالية التاريخية المقترحة هي Promotion Engine

لم يتم إعادة تنفيذ Price List أو Quote لأن التقرير الحالي يثبت أن تلك الوحدات ليست موضوع الـClosure الحالية، ولم يظهر contradictory evidence يستوجب إعادة فتحها.

### 1.3 Current Frontend Git
تمت مراجعة أحدث Commit الفعلي للمستودع:

Repository:
`papamohammed77-glitch/erp-frontend`

HEAD:
`2ad8da6057cf9c7f1e0ddb8374a7b220d21ee28b`

Message:
`Update main.html`

Direct Parent:
`edf60227f88eaabec10cf1083d87bb2665990279`

Parent of Parent:
`aaebffbdd732b9861d96631f5d01c5a6697bd1e4`

Commit verification:
GitHub reported the commit signature as verified.

الـHEAD الحالي يحتوي بالفعل على Price List integration في `main.html` عبر navigation / permission / title / route / `RW_PriceLists` module.

### 1.4 Current main.html
تم فتح المصدر الحالي المباشر:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Current blob في commit `2ad8da...`:
`0519117415390d6721c977fafab1a413d72bf52c`

المسار المعتمد لم يتغير.

`forensic_main_assembly.yml` يظل مرتبطًا بالمسار الصحيح للنظام الأم، ولا توجد حاجة لتغيير Source of Truth إلى `main2`.

---

# 2) Current Production — Promotion Engine

## 2.1 الحالة السابقة المثبتة

قبل هذه الدورة لم تكن Production تحتوي على Promotion Engine فعلي قابل للاستخدام كقدرة تجارية مستقلة:

- لا Promotion tables.
- لا Promotion Resolver RPC.
- لا Promotion Redemption RPC.
- لا Promotion Edge capability.

تم إنشاء هذه الطبقة الآن.

---

## 2.2 Production tables المنشأة

### `public.promotions`
تخزن تعريف العرض نفسه:

- company_id
- code
- name
- description
- promotion_type
- stacking_policy
- trigger_mode
- coupon_code
- channel_scope
- customer_scope
- priority
- min_subtotal
- min_qty
- max_discount
- usage_limit_total
- usage_limit_per_customer
- valid_from / valid_until
- is_active
- operation_id
- created_by
- timestamps

الأنواع المدعومة:

`discount`
`cheapest_item`
`buy_x_get_y`

سياسة التجميع:

`exclusive`
`stackable`

طرق التفعيل:

`automatic`
`code`

القنوات:

`all`
`pos`
`telesales`
`order-taker`
`van-sales`
`online-store`

### `public.promotion_rules`
تخزن قواعد العرض التفصيلية:

- scope = all / item / category
- trigger quantity
- reward type
- reward value
- reward quantity
- reward item
- maximum discount
- validity
- active state
- sequence

وتم إضافة Constraint يمنع قيمة الخصم النسبي الأعلى من 100%.

### `public.promotion_customers`
ربط عرض بعملاء محددين مع Company scope.

### `public.promotion_branches`
ربط عرض بفروع محددة مع Company scope.

### `public.promotion_redemptions`
سجل استخدام العرض:

- company
- promotion
- order
- customer
- channel
- coupon
- discount amount
- free items
- operation_id
- actor
- timestamp

مع Unique Identity:

`company_id + operation_id`

---

# 3) Security / Tenant Integrity

تم تنفيذ:

- RLS على جميع Promotion tables.
- FORCE RLS على جميع Promotion tables.
- سحب `anon` و`authenticated` من الجداول.
- منح service_role فقط للوصول التنفيذي.

كل الـresolver paths تتحقق من:

- Company
- Customer ownership
- Branch ownership
- Promotion ownership
- Customer targeting
- Branch targeting
- Channel
- Date validity
- Usage limits

ولا يوجد في هذا المحرك:

`app_settings LIMIT 1`

لاستخراج Tenant.

---

# 4) Promotion Resolution Engine

تم إنشاء:

`public.resolve_promotion_cart(...)`

وهو Resolver تجاري فقط.

المسار:

`Cart`
→ `Promotion Eligibility`
→ `Rule Match`
→ `Discount / Reward`
→ `Final Commercial Total`

ولا ينفذ:

- update على `stock_branches`
- insert على `inventory_log`
- Physical Stock movement

وبالتالي لا يوجد خلط بين:

`Commercial Pricing / Promotion`

وبين:

`Physical Inventory Engine`

وعقد المخزون يظل:

`Physical Movement -> post_stock_movement -> stock_branches + inventory_log`

---

# 5) Rule Selection Hardening

خلال تنفيذ المحرك ظهر Defect منطقي في النسخة الأولى من Resolver:

كان اختيار `rr` يمكن أن يلتقط Rule من Promotion لا يطابق فعليًا أحد عناصر السلة بسبب شرط اختيار غير مكتمل.

تم اكتشاف ذلك قبل إغلاق القدرة، وتم تعديل الـResolver في Production ليشترط أن يكون الـRule:

- Active
- ضمن تاريخ الصلاحية
- Trigger quantity مناسب
- والـscope الخاص به مطابقًا لعنصر فعلي في السلة

ثم تم تسجيل هذا التغيير في Git عبر:

`supabase/migrations/20260914_promotion_engine_resolver_hardening.sql`

وهذا يمنع تحويل Defect منطقي إلى Production behavior غير صحيح.

---

# 6) Promotion Redemption / Idempotency

تم إنشاء:

`public.record_promotion_redemption(...)`

وتم إثبات السلوك داخل Transaction في Production:

### المحاولة الأولى

```text
success = true
duplicate = false
operation_id = REDEEM-TEST-20260914
```

### إعادة نفس العملية

```text
success = true
duplicate = true
نفس redemption_id
نفس promotion_id
نفس discount_amount
```

ثم تمت عملية `ROLLBACK` بالكامل.

هذه نتيجة فعلية من PostgreSQL وليست محاكاة.

---

# 7) Resolver E2E Transactional Test

تم تشغيل اختبار Transactional كامل بدون ترك بيانات دائمة:

1. إنشاء Promotion مؤقت.
2. إنشاء Rule بنسبة خصم 10%.
3. تمرير Cart بقيمة 100.
4. استدعاء Resolver.
5. النتيجة:

```text
success = true
candidate_count = 1
discount_total = 10
final_subtotal = 90
promotion.code = TEST-PROMO-E2E2
```

6. `ROLLBACK` بعد الاختبار.

ثم تحقق Production بعد ذلك من:

`promotions = 0`

و:

`promotion_rules = 0`

لا توجد بيانات اختبار دائمة من هذه الاختبارات.

---

# 8) Promotion Edge Function

تم إنشاء ونشر:

`promotion-engine`

Production status:

`ACTIVE`

Production version بعد hardening:

`v2`

`verify_jwt = true`

Deployment SHA:
`a7d1614391c61080e81df71a36fce1272eff01580f7747f8a45a82b7755016ef`

Capabilities:

- `catalog`
- `list`
- `detail`
- `create`
- `update`
- `set_active`
- `resolve`
- `redeem`

Authorization:

`JWT -> auth user -> public.users -> company_id`

والصلاحيات الحالية تقبل:

- Owner
- `*`
- `promotions`
- `sales`
- `orders`

---

# 9) Create Idempotency Hardening

تم إضافة:

`promotions.operation_id`

مع Unique Index على:

`company_id + operation_id`

والـEdge الحالي يشترط `operation_id` عند CREATE.

إذا وصل Retry بنفس العملية بعد نجاح الإنشاء:

يتم إرجاع السجل السابق بدل إنشاء Promotion ثانية.

هذا يمنع Double Create الناتج عن Network Retry.

---

# 10) Canonical Git Backend Sources

تمت إضافة:

`supabase/migrations/20260914_promotion_engine_core.sql`

`supabase/migrations/20260914_promotion_engine_hardening.sql`

`supabase/migrations/20260914_promotion_engine_resolver_hardening.sql`

وSource الـEdge:

`Current/Edge_Functions/promotion-engine/index.ts`

وتم تسجيل Owner Change Set:

`doc/Draft/Reprots/PROMOTION_OWNER_SURGICAL_PATCH_20260914.js`

هذه الملفات أصبحت المرجع القابل لإعادة البناء Backend-wise.

---

# 11) Owner-side Main.html — لم يتم تعديله مباشرة

وفق فصل المسؤوليات، لم يتم تعديل:

`erp-frontend/companies/company-1/main.html`

من جانب المساعد.

تم إعداد ملف Owner Change Set كامل:

`doc/Draft/Reprots/PROMOTION_OWNER_SURGICAL_PATCH_20260914.js`

### التغييرات المطلوبة على النظام الأم

#### A) Navigation — حوالي السطر 1142

ابحث عن السطر الكامل:

```js
{ view: 'price-lists', label: 'قوائم الأسعار' },
```

أضف بعده مباشرة:

```js
{ view: 'promotions', label: 'العروض والخصومات' },
```

#### B) Permission Map — حوالي السطر 17085

ابحث عن:

```js
'price-lists': 'orders',
```

أضف بعده:

```js
'promotions': 'orders',
```

#### C) Titles — حوالي السطر 17144

ابحث عن:

```js
'price-lists':'قوائم الأسعار',
```

أضف بعده:

```js
'promotions':'العروض والخصومات',
```

#### D) Routing — حوالي السطر 17192

ابحث عن السطر الكامل:

```js
if (view === 'price-lists') { RW_PriceLists.render(); return; }
```

أضف بعده:

```js
if (view === 'promotions') { RW_Promotions.render(); return; }
```

#### E) Complete Module — بعد:

```js
window.RW_PriceLists = RW_PriceLists;
```

أضف **كامل** المحتوى الموجود في:

`doc/Draft/Reprots/PROMOTION_OWNER_SURGICAL_PATCH_20260914.js`

وبالتحديد الجزء الممتد من:

```js
var RW_Promotions = (function () {
```

حتى:

```js
window.RW_Promotions = RW_Promotions;
```

ويُوضع قبل Separator:

```text
// ============================================================
// EVENTS & BOOT
// ============================================================
```

لا تحذف أو تعدل `RW_PriceLists`.
لا تعيد نسخ Quotes.
لا تعدل `Current/PWA/main2`.

---

# 12) Owner UI Capability Included

الـOwner module ليس Skeleton.

يتضمن:

- Promotion listing
- KPI summary
- Create
- Update
- Active / Inactive
- Detail
- Rule editor
- Scope selection
- Quantity trigger
- Reward type
- Coupon code
- Channel
- Validity
- Priority
- Automatic / Code trigger
- Auto refresh
- Error state
- Empty state

والـUI يتصل فعليًا بالـProduction Edge capability.

---

# 13) ما تم تفاديه عمدًا

لم يتم:

- تعديل `main.html` مباشرة.
- تعديل `Current/PWA/main2`.
- إعادة فتح Quote backend.
- ربط Promotion مباشرة بحركة Physical Stock.
- تعديل `items.sales_price`.
- اختراع جدول Coupons مستقل رغم وجود الحاجة إلى Coupon behavior؛ تم احتواء ذلك داخل Promotion عبر `trigger_mode='code'` و`coupon_code`.
- إنشاء بيانات اختبار دائمة.

---

# 14) أخطاء وتعثرات التنفيذ

## 14.1 محاولة أولى لإنشاء Operation Registry منفصل
تم إنشاء `promotion_operations` أثناء استكشاف طريقة idempotency.

اتضح أنه غير مطلوب، لأن:

`promotions.operation_id`

مع Unique Index يحقق الهوية المطلوبة أبسط وبعلاقة مباشرة مع Business Object نفسه.

لذلك تم حذف `promotion_operations` من Production وعدم تركه كـdead infrastructure.

هذا إصلاح مقصود لمنع Governance residue.

## 14.2 أول Resolver كان يحتاج Hardening
تم كشف Rule matching gap قبل الإغلاق.

تم إصلاحه في Production وتسجيل الـcanonical migration.

## 14.3 بعض DDL batches رفضتها أداة التنفيذ
تم تفكيك العملية إلى migrations منفصلة بدل إعادة المحاولة الأعمى.

لم يتم تجاوز الحواجز بطريقة تنتج حالة غير قابلة لإعادة البناء.

---

# 15) Current Production Data State بعد التنفيذ

تم التحقق من عدم ترك بيانات Promotion test دائمة:

`promotions = 0`

`promotion_rules = 0`

ولا توجد حاجة إلى Data Repair في هذه الدورة لأن المحرك جديد ولم يتم المساس بسجلات تشغيلية قائمة.

---

# 16) What Is Proven

- Current frontend HEAD = `2ad8da...`
- Direct parent = `edf602...`
- Source of Truth = `erp-frontend/companies/company-1/main.html`
- Price List current integration موجودة في current main.html
- Promotion DB schema deployed
- Promotion security deployed
- Promotion Resolver deployed
- Promotion Redemption deployed
- Promotion Edge v2 ACTIVE
- JWT validation active
- Tenant context comes from authenticated user
- Resolver transactional test PASS
- Redemption retry test PASS
- Test data rolled back
- `promotion_operations` residue removed
- Canonical Git migration files created
- Canonical Edge source created
- Owner surgical patch created
- No Physical Stock writer introduced

---

# 17) What Is NOT Proven Yet

هذه النقاط تمنع Full Closure النهائي ولا يجوز تزويرها:

1. Owner merge داخل `erp-frontend/companies/company-1/main.html` لم يتم تنفيذه من المالك.
2. Browser click-by-click E2E لم يتم تشغيله بأداة Browser فعلية في هذه البيئة.
3. لم يتم إثبات authenticated browser runtime call من داخل المتصفح إلى `promotion-engine`.
4. Promotion consumer wiring داخل POS / Telesales / Order Taker / Van Sales / Online Store لم يُغلق في هذه Closure.
5. لا تزال هناك حاجة إلى ربط النتيجة التجارية قبل تثبيت `order_details.unit_price` في Consumer Closure مستقلة.

وعليه:

`PROMOTION ENGINE BACKEND = PRODUCTION DEPLOYED`

لكن:

`PROMOTION FULL BUSINESS CAPABILITY = OPEN`

بسبب Owner Merge + Browser E2E + Consumer Integration.

---

# 18) هل تحقق الهدف الأصلي الخاص بالاكتمال؟

**لا، ليس بالكامل بعد.**

والسبب ليس نقصًا في backend foundation، بل لأن Business Capability الكاملة تعني:

`UI + Edge + RPC + DB + Auth + Tenant + Rule Engine + Retry + Audit + Consumer + Browser E2E + Production Verification`

وهذه السلسلة لم تُغلق في جزء الـConsumer والـBrowser حتى الآن.

ولا يوجد في هذه الدورة أي أساس صحيح للقول إن النظام صار مكتملًا بالكامل.

---

# 19) SELF-AUDIT

## What I Initially Missed

في بداية العمل كان يمكن الاكتفاء ببناء جداول وعرض API، لكن ذلك كان سيترك Skeleton Engine.

تم تصحيح الاتجاه بإضافة:

- Rule matching hardening
- Redemption identity
- Coupon mode
- Customer scope
- Branch scope
- Channel scope
- Usage limits
- Idempotency
- Audit
- Owner UI
- Production deployment

## What Could Still Be Wrong

- Browser owner merge قد يكشف integration defect في DOM أو routing.
- Consumer modules لم تدخل Promotion Engine بعد.
- بعض الحسابات التجارية المتقدمة جدًا ليست جزءًا من هذه النسخة الأولى، مثل budgeted campaign allocation أو promotion-funded supplier reimbursement؛ لا ينبغي اختراعها قبل إثبات حاجة RAWAEA.

## Final Confidence

`BACKEND HIGH`

`FULL BUSINESS CAPABILITY NOT CLOSED`

---

# 20) GLOBAL INVENTORY / PROMOTION RELATION

هذه الدورة لم تغيّر عقد المخزون.

الـPromotion Engine لا يكتب Physical Stock مباشرة.

وعند استخدام Buy X Get Y، الـfree item يظهر كـCommercial Reward يجب على Consumer المستقبلي تحويله إلى Document Line بالشروط المعتمدة في المستند قبل الـposting.

لا يجوز أن يتحول Promotion Resolver إلى Physical Inventory Engine.

---

# 21) NEXT EXACT RESUMPTION POINT

الخطوة التالية ليست إعادة بناء Promotion backend.

الخطوة التالية هي:

```text
CURRENT FRONTEND HEAD
↓
VERIFY OWNER MERGE OF PROMOTION PATCH
↓
BROWSER E2E: LOGIN -> SALES -> PROMOTIONS
↓
CREATE PROMOTION
↓
ADD RULE
↓
ACTIVATE
↓
RESOLVE TEST CART
↓
CHECK NETWORK
↓
CHECK CONSOLE
↓
CHECK PRODUCTION DB
↓
THEN CREATE PROMOTION CONSUMER CLOSURE
```

ولا تعيد إنشاء الجداول أو RPCs التي ثبت نشرها هنا إلا إذا ظهر contradictory CURRENT evidence.

---

# 22) تعليمات للمساعد القادم — ابدأ من الحقيقة وليس من التقارير

عند فتح جلسة جديدة نفذ هذا الترتيب حرفيًا:

```text
1. CURRENT FRONTEND GIT HEAD
2. DIRECT PARENT
3. CURRENT main.html BLOB/SHA
4. CURRENT main.html anchors around Price Lists / Promotions
5. CURRENT PRODUCTION TABLES
6. CURRENT RLS
7. CURRENT RPC DEFINITIONS
8. CURRENT Edge Function version
9. CURRENT deployment metadata
10. CURRENT runtime evidence
11. CURRENT Production counts
12. OWNER PATCH FILE
13. ONLY THEN browser E2E
```

### قاعدة البحث

لا تقل:

`Report says it is done.`

بل اسأل:

```text
Where is the current code?
Where is the current deployment?
What is the current DB definition?
What is the current runtime result?
What is the current consumer?
```

### قاعدة الاستكمال

إذا كان الشيء موجودًا ومثبتًا:

`DO NOT REBUILD`

إذا كان موجودًا لكن ناقصًا:

`IDENTIFY EXACT GAP -> SURGICAL FIX`

إذا كان تقريرًا فقط:

`VERIFY FROM PRIMARY SOURCE`

إذا كان Owner change:

`READ CURRENT main.html -> GIVE EXACT COMPLETE CHANGESET`

إذا كان Production change:

`EXECUTE -> VERIFY -> DOCUMENT`

إذا ظهر Unknown:

`SEARCH -> CROSS CHECK -> CLASSIFY -> CONTINUE`

ولا تتوقف لأن هناك Unknown واحدًا إذا كانت هناك أعمال مستقلة قابلة للتنفيذ.

### القاعدة النهائية

```text
COMMIT != DEPLOYMENT
DEPLOYMENT != RUNTIME
RUNTIME != PRODUCTION VERIFIED
PRODUCTION VERIFIED != FULLY CLOSED
```

ولا يكتب المساعد `FULLY CLOSED` إلا بعد اجتياز كل هذه الطبقات معًا.

---

# 23) FINAL STATUS

```text
PROMOTION DB CORE             = PRODUCTION DEPLOYED
PROMOTION RULE ENGINE         = PRODUCTION DEPLOYED
PROMOTION REDEMPTION          = PRODUCTION DEPLOYED
PROMOTION SECURITY            = VERIFIED
PROMOTION IDEMPOTENCY         = VERIFIED TRANSACTIONALLY
PROMOTION EDGE                = ACTIVE v2
PROMOTION OWNER UI            = SURGICAL PATCH READY
PROMOTION BROWSER E2E         = OPEN
PROMOTION CONSUMER WIRING     = OPEN
PROMOTION FULL BUSINESS       = OPEN
```

العمل لم يتوقف عند Analysis، وتم تنفيذ البنية الأساسية والـProduction capability كاملة من ناحية Backend، بينما بقيت نقاط الإغلاق التي تتطلب Owner merge وBrowser runtime وConsumer integration مفتوحة كما يقتضي معيار الإغلاق الحقيقي.

# END OF REPORT 168
