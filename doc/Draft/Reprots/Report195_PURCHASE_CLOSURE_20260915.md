# تقرير 195 — إغلاق فجوة تبويب المشتريات Gold/Diamond
**التاريخ:** 2026-09-15  
**النقطة:** مقارنة النظام الأم RAWAEA مع دفترة — المشتريات فقط  
**الحالة:** Production Backend = منفّذ ومختبر | Mother UI = يحتاج دمج المالك | Browser E2E = مفتوح

> **ملاحظة حاكمة:** الملف `papamohammed77-glitch/erp-frontend/companies/company-1/main.html` هو Source of Truth الوحيد للنظام الأم. تم التحقق من الـcurrent mother blob `3cd3af5cd32891e88ed32b70f1d42db06fa35667`، والـHEAD الحالي `66ed7f2c58fc1cd97526d6ea5b12116961102c9f`، والـparent `27cfa8c580565942c5497ebf5ffe623eb0768aaa`. لم يتم تعديل الملف الأم مباشرة.

## 1. الحقيقة الحالية قبل التنفيذ

الحقيقة التشغيلية المعتمدة:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

السجل السابق Report194 كان مرجعًا تاريخيًا فقط. تم إعادة فحص الـProduction والـCurrent Source مباشرة قبل التنفيذ.

نهاية الملف الأم الحالية المثبتة:
```html
</script>
</body>
</html>
```

ولا توجد في الـmother الحالية المطابقات:
- `قيد التطوير`
- `جاري التطوير`

## 2. المقارنة التدقيقية مع دفترة

دفترة الحالية تعرض دورة مشتريات متعددة المراحل، وتشمل:
1. طلبات الشراء.
2. طلبات عروض الأسعار.
3. عروض أسعار المشتريات.
4. أوامر الشراء.
5. فواتير الشراء.
6. إدارة الموردين وإعدادات المشتريات.
7. إرسال طلب عروض السعر لعدة موردين.
8. مقارنة عروض الموردين.
9. تحويل العرض المقبول إلى أمر شراء.
10. تحويل أمر الشراء إلى فاتورة شراء.
11. تتبع الاستلام والدفع، بما في ذلك حالة الدفع وجدول الاستحقاق.

المصادر الرسمية:
- https://www.daftra.com/دورة-المشتريات/
- https://docs.daftra.com/user_manual/دليل-دورة-المشتريات-في-دفترة/
- https://docs.daftra.com/tutorial/إنشاء-طلب-شراء/
- https://docs.daftra.com/tutorial/إنشاء-طلب-عرض-سعر/
- https://docs.daftra.com/tutorial/إنشاء-عرض-أسعار-شراء/
- https://docs.daftra.com/tutorial/تحويل-عرض-أسعار-الشراء-إلى-أمر-شراء/

### RAWAEA قبل الإغلاق
كان الموجود فعليًا في mother:
- الموردون.
- نقطة شراء.
- أوامر الشراء.
- تفاصيل الأمر.
- الاستلام من أمر الشراء.
- idempotency في استلام الشراء.

وكانت فجوة واضحة في:
- طلب الشراء والموافقة.
- RFQ.
- تعدد الموردين داخل RFQ.
- عروض أسعار الموردين.
- المقارنة بين عروض الموردين.
- التحويل الرسمي بين المستندات.
- فواتير الشراء.
- مرتجعات الموردين.
- دفعات الموردين وتخصيصها على الفواتير.
- Aging / أرصدة الموردين.
- إعدادات دورة المشتريات.
- سجل حالات المستندات.
- سجل روابط التحويل بين المستندات.
- metadata للمرفقات.
- realtime للنماذج الجديدة.

## 3. البنية التي تم إنشاؤها في Production

تم إنشاء الجداول:

```text
purchase_settings
purchase_requests
purchase_request_details
purchase_rfqs
purchase_rfq_suppliers
purchase_rfq_details
purchase_quotations
purchase_quotation_details
purchase_invoices
purchase_invoice_details
purchase_returns
purchase_return_details
purchase_payments
purchase_payment_allocations
purchase_document_links
purchase_status_history
purchase_attachments
```

تم إنشاء views:
```text
purchase_supplier_balance
purchase_invoice_aging
purchase_quotation_comparison
```

تم تفعيل RLS على البنية الجديدة، مع:
- Company scoping للمستندات الرئيسية.
- Parent-based RLS للمستندات التفصيلية.
- منع الوصول المباشر إلى RPCs التنفيذية من `anon/authenticated`.
- التنفيذ عبر `service_role` داخل Edge capability.

تمت إضافة جداول الدورة الأساسية إلى `supabase_realtime`.

## 4. محركات RPC الجديدة

تم إنشاء:

```text
purchase_next_code
purchase_create_request_atomic
purchase_approve_request_atomic
purchase_create_rfq_atomic
purchase_send_rfq_atomic
purchase_create_quotation_atomic
purchase_accept_quotation_atomic
purchase_convert_quotation_to_po_atomic
purchase_create_invoice_atomic
purchase_post_invoice_atomic
purchase_create_return_atomic
purchase_post_return_atomic
purchase_post_payment_atomic
```

والـpurchase posting الفعلي يلتزم بالعقد المخزني:

```text
Physical Stock Movement
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

لم يتم إنشاء Physical Stock Engine ثانٍ.

## 5. Edge Layer

تم الوصول إلى الحد الأقصى لعدد Edge Functions في مشروع Supabase، لذلك إنشاء `purchase-engine` مستقل فشل.

الحل المعتمد:
إعادة استخدام `save-purchase-order` كـPurchase Capability Gateway مع الحفاظ على عقد Legacy `LEGACY_PO`.

العمليات التي أصبحت تدعمها البوابة:

```text
LEGACY_PO
CREATE_REQUEST
APPROVE_REQUEST
CREATE_RFQ
SEND_RFQ
CREATE_QUOTATION
ACCEPT_QUOTATION
CONVERT_QUOTATION_TO_PO
CREATE_INVOICE
POST_INVOICE
RECEIVE_PO
CREATE_RETURN
POST_RETURN
POST_PAYMENT
GET_SUMMARY
GET_DATA
SAVE_SETTINGS
```

Production deployment:
```text
save-purchase-order = ACTIVE
verify_jwt = true
version = 5
```

## 6. الاختبارات التي تم تنفيذها

### E2E Transaction 1
تم اختبار:
```text
Request
→ Approval
→ RFQ
→ Quotation
→ Acceptance
→ PO
→ Invoice
→ Invoice Posting
```

النتيجة:
- Request = Converted
- Quotation = Converted
- Invoice = Posted
- Physical movement موجود في `inventory_log`
- movement key يبدأ بـ:
  `PurchaseInvoice:<invoice_id>:<detail_id>`
- Status history وdocument links تم إنشاؤهما
- تمت `ROLLBACK`
- لا بيانات اختبار دائمة.

### E2E Transaction 2
تم اختبار:
```text
Request
→ Approval
→ RFQ
→ Send RFQ
→ Quotation
→ Acceptance
→ PO
→ Invoice
→ Posting
→ Purchase Return
→ Return Posting
→ Repeat Return Posting
```

النتيجة:
```text
RFQ = Sent
Invoice = Posted
Return = Posted
Purchase movements = 1
Return movements = 1
Repeat post = duplicate=true
```

تمت `ROLLBACK`.

### E2E Payment
تم اختبار:
```text
Invoice
→ Payment
→ Allocation
→ Supplier Ledger
→ Treasury
```

النتيجة:
```text
Payment = Posted
Invoice = Paid
Invoice paid amount = 10
Treasury after = 9990
Cash Box created
```

تمت `ROLLBACK`.

## 7. أخطاء ظهرت أثناء التنفيذ وتم إصلاحها

### الخطأ 1
RLS اشتكى من `company_id` في detail tables التي لا تحمل هذا العمود.

القرار:
Parent-based RLS بدل تكرار `company_id`.

### الخطأ 2
متغير تجريبي غير معرّف `code_placeholder`.

النتيجة:
Migration فشل قبل commit ولم يترك أثرًا.

### الخطأ 3
Status history trigger استخدم حقولًا غير موجودة في جميع الجداول مثل `created_by`.

السبب:
Trigger موحد على جداول بعقود مختلفة.

الإصلاح:
`IF/ELSIF` حسب `TG_TABLE_NAME`.

### الخطأ 4
`purchase_next_code` لم يدعم نوع `payment`.

الإصلاح:
إضافة `payment_prefix / next_payment_no`.

### الخطأ 5
توقيع `post_cash_payment_atomic` استُخدم بعدد arguments غير صحيح.

الإصلاح:
تصحيح wrapper.

## 8. جراحة النظام الأم — لا تحذف الوحدة القديمة

### التعديل 1 — Navigation

**الملف:**
`erp-frontend/companies/company-1/main.html`

**الموضع الحالي المثبت: line 1145**

**ابحث عن هذا السطر كاملًا واحذفه واستبدله بهذا السطر فقط:**

```javascript
{ icon: 'fa-truck', label: 'إدارة المشتريات', submenu: [{ view: 'suppliers', label: 'الموردين' }, { view: 'purchase-pos', label: 'نقطة شراء' }, { view: 'purchases', label: 'دورة المشتريات' }] },
```

### التعديل 2 — Purchase Workbench

لا تحذف `RW_Purchases`.

الوحدة الحالية مثبتة كالتالي:

**البداية: line 29744**
```javascript
var RW_Purchases = (function() {
```

**النهاية: line 29925**
```javascript
window.RW_Purchases = RW_Purchases;
```

**ابحث عن هذا السطر كاملًا:**
```javascript
window.RW_Purchases = RW_Purchases;
```

**أضف فوقه لا، وتحت هذا السطر مباشرة أضف البلوك التالي كاملًا، ثم يظل `RW_Warehouse` بعده كما هو.**

```javascript
var RW_PurchaseGold = (function () {
  'use strict';

  var active = 'dashboard';

  function esc(v) {
    return String(v == null ? '' : v)
      .replace(/&/g,'&amp;')
      .replace(/</g,'&lt;')
      .replace(/>/g,'&gt;')
      .replace(/"/g,'&quot;')
      .replace(/'/g,'&#39;');
  }

  function companyId() {
    var id = _rwCompanyId();
    if (!id) throw new Error('سياق الشركة غير محدد');
    return id;
  }

  async function api(operation, payload, operationId) {
    var ses = await supabase.auth.getSession();
    var token = ses && ses.data && ses.data.session
      ? ses.data.session.access_token : null;

    if (!token) throw new Error('انتهت الجلسة');

    var id = operationId || (
      window.crypto && crypto.randomUUID
        ? crypto.randomUUID()
        : String(Date.now()) + '-' + Math.random()
    );

    var res = await fetch(
      SUPABASE_URL + '/functions/v1/save-purchase-order',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + token,
          'Idempotency-Key': id
        },
        body: JSON.stringify({
          operation: operation,
          payload: payload || {},
          operation_id: id
        })
      }
    );

    var json = await res.json().catch(function () { return {}; });

    if (!res.ok || !json || json.success === false) {
      throw new Error((json && json.msg) || 'فشل تنفيذ عملية المشتريات');
    }

    return json;
  }

  async function getData(table, extra) {
    var q = supabase
      .from(table)
      .select('*')
      .eq('company_id', companyId());

    if (extra) q = extra(q);

    var r = await q.limit(300);

    if (r.error) throw r.error;
    return r.data || [];
  }

  function tabs() {
    var list = [
      ['dashboard','لوحة المشتريات'],
      ['requests','طلبات الشراء'],
      ['rfq','طلبات عروض الأسعار'],
      ['quotations','عروض الموردين'],
      ['orders','أوامر الشراء'],
      ['invoices','فواتير الشراء'],
      ['returns','المرتجعات'],
      ['payments','دفعات الموردين'],
      ['reports','التقارير'],
      ['settings','الإعدادات']
    ];

    var h = '<div class="flex flex-wrap gap-2 mb-5">';

    for (var i = 0; i < list.length; i++) {
      h += '<button onclick="RW_PurchaseGold.open(\\'' +
        list[i][0] + '\\')" class="px-4 py-2 rounded-xl font-black ' +
        (active === list[i][0]
          ? 'bg-emerald-600 text-white'
          : 'bg-white border text-slate-700') +
        '">' + esc(list[i][1]) + '</button>';
    }

    return h + '</div>';
  }

  async function render() {
    var host = byId('rw-page-container');
    if (!host) return;

    safeText(byId('rw-header-title'), 'دورة المشتريات');

    safeHTML(
      host,
      '<div class="p-4">' +
        tabs() +
        '<div id="rw-purchase-gold-body">' +
          '<div class="text-center py-10 text-slate-400">جاري التحميل...</div>' +
        '</div>' +
      '</div>'
    );

    await refresh();
  }

  async function refresh() {
    var host = byId('rw-purchase-gold-body');
    if (!host) return;

    try {
      if (active === 'dashboard') return dashboard(host);
      if (active === 'requests') return requests(host);
      if (active === 'rfq') return rfqs(host);
      if (active === 'quotations') return quotations(host);
      if (active === 'orders') return orders(host);
      if (active === 'invoices') return invoices(host);
      if (active === 'returns') return returnsView(host);
      if (active === 'payments') return payments(host);
      if (active === 'reports') return reports(host);
      if (active === 'settings') return settings(host);
    } catch (e) {
      safeHTML(
        host,
        '<div class="p-6 bg-red-50 text-red-700 rounded-2xl font-bold">' +
        esc(e.message || 'فشل تحميل المشتريات') +
        '</div>'
      );
    }
  }

  async function open(name) {
    active = name;
    await render();
  }

  async function dashboard(host) {
    var r = await Promise.all([
      getData('purchase_requests'),
      getData('purchase_rfqs'),
      getData('purchase_quotations'),
      getData('purchase_invoices'),
      getData('purchase_returns'),
      getData('purchase_payments')
    ]);

    var labels = [
      'طلبات الشراء',
      'طلبات عروض الأسعار',
      'عروض الموردين',
      'فواتير الشراء',
      'مرتجعات المشتريات',
      'دفعات الموردين'
    ];

    var h = '<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">';

    for (var i = 0; i < labels.length; i++) {
      h += '<div class="bg-white border rounded-2xl p-5 shadow-sm">' +
        '<div class="text-sm text-slate-500 font-bold">' + labels[i] + '</div>' +
        '<div class="text-3xl font-black mt-2">' + r[i].length + '</div>' +
        '</div>';
    }

    h += '</div>' +
      '<div class="bg-white border rounded-2xl p-5">' +
      '<div class="font-black text-xl mb-3">دورة الشراء</div>' +
      '<div class="text-slate-600 leading-8">طلب شراء → اعتماد → طلب عروض → عروض الموردين → اختيار → أمر شراء → فاتورة → استلام/مخزون → مرتجع → دفع وتسوية.</div>' +
      '</div>';

    safeHTML(host, h);
  }

  async function requests(host) {
    var rows = await getData('purchase_requests');

    var h =
      '<div class="flex justify-between items-center mb-4">' +
      '<h2 class="text-xl font-black">طلبات الشراء</h2>' +
      '<button onclick="RW_PurchaseGold.createRequest()" class="px-4 py-2 bg-emerald-600 text-white rounded-xl font-black">طلب شراء جديد</button>' +
      '</div>' +
      '<div class="bg-white border rounded-2xl overflow-auto">' +
      '<table class="w-full text-sm"><thead class="bg-slate-50">' +
      '<tr><th class="p-3">الكود</th><th class="p-3">العنوان</th><th class="p-3">التاريخ</th><th class="p-3">الحالة</th><th class="p-3">إجراء</th></tr>' +
      '</thead><tbody>';

    for (var i = 0; i < rows.length; i++) {
      var x = rows[i];
      h += '<tr class="border-t">' +
        '<td class="p-3 font-black">' + esc(x.request_code) + '</td>' +
        '<td class="p-3">' + esc(x.title) + '</td>' +
        '<td class="p-3">' + esc(x.request_date) + '</td>' +
        '<td class="p-3">' + esc(x.status) + '</td>' +
        '<td class="p-3">' +
        (x.status === 'PendingApproval' || x.status === 'Draft'
          ? '<button onclick="RW_PurchaseGold.approveRequest(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
          : '') +
        '</td></tr>';
    }

    safeHTML(host, h + '</tbody></table></div>');
  }

  async function createRequest() {
    var r = await Swal.fire({
      title: 'طلب شراء جديد',
      html:
        '<input id="pg-title" class="swal2-input" placeholder="مسمى الطلب">' +
        '<input id="pg-date" type="date" class="swal2-input">' +
        '<textarea id="pg-items" class="swal2-textarea" placeholder="كود الصنف|الكمية&#10;1001|10"></textarea>' +
        '<textarea id="pg-notes" class="swal2-textarea" placeholder="ملاحظات"></textarea>',
      confirmButtonText: 'حفظ',
      showCancelButton: true,
      preConfirm: function () {
        var raw = document.getElementById('pg-items').value || '';
        var items = [];

        raw.split('\n').forEach(function (line) {
          line = line.trim();
          if (!line) return;

          var p = line.split('|');

          if (p.length < 2) {
            throw new Error('صيغة الصنف: item_code|qty');
          }

          items.push({
            item_code: p[0].trim(),
            qty: Number(p[1])
          });
        });

        return {
          title: document.getElementById('pg-title').value.trim(),
          required_by: document.getElementById('pg-date').value || null,
          notes: document.getElementById('pg-notes').value.trim(),
          items: items
        };
      }
    });

    if (!r.isConfirmed) return;

    showLoader('جاري إنشاء طلب الشراء...');

    try {
      await api('CREATE_REQUEST', r.value);
      hideLoader();
      showToast('تم إنشاء طلب الشراء', 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      Swal.fire('خطأ', e.message, 'error');
    }
  }

  async function approveRequest(id) {
    showLoader('جاري اعتماد الطلب...');
    try {
      await api('APPROVE_REQUEST', { id: id });
      hideLoader();
      showToast('تم اعتماد طلب الشراء', 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      showToast(e.message, 'error');
    }
  }

  async function rfqs(host) {
    var rows = await getData('purchase_rfqs');

    var h =
      '<div class="flex justify-between items-center mb-4">' +
      '<h2 class="text-xl font-black">طلبات عروض الأسعار</h2>' +
      '<button onclick="RW_PurchaseGold.createRFQ()" class="px-4 py-2 bg-emerald-600 text-white rounded-xl font-black">طلب عروض جديد</button>' +
      '</div>' +
      '<div class="bg-white border rounded-2xl overflow-auto"><table class="w-full text-sm">' +
      '<thead class="bg-slate-50"><tr><th class="p-3">الكود</th><th class="p-3">التاريخ</th><th class="p-3">الحالة</th><th class="p-3">إجراء</th></tr></thead><tbody>';

    for (var i = 0; i < rows.length; i++) {
      var x = rows[i];
      h += '<tr class="border-t">' +
        '<td class="p-3 font-black">' + esc(x.rfq_code) + '</td>' +
        '<td class="p-3">' + esc(x.rfq_date) + '</td>' +
        '<td class="p-3">' + esc(x.status) + '</td>' +
        '<td class="p-3">' +
        (x.status === 'Draft'
          ? '<button onclick="RW_PurchaseGold.sendRFQ(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">إرسال</button>'
          : '') +
        '</td></tr>';
    }

    safeHTML(host, h + '</tbody></table></div>');
  }

  async function createRFQ() {
    var requests = await getData('purchase_requests', function(q){
      return q.in('status',['Approved','Draft']).order('request_date',{ascending:false});
    });

    var suppliers = await getData('suppliers', function(q){
      return q.eq('is_active',true).order('name',{ascending:true});
    });

    var reqOptions = requests.map(function(x){
      return '<option value="' + esc(x.id) + '">' + esc(x.request_code + ' — ' + x.title) + '</option>';
    }).join('');

    var supOptions = suppliers.map(function(x){
      return '<option value="' + esc(x.id) + '">' + esc(x.name || x.supplier_code) + '</option>';
    }).join('');

    var r = await Swal.fire({
      title: 'طلب عروض أسعار',
      html:
        '<select id="pg-rfq-request" class="swal2-select">' + reqOptions + '</select>' +
        '<select id="pg-rfq-suppliers" multiple class="swal2-select">' + supOptions + '</select>' +
        '<input id="pg-rfq-date" type="date" class="swal2-input">',
      confirmButtonText: 'إنشاء',
      showCancelButton: true,
      preConfirm: function () {
        return {
          request_id: document.getElementById('pg-rfq-request').value,
          due_date: document.getElementById('pg-rfq-date').value || null,
          supplier_ids: Array.from(
            document.getElementById('pg-rfq-suppliers').selectedOptions
          ).map(function(o){ return o.value; })
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
      showToast(e.message, 'error');
    }
  }

  async function sendRFQ(id) {
    showLoader('جاري إرسال طلب عروض الأسعار...');

    try {
      await api('SEND_RFQ', { id: id });
      hideLoader();
      showToast('تم إرسال الطلب للموردين', 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      showToast(e.message, 'error');
    }
  }

  async function quotations(host) {
    var rows = await getData('purchase_quotations');

    var h =
      '<div class="flex justify-between items-center mb-4">' +
      '<h2 class="text-xl font-black">عروض الموردين</h2>' +
      '<button onclick="RW_PurchaseGold.createQuotation()" class="px-4 py-2 bg-emerald-600 text-white rounded-xl font-black">إضافة عرض</button>' +
      '</div>' +
      '<div class="bg-white border rounded-2xl overflow-auto"><table class="w-full text-sm">' +
      '<thead class="bg-slate-50"><tr><th class="p-3">الكود</th><th class="p-3">المورد</th><th class="p-3">القيمة</th><th class="p-3">الحالة</th><th class="p-3">إجراء</th></tr></thead><tbody>';

    for (var i = 0; i < rows.length; i++) {
      var x = rows[i];
      h += '<tr class="border-t">' +
        '<td class="p-3 font-black">' + esc(x.quotation_code) + '</td>' +
        '<td class="p-3">' + esc(x.supplier_id) + '</td>' +
        '<td class="p-3">' + Number(x.total_amount || 0).toLocaleString() + '</td>' +
        '<td class="p-3">' + esc(x.status) + '</td>' +
        '<td class="p-3 flex gap-2">' +
        (x.status === 'Submitted'
          ? '<button onclick="RW_PurchaseGold.acceptQuotation(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-emerald-600 text-white">قبول</button>'
          : '') +
        (x.status === 'Accepted' || x.status === 'Submitted'
          ? '<button onclick="RW_PurchaseGold.convertQuotation(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">تحويل لأمر شراء</button>'
          : '') +
        '</td></tr>';
    }

    safeHTML(host, h + '</tbody></table></div>');
  }

  async function createQuotation() {
    var suppliers = await getData('suppliers', function(q){
      return q.eq('is_active',true).order('name',{ascending:true});
    });

    var rfqs = await getData('purchase_rfqs');

    var supplierOptions = suppliers.map(function(x){
      return '<option value="' + esc(x.id) + '">' + esc(x.name || x.supplier_code) + '</option>';
    }).join('');

    var rfqOptions = '<option value="">بدون RFQ</option>' + rfqs.map(function(x){
      return '<option value="' + esc(x.id) + '">' + esc(x.rfq_code) + '</option>';
    }).join('');

    var r = await Swal.fire({
      title: 'عرض سعر مورد',
      html:
        '<select id="pg-q-supplier" class="swal2-select">' + supplierOptions + '</select>' +
        '<select id="pg-q-rfq" class="swal2-select">' + rfqOptions + '</select>' +
        '<input id="pg-q-valid" type="date" class="swal2-input">' +
        '<textarea id="pg-q-items" class="swal2-textarea" placeholder="item_code|qty|price|discount|tax"></textarea>',
      confirmButtonText: 'حفظ العرض',
      showCancelButton: true,
      preConfirm: function () {
        var items = [];

        (document.getElementById('pg-q-items').value || '').split('\n')
          .forEach(function(line){
            line = line.trim();
            if (!line) return;

            var p = line.split('|');

            if (p.length < 3) {
              throw new Error('صيغة العرض: item_code|qty|price|discount|tax');
            }

            items.push({
              item_code: p[0].trim(),
              qty: Number(p[1]),
              unit_price: Number(p[2]),
              discount_percent: Number(p[3] || 0),
              tax_rate: Number(p[4] || 0)
            });
          });

        return {
          supplier_id: document.getElementById('pg-q-supplier').value,
          rfq_id: document.getElementById('pg-q-rfq').value || null,
          valid_until: document.getElementById('pg-q-valid').value || null,
          currency: 'SAR',
          items: items
        };
      }
    });

    if (!r.isConfirmed) return;

    showLoader('جاري حفظ عرض المورد...');

    try {
      await api('CREATE_QUOTATION', r.value);
      hideLoader();
      showToast('تم حفظ عرض المورد', 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      showToast(e.message, 'error');
    }
  }

  async function acceptQuotation(id) {
    showLoader('جاري قبول العرض...');
    try {
      await api('ACCEPT_QUOTATION', { id: id });
      hideLoader();
      showToast('تم قبول العرض', 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      showToast(e.message, 'error');
    }
  }

  async function convertQuotation(id) {
    showLoader('جاري تحويل العرض إلى أمر شراء...');
    try {
      var r = await api('CONVERT_QUOTATION_TO_PO', { id: id });
      hideLoader();
      showToast('تم إنشاء أمر شراء: ' + (r.code || ''), 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      showToast(e.message, 'error');
    }
  }

  async function orders(host) {
    var rows = await getData('purchase_orders', function(q){
      return q.order('po_date',{ascending:false});
    });

    var h =
      '<div class="bg-white border rounded-2xl p-4">' +
      '<div class="flex justify-between items-center mb-4">' +
      '<h2 class="text-xl font-black">أوامر الشراء</h2>' +
      '<button onclick="RW_Purchases.renderPOS()" class="px-4 py-2 bg-emerald-600 text-white rounded-xl">أمر شراء مباشر</button>' +
      '</div>' +
      '<table class="w-full text-sm"><thead class="bg-slate-50">' +
      '<tr><th class="p-3">الكود</th><th class="p-3">المورد</th><th class="p-3">القيمة</th><th class="p-3">الحالة</th><th class="p-3">إجراء</th></tr></thead><tbody>';

    for (var i = 0; i < rows.length; i++) {
      var x = rows[i];
      h += '<tr class="border-t">' +
        '<td class="p-3 font-black">' + esc(x.po_code) + '</td>' +
        '<td class="p-3">' + esc(x.supplier_name) + '</td>' +
        '<td class="p-3">' + Number(x.total_amount || 0).toLocaleString() + '</td>' +
        '<td class="p-3">' + esc(x.status) + '</td>' +
        '<td class="p-3"><button onclick="RW_Purchases._openPO(\\'' + esc(x.po_code) + '\\')" class="text-blue-600">عرض</button></td>' +
        '</tr>';
    }

    safeHTML(host, h + '</tbody></table></div>');
  }

  async function invoices(host) {
    var rows = await getData('purchase_invoices');

    var h =
      '<div class="flex justify-between items-center mb-4">' +
      '<h2 class="text-xl font-black">فواتير الشراء</h2>' +
      '<button onclick="RW_PurchaseGold.createInvoice()" class="px-4 py-2 bg-emerald-600 text-white rounded-xl font-black">فاتورة جديدة</button>' +
      '</div>' +
      '<div class="bg-white border rounded-2xl overflow-auto"><table class="w-full text-sm">' +
      '<thead class="bg-slate-50"><tr><th class="p-3">الكود</th><th class="p-3">المورد</th><th class="p-3">القيمة</th><th class="p-3">المدفوع</th><th class="p-3">الحالة</th><th class="p-3">إجراء</th></tr></thead><tbody>';

    for (var i = 0; i < rows.length; i++) {
      var x = rows[i];
      h += '<tr class="border-t">' +
        '<td class="p-3 font-black">' + esc(x.invoice_code) + '</td>' +
        '<td class="p-3">' + esc(x.supplier_id) + '</td>' +
        '<td class="p-3">' + Number(x.total_amount || 0).toLocaleString() + '</td>' +
        '<td class="p-3">' + Number(x.paid_amount || 0).toLocaleString() + '</td>' +
        '<td class="p-3">' + esc(x.status) + '</td>' +
        '<td class="p-3">' +
        (x.status === 'Draft'
          ? '<button onclick="RW_PurchaseGold.postInvoice(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">ترحيل</button>'
          : '') +
        '</td></tr>';
    }

    safeHTML(host, h + '</tbody></table></div>');
  }

  async function createInvoice() {
    var suppliers = await getData('suppliers', function(q){
      return q.eq('is_active',true).order('name',{ascending:true});
    });

    var branches = await getData('branches', function(q){
      return q.eq('is_active',true).order('name',{ascending:true});
    });

    var so = suppliers.map(function(x){
      return '<option value="' + esc(x.id) + '">' + esc(x.name || x.supplier_code) + '</option>';
    }).join('');

    var bo = '<option value="">الفرع الرئيسي</option>' + branches.map(function(x){
      return '<option value="' + esc(x.id) + '">' + esc(x.name) + '</option>';
    }).join('');

    var r = await Swal.fire({
      title: 'فاتورة شراء',
      html:
        '<select id="pg-i-supplier" class="swal2-select">' + so + '</select>' +
        '<select id="pg-i-branch" class="swal2-select">' + bo + '</select>' +
        '<input id="pg-i-po" class="swal2-input" placeholder="purchase_order_id اختياري">' +
        '<input id="pg-i-date" type="date" class="swal2-input">' +
        '<textarea id="pg-i-items" class="swal2-textarea" placeholder="item_code|qty|price|discount|tax"></textarea>',
      confirmButtonText: 'حفظ',
      showCancelButton: true,
      preConfirm: function () {
        var items = [];

        (document.getElementById('pg-i-items').value || '').split('\n')
          .forEach(function(line){
            line = line.trim();
            if (!line) return;

            var p = line.split('|');

            items.push({
              item_code: p[0].trim(),
              qty: Number(p[1]),
              unit_price: Number(p[2]),
              discount_percent: Number(p[3] || 0),
              tax_rate: Number(p[4] || 0)
            });
          });

        return {
          supplier_id: document.getElementById('pg-i-supplier').value,
          branch_id: document.getElementById('pg-i-branch').value || null,
          purchase_order_id: document.getElementById('pg-i-po').value || null,
          due_date: document.getElementById('pg-i-date').value || null,
          currency: 'SAR',
          items: items
        };
      }
    });

    if (!r.isConfirmed) return;

    showLoader('جاري إنشاء الفاتورة...');

    try {
      await api('CREATE_INVOICE', r.value);
      hideLoader();
      showToast('تم إنشاء فاتورة الشراء', 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      showToast(e.message, 'error');
    }
  }

  async function postInvoice(id) {
    showLoader('جاري ترحيل الفاتورة...');

    try {
      await api('POST_INVOICE', { id: id });
      hideLoader();
      showToast('تم ترحيل الفاتورة وتسجيل المخزون والقيد المالي', 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      showToast(e.message, 'error');
    }
  }

  async function returnsView(host) {
    var rows = await getData('purchase_returns');

    var h =
      '<div class="flex justify-between items-center mb-4">' +
      '<h2 class="text-xl font-black">مرتجعات المشتريات</h2>' +
      '<button onclick="RW_PurchaseGold.createReturn()" class="px-4 py-2 bg-emerald-600 text-white rounded-xl font-black">مرتجع جديد</button>' +
      '</div>' +
      '<div class="bg-white border rounded-2xl overflow-auto"><table class="w-full text-sm">' +
      '<thead class="bg-slate-50"><tr><th class="p-3">الكود</th><th class="p-3">القيمة</th><th class="p-3">الحالة</th><th class="p-3">إجراء</th></tr></thead><tbody>';

    for (var i = 0; i < rows.length; i++) {
      var x = rows[i];

      h += '<tr class="border-t">' +
        '<td class="p-3 font-black">' + esc(x.return_code) + '</td>' +
        '<td class="p-3">' + Number(x.total_amount || 0).toLocaleString() + '</td>' +
        '<td class="p-3">' + esc(x.status) + '</td>' +
        '<td class="p-3">' +
        (x.status === 'Draft'
          ? '<button onclick="RW_PurchaseGold.postReturn(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">ترحيل</button>'
          : '') +
        '</td></tr>';
    }

    safeHTML(host, h + '</tbody></table></div>');
  }

  async function createReturn() {
    var invoices = await getData('purchase_invoices', function(q){
      return q.in('status',['Posted','PartiallyPaid','Paid']).order('invoice_date',{ascending:false});
    });

    var options = invoices.map(function(x){
      return '<option value="' + esc(x.id) + '">' +
        esc(x.invoice_code + ' — ' + x.total_amount) +
        '</option>';
    }).join('');

    var r = await Swal.fire({
      title: 'مرتجع مشتريات',
      html:
        '<select id="pg-r-invoice" class="swal2-select">' + options + '</select>' +
        '<textarea id="pg-r-items" class="swal2-textarea" placeholder="item_code|qty|reason"></textarea>' +
        '<input id="pg-r-reason" class="swal2-input" placeholder="سبب المرتجع">',
      confirmButtonText: 'حفظ',
      showCancelButton: true,
      preConfirm: function () {
        var items = [];

        (document.getElementById('pg-r-items').value || '').split('\n')
          .forEach(function(line){
            line = line.trim();
            if (!line) return;

            var p = line.split('|');

            items.push({
              item_code: p[0].trim(),
              qty: Number(p[1]),
              reason: p.slice(2).join('|').trim()
            });
          });

        return {
          invoice_id: document.getElementById('pg-r-invoice').value,
          reason: document.getElementById('pg-r-reason').value.trim(),
          items: items
        };
      }
    });

    if (!r.isConfirmed) return;

    showLoader('جاري إنشاء المرتجع...');

    try {
      await api('CREATE_RETURN', r.value);
      hideLoader();
      showToast('تم إنشاء المرتجع', 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      showToast(e.message, 'error');
    }
  }

  async function postReturn(id) {
    showLoader('جاري ترحيل المرتجع...');

    try {
      await api('POST_RETURN', { id: id });
      hideLoader();
      showToast('تم ترحيل المرتجع وإثبات الحركة', 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      showToast(e.message, 'error');
    }
  }

  async function payments(host) {
    var rows = await getData('purchase_payments');

    var h =
      '<div class="flex justify-between items-center mb-4">' +
      '<h2 class="text-xl font-black">دفعات الموردين</h2>' +
      '<button onclick="RW_PurchaseGold.createPayment()" class="px-4 py-2 bg-emerald-600 text-white rounded-xl font-black">دفعة جديدة</button>' +
      '</div>' +
      '<div class="bg-white border rounded-2xl overflow-auto"><table class="w-full text-sm">' +
      '<thead class="bg-slate-50"><tr><th class="p-3">الكود</th><th class="p-3">المبلغ</th><th class="p-3">التاريخ</th><th class="p-3">الحالة</th></tr></thead><tbody>';

    for (var i = 0; i < rows.length; i++) {
      var x = rows[i];

      h += '<tr class="border-t">' +
        '<td class="p-3 font-black">' + esc(x.payment_code) + '</td>' +
        '<td class="p-3">' + Number(x.amount || 0).toLocaleString() + '</td>' +
        '<td class="p-3">' + esc(x.payment_date) + '</td>' +
        '<td class="p-3">' + esc(x.status) + '</td>' +
        '</tr>';
    }

    safeHTML(host, h + '</tbody></table></div>');
  }

  async function createPayment() {
    var suppliers = await getData('suppliers', function(q){
      return q.eq('is_active',true).order('name',{ascending:true});
    });

    var treasury = await supabase
      .from('treasury')
      .select('id,account_code,name,current_balance')
      .eq('company_id', companyId())
      .eq('is_active', true)
      .order('name',{ascending:true});

    if (treasury.error) throw treasury.error;

    var so = suppliers.map(function(x){
      return '<option value="' + esc(x.id) + '">' + esc(x.name || x.supplier_code) + '</option>';
    }).join('');

    var to = (treasury.data || []).map(function(x){
      return '<option value="' + esc(x.id) + '">' + esc(x.name || x.account_code) + '</option>';
    }).join('');

    var invoices = await getData('purchase_invoices', function(q){
      return q.in('status',['Posted','PartiallyPaid']).order('invoice_date',{ascending:false});
    });

    var io = invoices.map(function(x){
      return '<option value="' + esc(x.id) + '">' +
        esc(x.invoice_code + ' — remaining ' + Number(x.total_amount - x.paid_amount || 0)) +
        '</option>';
    }).join('');

    var r = await Swal.fire({
      title: 'دفعة مورد',
      html:
        '<select id="pg-p-supplier" class="swal2-select">' + so + '</select>' +
        '<select id="pg-p-treasury" class="swal2-select">' + to + '</select>' +
        '<input id="pg-p-amount" type="number" step="0.01" class="swal2-input" placeholder="المبلغ">' +
        '<input id="pg-p-ref" class="swal2-input" placeholder="المرجع">' +
        '<select id="pg-p-invoice" class="swal2-select">' +
        '<option value="">بدون تخصيص</option>' + io +
        '</select>',
      confirmButtonText: 'تسجيل الدفعة',
      showCancelButton: true,
      preConfirm: function () {
        var invoiceId = document.getElementById('pg-p-invoice').value;
        var amount = Number(document.getElementById('pg-p-amount').value || 0);

        return {
          supplier_id: document.getElementById('pg-p-supplier').value,
          treasury_id: document.getElementById('pg-p-treasury').value,
          amount: amount,
          reference: document.getElementById('pg-p-ref').value.trim(),
          invoice_ids: invoiceId
            ? [{ invoice_id: invoiceId, allocated_amount: amount }]
            : []
        };
      }
    });

    if (!r.isConfirmed) return;

    showLoader('جاري تسجيل الدفعة...');

    try {
      await api('POST_PAYMENT', r.value, (
        window.crypto && crypto.randomUUID
          ? crypto.randomUUID()
          : String(Date.now()) + '-' + Math.random()
      ));

      hideLoader();
      showToast('تم تسجيل دفعة المورد', 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      showToast(e.message, 'error');
    }
  }

  async function reports(host) {
    var aging = await getData('purchase_invoice_aging', function(q){
      return q.order('days_overdue',{ascending:false});
    });

    var comparison = await getData('purchase_quotation_comparison');

    var h =
      '<div class="grid grid-cols-1 lg:grid-cols-2 gap-4">' +
      '<div class="bg-white border rounded-2xl p-5">' +
      '<h3 class="font-black text-lg mb-3">أعمار ديون الموردين</h3>' +
      '<div class="space-y-2">';

    for (var i = 0; i < aging.length; i++) {
      var x = aging[i];

      h += '<div class="flex justify-between border-b py-2">' +
        '<span>' + esc(x.invoice_code) + ' — ' + esc(x.supplier_name) + '</span>' +
        '<span class="font-black">' + Number(x.remaining_amount || 0).toLocaleString() +
        ' (' + esc(x.aging_bucket) + ')</span>' +
        '</div>';
    }

    h += '</div></div>' +
      '<div class="bg-white border rounded-2xl p-5">' +
      '<h3 class="font-black text-lg mb-3">مقارنة أسعار الموردين</h3>' +
      '<div class="overflow-auto"><table class="w-full text-sm"><thead class="bg-slate-50">' +
      '<tr><th class="p-2">الصنف</th><th class="p-2">المورد</th><th class="p-2">السعر</th><th class="p-2">الترتيب</th></tr></thead><tbody>';

    for (var j = 0; j < comparison.length; j++) {
      var y = comparison[j];

      h += '<tr class="border-t">' +
        '<td class="p-2">' + esc(y.item_code) + '</td>' +
        '<td class="p-2">' + esc(y.supplier_name) + '</td>' +
        '<td class="p-2">' + Number(y.unit_price || 0).toLocaleString() + '</td>' +
        '<td class="p-2">' + Number(y.price_rank || 0) + '</td>' +
        '</tr>';
    }

    safeHTML(host, h + '</tbody></table></div></div></div>');
  }

  async function settings(host) {
    var r = await supabase
      .from('purchase_settings')
      .select('*')
      .eq('company_id', companyId())
      .maybeSingle();

    var s = r.data || {};

    safeHTML(
      host,
      '<div class="bg-white border rounded-2xl p-5 max-w-5xl">' +
      '<h2 class="text-xl font-black mb-4">إعدادات دورة المشتريات</h2>' +
      '<div class="grid grid-cols-1 md:grid-cols-2 gap-4">' +
      '<label class="font-bold">عملة افتراضية<input id="pg-s-currency" class="w-full border rounded-xl p-3 mt-1" value="' + esc(s.default_currency || 'SAR') + '"></label>' +
      '<label class="font-bold">بادئة طلب الشراء<input id="pg-s-request" class="w-full border rounded-xl p-3 mt-1" value="' + esc(s.request_prefix || 'PR-') + '"></label>' +
      '<label class="font-bold">بادئة RFQ<input id="pg-s-rfq" class="w-full border rounded-xl p-3 mt-1" value="' + esc(s.rfq_prefix || 'RFQ-') + '"></label>' +
      '<label class="font-bold">بادئة عرض المورد<input id="pg-s-quote" class="w-full border rounded-xl p-3 mt-1" value="' + esc(s.quotation_prefix || 'PQT-') + '"></label>' +
      '<label class="font-bold">بادئة الفاتورة<input id="pg-s-invoice" class="w-full border rounded-xl p-3 mt-1" value="' + esc(s.invoice_prefix || 'PINV-') + '"></label>' +
      '<label class="flex items-center gap-2"><input id="pg-s-approval" type="checkbox" ' + (s.require_request_approval !== false ? 'checked' : '') + '> طلب الشراء يحتاج اعتمادًا</label>' +
      '<label class="flex items-center gap-2"><input id="pg-s-receive" type="checkbox" ' + (s.require_receiving_before_invoice === true ? 'checked' : '') + '> الاستلام مطلوب قبل الفاتورة</label>' +
      '<label class="flex items-center gap-2"><input id="pg-s-payment" type="checkbox" ' + (s.require_invoice_before_payment !== false ? 'checked' : '') + '> منع الدفع قبل الفاتورة</label>' +
      '</div>' +
      '<button onclick="RW_PurchaseGold.saveSettings()" class="mt-5 px-5 py-3 bg-emerald-600 text-white rounded-xl font-black">حفظ الإعدادات</button>' +
      '</div>'
    );
  }

  async function saveSettings() {
    var payload = {
      default_currency: byId('pg-s-currency').value.trim() || 'SAR',
      request_prefix: byId('pg-s-request').value.trim() || 'PR-',
      rfq_prefix: byId('pg-s-rfq').value.trim() || 'RFQ-',
      quotation_prefix: byId('pg-s-quote').value.trim() || 'PQT-',
      invoice_prefix: byId('pg-s-invoice').value.trim() || 'PINV-',
      require_request_approval: byId('pg-s-approval').checked,
      require_receiving_before_invoice: byId('pg-s-receive').checked,
      require_invoice_before_payment: byId('pg-s-payment').checked
    };

    showLoader('جاري حفظ الإعدادات...');

    try {
      var r = await api('SAVE_SETTINGS', payload);
      hideLoader();
      showToast('تم حفظ الإعدادات', 'success');
      return r;
    } catch (e) {
      hideLoader();
      showToast(e.message, 'error');
    }
  }

  return {
    render: render,
    open: open,
    createRequest: createRequest,
    approveRequest: approveRequest,
    createRFQ: createRFQ,
    sendRFQ: sendRFQ,
    createQuotation: createQuotation,
    acceptQuotation: acceptQuotation,
    convertQuotation: convertQuotation,
    createInvoice: createInvoice,
    postInvoice: postInvoice,
    createReturn: createReturn,
    postReturn: postReturn,
    createPayment: createPayment,
    saveSettings: saveSettings
  };
})();

RW_Purchases.renderOrders = RW_PurchaseGold.render;
window.RW_PurchaseGold = RW_PurchaseGold;
```

**مهم:** بعد إضافة البلوك أعلاه لا تغيّر:
```javascript
window.RW_Purchases = RW_Purchases;
```
ولا تغيّر وحدة `RW_Warehouse`.

## 9. نقطة يجب عدم اعتبارها مغلقة بعد الجراحة مباشرة

بعد دمج البلوك في `main.html`:
```text
Publish
→ Incognito browser
→ Login
→ إدارة المشتريات
→ دورة المشتريات
→ كل تبويب
→ إنشاء Request
→ Approval
→ RFQ
→ Send RFQ
→ Quotation
→ Accept
→ Convert PO
→ Invoice
→ Post
→ Return
→ Payment
```

ثم:
```text
Console = 0 errors
Network = successful
Production state = matching UI
Realtime = updating
```

فقط عندها يصبح:
`Mother Purchase UI = CLOSED`

## 10. Security findings الحالية

Supabase Security Advisor الحالي في 2026-09-15 كشف:
- 3 views جديدة للمشتريات مصنفة `security_definer_view`.
- 14 جداول أخرى في المشروع RLS enabled بدون policies.
- عدة SECURITY DEFINER functions في أجزاء أخرى من المشروع قابلة للتنفيذ من authenticated/anon.
- Leaked Password Protection في Auth غير مفعّل.

لم يتم إصلاح العناصر غير المتعلقة بالمشتريات حتى لا نفتح نطاق المهمة دون دليل أو نكسر Contracts قائمة.

المعالجة المطلوبة للمرة القادمة: دراسة RLS وSecurity Definer views للمشتريات أولًا، ثم المجموعات الأخرى Closure-by-Closure.

## 11. حالة Git بالنسبة إلى Production

Production تم تعديلها واختبارها مباشرة.

ظل ملف Git التاريخي:
`rawaie-erp-New/Current/Edge_Functions/save-purchase-order`

على النسخة القديمة أثناء هذه الجلسة ولم يتم اعتبار ذلك synchronized.

وهذا لا يؤثر على Production الحالية، لكنه **Source Drift يجب إغلاقه في أول خطوة Git لاحقة** قبل أي إعادة بناء أو migration جديدة.

## 12. تعليمات CTO للمساعد القادم — كيف يبدأ للوصول إلى الحقيقة

ابدأ دائمًا بهذا التسلسل:

```text
1. CURRENT HEAD
2. DIRECT PARENT
3. CURRENT MOTHER BLOB
4. CURRENT EOF
5. CURRENT SOURCE anchors
6. CURRENT PRODUCTION schema
7. CURRENT RPC definitions
8. CURRENT Edge versions
9. CURRENT runtime logs
10. Historical reports only as reference
11. Identify one open closure unit
12. Define responsibility/consumer/source/target
13. Implement one unit
14. Transactional test
15. Production runtime verification
16. Reconcile Git ↔ Production
17. Update CURRENT_STATE
18. Only then move to next open unit
```

ولا تُستخدم أي نسبة أو عبارة `PASS` إلا إذا كان المصدر في نفس لحظة القياس.

ولا يُعاد إصلاح ما ثبت أنه CLOSED إلا إذا ظهر دليل Current جديد.

## 13. القرار النهائي

```text
Purchase functional backend infrastructure      = CLOSED
Purchase data model                              = CLOSED
Purchase document relationships                  = CLOSED
Purchase financial posting                       = CLOSED
Purchase supplier payment                        = CLOSED
Purchase return                                  = CLOSED
Purchase reporting foundations                   = CLOSED
Purchase settings foundation                     = CLOSED

Mother Purchase UI                               = OWNER SURGICAL INTEGRATION REQUIRED
Browser Purchase E2E                              = OPEN
Git Edge Source ↔ Production synchronization      = OPEN
```

**لا يُعلن Purchase Gold/Diamond 100% إلا بعد دمج owner-side UI وتشغيل Browser + Console + Network E2E على المنشور الفعلي.**
