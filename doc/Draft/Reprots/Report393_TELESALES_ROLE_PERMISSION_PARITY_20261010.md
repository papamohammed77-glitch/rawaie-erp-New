# Report393 — مزامنة صلاحيات التلي سيلز مع النظام الأم والقلب المركزي
**التاريخ:** 2026-10-10  
**النطاق:** تكامل مصادقة التلي سيلز وصلاحيات المستخدمين الموروثة من الأدوار، مع عدم تعديل `main.html` أو `telesales.html`.  
**المستودع:** `papamohammed77-glitch/rawaie-erp-New`  
**مشروع Production:** Supabase `fiilmooggumokxanwiyx`.

## PRE-CHANGE SELF-AUDIT

| المجال | قبل التغيير | الدليل |
|---|---:|---|
| فهم دورة التلي سيلز والأوردر | 96/100 | قراءة `submitOrder` ومسار الإنشاء/التعديل وحالة الربط بالرانشيت |
| فهم عقد الصلاحيات | 86/100 | Production يضم صلاحيات مباشرة وصلاحيات أدوار، لكن المستهلكين لم يكونوا متسقين |
| Production synchronization | 95/100 | قراءة Edge الحالي وRPC وACL وعدادات Production في الجلسة نفسها |
| Source/Production provenance | 78/100 | اكتشاف أن Current `save-sales-invoice` أقدم من Production؛ صُحح أدناه |
| Consumer tracing | 88/100 | التلي سيلز يستخدم `RW_Auth` ثم `RW_API`; إنشاء الأوردر يمر بـ`save-sales-invoice` والتعديل بـ`update-order` بعد جراحة الواجهة |
| Runtime verification | 84/100 | اختبار RPC بحساب دور موروث داخل معاملة بلا تغييرات بيانات؛ لا يوجد HTTP/Browser E2E في هذه البيئة |
| Execution confidence | 91/100 | إصلاح backend منشور ومطابق للمصدر؛ تطبيق الواجهة ونشرها لا يزالان بيد المالك |

### Confirmed Facts

1. الملف الأم `erp-frontend/companies/company-1/main.html` بقي دون تعديل، Blob SHA: `4f94f9c6ebdde1b59632384628c72767d3bb950d`. أداة GitHub أعادت محتوى فارغًا حتى عند طلب نطاق أسطر؛ لذلك لا أنسب إليه سلوكًا لم أقرأه.
2. ملف التلي سيلز بقي دون تعديل، Blob SHA: `d839ff043631d365be8eb2832ee98aa4fabcb43c`.
3. النواة المشتركة بقيت دون تعديل، Blob SHA: `e853c49375ccc8b94757b594057dcd853b4a2fdb`.
4. Production `update-order`: v6، `ACTIVE`، `verify_jwt=true`، package SHA-256 `a1b06430b9d90777f7d9549286d9c64e7df009c5d15a19917ce6be096a00c8f3`.
5. قبل الإصلاح، Production `save-sales-invoice` كان v16 وبحجم مصدر 5,512 بايت؛ ملف `Current/Edge_Functions/save-sales-invoice` كان 2,228 بايت فقط. لذلك كان ملف Current لا يمثل Production.
6. استُعيد مصدر Production v16 كأساس، ثم أُضيف دمج صلاحيات `users.permissions` و`roles.permissions` و`role_permissions.permission_key` مع قصر الدور على الشركة نفسها. نُشرت الدالة القائمة نفسها دون إنشاء Edge Function جديدة.
7. الدالة `save_sales_invoice_atomic` موجودة في Production، و`update_order_atomic` هي المسار الذري لتعديل الأوردر. إنشاء/تعديل أوردر التلي سيلز ليس حركة مخزون مادية؛ الربط بالرانشيت يتم لاحقًا عبر دورة الرانشيت القائمة.
8. كان هناك مستخدمان نشطان على الأقل يحصلان على صلاحيات المبيعات من الدور دون وجود `orders` أو `telesales` في مصفوفة الصلاحيات المباشرة؛ لذلك فحص `users.permissions` وحده لا يكفي.

### Unknowns / Conflicts

- لا يمكن إعلان تكامل الواجهة مكتملًا قبل أن يطبق المالك الجراحة المحددة أدناه وينشر الواجهة.
- لم يتوفر في هذه البيئة مستدعي HTTP/Browser موثق لتنفيذ طلب مصادق عليه إلى Edge Function؛ لم أسمِّ اختبار SQL اختبار HTTP.
- توجد 13 مطابقة قديمة لكلمات QA/Test داخل سجلات التدقيق الخاصة بـorders/order_details/runsheets. جداول المعاملات نفسها فارغة الآن. أبقيت سجلات التدقيق كما هي لحفظ الأثر الجنائي؛ لم يثبت أنها بيانات تشغيلية قائمة، وحذفها سيمحو سجل الأحداث.

## 1. الإصلاحات المنفذة في Production

### 1.1 مزامنة `save-sales-invoice` مع Production

- الإصدار السابق: v16، `verify_jwt=true`.
- الإصدار المنشور الآن: **v17 ACTIVE**، `verify_jwt=true`.
- Production package SHA-256: `fee635a235a3f8e42db8f72e792bbf2a828fb6a444f082c59bc8e95c4fa9ddb1`.
- ملف المصدر الرسمي: `Current/Edge_Functions/save-sales-invoice`.
- Git Blob SHA الجديد: `9ee86c7ee8ed92c79fe37c209ac3392db63f3f87`.
- Commit: `aabaed938038d3dee934a01b5ee7a943594724a2`.
- بعد النشر، تمت مقارنة محتوى `index.ts` المسترجع من Production بملف Current؛ **المحتوى متطابق حرفيًا** (6,494 بايتًا).
- أبقيت `verify_jwt=true`، ولم أنشئ Edge Function إضافية.

**الجراحة الخلفية:** تمت إضافة `role_id` إلى قراءة سجل المستخدم ودمج:
- `public.users.permissions`
- `public.roles.permissions` للدور التابع إلى الشركة نفسها
- `public.role_permissions.permission_key`

ويستخدم قرار صلاحيات إنشاء المبيعات القائمة الناتجة عن الدمج، بدل رفض مستخدم صالح لأن الصلاحية موروثة من دوره فقط.

### 1.2 RPC مصادق عليه لملف المستخدم وصلاحياته الفعلية

أنشأت ونشرت `public.get_my_effective_profile()` من دون إنشاء Edge Function جديدة.

- Migration Production: `20261009220629_telesales_effective_profile_rpc_20261010`.
- ملف المصدر: `supabase/migrations/20261009220629_telesales_effective_profile_rpc_20261010.sql`.
- Commit ملف migration: `694f6a736d7215dd3d3f4c7a5af598c7b05fbc2c`.
- الدالة `SECURITY DEFINER` مع `search_path = ''` وكل الجداول مؤهلة بالـschema.
- لا تقبل user ID من العميل؛ الهوية الوحيدة هي `auth.uid()`، وتعيد ملف صاحب الجلسة فقط.
- تجمع الصلاحيات المباشرة وصلاحيات الدور وصلاحيات جدول `role_permissions`، وتعيد الشركة والفرع الافتراضي والفروع المسموحة والدور المخزني النشط.
- ACL بعد التطبيق: `anon EXECUTE=false`، `authenticated EXECUTE=true`. لا تعتمد على إخفاء الزر في الواجهة كوسيلة حماية.

### 1.3 اختبار Production للـRPC

أُجري اختبار قراءة داخل معاملة باستخدام هوية مستخدم لديه صلاحية مبيعات موروثة من الدور، من دون تعديل بيانات المستخدم أو المخزون أو الأوردرات. النتيجة:

- `profile_found=true`
- `company_context_present=true`
- `has_orders=true`
- `permission_count=30`
- `is_owner=false`

انتهت المعاملة بـ`ROLLBACK`. هذا يثبت أن الـRPC يقرأ صلاحيات الدور للمستخدم المصادق عليه في الاختبار؛ ولا يثبت HTTP/Browser E2E.

## 2. Baseline وتنظيف البيانات التجريبية

أُعيد فحص Production بعد النشر:

| الكيان | العدد |
|---|---:|
| `orders` | 0 |
| `order_details` | 0 |
| `runsheets` | 0 |
| `run_sheet_details` | 0 |
| سجلات `erp_operation_registry` لأنواع عمليات المبيعات/الرانشيت المحددة | 0 |

لا توجد بيانات تشغيلية تجريبية نشطة في جداول دورة الأوردر/الرانشيت. توجد 13 مطابقة قديمة لكلمات `test/QA` في `audit_log` تعود إلى أغسطس/سبتمبر؛ أبقيتها كسجل أحداث تاريخي ولم أحذفها عشوائيًا. لا تُعد هذه السجلات صفوفًا حية في جداول الأوردرات أو الرانشيتات.

## 3. التعديل الجراحي المطلوب من المالك — النواة المشتركة

**الملف:** `erp-frontend/companies/company-1/core.js`  
**Blob SHA الحالي:** `e853c49375ccc8b94757b594057dcd853b4a2fdb`  
**العنصر:** وحدة `RW_Auth` فقط.  
**محدد البحث:** `var RW_Auth = (function() {`  
**حد الاستبدال:** احذف الوحدة كاملة حتى `})();` الذي يسبق مباشرة التعليق `// الوحدة ٢: RW_DB`.  
**لا تحذف** تعليق `// الوحدة ٢: RW_DB` ولا تعدّل أي جزء من `RW_DB` أو `RW_API`.

استبدل الوحدة المحذوفة كاملة بالنص التالي. يعتمد هذا البديل على RPC المصادق عليه المنشور أعلاه، فلا يحتاج إلى قراءة جدول الأدوار مباشرة من العميل ولا إلى تعديل `main.html`:

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

    function clearState() {
        currentUser = null;
        currentProfile = null;
        currentSession = null;
        pubUserId = null;
    }

    function toClientUser(profile) {
        var p = profile || currentProfile || {};
        return {
            id: p.id || pubUserId || null,
            auth_id: p.auth_id || (currentUser ? currentUser.id : null),
            company_id: p.company_id || null,
            email: p.email || (currentUser ? currentUser.email : null),
            name: p.name || (currentUser ? currentUser.email : null),
            role: p.role || 'موظف',
            isOwner: p.isOwner === true || p.isOwner === 'true',
            permissions: normalizePermissions(p.permissions),
            activeWarehouseRole: p.active_warehouse_role || p.activeWarehouseRole || '',
            defaultBranchId: p.default_branch_id || null,
            allowedBranchIds: p.allowed_branch_ids || null,
            session: currentSession
        };
    }

    function hydrateProfile(callback) {
        if (!supabase || !currentUser || !currentUser.id) {
            if (callback) callback(null, 'جلسة غير صالحة');
            return;
        }

        supabase.rpc('get_my_effective_profile').then(function(result) {
            if (result.error) {
                if (callback) callback(null, 'تعذر تحميل ملف المستخدم وصلاحياته: ' + result.error.message);
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

            currentProfile = {
                id: profile.id,
                auth_id: profile.auth_id || currentUser.id,
                company_id: profile.company_id,
                email: profile.email || currentUser.email,
                name: profile.name || currentUser.email,
                role: profile.role || 'موظف',
                status: profile.status || 'Active',
                isOwner: profile.isOwner === true || profile.isOwner === 'true',
                permissions: normalizePermissions(profile.permissions),
                active_warehouse_role: profile.active_warehouse_role || '',
                default_branch_id: profile.default_branch_id || null,
                allowed_branch_ids: profile.allowed_branch_ids || null
            };
            pubUserId = profile.id;

            if (callback) callback(toClientUser(currentProfile), null);
        }).catch(function(error) {
            if (callback) callback(
                null,
                'فشل تحميل ملف المستخدم: ' +
                (error && error.message ? error.message : 'خطأ غير معروف')
            );
        });
    }

    function init(callback) {
        if (!supabase) {
            if (callback) callback(null, 'Supabase غير مهيأ');
            return;
        }

        supabase.auth.getSession().then(function(result) {
            if (!result.data || !result.data.session) {
                clearState();
                if (callback) callback(null, 'NO_SESSION');
                return;
            }

            currentSession = result.data.session;
            currentUser = result.data.session.user;
            hydrateProfile(callback);
        }).catch(function(error) {
            if (callback) callback(
                null,
                error && error.message ? error.message : 'فشل استعادة الجلسة'
            );
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
                        clearState();
                        if (callback) callback(null, error || 'تعذر تحميل صلاحيات المستخدم');
                    }).catch(function() {
                        clearState();
                        if (callback) callback(null, error || 'تعذر تحميل صلاحيات المستخدم');
                    });
                    return;
                }

                if (callback) callback(user, null);
            });
        }).catch(function(error) {
            if (callback) callback(
                null,
                error && error.message ? error.message : 'فشل تسجيل الدخول'
            );
        });
    }

    function doLogout(callback) {
        if (!supabase) {
            clearState();
            if (callback) callback(true);
            return;
        }

        supabase.auth.signOut().then(function() {
            clearState();
            if (callback) callback(true);
        }).catch(function(error) {
            console.error('فشل تسجيل الخروج:', error);
            clearState();
            if (callback) callback(false);
        });
    }

    function getUser() {
        if (currentProfile) return toClientUser(currentProfile);
        return {
            id: pubUserId,
            auth_id: currentUser ? currentUser.id : null,
            company_id: null,
            email: currentUser ? currentUser.email : null,
            name: currentUser ? (
                currentUser.user_metadata ? currentUser.user_metadata.name : currentUser.email
            ) : null,
            role: 'موظف',
            isOwner: false,
            permissions: [],
            activeWarehouseRole: '',
            session: currentSession
        };
    }

    function getToken() {
        return currentSession ? currentSession.access_token : null;
    }

    function checkPermission(permissionKey) {
        if (!currentProfile) return false;
        if (currentProfile.isOwner) return true;
        var permissions = normalizePermissions(currentProfile.permissions);
        if (permissions.indexOf('*') !== -1) return true;
        return permissions.indexOf(permissionKey) !== -1;
    }

    function hasWarehouseRole(roleName) {
        if (!currentProfile) return false;
        if (currentProfile.isOwner) return true;

        var activeRole = '';
        try {
            activeRole = window._rwActiveRole ||
                currentProfile.active_warehouse_role || '';
        } catch (error) {
            activeRole = currentProfile.active_warehouse_role || '';
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

**التأثير المتوقع:** يقرأ التلي سيلز ملف المستخدم والصلاحيات من مصدر واحد مصادق عليه، ويشمل صلاحيات الدور من دون منح العميل حق قراءة ملف مستخدم آخر. وتبقى صلاحيات الواجهة وسلوك النواة متوافقين مع واجهة `RW_Auth` الحالية.

## 4. التعديل الجراحي في ملف التلي سيلز

لا تعدّل الملف مباشرة من جهتي. في `telesales.html` استبدل الدالة كاملة:
- **محدد البحث:** `// ==================== حفظ الأوردر ====================` ثم `self.submitOrder = function() {`
- **نهاية الحذف:** `};` الذي يسبق مباشرة `self._editOrderFromDetail = function(orderId)`.
- **النص البديل الكامل:** استخدم كتلة `self.submitOrder` الواردة في Report392، القسم **3. التعديل الجراحي الأول — telesales.html**؛ لم يتغير عقدها في هذه الجلسة.
- **لا تلمس** `main.html` أو أي دالة أخرى في `telesales.html`.

تُبقي الجراحة إنشاء الأوردر على `save-sales-invoice`، وتحوّل التعديل إلى `update-order` الذري، وتحل UUID العميل إلى `customer_code` قبل الاستدعاء.

## 5. الاختبارات المطلوبة بعد تطبيق المالك للجراحة

1. تسجيل الدخول بمستخدم صلاحياته `orders/telesales` موروثة من الدور فقط.
2. تسجيل الدخول بمستخدم لديه الصلاحية مباشرة.
3. رفض مستخدم غير نشط أو لا يملك صلاحية.
4. إنشاء أوردر تلي سيلز بحالة `Confirmed` والتحقق من `source=telesales`، الشركة والفرع الصحيحين، وربط التفاصيل بالأصناف الصحيحة.
5. إثبات عدم حدوث `post_stock_movement` أو تعديل `qty/allocated_qty` عند إنشاء/تعديل أوردر تلي سيلز.
6. تعديل أوردر غير مرتبط برانشيت، وإعادة الطلب نفسه بنفس `operation_id`؛ يجب ألا تتكرر التفاصيل.
7. ربط الأوردر من دورة الرانشيت القائمة، والتحقق من `runsheet_id` و`run_sheet_details` وتحول الحالة إلى `Pending` وفق عقد الرانشيت.
8. رفض تعديل الأوردر بعد ربطه بالرانشيت.
9. اختبار عزل الشركة والفرع.
10. بعد نشر الواجهة، تنفيذ HTTP E2E حقيقي والتحقق من baseline وعدم بقاء بيانات اختبار.

## 6. Production baseline / Evidence

- `save-sales-invoice`: v17 ACTIVE، `verify_jwt=true`, SHA-256 `fee635a235a3f8e42db8f72e792bbf2a828fb6a444f082c59bc8e95c4fa9ddb1`.
- `update-order`: v6 ACTIVE، `verify_jwt=true`, SHA-256 `a1b06430b9d90777f7d9549286d9c64e7df009c5d15a19917ce6be096a00c8f3`.
- `get_my_effective_profile()`: موجودة في Production؛ `anon EXECUTE=false`, `authenticated EXECUTE=true`, `search_path=''`.
- جداول `orders/order_details/runsheets/run_sheet_details`: صفر صفوف عند إعادة التحقق بعد النشر.
- سجلات عمليات المبيعات/الرانشيت المحددة في `erp_operation_registry`: صفر صفوف.
- لا توجد أدلة HTTP/Browser E2E في هذه الجلسة؛ لم أدّعها.

## SELF-AUDIT FINAL

**What I Proved**
- مصدر `save-sales-invoice` في Current كان متأخرًا عن Production؛ تم تصحيحه إلى المصدر المنشور ثم إضافة دمج صلاحيات الأدوار ونشر v17.
- ملف Current يطابق محتوى Production v17 حرفيًا.
- RPC المصادق عليه يعيد ملف المستخدم نفسه وصلاحياته المباشرة والموروثة؛ اختبار مستخدم دور-فقط نجح بلا تغييرات بيانات.
- لا توجد صفوف تشغيلية متبقية في جداول الأوردرات والرانشيتات أو سجل عمليات المبيعات المحدد.

**What I Did Not Prove**
- لم أُثبت HTTP/Browser E2E بعد تطبيق جراحة الواجهة؛ الملف الأم والتلي سيلز لم يتغيرا.
- لم أزعم إغلاق تكامل الواجهة 100%.

**What I Fixed**
- Source/Production drift في `save-sales-invoice`.
- اختلاف التفويض بين الإنشاء والتعديل عندما تكون الصلاحية موروثة من الدور.
- غياب RPC آمن يعيد ملف المستخدم وصلاحياته الفعلية إلى التطبيقات.

**What I Initially Missed**
- ملف `Current/Edge_Functions/save-sales-invoice` كان أقصر من Production ولم يكن يمثل الإصدار الحي.
- صلاحيات الأدوار لم تكن ظاهرة في مسار تهيئة `RW_Auth` بالواجهة.

**What Could Still Be Wrong**
- أي خطأ في تطبيق جراحة `RW_Auth` أو `submitOrder` أو نشر نسخة واجهة غير محدثة.
- أي خلل يظهر فقط عبر HTTP/Browser أو في ربط الأوردر بالرانشيت الفعلي.

**Final Confidence:** backend authorization/source sync = high; end-to-end frontend integration = pending owner-side surgery and runtime proof.

**Final Closure Status:** `BACKEND FIXED AND VERIFIED / FRONTEND SURGERY PENDING / NOT 100% CLOSED`.
