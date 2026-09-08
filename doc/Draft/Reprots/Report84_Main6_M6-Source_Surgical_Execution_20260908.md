# Report84 — Main6 M6-Source Surgical Execution / Forensic Reconciliation

## 1. نطاق الجلسة
المستهدف: `Current/PWA/main2/main6.md`، الجزء الرابع من النظام الأم المجزأ.
لم يتم تعديل main6 عبر الأدوات؛ ملكية التعديل اليدوي للمستخدم ثابتة.

## 2. مصادر التحقق
تمت مراجعة ملفات MASTER الثلاثة، `CURRENT_STATE.md`، Report82، Report83، `main5.md`، `main6.md`، `core.js` ذي الصلة، وتاريخ Git الحديث، إضافة إلى Production Supabase schema، Edge Functions، RPCs، grants والمهاجرات المرتبطة.

## 3. Git Reality
- HEAD الحالي وقت التدقيق: `e6f269afbb09b166143076d0ddc7d7c677fbf2df`.
- `main5.md` الحالي: blob `c4518d05ada50830e819563a55169843679d3e94`، وتوجد فيه جراحات M5-20 الأساسية بالفعل.
- `main6.md` الحالي: blob `87287d8da56a5411f9f31243b38b9c06dbf91d2b`.
- التحقق المباشر أظهر أن main6 لا يزال بالحالة الأصلية التي سجلها Report83.

## 4. Main5 Reconciliation
تم تجاوز تعارض `CURRENT_STATE` القديم الذي كان يشير إلى blob `9f992...`: Git الحالي يثبت blob أحدث `c451...`.
جراحات M5-20 الخاصة بصلاحية حذف Invoiced بقيت في المصدر، ولم يتم فتحها من جديد.
Runtime/Browser closure للـmain5 ما زال غير مثبت، لذلك لا يوجد Claim بأن main5 مغلق 100%.

## 5. Production Reality — Main6
Production project: `fiilmooggumokxanwiyx`.

- `submit-online-order` = v7 ACTIVE / JWT protected / يستخرج company_id من users.auth_id ويستدعي `submit_online_order_atomic`.
- `save-purchase-order` = v3 ACTIVE / JWT protected / يستدعي `save_purchase_order_atomic`.
- `receive-purchase` = v12 ACTIVE / JWT protected / يستدعي `receive_purchase_atomic` مع `p_operation_id`.
- `receive_purchase_atomic` يعتمد `receiving.operation_id` الموجود أصلًا والمقيد UNIQUE، وPhysical Stock يمر إلى `post_stock_movement`.

لم يثبت احتياج Migration جديدة خاصة بالـMain6 backend في هذه الجلسة، لذلك لم يتم إدخال تعديل Production بلا مبرر.

## 6. Production Schema Facts
- `items.item_code` = UNIQUE عالميًا.
- `order_details.order_code` غير موجود.
- `order_details.order_id` هو الرابط مع `orders`.
- `purchase_orders.company_id` = NOT NULL.
- `suppliers.company_id` = NOT NULL.
- `app_settings.company_id` = NOT NULL.
- `receiving.operation_id` = UNIQUE.

## 7. Main6 Defects Proven
M6-01 global app_settings lookup in Online Store.
M6-02 Track Order unscoped order lookup + invalid order_details.order_code lookup.
M6-03 unscoped purchase_orders list.
M6-04 unscoped PO lookup and premature detail query.
M6-05 unscoped suppliers load.
M6-06 unscoped purchase refresh.
M6-07 receive dialog uses ordered quantity instead of remaining quantity.
M6-08 Track Order item_name is not escaped before HTML insertion.
M6-09 savePO does not explicitly guard missing session token before fetch.

## 8. Exact Surgical Instructions
### M6-01
ابحث عن المقطع الكامل من:
```js
    try {
      var sRes = await supabase.from('app_settings').select('*').limit(1).single();
```
حتى:
```js
    } catch(e) {}
```
واحذفه كاملًا واستبدله:
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

### M6-02-A
احذف المقطع الكامل من:
```js
      var o = await supabase.from('orders').select('*').eq('order_code', input.value).maybeSingle();
```
حتى:
```js
      var it = await supabase.from('order_details').select('*').eq('order_code', input.value);
```
واستبدله:
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

### M6-02-B
ابحث عن السطر الكامل:
```js
      Swal.fire({ title: 'تفاصيل الطلب: ' + input.value, html: detailH, width: '700px', showCloseButton: true, showConfirmButton: false });
```
واحذفه واستبدله:
```js
      Swal.fire({ title: 'تفاصيل الطلب: ' + code, html: detailH, width: '700px', showCloseButton: true, showConfirmButton: false });
```

### M6-08
ابحث عن السطر الكامل الذي يبدأ بـ:
```js
          itemsH += '<tr><td class="p-2">'
```
ويحتوي:
```js
(i.item_name || '')
```
لا تحذف السطر كاملًا؛ استبدل التعبير `(i.item_name || '')` فقط بـ:
```js
esc(i.item_name || '')
```

### M6-03
ابحث عن السطر الكامل:
```js
    var res=await supabase.from('purchase_orders').select('*'); poData=res.data||[]; renderPOTable(poData);
```
واستبدله:
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

### M6-04
داخل `async function openReceive(poCode){` احذف المقطع الكامل الذي يبدأ:
```js
    var poRes=await supabase.from('purchase_orders').select('*').eq('po_code',poCode).maybeSingle();
```
وينتهي:
```js
    if(!poRes.data){ showToast('أمر الشراء غير موجود','error'); return; }
```
واستبدله:
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

### M6-05
ابحث عن السطر الكامل:
```js
    if (!RW_STATE.data.suppliers || !RW_STATE.data.suppliers.length) { try { var sRes = await supabase.from('suppliers').select('*'); RW_STATE.data.suppliers = sRes.data || []; } catch(e) {} }
```
واستبدله:
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

### M6-06
داخل نجاح حفظ أمر الشراء ابحث عن الكتلة الكاملة:
```js
              supabase.from('purchase_orders').select('*').then(function(d) {
                  poData = d.data || [];
                  renderPOTable(poData);
              });
```
واستبدلها:
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

### M6-07
ابحث عن السطر الكامل:
```js
      items.forEach(function(it,idx){ itemsH+='<tr><td class="p-2 font-semibold">'+(it.item_name||'')+'</td><td class="p-2 text-center font-bold">'+(it.qty_ordered||0)+'</td><td class="p-2 text-center"><input type="number" id="rec-qty-'+idx+'" value="'+(it.qty_ordered||0)+'" class="w-20 p-1 border rounded text-center" min="0"></td></tr>'; });
```
واستبدله:
```js
      items.forEach(function(it,idx){ var remaining=Math.max(0,Number(it.qty_ordered||0)-Number(it.qty_received||0)); itemsH+='<tr><td class="p-2 font-semibold">'+(it.item_name||'')+'</td><td class="p-2 text-center font-bold">'+(it.qty_ordered||0)+'</td><td class="p-2 text-center"><input type="number" id="rec-qty-'+idx+'" value="'+remaining+'" max="'+remaining+'" class="w-20 p-1 border rounded text-center" min="0"></td></tr>'; });
```

### M6-09
ابحث عن المقطعين المتجاورين الكاملين:
```js
    var ses=await supabase.auth.getSession(),t=ses.data.session&&ses.data.session.access_token;
    try{
```
واحذفهما واستبدلهما:
```js
    var ses=await supabase.auth.getSession(),t=ses.data.session&&ses.data.session.access_token;
    if(!t){ hideLoader(); showToast('انتهت الجلسة','error'); return; }
    try{
```

## 9. Realtime
لم تتم إضافة listener داخل main6. القرار مقصود: Production لديها Realtime foundation، لكن listener يجب أن يظل مركزيًا بعد دمج `core.js`/الوالد الكامل، لتجنب duplicate subscriptions وstate races.

## 10. ما تم اختباره
- main6 قرئ فعليًا من SOF إلى EOF؛ EOF = `window.RW_Purchases = RW_Purchases;`.
- `_rwCompanyId()` مثبت في `main2.md` ومستخدم بالفعل في main4/main5.
- Production backend versions والعقود أعيد التحقق منها مباشرة.
- لا توجد Migration Main6 جديدة مبررة.
- لا توجد بيانات أعمال Production عُدلت بسبب هذه المهمة.
- commit `4768d861...` لديه no CI statuses؛ هذا غياب دليل CI وليس Pass.

## 11. ما فشل / ما لم يثبت
- Main6 source surgery لم تنفذ لأن الملف مملوك للمستخدم حسب الاتفاق.
- Full parent syntax/E2E/Realtime runtime لم تُثبت بعد الدمج.
- لا يجوز إعلان Main6 Closed 100%.

## 12. Failure Memory
1. تقرير تاريخي عن `Current/PWA/main/main6.md` لا ينطبق على `Current/PWA/main2/main6.md`.
2. `CURRENT_STATE.md` كان يحمل blob قديمًا لـmain5؛ Git الحالي هو المرجع الأحدث.
3. لا تُضاف Realtime listeners محلية قبل مراجعة البنية المركزية.
4. لا تستخدم `LIMIT 1` بلا company scope عندما تكون الهوية company-bound.
5. لا تعتمد على `order_details.order_code` لأنه غير موجود في Production Schema.

## 13. Final Gate
```text
FORENSIC UNDERSTANDING = COMPLETE
PRODUCTION BACKEND VERIFICATION = COMPLETE
MAIN6 SOURCE SURGERY = PENDING USER EXECUTION
FULL-SOURCE RE-READ = PENDING
PARENT MERGE = PENDING
PARENT SYNTAX = PENDING
BROWSER/PWA E2E = PENDING
REALTIME CROSS-APP = PENDING
MAIN6 100% CLOSED = NOT CLAIMED
```

## 14. Next authorized action
بعد تنفيذ المستخدم للتعديلات التسع أعلاه:
1. إعادة قراءة main6 من SOF إلى EOF.
2. مطابقة كل نافذة استبدال حرفيًا.
3. فحص الأقواس والquotes وإغلاق IIFEs.
4. مطابقة EOF.
5. ثم دمج main2.
6. مراجعة core.js/sw.js/register-sw.js/manifest.json.
7. Full parent syntax + browser/PWA E2E + Realtime verification.
8. Production snapshot جديد في لحظة التقرير.

لا تنقل أي Closure claim من main6 القديم، ولا تعلن Production Pass من source-only evidence.
