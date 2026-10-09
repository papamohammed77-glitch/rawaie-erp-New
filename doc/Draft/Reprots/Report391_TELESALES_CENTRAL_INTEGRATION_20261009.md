# Report391 — تكامل التلي سيلز مع القلب المركزي للأوردرات والرانشيتات
**التاريخ:** 2026-10-09  
**النطاق:** أول تطبيق مبيعات — `companies/company-1/sales/telesales.html`  
**القاعدة:** عدم اعتبار أي إصلاح مكتملًا في الواجهة قبل تطبيق المالك للتغيير ونشره واختباره على النسخة المنشورة.

## 1. PRE-CHANGE SELF-AUDIT

| البند | الحالة المثبتة |
|---|---|
| Governance / continuity | قُرئ `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` و`CURRENT_STATE.md` |
| Current telesales source | قُرئ الملف الحالي؛ blob SHA `d839ff043631d365be8eb2832ee98aa4fabcb43c`، 1,489 سطرًا |
| Shared core | قُرئ `companies/company-1/core.js`؛ blob SHA `e853c49375ccc8b94757b594057dcd853b4a2fdb` |
| Current Production | Supabase `fiilmooggumokxanwiyx`؛ المشروع ACTIVE_HEALTHY، قاعدة PostgreSQL 17 |
| Existing production integration | `save-sales-invoice` v16، `update-order` v4 قبل الإصلاح، `confirm-order` v4، `create-runsheet` v26، `append-to-runsheet` v8 |
| Database contracts | `orders`, `order_details`, `runsheets`, `run_sheet_details` موجودة، وRLS مفعّل على الجداول الستة ذات الصلة |
| Live business data | عدد الأوردرات = 0، وعدد الرانشيتات = 0 وقت الفحص؛ لا يمكن الادعاء بتنفيذ E2E على طلب تشغيلي حقيقي |
| Stock boundary | إنشاء/تعديل أوردر تلي سيلز لا ينبغي أن يحرّك المخزون؛ الربط بالرانشيت يمر عبر RPCs المركزية |

## 2. النتائج الجنائية المثبتة

### A. مسار إنشاء الأوردر

التلي سيلز يستخدم بالفعل `RW_API.call('save-sales-invoice', ...)`. Production Edge Function v16 يتحقق من جلسة المستخدم وسجل `public.users` وصلاحية قاعدة البيانات، ثم يستدعي `save_sales_invoice_atomic`. هذه مسؤولية مركزية قائمة يجب الحفاظ عليها؛ لا نضيف Edge Function جديدة ولا ننقل منطق إنشاء الأوردر إلى الواجهة.

### B. عيب تعديل الأوردر الموجود

في النسخة الحالية من `submitOrder()`، مسار التعديل كان ينفذ سلسلة منفصلة مباشرة على الجداول:
1. قراءة الأوردر بالـ`order_code` فقط.
2. تحديث رأس الأوردر.
3. حذف كل `order_details`.
4. قراءة الأصناف باستخدام `item_code` دون `company_id`.
5. إدخال التفاصيل الجديدة في طلب منفصل.

هذا المسار غير ذري (non-atomic). فشل بعد حذف التفاصيل يمكن أن يترك الأوردر ناقصًا، كما أنه يتجاوز الـRPC المركزي الذي أُنشئ بالفعل للتعديل.

**المسار المركزي موجود مسبقًا:** Edge Function `update-order` تستدعي `update_order_atomic`، الذي يقفل الأوردر، ويتحقق من الشركة والمالك وحالة الأوردر والرانشيت وهوية الأصناف، ويكتب التفاصيل والسجل التدقيقي داخل معاملة واحدة. لذلك الحل الصحيح هو توصيل واجهة التلي سيلز بهذا المسار الموجود، وليس إنشاء Function جديدة.

### C. عيوب مؤكدة في `update_order_atomic` قبل الجراحة

- فحص الأصناف المكررة كان يعرّف عمود JSON باسم `code` لكنه يختار `item_code`؛ وبالتالي كان الفحص معيبًا.
- التعديل لا يرفع الحالة إلى `Confirmed`، رغم أن واجهة التلي سيلز الحالية تعلن نجاح الحفظ وتحوّل حالة التعديل إلى `Confirmed`.
- سجل التدقيق كان يكتب `action='update_order'` بينما قيد `audit_log_action_check` يسمح فقط بالقيم العامة `create/update/delete/login/logout/failed_login`. هذا كان يفشل المعاملة كاملة عند تسجيل التدقيق.

## 3. تغييرات Production المنفذة

### A. PostgreSQL

تم تطبيق migrations بالترتيب:

1. `telesales_update_order_status_and_duplicate_guard_20261009`
   - جعلت التعديل يحول الأوردر إلى `Confirmed`.
   - أصلحت مرجع عمود فحص التكرار ليتوافق مع حقل JSON `code`.
   - عدّلت نتيجة RPC لتعيد `order_status='Confirmed'`.

2. أثناء الاختبار ظهر خطأ إضافي مثبت: `audit_log_action_check` يرفض `update_order`. لم يتم توسيع القيد بلا حاجة؛ عُدّل تسجيل العملية إلى `action='update'` مع الإبقاء على `table_name='orders'` و`source_type='telesales'` و`operation_id` لتظل هوية العملية محفوظة.

3. `fix_telesales_update_order_audit_action_constraint_20261009`
   - يثبت التصحيح السابق داخل تعريف الدالة الرسمية.

### B. Edge Function

تم تحديث **الدالة القائمة** `update-order` من v4 إلى v5؛ لم تُنشأ أي Edge Function جديدة.

- الإصدار المنشور: v5، ACTIVE، `verify_jwt=true`.
- Source/package SHA-256: `d70b7ff7596ee71ad3a706388466abec03921cb7d09010fa4ea18371376de283`.
- أضيف تحقق صريح من صلاحيات المستخدم من `public.users.permissions`: `*` أو `orders` أو `telesales`.
- أضيف تحقق من أن الفرع ضمن الشركة، ومن توافقه مع `allowed_branch_ids` أو `default_branch_id` للمستخدم غير المالك.
- بقيت عملية التعديل على RPC المركزي `update_order_atomic`.
- لم تُكشف أو تُستخدم أي كلمة مرور للمستخدمين.

## 4. اختبار قاعدة البيانات

نفّذ اختبار معاملة تجريبية داخل `BEGIN … ROLLBACK` باستخدام هوية الشركة/الفرع/العميل/الصنف الموجودة فعلًا في Production. تحققت شروط الاختبار داخل كتلة SQL:

- تعديل أوردر تجريبي من Draft إلى Confirmed.
- حفظ سطر التفاصيل الجديد.
- رفض تكرار الصنف نفسه داخل الطلب.
- عدم تغيير عدد صفوف `stock_branches` أو `inventory_log`.
- تنفيذ `ROLLBACK` في نهاية الاختبار لإزالة جميع بيانات QA وآثارها.

المحاولة الأولى كشفت خطأ العمود في فحص التكرار، والمحاولة التالية كشفت تعارض سجل التدقيق مع CHECK constraint؛ أصلحت السببين ثم أعدت الاختبار. آخر تنفيذ للمعاملة اكتمل دون خطأ وأُجري `ROLLBACK`. بعد ذلك أُعيد فحص Production: `orders=0`, `runsheets=0`, `QA order residue=0`, `QA audit residue=0`, و`QA operation-registry residue=0`. هذا يثبت عدم بقاء أثر لهذا الاختبار المحدد.

## 5. ما لم يُغلق بعد

لا يمكن إغلاق تكامل التلي سيلز 100% قبل تطبيق المالك لتعديلات ملفات الواجهة المنشورة، وفق قاعدة المشروع التي تمنع المساعد من تعديل ملفات PWA المنشورة مباشرة. النصان الكاملان للاستبدال أدناه.

- `telesales.html`: استبدال `self.submitOrder` كاملًا.
- `core.js`: استبدال `RW_Auth` كاملًا لتصبح صلاحيات التطبيق من سجل المستخدم في قاعدة البيانات بدلًا من `user_metadata`. هذا التغيير مشترك بين التطبيقات، لذا يجب تطبيقه ومراجعته باعتباره تعديلًا مشتركًا، لا ترقيعًا محليًا داخل التلي سيلز فقط.

## 6. التعديل اليدوي الأول — telesales.html

**الملف:** `companies/company-1/sales/telesales.html`  
**SHA قبل التعديل:** `d839ff043631d365be8eb2832ee98aa4fabcb43c`  
**العنصر:** `self.submitOrder = function() { ... };`  
**المحدد الفريد:** `self.submitOrder = function() {` داخل قسم `// ==================== حفظ الأوردر ====================`  
**الإجراء:** احذف دالة `self.submitOrder` كاملة حتى قوس الإغلاق `};` السابق مباشرةً لـ`self._editOrderFromDetail = function(orderId)`، واستبدلها كاملة بما يلي:

```javascript
self.submitOrder = function() {
    if (!selCust) { RW_UI.toast('اختر عميلاً أولاً', 'warning'); return; }
    if (!cart.length) { RW_UI.toast('السلة فارغة', 'warning'); return; }
    if (!selBranch) { RW_UI.toast('اختر فرعاً', 'warning'); return; }

    var totals = self.calcTotals();
    if (minAmt > 0 && totals.total < minAmt) {
        RW_UI.toast('الحد الأدنى للفاتورة: ' + fmtNum(minAmt), 'warning');
        return;
    }

    var items = [];
    for (var i = 0; i < cart.length; i++) {
        if (!cart[i].code || !(Number(cart[i].qty) > 0) || !(Number(cart[i].price) >= 0)) {
            RW_UI.toast('يوجد صنف ببيانات أو كمية غير صالحة', 'error');
            return;
        }
        items.push({
            code: String(cart[i].code),
            name: cart[i].name || '',
            price: Number(cart[i].price),
            qty: Number(cart[i].qty),
            unit: cart[i].unit || 'حبة'
        });
    }

    var oldOrderCode = editingOrderCode;
    var isEdit = !!oldOrderCode;
    var header = {
        customer_code: selCust.customer_code,
        custName: selCust.name,
        area: selCust.area || '',
        total: totals.total,
        deliveryFees: totals.del,
        status: 'Confirmed',
        paymentType: selCust.payment_type || 'أجل',
        taxAmount: totals.tax,
        taxRate: taxRate,
        source: 'telesales'
    };

    self.closeCartModal();
    RW_UI.showLoader(isEdit ? 'جاري تحديث الأوردر...' : 'جاري حفظ الأوردر...');

    function finishSuccess(message) {
        RW_UI.hideLoader();
        RW_UI.toast(message, 'success');
        cart = [];
        selCust = null;
        selBranch = null;
        editingOrderCode = null;
        self.clearCustomer();
        self.updateFloatingCart();
        self.updateCartTabBadge();
        self.switchTab('today');
    }

    function finishFailure(json, err) {
        RW_UI.hideLoader();
        var message = (json && (json.msg || json.error)) || err || 'فشلت العملية';
        RW_UI.showError(message);
    }

    if (isEdit) {
        RW_API.call('update-order', {
            order_code: oldOrderCode,
            orderHeader: header,
            itemsList: items,
            branchCode: selBranch
        }, function(json, err) {
            if (err || !json || json.success !== true) {
                finishFailure(json, err);
                return;
            }
            finishSuccess('تم تحديث الأوردر ' + oldOrderCode + ' بنجاح');
        });
        return;
    }

    RW_API.call('save-sales-invoice', {
        orderHeader: header,
        itemsList: items,
        branchCode: selBranch
    }, function(json, err) {
        if (err || !json || json.success !== true) {
            finishFailure(json, err);
            return;
        }
        finishSuccess('تم الحفظ: ' + (json.orderID || json.order_id || 'تم إنشاء الأوردر'));
    });
};
```

### نتيجة التعديل المتوقعة

- إنشاء الأوردر يظل عبر `save-sales-invoice` المركزي.
- تعديل الأوردر ينتقل إلى `update-order` الذري.
- لا تُحذف تفاصيل الأوردر من الواجهة على عدة طلبات منفصلة.
- التحقق من صلاحية الشركة والفرع وهوية الصنف يحدث في Production.
- لا تحدث حركة مخزون عند إنشاء/تعديل طلب تلي سيلز؛ حركة المخزون تبقى في دورة Picking/Loading/Delivery/Returns المركزية.

## 7. التعديل اليدوي الثاني — core.js

**الملف:** `companies/company-1/core.js`  
**SHA قبل التعديل:** `e853c49375ccc8b94757b594057dcd853b4a2fdb`  
**العنصر:** `var RW_Auth = (function() { ... })();`  
**المحدد الفريد:** `var RW_Auth = (function() {` حتى `})();` الذي يسبق مباشرةً تعليق `// الوحدة ٢: RW_DB`.  
**الإجراء:** استبدل وحدة `RW_Auth` كاملة بالنص التالي. هذا تعديل في النواة المشتركة؛ يجب نشره واختباره في التلي سيلز ثم إعادة اختبار التطبيقات التي تعتمد على `core.js`.

```javascript
var RW_Auth = (function() {
    var currentUser = null;
    var currentProfile = null;
    var currentSession = null;
    var pubUserId = null;

    function normalizePermissions(value) {
        if (!Array.isArray(value)) return [];
        var out = [];
        for (var i = 0; i < value.length; i++) {
            var permission = String(value[i] == null ? '' : value[i]).trim();
            if (permission && out.indexOf(permission) === -1) out.push(permission);
        }
        return out;
    }

    function hydrateProfile(callback) {
        if (!supabase || !currentUser || !currentUser.id) {
            if (callback) callback(null, 'جلسة غير صالحة');
            return;
        }

        supabase.from('users')
            .select('id,auth_id,company_id,email,name,role,status,permissions,active_warehouse_role')
            .eq('auth_id', currentUser.id)
            .maybeSingle()
            .then(function(result) {
                if (result.error) {
                    if (callback) callback(null, 'تعذر تحميل صلاحيات المستخدم من قاعدة البيانات: ' + result.error.message);
                    return;
                }

                var profile = result.data;
                if (!profile || !profile.id || !profile.company_id) {
                    if (callback) callback(null, 'لا يوجد سجل مستخدم صالح مرتبط بحساب المصادقة');
                    return;
                }

                if (profile.status && String(profile.status).toLowerCase() !== 'active') {
                    if (callback) callback(null, 'حساب المستخدم غير نشط');
                    return;
                }

                var permissions = normalizePermissions(profile.permissions);
                pubUserId = profile.id;
                currentProfile = {
                    id: profile.id,
                    auth_id: profile.auth_id,
                    company_id: profile.company_id,
                    email: profile.email || currentUser.email,
                    name: profile.name || currentUser.email,
                    role: profile.role || 'موظف',
                    isOwner: permissions.indexOf('*') !== -1,
                    permissions: permissions,
                    activeWarehouseRole: profile.active_warehouse_role || ''
                };

                if (callback) callback({
                    id: currentProfile.id,
                    auth_id: currentProfile.auth_id,
                    company_id: currentProfile.company_id,
                    email: currentProfile.email,
                    name: currentProfile.name,
                    role: currentProfile.role,
                    isOwner: currentProfile.isOwner,
                    permissions: currentProfile.permissions.slice(),
                    activeWarehouseRole: currentProfile.activeWarehouseRole
                }, null);
            })
            .catch(function(error) {
                if (callback) callback(null, 'فشل تحميل ملف المستخدم: ' + (error && error.message ? error.message : 'خطأ غير معروف'));
            });
    }

    function init(callback) {
        if (!supabase) {
            if (callback) callback(null, 'Supabase غير مهيأ');
            return;
        }

        supabase.auth.getSession().then(function(result) {
            if (!result.data || !result.data.session) {
                currentSession = null;
                currentUser = null;
                currentProfile = null;
                pubUserId = null;
                if (callback) callback(null, 'NO_SESSION');
                return;
            }

            currentSession = result.data.session;
            currentUser = result.data.session.user;
            hydrateProfile(callback);
        }).catch(function(error) {
            if (callback) callback(null, error && error.message ? error.message : 'فشل استعادة الجلسة');
        });
    }

    function doLogin(email, pass, callback) {
        if (!email || !pass) {
            if (callback) callback(null, 'أدخل البريد الإلكتروني وكلمة المرور');
            return;
        }

        supabase.auth.signInWithPassword({ email: email, password: pass }).then(function(result) {
            if (result.error) {
                if (callback) callback(null, result.error.message);
                return;
            }

            currentSession = result.data.session;
            currentUser = result.data.session.user;
            hydrateProfile(function(user, error) {
                if (error || !user) {
                    supabase.auth.signOut().then(function() {
                        currentSession = null;
                        currentUser = null;
                        currentProfile = null;
                        pubUserId = null;
                        if (callback) callback(null, error || 'تعذر التحقق من صلاحيات المستخدم');
                    }).catch(function() {
                        currentSession = null;
                        currentUser = null;
                        currentProfile = null;
                        pubUserId = null;
                        if (callback) callback(null, error || 'تعذر التحقق من صلاحيات المستخدم');
                    });
                    return;
                }
                if (callback) callback(user, null);
            });
        }).catch(function(error) {
            if (callback) callback(null, error && error.message ? error.message : 'فشل تسجيل الدخول');
        });
    }

    function doLogout(callback) {
        supabase.auth.signOut().then(function() {
            currentUser = null;
            currentProfile = null;
            currentSession = null;
            pubUserId = null;
            if (callback) callback(true);
        }).catch(function(error) {
            if (callback) callback(false, error && error.message ? error.message : 'فشل تسجيل الخروج');
        });
    }

    function getUser() {
        if (!currentProfile) return null;
        return {
            id: currentProfile.id,
            auth_id: currentProfile.auth_id,
            company_id: currentProfile.company_id,
            email: currentProfile.email,
            name: currentProfile.name,
            role: currentProfile.role,
            isOwner: currentProfile.isOwner,
            permissions: currentProfile.permissions.slice(),
            activeWarehouseRole: currentProfile.activeWarehouseRole,
            session: currentSession
        };
    }

    function getToken() {
        return currentSession ? currentSession.access_token : null;
    }

    function checkPermission(permissionKey) {
        if (!currentProfile) return false;
        if (currentProfile.permissions.indexOf('*') !== -1) return true;
        return currentProfile.permissions.indexOf(permissionKey) !== -1;
    }

    function hasWarehouseRole(roleName) {
        if (!currentProfile) return false;
        if (currentProfile.permissions.indexOf('*') !== -1) return true;

        var activeRole = '';
        try {
            activeRole = window._rwActiveRole || currentProfile.activeWarehouseRole || '';
        } catch (error) {
            activeRole = currentProfile.activeWarehouseRole || '';
        }
        return activeRole === roleName;
    }

    return {
        init: init,
        doLogin: doLogin,
        doLogout: doLogout,
        getUser: getUser,
        getToken: getToken,
        checkPermission: checkPermission,
        hasWarehouseRole: hasWarehouseRole
    };
})();
```

**سبب ضرورة هذا التعديل:** النسخة الحالية من `core.js` تبني `isOwner` و`permissions` من `user_metadata`، بينما Production/RLS وEdge Functions تعتمد سجل `public.users` وصلاحياته. هذا يخلق مصدرين للحقيقة ويمكن أن يمنع مالكًا يملك `permissions=["*"]` في قاعدة البيانات من دخول التطبيق أو يجعله يرى صلاحيات قديمة. البديل أعلاه يفشل مغلقًا إذا تعذر تحميل سجل DB، ولا يرجع إلى metadata كمرجع للصلاحيات.

## 8. خطة التحقق بعد دمج المالك

1. نفّذ فحص JavaScript syntax لملفي `core.js` و`telesales.html`.
2. انشر النسخة الجديدة من الملفات المنشورة/PWA وفق مسار النشر الحالي.
3. سجّل دخولًا جديدًا بحساب تلي سيلز، وتحقق من صلاحية `telesales` من DB.
4. أنشئ أوردرًا، ثم راجع `orders` و`order_details` وتأكد من `source='telesales'` و`order_status='Confirmed'` ووجود `company_id`.
5. عدّل أوردرًا غير مرتبط برانشيت، وتأكد من ذريّة تحديث الرأس والتفاصيل ومن تسجيل `audit_log.action='update'`.
6. جرّب صنفًا مكررًا، وجرّب مستخدمًا بلا `orders/telesales/*`، وجرّب فرعًا غير مسموح.
7. أنشئ رانشيت من الأوردر المؤكد باستخدام واجهة الرانشيت الحالية، وتأكد من ارتباط `orders.runsheet_id` وتكوين `run_sheet_details` عبر `create_runsheet_atomic` أو `append_orders_to_runsheet_atomic`.
8. تحقق أن إنشاء/تعديل الطلب لا يغير `stock_branches` ولا `inventory_log`; حركة المخزون تظل في مراحل المخزون المركزية.
9. اختبر فشل الشبكة وإعادة المحاولة، وتأكد من عدم مضاعفة الطلب أو تفاصيله.
10. قارن الـartifact المنشور مع Git بعد النشر.

## 9. SELF-AUDIT FINAL

**ما ثبت:** Production DB/RPC عُدّل واختُبر داخل معاملة rollback؛ `update-order` v5 منشورة وACTIVE و`verify_jwt=true)؛ مسار إنشاء الأوردر الأصلي عبر `save-sales-invoice` محفوظ؛ RLS مفعّل على جداول الأوردر والرانشيت ذات الصلة.

**ما لم يثبت:** لا يوجد HTTP E2E موثق بجلسة مستخدم حقيقية في هذه الدورة؛ لم تُنفذ واجهة PWA بعد لأن قواعد المشروع تجعل تعديل الملفات المنشورة مسؤولية المالك؛ لا توجد أوردرات أو رانشيتات حقيقية في Production وقت الفحص؛ لم يثبت بعد تطابق الملف المنشور بعد التعديل مع Git.

**ما تم إصلاحه:** فحص الأصناف المكررة في RPC، انتقال حالة التعديل إلى Confirmed، توافق سجل التدقيق مع CHECK constraint، والتحقق من صلاحية التعديل والفرع في Edge Function.

**ما كاد يفوتني:** اختبار الـRPC كشف أن قيد سجل التدقيق كان سيُفشل المعاملة حتى بعد إصلاح مسار التعديل؛ أُصلح السبب بدل إخفاء الخطأ أو توسيع القيد بلا حاجة.

**ما قد يبقى خطأ:** لا يمكن استبعاد عيوب UX أو التوافق في المتصفح قبل تطبيق بديل الواجهة واختبار E2E؛ يجب مراجعة أي مستخدم يعتمد على role-based permission بدل `users.permissions` قبل نشر تغيير النواة المشتركة على جميع التطبيقات.

**Final Closure Status:** `PRODUCTION BACKEND REPAIRED / FRONTEND OWNER SURGERY PENDING / FULL INTEGRATION NOT YET CLOSED`.

## إلى CTO القادم

ابدأ من هذا التقرير ثم تحقق من Current Git وProduction مجددًا. لا تعد إنشاء `update-order`؛ الإصدار v5 موجود. لا تعد تطبيق تغييرات SQL المذكورة دون مقارنة التعريف الحالي. الخطوة الدقيقة التالية هي أن يدمج المالك استبدال `RW_Auth` في `core.js` واستبدال `self.submitOrder` في `telesales.html`، ثم نشرهما وتنفيذ اختبارات E2E المذكورة. بعد إغلاق التلي سيلز فقط انتقل إلى التطبيق التالي.


## 10. Production migration source synchronization

The exact SQL definitions submitted for the three Production migrations in this execution are now recorded in the repository under the official migration directory:

- `supabase/migrations/20261009164325_telesales_update_order_status_and_duplicate_guard_20261009.sql` — Git commit `6de7c8ffcec48e57e191f21ebaa45abf59bcad2e`.
- `supabase/migrations/20261009164549_fix_telesales_update_order_duplicate_guard_alias_20261009.sql` — Git commit `e74020920dbd56b3822bb0b89d0bf86c1b38b8f2`.
- `supabase/migrations/20261009164638_fix_telesales_update_order_audit_action_constraint_20261009.sql` — Git commit `4e762f36d4c16941e17fa1b1414a5fdcb83efab5`.

These files preserve the actual sequence, including the intermediate defects that were detected by runtime QA and corrected in the following migrations. They are not falsely represented as one pristine migration.
