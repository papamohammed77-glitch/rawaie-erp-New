# Report227 — التحقيق الجنائي في تعطل دخول النظام وإغلاق عقد الإيرادات — 2026-09-17

## 0. التنبيه الحاكم

**الهدف الأساسي في هذه الجلسة ليس إصلاح شاشة فقط. الهدف هو الوصول إلى حقيقة التشغيل الحالية ثم إغلاق النقطة وظيفيًا، مع الحفاظ على العقود التاريخية والعمليات الميدانية والتكامل المحاسبي، وعدم إعلان الإغلاق قبل إثباته.**

**النظام الأم الحالي Source of Truth هو:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

وليس أي Fragment تاريخي. تم التعامل مع:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`
كمصادر الحالة الحالية، بينما التقارير السابقة استُخدمت كدلائل بحث فقط.

تم أيضًا التحقق من `forensic_main_assembly.yml`، وهو يشير بالفعل إلى `erp-frontend/companies/company-1/main.html` كـSource of Truth وإلى `Current/PWA/main2` و`Original/PWA/main` كمصادر تاريخية مرجعية فقط. لذلك لم يكن هناك داعٍ لتعديله.

---

## 1. استرجاع آخر حالة Git وعدم البدء من الصفر

### 1.1 Current Mother Git

المستودع:
`papamohammed77-glitch/erp-frontend`

الحالة الحالية المثبتة:

```text
HEAD = d7bf7ed138fa95b8dfdb88cc407827340954aa43
Message = forensic: persist current Mother inventory extract
```

الـHEAD نفسه كان تحديثًا لسجل forensic extract، وليس تغييرًا وظيفيًا في `main.html`.

الـparent الذي يحمل آخر التغيير الفعلي في Mother هو:

```text
PARENT = 8fff8f4f05ba0c0d95a985a742b58a5890028fdb
Message = Update main.html
```

الـparent أضاف تبويب `revenues` وغيّر `_newReceipt()` وأضاف `_renderRevenues()`، وبالتالي فإن آخر كود وظيفي للـFinance في Mother موجود في محتوى ذلك الـparent وهو نفس المحتوى الجاري اختباره في HEAD الحالي.

Forensic extract الحالي:

```text
FILE_LINES = 25680
FILE_BYTES = 1428900
SHA256 = 868f7028294c7d84fdbbefefff5f11ef3a030f29f507b304e64b36de55339f25
```

---

## 2. `forensic_main_assembly.yml`

تمت مطابقة الملف الحالي مباشرة، وهو صحيح:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

القرار:

```text
لا تعديل مطلوب في forensic_main_assembly.yml
```

---

## 3. التحقيق الجنائي في مشكلة عدم تجاوز شاشة الدخول

### 3.1 الأثر الظاهر في Console

```text
main:15526 Uncaught SyntaxError: Invalid or unexpected token
```

وهذا خطأ Parsing على مستوى JavaScript.

نتيجة التحقيق: المتصفح يتوقف عند parsing للـscript، وبالتالي لا يمكن أن يُبنى runtime الخاص بالنظام الأم بصورة سليمة؛ لذلك فإن فشل الوصول إلى الواجهة بعد شاشة الدخول ليس مجرد مشكلة Authentication backend مثبتة من هذا الخطأ، بل يوجد حاجز Syntax قطعي يسبق تشغيل جزء من التطبيق.

### 3.2 السبب الجذري المثبت

الخطأ أُدخل في آخر تعديل على `_newReceipt()` داخل commit:
`8fff8f4f05ba0c0d95a985a742b58a5890028fdb`

السطر المعيب في المصدر هو بنية string JavaScript تستخدم apostrophe داخليًا مع escaping زائد.

النسخة المعيبة فعليًا:

```js
'onclick="RW_Finance.renderSubTab(\\'receipts\\')" ' +
```

والصحيح:

```js
'onclick="RW_Finance.renderSubTab(\'receipts\')" ' +
```

الفرق جوهري: المطلوب backslash واحد قبل كل apostrophe، وليس backslashين.

### 3.3 عدد المواضع

يوجد موضعان متماثلان داخل `_newReceipt()`:

1. زر الإغلاق في رأس شاشة/Modal الإيراد.
2. زر الإلغاء في نهاية نفس الشاشة.

موضع الخطأ الذي ظهر في Console هو عند السطر التقريبي:
`15526`

ويجب معالجة الموضعين معًا.

### 3.4 اختبار parsing

تم اختبار المقطع المعيب بصورة مستقلة باستخدام JavaScript parser داخل بيئة Node.

النتيجة:

```text
malformed escaping -> FAIL: Invalid or unexpected token
correct escaping   -> PASS
```

إذًا السبب الجذري مثبت، وليس تخمينًا.

### 3.5 رسالة Tailwind

الرسالة:

```text
cdn.tailwindcss.com should not be used in production
```

هي warning تشغيلية من Tailwind وليست سبب SyntaxError عند `main:15526`، ولا يوجد دليل بأنها تمنع parsing أو الدخول.

لا يجب خلط هذه الرسالة مع سبب العطل الحالي.

---

## 4. Revenue: هل نحتاج إنشاء Backend جديد؟

لا.

التحقيق المباشر في Production أثبت أن محرك الإيرادات موجود بالفعل، وبالتالي إنشاء جدول أو Engine آخر سيخلق Dual Write ودينًا معماريًا غير مطلوب.

الكيانات الموجودة فعليًا:

```text
finance_revenues
finance_revenue_lines
finance_revenue_categories
finance_save_revenue
finance_list_revenues_v2
finance_void_revenue
```

كما أن Production تحتوي على:

```text
journal_entries
journal_lines
cash_box
treasury
chart_of_accounts
```

وRLS مفعّل على الجداول المالية والخزينة وCashBox والقيود.

---

## 5. عقد الإيراد الموجود في Production

الـRPC الموجود حاليًا `finance_save_revenue` يثبت عمليًا العناصر التالية:

```text
Company Context
Branch
Treasury
Period Guard
Operation ID / Idempotency
Revenue Account validation
Multiple Revenue Lines
Journal Posting
Cash Box Receipt
Treasury.current_balance increment
```

و`finance_void_revenue` يعكس العملية بصورة متكاملة:

```text
Reverse Journal
CashBox -> Voided
Revenue -> VOID
Treasury balance reversed
```

إذًا العقد الصحيح هو:

```text
إيراد جديد
   ↓
Branch + Treasury
   ↓
1..N Revenue Lines
   ↓
finance_save_revenue
   ↓
Journal
   ↓
Cash Box Receipt
   ↓
Treasury Balance
   ↓
Revenue List / Reports
```

ولا يوجد داعٍ لإنشاء Receipt Engine موازي خاص بالإيراد.

---

## 6. Production E2E للمحاسبة والخزينة — مثبت Transactionally

استخدم الاختبار شركة النظام الحالية وسياق المستخدم الحقيقي المحاكى على مستوى JWT claim داخل Transaction.

### بيانات صحيحة من Production

Branch:

```text
a38332b6-6cea-480a-ada1-6eb6ab0590db
BR-01
الفرع الرئيسي
```

Treasury:

```text
0a9d9357-b5f3-4dfa-886f-7c73de4f274e
CASH-01
الخزينة الرئيسية
```

حسابات الإيراد الموجودة:

```text
9d1217e1-7759-4bef-9537-738cc414cbc8
Code 4
الإيرادات

7b9264f8-4d87-484e-92bc-c0fcab84f90d
Code 41
إيرادات المبيعات
```

### عملية Multi-Line

```text
Line 1 = 10
Line 2 = 20
Total   = 30
```

النتيجة:

```text
success = true
duplicate = false
revenue_rows = 1
revenue_lines = 2
journal_entries = 1
journal_line_rows = 3
cash_box_rows = 1
treasury before = 10000
treasury after = 10030
```

### Retry

إعادة نفس `operation_id` أعادت:

```text
duplicate = true
success = true
```

ولم تُكرر:

```text
Revenue row
CashBox row
Treasury mutation
Journal entry
```

### Void

تم تنفيذ `finance_void_revenue` واختبار العكس:

```text
Revenue status = VOID
CashBox status = Voided
Reversal journal created
Debit = 30
Credit = 30
Treasury returned = 10000
```

كل ذلك داخل Transaction واحدة ثم `ROLLBACK`.

النتيجة: لا توجد بيانات اختبار دائمة في Production.

---

## 7. مشكلة Revenue في Mother الحالية

الـRevenue ليس مفقودًا Backend.

المشكلة في Mother هي أن آخر commit وظيفي أضاف `revenues` وربطه بـ`_renderRevenues()`، وأضاف `_newReceipt()` جديدًا، ولكن الكود يحتوي على عيبين Frontend:

### العيب 1 — Syntax Error

escaping زائد في `renderSubTab('receipts')` داخل `_newReceipt()`.

### العيب 2 — Runtime Scope Error

النسخة الحالية من `_newReceipt()` تحتوي على:

```js
var branchesForRevenue = [];
```

لكن هذه متغير محلي داخل `_newReceipt()`.

بينما `_renderRevenues()` تستخدم `branchesForRevenue` خارج هذا النطاق.

لذلك حتى بعد إصلاح SyntaxError فقط، هناك احتمال runtime failure عند استدعاء Revenue view.

هذا سبب استبدال `_renderRevenues()` كاملًا بدل إصلاح السطر فقط.

---

## 8. Mother Surgical Instructions — التنفيذ على الملف المنشور فقط بواسطة المالك

**المساعد لم يعدّل `erp-frontend/companies/company-1/main.html` نهائيًا.**

### الجراحة رقم 1 — إصلاح SyntaxError

في:

```text
companies/company-1/main.html
```

الموضع المعروف:

```text
around line 15526
function _newReceipt()
```

ابحث حرفيًا عن:

```js
'onclick="RW_Finance.renderSubTab(\\'receipts\\')" ' +
```

**استبدل السطر نفسه حرفيًا بـ:**

```js
'onclick="RW_Finance.renderSubTab(\'receipts\')" ' +
```

كرر نفس الاستبدال في الموضع الثاني المطابق داخل `_newReceipt()`.

لا تغيّر أي `renderSubTab('receipts')` آخر خارج هذين الموضعين.

---

### الجراحة رقم 2 — استبدال `_renderRevenues()` بالكامل

في الملف:

```text
companies/company-1/main.html
```

ابحث حرفيًا عن:

```js
function _renderRevenues() {
```

احذف **الدالة كاملة فقط** حتى القوس الأخير الذي يغلق `_renderRevenues()`، ثم اترك الدالة التالية كما هي.

ضع مكانها هذا الاستبدال الكامل:

```js
async function _renderRevenues() {
    var content = byId('finance-content');
    if (!content) return;

    var companyId = _companyId();
    if (!companyId) {
        safeHTML(content, '<div class="bg-white rounded-2xl border p-6 text-red-600 font-bold">تعذر تحديد الشركة الحالية.</div>');
        return;
    }

    var now = new Date();
    var today = now.toISOString().slice(0, 10);
    var firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().slice(0, 10);

    async function loadRevenueRows(fromDate, toDate) {
        var result = await supabase.rpc('finance_list_revenues_v2', {
            p_company_id: companyId,
            p_from: fromDate,
            p_to: toDate
        });
        if (result.error) throw result.error;
        return result.data || [];
    }

    async function renderResults() {
        var fromInput = byId('fin_rev_from');
        var toInput = byId('fin_rev_to');
        var fromDate = fromInput && fromInput.value ? fromInput.value : firstDay;
        var toDate = toInput && toInput.value ? toInput.value : today;

        if (fromDate > toDate) {
            _showToast('تاريخ البداية يجب أن يسبق تاريخ النهاية.', 'warning');
            return;
        }

        content.dataset.revenueFrom = fromDate;
        content.dataset.revenueTo = toDate;

        safeHTML(content, '<div class="bg-white rounded-2xl border p-8 text-center text-gray-500">جاري تحميل الإيرادات...</div>');

        try {
            var rows = await loadRevenueRows(fromDate, toDate);
            var postedRows = rows.filter(function(r) {
                return String(r.status || '').toUpperCase() !== 'VOID';
            });
            var voidRows = rows.filter(function(r) {
                return String(r.status || '').toUpperCase() === 'VOID';
            });
            var total = rows.reduce(function(sum, r) {
                return sum + Number(r.total_amount || 0) + Number(r.tax_amount || 0);
            }, 0);
            var postedTotal = postedRows.reduce(function(sum, r) {
                return sum + Number(r.total_amount || 0) + Number(r.tax_amount || 0);
            }, 0);

            var html =
                '<div class="space-y-4">' +
                    '<div class="grid grid-cols-1 md:grid-cols-5 gap-3 items-end">' +
                        '<div><label class="block text-sm font-bold mb-1">من تاريخ</label><input id="fin_rev_from" type="date" value="' + _esc(fromDate) + '" class="w-full border rounded-xl p-3"></div>' +
                        '<div><label class="block text-sm font-bold mb-1">إلى تاريخ</label><input id="fin_rev_to" type="date" value="' + _esc(toDate) + '" class="w-full border rounded-xl p-3"></div>' +
                        '<button id="fin_rev_apply" type="button" class="bg-slate-800 text-white px-4 py-3 rounded-xl font-bold">تحديث النتائج</button>' +
                        '<button id="fin_rev_new" type="button" class="bg-emerald-600 text-white px-4 py-3 rounded-xl font-bold"><i class="fa-solid fa-money-bill-trend-up ml-1"></i> إيراد جديد</button>' +
                        '<button id="fin_rev_receipts" type="button" class="bg-white border px-4 py-3 rounded-xl font-bold text-gray-700">سندات القبض</button>' +
                    '</div>' +

                    '<div class="grid grid-cols-1 md:grid-cols-4 gap-3">' +
                        '<div class="bg-white border rounded-2xl p-4"><div class="text-xs text-gray-500">عدد العمليات</div><div class="text-2xl font-black">' + _fmtNum(rows.length) + '</div></div>' +
                        '<div class="bg-emerald-50 border border-emerald-100 rounded-2xl p-4"><div class="text-xs text-emerald-700">الإيرادات المرحلة</div><div class="text-2xl font-black text-emerald-700">' + _fmtNum(postedTotal) + ' EGP</div></div>' +
                        '<div class="bg-slate-50 border rounded-2xl p-4"><div class="text-xs text-gray-500">إجمالي العمليات</div><div class="text-2xl font-black">' + _fmtNum(total) + ' EGP</div></div>' +
                        '<div class="bg-red-50 border border-red-100 rounded-2xl p-4"><div class="text-xs text-red-700">المعكوس</div><div class="text-2xl font-black text-red-700">' + _fmtNum(voidRows.length) + '</div></div>' +
                    '</div>' +

                    '<div class="bg-white rounded-2xl shadow-sm border overflow-hidden">' +
                        '<div class="px-4 py-3 bg-emerald-50 border-b flex flex-wrap justify-between items-center gap-2">' +
                            '<div><div class="font-black text-lg text-emerald-800">الإيرادات</div><div class="text-xs text-emerald-700">قبض نقدي/خزينة مرتبط بالقيد المحاسبي وسند الإيراد.</div></div>' +
                            '<div class="text-xs font-bold text-gray-500">من ' + _esc(fromDate) + ' إلى ' + _esc(toDate) + '</div>' +
                        '</div>' +
                        '<div class="overflow-x-auto">' +
                            '<table class="w-full text-sm border-collapse">' +
                                '<thead><tr class="bg-slate-50 border-b">' +
                                    '<th class="p-3 border">الكود</th>' +
                                    '<th class="p-3 border">التاريخ</th>' +
                                    '<th class="p-3 border">الدافع / الجهة</th>' +
                                    '<th class="p-3 border">الفئة</th>' +
                                    '<th class="p-3 border">الفرع</th>' +
                                    '<th class="p-3 border">الخزينة</th>' +
                                    '<th class="p-3 border">الحسابات</th>' +
                                    '<th class="p-3 border">الإجمالي</th>' +
                                    '<th class="p-3 border">الحالة</th>' +
                                '</tr></thead><tbody>';

            if (!rows.length) {
                html += '<tr><td colspan="9" class="p-10 text-center text-gray-500">لا توجد إيرادات خلال الفترة المحددة.</td></tr>';
            } else {
                for (var i = 0; i < rows.length; i++) {
                    var r = rows[i];
                    var isVoid = String(r.status || '').toUpperCase() === 'VOID';
                    var statusLabel = isVoid ? 'معكوس' : 'مرحل';
                    var statusClass = isVoid ? 'bg-red-100 text-red-700' : 'bg-emerald-100 text-emerald-700';
                    var rowTotal = Number(r.total_amount || 0) + Number(r.tax_amount || 0);
                    html += '<tr class="border-t hover:bg-slate-50">' +
                        '<td class="p-3 border font-bold">' + _esc(r.revenue_code) + '</td>' +
                        '<td class="p-3 border">' + _esc(r.revenue_date) + '</td>' +
                        '<td class="p-3 border">' + _esc(r.payer_name || '—') + '</td>' +
                        '<td class="p-3 border">' + _esc(r.category_name || '—') + '</td>' +
                        '<td class="p-3 border">' + _esc(r.branch_name || r.branch_id || '—') + '</td>' +
                        '<td class="p-3 border">' + _esc(r.treasury_name || r.treasury_id || '—') + '</td>' +
                        '<td class="p-3 border text-center font-bold">' + _fmtNum(r.line_count || 0) + '</td>' +
                        '<td class="p-3 border font-black text-emerald-700">' + _fmtNum(rowTotal) + ' EGP</td>' +
                        '<td class="p-3 border"><span class="px-2 py-1 rounded-full text-xs font-bold ' + statusClass + '">' + statusLabel + '</span></td>' +
                    '</tr>';
                }
            }

            html += '</tbody></table></div></div></div>';
            safeHTML(content, html);

            var applyButton = byId('fin_rev_apply');
            var newButton = byId('fin_rev_new');
            var receiptsButton = byId('fin_rev_receipts');
            if (applyButton) applyButton.onclick = renderResults;
            if (newButton) newButton.onclick = _newReceipt;
            if (receiptsButton) receiptsButton.onclick = function() {
                renderSubTab('receipts');
            };
        } catch (e) {
            safeHTML(content, '<div class="bg-white rounded-2xl border p-6 text-red-600"><div class="font-black mb-2">تعذر تحميل الإيرادات</div><div>' + _esc(e && e.message ? e.message : 'خطأ غير معروف') + '</div></div>');
            _showToast(e && e.message ? e.message : 'فشل تحميل الإيرادات', 'error');
        }
    }

    await renderResults();
}
```

تم فحص هذا الاستبدال بـNode parser والنتيجة:

```text
PASS
```

ولا يحتوي على مرجع `branchesForRevenue` المحلي.

---

## 9. ما لا يحتاج تعديلًا في Mother الآن

لا تقم بتغيير العناصر التالية لمجرد التعديل:

```text
revenues tab entry
revenues dispatcher entry
finance_save_revenue
finance_list_revenues_v2
finance_void_revenue
```

هذه أجزاء مثبتة بالفعل في Current source / Production.

لا تنشئ:

```text
finance_revenues_new
revenue_receipts_new
revenue_engine_new
Edge Function جديدة للإيرادات
```

لأن ذلك سيكون تكرارًا غير ضروري.

---

## 10. لماذا لم يتم إنشاء Edge Function جديدة للإيرادات

الـProduction RPC الحالي هو capability محفوظ وآمن ويطبق Company Context وPeriod Guard وBranch/Treasury validation وAccounting + Cash Box + Treasury ضمن transaction واحدة.

إضافة Edge Function جديدة لا تضيف قيمة وظيفية لهذه الشاشة ما دام الـMother تستطيع استدعاء RPC الآمن مع المستخدم authenticated.

---

## 11. Security / Tenant Verification

تم التحقق من:

```text
finance_save_revenue -> authenticated execution موجود
finance_list_revenues_v2 -> company-scoped
finance_void_revenue -> authenticated execution موجود
```

كما أن RLS مفعّل على:

```text
finance_revenues
finance_revenue_lines
finance_revenue_categories
finance_expenses
finance_expense_lines
cash_box
treasury
journal_entries
journal_lines
```

والـRevenue list RPC الحالي يرفض company mismatch بواسطة:

```sql
p_company_id = app_private.current_user_company_id()
```

---

## 12. Manager.io / Industry Reference

تم استخدام Manager.io الرسمي كمرجع UX وليس كنسخة حرفية.

المبدأ المرجعي المناسب لـRAWAEA:

```text
Receipt / Revenue transaction
→ Money received into selected cash/bank account
→ Multiple allocation lines allowed
→ Accounting posting tied to transaction
```

والقرار في RAWAEA هو مواءمة ذلك مع عقدنا الموجود فعليًا:

```text
Branch + Treasury + 1..N Revenue Accounts
→ finance_save_revenue
```

بدون إنشاء محرك محاسبي منفصل.

---

## 13. أخطاء وتجارب هذه الجلسة

### تجربة 1 — parsing للمقطع المعيب

```text
Malformed escaping = FAIL
Correct escaping  = PASS
```

### تجربة 2 — Production Revenue Multi-Line

```text
10 + 20 = 30
Journal = PASS
CashBox = PASS
Treasury +30 = PASS
```

### تجربة 3 — Revenue Retry

```text
duplicate = true
No duplicate accounting/cash mutation
```

### تجربة 4 — Revenue Void

```text
Revenue = VOID
CashBox = Voided
Journal reversal = PASS
Treasury restored
```

### تجربة 5 — transactional rollback

تم تنفيذ الاختبارات داخل Transaction ثم rollback، ولم تُترك بيانات تجريبية دائمة.

### خطأ أداة أثناء التنفيذ

حدث خطأ SQL أثناء محاولة دمج استعلامين بـ`UNION` مع `ORDER BY/LIMIT` على مستوى كل SELECT بدون تغليف صحيح. لم يغيّر هذا Production ولم يُنتج أي mutation.

---

## 14. الحالة الفعلية عند نهاية هذه الجلسة

### Backend Revenue

```text
Production infrastructure = PRESENT
Accounting integration     = VERIFIED
Treasury integration      = VERIFIED
CashBox integration       = VERIFIED
Multi-line support        = VERIFIED
Idempotency               = VERIFIED
Void / reversal           = VERIFIED
```

### Mother Revenue

```text
Revenue tab                = PRESENT in current source
Revenue dispatcher         = PRESENT
New Revenue structure      = PRESENT but parsing is broken
_renderRevenues            = PRESENT but has scope defect
Mother syntax              = NOT CLOSED
Authenticated browser E2E  = NOT PROVEN
```

### Final closure status

```text
Production Revenue Core = CLOSED / PROVEN
Mother Revenue UI       = SURGERY READY / OWNER ACTION
Mother Login blocker    = ROOT CAUSE PROVEN / OWNER SURGERY REQUIRED
Browser E2E              = OPEN
Finance Gold/Diamond     = NOT YET CLOSED
```

**لا يجوز تسجيل 100% Closure لهذه النقطة قبل أن يدمج المالك الجراحتين في Mother ثم يثبت Browser E2E من شاشة الدخول حتى Revenue save/list مع Console نظيف وDB verification.**

---

## 15. Acceptance Criteria بعد دمج Mother

### Login

```text
No `Uncaught SyntaxError`
Login screen parses normally
Authentication/session initialization completes
System reaches main interface
```

### Revenue navigation

```text
Finance
→ الإيرادات
→ list renders
→ date filters work
→ New Revenue works
```

### Revenue entry

```text
Branch selected
Treasury selected
Revenue account line 1
Revenue account line 2
Amount 10 + 20
Total 30
Save
```

### Expected backend outcome

```text
finance_revenues       = 1 row for operation
finance_revenue_lines  = 2 lines
journal_entries        = 1 posted entry
cash_box               = 1 Receipt
Treasury               = +30
```

### Retry

```text
same operation_id
→ duplicate=true
→ no second cash/journal mutation
```

### Visibility

```text
Revenue list immediately shows the created transaction
```

### Console

```text
No `Invalid or unexpected token`
No ReferenceError: branchesForRevenue
```

---

## 16. Owner surgical checklist — بدون وصف زائد

### 16.1 Syntax

```text
ابحث:
'onclick="RW_Finance.renderSubTab(\\'receipts\\')" ' +
```

احذف السطر واستبدله بـ:

```js
'onclick="RW_Finance.renderSubTab(\'receipts\')" ' +
```

نفّذ ذلك في الموضعين داخل `_newReceipt()`.

### 16.2 Revenue renderer

```text
ابحث:
function _renderRevenues() {
```

احذف الدالة كاملة حتى القوس الأخير الذي يغلقها، واستبدلها بالكامل بالكود الموجود في Section 8 من هذا التقرير.

---

## 17. إرشادات للمساعد القادم — كيف يبدأ ويصل إلى الحقيقة

هذه الإرشادات يجب أن تكون نقطة الدخول العملية للجلسة القادمة:

```text
1. اقرأ CURRENT_STATE.md، ثم لا تثق به كحالة حالية.

2. احصل على CURRENT GIT HEAD للمستودع:
   papamohammed77-glitch/erp-frontend

3. افتح الـHEAD ثم الـparent المباشر.

4. افحص:
   companies/company-1/main.html
   من المصدر الحالي نفسه، لا من fragment تاريخي.

5. طابق الملف مع Production الحالية في Supabase.

6. طابق الـRPCs والـEdge Functions الحالية مع الـConsumers في Mother.

7. لا تعيد إنشاء Revenue Backend؛ هو مثبت في Production.

8. افحص أولًا هل المالك طبق الجراحتين:
   - correcting the two receipt escaping lines
   - replacing _renderRevenues()

9. شغّل JavaScript syntax validation على Mother الحالية.

10. نفّذ browser E2E authenticated:
    Login
    → Finance
    → Revenues
    → New Revenue
    → one line
    → multi-line
    → Save
    → List
    → Retry
    → DB verification

11. راقب Console في نفس دورة الاختبار.

12. اجمع Production evidence في نفس اللحظة، ولا تستخدم نسبة أو تقريرًا قديمًا كحقيقة حالية.

13. بعد إغلاق Revenue UI فقط انتقل إلى Closure Unit التالية.

14. لا تصلح عنصرًا ثبت أنه مغلق إلا إذا ظهر Regression مثبت.

15. لا تنشئ Engine جديدًا إذا كان الـProduction contract الموجود يكفي.

16. في كل Unknown:
    search current source
    → search current production
    → search database
    → search deployments
    → search consumer/caller/callee
    → search history
    → resolve

17. لا تعتبر:
    commit = deployment
    deployment = runtime success
    runtime = browser E2E
    browser E2E = full closure

18. لا تعلن 100% إلا بعد:
    Current Source
    + Current Production
    + Current Database
    + Current Deployment
    + Browser E2E
    + Console clean
    + Data verification
```

---

## 18. Final Self-Audit

### What was proved

```text
Current Mother Source of Truth = confirmed
Current Mother HEAD            = confirmed
Direct parent                  = confirmed
forensic_main_assembly.yml      = confirmed correct
Login Syntax root cause         = proven
Exact malformed escaping        = proven
Revenue backend existence       = proven
Revenue multi-account posting   = proven
Journal integration             = proven
CashBox integration             = proven
Treasury integration            = proven
Revenue retry idempotency       = proven
Revenue void                    = proven
Production test rollback        = proven
```

### What was fixed in Production

```text
لا توجد بنية Revenue جديدة مطلوبة في Production في هذه الجلسة؛ الموجود كان كافيًا ومثبتًا.
```

### What was NOT changed in Production

```text
No new revenue tables
No new revenue Edge Function
No new accounting engine
No field-operation changes
No inventory engine changes
```

### What remains open

```text
Mother syntax repair by Owner
Mother _renderRevenues() repair by Owner
Authenticated browser E2E
Console final verification
Revenue UI Gold/Diamond closure
```

### Final closure statement

```text
REVENUE PRODUCTION CORE                 = CLOSED / VERIFIED
REVENUE MOTHER UI                      = OPEN / OWNER SURGERY
LOGIN BLOCKER                          = OPEN / OWNER SURGERY
BROWSER E2E                            = OPEN
GLOBAL FINANCE GOLD/DIAMOND            = OPEN
```

**هذا التقرير لا يعلن False Closure.**

---

## 19. المراجع المباشرة

Current Mother:
`https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`

Current HEAD:
`https://github.com/papamohammed77-glitch/erp-frontend/commit/d7bf7ed138fa95b8dfdb88cc407827340954aa43`

Parent:
`https://github.com/papamohammed77-glitch/erp-frontend/commit/8fff8f4f05ba0c0d95a985a742b58a5890028fdb`

forensic assembly:
`https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/forensic_main_assembly.yml`

Historical Report226:
`https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report226`

Governance:
`https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/medhat/تقرير مبادئ حاكمة`

Direct execution prompt:
`https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/medhat/برومبت استكمال مهام`
