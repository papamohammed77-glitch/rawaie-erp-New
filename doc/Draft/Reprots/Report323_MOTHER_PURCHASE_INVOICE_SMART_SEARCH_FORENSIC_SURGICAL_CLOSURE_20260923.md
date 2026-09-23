# تقرير 323 — التحقيق الجنائي والإغلاق الجراحي لمودال فواتير الشراء — 2026-09-23

## 1. نقطة البداية المعتمدة

تم البدء من أحدث حالة قابلة للإثبات وليس من الذاكرة أو التقارير كحقيقة حالية.

### Current Mother Frontend

- Repository: `papamohammed77-glitch/erp-frontend`
- Current HEAD before owner patch: `8a12be7d7faf3294131e7b51de810d6e040a8faf`
- Direct parent: `2a8ce1d41e0af948bbec99ef947a3aaa492b13a5`
- Current `companies/company-1/main.html` blob: `71aec095f7c20a92b8f19b4cbc3e7bc237941ef1`
- Commit `8a12be7d...` يغير فقط label في تبويب المخازن، ولا يغير Purchase.
- `main.html` لم يُكتب إليه من المساعد.

### Production Purchase

Production الحالية أثبتت وجود البنية التالية:

- `purchase_invoices`
- `purchase_invoice_details`
- `purchase_orders`
- `purchase_order_details`
- `suppliers`
- `supplier_ledger`
- `stock_branches`
- `inventory_log`
- `journal_entries`
- `chart_of_accounts`

والقدرات الحالية:

- `purchase_create_invoice_atomic`
- `purchase_post_invoice_atomic`
- `save-purchase-order` Edge Function

لا توجد حاجة لإنشاء Edge Function جديدة.

## 2. الحقيقة الحالية لبيانات Production

في لحظة التحقق:

- active suppliers = 0
- active items = 16
- active branches = 4
- purchase_orders = 0
- purchase_invoices = 0
- purchase_invoice_details = 0
- supplier_ledger rows = 0
- Purchase journal entries = 0
- inventory_log rows = 6
- purchase_settings rows = 0

إذن لا توجد دورة شراء حقيقية يمكن استعمالها كـBrowser fixture دائم.

تم الالتزام بـTransaction/Rollback في اختبارات الإنتاج، ولم تُترك أي بيانات QA.

## 3. Root Cause — Supplier

العنصر الحالي في `RW_PurchaseGold.createInvoice()` هو:

`<select id="pg-i-supplier" ...>`

وهو مبني من:

`getData('suppliers')`

ثم يحول الموردين إلى `<option>`.

النتيجة:

- لا يوجد Supplier Search field حقيقي.
- لا يوجد بحث مباشر متعدد الحقول.
- لا يوجد selected supplier state مستقل عن UI text.
- البحث غير مناسب للتوسع إلى عدد كبير من الموردين.

### الحقول التي يدعمها Production Supplier Master

- supplier_code
- name
- search_label
- phone
- contact_person
- purchase_rep

تم تصميم البحث الجديد ليبحث في هذه الحقول مع company scoping وactive filter.

## 4. Root Cause — Item

العنصر الحالي:

`<input id="pg-i-code" ...>`

ويتم التحقق منه عبر:

`purchaseItemLookup(code)`

مع exact lookup على:

`items.item_code`

هذا ليس Smart Search؛ إنه exact lookup فقط.

Production أثبتت أن:

`items.item_code`

عليه UNIQUE constraint عالمي، لذلك لا يجوز اختراع Company+Item-Code كمفتاح جديد للمقارنة.

البحث الجراحي الجديد يستخدم:

- item_code
- name
- barcode
- search_label

مع tokenized multi-field matching وترتيب exact/prefix matches أولًا.

## 5. Root Cause — Supplier Invoice Reference

المودال الحالي يحتوي على:

`pg-i-supplier-no`

لكن بعد `preConfirm` يتم تنفيذ:

`delete r.value.supplier_invoice_no;`

وبذلك كان الرقم يُجمع من المستخدم ثم يُحذف قبل الوصول إلى Production.

هذا ثبت كفجوة حقيقية لأن:

- `purchase_invoices.supplier_invoice_no` موجود في Production.
- العمود nullable.
- الـpurchase invoice contract الحالي لا يستقبل الحقل.

### الإصلاح Production

تم إنشاء امتداد ذري رفيع:

`purchase_create_invoice_atomic_v2`

وهو لا يعيد بناء محرك الفاتورة؛ بل يستدعي:

`purchase_create_invoice_atomic`

ثم يحفظ:

- supplier_invoice_no
- notes

داخل نفس المعاملة.

المصدر القانوني الجديد:

`supabase/migrations/20260923_purchase_invoice_reference_extension.sql`

Production migration deployed successfully.

## 6. Existing Edge — تم تحديث الموجود فقط

تم تحديث نفس Edge:

`save-purchase-order`

من Version 6 إلى:

- Version 7
- ACTIVE
- verify_jwt = true

وأصبح CREATE_INVOICE يمرر:

- supplier
- branch
- PO
- due date
- currency
- supplier invoice number
- notes
- items
- operation id

إلى:

`purchase_create_invoice_atomic_v2`

لا توجد Edge Function جديدة.

المصدر الحالي في System Repo تم تحديثه إلى Production Version 7.

## 7. Production E2E — إنشاء + ترحيل + المخزون + المورد + المحاسبة

تم تنفيذ اختبار Transactional كامل على Production ثم Rollback.

### Test A — Purchase Invoice Core

نجح:

1. إنشاء Supplier مؤقت.
2. إنشاء Purchase Invoice.
3. إضافة Item حقيقي من Production.
4. تحديد Branch حقيقي.
5. Post Invoice.
6. Physical Stock movement عبر `post_stock_movement`.
7. Inventory Log.
8. Supplier Ledger.
9. Journal Entry.
10. Invoice Detail received_qty.
11. Rollback.

النتيجة:

`E2E_CREATE_POST_STOCK_AP_JOURNAL = PASS`

### Test B — Idempotency

تم تنفيذ:

- CREATE بنفس operation_id مرتين.
- POST لنفس invoice مرتين.
- التحقق من أن الحركة الفيزيائية لم تتكرر.
- التحقق من أن Supplier Ledger لم يتكرر.

النتيجة:

`E2E_IDEMPOTENCY = PASS`

### Test C — v2 Supplier Reference

تم تنفيذ:

- CREATE باستخدام `supplier_invoice_no`
- إعادة CREATE بنفس operation_id
- التحقق من duplicate=true
- التحقق من حفظ supplier_invoice_no
- POST
- التحقق من stock delta
- inventory_log count
- supplier_ledger
- journal entry
- rollback

النتيجة:

`V2_PURCHASE_INVOICE_E2E = PASS`

## 8. Smart Search Database Predicate Test

تم إنشاء Supplier QA داخل Transaction فقط، ثم اختبار:

- name
- supplier_code
- phone
- search_label

ثم اختبار Item lookup على Item حقيقي.

النتيجة:

`SUPPLIER_SMART_SEARCH_PREDICATE = PASS`

`ITEM_SMART_SEARCH_PREDICATE = PASS`

ثم ROLLBACK.

لا QA supplier بقي في Production.

## 9. مقارنة نمط العمل مع الأنظمة المرجعية

### Odoo

Vendor Bill يدعم Vendor، Bill Reference، Bill Date، Accounting Date، Payment Reference، Due Date/Payment Terms، Journal، وربط bill بالـpurchase order، مع توليد القيد عند التأكيد. Odoo يوضح أيضًا أن عدة bills يمكن أن ترتبط بنفس PO في حالات الشحنات أو الفوترة الجزئية.

المصدر الرسمي:
https://www.odoo.com/documentation/19.0/applications/finance/accounting/vendor_bills.html

### Microsoft Dynamics 365

Vendor Invoice workflow يوضح:
- Vendor lookup
- Item lookup
- PO
- Product Receipt
- Invoice
- Two-way / Three-way matching
- Price and quantity discrepancies
- Workflow review
- Matching details

المصادر الرسمية:
https://learn.microsoft.com/en-us/dynamics365/finance/accounts-payable/vendor-invoices-overview
https://learn.microsoft.com/en-us/dynamics365/finance/accounts-payable/accounts-payable-invoice-matching

### SAP S/4HANA

Supplier Invoice يدعم:
- Supplier invoice reference
- Invoice date
- PO reference
- invoice items
- quantity
- amount
- tax
- posting
- verification against PO / Goods Receipt

المصادر الرسمية:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/031c345485b84c8c94265be9ef61d3a8/4e246b54f94c8f4ce10000000a4450e5.html
https://help.sap.com/docs/s4hana-cloud-best-practices/seasons-for-retail-6di-jp/create-supplier-invoice-using-purchase-order

### النتيجة المعمارية

المودال المقترح لـRAWAEA يجب أن يحافظ على:
Header + Supplier + Source Document + Branch + Item Lines + Commercial Values + Validation + Posting + Audit/Idempotency.

ولا يحتاج RAWAEA إلى نسخ واجهات المنافسين؛ المطلوب هو إغلاق نفس العقود التشغيلية.

## 10. Exact Owner Surgical Patches — main.html

### PATCH-323-00 — helper block

**الملف:** `companies/company-1/main.html`

**الموضع الحالي:** `RW_PurchaseGold` → الدالة:

`async function purchaseItemLookup(code) {`

**رقم السطر الحالي:** حوالي 12105 في الـHEAD الحالي.

**الإجراء:**
ابحث عن الدالة الكاملة:

`async function purchaseItemLookup(code) {`

واحذفها كاملة فقط.

**البديل الكامل:**

```javascript
  async function purchaseItemLookup(code) {
    code = String(code || '').trim();
    if (!code) throw new Error('كود الصنف مطلوب');

    var r = await supabase
      .from('items')
      .select('id,item_code,name,unit,barcode,search_label,cost_price')
      .eq('item_code', code)
      .maybeSingle();

    if (r.error) throw r.error;
    if (!r.data) throw new Error('الصنف غير موجود: ' + code);

    return r.data;
  }

  function purchaseSearchTokens(value) {
    return String(value || '')
      .trim()
      .toLowerCase()
      .replace(/[,|()]/g, ' ')
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 4);
  }

  function purchaseEscapeIlike(value) {
    return String(value || '')
      .replace(/\\/g, '\\\\')
      .replace(/%/g, '\\%')
      .replace(/_/g, '\\_');
  }

  async function purchaseSupplierSearch(query) {
    var tokens = purchaseSearchTokens(query);
    if (!tokens.length) return [];

    var q = supabase
      .from('suppliers')
      .select('id,supplier_code,name,search_label,phone,contact_person,purchase_rep,payment_type,accounts_payable')
      .eq('company_id', companyId())
      .eq('is_active', true)
      .limit(25);

    for (var i = 0; i < tokens.length; i++) {
      var term = purchaseEscapeIlike(tokens[i]);
      q = q.or(
        'supplier_code.ilike.%' + term +
        '%,name.ilike.%' + term +
        '%,search_label.ilike.%' + term +
        '%,phone.ilike.%' + term +
        '%,contact_person.ilike.%' + term +
        '%,purchase_rep.ilike.%' + term
      );
    }

    var r = await q.order('name', { ascending: true });
    if (r.error) throw r.error;
    return r.data || [];
  }

  async function purchaseItemSearch(query) {
    var tokens = purchaseSearchTokens(query);
    if (!tokens.length) return [];

    var q = supabase
      .from('items')
      .select('id,item_code,name,unit,barcode,search_label,cost_price,is_active')
      .eq('is_active', true)
      .limit(40);

    for (var i = 0; i < tokens.length; i++) {
      var term = purchaseEscapeIlike(tokens[i]);
      q = q.or(
        'item_code.ilike.%' + term +
        '%,name.ilike.%' + term +
        '%,barcode.ilike.%' + term +
        '%,search_label.ilike.%' + term
      );
    }

    var r = await q.order('name', { ascending: true });
    if (r.error) throw r.error;

    var search = String(query || '').trim().toLowerCase();
    return (r.data || []).sort(function (a, b) {
      function score(x) {
        var code = String(x.item_code || '').toLowerCase();
        var barcode = String(x.barcode || '').toLowerCase();
        var name = String(x.name || '').toLowerCase();
        return (code === search ? 1000 : 0) +
          (barcode === search ? 900 : 0) +
          (code.indexOf(search) === 0 ? 500 : 0) +
          (barcode.indexOf(search) === 0 ? 450 : 0) +
          (name.indexOf(search) === 0 ? 300 : 0);
      }
      return score(b) - score(a);
    }).slice(0, 25);
  }
```

### PATCH-323-01 — Supplier field

**داخل:** `RW_PurchaseGold.createInvoice()`

**ابحث عن هذا النص بالضبط:**

`<label class="text-sm font-black">المورد<select id="pg-i-supplier"`

**احذف عنصر المورد الحالي بالكامل واستبدله بـ:**

```javascript
'<div class="relative"><label class="text-sm font-black">المورد' +
'<input id="pg-i-supplier-search" autocomplete="off" class="w-full border rounded-xl p-3 mt-1" placeholder="ابحث باسم المورد أو الكود أو الهاتف">' +
'</label>' +
'<input id="pg-i-supplier" type="hidden">' +
'<div id="pg-i-supplier-dropdown" class="hidden absolute z-[90] top-full right-0 left-0 mt-1 max-h-64 overflow-auto rounded-xl border bg-white shadow-2xl"></div>' +
'</div>' +
```

### PATCH-323-02 — Item field

**ابحث عن:**

``html
<label class="text-sm font-bold">كود الصنف<input id="pg-i-code" class="w-full border rounded-xl p-3 mt-1" placeholder="1001"></label>
```

**واستبدله بـ:**

```javascript
'<div class="relative"><label class="text-sm font-bold">كود الصنف' +
'<input id="pg-i-code" autocomplete="off" class="w-full border rounded-xl p-3 mt-1" placeholder="ابحث بالكود أو الاسم أو الباركود">' +
'</label>' +
'<div id="pg-i-item-dropdown" class="hidden absolute z-[90] top-full right-0 left-0 mt-1 max-h-72 overflow-auto rounded-xl border bg-white shadow-2xl"></div>' +
'</div>' +
```

### PATCH-323-03 — Smart Search event block

**داخل `didOpen: function () {` في `createInvoice()`**

ابحث عن أول سطر بعد:

`renderLines();`

وأضف بعده مباشرة:

```javascript
        var selectedSupplier = null;
        var selectedItem = null;
        var supplierResults = [];
        var itemResults = [];
        var supplierSearchTimer = null;
        var itemSearchTimer = null;

        var supplierSearch = byId('pg-i-supplier-search');
        var supplierDropdown = byId('pg-i-supplier-dropdown');
        var itemSearch = byId('pg-i-code');
        var itemDropdown = byId('pg-i-item-dropdown');

        function hidePurchaseDropdown(dropdown) {
          if (dropdown) dropdown.classList.add('hidden');
        }

        function setSupplierSelection(supplier) {
          selectedSupplier = supplier || null;
          if (!selectedSupplier) {
            byId('pg-i-supplier').value = '';
            supplierSearch.value = '';
            hidePurchaseDropdown(supplierDropdown);
            return;
          }

          byId('pg-i-supplier').value = selectedSupplier.id || '';
          supplierSearch.value = selectedSupplier.name || selectedSupplier.supplier_code || '';
          hidePurchaseDropdown(supplierDropdown);
        }

        function setItemSelection(item) {
          selectedItem = item || null;
          itemSearch.value = selectedItem ? selectedItem.item_code : '';
          hidePurchaseDropdown(itemDropdown);
        }

        function renderSupplierSearchResults(rows) {
          supplierResults = rows || [];

          if (!supplierResults.length) {
            safeHTML(
              supplierDropdown,
              '<div class="p-3 text-sm text-slate-500 text-center">لا يوجد مورد مطابق</div>'
            );
            supplierDropdown.classList.remove('hidden');
            return;
          }

          var h = '';

          for (var i = 0; i < supplierResults.length; i++) {
            var s = supplierResults[i];

            h +=
              '<button type="button" data-pg-supplier-index="' + i + '" class="w-full text-right p-3 border-b hover:bg-emerald-50">' +
              '<div class="font-black text-slate-900">' + esc(s.name || s.supplier_code || '') + '</div>' +
              '<div class="text-xs text-slate-500 mt-1">' +
                esc(s.supplier_code || '') +
                (s.phone ? ' · ' + esc(s.phone) : '') +
                (s.contact_person ? ' · ' + esc(s.contact_person) : '') +
              '</div>' +
              '</button>';
          }

          safeHTML(supplierDropdown, h);
          supplierDropdown.classList.remove('hidden');
        }

        function renderItemSearchResults(rows) {
          itemResults = rows || [];

          if (!itemResults.length) {
            safeHTML(
              itemDropdown,
              '<div class="p-3 text-sm text-slate-500 text-center">لا يوجد صنف مطابق</div>'
            );
            itemDropdown.classList.remove('hidden');
            return;
          }

          var h = '';

          for (var i = 0; i < itemResults.length; i++) {
            var item = itemResults[i];

            h +=
              '<button type="button" data-pg-item-index="' + i + '" class="w-full text-right p-3 border-b hover:bg-blue-50">' +
              '<div class="font-black text-slate-900">' + esc(item.name || item.item_code || '') + '</div>' +
              '<div class="text-xs text-slate-500 mt-1">' +
                'الكود: ' + esc(item.item_code || '') +
                (item.barcode ? ' · باركود: ' + esc(item.barcode) : '') +
                ' · الوحدة: ' + esc(item.unit || '') +
              '</div>' +
              '<div class="text-xs text-emerald-700 mt-1 font-bold">التكلفة الحالية: ' +
                (Number(item.cost_price) || 0).toLocaleString() +
              '</div>' +
              '</button>';
          }

          safeHTML(itemDropdown, h);
          itemDropdown.classList.remove('hidden');
        }

        if (supplierSearch) {
          supplierSearch.addEventListener('input', function () {
            selectedSupplier = null;
            byId('pg-i-supplier').value = '';

            var value = supplierSearch.value.trim();

            clearTimeout(supplierSearchTimer);

            if (!value) {
              hidePurchaseDropdown(supplierDropdown);
              return;
            }

            supplierSearchTimer = setTimeout(async function () {
              try {
                renderSupplierSearchResults(await purchaseSupplierSearch(value));
              } catch (e) {
                safeHTML(
                  supplierDropdown,
                  '<div class="p-3 text-sm text-red-600 text-center">' +
                    esc(e.message || 'تعذر البحث عن المورد') +
                  '</div>'
                );
                supplierDropdown.classList.remove('hidden');
              }
            }, 220);
          });

          supplierSearch.addEventListener('keydown', function (e) {
            if (e.key === 'Enter' && supplierResults.length) {
              e.preventDefault();
              setSupplierSelection(supplierResults[0]);
            }
          });
        }

        if (supplierDropdown) {
          supplierDropdown.addEventListener('click', function (e) {
            var button = e.target.closest('[data-pg-supplier-index]');
            if (!button) return;

            setSupplierSelection(
              supplierResults[Number(button.getAttribute('data-pg-supplier-index'))]
            );
          });
        }

        if (itemSearch) {
          itemSearch.addEventListener('input', function () {
            selectedItem = null;

            var value = itemSearch.value.trim();

            clearTimeout(itemSearchTimer);

            if (!value) {
              hidePurchaseDropdown(itemDropdown);
              return;
            }

            itemSearchTimer = setTimeout(async function () {
              try {
                renderItemSearchResults(await purchaseItemSearch(value));
              } catch (e) {
                safeHTML(
                  itemDropdown,
                  '<div class="p-3 text-sm text-red-600 text-center">' +
                    esc(e.message || 'تعذر البحث عن الصنف') +
                  '</div>'
                );
                itemDropdown.classList.remove('hidden');
              }
            }, 180);
          });

          itemSearch.addEventListener('keydown', function (e) {
            if (e.key === 'Enter' && itemResults.length) {
              e.preventDefault();
              setItemSelection(itemResults[0]);
            }
          });
        }

        if (itemDropdown) {
          itemDropdown.addEventListener('click', function (e) {
            var button = e.target.closest('[data-pg-item-index]');
            if (!button) return;

            setItemSelection(
              itemResults[Number(button.getAttribute('data-pg-item-index'))]
            );
          });
        }
```

### PATCH-323-04 — PO supplier synchronization

**داخل نفس `didOpen`، في `pg-i-po` change handler، ابحث بالضبط عن:**

```javascript
          if (supplierId) byId('pg-i-supplier').value = supplierId;
```

**احذفه واستبدله بـ:**

```javascript
          if (supplierId) {
            var supplierRes = await supabase
              .from('suppliers')
              .select('id,supplier_code,name')
              .eq('company_id', companyId())
              .eq('id', supplierId)
              .eq('is_active', true)
              .maybeSingle();

            if (supplierRes.error) {
              Swal.showValidationMessage(supplierRes.error.message);
              return;
            }

            if (!supplierRes.data) {
              Swal.showValidationMessage('المورد المرتبط بأمر الشراء غير موجود أو غير نشط');
              return;
            }

            setSupplierSelection(supplierRes.data);
          }
```

### PATCH-323-05 — Item Add button

**داخل `createInvoice()` ابحث عن بداية handler:**

```javascript
        byId('pg-i-add').addEventListener('click', async function () {
```

واحذف هذا الـhandler بالكامل حتى نهاية:

```javascript
        });
```

ثم استبدله بـ:

```javascript
        byId('pg-i-add').addEventListener('click', async function () {
          var code = byId('pg-i-code').value.trim();
          var qty = Number(byId('pg-i-add-qty').value);
          var price = Number(byId('pg-i-add-price').value);

          if (!code || !Number.isFinite(qty) || qty <= 0 || !Number.isFinite(price) || price < 0) {
            Swal.showValidationMessage('أدخل كود الصنف والكمية والسعر بشكل صحيح');
            return;
          }

          if (items.some(function (x) { return x.item_code === code; })) {
            Swal.showValidationMessage('هذا الصنف موجود بالفعل');
            return;
          }

          var btn = byId('pg-i-add');
          btn.disabled = true;
          btn.textContent = 'جارٍ التحقق...';

          try {
            var item = selectedItem && selectedItem.item_code === code
              ? selectedItem
              : await purchaseItemLookup(code);

            items.push({
              item_code: item.item_code,
              name: item.name,
              unit: item.unit,
              qty: qty,
              unit_price: price,
              discount_percent: 0,
              tax_rate: 0
            });

            setItemSelection(null);
            byId('pg-i-add-qty').value = '';
            byId('pg-i-add-price').value = '';
            renderLines();
          } catch (e) {
            Swal.showValidationMessage(e.message || 'تعذر التحقق من الصنف');
          } finally {
            btn.disabled = false;
            btn.textContent = 'إضافة بند';
          }
        });
```

### PATCH-323-06 — preserve supplier invoice number

**ابحث بالضبط عن:**

```javascript
    // supplier_invoice_no is not part of the current CREATE_INVOICE RPC contract.
    delete r.value.supplier_invoice_no;
```

**احذف السطرين بالكامل.**

لا تستبدلهما بأي شيء.

### PATCH-323-07 — invoice notes + payload

**داخل HTML الخاص بالمودال، بعد حقل `رقم فاتورة المورد` أضف:**

```javascript
'<label class="text-sm font-black">ملاحظات الفاتورة<textarea id="pg-i-notes" rows="2" class="w-full border rounded-xl p-3 mt-1" placeholder="ملاحظات أو شروط المورد"></textarea></label>' +
```

**وفي `preConfirm` داخل object الناتج أضف:**

```javascript
          notes: byId('pg-i-notes').value.trim(),
```

## 11. لا تُجرى التعديلات التالية

لا تعدل:

- `purchaseItemLookup` خارج PATCH-323-00.
- `purchase_post_invoice_atomic`.
- `post_stock_movement`.
- `stock_branches`.
- `inventory_log`.
- Purchase workflow RPCs الأخرى.
- أي Edge Function جديدة.
- صفحات التشغيل الميداني.
- Fleet / Branch / Warehouse closed cells.
- أي إصلاح Parser سابق.
- `main.html` كملف كامل.

## 12. Production Change Log

### Executed

1. `purchase_create_invoice_atomic_v2` deployed.
2. Existing `save-purchase-order` upgraded to Version 7.
3. Current system source for `save-purchase-order` synchronized to Production Version 7.
4. Canonical migration committed:
   `supabase/migrations/20260923_purchase_invoice_reference_extension.sql`

### Not executed

- No write to Mother `main.html`.
- No new Edge Function.
- No permanent QA business data.

## 13. Verification Matrix

| Closure | Result |
|---|---|
| Supplier DB search predicate | PASS |
| Item DB search predicate | PASS |
| Invoice CREATE | PASS |
| Invoice POST | PASS |
| Physical stock delta | PASS |
| inventory_log | PASS |
| Supplier Ledger | PASS |
| Journal Entry | PASS |
| Invoice detail received_qty | PASS |
| CREATE idempotency | PASS |
| POST idempotency | PASS |
| Supplier invoice reference persistence | PASS |
| Transaction rollback | PASS |
| Mother main.html modified by assistant | NO |
| Authenticated Browser E2E | OPEN |
| Served artifact verification | OPEN |

## 14. لماذا لم تُعلن Browser E2E مكتملة

لا يوجد في الأدوات المتاحة جلسة Browser مصادق عليها يمكن استخدامها كدليل على:

- فتح مودال فواتير الشراء فعليًا.
- تنفيذ supplier typing/click.
- تنفيذ item typing/click.
- متابعة Network.
- متابعة Console.
- التأكد من rendered served artifact.

وبالتالي:

DB/RPC E2E PASS ≠ Browser E2E PASS.

هذا لا يلغي ما تم إغلاقه Production، بل يمنع إعلان إغلاق غير مثبت.

## 15. الحالة التنفيذية

### PRODUCTION PURCHASE CORE
CLOSED / VERIFIED

### PURCHASE INVOICE REFERENCE
CLOSED / VERIFIED

### SUPPLIER SMART SEARCH BACKEND CONTRACT
CLOSED / VERIFIED

### ITEM SMART SEARCH BACKEND CONTRACT
CLOSED / VERIFIED

### MOTHER MAIN.HTML SURGICAL PATCH
READY FOR OWNER

### BROWSER E2E
OPEN

### FINAL PURCHASE GOLD/DIAMOND
OPEN UNTIL OWNER PATCH + FRESH BROWSER E2E

## 16. Exact Next Resumption Point

لا تعتمد على أي SHA قديم.

ابدأ من:

1. Current Mother HEAD.
2. Current Mother main.html blob.
3. Current Production `save-purchase-order` Version.
4. Current Production RPC definition.
5. Apply only PATCH-323-00 .. PATCH-323-07.
6. Parse full main.html.
7. Commit/publish frontend.
8. Verify served artifact identity.
9. Login fresh session.
10. Purchase Cycle → Purchase Invoices.
11. Supplier smart search.
12. Item smart search.
13. Create Draft Invoice.
14. Verify supplier reference.
15. Post Invoice.
16. Verify Network request payload.
17. Verify purchase_invoices.
18. Verify purchase_invoice_details.
19. Verify stock_branches delta.
20. Verify inventory_log.
21. Verify supplier_ledger.
22. Verify journal_entries.
23. Verify Realtime refresh.
24. Capture fresh Production snapshot.
25. Update CURRENT_STATE.
26. Never reopen closed backend contracts without contradictory current evidence.

## 17. Instructions to the Next Assistant

التقارير السابقة ليست Current Truth.

الحقيقة التالية فقط:

CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
+
CURRENT BROWSER

قاعدة التحقيق:

REPORT → clue
SOURCE → contract
PRODUCTION → runtime truth
DATABASE → persisted truth
BROWSER → UI truth

لا تعيد أي إصلاح أغلق في هذا التقرير إلا إذا ظهرت Current Evidence تناقضه.

ابدأ دائمًا من Current HEAD وCurrent Production، ثم افتح مصدر المودال المستهدف فقط.

## 18. خلاصة

تم إغلاق الجزء الخلفي الفعلي من أزمة فواتير الشراء دون إنشاء Edge Function جديدة ودون لمس main.html.

العنصر المتبقي للمالك محدد جراحيًا: Supplier smart search + Item smart search + supplier invoice reference/note payload داخل `RW_PurchaseGold.createInvoice()`.

بعد تطبيق الـOwner Patch لا تعالج Purchase من جديد بالتخمين؛ نفذ Browser E2E فقط، ثم انتقل لأول Gap حقيقي جديد.
