# Report83 — Main6 Forensic Surgical Reconciliation — 2026-09-08

## 1. نطاق الجلسة

المستهدف الوحيد:

`Current/PWA/main2/main6.md`

وهو الجزء الرابع من الملف الأصلي المجزأ `main2`.

وفق الاتفاق الحاكم، لا يقوم المساعد بتعديل `main2/main6.md` مباشرة؛ المستخدم ينفذ الجراحات المصدرية يدويًا. أما Production فيتم تعديلها من خلال المساعد عند ثبوت الحاجة.

---

## 2. المصادر التي تمت مراجعتها

تمت مراجعة:

- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `CURRENT_STATE.md`
- `doc/Draft/Reprots/Report82_Main5_M5-20_Historical_Contract_Reconciliation_20260908.md`
- `doc/Draft/medhat/تقرير 100 - main6 forensic closure.md`
- `Current/PWA/main2/main5.md`
- `Current/PWA/main2/main6.md`
- تاريخ Git والـcommits المرتبطة بـMAIN6.

كما تمت مطابقة Production Supabase: schema، RPCs، Edge Functions، dependencies، وTenant/Item identity contracts.

---

## 3. تصحيح نقطة الاستمرارية المهمة

التقرير السابق:

`doc/Draft/medhat/تقرير 100 - main6 forensic closure.md`

كان خاصًا بالمسار:

`Current/PWA/main/main6.md`

وليس:

`Current/PWA/main2/main6.md`

لذلك لم يتم نقل أي closure claim من الملف الأول إلى الملف المستهدف هنا.

---

## 4. حالة Main5 أثناء التدقيق

Current Git ما زال يسجل:

```text
PATH = Current/PWA/main2/main5.md
BLOB = 9f9926511c47f0295019daaf09ff4b5a1a2efc50
SOURCE = OPEN
RUNTIME = OPEN
```

وعليه لا يمكن اعتماد `main5 = Closed 100%` من المصدر المنشور حاليًا، حتى مع تنفيذ المستخدم لتعديلات محلية لم تُدفع إلى Git بعد.

لم يتم تعديل Main5 في هذه الجلسة.

---

## 5. Production Reality — Main6 Backend

### Online Store

```text
submit-online-order = v7 ACTIVE
VERIFY_JWT = true
```

ويستخرج `company_id` من `users.auth_id` ثم يستدعي:

`submit_online_order_atomic`

والـRPC يحسب القيمة اعتمادًا على Item Master الحالي، ويقرأ إعدادات المتجر ضمن الشركة، وينشئ `orders` و`order_details` داخل الشركة.

### Purchase Order

```text
save-purchase-order = v3 ACTIVE
VERIFY_JWT = true
```

ويستدعي:

`save_purchase_order_atomic`

والـRPC يتحقق من المورد والشركة والصنف ولا ينفذ Physical Stock مباشرة.

### Purchase Receiving

```text
receive-purchase = v12 ACTIVE
VERIFY_JWT = true
```

والتوقيع الحالي في Production:

```text
receive_purchase_atomic(
  p_company_id uuid,
  p_po_code text,
  p_user_email text,
  p_items jsonb,
  p_operation_id uuid
)
```

والـRPC الحالي:

- يتطلب `p_operation_id`.
- يثبت العملية داخل `receiving.operation_id` الموجود أصلًا والمقيد بـUNIQUE.
- يتحقق من الشركة والـPO والـitem identity.
- يمرر Physical Stock إلى `post_stock_movement`.
- يمرر accounting إلى `post_journal_entry`.
- يمرر Supplier Ledger إلى `post_supplier_ledger_entry`.

إذن Main6 Production backend متوافق حاليًا مع العقد ولم يثبت احتياج Migration جديدة تخص هذه المسارات.

---

## 6. Production Schema Evidence

تم إثبات:

```text
items.item_code = UNIQUE globally
order_details لا يحتوي order_code
order_details يرتبط بالطلب عبر order_id
purchase_orders.company_id = NOT NULL
suppliers.company_id = NOT NULL
app_settings.company_id = NOT NULL
receiving.operation_id = UNIQUE
```

وهذه الحقائق هي أساس الجراحات المصدرية أدناه.

---

## 7. Main6 Forensic Findings

### M6-01

`RW_OnlineStore.render()` يستخدم Global Lookup على `app_settings`:

```js
supabase.from('app_settings').select('*').limit(1).single()
```

هذا Tenant-unscoped.

### M6-02

`RW_OnlineStore.trackOrder()`:

1. يبحث عن `orders` بدون `company_id`.
2. يبحث عن `order_details` بواسطة `order_code`، بينما هذا العمود غير موجود في Production Schema.

الصحيح هو `order_id` بعد العثور على الطلب.

### M6-03

`RW_Purchases.renderOrders()` يقرأ `purchase_orders` بدون `company_id`.

### M6-04

`RW_Purchases.openReceive()`:

- يقرأ PO بدون `company_id`.
- يحاول قراءة التفاصيل قبل الحارس الصريح على وجود PO/خطئه.

### M6-05

تحميل الموردين يستخدم Global Lookup بدون Company Scope.

### M6-06

إعادة تحميل قائمة أوامر الشراء بعد العملية تستخدم Global Lookup.

### M6-07

حوار الاستلام الافتراضي يعرض `qty_ordered` بدل الكمية المتبقية:

`qty_ordered - qty_received`

### M6-08

يوجد helper باسم `esc()` داخل Online Store، لكن `item_name` في Track Order لا يمر عبره قبل إدخاله في HTML.

### M6-09

`savePO()` يستخرج access token لكن لا يحتوي حارسًا صريحًا قبل `fetch()` إذا كانت الجلسة منتهية.

---

## 8. التعليمات الجراحية الدقيقة للمستخدم

## M6-01 — Online Store Settings

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

## M6-02 — Track Order

ابحث عن المقطع الكامل الذي يبدأ بـ:

```js
      var o = await supabase.from('orders').select('*').eq('order_code', input.value).maybeSingle();
```

وينتهي بالسطر الكامل:

```js
      var it = await supabase.from('order_details').select('*').eq('order_code', input.value);
```

احذف المقطع كاملًا واستبدله بـ:

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

واحذفه واستبدله بـ:

```js
      Swal.fire({ title: 'تفاصيل الطلب: ' + code, html: detailH, width: '700px', showCloseButton: true, showConfirmButton: false });
```

ثم ابحث عن **السطر الكامل الذي يبدأ** بـ:

```js
        itemsH += '<tr><td class="p-2">'
```

وفيه التعبير:

```js
(i.item_name || '')
```

احذف هذا التعبير فقط واستبدله بـ:

```js
esc(i.item_name || '')
```

## M6-03 — Purchase Orders List

ابحث عن السطر الكامل:

```js
    var res=await supabase.from('purchase_orders').select('*'); poData=res.data||[]; renderPOTable(poData);
```

احذفه واستبدله بـ:

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

## M6-04 — Open Receive

ابحث داخل `async function openReceive(poCode){` عن المقطع الكامل الذي يبدأ بـ:

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

## M6-05 — Suppliers

ابحث عن **السطر الكامل**:

```js
    if (!RW_STATE.data.suppliers || !RW_STATE.data.suppliers.length) { try { var sRes = await supabase.from('suppliers').select('*'); RW_STATE.data.suppliers = sRes.data || []; } catch(e) {} }
```

احذفه واستبدله بـ:

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

## M6-06 — Purchase Refresh

ابحث داخل نجاح حفظ أمر الشراء عن **كتلة إعادة التحميل التي تحتوي حرفيًا على**:

```js
supabase.from('purchase_orders').select('*')
```

والتي تنتهي باستدعاء:

```js
renderPOTable(poData);
```

واستبدل **كتلة إعادة التحميل كاملة** بـ:

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

## M6-07 — Remaining Quantity

ابحث عن **السطر الكامل** داخل `items.forEach(function(it,idx){...` الذي يحتوي:

```js
<td class="p-2 text-center"><input type="number" id="rec-qty-
```

وينتهي بهذه البنية الحالية:

```js
value="'+(it.qty_ordered||0)+'" class="w-20 p-1 border rounded text-center" min="0"></td></tr>
```

احذف السطر كاملًا واستبدله بـ:

```js
      items.forEach(function(it,idx){ var remaining=Math.max(0,Number(it.qty_ordered||0)-Number(it.qty_received||0)); itemsH+='<tr><td class="p-2 font-semibold">'+(it.item_name||'')+'</td><td class="p-2 text-center font-bold">'+(it.qty_ordered||0)+'</td><td class="p-2 text-center"><input type="number" id="rec-qty-'+idx+'" value="'+remaining+'" max="'+remaining+'" class="w-20 p-1 border rounded text-center" min="0"></td></tr>'; });
```

هذا السطر كامل وينتهي بـ:

```text
});
```

## M6-09 — Session Token Guard

ابحث عن المقطع الكامل:

```js
    var ses=await supabase.auth.getSession(),t=ses.data.session&&ses.data.session.access_token;
    try{
```

واستبدله بـ:

```js
    var ses=await supabase.auth.getSession(),t=ses.data.session&&ses.data.session.access_token;
    if(!t){ hideLoader(); showToast('انتهت الجلسة','error'); return; }
    try{
```

---

## 9. Realtime

لم تتم إضافة listener جديد داخل Main6.

السبب الحاكم: يجب ألا نكرر Realtime infrastructure محليًا قبل مراجعة `core.js` والملف الكامل بعد الدمج؛ وإلا يمكن إنتاج duplicate subscriptions أو state races.

Realtime Main6 ينتقل إلى بوابة التكامل بعد الدمج.

---

## 10. ما تم اختباره في Production

تم إثبات:

```text
submit-online-order v7 = ACTIVE
save-purchase-order v3 = ACTIVE
receive-purchase v12 = ACTIVE
receive_purchase_atomic signature = ALIGNED WITH EDGE v12
receiving.operation_id = UNIQUE
items.item_code = UNIQUE
order_details.order_code = DOES NOT EXIST
order_details.order_id = EXISTS
```

لم يتم إدخال بيانات اختبار دائمة.

لم يتم تعديل بيانات أعمال Production بسبب Main6 في هذه الجلسة.

---

## 11. ما نجح وما لم يُغلق

### نجح

- الاسترداد الجنائي للسياق.
- تمييز Main6 المستهدف عن Main6 القديم في مسار مختلف.
- مطابقة Production backend الحالية مع عقود Main6.
- إثبات جميع نقاط القراءة tenant-unsafe الموجودة في المصدر الحالي.
- تحديد بدائل جراحية كاملة ومحددة.

### لم يُغلق

```text
main6.md source surgery = PENDING USER EXECUTION
main6 full source re-read = PENDING
main2 full merge = PENDING
full parent syntax validation = PENDING
browser/PWA E2E = PENDING
Realtime cross-app verification = PENDING
```

---

## 12. Self-Audit

### Confirmed Facts

- Production الحالية هي `fiilmooggumokxanwiyx`.
- Active backend versions المذكورة أعلاه تم التحقق منها مباشرة.
- `receive_purchase_atomic` الحالي يستخدم `p_operation_id` و`receiving.operation_id`.
- Physical Stock في Purchase Receiving يمر عبر `post_stock_movement`.
- `order_details` لا يملك `order_code`.
- `items.item_code` فريد عالميًا رسميًا.

### Unknowns

- لا يوجد حاليًا Browser E2E نهائي بعد دمج Main6 مع الملف الأم الكامل.
- لم يتم إثبات runtime closure للجزء قبل تنفيذ الجراحات.

### Conflicts

- يوجد فرق بين claim المستخدم بأن Main5 أُغلق محليًا وبين حالة Main5 المنشورة في Git.
- يوجد تقرير تاريخي عن `Current/PWA/main/main6.md` لا يجوز تطبيقه على `main2/main6.md`.

### Unverified Claims

```text
MAIN6 CLOSED 100% = UNVERIFIED
FULL-PARENT RUNTIME PASS = UNVERIFIED
REALTIME FINAL PASS = UNVERIFIED
```

---

## 13. النتيجة النهائية

```text
MAIN6 FORENSIC UNDERSTANDING = COMPLETE
MAIN6 SURGERIES = IDENTIFIED EXACTLY
MAIN6 PRODUCTION BACKEND = VERIFIED
MAIN6 SOURCE = OPEN
MAIN6 RUNTIME = OPEN
MAIN6 100% CLOSED = NOT CLAIMED
```

لا يوجد نصف حل معلن كحل نهائي.

---

## 14. بوابة الجلسة التالية

بعد أن ينفذ المستخدم الجراحات أعلاه:

```text
1. إعادة قراءة Current/PWA/main2/main6.md من SOF إلى EOF.
2. التحقق من كل نافذة استبدال.
3. التحقق من الأقواس والـquotes والـclosures.
4. مطابقة نهاية الملف:
   window.RW_OnlineStore = RW_OnlineStore;
   window.RW_Purchases = RW_Purchases;
5. دمج main2.
6. مراجعة core.js / sw.js / register-sw.js / manifest.json.
7. Full parent syntax check.
8. Browser/PWA E2E.
9. Realtime verification.
10. Production re-snapshot في لحظة التقرير.
```

حتى ذلك الحين لا يُسمح بإعلان Main6 Closed 100%.
