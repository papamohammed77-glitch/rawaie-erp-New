# RAWAEA ERP — Report 252
# إدارة التراخيص — التحقيق الجنائي والتعديل الجراحي وإغلاق عقد Production
## 2026-09-19

---

## 1. نطاق المهمة

هذه الجلسة محصورة في **إدارة التراخيص Owner License Management** داخل النظام الأم.

تم استبعاد:
- تبويب التقارير الشاملة من أي تعديل.
- `main.html` من أي كتابة مباشرة.
- العمليات المخزنية، Picker، Runsheet، Delivery، Purchase، Accounting، CRM، HR وأي عقد أغلقته تقارير سابقة ما لم يظهر دليل مباشر داخل عقد الترخيص يفرض تأثيرًا عليها.

الهدف ليس إضافة شاشة جديدة فقط؛ الهدف إغلاق العقد الوظيفي للتراخيص على مستوى المنظومة، مع الحفاظ على التطبيقات التشغيلية المنفصلة وعدم كسر أي عقد تشغيلي قائم.

---

## 2. قاعدة الحقيقة المستخدمة

تم تطبيق قاعدة:
**CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE**

التقارير السابقة استُخدمت كخريطة تاريخية فقط، ولم تُعامل كحالة حالية.

تمت قراءة:
1. `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` حتى النهاية.
2. `CURRENT_STATE.md` حتى النهاية قبل بدء الجراحة.
3. أحدث سلسلة التقارير ذات الصلة بالحالة حتى Report 251:
   - Report 247 — Users Runtime Parser.
   - Report 248 — Roles Page.
   - Report 249 — Roles Current Reconciliation.
   - Report 250 — System Settings.
   - Report 251 — System Settings Current Runtime.
4. تاريخ Mother وSystem Git، مع مراجعة الـparent chain.
5. Production PostgreSQL وfunctions وRLS وgrants وtriggers وdeployment state.

### ملاحظة من Reports 238–241
تقارير Comprehensive Reports الموجودة قبل هذه الجلسة تاريخية، ولم يتم فتح عقدها أو تعديلها لأن النطاق التنفيذي الحالي هو إدارة التراخيص فقط.

---

## 3. Current Git — System Repository

Repository:
`papamohammed77-glitch/rawaie-erp-New`

آخر HEAD قبل التقرير:
`894e23762d756e675be881b5ed83e761542b8096`

Parent:
`235a936df56e926e39a1d47563983657ea2ef8d8`

آخر سلسلة commits نفذت في هذه الجلسة:

| Commit | المسؤولية |
|---|---|
| `28ab9573977aa036f09e4f524493db774dd60314` | إنشاء عقد Owner License الأول |
| `441d8225425bdca4e34fa758952eb649e16cb1c3` | تثبيت إصلاح audit contract |
| `235a936df56e926e39a1d47563983657ea2ef8d8` | إغلاق execution surface لدوال الترخيص |
| `894e23762d756e675be881b5ed83e761542b8096` | مطابقة Current save-settings مع Production deployment v15 |

---

## 4. Current Git — Mother Repository

Repository:
`papamohammed77-glitch/erp-frontend`

Current Mother HEAD:
`80ef33e620dc1797f463b836d15651bdf0041761`

Parent:
`ed7147bcf1e8aea00ee239a52f6bb09154453240`

Mother current `main.html`:
- Path: `companies/company-1/main.html`
- Blob SHA: `951e1de989203449fd5ee52e736a70f5480249a1`
- Lines: 27,032
- File SHA256 المثبت في forensic extract:
  `7ac9907eb5536ff0ad9a7c60a3f7b79d0b6abd22369895b879cf7ff9966c5151`

**main.html لم يتم تعديله بواسطة CTO في هذه الجلسة.**

---

## 5. Historical Reconstruction — لماذا وصل Owner License إلى هذا الشكل؟

### 5.1 Original / Legacy

الإصدارات التاريخية القديمة كانت تتعامل مع `app_settings` أحيانًا بـglobal lookup مثل `LIMIT 1` دون إثبات Company Context.

هذا البناء أصبح غير مقبول بعد انتقال النظام إلى multi-company/tenant-safe contracts.

### 5.2 Main2

تاريخ `Current/PWA/main2/main10.md` يثبت أن Owner License أصبح:
- owner-only route.
- يحتاج Company Context حقيقي.
- لا يستخدم fake/default license record.
- يعتمد على بيانات Production الفعلية.

### 5.3 New-main / canonical Owner contract

التاريخ المثبت في commits السابقة يثبت أن OWNER ليس مجرد role text.
العقد التاريخي:
- `isOwner = true`
- `permissions = ["*"]`
- وجود `owner_profile`
- سلامة حالة license/auth

### 5.4 Current Mother

Current `RW_OwnerLicense` صار صفحة فعلية وليست Modal في المصدر الحالي، لكنه بقي محدودًا في:
- قراءة `app_settings` للشركة الحالية فقط.
- محاولة استخدام `owner_email` من `app_settings`.
- حفظ ثلاث قيم license فقط عبر `save-settings`.

وبالتالي حل مشكلات Company Context السابقة أُنجز، لكن عقد **Platform Owner License Administration** نفسه لم يُبنَ.

---

## 6. Root Cause — المشكلة المثبتة

### ROOT CAUSE A — خطأ Source/Schema

Current Mother block يحاول استخراج:
`owner_email`
من:
`app_settings`

Production schema لـ`app_settings` **لا يحتوي** `owner_email`.

الهوية الصحيحة المثبتة للمالك موجودة في:
`owner_profile.owner_email`

إذن:
**Current RW_OwnerLicense لا يمكنه بناء هوية المالك كاملة من العقد الذي يقرأه.**

### ROOT CAUSE B — نقص Business Contract

Production قبل هذه الجلسة لم يكن فيها:
- جدول Company License مستقل.
- RPC مركزي لإدارة تراخيص الشركات.
- endpoint مركزي لـ list/detail/save على مستوى كل الشركات.

الإدارة كانت مرتبطة بحالة `app_settings` الحالية للشركة فقط.

### ROOT CAUSE C — UI Contract ناقص

الصفحة الحالية لا تحتوي:
- Company Directory.
- اختيار شركة وإدارة تفاصيلها.
- License Registry.
- Runtime projection.
- مؤشرات الشركة.
- Audit history للتغييرات.
- حقول plan/billing/start/end/grace.

### ROOT CAUSE D — عدم وجود separation صريح بين:

**Owner Identity**

و

**Company Runtime License**

Production تثبت أن:
- `owner_profile` عالمي للمالك ولا يحتوي `company_id`.
- `app_settings` مرتبط بالشركة.
- لذلك لا يجوز دمجهما في سجل واحد.

الحل الصحيح هو الحفاظ على الاثنين مع إنشاء Company License Registry مستقل.

---

## 7. Current Production — قبل/بعد الجراحة

### قبل البنية الجديدة

Production كان يحتوي:
- `companies`
- `app_settings`
- `owner_profile`
- `users`

ولم يكن هناك License Registry مستقل.

### بعد الجراحة

تم إنشاء:

`public.company_licenses`

بهوية الشركة:

`company_id → companies.id`

والحقول:

| الحقل | الحالة |
|---|---|
| `plan_code` | implemented |
| `license_status` | implemented |
| `trial_start_date` | implemented |
| `trial_end_date` | implemented |
| `subscription_start_date` | implemented |
| `subscription_end_date` | implemented |
| `grace_end_date` | implemented |
| `billing_cycle` | implemented |
| `notes` | implemented |
| `created_by` / `updated_by` | implemented |
| timestamps | implemented |

Current Production after migration:

- companies = 1
- company_licenses = 1
- valid company license rows = 1
- Company = `MAIN / الروائع`
- runtime status = `trial`
- company license status = `trial`
- plan = null

لم يتم اختراع بيانات اشتراك أو خطة حقيقية.

---

## 8. Production Architecture الجديدة

تم إنشاء RPC:

`public.owner_license_admin_atomic`

التوقيع:

`p_action text,
p_company_id uuid,
p_actor_user_id uuid,
p_actor_auth_id uuid,
p_actor_email text,
p_payload jsonb`

### Actions

- `list`
- `detail`
- `save`

### Owner Guard

تم فرض المطابقة:

`users.auth_id = authenticated user`

+

`users.email = authenticated email`

+

`owner_profile.auth_user_id = authenticated user`

+

`users.permissions contains "*"`

ولا يُسمح بأي operation بدون هذا العقد.

### Execution surface

`owner_license_admin_atomic`

- SECURITY DEFINER
- لا توجد EXECUTE grants للـPUBLIC
- لا توجد EXECUTE grants لـanon
- لا توجد EXECUTE grants لـauthenticated
- التنفيذ مقصور على service_role

---

## 9. Runtime Projection

الصفحة الجديدة لا تجعل `company_licenses` جزيرة مستقلة.

عند Save:

`company_licenses`

يتم تحديثه أولًا داخل نفس Transaction ثم تُسقط القيم التشغيلية الحالية إلى:

`app_settings.status`

`app_settings.trial_end_date`

`app_settings.subscription_end_date`

وبالتالي التطبيقات الحالية التي تعتمد على `app_settings` لا تحتاج إلى إعادة بناء عقودها التشغيلية.

كما تم إنشاء trigger:

`trg_sync_company_license_from_app_settings`

للحفاظ على المزامنة إذا غُيرت حقول runtime بواسطة المسار الرسمي.

---

## 10. Security Closure

تم إنشاء trigger حماية:

`trg_guard_app_settings_license_fields`

لحماية:
- `status`
- `trial_end_date`
- `subscription_end_date`

وتأكدت Production أن هذه الحماية لا تفتح الطريق لغير المالك.

كما تم إغلاق EXECUTE السطحي لدوال trigger الأمنية الجديدة:

- `guard_app_settings_license_fields()`
- `sync_company_license_from_app_settings()`

حتى لا تظهر كـpublic RPC capabilities غير مقصودة.

### Advisor verification

بعد الإصلاح لم تعد دوال License الجديدة تظهر ضمن:

`anon_security_definer_function_executable`

أو:

`authenticated_security_definer_function_executable`

الملاحظات المتبقية في Advisor تخص دوال/جداول أخرى خارج هذا العقد ولا تمس إدارة التراخيص.

---

## 11. Audit Contract

Production `audit_log` يفرض Action Contract محدودًا:

- create
- update
- delete
- login
- logout
- failed_login

لذلك تم الالتزام بـ`update` بدل اختراع action جديد.

الـSave الجديد:
- يسجل التغيير عند وجود فرق حقيقي.
- لا ينشئ audit noise للـnoop.
- يعيد Detail بعد الحفظ.

---

## 12. Existing Edge Function — لماذا لم تُنشأ Function جديدة؟

Production وصلت فعليًا إلى حد عدد Edge Functions المسموح به.

بدل إنشاء Function ثالثة لمسؤولية مماثلة، تم توسيع capability داخل:

`save-settings`

مع الحفاظ على المسار القديم.

الـAPI الجديد:

```json
{
  "action": "license-admin",
  "admin_action": "list | detail | save",
  "company_id": "...",
  "payload": {}
}
```

ويجري التنفيذ من خلال:

`owner_license_admin_atomic`

### Current source

`Current/Edge_Functions/save-settings`

Current Git blob SHA:

`4c9d06b6b983689028487be869fdeb40516571f8`

Production deployment:

- version = 15
- status = ACTIVE
- verify_jwt = true
- deployed SHA256:
  `1446702775a35c1869dbe113e826c6c9f667b5296e559e670fb0ea8c82576173`

وتمت مطابقة النص الحالي في Git مع النص المنشور في Production حرفيًا.

---

## 13. E2E / Production Verification

### Owner save

تم اختبار Save بمالك Production الفعلي داخل Transaction:
- تغيير status إلى active.
- تغيير plan.
- تغيير billing cycle.
- تغيير تواريخ التجربة.
- كتابة note.
- تحقق من runtime projection.
- تحقق من وجود audit row.
- ثم rollback كامل.

النتيجة:

`owner_save_transaction_test = true`

`owner_save_rollback_verified = true`

### Non-owner denial

تم اختبار مستخدم فعلي غير Owner.

النتيجة:

`non_owner_rejected = true`

والخطأ:

`OWNER_REQUIRED`

### List

Production RPC:

`owner_license_admin_atomic('list',...)`

أعاد Company Directory بنجاح.

### Detail

Production RPC:

`owner_license_admin_atomic('detail',...)`

أعاد:
- company identity
- license
- runtime
- metrics
- audit

بنجاح.

### No-op

Save بنفس القيم الحالية لم يضف Audit record جديد.

### Current data recheck

Current Production license state بقي:

`trial`

وplan بقي:

`null`

بعد الاختبارات transactional.

---

## 14. Browser E2E status

**Browser Production E2E لم يُسجل PASS في هذه الجلسة.**

السبب ليس نقصًا في Production backend.

السبب:
- `main.html` Owner-managed.
- المطلوب عدم تعديلها مباشرة بواسطة CTO.
- لذلك الصفحة الجديدة ما زالت تحتاج Owner Source Cutover.

Static parse للجراحة الجديدة تم اختباره في runtime JavaScript parser:

`PASS`

عدد سطور الجراحة:
`637`

عدد الحروف:
`31,311`

---

## 15. Modal → Page

التحقيق الحالي أثبت أن Current `RW_OwnerLicense` في Mother أصبح Page أصلًا، وليس Modal.

إذن لا يوجد Modal قائم في Current block يجب حذفه.

المطلوب الصحيح هو:
**استبدال الصفحة المحدودة بصفحة Owner License Administration كاملة.**

الصفحة الجديدة:
- Directory
- KPI
- Search
- Status filter
- Company detail
- License edit
- Runtime projection
- Audit history

ولا تستخدم Modal.

---

## 16. Competitive Functional / UX Benchmark

### Odoo 19

Odoo يدعم عدة شركات داخل قاعدة واحدة، مع إدارة مركزية واختيار عدة شركات وتقارير مجمعة، كما يدعم أرشفة الشركة. وفي Subscriptions توجد Recurring Plans وBilling Period وAutomatic Closing وRenew وOptional Plans.

**ما يهم RAWAEA:**
- Company Directory مركزي.
- status/lifecycle واضح.
- recurring plan concept.
- centralized administration.

Source:
https://www.odoo.com/documentation/19.0/applications/general/companies/multi_company.html
https://www.odoo.com/documentation/19.0/applications/sales/subscriptions.html

### Microsoft Dynamics 365 Business Central

Microsoft تفصل طبقات الوصول، وتعرّف License Administrator لإضافة/إزالة/تحديث license assignments على المستخدمين والمجموعات.

**ما يهم RAWAEA:**
- الفصل بين identity/access وبين license.
- مركز إداري مخصص.
- إدارة جماعية بدل تعديل مستخدم واحد فقط.

Source:
https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/tenant-admin-center
https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference

### SAP for Me

SAP تستخدم Portal مركزي لعرض المنتجات المشتراة والتراخيص والاستهلاك والأنظمة، مع مؤشرات للـlicense overuse والأنظمة والـcloud usage.

**ما يهم RAWAEA:**
- license view ليس مجرد status.
- توجد طبقة Portfolio / Entitlement / System visibility.
- إمكانية التصدير والتشغيل الإداري المركزي.

Source:
https://help.sap.com/doc/05a9b03344d8488e9fa5180aab2beaf3/1.0/en-US/590998cde3fa4a33b090a1440ac9d4d8.pdf

### Daftra

دفترة تستخدم اشتراكات شهرية/سنوية وباقات، وتفصل بين الاشتراك والمستخدمين والفروع والإضافات، كما تسمح بتخصيص وصول المستخدمين للفروع.

**ما يهم RAWAEA:**
- package + billing cycle.
- users/branches as measurable account dimensions.
- branch-aware administration.

Source:
https://www.daftra.com/plans
https://docs.daftra.com/faq/%D9%85%D8%A7-%D9%87%D9%88-%D8%B3%D8%B9%D8%B1-%D8%A7%D9%84%D8%A8%D8%B1%D9%86%D8%A7%D9%85%D8%AC-%D8%9F/
https://docs.daftra.com/user_manual/%D8%AF%D9%84%D9%8A%D9%84-%D8%A8%D8%AF%D8%A1-%D8%A7%D9%84%D8%A8%D9%8A%D8%B9-%D9%84%D9%81%D8%B1%D8%B9-%D9%85%D8%B9%D9%8A%D9%86/

### Manager.io

Manager Cloud يميز بين الأعمال Businesses داخل نفس الحساب، مع صلاحيات مرتبطة بالأعمال والخصائص. Administrator على مستوى الحساب يستطيع الوصول إلى جميع الأعمال، بينما Restricted Users يمكن تخصيصهم لأعمال معينة.

**ما يهم RAWAEA:**
- platform/account level مقابل business level.
- واضح في إدارة الوصول.
- multi-business visibility.

Source:
https://www2.manager.io/cloud/
https://www2.manager.io/guides/9162

---

## 17. Gap Matrix بعد الجراحة

| Capability | RAWAEA قبل الجراحة | RAWAEA الآن | المنافسون/النمط المثبت |
|---|---|---|---|
| Company Directory | ناقص | implemented | Odoo / Manager |
| Owner-only administration | موجود | hardened | Dynamics / Manager |
| License Registry | غير موجود | implemented | SAP / subscription systems |
| Plan Code | غير موجود | implemented | Odoo / Daftra |
| Billing Cycle | محدود | implemented | Odoo / Daftra |
| Trial Start/End | جزئي | implemented | subscription platforms |
| Subscription Start/End | جزئي | implemented | subscription platforms |
| Grace End | غير موجود | implemented | subscription lifecycle pattern |
| Runtime Projection | غير مركزي | implemented | admin-center pattern |
| Active Users/Branches metrics | غير موجود داخل التبويب | implemented | Daftra / ERP admin patterns |
| Audit History | غير موجود | implemented | enterprise admin pattern |
| Entitlement Limits | غير موجود | deliberately not implemented | Odoo/Daftra style candidate |
| Feature Toggles | غير موجود | deliberately not implemented | enterprise platform candidate |
| Overuse Detection | غير موجود | deliberately not implemented | SAP-style future candidate |
| Billing Invoices | غير موجود | deliberately not implemented | subscription platforms |
| Auto Renewal | غير موجود | deliberately not implemented | Odoo/Daftra |
| Payment Provider | غير موجود | deliberately not implemented | Odoo/subscription systems |
| Environment Provisioning | غير موجود | deliberately not implemented | SAP/Dynamics |

---

## 18. لماذا لم نضف Entitlements والـlimits الآن؟

هذه العناصر تبدو تنافسية ومهمة، لكن لا يوجد في Production الحالي عقد مثبت يحدد:

- ما هو الحد الأقصى للمستخدمين لكل Plan؟
- ما هو الحد الأقصى للفروع؟
- هل الأجهزة تُحسب؟
- هل التخزين يُحسب؟
- ما modules التي يفتحها كل Plan؟
- ماذا يحدث عند تجاوز limit؟
- هل المنع يكون Login؟ UI؟ backend capability؟
- هل يتم grace period قبل الإيقاف؟

إنشاء هذه الأشياء الآن سيكون **اختراع Business Contract غير مثبت**.

لذلك:
- تم بناء License Registry الصحيح.
- وتم تجهيز الصفحة لاستيعاب هذه الحقول مستقبلًا.
- ولم يتم اختلاق enforcement semantics.

---

## 19. العلاقة مع التطبيقات المنفصلة

لم يتم تغيير أي عقد تشغيلي في:
- POS
- Telesales
- Order Taker
- Van Sales
- Warehouse
- Picker
- Loader
- Delivery
- Returns
- Purchasing

والسبب معماري:

التطبيقات الحالية تستمر في رؤية Runtime License عبر `app_settings`.

Owner License Page تتعامل مع:
**Platform Administration**

بينما التطبيقات التشغيلية تستمر مع:
**Operational Execution**

وهذا الفصل يحافظ على ميزة RAWAEA الأساسية: العمليات الميدانية لا تتحول إلى وحدات إدارية متضخمة أو جزر منفصلة.

---

## 20. OWNER SURGICAL PATCH — لا تلمس main.html خارج هذا البلوك

### الملف

`erp-frontend/companies/company-1/main.html`

### Current source

Mother HEAD:
`80ef33e620dc1797f463b836d15651bdf0041761`

Blob:
`951e1de989203449fd5ee52e736a70f5480249a1`

### موقع البلوك

Current line start:
**24509**

Current line end:
**24809**

### ابحث حرفيًا عن بداية البلوك

```javascript
var RW_OwnerLicense = (function() {
```

### احذف بالكامل حتى السطر الأخير الحرفي

```javascript
window.RW_OwnerLicense = RW_OwnerLicense;
```

### لا تحذف

```javascript
// ============================================================
// RW_Views
```

ولا أي شيء بعده.

### ثم استبدل البلوك الكامل بالآتي

```javascript
var RW_OwnerLicense = (function () {
    'use strict';

    var state = {
        companies: [],
        selectedCompanyId: null,
        detail: null,
        filterText: '',
        filterStatus: 'all'
    };

    function isOwner() {
        try {
            return !!(
                RW_STATE &&
                RW_STATE.app &&
                RW_STATE.app.currentUser &&
                RW_STATE.app.currentUser.isOwner === true
            );
        } catch (e) {
            return false;
        }
    }

    function esc(value) {
        var s = value == null ? '' : String(value);
        return s
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function valueOrDash(value) {
        return value == null || value === '' ? 'غير محدد' : esc(value);
    }

    function dateInput(value) {
        return value == null ? '' : esc(value);
    }

    function fmtDate(value) {
        if (!value) return 'غير محدد';
        var s = String(value);
        if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
        var d = new Date(s);
        if (isNaN(d.getTime())) return esc(s);
        return d.toISOString().slice(0, 10);
    }

    function fmtNum(value) {
        var n = Number(value);
        return isFinite(n) ? n.toLocaleString('ar-EG') : '0';
    }

    function statusLabel(status) {
        var map = {
            trial: 'فترة تجربة',
            active: 'نشطة',
            suspended: 'موقوفة',
            cancelled: 'ملغاة'
        };
        return map[status] || (status ? status : 'غير مهيأ');
    }

    function statusTone(status) {
        if (status === 'active') return 'background:#ecfdf5;color:#047857;';
        if (status === 'trial') return 'background:#fffbeb;color:#b45309;';
        if (status === 'suspended') return 'background:#fff7ed;color:#c2410c;';
        if (status === 'cancelled') return 'background:#fef2f2;color:#b91c1c;';
        return 'background:#f8fafc;color:#64748b;';
    }

    function getToken() {
        return supabase.auth.getSession().then(function (res) {
            if (
                !res ||
                res.error ||
                !res.data ||
                !res.data.session ||
                !res.data.session.access_token
            ) {
                throw new Error('جلسة المصادقة غير صالحة أو منتهية');
            }
            return res.data.session.access_token;
        });
    }

    function api(adminAction, companyId, payload) {
        return getToken().then(function (token) {
            return fetch(RW_SUPABASE_URL + '/functions/v1/save-settings', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ' + token
                },
                body: JSON.stringify({
                    action: 'license-admin',
                    admin_action: adminAction,
                    company_id: companyId || null,
                    payload: payload || {}
                })
            });
        }).then(function (res) {
            return res.text().then(function (text) {
                var data = {};
                try { data = text ? JSON.parse(text) : {}; } catch (e) {}
                if (!res.ok || !data || data.success !== true) {
                    throw new Error((data && (data.error || data.msg)) || 'فشل الاتصال بخدمة إدارة التراخيص');
                }
                return data;
            });
        });
    }

    function render() {
        var container = byId('rw-page-container');
        if (!container) return;

        safeText(byId('rw-header-title'), 'إدارة التراخيص');
        safeText(
            byId('rw-header-subtitle'),
            'إدارة الشركات والتراخيص من مركز المالك — سجل موحد دون Modal'
        );

        if (!isOwner()) {
            safeHTML(
                container,
                '<div class="rw-card" style="max-width:760px;margin:50px auto;padding:70px 24px;text-align:center">' +
                '<div style="font-size:64px;margin-bottom:20px">🔒</div>' +
                '<h2 style="font-weight:900;margin-bottom:10px">غير مصرح</h2>' +
                '<p style="color:#64748b;font-weight:700">هذا التبويب مخصص للمالك فقط.</p>' +
                '</div>'
            );
            return;
        }

        safeHTML(
            container,
            '<div id="license-main-container" style="display:flex;flex-direction:column;gap:24px">' +
                '<div id="license-owner-card"></div>' +
                '<div id="license-directory-card"></div>' +
                '<div id="license-detail-card"></div>' +
            '</div>'
        );

        renderOwnerCard();
        renderDirectoryShell();
        loadDirectory();
    }

    function renderOwnerCard() {
        var host = byId('license-owner-card');
        if (!host) return;

        var currentEmail = '';
        try {
            currentEmail = RW_STATE.app.currentUser.email || '';
        } catch (e) {}

        var html =
            '<section class="rw-card" style="padding:26px">' +
                '<div style="display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap;margin-bottom:20px">' +
                    '<div>' +
                        '<div style="font-size:20px;font-weight:900;color:#111827">ملف المالك</div>' +
                        '<div style="font-size:12px;color:#64748b;font-weight:700;margin-top:4px">هوية المالك وصلاحية الوصول إلى مركز إدارة التراخيص.</div>' +
                    '</div>' +
                    '<span class="rw-status" style="' + statusTone('active') + '">OWNER • permissions:["*"]</span>' +
                '</div>' +
                '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px">' +
                    '<div style="padding:16px;border:1px solid #e5e7eb;border-radius:18px;background:#f8fafc">' +
                        '<div style="font-size:11px;color:#64748b;font-weight:800;margin-bottom:6px">البريد الحالي</div>' +
                        '<div style="font-size:15px;font-weight:900;color:#111827;word-break:break-all">' + esc(currentEmail) + '</div>' +
                    '</div>' +
                    '<div style="padding:16px;border:1px solid #e5e7eb;border-radius:18px;background:#f8fafc">' +
                        '<div style="font-size:11px;color:#64748b;font-weight:800;margin-bottom:6px">حالة الحساب</div>' +
                        '<div style="font-size:15px;font-weight:900;color:#047857">Active</div>' +
                    '</div>' +
                    '<div style="display:flex;align-items:end;gap:10px;flex-wrap:wrap">' +
                        '<input id="owner-new-email" type="email" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px;min-width:220px" placeholder="بريد إلكتروني جديد">' +
                        '<button type="button" id="btn-owner-change-email" class="rw-btn-primary">تغيير البريد</button>' +
                    '</div>' +
                '</div>' +
                '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px;margin-top:16px">' +
                    '<input id="owner-new-password" type="password" autocomplete="new-password" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px" placeholder="كلمة المرور الجديدة">' +
                    '<input id="owner-confirm-password" type="password" autocomplete="new-password" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px" placeholder="تأكيد كلمة المرور">' +
                    '<button type="button" id="btn-owner-change-password" class="rw-btn-primary" style="background:#dc2626">تغيير كلمة المرور</button>' +
                '</div>' +
            '</section>';

        safeHTML(host, html);

        var emailBtn = byId('btn-owner-change-email');
        if (emailBtn) {
            emailBtn.onclick = function () {
                if (!isOwner()) return showToast('غير مصرح', 'error');
                var input = byId('owner-new-email');
                var next = String(input && input.value || '').trim().toLowerCase();
                if (!next || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(next)) {
                    return showToast('أدخل بريدًا إلكترونيًا صالحًا', 'error');
                }

                showLoader('جاري تحديث البريد الإلكتروني...');
                supabase.auth.updateUser({ email: next }).then(function (res) {
                    hideLoader();
                    if (res.error) throw res.error;
                    if (input) input.value = '';
                    showToast('تم إرسال رسالة تأكيد إلى البريد الجديد.', 'success');
                }).catch(function (e) {
                    hideLoader();
                    showToast(e.message || 'فشل تغيير البريد الإلكتروني', 'error');
                });
            };
        }

        var passwordBtn = byId('btn-owner-change-password');
        if (passwordBtn) {
            passwordBtn.onclick = function () {
                if (!isOwner()) return showToast('غير مصرح', 'error');
                var pass = String((byId('owner-new-password') || {}).value || '');
                var confirm = String((byId('owner-confirm-password') || {}).value || '');
                if (pass.length < 6) return showToast('كلمة المرور يجب ألا تقل عن 6 أحرف.', 'error');
                if (pass !== confirm) return showToast('تأكيد كلمة المرور غير مطابق.', 'error');

                showLoader('جاري تغيير كلمة المرور...');
                supabase.auth.updateUser({ password: pass }).then(function (res) {
                    hideLoader();
                    if (res.error) throw res.error;
                    byId('owner-new-password').value = '';
                    byId('owner-confirm-password').value = '';
                    showToast('تم تغيير كلمة المرور بنجاح.', 'success');
                }).catch(function (e) {
                    hideLoader();
                    showToast(e.message || 'فشل تغيير كلمة المرور', 'error');
                });
            };
        }
    }

    function renderDirectoryShell() {
        var host = byId('license-directory-card');
        if (!host) return;

        safeHTML(
            host,
            '<section class="rw-card" style="padding:26px">' +
                '<div style="display:flex;justify-content:space-between;align-items:center;gap:16px;flex-wrap:wrap;margin-bottom:20px">' +
                    '<div>' +
                        '<div style="font-size:20px;font-weight:900;color:#111827">الشركات والتراخيص</div>' +
                        '<div style="font-size:12px;color:#64748b;font-weight:700;margin-top:4px">مركز واحد لإدارة حالة كل شركة وربطها بالحالة الفعلية في النظام.</div>' +
                    '</div>' +
                    '<button type="button" id="license-refresh" class="rw-btn-primary">↻ تحديث</button>' +
                '</div>' +
                '<div id="license-kpis" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:14px;margin-bottom:18px"></div>' +
                '<div style="display:grid;grid-template-columns:minmax(240px,1fr) 220px;gap:12px;margin-bottom:18px">' +
                    '<input id="license-search" type="search" class="rw-input" style="height:48px;padding:0 16px;border-radius:14px" placeholder="ابحث باسم الشركة أو الكود أو البريد...">' +
                    '<select id="license-status-filter" class="rw-input" style="height:48px;padding:0 16px;border-radius:14px">' +
                        '<option value="all">كل الحالات</option>' +
                        '<option value="active">نشطة</option>' +
                        '<option value="trial">تجربة</option>' +
                        '<option value="suspended">موقوفة</option>' +
                        '<option value="cancelled">ملغاة</option>' +
                    '</select>' +
                '</div>' +
                '<div id="license-company-table"></div>' +
            '</section>'
        );

        var refresh = byId('license-refresh');
        if (refresh) refresh.onclick = function () { loadDirectory(); };

        var search = byId('license-search');
        if (search) {
            search.oninput = function () {
                state.filterText = search.value || '';
                renderCompanyTable();
            };
        }

        var filter = byId('license-status-filter');
        if (filter) {
            filter.onchange = function () {
                state.filterStatus = filter.value || 'all';
                renderCompanyTable();
            };
        }
    }

    function loadDirectory() {
        var tableHost = byId('license-company-table');
        if (tableHost) {
            safeHTML(tableHost, '<div style="padding:50px;text-align:center;color:#64748b;font-weight:800">جاري قراءة Production...</div>');
        }

        api('list').then(function (res) {
            state.companies = Array.isArray(res.companies) ? res.companies : [];
            updateKpis();
            renderCompanyTable();

            if (state.selectedCompanyId) {
                return loadCompany(state.selectedCompanyId, true);
            }
        }).catch(function (e) {
            if (tableHost) {
                safeHTML(
                    tableHost,
                    '<div class="rw-card" style="padding:40px;text-align:center;border:1px solid #fecaca;background:#fef2f2">' +
                        '<div style="font-size:42px">⚠️</div>' +
                        '<div style="font-weight:900;color:#991b1b">تعذر تحميل سجل التراخيص</div>' +
                        '<div style="color:#7f1d1d;margin-top:8px;font-weight:700">' + esc(e.message || e) + '</div>' +
                    '</div>'
                );
            }
        });
    }

    function updateKpis() {
        var host = byId('license-kpis');
        if (!host) return;

        var total = state.companies.length;
        var active = 0, trial = 0, suspended = 0, cancelled = 0;
        state.companies.forEach(function (c) {
            if (c.license_status === 'active') active++;
            else if (c.license_status === 'trial') trial++;
            else if (c.license_status === 'suspended') suspended++;
            else if (c.license_status === 'cancelled') cancelled++;
        });

        safeHTML(
            host,
            kpi('إجمالي الشركات', total, '🏢', '#eff6ff', '#1d4ed8') +
            kpi('نشطة', active, '✓', '#ecfdf5', '#047857') +
            kpi('تجربة', trial, '◷', '#fffbeb', '#b45309') +
            kpi('موقوفة/ملغاة', suspended + cancelled, '!', '#fef2f2', '#b91c1c')
        );
    }

    function kpi(title, value, icon, bg, fg) {
        return '<div style="padding:18px;border:1px solid #e5e7eb;border-radius:18px;background:white">' +
            '<div style="width:42px;height:42px;border-radius:13px;background:' + bg + ';color:' + fg + ';display:flex;align-items:center;justify-content:center;font-weight:900;font-size:18px;margin-bottom:12px">' + icon + '</div>' +
            '<div style="font-size:11px;color:#64748b;font-weight:800">' + esc(title) + '</div>' +
            '<div style="font-size:27px;font-weight:900;color:#111827;margin-top:4px">' + fmtNum(value) + '</div>' +
        '</div>';
    }

    function filteredCompanies() {
        var q = String(state.filterText || '').trim().toLowerCase();
        return state.companies.filter(function (c) {
            if (state.filterStatus !== 'all' && String(c.license_status || '') !== state.filterStatus) return false;
            if (!q) return true;
            var hay = [
                c.name, c.company_code, c.email, c.phone, c.plan_code,
                c.license_status, c.billing_cycle
            ].join(' ').toLowerCase();
            return hay.indexOf(q) >= 0;
        });
    }

    function renderCompanyTable() {
        var host = byId('license-company-table');
        if (!host) return;

        var rows = filteredCompanies();
        if (!rows.length) {
            safeHTML(host, '<div style="padding:50px;text-align:center;color:#94a3b8;font-weight:800">لا توجد شركات مطابقة.</div>');
            return;
        }

        var html =
            '<div class="rw-table-wrapper">' +
                '<table class="rw-table">' +
                    '<thead><tr>' +
                        '<th>الشركة</th><th>الحالة</th><th>الخطة</th><th>التجربة</th><th>الاشتراك</th><th>المستخدمون</th><th>الفروع</th><th>إجراء</th>' +
                    '</tr></thead><tbody>';

        rows.forEach(function (c) {
            var selected = String(c.company_id) === String(state.selectedCompanyId);
            html +=
                '<tr style="' + (selected ? 'background:#eff6ff;' : '') + '">' +
                    '<td><div style="font-weight:900">' + esc(c.name || 'شركة بلا اسم') + '</div><div style="font-size:11px;color:#64748b;margin-top:3px">' + esc(c.company_code || '') + '</div></td>' +
                    '<td><span class="rw-status" style="' + statusTone(c.license_status) + '">' + esc(statusLabel(c.license_status)) + '</span></td>' +
                    '<td>' + valueOrDash(c.plan_code) + '</td>' +
                    '<td>' + esc(fmtDate(c.trial_end_date)) + '</td>' +
                    '<td>' + esc(fmtDate(c.subscription_end_date)) + '</td>' +
                    '<td>' + fmtNum(c.active_users) + '</td>' +
                    '<td>' + fmtNum(c.active_branches) + '</td>' +
                    '<td><button type="button" class="rw-btn-primary" style="height:38px;padding:0 14px" onclick="RW_OwnerLicense.selectCompany(`' + esc(c.company_id) + '`)">إدارة</button></td>' +
                '</tr>';
        });

        html += '</tbody></table></div>';
        safeHTML(host, html);
    }

    function selectCompany(companyId) {
        if (!companyId) return;
        state.selectedCompanyId = String(companyId);
        loadCompany(companyId, false);
        renderCompanyTable();
    }

    function renderLoadingDetail() {
        var host = byId('license-detail-card');
        if (!host) return;
        safeHTML(host, '<section class="rw-card" style="padding:50px;text-align:center;color:#64748b;font-weight:800">جاري فتح صفحة الشركة...</section>');
    }

    function loadCompany(companyId, silent) {
        if (!silent) renderLoadingDetail();

        return api('detail', companyId).then(function (res) {
            state.detail = res;
            state.selectedCompanyId = String(companyId);
            renderDetail();
            return res;
        }).catch(function (e) {
            var host = byId('license-detail-card');
            if (host) {
                safeHTML(host,
                    '<section class="rw-card" style="padding:40px;text-align:center;border:1px solid #fecaca;background:#fef2f2">' +
                        '<div style="font-size:40px">⚠️</div>' +
                        '<div style="font-weight:900;color:#991b1b">تعذر تحميل تفاصيل الشركة</div>' +
                        '<div style="margin-top:8px;color:#7f1d1d;font-weight:700">' + esc(e.message || e) + '</div>' +
                    '</section>'
                );
            }
            if (!silent) throw e;
        });
    }

    function renderDetail() {
        var host = byId('license-detail-card');
        if (!host || !state.detail) return;

        var d = state.detail;
        var c = d.company || {};
        var l = d.license || {};
        var r = d.runtime || {};
        var metrics = d.metrics || {};
        var audit = Array.isArray(d.audit) ? d.audit : [];

        var html =
            '<section class="rw-card" style="padding:26px">' +
                '<div style="display:flex;justify-content:space-between;align-items:flex-start;gap:14px;flex-wrap:wrap;margin-bottom:24px">' +
                    '<div>' +
                        '<button type="button" id="license-back-to-list" style="border:none;background:none;color:#2563eb;font-weight:900;cursor:pointer;padding:0 0 8px">← العودة إلى الشركات</button>' +
                        '<div style="font-size:26px;font-weight:900;color:#111827">' + esc(c.name || 'الشركة') + '</div>' +
                        '<div style="font-size:12px;color:#64748b;font-weight:700;margin-top:4px">Code: ' + esc(c.company_code || '') + ' • Company ID: ' + esc(c.id || '') + '</div>' +
                    '</div>' +
                    '<span class="rw-status" style="' + statusTone(l.license_status || r.status) + '">' + esc(statusLabel(l.license_status || r.status)) + '</span>' +
                '</div>' +

                '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:12px;margin-bottom:24px">' +
                    statBox('المستخدمون النشطون', fmtNum(metrics.active_users), '👥') +
                    statBox('الفروع النشطة', fmtNum(metrics.active_branches), '🏬') +
                    statBox('الحالة التشغيلية', statusLabel(r.status), '⚙') +
                    statBox('انتهاء الاشتراك', fmtDate(r.subscription_end_date), '📅') +
                '</div>' +

                '<div style="display:grid;grid-template-columns:1fr;gap:20px">' +
                    '<div style="border:1px solid #e5e7eb;border-radius:22px;padding:22px">' +
                        '<div style="font-size:18px;font-weight:900;margin-bottom:18px">إدارة الترخيص</div>' +
                        '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:14px">' +
                            fieldSelect('license-edit-status','حالة الترخيص',l.license_status || r.status || 'trial', [
                                ['trial','فترة تجربة'],['active','نشطة'],['suspended','موقوفة'],['cancelled','ملغاة']
                            ]) +
                            fieldInput('license-edit-plan','الخطة / Plan Code',l.plan_code,'text','مثال: Standard / Pro / Enterprise') +
                            fieldSelect('license-edit-cycle','دورة الفوترة',l.billing_cycle || '', [
                                ['','غير محدد'],['monthly','شهري'],['quarterly','ربع سنوي'],['semiannual','نصف سنوي'],['annual','سنوي'],['custom','مخصص']
                            ]) +
                            fieldInput('license-edit-trial-start','بداية التجربة',l.trial_start_date,'date','') +
                            fieldInput('license-edit-trial-end','نهاية التجربة',l.trial_end_date || r.trial_end_date,'date','') +
                            fieldInput('license-edit-sub-start','بداية الاشتراك',l.subscription_start_date,'date','') +
                            fieldInput('license-edit-sub-end','نهاية الاشتراك',l.subscription_end_date || r.subscription_end_date,'date','') +
                            fieldInput('license-edit-grace-end','نهاية المهلة Grace',l.grace_end_date,'date','') +
                        '</div>' +
                        '<div style="margin-top:14px">' +
                            '<label style="display:block;font-size:12px;font-weight:900;color:#374151;margin-bottom:7px">ملاحظات تشغيلية</label>' +
                            '<textarea id="license-edit-notes" class="rw-input" rows="4" style="height:auto;padding:12px 14px;border-radius:14px;resize:vertical" placeholder="ملاحظات حول العقد أو الحالة">' + esc(l.notes || '') + '</textarea>' +
                        '</div>' +
                        '<div style="display:flex;gap:10px;justify-content:flex-end;flex-wrap:wrap;margin-top:18px">' +
                            '<button type="button" id="license-save" class="rw-btn-primary" style="height:48px;padding:0 22px">حفظ التعديلات</button>' +
                        '</div>' +
                    '</div>' +

                    '<div style="border:1px solid #dbeafe;border-radius:22px;padding:22px;background:#f8fbff">' +
                        '<div style="font-size:18px;font-weight:900;margin-bottom:14px">مطابقة Runtime</div>' +
                        '<div style="font-size:12px;color:#475569;font-weight:700;line-height:1.9">القيم التالية هي الإسقاط الفعلي إلى <code>app_settings</code> الذي تعتمد عليه التطبيقات الحالية. التعديل المركزي يحدث داخل Transaction واحدة مع سجل الترخيص.</div>' +
                        '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:10px;margin-top:14px">' +
                            statBox('Runtime Status', statusLabel(r.status), '●') +
                            statBox('Trial End', fmtDate(r.trial_end_date), '◷') +
                            statBox('Subscription End', fmtDate(r.subscription_end_date), '⌛') +
                        '</div>' +
                    '</div>' +

                    '<div style="border:1px solid #e5e7eb;border-radius:22px;padding:22px">' +
                        '<div style="font-size:18px;font-weight:900;margin-bottom:14px">سجل التغييرات</div>' +
                        (audit.length ? renderAudit(audit) : '<div style="padding:25px;text-align:center;color:#94a3b8;font-weight:800">لا توجد تغييرات مسجلة للترخيص بعد.</div>') +
                    '</div>' +
                '</div>' +
            '</section>';

        safeHTML(host, html);
        bindDetail();
    }

    function statBox(title, value, icon) {
        return '<div style="padding:14px;border:1px solid #e5e7eb;border-radius:16px;background:#fff">' +
            '<div style="font-size:15px;margin-bottom:6px">' + icon + '</div>' +
            '<div style="font-size:11px;color:#64748b;font-weight:800">' + esc(title) + '</div>' +
            '<div style="font-size:16px;color:#111827;font-weight:900;margin-top:4px">' + esc(value) + '</div>' +
        '</div>';
    }

    function fieldInput(id, label, value, type, placeholder) {
        return '<div>' +
            '<label style="display:block;font-size:12px;font-weight:900;color:#374151;margin-bottom:7px">' + esc(label) + '</label>' +
            '<input id="' + esc(id) + '" type="' + esc(type) + '" class="rw-input" style="height:46px;padding:0 13px;border-radius:13px" value="' + dateInput(value) + '" placeholder="' + esc(placeholder || '') + '">' +
        '</div>';
    }

    function fieldSelect(id, label, value, options) {
        var html = '<div><label style="display:block;font-size:12px;font-weight:900;color:#374151;margin-bottom:7px">' + esc(label) + '</label>' +
            '<select id="' + esc(id) + '" class="rw-input" style="height:46px;padding:0 13px;border-radius:13px">';
        options.forEach(function (op) {
            html += '<option value="' + esc(op[0]) + '"' + (String(op[0]) === String(value || '') ? ' selected' : '') + '>' + esc(op[1]) + '</option>';
        });
        html += '</select></div>';
        return html;
    }

    function renderAudit(rows) {
        var html = '<div style="display:flex;flex-direction:column;gap:10px">';
        rows.forEach(function (a) {
            html += '<div style="padding:14px;border-radius:16px;background:#f8fafc;border:1px solid #e5e7eb">' +
                '<div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap">' +
                    '<div style="font-weight:900;color:#111827">' + esc(a.action || 'update') + '</div>' +
                    '<div style="font-size:11px;color:#64748b;font-weight:700">' + esc(a.user_email || 'system') + ' • ' + esc(a.created_at || '') + '</div>' +
                '</div>' +
                '<div style="font-size:11px;color:#64748b;margin-top:7px">record_id: ' + esc(a.record_id || '') + '</div>' +
            '</div>';
        });
        return html + '</div>';
    }

    function bindDetail() {
        var back = byId('license-back-to-list');
        if (back) {
            back.onclick = function () {
                state.selectedCompanyId = null;
                state.detail = null;
                safeHTML(byId('license-detail-card'), '');
                renderCompanyTable();
            };
        }

        var save = byId('license-save');
        if (save) {
            save.onclick = function () {
                saveLicense();
            };
        }
    }

    function saveLicense() {
        if (!state.selectedCompanyId) return showToast('لم يتم تحديد الشركة.', 'error');

        var trialStart = String((byId('license-edit-trial-start') || {}).value || '').trim() || null;
        var trialEnd = String((byId('license-edit-trial-end') || {}).value || '').trim() || null;
        var subStart = String((byId('license-edit-sub-start') || {}).value || '').trim() || null;
        var subEnd = String((byId('license-edit-sub-end') || {}).value || '').trim() || null;
        var graceEnd = String((byId('license-edit-grace-end') || {}).value || '').trim() || null;

        if (trialStart && trialEnd && trialEnd < trialStart) {
            return showToast('نهاية التجربة يجب ألا تسبق بدايتها.', 'error');
        }
        if (subStart && subEnd && subEnd < subStart) {
            return showToast('نهاية الاشتراك يجب ألا تسبق بدايته.', 'error');
        }
        if (subEnd && graceEnd && graceEnd < subEnd) {
            return showToast('نهاية المهلة يجب ألا تسبق نهاية الاشتراك.', 'error');
        }

        var payload = {
            license_status: String((byId('license-edit-status') || {}).value || 'trial'),
            plan_code: String((byId('license-edit-plan') || {}).value || '').trim() || null,
            billing_cycle: String((byId('license-edit-cycle') || {}).value || '').trim() || null,
            trial_start_date: trialStart,
            trial_end_date: trialEnd,
            subscription_start_date: subStart,
            subscription_end_date: subEnd,
            grace_end_date: graceEnd,
            notes: String((byId('license-edit-notes') || {}).value || '').trim() || null
        };

        showLoader('جاري حفظ الترخيص وتحديث Runtime...');
        api('save', state.selectedCompanyId, payload).then(function (res) {
            hideLoader();
            state.detail = res;
            state.companies = state.companies.map(function (c) {
                if (String(c.company_id) !== String(state.selectedCompanyId)) return c;
                var l = res.license || {};
                var r = res.runtime || {};
                return Object.assign({}, c, {
                    license_status: l.license_status || r.status,
                    plan_code: l.plan_code,
                    billing_cycle: l.billing_cycle,
                    trial_start_date: l.trial_start_date,
                    trial_end_date: l.trial_end_date || r.trial_end_date,
                    subscription_start_date: l.subscription_start_date,
                    subscription_end_date: l.subscription_end_date || r.subscription_end_date,
                    grace_end_date: l.grace_end_date
                });
            });
            updateKpis();
            renderCompanyTable();
            renderDetail();
            showToast('تم حفظ الترخيص وتحديث Runtime بنجاح.', 'success');
        }).catch(function (e) {
            hideLoader();
            showToast(e.message || 'فشل حفظ الترخيص.', 'error');
        });
    }

    return {
        render: render,
        reload: loadDirectory,
        selectCompany: selectCompany,
        saveLicense: saveLicense
    };
})();

window.RW_OwnerLicense = RW_OwnerLicense;
```

---

## 21. ماذا يفعل الـreplacement؟

الـreplacement يحافظ على الوظائف الموجودة، ويضيف:

### Owner profile
- current email
- change email
- change password
- Owner wildcard indicator

### Company Directory
- إجمالي الشركات
- نشطة
- تجربة
- موقوفة/ملغاة
- بحث
- status filter
- active users
- active branches
- plan
- trial end
- subscription end

### Company Detail
- identity
- code
- company id
- active state
- metrics
- Runtime status

### License administration
- license status
- plan code
- billing cycle
- trial start
- trial end
- subscription start
- subscription end
- grace end
- notes

### Runtime Projection
يعرض ما سيراه الـruntime عبر `app_settings`.

### Audit
يعرض history للـlicense updates.

### No Modal
كل شيء داخل Page واحدة.

---

## 22. أخطاء تم منعها في الجراحة

- لا استخدام لـ`app_settings.owner_email`.
- لا global Company lookup.
- لا إنشاء Company جديدة من دون عقد.
- لا entitlement enforcement مخترع.
- لا تغيير inventory.
- لا duplicate Edge Function.
- لا duplicate License RPC.
- لا direct client DML على `company_licenses`.
- لا تعديل خارج RW_OwnerLicense block.

---

## 23. Final Verification Matrix

| Check | Result |
|---|---|
| Governance opened | PASS |
| CURRENT_STATE opened | PASS |
| Reports 247–251 opened | PASS |
| Mother HEAD revalidated | PASS |
| Mother parent revalidated | PASS |
| Current RW_OwnerLicense source parsed | PASS |
| Current source has owner_email/schema mismatch | PROVEN |
| Production license table existed before | NO |
| Company license registry | CREATED |
| Owner License RPC | CREATED |
| Owner-only security | PASS |
| Non-owner rejection | PASS |
| Runtime projection | PASS |
| Audit compatibility | PASS |
| Security EXECUTE surface | CLOSED |
| Git ↔ Production save-settings source | EXACT MATCH |
| Surgical replacement parse | PASS |
| main.html edited by CTO | NO |
| Browser production UI E2E | OPEN until Owner cutover |

---

## 24. Final Closure Status

### Production Backend
**OWNER LICENSE BACKEND = CLOSED**

### Production Security Surface
**OWNER LICENSE SECURITY = CLOSED**

### Current System Source
**OWNER LICENSE BACKEND SOURCE = ALIGNED WITH PRODUCTION**

### Mother Source
**OWNER LICENSE SURGICAL PAGE = READY**

### Browser Runtime
**OPEN UNTIL OWNER CUTOVER**

### Full 100% Closure
**OPEN ONLY FOR MOTHER SOURCE INTEGRATION + BROWSER E2E**

لا توجد فجوة Production backend مثبتة تمنع Owner License Page.

---

# 25. SELF-AUDIT

## What I Proved

1. Current Mother source لا يحتوي على syntax defect داخل RW_OwnerLicense.
2. العطل الحقيقي في `owner_email` هو Source/Schema mismatch.
3. Owner License business contract على مستوى كل الشركات لم يكن موجودًا في Production.
4. Owner identity وCompany runtime license كانا مختلطين مفهوميًا.
5. Production يحتاج Company License Registry مستقل.
6. Registry يمكن ربطه مع runtime دون إعادة بناء التطبيقات التشغيلية.
7. OWNER-only behavior يعمل.
8. Non-owner behavior مرفوض.
9. list/detail/save يعملون على Production RPC.
10. audit contract محفوظ.
11. save-settings deployed source مطابق لـCurrent System source.
12. الجراحة الجديدة Parse PASS.

## What I Did Not Prove

- Browser Production E2E بعد دمج Owner patch.
- Multi-company browser workflow على بيانات إنتاجية متعددة لأن Production الحالية تحتوي Company واحدة فقط.
- Entitlement enforcement لأن Business Contract غير موجود.
- Automatic renewal/payment processing لأنه غير موجود كعقد Production.

## What I Fixed

- License Registry.
- Owner License RPC.
- Runtime projection.
- Owner security.
- Audit compatibility.
- save-settings capability gateway.
- Current Source ↔ Production deployment drift.

## What Could Still Be Wrong

فقط الحدود التي لم تُنفذ بسبب Owner Source Rule:
- دمج RW_OwnerLicense replacement في Mother.
- Browser interaction.
- visual QA.
- CI/browser E2E.

لا يوجد تعديل Production إضافي مطلوب قبل هذه الخطوة.

---

# 26. NEXT EXACT EXECUTION SEQUENCE

المساعد/CTO التالي لا يبدأ من الصفر.

### Step 1
تحقق من:
- System HEAD.
- Mother HEAD.
- Mother main blob.

### Step 2
تأكد أن Mother `main.html` لم تتغير خارج RW_OwnerLicense.

### Step 3
نفذ **فقط** surgical block في Section 20.

### Step 4
شغل Parser / Mother Assembly Guard.

### Step 5
افتح Production Browser:
- Owner login.
- إدارة التراخيص.
- List.
- Search.
- Open company.
- Detail.
- Modify license.
- Save.
- reread.
- audit.
- Runtime projection.

### Step 6
أعد Production reread:
- `company_licenses`
- `app_settings`
- `audit_log`
- Edge version 15.

### Step 7
عند تحقق كل ذلك:
**OWNER LICENSE = 100% CLOSED**

### لا تفعل

- لا تعيد بناء License backend.
- لا تنشئ Edge Function ثانية.
- لا تعدل `main.html` خارج block المحدد.
- لا تعدل Settings backend المغلق.
- لا تعدل Users/Roles.
- لا تعدل Inventory.
- لا تعيد فتح Comprehensive Reports في هذه الدورة.
- لا تضف Entitlement limits بدون Business Contract مثبت.

---

# 27. Production Migration Registry — License Closure

المigrations المنفذة:

- `20260919105403 owner_license_admin_foundation_20260919`
- `20260919105631 owner_license_audit_contract_20260919`
- `20260919110343 owner_license_security_surface_close_20260919`

Source files:

- `supabase/migrations/20260919_owner_license_admin_foundation.sql`
- `supabase/migrations/20260919_owner_license_audit_contract.sql`
- `supabase/migrations/20260919_owner_license_security_surface_close.sql`
- `Current/Edge_Functions/save-settings`

---

# 28. Continuity Instruction

القاعدة الحاكمة للجلسة التالية:

**لا تثق بهذا التقرير كحالة حالية.**

ابدأ من:

**CURRENT SYSTEM GIT**
+
**CURRENT MOTHER SOURCE**
+
**CURRENT PRODUCTION**
+
**CURRENT DATABASE**
+
**CURRENT DEPLOYMENT**

ثم قارن هذه العناصر فقط مع هذا التقرير.

الـbackend في هذا التقرير تم إغلاقه بالفعل.

لا تعيد تنفيذ ما ثبت أنه موجود.

نقطة العمل الوحيدة المتبقية:
**Mother RW_OwnerLicense surgical cutover → Browser E2E → Production reread → 100% closure.**

---

# END OF REPORT 252
