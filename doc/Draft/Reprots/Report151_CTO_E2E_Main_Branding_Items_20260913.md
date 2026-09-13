# Report151 — التحقيق الجنائي E2E للنظام الأم: Branding + Items

**التاريخ:** 2026-09-13  
**المرحلة:** E2E — `erp-frontend/companies/company-1/main.html`

## 1. المبدأ الحاكم

**Source of Truth الوحيد:**  
`https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`

المجلد `Current/PWA/main2` والملفات التاريخية استخدمت فقط للسياق التاريخي، وليس كمصدر للكود الحالي.

## 2. الواقع الحالي المثبت

تم فحص المصدر المنشور الحالي مباشرة. المصدر يحتوي على:

- `RW_SUPABASE_CLIENT` يعمل.
- `RW_Data.loadItems()` مقيدة بـ `RW_STATE.app.company.id`.
- Console المرفق يثبت:
  - `Bootstrap data loaded successfully`
  - `ITEMS COUNT = 17`
  - `CUSTOMERS COUNT = 3`
  - `BRANCHES COUNT = 2`
  - `APP_SETTINGS_RESULT` ناجح وبصف واحد.

إذن مشكلة الأصناف ليست غياب البيانات من Production.

## 3. ROOT CAUSE — تبويب الأصناف

في `main.html` الحالي حول السطر **1737** يوجد:

```javascript
    function _esc(s) {
    return esc(s == null ? '' : String(s));
}
```

لا يوجد تعريف قابل للوصول للدالة `esc` في المصدر الحالي.

الدالة نفسها مستخدمة في Rendering جدول الأصناف حول السطر **1956**، ولذلك يحدث:

```text
ReferenceError: esc is not defined
```

داخل:

```text
RW_Items._esc
→ _jsAttr
→ RW_Table.paginate
→ _renderTable
→ _applyFilters
→ _renderListView
→ render
```

وهذا يفسر بالكامل لماذا تصل الأصناف من Production ثم لا تظهر في الواجهة.

## 4. FIX-151-01 — إصلاح `_esc`

### ابحث عن المقطع الكامل الحالي

في الملف:

`companies/company-1/main.html`

ابحث عن:

```javascript
    function _esc(s) {
    return esc(s == null ? '' : String(s));
}
```

**احذف المقطع كاملًا واستبدله بالكامل بـ:**

```javascript
    function _esc(s) {
        return String(s == null ? '' : s)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }
```

**آخر سطر كامل للبديل:**

```javascript
    }
```

ولا تعدل `_jsString()` أو `_jsAttr()`.

## 5. سبب ظهور مشكلة اسم الشركة والشعار

في `enterSystem()` الحالي حول **السطور 969–1000** توجد قراءة:

```javascript
.from('app_settings')
.select('*')
.eq('company_id', RW_STATE.app.company.id)
```

ثم تحديث:

```javascript
row.company_name
row.company_logo
```

وهذا صحيح فقط عندما تكون `RW_STATE.app.company.id` مثبتة.

لكن في `boot()` الحالي، مسار Session Restore يضع:

```javascript
RW_STATE.app.company = {
    name: meta.companyName || 'الروائع ERP',
    logo: meta.companyLogo || 'ر'
};
```

ولا يضع:

```javascript
id
```

لذلك يوجد Defect حقيقي في Session Restore يؤثر على كل الـcompany-scoped reads وليس Branding فقط.

## 6. FIX-151-02 — تثبيت Company Context في Session Restore

داخل `function boot()`:

ابحث عن **المقطع الكامل** الذي يبدأ بـ:

```javascript
                RW_STATE.app.company = {
```

وينتهي مباشرة قبل:

```javascript
                RW_Auth.enterSystem();
```

احذفه بالكامل واستبدله بـ:

```javascript
                return RW_SUPABASE_CLIENT
                    .from('users')
                    .select('company_id, status')
                    .eq('auth_id', user.id)
                    .maybeSingle()
                    .then(function(profileRes) {
                        if (profileRes.error) throw profileRes.error;
                        if (!profileRes.data || !profileRes.data.company_id) {
                            throw new Error('بيانات سياق الشركة للمستخدم غير مكتملة');
                        }
                        if (profileRes.data.status === 'Inactive') {
                            throw new Error('حساب المستخدم غير نشط');
                        }

                        RW_STATE.app.company = {
                            id: profileRes.data.company_id,
                            name: meta.companyName || 'الروائع ERP',
                            logo: meta.companyLogo || 'ر'
                        };

                        RW_Auth.enterSystem();
                    });
```

لا تحذف `Session restored` ولا `currentUser` ولا `permissions`.

## 7. FIX-151-03 — تثبيت Branding من Production Settings

داخل `enterSystem()`:

ابحث عن المقطع الكامل الذي يبدأ بالسطر:

```javascript
        // تحديث اسم الشركة والشعار من الإعدادات (اختياري)
```

وينتهي قبل:

```javascript
        RW_Navigation.buildSidebar();
```

احذفه بالكامل واستبدله بـ:

```javascript
        // تحميل هوية الشركة من Production Settings بعد تثبيت company context
        RW_SUPABASE_CLIENT
            .from('app_settings')
            .select('company_name,company_logo,store_name,store_logo')
            .eq('company_id', RW_STATE.app.company.id)
            .order('created_at', { ascending: true })
            .limit(1)
            .then(function(r) {
                console.log('APP_SETTINGS_RESULT', r);

                if (!r || r.error) {
                    console.error(
                        'APP_SETTINGS_ERROR',
                        r && r.error ? r.error : 'unknown settings error'
                    );
                    return;
                }

                var row = r.data && r.data.length ? r.data[0] : null;
                var companyName = row && (
                    row.company_name ||
                    row.store_name
                );
                var companyLogo = row && (
                    row.company_logo ||
                    row.store_logo
                );

                companyName =
                    companyName ||
                    RW_STATE.app.company.name ||
                    'الروائع ERP';

                RW_STATE.app.company.name = companyName;
                RW_STATE.app.company.logo =
                    companyLogo ||
                    RW_STATE.app.company.logo ||
                    'ر';

                safeText(
                    byId('rw-sidebar-company-name'),
                    companyName
                );

                var logoImg = byId('rw-sidebar-brand-logo');

                if (logoImg) {
                    if (
                        companyLogo &&
                        /^(data:|https?:\/\/|blob:)/i.test(
                            String(companyLogo)
                        )
                    ) {
                        logoImg.src = String(companyLogo);
                        logoImg.alt = companyName;
                        logoImg.style.display = 'block';
                        logoImg.style.objectFit = 'contain';
                        logoImg.style.backgroundColor = '#f8fafc';
                    } else {
                        logoImg.removeAttribute('src');
                        logoImg.alt = companyName;
                    }
                }
            })
            .catch(function(e) {
                console.error('APP_SETTINGS_ERROR', e);
            });
```

هذا لا يخترع حقلًا جديدًا؛ يستخدم الحقول الموجودة في Production schema:
`company_name`, `company_logo`, `store_name`, `store_logo`.

## 8. Production verification

تم التحقق من Production schema بوجود:

```text
app_settings.company_name
app_settings.company_logo
app_settings.store_name
app_settings.store_logo
users.company_id
```

كما ثبت من Console أن Bootstrap يقرأ 17 صنفًا.

**لا توجد Migration مطلوبة لهذه المشكلة.**

## 9. E2E status

تم إثبات:

```text
Supabase initialization = PASS
Bootstrap items load = PASS
Items count = 17
Items rendering blocker = esc undefined / PROVEN
Session Restore company.id defect = PROVEN
Production settings schema = VERIFIED
```

لم يتم الادعاء بإغلاق Browser E2E بعد الإصلاح لأن هذه البيئة لا توفر جلسة متصفح تنفيذية لتسجيل الدخول والتنقل بعد تعديل الملف المنشور.

بعد تطبيق الجراحات يجب إعادة الاختبار بهذا الترتيب:

```text
Fresh Browser
→ Session Restore/Login
→ Company name/logo
→ Dashboard
→ Items
→ Items / list
→ Items / movement
→ Items / matrix
→ remaining sidebar routes
→ next actual Console error only
```

## 10. Assembly Governance

الحالة الحالية في `forensic_main_assembly.yml` كانت بالفعل تشير إلى:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
```

تم تحديد الحاجة إلى صياغة أوضح بحيث يكون:

```text
published main = current reconstruction authority
Current/PWA/main2 = historical fragments only
```

لكن تحديث ملف GitHub نفسه تعذر بسبب رفض طبقة أمان موصل GitHub، لذلك **لم يتم الادعاء بأن الملف تغير**.

## 11. Self-Audit

### What was proven

- الملف الحالي هو مصدر الحقيقة.
- 17 صنفًا تصل من Production.
- الخطأ `esc is not defined` هو سبب توقف Rendering للأصناف.
- `boot()` الحالي لا يثبت `company.id` أثناء Session Restore.
- `enterSystem()` يعتمد على `company.id` لقراءة الإعدادات.
- Production schema يحتوي حقول الهوية والشعار.

### What was not proven

- نجاح Browser E2E بعد تطبيق الجراحات.
- قيمة `company_name/company_logo` الفعلية الحالية من صف Production لم يتم الادعاء بها.

### Production changes

```text
SUPABASE MIGRATION = NONE
SUPABASE DATA REPAIR = NONE
```

### Final status

```text
ITEMS LOAD = PASS
ITEMS RENDER = BLOCKED
FIX-151-01 = READY
COMPANY SESSION CONTEXT = DEFECT PROVEN
FIX-151-02 = READY
BRANDING PATH = NEEDS FIX-151-03
FIX-151-03 = READY
BROWSER E2E = OPEN UNTIL OWNER DEPLOYS AND RETESTS
GOLD/DIAMOND = OPEN
```
