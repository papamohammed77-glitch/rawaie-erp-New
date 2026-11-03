# Report604 — استكمال فحص مستهلكي مرتجعات الشراء وتصحيح Preflight P0-D

**التاريخ:** 2026-11-03 — Africa/Cairo  
**نقطة الاستكمال:** LVE-2026-11-03-603 / Report603  
**الحالة:** P0-D INTERNAL CONSUMER REVIEW COMPLETE / READY FOR EXACT OWNER APPROVAL — NOT APPLIED  
**النطاق:** كل مستهلكي `purchase_returns` و`purchase_return_details` داخل المستودعات المتاحة، مطابقة قراءات النظام الأم وRealtime، تدقيق SQL والـRollback، وتثبيت خطر تجاوز كمية المرتجع.  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main`  
**مستودع التقارير:** `papamohammed77-glitch/rawaie-erp-New` / `main`

---

## 1. سبب هذا الاستكمال

Report603 أثبت فجوة صلاحيات DML وخطر تجاوز الكمية التراكمي، لكنه ترك المستهلكين خارج `companies/company-1` ضمن UNKNOWN، كما أن Rollback المقترح فيه لا يعيد امتياز `MAINTAIN` الذي ظهر في Snapshot Production.

استُكمل ذلك هنا من خلال قراءة Blob ملف `main.html` كاملًا، وفحص مستهلكي Buyer وEdge، وجرد المستودعات التي أتاحها اتصال GitHub، ثم إعادة قراءة Grants وPolicies وPublication من Production. لا يُستبدل Report603؛ هذا ملحق تصحيحي ومكمل له.

## 2. اكتشاف مستهلك النظام الأم — CONFIRMED

**الملف:** `companies/company-1/main.html`  
**Blob SHA:** `53b5a9e9d0433a785c3d5471a9c0d68c25497882`  
**الحجم المقروء:** 1,800,879 character / 33,358 lines.

ظهر تبويب مستقل باسم **مرتجعات المشتريات** في مكوّن `RW_PurchaseGold`:

| المسؤولية | الموضع |
|---|---:|
| `getData(table)` — قراءة Supabase مباشرةً بـ `supabase.from(table).select('*').eq('company_id', companyId())` | 12235–12247 |
| `api(operation,payload)` — يرسل العملية إلى Edge `save-purchase-order` مع Bearer token وIdempotency-Key | 12196–12233 |
| اشتراك Realtime لجدول `purchase_returns` | 12432–12439 |
| تحميل قائمة المرتجعات | 13792–13818 |
| إنشاء مرتجع | 13820–13979 |
| ترحيل مرتجع | 13980–13992 |

**النتيجة الأمنية المهمة:** النظام الأم يقرأ رؤوس `purchase_returns` مباشرةً من Supabase، ويشترك في تغييراتها عبر Postgres Changes، لكنه لا يكتب مباشرةً في الجدولين. الإنشاء والترحيل يمران عبر:
- `api('CREATE_RETURN', ...)` عند السطر 13971.
- `api('POST_RETURN', ...)` عند السطر 13984.
- كلاهما يوجّه إلى `/functions/v1/save-purchase-order` مع Authorization وOperation ID.

لم يظهر في Blob أي `supabase.from('purchase_returns').insert/update/upsert/delete` أو نظيره لـ`purchase_return_details`. لذلك يجب **الإبقاء على SELECT للمستخدم المصادق عليه** بعد P0-D؛ سحب القراءة سيكسر قائمة المرتجعات وتحديثها اللحظي في النظام الأم.

## 3. استكمال فحص تطبيقات الشركة وBuyer

### 3.1 النظام الأم

- `main.html` يقرأ `purchase_returns` مباشرةً بفلتر الشركة.
- لا يقرأ `purchase_return_details` مباشرةً.
- Realtime يستمع إلى `purchase_returns`، والجدول موجود بالفعل في `supabase_realtime`.
- الإنشاء والترحيل يمران بالبوابة المركزية، لا بـDML مباشر.

### 3.2 Buyer PWA

**الملف:** `companies/company-1/purchasing/buyer.html`  
**Blob SHA:** `aee14e6a4edbccd5fb95dff24f21daf1c6d21fcc`.

يضع Buyer الجدولين في إعداد Realtime/cache invalidation:
- `purchase_returns` عند الأسطر 191 و212 و215.
- `purchase_return_details` عند الأسطر 192 و215.

قراءة بيانات Buyer تمر عبر `GET_DATA` في Edge `save-purchase-order`، الذي يقرأ تفاصيل الجداول من الخادم ويعيدها للواجهة. لم يظهر DML مباشر من Buyer على الجدولين.

### 3.3 جرد ملفات الشركة

تم فحص شجرة `companies/company-1` ذات 34 ملف HTML/JS/TS؛ لم تظهر كتابة مباشرة على الجدولين. الاستثناءات النصية ذات الصلة محصورة في Buyer PWA والنظام الأم أعلاه، وكلها قراءة/Realtime أو استعمال للبوابة المركزية.

## 4. مراجعة المستودعات المتاحة

أعاد اتصال GitHub ثلاثة مستودعات فقط للحساب المرتبط:

1. `erp-frontend` — المستودع التشغيلي الحالي.
2. `rawaie-erp-New` — مستودع التقارير والحالة والنسخ المرجعية.
3. `rawaie-erp-review` — مستودع تاريخي.

فُحصت الملفات التاريخية ذات الصلة في `rawaie-erp-review`:
- `PWA/purchasing/buyer.html`
- `PWA/purchasing/supervisor.html`
- `PWA/warehouse/returns.html`
- `Edge_Functions/original/09_purchasing/save-purchase-order.ts`

لم يظهر فيها مرجع إلى `purchase_returns` أو `purchase_return_details`. ملف `warehouse/returns.html` التاريخي يتعامل مع مرتجعات الرانشيت/المبيعات عبر `run_sheet_details`، وليس مرتجعات الموردين. Edge التاريخي المذكور يكتب أوامر الشراء وتفاصيلها فقط.

كما فُحصت النسخ المرجعية ذات الصلة في `rawaie-erp-New/Current/PWA`:
- `buyer.html`
- `Returns.html`
- `receiver.html`

ولم يظهر فيها استهلاك لجدولي مرتجعات المشتريات. هذه النسخ مرجعية/تاريخية وليست مسار النشر التشغيلي الحالي.

**حد الإثبات:** هذا يكمل فحص المستودعات التي أتاحها اتصال GitHub والملفات التشغيلية الحالية. لا يمكن الجزم بعدم وجود تكامل طرف ثالث أو مستودع غير متاح لهذا الاتصال؛ لم يتم ادعاء ذلك.

## 5. البوابة المركزية وصلاحياتها — CONFIRMED

**المصدر التشغيلي:** `supabase/functions/save-purchase-order/index.ts`  
**Git blob:** `bc038be8c60a3d593f604c7b2ae445e807bacf57`  
**الحجم:** 23,077 characters / 491 lines.  
المصدر مطابق بايتًا لمصدر Production `save-purchase-order` v22 (ACTIVE, `verify_jwt=true`).

تتحقق Edge من:
- Bearer token و`auth.getUser`.
- المستخدم النشط والشركة.
- `get_my_effective_profile` باستخدام JWT المستدعي.
- الصلاحيات الفعلية قبل العملية.

العقد:
- `CREATE_RETURN` يمر عبر `purchase_create_return_atomic`، ويتطلب صلاحية `purchases`.
- `POST_RETURN` يمر عبر `purchase_post_return_atomic`، ويتطلب `purchases + finance`.
- `CANCEL_DOCUMENT` لمرتجع الشراء يتطلب `purchases + finance`.
- عمليات الكتابة تستعمل Service Role client في Edge بعد التحقق من المستدعي؛ وRPCs المرتجعات لا تسمح بتنفيذ مباشر من `anon` أو `authenticated`.

إذن سحب Client DML لا يعطل الكاتب المركزي إذا بقيت Grants الحالية لـ`service_role` دون تغيير.

## 6. Snapshot Production المصحح لجداول المرتجعات

المشروع: `fiilmooggumokxanwiyx` — PostgreSQL 17.6.1.121.

### 6.1 RLS / Policies

| الجدول | RLS | FORCE RLS | السياسة الحالية |
|---|---|---|---|
| `purchase_returns` | ON | OFF | `ALL TO PUBLIC`، company_id = current_user_company_id() |
| `purchase_return_details` | ON | OFF | `ALL TO PUBLIC`، EXISTS على الرأس داخل الشركة |

سياسة RLS الحالية تعزل الشركة، لكنها لا تفرض RBAC لصلاحيات المشتريات والمالية. و`TO PUBLIC` في السياسة يصف دور السياسة؛ وهو ليس بحد ذاته Grant على الجدول.

### 6.2 الامتيازات الدقيقة الحالية

الاستعلام المباشر بـ`has_table_privilege` و`aclexplode` أثبت على **كلا الجدولين**:

| الدور | SELECT | INSERT | UPDATE | DELETE | MAINTAIN | REFERENCES | TRIGGER | TRUNCATE |
|---|---|---|---|---|---|---|---|---|
| anon | نعم | نعم | نعم | نعم | نعم | نعم | نعم | لا |
| authenticated | نعم | نعم | نعم | نعم | نعم | نعم | نعم | لا |
| service_role | نعم | نعم | نعم | نعم | نعم | نعم | نعم | نعم |

هذه أدق من ملخص Report603: المنح العميلية تتضمن `MAINTAIN` و`REFERENCES` و`TRIGGER` أيضًا، وليس فقط DML المعتاد.

### 6.3 Triggers / Constraints / Data

- رأس المرتجع: Trigger لتاريخ الحالة وTrigger لتحديث `updated_at` فقط.
- التفاصيل: لا يوجد Trigger تراكمي يحسب المرتجعات السابقة.
- القيود: PK/FKs و`qty > 0` و`unit_price >= 0`؛ لا يوجد FK من تفاصيل المرتجع إلى سطر فاتورة الشراء الأصلي ولا unique index على (return_id, invoice_detail_id).
- `purchase_returns` له unique على (company_id, operation_id) وعلى return_code.
- عدد السجلات الحالية: `purchase_returns=0`، `purchase_return_details=0`.

### 6.4 Realtime

كلا الجدولين موجود في `supabase_realtime`. كما أن:
- النظام الأم يشترك في `purchase_returns`.
- Buyer يدرج الجدولين في اشتراكه.

إبقاء `GRANT SELECT TO authenticated` وسياسة SELECT المقيدة بالشركة شرط تكامل، وليس منحًا زائدًا. لا تحذف الجدولين من Publication ضمن P0-D.

## 7. P0-D — جاهزية SQL وتصحيح Rollback Report603

Migration المقترحة في Report603 §8.1 مناسبة من حيث الهدف:
- `REVOKE ALL PRIVILEGES` من PUBLIC وanon وauthenticated على الجدولين.
- `GRANT SELECT` لـauthenticated فقط.
- استبدال ALL policies بسياسات SELECT فقط مع شرط الشركة.
- عدم تغيير صلاحيات `service_role`.

### 7.1 تصحيح إلزامي للـRollback

Rollback المكتوب في Report603 §8.3 أغفل `MAINTAIN` رغم أنه موجود في Snapshot السابق على anon وauthenticated. لذلك **لا تستخدم نص Rollback القديم حرفيًا**. عند الحاجة إلى استعادة Snapshot الحالي، يجب أن يتضمن منح MAINTAIN أيضًا:

```sql
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, UPDATE
ON TABLE public.purchase_returns, public.purchase_return_details
TO anon, authenticated;
```

لا تُضف TRUNCATE إلى anon/authenticated؛ فهو غير موجود في Snapshot الحالي. لا تغيّر Grants الخاصة بـservice_role. ويجب إعادة بناء Rollback من Snapshot جديد إذا اختلفت أي Grant أو Policy عند لحظة التنفيذ.

### 7.2 Acceptance مصحح بعد الموافقة

- anon: لا SELECT ولا INSERT/UPDATE/DELETE ولا MAINTAIN/REFERENCES/TRIGGER.
- authenticated: SELECT فقط، مع company-scoped RLS.
- authenticated: INSERT/UPDATE/DELETE/MAINTAIN/REFERENCES/TRIGGER/TRUNCATE مرفوض.
- service_role: يحافظ على Grants السابقة، بما فيها TRUNCATE/MAINTAIN.
- Parent Returns list: يظل يقرأ ويُحدّث عبر Realtime.
- Buyer PWA: تظل Realtime/cache invalidation للجدولين تعمل.
- CREATE_RETURN وPOST_RETURN وCANCEL_DOCUMENT تستمر من Edge مع التحقق من الصلاحية.
- لا اختبار ببيانات مالية/مخزنية في Production؛ تستخدم بيئة معزولة بعد الموافقة.

**الحالة:** Consumer review للمستودعات المتاحة مكتمل. P0-D جاهز للعرض والاعتماد. لم يُنفذ SQL.

## 8. P0-R — تأكيد إضافي لخلل تجاوز كمية المرتجع

أُعيدت قراءة Blob `main.html` كاملًا مع تعريفَي RPC من Production مباشرة.

### 8.1 واجهة النظام الأم

في `createReturn()`:
- تُقرأ بنود `purchase_invoice_details`.
- `max_qty` يُضبط على `received_qty` الأصلية مباشرة.
- لا تُقرأ المرتجعات السابقة ولا تُطرح من الحد الأقصى.
- التحقق في الواجهة يرفض فقط إذا كانت الكمية أكبر من `max_qty` الأصلي.
- payload يرسل `item_code` و`qty`، لا `purchase_invoice_detail_id`.
- `api()` يولد UUID جديدًا عند كل إرسال ما لم يُمرر Operation ID صريح.

المواضع: `main.html` الأسطر 13820–13962؛ API عند 12196–12233.

### 8.2 Production RPC

`purchase_create_return_atomic`:
1. يتحقق من وجود operation_id ويعيد نفس النتيجة عند تكراره.
2. يقفل رأس الفاتورة.
3. لكل عنصر يبحث عن سطر الفاتورة بـ(invoice_id, item_code) ويقفل السطر.
4. يتحقق من `qty > 0` و`qty <= received_qty`.
5. ينشئ تفاصيل المرتجع.

**الخلل:** لا يجمع `purchase_return_details.qty` للمرتجعات السابقة على سطر الفاتورة ولا يطرحها من received_qty. كما أن البحث بـitem_code بدل ID سطر الفاتورة يجعل الربط ملتبسًا إذا تكرر SKU في فاتورة واحدة؛ والمخطط الحالي لا يفرض unique(invoice_id,item_code).

قفل الرأس/السطر يحد التزامن لكنه لا يعالج النقص؛ فالعمليات المتتابعة بمفاتيح مختلفة تبقى قادرة على تجاوز الإجمالي لأن شرط الدالة يقارن كل طلب منفردًا بكمية الاستلام الأصلية.

### 8.3 Production RPC عند الترحيل

`purchase_post_return_atomic` ينفذ لكل سطر:
- `post_stock_movement(...,'SupplierReturn', branch_id, NULL,...)`.
- قيد Dr Supplier 211 / Cr Inventory 124.
- `supplier_ledger` debit.
- حالة Posted.

ولا يطلب إثبات قبول المورد أو يرحّل accepted_qty فقط.

**الحكم:** P0-R خطر مستقل عن P0-D. تضييق ACL لا يصلحه؛ يجب منع التجاوز داخل RPC وتحديد سطر الفاتورة الأصلي، ثم تصميم واقعة التسليم والقبول الجزئي للمورد قبل أي أثر مخزني/محاسبي. لا توجد بيانات مرتجعات حالية في Production، ولم يُجر اختبار تفاعلي.

## 9. فجوة قابلية إعادة إنتاج Edge الاستلام

- `save-purchase-order` v22: مصدره موجود في المستودع التشغيلي ومطابق بايتًا لمصدر Production.
- `receive-purchase` v13: نشطة في Production، لكن لا يوجد مسار `supabase/functions/receive-purchase` في شجرة `erp-frontend/main`.
- نسخة `rawaie-erp-New/Current/Edge_Functions/receive-purchase` blob `76b21329702a884b31ece74e3c535fa27e756b10`، 2,792 characters، وليست مطابقة للمصدر الحي v13 ذي 4,140 characters.
- هذا لا يغيّر نتيجة P0-D، لكنه Gap لإعادة بناء/مراجعة المصدر. لا تنشئ Edge جديدة ولا تستبدل النسخة الحية قبل Change Set مستقل ومراجعة.

## 10. ما تم وما لم يتم

**تم فعليًا:**
- استكمال قراءة `main.html` كاملًا عبر Git Blob دون أي تعديل.
- كشف مستهلك النظام الأم للمرتجعات وتحديد direct SELECT مقابل Edge write.
- استكمال جرد المستودعات المتاحة ومراجعة ملفات PWA التاريخية ذات الصلة.
- إعادة التحقق من ACL/RLS/Policies/Triggers/Indexes/Publication وRPC definitions في Production.
- تصحيح نقص MAINTAIN في Rollback الموصوف في Report603.
- تأكيد P0-R من واجهة النظام الأم ومن RPC الحي.

**لم يتم:**
- لا DDL/Migration أو RLS/ACL/Grant/RPC/Trigger تغيير.
- لا Edge deployment أو تعديل Buyer/main.html أو ملفات PWA.
- لا تحديث بيانات Production أو إنشاء Fixtures.
- لا E2E مصادق عليه، ولا test transaction، ولا تحقق من Artifact Cloudflare الحالي.
- لا إصلاح لخلل التراكم أو قبول المورد.

## 11. بوابة التنفيذ والخطوة التالية

1. **P0-D:** يعرض Report603 §8.1 مع هذا التصحيح للـRollback والـAcceptance، ثم ينتظر موافقة المالك الصريحة على SQL ذاته وفق Master CTO §77.2. طلب «استمر» لا يبدل شرط الموافقة المحددة.
2. **P0-R:** Change Set مستقل؛ لا يُنفذ مع P0-D تلقائيًا. يلزم عقد قبول المورد والحيازة والمردود الجزئي والربط بسطر الفاتورة، ثم SQL/RPC كامل مع اختبارات التزامن وRollback وموافقة منفصلة.
3. Owner HTML corrections في Report603 §10 تبقى على مسار المالك؛ لا تعديل مباشر في Buyer أو `main.html`.
4. بعد الموافقات وتوفير بيئة اختبار معزولة: نفذ regression على Parent/Buyer/Receiver/Realtime وقياسات stock/ledger/GL/cash قبل/بعد، ثم تحقق من Cloudflare والـruntime.

**STATUS:** AVAILABLE-REPOSITORY CONSUMER REVIEW COMPLETE / P0-D READY FOR EXACT OWNER APPROVAL / P0-R CONFIRMED INTEGRITY GAP / BUYER OWNER PATCHES NOT APPLIED / EDGE SOURCE PARITY GAP / NO PRODUCTION MUTATION / OVERALL OPEN — NOT PRODUCTION-READY.
