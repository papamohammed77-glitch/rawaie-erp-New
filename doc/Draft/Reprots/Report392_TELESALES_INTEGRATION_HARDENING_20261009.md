# Report392 — إغلاق فجوات تكامل التلي سيلز مع القلب المركزي
**التاريخ:** 2026-10-09  
**المستودع:** `papamohammed77-glitch/rawaie-erp-New`  
**النطاق الوحيد:** تكامل `telesales.html` مع صلاحيات النظام الأم، وRPC تعديل الأوردر، والربط اللاحق بالرانشيت.  
**حدود التعديل:** لم يتم تعديل `main.html` أو `telesales.html` أو `core.js`؛ التعديلات المصدرية في الواجهة موضحة كجراحة يطبقها المالك. نُفذت تغييرات Production اللازمة في قاعدة البيانات والدالة الموجودة `update-order` دون إنشاء Edge Function جديدة.

## PRE-CHANGE SELF-AUDIT

| المجال | التقييم قبل التغيير | دليل / ملاحظة |
|---|---:|---|
| فهم تدفق التلي سيلز | 96/100 | الإنشاء يمر عبر `save-sales-invoice`؛ تعديل الواجهة كان يكتب على الجداول مباشرة |
| فهم عقد قاعدة البيانات | 94/100 | `update_order_atomic(uuid,text,text,jsonb,jsonb,text,uuid)` موجودة في Production |
| Production synchronization | 95/100 | جرى فحص Live Edge، وتعريف RPC، وACL، وعدادات البيانات قبل التغيير وبعده |
| Historical/current comparison | 88/100 | تمت مراجعة Report391 ومصدر migrations النهائي؛ لم أتعامل مع التقرير السابق كدليل Production |
| Consumer tracing | 85/100 | تم تتبع مسار الإنشاء والتعديل في ملف التلي سيلز وواجهة RPC؛ ربط الرانشيت بعد النشر يحتاج E2E متصفح |
| Runtime verification | 80/100 | اختبار SQL معاملاتي مع ROLLBACK نجح؛ HTTP/browser E2E لم يُثبت في هذه البيئة |
| Execution confidence | 88/100 | backend hardening منشور ومطابق للمصدر المسجل؛ الواجهة لم تُنشر بعد |

### Confirmed Facts
- `erp-frontend/companies/company-1/sales/telesales.html`: blob SHA `d839ff043631d365be8eb2832ee98aa4fabcb43c`، 1,489 سطرًا.
- `erp-frontend/companies/company-1/core.js`: blob SHA `e853c49375ccc8b94757b594057dcd853b4a2fdb`.
- `erp-frontend/companies/company-1/main.html`: blob SHA `4f94f9c6ebdde1b59632384628c72767d3bb950d`. أداة جلب الملف أعادت محتوى فارغًا حتى عند طلب نطاقات أسطر؛ لذلك لم أستنتج تفاصيل داخلية غير مقروءة منه ولم ألمسه.
- Supabase Production project `fiilmooggumokxanwiyx`، الحالة `ACTIVE_HEALTHY`.
- `update-order` كان v5، `ACTIVE`، `verify_jwt=true)، SHA-256 `d70b7ff7596ee71ad3a706388466abec03921cb7d09010fa4ea18371376de283`.
- `orders`, `runsheets`, `order_details`, `run_sheet_details` كانت جميعها صفرًا عند الفحص. لذلك لا أدعي اختبار أوردر تشغيلي حقيقي.
- صلاحيات RPC `update_order_atomic` هي `postgres, service_role` فقط؛ لا يوجد EXECUTE لـ`anon` أو `authenticated`.
- المستهلك الحالي في `submitOrder` كان يعدّل `orders` ثم يحذف `order_details` ثم يعيد إدخالها بطلبات منفصلة؛ هذا مسار غير ذري ويتجاوز الـRPC المركزي.
- عيب إضافي في مسار التعديل: `_editOrderFromDetail` يضع `orders.customer_id` (UUID) في `selCust.customer_code`. لذلك فإن إرسال القيمة كما هي إلى RPC الذي يبحث بـ`customers.customer_code` يفشل عند تعديل أوردر موجود.

### Unknowns / Conflicts
- لم تتوفر جلسة مستخدم متصفح حقيقية لتنفيذ HTTP E2E من هذه البيئة.
- لم تُنشر جراحة الواجهة بعد؛ لذلك لا يمكن إثبات التطابق بين Frontend Production وGit ولا إغلاق تكامل التلي سيلز نهائيًا.
- لم يمكن قراءة محتوى `main.html` عبر أداة GitHub بسبب استجابة فارغة؛ لم يُعدل الملف ولم تُنسب إليه تفاصيل غير مثبتة.
- لا أعتبر اختبار SQL المعاملي بديلًا عن اختبار HTTP أو اختبار المتصفح.

## 1. Production work executed

### A. Existing Edge Function — update-order v6
تم تحديث الدالة الموجودة، دون إنشاء دالة جديدة، لتوحيد قرار التفويض بين Edge و`update_order_atomic`:
- جلب `role_id` من سجل `public.users`.
- دمج الصلاحيات المباشرة من `users.permissions` مع `roles.permissions` و`role_permissions.permission_key`.
- السماح بالتعديل عند وجود `*` أو `orders` أو `telesales` ضمن الصلاحيات الفعلية.
- الحفاظ على `verify_jwt=true` والتحقق من الشركة والفرع.
- Production v6: `ACTIVE`, `verify_jwt=true`, package SHA-256 `a1b06430b9d90777f7d9549286d9c64e7df009c5d15a19917ce6be096a00c8f3`.

تم حفظ المصدر الحالي المسترجع من Production في:
`Current/Edge_Functions/update-order` — blob SHA `a729c50a1f45fa78c4f5c86504f5c7fdb9ca18b3`، commit `c03a39d69ba8fc1cc9da8b7bd53368163d856e24`. الـblob SHA هو Git identity للملف، وليس مساويًا تلقائيًا لـProduction package SHA-256.

### B. PostgreSQL idempotency repair
أثبت فحص تعريف `update_order_atomic` وجود فحص idempotency قبل قفل الأوردر فقط. عند طلبين متزامنين بنفس `operation_id`، قد يجتاز الطلب الثاني الفحص الأول قبل اكتمال الأول ثم ينتظر قفل الأوردر، وبعده يعيد التنفيذ لأن الفحص لم يتكرر.

تمت إضافة إعادة فحص لسجل العمليات بعد `SELECT ... FOR UPDATE` وقبل تعديل الحالة أو التفاصيل. إذا اكتمل الطلب الأول، يرجع الثاني نفس النتيجة مع `duplicate=true` بدل إعادة كتابة التفاصيل.

- Migration: `20261009210000_fix_update_order_idempotency_after_order_lock.sql`.
- Commit: `54f5bfa7794878aa2771ca083eff8170c1e3851b`.
- تم تطبيق migration في Production.
- بعد التطبيق، أكد تعريف Production وجود الفحص الثاني، مع بقاء ACL محصورًا في `postgres/service_role`.

## 2. Runtime QA / Baseline

تم تنفيذ اختبار SQL معاملاتي باستخدام بيانات مرجعية موجودة في Production، مع إنشاء أوردر QA مؤقت داخل المعاملة:
1. استدعاء `update_order_atomic` أول مرة.
2. إعادة نفس الاستدعاء بنفس `operation_id`.
3. التحقق من نجاح الأول، و`duplicate=true` للثاني، وبقاء سطر تفاصيل واحد فقط.
4. تنفيذ `ROLLBACK`.

بعد الاختبار أُعيد فحص Production:
- `orders=0`
- `runsheets=0`
- `order_details=0`
- `run_sheet_details=0`
- QA registry residue = `0`
- QA audit residue = `0`

هذا يثبت سلامة اختبار المعاملة وتنظيف آثاره. **لا يثبت** اختبار تزامن متعدد الجلسات أو HTTP E2E أو Browser E2E.

## 3. التعديل الجراحي الأول — telesales.html

**الملف:** `erp-frontend/companies/company-1/sales/telesales.html`  
**SHA الحالي:** `d839ff043631d365be8eb2832ee98aa4fabcb43c`  
**الدالة:** `self.submitOrder = function() { ... };`  
**محدد البحث:** `// ==================== حفظ الأوردر ====================` ثم `self.submitOrder = function() {`  
**حد الاستبدال:** احذف الدالة كاملة حتى `};` الذي يسبق مباشرة `self._editOrderFromDetail = function(orderId)`، ثم استبدلها بالنص الكامل التالي.

هذا البديل يعالج أيضًا خطأ هوية العميل: يبحث أولًا بـ`customer_code`، وإذا كانت القيمة UUID قادمة من `orders.customer_id` يحلّها إلى `customer_code` الصحيح قبل استدعاء الـRPC.

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
    var customerCandidate = String(selCust.customer_code || selCust.id || '').trim();

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

    function resolveCustomerCode(callback) {
        if (!customerCandidate) {
            callback(null, 'كود العميل غير متوفر');
            return;
        }

        supabase.from('customers')
            .select('customer_code')
            .eq('customer_code', customerCandidate)
            .maybeSingle()
            .then(function(byCode) {
                if (byCode.error) {
                    callback(null, byCode.error.message);
                    return;
                }
                if (byCode.data && byCode.data.customer_code) {
                    callback(byCode.data.customer_code, null);
                    return;
                }

                // Edit flow currently seeds selCust.customer_code with orders.customer_id (UUID).
                // Resolve that UUID to the canonical customer_code before calling the atomic RPC.
                supabase.from('customers')
                    .select('customer_code')
                    .eq('id', customerCandidate)
                    .maybeSingle()
                    .then(function(byId) {
                        if (byId.error) {
                            callback(null, byId.error.message);
                            return;
                        }
                        if (!byId.data || !byId.data.customer_code) {
                            callback(null, 'العميل غير موجود ضمن الشركة');
                            return;
                        }
                        callback(byId.data.customer_code, null);
                    })
                    .catch(function(error) {
                        callback(null, error && error.message ? error.message : 'تعذر التحقق من العميل');
                    });
            })
            .catch(function(error) {
                callback(null, error && error.message ? error.message : 'تعذر التحقق من العميل');
            });
    }

    resolveCustomerCode(function(customerCode, customerError) {
        if (customerError || !customerCode) {
            finishFailure({ msg: customerError || 'تعذر تحديد العميل' }, null);
            return;
        }

        var header = {
            customer_code: customerCode,
            custName: selCust.name || '',
            area: selCust.area || '',
            total: totals.total,
            deliveryFees: totals.del,
            status: 'Confirmed',
            paymentType: selCust.payment_type || 'أجل',
            taxAmount: totals.tax,
            taxRate: taxRate,
            source: 'telesales'
        };

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
    });
};
```

**التأثير المتوقع:**
- الإنشاء يظل عبر `save-sales-invoice`.
- التعديل ينتقل إلى `update-order` ثم `update_order_atomic` داخل معاملة واحدة.
- لا يتم حذف وإعادة إدخال التفاصيل من الواجهة عبر طلبات مستقلة.
- لا يتغير المخزون نتيجة إنشاء/تعديل أوردر تلي سيلز.
- لا يُرسل UUID العميل في موضع يتطلب `customer_code`.

## 4. التعديل الجراحي الثاني — core.js

**الملف:** `erp-frontend/companies/company-1/core.js`  
**SHA الحالي:** `e853c49375ccc8b94757b594057dcd853b4a2fdb`  
**العنصر:** `var RW_Auth = (function() { ... })();`  
**محدد البحث:** `var RW_Auth = (function() {` حتى `})();` الذي يسبق مباشرة `// الوحدة ٢: RW_DB`.  
**الإجراء:** استبدل وحدة `RW_Auth` كاملة بالنص التالي. لا تنشرها إلى كل PWAs قبل اختبارها على التلي سيلز ثم بقية المستهلكين للنواة المشتركة.

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

**سبب التعديل:** المصدر الحالي يقرأ `isOwner` و`permissions` من `user_metadata` القابل للتغير، بينما الـEdge/RPC تعتمد بيانات `public.users`. البديل يربط الهوية عبر `auth.users.id → public.users.auth_id` ويغلق الدخول إذا تعذر التحقق من سجل المستخدم.

## 5. اختبار ما بعد تطبيق المالك

1. نفّذ JavaScript syntax check على `core.js` و`telesales.html`.
2. انشر الملفات من مسار النشر المعتمد، دون تعديل `main.html`.
3. سجل دخولًا بحساب تلي سيلز وتأكد من صلاحياته المحملة من DB.
4. أنشئ أوردرًا ثم تحقق من `orders` و`order_details).
5. عدّل أوردرًا غير مرتبط برانشيت، وتحقق من تحديث الرأس والتفاصيل ذريًا.
6. جرّب قيمة `customer_id` UUID في مسار التعديل وتأكد من حلها إلى `customer_code`.
7. جرّب مستخدمًا يملك صلاحية عبر الدور، ومستخدمًا بلا `orders/telesales/*`، وفرعًا خارج النطاق.
8. اربط أوردرًا مؤكدًا برانشيت عبر مسار الرانشيت القائم (`create-runsheet` أو `append-to-runsheet`) وتحقق من `orders.runsheet_id` و`run_sheet_details`.
9. تأكد أن إنشاء/تعديل الطلب لا يغير `stock_branches` أو `inventory_log`.
10. اختبر retry وduplicate من جلسة حقيقية، ثم قارن artifact المنشور مع Git.

## 6. Loss / Gain / Responsibility Matrix

| المسؤولية | الوضع السابق | الإجراء |
|---|---|---|
| إنشاء أوردر | Edge `save-sales-invoice` مركزي | RETAINED |
| تعديل أوردر | تحديث/حذف/إدخال مباشر متعدد الطلبات من PWA | MOVED إلى `update-order → update_order_atomic` عبر الجراحة المطلوبة |
| تفويض تعديل الأوردر | Edge يفحص صلاحيات المستخدم المباشرة فقط | HARDENED: direct + role permissions |
| منع إعادة تنفيذ الطلب المتزامن | فحص idempotency قبل قفل الأوردر فقط | HARDENED: إعادة فحص بعد قفل الأوردر |
| حركة المخزون | ليست مسؤولية إنشاء/تعديل أوردر التلي سيلز | RETAINED خارج هذا المسار |
| النظام الأم | لم يُعدل | RETAINED؛ لم يمكن قراءة محتواه الكامل عبر أداة GitHub في هذه الدورة |
| تطبيق التلي سيلز | لم يُعدل من المساعد | OWNER SURGERY PENDING |

## 7. SELF-AUDIT FINAL

**What I Proved**
- Production Edge `update-order` صار v6 و`verify_jwt=true`.
- التفويض في Edge أصبح يجمع الصلاحيات المباشرة وصلاحيات الدور.
- Production RPC يحتوي فحص idempotency ثانيًا بعد قفل الأوردر.
- ACL للـRPC ما زال محصورًا في `postgres/service_role`.
- اختبار RPC معاملاتي نجح ولم يترك صفوف QA.
- مصدر Edge الحالي محفوظ في المسار الرسمي `Current/Edge_Functions/update-order`.

**What I Did Not Prove**
- لم أثبت HTTP E2E بجلسة مستخدم حقيقية أو Browser E2E.
- لم أثبت الربط الفعلي للأوردر بالرانشيت بعد نشر جراحة الواجهة.
- لم أثبت تطابق Frontend Production مع Git بعد النشر.
- لم أقرأ محتوى `main.html` لأن أداة الجلب أعادت محتوى فارغًا.

**What I Fixed**
- تفاوت صلاحيات Edge عن عقد الدور في RPC.
- فجوة idempotency في إعادة الطلب بعد انتظار قفل الأوردر.

**What I Initially Missed**
- مسار التعديل الحالي يضع UUID العميل في `selCust.customer_code`; لذلك لا يكفي استبدال transport إلى RPC دون تطبيع هوية العميل. عولج هذا داخل بديل `submitOrder` دون تعديل الملف نفسه.

**What Could Still Be Wrong**
- أي سلوك واجهة أو صلاحيات محلية أخرى في التطبيقات المستهلكة لـ`core.js` حتى يتم نشره واختباره.
- HTTP/Browser integration وrunsheet linkage حتى ينفذ اختبار E2E بعد الجراحة.
- محتوى النظام الأم الداخلي لم يُثبت في هذه الدورة بسبب تعذر قراءة الملف كاملًا.

**Final Closure Status:** `BACKEND HARDENED / OWNER FRONTEND SURGERY PENDING / FULL TELESALES INTEGRATION NOT CLOSED`.

## تعليمات بداية الجلسة التالية
1. ابدأ بقراءة Production الحالي لـ`update-order` و`update_order_atomic`، ولا تعِد تطبيق migration أو نشر v6 دون مقارنة live state.
2. طبّق جراحة `submitOrder` أعلاه أولًا، ثم جراحة `RW_Auth` بعد مراجعة مستهلكي النواة المشتركة.
3. لا تعدّل `main.html` أو `telesales.html` مباشرة من المساعد.
4. بعد نشر المالك، نفّذ HTTP/Browser E2E حقيقيًا ثم اختبر إنشاء/تعديل/تكرار/تفويض/ربط رانشيت وعدم وجود أثر مخزني.
5. لا تعلن الإغلاق النهائي قبل إثبات Frontend Production + Git + DB + Runsheet consumer في نفس دورة التحقق.
