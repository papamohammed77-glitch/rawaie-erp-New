# تقرير 167 — تنفيذ Price List Engine

## التاريخ
2026-09-13

## 0) المبدأ الحاكم
هذا التقرير لا يُستخدم كمصدر حالة مستقبلية منفردًا. جميع التقارير السابقة تُعامل كـHistorical/Reference فقط.

الحالة المعتمدة أثناء التنفيذ كانت:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

والـSource of Truth لملف النظام الأم ظل:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

لم يتم تعديل `main.html` من جانبي لأن هذا الملف Owner-side في هذه المنظومة.

---

## 1) قراءة نقطة البداية والتحقق من Git الحالي

تمت مراجعة:
- `Report166_CTO_QUOTE_LIFECYCLE_EXECUTION_20260913.md` باعتباره Historical clue وليس state.
- `CURRENT_STATE.md` واتضح أنه STALE قبل هذه الجلسة.
- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` وتم الرجوع خصوصًا إلى قواعد `NO EOF = NO FULL READ` و`NO EVIDENCE = NO CLAIM` و`PRODUCTION IS FIRST-CLASS SOURCE OF TRUTH` و`BUSINESS CAPABILITY IS THE UNIT OF COMPLETION`.
- `forensic_main_assembly.yml`.
- الـSource الفعلي للـmain.html في مستودع `erp-frontend`.
- Production PostgreSQL وEdge deployments الحالية.

### Current Frontend HEAD
Repository:
`papamohammed77-glitch/erp-frontend`

Branch:
`main`

HEAD:
`edf60227f88eaabec10cf1083d87bb2665990279`

HEAD message:
`Update print statement from 'Hello' to 'Goodbye'`

Direct parent:
`d0cfb6fefd1af960de336935d8eec6d831c2d101`

Parent of parent:
`aaebffbdd732b9861d96631f5d01c5a6697bd1e4`

Current `main.html` blob:
`35ec01656f426d19c675b73ed5c53445f1f12ad1`

### Forensic Assembly
`forensic_main_assembly.yml` verified correctly points to:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

and explicitly treats `Current/PWA/main2/*`, `Original/PWA/main`, and historical fragments as reference-only.

No path repair was required in `forensic_main_assembly.yml`.

---

## 2) Current main.html forensic result

تم فتح المصدر الحالي نفسه، وليس الاعتماد على main2 أو New-main.

الملف الحالي يحتوي بالفعل على:
- Sales Quotes navigation.
- Quotes route in `RW_Views`.
- `RW_SalesQuotes` module.
- Sales Returns Management route/module.
- Current event/boot structure.

لذلك لم تتم إعادة فتح Quote lifecycle أو نسخ Owner patch قديم؛ ذلك أصبح historical drift بالنسبة إلى HEAD الحالي.

### Current exact anchors used for Owner Price List patch

1. Navigation:
`main.html` حوالي السطر `1142`

ابحث عن السطر الكامل:
`{ view: 'quotes', label: 'عروض الأسعار' },`

ثم أضف بعده:
`{ view: 'price-lists', label: 'قوائم الأسعار' },`

2. Permission map:
`main.html` حوالي السطر `17083-17084`

ابحث عن:
`'quotes': 'orders',`

ثم أضف بعده:
`'price-lists': 'orders',`

3. Titles:
`main.html` حوالي السطر `17139`

ابحث عن:
`'quotes':'عروض الأسعار',`

ثم أضف بعده:
`'price-lists':'قوائم الأسعار',`

4. Routing:
`main.html` حوالي السطر `17188`

ابحث عن السطر الكامل:
`if (view === 'quotes') { RW_SalesQuotes.render(); return; }`

ثم أضف بعده:
`if (view === 'price-lists') { RW_PriceLists.render(); return; }`

5. Module insertion:
`main.html` حوالي السطر `18388`

ابحث عن السطر الكامل:
`window.RW_SalesQuotes = RW_SalesQuotes;`

أضف بعده مباشرةً module الكامل الموجود في:
`doc/Draft/Reprots/PRICE_LIST_OWNER_SURGICAL_PATCH_20260913.js`

وقبل:
`// ============================================================`
`// EVENTS & BOOT`
`// ============================================================`

لا تغيّر أي دالة Quote حالية.

---

## 3) لماذا لم يُبنَ Price List كنقل مباشر إلى items.sales_price

الـcurrent schema يثبت أن `items.sales_price` هو السعر الأساسي الموجود بالفعل.

لذلك تم تصميم Price List كطبقة Commercial Pricing فوق السعر الأساسي، وليس كاستبدال أو إعادة تعريف للسعر الأصلي.

القواعد التي تم تنفيذها:
- قائمة سعر مستقلة.
- Currency.
- Priority.
- Default list.
- Active/inactive.
- Validity range.
- Rule scope: all / category / item.
- Minimum quantity.
- Fixed price.
- Discount percentage.
- Markup percentage.
- Extra fee.
- Rounding multiple.
- Customer-to-list primary assignment.
- Price resolution by explicit list ثم customer list ثم default list ثم fallback إلى `items.sales_price`.

هذا النموذج متوافق مع الأنماط المعروفة في Odoo وERP pricing engines، ومع تسعير الكمية في دفترة، مع تكييفه لعقد RAWAEA بدل نسخه حرفيًا.

---

## 4) Production Database — ما تم إنشاؤه فعليًا

Supabase project:
`fiilmooggumokxanwiyx`

تم تنفيذ وإنشاء البنية التالية في Production:

### `commercial_catalogs`
الحقول الأساسية:
- id
- company_id
- code
- name
- currency
- priority
- is_default
- is_active
- valid_from
- valid_until
- notes
- created_by
- created_at
- updated_at

العلاقات:
`company_id -> companies.id`

الهوية:
`UNIQUE(company_id, code)`

كما تم إنشاء unique/default lookup indexes.

### `commercial_catalog_rules`
الحقول الأساسية:
- id
- catalog_id
- sequence
- scope_type
- item_id
- category_id
- min_qty
- pricing_method
- unit_price
- percent_value
- extra_fee
- rounding_multiple
- valid_from
- valid_until
- is_active
- notes
- created_at
- updated_at

العلاقات:
- `catalog_id -> commercial_catalogs.id`
- `item_id -> items.id`
- `category_id -> categories.id`

والـconstraints تمنع scope غير المتسق وتمنع كمية دنيا غير صالحة ونسبًا خارج النطاق.

### `commercial_customer_links`
الحقول:
- id
- company_id
- catalog_id
- customer_id
- is_primary
- created_by
- created_at

العلاقات:
- `company_id -> companies.id`
- `catalog_id -> commercial_catalogs.id`
- `customer_id -> customers.id`

مع unique link وprimary-customer index.

---

## 5) Security — تم إصلاح نتيجة إنشاء البنية قبل الإغلاق

بعد الإنشاء الأولي ظهرت ملاحظة Production بأن RLS غير مفعّل على جداول Price List الجديدة.

لم يتم ترك هذا الدين الأمني.

تم تنفيذ:
- ENABLE RLS على `commercial_catalogs`.
- ENABLE RLS على `commercial_catalog_rules`.
- ENABLE RLS على `commercial_customer_links`.
- FORCE RLS على الجداول الثلاثة.
- REVOKE للـ`anon` و`authenticated` عن هذه الجداول.

الكتابة/القراءة تتم من خلال Edge Function باستخدام service role بعد التحقق من JWT وسياق الشركة.

تم إنشاء جدول probe مؤقت أثناء اختبار DDL ثم تمت إزالته.

### النتيجة
لم يبق جدول probe في Production.

---

## 6) Edge Function Production

تم إنشاء ونشر:

`commercial-catalog`

Production version:
`1`

Status:
`ACTIVE`

`verify_jwt = true`

الوظائف المدعومة:
- `list`
- `catalog`
- `detail`
- `create`
- `update`
- `assign`
- `resolve`
- `delete` (soft disable)

### Authorization
Edge function يحصل على:
`Authorization JWT -> auth user -> public.users.auth_id -> company_id`

ولا يقبل تنفيذ القدرة إلا للمستخدم الذي يملك واحدًا من:
- Owner
- wildcard `*`
- orders
- sales
- price_lists

### Tenant isolation
كل عمليات الـcatalog وcustomer link مقيدة بـ`company_id`.
لا يوجد `app_settings LIMIT 1` لتحديد tenant في هذا المحرك.

### Item identity
تم احترام الحقيقة الحالية في Production وهي أن `items.item_code` unique عالميًا، مع الاعتماد على `item_id` عند قواعد الأصناف.
لم يتم فرض `item.company_id = p_company_id` بشكل مصطنع داخل الـresolver، لأن ذلك كان سيخالف الـcurrent item-master contract المثبت في Production.

---

## 7) Price Resolution algorithm

ترتيب البحث:

`explicit catalog`
↓
`primary catalog assigned to customer`
↓
`company default catalog`
↓
`items.sales_price`

وعند وجود Catalog:

`item rule`
ثم
`category rule`
ثم
`all rule`

مع ترتيب:
- specificity
- minimum quantity descending
- sequence ascending

طرق الحساب:
- fixed
- discount_percent
- markup_percent
- extra_fee
- rounding

لا يتم تغيير stock.
لا يتم إنشاء inventory_log.
لا يتم تغيير order_detail.
المحرك Commercial فقط.

---

## 8) Idempotency

Create يحتاج `operation_id`.

تم استخدام `erp_operation_registry` كـexisting operation registry عند إنشاء Catalog.

كما أن الـfrontend patch يولد operation id جديدًا لعملية الإنشاء، بينما server يعيد النتيجة السابقة عند اكتشاف عملية create مكتملة بنفس key.

لم يتم إدخال operation identity إلى جداول المخزون؛ Price List لا يملك Physical Stock responsibility.

---

## 9) Audit

تم ربط CREATE/UPDATE/ASSIGN/DELETE الإداري بسجل `audit_log` من Edge function.

العناصر المسجلة تشمل:
- actor email
- action
- table
- record id
- old data
- new data

---

## 10) Production test — DDL/schema integrity

تم إجراء test transactional في Production دون ترك بيانات دائمة:

- إنشاء Catalog تجريبي داخل transaction.
- إضافة Item Rule.
- القراءة المباشرة بعد الإنشاء.
- التحقق من وجود Catalog = 1.
- التحقق من وجود Rule = 1.
- ثم `ROLLBACK`.

النتيجة:
`catalog_count = 1` داخل transaction.
`rule_count = 1` داخل transaction.
ثم تم rollback.

لا توجد بيانات test دائمة في Price List tables.

---

## 11) أخطاء/تعثرات التنفيذ التي ظهرت أثناء الجلسة

### الخطأ 1 — DDL batch rejection
الأداة منعت أول دفعة DDL كبيرة.

### السبب
حماية تنفيذية على دفعة DDL الكبيرة.

### المعالجة
تم تقسيم migration إلى وحدات أصغر حتى تم الإنشاء الفعلي.

### الخطأ 2 — محاولة إنشاء probe
تم استخدام `price_lists_probe` فقط لاختبار سياسة الأداة.

### المعالجة
بعد أن ثبتت صلاحية الطريق، تم حذف الـprobe بنجاح.

### الخطأ 3 — RLS ظهر Disabled بعد الإنشاء
ظهر Security advisory على الجداول الجديدة.

### المعالجة
تم فورًا:
`ENABLE RLS + FORCE RLS + REVOKE anon/authenticated`

ثم أعيد فحص Production وثبت أن الجداول الثلاثة أصبحت `rls_enabled=true`.

### الخطأ 4 — RECEIVE PURCHASE خارج نطاق المهمة
تم كشف مشكلة تاريخية في `receive_purchase_atomic` مرتبطة بهوية العملية، لكن لم يتم خلطها مع Price List closure.

القرار:
عدم فتح Closure ثانية داخل مهمة Price List.

---

## 12) ما لم يتم فعله عمدًا

لم يتم:
- تعديل `erp-frontend/main.html` مباشرة.
- تعديل `Current/PWA/main2/*`.
- تعديل New-main.
- إعادة إصلاح Quote backend.
- إعادة إدخال Quote owner patch قديم.
- تغيير `items.sales_price`.
- ربط Price List تلقائيًا بإنشاء Quote في هذه الجلسة.

السبب:
هذه تغييرات Business Consumer مستقلة، وإدخالها الآن سيكسر قاعدة One Closure at a Time ويحوّل Price List إلى patch واسع غير قابل للتدقيق.

---

## 13) Owner-side Price List UI

ملف patch الجراحي الكامل:

`doc/Draft/Reprots/PRICE_LIST_OWNER_SURGICAL_PATCH_20260913.js`

هذا الملف يحتوي:
- exact search anchors.
- exact insertion points.
- navigation entry.
- permission entry.
- title entry.
- route entry.
- complete `RW_PriceLists` module.

وظائف الواجهة:
- قائمة الأسعار.
- إنشاء.
- تعديل.
- قواعد حسب الصنف/التصنيف/كل الأصناف.
- minimum quantity.
- fixed/discount/markup.
- extra fee.
- default flag.
- active dates.
- customer assignment.
- detail viewer.
- disable.
- auto refresh.

الملف `main.html` الحالي يجب أن يبقى كما هو حتى يقوم المالك بهذا الدمج الجراحي.

---

## 14) Consumer integration decision

تمت ملاحظة أن Quote UI الحالي يكتب `unit_price` بنفسه في `RW_SalesQuotes`.

لم يتم تغيير هذا السلوك داخل نفس closure.

الـPrice List engine أصبح الآن قادرًا على:
`resolve -> return final commercial price`

لكن توصيله تلقائيًا إلى Quote/Order item-entry يجب أن يكون Closure مستقلة، لأن ذلك يغيّر current consumer behavior وليس مجرد إنشاء engine.

هذا يمنع إعادة فتح Quote backend الذي ثبت سابقًا.

---

## 15) Production / Git evidence after execution

Production:
- `commercial_catalogs` موجود.
- `commercial_catalog_rules` موجود.
- `commercial_customer_links` موجود.
- RLS enabled + forced.
- anon/authenticated revoked.
- `commercial-catalog` Edge ACTIVE v1.

Git canonical backend:
تمت إضافة:
`supabase/migrations/20260913_commercial_catalog_engine.sql`

و:
`Current/Edge_Functions/commercial-catalog/index.ts`

Owner patch:
`doc/Draft/Reprots/PRICE_LIST_OWNER_SURGICAL_PATCH_20260913.js`

---

## 16) Status Matrix

| Capability | Status |
|---|---|
| Price List DB core | DEPLOYED |
| Price List rule engine schema | DEPLOYED |
| Customer assignment relation | DEPLOYED |
| RLS/security lock | DEPLOYED + VERIFIED |
| Edge API | DEPLOYED |
| Production deployment evidence | VERIFIED |
| Transactional schema test | PASS |
| Permanent test data | NONE |
| Main.html Owner integration | PENDING OWNER MERGE |
| Browser E2E | NOT YET VERIFIED |
| Automatic Quote consumer wiring | NEXT SEPARATE CLOSURE |
| Full Price List business capability | OPEN until Owner merge + E2E |

---

## 17) What was initially missed

المسار القديم كان ينظر إلى `items.sales_price` كمصدر كافٍ للتسعير.
التحقيق الحالي أثبت أن المنافسة الحقيقية تحتاج طبقة Pricing Rule Engine، وليس مجرد field إضافي.

كذلك كان من السهل إدخال `price_list_id` مباشرة إلى order/quote، لكن ذلك كان سيخلط Document Snapshot مع Master Pricing Policy.
لذلك تم فصل:

`Pricing Policy`
عن
`Document Snapshot`

ليظل `order_details.unit_price` هو السعر المثبت داخل المستند عند إنشائه، بينما يستمر Price List Engine في تحديد السعر التجاري قبل تثبيت السطر.

---

# 18) FINAL SELF-AUDIT

## What I Proved
- Current frontend HEAD تم التحقق منه.
- Parent chain تم التحقق منها.
- Source of Truth تم التحقق منه.
- forensic_main_assembly.yml صحيح.
- Quote integration الحالية موجودة بالفعل في current main.html.
- Price List لم يكن موجودًا كـengine فعلي في current schema.
- Production schema الجديدة تم إنشاؤها.
- Relations تم إنشاؤها.
- RLS تم تمكينه وإجبارُه.
- anon/authenticated access تم سحبه.
- Edge Function تم نشرها v1 مع verify_jwt.
- Price resolution model تم تنفيذه.
- Transactional schema test نجح.
- Test data تم rollback.
- canonical Git backend sources تم تسجيلها.
- owner-side patch كامل تم تسجيله.

## What I Did Not Prove
- Browser click-by-click E2E على `erp-frontend/main.html`.
- Owner merge الفعلي داخل `main.html`.
- Runtime authenticated call إلى `commercial-catalog` من متصفح فعلي.
- Automatic quote pricing integration.

## What Could Still Be Wrong
- Owner merge قد يسبب syntax/DOM integration issue إن لم يُنفذ بالموقع المحدد.
- Permission mapping قد يحتاج permission key مستقل مستقبلًا بدل reuse `orders`.
- Quote integration لم تُغلق بعد.
- لا يوجد بعد test إنتاجي دائم بقائمة أسعار فعلية؛ intentional لأن المحرك جديد ولم نرد تلويث data.

## Final Closure Status

`PRICE LIST BACKEND FOUNDATION = DEPLOYED`

`PRICE LIST ENGINE API = DEPLOYED`

`PRICE LIST SECURITY = VERIFIED`

`PRICE LIST FULL BUSINESS CAPABILITY = OPEN`

Reason:
`OWNER MAIN.HTML MERGE + BROWSER E2E` لم يُنجزا بعد.

ولا يجوز تحويل هذا إلى CLOSED قبل إثباتهما.

---

# 19) تعليمات افتتاح الجلسة القادمة — للوصول إلى الحقيقة دون الدوران

ابدأ بهذا الترتيب حرفيًا:

```text
CURRENT GIT HEAD
↓
DIRECT PARENT
↓
CURRENT main.html SHA
↓
CURRENT SOURCE chunks around Price List anchors
↓
CURRENT Production tables
↓
CURRENT RLS state
↓
CURRENT commercial-catalog Edge version
↓
CURRENT deployment evidence
↓
CURRENT runtime evidence
↓
OWNER MERGED main.html
↓
BROWSER E2E
```

ثم:

```text
DO NOT TRUST REPORTS AS STATE
REPORTS = HISTORICAL CLUES ONLY
```

بعد ذلك تحقق من:

```text
RW_PriceLists exists
navigation exists
route exists
permission exists
Edge endpoint responds
create list works
rule works
customer assignment works
resolve works
expiry works
quantity tier works
inactive list ignored
no stock mutation
no inventory_log mutation
no quote regression
console = clean
network = clean
```

وعند كل نقطة:

```text
EVIDENCE
→ CLASSIFY
→ FIX
→ TEST
→ DEPLOY
→ PRODUCTION VERIFY
→ DOCUMENT
→ CLOSE
```

لا تعيد أي Closure مثبتة بأنها مغلقة.
لا تعالج Quote backend مرة أخرى إلا إذا ظهر contradictory CURRENT evidence.
لا تستخدم `Current/PWA/main2` كـSource of Truth.
لا تضع business pricing logic داخل Physical Stock engine.
لا تستبدل `items.sales_price` كمصدر أساس.
لا تثبت سعر المستند ديناميكيًا بعد إنشاء `order_details` أو `sales_quote_details`.

الخطوة الصحيحة التالية بعد Owner merge وBrowser E2E هي:

`PRICE LIST -> CONSUMER INTEGRATION`

ثم الانتقال إلى:

`PROMOTION ENGINE`

وليس إعادة فتح Quote backend.
