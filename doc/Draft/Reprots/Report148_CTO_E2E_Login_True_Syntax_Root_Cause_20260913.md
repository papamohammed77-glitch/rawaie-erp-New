# Report148 — CTO E2E Login — True Syntax Root Cause — النظام الأم

**التاريخ:** 2026-09-13

## 1. النقطة الحاكمة

ثبت من المصدر الفعلي أن البلاغ `main:5592 Invalid regular expression: missing /` لا يعني أن السطر 5592 هو سبب العطل.

العيب الحقيقي الموجود في Source of Truth الحالي هو **السطر 5590 داخل `_searchCustomers()`**. يحتوي السطر على escape غير صحيح داخل string أحادي الاقتباس، ما يؤدي إلى إنهاء السلسلة النصية مبكرًا وانهيار حالة الـJavaScript parser. لذلك يظهر الخطأ عند slash الموجود لاحقًا في `</div>` بالسطر 5592.

```text
ROOT CAUSE = LINE 5590
RUNTIME REPORTED LOCATION = LINE 5592
LINE 5592 = SYMPTOM LOCATION
```

## 2. المصدر الذي تم التحقق منه

```text
Repository = papamohammed77-glitch/erp-frontend
Branch = main
File = companies/company-1/main.html
Current blob SHA = 68bf9f3cc4527e2d5329563470f6dcede75f3c33
Latest frontend commit = 094197b8b57219630242aacfe9c564d7a4f6df58
```

الـcommit الأخير يغيّر marker زمني فقط ولا يغيّر `_searchCustomers()`.

## 3. السطر المعيب الحالي

السطر 5590 الحالي كما هو في Git:

```javascript
      h += '<div onclick="RW_TeleSales._selectCustomer(\\'' + c.customer_code + '\\')" class="p-3 hover:bg-blue-50 cursor-pointer flex justify-between border-b">';
```

التركيب `\\'` غير صحيح في هذا السياق؛ فهو لا يهرب علامة الاقتباس المفردة كما هو مقصود، بل يؤدي إلى إنهاء string مبكرًا.

## 4. الاختبار المستقل

تم اختبار الصياغة الحالية للسطر في Node.js وأنتجت خطأ صياغة.

تم اختبار الصياغة المصححة وأنتجت `NODE SYNTAX CHECK = PASS` مع الحفاظ على السلوك المقصود، أي إنتاج:

```html
<div onclick="RW_TeleSales._selectCustomer('C1')" class="x">
```

## 5. Owner Surgical Change

### الملف

```text
erp-frontend/companies/company-1/main.html
```

### العنصر

```text
السطر 5590 داخل _searchCustomers(query)
```

### الإجراء

احذف **السطر 5590 بالكامل فقط**، وهو السطر الذي يبدأ بـ:

```javascript
h += '<div onclick="RW_TeleSales._selectCustomer(\\''
```

وينتهي بـ:

```javascript
border-b">';
```

ثم استبدله حرفيًا بالسطر التالي:

```javascript
      h += '<div onclick="RW_TeleSales._selectCustomer(\'' + c.customer_code + '\')" class="p-3 hover:bg-blue-50 cursor-pointer flex justify-between border-b">';
```

لا تحذف أو تعدل الأسطر 5588 و5589 و5591 و5592 و5593 و5594، ولا تستبدل `_searchCustomers()` كاملة.

## 6. خطأ أداة الاختبار السابقة

الـprobe الثاني المقدم في Report147 لم يكتمل؛ Console سجل:

```text
VM206:93 Uncaught SyntaxError: Invalid regular expression flags
```

والسبب في أداة الاختبار نفسها هو استخدام regex literal مع double escaping للـslash في جزء استخراج `</script>`. لذلك لم تنتج تلك الجولة نتيجة `BYTE_EQUALITY` موثوقة.

## 7. Production / Supabase

مشكلة الدخول الحالية Frontend lexical syntax. لا يوجد سبب مثبت لتغيير Supabase لحلها.

```text
SUPABASE PATCH = NONE
```

## 8. Assembly / Source of Truth

تم فتح:

```text
rawwaie-erp-New/.github/workflows/forensic_main_assembly.yml
```

والمسار الحالي صحيح ويشير إلى:

```text
https://raw.githubusercontent.com/papamohammed77-glitch/erp-frontend/main/companies/company-1/main.html
```

ولا حاجة لتعديل الـworkflow لهذا السبب.

## 9. حالة الإغلاق

```text
FORENSIC ROOT CAUSE = PROVEN
OWNER SURGICAL CHANGESET = READY
SUPABASE = NO CHANGE
MAIN.HTML = NOT MODIFIED BY ASSISTANT
POST-PATCH DEPLOYMENT = PENDING OWNER
POST-PATCH E2E LOGIN = PENDING OWNER
GLOBAL GOLD/DIAMOND = OPEN
```

لا يوجد تعديل آخر مطلوب في `_searchCustomers()` قبل تطبيق استبدال السطر 5590 أعلاه.

# END REPORT148
