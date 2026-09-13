# Report153 — التحقيق الجنائي E2E لتبويب الأصناف

**التاريخ:** 2026-09-13  
**نطاق الجلسة:** مقارنة تبويب الأصناف في النظام الأم المنشور مع المصدر التاريخي، مع مطابقة Git/Source/Production/Deployment.  
**قاعدة الحوكمة:** التقارير السابقة استُخدمت كقرائن تاريخية فقط. الحالة الحالية بُنيت من CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

---

## 0. الهدف الحاكم

الهدف ليس تحسين الشكل، بل إثبات أن تبويب **الأصناف** في النظام الأم المنشور الحالي:

```text
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
```

لم يفقد وظائف تاريخية، وأن أي Regression مثبت يُعاد إلى سلوكه الصحيح دون المساس بالعمليات التي تم تصميمها خلال مراحل المشروع السابقة.

النظام الأم المنشور هو Source of Truth.  
`Current/PWA/main2` و`Original/PWA/main` تاريخيان فقط ولا يُستخدمان كبديل عن المصدر المنشور الحالي.

---

# 1. CURRENT GIT RECONCILIATION

تمت مراجعة أحدث commits في `erp-frontend`.

### HEAD الحالي

```text
ca91daa29802d161eeb7920bc36dfe4fa3ab2820
```

### Parent المباشر

```text
b29461b0bf5b3af6d387f39497e8e6cf95dfdbbd
```

### Parent الوظيفي السابق

```text
1c212f98e89de4de2384080fef9c75c7d93b0e7e
```

تم أيضًا التحقق من أن الحالة الحالية تقدمت بعد Report152، ولذلك لا يجوز إعادة تنفيذ FIX-152 أو أي تعديل أصبح جزءًا من HEAD الحالي.

Current `main.html` blob:

```text
507a77e7290bbf7c24ce34ce9a121ee2e63e4c44
```

---

# 2. FORENSIC ASSEMBLY SOURCE OF TRUTH

تم فحص:

```text
rawaie-erp-New/forensic_main_assembly.yml
```

والتعريف الحالي صحيح:

```yaml
version: 2
project: rawaea-erp
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

**النتيجة:** لا يوجد تعديل مطلوب على `forensic_main_assembly.yml`.

وجود `Current/PWA/main2/*` تحت `fragments` لا يغير Source of Truth لأن الملف نفسه يصرح صراحة أن `published_main_is_authoritative`.

---

# 3. CURRENT ITEMS MODULE — INVENTORY OF FEATURES

تم فتح قسم `RW_Items` في المصدر المنشور الحالي، ثم مقارنة المسارات الرئيسية مع `Original/PWA/main/main2.md` التاريخي.

الوظائف الموجودة فعليًا في Current Source:

| الوظيفة | Current | Original | النتيجة |
|---|---|---|---|
| قائمة الأصناف | موجودة | موجودة | موجودة |
| البحث بالاسم/الكود/الباركود | موجود | موجود | موجود |
| فلترة التصنيف | موجودة | موجودة | موجودة |
| فلترة الحالة المخزنية | موجودة | موجودة | موجودة |
| فرز حسب الاسم/التصنيف/السعر/المخزون | موجود | موجود | موجود |
| أعمدة المخزون حسب الفروع | موجودة | موجودة | **الـrenderer الحالي به Regression** |
| drill-down لحركة الصنف | موجود | موجود | موجود |
| drill-down لحركة الفرع | موجود تاريخيًا | موجود تاريخيًا | **مفقود من صف القائمة الحالي** |
| مصفوفة الأرصدة حسب الفروع | موجودة | موجودة | موجودة |
| بحث مصفوفة الفروع | موجود | موجود | موجود |
| فلترة حسب الفرع | موجودة | موجودة | موجودة |
| تصدير Excel | موجود | موجود | موجود |
| تحديث الأرصدة من ملف | موجود | موجود | موجود |
| إدارة التصنيفات | موجودة | موجودة | موجودة، والـCurrent أكثر company-scoped |
| إضافة صنف | موجودة | موجودة | موجودة |
| تعديل صنف | موجود | موجود | موجود |
| حذف صنف | موجود | موجود | موجود |
| صورة الصنف | موجودة | موجودة | موجودة |
| 3 تبويبات للصنف | موجودة | موجودة | موجودة |
| رصيد افتتاحي | موجود | موجود | موجود |
| عروض وتسويق | موجود | موجود | موجود |

**الاستنتاج:** الادعاء بأن تبويب الأصناف الحالي فقد معظم وظائفه لم يثبت عند المطابقة مع `Original/PWA/main/main2.md`. الوظائف الأساسية موجودة. لكن توجد Regression حقيقية ومحددة داخل renderer، وهي كافية لجعل القائمة نفسها تعرض بشكل خاطئ وتفقد بعض سلوك drill-down.

---

# 4. PROVEN REGRESSION — `_renderTable`

## Current Source

في `companies/company-1/main.html`، داخل:

```text
var RW_Items = (function() { ...
function _renderTable(data) { ... }
```

يبدأ callback الخاص بـ`RW_Table.paginate` عند **السطر 2008 في المصدر الحالي**.

Current defect:

```javascript
var rowHtml = '<tr ...';
...
for (var b2 = 0; b2 < branchIds.length; b2++) {
    ...
    var rowHtml = '<tr class="border-t hover:bg-gray-50"> ...';
}
rowHtml += '<td ... الحالة ...></td></tr>';
return rowHtml;
```

هذا `var rowHtml` الداخلي يعيد استخدام نفس متغير function scope في JavaScript، فيستبدل الصف الذي بُني بالفعل بدل إضافة خلايا الفروع إليه.

كما أن النسخة الحالية لا تضيف `<td>` لكل فرع داخل الحلقة.

وهذا يطابق الفرق المثبت مقابل `Original/PWA/main/main2.md`، حيث كانت الحلقة تستخدم:

```javascript
rowHtml += '<td ...>...</td>';
```

وليس إعادة تعريف `rowHtml`.

---

# 5. PROVEN REGRESSION — branch movement drill-down

في النسخة التاريخية الصحيحة، الضغط على خلية مخزون فرع محدد كان يستدعي:

```javascript
RW_Items._renderStockMovementReport(itemCode, itemName, bid2, branchName2)
```

أما Current Source داخل الحلقة المتضررة فيستدعي:

```javascript
RW_Items._renderStockMovementReport(itemCode, itemName, null)
```

وبالتالي حتى بعد إصلاح renderer، إذا لم نُعد `bid2` و`branchName2` فلن نحتفظ بسلوك عرض حركة الصنف للفرع المحدد.

هذا Regression مثبت وليس افتراضًا.

---

# 6. EXACT OWNER-ONLY FRONTEND FIX

**هذه المنطقة من اختصاص المالك. لم يتم تعديل `erp-frontend/main.html` بواسطة المساعد.**

## ابحث عن

داخل الدالة:

```javascript
function _renderTable(data) {
```

ابحث عن السطر الكامل التالي عند **السطر 2008**:

```javascript
        RW_Table.paginate('items-tbody', sorted, 1, 50, function(item, idx) {
```

احذف **البلوك كاملًا** من هذا السطر حتى السطر الكامل:

```javascript
    });
```

الذي يأتي مباشرة قبل:

```javascript
    function _sort(field) {
```

ثم استبدله بالبلوك التالي كاملًا:

```javascript
        RW_Table.paginate('items-tbody', sorted, 1, 50, function(item, idx) {
            var img = item.image_url || 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22150%22 height=%22150%22%3E%3Crect fill=%22%23e2e8f0%22 width=%22150%22 height=%22150%22/%3E%3Ctext fill=%22%2394a3b8%22 font-family=%22Arial%22 font-size=%2214%22 x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 dy=%22.3em%22%3E📦%3C/text%3E%3C/svg%3E';
            var status = _getStockStatus(item);
            var rowHtml = '<tr class="hover:bg-blue-50"><td class="p-3 text-center text-xs text-gray-400">' + (idx + 1) + '</td>' +
                '<td class="p-4 cursor-pointer" onclick="RW_Items.openItemPage(' + _jsAttr(item.item_code) + ')"><div class="flex items-center gap-3">' +
                '<img src="' + _esc(img) + '" class="h-24 w-24 rounded-xl object-cover border-2 border-gray-100 shadow-sm cursor-pointer" onerror="this.src=\\'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22150%22 height=%22150%22%3E%3Crect fill=%22%23e2e8f0%22 width=%22150%22 height=%22150%22/%3E%3Ctext fill=%22%2394a3b8%22 font-family=%22Arial%22 font-size=%2214%22 x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 dy=%22.3em%22%3E📦%3C/text%3E%3C/svg%3E\\'" onclick="event.stopPropagation(); RW_Items._viewImage(' + _jsAttr(img) + ')" title="اضغط لتكبير الصورة">' +
                '<div><span class="font-bold text-base">' + _esc(item.name||'') + '</span><br><span class="text-xs text-gray-400">' + _esc(item.item_code||'') + '</span></div></div></td>' +
                '<td class="p-4 text-gray-500">' + _esc(item.category||'-') + '</td>' +
                '<td class="p-4 text-center font-bold text-blue-600">' + _fmtNum(item.sales_price) + ' EGP</td>';

            var totalStock = item._totalStock || 0;
            rowHtml += '<td class="p-4 text-center font-bold cursor-pointer underline text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + totalStock + '</td>';

            var branchStock = item._branchStock || {};

            for (var b2 = 0; b2 < branchIds.length; b2++) {
                var bid2 = branchIds[b2];
                var st = branchStock[bid2] || { qty: 0, allocated: 0 };
                var branchName2 = '';

                for (var bn2 = 0; bn2 < branches.length; bn2++) {
                    if ((branches[bn2].id || branches[bn2].branch_code) === bid2) {
                        branchName2 = branches[bn2].name || branches[bn2].branch_code || bid2;
                        break;
                    }
                }

                rowHtml += '<td class="p-4 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
            }

            rowHtml += '<td class="p-4 text-center"><span class="px-2 py-1 rounded-full text-xs font-bold ' + status.color + '">' + status.label + '</span></td></tr>';
            return rowHtml;
        });
```

**ملاحظة تنفيذية مهمة:** البلوك أعلاه يعيد أيضًا السلوك التاريخي الصحيح للفرع المحدد؛ لذلك لا تُستبدل فقط عبارة `var rowHtml` داخل الحلقة.

---

# 7. ITEMS SUBMODULES REVIEW

## 7.1 Movement Report

Current Source يحتوي نسخة أكثر تطورًا من الأصل التاريخي:

- يقرأ `inventory_log` المركزي.
- يقيّد `company_id` بسياق الجلسة.
- يقيّد `item_id` بهوية الصنف.
- يدعم التاريخ.
- يدعم branch-specific reporting.
- يحسب opening balance.
- يميز physical movement types.
- يعرض المستخدم والمرجع.

هذا ليس مكانًا لإعادة إدخال النسخة التاريخية الأبسط المعتمدة على `stock_vouchers`.

**لا تعديل هنا.**

## 7.2 Matrix

المصفوفة الحالية تحتوي search + branch filter + pagination + Excel export + branch movement drill-down.

**لا تعديل هنا.**

## 7.3 Upload / Inventory Adjustment

المسار الحالي يحتوي:

- CSV/XLS/XLSX.
- parsing للعناوين.
- duplicate aggregation.
- item resolution.
- preview.
- replace/add/deduct.
- operation identity داخل جلسة الواجهة.
- refresh بعد نجاح العملية.

**لا تعديل هنا في هذا closure.**

## 7.4 Categories

الـCurrent يستخدم company-scoped queries، والـProduction `save-category` الحالي أيضًا يحقق company context من المستخدم والصلاحيات قبل CRUD.

**لا تعديل مطلوب في هذا closure.**

## 7.5 Delete Item

Production `delete-item` الحالي:

- verify JWT.
- يحدد `company_id` من `users.auth_id`.
- يتحقق من الصلاحية.
- يحذف `items` مع `company_id + item_code`.

**لا تعديل مطلوب في هذا closure.**

---

# 8. COST_PRICE — HISTORICAL GAP, NOT PROVEN CURRENT REGRESSION

Current Production `save-item` يدعم:

```text
cost_price
```

لكن واجهة `RW_Items.openItemPage()` الحالية لا تعرض حقل Cost Price، والـpayload الحالي لا يرسل `cost_price`.

تمت مقارنة هذا أيضًا مع `Original/PWA/main/main2.md`، ووجد أن النسخة التاريخية لنفس module لم تكن تعرض `cost_price` في form أيضًا.

لذلك:

```text
Current regression caused by merge = NOT PROVEN
Historical behavior = also omitted cost_price
```

هذا يعني أن إضافة حقل تكلفة إلى الواجهة الآن ستكون **تغييرًا وظيفيًا جديدًا** وليس مجرد restoration للنسخة الأصلية.

بالتالي لم يتم تعديل هذا الجزء تلقائيًا.

### القرار

لا يُفتح Closure مستقل لـ`cost_price` إلا بعد إثبات العقد التاريخي/صلاحيات الأدوار/سبب إخفاء pricing details، ثم يُقرر هل المطلوب:

```text
restore
```

أم:

```text
new Gold/Diamond capability
```

ولا يجوز الخلط بينهما.

---

# 9. CURRENT PRODUCTION / DATABASE CROSS-CHECK

تمت مراجعة Production Supabase الحالية:

```text
Project = SMART ERP
Project ref = fiilmooggumokxanwiyx
Status = ACTIVE_HEALTHY
Postgres = 17.6.1.121
Region = eu-west-1
```

الـProduction `save-item` الحالي هو version 13 ويقوم بـ:

- authentication.
- company resolution من `users.auth_id`.
- permission check.
- category company validation.
- edit/create.
- opening branch validation.
- delegating opening stock إلى `create_item_with_opening_stock`.

الـProduction `save-category` الحالي هو version 4 وcompany-scoped.

الـProduction `delete-item` الحالي هو version 4 وcompany-scoped.

**لم يثبت من هذا closure أي إصلاح Database/Production مطلوب خصيصًا لاستعادة وظائف Items.**

لذلك:

```text
Production Data Repair = NONE
Production Migration = NONE
Production Edge Deployment = NONE
```

في هذه الـclosure الخاصة بتبويب الأصناف.

---

# 10. E2E VERIFICATION STATUS

لا توجد في هذه البيئة أداة Browser E2E فعلية تسمح لي بتنفيذ click/login/type داخل المتصفح المنشور.

لذلك لا يجوز كتابة:

```text
Browser E2E PASS
```

ما تم إثباته هو:

```text
CURRENT GIT = VERIFIED
LATEST HEAD = VERIFIED
PARENT COMMIT = VERIFIED
CURRENT MAIN.HTML = VERIFIED
ITEMS MODULE = VERIFIED
ORIGINAL ITEMS MODULE = VERIFIED
REGRESSION IN _renderTable = PROVEN
BRANCH DRILL-DOWN REGRESSION = PROVEN
FORENSIC ASSEMBLY SOURCE = VERIFIED
PRODUCTION save-item = VERIFIED
PRODUCTION save-category = VERIFIED
PRODUCTION delete-item = VERIFIED
```

---

# 11. WHAT WAS NOT CHANGED

لم يتم تعديل:

```text
erp-frontend/companies/company-1/main.html
```

لأن الملف منشور في مستودع المالك، والمستخدم هو من يطبق الـsurgical replacement عليه.

لم يتم تعديل:

```text
Current/PWA/main2/*
Original/PWA/main/*
```

لأنهما تاريخيان فقط.

لم يتم تعديل `forensic_main_assembly.yml` لأنه صحيح بالفعل.

لم يتم فتح أو تغيير Production migration خاصة بـItems لأن الأدلة الحالية لا تثبت ضرورة ذلك.

---

# 12. ERRORS / FAILED ATTEMPTS DURING SESSION

ظهر أثناء العمل السابق في مسار آخر متعلق بالمخزون اختبار idempotency لم يكن صالحًا كدليل نهائي بسبب ترتيب الحارس والتحقق، وتم التعامل معه كاختبار غير مكتمل لا كـProduction PASS.

في نطاق Items الحالي لم يحدث تعديل Production فاشل، ولم يتم تسجيل migration إضافية غير مطلوبة.

---

# 13. FINAL RESULT

## Current functional verdict for Items

```text
Items overall feature set = MOSTLY PRESENT
Major historical feature loss = NOT PROVEN
Critical renderer regression = PROVEN
Branch-specific drill-down loss = PROVEN
Matrix = PRESENT
Movement report = PRESENT + CURRENTLY MORE CENTRALIZED
Upload adjustment = PRESENT
Category management = PRESENT
Item CRUD = PRESENT
3 item tabs = PRESENT
Opening stock = PRESENT
Image handling = PRESENT
```

### Closure status

```text
ITEMS FORENSIC REVIEW = COMPLETE
OWNER FRONTEND FIX = PENDING
PRODUCTION FIX = NOT REQUIRED FOR THIS ITEMS CLOSURE
BROWSER E2E = NOT EXECUTABLE IN THIS ENVIRONMENT
FULL GOLD/DIAMOND SYSTEM = OPEN
```

لا يجوز اعتبار `ITEMS = 100% CLOSED` قبل أن يطبق المالك الاستبدال الجراحي للـrenderer ثم يعمل browser E2E على النسخة المنشورة الحالية.

---

# 14. WHAT THE NEXT CTO / ASSISTANT MUST DO FIRST

**هذه التعليمات جزء من التقرير وليست اقتراحًا عامًا.**

1. ابدأ من:

```text
CURRENT GIT HEAD
```

ثم افحص الـparent المباشر، ثم مصدر `companies/company-1/main.html` الحالي، ولا تعيد تنفيذ إصلاحات موجودة بالفعل في HEAD.

2. بعد ذلك افحص Production الحالية من Supabase مباشرة، وليس من التقرير السابق.

3. اعتبر:

```text
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT
```

هي الأدلة الأساسية، واجعل التقارير مجرد تاريخ يشرح لماذا بُنيت الأشياء بهذا الشكل.

4. قبل أي تعديل اسأل بالترتيب:

```text
ما العقد التاريخي؟
ما السلوك الحالي؟
ما الفرق المثبت؟
هل الفرق Regression أم Capability جديدة؟
أين انتقلت المسؤولية إن تغيرت؟
```

5. في الـfrontend استخدم:

```text
EXACT SEARCH
→
EXACT DELETE
→
COMPLETE REPLACEMENT
→
OWNER DEPLOYS
→
FRESH INCOGNITO
→
BROWSER VERIFY
→
NEXT REAL ERROR ONLY
```

6. في Production استخدم Closure Unit منفصلة. لا تخلط إصلاح Writer أو RPC أو tenant issue مع frontend UI closure.

7. لا تعتبر:

```text
Git commit
```

هو نفسه:

```text
Deployment
```

ولا تعتبر deployment هو نفسه runtime success، ولا runtime success هو نفسه browser E2E pass.

8. إذا ظهر شيء “غير منطقي” في الكود، لا تصلحه قبل فتح تاريخه؛ قد يكون:

```text
Historical Contract
Compatibility Layer
Migration Bridge
Business Rule
أو Bug حقيقي
```

9. لا تُضف capability جديدة باسم “إصلاح Regression” إلا إذا ثبت أنها كانت موجودة في العقد السابق أو ثبت أن Target Architecture تتطلبها صراحة.

10. عند الوصول إلى next closure، لا تبدأ بـItems من جديد. ابدأ من أول نقطة لم تُغلق في جدول الحالة الحالي فقط.

---

# FINAL SELF-AUDIT

### What I Proved

- Current HEAD وparent تم التحقق منهما.
- Source of Truth الحالي verified.
- `forensic_main_assembly.yml` صحيح.
- `RW_Items` الحالية تحتوي غالبية وظائفها التاريخية.
- `_renderTable` الحالي يحتوي Regression حقيقية ومحددة.
- branch-specific drill-down مفقود من current list renderer.
- Production item/category/delete capabilities موجودة وcompany-scoped.

### What I Did Not Prove

- Browser E2E pass.
- أن `cost_price` يجب إضافته إلى UI؛ الموجود تاريخيًا لا يثبت ذلك.
- أن هناك فقدًا واسعًا لوظائف أخرى في Items يتجاوز Regression التي تم تحديدها هنا.

### What I Fixed

في هذه closure:

```text
Production = no new fix required
```

والتعديل frontend محدد بالكامل في قسم **EXACT OWNER-ONLY FRONTEND FIX** لينفذه المالك.

### What I Initially Missed / Corrected During Investigation

التحقيق الأولي ركز على وجود الوظائف نفسها. بعد المطابقة السطرية ظهر أن المشكلة الأهم ليست غياب module كامل، بل فساد renderer أثناء الدمج: إعادة تعريف `rowHtml` داخل الحلقة وفقدان branch-specific arguments.

### What Could Still Be Wrong

الـbrowser runtime بعد تطبيق الإصلاح قد يكشف مشاكل أخرى في أجزاء أخرى من النظام الأم. لا يجوز استباقها.

### Final Closure Status

```text
REPORT153 = COMPLETE
ITEMS FORENSIC GAP IDENTIFICATION = COMPLETE
OWNER PATCH INSTRUCTION = COMPLETE
PRODUCTION PATCH = NOT REQUIRED
BROWSER E2E = PENDING REAL BROWSER EXECUTION
GLOBAL GOLD/DIAMOND = OPEN
```
