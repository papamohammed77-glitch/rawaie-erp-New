# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13 08:39 UTC  
**Current checkpoint:** Report152 — CTO E2E Mother System Sidebar + Company Context + Branding forensic closure.

## CRITICAL GOVERNANCE PRINCIPLE

**لا أثق بالتقارير السابقة كحقيقة نهائية.**

الـSource of Truth الوحيد لاختبار النظام الأم هو الملف المنشور الحالي:

```text
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
```

`Current/PWA/main2` و`Original/PWA/main` والتقارير السابقة تستخدم فقط كسياق تاريخي وforensic clues، وليست مصدرًا للكود الحالي.

## Current Published Main Identity

```text
Repository = papamohammed77-glitch/erp-frontend
Branch = main
Latest branch commit = b29461b0bf5b3af6d387f39497e8e6cf95dfdbbd
Current main.html blob SHA = 59826d7197c5866294decddfef8df3c86f209d14
HTML source timestamp comment = 2026-09-13 08:30 UTC
Functional parent commit inspected = 1c212f98e89de4de2384080fef9c75c7d93b0e7e
Functional parent commit message = Refactor company identity loading from settings
```

آخر commit `b29461b...` غيّر timestamp فقط. الـfunctional regression المهمة ظهرت في الـparent `1c212f...` أثناء إعادة هيكلة Branding.

## Current State Reconciled Against Previous Reports

### Report150

Report150 كان يذكر أن `_cashFlow` مفقودة.

هذا أصبح **STALE** في المصدر الحالي: `_cashFlow()` موجودة فعليًا في `RW_Finance` الحالية وتستدعي Production RPC `get_cash_flow`.

لا يجوز إعادة تطبيق FIX-150.

### Report151

Report151 وثّق إصلاحات `_esc` وSession Restore وBranding، لكن المصدر الحالي تقدم بعدها.

الحالة الحالية:

```text
RW_Items._esc = CURRENTLY FIXED
boot() company.id = CURRENTLY PRESENT
enterSystem() Production Settings loading = CURRENTLY PRESENT
```

لكن Report151 لم يلتقط Regression أحدث: `RW_Navigation.buildSidebar()` تم حذفه من `enterSystem()` في commit `1c212f...`.

## PROVEN ROOT CAUSE — SIDEBAR

المسار الحالي داخل `enterSystem()` يحتوي:

```javascript
byId('rw-main-shell').style.display = 'flex';
```

ثم يبدأ تحميل الهوية والـbootstrap، لكنه لا ينفذ:

```javascript
RW_Navigation.buildSidebar();
```

بينما `rw-sidebar-nav` يعتمد على هذا الاستدعاء لملء القائمة.

Git diff من commit `1c212f...` يثبت أن السطر التالي حُذف صراحة أثناء Branding refactor:

```diff
-        RW_Navigation.buildSidebar();
```

والـhistorical `Current/PWA/main2/main1.md` يثبت أن `buildSidebar()` كان جزءًا من التسلسل الصحيح سابقًا.

### FIX-152-01

**Owner-only source change. Assistant did not modify main.html.**

ابحث في `companies/company-1/main.html` عن السطر الكامل حول line 951:

```javascript
        byId('rw-main-shell').style.display = 'flex';
```

أضف تحته مباشرة:

```javascript
        RW_Navigation.buildSidebar();
```

المنطقة النهائية المطلوبة:

```javascript
        byId('rw-login-page').style.display = 'none';
        byId('rw-main-shell').style.display = 'flex';
        RW_Navigation.buildSidebar();
        
        var user = RW_STATE.app.currentUser;
```

## PROVEN ROOT CAUSE — COMPANY CONTEXT COMPATIBILITY

الـcanonical state الحالي هو:

```javascript
RW_STATE.app.company.id
```

لكن وحدات مدمجة مثل Warehouse وFinance ما زالت تستخدم:

```javascript
RW_STATE.app.companyId
```

وهذا alias غير موجود في الـstate الحالي.

تم إثبات ذلك مباشرة في `main7.md` و`main8.md` وفي المصدر المنشور الحالي.

### FIX-152-02

**Owner-only source change.**

ابحث عن السطر الكامل:

```javascript
window.RW_STATE = RW_STATE;
```

أضف فوقه البلوك الكامل:

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

ثم يبقى:

```javascript
window.RW_STATE = RW_STATE;
```

دون تعديل.

هذا Compatibility Contract دائم يغلق التباين بين الوحدات المدمجة دون تكرار إصلاح عشرات الدوال، مع إبقاء `RW_STATE.app.company.id` هو canonical source.

## BRANDING — CURRENT PRODUCTION FACTS

Production `app_settings` للشركة الرئيسية حاليًا:

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
Company name data = PRESENT
Company logo data = ABSENT / NULL
```

و`enterSystem()` الحالي يقرأ حقول Branding المطلوبة بشكل صحيح بعد تثبيت Company Context.

لا يجوز وضع Logo ثابت داخل `main.html`.

إذا بقي الشعار فارغًا بعد FIX-152-01/02، فإن Closure التالي هو اختبار/إصلاح حفظ `company_logo` في تبويب إعدادات النظام والعقد الخلفي؛ وليس تعديل HTML لزرع قيمة ثابتة.

## FINANCE — CURRENT STATUS

`RW_Finance` الحالية تحتوي `_cashFlow()` بالفعل.

توجد قراءة مالية company-scoped عبر `_companyId()`، لكنها تعتمد على `RW_STATE.app.companyId`، وبالتالي كانت معرضة للفشل قبل FIX-152-02.

لا يوجد سبب لإعادة إصلاح `_cashFlow`.

## WAREHOUSE — CURRENT STATUS

الوحدة الحالية تحتوي بالفعل على:

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

المشكلة المثبتة الحالية ليست غياب هذه الوظائف، وإنما Company Context alias mismatch داخل عدد من الوظائف.

## SESSION RESTORE — CURRENT STATUS

`boot()` الحالي يقرأ `users.company_id` حسب `auth_id` ويضع:

```javascript
RW_STATE.app.company = {
    id: profileRes.data.company_id,
    name: meta.companyName || 'الروائع ERP',
    logo: meta.companyLogo || 'ر'
};
```

إذن Report151's `company.id` defect أصبح **CLOSED in current source**.

الـCompatibility alias فقط هو المطلوب الآن حتى تستفيد منه الوحدات التي ما زالت تقرأ `companyId`.

## PRODUCTION CHANGES IN REPORT152

```text
SUPABASE MIGRATION = NONE
SUPABASE DATA REPAIR = NONE
```

سبب عدم إجراء أي Production modification: schema والبيانات المطلوبة للمشكلة الحالية مثبتة وصحيحة، والمشكلة الحالية frontend orchestration/state compatibility.

## FORENSIC ASSEMBLY GOVERNANCE

`forensic_main_assembly.yml` verified directly and remains correct:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

لا تعديل مطلوب لهذا الملف.

## REPORTS CREATED / UPDATED

```text
doc/Draft/Reprots/Report152_CTO_E2E_Main_Sidebar_CompanyContext_20260913.md = CREATED
CURRENT_STATE.md = UPDATED
```

## FILES MODIFIED BY ASSISTANT

```text
rawaie-erp-New/doc/Draft/Reprots/Report152_CTO_E2E_Main_Sidebar_CompanyContext_20260913.md
rawaie-erp-New/CURRENT_STATE.md
```

```text
erp-frontend/companies/company-1/main.html = NOT MODIFIED BY ASSISTANT
```

## BROWSER E2E STATUS

لا يجوز إعلان Browser E2E PASS من هذه البيئة.

المثبت حاليًا:

```text
CURRENT GIT = VERIFIED
CURRENT SOURCE SHA = VERIFIED
SIDEBAR REGRESSION ROOT = PROVEN
COMPANY CONTEXT MISMATCH = PROVEN
SESSION RESTORE company.id = PRESENT
_CASHFLOW = PRESENT
BRANDING READ PATH = PRESENT
PRODUCTION branding row = VERIFIED
PRODUCTION logo fields = NULL
ASSEMBLY SOURCE = VERIFIED
```

المطلوب قبل الإغلاق النهائي:

```text
OWNER APPLY FIX-152-01
OWNER APPLY FIX-152-02
REDEPLOY SAME main.html
FRESH INCOGNITO
LOGIN / SESSION RESTORE
SIDEBAR
COMPANY IDENTITY
DASHBOARD
ITEMS
WAREHOUSE OPERATIONS
VOUCHERS
COUNTS
FINANCE
REPORTS
HR
CRM
CONSOLE
```

ثم تؤخذ **أول مشكلة Console جديدة فعلية فقط** كوحدة إغلاق تالية.

## GOLD / DIAMOND STATUS

```text
GLOBAL FUNCTIONAL COMPLETION = OPEN
FULL CROSS-MODULE E2E = OPEN
AUTH/SESSION = PARTIALLY VERIFIED
SIDEBAR = ROOT PROVEN / OWNER FIX PENDING
COMPANY CONTEXT = ROOT PROVEN / OWNER FIX PENDING
BRANDING = READ PATH VERIFIED / LOGO DATA NULL
FINANCE = CODE PRESENT / LIVE E2E PENDING
WAREHOUSE = CODE PRESENT / LIVE E2E PENDING
HR = CODE PRESENT / LIVE E2E PENDING
CRM = CODE PRESENT / LIVE E2E PENDING
PRODUCTION DATA REPAIR = NONE REQUIRED IN THIS CLOSURE
GOLD/DIAMOND = OPEN
```

## CRITICAL REPEAT

**لا أثق بالتقارير السابقة، ولا بالـCURRENT_STATE القديم، ولا بذاكرة المساعد.**

الحالة الحالية المعتمدة في هذه اللحظة مبنية من:

```text
CURRENT GIT
+
CURRENT SOURCE
+
GIT HISTORY
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
```

ولا تعتبر أي Closure مكتملة إلا بعد الـruntime/browser verification المقابل لها.
