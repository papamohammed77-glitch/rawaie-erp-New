# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-08

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT MAIN HEAD = 523fce99b65c0cd7614cf31d6cbff9c649590429
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
LATEST FORENSIC REPORT = doc/Draft/Reprots/Report84_Main6_M6-Source_Surgical_Execution_20260908.md
```

## GOVERNANCE — NON-NEGOTIABLE

```text
CURRENT REALITY > CURRENT GIT > CURRENT PRODUCTION > CURRENT DEPLOYMENTS > CURRENT DATABASE CONTRACTS > VERIFIED ARTIFACTS > HISTORY > REPORTS > MEMORY > ASSUMPTIONS

READ → VERIFY → RECONCILE → UNDERSTAND → PATCH → TEST → DEPLOY → VERIFY PRODUCTION → DOCUMENT → UPDATE CURRENT_STATE

UNKNOWN != BUG
UNKNOWN != REMOVE
SOURCE != RUNTIME PROOF
GIT != PRODUCTION PROOF
NO CLOSURE CLAIM WITHOUT CURRENT EVIDENCE
ONE CLOSURE UNIT AT A TIME
```

## ARCHITECTURAL CONTRACTS

### Physical Stock

```text
PHYSICAL STOCK MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

`reserve_stock` / `release_stock_reservation` are Reservation Engines only.
No other Writer may mutate Physical Stock independently.

### Tenant / Company

Authenticated user must resolve through `users.auth_id → users.company_id` and all company-bound operational reads/writes must use that company context.
Do not use global `LIMIT 1` for company-bound identity.

### Item Identity

Current Production Schema proves:

```text
items.item_code = UNIQUE globally
```

Therefore `item_code` may remain the global Item Master identity where the schema contract explicitly makes it global. Company-bound tables still require their own `company_id` / branch relationship checks.

### Fulfillment Identity

```text
order_details.order_id → orders.id
```
`order_details.order_code` does not exist in Production and must not be used.

### Realtime

Realtime infrastructure should be centralized after full-parent integration. Do not create duplicate local subscriptions in individual fragments before `core.js` / parent runtime architecture is verified.

## MAIN4

```text
PATH = Current/PWA/main2/main4.md
BLOB = e89d29e4164c68784c109292f27d4d77df240557
SOURCE = CLOSED
RUNTIME = OPEN
```

## MAIN5

Current Git has moved beyond the stale state reference that was previously stored in `CURRENT_STATE.md`.

```text
PATH = Current/PWA/main2/main5.md
CURRENT BLOB = c4518d05ada50830e819563a55169843679d3e94
CURRENT SOURCE EOF = window.RW_Runsheets = RW_Runsheets;
```

M5-20 source reconciliation is present in the current Git source. The `Invoiced` deletion capability remains intentionally preserved for the historical/authorized manager path and must NOT be reverted to Report81's superseded remove-Invoiced decision.

Production M5-20 capability remains:

```text
public.delete_order_atomic
Edge = delete-order v9 ACTIVE
VERIFY_JWT = true
```

Main5 runtime/browser/full-parent closure remains OPEN until demonstrated after final integration.

## MAIN6 — CURRENT TARGET

```text
PATH = Current/PWA/main2/main6.md
BLOB = 87287d8da56a5411f9f31243b38b9c06dbf91d2b
PART = fourth fragment of main2
SOURCE = OPEN / SURGERY SPECIFIED
RUNTIME = OPEN
```

The file was read from SOF through EOF. Current EOF is:

```js
window.RW_Purchases = RW_Purchases;
```

No source modification to Main6 was performed by the assistant. This is intentional and must remain so: the user owns manual source surgery for `Current/PWA/main2/main6.md`.

## MAIN6 — PRODUCTION REALITY VERIFIED

```text
submit-online-order = v7 ACTIVE / verify_jwt=true
save-purchase-order = v3 ACTIVE / verify_jwt=true
receive-purchase = v12 ACTIVE / verify_jwt=true
```

Current `receive_purchase_atomic` signature:

```text
p_company_id uuid,
p_po_code text,
p_user_email text,
p_items jsonb,
p_operation_id uuid
```

`receive_purchase_atomic` uses existing `receiving.operation_id`, which is UNIQUE, and delegates Physical Stock to `post_stock_movement`.

No new Main6-specific Production migration was justified at this checkpoint; no Production business data was changed because of Main6 in this session.

## MAIN6 — VERIFIED SOURCE DEFECTS

```text
M6-01 = Online Store app_settings global lookup
M6-02 = Track Order missing company scope + invalid order_details.order_code lookup
M6-03 = Purchase Orders list missing company scope
M6-04 = Open Receive missing company scope + detail query before PO guard
M6-05 = Suppliers load missing company scope
M6-06 = Purchase refresh missing company scope
M6-07 = Receive dialog defaults to qty_ordered instead of remaining quantity
M6-08 = Track Order item_name not escaped before HTML insertion
M6-09 = savePO lacks explicit token guard before fetch
```

## MAIN6 — EXACT SURGERY REFERENCE

The exact complete replacement windows are recorded in:

```text
doc/Draft/Reprots/Report83_Main6_M6-Forensic_Surgical_Reconciliation_20260908.md
doc/Draft/Reprots/Report84_Main6_M6-Source_Surgical_Execution_20260908.md
```

The user must execute all nine source surgeries exactly and not alter adjacent code outside the specified windows.

### M6-01
Replace the complete settings-load try/catch in `RW_OnlineStore.render()`:

```js
    try {
      var sRes = await supabase.from('app_settings').select('*').limit(1).single();
      if (!sRes.error && sRes.data) {
        deliveryFee = Number(sRes.data.delivery_fee) || 0;
        taxRate = Number(sRes.data.tax_rate) || 0;
      }
    } catch(e) {}
```

with:

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
In `trackOrder()` replace the complete block beginning with:

```js
      var o = await supabase.from('orders').select('*').eq('order_code', input.value).maybeSingle();
```

and ending with:

```js
      var it = await supabase.from('order_details').select('*').eq('order_code', input.value);
```

with:

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
Replace the full title line:

```js
      Swal.fire({ title: 'تفاصيل الطلب: ' + input.value, html: detailH, width: '700px', showCloseButton: true, showConfirmButton: false });
```

with:

```js
      Swal.fire({ title: 'تفاصيل الطلب: ' + code, html: detailH, width: '700px', showCloseButton: true, showConfirmButton: false });
```

### M6-08
In the complete Track Order item row, replace only the expression:

```js
(i.item_name || '')
```

with:

```js
esc(i.item_name || '')
```

Do not delete the rest of the line.

### M6-03
Replace this complete line:

```js
    var res=await supabase.from('purchase_orders').select('*'); poData=res.data||[]; renderPOTable(poData);
```

with:

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
Inside `async function openReceive(poCode){`, replace the complete block beginning with:

```js
    var poRes=await supabase.from('purchase_orders').select('*').eq('po_code',poCode).maybeSingle();
```

and ending with:

```js
    if(!poRes.data){ showToast('أمر الشراء غير موجود','error'); return; }
```

with:

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
Replace this complete line:

```js
    if (!RW_STATE.data.suppliers || !RW_STATE.data.suppliers.length) { try { var sRes = await supabase.from('suppliers').select('*'); RW_STATE.data.suppliers = sRes.data || []; } catch(e) {} }
```

with:

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
After successful purchase-order save, replace this complete reload block:

```js
              supabase.from('purchase_orders').select('*').then(function(d) {
                  poData = d.data || [];
                  renderPOTable(poData);
              });
```

with:

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
Replace the complete receive-row line:

```js
      items.forEach(function(it,idx){ itemsH+='<tr><td class="p-2 font-semibold">'+(it.item_name||'')+'</td><td class="p-2 text-center font-bold">'+(it.qty_ordered||0)+'</td><td class="p-2 text-center"><input type="number" id="rec-qty-'+idx+'" value="'+(it.qty_ordered||0)+'" class="w-20 p-1 border rounded text-center" min="0"></td></tr>'; });
```

with:

```js
      items.forEach(function(it,idx){ var remaining=Math.max(0,Number(it.qty_ordered||0)-Number(it.qty_received||0)); itemsH+='<tr><td class="p-2 font-semibold">'+(it.item_name||'')+'</td><td class="p-2 text-center font-bold">'+(it.qty_ordered||0)+'</td><td class="p-2 text-center"><input type="number" id="rec-qty-'+idx+'" value="'+remaining+'" max="'+remaining+'" class="w-20 p-1 border rounded text-center" min="0"></td></tr>'; });
```

### M6-09
Replace the complete adjacent pair:

```js
    var ses=await supabase.auth.getSession(),t=ses.data.session&&ses.data.session.access_token;
    try{
```

with:

```js
    var ses=await supabase.auth.getSession(),t=ses.data.session&&ses.data.session.access_token;
    if(!t){ hideLoader(); showToast('انتهت الجلسة','error'); return; }
    try{
```

## MAIN6 — TESTED / VERIFIED BEFORE USER SURGERY

Confirmed from current Production:

```text
items.item_code UNIQUE globally
order_details.order_code DOES NOT EXIST
order_details.order_id EXISTS
purchase_orders.company_id NOT NULL
suppliers.company_id NOT NULL
app_settings.company_id NOT NULL
receiving.operation_id UNIQUE
```

Confirmed current backend consumers are aligned:

```text
submit-online-order v7
save-purchase-order v3
receive-purchase v12
```

No new Main6 Production migration is justified at this checkpoint.

## MAIN6 — FAILURE MEMORY

```text
1. Do not apply the old Report100 closure because it targeted Current/PWA/main/main6.md, not Current/PWA/main2/main6.md.
2. Do not trust the stale Main5 SHA in older CURRENT_STATE entries; current Git source is the authority for current source state.
3. Do not add local Main6 Realtime listeners before shared core.js / parent runtime integration is checked.
4. Do not use order_details.order_code.
5. Do not use global LIMIT 1 for company-bound operational data.
6. Do not declare source success as runtime success.
```

## MAIN6 — CURRENT GATE

```text
FORENSIC UNDERSTANDING = COMPLETE
PRODUCTION BACKEND VERIFICATION = COMPLETE
SOURCE SURGERY = PENDING USER EXECUTION
SOURCE RE-READ = PENDING
EOF VALIDATION = PENDING
MAIN2 MERGE = PENDING
PARENT core.js/sw.js/register-sw.js/manifest.json REVIEW = PENDING
FULL PARENT SYNTAX = PENDING
BROWSER/PWA E2E = PENDING
REALTIME CROSS-APP = PENDING
PRODUCTION SNAPSHOT AT FINAL REPORT = PENDING
MAIN6 100% CLOSED = NOT CLAIMED
```

## REPORT HISTORY

```text
Report82 = Main5 M5-20 historical contract reconciliation + Production capability restoration
Report83 = Main6 forensic surgical reconciliation
Report84 = Main6 current-source revalidation + exact surgical execution record
```

No previous report was deleted.

## NEXT SESSION ENTRY POINT

Do not start from zero.

Start with:

```text
LATEST REPORT = Report84
LATEST STATE = CURRENT_STATE.md
LATEST MAIN HEAD = 523fce99b65c0cd7614cf31d6cbff9c649590429
MAIN6 TARGET = Current/PWA/main2/main6.md
MAIN6 BLOB = 87287d8da56a5411f9f31243b38b9c06dbf91d2b
MAIN6 SOURCE SURGERY = USER PENDING
MAIN6 PRODUCTION BACKEND = VERIFIED / NO NEW PATCH REQUIRED
MAIN5 CURRENT BLOB = c4518d05ada50830e819563a55169843679d3e94
```

The first action after the user completes the Main6 source edits is:

```text
READ MAIN6 SOF → EOF
COMPARE EVERY SURGERY WINDOW
CHECK BRACES / QUOTES / IIFEs
VERIFY EOF = window.RW_Purchases = RW_Purchases;
THEN PROCEED TO MAIN2 FULL MERGE
```

Do not claim Main6 Closed 100% before source, merge, parent syntax, browser/PWA E2E, Realtime verification, and a fresh Production snapshot are all proven.