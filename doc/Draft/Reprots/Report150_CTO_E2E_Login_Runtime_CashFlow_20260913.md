# Report150 — التحقيق الجنائي E2E Login بعد انتقال العطل من Syntax إلى Runtime

**التاريخ:** 2026-09-13  
**المرحلة:** E2E — النظام الأم `main.html`  
**نوع المهمة:** Runtime / Login Bootstrap / Finance Module  
**Source of Truth:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html` على `main`  

---

## 1. المبدأ الحاكم — نقطة البداية

**الـSource of Truth الوحيد في هذه المهمة هو الملف المنشور الحالي:**

```text
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
```

ولا يجوز اعتبار `Current/PWA/main2` أو `Original/PWA/main` أو أي تقرير تاريخي مصدرًا للكود الحالي. استخدمت المصادر التاريخية فقط لإعادة بناء لماذا وصل الجزء الحالي إلى تركيبته الحالية.

القاعدة المنفذة:

```text
UNDERSTAND
→ RECONSTRUCT HISTORICAL CONTRACT
→ TRACE CURRENT GIT
→ TRACE RUNTIME FAILURE
→ TRACE DEPENDENCY CONTRACT
→ SURGICAL OWNER FIX
→ VERIFY
```

ولا يوجد في هذا التقرير أي ادعاء بأن شاشة الدخول مغلقة قبل إعادة النشر وإعادة اختبار المتصفح بعد الإصلاح.

---

## 2. آخر Production/Git reality قبل الحكم

### Published Main

المصدر الحالي في `erp-frontend` يحمل:

```text
Branch = main
Latest inspected commit = a91bae00418b040a8687547cf2437036f8661b0d
Current main.html blob SHA = 26a8148682685e20f54b2cac074d898ee4ba5264
HTML source timestamp comment = 2026-09-13 07:00 UTC
```

والـcommit الأخير هو `Update main.html`، وكان parent له هو commit Report149 السابق `1048877b6bec6152332d102e11782a036b61e09f`.

هذا يثبت أن المالك طبق مجموعة إصلاحات Report149 السبعة بعد التقرير السابق.

### Assembly Governance

`forensic_main_assembly.yml` في `rawaie-erp-New` حاليًا يعلن صراحة:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
```

وهذا متسق مع القرار الحالي، وليس مع ملفات `main2`.

---

## 3. نتيجة التغيير عن Report149

Report149 كان يعالج سبعة Syntax roots.

المصدر الحالي لم يعد يحمل نفس العطل؛ والدليل المباشر أن Console في الاختبار الحالي وصل إلى:

```text
main:174 ✅ Supabase Client initialized successfully
```

ثم توقف JavaScript عند:

```text
main:11967 Uncaught ReferenceError: _cashFlow is not defined
    at main:11967:12
    at main:11976:3
    at main:17476:3
```

إذن:

```text
Report149 Syntax blocker = تجاوز بنجاح في المصدر الحالي
Current blocker = Runtime ReferenceError
```

وهذا ليس استنتاجًا من التقرير؛ بل تغيير مباشر ومثبت في Console والمصدر الحالي.

---

## 4. ROOT CAUSE — `_cashFlow` غير معرّفة

تم فتح المصدر الحالي مباشرة عند منطقة الخطأ.

الـ`RW_Finance` IIFE يحتوي على:

```javascript
function _balanceSheet() {
    ...
}

function _costCenterProfitLoss() {
    ...
}
```

ولا توجد بينهما أو في نطاق `RW_Finance` الحالية دالة:

```javascript
function _cashFlow() { ... }
```

لكن `_renderReports()` يعرّف زرًا يستدعي:

```javascript
RW_Finance._cashFlow()
```

كما أن الـreturn object في نهاية `RW_Finance` يعرّف:

```javascript
_cashFlow: _cashFlow,
```

والجزء الحالي عند السطر 11967 يتضمن هذا الاسم صراحة.

النتيجة:

```text
_identifier export = موجود
_function declaration = مفقودة
_runtime evaluation = ReferenceError
```

وبما أن هذا يحدث أثناء تقييم الـIIFE نفسه، فإن الخطأ يمكن أن يوقف تنفيذ بقية الـscript قبل إكمال boot/login bindings اللاحقة، وهو ما يفسر استمرار الوقوف عند شاشة الدخول رغم إصلاح Syntax السابق.

---

## 5. لماذا لا يجوز حذف `_cashFlow` من الـreturn object

تم رفض حل ترقيعي من النوع:

```javascript
// حذف _cashFlow: _cashFlow
```

لأن المصدر الحالي نفسه يحتوي على زر:

```javascript
onclick="RW_Finance._cashFlow()"
```

إذًا وجود capability الخاصة بالتدفقات النقدية جزء من عقد واجهة المالية الحالية، وليست مرجعًا ميتًا فقط.

الحل الصحيح هو **إعادة الوظيفة المفقودة في موضعها**، لا حذف العقد الذي يعتمد عليها.

---

## 6. Historical reconstruction

تمت مقارنة تركيب `RW_Finance` الحالي مع `Current/PWA/main2/main8.md` و`Original/PWA/main/main8.md`.

النتيجة التاريخية المهمة:

- `main8` هو مصدر وحدة المالية.
- يحتوي على `_balanceSheet()` ثم `_costCenterProfitLoss()` ثم `_accountActivity()`.
- يحتوي أيضًا على زر التدفقات النقدية وعلى:
  ```javascript
  _cashFlow: _cashFlow,
  ```
- لكن لا يحتوي هو الآخر على implementation مكتمل لـ`function _cashFlow()`.

إذن العيب ليس إنشاءً جديدًا في `main.html`؛ بل **قدرة تم الإعلان عنها وظيفيًا لكنها سقطت أثناء التجميع/الاستكمال**.

هذا يفسر لماذا لا يجوز نسخ دالة قديمة غير موجودة أصلًا.

---

## 7. Production contract المرتبط بالحل

تم البحث في Production Supabase مباشرة، وتم العثور على RPC حالي صالح باسم:

```text
public.get_cash_flow(p_from_date date, p_to_date date)
```

وتوقيعه الحالي:

```text
get_cash_flow(p_from_date date, p_to_date date)
```

ويعيد:

```text
category
account_id
account_name
amount
```

والـRPC يستخدم مباشرة:

```sql
app_private.current_user_company_id()
```

لتحديد الشركة من `auth.uid()`، وليس `LIMIT 1` على `app_settings`.

وتعريف `app_private.current_user_company_id()` الحالي يعتمد على:

```sql
SELECT u.company_id
FROM public.users u
WHERE u.auth_id=auth.uid()
  AND u.status IS DISTINCT FROM 'Inactive'
LIMIT 1
```

لذلك عقد الـread الخاص بالتدفقات النقدية موجود فعليًا في Production ولا نحتاج لاختراع SQL جديد في الواجهة.

---

## 8. Production runtime verification للـRPC

تمت محاكاة Session داخليًا داخل Transaction غير دائمة باستخدام مستخدم Production حقيقي من الشركة الرئيسية، دون تعديل دائم على قاعدة البيانات.

النتيجة:

```text
auth.uid() = user auth id الذي تم حقنه في request.jwt.claims
current_user_company_id() = company 00000000-0000-0000-0000-000000000001
```

ثم تم استدعاء:

```text
get_cash_flow(current_date-30,current_date)
```

بدون أخطاء.

لا توجد حركة مالية ضمن نافذة الاختبار الحالية، ولذلك لم تُرجع صفوف بيانات، لكن **RPC نفسه قابل للاستدعاء بعقده الحالي ويحل Company Context من Session**.

لا يوجد تعديل دائم على Production نتيجة هذا الاختبار.

---

## 9. السبب الحقيقي لاستمرار مشكلة Login

الـConsole الحالي يثبت:

```text
Supabase Client initialized = PASS
main.html parsing = progressed past Syntax stage
RW_Finance IIFE initialization = FAIL
ReferenceError `_cashFlow` = ROOT CURRENT BLOCKER
Login E2E = not reachable to valid closure while this top-level runtime error exists
```

إذن المشكلة الحالية ليست:

```text
Cache
Supabase initialization
Tailwind warning
```

وليست إثباتًا بحد ذاتها على فشل `signInWithPassword`.

هي:

```text
Missing Finance function during top-level script evaluation
```

---

## 10. الـTailwind warning

الرسالة:

```text
cdn.tailwindcss.com should not be used in production.
```

ما زالت موجودة.

لكنها Warning وليست exception، ولم توقف تنفيذ الـscript.

لذلك لا تُعتبر سبب شاشة الدخول في هذه الـClosure Unit.

---

## 11. الإصلاح الجراحي المطلوب في النظام الأم

**المساعد لم يعدّل `erp-frontend/companies/company-1/main.html`، احترامًا لفصل المسؤوليات.**

### FIX-150-01 — إعادة تعريف `_cashFlow()` بالكامل

**موضع الإضافة الدقيق:**

في الملف:

```text
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
```

**موضع الإضافة:** قبل السطر الحالي الذي يبدأ بـ:

```javascript
    function _costCenterProfitLoss() {
```

وهو موضع `main.html` الحالي حول **line 11756**.

لا تحذف `_costCenterProfitLoss()`.

ابحث عن **السطر الكامل**:

```javascript
    function _costCenterProfitLoss() {
```

وأضف **فوقه مباشرة** الدالة الكاملة التالية:

```javascript
    function _cashFlow() {
        var out = byId('report-output');
        if (!out) return;

        var fromEl = byId('rp-from');
        var toEl = byId('rp-to');
        var fromDate = fromEl && fromEl.value
            ? fromEl.value
            : new Date().toISOString().slice(0, 10);
        var toDate = toEl && toEl.value
            ? toEl.value
            : new Date().toISOString().slice(0, 10);

        if (!fromDate || !toDate || fromDate > toDate) {
            safeHTML(
                out,
                '<div class="text-center py-8 text-red-500">نطاق التاريخ غير صالح.</div>'
            );
            return;
        }

        safeHTML(
            out,
            '<div class="text-center py-8">' +
                '<i class="fa-solid fa-spinner fa-spin"></i> ' +
                'جاري تحميل التدفقات النقدية...' +
            '</div>'
        );

        supabase.rpc('get_cash_flow', {
            p_from_date: fromDate,
            p_to_date: toDate
        }).then(function(res) {
            if (res.error) throw res.error;

            var rows = Array.isArray(res.data) ? res.data : [];
            var categoryLabels = {
                operating_inflow: 'تدفقات تشغيلية داخلة',
                operating_outflow: 'تدفقات تشغيلية خارجة',
                investing: 'أنشطة استثمارية',
                financing: 'أنشطة تمويلية'
            };
            var categoryTotals = {
                operating_inflow: 0,
                operating_outflow: 0,
                investing: 0,
                financing: 0
            };

            for (var i = 0; i < rows.length; i++) {
                var category = String(rows[i].category || '');
                var amount = Number(rows[i].amount || 0);
                if (!isFinite(amount)) amount = 0;
                if (!Object.prototype.hasOwnProperty.call(categoryTotals, category)) {
                    categoryTotals[category] = 0;
                }
                categoryTotals[category] += amount;
            }

            var operatingNet =
                Number(categoryTotals.operating_inflow || 0) -
                Number(categoryTotals.operating_outflow || 0);
            var investingNet = Number(categoryTotals.investing || 0);
            var financingNet = Number(categoryTotals.financing || 0);
            var netCashFlow = operatingNet + investingNet + financingNet;

            var html =
                '<div class="bg-white rounded-2xl shadow-sm border p-5">' +
                    '<div class="flex flex-wrap items-center justify-between gap-3 mb-5">' +
                        '<div>' +
                            '<h3 class="font-black text-xl">قائمة التدفقات النقدية</h3>' +
                            '<p class="text-sm text-gray-500 mt-1">من ' +
                                _esc(fromDate) +
                                ' إلى ' +
                                _esc(toDate) +
                            '</p>' +
                        '</div>' +
                        '<div class="text-sm text-gray-500">عقد Production الحالي</div>' +
                    '</div>' +

                    '<div class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-6">' +
                        '<div class="bg-emerald-50 border rounded-xl p-4">' +
                            '<div class="text-xs text-gray-500 mb-1">التشغيلي الصافي</div>' +
                            '<div class="text-xl font-black ' +
                                (operatingNet >= 0 ? 'text-emerald-700' : 'text-red-700') +
                            '">' +
                                _fmtNum(operatingNet) +
                            '</div>' +
                        '</div>' +
                        '<div class="bg-indigo-50 border rounded-xl p-4">' +
                            '<div class="text-xs text-gray-500 mb-1">الاستثماري</div>' +
                            '<div class="text-xl font-black ' +
                                (investingNet >= 0 ? 'text-indigo-700' : 'text-red-700') +
                            '">' +
                                _fmtNum(investingNet) +
                            '</div>' +
                        '</div>' +
                        '<div class="bg-violet-50 border rounded-xl p-4">' +
                            '<div class="text-xs text-gray-500 mb-1">التمويلي</div>' +
                            '<div class="text-xl font-black ' +
                                (financingNet >= 0 ? 'text-violet-700' : 'text-red-700') +
                            '">' +
                                _fmtNum(financingNet) +
                            '</div>' +
                        '</div>' +
                        '<div class="bg-cyan-50 border rounded-xl p-4">' +
                            '<div class="text-xs text-gray-500 mb-1">صافي التدفق</div>' +
                            '<div class="text-xl font-black ' +
                                (netCashFlow >= 0 ? 'text-cyan-700' : 'text-red-700') +
                            '">' +
                                _fmtNum(netCashFlow) +
                            '</div>' +
                        '</div>' +
                    '</div>' +

                    '<div class="overflow-x-auto">' +
                        '<table class="w-full text-sm border">' +
                            '<thead>' +
                                '<tr class="bg-gray-50">' +
                                    '<th class="p-2 border">التصنيف</th>' +
                                    '<th class="p-2 border">الحساب</th>' +
                                    '<th class="p-2 border text-left">المبلغ</th>' +
                                '</tr>' +
                            '</thead>' +
                            '<tbody>';

            if (!rows.length) {
                html +=
                    '<tr>' +
                        '<td colspan="3" class="p-6 text-center text-gray-500">' +
                            'لا توجد حركة مسجلة في الفترة المحددة.' +
                        '</td>' +
                    '</tr>';
            } else {
                for (var r = 0; r < rows.length; r++) {
                    var rowCategory = String(rows[r].category || '');
                    var rowAmount = Number(rows[r].amount || 0);
                    if (!isFinite(rowAmount)) rowAmount = 0;
                    html +=
                        '<tr class="border-t">' +
                            '<td class="p-2 font-bold">' +
                                _esc(categoryLabels[rowCategory] || rowCategory || 'غير محدد') +
                            '</td>' +
                            '<td class="p-2">' +
                                _esc(rows[r].account_name || '') +
                                ' (' +
                                _esc(rows[r].account_id || '') +
                                ')' +
                            '</td>' +
                            '<td class="p-2 text-left font-black ' +
                                (rowAmount >= 0 ? 'text-gray-800' : 'text-red-700') +
                            '">' +
                                _fmtNum(rowAmount) +
                            '</td>' +
                        '</tr>';
                }
            }

            html +=
                            '</tbody>' +
                        '</table>' +
                    '</div>' +

                    '<div class="mt-4 text-xs text-gray-500">' +
                        'التصنيف والقيم أعلاه معروضة وفق دالة Production الحالية get_cash_flow، ' +
                        'دون إنشاء محرك محاسبي موازٍ في الواجهة.' +
                    '</div>' +
                '</div>';

            safeHTML(out, html);
        }).catch(function(e) {
            console.error('RW_Finance._cashFlow', e);
            safeHTML(
                out,
                '<div class="text-center py-8 text-red-500">' +
                    _esc(e && e.message ? e.message : 'فشل تحميل التدفقات النقدية') +
                '</div>'
            );
        });
    }
```

### آخر سطر كامل للدالة الجديدة

لا تترك جزءًا من الدالة.

آخر سطر كامل يجب أن يكون:

```javascript
    }
```

ثم مباشرة بعده يجب أن يبقى في الملف السطر الحالي:

```javascript
    function _costCenterProfitLoss() {
```

ولا تحذف `_cashFlow: _cashFlow,` من return object عند line 11967.

---

## 12. لماذا هذا هو الإصلاح الصحيح

هذا الإصلاح لا يخترع مصدر بيانات جديدًا، ولا يكرر منطق الحسابات في الواجهة.

الواجهة تقوم فقط بـ:

```text
Date Range
→ Supabase RPC get_cash_flow
→ Render result
```

بينما Company Context وتصنيف البيانات يظل داخل Production RPC الحالي.

وهذا يحافظ على:

```text
Single Production Accounting Contract
No parallel calculation engine
No global app_settings company lookup
No deletion of existing Finance capability
```

---

## 13. ما لم يتم تغييره في هذه Closure Unit

```text
erp-frontend/companies/company-1/main.html = NOT MODIFIED BY ASSISTANT

Supabase Production = NOT MODIFIED

Current/PWA/main2 = NOT MODIFIED

Original/PWA/main = NOT MODIFIED
```

لا توجد حاجة إلى تعديل Supabase لهذا العطل لأن `get_cash_flow` موجود ويعمل بعقده الحالي.

---

## 14. المطلوب بعد تطبيق FIX-150-01

المسؤول عن `main.html` يطبق **FIX-150-01 فقط** في الملف المنشور الحالي، ثم ينشر الملف نفسه.

بعد النشر يجب تنفيذ التحقق التالي بالترتيب:

```text
1. Verify Git commit/blob for main.html
2. Open a fresh incognito browser
3. Confirm current published file identity
4. Confirm Console has no ReferenceError `_cashFlow`
5. Confirm `RW_Finance` initializes
6. Confirm login form listener initializes
7. Submit valid login
8. Confirm `auth` session
9. Confirm users/company context
10. Confirm `enterSystem()`
11. Confirm dashboard appears
12. Confirm no new top-level initialization error
```

ثم فقط نفتح العطل التالي إن ظهر.

---

## 15. SELF-AUDIT

### What I Proved

- Current `erp-frontend/main.html` is newer than Report149 and contains the owner-applied syntax fixes.
- Current blob SHA is `26a8148682685e20f54b2cac074d898ee4ba5264`.
- Latest `main.html` commit is `a91bae00418b040a8687547cf2437036f8661b0d`.
- The current Console error is `_cashFlow is not defined` at line 11967.
- `_cashFlow` is exported and called but not declared in the current Finance module.
- The existing Production RPC `get_cash_flow(date,date)` is present.
- The RPC resolves company context through `app_private.current_user_company_id()`.
- A transactional Production runtime test of the RPC completed without error.
- Tailwind warning is not the runtime root cause.

### What I Did Not Prove

- Browser Login E2E PASS after FIX-150-01 because the owner has not yet applied/redeployed this new frontend surgery in the current published file.
- Absence of any later runtime error after `_cashFlow` is repaired.
- Full functional E2E of all tabs and field operations after successful login.

### What I Fixed

No frontend source was changed by the assistant.

The current cycle produced an exact owner surgery based on direct current-source and Production contract evidence.

### What I Initially Missed in This Cycle

The previous checkpoint stopped at Syntax, while the updated production file advanced far enough to reveal a different runtime failure. The missing `_cashFlow` capability was not in the earlier syntax closure because Syntax parsing does not prove top-level symbol binding.

### What Could Still Be Wrong

After `_cashFlow` is restored, another independent runtime/auth/navigation defect may become visible. It must be treated from the new Console evidence only and not guessed in advance.

### Final Confidence

```text
CURRENT SOURCE IDENTITY = HIGH / DIRECTLY VERIFIED
CURRENT `_cashFlow` ROOT CAUSE = HIGH / DIRECTLY VERIFIED
PRODUCTION RPC CONTRACT = HIGH / DIRECTLY VERIFIED
LIVE LOGIN AFTER NEW PATCH = NOT YET PROVEN
```

### Final Closure Status

```text
REPORT149 SYNTAX BLOCKER = SUPERSEDED BY CURRENT SOURCE / NO LONGER THE ACTIVE CONSOLE ROOT
CURRENT RUNTIME BLOCKER = `_cashFlow` MISSING
FIX-150-01 = SURGERY READY / OWNER APPLICATION REQUIRED
SUPABASE CHANGE = NONE REQUIRED FOR THIS ROOT
LOGIN E2E = OPEN
SESSION RESTORE COMPANY-ID = OPEN / SEPARATE
GLOBAL GOLD/DIAMOND = OPEN
```

# END REPORT150
