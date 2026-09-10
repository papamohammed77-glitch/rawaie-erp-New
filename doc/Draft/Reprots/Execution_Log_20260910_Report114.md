# سجل تنفيذ — Report114 — 2026-09-10

## 1. المصدر الحاكم
تم فتح MASTER التنفيذي الحالي وإعادة تطبيق منهجية:
CURRENT VERIFIED REALITY > CURRENT PRODUCTION > CURRENT DATABASE CONTRACT > CURRENT DEPLOYMENT > CURRENT GIT > CURRENT SOURCE > HISTORICAL REPORTS.

كما تم الالتزام بقاعدة Closure Unit واحدة في كل مرة، وبقاعدة Owner Source Surgery الخاصة بملفات `Current/PWA/main2/main1.md ... main11.md`.

## 2. آخر حدث متحقق
- Git HEAD: `54235973924c95dd20a058e5de034f10a364c430`
- وقت الحدث: `2026-09-10 10:10:56 UTC`
- الملف المتغير: `Current/PWA/main2/main9.md`
- التغيير اللاحق لـReport113: إزالة `DirectReturn` من فلتر المرتجعات، فأصبح المصدر الحالي يستخدم `SalesReturn + Return`.

## 3. Production snapshot
تم القياس مباشرة من Supabase عند:
`2026-09-10 10:22:45.903 UTC`

companies=1; branches=2; users=24; items=17; customers=3; orders=0; runsheets=0; purchase_orders=0; stock_vouchers=0; stock_branches=20; inventory_log=3; receiving=0; journal_entries=2; audit_log=1869.

## 4. Main9
### الحالة
OPEN — لا يجوز إعلان Closed.

### العيب الحالي المثبت
`logistics-returns / r25` يستخدم `SalesReturn` و`Return` فقط.

### الجراحة المطلوبة
يجب أن تكون الحركة:
`SalesReturn` و`DirectReturn` فقط.

### البديل
```javascript
var r25 =
    await supabase
        .from('inventory_log')
        .select(
            'movement_date, movement_type, qty, item_code, item_name, reference, voucher_id'
        )
        .eq(
            'company_id',
            companyId
        )
        .in(
            'movement_type',
            [
                'SalesReturn',
                'DirectReturn'
            ]
        )
        .gte(
            'movement_date',
            fromDate
        )
        .lte(
            'movement_date',
            toDate
        )
        .order(
            'movement_date',
            { ascending: false }
        );
```

### Syntax
Replacement Syntax = PASS بواسطة `node --check` على البديل الجراحي.
Full-file Syntax بعد التطبيق في Owner Source = NOT PROVEN.

## 5. Main10
الحالة:
CURRENT / NO NEW SURGERY.

تم التحقق من أن `_loadLicenseData()` يبدأ من `RW_STATE.app.company.id` مع fallbacks توافقية، ويستخدم `app_settings.eq('company_id', companyId)`.

## 6. Main11
### الحالة
OPEN — Tenant Closure Unit مستقلة.

### العيب الحالي المثبت
`RW_HR.render()` ينفذ:
```javascript
supabase.from('users').select('*')
```
بدون company scope.

### الجراحة المطلوبة
استخدام `var companyId = _rwCompanyId();` والتحقق منه، ثم `.eq('company_id', companyId)`.

### Syntax
Replacement Syntax = PASS بواسطة `node --check` على البديل الجراحي.
Full-file Syntax بعد التطبيق = NOT PROVEN.

## 7. Main2
`_rwCompanyId()` الحالي هو:
```javascript
function _rwCompanyId() {
    return window.RW_STATE && RW_STATE.app && RW_STATE.app.company && RW_STATE.app.company.id ? RW_STATE.app.company.id : null;
}
```

هذا هو الـParent company contract المستخدم في جراحة Main11.

## 8. Inventory Core
تم الإبقاء على الحكم المثبت:
Physical Writers خارج `post_stock_movement` = 0.
لا يوجد أساس لإعادة بناء Inventory Core من الصفر في هذه المرحلة.

## 9. CI / Runtime
آخر Browser Verify على HEAD الحالي فشل في خطوة `Immutable audited target` بسبب عدم تطابق hash لـ`Current/PWA/New-main` مع الـaudited target، قبل مرحلة Chromium. لا يُستخدم هذا الفشل لإثبات وجود Syntax Error في Main9.

## 10. Final closure
- Inventory Physical Core = VERIFIED.
- Main9 = OPEN / SURGERY REQUIRED.
- Main10 = CURRENT.
- Main11 = OPEN / TENANT SURGERY REQUIRED.
- Full-file syntax after Owner Source surgery = NOT PROVEN.
- Main2 Assembly = BLOCKED.
- Browser/PWA smoke = BLOCKED.
- Gold/Diamond = NOT CLOSED.

## 11. Governance conclusion
ليس المتبقي مجرد Assembly للـ11 أجزاء. توجد جراحة Main9 وجراحة Main11، ثم Syntax/Integration/Assembly/Runtime verification قبل إغلاق Gold/Diamond.

## 12. Next authorized action
Main9 surgery → EOF reread → Syntax → Verify → Close Main9.
ثم Main11 surgery → EOF reread → Syntax → Verify → Close Main11.
ثم Full Main2 reconciliation → Assembly → Browser/PWA verification → final closure.
