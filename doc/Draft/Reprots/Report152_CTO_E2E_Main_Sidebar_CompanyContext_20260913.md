# Report152 — التحقيق الجنائي E2E للنظام الأم: Sidebar + Company Context + Branding

**التاريخ:** 2026-09-13  
**المرحلة:** E2E — `erp-frontend/companies/company-1/main.html`  
**الحالة:** Owner surgical fixes identified; Source-of-Truth file intentionally NOT modified by assistant.

---

## 1. المبدأ الحاكم — نقطة البداية وتتكرر هنا

**لا أثق بالتقارير السابقة كحقيقة نهائية.**

تم استخدام `Report151` و`Report150` و`CURRENT_STATE.md` و`MASTER CTO GOVERNANCE` كـforensic clues فقط، ثم تمت مطابقة الاستنتاجات مع:

- الملف المنشور الحالي فعليًا في `erp-frontend`.
- Git history والـcommit الأخير ذي الصلة.
- Production Supabase schema/data الحالية.
- الوحدات التاريخية المرجعية `Current/PWA/main2/main1.md` و`main7.md` و`main8.md`.
- بنية الـruntime الحالية حيث أمكن إثباتها من المصدر.

**قاعدة هذا التقرير:** `REPORT ≠ CURRENT STATE`. أي نقطة لم يثبتها المصدر الحالي لا تعتبر مغلقة.

---

## 2. Current Reality Snapshot

### Published Source of Truth

```text
Repository: papamohammed77-glitch/erp-frontend
Path: companies/company-1/main.html
Branch: main
Current blob SHA: 59826d7197c5866294decddfef8df3c86f209d14
Latest branch commit: b29461b0bf5b3af6d387f39497e8e6cf95dfdbbd
Latest commit message: Update timestamp comment in main.html
Current HTML timestamp comment: 2026-09-13 08:30 UTC
```

الـlatest branch commit غيّر timestamp فقط؛ وبالتالي الحالة الوظيفية المهمة في الملف الحالي جاءت من الـparent commit:

```text
1c212f98e89de4de2384080fef9c75c7d93b0e7e
Refactor company identity loading from settings
```

وهذا الـcommit هو نقطة التدقيق الأهم لأنه غيّر `enterSystem()` و`boot()` و`RW_Items._esc`.

---

## 3. لماذا كانت التقارير السابقة غير كافية للحالة الحالية

`CURRENT_STATE.md` كان لا يزال يذكر:

```text
Current SHA = 26a814...
_current runtime blocker = _cashFlow missing
Session Restore company.id defect = OPEN
```

لكن الملف المنشور الحالي صار:

```text
SHA = 59826d7197c5866294decddfef8df3c86f209d14
```

والمصدر الحالي يحتوي فعليًا على `_cashFlow()`، كما أن `boot()` الحالي يثبت `RW_STATE.app.company.id` من `users.company_id`.

إذن البنود السابقة في `CURRENT_STATE.md` أصبحت **STALE** ولا يجوز البناء عليها كحالة حالية.

---

## 4. ROOT CAUSE رقم 1 — اختفاء محتوى القائمة الجانبية

### المصدر الحالي

داخل `enterSystem()`، بعد:

```javascript
byId('rw-main-shell').style.display = 'flex';
```

ينتقل الكود مباشرة إلى:

```javascript
var user = RW_STATE.app.currentUser;
```

ولا يوجد في هذا المسار:

```javascript
RW_Navigation.buildSidebar();
```

بينما `rw-sidebar-nav` في HTML هو container فارغ يعتمد على `buildSidebar()` لملء القائمة.

### إثبات تاريخي مباشر

في `Current/PWA/main2/main1.md`، كان التسلسل التاريخي الصحيح داخل `enterSystem()` يتضمن:

```javascript
RW_Navigation.buildSidebar();
RW_Workflow.loadRules();
RW_Notification.init();
```

وفي fallback الحالي أيضًا توجد:

```javascript
RW_Navigation.buildSidebar();
RW_Navigation.navigate('dashboard');
```

### Root Cause التاريخي

الـcommit:

```text
1c212f98e89de4de2384080fef9c75c7d93b0e7e
```

حذف صراحة من `enterSystem()`:

```diff
-        RW_Navigation.buildSidebar();
```

أثناء إعادة هيكلة تحميل هوية الشركة من `app_settings`.

**إذن اختفاء القائمة ليس مشكلة CSS أو صلاحيات مثبتة من Production؛ إنه Regression مباشر في orchestration بعد حذف الاستدعاء.**

---

## 5. Owner Surgical Fix — SIDEBAR

**ملف التنفيذ:** `erp-frontend/companies/company-1/main.html`  
**الassistant لا يعدل هذا الملف.**

### ابحث عن السطر الحالي عند السطر 951 تقريبًا

ابحث عن هذا السطر الكامل:

```javascript
        byId('rw-main-shell').style.display = 'flex';
```

### أضف فوق السطر التالي مباشرة

```javascript
        RW_Navigation.buildSidebar();
```

أي أن المنطقة يجب أن تصبح:

```javascript
        byId('rw-login-page').style.display = 'none';
        byId('rw-main-shell').style.display = 'flex';
        RW_Navigation.buildSidebar();
        
        var user = RW_STATE.app.currentUser;
```

**لا تحذف أي سطر آخر في هذه المنطقة.**

السبب في اختيار هذا الموضع أنه يضمن بناء الـsidebar في كل `enterSystem()` ناجح، قبل بدء الـbootstrap، ولا يعتمد على نجاح `app_settings` أو `RW_Data`.

---

## 6. ROOT CAUSE رقم 2 — Company Context بين الوحدات المدمجة

### Canonical state الحالي

الملف الحالي يعرّف:

```javascript
const RW_STATE = {
    app: {
        initialized: false,
        authenticated: false,
        loading: false,
        currentView: 'dashboard',
        currentUser: null,
        company: {
            id: null,
            name: 'الروائع ERP',
            logo: 'ر'
        }
    },
    ...
};
```

إذن الـcanonical Company Context الحالي هو:

```text
RW_STATE.app.company.id
```

### ولكن الوحدات التاريخية المدمجة لا تزال تعتمد على alias قديم

ثبت من `main7.md` و`main8.md` أن وحدات Warehouse وFinance تستخدم:

```javascript
RW_STATE.app.companyId
```

ومثال Finance الحالي:

```javascript
function _companyId() {
    var id = null;
    if (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.app) {
        id = RW_STATE.app.companyId || null;
    }
    if (!id && typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.user) {
        id = RW_STATE.user.companyId || null;
    }
    if (!id) throw new Error('سياق الشركة غير محدد');
    return id;
}
```

وفي Warehouse توجد قراءات مباشرة متعددة من:

```javascript
RW_STATE.app.companyId
```

بينما `RW_STATE.app.companyId` غير موجود في الـstate الحالي.

### الأثر الوظيفي المثبت من المصدر

هذا يفسر مباشرة:

```text
Warehouse receiving = company context missing
Warehouse vouchers = company context missing
Inventory/counting = company context missing
Finance = company context missing
```

ولا يلزم تعديل كل دالة على حدة ما دام لدينا Compatibility Contract واحد واضح.

---

## 7. Owner Surgical Fix — COMPANY CONTEXT COMPATIBILITY CONTRACT

**المطلوب هو إضافة alias دائم، وليس نسخ company context في عشرات الدوال.**

### ابحث عن السطر الحالي عند السطر 877 تقريبًا

```javascript
window.RW_STATE = RW_STATE;
```

### أضف فوقه مباشرة العنصر الكامل التالي

```javascript
Object.defineProperty(RW_STATE.app, 'companyId', {
    configurable: true,
    enumerable: true,
    get: function() {
        return this.company && this.company.id ? this.company.id : null;
    },
    set: function(value) {
        if (!this.company) {
            this.company = {
                id: null,
                name: 'الروائع ERP',
                logo: 'ر'
            };
        }
        this.company.id = value || null;
    }
});
```

ثم اترك السطر:

```javascript
window.RW_STATE = RW_STATE;
```

كما هو بعده.

### الوضع النهائي للجزء

```javascript
const RW_STATE = { app: { initialized: false, authenticated: false, loading: false, currentView: 'dashboard', currentUser: null, company: { id: null, name: 'الروائع ERP', logo: 'ر' } }, data: { items: [], customers: [], suppliers: [], branches: [] }, permissions: [], ui: { sidebarOpen: false, sidebarCollapsed: false } };
Object.defineProperty(RW_STATE.app, 'companyId', {
    configurable: true,
    enumerable: true,
    get: function() {
        return this.company && this.company.id ? this.company.id : null;
    },
    set: function(value) {
        if (!this.company) {
            this.company = {
                id: null,
                name: 'الروائع ERP',
                logo: 'ر'
            };
        }
        this.company.id = value || null;
    }
});
window.RW_STATE = RW_STATE;
```

**لا تعدل `_companyId()` في Finance ولا كل `RW_Warehouse` functions يدويًا.** هذا الـcompatibility bridge يغلق الـcontract mismatch في نقطة واحدة، ويحافظ على `RW_STATE.app.company.id` كالمصدر canonical.

---

## 8. Login وSession Restore

### Login path الحالي

الـlogin الحالي صحيح في هذه النقطة:

```javascript
RW_STATE.app.company = {
    id: profileRes.data.company_id,
    name: meta.companyName || 'الروائع ERP',
    logo: meta.companyLogo || 'ر'
};
```

### Session Restore path الحالي

الـboot الحالي صحيح أيضًا في هذه النقطة:

```javascript
RW_STATE.app.company = {
    id: profileRes.data.company_id,
    name: meta.companyName || 'الروائع ERP',
    logo: meta.companyLogo || 'ر'
};
```

لذلك **لا تعيد تطبيق FIX-151-02**؛ ذلك الإصلاح موجود بالفعل في النسخة الحالية.

---

## 9. Branding — الحالة الفعلية في Production

تم فحص `app_settings` في Production للشركة:

```text
company_id = 00000000-0000-0000-0000-000000000001
company_name = الروائع
store_name = الروائع
company_logo = NULL
store_logo = NULL
main_branch_id = a38332b6-6cea-480a-ada1-6eb6ab0590db
```

إذن:

```text
Company Name data = موجود
Company Logo data = غير موجودة حاليًا
```

والـ`enterSystem()` الحالي يقرأ بشكل صحيح:

```javascript
company_name
company_logo
store_name
store_logo
```

ويقيد القراءة بـ:

```javascript
.eq('company_id', RW_STATE.app.company.id)
```

لذلك **لا توجد Production Migration مطلوبة للـbranding logic**.

لا يجوز إدخال logo ثابت داخل `main.html`؛ ذلك سيكسر عقد أن الهوية ديناميكية من `app_settings`.

بعد إصلاح Company Context وSidebar، إذا بقي الشعار فارغًا فالمطلوب هو اختبار تبويب إعدادات النظام وحفظ قيمة `company_logo` الفعلية من خلال العقد الحالي، وليس زرع قيمة ثابتة في المصدر.

---

## 10. Finance — ما الذي تم إثباته

`RW_Finance` الحالي يحتوي على `_cashFlow()` فعلًا، وبالتالي تقرير150 القديم الذي كان يعد `_cashFlow` مفقودة أصبح **STALE**.

النسخة الحالية تحتوي:

```javascript
function _cashFlow() {
    ...
    supabase.rpc('get_cash_flow', {
        p_from_date: fromDate,
        p_to_date: toDate
    })
```

وتحتفظ بالـreturn capability الخاصة بها.

لذلك لا تعيد FIX الخاصة بالتدفقات النقدية.

العطل الحالي في Finance ليس `_cashFlow`؛ هو Company Context alias.

---

## 11. Operations / Warehouse — ما الذي تم إثباته

`RW_Warehouse` الحالي يحتوي فعليًا على:

```text
Receiving
Picking
Loading
Delivery
Return
Unloading
Manual Vouchers
Inventory Counts
Settlement
```

والواجهات موجودة وليست مجرد menu placeholders.

لكن بعض عملياتها تعتمد على:

```javascript
RW_STATE.app.companyId
```

بدل:

```javascript
RW_STATE.app.company.id
```

وبذلك فالخلل الحالي **تكامل حالة الشركة داخل الوحدات المدمجة** وليس غياب الوظائف نفسها.

مثال مثبت مباشرة:

```javascript
loadReceiving()
_showReceivingDetails()
_loadVoucherEntityOptions()
loadVouchers()
_viewVoucherDetails()
_saveVehicleCount()
_saveInvCount()
_saveGeneralCount()
```

وتوجد قراءات إضافية لـ`companyId` في وحدة Warehouse.

---

## 12. Production — لا يوجد تعديل مطلوب في هذه الجولة

بعد مطابقة المشكلة مع Production الحالية:

```text
app_settings schema = valid
users.company_id = available
company-scoped settings row = available
main branch = available
get_cash_flow = available
```

ولا توجد في هذه الجولة حاجة إلى:

```text
CREATE TABLE
ALTER TABLE
NEW COMPANY ROW
NEW LOGO COLUMN
NEW RPC
DATA REPAIR
```

أي تعديل Production غير متعلق بالمشكلة الفعلية سيكون غير مبرر، ولذلك لم يتم تنفيذه.

---

## 13. forensic_main_assembly.yml

تم فتح الملف الفعلي وهو بالفعل صحيح:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
```

والملف يعلن:

```yaml
assembly_status: reference_only; published_main_is_authoritative
```

إذن لا يوجد تعديل مطلوب في `forensic_main_assembly.yml`.

---

## 14. ما لم أفعله عمدًا

لم أعدّل:

```text
erp-frontend/companies/company-1/main.html
```

لأن هذا الملف Source of Truth وملكية تعديلاته للمستخدم حسب العقد التشغيلي للجلسة.

ولم أعد تطبيق:

```text
FIX-149 Syntax
FIX-150 _cashFlow
FIX-151-02 Session Restore company.id
FIX-151-03 Branding loader
```

لأن المصدر الحالي يثبت أنها إما مطبقة بالفعل أو لم تعد هي العطل الحالي.

---

## 15. Browser E2E Reality

لم يتم ادعاء `Browser E2E = PASS` لأن بيئة التنفيذ الحالية لا توفر جلسة متصفح مصادق عليها بالمستخدم الفعلي ولا تسمح للـassistant بإدخال بيانات اعتماد المالك.

المتاح الذي تم إثباته:

```text
Current Git source = VERIFIED
Current SHA = VERIFIED
Regression commit = VERIFIED
Sidebar root cause = PROVEN
Company context mismatch = PROVEN
Current session restore company.id = PRESENT
Current _cashFlow = PRESENT
Production app_settings = VERIFIED
Production logo fields = NULL
Assembly source of truth = VERIFIED
```

لذلك حالة الـBrowser E2E بعد تطبيق جراحات المستخدم تبقى:

```text
PENDING OWNER DEPLOY + FRESH INCognito RETEST
```

---

## 16. Exact Owner Execution Order

نفذ التعديلات في نفس الملف وبالترتيب التالي:

### FIX-152-01 — Sidebar

ابحث عن:

```javascript
        byId('rw-main-shell').style.display = 'flex';
```

ثم أضف فوق:

```javascript
        RW_Navigation.buildSidebar();
```

### FIX-152-02 — Company Context Compatibility

ابحث عن:

```javascript
window.RW_STATE = RW_STATE;
```

وأضف فوقه **بلوك `Object.defineProperty` الكامل الموجود في هذا التقرير**.

### لا تنفذ أي Fix آخر من التقارير السابقة الآن.

بعد ذلك يجب نشر **نفس**:

```text
companies/company-1/main.html
```

ثم اختبار:

```text
Fresh Incognito
→ Login
→ Session restored
→ Sidebar visible + populated
→ Company name visible
→ Company logo path checked
→ Dashboard
→ Items
→ Receiving
→ Vouchers
→ Inventory Counts
→ Finance
→ Reports
→ HR
→ CRM
→ Console
```

ثم **أول Console error جديد فقط** يكون هو Closure Unit التالية.

---

## 17. Self-Audit — What was proven

```text
1. Current Source of Truth = proven.
2. Current Git SHA = proven.
3. Last functional regression commit = proven.
4. Sidebar removal from enterSystem = proven from Git diff.
5. Historical main1 contains the missing buildSidebar call = proven.
6. Canonical company.id exists in login and boot = proven.
7. Finance and Warehouse still read legacy companyId alias = proven.
8. app_settings current row and logo NULL state = proven.
9. _cashFlow currently exists = proven.
10. forensic_main_assembly.yml is already correct = proven.
```

## 18. Self-Audit — What was NOT proven

```text
1. Authenticated browser E2E after owner edits.
2. Actual visual logo rendering after a real logo is saved in Settings.
3. Full functional click-through of every downstream HR/CRM/reporting capability in a live browser.
```

هذه البنود لا يجوز تحويلها إلى PASS قبل تنفيذها فعليًا.

---

## 19. Final Closure Status

```text
SIDEBAR ROOT CAUSE = PROVEN
SIDEBAR FIX = OWNER READY
COMPANY CONTEXT ROOT CAUSE = PROVEN
COMPANY CONTEXT FIX = OWNER READY
SESSION RESTORE = CURRENTLY CORRECT
_CASHFLOW = CURRENTLY PRESENT
BRANDING READ PATH = CURRENTLY CORRECT
PRODUCTION LOGO DATA = NULL
FORENSIC ASSEMBLY SOURCE = CORRECT
SUPABASE CHANGE = NONE REQUIRED
SUPABASE DATA REPAIR = NONE REQUIRED
BROWSER E2E = OPEN
GOLD/DIAMOND = OPEN
```

## 20. Important repeated rule

**لا أثق بالتقارير السابقة ولا أعتبرها الحالة الحالية.**

الحالة المعتمدة في هذه الجلسة هي فقط ما تم إثباته من:

```text
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
```

وأي Closure لاحق يجب أن يبدأ من هذا الأساس ولا يعيد إصلاح ما ثبت أنه أصلح بالفعل.
