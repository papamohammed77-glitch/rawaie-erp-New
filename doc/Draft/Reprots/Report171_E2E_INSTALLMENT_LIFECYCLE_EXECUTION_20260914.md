# تقرير 171 — تنفيذ وإغلاق Installment Lifecycle — E2E / Production / Master UI

**التاريخ:** 14 سبتمبر 2026

> **النقطة الأهم:** الهدف التنفيذي في هذه الجلسة هو اختبار واستكمال **ملف النظام الأم الحالي**:
> `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
>
> وهذا الملف وحده هو Source of Truth للنظام الأم. `Current/PWA/main2/*` و`New-main` وملفات الـPatch والتقارير السابقة Historical/Reference فقط.

## 1. قاعدة الحقيقة

التقارير السابقة لم تُعامل كحالة حالية.

الحالة المعتمدة:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

القواعد:

`REPORT != CURRENT STATE`

`COMMIT != DEPLOYMENT`

`DEPLOYMENT != RUNTIME SUCCESS`

`RUNTIME SUCCESS != PRODUCTION VERIFIED`

`PRODUCTION VERIFIED != FULLY CLOSED`

---

## 2. آخر Git قبل التنفيذ

المستودع:
`papamohammed77-glitch/erp-frontend`

HEAD الحالي:
`48714c33d5fc12646d0c2ea38033d902a52c4d1a`

رسالة HEAD:
`Initialize customer payment real-time updates`

Parent المباشر:
`c379674711d6e67d5c2c01305ae8449dd3c0947e`

رسالة Parent:
`Add real-time customer payment updates functionality`

الـHEAD الأخير غيّر `_renderReceipts()` وأضاف `_customerPaymentRealtimeChannel` ونقل تشغيل Realtime إلى مسار شاشة التحصيل، وبذلك لا يجوز إعادة إصلاح عيوب Report170 القديمة الخاصة بهذا الجزء.

تم فحص حالة الـcommit ولم توجد Status Checks مسجلة تمنح اعتمادًا مستقلًا.

---

## 3. Source of Truth / forensic assembly

تم التحقق أن:

`rawaie-erp-New/forensic_main_assembly.yml`

يشير بالفعل إلى:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

لا يوجد تعديل مطلوب عليه في هذه الجلسة؛ المسار الحالي صحيح بالفعل.

---

## 4. الهدف المفتوح الذي تم تنفيذه

كان العقد:

`Installment lifecycle = OPEN`

المطلوب ليس إنشاء جدول شكلي، وإنما دورة كاملة تشمل:

- إنشاء خطة تقسيط مرتبطة بأمر/فاتورة وعميل داخل الشركة.
- إنشاء بنود الاستحقاقات.
- منع تكرار الخطة النشطة لنفس الأمر.
- توزيع التحصيل على الأقساط بالترتيب.
- دعم Partial Payment.
- تحديث حالة القسط والخطة.
- حساب Overdue/Aging.
- إلغاء الخطة قبل وجود دفعات.
- منع الإلغاء بعد وجود دفعات.
- Idempotency عند إنشاء الخطة.
- Audit.
- Realtime.
- Tenant isolation.
- الارتباط بمنظومة `sales_payment_allocations` القائمة دون إنشاء محرك تحصيل مالي موازٍ.

---

## 5. Production Database — ما تم تنفيذه فعليًا

Supabase project:
`fiilmooggumokxanwiyx`

### 5.1 توسيع `installments`

تمت إضافة:

- `company_id`
- `order_id`
- `customer_uuid`
- `updated_at`
- `created_by`
- `cancelled_at`
- `completed_at`

وتم إنشاء العلاقات:

- `company_id -> companies.id`
- `order_id -> orders.id`
- `customer_uuid -> customers.id`

### 5.2 توسيع `installment_details`

تمت إضافة:

- `company_id`
- `installment_uuid`
- `installment_no`
- `remaining_amount`
- `updated_at`

وتم إنشاء:

`installment_uuid -> installments.id`

### 5.3 جدول الربط المالي الجديد

تم إنشاء:

`public.installment_payment_allocations`

ويربط مباشرة:

`company_id`
`installment_id`
`installment_detail_id`
`sales_payment_allocation_id`
`order_id`
`allocated_amount`
`created_by`
`created_at`

وتم وضع Unique Key على:

`(sales_payment_allocation_id, installment_detail_id)`

لمنع تكرار نفس تخصيص الدفع لنفس القسط.

### 5.4 الفهارس والقيود

تم إنشاء وفحص القيود والفهارس اللازمة لعزل الشركة، منع تعدد الخطط النشطة لنفس الأمر، وتسريع الوصول إلى العميل والحالة والاستحقاق.

### 5.5 RLS

`installments`
`installment_details`
`installment_payment_allocations`

أصبحت مسارات الوصول للمستخدمين المصادق عليهم Company-scoped بدل سياسة `ALL` العامة القديمة.

---

## 6. Production RPCs

تم إنشاء/تثبيت:

### `create_installment_plan_atomic`

المسؤوليات:

- Company-scoped Order.
- Company-scoped Customer.
- رفض Invoice/Order الملغاة.
- رفض الخطة إذا لا يوجد outstanding.
- رفض وجود Active Plan لنفس order.
- فحص كل Schedule Line.
- فحص ترتيب التواريخ.
- مطابقة مجموع الأقساط مع outstanding.
- إنشاء Plan + Details.
- Idempotency عبر `erp_operation_registry`.
- Fingerprint لمنع إعادة استخدام Operation ID مع Payload مختلف.

### `cancel_installment_plan_atomic`

المسؤوليات:

- Company scope.
- يسمح بالإلغاء قبل أي دفعة.
- يرفض الإلغاء بعد وجود `paid_amount > 0`.
- يحوّل الخطة والبنود إلى `Cancelled`.

### `refresh_installment_plan_atomic`

المسؤوليات:

- تحديث `remaining_amount`.
- تحديث حالة كل قسط.
- تحديد Overdue.
- تحديث إجمالي Paid/Remaining.
- تحديث حالة الخطة إلى `Active / Partially Paid / Overdue / Paid`.

### `allocate_sales_payment_to_installment_atomic`

المسؤولية المركزية في التخصيص:

`Sales Payment Allocation -> Installment`

وتوزيع المبلغ يبدأ من أقرب قسط مفتوح بالترتيب، مع دعم partial allocation.

لا توجد كتابة مالية مستقلة خارج Core التحصيل الحالي.

---

## 7. الربط مع Sales Payment Core

لم يتم تعديل `post_sales_payment_allocation_atomic` لتكوين محرك تقسيط منفصل.

تم استخدام Trigger:

`trg_sales_payment_allocation_installment`

على:

`public.sales_payment_allocations`

والـTrigger يستدعي:

`allocate_sales_payment_to_installment_atomic`

وبالتالي مسار الدفع يصبح:

```text
Customer Payment
      ↓
post_sales_payment_allocation_atomic
      ↓
sales_payment_allocations
      ↓
trg_sales_payment_allocation_installment
      ↓
allocate_sales_payment_to_installment_atomic
      ↓
installment_details
      ↓
installments
```

وهذا يحافظ على Source of Truth المالي الحالي بدل إنشاء Ledger/Receipt Engine ثانٍ.

---

## 8. Overdue / Aging

تم إنشاء View:

`public.installment_aging_v`

وتحسب من Production مباشرة:

- Effective Status.
- Next Due Date.
- Overdue Amount.
- Max Overdue Days.
- Customer.
- Order.
- Remaining.

الوصول المباشر لها للمستخدمين تم حجبه، وتستخدمها Edge capability بعد المصادقة وعزل الشركة.

---

## 9. Audit + Realtime

تم إنشاء Audit Triggers على:

- `installments`
- `installment_details`
- `installment_payment_allocations`

وتستخدم البنية الموجودة:

`fn_audit_trigger()`

وتم ربط الجداول الثلاثة بـ`supabase_realtime` عندما كانت publication موجودة.

---

## 10. Edge Function Production

تم نشر:

`installments`

Status:
`ACTIVE`

Version:
`1`

`verify_jwt=true`

Deployment SHA:
`770c6a830f9d95bb5efb4f563c1de37b6581bef1f47856468df7259e77598db7`

العمليات المدعومة:

- `GET` listing / aging.
- `create`
- `cancel`
- `refresh`
- `list`

والسياق يأتي من:

`JWT -> users.auth_id -> users.company_id`

وليس من `app_settings LIMIT 1`.

تم أيضًا حفظ المصدر في Git:

`Current/Edge_Functions/installments/index.ts`

---

## 11. E2E Production Testing

### الاختبار 1 — Create + Retry + Payment Allocation

تم إنشاء Customer وOrder مؤقتين داخل Production Transaction.

الخطة:

- قسط أول: `400` مستحق قبل اليوم.
- قسط ثانٍ: `600` في المستقبل.
- إجمالي الخطة: `1000`.

تم إنشاء الخطة.

تمت محاولة إعادة استخدام نفس Operation ID.

ثم أُنشئ Payment Allocation بمبلغ `400`.

النتيجة المثبتة قبل الـRollback:

- تم تسجيل `allocation_rows = 1`.
- أول قسط أصبح Paid بمقدار `400`.
- الخطة أصبحت `Partially Paid`.
- التخصيص مرتبط فعليًا بـ`sales_payment_allocations`.

تم تنفيذ `refresh_installment_plan_atomic` في نفس السيناريو.

ثم تم `ROLLBACK`.

### الاختبار 2 — Cancel قبل الدفع

تم إنشاء خطة مؤقتة بمبلغ `500`.

تم تنفيذ:

`cancel_installment_plan_atomic`

والنتيجة:

- `plan_status = Cancelled`
- عدد البنود الملغاة = `1`

ثم تم `ROLLBACK`.

### الاختبار 3 — أخطاء تنفيذية أثناء الاختبار

ظهر خطأ SQL في أحد استعلامات التشخيص بسبب اسم عمود غير مؤهل (`paid_amount` أصبح ambiguous في Join).

هذا الخطأ كان في **استعلام الاختبار نفسه** وليس في Production Data ولا في RPC، ولم ينتج عنه تغيير دائم.

ثم أعيد تنفيذ الاختبار باستعلام مصحح ونجح مسار الـallocation.

### الاختبار 4 — Paid Cancel

تم إعداد اختبار منع الإلغاء بعد الدفع، لكن نسخة الاستعلام الأولى توقفت بسبب نفس Ambiguous Column error قبل الوصول للحارس.

لم تُسجل أي بيانات دائمة من هذا الاختبار.

**هذا يعني أن منع الإلغاء بعد الدفع مثبت من تعريف RPC نفسه، لكن السيناريو E2E المستقل الكامل له لم يُسجل كاختبار مستقل ناجح في هذه الجلسة.**

---

## 12. Production Cleanup Verification

بعد كل الاختبارات transactional:

`installments = 0`

`installment_details = 0`

`installment_payment_allocations = 0`

ولا توجد بيانات E2E دائمة من اختبارات هذه الجلسة.

---

## 13. ماذا لم يتم تغييره

### لم يتم تعديل

`erp-frontend/companies/company-1/main.html`

لأن ملكية تعديل النظام الأم في هذه الجلسة للمالك كما حددت التعليمات.

### لم تتم إعادة فتح

إصلاحات Realtime القديمة من Report170؛ الـHEAD الحالي أثبت أنها دخلت بالفعل في commit `48714c33...`.

### لم يتم تعديل

`forensic_main_assembly.yml`

لأن Source of Truth الحالي صحيح بالفعل.

---

# 14. تعليمات Surgical Master UI — يجب تنفيذها على `erp-frontend` فقط

> هذه التعديلات لا ينفذها المساعد. المالك ينفذها على ملف النظام الأم الحالي فقط.

## A — إضافة تبويب التقسيط داخل Finance Navigation

**ابحث عن هذا العنصر الكامل في `RW_Navigation.menuTree`**:

```js
{ action: 'showFinanceTab', arg: 'reports', label: 'التقارير المالية', perm: ['finance', 'finance_manager'] },
```

**استبدله بهذا العنصرين كاملين:**

```js
{ action: 'showFinanceTab', arg: 'reports', label: 'التقارير المالية', perm: ['finance', 'finance_manager'] },
{ action: 'showFinanceTab', arg: 'installments', label: 'التقسيط والتحصيل الآجل', perm: ['finance', 'finance_manager'] },
```

هذا هو العنصر المحدد؛ لا تعدل بقية `menuTree`.

---

## B — تعديل `renderSubTab(subTab)` في `RW_Finance`

الموضع الحالي في `main.html` يقع في كتلة `RW_Finance.renderSubTab` عند المصدر الذي فُحص في الجلسة قرب السطر **10400**.

**ابحث داخل مصفوفة `tabs` عن السطر الكامل:**

```js
{ id: 'reports', label: 'التقارير المالية' }, { id: 'budgets', label: 'الموازنات' }
```

**استبدله بالسطر الكامل:**

```js
{ id: 'reports', label: 'التقارير المالية' }, { id: 'installments', label: 'التقسيط والتحصيل الآجل' }, { id: 'budgets', label: 'الموازنات' }
```

ثم **ابحث عن السطر الكامل:**

```js
else if (tab === 'reports') _renderReports();
```

**واستبدله بالسطرين الكاملين:**

```js
else if (tab === 'reports') _renderReports();
else if (tab === 'installments') _renderInstallments();
```

---

## C — إضافة موديول التقسيط الكامل

الموضع الحالي المؤكد في `main.html` هو قبل:

```js
function _renderBudgets() {
```

وهو في المصدر الحالي قرب السطر **11980+**.

**ابحث عن السطر الكامل:**

```js
function _renderBudgets() {
```

**أضف فوقه مباشرة المقطع الكامل التالي دون حذف `function _renderBudgets()` نفسه:**

```js
function _installmentEndpoint() {
    return RW_SUPABASE_URL + '/functions/v1/installments';
}

function _installmentOperationId() {
    return window.crypto && crypto.randomUUID
        ? crypto.randomUUID()
        : String(Date.now()) + '-' + Math.random();
}

async function _installmentFetch(url, options) {
    var ses = await supabase.auth.getSession();
    var token = ses && ses.data && ses.data.session
        ? ses.data.session.access_token
        : null;
    if (!token) throw new Error('انتهت الجلسة');

    var opts = options || {};
    opts.headers = Object.assign({}, opts.headers || {}, {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
    });

    var res = await fetch(url, opts);
    var json = await res.json().catch(function() { return {}; });
    if (!res.ok || !json || json.success === false) {
        throw new Error((json && (json.msg || json.error)) || 'فشل تنفيذ عملية التقسيط');
    }
    return json;
}

var _installmentRealtimeChannel = null;

function _renderInstallments() {
    var content = byId('finance-content');
    if (!content) return;

    if (_installmentRealtimeChannel) {
        try { supabase.removeChannel(_installmentRealtimeChannel); } catch (e) {}
        _installmentRealtimeChannel = null;
    }

    var html = '' +
        '<div class="space-y-4">' +
        '<div class="bg-white rounded-2xl shadow-sm border p-4">' +
        '<div class="flex flex-wrap justify-between items-center gap-3 mb-4">' +
        '<div>' +
        '<h2 class="text-xl font-black"><i class="fa-solid fa-calendar-days ml-2 text-blue-600"></i>التقسيط والتحصيل الآجل</h2>' +
        '<p class="text-sm text-gray-500 mt-1">إنشاء وإدارة جداول الأقساط ومتابعة الاستحقاقات والتحصيل الفعلي.</p>' +
        '</div>' +
        '<div class="flex gap-2">' +
        '<button type="button" onclick="RW_Finance._loadInstallmentList()" class="bg-gray-100 text-gray-700 px-4 py-2 rounded-xl font-bold"><i class="fa-solid fa-rotate ml-1"></i> تحديث</button>' +
        '</div>' +
        '</div>' +

        '<div class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-4">' +
        '<div><label class="block text-sm font-bold mb-1">الأمر</label><select id="ins-order" class="border rounded-xl p-2.5 w-full"></select></div>' +
        '<div><label class="block text-sm font-bold mb-1">عدد الأقساط</label><input id="ins-count" type="number" min="1" max="120" value="3" class="border rounded-xl p-2.5 w-full"></div>' +
        '<div><label class="block text-sm font-bold mb-1">أول استحقاق</label><input id="ins-start-date" type="date" value="' + new Date().toISOString().slice(0,10) + '" class="border rounded-xl p-2.5 w-full"></div>' +
        '<div><label class="block text-sm font-bold mb-1">الفاصل</label><select id="ins-frequency" class="border rounded-xl p-2.5 w-full"><option value="7">أسبوعي</option><option value="14">كل أسبوعين</option><option value="30" selected>شهري</option><option value="60">كل شهرين</option></select></div>' +
        '</div>' +

        '<div class="flex flex-wrap gap-2 mb-4">' +
        '<button type="button" onclick="RW_Finance._buildInstallmentSchedule()" class="bg-indigo-600 text-white px-5 py-2.5 rounded-xl font-bold"><i class="fa-solid fa-wand-magic-sparkles ml-1"></i> توليد الجدول</button>' +
        '<button type="button" onclick="RW_Finance._createInstallmentPlan()" class="bg-emerald-600 text-white px-5 py-2.5 rounded-xl font-bold"><i class="fa-solid fa-check ml-1"></i> حفظ خطة التقسيط</button>' +
        '</div>' +

        '<div id="ins-schedule" class="overflow-x-auto mb-4"></div>' +
        '</div>' +

        '<div class="bg-white rounded-2xl shadow-sm border p-4">' +
        '<div class="flex flex-wrap justify-between items-center gap-2 mb-4">' +
        '<div><h3 class="text-lg font-black">الخطط الحالية</h3><p class="text-xs text-gray-500">الحالة الفعلية والاستحقاق والمتبقي.</p></div>' +
        '<select id="ins-filter-status" onchange="RW_Finance._loadInstallmentList()" class="border rounded-xl p-2"><option value="">كل الحالات</option><option value="Active">نشطة</option><option value="Partially Paid">مدفوع جزئي</option><option value="Overdue">متأخرة</option><option value="Paid">مسددة</option><option value="Cancelled">ملغاة</option></select>' +
        '</div>' +
        '<div id="ins-list" class="overflow-x-auto"></div>' +
        '</div>' +
        '</div>';

    safeHTML(content, html);

    var companyId = _companyId();
    _installmentRealtimeChannel = supabase
        .channel('rw-installments-' + companyId)
        .on('postgres_changes', { event: '*', schema: 'public', table: 'installments', filter: 'company_id=eq.' + companyId }, function() {
            _loadInstallmentList();
        })
        .on('postgres_changes', { event: '*', schema: 'public', table: 'installment_details', filter: 'company_id=eq.' + companyId }, function() {
            _loadInstallmentList();
        })
        .on('postgres_changes', { event: '*', schema: 'public', table: 'installment_payment_allocations', filter: 'company_id=eq.' + companyId }, function() {
            _loadInstallmentList();
        })
        .subscribe();

    _loadInstallmentOrders();
    _loadInstallmentList();
}

async function _loadInstallmentOrders() {
    try {
        var companyId = _companyId();
        var res = await supabase.from('orders')
            .select('id,order_code,total_amount,amount_paid,customer_id,customer_name,order_status,payment_type,order_date')
            .eq('company_id', companyId)
            .neq('order_status', 'Cancelled')
            .order('created_at', { ascending: false })
            .limit(200);

        if (res.error) throw res.error;
        var orders = res.data || [];
        var select = byId('ins-order');
        if (!select) return;

        var html = '<option value="">اختر أمرًا غير مسدد بالكامل</option>';
        for (var i = 0; i < orders.length; i++) {
            var o = orders[i];
            var outstanding = Math.max(0, Number(o.total_amount || 0) - Number(o.amount_paid || 0));
            if (outstanding <= 0) continue;
            html += '<option value="' + _esc(o.id) + '" data-outstanding="' + outstanding + '" data-customer="' + _esc(o.customer_name || '') + '">' +
                _esc(o.order_code) + ' — ' + _esc(o.customer_name || 'بدون اسم') + ' — متبقي ' + _fmtNum(outstanding) +
                '</option>';
        }
        safeHTML(select, html);
    } catch (e) {
        _showToast(e.message || 'فشل تحميل الأوامر', 'error');
    }
}

function _buildInstallmentSchedule() {
    var select = byId('ins-order');
    var countEl = byId('ins-count');
    var startEl = byId('ins-start-date');
    var freqEl = byId('ins-frequency');
    var out = byId('ins-schedule');
    if (!select || !countEl || !startEl || !freqEl || !out) return;

    var option = select.options[select.selectedIndex];
    var outstanding = option ? Number(option.getAttribute('data-outstanding') || 0) : 0;
    var count = parseInt(countEl.value, 10);
    var frequency = parseInt(freqEl.value, 10);
    var startDate = startEl.value;

    if (!select.value || outstanding <= 0) {
        safeHTML(out, '<div class="text-center py-6 text-amber-600">اختر أمرًا له رصيد مستحق أولًا.</div>');
        return;
    }
    if (!Number.isFinite(count) || count < 1 || count > 120) {
        safeHTML(out, '<div class="text-center py-6 text-red-600">عدد الأقساط يجب أن يكون بين 1 و120.</div>');
        return;
    }
    if (!startDate || !Number.isFinite(frequency) || frequency <= 0) {
        safeHTML(out, '<div class="text-center py-6 text-red-600">بيانات الجدول غير مكتملة.</div>');
        return;
    }

    var baseAmount = Math.floor((outstanding / count) * 100) / 100;
    var lastAmount = Number((outstanding - baseAmount * (count - 1)).toFixed(2));
    var html = '<table class="w-full text-sm border-collapse"><thead><tr class="bg-gray-50"><th class="p-2 border">#</th><th class="p-2 border">الاستحقاق</th><th class="p-2 border">المبلغ</th><th class="p-2 border">ملاحظات</th></tr></thead><tbody>';
    var baseDate = new Date(startDate + 'T00:00:00');

    for (var i = 0; i < count; i++) {
        var d = new Date(baseDate);
        d.setDate(d.getDate() + (i * frequency));
        var iso = d.toISOString().slice(0,10);
        var amount = i === count - 1 ? lastAmount : baseAmount;
        html += '<tr class="border-t">' +
            '<td class="p-2 border text-center font-bold">' + (i + 1) + '</td>' +
            '<td class="p-2 border"><input type="date" class="ins-date border rounded-lg p-2 w-full" value="' + iso + '"></td>' +
            '<td class="p-2 border"><input type="number" step="0.01" min="0.01" class="ins-amount border rounded-lg p-2 w-full" value="' + amount.toFixed(2) + '"></td>' +
            '<td class="p-2 border"><input type="text" class="ins-note border rounded-lg p-2 w-full" placeholder="ملاحظة اختيارية"></td>' +
            '</tr>';
    }
    html += '</tbody></table>';
    safeHTML(out, html);
}

async function _createInstallmentPlan() {
    try {
        var select = byId('ins-order');
        var rows = document.querySelectorAll('#ins-schedule tbody tr');
        if (!select || !select.value) throw new Error('اختر أمرًا أولًا ثم ولّد جدول الأقساط');
        if (!rows.length) throw new Error('ولّد جدول الأقساط أولًا');

        var schedule = [];
        var total = 0;
        for (var i = 0; i < rows.length; i++) {
            var date = rows[i].querySelector('.ins-date').value;
            var amount = Number(rows[i].querySelector('.ins-amount').value);
            var note = rows[i].querySelector('.ins-note').value || '';
            if (!date || !Number.isFinite(amount) || amount <= 0) throw new Error('بيانات القسط رقم ' + (i + 1) + ' غير صحيحة');
            schedule.push({ due_date: date, amount: Number(amount.toFixed(2)), notes: note });
            total += amount;
        }

        var option = select.options[select.selectedIndex];
        var outstanding = Number(option ? option.getAttribute('data-outstanding') || 0 : 0);
        if (Math.abs(total - outstanding) > 0.01) throw new Error('مجموع الأقساط لا يساوي الرصيد المستحق.');

        _showLoader('جاري حفظ خطة التقسيط...');
        var json = await _installmentFetch(_installmentEndpoint(), {
            method: 'POST',
            body: JSON.stringify({
                action: 'create',
                order_id: select.value,
                schedule: schedule,
                operation_id: _installmentOperationId()
            })
        });

        _showToast(json.duplicate ? 'الخطة موجودة بالفعل ولم تُكرر.' : 'تم إنشاء خطة التقسيط بنجاح', 'success');
        _loadInstallmentOrders();
        _loadInstallmentList();
        safeHTML(byId('ins-schedule'), '');
    } catch (e) {
        _showToast(e.message || 'فشل إنشاء خطة التقسيط', 'error');
    } finally {
        _hideLoader();
    }
}

async function _loadInstallmentList() {
    var out = byId('ins-list');
    if (!out) return;
    try {
        safeHTML(out, '<div class="text-center py-6 text-gray-500"><i class="fa-solid fa-spinner fa-spin"></i> جاري التحميل...</div>');
        var status = byId('ins-filter-status') ? byId('ins-filter-status').value : '';
        var url = _installmentEndpoint();
        if (status) url += '?status=' + encodeURIComponent(status);
        var json = await _installmentFetch(url, { method: 'GET' });
        var rows = json.data || [];

        if (!rows.length) {
            safeHTML(out, '<div class="text-center py-8 text-gray-500">لا توجد خطط تقسيط.</div>');
            return;
        }

        var html = '<table class="w-full text-sm border-collapse"><thead><tr class="bg-gray-50"><th class="p-2 border">الخطة</th><th class="p-2 border">الأمر</th><th class="p-2 border">العميل</th><th class="p-2 border">الإجمالي</th><th class="p-2 border">المدفوع</th><th class="p-2 border">المتبقي</th><th class="p-2 border">الاستحقاق التالي</th><th class="p-2 border">متأخر</th><th class="p-2 border">الحالة</th><th class="p-2 border">إجراءات</th></tr></thead><tbody>';
        for (var i = 0; i < rows.length; i++) {
            var r = rows[i];
            var statusClass = r.effective_status === 'Overdue' ? 'text-red-700 bg-red-50' :
                r.effective_status === 'Paid' ? 'text-green-700 bg-green-50' :
                r.effective_status === 'Partially Paid' ? 'text-blue-700 bg-blue-50' :
                r.effective_status === 'Cancelled' ? 'text-gray-700 bg-gray-100' : 'text-amber-700 bg-amber-50';
            html += '<tr class="border-t hover:bg-gray-50">' +
                '<td class="p-2 border font-bold">' + _esc(r.installment_code) + '</td>' +
                '<td class="p-2 border">' + _esc(r.order_code || r.invoice_id) + '</td>' +
                '<td class="p-2 border">' + _esc(r.customer_name || '') + '</td>' +
                '<td class="p-2 border text-left">' + _fmtNum(r.total_amount) + '</td>' +
                '<td class="p-2 border text-left text-green-700">' + _fmtNum(r.paid_amount) + '</td>' +
                '<td class="p-2 border text-left font-black">' + _fmtNum(r.remaining_amount) + '</td>' +
                '<td class="p-2 border">' + _esc(r.next_due_date || '-') + '</td>' +
                '<td class="p-2 border text-left ' + (Number(r.overdue_amount || 0) > 0 ? 'text-red-700 font-bold' : '') + '">' + _fmtNum(r.overdue_amount) + '</td>' +
                '<td class="p-2 border"><span class="px-2 py-1 rounded-full text-xs font-bold ' + statusClass + '">' + _esc(r.effective_status) + '</span></td>' +
                '<td class="p-2 border text-center whitespace-nowrap">' +
                '<button type="button" class="text-indigo-600 mx-1" title="تحديث" onclick="RW_Finance._refreshInstallmentPlan(\'' + _esc(r.installment_id) + '\')"><i class="fa-solid fa-rotate"></i></button>' +
                (r.stored_status !== 'Cancelled' && r.effective_status !== 'Paid' ? '<button type="button" class="text-red-600 mx-1" title="إلغاء" onclick="RW_Finance._cancelInstallmentPlan(\'' + _esc(r.installment_id) + '\')"><i class="fa-solid fa-ban"></i></button>' : '') +
                '</td></tr>';
        }
        html += '</tbody></table>';
        safeHTML(out, html);
    } catch (e) {
        safeHTML(out, '<div class="text-center py-8 text-red-500">' + _esc(e.message || 'فشل تحميل خطط التقسيط') + '</div>');
    }
}

async function _refreshInstallmentPlan(planId) {
    if (!planId) return;
    try {
        _showLoader('جاري تحديث خطة التقسيط...');
        await _installmentFetch(_installmentEndpoint(), {
            method: 'POST',
            body: JSON.stringify({
                action: 'refresh',
                installment_id: planId,
                as_of: new Date().toISOString().slice(0,10)
            })
        });
        _showToast('تم تحديث حالة الخطة', 'success');
        _loadInstallmentList();
    } catch (e) {
        _showToast(e.message || 'فشل تحديث الخطة', 'error');
    } finally {
        _hideLoader();
    }
}

async function _cancelInstallmentPlan(planId) {
    if (!planId) return;
    var ok = window.confirm('تأكيد إلغاء خطة التقسيط؟\nلا يمكن الإلغاء بعد وجود دفعات على الخطة.');
    if (!ok) return;
    try {
        _showLoader('جاري إلغاء خطة التقسيط...');
        await _installmentFetch(_installmentEndpoint(), {
            method: 'POST',
            body: JSON.stringify({
                action: 'cancel',
                installment_id: planId
            })
        });
        _showToast('تم إلغاء خطة التقسيط', 'success');
        _loadInstallmentList();
    } catch (e) {
        _showToast(e.message || 'تعذر إلغاء الخطة', 'error');
    } finally {
        _hideLoader();
    }
}
```

---

## D — تصدير الدوال داخل `RW_Finance` return object

الموضع الحالي داخل `RW_Finance` return object قرب المصدر **12530+**.

**ابحث عن السطر الكامل:**

```js
_renderBudgets: _renderBudgets, _loadBudgetsList: _loadBudgetsList, _editBudget: _editBudget,
```

**واستبدله بالسطرين الكاملين:**

```js
_renderBudgets: _renderBudgets, _loadBudgetsList: _loadBudgetsList, _editBudget: _editBudget,
_renderInstallments: _renderInstallments, _loadInstallmentOrders: _loadInstallmentOrders, _buildInstallmentSchedule: _buildInstallmentSchedule, _createInstallmentPlan: _createInstallmentPlan, _loadInstallmentList: _loadInstallmentList, _refreshInstallmentPlan: _refreshInstallmentPlan, _cancelInstallmentPlan: _cancelInstallmentPlan,
```

لا تحذف أي عنصر آخر من `return` object.

---

# 15. حالة Master UI بعد هذه الجلسة

بعد تطبيق التعديلات الجراحية أعلاه على `erp-frontend/.../main.html` يصبح المسار:

`Finance -> التقسيط والتحصيل الآجل`

ثم:

`Order -> Schedule -> Create Plan -> Production`

والتحصيل الفعلي من أي Receipt/Payment Allocation قائم سيدخل تلقائيًا إلى الخطة عبر Production Trigger.

لكن لا يجوز تسجيل:

`MASTER UI CLOSED`

ولا:

`BROWSER E2E CLOSED`

إلا بعد تشغيل النسخة المنشورة الحالية في متصفح فعلي واختبار الشاشة من البداية للنهاية.

---

# 16. SELF-AUDIT

## ما تم إثباته

- آخر HEAD وParent تم التحقق منهما مباشرة.
- Source of Truth الحالي تم التحقق منه.
- `forensic_main_assembly.yml` صحيح.
- Installment schema أصبح مربوطًا بالشركة والأمر والعميل.
- Installment detail أصبح مربوطًا بالخطة.
- Payment allocation bridge موجود.
- RLS Company-scoped.
- Audit موجود.
- Realtime infrastructure موجود.
- Edge Function Production موجودة.
- Create/Partial Allocation/Refresh transactional flow تم تشغيله على Production ثم rollback.
- Cancel-before-payment تم تشغيله ثم rollback.
- لا توجد بيانات E2E دائمة بعد الاختبارات.

## ما لم يتم إثباته

- لم يتم تنفيذ Browser E2E فعلي داخل `erp-frontend/main.html` في هذه الجلسة لأن تعديل الملف نفسه مملوك للمالك.
- لم يتم اعتماد Paid-Cancel كاختبار E2E مستقل ناجح؛ منعه مثبت في RPC لكن الاختبار المستقل الأول توقف بخطأ SQL في استعلام الاختبار.
- لا يجوز اعتبار تبويب Master UI مغلقًا قبل دمج المالك للتعديل وتشغيله فعليًا.

## ما تم إصلاحه

- تم تحويل Installment lifecycle من skeleton منفصل إلى Production capability مترابطة.
- تم منع العزل الضعيف السابق.
- تم منع إنشاء محرك مالي موازٍ.
- تم ربط التقسيط بـSales Payment Allocation الحالي.
- تم إضافة aging/overdue/realtime/audit.

## ما تم اكتشافه أثناء التنفيذ

- بعض التقارير القديمة كانت تصف حالة أقدم من حالة Git الفعلية.
- الـHEAD الحالي أصلح بالفعل العيب القديم الخاص بالـCustomer Payment Realtime؛ إعادة إصلاحه كانت ستنتج دينًا مكررًا.
- اختبارات SQL المركبة تحتاج تأهيلًا صارمًا لأسماء الأعمدة عند الـJoin لتجنب أخطاء تشخيصية كاذبة.

## ما يمكن أن يكون ما زال خاطئًا

أكبر بند متبقٍ هو Browser/UX Integration حتى يدمج المالك الجراحة المطلوبة ويختبرها على النسخة المنشورة.

---

# 17. الحالة النهائية

```text
Installment DB Foundation             = PRODUCTION DEPLOYED
Installment Relationships             = PRODUCTION DEPLOYED
Installment Payment Bridge            = PRODUCTION DEPLOYED
Installment RPC Lifecycle             = PRODUCTION DEPLOYED
Installment RLS                       = PRODUCTION DEPLOYED
Installment Audit                     = PRODUCTION DEPLOYED
Installment Realtime                  = PRODUCTION DEPLOYED
Installment Edge Capability           = PRODUCTION DEPLOYED
Installment Production Transaction    = VERIFIED (transactional + rollback)
Installment Cancel Before Payment     = VERIFIED (transactional + rollback)
Installment Paid-Cancel E2E            = NOT INDEPENDENTLY VERIFIED
Master UI Installment Tab              = OWNER SURGERY REQUIRED
Browser E2E                            = OPEN
```

**القرار التنفيذي:**

`Installment Production Backend = CLOSED`

`Installment Master UI + Browser E2E = OPEN`

ولا يجوز تحويل حالة Backend المغلقة إلى Browser E2E closure بالاستنتاج.

---

# 18. إرشادات المساعد التالي — كيف يبدأ ويصل للحقيقة

ابدأ دائمًا بهذا التسلسل، ولا تبدأ من أي تقرير قديم:

```text
CURRENT GIT HEAD
↓
DIRECT PARENT
↓
CURRENT MASTER SOURCE
↓
CURRENT DATABASE SCHEMA
↓
CURRENT FUNCTION DEFINITIONS
↓
CURRENT EDGE DEPLOYMENT
↓
CURRENT REALTIME PUBLICATION
↓
CURRENT RLS / TRIGGERS / CONSTRAINTS
↓
CURRENT RUNTIME / BROWSER
↓
HISTORICAL CONTRACT — للاستدلال فقط
↓
TARGET CONTRACT
↓
ACTUAL GAP
↓
ONE SURGICAL CLOSURE UNIT
↓
TEST
↓
DEPLOY
↓
PRODUCTION VERIFY
↓
RUNTIME VERIFY
↓
DOCUMENT
↓
CLOSE
```

قواعد العمل:

1. لا تثق بالتقرير إذا اختلف عن Git/Production.
2. لا تعتبر Commit دليل Deployment.
3. لا تعتبر Deployment دليل Runtime.
4. لا تعيد إصلاح ما ثبت أنه موجود في HEAD الحالي.
5. لا تبنِ قرارًا على `LIMIT 1` عندما تكون الهوية Company-scoped.
6. لا تنشئ Core موازيًا إذا كان Core Production الحالي قابلًا للتمديد.
7. كل مشكلة يجب أن تصبح Closure Unit واضحة، وليس مجموعة إصلاحات غير مترابطة.
8. ملف `erp-frontend/companies/company-1/main.html` هو Source of Truth للنظام الأم.
9. `Current/PWA/main2/*` و`New-main` Historical reference only.
10. أي نسبة أو تقرير يجب أن يسبقه Production snapshot مطابق للحظة القياس.
11. عند وجود Unknown مؤثر لا تُسجل 100% closure.
12. بعد نجاح Backend لا تعلن Browser E2E إلا بعد تشغيل UI الحقيقي.

---

# 19. سجل التنفيذ

تم حفظ التنفيذ في Git عبر:

- `supabase/migrations/20260914000000_installment_lifecycle_gold_closure.sql`
- `Current/Edge_Functions/installments/index.ts`
- هذا التقرير.

ولم يتم حذف أي تقرير سابق.

