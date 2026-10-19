# Report446 — إصلاح فلتر «أوردرات عمليات» ليشمل المرتبط وغير المرتبط برانشيت

**التاريخ:** 2026-10-19  
**النطاق الوحيد:** `erp-frontend/companies/company-1/main.html`، وحدة `RW_Orders`.  
**حدود التنفيذ:** لم أعدّل `main.html` أو `store/index.html`، ولم أغيّر Production أو أنشئ بيانات تجريبية. هذا التقرير يقدّم التعديل الجراحي للمالك فقط.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** 98/100 — المطلوب عرض طلبات المتجر الإلكتروني والتلي سيلز والأوردر تيكر، سواء ارتبطت برانشيت أم لا.
- **Architecture Understanding:** 98/100 — زر عرض الطلبات التشغيلية هو فلتر عرض؛ أهلية اختيار الطلب لإنشاء/ضم رانشيت عقد منفصل لا يجوز إضعافه.
- **Database Understanding:** 99/100 ضمن النطاق — تمت قراءة مخطط `orders` وتوزيع الطلبات الحي في Production.
- **Historical Understanding:** 97/100 — تمت مراجعة Report443 وReport444 وReport445 باعتبارها أدلة تاريخية، ثم فحص مصدر Git الحالي مباشرة.
- **Production Understanding:** 99/100 للبيانات والعقد المفحوصين — استعلام مباشر في 2026-10-19 16:27:10 UTC.
- **Current Understanding:** 100/100 للنطاق المحدد — تمت قراءة blob الحالي الكامل واستخراج دوال `RW_Orders` المعنية.
- **Execution Confidence:** 99/100 للتعديل الجراحي؛ اختبار المتصفح المنشور غير منفذ من هذه الجلسة.

### مصادر الحالة الحالية

- Repository: `papamohammed77-glitch/erp-frontend`
- Current file: `companies/company-1/main.html`
- Current blob SHA: `1b38c60ff38d439d429474b17ff54b5b169c07b4`
- آخر commit معروف للمصدر: `1a60b404e1d3c9e2769036618bebf3c66947d1f1`
- تاريخ المقارنة: Report443 → Report444 → Report445، مع إعادة قراءة المصدر الحالي بدل إعادة تطبيق patch قديم.
- Production project: `fiilmooggumokxanwiyx`

## ما أثبته Production الآن

عند `2026-10-19 16:27:10.683668+00 UTC`:

| المؤشر | العدد |
|---|---:|
| جميع الطلبات | 12 |
| طلبات المصادر التشغيلية المطلوبة | 7 |
| منها مرتبط برانشيت | 6 |
| منها غير مرتبط برانشيت | 1 |

توزيع الطلبات التشغيلية:

| المصدر كما هو مخزن | الحالة | العدد | مرتبط برانشيت |
|---|---|---:|---:|
| `online_store` | Pending | 1 | 0 |
| `order-taker` | Pending | 4 | 4 |
| `telesales` | Pending | 2 | 2 |

إذن الشرط الحالي `!order.runsheet_id` يستبعد فعليًا ستة من الطلبات السبعة التي يجب أن يعرضها زر العمليات. لا حاجة لتعديل قاعدة البيانات أو RPC أو Edge Function لهذا العيب؛ هو خطأ فصل مسؤوليات داخل فلتر الواجهة.

## Root Cause

في المصدر الحالي:

1. `_isRunsheetEligible(order)` يشترط المصدر التشغيلي، والحالة `Confirmed/Pending`، وعدم وجود `runsheet_id`.
2. `_applyFilters()` يستخدم `_isRunsheetEligible` لتحديد ما يعرضه زر «أوردرات عمليات».
3. بذلك اختلط **فلتر مصدر الطلب** مع **أهلية اختيار الطلب للرانشيت**، فاختفت الطلبات التشغيلية المرتبطة برانشيت.
4. منطق checkbox في `_renderTable` يطبق أهلية الرانشيت منفصلًا؛ يجب الحفاظ عليه كما هو.

## التعديل الجراحي — يطبقه المالك فقط

**لا تستبدل الملف أو الكائن أو الدالة `_applyFilters` كاملة.** نفّذ الاستبدالين التاليين فقط على SHA الحالي المذكور أعلاه.

### PATCH A — استبدال دالة predicate الخاصة بزر العمليات

**الملف:** `companies/company-1/main.html`  
**الكائن:** `RW_Orders`  
**الموضع الحالي:** قرابة الأسطر 10389–10394.  
**محدد البحث:** ابحث داخل `RW_Orders` عن الدالة التي تبدأ بـ `function _isRunsheetEligible(order)` وتنتهي قبل `function _populateSourceFilter()`.

**احذف الدالة كاملة فقط:**

```javascript
    function _isRunsheetEligible(order) {
        var source = _normalizeOrderSource(order && order.source);
        return ['telesales', 'tele-sales', 'order-taker', 'online-store'].indexOf(source) !== -1 &&
            ['Confirmed', 'Pending'].indexOf(order && order.order_status) !== -1 &&
            !(order && order.runsheet_id);
    }
```

**واستبدلها كاملة بهذا النص:**

```javascript
    function _isOperationsOrder(order) {
        var source = _normalizeOrderSource(order && order.source);
        return ['telesales', 'tele-sales', 'order-taker', 'online-store'].indexOf(source) !== -1;
    }
```

### PATCH B — غيّر predicate المستخدم في فلتر العمليات فقط

**الموضع الحالي:** داخل `function _applyFilters()`، قرابة السطر 10465.  
**محدد البحث:** ابحث عن هذا السطر المطابق حرفيًا:

```javascript
        if (operationsOnly) filtered = filtered.filter(_isRunsheetEligible);
```

**استبدله بهذا السطر فقط:**

```javascript
        if (operationsOnly) filtered = filtered.filter(_isOperationsOrder);
```

**لا تغيّر** منطق `runsheetEligible` أو checkbox داخل `_renderTable`. يجب أن تظل شروط إنشاء/ضم رانشيت كما هي: مصدر مسموح، حالة `Confirmed/Pending`، و`runsheet_id` فارغ.

## اختبارات ما بعد التطبيق

1. فحص JavaScript syntax للملف كاملًا.
2. تفعيل «أوردرات عمليات»: يجب أن يعرض المصادر `online_store`, `telesales`, `tele-sales`, `order-taker` بعد التطبيع، سواء كانت مرتبطة برانشيت أم لا.
3. على لقطة Production الحالية، يجب أن تكون النتيجة الأساسية 7 طلبات: 1 متجر إلكتروني + 4 أوردر تيكر + 2 تلي سيلز، منها 6 مرتبطة و1 غير مرتبطة.
4. يجب ألا يظهر `pos` أو `van-sales` ضمن زر العمليات.
5. تحقق أن checkbox يظل معطلًا للطلب المرتبط برانشيت أو غير المؤهل بالحالة/المصدر.
6. اختبر تقاطع فلتر العمليات مع التاريخ والعميل والحالة والمنطقة والرانشيت والمصدر، ثم إعادة التعيين والفرز وRealtime والتحديث الدوري.
7. تحقق من النتيجة في نسخة Cloudflare المنشورة؛ لم يُثبت served-artifact parity أو Browser E2E في هذه الجلسة.
8. لا تنشئ أو تحذف طلبات Production تجريبية.

## Production / Data Safety

- لا يوجد إصلاح SQL/RPC/Edge مبرر لهذا الخلل؛ البيانات الحية تثبت أن الطلبات السبعة موجودة بالفعل.
- لم أغيّر Production schema أو ACL أو Edge Functions.
- لم أعدّل `main.html` أو ملف المتجر؛ المالك هو من يطبق التعديل الجراحي.
- لم أُجرِ أي تعديل أو حذف لبيانات الأعمال.

## SELF-AUDIT FINAL

- **What I Proved:** الخلل ناتج عن استخدام predicate أهلية الرانشيت كفلتر للطلبات التشغيلية؛ Production يحوي 7 طلبات من المصادر المطلوبة، 6 مرتبطة برانشيت و1 غير مرتبط.
- **What I Did Not Prove:** لم أنفذ اختبار متصفح أو HTTP على النسخة المنشورة، ولم أثبت تطابق Cloudflare artifact مع Git.
- **What I Fixed:** لم أغيّر الكود التشغيلي؛ جهزت استبدالين محدودين ودقيقين للمالك.
- **What I Initially Missed:** كان فلتر العمليات يربط العرض بشرط عدم وجود `runsheet_id`، فاستبعد الطلبات المرتبطة.
- **What Could Still Be Wrong:** قد تظهر فجوة Runtime أخرى بعد التطبيق؛ يلزم syntax + Browser E2E.
- **Final Confidence:** 99/100 في التشخيص والتعديل المقترح، وRuntime غير مثبت.
- **Final Closure Status:** `ROOT CAUSE VERIFIED / OWNER SURGICAL PATCH READY / PRODUCTION UNCHANGED / BROWSER E2E OPEN`.
