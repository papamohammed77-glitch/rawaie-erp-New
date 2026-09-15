# تقرير 196 — التحقيق الجنائي في فشل تجاوز شاشة الدخول بعد دمج تبويب المشتريات

**التاريخ:** 2026-09-15
**Closure Unit:** Mother System Browser E2E — Purchase Merge Syntax Blocker
**Source of Truth:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
**الحالة النهائية:** OPEN — Owner Surgical Fix Required

## 1. المبدأ الحاكم

الملف الأم الحالي هو Source of Truth الوحيد. التقارير السابقة استُخدمت كدلائل تاريخية فقط، ولم يُفترض أنها تمثل الحالة الحالية.

## 2. Current Git reconciliation

تمت مطابقة Current Git مباشرة.

HEAD الحالي:
`9b39626e8679e35b8215adf2ba4977b838e1f5d2`

الـparent المباشر:
`afbdd46b2bcf503bcf3b92b5ad1da97ed2495ebd`

الـparent السابق للتطبيق:
`66ed7f2c58fc1cd97526d6ea5b12116961102c9f`

الـHEAD الحالي يحتوي تعديل Navigation وإضافة وحدة `RW_PurchaseGold`.
والـparent المباشر كان يضيف فقط بنية Browser E2E، وليس تغييرًا في جسم `main.html`.

## 3. Current mother read / EOF

تم جلب جسم الـblob الحالي مباشرة من Git باستخدام SHA الحالي:
`4057fa179da0ac77355a2239d138758aeb4bd662`

تم التحقق من بداية الملف ومن مواضع متعددة داخله ومن نهاية الجسم نفسها، ونهاية الملف الحالية:

```html
</script>
</body>
</html>
```

كما تم البحث في الجسم الحالي عن:

```text
قيد التطوير
جاري التطوير
```

والنتيجة: لا توجد مطابقات.

ملاحظة تقنية: أداة GitHub لا تعيد هذا الـblob الضخم عبر range API بصورة قابلة للاستخدام، لذلك تم الاعتماد على blob fetch المباشر + البحث الداخلي + إثبات EOF، وليس على snippet منفرد حول السطر 9144.

## 4. forensic finding — السبب الجذري

Console:

```text
main:9144 Uncaught SyntaxError: Invalid or unexpected token
```

الخطأ لا يخص Tailwind. رسالة Tailwind مجرد تحذير إنتاجي وليست SyntaxError.

السبب الجذري مثبت داخل الوحدة المضافة `RW_PurchaseGold` في `tabs()`.

الجزء الحالي يحتوي escaping زائدًا:

```javascript
for (var i = 0; i < list.length; i++) {
  h += '<button onclick="RW_PurchaseGold.open(\\'' +
    list[i][0] + '\\')" class="px-4 py-2 rounded-xl font-black ' +
    (active === list[i][0]
      ? 'bg-emerald-600 text-white'
      : 'bg-white border text-slate-700') +
    '">' + esc(list[i][1]) + '</button>';
}
```

السطر الذي ينهار عنده parser في الـcurrent source هو **line 9144**:

```javascript
h += '<button onclick="RW_PurchaseGold.open(\\'' +
```

ويوجد نفس الخطأ في السطر التالي داخل:

```javascript
list[i][0] + '\\')"
```

في JavaScript داخل string محدد بـsingle quote، المطلوب escaping لعلامة الاقتباس الداخلية هو `\\'` في النص الذي يمثل source النهائي؟ لا. في الملف الفعلي المطلوب هو backslash واحد قبل `'`، أي `\\'` عند تمثيله في JSON فقط، أما النص البرمجي نفسه فيجب أن يكون:

```javascript
'<button onclick="RW_PurchaseGold.open(\'' +
```

وهذا ما يفسر `Invalid or unexpected token`.

## 5. Independent parser proof

تم بناء اختبار معزول مطابق للنمط الحالي.

النسخة الحالية ذات `\\'` فشلت في `node --check` بنفس:

```text
SyntaxError: Invalid or unexpected token
```

بعد تصحيح escaping إلى backslash واحد، لم يعط `node --check` أي خطأ.

إذن السبب ليس تخمينًا؛ هو parser-confirmed.

## 6. Historical comparison

Commit `9b39626e...` أضاف `RW_PurchaseGold`، والـdiff نفسه يثبت إضافة هذا البلوك بعد:

```javascript
window.RW_Purchases = RW_Purchases;
```

والـparent `afbdd46b...` كان إنشاء Browser E2E harness فقط.

هذا يثبت causal boundary واضحة: عطل SyntaxError ظهر في الكود الذي أضيف ضمن تحديث المشتريات في الـcurrent application HEAD.

## 7. `forensic_main_assembly.yml`

تم فحص الملف الحالي مباشرة.
المسار صحيح بالفعل:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

لا حاجة إلى تعديل هذا الملف.

## 8. Production

لم يثبت أن مشكلة شاشة الدخول تحتاج أي تغيير Production أو Database.
الخطأ يحدث أثناء JavaScript parsing قبل بدء التشغيل الوظيفي، ولذلك إنشاء جدول أو Edge Function جديد لإصلاح هذه النقطة سيكون تعديلًا غير مبرر.

## 9. Owner surgical action — التنفيذ المطلوب

**لا تحذف `RW_PurchaseGold` كاملة.**

في الملف:
`companies/company-1/main.html`

### ابحث عن البلوك الذي يبدأ من line 9143:

```javascript
for (var i = 0; i < list.length; i++) {
```

### وينتهي بهذا السطر كاملًا:

```javascript
}
```

المقصود هو نهاية حلقة `for` الخاصة بدالة `tabs()` مباشرة قبل:

```javascript
return h + '</div>';
```

**احذف الحلقة كاملة واستبدلها بهذا البلوك كاملًا:**

```javascript
for (var i = 0; i < list.length; i++) {
  h += '<button onclick="RW_PurchaseGold.open(\'' +
    list[i][0] + '\')" class="px-4 py-2 rounded-xl font-black ' +
    (active === list[i][0]
      ? 'bg-emerald-600 text-white'
      : 'bg-white border text-slate-700') +
    '">' + esc(list[i][1]) + '</button>';
}
```

**لا تعدل أي سطر قبل `for` أو بعد `}` الخاص بالحلقة.**

## 10. Required re-verification after owner application

لا يُعتبر هذا Closure مغلقًا بعد النص أعلاه وحده.

التسلسل الإلزامي:

```text
Owner applies exact block
→ publish current main.html
→ verify published URL is latest main
→ rerun Browser E2E
→ Console Errors = 0
→ Page Errors = 0
→ Login form visible
→ login click
→ authenticated shell visible
→ first navigation click works
→ Network checked
→ current Git blob re-read
→ EOF re-verified
→ only then close blocker
```

## 11. What was not changed

- لم يتم تعديل `erp-frontend/companies/company-1/main.html` مباشرة.
- لم يتم تعديل `New-main`.
- لم يتم الرجوع إلى `Current/PWA/main2` كمصدر تنفيذ.
- لم يتم إنشاء جداول أو Edge Functions جديدة لأن الدليل الحالي لا يبرر ذلك.
- لم يتم إعادة إصلاح Backend purchase closure السابقة بدون defect جديد.

## 12. What was proven

```text
Current HEAD = verified
Direct parent = verified
Current mother blob = verified
EOF = verified
Source of Truth path = verified
Purchase block location = verified from current HEAD diff
Syntax defect = proven
Node parser failure on current pattern = proven
Node parser pass after surgical escaping fix = proven
Tailwind warning = non-blocking warning
Production change required for this blocker = no
```

## 13. What was not proven

```text
Published post-fix browser PASS = not yet proven
Authenticated login click-by-click PASS = not yet proven
Network PASS after owner fix = not yet proven
Overall Browser E2E Closure = OPEN
```

## 14. Next CTO start instructions

ابدأ دائمًا من:

```text
CURRENT_STATE
→ CURRENT GIT HEAD
→ DIRECT PARENT
→ CURRENT MOTHER BLOB
→ EOF
→ CURRENT DEPLOYMENT
→ CURRENT BROWSER/CONSOLE/NETWORK
```

اعتبر التقارير pointers فقط.

عند ظهور SyntaxError:

```text
exact current blob
→ exact line/anchor
→ parent diff
→ minimal parser reproduction
→ surgical owner replacement
→ published browser verification
```

لا تعالج Production لمشكلة parser قبل إثبات الحاجة.
ولا تعيد فتح Closure مغلقًا إلا بدليل جديد.
ولا تعتبر static PASS أو staging PASS أو old Browser PASS بديلاً عن Current Browser PASS.

## 15. Closure status

```text
MOTHER E2E SYNTAX BLOCKER = PROVEN
ROOT CAUSE = PROVEN
SURGICAL FIX = READY
OWNER APPLICATION = REQUIRED
BROWSER REVERIFICATION = OPEN
OVERALL CLOSURE = OPEN
```
