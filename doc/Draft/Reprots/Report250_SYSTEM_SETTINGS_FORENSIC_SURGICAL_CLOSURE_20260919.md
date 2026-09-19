# RAWAEA ERP — Report 250
# التحقيق الجنائي والإصلاح الجراحي — إعدادات النظام
## 2026-09-19

> نطاق هذه الجلسة محصور في **RW_Settings / app_settings / save-settings** فقط.
> لم يتم تعديل `main.html` بواسطة CTO.
> تم إيقاف أي Closure سابق لا يخص Settings وعدم إعادة فتح Inventory / Orders / Runsheets / Reports إلا إذا ظهر دليل جديد خاص بهذه النقطة.

---

## 1) قاعدة الحقيقة المعتمدة

تمت إعادة بناء الحالة من:

```
CURRENT SYSTEM GIT
+
CURRENT MOTHER GIT
+
CURRENT MOTHER SOURCE
+
CURRENT PRODUCTION DATABASE
+
CURRENT EDGE DEPLOYMENT
+
CURRENT MIGRATION REGISTRY
```

التقارير التاريخية استُخدمت للاسترداد والتوجيه فقط.

### Current System Repository

`papamohammed77-glitch/rawaie-erp-New`

- HEAD الحالي: `daa9a58070de0204a81ef44dc40928c5ae4b4c43`
- Parent: `4650bc4d07fbeb49309aa80e916f789871cf3576`
- آخر System checkpoint قبل هذه الجلسة: RW_Roles.
- هذا يعني أن الحالة قبل هذه الجلسة لم تكن Settings checkpoint، رغم وجود أدلة تاريخية لSettings.

### Current Mother Repository

`papamohammed77-glitch/erp-frontend`

- HEAD الحالي: `4c16891f059bc46f994634f559a05e05f73b126a`
- Parent: `7a00dcfdda11ee8fb8fbe26a011be09db2e97c7f`
- Parent parent: `e08652c3a6cb1d1768a04685cec437aa2d8b04c9`
- Mother current `companies/company-1/main.html` blob: `65484a74a3c3fd0b7f5b6ba5ed056c1409a1d029`
- لم يتم تعديل هذا الـblob في هذه الجلسة.

Commit `7a00dcf...` أضاف في قائمة التنقل:
`settings → hint: الإعدادات العامة`
ولم يغير عقد RW_Settings التشغيلي نفسه.

### Current Production

Supabase project:
`fiilmooggumokxanwiyx`

الحقيقة الحالية:

- Company واحدة فعالة: `00000000-0000-0000-0000-000000000001`
- app_settings rows = 1
- Branches للشركة = 2
- main_branch_id = `a38332b6-6cea-480a-ada1-6eb6ab0590db`
- Settings row = `74aeade7-57f2-48ae-9265-fa8fcd1a9d66`
- audit_log records الخاصة بـapp_settings قبل هذه المهمة = 0

Current app_settings values بعد تنظيف اختبارات الجلسة:

- company_name = الشيخ للتجارة والتوزيع
- company_phone = NULL
- store_name = الروائع
- store_logo = NULL
- store_primary_color = #2563eb
- store_secondary_color = #1e40af
- payment_method = both
- currency = SAR
- delivery_fee = 0.00
- min_invoice_amount = 0.00
- tax_rate = 0.00
- free_shipping_threshold = 0
- main_branch_id = a38332b6-6cea-480a-ada1-6eb6ab0590db
- status = trial
- trial_end_date = NULL
- subscription_end_date = NULL
- runsheet_serial = 1
- order_serial = 1
- updated_at = 2026-09-13 06:10:00.144+00

---

# 2) استرجاع تاريخ Settings قبل أي تعديل

## Historical Mother Contract

النسخة الأصلية من Settings كانت موجودة منذ البداية كموديول واضح داخل `main.html` وكان هدفها:

- قراءة app_settings.
- عرض إعدادات الفاتورة والرسوم.
- إعدادات الشركة والشعار.
- قسم منفصل لـZATCA.

النسخة الأصلية كذلك كانت تعرض:

- vat_number
- registered_name
- business_address

لكن هذه الحقول لم تثبت كجزء من Production schema الحالي.

## Historical save-settings

الـEdge التاريخي كان يعاني من:

- قراءة `app_settings` بدون tenant scope.
- fallback إلى company ثابت.
- whitelist قديمة.
- عدم وجود عقد واضح لتدفق permissions الحالي.

هذا ليس Current Contract.

---

# 3) Current RW_Settings forensic reconstruction

الكتلة الحالية في Mother:

```
var RW_Settings = (function() {
...
})();
window.RW_Settings = RW_Settings;
```

موجودة في:

```
companies/company-1/main.html
blob:
65484a74a3c3fd0b7f5b6ba5ed056c1409a1d029
```

وتم تحديدها بدقة من:

- السطر 5141 حتى السطر 5264 في الـblob الحالي.

### ما تفعله حاليًا

1. تقرأ `app_settings` بشكل company-scoped باستخدام `_rwCompanyId()`.
2. تعرض:
   - delivery_fee
   - min_invoice_amount
   - tax_rate
   - currency
   - company_name
   - company_logo
3. تعرض قسم ZATCA قديم.
4. تحفظ عبر:
   `/functions/v1/save-settings`

### المشكلة الأولى — ZATCA stale consumer

Current Source يرسل:

```
vat_number
registered_name
business_address
```

لكن Current Production schema لا يحتوي هذه الأعمدة.

والـsave-settings الحالي لا يدعمها.

إذن البطاقة القديمة ليست contract حاليًا؛ استمرار إرسالها يخلق failure أو payload غير مدعوم.

**الإجراء:** أُزيلت هذه الحقول من الجراحة الجديدة، ولم تتم إضافة أعمدة مخترعة لها.

---

# 4) Root Cause الحقيقي الذي أثبته التحقيق

## ROOT CAUSE A — Settings UI / Production contract drift

الواجهة الحالية كانت تحتوي حقولًا غير موجودة في Production schema.

هذا ليس نقص UI بسيطًا؛ إنه اختلاف بين:

```
Current Source Contract
      ≠
Current Production Contract
```

---

## ROOT CAUSE B — save-settings v13 لم يكن يفرض settings permission

Current RLS كان يفرض permission، لكن الـEdge نفسه كان يقبل مستخدمًا Active داخل الشركة دون أن يطبق نفس permission contract.

هذا جعل الحارس موزعًا بدل أن يكون موحدًا.

تم إغلاق ذلك الآن في:

```
save-settings v14
→ save_system_settings_atomic
```

---

## ROOT CAUSE C — direct DML surface على app_settings

Production كانت تمنح:

```
anon        INSERT / UPDATE / DELETE
authenticated INSERT / UPDATE / DELETE
```

رغم أن الـapplication current consumer يستخدم Edge.

هذا يعني أن وجود RLS وحده لم يكن كافيًا لضمان:

```
Settings Write
=
Canonical Gateway
```

### الإصلاح

تم revoke:

```
INSERT
UPDATE
DELETE
TRUNCATE
TRIGGER
REFERENCES
```

عن:

```
anon
authenticated
```

وأصبح:

```
anon          = SELECT
authenticated = SELECT
service_role  = write
postgres      = internal
```

وبذلك يصبح الـwriter المقصود:

```
RW_Settings
↓
save-settings
↓
save_system_settings_atomic
↓
app_settings
+
audit_log
```

---

## ROOT CAUSE D — Store PWA يقرأ free_shipping_threshold فعليًا بينما العمود كان غير موجود

Current Store PWA يقرأ:

```
app_settings.free_shipping_threshold
```

ويستخدمه في منطق المتجر.

لكن Production schema كان لا يحتويه.

هذا Contract Gap حقيقي وليس افتراضًا.

### الإصلاح

تمت إضافة:

```
free_shipping_threshold numeric
NOT NULL
DEFAULT 0
```

مع:

```
CHECK (free_shipping_threshold >= 0)
```

---

## ROOT CAUSE E — no-op save كان يحرك updated_at

النسخة الأولى من RPC الجديد كانت تحدث:

```
updated_at = now()
```

حتى عندما لا تتغير أي قيمة فعلية.

تم اكتشافه أثناء runtime verification.

تم تصحيح السلوك بحيث:

```
semantic no-op
→ لا UPDATE
→ لا updated_at change
→ لا audit row
```

وهذا مهم لأن app_settings موجود أصلًا في Supabase Realtime.

---

# 5) Production Contract الذي تم بناؤه

## Canonical Writer

تم إنشاء:

```
public.save_system_settings_atomic(
    p_company_id uuid,
    p_actor_user_id uuid,
    p_actor_email text,
    p_owner_verified boolean,
    p_settings jsonb
)
```

### مسؤولياته

- company existence
- actor existence
- actor Active
- actor company match
- actor auth_id existence
- settings permission
- OWNER semantics
- field whitelist
- type validation
- color validation
- currency validation
- non-negative numeric validation
- tax range validation
- main branch company validation
- license owner-only guard
- semantic no-op detection
- atomic app_settings write
- atomic audit_log write
- return authoritative settings snapshot

---

# 6) Production permission contract

الـRPC يطابق العقد الحالي:

```
OWNER
=
isOwner
+
permissions[*]
+
owner_profile
```

كما يحافظ على إمكانية:

```
user.permissions.settings
```

أو:

```
role.permissions.settings
```

للتعديلات العامة.

أما:

```
status
trial_end_date
subscription_end_date
```

فهي OWNER-only.

---

# 7) الحقول المعتمدة في Settings الآن

## General — editable

```
company_name
company_phone
company_logo

store_name
store_logo
store_primary_color
store_secondary_color

currency
delivery_fee
min_invoice_amount
tax_rate
free_shipping_threshold

main_branch_id
```

## System / operational — read only داخل صفحة Settings

```
payment_method
runsheet_serial
order_serial
status
trial_end_date
subscription_end_date
updated_at
```

### لماذا payment_method read-only؟

Production الحالية تثبت قيمة `both`.

لكن لم يثبت من Current Source عقد enum رسمي يسمح لنا باختراع قاموس جديد مثل:

```
cash
card
credit
both
```

لذلك لم يتم اختراع semantics غير مثبتة.

---

# 8) لماذا لم تتم إضافة ZATCA fields؟

لم تثبت Current Production schema:

```
vat_number
registered_name
business_address
```

ولذلك:

```
NO GUESS
NO FAKE COLUMN
NO UI DEBT
```

المكان الصحيح لاحقًا:

```
Company Legal / Tax Identity Contract
```

وليس إدخال 3 أعمدة مجهولة في app_settings.

---

# 9) لماذا لم تتم إضافة كل وظائف المنافسين؟

لأن المنافسين يملكون عقودًا أكثر اتساعًا من RAWAEA.

لكن إضافة وظائف بلا Production Contract ستكون إعادة للخطأ نفسه.

## Odoo

Odoo 19 يفصل بين General Settings وCompany-specific settings، ويدعم multi-company access والـcompany selector، مع إمكانية الإعدادات الخاصة بالشركة.

Source:
https://www.odoo.com/documentation/19.0/applications/general/companies/multi_company.html

https://www.odoo.com/documentation/19.0/applications/general/users.html

## Microsoft Dynamics 365 Business Central

Company Information موزعة منطقيًا إلى:

- General
- Communication
- Payments
- Shipping
- Tax

Source:
https://learn.microsoft.com/en-us/dynamics365/business-central/quick-start-company-information

https://learn.microsoft.com/en-ca/dynamics365/business-central/admin-company-information

## SAP

SAP يوسع الإعدادات على مستوى Business Place وOfficial Document Numbering، بما في ذلك الفروع والترقيم الرسمي.

Source:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/88520ff2932b479090ed3b7b116b2e91/4062d2ffd1c1424b93874bf2a330d44c.html

https://help.sap.com/docs/SAP_S4HANA_CLOUD/0c676015e0414931bdc9ebacd6eb2dff/a347756c5aba47898fbcbc716ecf70a6.html

## Daftra

Daftra يضع Branch Settings مستقلة، مع:

- Main Branch
- branch sharing
- account branch behavior

ويضع Default Tax ضمن Sales/Invoicing settings.

Source:
https://docs.daftra.com/en/user_manual/adding-and-managing-branches/

https://docs.daftra.com/en/tutorial/branches-settings/

https://docs.daftra.com/en/tutorial/default-tax-in-sales-settings/

## Manager.io

Manager يربط Settings بـBusiness Details وLocalized Features وCustom Fields وForm Defaults، مع Change/Audit-oriented history.

Source:
https://www2.manager.io/guides/22137

https://www2.manager.io/guides/8941

https://www2.manager.io/guides/14059

### النتيجة المعمارية

الـcompetitive gap الحقيقي لـRAWAEA ليس “عدد inputs”.

الهدف هو:

```
ONE SETTINGS PAGE
+
MULTI-DOMAIN CONTROL
+
AUTHORITATIVE CONTRACT
+
AUDIT
+
REALTIME
+
NO PARALLEL WRITERS
```

---

# 10) UX / Functional target الناتج من التحقيق

Settings الجديدة ستصبح Page حقيقية، وليس Modal.

**مهم:**
Current RW_Settings بالفعل route/page مستقلة؛ لذلك لم تكن هناك حاجة لتحويل Modal قديم هنا.

النسخة الجديدة المقترحة للـPage تحتوي على:

### Header ثابت

- عنوان Settings
- Section navigation
- Save All

### Summary strip

- Main Branch
- Currency
- Status
- Last Update

### Section 1 — هوية الشركة

- Company name
- Company phone
- Company logo

### Section 2 — هوية المتجر

- Store name
- Store logo
- Primary color
- Secondary color

### Section 3 — Sales

- Delivery fee
- Minimum invoice
- Tax rate
- Free shipping threshold
- Currency
- Payment method read-only

### Section 4 — Operations

- Main branch
- Order serial read-only
- Runsheet serial read-only
- License state read-only

---

# 11) Data Workflow

## READ

```
Session
↓
_rwCompanyId()
↓
app_settings where company_id = current company
+
branches where company_id = current company
↓
RW_Settings Page
```

## WRITE

```
RW_Settings
↓
save-settings v14
↓
JWT validation
↓
users.auth_id → company
↓
permission / OWNER guard
↓
save_system_settings_atomic
↓
app_settings
+
audit_log
↓
Supabase Realtime
```

## No impact on operational field apps

Settings لا تدخل مباشرة في:

- picking
- loading
- delivery
- return
- runsheet creation
- inventory movement
- stock engines

إلا من خلال الحقول التي يثبت أنها consumed بالفعل، مثل:

```
currency
company/store identity
main_branch_id
free_shipping_threshold
```

---

# 12) Production changes executed بالفعل

## Migration 1

Production migration:

```
system_settings_atomic_contract_20260919
```

## Migration 2

Correction:

```
system_settings_atomic_contract_compile_fix_20260919
```

## Migration 3 — final closure

```
system_settings_writer_and_direct_dml_closure_20260919
```

Production migration registry current versions:

```
20260919092114
system_settings_atomic_contract_20260919

20260919092205
system_settings_atomic_contract_compile_fix_20260919

20260919092823
system_settings_writer_and_direct_dml_closure_20260919
```

---

# 13) Current Edge Deployment

Function:

```
save-settings
```

Current Production:

- version = 14
- status = ACTIVE
- verify_jwt = true
- ezbr_sha256 =
`68a3434f3ff13e44695518cb4297df66ff316664bbf3cb6dfc4e125618296a34`

هذا الـEdge أصبح Thin Gateway.

---

# 14) Runtime Verification

## PASS — Owner/general

تم تنفيذ write test للـOwner، وكان:

```
success = true
changed = true
```

مع rollback وتنظيف أثر الاختبار.

## PASS — Accountant/general

```
success = true
changed = false
```

والأهم أن no-op لم يعد يغيّر `updated_at`.

## PASS — Unauthorized general

Sales Manager بلا `settings`:

```
SETTINGS_PERMISSION_REQUIRED
```

## PASS — License escalation

Accountant حاول تعديل:

```
status
```

والنتيجة:

```
OWNER_REQUIRED_FOR_LICENSE_SETTINGS
```

## PASS — Legacy fields

إرسال:

```
vat_number
```

والنتيجة:

```
UNSUPPORTED_SETTINGS_FIELDS:vat_number
```

## PASS — Branch isolation

main_branch_id غير تابع للشركة:

```
MAIN_BRANCH_COMPANY_MISMATCH
```

## PASS — Direct DML closure

Production grants أصبحت:

```
anon          SELECT
authenticated SELECT
service_role  full write
postgres      internal
```

---

# 15) Production data repair

لم يتم إدخال أي business data جديد.

تم فقط:

1. إضافة `free_shipping_threshold = 0` كـdefault schema-supported field.
2. إجراء runtime test.
3. تنظيف أثر test.
4. إعادة `company_phone = NULL`.
5. إعادة `updated_at` إلى snapshot المعتمد:
   `2026-09-13 06:10:00.144+00`.
6. audit_log الخاصة بـapp_settings = 0 بعد تنظيف اختبارات الجلسة.

---

# 16) Static Source Verification

تم اختبار كتلة RW_Settings الجراحية الجديدة منفردة باستخدام JavaScript parser.

```
Node syntax check = PASS
```

لم يتم إدخالها داخل main.html لأن Owner هو صاحب عملية دمج Mother source حسب قاعدة المهمة.

---

# 17) الجراحة المطلوبة في Mother main.html

## العنصر المعيب الذي يجب حذفه

في:

```
papamohammed77-glitch/erp-frontend
companies/company-1/main.html
blob:
65484a74a3c3fd0b7f5b6ba5ed056c1409a1d029
```

ابحث **حرفيًا** عن:

```
var RW_Settings = (function() {
```

ابدأ الحذف من هذا السطر.

انتهِ عند السطر:

```
window.RW_Settings = RW_Settings;
```

احذف الكتلة كاملة، ثم استبدلها **بالكتلة التالية كاملة دون حذف أي جزء منها**:

```javascript
var RW_Settings = (function() {
    var currentSettings = {};
    var currentBranches = [];
    var companyId = null;

    function escapeHtml(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function fmtNumber(value) {
        var n = Number(value);
        if (!Number.isFinite(n)) return '0';
        return n.toLocaleString('en-US', { maximumFractionDigits: 2 });
    }

    function imageFallback() {
        return 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22400%22 height=%22240%22%3E%3Crect fill=%22%23f1f5f9%22 width=%22400%22 height=%22240%22/%3E%3Ctext fill=%22%2394a3b8%22 font-family=%22Arial%22 font-size=%2224%22 x=%2250%25%22 y=%2252%25%22 text-anchor=%22middle%22%3ENo Logo%3C/text%3E%3C/svg%3E';
    }

    function uploadLogo(file, folder) {
        if (!file) return Promise.resolve(null);
        if (!/^image\//i.test(file.type || '')) {
            return Promise.reject(new Error('الملف المختار ليس صورة'));
        }
        if (file.size > 3 * 1024 * 1024) {
            return Promise.reject(new Error('حجم الشعار يجب ألا يتجاوز 3 ميجابايت'));
        }

        var safeName = String(file.name || 'logo')
            .replace(/[^A-Za-z0-9._-]+/g, '-')
            .replace(/^-+|-+$/g, '');
        if (!safeName) safeName = 'logo';

        var fileName = folder + '/' + Date.now() + '-' + safeName;

        return supabase.storage
            .from('product-images')
            .upload(fileName, file, { upsert: true, cacheControl: '31536000' })
            .then(function(result) {
                if (result.error) throw new Error(result.error.message || 'فشل رفع الشعار');
                var pub = supabase.storage.from('product-images').getPublicUrl(fileName);
                return pub.data && pub.data.publicUrl ? pub.data.publicUrl : null;
            });
    }

    function sectionButton(id, icon, label) {
        return '<button type="button" data-settings-section="' + id + '" class="flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100 transition">' +
            '<i class="fa-solid ' + icon + '"></i><span>' + label + '</span></button>';
    }

    function field(label, id, type, value, extra, help) {
        return '<div class="flex flex-col gap-2">' +
            '<label for="' + id + '" class="text-sm font-extrabold text-slate-700">' + label + '</label>' +
            '<input id="' + id + '" type="' + type + '" value="' + escapeHtml(value) + '" ' + (extra || '') +
            ' class="w-full h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm font-bold text-slate-800 focus:outline-none focus:ring-4 focus:ring-blue-100 focus:border-blue-500">' +
            (help ? '<div class="text-[11px] text-slate-500">' + help + '</div>' : '') +
            '</div>';
    }

    function colorField(label, id, value, help) {
        return '<div class="flex flex-col gap-2">' +
            '<label for="' + id + '" class="text-sm font-extrabold text-slate-700">' + label + '</label>' +
            '<div class="flex items-center gap-3">' +
            '<input id="' + id + '" type="color" value="' + escapeHtml(value || '#2563eb') + '" class="h-12 w-16 rounded-xl border border-slate-200 bg-white p-1 cursor-pointer">' +
            '<input id="' + id + '-text" type="text" value="' + escapeHtml(value || '#2563eb') + '" maxlength="7" class="flex-1 h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm font-bold text-slate-800">' +
            '</div>' +
            (help ? '<div class="text-[11px] text-slate-500">' + help + '</div>' : '') +
            '</div>';
    }

    function syncColorPair(colorId) {
        var color = byId(colorId);
        var text = byId(colorId + '-text');
        if (!color || !text) return;
        color.addEventListener('input', function() { text.value = color.value; });
        text.addEventListener('input', function() {
            var value = text.value.trim();
            if (/^#[0-9A-Fa-f]{6}$/.test(value)) color.value = value;
        });
    }

    function readNumber(id) {
        var el = byId(id);
        var value = el ? Number(el.value) : NaN;
        if (!Number.isFinite(value) || value < 0) throw new Error('قيمة غير صالحة في الحقل: ' + id);
        return value;
    }

    function readPayload() {
        var primary = (byId('settings-primary-color-text')?.value || '#2563eb').trim();
        var secondary = (byId('settings-secondary-color-text')?.value || '#1e40af').trim();

        if (!/^#[0-9A-Fa-f]{6}$/.test(primary)) throw new Error('اللون الأساسي يجب أن يكون بصيغة #RRGGBB');
        if (!/^#[0-9A-Fa-f]{6}$/.test(secondary)) throw new Error('اللون الثانوي يجب أن يكون بصيغة #RRGGBB');

        var branch = byId('settings-main-branch');
        if (!branch || !branch.value) throw new Error('يجب تحديد الفرع الرئيسي');

        return {
            company_name: (byId('settings-company-name')?.value || '').trim(),
            company_phone: (byId('settings-company-phone')?.value || '').trim() || null,
            company_logo: currentSettings.company_logo || null,
            store_name: (byId('settings-store-name')?.value || '').trim(),
            store_logo: currentSettings.store_logo || null,
            store_primary_color: primary,
            store_secondary_color: secondary,
            currency: byId('settings-currency')?.value || 'SAR',
            delivery_fee: readNumber('settings-delivery-fee'),
            min_invoice_amount: readNumber('settings-min-invoice'),
            tax_rate: readNumber('settings-tax-rate'),
            free_shipping_threshold: readNumber('settings-free-shipping-threshold'),
            main_branch_id: branch.value
        };
    }

    function renderReadOnlySummary() {
        var branch = currentBranches.find(function(b) { return b.id === currentSettings.main_branch_id; });
        safeHTML(byId('rw-settings-summary'), '' +
            '<div class="grid grid-cols-2 lg:grid-cols-4 gap-3">' +
            '<div class="rounded-2xl border border-slate-200 bg-slate-50 p-4"><div class="text-[11px] font-bold text-slate-500">الفرع الرئيسي</div><div class="mt-1 font-black text-slate-800">' + escapeHtml(branch ? branch.name : 'غير محدد') + '</div></div>' +
            '<div class="rounded-2xl border border-slate-200 bg-slate-50 p-4"><div class="text-[11px] font-bold text-slate-500">العملة</div><div class="mt-1 font-black text-slate-800">' + escapeHtml(currentSettings.currency || 'SAR') + '</div></div>' +
            '<div class="rounded-2xl border border-slate-200 bg-slate-50 p-4"><div class="text-[11px] font-bold text-slate-500">حالة النظام</div><div class="mt-1 font-black text-slate-800">' + escapeHtml(currentSettings.status || 'trial') + '</div></div>' +
            '<div class="rounded-2xl border border-slate-200 bg-slate-50 p-4"><div class="text-[11px] font-bold text-slate-500">آخر تحديث</div><div class="mt-1 font-black text-slate-800">' + escapeHtml(currentSettings.updated_at || '—') + '</div></div>' +
            '</div>'
        );
    }

    function refreshFormFromState() {
        var ids = {
            'settings-company-name': currentSettings.company_name || '',
            'settings-company-phone': currentSettings.company_phone || '',
            'settings-store-name': currentSettings.store_name || '',
            'settings-delivery-fee': currentSettings.delivery_fee ?? 0,
            'settings-min-invoice': currentSettings.min_invoice_amount ?? 0,
            'settings-tax-rate': currentSettings.tax_rate ?? 0,
            'settings-free-shipping-threshold': currentSettings.free_shipping_threshold ?? 0,
            'settings-currency': currentSettings.currency || 'SAR',
            'settings-main-branch': currentSettings.main_branch_id || ''
        };
        Object.keys(ids).forEach(function(id) {
            var el = byId(id);
            if (el) el.value = ids[id];
        });

        ['settings-primary-color', 'settings-secondary-color'].forEach(function(id) {
            var color = byId(id);
            var text = byId(id + '-text');
            var value = id === 'settings-primary-color' ? (currentSettings.store_primary_color || '#2563eb') : (currentSettings.store_secondary_color || '#1e40af');
            if (color) color.value = value;
            if (text) text.value = value;
        });

        var companyPreview = byId('settings-company-logo-preview');
        var storePreview = byId('settings-store-logo-preview');
        if (companyPreview) companyPreview.src = currentSettings.company_logo || imageFallback();
        if (storePreview) storePreview.src = currentSettings.store_logo || imageFallback();
        renderReadOnlySummary();
    }

    async function loadData() {
        companyId = _rwCompanyId();
        if (!companyId) throw new Error('سياق الشركة غير محدد');

        var settingsResult = await supabase.from('app_settings')
            .select('id,company_id,company_name,company_phone,company_logo,store_name,store_logo,store_primary_color,store_secondary_color,payment_method,currency,delivery_fee,min_invoice_amount,tax_rate,free_shipping_threshold,main_branch_id,runsheet_serial,order_serial,status,trial_end_date,subscription_end_date,updated_at')
            .eq('company_id', companyId)
            .limit(1)
            .maybeSingle();

        if (settingsResult.error) throw new Error(settingsResult.error.message);
        if (!settingsResult.data) throw new Error('إعدادات الشركة غير موجودة');

        currentSettings = settingsResult.data;

        var branchesResult = await supabase.from('branches')
            .select('id,branch_code,name,is_active')
            .eq('company_id', companyId)
            .order('branch_code', { ascending: true });

        if (branchesResult.error) throw new Error(branchesResult.error.message);
        currentBranches = (branchesResult.data || []).filter(function(b) { return b.is_active !== false; });
        if (!currentBranches.length) throw new Error('لا توجد فروع نشطة للشركة');
    }

    function build() {
        var container = byId('rw-page-container');
        if (!container) return;

        var branchOptions = currentBranches.map(function(b) {
            return '<option value="' + escapeHtml(b.id) + '"' + (b.id === currentSettings.main_branch_id ? ' selected' : '') + '>' +
                escapeHtml(b.branch_code + ' — ' + b.name) + '</option>';
        }).join('');

        var html = '' +
            '<div class="max-w-7xl mx-auto pb-28">' +
            '<div class="sticky top-0 z-30 -mx-4 px-4 pt-2 pb-3 bg-slate-50/95 backdrop-blur">' +
            '<div class="rounded-3xl border border-slate-200 bg-white shadow-sm p-4">' +
            '<div class="flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4">' +
            '<div><div class="flex items-center gap-3"><div class="w-12 h-12 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center"><i class="fa-solid fa-sliders text-xl"></i></div>' +
            '<div><h1 class="text-2xl font-black text-slate-900">إعدادات النظام</h1><div class="text-xs font-bold text-slate-500 mt-1">مركز الإعدادات الموحد للشركة والمتجر والتشغيل</div></div></div></div>' +
            '<div class="flex items-center gap-2 flex-wrap">' +
            sectionButton('identity', 'fa-building', 'هوية الشركة') +
            sectionButton('store', 'fa-store', 'هوية المتجر') +
            sectionButton('sales', 'fa-receipt', 'المبيعات') +
            sectionButton('operations', 'fa-code-branch', 'التشغيل') +
            '<button type="button" id="rw-settings-save-all" class="px-5 py-3 rounded-xl bg-blue-600 text-white text-sm font-black shadow-md hover:bg-blue-700 transition"><i class="fa-solid fa-floppy-disk ml-2"></i>حفظ كل الإعدادات</button>' +
            '</div></div></div></div>' +

            '<div id="rw-settings-summary" class="mt-4"></div>' +

            '<section id="settings-section-identity" class="mt-6 scroll-mt-32">' +
            '<div class="rounded-3xl bg-white border border-slate-200 shadow-sm overflow-hidden">' +
            '<div class="p-6 border-b border-slate-100"><h2 class="text-lg font-black text-slate-900"><i class="fa-solid fa-building text-blue-600 ml-2"></i>هوية الشركة</h2><p class="text-xs text-slate-500 mt-1">بيانات الشركة التي يعتمد عليها النظام في العرض والمستندات.</p></div>' +
            '<div class="p-6 grid grid-cols-1 lg:grid-cols-2 gap-5">' +
            field('اسم الشركة', 'settings-company-name', 'text', currentSettings.company_name || '', 'maxlength="200" required', 'الاسم التشغيلي المسجل حاليًا في إعدادات الشركة.') +
            field('هاتف الشركة', 'settings-company-phone', 'tel', currentSettings.company_phone || '', 'maxlength="50" inputmode="tel"', 'بيانات الاتصال الأساسية.') +
            '<div class="lg:col-span-2 rounded-2xl border border-slate-200 p-5 bg-slate-50/70"><div class="flex items-center justify-between mb-4"><div><div class="font-black text-slate-800">شعار الشركة</div><div class="text-[11px] text-slate-500">يظهر في واجهات ومستندات النظام التي تستخدم company_logo.</div></div></div><div class="flex flex-col md:flex-row items-start md:items-center gap-5"><img id="settings-company-logo-preview" src="' + escapeHtml(currentSettings.company_logo || imageFallback()) + '" onerror="this.src='' + imageFallback() + ''" class="w-24 h-24 rounded-2xl border border-slate-200 bg-white object-contain p-2"><div><input type="file" id="settings-company-logo-file" accept="image/*" class="text-xs file:py-2 file:px-4 file:rounded-xl file:border-0 file:bg-blue-50 file:text-blue-700"><div class="text-[11px] text-slate-500 mt-2">PNG/JPG/WebP — بحد أقصى 3MB.</div></div></div></div>' +
            '</div></div></section>' +

            '<section id="settings-section-store" class="mt-6 scroll-mt-32">' +
            '<div class="rounded-3xl bg-white border border-slate-200 shadow-sm overflow-hidden">' +
            '<div class="p-6 border-b border-slate-100"><h2 class="text-lg font-black text-slate-900"><i class="fa-solid fa-store text-emerald-600 ml-2"></i>هوية المتجر والواجهة</h2><p class="text-xs text-slate-500 mt-1">الإعدادات المرتبطة بالمتجر الإلكتروني والمظهر العام.</p></div>' +
            '<div class="p-6 grid grid-cols-1 lg:grid-cols-2 gap-5">' +
            field('اسم المتجر', 'settings-store-name', 'text', currentSettings.store_name || '', 'maxlength="200" required', 'الاسم الذي يقرأه Store PWA من app_settings.store_name.') +
            '<div class="lg:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-5">' +
            colorField('اللون الأساسي', 'settings-primary-color', currentSettings.store_primary_color || '#2563eb', 'محصور بصيغة #RRGGBB.') +
            colorField('اللون الثانوي', 'settings-secondary-color', currentSettings.store_secondary_color || '#1e40af', 'محصور بصيغة #RRGGBB.') +
            '</div>' +
            '<div class="lg:col-span-2 rounded-2xl border border-slate-200 p-5 bg-slate-50/70"><div class="font-black text-slate-800 mb-4">شعار المتجر</div><div class="flex flex-col md:flex-row items-start md:items-center gap-5"><img id="settings-store-logo-preview" src="' + escapeHtml(currentSettings.store_logo || imageFallback()) + '" onerror="this.src='' + imageFallback() + ''" class="w-24 h-24 rounded-2xl border border-slate-200 bg-white object-contain p-2"><div><input type="file" id="settings-store-logo-file" accept="image/*" class="text-xs file:py-2 file:px-4 file:rounded-xl file:border-0 file:bg-emerald-50 file:text-emerald-700"><div class="text-[11px] text-slate-500 mt-2">يُحفظ في نفس مخزن الشعارات المستخدم حاليًا.</div></div></div></div>' +
            '</div></div></section>' +

            '<section id="settings-section-sales" class="mt-6 scroll-mt-32">' +
            '<div class="rounded-3xl bg-white border border-slate-200 shadow-sm overflow-hidden">' +
            '<div class="p-6 border-b border-slate-100"><h2 class="text-lg font-black text-slate-900"><i class="fa-solid fa-receipt text-amber-600 ml-2"></i>إعدادات المبيعات والتسعير</h2><p class="text-xs text-slate-500 mt-1">قيم افتراضية مستهلكة فعليًا بواسطة النظام والمتجر.</p></div>' +
            '<div class="p-6 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">' +
            field('رسوم التوصيل الافتراضية', 'settings-delivery-fee', 'number', currentSettings.delivery_fee ?? 0, 'min="0" step="0.01"', 'قيمة غير سالبة.') +
            field('الحد الأدنى للفاتورة', 'settings-min-invoice', 'number', currentSettings.min_invoice_amount ?? 0, 'min="0" step="0.01"', 'قيمة غير سالبة.') +
            field('نسبة الضريبة (%)', 'settings-tax-rate', 'number', currentSettings.tax_rate ?? 0, 'min="0" max="100" step="0.01"', 'النطاق المسموح 0–100%.') +
            field('حد التوصيل المجاني', 'settings-free-shipping-threshold', 'number', currentSettings.free_shipping_threshold ?? 0, 'min="0" step="0.01"', 'تمت إضافته لأن Store PWA الحالي يقرأ هذا المفتاح فعليًا.') +
            '<div class="flex flex-col gap-2"><label for="settings-currency" class="text-sm font-extrabold text-slate-700">العملة</label><select id="settings-currency" class="w-full h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm font-bold text-slate-800"><option value="SAR">ريال سعودي (SAR)</option><option value="EGP">جنيه مصري (EGP)</option><option value="AED">درهم إماراتي (AED)</option><option value="KWD">دينار كويتي (KWD)</option><option value="QAR">ريال قطري (QAR)</option><option value="BHD">دينار بحريني (BHD)</option><option value="OMR">ريال عماني (OMR)</option><option value="USD">دولار أمريكي (USD)</option></select><div class="text-[11px] text-slate-500">القيم المسموح بها محكومة أيضًا في Production.</div></div>' +
            '<div class="rounded-2xl border border-slate-200 bg-slate-50 p-4"><div class="text-[11px] font-bold text-slate-500">نمط الدفع المحفوظ</div><div class="mt-1 text-sm font-black text-slate-800">' + escapeHtml(currentSettings.payment_method || 'both') + '</div><div class="text-[11px] text-slate-500 mt-1">عرض فقط؛ لم يتم اختراع قاموس قيم جديد لهذا الحقل.</div></div>' +
            '</div></div></section>' +

            '<section id="settings-section-operations" class="mt-6 scroll-mt-32">' +
            '<div class="rounded-3xl bg-white border border-slate-200 shadow-sm overflow-hidden">' +
            '<div class="p-6 border-b border-slate-100"><h2 class="text-lg font-black text-slate-900"><i class="fa-solid fa-code-branch text-indigo-600 ml-2"></i>التشغيل والتحكم</h2><p class="text-xs text-slate-500 mt-1">قيم تشغيلية مرتبطة بدورة المخزون والتطبيقات المنفصلة.</p></div>' +
            '<div class="p-6 grid grid-cols-1 lg:grid-cols-2 gap-5">' +
            '<div class="flex flex-col gap-2"><label for="settings-main-branch" class="text-sm font-extrabold text-slate-700">الفرع الرئيسي</label><select id="settings-main-branch" class="w-full h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm font-bold text-slate-800">' + branchOptions + '</select><div class="text-[11px] text-slate-500">يُحفظ فقط إذا كان الفرع تابعًا لنفس الشركة، ثم تُزامن projection الموجودة في companies.</div></div>' +
            '<div class="rounded-2xl border border-slate-200 p-5 bg-slate-50"><div class="font-black text-slate-800 mb-3">قيم نظامية للقراءة فقط</div><div class="grid grid-cols-2 gap-3"><div><div class="text-[11px] text-slate-500">عداد أوامر البيع</div><div class="font-black">' + fmtNumber(currentSettings.order_serial) + '</div></div><div><div class="text-[11px] text-slate-500">عداد الرانشيت</div><div class="font-black">' + fmtNumber(currentSettings.runsheet_serial) + '</div></div><div><div class="text-[11px] text-slate-500">حالة الترخيص</div><div class="font-black">' + escapeHtml(currentSettings.status || 'trial') + '</div></div><div><div class="text-[11px] text-slate-500">آخر تحديث</div><div class="font-black text-xs">' + escapeHtml(currentSettings.updated_at || '—') + '</div></div></div></div>' +
            '</div></div></section>' +

            '<div class="fixed bottom-4 left-4 right-4 xl:left-[310px] xl:right-[34px] z-40 pointer-events-none"><div class="max-w-7xl mx-auto flex justify-end"><div class="pointer-events-auto rounded-2xl border border-slate-200 bg-white/95 backdrop-blur shadow-lg px-3 py-3 flex items-center gap-3"><span id="rw-settings-save-state" class="text-xs font-bold text-slate-500">لا توجد تغييرات محفوظة</span><button type="button" id="rw-settings-save-bottom" class="px-5 py-3 rounded-xl bg-blue-600 text-white text-sm font-black hover:bg-blue-700 transition"><i class="fa-solid fa-floppy-disk ml-2"></i>حفظ</button></div></div></div>' +
            '</div>';

        safeHTML(container, html);
        refreshFormFromState();
        syncColorPair('settings-primary-color');
        syncColorPair('settings-secondary-color');

        byId('settings-currency').value = currentSettings.currency || 'SAR';

        function markDirty() {
            var label = byId('rw-settings-save-state');
            if (label) label.textContent = 'هناك تغييرات غير محفوظة';
        }

        container.querySelectorAll('input,select,textarea').forEach(function(el) {
            if (el.type !== 'file') el.addEventListener('input', markDirty);
            el.addEventListener('change', markDirty);
        });

        container.querySelectorAll('[data-settings-section]').forEach(function(btn) {
            btn.addEventListener('click', function() {
                var target = byId('settings-section-' + btn.getAttribute('data-settings-section'));
                if (target) target.scrollIntoView({ behavior: 'smooth', block: 'start' });
            });
        });

        ['settings-company-logo-file','settings-store-logo-file'].forEach(function(id) {
            var input = byId(id);
            if (!input) return;
            input.addEventListener('change', function() {
                var file = input.files && input.files[0];
                if (!file) return;
                var reader = new FileReader();
                reader.onload = function(e) {
                    var previewId = id.indexOf('company') >= 0 ? 'settings-company-logo-preview' : 'settings-store-logo-preview';
                    var preview = byId(previewId);
                    if (preview) preview.src = e.target.result;
                    markDirty();
                };
                reader.readAsDataURL(file);
            });
        });

        var saveButtons = [byId('rw-settings-save-all'), byId('rw-settings-save-bottom')].filter(Boolean);
        saveButtons.forEach(function(btn) {
            btn.addEventListener('click', save);
        });

        async function save() {
            try {
                var payload = readPayload();

                var companyFile = byId('settings-company-logo-file')?.files?.[0];
                var storeFile = byId('settings-store-logo-file')?.files?.[0];

                showLoader('جاري تجهيز إعدادات النظام...');
                if (companyFile) {
                    payload.company_logo = await uploadLogo(companyFile, 'logos');
                }
                if (storeFile) {
                    payload.store_logo = await uploadLogo(storeFile, 'store-logos');
                }

                var result = await _saveSettings(payload);
                if (!result || !result.success) throw new Error(result?.error || result?.msg || 'فشل حفظ الإعدادات');

                currentSettings = result.settings || Object.assign({}, currentSettings, payload);
                hideLoader();
                refreshFormFromState();

                var state = byId('rw-settings-save-state');
                if (state) state.textContent = result.changed ? 'تم حفظ الإعدادات بنجاح' : 'لا توجد تغييرات جديدة';

                var companyInput = byId('settings-company-logo-file');
                var storeInput = byId('settings-store-logo-file');
                if (companyInput) companyInput.value = '';
                if (storeInput) storeInput.value = '';

                showToast(result.changed ? 'تم حفظ إعدادات النظام' : 'لا توجد تغييرات جديدة', 'success');
            } catch (e) {
                hideLoader();
                showToast(e.message || 'فشل حفظ الإعدادات', 'error');
            }
        }
    }

    async function render() {
        safeText(byId('rw-header-title'), 'إعدادات النظام');
        showLoader('جاري تحميل الإعدادات...');
        try {
            await loadData();
            build();
        } catch (e) {
            console.error('RW_Settings.render', e);
            var c = byId('rw-page-container');
            if (c) safeHTML(c, '<div class="max-w-3xl mx-auto p-8"><div class="rounded-3xl border border-red-200 bg-red-50 p-6 text-red-800"><div class="font-black text-lg">تعذر تحميل إعدادات النظام</div><div class="text-sm mt-2">' + escapeHtml(e.message || 'خطأ غير معروف') + '</div></div></div>');
        } finally {
            hideLoader();
        }
    }

    async function _saveSettings(payload) {
        var sessionRes = await supabase.auth.getSession();
        if (sessionRes.error || !sessionRes.data || !sessionRes.data.session || !sessionRes.data.session.access_token) {
            throw new Error('جلسة المصادقة غير صالحة أو منتهية');
        }

        var response = await fetch(RW_SUPABASE_URL + '/functions/v1/save-settings', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + sessionRes.data.session.access_token
            },
            body: JSON.stringify(payload)
        });

        var json = await response.json().catch(function() { return {}; });
        if (!response.ok || !json.success) {
            throw new Error(json.error || json.msg || ('HTTP ' + response.status));
        }
        return json;
    }

    return { render: render };
})();
window.RW_Settings = RW_Settings;
```

### لا تعدل

- RW_Views
- sidebar permissions
- RW_OwnerLicense
- أي module آخر
- أي business/warehouse app
- أي inventory engine

---

# 18) ما الذي تغير وظيفيًا في Surgery

البديل الجديد يحقق:

- Page وليس Modal
- company-scoped read
- exact field contract
- company identity
- store identity
- company/store logos
- colors
- delivery/min invoice/tax
- free-shipping threshold
- currency
- main branch
- payment method visibility بدون اختراع enum
- readonly operational state
- single Save All
- sticky navigation
- dirty-state feedback
- upload validation
- Edge-only save
- no stale ZATCA payload
- graceful errors
- no direct table write

---

# 19) Open Boundary — لا يجوز الادعاء بإغلاقها الآن

لا يوجد Browser Production PASS في هذه الجلسة لأن:

```
main.html
```

تعمدنا عدم تعديله.

إذن:

```
Production Settings Contract = CLOSED
Production Writer Surface = CLOSED
Production Security Surface = CLOSED
Surgical Mother Replacement = READY
Static Patch Parse = PASS
Browser E2E = PENDING OWNER CUTOVER
```

ولا يجوز تحويل:

```
Static PASS
]

إلى:

```
Browser PASS
```

---

# 20) Downstream consumer gap تم اكتشافه ولم يتم كسره

Current Store PWA ما زال لديه read pattern تاريخي:

```
app_settings.select('*').limit(1)
```

وهذا خارج نطاق Settings writer closure.

لم يتم تعديله هنا لأن:

- Settings page نفسها أصبحت company-scoped.
- Store read contract يحتاج Closure مستقل.
- لا يجوز خلط Store consumer repair مع Settings writer repair.

كما أن Store PWA لديه semantics غير موحدة في استخدام `free_shipping_threshold`:
بعض المسارات تستخدم fallback إلى 200، بينما checkout يعتمد القيمة الحالية بطريقة مختلفة.

هذه **مشكلة downstream consumer منفصلة**، وليست سببًا لإعادة فتح Settings writer.

---

# 21) What was NOT changed

```
main.html                = NOT MODIFIED
RW_Reports_Comprehensive = NOT MODIFIED
Inventory                 = NOT MODIFIED
Picking                   = NOT MODIFIED
Loading                   = NOT MODIFIED
Delivery                  = NOT MODIFIED
Returns                   = NOT MODIFIED
Runsheets                 = NOT MODIFIED
Sales                     = NOT MODIFIED
Finance                   = NOT MODIFIED
HR                        = NOT MODIFIED
CRM                       = NOT MODIFIED
```

---

# 22) Final Self-Audit

## What I Proved

- Current System HEAD revalidated.
- Current Mother HEAD revalidated.
- Mother main blob revalidated.
- Historical Settings source reviewed.
- Current RW_Settings located exactly.
- Current app_settings schema revalidated.
- Current permissions revalidated.
- Current Production row revalidated.
- Current Edge v14 deployed and active.
- Settings permission gap closed.
- Direct DML surface closed.
- free_shipping_threshold gap closed.
- no-op updated_at defect closed.
- stale ZATCA consumer removed from surgical target.
- Audit writer added atomically.
- Production tests passed for allowed and rejected cases.
- Mother surgical block parses successfully.

## What I Did Not Prove

- Browser Production E2E after Owner cutover.
- Visual QA in the live Mother page after replacing the block.

## What Could Still Be Wrong

- Owner may paste a partial block instead of exact replacement.
- Mother deployment may lag current commit.
- A browser-only integration defect may appear after cutover.
- Store PWA downstream semantics for free_shipping_threshold remain a separate closure.

---

# 23) تعليمات المساعد التالي — البداية الصحيحة

ابدأ **وليس من الصفر**.

الترتيب الإلزامي:

```
READ CURRENT_STATE
↓
READ REPORT 250
↓
VERIFY SYSTEM HEAD
↓
VERIFY MOTHER HEAD
↓
VERIFY main.html blob
↓
VERIFY save-settings v14
↓
VERIFY app_settings schema/grants
↓
VERIFY current settings row
↓
CHECK whether Owner integrated exact RW_Settings block
```

إذا لم يتم دمج Surgery:

```
لا تعدّل Production مرة أخرى
لا تعيد إنشاء RPC
لا تعيد بناء Edge
لا تعيد إصلاح app_settings
```

نفذ فقط:

```
OWNER SOURCE CUTOVER
↓
NODE STATIC CHECK
↓
BROWSER E2E
↓
Settings READ
↓
Change one general setting
↓
Reload
↓
Verify Persistence
↓
Verify Audit
↓
Verify Realtime
↓
Verify Main Branch projection
↓
Verify Store consumer
```

إذا ظهر خطأ جديد بعد ذلك:

```
FOUND
↓
ROOT CAUSE
↓
HISTORICAL REVIEW
↓
CURRENT SOURCE
↓
CURRENT PRODUCTION
↓
SURGICAL FIX
↓
TEST
↓
DEPLOY
↓
VERIFY
↓
CLOSE
```

ولا تعيد إصلاح شيء أُثبت إغلاقه إلا بدليل Regression جديد.

---

# 24) FINAL STATUS

```
SYSTEM SETTINGS FORENSIC = COMPLETE
PRODUCTION SETTINGS CONTRACT = CLOSED
PRODUCTION SECURITY SURFACE = CLOSED
PRODUCTION DATA REPAIR = COMPLETE
CURRENT EDGE = DEPLOYED
CURRENT SOURCE PATCH = READY
MAIN.HTML CTO EDITS = 0

OWNER CUTOVER = OPEN
BROWSER E2E = OPEN
FULL SETTINGS CLOSURE = OPEN UNTIL OWNER CUTOVER
```

---

# END REPORT 250
