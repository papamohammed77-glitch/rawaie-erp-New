# Report435 — POS: عزل الجهاز والخزينة والجلسة وإصلاح مسار البيع الإنتاجي — 2026-10-18

## PRE-CHANGE SELF-AUDIT

Business Understanding: حساب الكاشير هو هوية الموظف، بينما الجهاز وخزينته ووردية الجهاز كيانات منفصلة. البيع النقدي يجب أن يذهب إلى خزينة الجهاز المثبتة، لا إلى خزينة تختارها الدالة عشوائيًا ولا إلى الخزينة العامة لمجرد أنها الوحيدة.

Architecture Understanding: POS PWA → save-sales-invoice v19 (JWT) → service_role → save_sales_invoice_atomic → post_stock_movement + post_cash_receipt_atomic. الوردية والجهاز والخزينة تُدار عبر RPCs موجودة؛ لم تُنشأ Edge Function جديدة.

Database Understanding: Production يحتوي pos_terminals وpos_shifts وpos_shift_cash_counts وpos_shift_events، ويربط pos_shifts بـ cashier_user_id وterminal_id وtreasury_id. orders يحتوي shift_id وdevice_id. cash_box يحتوي shift_id وtreasury_id.

Historical Understanding: راجعت CURRENT_STATE.md، Report425 الخاص بنواة الورديات، Report426 الخاص بعقد الفرع/العميل النقدي، Report433 الخاص بواجهة QR في النظام الأم، Report434 الخاص بربط الجهاز بالخزينة، ثم قارنت ذلك بالمصدر الحي وقاعدة البيانات الحية. التقارير تاريخية ولا تتقدم على الدليل الحالي.

Production Understanding: فحص مباشر لقاعدة fiilmooggumokxanwiyx في 2026-10-18 قرابة 16:02–16:12 UTC، وتعريفات الدوال والـACL والـtriggers والصفوف الحالية.

Current Understanding:
- POS: companies/company-1/sales/pos.html — blob SHA f6bc60f7067922d2603c4f849d2fb477407a7e83 — 119,763 حرفًا / 2,103 سطرًا.
- أحدث commit واجهة POS عُثر عليه: e8f6e4000f2edb49944b25365f575dc62a580d30؛ أضاف ربط QR للخزينة. التعديل موجود في المصدر الحالي.
- core.js — blob SHA c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81.
- Migration Production/Git: supabase/migrations/20261018161000_pos_terminal_treasury_sale_routing.sql — blob SHA bb2a923cd07483d8fa114c43e9e5f859e56268e6 — commit c1402a7671a69886ce909aabb3db64bfb599ab97.

Execution Confidence: مرتفع لإصلاح Production الخاص بتوجيه النقدية، لأن الإصلاح اختُبر بمعاملة SQL ناجحة داخل rollback، مع اختبار رفض جهاز خاطئ. غير مكتمل بالنسبة لواجهة المتصفح لأن تعديل POS ما زال على المالك، ولم أدّعِ Browser/HTTP E2E.

### Confirmed Facts — Production قبل التعديل

- عدد الخزائن النشطة = 3.
- pos_terminals = 1، pos_shifts = 1، pos_shift_events = 2، cash_box = 6، وPOS orders = 4.
- الجهاز الموجود مربوط بالفرع BR-01 وبالخزينة الرئيسية، ووردية السجل الحالي مغلقة.
- فرق الوردية المغلقة الحالي = -135.00. لم أعدّل هذه الوردية أو الفرق أو أي حركة نقدية قائمة.
- save_sales_invoice_atomic كان يشترط أن يكون للشركة خزينة نشطة واحدة بالضبط؛ ومع وجود 3 خزائن كان مسار البيع النقدي POS يفشل برسالة POS_CASH_TREASURY_MAPPING_REQUIRED رغم وجود خزينة ثابتة على الجهاز والوردية.
- pos_get_shift_summary يعيد terminal_id وterminal_code وtreasury_id ضمن بيانات الوردية، لكن POS كان يقبل الوردية العائدة دون مطابقة هويتها مع الجهاز الحالي.
- POS لم يكن يرسل shift_id أو device_id في حمولة الفاتورة.
- loadBranches كان يعرض كل الفروع المخزنة محليًا دون تطبيق defaultBranchId / allowedBranchIds في الواجهة.
- اختيار العميل كان متاحًا، بينما Production save-sales-invoice يفرض فعليًا عميلًا نقديًا عامًا على POS؛ لذا كان بالإمكان عرض اسم عميل في الواجهة/الإيصال لا يمثل العميل المسجل فعليًا.
- RW_Auth.doLogout يستخدم supabase.auth.signOut() الافتراضي، وهو scope=global حسب توثيق Supabase، أي أن تسجيل الخروج من جهاز قد ينهي جلسات الأجهزة الأخرى. هذا يخالف استقلال جلسات الكاشير عبر الأجهزة.

## ما تم إصلاحه فعليًا في Production

### Migration

الملف: supabase/migrations/20261018161000_pos_terminal_treasury_sale_routing.sql

Production migration name: pos_terminal_treasury_sale_routing_20261018
Production migration version: 20261018160955

1. save_sales_invoice_atomic أصبح يحفظ shift_id وdevice_id القادمين من عقد POS في orders.
2. عندما يكون مصدر العملية pos، لم يعد يختار خزينة الشركة بناءً على شرط «خزينة نشطة واحدة فقط». بل يقرأ treasury_id من الوردية المفتوحة المرتبطة بالفاتورة، ويتحقق من:
   - الشركة والفرع.
   - الكاشير صاحب الوردية.
   - أن الوردية مفتوحة.
   - أن الجهاز نشط ومربوط بالخزينة نفسها.
   - أن الخزينة نشطة وتتبع الشركة نفسها.
   - أن device_id المرسل، إذا وُجد، يطابق terminal_code الثابت.
3. أبقيت عقد الخزينة السابق لعمليات البيع النقدي غير POS دون تغيير.
4. تم تقوية trigger pos_assign_order_shift: إذا أرسل POS shift_id صريحًا، يلزم أيضًا device_id صحيحًا ومربوطًا بالجهاز والخزينة والوردية نفسها. وإذا أرسل device_id دون shift_id، يربط العملية بالوردية المفتوحة على ذلك الجهاز فقط. بقي مسار توافق مؤقت للعملاء الأقدم الذين لا يرسلون device_id؛ لذلك يجب على المالك تطبيق Patch POS أدناه حتى يستخدم العقد الجديد.

لم تُضف Edge Function. save-sales-invoice بقي v19 ACTIVE وverify_jwt=true. بقي save_sales_invoice_atomic غير قابل للتنفيذ من anon/authenticated ومسموحًا لـservice_role فقط. دالة trigger ليست API للمستخدمين ولا تُمنح صلاحية تنفيذ مباشرة.

## الاختبارات الفعلية

1. Transactional SQL E2E داخل معاملة تم التراجع عنها:
   - أنشأت وردية اختبار مؤقتة داخل المعاملة.
   - استدعيت save_sales_invoice_atomic بصنف إنتاجي متوفر، مصدر pos، shift_id وdevice_id المطابقين.
   - نجح المسار وأنشأ مؤقتًا ORD-1011 بمبلغ 90.00، وربط cash_box بالوردية والجهاز والخزينة الرئيسية المحددة على الجهاز.
   - نفذت ROLLBACK؛ لم يبقَ طلب أو حركة نقدية تجريبية.
2. اختبار جهاز خاطئ:
   - مررت device_id غير مربوط بالخزينة/الفرع.
   - رفض trigger العملية بالخطأ POS_TERMINAL_NOT_BOUND_TO_BRANCH_TREASURY.
   - الاختبار داخل كتلة استثناء معزولة؛ لم يبقَ أي صف تجريبي.
3. بعد الاختبارات: pos_terminals=1، pos_shifts=1، pos_shift_events=2، cash_box=6، active_treasuries=3، test_orders=0.
4. تم الحفاظ على فرق الوردية التاريخي -135.00 كما هو.
5. لم يتم إثبات Browser/HTTP E2E بعد، لأن تغييرات واجهة POS التالية لم تُطبق بعد.

## OWNER CHANGESETS — تعديلات جراحية فقط

لا تعدّل main.html. لا تستبدل pos.html كاملًا. لا تُعد تطبيق تغييرات قديمة من تقارير سابقة إلا حيث يثبت المصدر الحالي أنها ما زالت ناقصة.

### Patch A — منع إظهار وردية جهاز آخر

FILE: companies/company-1/sales/pos.html
SHA: f6bc60f7067922d2603c4f849d2fb477407a7e83
ELEMENT: متغيرات حالة الوردية، قرب السطر 276.

ابحث عن:
~~~javascript
self._shiftLoaded = false;
~~~

وأضف بعده مباشرة:
~~~javascript
self._shiftOnOtherTerminal = false;
~~~

في الدالة self._renderShiftState قرب السطر 485، استبدل سطر label الحالي:
~~~javascript
if (label) label.innerText = self._activeShiftId ? ('وردية مفتوحة • ' + Number((self._shiftSummary || {}).expected_cash || 0).toFixed(2)) : 'بدء الوردية';
~~~

بهذا:
~~~javascript
if (label) label.innerText = self._shiftOnOtherTerminal ? 'الوردية مفتوحة على جهاز آخر' : (self._activeShiftId ? ('وردية مفتوحة • ' + Number((self._shiftSummary || {}).expected_cash || 0).toFixed(2)) : 'بدء الوردية');
~~~

ثم ابحث عن الدالة الكاملة self.loadShiftState = function(callback) قرب الأسطر 496–520 واحذف الدالة كاملة واستبدلها:
~~~javascript
self.loadShiftState = function(callback) {
    if (!currentUser || typeof supabase === 'undefined' || !supabase || typeof supabase.rpc !== 'function') {
        if (typeof callback === 'function') callback(false);
        return;
    }

    supabase.rpc('pos_get_shift_summary', { p_shift_id: null }).then(function(res) {
        if (res.error || !res.data || res.data.success !== true) {
            self._shiftLoaded = false;
            self._activeShiftId = null;
            self._shiftSummary = null;
            self._shiftOnOtherTerminal = false;
            self._renderShiftState();
            console.error('POS shift summary failed:', res.error || res.data);
            if (typeof callback === 'function') callback(false);
            return;
        }

        var shift = res.data.active_shift && res.data.shift ? res.data.shift : null;
        var terminalCode = self._getShiftTerminalCode();
        var localTerminalId = '';
        var localTreasuryId = '';

        try {
            localTerminalId = localStorage.getItem('rawaea_pos_terminal_id') || '';
            localTreasuryId = localStorage.getItem('rawaea_pos_terminal_treasury_id') || '';
        } catch (e) {}

        self._shiftOnOtherTerminal = !!(shift && (
            !localTerminalId ||
            !localTreasuryId ||
            String(shift.terminal_id || '') !== String(localTerminalId) ||
            String(shift.treasury_id || '') !== String(localTreasuryId) ||
            String(shift.terminal_code || '') !== String(terminalCode)
        ));

        if (self._shiftOnOtherTerminal) {
            self._shiftLoaded = true;
            self._activeShiftId = null;
            self._shiftSummary = null;
            self._renderShiftState();
            console.warn('POS open shift belongs to a different terminal; it will not be reused on this device.');
            if (typeof callback === 'function') callback(true);
            return;
        }

        self._shiftSummary = res.data;
        self._activeShiftId = shift ? shift.id : null;
        self._shiftLoaded = true;
        self._renderShiftState();
        if (typeof callback === 'function') callback(true);
    }).catch(function(err) {
        self._shiftLoaded = false;
        self._activeShiftId = null;
        self._shiftSummary = null;
        self._shiftOnOtherTerminal = false;
        self._renderShiftState();
        console.error('POS shift summary exception:', err);
        if (typeof callback === 'function') callback(false);
    });
};
~~~

### Patch B — منع فتح وردية/بيع باستخدام وردية جهاز آخر

في self.openPaymentModal، بعد السطر:
~~~javascript
self.loadShiftState(function(ok) {
~~~

أضف مباشرة:
~~~javascript
if (self._shiftOnOtherTerminal) {
    RW_UI.showError('هذا الحساب لديه وردية مفتوحة على جهاز آخر. لا يمكن نقل الوردية أو استخدام خزينة الجهاز الآخر؛ أغلق الوردية من الجهاز الأصلي أولًا.');
    return;
}
~~~

وفي بداية self.startShift = function()، بعد سطر فتح الدالة مباشرة، أضف:
~~~javascript
if (self._shiftOnOtherTerminal) {
    RW_UI.showError('لا يمكن فتح وردية ثانية لهذا الحساب قبل إغلاق الوردية المفتوحة على الجهاز الأصلي.');
    return;
}
~~~

لا تغيّر بقية الدالتين.

### Patch C — ربط الفاتورة بالوردية والجهاز فعليًا

داخل self.finalizeCheckout، ابحث عن:
~~~javascript
var custCode = selCust ? selCust.customer_code : '';
var custName = selCust ? selCust.name : 'عميل نقدي';
~~~

واستبدله بـ:
~~~javascript
var custCode = '';
var custName = 'عميل نقدي';
~~~

داخل كائن hdr، استبدل:
~~~javascript
area: selCust ? (selCust.area || '') : '',
~~~

بـ:
~~~javascript
area: '',
~~~

وأضف داخل hdr بعد source: 'pos', مباشرة:
~~~javascript
shift_id: self._activeShiftId,
device_id: self._getShiftTerminalCode(),
~~~

لا تحذف operation_id أو fingerprint أو أي حقل آخر. هذا يجعل الطلب يمرر هوية الوردية والجهاز إلى Core المركزي؛ الـtrigger والـCore في Production يتحققان منهما.

### Patch D — فرض فرع المستخدم المصرح به في واجهة POS

FILE: companies/company-1/sales/pos.html
الدالة: self.loadBranches قرب الأسطر 822–834.

احذف الدالة كاملة واستبدلها:
~~~javascript
self.loadBranches = function() {
    if (!db) {
        var failedSelect = RW_UI.byId('posBranchSel');
        if (failedSelect) RW_UI.safeHTML(failedSelect, '<option value="">🏭 فشل تحميل الفروع</option>');
        return;
    }

    db.branches.toArray().then(function(branches) {
        var user = currentUser || {};
        var permissions = Array.isArray(user.permissions) ? user.permissions : [];
        var isOwner = user.isOwner === true || permissions.indexOf('*') !== -1;
        var defaultId = String(user.defaultBranchId || '').trim();
        var rawAllowed = user.allowedBranchIds;
        var allowed = [];
        var i;

        if (Array.isArray(rawAllowed)) {
            allowed = rawAllowed.map(function(x) { return String(x || '').trim(); }).filter(function(x) { return !!x; });
        } else if (typeof rawAllowed === 'string' && rawAllowed.trim()) {
            var raw = rawAllowed.trim();
            if (raw.charAt(0) === '[') {
                try {
                    var parsed = JSON.parse(raw);
                    if (Array.isArray(parsed)) allowed = parsed.map(function(x) { return String(x || '').trim(); }).filter(function(x) { return !!x; });
                } catch (e) {
                    allowed = [];
                }
            } else {
                allowed = raw.split(',').join(';').split(';').map(function(x) { return String(x || '').trim(); }).filter(function(x) { return !!x; });
            }
        }

        if (!isOwner) {
            var allowedValue = defaultId || (allowed.length === 1 ? allowed[0] : '');
            if (!allowedValue) {
                branchMap = {};
                selBranch = null;
                var noBranchSelect = RW_UI.byId('posBranchSel');
                if (noBranchSelect) RW_UI.safeHTML(noBranchSelect, '<option value="">لا يوجد فرع افتراضي وحيد مصرح به</option>');
                RW_UI.showError('اربط حساب الكاشير بفرع افتراضي أو فرع واحد مسموح به من النظام الأم قبل البيع.');
                return;
            }
            branches = branches.filter(function(branch) {
                return String(branch.id) === allowedValue || String(branch.branch_code) === allowedValue;
            });
        }

        branchMap = {};
        var html = '<option value="">🏭 اختر الفرع</option>';
        for (i = 0; i < branches.length; i++) {
            branchMap[branches[i].branch_code] = branches[i].id;
            html += '<option value="' + branches[i].branch_code + '">' + (branches[i].name || branches[i].branch_code) + '</option>';
        }

        var select = RW_UI.byId('posBranchSel');
        if (select) RW_UI.safeHTML(select, html);

        var preferredCode = '';
        var activeShift = self._shiftSummary && self._shiftSummary.shift;
        if (activeShift) {
            for (i = 0; i < branches.length; i++) {
                if (String(branches[i].id) === String(activeShift.branch_id)) {
                    preferredCode = branches[i].branch_code;
                    break;
                }
            }
        }
        if (!preferredCode && !isOwner && branches.length === 1) preferredCode = branches[0].branch_code;
        if (!preferredCode && isOwner && selBranch && branchMap[selBranch]) preferredCode = selBranch;

        if (select) select.value = preferredCode;
        selBranch = preferredCode || null;
        if (selBranch) self.renderProducts();
        if (!isOwner && branches.length !== 1) {
            RW_UI.showError('الفرع المحدد في ملف المستخدم غير موجود ضمن الفروع المحملة. راجع ربط الفرع من النظام الأم.');
        }
    }).catch(function(err) {
        console.error('POS branch load failed:', err);
        RW_UI.showError('تعذر تحميل الفروع المصرح بها.');
    });
};
~~~

### Patch E — إزالة اختيار عميل غير متوافق مع عقد POS النقدي

في سطر HTML قرب السطر 86، ابحث عن بداية العنصر:
~~~html
<select id="posCustSelect" onchange="POS.onCustomerChange()"
~~~

واستبدلها بـ:
~~~html
<select id="posCustSelect" disabled onchange="POS.onCustomerChange()"
~~~

ثم استبدل الدالة self.loadCustomers قرب الأسطر 836–843 كاملة بهذا:
~~~javascript
self.loadCustomers = function() {
    selCust = null;
    var select = RW_UI.byId('posCustSelect');
    if (select) {
        select.disabled = true;
        RW_UI.safeHTML(select, '<option value="">👤 عميل نقدي (عام)</option>');
        select.value = '';
    }
    RW_UI.safeText(RW_UI.byId('cartCustName'), 'عميل نقدي (عام)');
    RW_UI.safeHTML(RW_UI.byId('cartCustDetails'), '');
};
~~~

### Patch F — جلسة مستقلة لكل جهاز، مع إغلاق تلقائي عند ترك الشاشة

FILE: companies/company-1/core.js
SHA: c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81

في موضع تنظيف جلسة الدخول الفاشل داخل doLogin (السطر الحالي 153)، وفي doLogout (السطر الحالي 180)، ابحث في كل موضع عن:
~~~javascript
supabase.auth.signOut().then(function() {
~~~

واستبدل السطر في الموضعين بـ:
~~~javascript
supabase.auth.signOut({ scope: 'local' }).then(function() {
~~~

لا تستبدل بقية الدالتين. السبب: توثيق Supabase يثبت أن signOut() الافتراضي يستخدم global ويُنهي جلسات الأجهزة الأخرى؛ scope: local ينهي جلسة الجهاز الحالي فقط. المرجع: https://supabase.com/docs/reference/javascript/auth-signout

في pos.html، أضف الكتلة التالية قبل RW_SW.register('../sw.js'); مباشرة. لا تضعها داخل دالة أخرى:
~~~javascript
(function() {
    var idleTimer = null;
    var hiddenTimer = null;
    var logoutInProgress = false;

    function appVisible() {
        var app = document.getElementById('mainApp');
        return !!(app && !app.classList.contains('hidden'));
    }

    function clearTimers() {
        if (idleTimer) {
            clearTimeout(idleTimer);
            idleTimer = null;
        }
        if (hiddenTimer) {
            clearTimeout(hiddenTimer);
            hiddenTimer = null;
        }
    }

    function secureLogout() {
        if (logoutInProgress || !appVisible()) return;
        logoutInProgress = true;
        clearTimers();
        RW_UI.toast('تم تسجيل الخروج تلقائيًا لحماية حساب الكاشير', 'warning');
        POS.doLogout();
        setTimeout(function() { logoutInProgress = false; }, 1500);
    }

    function armIdleTimer() {
        if (!appVisible()) return;
        if (idleTimer) clearTimeout(idleTimer);
        idleTimer = setTimeout(secureLogout, 3 * 60 * 1000);
    }

    document.addEventListener('visibilitychange', function() {
        if (document.hidden) {
            if (hiddenTimer) clearTimeout(hiddenTimer);
            hiddenTimer = setTimeout(function() {
                if (document.hidden) secureLogout();
            }, 15000);
        } else {
            if (hiddenTimer) {
                clearTimeout(hiddenTimer);
                hiddenTimer = null;
            }
            armIdleTimer();
        }
    });

    ['pointerdown', 'keydown', 'touchstart', 'click'].forEach(function(eventName) {
        document.addEventListener(eventName, armIdleTimer, { passive: true });
    });
    window.addEventListener('focus', armIdleTimer);
})();
~~~

هذا يغلق الجلسة المحلية بعد 15 ثانية من إخفاء شاشة POS، أو بعد 3 دقائق من عدم النشاط. تسجيل الخروج محلي فلا ينهي جلسات الموظف على الأجهزة الأخرى.

## SELF-AUDIT FINAL

What I Proved:
- Production الحالي يحتوي 3 خزائن نشطة؛ شرط الخزينة الوحيدة كان يتعارض مع تصميم الخزينة الثابتة لكل جهاز.
- بعد migration، بيع POS النقدي التجريبي داخل rollback سجل الخزينة المرتبطة بالوردية والجهاز، لا خزينة مختارة عبر العدّ العام.
- طلب بجهاز غير مربوط رُفض.
- لا يوجد أثر تجريبي بعد الاختبار؛ baseline counts عادت كما كانت.
- ACL الخاص بـsave_sales_invoice_atomic بقي service_role فقط.
- فرق الوردية التاريخي -135.00 لم يتغير.

What I Did Not Prove:
- لم أثبت Browser/HTTP E2E من جلسة كاشير فعلية.
- لم أثبت Cloudflare served artifact parity مع Git.
- لم تُطبق بعد تغييرات المالك في pos.html وcore.js.
- لا أزعم أن auto-logout أو الفرع أو العميل أو مطابقة الجهاز قد اختُبرت في المتصفح قبل تطبيق الـpatches.

What I Fixed:
- أصلحت Production Core/trigger لتوجيه النقدية عبر shift/terminal treasury وتحقق هوية الجهاز عند إرسال device_id.
- حفظت migration canonical في GitHub وطبقتها في Production.

What I Initially Missed:
- لم تكن المشكلة مجرد اختيار خزينة في UI؛ قلب البيع نفسه كان يرفض وجود أكثر من خزينة نشطة.
- ربط الوردية بالمستخدم وحده لا يكفي لمنع استخدام وردية جهاز آخر؛ يجب إرسال shift_id وdevice_id والتحقق منهما.

What Could Still Be Wrong:
- قد تظل النسخة المخدومة من POS قديمة حتى يطبق المالك الـpatches وينشرها.
- مسار التوافق للعملاء الأقدم يبقى متاحًا عندما لا يرسل العميل device_id؛ يجب إنهاء هذا التوافق بعد نشر واختبار الواجهة الجديدة، لا قبله.

Final Confidence: مرتفع في إصلاح Production المطبق واختبارات SQL المعزولة؛ متوسط في الإغلاق الوظيفي الكامل إلى حين تطبيق owner patches واختبار المتصفح.

Final Closure Status:
PRODUCTION CORE REPAIRED + SQL TRANSACTION VERIFIED + BASELINE RESTORED / OWNER POS+CORE PATCHES REQUIRED / BROWSER E2E OPEN / NOT 100% CLOSED.

## نقطة الاستكمال الدقيقة

1. المالك يطبق Patches A–F على الملفات المذكورة فقط، بعد مطابقة SHA.
2. ينشر POS PWA ويتحقق من أن الجهاز الحالي ما زال مربوطًا بالخزينة الرئيسية والوردية المغلقة لا تُعاد فتحها تلقائيًا.
3. يختبر بحساب كاشير: تسجيل الدخول على جهاز ثانٍ لا يعرض وردية الجهاز الأول ولا يسمح بالبيع عليها؛ فتح وردية على الجهاز المربوط فقط؛ فاتورة نقدية تُسجل في خزينة الجهاز؛ فرع غير مصرح لا يظهر ولا يُقبل؛ تسجيل الخروج المحلي لا يُنهي جلسة جهاز آخر؛ إغلاق تلقائي عند إخفاء الشاشة/الخمول.
4. بعد إثبات الواجهة، أعد فحص Production وserved artifact، ثم أزل مسار التوافق القديم الذي يقبل POS بلا device_id في Closure منفصل مع نشر متزامن ومثبت.
