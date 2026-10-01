# Report389 — التحقيق الجنائي: Owner Wildcard + Items Save/Image + Store Visibility — 2026-10-01

## 0. نقطة الإغلاق المعتمدة

هذه الجلسة بدأت من آخر حالة مثبتة ولم تُعد فتح أي Closure مغلق.

ترتيب الإثبات:
CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → CURRENT DEPLOYMENT EVIDENCE

التقارير السابقة قرائن تاريخية فقط.

### Current Frontend

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
Current HEAD: `768ee12721a85511e38618666c29568f0658615c`
Parent: `bc4d7a02919dcaf82d11bb599e879281cd550737`
Target: `companies/company-1/main.html`
Current target blob: `2b5b763ada7428f96a05c1144c75f13eec5b1492`
Current source: ~32K lines / ~1.756M chars
Inline JavaScript compilation: PASS

آخر Commit للملف نفسه:
`768ee12721a85511e38618666c29568f0658615c`
Message:
`Update HTML for no matching operations message`

الـcommit غير فقط `_renderVoucherHistory()` بإضافة/تثبيت عمود المندوب وempty-state/header، لذلك لا يجوز اعتبار Report388 ما زال pending على Current HEAD.

---

## 1. تصحيح تعارض CURRENT_STATE

`CURRENT_STATE.md` كان يحتوي في قمته حالة أقدم:
HEAD = `bc4d7a...`
blob = `6cb0ac...`

لكن Current Git الآن تقدم إلى:
HEAD = `768ee127...`
blob = `2b5b763...`

والـparent المباشر هو:
`bc4d7a...`

إذن أي تعليمات من CURRENT_STATE تخص:
- إعادة تطبيق Report384
- إعادة تطبيق Report385
- Report386 line-5
- إعادة تثبيت عمود المندوب في `_renderVoucherHistory`

أصبحت تاريخية إذا لم يثبت أن النسخة التي يعمل عليها المستخدم أقدم من Current HEAD.

---

# 2. العمود الذي لا يظهر في التبويبين — الحقيقة الحالية

تم فتح Current `main.html` نفسه.

## Global Voucher Table

`loadVouchers()` يحتوي بالفعل على:
- `custodian_user_id`
- company-scoped users lookup
- `_custodian_name`
- عمود `المندوب`

## DirectSale / DirectReturn history

الدالة:
`async function _renderVoucherHistory(type)`

وتحتوي Current Source بالفعل على:

`<td ...>${esc(r.custodian_name||'—')}</td>`

وعنوان:

`<th>المندوب</th>`

وحالة الفراغ:
`colspan="11"`

هذا ثبت أيضًا من آخر Commit `768ee127...` الذي غيّر هذه المنطقة فعليًا.

### القرار

**لا يوجد الآن عنصر معيب في Current Source خاص بعمود المندوب.**

إذا كان العمود لا يظهر في الشاشة التي أمام المستخدم رغم أن Current Git يحتويه، فالمسار الصحيح في الإغلاق التالي هو:

served artifact → deployment → cache → rendered browser

وليس تعديل `main.html` مرة أخرى.

**لا تُعد جراحة Report388 على Current HEAD.**

---

# 3. السبب الجذري الأول المغلق جزئيًا — إدارة التراخيص لا تظهر

## Current source defect

داخل:

`RW_Auth`
→ `login()`

Current source يعرّف:

`var meta = user.user_metadata || {};`

ثم يبني:

- `currentUser.isOwner` من `meta.isOwner`
- `RW_STATE.permissions` من `meta.permissions`

بدل أن يجعل DB contract الحالي هو مصدر الحقيقة.

هذا يتعارض مع العقد المثبت في Production:

### public.users

`owner@alrawae.com`
- status = Active
- permissions = [`*`]
- auth_id مرتبط بالمستخدم الصحيح

### auth.users

- raw metadata موجود فيه `isOwner=true`
- raw metadata فيه permissions=[`*`]

لكن وجود القيمة في Auth metadata لا يجعلها المصدر الصحيح للسلطة.

---

# 4. Production proof — Owner Wildcard

تم فحص Production مباشرة.

### owner

`public.users.permissions = ["*"]`

### owner profile

الرابط إلى:
`owner_profile.auth_user_id`
سليم.

### license status

`active`

### distribution

من 29 مستخدمًا نشطًا:
- wildcard users = 1
- users with direct `items` permission = 3

إذن wildcard ليس نظام صلاحيات الدور.

إنه **حالة Owner authorization مستقلة**.

---

# 5. لماذا كان التبويب لا يظهر

في Current `main.html`:

`RW_Navigation.menuTree` يحتوي:

```js
{ view: 'license', icon: 'fa-shield-haltered', label: 'إدارة الترخيص', perm: 'owner' }
```

والـowner tab يستخدم:

```js
RW_STATE.app.currentUser.isOwner === true
```

و`RW_OwnerLicense.isOwner()` يستخدم القيمة نفسها.

لكن `RW_Auth.login()` كان يستمد `isOwner` من:

`user.user_metadata`

لا من:
`public.users.permissions=["*"]`

إذن حدثت فجوة:

DB Owner Contract = صحيح
↓
Auth metadata = ليس مصدر السلطة
↓
UI currentUser = قديم/منفصل
↓
owner guard = false
↓
إدارة التراخيص = مخفية

---

# 6. OWNER SURGICAL PATCH — main.html

**المصدر لم يتم تعديله.**

## الملف

`companies/company-1/main.html`

## الدالة

`RW_Auth.login()`

## الموضع الحالي

تقريبًا السطر 1268 إلى السطر 1304.

## ابحث حرفيًا عن العنصر الكامل التالي

ابدأ من:

```js
return RW_SUPABASE_CLIENT
    .from('users')
    .select('company_id, status')
```

واحذف هذا البلوك كاملًا حتى:

```return self.enterSystem();
    });```

أي احذف العنصر الحالي الكامل الذي يبدأ بـ:
`return RW_SUPABASE_CLIENT.from('users')`

وينتهي بـ:
`return self.enterSystem();
    });`

## الاستبدال الكامل

```js
return RW_SUPABASE_CLIENT
    .from('users')
    .select('company_id, status, permissions, name')
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

        var dbPermissions = Array.isArray(profileRes.data.permissions)
            ? profileRes.data.permissions
                .map(function(p) { return String(p).trim(); })
                .filter(function(p) { return !!p; })
            : [];
        var isOwner = dbPermissions.indexOf('*') !== -1;

        RW_STATE.app.authenticated = true;
        RW_STATE.app.currentUser = {
            name: profileRes.data.name || meta.name || user.email,
            email: user.email,
            role: meta.role || 'مدير النظام',
            isOwner: isOwner,
            permissions: dbPermissions
        };

        RW_STATE.permissions = dbPermissions;
        RW_STATE.app.company = {
            id: profileRes.data.company_id,
            name: meta.companyName || 'الروائع ERP',
            logo: meta.companyLogo || 'ر'
        };

        RW_Audit_log('login', 'auth', user.id, null, {
            email: user.email,
            role: meta.role || 'مدير النظام',
            company_id: profileRes.data.company_id
        });

        return self.enterSystem();
    });
```

## نتيجة العقد بعد الاستبدال

`public.users.permissions`
→ `RW_STATE.permissions`

وإذا:
`permissions` تحتوي `*`

فإن:
`currentUser.isOwner = true`

وبذلك:
- Global permissions guard يمر.
- `perm:'owner'` يمر.
- `RW_OwnerLicense.isOwner()` يمر.

### ما لم يتغير

- role_id
- role name
- owner_profile
- license status
- workflow
- database
- Edge Functions

---

# 7. اختبار Source Patch In-Memory

تم تطبيق Owner patch على نسخة In-Memory من Current source.

النتيجة:

- target anchor found = PASS
- complete block replacement = PASS
- inline JavaScript compilation = PASS

كما أن التعديل لا يكرر الدالة ولا ينشئ محرك صلاحيات جديد.

---

# 8. السبب الجذري الثاني — Save Item / Image Failure

## الدالة

`RW_Items`
→ `_handleSaveFromPage()`

## العنصر المعيب

الدالة الداخلية:

`function resolveImageUrlAndSave(item, fileInput, callback)`

الموضع الحالي:

تقريبًا السطر 5578.

## العيب المثبت

عند فشل رفع الصورة:

1. يظهر Toast بالخطأ.
2. يتم أخذ الصورة القديمة.
3. يتم استدعاء `callback(fallbackUrl)`.
4. `executeSave(imageUrl)` يستمر.
5. قد ينتهي السيناريو برسالة نجاح حفظ الصنف رغم أن الصورة الجديدة فشلت.

هذا **False/Partial Success**.

---

# 9. ITEMS IMAGE SURGICAL PATCH — main.html

## ابحث حرفيًا

```js
function resolveImageUrlAndSave(item, fileInput, callback) {
```

واحذف **الدالة كاملة** حتى القوس:

```js
}
```

الذي يأتي قبل التعليق:

```js
// دالة الحفظ الفعلية – تستقبل imageUrl كمعامل
```

## استبدلها بالكامل بهذا العنصر

```js
function resolveImageUrlAndSave(item, fileInput, callback) {
    var file = (fileInput && fileInput.files.length > 0) ? fileInput.files[0] : null;

    if (!file) {
        var existingUrl = (item && item.image_url != null) ? item.image_url : null;
        console.log('📸 لا توجد صورة جديدة. استخدام:', existingUrl);
        callback(existingUrl);
        return;
    }

    console.log('📤 بدء رفع الصورة:', file.name, file.size);

    // اسم ملف آمن – ASCII فقط مع الحفاظ على الامتداد
    var lastDot = file.name.lastIndexOf('.');
    var fileExt = lastDot > -1 ? file.name.substring(lastDot) : '.jpg';
    var safeName = encodeURIComponent(file.name.substring(0, lastDot > -1 ? lastDot : file.name.length));
    var fileName = Date.now() + '-' + safeName + fileExt;

    supabase.storage.from('product-images').upload(fileName, file, { upsert: false })
        .then(function(res) {
            if (res.error) {
                console.error('❌ فشل الرفع:', res.error.message);
                hideLoader();
                showToast('فشل رفع الصورة: ' + res.error.message, 'error');
                return;
            }

            console.log('✅ رفع ناجح. جاري توليد الرابط العام...');
            var publicUrl = supabase.storage.from('product-images').getPublicUrl(fileName).data.publicUrl;
            if (!publicUrl) {
                hideLoader();
                showToast('تم رفع الصورة لكن تعذر إنشاء الرابط العام', 'error');
                return;
            }

            console.log('✅ الرابط العام:', publicUrl);
            callback(publicUrl);
        })
        .catch(function(err) {
            console.error('❌ خطأ شبكة:', err.message);
            hideLoader();
            showToast('فشل رفع الصورة: ' + (err && err.message ? err.message : 'خطأ غير معروف'), 'error');
        });
}
```

### النتيجة

Upload failure
→ stop

ولا يحدث:

Upload failure
→ fallback
→ fake success

كما تم تغيير:
`upsert: true`
إلى:
`upsert: false`

وبالتالي لا توجد كتابة overwrite غير لازمة على صورة موجودة.

---

# 10. Production save-item — الإصلاح المنفذ

Edge Function الحالية:

`save-item`

قبل الإصلاح:
version 13

تم تحديث نفس الـEdge Function:

version 14

بدون إنشاء Function جديدة.

## الإصلاح الأول

أُزيل اعتماد Authorization على:

`user.user_metadata.isOwner`

وأصبح authorization مبنيًا على DB permissions:

- `items`
- أو `*`

## الإصلاح الثاني

تم تثبيت:

`category_id = null`

قبل معالجة التصنيف.

وعند حذف التصنيف من الواجهة أصبح:

`category = null`
و
`category_id = null`

بدل إبقاء FK القديم.

هذا يغلق defect حقيقي في Edit Item وليس capability جديدة.

## لا تغيير في

- company resolution
- opening balance
- stock movement
- item code generation
- category validation
- authentication
- verify_jwt

---

# 11. Production Storage Security — الإصلاح المنفذ

Bucket:

`product-images`

كان يسمح بـPublic Insert.

تم حذف:

- `Public Insert Access`
- duplicate generic authenticated insert policies

ووضع policy واحدة:

`product_images_authenticated_insert_items`

تسمح بالـINSERT فقط للمستخدم authenticated النشط الذي يمتلك:

- `items`
- أو `*`

أو يأتي حقه من role permissions.

أما القراءة العامة فبقيت كما هي لأن صور المتجر الإلكتروني public assets.

### النتيجة

Anonymous/public:
- Read = allowed
- Insert = denied

Authenticated without item privilege:
- Insert = denied

Authenticated with items / owner wildcard:
- Insert = allowed

ولا توجد UPDATE policy لازمة لهذا المسار بعد تحويل الرفع إلى:
`upsert:false`

---

# 12. حفظ الصنف / تعديل الصنف / الصورة / المتجر الإلكتروني

تمت مراجعة Current Items module.

## Current fields الموجودة

### Basic

- name
- barcode
- category
- unit
- alt_unit
- alt_unit_qty
- weight
- volume
- description

### Pricing / Inventory

- sales_price
- old_price
- reorder_point
- max_qty
- max_qty_per_order
- sort_order

### Marketing

- discount_percent
- discount_start
- discount_end
- badge_text
- is_daily_deal
- is_active
- show_in_store

### Media

- image file
- image_url
- preview
- image viewer

إذن الحقول الأساسية ليست ناقصة في Current UI بالنسبة لهذه الوحدة.

---

# 13. Store Visibility

Current Source يرسل:

`show_in_store`

إلى `save-item`.

والـbackend يحفظ:

`show_in_store`

والـOnline Store يقرأ فقط العناصر:

`is_active=true`
و
`show_in_store=true`

و`image_url` يستخدم كصورة المنتج.

إذن مسار:

Item Master
→ save-item
→ items
→ Online Store

موجود ومترابط.

الـbug الحالي المثبت لم يكن في شرط visibility، بل كان في حالة فشل رفع الصورة التي كانت تسمح للحفظ بالاستمرار رغم فشل جزء من العملية.

---

# 14. Production Transactional QA — Create + Opening Stock

تم تنفيذ fixture حقيقي داخل:

`BEGIN ... ROLLBACK`

باستخدام الشركة Production الحالية والفرع BR-01.

العينة:

`__QA_ITEM_MASTER_SAVE_E2E__`

البيانات:

- sales_price = 25
- cost_price = 10
- show_in_store = false
- opening_qty = 2

## النتيجة داخل Transaction

- create success = true
- opening balance posted = true
- branch qty = 2
- allocated_qty = 0
- inventory_log rows = 1
- movement qty = 2
- journal_entries total = 10
- QA journal entries = 0
- item audit rows = 1 أثناء transaction

ثم:

`ROLLBACK`

---

# 15. Production Transactional QA — Edit + Store Visibility

Fixture ثان داخل:

`BEGIN ... ROLLBACK`

تم:

1. إنشاء Item بكمية افتتاحية = 0.
2. التأكد أنه لا توجد حركة مخزنية.
3. تعديل:
   - name
   - sales_price
   - show_in_store=true
   - category_id=null
   - category=null
   - image_url جديد
4. قراءة الحالة.

## النتيجة

- opening_balance_posted = false
- inventory_logs before = 0
- inventory_logs after = 0
- journal_entries before = 10
- journal_entries after = 10
- store eligibility after edit = 1
- category_id after edit = null
- image_url after edit = القيمة الجديدة

ثم:

`ROLLBACK`

وهذا يثبت أن Edit Item لا يغير المخزون أو الحسابات، بينما تغيير show_in_store/image_url يصل إلى Item Master.

---

# 16. Cleanup

بعد اختبارات QA:

- QA items = 0
- QA inventory logs = 0
- QA rollback residue = 0

ولا توجد بيانات تجريبية دائمة.

---

# 17. المحاسبة ورصيد الفرع

## Item Create with opening balance

هذا المسار يستدعي:

`create_item_with_opening_stock`
→ `post_stock_movement`

وبذلك يغير Branch Stock.

في الاختبار:

Branch Stock:
0 → 2

وسُجلت حركة inventory_log واحدة.

لكن هذا المسار لم ينشئ journal entry جديدة في البيانات الحالية؛
journal_entries بقيت 10.

## Item Edit

التعديل المباشر لخصائص الصنف:

- لا يحرك stock
- لا يغير allocated_qty
- لا يغير treasury
- لا ينشئ journal entry

وهذا ثبت بالـtransaction test.

إذن لا يجوز ربط حفظ بيانات الصنف العادية بقيد محاسبي جديد.

---

# 18. أمن Production

## save-item v14

تم التحقق من:

- verify_jwt = true
- status = ACTIVE
- version = 14

ولم يتم إنشاء Edge Function جديدة.

## Storage

تم التحقق من:

`product_images_authenticated_insert_items`

مع استمرار:

`Public Read Access`

ولا يوجد Public Insert بعد الإصلاح.

---

# 19. E2E Status

## Static Source E2E

PASS

- Current source parse
- Owner patch in-memory parse
- Image patch in-memory parse
- item save contract
- item edit contract
- store visibility contract

## Database Transactional E2E

PASS

- create
- opening stock
- edit
- category clear
- store visibility
- image_url persistence
- stock invariance on edit
- accounting invariance on edit
- rollback cleanup

## Operational Workflow E2E

PASS by inherited existing contract

- DirectSale
- DirectReturn
- RECEIVE
- custody
- accounting
- duplicate operation

تم حماية هذه العقود ولم يعاد بناؤها.

## Browser-rendered Production E2E

OPEN

لا توجد في هذه البيئة أداة متاحة لتنفيذ login/click/type داخل المتصفح المنشور.

لذلك لا يتم ادعاء Browser PASS.

## Served Artifact Identity

OPEN

لا يوجد دليل runtime مستقل في هذه الجلسة يثبت أن النسخة التي يراها المستخدم هي blob:

`2b5b763ada7428f96a05c1144c75f13eec5b1492`

أو النسخة التي سيضع عليها المالك Owner Patch.

---

# 20. Benchmark — لماذا هذا الاتجاه مطلوب

### Odoo

الوثائق الرسمية الحالية تضع في إدارة المنتج:
- visibility
- product images/media
- variants
- inventory
- packaging
- pricing
- eCommerce product page
- product-level/variant-level attributes

كما توفر Product Page تخصيص الصورة الرئيسية والوسائط والإظهار في المتجر.

مصادر:
- https://www.odoo.com/documentation/19.0/applications/websites/ecommerce/configuration.html
- https://www.odoo.com/documentation/19.0/applications/websites/ecommerce/ecommerce_design/product_page.html
- https://www.odoo.com/documentation/19.0/applications/sales/sales/products_prices/products/variants.html

### Microsoft Dynamics 365 Business Central

Item Card يجمع بيانات التسعير والتوريد والتخزين والتكلفة والترحيل، ويدعم variants وattributes وpictures وSKUs للتخطيط حسب الموقع/النسخة.

مصادر:
- https://learn.microsoft.com/en-us/dynamics365/business-central/application/base-application/page/microsoft.inventory.item.item-card
- https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-item-variants

### SAP

Product Master موزع على Basic Data وSales وProcurement وPlant/Costing/Valuation وUnit of Measure، مع إمكانات منفصلة لإدارة نصوص البيع والبيانات التنظيمية.

مصادر:
- https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/18fe3fab96864826bfa0be0de4f65b85/3fda6fe0c54f469290127d2082427d70.html
- https://help.sap.com/docs/s4hana-best-practices/create-product-master-of-type-semi-finished-good-bns-fc0c992299bd8a623d54a87f1a3c86a4/create-product-master-data-basic-data

### Manager.io

Inventory Item form يجمع Item Code وItem Name وUnit وPurchase/Sales Price وDescription وControl Account وStarting Balance وAverage Cost، مع تحديث item master دون تعديل المستندات السابقة.

مصدر:
- https://www2.manager.io/guides/7551

### ملاحظة

لم يتم استخدام claim غير موثق من Daftra في الحكم الحالي لعدم توفر مصدر رسمي كافٍ في هذا الفحص.

---

# 21. ما ينقص RAWAEA مقارنة بالـERP الناضج — ولكن ليس ضمن هذا الإصلاح

الفجوات المستقبلية الحقيقية التي تستحق دراسة مستقلة:

1. Variants / attributes.
2. Vendor-specific references.
3. Packaging / barcodes per package.
4. Multiple product images/media.
5. Item translations.
6. Location-specific replenishment parameters.
7. Item-level purchase lead time.
8. Preferred suppliers.
9. Standard/average cost governance.
10. Product lifecycle states.
11. E-commerce category/SEO metadata.
12. Channel-specific price lists.
13. Item audit timeline.
14. Better media lifecycle and orphan-file cleanup.
15. Controlled image replacement/deletion.

هذه **ليست bugs تم إصلاحها في هذه الجلسة**.

لا تُدمج مع Owner/Items surgical closure.

---

# 22. حماية ما سبق

لم يتم إعادة فتح:

- DirectReturn RECEIVE direction
- `custodian_user_id`
- Master Assignment
- global voucher representative mapping
- warehouse voucher workflow
- custody accounting
- inventory core
- owner wildcard DB contract
- existing operational PWAs

ولا تم إنشاء:
- Edge Function جديدة
- RPC جديدة
- جدول جديد
- عمود جديد

---

# 23. Self Audit

| الضابط | الحالة |
|---|---|
| قراءة Governance حتى النهاية | PASS |
| مراجعة CURRENT_STATE | PASS |
| مراجعة أحدث Reports | PASS |
| Current Git | PASS |
| HEAD + Parent | PASS |
| Current Source | PASS |
| Production | PASS |
| Database | PASS |
| Deployment evidence | OPEN |
| عدم الثقة بالتقارير كحالة حالية | PASS |
| عدم إعادة الإصلاحات المغلقة | PASS |
| Owner Wildcard = `*` | PASS |
| License guard root cause | PROVEN |
| Item image failure root cause | PROVEN |
| save-item production repair | DEPLOYED v14 |
| Storage public insert security gap | CLOSED |
| Category clear defect | CLOSED in save-item |
| Opening stock test | PASS + ROLLBACK |
| Item edit test | PASS + ROLLBACK |
| Store visibility test | PASS + ROLLBACK |
| Accounting invariance on edit | PASS |
| Browser E2E | OPEN |
| Served artifact | OPEN |

---

# 24. هل وصلنا إلى مستوى منافسة ERP الرئيسية؟

### هذه الوحدة

نعم من ناحية **contract integrity + integrated master data** أصبحت على مسار ERP حقيقي:

Item Master
→ Pricing
→ Inventory control
→ Branch stock
→ Image
→ Store visibility
→ Audit
→ Central save service

لكن لا يجوز إعلان تكافؤ شامل مع Odoo/Dynamics/SAP؛ لأن Product Master في تلك الأنظمة أوسع من Current RAWAEA، خصوصًا في:
- variants
- attributes
- locations/SKUs
- procurement parameters
- product media
- translations
- costing/valuation dimensions
- e-commerce catalog depth

الحكم الصحيح هنا:
**current unit is integrated and operationally sound, while broader master-data depth remains an open roadmap.**

---

# 25. FINAL CTO VERDICT

## Closed by evidence

### A
Owner identity contract:
`public.users.permissions=["*"]`

### B
Current UI owner guard:
needs the Owner surgical patch in section 6.

### C
Production item save:
secured and deployed as `save-item v14`.

### D
Image save failure:
exact main.html surgical fix ready in section 9.

### E
Category clear:
fixed in Production v14.

### F
Store visibility:
verified by transactional test.

### G
Branch stock:
verified to remain unchanged on Edit.

### H
Accounting:
verified unchanged on Edit.

### I
Representative column:
already present in Current HEAD; do not reapply old patch.

---

# 26. Next exact execution sequence

1. Owner opens Current `main.html`.
2. Applies **Owner surgical replacement** in section 6.
3. Applies **image helper surgical replacement** in section 9.
4. Runs full inline-JS syntax gate.
5. Publishes Current source.
6. Fresh login/session.
7. Verify `إدارة التراخيص`.
8. Verify Items Create.
9. Verify Items Edit.
10. Verify image upload success.
11. Verify image upload failure stops save.
12. Verify show_in_store false hides item from store.
13. Verify show_in_store true returns item to store.
14. Verify representative column in the two voucher views.
15. Verify served artifact identity.
16. Browser E2E.
17. Close only after runtime proof.

---

# 27. تعليمات المساعد التالي للوصول إلى الحقيقة

ابدأ من:
`CURRENT GIT`

ثم:
`CURRENT SOURCE`

ثم:
`CURRENT PRODUCTION`

ثم:
`CURRENT DATABASE`

ثم:
`CURRENT DEPLOYMENT`

ولا تبدأ من Report389.

إذا قال المستخدم إن عمود المندوب لا يظهر:
- لا تفترض أن source ناقص.
- قارن served artifact بالـCurrent blob.
- افحص browser cache/deployment.
- إذا ظهر أن النسخة served أقدم، أصلح deployment drift.
- لا تعيد Report388.

إذا ظهر عيب جديد في Items:
- حدد function + exact string + current line.
- افصل UI bug عن backend contract.
- لا تضف Edge Function جديدة.
- لا تغير inventory writer من أجل مشكلة UI.
- لا تربط Item Master edit بقيد مالي دون business contract مثبت.

# END REPORT389
