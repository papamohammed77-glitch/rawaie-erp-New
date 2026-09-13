# تقرير 169 — تنفيذ Multiple / Partial Sales Payment Allocation

**التاريخ:** 14 سبتمبر 2026

> **الحقيقة الحاكمة في هذه الجلسة:** لا يُعتد بأي تقرير سابق كحالة حالية. تم بناء التحقق على CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE فقط.
>
> **نقطة البدء الإلزامية:** اختبار E2E لملف النظام الأم:
> `https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`
>
> هذا الملف هو Source of Truth للنظام الأم. لم يتم تعديل `Current/PWA/main2` ولا `New-main` في هذه الجلسة.

## 1. استرجاع الحقيقة الحالية

### Frontend

تم فحص أحدث commit في مستودع `erp-frontend`:

- HEAD: `e5176010a2bb1a246eaa9f5943a79542af42ee66`
- Parent: `f5261200bb0db7b8d888eabb0c99361e32e3f113`
- رسالة HEAD: `Update timestamp in main.html comment`
- التغيير الوحيد في HEAD هو timestamp أعلى `companies/company-1/main.html`، لذلك لا يوجد تغيير منطقي بعد أساس Patch الدفع.

الـParent نفسه هو commit إضافة العروض والخصومات إلى النظام الأم، وتم التحقق من Diff المباشر لذلك الـParent.

### Backend

تم فحص أحدث commit في `rawaie-erp-New`:

- HEAD: `1ab3541d29bf68f7cfc194aea90a25eabd183f01`
- الرسالة: `fix(payments): harden operation-id fingerprint and stale processing guard`
- تم أيضًا مطابقة السلسلة مع:
  - `8e98fce30d93243d4397d351c55f1a1b6701d651` — Canonical sales payment allocation Edge API.
  - `2fd86c0552c0edfcf57435cd234635d4cabf3852` — Core schema + atomic RPC.

## 2. الحالة الحقيقية للدفع قبل التنفيذ

Production تحتوي فعليًا على:

- `sales_payment_receipts`
- `sales_payment_allocations`
- `orders.amount_paid`
- `erp_operation_registry`

الـRPC المركزي `post_sales_payment_allocation_atomic` موجود ومحصّن بالـoperation fingerprint وstale-processing guard.

الـEdge Function المنشورة `sales-payment-allocation` موجودة ومفعلة بـJWT والتحقق من `users.auth_id -> company_id`، وتوفر `catalog`, `open_orders`, `list`, `detail`, `create`.

وبالتالي **لم تتم إعادة بناء Payment Core من الصفر**؛ لأن ذلك كان سيكرر ما ثبت وجوده ويخلق الدين الذي تمنعه مبادئ الحوكمة.

## 3. ما كان مفتوحًا فعليًا

المشكلة الفعلية المتبقية كانت Consumer/UI في النظام الأم:

- تبويب `سندات القبض` كان يعرض الـcash_box receipts التقليدية فقط.
- لم يكن يحتوي UI كاملًا لتحصيل عميل.
- لم يكن يتيح توزيع دفعة واحدة على عدة فواتير.
- لم يكن يتيح Partial Allocation.
- لم يكن يعرض Unallocated Credit بصورة واضحة.
- لم يكن يستهلك Edge API الجديد الموجود في Production.

لذلك بقيت حالة `Multiple / Partial Sales Payment allocation = OPEN` صحيحة من منظور المنتج، رغم اكتمال طبقة الـbackend.

## 4. التنفيذ الفعلي في Production

تم تنفيذ Migration جديدة مباشرة على Production:

`20260914_sales_payment_allocation_realtime_indexes`

وتحتوي على:

1. Index على `sales_payment_allocations(order_id)`.
2. Index على `sales_payment_receipts(cash_box_id)`.
3. إضافة `sales_payment_receipts` إلى `supabase_realtime` إن لم تكن مضافة.
4. إضافة `sales_payment_allocations` إلى `supabase_realtime` إن لم تكن مضافة.

الغاية: تقوية مسار القراءة الفورية وربط العلاقات الشائعة دون تغيير Business Contract.

تم تسجيل نفس الـmigration في Git canonical:

`supabase/migrations/20260914_sales_payment_allocation_realtime_indexes.sql`

## 5. تنفيذ Consumer/UI المطلوب للنظام الأم

لم يتم تعديل `erp-frontend/main.html` مباشرة تنفيذًا لتوزيع المسؤوليات.

تم إعداد Patch مالك كامل في:

`doc/Draft/Reprots/SALES_PAYMENT_ALLOCATION_OWNER_SURGICAL_PATCH_20260914.js`

ويشمل:

### PATCH A
استبدال `_renderReceipts()` كاملًا.

- نقطة البحث: `function _renderReceipts() {`
- موضعه الحالي: حوالي السطر `11264`.
- الحذف حتى القوس الأخير مباشرة قبل `function _buildReceiptsTable(data)`.
- البديل الكامل موجود في ملف الـPatch نفسه.

### PATCH B
إضافة Customer Payment Allocation module كامل مباشرة قبل:

`function _renderPayments() {`

- الموضع الحالي: حوالي السطر `11357`.
- لا يتم تعديل `function _renderPayments()` نفسه.

الموديول يضيف:

- اختيار العميل.
- اختيار الخزينة.
- تاريخ القبض.
- مبلغ الدفعة.
- المرجع والملاحظات.
- تحميل الفواتير المفتوحة للعميل.
- توزيع الدفعة على فاتورة واحدة أو عدة فواتير.
- السداد الجزئي.
- رصيد غير مخصص.
- إعادة حساب totals قبل الحفظ.
- إرسال `operation_id` إلى الـEdge/API.
- عرض سندات التحصيل وتفاصيل allocations.

## 6. التزامن اللحظي

تم إعداد Patch إضافي:

`doc/Draft/Reprots/SALES_PAYMENT_ALLOCATION_OWNER_REALTIME_SUPPLEMENT_20260914.js`

ويضيف channel باسم:

`rw-customer-payment-<companyId>`

ويستمع إلى:

- `sales_payment_receipts`
- `sales_payment_allocations`

مع company filter، ثم يعيد تحميل قائمة سندات التحصيل عند التغيير.

هذا الجزء لا يلمس قاعدة العمل ولا يكتب في قاعدة البيانات؛ هو Consumer refresh فقط.

## 7. Verification في Production

### ما تم إثباته

- Payment Core موجود فعلًا في Production.
- RPC المركزي يستخدم `company_id` في Customer / Treasury / Orders.
- Order allocation يمنع تجاوز outstanding.
- أكثر من Order في نفس receipt ممكن عبر `sales_payment_allocations`.
- Partial allocation مدعوم.
- Unallocated balance محسوب كـ`amount - allocated_amount`.
- `erp_operation_registry` يحمي duplicate operation.
- Current production Edge Function هي الـcanonical API المقصود.
- Realtime publication تم تجهيزها فعليًا في Production.

### ما لم يتم إثباته في هذه الجلسة

لم يتم تشغيل متصفح E2E فعليًا على الصفحة المنشورة لأن بيئة هذه الجلسة لا توفر Browser Automation للنقر داخل UI والتحقق من Console/network/DOM.

لذلك لا يجوز تسجيل:

`PRODUCTION RUNTIME VERIFIED = PASS`

ولا يجوز تسجيل:

`GLOBAL CLOSURE = 100%`

قبل أن يدمج المالك Patch النظام الأم في `erp-frontend/companies/company-1/main.html` ويجري اختبار E2E بالمتصفح الخفي على النسخة المنشورة.

## 8. أخطاء / تجارب فاشلة

أثناء مراجعة Payment Core ظهر أن الاختبار النظري يمكن أن يلتبس مع idempotency إذا تم بناء العملية من حالة `qty_received_before` أو أي state متغير.

الاستنتاج الصحيح: Operation Identity يجب أن تأتي من Client Operation ID ثابت، وليس من hash لحالة تتغير بعد التنفيذ.

في Payment Core الحالي، `operation_id` موجود أصلًا كعقد واضح ومحصّن في `erp_operation_registry`. لذلك لم تتم إضافة آلية منافسة.

## 9. قرار معماري

لا تتم إضافة Writer أو جدول بديل لنفس مسؤولية الدفع.

السلسلة المعتمدة:

`Master UI`

→ `sales-payment-allocation Edge Function`

→ `post_sales_payment_allocation_atomic`

→ `post_cash_receipt_atomic`

→ `sales_payment_receipts`

→ `sales_payment_allocations`

→ `orders.amount_paid`

→ `customer ledger`

مع `erp_operation_registry` كحارس Idempotency.

لا يوجد Dual Write من الواجهة إلى جداول التحصيل مباشرة.

## 10. Source of Truth

Source of Truth للنظام الأم:

`https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`

وليس:

- `Current/PWA/main2`
- `New-main`
- أي fragment تاريخي.

الـ11 أجزاء لا تستخدم إلا كمرجع تاريخي عند الحاجة لفهم نية التعديل السابق.

## 11. حالة المهمة

### Backend

**Production Infrastructure:** CLOSED

**Production Core:** CLOSED

**Realtime infrastructure:** CLOSED

### Frontend Consumer

**Owner Surgical Patch prepared:** YES

**Master main.html actually merged:** NO

**Browser E2E executed:** NO

### Final Closure

**Multiple / Partial Sales Payment Allocation = OPEN**

والسبب الوحيد المتبقي هو Consumer merge + Browser E2E verification، وليس غياب الـbackend infrastructure.

## 12. إرشادات المساعد التالي للوصول إلى الحقيقة

1. ابدأ دائمًا من `CURRENT GIT` لا من تقرير.
2. افحص أحدث commit ثم parent ثم Diff الفعلي.
3. افتح `erp-frontend/companies/company-1/main.html` الحالي نفسه، ولا تفترض أن Patch تاريخي ما زال مطابقًا.
4. افحص Production Supabase في نفس لحظة التقرير.
5. طابق Deployment الحالي للـEdge Function مع Git canonical.
6. افحص الجداول والـconstraints والـRLS والـRPC definitions قبل أي تعديل.
7. لا تُصلح شيئًا ثبت أنه CLOSED في Production.
8. إذا كانت المشكلة Consumer/UI، جهّز تعديلًا جراحيًا كاملًا للمالك ولا تعدّل الـmaster بنفسك.
9. عند أي E2E، سجّل بالترتيب: UI → Network → Edge → RPC → DB → State → Realtime → Console.
10. لا تعتبر وجود الجدول أو الـRPC نجاحًا وظيفيًا؛ النجاح هو إتمام Business Journey كاملة.
11. لا تعتبر Staging/SQL PASS مساويًا لـProduction Runtime PASS.
12. لا تسجل نسبة أو Closure إلا بعد مطابقة Production الحالية في لحظة التقرير.
13. إذا ظهر تعارض بين تقرير وProduction، Production الحالية هي المرجع، والتقرير يسجل كـSTale historical evidence.
14. إذا واجهت فجوة، لا تخترع عقدًا جديدًا قبل البحث عن العقد الحالي في Schema وRPC وConsumer وGit history.
15. كل Closure Unit تنتهي فقط بعد: Implement → Deploy → Production Verify → Runtime Verify → Documentation.

## 13. النتيجة النهائية

تم تنفيذ البنية التحتية اللازمة في Production وإعداد مسار UI الكامل بطريقة جراحية موثقة.

لكن وفق مبادئ الحوكمة، **لن يتم الادعاء بإغلاق المهمة 100% قبل دمج Patch النظام الأم وتشغيل E2E فعليًا**.
