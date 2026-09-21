# تقرير 285 — الأذونات المخزنية / التكامل مع Van Sales
## CURRENT-REALITY FORENSIC REGRESSION & SURGICAL CLOSURE
### 2026-09-21

---

## 0. نطاق المهمة

النطاق الوحيد لهذه الجلسة:

- إدارة المخازن والمخزون → الأذونات المخزنية.
- التطبيق المستقل:
  `companies/company-1/warehouse/vouchers.html`
- التكامل مع:
  `companies/company-1/sales/van-sales.html`
- التكامل مع النظام الأم `companies/company-1/main.html` دون تعديله.
- مطابقة Production الحالية في Supabase.
- مطابقة آخر Git وParent.
- تحديد ما تم إغلاقه سابقًا وما استحدثته آخر تعديلات Mother.
- عدم إعادة إصلاح أي Closure سبق إغلاقه.
- إنتاج Patch جراحي Owner-only للتطبيق المستقل.
- عدم إنشاء Edge Function جديدة.
- عدم تعديل `main.html`.
- عدم تعديل `vouchers.html` مباشرة من هذه الجلسة.

قاعدة الحقيقة:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

التقارير السابقة استُخدمت كـhistorical trail فقط.

---

# 1. GOVERNANCE RECOVERY

تمت إعادة قراءة:

`doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`

- SHA: `b03feec14a417ca9032d714774f2687b4542a373`
- عدد الأسطر: 2606
- تمت القراءة حتى EOF.

أهم القواعد المطبقة في هذه الجلسة:

- الدراسة قبل التعديل.
- Reports ليست Current State.
- Production مصدر حقيقة من الدرجة الأولى.
- لا Assumptions.
- لا إعادة فتح Closure مغلق دون Regression جديد.
- كل Defect يجب أن يُربط بـRoot Cause قابل للإثبات.
- لا Skeleton Completion.
- لا Half Fix.
- لا New Debt.
- لا New Edge Function إذا كان هناك RPC/Capability قائم صالح.
- Browser/Production closure لا يُعلن دون الدليل الفعلي.

---

# 2. CURRENT GIT — SYSTEM REPOSITORY

Repository:

`papamohammed77-glitch/rawaie-erp-New`

آخر System HEAD قبل هذا التقرير:

`90388a19464e0a8ac935b5189b670fc697289766`

Message:

`state: record Report284 vouchers canonical integration checkpoint`

Immediate parent:

`141c526186d5a3031666ea2986c24da038b25120`

Parent message:

`fix: record canonical mobile branch guard migration`

Relevant prior closure:

`d1c9f8de55b33a02d1ea6734b19db9d1c9fa2031`

والذي أغلق Production mobile-branch / DirectReturn defects.

---

# 3. CURRENT REPORT TRAIL

آخر تقارير نطاق الأذونات التي جرى العثور عليها في:

`doc/Draft/Reprots`

هي:

- Report282 — Vouchers ↔ Van Sales integration.
- Report283 — Mobile Branch / DirectReturn forensic closure.
- Report284 — Canonical integration forensic closure.

تمت قراءة Report282 وReport283 وReport284 حتى EOF.

النتيجة التاريخية المشتركة بينها:

- Physical Stock centralization مغلقة.
- DirectSale backend مغلق.
- DirectReturn backend مغلق.
- RECEIVE idempotency مغلقة.
- VanSales mobile branch / driver guard مغلقة.
- لا حاجة إلى Edge Function جديدة.
- owner UI patches كانت المفتوحة سابقًا.

لكن هذه التقارير أصبحت الآن **أقدم من Current Source** لأن Mother/Target source تحرك بعد ذلك.

---

# 4. CURRENT SOURCE — TARGET

## 4.1 Vouchers

Repository:

`papamohammed77-glitch/erp-frontend`

File:

`companies/company-1/warehouse/vouchers.html`

CURRENT blob:

`8d7fd4375376de11200836c2fe76f98d27ac7c53`

الحجم:

84952 bytes

عدد الأسطر:

1321

هذا الـblob هو المصدر الحالي الفعلي الذي بُني عليه التحقيق.

---

## 4.2 Van Sales

File:

`companies/company-1/sales/van-sales.html`

CURRENT blob:

`a914c3e268c8801533051a3f0901c0db5919ee64`

لا يوجد Regression مثبت في Van Sales في هذه الجلسة.

تمت المحافظة على الإصلاحات السابقة:

- authenticated driver context.
- mobile branch resolution عبر `setup-van-branch`.
- retry operation identity.
- VanSale central stock path.
- عدم إنشاء physical movement engine ثانٍ.

لا يوجد سبب حالي لإعادة تعديل Van Sales.

---

## 4.3 Mother main.html

File:

`companies/company-1/main.html`

CURRENT blob:

`f7bec336bcdebb00bdfb2ce95a07e55919c03dae`

الحجم:

1805015 bytes

عدد الأسطر:

1 بسبب minification.

تمت مراجعته دون تعديل.

ولم يظهر في النص الحالي route literal مباشر باسم:

- `vouchers.html`
- `warehouse/vouchers`
- `الأذونات المخزنية`
- `activeWarehouseRole`

وهذا يعني أن الربط الأم ليس في هذا الملف بصيغة literal بسيطة يمكن افتراضها.

الاستنتاج:

**لا توجد مبررات لتعديل Mother في هذه الجلسة.**

---

# 5. LATEST MOTHER COMMITS — REGRESSION SOURCE

Current Mother HEAD:

`7efa2dfe17ddd10cc410d3887cc9876d630aa319`

Parent:

`7375e75d562b4743f435fd26db60402a5a23e293`

ومن parent:

`e0769499509ab3cd919d62b46e93529e13c992b7`

Commit `7375...` سبق أن غيّر Van Sales operation identity من unverified company state إلى authenticated driver identity، وهو Closure سابق ولا يُعاد فتحه.

أما HEAD `7efa...` فقد حمل في نفس التغيير تعديل `vouchers.html` وأضاف نسخة جديدة من `cards:function`.

هذا التعديل هو الذي ترك بقايا النسخة السابقة في المصدر الحالي.

---

# 6. ROOT CAUSE — VOUCHERS PARSER

## 6.1 الخطأ المثبت

المصدر الحالي يحتوي:

- `cards:function(rows,scope){...``
- وتنتهي الدالة الجديدة فعليًا عند السطر 415 بـ `},`

ثم توجد مباشرة بعدها نسخة قديمة مستقلة من:

`rows.map(function(v){...`).join('')},`

وهذه النسخة ليست داخل أي property صحيح في object.

### الاختبار الجنائي

تم استخراج JavaScript الرئيسي من المصدر الحالي وتشغيل parser عليه.

### النتيجة قبل التعديل

`SyntaxError: Unexpected token '.'`

### التعديل الافتراضي داخل الذاكرة

تم حذف **السطر 416 فقط** دون أي تعديل آخر.

### النتيجة بعد حذف السطر

JavaScript parse = PASS.

لا توجد حاجة إلى:

- إعادة بناء `cards`.
- إعادة إضافة `send`.
- إعادة إضافة `cancel`.
- إعادة إضافة `complete`.
- إعادة إضافة `summary`.
- إعادة إضافة `receive`.

كل هذه موجودة أصلًا في Current Source.

---

# 7. OWNER PATCH 1 — حذف البقايا النحوية فقط

## الملف المطلوب تعديله

`companies/company-1/warehouse/vouchers.html`

## ابحث عن

**السطر 416**

وابحث بالنص المميز التالي:

`rows.map(function(v){var c=v.status==='Draft'?'bg-amber-100 text-amber-700'...`

وهو السطر القديم الكامل الذي يبدأ:

`rows.map(function(v){var c=v.status==='Draft'...`

وينتهي:

`}).join('')},`

### الإجراء

**احذف السطر 416 كاملًا فقط.**

### مهم

لا تحذف:

`cards:function(rows,scope){`

ولا تحذف محتوى `cards` الحالي.

لا يوجد Replacement لأن الدالة الحالية عند السطر 265 مكتملة بالفعل.

### سبب عدم وجود Replacement

السطر 416 ليس جزءًا وظيفيًا ناقصًا.

هو Duplicate orphaned code.

إزالته هي الـsurgical fix الصحيح.

---

# 8. APP UNDEFINED ROOT CAUSE

الخطأ:

`vouchers:12 Uncaught ReferenceError: App is not defined`

ليس Defect مستقلًا في `App`.

السبب:

1. parser توقف عند السطر 416.
2. تنفيذ script توقف.
3. object:
   `var App={...}`
   لم يُنشأ.
4. أزرار HTML التي تستدعي:
   - `App.togglePass()`
   - `App.doLogin()`
   - `App.send()`
   - `App.receive()`
   - `App.complete()`
   - `App.details()`
   أصبحت تشير إلى object غير موجود.

إذن:

**إصلاح parser يغلق App undefined تلقائيًا.**

لا يوجد مبرر لإضافة App جديد أو إعادة كتابة object.

---

# 9. OWNER PATCH 2 — Service Worker 404

## الخطأ المرصود

`Failed to register a ServiceWorker...`

ومع المسار:

`/companies/company-1/warehouse/sw.js`

## Current Source reconstruction

في `vouchers.html` يوجد في نهاية script:

`RW_SW.register('../sw.js');`

والـpage نفسها لا تحتوي:

`warehouse/sw.js`

كما أن:

`companies/company-1/register-sw.js`

يحتوي coordinator يستثني صراحة:

`/vouchers.html`

من registration.

كما أن Current source لا يحتوي `companies/company-1/warehouse/sw.js`.

### الإجراء

في نفس الملف:

`companies/company-1/warehouse/vouchers.html`

ابحث تحديدًا عن:

`RW_SW.register('../sw.js');`

### احذف هذا الاستدعاء كاملًا فقط.

لا تضف:

- `warehouse/sw.js`
- Service Worker جديد.
- Edge Function جديدة.
- redirect للـSW.

### السبب

الحالة الصحيحة للتطبيق الحالي هي ألا يحاول تسجيل Service Worker من هذا التطبيق عندما لا يوجد worker canonical في هذا المسار.

كما أن إضافة Worker جديد ستكون Architecture change غير مثبتة وقد تعيد فتح مشكلة Cache/Scope بدل حلها.

---

# 10. TAILWIND WARNING

Current source يحتوي:

`<script src="https://cdn.tailwindcss.com"></script>`

والتحذير:

`cdn.tailwindcss.com should not be used in production`

هذا **تحذير Build/Delivery وليس سبب فشل التطبيق**.

لا يمكن إزالته بأمان دون:

- إنشاء compiled CSS artifact.
- تعديل الصفحة لتقرأ CSS artifact.
- اختبار كل utility class المستخدمة فعليًا.
- التأكد من عدم تغيير الـvisual contract.

وبما أن هذه الجلسة محكومة بعدم تعديل `vouchers.html` مباشرة من CTO وعدم بناء بنية Frontend جديدة، لم يتم إجراء تغيير شكلي/Build غير مثبت.

### الحالة

Tailwind warning = NON-BLOCKING TECH DEBT

ولا يُعامل كـProduction Functional Failure.

---

# 11. LOGIN CONTRACT — نتيجة التحقيق

Current `vouchers.html` يستخدم:

`RW_Auth.doLogin`

و:

`RW_Auth.init`

والـCurrent `core.js` يثبت:

- session recovery.
- `auth_id` / user record.
- `active_warehouse_role`.
- Owner semantics.
- wildcard permissions.
- company/user context.

وفي `vouchers.html`:

`s.user.activeWarehouseRole!=='أذونات'`

هو guard التشغيل.

وفي `app.html`:

`activeWarehouseRole==='أذونات'`

يوجه إلى:

`/companies/company-1/warehouse/vouchers.html`

إذن Login Architecture الحالية **مقصودة ومتكاملة**.

### النتيجة

لا يوجد Authentication redesign مطلوب.

الـLogin error المرصود كان downstream من parser failure.

---

# 12. CURRENT VOUCHERS ROLE — BUSINESS CONTRACT

ثبت من Current Source:

الأنواع:

- Transfer — فرع → فرع.
- DirectSale — فرع → مركبة.
- DirectReturn — مركبة → فرع.
- SupplierReturn — فرع → مورد.
- Scrap — Adjustment Engine.
- Adjustment — Adjustment Engine.

هذا التطبيق مسؤول عن:

**العمليات المخزنية التي لا تعتمد على Order/Runsheet fulfillment lifecycle.**

ولا ينشئ:

- Order.
- Runsheet.
- Picking.
- Loading.
- Delivery.
- Order fulfillment state.

أما DirectSale فهو عهدة Vehicle Mobile Stock قبل البيع، وليس Sales Order.

وبالتالي فصل التطبيق عن أوردر/رانشيت هو قرار معماري صحيح.

---

# 13. CURRENT DATA FLOW

## Manual Voucher

`vouchers.html`

↓

`RW_API.call('create-stock-voucher', ...)`

↓

Edge Function الحالية:

`create-stock-voucher`

↓

RPC الحالي:

`create_manual_stock_voucher_atomic`

↓

Core:

`create_manual_stock_voucher_atomic_core_12_20260828`

↓

`stock_vouchers`
+
`stock_voucher_details`

وفي العمليات:

`send-stock-voucher`

↓

`send_stock_voucher_atomic`

↓

`send_stock_voucher_atomic_core_20260828`

↓

`post_stock_movement`

↓

`stock_branches`

+

`inventory_log`

وفي RECEIVE:

`receive-stock-voucher`

↓

`post_manual_stock_voucher_atomic`

↓

`post_manual_stock_voucher_atomic_core_20260828`

↓

`post_stock_movement`

وفي التفاصيل:

`inventory_control(VOUCHER_AUDIT)`

↓

`stock_vouchers`
+
`stock_voucher_details`
+
`audit_log`
+
`inventory_log`

هذا يثبت أن التطبيق ليس جزيرة مستقلة.

---

# 14. CURRENT PRODUCTION

Supabase project:

`fiilmooggumokxanwiyx`

آخر Production verification:

- companies = 1
- branches = 3
- vehicles = 1
- stock_vouchers = 1
- stock_voucher_details = 3
- stock_voucher_operations = 1
- inventory_log = 3
- audit_log = 2027

Persistent demo voucher:

- `IN-1`
- type = `DirectSale`
- status = `Draft`
- source = `BR-01`
- target = `VEH-TEST-260921`

Persistent test vehicle:

- `VEH-TEST-260921`
- mobile stock = true
- mobile branch = `5372503d-f638-4e7f-808d-bda585825b2f`

لا يوجد دليل على Production drift جديد في هذا closure.

---

# 15. PRODUCTION BACKEND — CURRENT CLOSURE

تمت إعادة فحص definitions الحالية:

## CREATE

`create_manual_stock_voucher_atomic`

يدخل إلى:

`create_manual_stock_voucher_atomic_core_12_20260828`

ومع Current Edge Function v10 يتم تمرير:

- `rep_id`
- `operation_id`

عندما تكون موجودة.

## SEND

`send_stock_voucher_atomic`

يدخل إلى:

`send_stock_voucher_atomic_core_20260828`

ثم:

`post_stock_movement`

## RECEIVE

`post_manual_stock_voucher_atomic`

يدخل إلى core الحركة ثم:

`post_stock_movement`

## Physical writer

Current Production contract:

**Physical Stock Movement = post_stock_movement**

ولا يوجد Physical Stock Engine ثانٍ مطلوب لهذا التبويب.

---

# 16. VAN SALES INTEGRATION

Current `van-sales.html`:

- يحدد Vehicle Mobile Branch من `setup-van-branch`.
- يستخدم operation_id للحفظ/retry.
- يحفظ البيع عبر:
  `save-sales-invoice`
- ثم:
  `save_sales_invoice_atomic`
- ثم:
  `post_stock_movement(VanSale)`

Current Voucher DirectSale:

`Branch → Vehicle`

Current Voucher DirectReturn:

`Vehicle → Branch`

إذن:

**Voucher = stock custody movement**

بينما:

**Van Sales = commercial sale against vehicle stock**

و:

**Order/Runsheet = fulfillment pipeline**

وهذه المسؤوليات لا يجوز دمجها في Engine واحد داخل الواجهة.

---

# 17. COMPETITIVE BENCHMARK

تمت مراجعة المصادر الرسمية الحديثة.

## Odoo

Odoo 19 يثبت:

- inventory adjustment.
- barcode inventory count.
- lots/serial numbers.
- traceability.
- counted vs on-hand.
- difference.
- barcode operations.

مصادر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/count_products.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/product_management/product_tracking/lots.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/product_management/product_tracking/serial_numbers.html

## Microsoft Dynamics 365

يثبت:

- Movement.
- Inventory adjustment.
- Transfer.
- Item arrival.
- Counting.
- Tag counting.
- From/To inventory dimensions.
- issue + receipt semantics في transfer.

مصادر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-tag-counting

## SAP

الـGoods Movement contract يميز:

- Goods Receipt.
- Goods Issue.
- Physical Stock Transfer.
- Transfer Posting.

## Daftra

الموثق لديها يشمل:

- transaction history.
- warehouse / movement reporting.
- stocktaking.
- serial / lot / expiry use cases.
- physical count and discrepancy concepts.

## Manager.io

لم يُستخدم كمصدر عقد في هذه الجلسة لعدم توفر توثيق رسمي حديث بنفس مستوى المصادر السابقة.

---

# 18. COMPETITIVE GAP — WHAT NOT TO INVENT NOW

المزايا التي ثبتت أهميتها في الأنظمة المنافسة:

- Lot.
- Serial.
- Expiry.
- Physical count.
- System count.
- Difference.
- Traceability.
- Rich stocktaking.
- print/export.
- richer approval.
- in-transit transfer.

لكن هذه ليست مجرد fields إضافية داخل voucher.

كل واحدة منها تحتاج:

- Business Contract.
- Schema Contract.
- movement semantics.
- valuation.
- audit.
- reporting.
- reversal.
- permissions.

لذلك لم يتم إدخالها في هذا closure حتى لا نخلق واجهة توهم بوجود Capability غير مبنية.

هذه تبقى Future Business Contracts.

---

# 19. WHAT IS ALREADY PRESENT — DO NOT REBUILD

Current vouchers already contains:

- login/recovery.
- role gate.
- pending/completed/account tabs.
- transfer.
- direct sale.
- direct return.
- supplier return.
- scrap.
- adjustment.
- branch/vehicle/supplier/rep selection.
- mobile branch support.
- source stock availability.
- product search.
- barcode scanner hooks.
- before/after stock workflow.
- CREATE operation identity.
- RECEIVE operation identity.
- duplicate protection.
- Send.
- Cancel.
- Complete.
- Receive.
- unified audit/details.
- inventory movement history.
- realtime refresh.
- mobile drawer.
- responsive UI.

لا تعيد بناء أي منها.

---

# 20. FINAL OWNER PATCH SET — EXACT

## PATCH 1

File:

`companies/company-1/warehouse/vouchers.html`

Element:

**line 416**

Search exact:

`rows.map(function(v){var c=v.status==='Draft'?'bg-amber-100 text-amber-700'`

Delete the entire orphaned `rows.map(...).join('')},` line.

No replacement.

Reason:

duplicate body of the old `cards` renderer.

Verification:

JavaScript parser changes from:

`Unexpected token '.'`

to:

PASS.

---

## PATCH 2

Same file.

Search exact:

`RW_SW.register('../sw.js');`

Delete that call only.

No replacement.

Reason:

Current canonical source has no standalone voucher Service Worker at `warehouse/sw.js`, and the shared coordinator intentionally excludes vouchers.

---

# 21. POST-PATCH VALIDATION COMMANDS

بعد أن يطبق Owner PATCH 1 وPATCH 2:

### Static gate

- parse the complete inline JavaScript.
- must return PASS.
- zero `SyntaxError`.

### App object gate

must verify:

- `App` exists.
- `App.doLogin`
- `App.send`
- `App.cancel`
- `App.complete`
- `App.receive`
- `App.details`

must all be callable.

### SW gate

No call to:

`RW_SW.register('../sw.js')`

must remain in vouchers source.

No request to:

`warehouse/sw.js`

must be generated by the current voucher page.

### Production E2E

- login.
- role = أذونات.
- load refs.
- source branch.
- DirectSale target vehicle.
- CREATE.
- SEND.
- vehicle stock.
- DirectReturn.
- RECEIVE.
- retry with same operation_id.
- audit.
- movement history.
- final stock reconciliation.

---

# 22. E2E LIMITATION OF THIS SESSION

Production RPC/backend E2E has already been historically closed and current Production definitions remain aligned.

لكن Browser E2E النهائي لم يُعلن مغلقًا في هذه الجلسة لأن Owner هو الذي يملك تعديل target frontend source، ولم يتم تشغيل browser against the patched source بعد.

لم يتم تحويل:

STATIC PASS

إلى:

BROWSER PASS.

وهذا متعمد حفاظًا على قواعد الـGovernance.

---

# 23. PRODUCTION ACTION RESULT

لا يوجد Production migration أو Edge Function جديدة لازمة نتيجة Regression الحالي.

Current Production infrastructure remains:

- Physical stock centralization = CLOSED.
- Voucher CREATE = CLOSED.
- Voucher SEND = CLOSED.
- Voucher RECEIVE = CLOSED.
- Voucher COMPLETE = CLOSED.
- Voucher CANCEL = CLOSED.
- DirectSale Vehicle Stock = CLOSED.
- DirectReturn = CLOSED.
- Van Sales central stock = CLOSED.
- Operation identity = CLOSED.
- No new Edge Function = 0.

أي تعديل Production إضافي الآن سيكون غير ضروري.

---

# 24. FINAL CLOSURE MATRIX

| Closure | Result |
|---|---|
| Governance recovery | PASS |
| Current System Git | VERIFIED |
| System parent | VERIFIED |
| Current Mother Git | VERIFIED |
| Current vouchers source | VERIFIED |
| Current Van Sales source | VERIFIED |
| Current Production | VERIFIED |
| Current database schema | VERIFIED |
| Physical stock centralization | CLOSED |
| Voucher backend contract | CLOSED |
| Van Sales integration | CLOSED |
| Syntax root cause | PROVEN |
| App undefined root cause | PROVEN |
| SW direct registration defect | PROVEN |
| Tailwind warning | NON-BLOCKING TECH DEBT |
| Owner Patch 1 | READY |
| Owner Patch 2 | READY |
| main.html change | 0 |
| vouchers.html CTO write | 0 |
| van-sales CTO write | 0 |
| New Edge Functions | 0 |
| New Production writer | 0 |
| Browser E2E | OPEN UNTIL OWNER PATCH |
| Lot/Serial/Expiry | FUTURE BUSINESS CONTRACT |
| Full voucher UI closure | OPEN UNTIL PATCH + BROWSER |

---

# 25. ZERO-DEBT CONCLUSION

لا توجد الآن حاجة لإعادة بناء القلب المركزي.

القلب المركزي موجود وصحيح:

`post_stock_movement`

المشكلة الحالية ليست Database architecture failure.

المشكلة الحالية:

**Frontend source regression**

حدث بعد آخر Mother commit، عندما أضيف renderer جديد وترك renderer قديم orphaned.

إذن الحل ليس:

- Edge Function.
- SQL workaround.
- new table.
- new writer.
- new SW.
- rewrite.

الحل الجراحي:

1. حذف orphan renderer line.
2. حذف direct SW registration call.
3. إعادة parse.
4. Browser E2E بعد Owner cutover.

---

# 26. SELF-AUDIT

## What I Proved

- Governance file reread to EOF.
- Latest report trail identified.
- Report282/283/284 read to EOF.
- System HEAD and parent checked.
- Current Mother HEAD and parent checked.
- Current vouchers source read.
- Current Van Sales source read.
- Current main source read without modification.
- Production schema/current functions checked.
- Current Production data snapshot checked.
- Physical writer boundary checked.
- Login/auth contract checked.
- Exact parser failure reproduced.
- Exact orphan line identified.
- In-memory surgical parser repair passed.
- Service Worker path reconstructed.
- No new Production core is necessary.
- No new Edge Function is necessary.
- Previous closures were preserved.

## What I Did Not Claim

- I did not claim Browser E2E PASS after a source patch that the Owner has not applied.
- I did not claim Tailwind warning eliminated.
- I did not claim Lot/Serial/Expiry implemented.
- I did not modify `main.html`.
- I did not modify `vouchers.html`.
- I did not modify `van-sales.html`.

## What Was Initially Stale

The previously recorded target blob and Mother revision in older reports were no longer current.

The current source moved to:

Vouchers:
`8d7fd4375376de11200836c2fe76f98d27ac7c53`

Mother:
`7efa2dfe17ddd10cc410d3887cc9876d630aa319`

The newly introduced regression was found only after re-fetching Current Source.

---

# 27. START INSTRUCTIONS FOR NEXT SESSION

Do not start from zero.

1. Read the final section of `CURRENT_STATE.md`.
2. Verify the newest System HEAD and parent.
3. Verify the current Mother HEAD.
4. Re-fetch `vouchers.html`.
5. Search exactly for the orphaned `rows.map(function(v){...` line.
6. Search exactly for `RW_SW.register('../sw.js');`.
7. If both are already absent, do not change the source again.
8. Parse the complete file.
9. Verify `App` object.
10. Run Browser E2E.
11. Re-read Production immediately before the final report.
12. Do not reopen any Production closure unless new runtime evidence contradicts it.

---

# 28. OWNER EXECUTION CARD

### File

`companies/company-1/warehouse/vouchers.html`

### Action A

**Search → Delete**

`rows.map(function(v){var c=v.status==='Draft'?...}).join('')},`

**Location:** line 416.

### Action B

**Search → Delete**

`RW_SW.register('../sw.js');`

**Location:** final script bootstrap.

### Do not touch

- `main.html`
- `van-sales.html`
- `core.js`
- `register-sw.js`
- any Edge Function
- any closed Production RPC

---

# 29. SESSION FINAL STATE

```
CURRENT GIT              = VERIFIED
CURRENT SOURCE           = VERIFIED
CURRENT PRODUCTION       = VERIFIED
CURRENT DATABASE         = VERIFIED
CURRENT DEPLOYMENT       = VERIFIED

PHYSICAL STOCK CORE      = CLOSED
VOUCHER BACKEND          = CLOSED
VAN SALES INTEGRATION    = CLOSED

CURRENT REGRESSION       = IDENTIFIED
ROOT CAUSE               = ORPHAN renderer at line 416
SECONDARY DEFECT         = redundant SW registration
SURGICAL PATCH           = READY
PRODUCTION REPAIR        = NOT REQUIRED
NEW EDGE FUNCTION        = 0
MAIN.HTML MODIFIED       = 0
VOUCHERS MODIFIED BY CTO = 0
VAN SALES MODIFIED       = 0

STATIC PARSER AFTER PATCH = PASS
BROWSER E2E                = OPEN
FULL UI CLOSURE            = OWNER PATCH + BROWSER E2E
```

# END
