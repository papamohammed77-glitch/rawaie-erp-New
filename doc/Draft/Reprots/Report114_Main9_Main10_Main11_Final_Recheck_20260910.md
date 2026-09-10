# تقرير التنفيذ والمطابقة — Report114
## RAWAEA ERP — إعادة الفحص الجراحية النهائية لـ Main9 / Main10 / Main11
### التاريخ: 2026-09-10

## 1. المرجعية الحاكمة
تم فتح MASTER التنفيذي الحالي وإعادة العمل وفق هرم الحقيقة فيه: الواقع الحالي المتحقق ثم Production ثم عقود قاعدة البيانات والنشر ثم Git والمصدر، مع اعتبار التقارير التاريخية أدلة لا مصدر حقيقة.

قاعدة التنفيذ المستمرة هي: Closure Unit واحدة في كل مرة، ثم فهم → تتبع → جراحة → Syntax → Production Verification → توثيق → إغلاق.

قاعدة Owner Source Surgery تمنع التعديل المباشر على `Current/PWA/main2/main1.md ... main11.md` في هذه الدورة؛ لذلك لم يتم الادعاء بتنفيذ جراحة على Owner Source من خلال التقرير فقط.

## 2. آخر واقع Production — قياس مباشر
تم تحديث القياس المباشر من Supabase في:
`2026-09-10 10:22:45.903 UTC`

النتيجة الحالية:
- companies = 1
- branches = 2
- users = 24
- items = 17
- customers = 3
- orders = 0
- runsheets = 0
- purchase_orders = 0
- stock_vouchers = 0
- stock_branches = 20
- inventory_log = 3
- receiving = 0
- journal_entries = 2
- audit_log = 1869

لا يوجد تغيير في أعداد البيانات يبرر استنتاجًا مخالفًا للحالة السابقة.

## 3. آخر Git Truth
آخر HEAD تحققناه مباشرة هو:
`54235973924c95dd20a058e5de034f10a364c430`

وقت الـcommit:
`2026-09-10 10:10:56 UTC`

هذا الـcommit عدّل `Current/PWA/main2/main9.md` بعد Report113، وحذف `DirectReturn` من فلتر تقرير المرتجعات، فأصبح الفلتر الحالي:
`SalesReturn + Return`.

لذلك Report113 لم يعد يمثل Main9 الحالي، ويجب عدم اعتماد قوله القديم بأن المشكلة هي `SalesReturn + DirectReturn + Return` دون إعادة مطابقة المصدر الحالي.

Current Main9 blob:
`4786e11f64448919bd694c2647dcab1c77f0e6e5`
الحجم الحالي: `161623` bytes.

## 4. Main9 — الحالة الحالية
Main9 يحتوي الإصلاحات التاريخية الخاصة بـ company context وProduction reporting، ولم تتم إعادة تطبيقها أعمى.

### العنصر المعيب
داخل:
`else if (reportId === 'logistics-returns')`

الاستعلام الحالي `r25` يحتوي:
```javascript
.in(
    'movement_type',
    [
        'SalesReturn',
        'Return'
    ]
)
```

### سبب الرفض
العقد الحالي المثبت في `CURRENT_STATE.md` وProduction يدعم `SalesReturn` و`DirectReturn` فقط ضمن semantics المرتجعات المثبتة. `Return` ليس movement type مدعومًا مثبتًا في العقد الحالي.

### البديل الكامل الجاهز
```javascript
var r25 =
    await supabase
        .from('inventory_log')
        .select(
            'movement_date, movement_type, qty, item_code, item_name, reference, voucher_id'
        )
        .eq(
            'company_id',
            companyId
        )
        .in(
            'movement_type',
            [
                'SalesReturn',
                'DirectReturn'
            ]
        )
        .gte(
            'movement_date',
            fromDate
        )
        .lte(
            'movement_date',
            toDate
        )
        .order(
            'movement_date',
            { ascending: false }
        );
```

### موضع الاستبدال
في `Current/PWA/main2/main9.md` داخل فرع `logistics-returns`، استبدل كتلة `var r25 = ...` الحالية بالكامل حتى نهاية استدعاء `.order(...)` مباشرة، واترك بقية المسار كما هي.

### Syntax
تم التحقق من صيغة البديل الجراحي نفسها بواسطة `node --check` سابقًا وكانت النتيجة `PASS`.
أما `Main9` كاملًا بعد التطبيق في Owner Source فلم نعلن له PASS بعد؛ لأن الجراحة لم تُطبق في المصدر المالك، كما أن Workflow الحالي لم يقدم PASS ناجحًا بعد آخر تغيير.

## 5. Main10 — الحالة الحالية
`Current/PWA/main2/main10.md` تم فحصه من البداية للنهاية.

الإصلاح الحالي لـ `_loadLicenseData()` يستخدم أولًا:
`RW_STATE.app.company.id`
ثم fallbacks التوافقية، ثم يقرأ `app_settings` باستخدام:
`.eq('company_id', companyId)`.

لم يظهر عيب جديد مثبت يستوجب Surgical Replacement.

**الحالة: Main10 = CURRENT / NO NEW SURGERY.**

## 6. Main11 — الحالة الحالية
`RW_HR.render()` في `Current/PWA/main2/main11.md` يقرأ حاليًا:
```javascript
var res = await supabase.from('users').select('*');
```

وهذا غير مقيد بـ`company_id`، مع أن Main2 يثبت company context الحالي في:
`RW_STATE.app.company.id`
وProduction تحتوي `users.company_id`.

### العنصر المعيب
الدالة كاملة:
`async function render()` داخل `RW_HR`.

### سبب الرفض
القراءة غير المقيدة تسمح نظريًا بعرض مستخدمي شركة خارج سياق الشركة الحالية، وهو Tenant Isolation defect مباشر في المصدر الحالي.

### البديل الكامل الجاهز
```javascript
async function render() {
    var container = byId('rw-page-container');
    if (!container) return;
    safeText(byId('rw-header-title'), 'الموارد البشرية');
    safeText(byId('rw-header-subtitle'), 'إدارة ملفات الموظفين والرواتب والمستندات');

    var companyId = _rwCompanyId();
    if (!companyId) {
        showToast('سياق الشركة غير محدد', 'error');
        return;
    }

    showLoader('جاري تحميل بيانات الموظفين...');
    var res = await supabase
        .from('users')
        .select('*')
        .eq('company_id', companyId);
    hrData = res.data || [];
    hideLoader();

    if (hrData.length === 0) {
        safeHTML(container, '<div class="text-center py-10 text-gray-500">لا يوجد موظفون.</div>');
        return;
    }

    var html = '<div class="p-4"><div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" id="hr-cards-container">';
    for (var i = 0; i < hrData.length; i++) {
        var emp = hrData[i];
        if (emp.role === 'مالك' || emp.role === 'Owner' || emp.is_owner === true) continue;

        var statusClass = emp.status === 'Active' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700';
        var statusText = emp.status === 'Active' ? 'نشط' : 'غير نشط';
        var initials = (emp.name || '؟').charAt(0);
        var avatarColor = 'bg-blue-500';
        if (emp.role === 'مدير') avatarColor = 'bg-indigo-500';
        else if (emp.role === 'محاسب') avatarColor = 'bg-emerald-500';
        else if (emp.role === 'مندوب' || emp.role === 'سائق') avatarColor = 'bg-amber-500';
        else if (emp.role === 'مخزني') avatarColor = 'bg-purple-500';

        html += '<div class="bg-white rounded-2xl shadow-sm border p-6 hover:shadow-md transition cursor-pointer" onclick="RW_HR._openModal(\\'' + _esc(emp.email) + '\\')">';
        html += '<div class="flex items-center gap-4 mb-4">';
        html += '<div class="w-16 h-16 ' + avatarColor + ' rounded-2xl flex items-center justify-center text-white text-2xl font-black">' + _esc(initials) + '</div>';
        html += '<div>';
        html += '<h3 class="font-black text-lg text-gray-800">' + _esc(emp.name) + '</h3>';
        html += '<p class="text-sm text-gray-500">' + _esc(emp.role) + '</p>';
        html += '</div></div>';
        html += '<div class="space-y-2 text-sm">';
        html += '<div class="flex justify-between"><span class="text-gray-500">البريد:</span><span class="font-bold text-gray-700">' + _esc(emp.email) + '</span></div>';
        html += '<div class="flex justify-between"><span class="text-gray-500">الهاتف:</span><span class="font-bold text-gray-700">' + _esc(emp.phone || '-') + '</span></div>';
        html += '<div class="flex justify-between items-center"><span class="text-gray-500">الحالة:</span><span class="px-2 py-0.5 rounded-full text-xs font-bold ' + statusClass + '">' + statusText + '</span></div>';
        html += '</div></div>';
    }
    html += '</div></div>';

    safeHTML(container, html);
}
```

### موضع الاستبدال
استبدل `async function render()` الحالية داخل `var RW_HR = (function() { ... })();` كاملةً حتى القوس `}` الخاص بها مباشرة قبل:
`function _openModal(email) {`

### Syntax
تم التحقق من صيغة البديل الجراحي نفسها بواسطة `node --check` وكانت النتيجة `PASS`.
لم يتم إعلان Main11 كاملًا PASS أو Closed لأن Owner Source لم يُعدّل بعد.

## 7. Main2 — المطابقة الحالية
تم فتح `Current/PWA/main2/main2.md` ومراجعة company helper الحالي:
```javascript
function _rwCompanyId() {
    return window.RW_STATE && RW_STATE.app && RW_STATE.app.company && RW_STATE.app.company.id ? RW_STATE.app.company.id : null;
}
```

هذا يثبت أن البديل المقترح لـMain11 يستخدم نفس Parent contract، وليس Company ID مخمّنًا أو مأخوذًا من `app_settings LIMIT 1`.

Main2 Assembly لم يُنفذ لأن مصادر Owner ما زالت تحتوي الجراحتين أعلاه ولأن شروط الـMASTER لم تتحقق بعد.

## 8. Syntax / CI / Runtime
Workflow الحوكمي الحالي يفحص Main9 وMain10 فقط، ولا يجوز استخدامه لإثبات Main11.

كما أن آخر Browser Verify على HEAD `542359...` فشل في خطوة `Immutable audited target` قبل بوابة Chromium بسبب عدم تطابق hash لـ`Current/PWA/New-main` مع القيمة audited المتوقعة. هذا فشل في Assembly/Target integrity، وليس دليلًا على أن Main9 نفسه به Syntax Error.

لذلك:
- Main9 full-file Syntax PASS = غير مثبت بعد آخر source state.
- Main10 full-file Syntax PASS = غير مثبت بعد آخر source state.
- Main11 full-file Syntax PASS = غير مثبت بعد آخر source state.
- Replacement Syntax = PASS.
- Main2 Assembly = BLOCKED.
- Browser/PWA smoke = BLOCKED.

## 9. SELF-AUDIT
### ما تم إثباته
- MASTER أعيد فتحه كمصدر حاكم.
- Report113 وExecution Log أعيد فتحهما، ثم تمت إعادة مطابقة المصدر الحالي.
- Production أُعيد قياسها مباشرة في 2026-09-10 10:22:45.903 UTC.
- آخر Git HEAD الحالي تم تحديده وهو أحدث من Report113.
- Main9 الحالي أُعيد فتحه والمشكلة الحالية الدقيقة تم تحديدها.
- Main10 الحالي أُعيد فتحه ولم يُكتشف عيب جديد مثبت.
- Main11 الحالي أُعيد فتحه وثُبتت مشكلة Tenant.
- Main2 الحالي أُعيد فتحه وثبت company helper.
- البدائل الجراحية تم التحقق من Syntax لها.

### ما لم يتم إثباته
- تطبيق Main9 surgery في Owner Source.
- تطبيق Main11 surgery في Owner Source.
- Full-file Syntax PASS بعد التطبيق.
- Main2 Assembly PASS.
- Browser/PWA smoke PASS.
- Production UI report smoke PASS.
- Gold/Diamond Closure = 100%.

## 10. الحكم النهائي
**لا، لم نصل إلى Closed 100%.**

وليس صحيحًا أن الباقي مجرد ضم الأجزاء الـ11 في ملف واحد.

الحالة الدقيقة هي:

- Inventory Physical Core = VERIFIED / Physical Writers خارج `post_stock_movement` = 0.
- Main9 = OPEN / Surgical replacement required.
- Main10 = CURRENT / No new surgery.
- Main11 = OPEN / Tenant surgical replacement required.
- Main9/Main10/Main11 full-file syntax after source application = NOT PROVEN.
- Main2 Assembly = BLOCKED.
- Gold/Diamond = NOT CLOSED.

### الخطوة التالية المسموح بها طبقًا للـMASTER
تطبيق جراحة Main9 أولًا، ثم إعادة قراءة Main9 حتى EOF + Syntax + تحقق، ثم إغلاقها رسميًا. بعد ذلك فتح Closure Unit Main11 وتطبيق جراحتها بنفس المنهج، ثم إعادة قراءة Main11 + Syntax + تحقق، ثم مطابقة Main2 كاملًا، وبعدها فقط Assembly وBrowser/PWA verification.
