# Report432 — QR تعريف الخزائن والبنوك داخل النظام الأم
**التاريخ:** 2026-10-16  
**النطاق:** `RW_Finance → الخزائن والبنوك` فقط  
**مصدر النظام الأم:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`  
**قاعدة Production:** `fiilmooggumokxanwiyx`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** المطلوب مودال أوسع وأكثر احترافية، ورمز QR ثابت ومميز لكل خزينة/بنك، قابل لأن يقرأه تطبيق الكاشير لاحقًا لتحديد الخزينة المقصودة. لا يجوز أن يغير إنشاء الرمز أو عرضه أي رصيد أو حركة مالية.
- **Architecture Understanding:** النظام الأم يملك إدارة بيانات الخزائن، أما تطبيق POS فهو مستهلك تشغيلي مستقل. تعليمات المالك تمنع المساعد من تعديل `main.html` أو تطبيق POS؛ لذلك هذا التقرير يسلّم Owner Change Set جراحيًا ولا يغيّر الملفات مباشرة.
- **Database Understanding:** Production يحتوي `public.treasury.id` كـUUID ثابت، و`company_id`، و`branch_id`، و`pos_terminals` و`pos_shifts`. توجد RPCs موثقة لإدارة الخزينة: `finance_list_treasury_branches`, `finance_save_treasury`, `finance_delete_treasury`.
- **Historical Understanding:** Report431 وثّق إصلاح حفظ الخزينة وربطها اختياريًا بالفرع عبر RPC مصادق عليه. هذا التقرير يبني على ذلك ولا يعيد كتابة عقد الحفظ أو يفتح صلاحيات كتابة مباشرة على الجدول.
- **Production Understanding:** فُحصت قاعدة Production مباشرة في هذه الدورة. آخر وقت قراءة SQL المسجل: `2026-10-16 20:32:39.750235+00 UTC`. عدد السجلات وقت الفحص: `treasury=1`, `pos_terminals=1`, `pos_shifts=1`, `cash_box=6`. لم تُنشأ بيانات اختبار ولم تُعدّل بيانات مالية.
- **Current Source Understanding:** آخر commit في مستودع النظام الأم وقت المزامنة: `4bd8958bd4d087346c56c871b29b749b9b1c1384`، وcommit تعديل مودال الخزينة: `cba8e7fc7762c08735e678d09eb0080eb9538129`. ملف `main.html` الحالي blob SHA: `9d02dcc1129e00c033082384562177ce1aa5b80a`، 32,569 سطرًا. هذا هو SHA الذي تنطبق عليه أرقام الأسطر أدناه.
- **Execution Confidence:** مرتفع في صحة مصدر الهوية وبنية QR المقترحة؛ إغلاق واجهة المستخدم وE2E غير مثبتين قبل تطبيق المالك للتعديلات ونشر النظام الأم.

### Confirmed Facts

1. الملف الحالي يحتوي بالفعل على QRCode.js مستخدمًا في موضع آخر، ويحمّله ديناميكيًا من `https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js`. لذلك لا حاجة لإضافة مكتبة أو تحميل دائم جديد.
2. دالة `_openTreasuryDialog()` الحالية تحفظ عبر `finance_save_treasury`، ودالة `_editTreasury(code)` الحالية تستخدم RPCs الآمنة التي وثّقها Report431. يجب الحفاظ على هذا الإصلاح وعدم الرجوع إلى `supabase.from('treasury').insert/update/delete`.
3. `treasury.id` هو هوية ثابتة مناسبة لتعريف الخزينة في QR، مع تضمين `company_id` ونسخة صيغة payload. الرمز ليس سرًا ولا يمثل صلاحية دخول.
4. لا يحتاج إنشاء QR وعرضه إلى عمود جديد أو Migration: يمكن توليد الرمز بصورة حتمية من هوية الخزينة المحفوظة.
5. لم يثبت في هذه المهمة أن تطبيق POS الحالي يقرأ هذا النوع من payload أو ينفذ ربطًا تلقائيًا بعد المسح. لذلك لا ندّعي أن المسح والربط الفعلي قد أصبحا جاهزين بمجرد عرض الرمز؛ ذلك يحتاج Consumer مصادقًا عليه وعقد ربط في POS/Production.

### Production Security / ACL Reconciliation

- `finance_list_treasury_branches(uuid)`, `finance_save_treasury(uuid,uuid,text,text,numeric,uuid)`, و`finance_delete_treasury(uuid,uuid)`: `anon EXECUTE=false`, `authenticated EXECUTE=true`, `service_role EXECUTE=true`.
- صلاحيات `public.treasury` المباشرة لا تمنح `authenticated` عمليات INSERT/UPDATE/DELETE؛ يظل التعديل عبر RPC هو المسار الصحيح.
- لم تُجرَ أي تغييرات DDL أو ACL أو بيانات في Production؛ لا يوجد تغيير قاعدة بيانات مطلوب لعرض QR نفسه.

## OWNER CHANGE SET — لا تعدّل أي ملف آخر

**قبل التطبيق:** أعد جلب `main.html` وتأكد أن blob SHA ما زال `9d02dcc1129e00c033082384562177ce1aa5b80a`. إذا تغيّر، أعد تحديد المقاطع من النسخة الجديدة ولا تعتمد أرقام الأسطر القديمة.

### Change A — استبدال جدول الخزائن لإضافة زر QR مستقل

- **الملف:** `companies/company-1/main.html`
- **الدالة:** `_buildTreasuryTable(data)`
- **الموضع الحالي:** السطر 18067، وتنتهي قبل `function _filterTreasury() {` عند السطر 18076.
- **ابحث عن المحدد الدقيق:** `function _buildTreasuryTable(data) {`
- **احذف الدالة كاملة حتى القوس الختامي الذي يسبق `function _filterTreasury() {`، واستبدلها بالكامل بالنص التالي:**

```javascript
function _buildTreasuryTable(data) {
    if (!data || !data.length) {
        return '<div class="text-center py-8 text-gray-500">لا توجد خزائن أو بنوك بعد</div>';
    }

    var html =
        '<div class="overflow-x-auto rounded-xl border border-gray-200">' +
        '<table class="w-full text-sm border-collapse min-w-[720px]">' +
        '<thead><tr class="bg-gray-50 text-gray-600">' +
        '<th class="p-3 border-b text-right">الكود</th>' +
        '<th class="p-3 border-b text-right">الاسم</th>' +
        '<th class="p-3 border-b text-right">النوع</th>' +
        '<th class="p-3 border-b text-right">الرصيد الحالي</th>' +
        '<th class="p-3 border-b text-center">QR الكاشير</th>' +
        '</tr></thead><tbody>';

    for (var i = 0; i < data.length; i++) {
        var t = data[i];
        html +=
            '<tr class="border-t hover:bg-blue-50/60 transition-colors cursor-pointer" ' +
                'onclick="RW_Finance._editTreasury(\'' + _esc(t.account_code) + '\')">' +
            '<td class="p-3 whitespace-nowrap">' + _esc(t.account_code) + '</td>' +
            '<td class="p-3 font-bold">' + _esc(t.account_name) + '</td>' +
            '<td class="p-3">' +
                (t.type === 'Cash' ? 'خزينة نقدية' : 'بنك') +
            '</td>' +
            '<td class="p-3 font-bold text-blue-700 whitespace-nowrap">' +
                _fmtNum(t.current_balance) +
            '</td>' +
            '<td class="p-2 text-center">' +
                '<button type="button" data-code="' + _esc(t.account_code) + '" ' +
                    'onclick="event.stopPropagation(); RW_Finance._showTreasuryQR(this.dataset.code)" ' +
                    'class="inline-flex items-center gap-2 rounded-lg bg-indigo-50 hover:bg-indigo-100 ' +
                    'text-indigo-700 border border-indigo-200 px-3 py-2 font-bold" ' +
                    'title="عرض رمز QR لهذه الخزينة">' +
                    '<i class="fa-solid fa-qrcode"></i><span>عرض QR</span>' +
                '</button>' +
            '</td></tr>';
    }

    html += '</tbody></table></div>';
    return html;
}
```

**النتيجة:** يبقى النقر على الصف لفتح التعديل كما هو، ويظهر زر QR مستقل لا يفتح مودال التعديل عند الضغط عليه.

### Change B — إضافة دالة عرض QR

- **الملف:** `companies/company-1/main.html`
- **الدالة الجديدة داخل وحدة `RW_Finance`:** `_showTreasuryQR(code, fallbackItem)`
- **الموضع:** أدرج الدالة كاملة مباشرة قبل المحدد الحالي `function _filterTreasury() {` (الموجود حاليًا قرب السطر 18076).
- **لا تضف نسخة ثانية إن كانت الدالة موجودة عند التطبيق؛ ابحث عنها أولًا.**

```javascript
async function _showTreasuryQR(code, fallbackItem) {
    var item = fallbackItem || null;

    if (!item) {
        for (var i = 0; i < _cache.treasury.length; i++) {
            if (_cache.treasury[i].account_code === code || _cache.treasury[i].id === code) {
                item = _cache.treasury[i];
                break;
            }
        }
    }

    if (!item || !item.id) {
        _showToast('تعذر العثور على هوية الخزينة لإنشاء رمز QR', 'error');
        return;
    }

    var companyId;
    try {
        companyId = _companyId();
    } catch (e) {
        _showToast((e && e.message) || 'سياق الشركة غير محدد', 'error');
        return;
    }

    var payload = JSON.stringify({
        type: 'rawaea_treasury',
        version: 1,
        company_id: String(companyId),
        treasury_id: String(item.id)
    });

    try {
        if (typeof QRCode === 'undefined') {
            await new Promise(function (resolve, reject) {
                var existing = document.querySelector('script[data-rawaea-qrcode="1"]');
                if (existing) {
                    existing.addEventListener('load', resolve, { once: true });
                    existing.addEventListener('error', reject, { once: true });
                    return;
                }

                var script = document.createElement('script');
                script.src = 'https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js';
                script.async = true;
                script.dataset.rawaeaQrcode = '1';
                script.onload = resolve;
                script.onerror = function () {
                    reject(new Error('تعذر تحميل مكتبة إنشاء QR'));
                };
                document.head.appendChild(script);
            });
        }

        if (typeof QRCode === 'undefined') {
            throw new Error('مكتبة QR غير متاحة بعد التحميل');
        }

        await Swal.fire({
            title: 'رمز QR — ' + String(item.account_name || 'الخزينة'),
            width: 560,
            html:
                '<div class="text-center space-y-3">' +
                    '<div class="rounded-xl border bg-gray-50 p-4">' +
                        '<div id="treasury-qr-container" class="flex justify-center min-h-[250px] items-center"></div>' +
                    '</div>' +
                    '<div class="text-right rounded-lg bg-blue-50 border border-blue-100 p-3 text-sm">' +
                        '<div><strong>الحساب:</strong> ' + _esc(item.account_name || '') + '</div>' +
                        '<div><strong>الكود:</strong> ' + _esc(item.account_code || '') + '</div>' +
                        '<div><strong>النوع:</strong> ' + (item.type === 'Cash' ? 'خزينة نقدية' : 'بنك') + '</div>' +
                        '<p class="mt-2 text-xs text-gray-600">هذا الرمز يعرّف الخزينة فقط ولا يمنح صلاحية دخول أو تنفيذ مالي. عند مسحه يجب على تطبيق الكاشير التحقق من جلسة المستخدم والشركة وصلاحية الربط من الخادم.</p>' +
                    '</div>' +
                    '<div class="text-xs text-gray-500 break-all">هوية الخزينة: ' + _esc(item.id) + '</div>' +
                '</div>',
            confirmButtonText: 'تم',
            didOpen: function () {
                var container = document.getElementById('treasury-qr-container');
                if (!container) return;
                container.innerHTML = '';
                new QRCode(container, {
                    text: payload,
                    width: 240,
                    height: 240,
                    colorDark: '#111827',
                    colorLight: '#ffffff',
                    correctLevel: QRCode.CorrectLevel.M
                });
            }
        });
    } catch (e) {
        _showToast((e && e.message) || 'تعذر إنشاء رمز QR للخزينة', 'error');
    }
}
```

**عقد الرمز:** JSON versioned payload يحتوي `type=rawaea_treasury` و`company_id` و`treasury_id`. هذه البيانات معرّفات وليست أسرارًا. يجب ألا يعتمد أي Consumer مستقبلي على `company_id` القادم من QR كإثبات صلاحية؛ الخادم يستخرج شركة المستخدم من جلسة المصادقة ويقارنها بالشركة المالكة للخزينة.

### Change C — عرض QR تلقائيًا بعد إنشاء الخزينة

- **الملف:** `companies/company-1/main.html`
- **الدالة:** `_openTreasuryDialog()`
- **SHA المستهدف:** `9d02dcc1129e00c033082384562177ce1aa5b80a`
- **محدد البحث:** داخل كتلة `try` بعد `var saved = await supabase.rpc('finance_save_treasury', {`، ابحث عن المقطع التالي حرفيًا:

```javascript
        if (saved.error) throw saved.error;

        _refreshCache();
        renderSubTab('treasury');
        _showToast('تم حفظ الحساب بنجاح', 'success');
```

- **استبدل المقطع السابق كاملًا بهذا النص:**

```javascript
        if (saved.error) throw saved.error;

        var savedTreasury = Array.isArray(saved.data) ? saved.data[0] : saved.data;
        if (!savedTreasury || !savedTreasury.id || !savedTreasury.account_code) {
            throw new Error('تم الحفظ لكن استجابة الخزينة لا تحتوي الهوية اللازمة لإنشاء QR');
        }

        _refreshCache();
        renderSubTab('treasury');
        await _showTreasuryQR(savedTreasury.account_code, savedTreasury);
        _showToast('تم حفظ الحساب وإنشاء رمز QR الخاص به', 'success');
```

هذا يستفيد من استجابة `finance_save_treasury` الموجودة ولا ينشئ سجلًا ثانيًا. إذا تعذرت استجابة الهوية، سيظهر خطأ صريح بدل ادعاء أن الرمز أُنشئ.

### Change D — توسيع مودال الإنشاء

- **الدالة:** `_openTreasuryDialog()`
- **المحدد:** السطر الحالي `width: 720,` داخل `Swal.fire` الخاص بعنوان `إضافة خزينة / بنك`.
- **استبدل السطر فقط بـ:**

```javascript
        width: 820,
```

لا تغيّر مودال تعديل البيانات أو وظائف الأرصدة.

### Change E — إتاحة الدالة للزر

- **الموضع:** كائن التصدير في نهاية وحدة `RW_Finance`، قرب السطر 21394.
- **المحدد الحالي:**

```javascript
_filterTreasury: _filterTreasury, _openTreasuryDialog: _openTreasuryDialog, _editTreasury: _editTreasury,
```

- **استبدله بالسطر:**

```javascript
_filterTreasury: _filterTreasury, _openTreasuryDialog: _openTreasuryDialog, _editTreasury: _editTreasury, _showTreasuryQR: _showTreasuryQR,
```

## الاختبارات المطلوبة بعد تطبيق المالك

1. إنشاء خزينة اختبار صفرية الرصيد من النظام الأم؛ التأكد من نجاح الحفظ عبر `finance_save_treasury` وعدم ظهور POST مباشر إلى `/rest/v1/treasury`.
2. التأكد من فتح QR تلقائيًا، وأن الرمز قابل للمسح ويحتوي JSON صالحًا به `type`, `version`, `company_id`, `treasury_id`.
3. من قائمة الخزائن، الضغط على «عرض QR» لا يفتح مودال التعديل، ويعرض الرمز الخاص بالسجل الصحيح.
4. بعد إعادة تحميل الصفحة، يظل زر QR يعرض نفس `treasury_id` لأن الهوية مشتقة من UUID الثابت، لا من رقم عشوائي جديد.
5. تعديل اسم/نوع/فرع الخزينة لا يغيّر `id` أو الأرصدة، ويظل QR صالحًا.
6. فشل تحميل مكتبة QR يعرض خطأ واضحًا ولا يؤثر في حفظ الخزينة أو بياناتها.
7. حذف سجل الاختبار فقط عبر `finance_delete_treasury` بعد التأكد أنه بلا رصيد أو حركات أو ورديات؛ ثم إثبات `fixture_residue=0` وعدد الخزائن يعود إلى baseline.
8. اختبار قارئ QR في تطبيق POS وربط الخزينة ليس PASS ضمن هذا التغيير؛ يحتاج Change Set مستقلًا على Consumer الحالي وعقد RPC مصادق عليه. لا تُعلن الربط التلقائي مكتملًا قبل هذا الاختبار.

## Production / Data / Migration

- لا Migration مطلوبة لعرض QR؛ `treasury.id` و`company_id` موجودان بالفعل.
- لم تتغير Production schema أو ACL أو البيانات في هذه الدورة.
- لم تُنشأ بيانات اختبار في قاعدة العملاء الحية؛ اختبارات الواجهة تنتظر تطبيق المالك للتعديل.
- لا تُنشأ Edge Function جديدة لهذا التغيير؛ لا حاجة لها في توليد QR بالمتصفح.

## الحالة

`PRODUCTION RPC CONTRACTS RECHECKED / CURRENT SOURCE SHA VERIFIED / QR OWNER CHANGESET PREPARED / NO PRODUCTION DATA MUTATION / UI DEPLOYMENT + BROWSER E2E OPEN`

## SELF-AUDIT FINAL

- **What I Proved:** مصدر QR الحالي متاح بالفعل في النظام الأم؛ هوية الخزينة UUID ثابتة؛ RPCs الحالية متاحة للمستخدم المصادق عليه وغير متاحة لـanon؛ Production يحتوي سجل خزينة واحدًا ولم تتغير البيانات في هذه الدورة.
- **What I Did Not Prove:** لم يُطبّق Owner Change Set بعد؛ لم يُنشر UI الجديد؛ لم يُختبر QR من متصفح فعلي؛ لم يُثبت Consumer POS الذي يربط الخزينة بمجرد المسح.
- **What I Fixed:** لم أغيّر Production لأن إنشاء QR لا يتطلب تغيير DB. جهزت تغييرات جراحية تحفظ مسار RPC الحالي وتضيف عرض QR ثابتًا.
- **What I Initially Missed:** تقرير Report431 لا يغلق طلب QR؛ كما أن وجود مكتبة QR في النظام لا يعني أن كل خزينة لديها زر/رمز معروض.
- **What Could Still Be Wrong:** قد تتغير نسخة `main.html` قبل تطبيق المالك؛ يجب إعادة فحص SHA. كما أن تحميل CDN قد يفشل في بيئة مقيدة الشبكة.
- **Final Confidence:** مرتفع في Owner Change Set؛ غير مثبت في Runtime قبل التطبيق.
- **Final Closure Status:** `OWNER CHANGESET READY — NOT CLOSED UNTIL APPLIED, DEPLOYED, AND BROWSER-VERIFIED`.

## نقطة الاستكمال الدقيقة

أعد جلب `companies/company-1/main.html` من `erp-frontend`، وتحقق أن blob SHA هو `9d02dcc1129e00c033082384562177ce1aa5b80a`. طبّق Changes A–E فقط، ثم اختبر إنشاء خزينة صفرية الرصيد وعرض QR وإعادة تحميل الصفحة والحذف النظيف. بعد ذلك، نفّذ مهمة منفصلة لتتبع Consumer الـPOS وعقد الربط المصادق عليه؛ لا تدّعِ أن المسح يربط الكاشير تلقائيًا قبل ذلك.
