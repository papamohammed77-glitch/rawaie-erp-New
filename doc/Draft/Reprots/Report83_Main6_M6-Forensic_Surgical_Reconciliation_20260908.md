# Report83 — Main6 Forensic Surgical Reconciliation — 2026-09-08

## 1. نطاق الجلسة

المستهدف الوحيد في هذه الجلسة هو:

`Current/PWA/main2/main6.md`

وهو الجزء الرابع من الملف الأصلي المجزأ `main2`.

تم الالتزام بقاعدة أن ملف النظام الأم المجزأ لا يتم تعديله مباشرة من المساعد؛ لذلك لا يحتوي هذا التقرير على ادعاء بأن `main6.md` نفسه تم تغييره في Git.

تم فحص Production Supabase والمستودع والوثائق التاريخية قبل تحديد أي تعديل.

---

## 2. المصادر التي تمت مراجعتها

### الحوكمة والاستمرارية

- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`

### الحالة والتاريخ

- `CURRENT_STATE.md`
- `doc/Draft/Reprots/Report82_Main5_M5-20_Historical_Contract_Reconciliation_20260908.md`
- `doc/Draft/medhat/تقرير 100 - main6 forensic closure.md`
- تاريخ Git والـcommits ذات الصلة بـMAIN6.

### المصدر المستهدف

- `Current/PWA/main2/main5.md`
- `Current/PWA/main2/main6.md`

### Production

تمت مطابقة:

- PostgreSQL schema الحالي.
- RPC signatures والـdefinitions.
- Edge Functions الفعالة وإصداراتها.
- العلاقات بين `orders` / `order_details` / `purchase_orders` / `purchase_order_details` / `suppliers` / `app_settings`.

---

## 3. نتيجة استرجاع الحالة

### Main5

الحالة المسجلة سابقًا في `CURRENT_STATE.md` تشير إلى أن `main5` ما زال:

```text
SOURCE = OPEN
RUNTIME = OPEN
```

كما أن blob الحالي في Git ما زال يحمل النسخة القديمة وقت هذا التدقيق. لذلك لا يمكن اعتماد `main5 = CLOSED 100%` من مصدر Git الحالي حتى بعد قول المستخدم إن التعديلات تم تنفيذها محليًا.

هذا ليس رفضًا لما تم تنفيذه محليًا، بل قاعدة Evidence: المصدر الفعلي المنشور في Git لم يثبت الإغلاق بعد.

### Main6

لم يتم نقل أي إغلاق سابق من:

`Current/PWA/main/main6.md`

إلى:

`Current/PWA/main2/main6.md`

لأنهما مساران مختلفان.

تقرير `تقرير 100 - main6 forensic closure.md` تناول المسار الأول، وليس ملف `main2/main6.md` المستهدف هنا.

---

## 4. Production Reality — Main6 Backends

### submit-online-order

Production:

```text
submit-online-order v7
VERIFY_JWT = true
```

ويستخرج `company_id` من المستخدم المصادق عليه ثم يستدعي:

`submit_online_order_atomic`

الـRPC نفسه:

- يتحقق من وجود الشركة.
- يقرأ `app_settings` باستخدام `company_id`.
- يقرأ `items` بواسطة `item_code` العالمي الفريد رسميًا.
- يحسب السعر من `sales_price` الموجود في Item Master، وليس من السعر المرسل من العميل.
- ينشئ `orders` داخل الشركة.
- ينشئ `order_details` مرتبطة بـ`order_id`.

لا يوجد مبرر حالي لتعديل Production لهذا المسار بسبب main6.

### save-purchase-order

Production:

```text
save-purchase-order v3
VERIFY_JWT = true
```

ويستدعي:

`save_purchase_order_atomic`

الـRPC:

- يتحقق من الشركة.
- يتحقق من المورد داخل الشركة.
- يستعمل Item Master بالهوية العالمية المثبتة في Schema.
- لا ينفذ Physical Stock Movement.

لا يوجد مبرر حالي لتعديل Production لهذا المسار بسبب main6.

### receive-purchase

Production:

```text
receive-purchase v12
VERIFY_JWT = true
```

ويستخرج `company_id` من `users.auth_id`.

ويُرسل:

`p_operation_id`

إلى:

`receive_purchase_atomic`

وتوقيع Production الحالي هو:

```text
receive_purchase_atomic(
  p_company_id uuid,
  p_po_code text,
  p_user_email text,
  p_items jsonb,
  p_operation_id uuid
)
```

الـRPC الحالي يحقق idempotency قبل إعادة تنفيذ Physical Movement باستخدام `receiving.operation_id` الموجود أصلًا والمقيد بـUNIQUE.

ويحوّل Physical Stock فقط عبر:

`post_stock_movement(..., 'PurchaseIn', ...)`

إذن Production backend لهذا المسار متوافق مع الهدف، ولا توجد migration جديدة لازمة بسبب main6 في هذه اللحظة.

---

## 5. Schema Evidence المهمة

ثبت في Production:

```text
items.item_code = UNIQUE globally
stock_branches(branch_id,item_id) = UNIQUE
purchase_orders.company_id = NOT NULL
purchase_order_details.item_id = FK -> items.id
purchase_orders.branch_id = FK -> branches.id
suppliers.company_id = NOT NULL
orders.company_id = NOT NULL
order_details.order_id = FK -> orders.id
app_settings.company_id = NOT NULL
receiving.operation_id = NOT NULL + UNIQUE
```

ومن ثم:

- `order_code` ليس عمودًا في `order_details`.
- أي بحث عن تفاصيل الطلب يجب أن يتم عبر `order_id`.
- `app_settings` لا يجوز قراءتها بـ`LIMIT 1` بدون `company_id` عندما تكون العملية tenant-bound.
- `suppliers` و`purchase_orders` و`orders` تحتاج Company Scope في قراءات الواجهة.

---

## 6. Main6 — النتائج الجنائية

تم تحديد مجموعة الإصلاحات المصدرية التالية في `Current/PWA/main2/main6.md`.

### M6-01 — Online Store Settings Scope

المشكلة:

المصدر يستخدم:

```js
var sRes = await supabase.from('app_settings').select('*').limit(1).single();
```

وهذا Global Lookup غير صحيح في نظام متعدد الشركات.

الحالة:

```text
FOUND = TRUE
ROOT CAUSE = Tenant-unscoped settings lookup
PRODUCTION CORE = SAFE
SOURCE FIX = REQUIRED
```

### M6-02 — Track Order Company Scope

المصدر الحالي يبحث عن الطلب بهذه الصورة:

```js
.eq('order_code', input.value)
```

بدون `company_id`.

كما يبحث عن `order_details` باستخدام `order_code`، وهو عمود غير موجود في Production Schema.

الحالة:

```text
FOUND = TRUE
ROOT CAUSE = Missing tenant scope + wrong relational key
SOURCE FIX = REQUIRED
```

### M6-03 — Purchase Orders List Scope

المصدر الحالي:

```js
supabase.from('purchase_orders').select('*')
```

بدون `company_id`.

الحالة:

```text
FOUND = TRUE
ROOT CAUSE = Tenant-unscoped read
SOURCE FIX = REQUIRED
```

### M6-04 — Open Receive Scope and Error Order

المصدر الحالي:

```js
var poRes=await supabase.from('purchase_orders').select('*').eq('po_code',poCode).maybeSingle();
var itemsRes=await supabase.from('purchase_order_details').select('*').eq('po_id',poRes.data?poRes.data.id:null);
hideLoader();
if(!poRes.data){ ... }
```

المشكلات:

- PO Lookup غير Company-scoped.
- Details request يسبق التحقق الصريح من وجود PO/خطئه.

الحالة:

```text
FOUND = TRUE
ROOT CAUSE = Unscoped document lookup + wrong error ordering
SOURCE FIX = REQUIRED
```

### M6-05 — Supplier Read Scope

المصدر الحالي:

```js
supabase.from('suppliers').select('*')
```

بدون `company_id`.

الحالة:

```text
FOUND = TRUE
ROOT CAUSE = Tenant-unscoped read
SOURCE FIX = REQUIRED
```

### M6-06 — Purchase Refresh Scope

بعد الاستلام توجد إعادة تحميل لـ`purchase_orders` بدون Company Scope.

الحالة:

```text
FOUND = TRUE
ROOT CAUSE = Tenant-unscoped refresh
SOURCE FIX = REQUIRED
```

### M6-07 — Receive Dialog Remaining Quantity

واجهة الاستلام الحالية تضبط القيمة الافتراضية على:

```js
value="'+(it.qty_ordered||0)+'"
```

وهذا يعرض الكمية الأصلية بدل الكمية المتبقية عندما يكون هناك Partial Receiving سابق.

الحالة:

```text
FOUND = TRUE
ROOT CAUSE = UI uses ordered quantity instead of remaining quantity
SOURCE FIX = REQUIRED
```

### M6-08 — Track Order HTML Escaping

الملف يحتوي على `esc()`، لكن اسم الصنف يبنى مباشرة داخل HTML في `itemsH`.

هذا ليس Physical Stock defect، لكنه hardening صحيح ومحدود في نفس المقطع.

الحالة:

```text
FOUND = TRUE
ROOT CAUSE = Existing escape helper not applied to item_name
SOURCE FIX = REQUIRED
```

### M6-09 — Session Token Guard in savePO

المصدر يستخرج token ثم يستعمله مباشرة في Authorization header.

يلزم حارس صريح قبل `fetch()` عند عدم وجود session token.

الحالة:

```text
FOUND = TRUE
ROOT CAUSE = Missing explicit session guard
SOURCE FIX = REQUIRED
```

---

## 7. ما لم يتم تغييره عمدًا

لم تتم إضافة Realtime Channels جديدة إلى `main6` بشكل مستقل.

السبب:

Realtime هو جزء من البنية المشتركة (`core.js` / runtime)، وإضافة listener محلي جديد دون مطابقة الـshared infrastructure قد تنتج duplicate subscriptions أو تضارب state.

سيتم حسم Realtime بعد دمج الأجزاء في الملف الكامل واختبار runtime النهائي.

كذلك لم تتم إعادة بناء Business Logic الخاص بـPurchase / Online Order لأن Production RPCs الحالية تقوم بالفعل بالمسؤوليات الأساسية بصورة صحيحة.

---

## 8. التعليمات الجراحية المطلوب تنفيذها على main6.md

### الجراحة 1 — M6-01

ابحث عن **المقطع الكامل** الذي يبدأ بـ:

```js
    try {
      var sRes = await supabase.from('app_settings').select('*').limit(1).single();
```

وينتهي بالسطر الكامل:

```js
    } catch(e) {}
```

احذف المقطع كاملًا واستبدله بـ:

```js
    try {
      var companyId = _rwCompanyId();
      if (!companyId) throw new Error('سياق الشركة غير محدد');
      var sRes = await supabase.from('app_settings')
        .select('delivery_fee, tax_rate')
        .eq('company_id', companyId)
        .order('created_at', { ascending: true })
        .limit(1)
        .maybeSingle();
      if (sRes.error) throw sRes.error;
      if (sRes.data) {
        deliveryFee = Number(sRes.data.delivery_fee) || 0;
        taxRate = Number(sRes.data.tax_rate) || 0;
      }
    } catch(e) {
      deliveryFee = 0;
      taxRate = 0;
      console.error('Online Store settings load failed:', e);
    }
```

### الجراحة 2 — M6-02

ابحث عن المقطع الذي يبدأ بالسطر:

```js
      var o = await supabase.from('orders').select('*').eq('order_code', input.value).maybeSingle();
```

وينتهي بالسطر:

```js
      var it = await supabase.from('order_details').select('*').eq('order_code', input.value);
```

احذف المقطعين كاملين واستبدلهما بـ:

```js
      var companyId = _rwCompanyId();
      if (!companyId) throw new Error('سياق الشركة غير محدد');
      var code = String(input.value || '').trim();
      var o = await supabase.from('orders')
        .select('id, order_code, customer_name, area, total_amount, order_status')
        .eq('company_id', companyId)
        .eq('order_code', code)
        .maybeSingle();
      if (o.error || !o.data) { hideLoader(); Swal.fire({ title: 'الطلب غير موجود', text: 'لم يتم العثور على طلب بهذا الرقم', icon: 'error' }); return; }
      var it = await supabase.from('order_details')
        .select('item_name, qty, unit_price, line_amount')
        .eq('order_id', o.data.id);
      if (it.error) throw it.error;
```

ثم ابحث عن السطر الكامل:

```js
      Swal.fire({ title: 'تفاصيل الطلب: ' + input.value, html: detailH, width: '700px', showCloseButton: true, showConfirmButton: false });
```

واستبدله بـ:

```js
      Swal.fire({ title: 'تفاصيل الطلب: ' + code, html: detailH, width: '700px', showCloseButton: true, showConfirmButton: false });
```

ثم داخل بناء `itemsH` ابحث عن:

```js
(i.item_name || '')
```

داخل السطر الكامل الذي يبدأ بـ:

```js
itemsH += '<tr>
```

واستبدل **فقط** التعبير:

```js
(i.item_name || '')
```

بـ:

```js
esc(i.item_name || '')
```

### الجراحة 3 — M6-03

ابحث عن السطر الكامل:

```js
    var res=await supabase.from('purchase_orders').select('*'); poData=res.data||[]; renderPOTable(poData);
```

واحذف السطر كاملًا واستبدله بـ:

```js
    var companyId = _rwCompanyId();
    if (!companyId) { showToast('سياق الشركة غير محدد','error'); return; }
    var res=await supabase.from('purchase_orders')
      .select('*')
      .eq('company_id', companyId)
      .order('po_date', { ascending: false });
    if (res.error) { showToast('تعذر تحميل أوامر الشراء','error'); return; }
    poData=res.data||[];
    renderPOTable(poData);
```

### الجراحة 4 — M6-04

ابحث عن المقطع الكامل داخل `openReceive` الذي يبدأ بـ:

```js
    var poRes=await supabase.from('purchase_orders').select('*').eq('po_code',poCode).maybeSingle();
```

وينتهي بالسطر الكامل:

```js
    if(!poRes.data){ showToast('أمر الشراء غير موجود','error'); return; }
```

احذف المقطع كاملًا واستبدله بـ:

```js
    var companyId = _rwCompanyId();
    if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد','error'); return; }

    var poRes=await supabase.from('purchase_orders')
      .select('*')
      .eq('company_id',companyId)
      .eq('po_code',poCode)
      .maybeSingle();
    if(poRes.error){ hideLoader(); showToast('تعذر تحميل أمر الشراء','error'); return; }
    if(!poRes.data){ hideLoader(); showToast('أمر الشراء غير موجود','error'); return; }

    var itemsRes=await supabase.from('purchase_order_details')
      .select('*')
      .eq('po_id',poRes.data.id);
    if(itemsRes.error){ hideLoader(); showToast('تعذر تحميل تفاصيل أمر الشراء','error'); return; }
    hideLoader();
```

### الجراحة 5 — M6-05

ابحث عن السطر الكامل:

```js
    if (!RW_STATE.data.suppliers || !RW_STATE.data.suppliers.length) { try { var sRes = await supabase.from('suppliers').select('*'); RW_STATE.data.suppliers = sRes.data || []; } catch(e) {} }
```

احذف السطر كاملًا واستبدله بـ:

```js
    if (!RW_STATE.data.suppliers || !RW_STATE.data.suppliers.length) {
      try {
        var companyId = _rwCompanyId();
        if (!companyId) throw new Error('سياق الشركة غير محدد');
        var sRes = await supabase.from('suppliers')
          .select('*')
          .eq('company_id', companyId)
          .order('name', { ascending: true });
        if (sRes.error) throw sRes.error;
        RW_STATE.data.suppliers = sRes.data || [];
      } catch(e) {
        console.error('Suppliers load failed:', e);
        RW_STATE.data.suppliers = [];
      }
    }
```

### الجراحة 6 — M6-06

ابحث في `savePO`/success block عن إعادة تحميل `purchase_orders` التي تبدأ بـ:

```js
supabase.from('purchase_orders').select('*')
```

وفي المقطع الذي ينتهي باستدعاء:

```js
renderPOTable(poData);
```

استبدل **كتلة إعادة التحميل كاملة** بـ:

```js
              var companyId = _rwCompanyId();
              if (companyId) {
                supabase.from('purchase_orders')
                  .select('*')
                  .eq('company_id', companyId)
                  .order('po_date', { ascending: false })
                  .then(function(d) {
                    if (d.error) { showToast('تعذر تحديث قائمة أوامر الشراء','error'); return; }
                    poData = d.data || [];
                    renderPOTable(poData);
                  });
              }
```

### الجراحة 7 — M6-07

ابحث عن السطر الكامل داخل `openReceive` الذي يحتوي على:

```js
value="'+(it.qty_ordered||0)+'"
```

واجعل قيمة الـinput هي **المتبقي**:

```js
value="'+Math.max(0, Number(it.qty_ordered||0)-Number(it.qty_received||0))+'"
```

وفي نفس السطر أضف `max` مساويًا لنفس المتبقي حتى لا تسمح الواجهة بإدخال كمية أكبر من الرصيد المتبقي.

### الجراحة 8 — M6-09

ابحث عن المقطع الكامل الذي يبدأ بـ:

```js
    var ses=await supabase.auth.getSession(),t=ses.data.session&&ses.data.session.access_token;
```

وينتهي قبل:

```js
    try{
```

اجعل الكتلة:

```js
    var ses=await supabase.auth.getSession(),t=ses.data.session&&ses.data.session.access_token;
    if(!t){ hideLoader(); showToast('انتهت الجلسة','error'); return; }
```

---

## 9. قاعدة الدمج

بعد تنفيذ المستخدم للتعديلات أعلاه على `Current/PWA/main2/main6.md`:

1. تتم قراءة الملف كاملًا من أوله إلى آخر سطر.
2. تتم مراجعة أقواس/quotes/template literals/closures.
3. يتم مطابقة `window.RW_OnlineStore` و`window.RW_Purchases`.
4. يتم دمج الجزء مع بقية `main2`.
5. تتم مراجعة التكامل مع `core.js` / `sw.js` / `register-sw.js` / `manifest.json` قبل إعلان runtime closure.
6. يتم تنفيذ Browser/PWA verification على الملف الكامل، وليس على fragment فقط.

---

## 10. التجارب التي تمت

### نجح

- مطابقة Production PostgreSQL الحالية مع Edge Function contracts.
- التحقق من توقيع `receive_purchase_atomic` الحالي.
- التحقق من وجود `receiving.operation_id` وUNIQUE identity mechanism.
- التحقق من Company-scoped backend paths لـonline order وpurchase order وpurchase receiving.
- التحقق من `items.item_code` كـUNIQUE عالمي رسميًا.
- التحقق من عدم وجود `order_code` في `order_details`.

### لم يتم اعتباره Pass

لم يتم اعتبار `main6.md` Source Closed لأن الإصلاحات المصدرية لم تُدمج بعد في الملف المستهدف.

لم يتم اعتبار Browser Runtime Closed لأن التجربة النهائية يجب أن تتم على الملف الكامل بعد الدمج، وهو ما ينص عليه الإجراء المرحلي.

---

## 11. ما تم إثباته

```text
Production backend contract for Main6 = VERIFIED
Production tenant extraction for active Main6 Edge flows = VERIFIED
Production receiving idempotency contract = VERIFIED
Production item identity contract = VERIFIED
Main6 source contains tenant/read-key defects = VERIFIED
Main6 source surgical fixes = IDENTIFIED EXACTLY
```

## 12. ما لم يتم إثباته بعد

```text
main2/main6.md final source after user edits = NOT YET VERIFIED
full main2 merged file syntax = NOT YET VERIFIED
browser runtime of merged full parent file = NOT YET VERIFIED
realtime cross-app propagation after final merge = NOT YET VERIFIED
Main5 source sync to Git = NOT YET VERIFIED
```

## 13. القرار النهائي لهذه الجلسة

`MAIN6 SOURCE = OPEN / SURGERY SPECIFIED`

`MAIN6 PRODUCTION BACKEND = VERIFIED FOR CURRENT CONTRACT`

`MAIN6 RUNTIME = OPEN UNTIL FULL MERGE TEST`

ولا يجوز تسجيل `MAIN6 CLOSED 100%` قبل إعادة قراءة الملف بعد تنفيذ الجراحات والاختبار على الملف الأم الكامل.

---

## 14. Self-Audit

### What I Proved

- قارنت Main6 المستهدف نفسه، وليس Main6 آخر.
- راجعت Production الحالية بدل الاعتماد على تقرير تاريخي وحده.
- أثبت أن `order_details` لا يحتوي `order_code` وأن `order_id` هو الرابط الصحيح.
- أثبت أن active purchase/online backends الحالية Company-scoped.
- حددت إصلاحات source دقيقة وقابلة للتنفيذ اليدوي.

### What I Did Not Prove

- لم أثبت Browser Runtime بعد الدمج الكامل.
- لم أثبت أن المستخدم نفذ كل الجراحات في `main6.md`، لأن هذا التنفيذ خارج المساعد وفق القاعدة المتفق عليها.

### What I Fixed

Production backend لم يحتج لتعديل جديد خاص بـMain6 بعد المطابقة؛ source surgical instructions تم تحديدها.

### What I Initially Missed

تمت ملاحظة أن Report100 السابق كان خاصًا بمسار `Current/PWA/main/main6.md` وليس `Current/PWA/main2/main6.md`، وتم تصحيح ذلك قبل اعتماد أي closure claim.

### What Could Still Be Wrong

أخطر نقطة متبقية هي تنفيذ الجراحات يدويًا بشكل غير كامل ثم محاولة اعتبار الملف مغلقًا؛ لذلك يجب إعادة القراءة الكاملة بعد التنفيذ قبل الانتقال للدمج.

### Final Confidence

```text
Production contract confidence = HIGH
Source surgical diagnosis = HIGH
Final source closure confidence = NOT CLAIMED YET
Runtime closure confidence = NOT CLAIMED YET
```

### Final Closure Status

```text
MAIN6 = NOT CLOSED YET
REASON = Source surgical edits pending + full-parent runtime test pending
```