# Report413 — مزامنة أوردرات المبيعات مع الحالة النهائية + قيد مصادر الرانشيت
**التاريخ:** 2026-10-11  
**النطاق:** تبويب أوردرات المبيعات في النظام الأم، مع إصلاح عقد ضم الأوردرات إلى الرانشيت في Production.  
**المستودعات:** `papamohammed77-glitch/rawaie-erp-New` و`papamohammed77-glitch/erp-frontend`  
**Supabase Production:** `fiilmooggumokxanwiyx`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** النظام الأم يجب أن يعرض مصدر الأوردر ومنشئه ووقت الإنشاء، وعدد الأصناف التي ما زالت لها كمية متبقية، وحالة الأوردر النهائية بعد المرتجع. ولا يجوز ضم أوردرات POS/الكاشير إلى الرانشيت؛ POS يسجل البيع وحركة المخزون مباشرة، بينما الرانشيت مسار تنفيذ ميداني للأوردرات المؤهلة.
- **Architecture Understanding:** `main.html` وملفات التطبيقات التشغيلية ملفات يطبق المالك تعديلات الواجهة عليها. تم تعديل Production مباشرة فقط في Core RPCs القائمة، بلا إنشاء Edge Function جديدة. التعديل الأمامي أدناه Owner Surgical Patch.
- **Database Understanding:** Production يحتوي `orders.source`, `created_by`, `created_at`, `total_amount`, `original_total_amount` و`order_details.qty`, `qty_returned`, `line_amount`. جدول `users` يحتوي `email` و`name` و`company_id`.
- **Historical Understanding:** تمت قراءة `CURRENT_STATE.md` وتقارير Report408 وReport411 وReport412، ثم إعادة التحقق من Production في هذه الدورة. التقارير السابقة استرشادية ولا تثبت الحالة الحالية.
- **Production Understanding:** الاستعلام الحي عند `2026-10-11 15:22:09.969729+00` أثبت أن `ORD-1006` = `Partially Returned`, المصدر `pos`, المنشئ `cashier@rawaea.com`, وقت الإنشاء `2026-10-11 07:31:00.768458+00`, الإجمالي الحالي 135.00 والأصلي 185.00، صفا تفاصيل، الكمية الأصلية 2 والمرتجعة 1 والمتبقية 1، و`runsheet_id=NULL`.
- **Current Understanding:** Snapshot `rawaie-erp-New/Current/PWA/main.html` blob `27b777528665dcc985809648f006452c861ae36e` يثبت أن عدّ التفاصيل لا يستبعد المرتجع، وRealtime يحدّث رأس الأوردر فقط، والجدول لا يعرض المصدر/المنشئ/وقت الإنشاء، ومربع الاختيار لا يقيد المصدر. ملف `erp-frontend/companies/company-1/main.html` أعاد SHA `4f94f9c6ebdde1b59632384628c72767d3bb950d` لكن محتوى الملف الحي لم يرجع عبر الموصل؛ لذلك لا أدّعي تطابقه مع Snapshot.
- **Execution Confidence:** مرتفع في Production Core والحقول؛ متوسط في تشخيص Snapshot؛ غير مثبت في انطباق patch على الملف الأم الحي أو نشره واختباره من المتصفح.

## 1. Production: defect مثبت وإصلاح مطبق

### السبب الجذري
الـRPCs الموجودتان `public.create_runsheet_atomic` و`public.append_orders_to_runsheet_atomic` كانتا تتحققان من الشركة والحالة وعدم ارتباط الأوردر برانشيت، لكنهما لا تتحققان من `orders.source`. هذا يسمح لمسار RPC أن يقبل مصدرًا غير مؤهل إذا تجاوز المستخدم واجهة النظام الأم. Edge الحالي `create-runsheet v26` و`append-to-runsheet v8` يستدعيان هاتين الدالتين باستخدام `service_role`؛ لذا مكان الضمان المركزي الصحيح هو الـRPCs الحالية وليس Edge جديدة.
### ما تم تنفيذه
- أُنشئ ملف Migration: `supabase/migrations/20261011153000_enforce_runsheet_source_eligibility.sql`.
- Commit ملف Migration: `c955ad6c5f60f3c9ba2f14f0fb74e07d691d3574`.
- طُبقت Migration على Production بنجاح؛ سجل Supabase أعاد `success=true`. رقم النسخة المسجل: `20261011152539` والاسم `20261011153000_enforce_runsheet_source_eligibility`.
- التعديل يضيف حارس المصدر إلى الدالتين الموجودتين، مع تطبيع المسافات والشرطة السفلية إلى شرطة عادية. المصادر المقبولة: `telesales`, `tele-sales`, `order-taker`, `online-store`. يظل `pos` وأي مصدر فارغ/غير معروف غير مؤهل.
- تمت إعادة قراءة تعريفات Production بعد النشر: الحارس موجود في الدالتين. ظلت ACL كما هي: `anon=false`, `authenticated=false`, `service_role=true`; وظلت الدالتان `SECURITY DEFINER` مع `search_path=public`.
- Production حاليًا لا يحتوي أوردرات مرتبطة برانشيت من مصدر POS؛ الاستعلام الحي أظهر أن الأوردرات المرتبطة الحالية مصدرها `order-taker` فقط.
- لم تتغير بيانات أعمال أو مخزون أو قيود محاسبية، ولم يُنشأ أي fixture. محاولة اختبار Runtime سلبية عبر كتلة SQL محكومة رُفضت من طبقة أمان الأداة؛ لذلك لا أدّعي HTTP E2E أو تنفيذ Mutation اختبارية. تحقق النشر هنا مبني على Migration success + تعريفات الدوال وACL بعد النشر.

## 2. Loss / Gain / Responsibility Matrix

| الوظيفة | النتيجة |
|---|---|
| حفظ الأوردر الأصلي وسطور المرتجع للتدقيق | RETAINED |
| قراءة المصدر والمنشئ ووقت الإنشاء | OWNER PATCH REQUIRED |
| عدّ أسطر الأصناف ذات كمية متبقية فقط | OWNER PATCH REQUIRED |
| تحديث مشتقات الجدول بعد Realtime | OWNER PATCH REQUIRED |
| منع POS/المصادر المجهولة من إنشاء/ضم رانشيت | HARDENED IN PRODUCTION CORE |
| Company Isolation في الـRPCs | RETAINED؛ التحقق قائم على `company_id` |
| إضافة Edge Function | INTENTIONALLY NOT ADDED |
| تعديل `main.html` أو POS من المساعد | INTENTIONALLY NOT DONE حسب سياسة المالك |

## 3. Owner Surgical Patch — لا تعدّل الملف الأم من المساعد

**الملف:** `erp-frontend/companies/company-1/main.html`  
**الموضع:** الوحدة `RW_Orders`.  
**شرط التنفيذ:** افتح النص الحي وتحقق من SHA وتوقيع كل عنصر قبل الاستبدال. لا تنقل Snapshot كاملًا ولا تستبدل دالة لا تطابقه.

### A. أضف helper واحدًا
ابحث داخل `RW_Orders` عن:

```javascript
var ordersData = [];
```

أضف بعده مباشرة:

```javascript
function _normalizeOrderSource(source) {
    return String(source || '').trim().toLowerCase().replace(/[ _]+/g, '-');
}

function _runsheetSourceEligible(source) {
    return ['telesales', 'tele-sales', 'order-taker', 'online-store']
        .indexOf(_normalizeOrderSource(source)) !== -1;
}

function _canAddOrderToRunsheet(order) {
    return !!order &&
        !order.runsheet_id &&
        ['Confirmed', 'Pending'].indexOf(order.order_status) !== -1 &&
        _runsheetSourceEligible(order.source);
}
```

### B. استبدل `async function loadData()` كاملة
ابحث داخل `RW_Orders` عن `async function loadData()` واستبدل الدالة كاملة:

```javascript
async function loadData() {
    var companyId = getCompanyId();
    var ordersRes = await sb.from('orders')
        .select('*, runsheets(runsheet_code)')
        .eq('company_id', companyId)
        .order('order_date', { ascending: false })
        .order('order_code', { ascending: true });
    if (ordersRes.error) throw ordersRes.error;

    var rows = ordersRes.data || [];
    if (!rows.length) return [];

    var orderIds = rows.map(function (o) { return o.id; }).filter(Boolean);
    var detailsRes = await sb.from('order_details')
        .select('order_id, item_code, qty, qty_returned')
        .in('order_id', orderIds);
    if (detailsRes.error) throw detailsRes.error;

    var counts = {};
    (detailsRes.data || []).forEach(function (d) {
        if (!d.order_id) return;
        var qty = Math.max(0, Number(d.qty) || 0);
        var returned = Math.min(qty, Math.max(0, Number(d.qty_returned) || 0));
        if (qty - returned > 0) {
            counts[d.order_id] = (counts[d.order_id] || 0) + 1;
        }
    });

    var creatorNames = {};
    var usersRes = await sb.from('users')
        .select('email,name')
        .eq('company_id', companyId);
    if (!usersRes.error) {
        (usersRes.data || []).forEach(function (u) {
            if (u.email) creatorNames[String(u.email).trim().toLowerCase()] = u.name || u.email;
        });
    } else {
        console.warn('Creator names unavailable; showing created_by identifier:', usersRes.error);
    }

    return rows.map(function (o) {
        o.itemsCount = counts[o.id] || 0;
        o._runsheetCode = o.runsheets && o.runsheets.runsheet_code
            ? o.runsheets.runsheet_code
            : null;
        var creatorKey = String(o.created_by || '').trim().toLowerCase();
        o.creatorName = creatorNames[creatorKey] || o.created_by || 'غير محدد';
        return o;
    });
}
```

إذا تعذر على الجلسة قراءة `users` بسبب RLS، تبقى القائمة عاملة ويظهر `created_by` بدل الاسم؛ لا تجعل تعذر الاسم يفشل تحميل الأوردرات.

### C. أصلح Realtime
ابحث داخل `RW_Orders` عن `async function refreshRealtimeChannel()` واستبدل الدالة كاملة:

```javascript
async function refreshRealtimeChannel() {
    if (ordersRealtimeChannel) {
        try { await sb.removeChannel(ordersRealtimeChannel); }
        catch (e) { console.warn(e); }
        ordersRealtimeChannel = null;
    }

    var companyId = getCompanyId();
    ordersRealtimeChannel = sb.channel('orders-realtime-' + companyId)
        .on('postgres_changes', {
            event: '*',
            schema: 'public',
            table: 'orders',
            filter: 'company_id=eq.' + companyId
        }, function () {
            _refreshData().catch(function (e) {
                console.warn('Orders/return realtime refresh failed:', e);
            });
        })
        .subscribe();
}
```

هذا يعيد تحميل رأس الأوردر والتفاصيل المشتقة ضمن الشركة الحالية بدل تحديث رأس الأوردر في الذاكرة فقط.

### D. حدّث رأس الجدول وعمود التاريخ
داخل `RW_Orders.render()` ابحث عن رأس عمود التاريخ:

```javascript
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\\'order_date\\')">التاريخ <i class="fa-solid fa-sort"></i></th>' +
```

استبدله بـ:

```javascript
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\\'created_at\\')">تاريخ ووقت الإنشاء <i class="fa-solid fa-sort"></i></th>' +
```

وابحث في رأس الجدول عن عمود `العميل والمنطقة` ثم أضف بعده مباشرة:

```javascript
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\\'source\\')">المصدر <i class="fa-solid fa-sort"></i></th>' +
'<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\\'creatorName\\')">المنشئ <i class="fa-solid fa-sort"></i></th>' +
```

في رأس خانة تحديد الكل داخل `RW_Orders.render()`، غيّر المحدد فقط من:

```javascript
document.querySelectorAll('.order-checkbox')
```

إلى:

```javascript
document.querySelectorAll('.order-checkbox:not(:disabled)')
```

لا تنفذ هذا الاستبدال على مستوى الملف كله؛ داخل محدد `id="check-all"` في `RW_Orders.render()` فقط.

### E. استبدل `function _renderTable(rows)` كاملة
```javascript
function _renderTable(rows) {
    var tbody = byLocalId('orders-table-body');
    if (!tbody) return;

    if (!rows || !rows.length) {
        safeHTML(tbody, '<tr><td colspan="11" class="text-center py-8 text-gray-500">لا توجد أوردرات</td></tr>');
        var pc = byLocalId('orders-table-body-controls');
        if (pc) safeHTML(pc, '');
        return;
    }

    var checkAll = byLocalId('check-all');
    if (checkAll) checkAll.checked = false;

    RW_Table.paginate('orders-table-body', rows, 1, 50, function (o) {
        var actions = '';
        if (o.order_status === 'Draft' || o.order_status === 'Pending') {
            actions += '<button onclick="event.stopPropagation();RW_Orders._confirm(\'' + escAttr(o.order_code) + '\')" class="text-green-600 mx-1" title="تأكيد"><i class="fa-solid fa-check-circle"></i></button>';
        }
        var canDelete = ['Draft', 'Confirmed', 'Pending'].indexOf(o.order_status) !== -1 && !o.runsheet_id;
        if (canDelete) {
            actions += '<button onclick="event.stopPropagation();RW_Orders._delete(\'' + escAttr(o.order_code) + '\')" class="text-red-500 mx-1" title="حذف"><i class="fa-solid fa-trash-can"></i></button>';
        }

        var eligible = _canAddOrderToRunsheet(o);
        var checkbox = eligible
            ? '<input type="checkbox" class="order-checkbox" data-id="' + escAttr(o.order_code) + '" aria-label="اختيار ' + escAttr(o.order_code) + ' للرانشيت">'
            : '<input type="checkbox" class="order-checkbox" data-id="' + escAttr(o.order_code) + '" disabled title="المصدر أو الحالة لا يسمحان بإدخال الأوردر في رانشيت">';
        var sourceRaw = String(o.source || '').trim();
        var sourceKey = _normalizeOrderSource(sourceRaw);
        var sourceLabels = {
            'pos': 'كاشير',
            'telesales': 'تلي سيلز',
            'tele-sales': 'تلي سيلز',
            'order-taker': 'أوردر تيكر',
            'online-store': 'المتجر الإلكتروني'
        };
        var sourceLabel = sourceLabels[sourceKey] || sourceRaw || 'غير محدد';
        var creatorLabel = String(o.creatorName || o.created_by || '').trim() || 'غير محدد';
        var createdAtLabel = o.created_at
            ? new Date(o.created_at).toLocaleString('ar-EG', {
                year: 'numeric', month: '2-digit', day: '2-digit',
                hour: '2-digit', minute: '2-digit', hour12: false
              })
            : (o.order_date ? formatDate(o.order_date) + ' — وقت الإنشاء غير متاح' : '—');

        return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Orders._showDetails(\'' + escAttr(o.order_code) + '\')">' +
            '<td class="p-3 text-center" onclick="event.stopPropagation()">' + checkbox + '</td>' +
            '<td class="p-3 text-center font-bold text-blue-600">' + esc(o.order_code) + '</td>' +
            '<td class="p-3 text-center whitespace-nowrap">' + esc(createdAtLabel) + '</td>' +
            '<td class="p-3 text-center"><p class="font-semibold">' + esc(o.customer_name || '—') + '</p><p class="text-xs text-gray-500">' + esc(o.area || '') + '</p></td>' +
            '<td class="p-3 text-center"><span class="inline-flex px-2 py-1 rounded bg-slate-50 text-slate-700 text-xs" title="' + escAttr(sourceRaw) + '">' + esc(sourceLabel) + '</span></td>' +
            '<td class="p-3 text-center text-xs break-all" title="' + escAttr(o.created_by || '') + '">' + esc(creatorLabel) + '</td>' +
            '<td class="p-3 text-center font-bold">' + formatNumber(o.itemsCount) + '</td>' +
            '<td class="p-3 text-center font-bold">' + formatNumber(o.total_amount) + ' EGP</td>' +
            '<td class="p-3 text-center"><span class="px-2 py-1 rounded-full text-xs font-semibold ' + statusClassOrder(o.order_status) + '">' + esc(o.order_status) + '</span></td>' +
            '<td class="p-3 text-center">' + esc(o._runsheetCode || '---') + '</td>' +
            '<td class="p-3 text-center">' + actions + '</td>' +
        '</tr>';
    });
}
```

بعد إضافة العمودين أصبح عدد الأعمدة 11. غيّر `colspan="9"` إلى `colspan="11"` في صفّي التحميل والخطأ داخل `RW_Orders.render()` فقط، بالإضافة إلى حالة الجدول الفارغ التي يغطيها البديل أعلاه.

### F. امنع التجاوز من أزرار إنشاء/ضم الرانشيت
ابحث داخل `RW_Orders` عن `function _validateSelected(selected)` واستبدلها كاملة:

```javascript
function _validateSelected(selected) {
    var companyId = getCompanyId();
    if (!selected || !selected.length) throw new Error('اختر أوردرًا واحدًا على الأقل');

    var rows = [];
    selected.forEach(function (code) {
        var found = ordersData.find(function (o) {
            return o.order_code === code && o.company_id === companyId;
        });
        if (!found) throw new Error('أحد الأوردرات المحددة غير موجود في سياق الشركة الحالي');
        if (!_runsheetSourceEligible(found.source)) {
            throw new Error('المصدر "' + (found.source || 'غير محدد') + '" غير مؤهل للرانشيت: ' + code);
        }
        if (found.runsheet_id) throw new Error('الأوردر ' + code + ' مرتبط بالفعل برانشيت');
        if (['Confirmed', 'Pending'].indexOf(found.order_status) === -1) {
            throw new Error('الأوردر ' + code + ' لا يمكن إدخاله في رانشيت في حالته الحالية: ' + found.order_status);
        }
        rows.push(found);
    });
    return rows;
}
```

الضمان المركزي Production صار يرفض المصادر غير المؤهلة كذلك، لذلك التحقق الأمامي لتحسين التجربة وليس حاجز الأمان الوحيد.

### G. تفاصيل المرتجع
استبدل `async function _showDetails(code)` بالنسخة الكاملة الواردة في Report408، القسم `OWNER CHANGESET`. النسخة تعرض الكمية الأصلية والمرتجعة والمتبقية، قيمة المتبقي، سبب المرتجع، وعدد السطور المتبقية، وتأخذ الإجمالي النهائي من `orders.total_amount`. لا تعِد بناء هذه الدالة من الذاكرة ولا تغيّر سطور البيع الأصلية.

## 4. الاختبار المطلوب بعد تطبيق المالك للتعديل الأمامي

1. `ORD-1006` قراءة فقط: المصدر «كاشير»، المنشئ «كاشير» مع بقاء البريد `cashier@rawaea.com` متاحًا كتلميح، وقت الإنشاء ظاهر، عدد الأصناف المتبقية = 1، الحالة `Partially Returned`، الإجمالي النهائي 135.00 EGP.
2. الأوردرات `pos` لا يمكن تحديدها ولا إنشاء/ضم رانشيت بها؛ وكذلك المصدر الفارغ أو غير المعروف.
3. `order-taker` في حالة `Confirmed/Pending` وغير مرتبط برانشيت يجب أن يكون قابلًا للتحديد. اختبر `telesales` و`online-store` إذا وُجدت بياناتها في بيئة اختبار.
4. تحديد الكل يحدد العناصر المفعّلة فقط.
5. بعد تغيير مرتجع على fixture معزول، يجب أن يعاد حساب عدد الأصناف من التفاصيل وتحديث الجدول عبر Realtime دون إعادة تحميل يدوي.
6. تفاصيل الأوردر: الأصلي/المرتجع/المتبقي لكل سطر، والإجمالي النهائي من رأس الأوردر.
7. اختبر الطباعة بشكل منفصل قبل إعلان تكامل كامل؛ Snapshot الطباعة الحالي ما زال يعرض الكميات وقيمة السطور الأصلية، ولم يتغير في هذه الدورة.
8. تحقق من المصدر الحي المنشور وService Worker وConsole/Network. لا يُعد Git snapshot إثباتًا على النشر.

## 5. Production Verification / Baseline

- Migration file committed: `c955ad6c5f60f3c9ba2f14f0fb74e07d691d3574`.
- Migration recorded in Production as version `20261011152539`.
- Both atomic RPC definitions were re-read after deploy; source guard is present in each.
- ACL preserved: no EXECUTE for `anon/authenticated`, EXECUTE for `service_role`.
- Baseline `ORD-1006` re-read after deploy: still `Partially Returned`, `source=pos`, `runsheet_id=NULL`, total 135.00, original 185.00, detail rows 2, original qty 2, returned qty 1, remaining qty 1.
- No Production business rows were created/modified for testing. The tool security layer refused the attempted guarded SQL runtime test; do not claim a live HTTP E2E pass.
- No Edge Function was added or deployed. Existing Edge functions continue calling the now-hardened RPCs.

## SELF-AUDIT FINAL

- **What I Proved:** Production schema supports the required fields; `ORD-1006` reflects the final return state; `users.name` resolves `cashier@rawaea.com` to «كاشير»; existing run-sheet RPCs lacked source eligibility; the source guard is deployed in both current RPCs with the prior ACL preserved.
- **What I Did Not Prove:** The live main.html source text, that the owner patch was applied, hosted artifact parity, browser/HTTP E2E, or print consistency.
- **What I Fixed:** Production source eligibility in `create_runsheet_atomic` and `append_orders_to_runsheet_atomic`, through a recorded migration. No business data was changed.
- **What I Initially Missed:** Source eligibility must be enforced at the central RPC layer because both existing Edge Functions use `service_role`; a UI checkbox alone is bypassable.
- **What Could Still Be Wrong:** The live main.html may differ from the snapshot; user-table read permission may cause creator names to fall back to email; frontend and print patches remain unapplied/unverified.
- **Final Confidence:** High for deployed DB contract/ACL; medium for snapshot-based UI diagnosis; unverified for frontend deployment and browser E2E.
- **Final Closure Status:** `PRODUCTION CORE SOURCE GUARD DEPLOYED / OWNER UI PATCH SPECIFIED / LIVE MAIN SOURCE PARITY UNVERIFIED / FRONTEND DEPLOYMENT + BROWSER E2E + PRINT OPEN / NOT CLOSED`.

## تعليمات الاستئناف
1. أعد قراءة Production و`CURRENT_STATE.md` في بداية الجلسة؛ لا تعتمد على هذا التقرير كحقيقة لحظية.
2. اطلب من المالك فتح `erp-frontend/companies/company-1/main.html` ومطابقة النص الحي قبل أي استبدال.
3. طبّق A–G على العناصر المطابقة فقط، ثم اختبر جدول الأوردرات والتفاصيل وتحديد الرانشيت.
4. افحص الطباعة وتوحيد الحالة النهائية؛ لا تغلق المهمة قبل ذلك.
5. سجّل SHA الفعلي للملف المنشور ونتائج Browser/HTTP E2E في `CURRENT_STATE.md`.
