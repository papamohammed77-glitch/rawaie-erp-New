# Report74 — المراجعة الجنائية التدقيقية لـ main4 بعد تطبيق Patch Report73

التاريخ: 2026-09-07
المستودع: `papamohammed77-glitch/rawaie-erp-New`
الفرع: `main`
Production: `SMART ERP / fiilmooggumokxanwiyx`

## 1. نقطة الاستمرار

لم تبدأ الجلسة من الصفر.
تمت استعادة الحالة من:

- `CURRENT_STATE.md`
- `Report73_Main4_Surgical_Forensic_20260907.md`
- `MASTER - RAWAEA ERP.md`
- Git history الحالي
- `Current/PWA/main2/main4.md` الحالي
- Production PostgreSQL الحالية
- Production Edge Functions الحالية ذات العلاقة

## 2. آخر Git Verified Event قبل إعادة المراجعة

تم التحقق من commit:

```text
42ab7aeb113d64ea08becb134a8e114165594dc1
Refactor app settings retrieval and currency usage
2026-09-07 09:09:21 UTC
```

وهذا الـcommit عدّل فعليًا:

```text
Current/PWA/main2/main4.md
```

Current main4 blob:

```text
7e99ce1d81e2f594f9c2ed811ce5666914b4ceef
```

إذن تقرير Report73 الذي كان يصف `main4` قبل patch أصبح تاريخيًا بالنسبة للمصدر، وتمت إعادة القراءة من Git الحالي بدل الاعتماد على وصف التقرير.

## 3. MASTER Governance Revalidated

تمت قراءة `MASTER - RAWAEA ERP.md` كاملًا حتى النهاية.
والقواعد الحاكمة المعاد اعتمادها:

```text
CURRENT REALITY > CURRENT GIT > CURRENT PRODUCTION > DEPLOYMENTS > DB CONTRACTS > HISTORICAL > REPORTS > MEMORY > ASSUMPTIONS

READ → VERIFY → RECONCILE → UNDERSTAND → PATCH → VERIFY

ONE CLOSURE UNIT AT A TIME

UNKNOWN ≠ BUG
UNKNOWN ≠ REMOVE

Git PASS ≠ Production PASS
Source PASS ≠ Runtime PASS

لا Closure بلا دليل حالي
```

## 4. main4 Full Re-read Result

تمت قراءة `Current/PWA/main2/main4.md` كاملًا من البداية حتى نهاية `RW_TeleSales` و`})();` النهائي.

النتيجة المهمة:

### Report73 findings that are now actually applied

#### RW_POS

تم بالفعل إصلاح:

```text
company-scoped app_settings
main_branch_id retrieval
main branch company validation
currency from app_settings
branchCode instead of branchId
```

كما تم إزالة الاعتماد على `EGP` داخل POS واستبداله بـ`currency` الحالية.

#### RW_Roles

تم بالفعل إصلاح company scoping في:

```text
initial render read
post-delete read
post-seed read
```

كما أصبح initial roles query:

```javascript
.eq('company_id', _rwCompanyId())
```

#### RW_TeleSales

تم بالفعل إصلاح:

```text
app_settings company scope
branches company scope
stock_branches restricted through company branch IDs
_getAvailable requires selected branch
currency from settings
silent settings fallback was replaced with an error path
```

## 5. New defects discovered by the second full source read

هذه النقاط لم تعد مجرد Findings من Report73؛ بل تم إثباتها من المصدر الحالي بعد تطبيق patch.

### DEFECT-M4-01 — RW_Roles save success uses an out-of-scope variable

المقطع الحالي داخل نجاح `save-role` هو:

```javascript
if (json.success) { showToast(isEdit ? 'تم التعديل' : 'تمت الإضافة', 'success'); Swal.close();  rolesData = dRes.data || []; renderTable(rolesData); }
```

`dRes` تم تعريفه داخل `render()` وليس داخل `openModal()`.

إذن بعد نجاح الحفظ:

```text
save-role = قد ينجح في Production
ثم openModal success handler
→ dRes غير معرف
→ ReferenceError
```

هذا Defect حقيقي في Source، وليس Backend speculation.

### DEFECT-M4-02 — RW_TeleSales _saveOrder يحتوي كتلة Legacy ثانية داخل نفس الدالة

بعد الكتلة الجديدة الخاصة بتحميل `app_settings` وتنفيذ الحفظ توجد كتلة قديمة ثانية داخل `_saveOrder` تبدأ بـ:

```javascript
var total = subtotal + (deliveryFee || 0);
```

ثم تعيد:

```javascript
var orderHeader = { ... }

showLoader('جاري حفظ الأوردر...');

supabase.auth.getSession().then(...)
```

وتستخدم متغيرات مثل:

```text
subtotal
itemsList
```

خارج نطاق تعريفها الجديد.

هذه الكتلة يجب إزالتها بالكامل من `main4`.

القرار الصحيح هو عدم محاولة إصلاح الكتلة القديمة سطرًا بسطر؛ لأن الكتلة الجديدة أصبحت هي المسار المعتمد، ووجود الكتلة القديمة يخلق مسار تنفيذ ثانيًا ونطاقات متضاربة.

## 6. Production Reconciliation — 2026-09-07

تم التحقق مباشرة من Production الحالية.

```text
companies = 1
app_settings = 1
users = 24
roles = 20
customers = 3
suppliers = 1
branches = 2
items = 17
```

الإعدادات الحالية:

```text
company_id = 00000000-0000-0000-0000-000000000001
company_name = الروائع
currency = SAR
main_branch_id = a38332b6-6cea-480a-ada1-6eb6ab0590db
```

الفروع:

```text
BR-01 = الفرع الرئيسي
BR-2  = فرع إسكندرية
```

## 7. Production Contract Verification

### save-sales-invoice

Production RPC contract الحالي:

```text
save_sales_invoice_atomic(
  p_order_header jsonb,
  p_items jsonb,
  p_branch_code text,
  p_user_email text
)
```

إذن استخدام `branchCode` في main4 صحيح.

كما أن الـRPC يشتق الشركة من المستخدم، ويستخدم `operation_id` الموجود في `orderHeader` كهوية عملية.

### save-role

Production Edge Function الحالية:

```text
version = 6
verify_jwt = true
```

وتستخدم `auth_id -> users.company_id` ثم تحفظ `roles.company_id` وفق سياق المستخدم.

إذن إصلاح القراءة في main4 يجب أن يظل company-scoped ولا يحتاج نقل مسؤولية Backend إلى الواجهة.

### delete-role

Production Edge Function الحالية:

```text
version = 2
verify_jwt = true
```

لكنها ما زالت تحذف حسب `roleId` فقط دون company predicate.

هذا بقي مستقلًا ولم يتم خلطه بإصلاح main4، وفق Closure Unit rule.

### seed-roles

Production Edge Function الحالية:

```text
version = 3
verify_jwt = true
```

وهي نقطة Backend مستقلة.

## 8. ما تم اختباره فعليًا

تم تنفيذ:

```text
FULL main4 source read = PASS
CURRENT Git verification = PASS
Latest commit verification = PASS
Production company/settings/branches = PASS
Production save-sales-invoice contract = PASS
Production save-role contract = PASS
Production delete-role contract inspected = PASS
```

تم أيضًا فحص تركيب دالة `_saveOrder` البديلة المقترحة باستخدام JavaScript syntax check مستقل.

```text
Candidate _saveOrder syntax = PASS
```

## 9. ما لم يتم اختباره

```text
Browser E2E = NOT VERIFIED
main4 browser runtime = NOT VERIFIED
Final 11-part assembly = NOT VERIFIED
Full PWA runtime = NOT VERIFIED
Production runtime execution of edited main4 = NOT VERIFIED
```

## 10. تعليمات المستخدم المطلوبة لإغلاق main4

### PATCH-M4-01

ابحث داخل `RW_Roles` عن هذا المقطع كاملًا، وينتهي عند:

```javascript
else { showToast(json.error || 'فشل الحفظ', 'error'); }
```

والجزء المطلوب استبداله هو `if (json.success) { ... }` الموجود قبله تحديدًا.

استبدله بالمقطع:

```javascript
if (json.success) {
    showToast(isEdit ? 'تم التعديل' : 'تمت الإضافة', 'success');
    Swal.close();

    var refreshedRoles = await supabase.from('roles')
        .select('*')
        .eq('company_id', _rwCompanyId())
        .order('created_at', { ascending: true });

    if (refreshedRoles.error) {
        showToast('تم الحفظ لكن تعذر تحديث قائمة الأدوار', 'warning');
        return;
    }

    rolesData = refreshedRoles.data || [];
    renderTable(rolesData);
}
```

### PATCH-M4-02

ابحث عن بداية الدالة:

```javascript
function _saveOrder() {
```

واحذف **الدالة كاملة حتى السطر الذي يسبق مباشرة**:

```javascript
function loadBranches() {
```

ثم ضع مكانها هذه الدالة كاملة:

```javascript
async function _saveOrder() {
    if (!selectedCustomer) {
        showToast('يرجى اختيار عميل أولاً', 'warning');
        return;
    }

    if (!cart.length) {
        showToast('أضف أصنافاً إلى السلة', 'warning');
        return;
    }

    var branchSelect = byId('ts-branch-select');
    var branchCode = branchSelect ? branchSelect.value : '';

    if (!branchCode) {
        showToast('اختر الفرع المصروف منه أولاً', 'warning');
        return;
    }

    showLoader('جاري حفظ الأوردر...');

    try {
        var companyId = _rwCompanyId();
        if (!companyId) {
            throw new Error('سياق الشركة غير محدد');
        }

        var settingsRes = await supabase.from('app_settings')
            .select('min_invoice_amount,delivery_fee,tax_rate,currency')
            .eq('company_id', companyId)
            .order('created_at', { ascending: true })
            .limit(1)
            .maybeSingle();

        if (settingsRes.error || !settingsRes.data) {
            throw new Error('تعذر تحميل إعدادات الشركة، لم يتم حفظ الأوردر');
        }

        var settings = settingsRes.data;
        deliveryFee = Number(settings.delivery_fee) || 0;
        taxRate = Number(settings.tax_rate) || 0;
        currency = settings.currency || 'SAR';
        var minInvoice = Number(settings.min_invoice_amount) || 0;

        var subtotal = 0;
        var itemsList = [];

        for (var i = 0; i < cart.length; i++) {
            var line = cart[i].price * cart[i].qty;
            subtotal += line;
            itemsList.push({
                code: cart[i].code,
                name: cart[i].name,
                price: cart[i].price,
                qty: cart[i].qty,
                unit: cart[i].unit
            });
        }

        var before = subtotal + deliveryFee;
        var taxAmt = Math.round(before * taxRate) / 100;
        var total = before + taxAmt;

        if (minInvoice > 0 && total < minInvoice) {
            showToast(
                'الحد الأدنى للفاتورة: ' + minInvoice + ' ' + currency +
                '. الإجمالي الحالي: ' + total.toLocaleString() + ' ' + currency,
                'warning'
            );
            return;
        }

        var items = RW_STATE.data.items || [];

        for (var k = 0; k < cart.length; k++) {
            var cartItem = cart[k];
            var item = null;

            for (var m = 0; m < items.length; m++) {
                if (items[m].item_code === cartItem.code) {
                    item = items[m];
                    break;
                }
            }

            if (!item) {
                showToast('الصنف غير موجود: ' + cartItem.code, 'error');
                return;
            }

            var available = _getAvailable(item.id);
            if (cartItem.qty > available) {
                showToast(
                    'الرصيد المتاح للصنف "' + (item.name || cartItem.code) +
                    '" غير كافٍ. المتاح: ' + available,
                    'warning'
                );
                return;
            }

            var maxQty = item.max_qty ? Number(item.max_qty) : 0;
            if (maxQty > 0 && cartItem.qty > maxQty) {
                showToast(
                    'الكمية المطلوبة للصنف "' + (item.name || cartItem.code) +
                    '" تتجاوز الحد الأقصى: ' + maxQty,
                    'warning'
                );
                return;
            }
        }

        var orderHeader = {
            operation_id: crypto.randomUUID(),
            customer_code: selectedCustomer.customer_code,
            custName: selectedCustomer.name,
            area: selectedCustomer.area || '',
            total: total,
            deliveryFees: deliveryFee,
            status: 'Confirmed',
            paymentType: selectedCustomer.payment_type || 'أجل',
            taxAmount: taxAmt,
            taxRate: taxRate
        };

        var ses = await supabase.auth.getSession();
        var token = ses.data.session ? ses.data.session.access_token : null;

        if (!token) {
            throw new Error('انتهت الجلسة');
        }

        var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-sales-invoice', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Authorization: 'Bearer ' + token
            },
            body: JSON.stringify({
                orderHeader: orderHeader,
                itemsList: itemsList,
                branchCode: branchCode
            })
        });

        var json = await res.json();

        if (!json.success) {
            throw new Error(json.msg || 'فشل حفظ الأوردر');
        }

        RW_Audit_log('create', 'orders', json.orderID || '', null, orderHeader);
        showToast('تم حفظ الأوردر بنجاح: ' + (json.orderID || ''), 'success');

        cart = [];
        selectedCustomer = null;
        byId('ts-customer-search').value = '';
        byId('ts-customer-info').classList.add('hidden');
        updateCartDisplay();
    } catch (e) {
        console.error(e);
        showToast(e.message || 'فشل الاتصال', 'error');
    } finally {
        hideLoader();
    }
}
```

لا تحذف `function loadBranches() {` ولا تعدل ما بعدها.

## 11. سبب اختيار PATCH-M4-02 بهذه الصورة

لا يوجد داعٍ للإصلاح الجزئي داخل الكتلة القديمة؛ لأنها Legacy execution path ظهرت داخل الدالة نفسها بعد النسخة الجديدة.

استبدال `_saveOrder` بالكامل يحقق:

```text
single execution path
single settings read
single totals calculation
single branch source
single inventory validation path
single API submission
single error/finally path
no duplicated async chain
no out-of-scope variables
```

ولا يغير عقد Backend أو Business contract الخاص بحفظ TeleSales؛ بل يجعل واجهة main4 تطابق الـcontract الحالي.

## 12. Production modifications in this session

لم يتم تنفيذ تعديل Production خاص بـmain4 في هذه الجلسة، لأن الـProduction contracts ذات العلاقة متوافقة بالفعل مع patch المطلوب في المصدر.

لم يتم إنشاء بيانات اختبار دائمة.
ولم يتم تعديل `roles` RLS أو `delete-role` لأنهما Closure Units مستقلة.

## 13. FINAL SELF-AUDIT

### WHAT I PROVED

- `CURRENT_STATE.md` تم استرجاعه ومقارنته بالحاضر.
- `MASTER - RAWAEA ERP.md` تم قراءته كاملًا.
- `Report73` تمت قراءته واعتماد ما ثبت منه فقط.
- آخر commit بعد Report73 هو `42ab7a...` وتم التحقق من أنه عدّل main4 فعليًا.
- `main4.md` الحالي تمت قراءته كاملًا حتى EOF.
- إصلاحات POS وRoles/TeleSales الأساسية من Report73 موجودة في المصدر الحالي.
- Production الحالية = شركة واحدة، إعداد واحد، 24 مستخدمًا، 20 Role، 3 عملاء، مورد واحد، فرعان، 17 صنفًا.
- Production currency = SAR.
- Production main branch = BR-01.
- Production save-sales-invoice contract يستخدم `p_branch_code`.
- يوجد Defect-M4-01 حقيقي في Role save بسبب `dRes` خارج النطاق.
- يوجد Defect-M4-02 حقيقي بسبب بقاء كتلة `_saveOrder` قديمة ثانية.

### WHAT I DID NOT PROVE

- Browser runtime بعد patch المستخدم.
- Runtime success للفواتير أو TeleSales.
- Final 11-part assembly.
- Full PWA Production equivalence.

### CURRENT STATUS

```text
MAIN3 = VERIFIED / DO NOT REOPEN
MAIN4 = REPORT73 PATCH APPLIED / SECOND FORENSIC REVIEW COMPLETE / TWO SOURCE DEFECTS OPEN
DELETE-EMPLOYEE = OPEN / SEPARATE BACKEND CLOSURE
ROLES RLS = OPEN / SEPARATE GOVERNANCE CLOSURE
DELETE-ROLE BACKEND = OPEN / SEPARATE BACKEND CLOSURE
11-PART ASSEMBLY = OPEN
FULL PWA RUNTIME = OPEN
PROJECT = OPEN
```

## 14. NEXT AUTHORIZED ACTION

```text
1. User applies PATCH-M4-01 exactly.
2. User replaces _saveOrder entirely using PATCH-M4-02 exactly.
3. No other main4 edits.
4. Re-read main4.md from first line to EOF.
5. Verify the two defects are gone.
6. Verify there is exactly one _saveOrder definition.
7. Verify no `dRes.data` reference remains inside save-role success handler.
8. Verify `branchCode` is passed exactly as selected branch code.
9. Reconcile Production at that time.
10. Then perform main4 integration/runtime verification where possible.
11. Only after main4 closure, open the next independent Closure Unit.
