# تقرير 361 — التحقيق الجنائي وإغلاق عطل طباعة مودال الأذونات المخزنية
**التاريخ:** 2026-09-29  
**النطاق:** `companies/company-1/warehouse/vouchers.html` — مودال تفاصيل الإذن في تبويبي **معلقة** و**مكتملة**  
**المنهج:** Production أولًا → Git الحالي → Source الحالي → Database → Deployment evidence → اختبار السببية → تعديل جراحي واحد فقط.

---

## 1) قاعدة الحقيقة المعتمدة

التقارير السابقة استُخدمت كدلائل تاريخية فقط. الحالة الحالية التي بُني عليها هذا التقرير هي:

### CURRENT GIT
- نظام الروائع: `1c862e242a1b3fe23e11f586ecf0703bec35920a`
- Parent: `af7bd6c2f22b308f732ec3503a8ad21163d37d02`
- Frontend: `1214f6bca0d5f851bec2be8bd3d466b4af758efd`
- Parent: `386b003ccd1650444062844394a7ec6ac2f7032f`

### CURRENT SOURCE
- `vouchers.html` blob الحالي: `d231a6b1762fdd66a0c57e33a8c43a7200391a13`
- الحجم: 6625 سطرًا / 215151 حرفًا.
- `Current/PWA/main.html` blob: `27b777528665dcc985809648f006452c861ae36e`
- `van-sales.html` blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`

### ملاحظة حاسمة
`CURRENT_STATE.md` كان يصف Frontend HEAD أقدم (`386b...`) وblob أقدم لـ`vouchers.html`.  
الـHEAD الحالي تقدم إلى `1214f6...`، ولذلك تم تجاوز الحالة القديمة وعدم إعادة تطبيق إصلاحات DirectReturn السابقة.

---

## 2) ما تم إثباته في المصدر الحالي

### النظام الأم — بدون أي تعديل

`Current/PWA/main.html` ما زال يملك:
- صلاحية المالك عبر `isOwner===true`.
- wildcard `*` في `RW_STATE.permissions`.
- تفويض تطبيق الأذونات إلى `./vouchers.html`.
- ربط الـnavigation وpermission map مع `vouchers`.
- مصدر سلطة المخزون الفعلي هو Production Core/RPC وليس DOM الواجهة.

تمت قراءة الجزء المرتبط بالصلاحيات والتفويض والتحكم في الأذونات، ولم تُجر أي كتابة على `main.html`.

### تطبيق الأذونات المخزنية

الدور الحالي ثابت:
- تبويب **معلقة** و**مكتملة** يستخدمان نفس قائمة الأذونات.
- القائمة تستدعي `inventory_voucher_report` مع:
  - `source='Manual'`
  - `workflow_scope='pending'` أو `completed`
- صف الإذن يفتح:
  - `App.details(code)`
- مودال التفاصيل نفسه هو نقطة الطباعة.
- في حالات الاستلام والإكمال وحالات العرض النهائي يوجد:
  - `App.printVoucher()`

### تطبيق المندوب المباشر

`van-sales.html` لا يملك صلاحية أن يصبح مخزنًا موازيًا:
- يستعمل `orders` / `order_details`.
- يتعامل مع مخزون السيارة عبر بيانات المخزون الحالية.
- حفظ فاتورة البيع يتم عبر:
  - `RW_API.call('save-sales-invoice', ...)`
- الجرد السريع يتم عبر:
  - `RW_API.call('save-inventory-count', ...)`

إذن تطبيق المندوب يبقى تطبيقًا تشغيليًا منفصلًا، بينما الأذونات المخزنية هي قناة العمليات المخزنية غير المرتبطة مباشرة بالأوردر/الرانشيت. لم يتم خلط المسارين.

---

## 3) Production — التحقق قبل أي تغيير

مشروع Supabase الحالي:
- Project: `SMART ERP`
- Ref: `fiilmooggumokxanwiyx`
- PostgreSQL 17.6.1.121
- الحالة: ACTIVE_HEALTHY

### RPCs الحالية

تم التحقق من تعريف:
- `public.inventory_voucher_report(text,jsonb)`
- `public.inventory_control(text,jsonb)`

الاثنان `SECURITY DEFINER` مع `search_path = public, pg_temp`.

`inventory_voucher_report` هو مصدر قائمة **معلقة/مكتملة**.
`inventory_control / VOUCHER_AUDIT` هو مصدر تفاصيل المودال.

### Production state الحالي للأذونات اليدوية

- Completed / DirectSale = 1
- Completed / SupplierReturn = 4
- Received / DirectReturn = 1
- Received / Transfer = 1
- Sent / DirectSale = 1

أي أن التبويبين المستهدفين يملكان بيانات فعلية قابلة للاختبار، ولا توجد ضرورة لإنشاء سجل جديد فقط لإثبات فتح المودال.

### سجلات اختبار حقيقية صالحة

`IN-1`:
- Completed / DirectSale
- 5 تفاصيل
- 5 حركات مخزون
- 3 سجلات تدقيق
- 1 قيد Driver Ledger

`IN-9`:
- Received / DirectReturn
- 1 تفصيلة
- حركتا مخزون (سحب من السيارة + إدخال إلى الفرع)
- 4 سجلات تدقيق
- 1 Driver Ledger

`QA-SR-UI-CONTRACT-20260927-01`:
- Completed / SupplierReturn
- 1 تفصيلة
- 1 حركة
- 6 تدقيق
- 1 Journal Entry
- 1 Supplier Ledger

### قرار تنظيف البيانات

تم البحث عن السجلات ذات البوادئ التجريبية:
- لم يوجد سجل تجريبي قابل للحذف بلا آثار.
- سجل QA الموجود مرتبط بالفعل بالمخزون والتدقيق والقيود المالية.
- لذلك **لم يُحذف**؛ حذفه سيكون إتلافًا لسلسلة تاريخية صحيحة.
- لا حاجة لإضافة بيانات Production جديدة لهذا العطل.

---

## 4) التأثير على المخزون والحسابات والخزينة

تمت مراجعة العلاقة للمسارين المستهدفين.

### DirectSale `IN-1`
الحركة الحالية تربط:
- المصدر = فرع
- الهدف = مخزون السيارة
- الحركة = DirectSale
- 5 تفاصيل ↔ 5 Inventory Log rows.

### DirectReturn `IN-9`
الحركة الحالية تثبت:
1. خروج فعلي من مخزون السيارة عند إرسال المرتجع.
2. دخول فعلي إلى الفرع عند الاستلام.

المخزون الحالي لصنف `1001` يطابق هذا التسلسل:
- مخزون السيارة المرتبط بـIN-9 = 0
- مخزون الفرع المستهدف = 7
- لا يوجد allocated residue.

### أثر الطباعة
`printVoucher()`:
- لا ينشئ Voucher.
- لا يرسل/يستلم.
- لا يغير `stock_branches`.
- لا يكتب `inventory_log`.
- لا ينشئ Journal Entry.
- لا يغير Treasury.
- لا يغير Driver/Supplier Ledger.

الطباعة عملية عرض فقط.

---

# 5) السبب الجذري لعطل الطباعة

## العنصر المعيب المثبت

**الملف:**
`companies/company-1/warehouse/vouchers.html`

**الكائن:**
`App`

**الدالة:**
`printVoucher:function()`

**الموضع الحالي:**
تقريبًا من السطر 1664.

**السطر المسبب مباشرة للعطل:**

```javascript
var w=window.open('','_blank','noopener,noreferrer,width=1200,height=900');
```

ثم يأتي بعده مباشرة:

```javascript
if(!w){
    RW_UI.toast('تعذر فتح نافذة الطباعة','error');
    return;
}
```

### السببية

الدالة تطلب `noopener` و`noreferrer` من `window.open()`، ثم تتوقع في الوقت نفسه الحصول على reference صالح للنافذة الجديدة.

توثيق MDN الحالي لـ`Window.open()` يوضح أن:
- `noopener` يجعل النافذة الجديدة لا تمتلك `opener`.
- ومع `noopener` في `windowFeatures` يمكن أن تكون قيمة الإرجاع `null`.
- و`noreferrer` يتضمن أيضًا `noopener`.

المصدر:
MDN — Window.open()

وبذلك يصبح تسلسل الكود الحالي:

```
window.open(..., noopener,noreferrer,...)
        ↓
w === null
        ↓
if(!w)
        ↓
toast + return
        ↓
لا document.write
لا print()
```

وهذا يطابق العطل الملاحظ: **زر الطباعة موجود داخل المودال لكنه لا يصل إلى نافذة الطباعة.**

### سبب ثانوي تم إغلاقه

اختيار:

```javascript
document.querySelector('.swal2-html-container')
```

ليس السبب المباشر للعطل الحالي، لكنه أقل دقة من API الرسمي لـSweetAlert2.

SweetAlert2 يوفر:
```javascript
Swal.getHtmlContainer()
```

وهو العنصر الرسمي الذي تُرسم فيه قيمة `html`.

المصدر:
SweetAlert2 — API / `Swal.getHtmlContainer()`

لذلك تم تضمين هذا التحسين داخل **نفس الإصلاح الجراحي** دون لمس `details()`.

---

# 6) لماذا العطل موجود في «معلقة» و«مكتملة» معًا؟

لأن الزرين في المسارين يستدعيان نفس العنصر:

```javascript
App.printVoucher()
```

والقائمة نفسها لا تملك محرّك طباعة آخر للمودال.

إذن:

```
Pending
   ↓
App.details(code)
   ↓
Swal.fire(...)
   ↓
App.printVoucher()
   ↓
العطل

Completed
   ↓
App.details(code)
   ↓
Swal.fire(...)
   ↓
App.printVoucher()
   ↓
نفس العطل
```

لا توجد حاجة إلى إصلاح دالة ثانية.

---

# 7) التحقق التاريخي

تمت مقارنة `printVoucher()` عبر:
- Frontend parent `56fee06...`
- مرجع `8b6b321...`
- مرجع `826cfb...`
- Current HEAD `1214f6...`

ونفس نمط:
```
window.open(... noopener,noreferrer ...)
```
ظل موجودًا.

كما أن commit `1214f6...` نفسه **لم يعدل printVoucher**؛ تعديله كان خاصًا بإصلاحات DirectReturn السابقة.

النتيجة:
- العطل ليس من إعادة تطبيق DR-UI-01..04.
- لا يجوز إعادة لمس تلك النقاط.
- لا يجوز إعادة بناء `details()`.
- الإصلاح الحالي مستقل وجراحي.

---

# 8) الاختبار السببي

تم تنفيذ اختبار وحدات forensic صغير يحاكي سلوك المتصفح الموثق:

### النسخة الحالية
- `window.open(...noopener,noreferrer...)` → `null`
- Toast الخطأ يظهر.
- `print()` لا يصل إليه التنفيذ.

### النسخة الجراحية
- نافذة الطباعة تُفتح.
- محتوى الإذن يُكتب.
- `print()` يُستدعى مرة واحدة.
- لا يوجد toast خطأ.

النتيجة:
```
PRINT_FORENSIC_UNIT=PASS
current=blocked
patched=printable
```

هذا اختبار سببي للكود، وليس ادعاء Browser E2E Production.

---

# 9) التعديل الجراحي الوحيد المطلوب

## الملف المطلوب تعديله

```
companies/company-1/warehouse/vouchers.html
```

## ابحث بدقة عن هذا العنصر

داخل كائن `App`:

```javascript
printVoucher:function(){
    var node=document.querySelector('.swal2-html-container');

    if(!node){
        RW_UI.toast('لا توجد وثيقة مفتوحة للطباعة','warning');
        return;
    }

    var w=window.open('','_blank','noopener,noreferrer,width=1200,height=900');

    if(!w){
        RW_UI.toast('تعذر فتح نافذة الطباعة','error');
        return;
    }

    w.document.open();

    w.document.write(
        '<!doctype html>'+
        '<html lang="ar" dir="rtl">'+
        '<head>'+
        '<meta charset="utf-8">'+
        '<title>إذن مخزني</title>'+
        '<style>'+
        'body{font-family:Arial,Tahoma,sans-serif;margin:24px;color:#111827}'+
        'table{width:100%;border-collapse:collapse;margin-top:12px}'+
        'th,td{border:1px solid #cbd5e1;padding:8px;font-size:12px}'+
        'th{background:#f1f5f9}'+
        '.no-print{display:none!important}'+
        '.card{break-inside:avoid}'+
        '@media print{body{margin:10mm}}'+
        '</style>'+
        '</head>'+
        '<body>'+
        node.innerHTML+
        '</body>'+
        '</html>'
    );

    w.document.close();

    setTimeout(function(){
        w.focus();
        w.print();
    },250);
},
```

## احذف هذا العنصر بالكامل فقط

ولا تحذف `exportVoucher:function()` ولا أي شيء حوله.

## واستبدله بالكامل بهذا العنصر المصحح

```javascript
printVoucher:function(){
    var node=
        (typeof Swal!=='undefined' &&
         typeof Swal.getHtmlContainer==='function')
            ?Swal.getHtmlContainer()
            :document.querySelector(
                '.swal2-html-container'
            );

    if(!node){
        RW_UI.toast(
            'لا توجد وثيقة مفتوحة للطباعة',
            'warning'
        );
        return;
    }

    var w=window.open(
        '',
        'rawaea-voucher-print',
        'popup,width=1200,height=900'
    );

    if(!w){
        RW_UI.toast(
            'تعذر فتح نافذة الطباعة',
            'error'
        );
        return;
    }

    var printedOnce=false;

    var printNow=function(){
        if(printedOnce){
            return;
        }

        printedOnce=true;

        try{
            w.focus();
            w.print();
        }catch(e){
            RW_UI.toast(
                'تعذر بدء الطباعة',
                'error'
            );

            console.error(
                'App.printVoucher',
                e
            );
        }
    };

    if(
        typeof w.addEventListener==='function'
    ){
        w.addEventListener(
            'load',
            printNow,
            {once:true}
        );
    }

    w.document.open();

    w.document.write(
        '<!doctype html>'+
        '<html lang="ar" dir="rtl">'+
        '<head>'+
        '<meta charset="utf-8">'+
        '<title>إذن مخزني</title>'+
        '<style>'+
        'body{font-family:Arial,Tahoma,sans-serif;margin:24px;color:#111827}'+
        'table{width:100%;border-collapse:collapse;margin-top:12px}'+
        'th,td{border:1px solid #cbd5e1;padding:8px;font-size:12px}'+
        'th{background:#f1f5f9}'+
        '.no-print{display:none!important}'+
        '.card{break-inside:avoid}'+
        '@media print{body{margin:10mm}}'+
        '</style>'+
        '</head>'+
        '<body>'+
        node.innerHTML+
        '</body>'+
        '</html>'
    );

    w.document.close();

    setTimeout(
        printNow,
        300
    );
},
```

### لا تعدل أي عنصر آخر

خصوصًا:
- لا تعدل `details:function(code)`.
- لا تعدل `actionFor()`.
- لا تعدل `renderList()`.
- لا تعدل تبويب `pending`.
- لا تعدل تبويب `completed`.
- لا تعدل `printDraftVoucher()`.
- لا تعيد تطبيق DirectReturn patches.
- لا تلمس `main.html`.
- لا تلمس `van-sales.html`.

---

# 10) لماذا هذا الإصلاح آمن على الـworkflow؟

الإصلاح لا يكتب إلى قاعدة البيانات.

التسلسل يصبح:

```
Pending / Completed
        ↓
details(code)
        ↓
inventory_control / VOUCHER_AUDIT
        ↓
Swal modal
        ↓
printVoucher()
        ↓
فتح print browsing context
        ↓
نسخ modal HTML
        ↓
Browser Print
```

لا يوجد أي branch يؤدي من `printVoucher()` إلى:
- Create
- Send
- Receive
- Complete
- Cancel
- Stock Update
- Ledger Post

وبالتالي لا يتغير Business Contract للمخزون.

---

# 11) اختبار E2E المطلوب بعد تطبيق التصحيح

## المسار A — Pending
استخدم إذنًا حاليًا مثل:
- `IN-8` — DirectSale / Sent

ثم:
```
معلقة
→ فتح IN-8
→ المودال
→ طباعة
→ نافذة جديدة
→ معاينة الطباعة
```

## المسار B — Pending Received
- `IN-9` — DirectReturn / Received

```
معلقة
→ فتح IN-9
→ طباعة
→ نجاح
```

## المسار C — Completed
- `IN-1` — DirectSale / Completed

```
مكتملة
→ فتح IN-1
→ طباعة
→ نجاح
```

## المسار D — Completed QA history
- `QA-SR-UI-CONTRACT-20260927-01`

```
مكتملة
→ فتح
→ طباعة
→ لا يتغير أي سجل مالي أو مخزني
```

### Assertions

بعد كل اختبار:
- modal remains functional.
- print window opens.
- document contains voucher code.
- no console/page error مرتبط بالطباعة.
- no new voucher row.
- no new inventory_log row.
- no change to stock_balances.
- no change to driver/supplier ledger.
- no journal/treasury mutation.

---

# 12) Browser E2E / Deployment Evidence

Workflow الموجود:
```
.github/workflows/warehouse_vouchers_browser_e2e_20260920.yml
```

ويتحقق حاليًا من:
- source syntax
- canonical core path
- canonical service-worker path
- boot browser smoke.

لم يوجد run مرتبط بالـHEAD الحالي:
```
1214f6bca0d5f851bec2be8bd3d466b4af758efd
```

كما أن `fetch_commit_workflow_runs` أعاد مجموعة فارغة لهذا الـHEAD.

لذلك:
- **الاختبار السببي المحلي: PASS**
- **Production DB integrity: PASS**
- **Authenticated browser E2E على HEAD الحالي: OPEN evidence gap**

ولا يجوز تسجيل Browser E2E كـPASS بدون run فعلي.

---

# 13) المنافسة — ما يلزم لاحقًا وليس جزءًا من هذا الإصلاح

من مراجعة الأنظمة الحالية:

### Odoo
يدعم Inventory Adjustments وعمليات المخزون من خلال Barcode/Mobile، بما في ذلك عد المخزون ومسارات النقل.  
المصادر: Odoo 18/19 Inventory & Barcode documentation.

### Dynamics 365
يوفر Warehouse Management mobile menu items لأنشطة مثل Counting وAdjustments وPrint مع تأكيد العمال للمنتج/الموقع/الكمية.  
المصدر: Microsoft Learn — Warehouse Management mobile devices.

### SAP
Goods Movement ينتج material document ويتيح طباعة goods receipt/issue slips، كما أن transfer posting يمكن أن ينتج individual/collective slips مع إعدادات Output Parameter Determination.  
المصادر: SAP Help — MM-IM / Goods Movement / Transfer Posting.

### Daftra
يعرض Transfer تفاصيل From/To وAvailable Before/After، ويوفر Inventory Detailed Transactions Report مع Print وCSV/Excel/PDF، ويعرض نوع الحركة والمستودع والكمية والملاحظات.  
المصادر: Daftra Knowledge Base.

### Manager
يمتلك Inventory Transfers وInventory Transfer Lines وتقارير inventory quantity by location، مع إمكان توسيع عرض الخطوط والبحث المتقدم.  
المصادر: Manager Forum.

### الفجوات التنافسية المستقبلية المستخرجة
هذه ليست جزءًا من التصحيح الحالي:
- قبل/بعد على مستوى كل line.
- barcode / SKU presentation أقوى.
- سبب الحركة وتصنيف السبب.
- attachment/evidence.
- batch/lot/serial/expiry عند الحاجة.
- timeline أو lifecycle visual.
- print template/version.
- movement/audit correlation.
- exception flags.
- export PDF/CSV.
- aging/transit visibility.

هذه backlog حقيقية وليست شرطًا لإغلاق عطل الطباعة الحالي.

---

# 14) لا حاجة لأي تغيير Production

التحقيق أثبت أن:
- `inventory_voucher_report` يعمل كـsource للقوائم.
- `inventory_control / VOUCHER_AUDIT` يعمل كمصدر للمودال.
- البيانات موجودة.
- stock/audit/ledger relationships سليمة.
- المشكلة في client-side print window فقط.

لذلك لم يتم:
- إنشاء Edge Function.
- إنشاء RPC جديد.
- إنشاء migration.
- تعديل جدول.
- تعديل RLS.
- تعديل stock engine.
- تعديل accounting engine.

وهذا هو القرار الصحيح تحت قيد Functions/Spend Cap.

---

# 15) حالة النقاط بعد التحقيق

| البند | الحالة |
|---|---|
| Owner wildcard | CLOSED |
| Main authority/delegation | CLOSED |
| DirectReturn historical fixes | CLOSED — لا تعاد |
| Transfer source/destination contracts | CLOSED |
| Supplier Return backend | CLOSED |
| Pending list retrieval | VERIFIED |
| Completed list retrieval | VERIFIED |
| Voucher details RPC | VERIFIED |
| Stock/accounting integrity | VERIFIED |
| Printing root cause | FOUND |
| Surgical print replacement | PREPARED |
| Production backend change | NOT REQUIRED |
| Browser E2E current HEAD | OPEN evidence gap |

---

# 16) إرشادات الاستمرارية للجلسة القادمة

ابدأ من:
```
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
```

ثم:

1. تحقق أن Frontend HEAD ما زال `1214f6...` أو استبدله بالـHEAD الحقيقي وقت الجلسة.
2. تحقق أن العنصر القديم `printVoucher:function(){...noopener,noreferrer...}` اختفى = 0.
3. تحقق أن عنصر الطباعة الجديد موجود = 1.
4. لا تعيد DR-UI-01..04.
5. لا تعدل `details()`.
6. شغّل syntax gate.
7. نفّذ browser E2E على:
   - IN-8
   - IN-9
   - IN-1
   - QA-SR-UI-CONTRACT-20260927-01
8. افحص popup/print.
9. بعد الاختبار افحص DB no-write invariants.
10. فقط عند وجود evidence فعلي أغلق Browser E2E.
11. لا تُنشئ RPC/Edge جديدًا لهذا العطل.
12. انتقل بعد ذلك إلى **أول Business Contract حقيقي ما زال OPEN**.

---

## المصادر الخارجية المستخدمة للتحقق

- MDN — Window.open() API.
- MDN — Window.opener.
- SweetAlert2 — getHtmlContainer().
- Odoo — Inventory/Barcode adjustments and transfers.
- Microsoft Learn — Dynamics 365 Warehouse Management mobile devices.
- SAP Help — Inventory Management, Goods Movement, Transfer Posting and print output.
- Daftra Knowledge Base — Stock Transfer / Stocktaking / Inventory Detailed Transactions.
- Manager Forum — Inventory Transfers / Inventory Transfer Lines.

**الخلاصة التنفيذية:** العطل محصور في `App.printVoucher()`. لا يحتاج Backend fix. الإصلاح الجراحي أعلاه هو العنصر الوحيد المطلوب في `vouchers.html`، ويعالج السبب المباشر دون إعادة بناء المودال أو لمس الـworkflow أو المخزون أو الحسابات.
