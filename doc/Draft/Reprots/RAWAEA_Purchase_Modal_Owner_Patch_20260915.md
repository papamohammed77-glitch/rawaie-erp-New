# RAWAEA ERP — Owner Surgical Patch Package — Purchase Modals — 2026-09-15

## Source of Truth
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
Current HEAD: `befa657277fc013c4fe4d3e326ed8fc5d1040b7b`
Current Mother blob: `bc268b9bb350991df64221e7f99b958264fb8d5f`

Do NOT modify historical fragments. Do NOT modify `Current/PWA/main2/*`.

## 1. Add helper block
Current location: immediately BEFORE `async function render()` at source line 9155.

Search for this exact full line:
```javascript
  async function render() {
```

Add this complete block immediately ABOVE it:

```javascript
  var purchaseRealtimeChannel = null;

  function purchaseToday() {
    return new Date().toISOString().slice(0, 10);
  }

  async function purchaseItemLookup(code) {
    code = String(code || '').trim();
    if (!code) throw new Error('كود الصنف مطلوب');
    var r = await supabase
      .from('items')
      .select('id,item_code,name,unit')
      .eq('item_code', code)
      .maybeSingle();

    if (r.error) throw r.error;
    if (!r.data) throw new Error('الصنف غير موجود: ' + code);
    return r.data;
  }

  function ensurePurchaseRealtime() {
    var c = companyId();
    if (!c || purchaseRealtimeChannel || !supabase || typeof supabase.channel !== 'function') return;

    purchaseRealtimeChannel = supabase
      .channel('purchase-gold-live-' + c)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'purchase_requests',
        filter: 'company_id=eq.' + c
      }, function () {
        if (!Swal.isVisible()) refresh();
      })
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'purchase_rfqs',
        filter: 'company_id=eq.' + c
      }, function () {
        if (!Swal.isVisible()) refresh();
      })
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'purchase_quotations',
        filter: 'company_id=eq.' + c
      }, function () {
        if (!Swal.isVisible()) refresh();
      })
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'purchase_invoices',
        filter: 'company_id=eq.' + c
      }, function () {
        if (!Swal.isVisible()) refresh();
      })
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'purchase_returns',
        filter: 'company_id=eq.' + c
      }, function () {
        if (!Swal.isVisible()) refresh();
      })
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'purchase_payments',
        filter: 'company_id=eq.' + c
      }, function () {
        if (!Swal.isVisible()) refresh();
      })
      .subscribe();
  }
```

## 2. Add one line to render()
Current source lines: 9155–9172.

Inside `async function render()` search the exact first two lines:
```javascript
  async function render() {
    var host = byId('rw-page-container');
```

Immediately after:
```javascript
    if (!host) return;
```

add:
```javascript
    ensurePurchaseRealtime();
```

Final beginning must be:
```javascript
  async function render() {
    var host = byId('rw-page-container');
    if (!host) return;

    ensurePurchaseRealtime();
```

## 3. Replace createRequest()
Current function: source lines 9271–9323.

DELETE the entire function from:
```javascript
  async function createRequest() {
```
through and INCLUDING:
```javascript
  }
```
that closes `createRequest`, immediately before:
```javascript
  async function approveRequest(id) {
```

Replace with:

```javascript
  async function createRequest() {
    var items = [];

    function renderLines() {
      var host = byId('pg-rq-lines');
      if (!host) return;

      if (!items.length) {
        host.innerHTML =
          '<div class="rounded-xl border border-dashed border-slate-300 p-6 text-center text-slate-400">' +
          'لم تتم إضافة أصناف إلى الطلب بعد' +
          '</div>';
        return;
      }

      var h =
        '<div class="overflow-auto rounded-xl border bg-white">' +
        '<table class="w-full text-sm">' +
        '<thead class="bg-slate-50"><tr>' +
        '<th class="p-3 text-right">الصنف</th>' +
        '<th class="p-3 text-right">الوحدة</th>' +
        '<th class="p-3 text-right">الكمية</th>' +
        '<th class="p-3 text-center">إجراء</th>' +
        '</tr></thead><tbody>';

      for (var i = 0; i < items.length; i++) {
        var x = items[i];
        h +=
          '<tr class="border-t">' +
          '<td class="p-3"><div class="font-black">' + esc(x.item_code) + '</div>' +
          '<div class="text-xs text-slate-500">' + esc(x.name || '') + '</div></td>' +
          '<td class="p-3">' + esc(x.unit || '') + '</td>' +
          '<td class="p-3 font-black">' + Number(x.qty).toLocaleString() + '</td>' +
          '<td class="p-3 text-center"><button type="button" data-rq-remove="' + i + '" class="text-red-600 font-black">حذف</button></td>' +
          '</tr>';
      }

      host.innerHTML = h + '</tbody></table></div>';

      Array.from(host.querySelectorAll('[data-rq-remove]')).forEach(function (btn) {
        btn.addEventListener('click', function () {
          items.splice(Number(btn.getAttribute('data-rq-remove')), 1);
          renderLines();
        });
      });
    }

    var r = await Swal.fire({
      title: 'طلب شراء جديد',
      width: 980,
      html:
        '<div dir="rtl" class="text-right space-y-5">' +
        '<div class="rounded-2xl bg-gradient-to-l from-emerald-50 to-slate-50 border border-emerald-100 p-5">' +
        '<div class="flex items-center gap-3">' +
        '<div class="w-12 h-12 rounded-2xl bg-emerald-600 text-white flex items-center justify-center"><i class="fas fa-cart-plus"></i></div>' +
        '<div><div class="text-lg font-black text-slate-900">إنشاء طلب شراء</div>' +
        '<div class="text-sm text-slate-500">أنشئ الطلب كوثيقة عملية، ثم أضف الأصناف المطلوبة وراجعها قبل الحفظ.</div></div>' +
        '</div></div>' +

        '<div class="grid grid-cols-1 md:grid-cols-2 gap-4">' +
        '<label class="text-sm font-black text-slate-700">مسمى الطلب' +
        '<input id="pg-rq-title" class="w-full border border-slate-200 rounded-xl p-3 mt-1" placeholder="مثال: طلب توريد بضاعة للفرع الرئيسي"></label>' +
        '<label class="text-sm font-black text-slate-700">مطلوب قبل' +
        '<input id="pg-rq-date" type="date" class="w-full border border-slate-200 rounded-xl p-3 mt-1"></label>' +
        '</div>' +

        '<div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">' +
        '<div class="font-black text-slate-900 mb-3">بنود طلب الشراء</div>' +
        '<div class="grid grid-cols-1 md:grid-cols-[1fr_180px_auto] gap-3 items-end">' +
        '<label class="text-sm font-bold text-slate-700">كود الصنف' +
        '<input id="pg-rq-code" class="w-full border border-slate-200 rounded-xl p-3 mt-1" placeholder="1001"></label>' +
        '<label class="text-sm font-bold text-slate-700">الكمية' +
        '<input id="pg-rq-qty" type="number" min="0.01" step="0.01" class="w-full border border-slate-200 rounded-xl p-3 mt-1" placeholder="10"></label>' +
        '<button type="button" id="pg-rq-add" class="px-5 py-3 rounded-xl bg-blue-600 text-white font-black">إضافة الصنف</button>' +
        '</div>' +
        '<div id="pg-rq-lines" class="mt-4"></div>' +
        '</div>' +

        '<label class="text-sm font-black text-slate-700">ملاحظات' +
        '<textarea id="pg-rq-notes" rows="3" class="w-full border border-slate-200 rounded-xl p-3 mt-1" placeholder="سبب الطلب أو تعليمات الشراء"></textarea>' +
        '</label>' +
        '</div>',
      showCancelButton: true,
      confirmButtonText: 'حفظ طلب الشراء',
      cancelButtonText: 'إلغاء',
      focusConfirm: false,
      didOpen: function () {
        byId('pg-rq-date').value = purchaseToday();
        renderLines();

        byId('pg-rq-add').addEventListener('click', async function () {
          var code = byId('pg-rq-code').value.trim();
          var qty = Number(byId('pg-rq-qty').value);

          if (!code || !Number.isFinite(qty) || qty <= 0) {
            Swal.showValidationMessage('أدخل كود صنف صحيح وكمية أكبر من صفر');
            return;
          }

          if (items.some(function (x) { return x.item_code === code; })) {
            Swal.showValidationMessage('هذا الصنف مضاف بالفعل');
            return;
          }

          var btn = byId('pg-rq-add');
          btn.disabled = true;
          btn.textContent = 'جارٍ التحقق...';

          try {
            var item = await purchaseItemLookup(code);
            items.push({
              item_code: item.item_code,
              name: item.name,
              unit: item.unit,
              qty: qty
            });
            byId('pg-rq-code').value = '';
            byId('pg-rq-qty').value = '';
            renderLines();
          } catch (e) {
            Swal.showValidationMessage(e.message || 'تعذر التحقق من الصنف');
          } finally {
            btn.disabled = false;
            btn.textContent = 'إضافة الصنف';
          }
        });
      },
      preConfirm: function () {
        var title = byId('pg-rq-title').value.trim();

        if (!title) {
          Swal.showValidationMessage('مسمى الطلب مطلوب');
          return false;
        }

        if (!items.length) {
          Swal.showValidationMessage('أضف صنفًا واحدًا على الأقل');
          return false;
        }

        return {
          title: title,
          required_by: byId('pg-rq-date').value || null,
          notes: byId('pg-rq-notes').value.trim(),
          items: items.map(function (x) {
            return {
              item_code: x.item_code,
              qty: Number(x.qty)
            };
          })
        };
      }
    });

    if (!r.isConfirmed) return;

    showLoader('جاري إنشاء طلب الشراء...');

    try {
      var result = await api('CREATE_REQUEST', r.value);
      hideLoader();
      showToast('تم إنشاء طلب الشراء: ' + (result.code || ''), 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      Swal.fire('تعذر إنشاء الطلب', e.message, 'error');
    }
  }
```

## 4. Replace createRFQ()
Current function: source lines 9365–9414.

DELETE the entire function from:
```javascript
  async function createRFQ() {
```
through the `}` immediately before:
```javascript
  async function sendRFQ(id) {
```

Replace with:

```javascript
  async function createRFQ() {
    var requests = await getData('purchase_requests', function (q) {
      return q.in('status', ['Approved', 'Draft']).order('request_date', { ascending: false });
    });

    var suppliers = await getData('suppliers', function (q) {
      return q.eq('is_active', true).order('name', { ascending: true });
    });

    if (!requests.length) {
      Swal.fire('لا توجد طلبات', 'أنشئ أو اعتمد طلب شراء أولًا قبل إنشاء طلب عروض الأسعار.', 'info');
      return;
    }

    if (!suppliers.length) {
      Swal.fire('لا يوجد موردون', 'لا يوجد موردون نشطون يمكن إرسال طلب عروض إليهم.', 'info');
      return;
    }

    var reqOptions = requests.map(function (x) {
      return '<option value="' + esc(x.id) + '">' +
        esc(x.request_code + ' — ' + x.title) +
        '</option>';
    }).join('');

    var supOptions = suppliers.map(function (x) {
      return '<option value="' + esc(x.id) + '">' +
        esc((x.name || x.supplier_code) + ' — ' + (x.supplier_code || '')) +
        '</option>';
    }).join('');

    var r = await Swal.fire({
      title: 'طلب عروض أسعار جديد',
      width: 1000,
      html:
        '<div dir="rtl" class="text-right space-y-5">' +
        '<div class="rounded-2xl bg-gradient-to-l from-blue-50 to-slate-50 border border-blue-100 p-5">' +
        '<div class="flex items-center gap-3">' +
        '<div class="w-12 h-12 rounded-2xl bg-blue-600 text-white flex items-center justify-center"><i class="fas fa-bullhorn"></i></div>' +
        '<div><div class="text-lg font-black">طلب عروض أسعار</div>' +
        '<div class="text-sm text-slate-500">اختر الطلب، الموعد النهائي، والموردين المدعوين. سيتم توريث بنود الطلب إلى RFQ.</div></div>' +
        '</div></div>' +

        '<div class="grid grid-cols-1 md:grid-cols-2 gap-4">' +
        '<label class="text-sm font-black text-slate-700">طلب الشراء' +
        '<select id="pg-rfq-request" class="w-full border border-slate-200 rounded-xl p-3 mt-1">' + reqOptions + '</select></label>' +
        '<label class="text-sm font-black text-slate-700">آخر موعد لتقديم العرض' +
        '<input id="pg-rfq-date" type="date" class="w-full border border-slate-200 rounded-xl p-3 mt-1"></label>' +
        '</div>' +

        '<label class="text-sm font-black text-slate-700">الموردون المدعوون' +
        '<select id="pg-rfq-suppliers" multiple class="w-full border border-slate-200 rounded-xl p-3 mt-1 min-h-[150px]">' + supOptions + '</select>' +
        '</label>' +

        '<div class="rounded-2xl border p-4 bg-slate-50">' +
        '<div class="font-black mb-3">بنود الطلب الموروثة</div>' +
        '<div id="pg-rfq-request-lines" class="text-sm text-slate-600">اختر طلبًا لمعاينة البنود.</div>' +
        '</div>' +
        '</div>',
      showCancelButton: true,
      confirmButtonText: 'إنشاء RFQ',
      cancelButtonText: 'إلغاء',
      focusConfirm: false,
      didOpen: async function () {
        byId('pg-rfq-date').value = purchaseToday();

        async function loadRequestLines() {
          var host = byId('pg-rfq-request-lines');
          var requestId = byId('pg-rfq-request').value;
          if (!requestId) {
            host.innerHTML = 'اختر طلبًا لمعاينة البنود.';
            return;
          }

          host.innerHTML = 'جاري تحميل البنود...';

          try {
            var d = await supabase
              .from('purchase_request_details')
              .select('item_code,item_name,unit,qty_requested,notes')
              .eq('request_id', requestId)
              .order('created_at', { ascending: true });

            if (d.error) throw d.error;

            var rows = d.data || [];
            if (!rows.length) {
              host.innerHTML = '<div class="text-red-600 font-bold">الطلب المختار لا يحتوي بنودًا.</div>';
              return;
            }

            var h = '<div class="overflow-auto rounded-xl border bg-white"><table class="w-full text-sm"><thead class="bg-slate-50"><tr>' +
              '<th class="p-2 text-right">الصنف</th><th class="p-2 text-right">الوحدة</th><th class="p-2 text-right">الكمية</th><th class="p-2 text-right">ملاحظات</th>' +
              '</tr></thead><tbody>';

            rows.forEach(function (x) {
              h += '<tr class="border-t">' +
                '<td class="p-2 font-black">' + esc(x.item_code) + '<div class="text-xs text-slate-500">' + esc(x.item_name || '') + '</div></td>' +
                '<td class="p-2">' + esc(x.unit || '') + '</td>' +
                '<td class="p-2 font-black">' + Number(x.qty_requested || 0).toLocaleString() + '</td>' +
                '<td class="p-2">' + esc(x.notes || '') + '</td>' +
                '</tr>';
            });

            host.innerHTML = h + '</tbody></table></div>';
          } catch (e) {
            host.innerHTML = '<div class="text-red-600 font-bold">' + esc(e.message || 'تعذر تحميل البنود') + '</div>';
          }
        }

        byId('pg-rfq-request').addEventListener('change', loadRequestLines);
        loadRequestLines();
      },
      preConfirm: function () {
        var requestId = byId('pg-rfq-request').value;
        var selectedSuppliers = Array.from(byId('pg-rfq-suppliers').selectedOptions).map(function (o) {
          return o.value;
        });

        if (!requestId) {
          Swal.showValidationMessage('اختيار طلب الشراء مطلوب');
          return false;
        }

        if (!selectedSuppliers.length) {
          Swal.showValidationMessage('اختر موردًا واحدًا على الأقل');
          return false;
        }

        return {
          request_id: requestId,
          due_date: byId('pg-rfq-date').value || null,
          supplier_ids: selectedSuppliers
        };
      }
    });

    if (!r.isConfirmed) return;

    showLoader('جاري إنشاء طلب عروض الأسعار...');

    try {
      var result = await api('CREATE_RFQ', r.value);
      hideLoader();
      showToast('تم إنشاء طلب عروض الأسعار: ' + (result.code || ''), 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      Swal.fire('تعذر إنشاء RFQ', e.message, 'error');
    }
  }
```

## 5. Replace createQuotation()
Current function: source lines 9461–9531.

DELETE the full function through the closing `}` immediately before:
```javascript
  async function acceptQuotation(id) {
```

Replace with:

```javascript
  async function createQuotation() {
    var suppliers = await getData('suppliers', function (q) {
      return q.eq('is_active', true).order('name', { ascending: true });
    });

    var rfqs = await getData('purchase_rfqs', function (q) {
      return q.order('rfq_date', { ascending: false });
    });

    if (!suppliers.length) {
      Swal.fire('لا يوجد موردون', 'لا يوجد موردون نشطون.', 'info');
      return;
    }

    var supplierOptions = suppliers.map(function (x) {
      return '<option value="' + esc(x.id) + '">' + esc(x.name || x.supplier_code) + '</option>';
    }).join('');

    var rfqOptions = '<option value="">بدون RFQ</option>' + rfqs.map(function (x) {
      return '<option value="' + esc(x.id) + '">' + esc(x.rfq_code + ' — ' + x.status) + '</option>';
    }).join('');

    var items = [];

    function renderLines() {
      var host = byId('pg-q-lines');
      if (!host) return;

      if (!items.length) {
        host.innerHTML = '<div class="rounded-xl border border-dashed border-slate-300 p-6 text-center text-slate-400">لا توجد بنود.</div>';
        return;
      }

      var h = '<div class="overflow-auto rounded-xl border bg-white"><table class="w-full text-sm"><thead class="bg-slate-50"><tr>' +
        '<th class="p-2 text-right">الصنف</th><th class="p-2">الكمية</th><th class="p-2">السعر</th><th class="p-2">خصم %</th><th class="p-2">ضريبة %</th><th class="p-2">الإجمالي</th><th class="p-2"></th>' +
        '</tr></thead><tbody>';

      for (var i = 0; i < items.length; i++) {
        var x = items[i];
        var gross = Number(x.qty || 0) * Number(x.unit_price || 0);
        var net = gross * (1 - Number(x.discount_percent || 0) / 100);
        var total = net * (1 + Number(x.tax_rate || 0) / 100);

        h += '<tr class="border-t">' +
          '<td class="p-2"><div class="font-black">' + esc(x.item_code) + '</div><div class="text-xs text-slate-500">' + esc(x.name || '') + '</div></td>' +
          '<td class="p-2"><input data-q-field="qty" data-q-index="' + i + '" type="number" min="0.01" step="0.01" value="' + esc(String(x.qty)) + '" class="w-24 border rounded-lg p-2"></td>' +
          '<td class="p-2"><input data-q-field="price" data-q-index="' + i + '" type="number" min="0" step="0.01" value="' + esc(String(x.unit_price)) + '" class="w-28 border rounded-lg p-2"></td>' +
          '<td class="p-2"><input data-q-field="discount" data-q-index="' + i + '" type="number" min="0" max="100" step="0.01" value="' + esc(String(x.discount_percent || 0)) + '" class="w-24 border rounded-lg p-2"></td>' +
          '<td class="p-2"><input data-q-field="tax" data-q-index="' + i + '" type="number" min="0" max="100" step="0.01" value="' + esc(String(x.tax_rate || 0)) + '" class="w-24 border rounded-lg p-2"></td>' +
          '<td class="p-2 font-black">' + total.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</td>' +
          '<td class="p-2"><button type="button" data-q-remove="' + i + '" class="text-red-600 font-black">حذف</button></td>' +
          '</tr>';
      }

      host.innerHTML = h + '</tbody></table></div>';

      Array.from(host.querySelectorAll('[data-q-field]')).forEach(function (el) {
        el.addEventListener('input', function () {
          var idx = Number(el.getAttribute('data-q-index'));
          var field = el.getAttribute('data-q-field');
          var value = Number(el.value);
          if (field === 'qty') items[idx].qty = value;
          if (field === 'price') items[idx].unit_price = value;
          if (field === 'discount') items[idx].discount_percent = value;
          if (field === 'tax') items[idx].tax_rate = value;
          renderLines();
        });
      });

      Array.from(host.querySelectorAll('[data-q-remove]')).forEach(function (btn) {
        btn.addEventListener('click', function () {
          items.splice(Number(btn.getAttribute('data-q-remove')), 1);
          renderLines();
        });
      });
    }

    var r = await Swal.fire({
      title: 'إضافة عرض مورد',
      width: 1100,
      html:
        '<div dir="rtl" class="text-right space-y-5">' +
        '<div class="rounded-2xl bg-gradient-to-l from-violet-50 to-slate-50 border border-violet-100 p-5">' +
        '<div class="flex items-center gap-3">' +
        '<div class="w-12 h-12 rounded-2xl bg-violet-600 text-white flex items-center justify-center"><i class="fas fa-tags"></i></div>' +
        '<div><div class="text-lg font-black">عرض مورد</div>' +
        '<div class="text-sm text-slate-500">اختر المورد وRFQ ثم أدخل الأسعار والخصومات والضرائب على مستوى كل بند.</div></div>' +
        '</div></div>' +

        '<div class="grid grid-cols-1 md:grid-cols-3 gap-4">' +
        '<label class="text-sm font-black text-slate-700">المورد<select id="pg-q-supplier" class="w-full border rounded-xl p-3 mt-1">' + supplierOptions + '</select></label>' +
        '<label class="text-sm font-black text-slate-700">RFQ<select id="pg-q-rfq" class="w-full border rounded-xl p-3 mt-1">' + rfqOptions + '</select></label>' +
        '<label class="text-sm font-black text-slate-700">صالح حتى<input id="pg-q-valid" type="date" class="w-full border rounded-xl p-3 mt-1"></label>' +
        '</div>' +

        '<div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">' +
        '<div class="font-black text-slate-900 mb-3">بنود العرض</div>' +
        '<div class="grid grid-cols-1 md:grid-cols-[1fr_140px_140px_auto] gap-3 items-end">' +
        '<label class="text-sm font-bold">كود الصنف<input id="pg-q-code" class="w-full border rounded-xl p-3 mt-1" placeholder="1001"></label>' +
        '<label class="text-sm font-bold">الكمية<input id="pg-q-add-qty" type="number" min="0.01" step="0.01" class="w-full border rounded-xl p-3 mt-1" placeholder="10"></label>' +
        '<label class="text-sm font-bold">سعر الوحدة<input id="pg-q-add-price" type="number" min="0" step="0.01" class="w-full border rounded-xl p-3 mt-1" placeholder="25"></label>' +
        '<button type="button" id="pg-q-add" class="px-5 py-3 rounded-xl bg-blue-600 text-white font-black">إضافة بند</button>' +
        '</div>' +
        '<div id="pg-q-lines" class="mt-4"></div>' +
        '</div>' +
        '</div>',
      showCancelButton: true,
      confirmButtonText: 'حفظ العرض',
      cancelButtonText: 'إلغاء',
      focusConfirm: false,
      didOpen: async function () {
        byId('pg-q-valid').value = purchaseToday();
        renderLines();

        async function loadRFQLines() {
          var rfqId = byId('pg-q-rfq').value;
          if (!rfqId) return;

          var d = await supabase
            .from('purchase_rfq_details')
            .select('item_code,item_name,unit,qty_requested')
            .eq('rfq_id', rfqId)
            .order('created_at', { ascending: true });

          if (d.error) {
            Swal.showValidationMessage(d.error.message);
            return;
          }

          items = (d.data || []).map(function (x) {
            return {
              item_code: x.item_code,
              name: x.item_name,
              unit: x.unit,
              qty: Number(x.qty_requested || 0),
              unit_price: 0,
              discount_percent: 0,
              tax_rate: 0
            };
          });

          renderLines();
        }

        byId('pg-q-rfq').addEventListener('change', loadRFQLines);

        byId('pg-q-add').addEventListener('click', async function () {
          var code = byId('pg-q-code').value.trim();
          var qty = Number(byId('pg-q-add-qty').value);
          var price = Number(byId('pg-q-add-price').value);

          if (!code || !Number.isFinite(qty) || qty <= 0 || !Number.isFinite(price) || price < 0) {
            Swal.showValidationMessage('أدخل كود الصنف والكمية والسعر بشكل صحيح');
            return;
          }

          if (items.some(function (x) { return x.item_code === code; })) {
            Swal.showValidationMessage('هذا الصنف موجود بالفعل');
            return;
          }

          try {
            var item = await purchaseItemLookup(code);
            items.push({
              item_code: item.item_code,
              name: item.name,
              unit: item.unit,
              qty: qty,
              unit_price: price,
              discount_percent: 0,
              tax_rate: 0
            });
            byId('pg-q-code').value = '';
            byId('pg-q-add-qty').value = '';
            byId('pg-q-add-price').value = '';
            renderLines();
          } catch (e) {
            Swal.showValidationMessage(e.message);
          }
        });
      },
      preConfirm: function () {
        var supplierId = byId('pg-q-supplier').value;

        if (!supplierId) {
          Swal.showValidationMessage('اختيار المورد مطلوب');
          return false;
        }

        if (!items.length) {
          Swal.showValidationMessage('أضف بندًا واحدًا على الأقل');
          return false;
        }

        for (var i = 0; i < items.length; i++) {
          if (!Number.isFinite(Number(items[i].qty)) || Number(items[i].qty) <= 0 ||
              !Number.isFinite(Number(items[i].unit_price)) || Number(items[i].unit_price) < 0 ||
              Number(items[i].discount_percent) < 0 || Number(items[i].discount_percent) > 100 ||
              Number(items[i].tax_rate) < 0 || Number(items[i].tax_rate) > 100) {
            Swal.showValidationMessage('تحقق من كميات وأسعار وخصومات وضرائب البنود');
            return false;
          }
        }

        return {
          supplier_id: supplierId,
          rfq_id: byId('pg-q-rfq').value || null,
          valid_until: byId('pg-q-valid').value || null,
          currency: 'SAR',
          items: items.map(function (x) {
            return {
              item_code: x.item_code,
              qty: Number(x.qty),
              unit_price: Number(x.unit_price),
              discount_percent: Number(x.discount_percent || 0),
              tax_rate: Number(x.tax_rate || 0)
            };
          })
        };
      }
    });

    if (!r.isConfirmed) return;

    showLoader('جاري حفظ عرض المورد...');

    try {
      var result = await api('CREATE_QUOTATION', r.value);
      hideLoader();
      showToast('تم حفظ عرض المورد: ' + (result.code || ''), 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      Swal.fire('تعذر حفظ العرض', e.message, 'error');
    }
  }
```

## 6. Replace createInvoice()
Current function: source lines 9616–9686.

DELETE the entire function through the `}` immediately before:
```javascript
  async function postInvoice(id) {
```

Replace with:

```javascript
  async function createInvoice() {
    var suppliers = await getData('suppliers', function (q) {
      return q.eq('is_active', true).order('name', { ascending: true });
    });

    var branches = await getData('branches', function (q) {
      return q.eq('is_active', true).order('name', { ascending: true });
    });

    var pos = await getData('purchase_orders', function (q) {
      return q.in('status', ['Draft', 'Confirmed', 'Approved', 'Partially Received', 'Received']).order('po_date', { ascending: false });
    });

    var so = suppliers.map(function (x) {
      return '<option value="' + esc(x.id) + '">' + esc(x.name || x.supplier_code) + '</option>';
    }).join('');

    var bo = '<option value="">الفرع الرئيسي</option>' + branches.map(function (x) {
      return '<option value="' + esc(x.id) + '">' + esc(x.name) + '</option>';
    }).join('');

    var poOptions = '<option value="">بدون أمر شراء</option>' + pos.map(function (x) {
      return '<option value="' + esc(x.id) + '" data-supplier="' + esc(x.supplier_id || '') + '" data-branch="' + esc(x.branch_id || '') + '">' +
        esc(x.po_code + ' — ' + (x.supplier_name || '') + ' — ' + Number(x.total_amount || 0).toLocaleString()) +
        '</option>';
    }).join('');

    var items = [];

    function renderLines() {
      var host = byId('pg-i-lines');
      if (!host) return;

      if (!items.length) {
        host.innerHTML = '<div class="rounded-xl border border-dashed border-slate-300 p-6 text-center text-slate-400">لا توجد بنود.</div>';
        return;
      }

      var h = '<div class="overflow-auto rounded-xl border bg-white"><table class="w-full text-sm"><thead class="bg-slate-50"><tr>' +
        '<th class="p-2 text-right">الصنف</th><th class="p-2">الكمية</th><th class="p-2">السعر</th><th class="p-2">خصم %</th><th class="p-2">ضريبة %</th><th class="p-2">الإجمالي</th><th class="p-2"></th>' +
        '</tr></thead><tbody>';

      items.forEach(function (x, i) {
        var gross = Number(x.qty || 0) * Number(x.unit_price || 0);
        var net = gross * (1 - Number(x.discount_percent || 0) / 100);
        var total = net * (1 + Number(x.tax_rate || 0) / 100);

        h += '<tr class="border-t">' +
          '<td class="p-2"><div class="font-black">' + esc(x.item_code) + '</div><div class="text-xs text-slate-500">' + esc(x.name || '') + '</div></td>' +
          '<td class="p-2"><input data-i-field="qty" data-i-index="' + i + '" type="number" min="0.01" step="0.01" value="' + esc(String(x.qty)) + '" class="w-24 border rounded-lg p-2"></td>' +
          '<td class="p-2"><input data-i-field="price" data-i-index="' + i + '" type="number" min="0" step="0.01" value="' + esc(String(x.unit_price)) + '" class="w-28 border rounded-lg p-2"></td>' +
          '<td class="p-2"><input data-i-field="discount" data-i-index="' + i + '" type="number" min="0" max="100" step="0.01" value="' + esc(String(x.discount_percent || 0)) + '" class="w-24 border rounded-lg p-2"></td>' +
          '<td class="p-2"><input data-i-field="tax" data-i-index="' + i + '" type="number" min="0" max="100" step="0.01" value="' + esc(String(x.tax_rate || 0)) + '" class="w-24 border rounded-lg p-2"></td>' +
          '<td class="p-2 font-black">' + total.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '</td>' +
          '<td class="p-2"><button type="button" data-i-remove="' + i + '" class="text-red-600 font-black">حذف</button></td>' +
          '</tr>';
      });

      host.innerHTML = h + '</tbody></table></div>';

      Array.from(host.querySelectorAll('[data-i-field]')).forEach(function (el) {
        el.addEventListener('change', function () {
          var idx = Number(el.getAttribute('data-i-index'));
          var field = el.getAttribute('data-i-field');
          var value = Number(el.value);
          if (field === 'qty') items[idx].qty = value;
          if (field === 'price') items[idx].unit_price = value;
          if (field === 'discount') items[idx].discount_percent = value;
          if (field === 'tax') items[idx].tax_rate = value;
          renderLines();
        });
      });

      Array.from(host.querySelectorAll('[data-i-remove]')).forEach(function (btn) {
        btn.addEventListener('click', function () {
          items.splice(Number(btn.getAttribute('data-i-remove')), 1);
          renderLines();
        });
      });
    }

    var r = await Swal.fire({
      title: 'فاتورة شراء جديدة',
      width: 1100,
      html:
        '<div dir="rtl" class="text-right space-y-5">' +
        '<div class="rounded-2xl bg-gradient-to-l from-amber-50 to-slate-50 border border-amber-100 p-5">' +
        '<div class="flex items-center gap-3"><div class="w-12 h-12 rounded-2xl bg-amber-500 text-white flex items-center justify-center"><i class="fas fa-file-invoice-dollar"></i></div>' +
        '<div><div class="text-lg font-black">إنشاء فاتورة شراء</div><div class="text-sm text-slate-500">اربط الفاتورة بأمر شراء متى أمكن، وحدد الفرع وبنود الفاتورة بدقة.</div></div></div></div>' +

        '<div class="grid grid-cols-1 md:grid-cols-3 gap-4">' +
        '<label class="text-sm font-black">المورد<select id="pg-i-supplier" class="w-full border rounded-xl p-3 mt-1">' + so + '</select></label>' +
        '<label class="text-sm font-black">الفرع<select id="pg-i-branch" class="w-full border rounded-xl p-3 mt-1">' + bo + '</select></label>' +
        '<label class="text-sm font-black">أمر الشراء<select id="pg-i-po" class="w-full border rounded-xl p-3 mt-1">' + poOptions + '</select></label>' +
        '</div>' +

        '<div class="grid grid-cols-1 md:grid-cols-2 gap-4">' +
        '<label class="text-sm font-black">تاريخ الاستحقاق<input id="pg-i-date" type="date" class="w-full border rounded-xl p-3 mt-1"></label>' +
        '<label class="text-sm font-black">رقم فاتورة المورد<input id="pg-i-supplier-no" class="w-full border rounded-xl p-3 mt-1" placeholder="رقم المستند لدى المورد"></label>' +
        '</div>' +

        '<div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">' +
        '<div class="font-black mb-3">بنود الفاتورة</div>' +
        '<div class="grid grid-cols-1 md:grid-cols-[1fr_120px_140px_auto] gap-3 items-end">' +
        '<label class="text-sm font-bold">كود الصنف<input id="pg-i-code" class="w-full border rounded-xl p-3 mt-1" placeholder="1001"></label>' +
        '<label class="text-sm font-bold">الكمية<input id="pg-i-add-qty" type="number" min="0.01" step="0.01" class="w-full border rounded-xl p-3 mt-1" placeholder="10"></label>' +
        '<label class="text-sm font-bold">السعر<input id="pg-i-add-price" type="number" min="0" step="0.01" class="w-full border rounded-xl p-3 mt-1" placeholder="25"></label>' +
        '<button type="button" id="pg-i-add" class="px-5 py-3 rounded-xl bg-blue-600 text-white font-black">إضافة بند</button>' +
        '</div>' +
        '<div id="pg-i-lines" class="mt-4"></div>' +
        '</div>' +
        '</div>',
      showCancelButton: true,
      confirmButtonText: 'حفظ الفاتورة',
      cancelButtonText: 'إلغاء',
      focusConfirm: false,
      didOpen: function () {
        byId('pg-i-date').value = purchaseToday();
        renderLines();

        byId('pg-i-po').addEventListener('change', async function () {
          var selected = byId('pg-i-po').selectedOptions[0];
          var supplierId = selected ? selected.getAttribute('data-supplier') : '';
          var branchId = selected ? selected.getAttribute('data-branch') : '';

          if (supplierId) byId('pg-i-supplier').value = supplierId;
          if (branchId) byId('pg-i-branch').value = branchId;

          var poId = byId('pg-i-po').value;
          if (!poId) return;

          var d = await supabase
            .from('purchase_order_details')
            .select('item_code,item_name,unit,qty_ordered,qty_received,unit_price')
            .eq('po_id', poId)
            .order('created_at', { ascending: true });

          if (d.error) {
            Swal.showValidationMessage(d.error.message);
            return;
          }

          items = (d.data || []).map(function (x) {
            return {
              item_code: x.item_code,
              name: x.item_name,
              unit: x.unit,
              qty: Number(x.qty_ordered || 0),
              unit_price: Number(x.unit_price || 0),
              discount_percent: 0,
              tax_rate: 0
            };
          });

          renderLines();
        });

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

          try {
            var item = await purchaseItemLookup(code);
            items.push({
              item_code: item.item_code,
              name: item.name,
              unit: item.unit,
              qty: qty,
              unit_price: price,
              discount_percent: 0,
              tax_rate: 0
            });
            byId('pg-i-code').value = '';
            byId('pg-i-add-qty').value = '';
            byId('pg-i-add-price').value = '';
            renderLines();
          } catch (e) {
            Swal.showValidationMessage(e.message);
          }
        });
      },
      preConfirm: function () {
        if (!byId('pg-i-supplier').value) {
          Swal.showValidationMessage('اختيار المورد مطلوب');
          return false;
        }

        if (!items.length) {
          Swal.showValidationMessage('أضف بندًا واحدًا على الأقل');
          return false;
        }

        for (var i = 0; i < items.length; i++) {
          if (!Number.isFinite(Number(items[i].qty)) || Number(items[i].qty) <= 0 ||
              !Number.isFinite(Number(items[i].unit_price)) || Number(items[i].unit_price) < 0 ||
              Number(items[i].discount_percent) < 0 || Number(items[i].discount_percent) > 100 ||
              Number(items[i].tax_rate) < 0 || Number(items[i].tax_rate) > 100) {
            Swal.showValidationMessage('تحقق من بنود الفاتورة');
            return false;
          }
        }

        return {
          supplier_id: byId('pg-i-supplier').value,
          branch_id: byId('pg-i-branch').value || null,
          purchase_order_id: byId('pg-i-po').value || null,
          due_date: byId('pg-i-date').value || null,
          supplier_invoice_no: byId('pg-i-supplier-no').value.trim(),
          currency: 'SAR',
          items: items.map(function (x) {
            return {
              item_code: x.item_code,
              qty: Number(x.qty),
              unit_price: Number(x.unit_price),
              discount_percent: Number(x.discount_percent || 0),
              tax_rate: Number(x.tax_rate || 0)
            };
          })
        };
      }
    });

    if (!r.isConfirmed) return;

    // supplier_invoice_no is not part of the current CREATE_INVOICE RPC contract.
    delete r.value.supplier_invoice_no;

    showLoader('جاري إنشاء الفاتورة...');

    try {
      var result = await api('CREATE_INVOICE', r.value);
      hideLoader();
      showToast('تم إنشاء فاتورة الشراء: ' + (result.code || ''), 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      Swal.fire('تعذر إنشاء الفاتورة', e.message, 'error');
    }
  }
```

## 7. Replace createReturn()
Current function: source lines 9730–9787.

DELETE the entire function through the `}` immediately before:
```javascript
  async function postReturn(id) {
```

Replace with:

```javascript
  async function createReturn() {
    var invoices = await getData('purchase_invoices', function (q) {
      return q.in('status', ['Posted', 'PartiallyPaid', 'Paid']).order('invoice_date', { ascending: false });
    });

    if (!invoices.length) {
      Swal.fire('لا توجد فواتير', 'لا توجد فاتورة شراء مؤهلة للمرتجع حاليًا.', 'info');
      return;
    }

    var options = invoices.map(function (x) {
      return '<option value="' + esc(x.id) + '">' +
        esc(x.invoice_code + ' — ' + Number(x.total_amount || 0).toLocaleString()) +
        '</option>';
    }).join('');

    var items = [];

    function renderLines() {
      var host = byId('pg-r-lines');
      if (!host) return;

      if (!items.length) {
        host.innerHTML = '<div class="rounded-xl border border-dashed border-slate-300 p-6 text-center text-slate-400">اختر فاتورة لمعاينة البنود.</div>';
        return;
      }

      var h = '<div class="overflow-auto rounded-xl border bg-white"><table class="w-full text-sm"><thead class="bg-slate-50"><tr>' +
        '<th class="p-2 text-right">الصنف</th><th class="p-2">المتاح للمرتجع</th><th class="p-2">كمية المرتجع</th><th class="p-2">السبب</th>' +
        '</tr></thead><tbody>';

      items.forEach(function (x, i) {
        h += '<tr class="border-t">' +
          '<td class="p-2"><div class="font-black">' + esc(x.item_code) + '</div><div class="text-xs text-slate-500">' + esc(x.item_name || '') + '</div></td>' +
          '<td class="p-2 font-black">' + Number(x.max_qty || 0).toLocaleString() + '</td>' +
          '<td class="p-2"><input data-r-field="' + i + '" type="number" min="0" max="' + Number(x.max_qty || 0) + '" step="0.01" value="' + Number(x.qty || 0) + '" class="w-28 border rounded-lg p-2"></td>' +
          '<td class="p-2"><input data-r-reason="' + i + '" value="' + esc(x.reason || '') + '" class="w-full border rounded-lg p-2" placeholder="سبب الصنف"></td>' +
          '</tr>';
      });

      host.innerHTML = h + '</tbody></table></div>';

      Array.from(host.querySelectorAll('[data-r-field]')).forEach(function (el) {
        el.addEventListener('input', function () {
          items[Number(el.getAttribute('data-r-field'))].qty = Number(el.value);
        });
      });

      Array.from(host.querySelectorAll('[data-r-reason]')).forEach(function (el) {
        el.addEventListener('input', function () {
          items[Number(el.getAttribute('data-r-reason'))].reason = el.value;
        });
      });
    }

    var r = await Swal.fire({
      title: 'مرتجع مشتريات جديد',
      width: 1050,
      html:
        '<div dir="rtl" class="text-right space-y-5">' +
        '<div class="rounded-2xl bg-gradient-to-l from-rose-50 to-slate-50 border border-rose-100 p-5">' +
        '<div class="flex items-center gap-3"><div class="w-12 h-12 rounded-2xl bg-rose-600 text-white flex items-center justify-center"><i class="fas fa-undo"></i></div>' +
        '<div><div class="text-lg font-black">مرتجع مشتريات</div><div class="text-sm text-slate-500">الكمية القصوى لكل بند محسوبة من الكمية المستلمة الفعلية في الفاتورة.</div></div></div></div>' +

        '<label class="text-sm font-black text-slate-700">فاتورة الشراء' +
        '<select id="pg-r-invoice" class="w-full border rounded-xl p-3 mt-1">' + options + '</select></label>' +

        '<label class="text-sm font-black text-slate-700">سبب المرتجع العام' +
        '<input id="pg-r-reason" class="w-full border rounded-xl p-3 mt-1" placeholder="مثال: بضاعة تالفة أو غير مطابقة"></label>' +

        '<div id="pg-r-lines"></div>' +
        '</div>',
      showCancelButton: true,
      confirmButtonText: 'إنشاء المرتجع',
      cancelButtonText: 'إلغاء',
      focusConfirm: false,
      didOpen: async function () {
        async function loadInvoiceLines() {
          var invoiceId = byId('pg-r-invoice').value;
          var host = byId('pg-r-lines');

          host.innerHTML = 'جاري تحميل بنود الفاتورة...';

          var d = await supabase
            .from('purchase_invoice_details')
            .select('item_id,item_code,item_name,unit,qty,received_qty,unit_price')
            .eq('invoice_id', invoiceId)
            .order('created_at', { ascending: true });

          if (d.error) {
            host.innerHTML = '<div class="text-red-600 font-bold">' + esc(d.error.message) + '</div>';
            return;
          }

          items = (d.data || []).filter(function (x) {
            return Number(x.received_qty || 0) > 0;
          }).map(function (x) {
            return {
              item_id: x.item_id,
              item_code: x.item_code,
              item_name: x.item_name,
              unit: x.unit,
              max_qty: Number(x.received_qty || 0),
              qty: 0,
              unit_price: Number(x.unit_price || 0),
              reason: ''
            };
          });

          renderLines();
        }

        byId('pg-r-invoice').addEventListener('change', loadInvoiceLines);
        loadInvoiceLines();
      },
      preConfirm: function () {
        var selected = items.filter(function (x) {
          return Number(x.qty || 0) > 0;
        });

        if (!selected.length) {
          Swal.showValidationMessage('حدد كمية مرتجع لبند واحد على الأقل');
          return false;
        }

        for (var i = 0; i < selected.length; i++) {
          if (selected[i].qty > selected[i].max_qty) {
            Swal.showValidationMessage('كمية المرتجع تتجاوز الكمية المستلمة: ' + selected[i].item_code);
            return false;
          }
        }

        return {
          invoice_id: byId('pg-r-invoice').value,
          reason: byId('pg-r-reason').value.trim(),
          items: selected.map(function (x) {
            return {
              item_code: x.item_code,
              qty: Number(x.qty),
              reason: x.reason || byId('pg-r-reason').value.trim()
            };
          })
        };
      }
    });

    if (!r.isConfirmed) return;

    showLoader('جاري إنشاء المرتجع...');

    try {
      var result = await api('CREATE_RETURN', r.value);
      hideLoader();
      showToast('تم إنشاء المرتجع: ' + (result.code || ''), 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      Swal.fire('تعذر إنشاء المرتجع', e.message, 'error');
    }
  }
```

## 8. Replace createPayment()
Current function: source lines 9828–9906.

DELETE the entire function through the `}` immediately before:
```javascript
  async function reports(host) {
```

Replace with:

```javascript
  async function createPayment() {
    var suppliers = await getData('suppliers', function (q) {
      return q.eq('is_active', true).order('name', { ascending: true });
    });

    var treasury = await supabase
      .from('treasury')
      .select('id,account_code,account_name,type,current_balance')
      .eq('company_id', companyId())
      .eq('is_active', true)
      .order('account_name', { ascending: true });

    if (treasury.error) throw treasury.error;

    var invoices = await getData('purchase_invoices', function (q) {
      return q.in('status', ['Posted', 'PartiallyPaid']).order('invoice_date', { ascending: false });
    });

    var so = suppliers.map(function (x) {
      return '<option value="' + esc(x.id) + '">' + esc(x.name || x.supplier_code) + '</option>';
    }).join('');

    var to = (treasury.data || []).map(function (x) {
      return '<option value="' + esc(x.id) + '">' +
        esc((x.account_name || x.account_code) + ' — رصيد ' + Number(x.current_balance || 0).toLocaleString()) +
        '</option>';
    }).join('');

    if (!suppliers.length || !(treasury.data || []).length) {
      Swal.fire('بيانات غير مكتملة', 'يلزم وجود مورد وحساب خزينة نشط قبل تسجيل دفعة.', 'info');
      return;
    }

    var r = await Swal.fire({
      title: 'دفعة مورد جديدة',
      width: 1100,
      html:
        '<div dir="rtl" class="text-right space-y-5">' +
        '<div class="rounded-2xl bg-gradient-to-l from-cyan-50 to-slate-50 border border-cyan-100 p-5">' +
        '<div class="flex items-center gap-3"><div class="w-12 h-12 rounded-2xl bg-cyan-600 text-white flex items-center justify-center"><i class="fas fa-money-bill-wave"></i></div>' +
        '<div><div class="text-lg font-black">تسجيل دفعة مورد</div><div class="text-sm text-slate-500">يمكن تخصيص الدفعة على أكثر من فاتورة للمورد نفسه.</div></div></div></div>' +

        '<div class="grid grid-cols-1 md:grid-cols-3 gap-4">' +
        '<label class="text-sm font-black">المورد<select id="pg-p-supplier" class="w-full border rounded-xl p-3 mt-1">' + so + '</select></label>' +
        '<label class="text-sm font-black">الخزينة<select id="pg-p-treasury" class="w-full border rounded-xl p-3 mt-1">' + to + '</select></label>' +
        '<label class="text-sm font-black">المبلغ<input id="pg-p-amount" type="number" min="0.01" step="0.01" class="w-full border rounded-xl p-3 mt-1" placeholder="1000"></label>' +
        '</div>' +

        '<div class="grid grid-cols-1 md:grid-cols-2 gap-4">' +
        '<label class="text-sm font-black">المرجع<input id="pg-p-ref" class="w-full border rounded-xl p-3 mt-1" placeholder="تحويل بنكي / إيصال"></label>' +
        '<div class="rounded-xl bg-slate-50 border p-3"><div class="text-xs text-slate-500">إجمالي التخصيص</div><div id="pg-p-allocated" class="font-black text-lg">0</div></div>' +
        '</div>' +

        '<div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">' +
        '<div class="font-black mb-3">الفواتير المفتوحة للمورد</div>' +
        '<div id="pg-p-invoices"></div>' +
        '</div>' +
        '</div>',
      showCancelButton: true,
      confirmButtonText: 'تسجيل الدفعة',
      cancelButtonText: 'إلغاء',
      focusConfirm: false,
      didOpen: function () {
        function renderInvoices() {
          var supplierId = byId('pg-p-supplier').value;
          var host = byId('pg-p-invoices');

          var list = invoices.filter(function (x) {
            return x.supplier_id === supplierId;
          });

          if (!list.length) {
            host.innerHTML = '<div class="text-slate-400 text-center p-6">لا توجد فواتير مفتوحة لهذا المورد.</div>';
            byId('pg-p-allocated').textContent = '0';
            return;
          }

          var h = '<div class="overflow-auto rounded-xl border bg-white"><table class="w-full text-sm"><thead class="bg-slate-50"><tr>' +
            '<th class="p-2 text-center">تخصيص</th><th class="p-2 text-right">الفاتورة</th><th class="p-2">الإجمالي</th><th class="p-2">المدفوع</th><th class="p-2">المتبقي</th><th class="p-2">مبلغ التخصيص</th>' +
            '</tr></thead><tbody>';

          list.forEach(function (x) {
            var remaining = Math.max(0, Number(x.total_amount || 0) - Number(x.paid_amount || 0));
            h += '<tr class="border-t">' +
              '<td class="p-2 text-center"><input type="checkbox" data-p-check="' + esc(x.id) + '"></td>' +
              '<td class="p-2 font-black">' + esc(x.invoice_code) + '</td>' +
              '<td class="p-2">' + Number(x.total_amount || 0).toLocaleString() + '</td>' +
              '<td class="p-2">' + Number(x.paid_amount || 0).toLocaleString() + '</td>' +
              '<td class="p-2 font-black">' + remaining.toLocaleString() + '</td>' +
              '<td class="p-2"><input data-p-amount="' + esc(x.id) + '" data-max="' + remaining + '" type="number" min="0" max="' + remaining + '" step="0.01" value="0" class="w-32 border rounded-lg p-2"></td>' +
              '</tr>';
          });

          host.innerHTML = h + '</tbody></table></div>';

          function updateAllocated() {
            var total = 0;
            Array.from(host.querySelectorAll('[data-p-amount]')).forEach(function (el) {
              total += Math.max(0, Number(el.value || 0));
            });
            byId('pg-p-allocated').textContent = total.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
          }

          Array.from(host.querySelectorAll('[data-p-check]')).forEach(function (check) {
            check.addEventListener('change', function () {
              var input = host.querySelector('[data-p-amount="' + check.getAttribute('data-p-check') + '"]');
              var max = Number(input.getAttribute('data-max') || 0);
              input.value = check.checked ? max : 0;
              updateAllocated();
            });
          });

          Array.from(host.querySelectorAll('[data-p-amount]')).forEach(function (input) {
            input.addEventListener('input', updateAllocated);
          });
        }

        byId('pg-p-supplier').addEventListener('change', renderInvoices);
        renderInvoices();
      },
      preConfirm: function () {
        var supplierId = byId('pg-p-supplier').value;
        var treasuryId = byId('pg-p-treasury').value;
        var amount = Number(byId('pg-p-amount').value || 0);
        var allocations = [];

        if (!supplierId || !treasuryId) {
          Swal.showValidationMessage('اختيار المورد والخزينة مطلوب');
          return false;
        }

        if (!Number.isFinite(amount) || amount <= 0) {
          Swal.showValidationMessage('مبلغ الدفعة يجب أن يكون أكبر من صفر');
          return false;
        }

        Array.from(document.querySelectorAll('[data-p-amount]')).forEach(function (el) {
          var allocated = Number(el.value || 0);
          var max = Number(el.getAttribute('data-max') || 0);

          if (allocated > 0) {
            if (allocated > max) {
              throw new Error('التخصيص يتجاوز المتبقي للفواتير');
            }

            allocations.push({
              invoice_id: el.getAttribute('data-p-amount'),
              allocated_amount: allocated
            });
          }
        });

        var allocatedTotal = allocations.reduce(function (sum, x) {
          return sum + Number(x.allocated_amount || 0);
        }, 0);

        if (allocatedTotal > amount) {
          Swal.showValidationMessage('إجمالي التخصيص أكبر من مبلغ الدفعة');
          return false;
        }

        return {
          supplier_id: supplierId,
          treasury_id: treasuryId,
          amount: amount,
          reference: byId('pg-p-ref').value.trim(),
          invoice_ids: allocations
        };
      }
    });

    if (!r.isConfirmed) return;

    showLoader('جاري تسجيل دفعة المورد...');

    try {
      await api('POST_PAYMENT', r.value, window.crypto && crypto.randomUUID ? crypto.randomUUID() : String(Date.now()) + '-' + Math.random());
      hideLoader();
      showToast('تم تسجيل دفعة المورد', 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      Swal.fire('تعذر تسجيل الدفعة', e.message, 'error');
    }
  }
```

## 9. Replace reports()
Current function: source lines 9908–9949.

DELETE the whole current function from:
```javascript
  async function reports(host) {
```
through the closing `}` immediately before:
```javascript
  async function settings(host) {
```

Replace with:

```javascript
  async function reports(host) {
    var r = await Swal.fire({
      title: 'تقارير المشتريات',
      width: 520,
      html:
        '<div dir="rtl" class="text-right space-y-3">' +
        '<label class="text-sm font-black">التاريخ المرجعي<input id="pg-report-date" type="date" class="w-full border rounded-xl p-3 mt-1"></label>' +
        '<div class="text-sm text-slate-500 bg-slate-50 border rounded-xl p-3">سيتم تحميل التقرير الموحد من purchase_get_reports ثم عرض النتائج التفصيلية في شاشة المشتريات.</div>' +
        '</div>',
      showCancelButton: true,
      confirmButtonText: 'عرض التقرير',
      cancelButtonText: 'إلغاء',
      didOpen: function () {
        byId('pg-report-date').value = purchaseToday();
      },
      preConfirm: function () {
        return byId('pg-report-date').value || purchaseToday();
      }
    });

    if (!r.isConfirmed) return;

    showLoader('جاري تحميل تقرير المشتريات...');

    try {
      var data = await api('GET_REPORTS', { as_of_date: r.value });

      var requests = data.requests || {};
      var rfqs = data.rfqs || {};
      var quotations = data.quotations || {};
      var orders = data.orders || {};
      var invoices = data.invoices || {};
      var payments = data.payments || {};
      var returns = data.returns || {};

      var h =
        '<div class="space-y-5">' +
        '<div class="grid grid-cols-1 md:grid-cols-3 xl:grid-cols-4 gap-4">' +
        '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">طلبات مفتوحة</div><div class="text-3xl font-black">' + Number(requests.open || 0) + '</div><div class="text-xs text-amber-600 mt-1">تحت الاعتماد: ' + Number(requests.pending_approval || 0) + '</div></div>' +
        '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">RFQ مفتوحة</div><div class="text-3xl font-black">' + Number(rfqs.open || 0) + '</div><div class="text-xs text-blue-600 mt-1">دعوات الموردين: ' + Number(rfqs.supplier_invites || 0) + '</div></div>' +
        '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">العروض المقدمة</div><div class="text-3xl font-black">' + Number(quotations.submitted || 0) + '</div><div class="text-xs text-emerald-600 mt-1">المقبولة: ' + Number(quotations.accepted || 0) + '</div></div>' +
        '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">أوامر الشراء المفتوحة</div><div class="text-3xl font-black">' + Number(orders.open || 0) + '</div><div class="text-xs text-slate-600 mt-1">القيمة: ' + Number(orders.value || 0).toLocaleString() + '</div></div>' +
        '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">فواتير مفتوحة</div><div class="text-3xl font-black">' + Number(invoices.open || 0) + '</div><div class="text-xs text-rose-600 mt-1">مستحق: ' + Number(invoices.outstanding || 0).toLocaleString() + '</div></div>' +
        '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">دفعات مرحّلة</div><div class="text-3xl font-black">' + Number(payments.posted_amount || 0).toLocaleString() + '</div></div>' +
        '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">مرتجعات مفتوحة</div><div class="text-3xl font-black">' + Number(returns.open || 0) + '</div><div class="text-xs text-rose-600 mt-1">مرحّلة: ' + Number(returns.posted_value || 0).toLocaleString() + '</div></div>' +
        '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-slate-500">غير مفوترة من الاستلام</div><div class="text-3xl font-black">' + Number(invoices.unbilled_receipts || 0).toLocaleString() + '</div></div>' +
        '</div>' +

        '<div class="grid grid-cols-1 lg:grid-cols-2 gap-5">' +
        '<div class="bg-white border rounded-2xl p-5"><h3 class="text-lg font-black mb-4">أعمار الموردين</h3><div class="overflow-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-2 text-right">المورد</th><th class="p-2">الرصيد</th><th class="p-2">التصنيف</th></tr></thead><tbody>';

      (data.supplier_aging || []).forEach(function (x) {
        h += '<tr class="border-t"><td class="p-2 font-bold">' + esc(x.supplier_name || x.supplier_id || '') + '</td><td class="p-2 font-black">' + Number(x.net_balance || 0).toLocaleString() + '</td><td class="p-2">' + esc(x.aging_bucket || '') + '</td></tr>';
      });

      h += '</tbody></table></div></div>' +
        '<div class="bg-white border rounded-2xl p-5"><h3 class="text-lg font-black mb-4">مقارنة عروض الموردين</h3><div class="overflow-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-2 text-right">الصنف</th><th class="p-2">المورد</th><th class="p-2">السعر</th><th class="p-2">الترتيب</th></tr></thead><tbody>';

      (data.quotation_comparison || []).forEach(function (x) {
        h += '<tr class="border-t"><td class="p-2 font-bold">' + esc(x.item_code || '') + '</td><td class="p-2">' + esc(x.supplier_name || '') + '</td><td class="p-2 font-black">' + Number(x.unit_price || x.price || 0).toLocaleString() + '</td><td class="p-2">' + Number(x.price_rank || 0) + '</td></tr>';
      });

      h += '</tbody></table></div></div></div>' +
        '</div>';

      hideLoader();
      safeHTML(host, h);
    } catch (e) {
      hideLoader();
      safeHTML(host,
        '<div class="p-6 rounded-2xl bg-red-50 text-red-700 font-bold">' +
        esc(e.message || 'تعذر تحميل التقرير') +
        '</div>'
      );
    }
  }
```

## 10. Replace settings() بالكامل
Current function: source lines 9951–9977.

DELETE the full current `settings(host)` function through the `}` immediately before:
```javascript
  async function saveSettings() {
```

Replace with:

```javascript
  async function settings(host) {
    var r = await supabase
      .from('purchase_settings')
      .select('*')
      .eq('company_id', companyId())
      .maybeSingle();

    if (r.error) throw r.error;

    var branches = await getData('branches', function (q) {
      return q.eq('is_active', true).order('name', { ascending: true });
    });

    var s = r.data || {};
    var branchOptions = '<option value="">لا يوجد فرع افتراضي</option>' + branches.map(function (x) {
      return '<option value="' + esc(x.id) + '" ' + (s.default_branch_id === x.id ? 'selected' : '') + '>' +
        esc(x.name || x.branch_code) +
        '</option>';
    }).join('');

    safeHTML(host,
      '<div class="max-w-6xl space-y-5">' +
      '<div class="rounded-2xl bg-gradient-to-l from-slate-900 to-slate-700 text-white p-6">' +
      '<div class="flex items-center gap-3"><div class="w-12 h-12 rounded-2xl bg-white/10 flex items-center justify-center"><i class="fas fa-sliders-h"></i></div>' +
      '<div><div class="text-2xl font-black">إعدادات دورة المشتريات</div><div class="text-white/70 text-sm mt-1">هذه القيم تُحفظ في Purchase Settings وتتحكم في سلوك دورة المشتريات.</div></div></div>' +
      '</div>' +

      '<div class="bg-white border rounded-2xl p-5">' +
      '<div class="font-black text-lg mb-4">الترقيم والعملة</div>' +
      '<div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">' +
      '<label class="text-sm font-black">العملة الافتراضية<input id="pg-s-currency" class="w-full border rounded-xl p-3 mt-1" value="' + esc(s.default_currency || 'SAR') + '"></label>' +
      '<label class="text-sm font-black">بادئة طلب الشراء<input id="pg-s-request" class="w-full border rounded-xl p-3 mt-1" value="' + esc(s.request_prefix || 'PR-') + '"></label>' +
      '<label class="text-sm font-black">بادئة RFQ<input id="pg-s-rfq" class="w-full border rounded-xl p-3 mt-1" value="' + esc(s.rfq_prefix || 'RFQ-') + '"></label>' +
      '<label class="text-sm font-black">بادئة العرض<input id="pg-s-quote" class="w-full border rounded-xl p-3 mt-1" value="' + esc(s.quotation_prefix || 'PQT-') + '"></label>' +
      '<label class="text-sm font-black">بادئة الفاتورة<input id="pg-s-invoice" class="w-full border rounded-xl p-3 mt-1" value="' + esc(s.invoice_prefix || 'PINV-') + '"></label>' +
      '<label class="text-sm font-black">بادئة المرتجع<input id="pg-s-return" class="w-full border rounded-xl p-3 mt-1" value="' + esc(s.return_prefix || 'PRT-') + '"></label>' +
      '<label class="text-sm font-black">بادئة الدفعة<input id="pg-s-payment-prefix" class="w-full border rounded-xl p-3 mt-1" value="' + esc(s.payment_prefix || 'PPMT-') + '"></label>' +
      '<label class="text-sm font-black">الفرع الافتراضي<select id="pg-s-branch" class="w-full border rounded-xl p-3 mt-1">' + branchOptions + '</select></label>' +
      '</div></div>' +

      '<div class="bg-white border rounded-2xl p-5">' +
      '<div class="font-black text-lg mb-4">سياسات التشغيل</div>' +
      '<div class="grid grid-cols-1 md:grid-cols-2 gap-3">' +
      '<label class="flex items-center gap-3 rounded-xl border p-4"><input id="pg-s-approval" type="checkbox" ' + (s.require_request_approval !== false ? 'checked' : '') + '><span><span class="font-black">اعتماد طلبات الشراء</span><span class="block text-xs text-slate-500">لا ينتقل الطلب مباشرة إلى دورة RFQ قبل الاعتماد.</span></span></label>' +
      '<label class="flex items-center gap-3 rounded-xl border p-4"><input id="pg-s-receive" type="checkbox" ' + (s.require_receiving_before_invoice === true ? 'checked' : '') + '><span><span class="font-black">الاستلام قبل الفاتورة</span><span class="block text-xs text-slate-500">استخدام سياسة الاستلام قبل الفوترة.</span></span></label>' +
      '<label class="flex items-center gap-3 rounded-xl border p-4"><input id="pg-s-payment" type="checkbox" ' + (s.require_invoice_before_payment !== false ? 'checked' : '') + '><span><span class="font-black">الفاتورة قبل الدفع</span><span class="block text-xs text-slate-500">منع الدفع قبل وجود فاتورة شراء.</span></span></label>' +
      '<label class="flex items-center gap-3 rounded-xl border p-4"><input id="pg-s-inventory" type="checkbox" ' + (s.require_inventory_on_invoice !== false ? 'checked' : '') + '><span><span class="font-black">ربط الفاتورة بالمخزون</span><span class="block text-xs text-slate-500">تفعيل سياسة الربط مع محرك المخزون.</span></span></label>' +
      '<label class="flex items-center gap-3 rounded-xl border p-4"><input id="pg-s-return-voucher" type="checkbox" ' + (s.require_inventory_voucher_on_return !== false ? 'checked' : '') + '><span><span class="font-black">إذن مخزني عند المرتجع</span><span class="block text-xs text-slate-500">يحافظ على فصل دورة المشتريات عن محرك المخزون.</span></span></label>' +
      '</div>' +
      '<button type="button" onclick="RW_PurchaseGold.saveSettings()" class="mt-5 px-6 py-3 rounded-xl bg-emerald-600 text-white font-black"><i class="fas fa-save ml-2"></i>حفظ إعدادات المشتريات</button>' +
      '</div>' +
      '</div>'
    );
  }
```

## 11. Replace saveSettings()
Current function: source lines 9979–10001.

DELETE the entire current function through the closing `}` immediately before:
```javascript
  return {
```

Replace with:

```javascript
  async function saveSettings() {
    var payload = {
      default_currency: byId('pg-s-currency').value.trim() || 'SAR',
      request_prefix: byId('pg-s-request').value.trim() || 'PR-',
      rfq_prefix: byId('pg-s-rfq').value.trim() || 'RFQ-',
      quotation_prefix: byId('pg-s-quote').value.trim() || 'PQT-',
      invoice_prefix: byId('pg-s-invoice').value.trim() || 'PINV-',
      return_prefix: byId('pg-s-return').value.trim() || 'PRT-',
      payment_prefix: byId('pg-s-payment-prefix').value.trim() || 'PPMT-',
      default_branch_id: byId('pg-s-branch').value || null,
      require_request_approval: byId('pg-s-approval').checked,
      require_receiving_before_invoice: byId('pg-s-receive').checked,
      require_invoice_before_payment: byId('pg-s-payment').checked,
      require_inventory_on_invoice: byId('pg-s-inventory').checked,
      require_inventory_voucher_on_return: byId('pg-s-return-voucher').checked
    };

    showLoader('جاري حفظ إعدادات دورة المشتريات...');

    try {
      var r = await api('SAVE_SETTINGS', payload);
      hideLoader();
      showToast('تم حفظ إعدادات دورة المشتريات', 'success');
      await refresh();
      return r;
    } catch (e) {
      hideLoader();
      showToast(e.message, 'error');
      throw e;
    }
  }
```

## 12. Do not modify these already-correct functions
Do NOT edit:
- `approveRequest`
- `sendRFQ`
- `acceptQuotation`
- `convertQuotation`
- `postInvoice`
- `postReturn`
unless a fresh Browser/Network test proves a separate defect.

## 13. Important backend alignment
Current Production `purchase_create_invoice_atomic` does NOT accept `supplier_invoice_no`, so the new modal intentionally reads it only as UI context and removes it before the API call. Do not add a frontend-only fake persistence claim.

## 14. Expected functional result
The modal flow becomes:
Request:
structured header → validated item lines → save through API/RPC

RFQ:
request selection → inherited request lines → multi-supplier selection → save through API/RPC

Quotation:
supplier/RFQ → inherited RFQ lines → editable price/discount/tax → totals → save through API/RPC

Invoice:
supplier/PO/branch → inherited PO lines → editable bill lines → save through API/RPC

Return:
invoice → received quantity limits → selected return lines → save through API/RPC

Payment:
supplier/treasury → multi-invoice allocation → amount validation → save through API/RPC

Reports:
single authoritative purchase_get_reports call

Settings:
complete purchase_settings controls + default branch → SAVE_SETTINGS API/RPC

Realtime:
Mother subscribes to the currently published purchase master transaction tables and refreshes the active Purchase view when no modal is open.
