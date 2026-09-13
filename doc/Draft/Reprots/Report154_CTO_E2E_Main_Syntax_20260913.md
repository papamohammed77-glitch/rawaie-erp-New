# Report154 — CTO E2E للنظام الأم — Syntax/Login Gate

**التاريخ:** 2026-09-13  
**نطاق الجلسة:** التحقيق الحالي في عدم تجاوز شاشة الدخول عند اختبار النظام الأم المنشور، مع التركيز على خطأ JavaScript عند السطر 2013، ومطابقة Git الحالي مع الـparent المباشر والمصدر الفعلي المنشور.  
**القاعدة الحاكمة:** التقارير السابقة STALE للاستئناس فقط. الحقيقة الحالية لا تُبنى إلا من `CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`.

---

# 0. الهدف الحاكم — اقرأ هذه النقطة بعناية

الهدف في هذه الجلسة هو **اختبار E2E لملف النظام الأم**:

```text
papamohammed77-glitch/erp-frontend
companies/company-1/main.html
```

والتحقق من أن النظام الأم يبدأ ويجتاز شاشة الدخول دون أخطاء JavaScript تمنع تنفيذ بقية البرنامج.

الهدف ليس كتابة تقرير نظري؛ الهدف الوصول إلى سبب قابل للإثبات، ثم تحديد الإصلاح الجراحي الصحيح، مع إبقاء التعديل على ملف النظام الأم من اختصاص المالك.

كما أن أي نتيجة لاحقة يجب أن تبدأ من المصدر المنشور الحالي، وليس من ملفات `Current/PWA/main2` التاريخية.

---

# 1. CURRENT GIT — إعادة بناء الحقيقة الحالية

تم رفض بيانات `CURRENT_STATE.md` القديمة كحالة حالية لأنها كانت تشير إلى HEAD أقدم.

الحالة الحية للفرع `main` في مستودع `erp-frontend` هي:

```text
HEAD = 02166a9f8e94ac0b2cc15257eb0aec8e039848bd
PARENT = 06264f8eefc5e0d5281538c80e9c7aaa454ecf9b
```

Commit HEAD:

```text
Update comment timestamp in main.html
2026-09-13 07:26:19Z
```

والـparent المباشر:

```text
Update main.html
2026-09-13 07:23:11Z
```

## نتيجة مراجعة الـparent

الـparent `06264f8` أدخل تعديلات حقيقية على `RW_Items._renderTable()`، منها:

- إضافة خلايا المخزون لكل فرع.
- إعادة استخدام `rowHtml +=` بدل فقدان الصف.
- إعادة تمرير `bid2 + branchName2` إلى `_renderStockMovementReport()`.

لكن نفس commit أدخل أيضًا escaping زائدًا داخل JavaScript string، حيث تحولت الحالة الصحيحة:

```javascript
\'
```

إلى الحالة المعيبة:

```javascript
\\'
```

داخل literal محاط بعلامات `'`.

## نتيجة مراجعة HEAD

HEAD `02166a9` لم يصلح هذا الجزء. تعديل HEAD الظاهر في الـdiff هو:

- تحديث timestamp في أول الملف.
- حذف قوس `}` بعد callback الخاص بـ`RW_Table.paginate` وقبل `function _sort(field)`.

وبالتالي فإن HEAD الحالي يحتوي عيبين مستقلين في نفس المنطقة:

1. malformed escaping عند السطر 2013، وكذلك في سطرَي 2019 و2035 داخل نفس الـcallback.
2. فقدان قوس إغلاق `}` للدالة `_renderTable()` بعد `});` وقبل `function _sort(field)`.

---

# 2. CURRENT SOURCE — الدليل المباشر

المصدر الحالي `main` تم فتحه مباشرة.

الـblob الحالي:

```text
e86c602ec65ac655c077f3d9f24f050e058829f4
```

الجزء الحالي من `_renderTable(data)` يثبت:

```javascript
function _renderTable(data) {
```

وتبدأ منطقة الـpagination عند السطر:

```javascript
        RW_Table.paginate('items-tbody', sorted, 1, 50, function(item, idx) {
```

وعند السطر 2013 تقريبًا يظهر:

```javascript
onerror="this.src=\\'data:image/svg+xml,...\\'"
```

كما تظهر الصيغة المعيبة نفسها عند:

```text
_swtichSubTab(\\'movement\\')
```

في خلية إجمالي المخزون، وفي خلية مخزون الفرع.

وبعد نهاية callback:

```javascript
        });
```

لا توجد في المصدر الحالي `main` علامة:

```javascript
    }
```

قبل:

```javascript
    function _sort(field) {
```

وهذا مطابق تمامًا لـdiff الـHEAD `02166a9`.

---

# 3. ROOT CAUSE — الخطأ الظاهر في Console

رسالة المتصفح:

```text
main:2013 Uncaught SyntaxError: Unexpected identifier 'data'
```

مفسرة مباشرة من الـsource الحالي.

داخل JavaScript literal يبدأ بـ:

```javascript
'
```

وجود:

```javascript
\\'
```

لا يعني `escaped quote` واحدًا، بل يعني backslash literal ثم quote غير مهربة، وبالتالي تنغلق الـstring قبل كلمة `data`.

وهذا يفسر حرفيًا:

```text
Unexpected identifier 'data'
```

ولا يوجد أي احتياج لافتراض آخر لهذه الرسالة.

تم عمل reproducer مستقل في Node.js، وأعطى نفس النتيجة:

```text
SyntaxError: Unexpected identifier 'data'
```

بينما النسخة المصححة التي تستخدم:

```javascript
\'
```

اجتازت `node --check` بنجاح.

---

# 4. SECOND ROOT CAUSE — قوس `_renderTable`

HEAD الحالي `02166a9` يحتوي diff صريحًا:

```diff
         });
-    }
+
 
     function _sort(field) {
```

أي أن commit الـHEAD حذف قوس الإغلاق الخاص بـ`_renderTable()`.

لذلك حتى بعد إصلاح escaping عند السطر 2013، لا يجوز إعلان النجاح؛ يجب أيضًا إعادة القوس `}` إلى موضعه الصحيح.

هذه ليست ملاحظة شكلية. هي syntax defect مستقل في المصدر الحالي.

---

# 5. لماذا لا نستخدم Report153 كما هو

Report153 كان صحيحًا في تشخيص بعض Regression الخاصة بالـrenderer، لكنه الآن **STALE بالنسبة للحالة الحالية**.

الأهم أن الـreplacement الموجود داخله يحمل escaping زائدًا هو نفسه:

```javascript
\\'
```

ولذلك لا يجوز للمالك نسخ replacement من Report153 حرفيًا.

والسبب الثاني أن `HEAD` الحالي لم يعد يملك regression القديمة الخاصة بـ`var rowHtml` داخل الحلقة بالطريقة نفسها التي كانت موجودة في مرحلة أقدم؛ بل أصبح لديه `rowHtml +=` الصحيح في المصدر الحالي.

بالتالي لا نعيد إصلاح ما أصلح بالفعل، ونصلح فقط العيوب الموجودة فعليًا في HEAD الحالي:

```text
Malformed escaping
+
Missing function-closing brace
```

---

# 6. OWNER-ONLY SURGICAL FIX — الحل التنفيذي الدقيق

**المساعد لم يعدل `erp-frontend/companies/company-1/main.html`.**

التعديل التالي ينفذه المالك فقط.

## ابحث عن العنصر الكامل

داخل:

```javascript
function _renderTable(data) {
```

ابحث عن هذا السطر الكامل عند السطر الحالي 2008 تقريبًا:

```javascript
        RW_Table.paginate('items-tbody', sorted, 1, 50, function(item, idx) {
```

ثم احذف **البلوك كاملًا** من هذا السطر حتى هذا السطر الكامل:

```javascript
        });
```

الذي يسبق مباشرة:

```javascript
    function _sort(field) {
```

ثم استبدله بالبلوك التالي **كاملًا**:

```javascript
        RW_Table.paginate('items-tbody', sorted, 1, 50, function(item, idx) {
            var img = item.image_url || 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22150%22 height=%22150%22%3E%3Crect fill=%22%23e2e8f0%22 width=%22150%22 height=%22150%22/%3E%3Ctext fill=%22%2394a3b8%22 font-family=%22Arial%22 font-size=%2214%22 x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 dy=%22.3em%22%3E📦%3C/text%3E%3C/svg%3E';
            var status = _getStockStatus(item);
            var rowHtml = '<tr class="hover:bg-blue-50"><td class="p-3 text-center text-xs text-gray-400">' + (idx + 1) + '</td>' +
                '<td class="p-4 cursor-pointer" onclick="RW_Items.openItemPage(' + _jsAttr(item.item_code) + ')"><div class="flex items-center gap-3">' +
                '<img src="' + _esc(img) + '" class="h-24 w-24 rounded-xl object-cover border-2 border-gray-100 shadow-sm cursor-pointer" onerror="this.src=\'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22150%22 height=%22150%22%3E%3Crect fill=%22%23e2e8f0%22 width=%22150%22 height=%22150%22/%3E%3Ctext fill=%22%2394a3b8%22 font-family=%22Arial%22 font-size=%2214%22 x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 dy=%22.3em%22%3E📦%3C/text%3E%3C/svg%3E\'" onclick="event.stopPropagation(); RW_Items._viewImage(' + _jsAttr(img) + ')" title="اضغط لتكبير الصورة">' +
                '<div><span class="font-bold text-base">' + _esc(item.name||'') + '</span><br><span class="text-xs text-gray-400">' + _esc(item.item_code||'') + '</span></div></div></td>' +
                '<td class="p-4 text-gray-500">' + _esc(item.category||'-') + '</td>' +
                '<td class="p-4 text-center font-bold text-blue-600">' + _fmtNum(item.sales_price) + ' EGP</td>';

            var totalStock = item._totalStock || 0;
            rowHtml += '<td class="p-4 text-center font-bold cursor-pointer underline text-blue-600" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + totalStock + '</td>';

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

                rowHtml += '<td class="p-4 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
            }

            rowHtml += '<td class="p-4 text-center"><span class="px-2 py-1 rounded-full text-xs font-bold ' + status.color + '">' + status.label + '</span></td></tr>';
            return rowHtml;
        });
    }
```

### مهم جدًا

الـdifference الجوهري عن replacement القديم هو:

```text
الصحيح داخل المصدر:
\'

وليس:
\\'
```

والبلوك الجديد يعيد أيضًا قوس الإغلاق:

```javascript
    }
```

قبل:

```javascript
    function _sort(field) {
```

---

# 7. WHAT WAS VERIFIED AFTER BUILDING THE REPLACEMENT

تم إعداد نسخة اختبارية من الـcallback المصحح وإخضاعها إلى:

```text
node --check
```

النتيجة:

```text
SYNTAX_PASS
```

كما تم اختبار reproducer للنسخة المعيبة، ونتج نفس خطأ المتصفح:

```text
Unexpected identifier 'data'
```

إذن الإصلاح ليس تخمينًا، بل تم ربط رسالة Console مباشرة بالبنية النحوية الفعلية.

---

# 8. TAILWIND CDN WARNING

Console يحتوي أيضًا على:

```text
cdn.tailwindcss.com should not be used in production
```

هذا **تحذير إنتاجي غير مانع لتشغيل JavaScript**، وليس سبب عدم تجاوز شاشة الدخول.

لم يتم تغييره داخل هذا الـclosure لأن تحويل Tailwind من CDN إلى build-time pipeline هو موضوع build/deployment مستقل، ولا يوجد دليل يبرر فتح تغيير واسع في ملف النظام الأم أثناء إصلاح Syntax Gate.

القرار:

```text
TAILWIND WARNING = KNOWN NON-BLOCKING
SEPARATE BUILD CLOSURE = OPEN
```

---

# 9. FORENSIC ASSEMBLY

تم فتح:

```text
rawaie-erp-New/forensic_main_assembly.yml
```

والحالة الحالية صحيحة:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

لا تعديل مطلوب في هذا الملف.

ملفات:

```text
Current/PWA/main2/*
Original/PWA/main/*
```

تبقى historical/reference only.

---

# 10. PRODUCTION / SUPABASE

هذا الـclosure الحالي خاص بـfrontend syntax gate.

لا يوجد دليل حالي يثبت أن Production Supabase هي سبب عدم تجاوز شاشة الدخول.

لم يتم تنفيذ أي migration أو تغيير بيانات أو نشر Edge Function متعلق بهذا الـclosure.

السبب: التعديل المطلوب مثبت داخل `main.html` قبل وصول التنفيذ أصلًا إلى مرحلة الدخول/التشغيل الوظيفي الكامل.

---

# 11. E2E STATUS — الصدق التشغيلي

لا توجد في هذه البيئة أداة Browser Automation حقيقية أستطيع من خلالها تنفيذ:

```text
open page
fill credentials
click login
observe rendered dashboard
```

لذلك لا يجوز كتابة:

```text
Browser E2E PASS
```

بعد تنفيذ المالك للتعديل والنشر، يصبح الـE2E المطلوب:

```text
fresh deployment
→ fresh incognito
→ login
→ تجاوز شاشة الدخول
→ dashboard
→ sidebar
→ Items
→ list rendering
→ branch cells
→ branch movement drill-down
→ matrix
→ upload
→ item CRUD
→ console = no SyntaxError
```

ويجب تسجيل كل نتيجة من المتصفح الفعلي.

---

# 12. WHAT WAS NOT TOUCHED

لم يتم تعديل:

```text
erp-frontend/companies/company-1/main.html
```

لأنه Owner-only.

ولم يتم تعديل:

```text
Current/PWA/main2/*
Original/PWA/main/*
```

ولم يتم تعديل:

```text
forensic_main_assembly.yml
```

لأنه صحيح.

ولم يتم تكرار أي إصلاح تاريخي غير لازم.

---

# 13. FINAL VERDICT

الحالة الحالية المثبتة:

```text
CURRENT GIT = VERIFIED
CURRENT HEAD = 02166a9
CURRENT PARENT = 06264f8
CURRENT SOURCE = VERIFIED
FORENSIC ASSEMBLY = VERIFIED
CONSOLE SYNTAX ROOT CAUSE = PROVEN
MISSING _renderTable BRACE = PROVEN
TAILWIND WARNING = NON-BLOCKING
SUPABASE CAUSE = NOT PROVEN
OWNER SURGICAL REPLACEMENT = READY
PRODUCTION CHANGE = NOT REQUIRED
BROWSER E2E = PENDING OWNER MERGE + REAL BROWSER
```

لا تعتبر هذه الجلسة `100% CLOSED` قبل أن يظهر المصدر المنشور بعد الدمج بدون SyntaxError، ثم يثبت ذلك من browser E2E فعلي.

---

# 14. NEXT CTO / ASSISTANT — كيف تبدأ للوصول إلى الحقيقة

ابدأ دائمًا بهذا التسلسل الحرفي:

```text
1. اقرأ branch main الحالي من Git مباشرة.
2. استخرج HEAD الحقيقي من branch ref، ولا تعتمد على CURRENT_STATE القديم.
3. افتح HEAD commit.
4. افتح parent المباشر.
5. قارن diff بينهما.
6. افتح الملف المستهدف من ref=main نفسه.
7. لا تعتمد على snippet من تقرير سابق إذا اختلفت معه نسخة main الحالية.
8. ثبّت أول خطأ Runtime/Syntax قابل لإعادة الإنتاج.
9. حدّد سببه من المصدر نفسه.
10. افحص إن كان هناك خطأ ثانٍ سيظهر بعد إصلاح الخطأ الأول.
11. نفّذ Static Verification على replacement قبل إصداره للمالك.
12. لا تعدّل Owner-only files بنفسك.
13. Production فقط تُعدل مباشرة إذا أثبت المصدر والـruntime ضرورتها.
14. بعد كل إصلاح أعد مزامنة Production/Deployment قبل أي نسبة أو تقرير.
15. لا تعتبر CODE PASS = RUNTIME PASS.
16. لا تعتبر RUNTIME PASS = Browser E2E PASS.
17. لا تعيد إصلاح شيء مثبت في HEAD الحالي أو Production الحالية.
18. استخدم التقارير التاريخية لفهم السبب والسياق فقط، لا كـcurrent state.
19. عند وجود تعارض بين تقرير وGit الحالي، Git الحالي هو المرجع الأول ثم Production ثم Database ثم Deployment evidence.
20. بعد إغلاق الـclosure الحالي فقط انتقل لأول defect حالي جديد.
```

## قاعدة الحوكمة النهائية

```text
REPORT
↓
PRIMARY SOURCE
↓
CURRENT GIT
↓
CURRENT SOURCE
↓
CURRENT PRODUCTION
↓
CURRENT DATABASE
↓
CURRENT DEPLOYMENT
↓
REPRODUCTION
↓
ROOT CAUSE
↓
SURGICAL FIX
↓
STATIC VERIFY
↓
DEPLOY
↓
RUNTIME VERIFY
↓
BROWSER E2E
↓
CLOSE
```

ولا يجوز القفز مباشرة من تقرير إلى Patch.

---

# 15. SESSION CLOSURE

```text
FORENSIC RECONSTRUCTION = COMPLETE
CURRENT HEAD RECONCILIATION = COMPLETE
CURRENT PARENT REVIEW = COMPLETE
CURRENT SOURCE REVIEW = COMPLETE
SYNTAX ROOT CAUSE = COMPLETE
EXACT OWNER FIX = COMPLETE
STATIC FIX VERIFICATION = COMPLETE
PRODUCTION FIX = NOT REQUIRED
REAL BROWSER E2E = PENDING OWNER MERGE
GLOBAL GOLD/DIAMOND = OPEN
```

**الخطوة الوحيدة التالية على ملف النظام الأم:** تنفيذ الاستبدال الجراحي الكامل المحدد في القسم 6، ثم نشر النسخة الجديدة وإجراء اختبار E2E فعلي في متصفح خفي جديد.
