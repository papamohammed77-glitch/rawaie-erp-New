# تقرير 60 — مراجعة وتنفيذ الجزء الثاني Main2

**التاريخ:** 2026-09-05
**المستودع:** `papamohammed77-glitch/rawaie-erp-New`
**الفرع:** `main`
**النطاق:** `Current/PWA/main2/main2.md`
**المهمة:** استكمال الإغلاق الجراحي للجزء الثاني وفق المبادئ الحاكمة وReport59 وMASTER - RAWAEA ERP.md.

## 1. مبدأ الحوكمة المطبق

تم التعامل مع المهمة باعتبارها استمرارًا لسلسلة Main2 السابقة، وليس إعادة بدء. تمت مراجعة المصدر الحاكم `MASTER - RAWAEA ERP.md`، و`CURRENT_STATE.md`، وReport59، ثم فحص Production وGit history قبل التعديل.

تم الالتزام بالمبدأ:

`READ → VERIFY → RECONCILE → UNDERSTAND → PATCH → VERIFY`

كما تم التعامل مع Main2 باعتباره جزءًا منطقيًا من النظام الأم، وليس ملفًا مستقلًا، ولم يتم تعديل `New-main`.

## 2. الحالة التي تم استردادها

آخر حالة موثقة قبل الجلسة كانت:

- Main1 source mutation: `ed4e91ec...`
- آخر Main2 mutation موثق: `a6556235...`
- Report59: كشف ثمانية عيوب جراحية M2-01 إلى M2-08.
- حالة `Current/PWA/main2/main2.md` عند بدء الجلسة كانت blob `b1096fdadd4734881d2c16c341dea769fc306fc5` وفق CURRENT_STATE/Report59.

تمت مطابقة ذلك مع الحالة الحالية بدل الاعتماد على التقرير وحده.

## 3. نتائج الفحص الفعلي

### M2-01 — Tenant scope في Dashboard
تم التحقق من أن استعلام المبيعات وصافي الربح أصبحا يستخدمان `eq('company_id', companyId)`.

**الحكم:** مطبق في Main2 الحالي.

### M2-02 — Top Items يستخدم `orderIds` غير معرفة
تم اكتشاف أن أول إصلاح آلي أضاف استعلامًا صحيحًا باستخدام `topOrderIds` لكنه ترك الاستعلام القديم الذي يستخدم `orderIds` داخل `loadAll`.

محاولة إزالة هذا الاستعلام أُعدت في executor جراحي fail-closed، لكن executor لم يُنفذ على الفرع الرئيسي قبل إغلاقه.

**الحكم:** ما زال مفتوحًا في `main2.md` النهائي.

**التصحيح المطلوب حرفيًا:** حذف الكتلة:

```javascript
// 5. أفضل الأصناف
supabase.from('order_details').select('item_code, item_name, qty, unit_price').in('order_id', orderIds).then(function(res) {
    renderTopItemsChart(res.data || []);
}).catch(function() {});
```

دون حذف المسار الصحيح الذي يستخدم `topOrderIds` داخل callback الخاص بـ`orders`.

### M2-03 — Category replacement selector
تم التحقق من وجود `eq('company_id', companyId)` في lookup الخاص بالتصنيفات البديلة.

**الحكم:** مطبق.

### M2-04 — Barcode lookup في upload preview
تم اكتشاف أن lookup الباركود بقي بلا `company_id` scope في النسخة النهائية الحالية.

**الحكم:** ما زال مفتوحًا.

**التصحيح المطلوب حرفيًا:**

من:

```javascript
supabase.from('items').select('id, item_code, barcode, name').in('barcode', barcodes)
```

إلى:

```javascript
supabase.from('items').select('id, item_code, barcode, name').eq('company_id', companyId).in('barcode', barcodes)
```

### M2-05 — تنفيذ صفوف غير صالحة من ملف التسوية
تم التحقق من إضافة `_valid` أثناء المعاينة، وأن التنفيذ يرسل الصفوف التي تم اعتمادها فقط.

**الحكم:** مطبق.

### M2-06 — Contract mismatch في adjustment success handler
تم تغيير اعتماد الواجهة من `json.results[]` إلى `json.movement_count`، وهو متوافق مع عقد Production الحالي لـ`post_inventory_adjustment_atomic`.

**الحكم:** مطبق.

### M2-07 — Retry idempotency
تم التحقق من وجود `operation_id` ثابت خلال دورة upload الواحدة، وتغييره فقط عند تحميل ملف جديد، مع تنظيفه بعد نجاح العملية.

**الحكم:** مطبق في Main2 الحالي.

### M2-08 — Stock voucher movement report tenant scope
تم التحقق من إضافة `eq('company_id', companyId)` إلى استعلام `stock_vouchers` الخاص بتقرير الحركة.

**الحكم:** مطبق.

## 4. Production / Database verification

تم فحص Production مباشرة في نطاق المهمة السابقة/الموازية للتحقق من العقود التي تعتمد عليها Main2، ومن أهم النتائج:

- `post_inventory_adjustment_atomic` منشور كـ`SECURITY DEFINER` ويستدعي `post_stock_movement`.
- عقد Production يعيد `movement_count` وليس `results[]`، وهو ما يبرر إصلاح M2-06.
- `items.item_code` عليه قيد `UNIQUE` عالميًا في schema الحالي، ولذلك لا يجوز فرض company scope على الهوية العالمية للصنف عند التعامل مع `item_id/item_code` كهوية master، بينما يجب إبقاء lookups التشغيلية الأخرى company-scoped.
- `stock_branches` لديه uniqueness على `(branch_id,item_id)`.

هذه النتائج استُخدمت للتحقق من العقد، لا لإعادة تفسير Business Logic بالتخمين.

## 5. ما تم تنفيذه فعليًا في Git

حدثت سلسلة تعديلات فعلية على `main` أثناء الجلسة، أهمها:

- `7248ef0ed42d88410d0e1bd2f7bfaabc8328c9a6` — إدخال إصلاحات Main2 الأساسية M2-01/M2-03/M2-05/M2-06/M2-07/M2-08.
- `3c5478e9f4c2c3020c1d1ede1b33099e4aac3aea` — تحديث executor الجراحي المتبقي.
- `f50eee4ff308e2cb3bcb93c297b5f6e58142834c` — تنظيف executor التجريبي.
- `daafdb1507de421a43e6911fe5263f4f03d328dd` — تنظيف ملف trigger التجريبي.

تم إنشاء PR #128 كقناة تنفيذ تجريبية مضبوطة، لكنه لم يُدمج، ثم أُغلق صراحةً حتى لا تبقى قناة تنفيذ مؤقتة مفتوحة.

## 6. ما فشل ولماذا

الآلية التي تستخدم GitHub Contents API تعطي primitive لاستبدال الملف كاملًا ولا تقدم patch جزئيًا للملف الكبير. لذلك كان من غير الآمن إعادة كتابة `main2.md` كاملًا يدويًا اعتمادًا على مخرجات truncated.

تم استخدام executor جراحي موجود/مؤقت لمحاولة تنفيذ التعديل الجزئي، لكن فحص GitHub Actions أظهر أن قناة التنفيذ المطلوبة لم تنتج commit Main2 النهائي، مع وجود Workflow runs أخرى فاشلة لا تخص هذا الإصلاح. لذلك تم رفض اعتبار ذلك نجاحًا.

كذلك اتضح أن أحد الاختبارات/التحويلات الأولى ترك residual defect (`orderIds`) بعد أن أنشأ المسار الصحيح؛ وتم اكتشافه في post-write audit بدل تمريره كتعديل ناجح.

## 7. Verification matrix

| البند | النتيجة |
|---|---|
| Historical context reviewed | PASS |
| MASTER governance reviewed | PASS |
| CURRENT_STATE reviewed | PASS |
| Report59 reviewed | PASS |
| Production contract checked | PASS |
| M2-01 | CLOSED in source |
| M2-02 | OPEN — residual `orderIds` |
| M2-03 | CLOSED in source |
| M2-04 | OPEN — barcode lookup unscoped |
| M2-05 | CLOSED in source |
| M2-06 | CLOSED in source |
| M2-07 | CLOSED in source |
| M2-08 | CLOSED in source |
| Production runtime verification for Main2 | NOT PERFORMED |
| Main2 100% closure | **INCOMPLETE** |

## 8. Mandatory self-audit

### What I proved

1. Main2 الحالي يحتوي فعليًا على معظم الإصلاحات المطلوبة من Report59.
2. M2-02 وM2-04 تم اكتشاف بقائهما بعد post-write audit، ولم يتم إخفاؤهما خلف تقرير نجاح.
3. Contract الخاص بـM2-06 متوافق مع Production.
4. لا يوجد تعديل مقصود على `New-main` ضمن هذه المهمة.
5. PR التنفيذ التجريبي تم إغلاقه ولم يُترك مفتوحًا.

### What I did not prove

1. لم أثبت تشغيل Main2 النهائي في Production/runtime.
2. لم أثبت assembled parent artifact بعد دمج أجزاء Main2/11 fragments.
3. لم أثبت browser-level integration للجزء الثاني.
4. لم أثبت أن M2-02/M2-04 مغلقان في `main2.md` النهائي.

### What I fixed

- M2-01
- M2-03
- M2-05
- M2-06
- M2-07
- M2-08

### What I initially missed

- residual `orderIds` بعد إضافة المسار الصحيح لـTop Items.
- بقاء barcode lookup بلا company scope.

### What could still be wrong

- أي drift لاحق في مصدر `main2.md` قبل assembly.
- أي defect تكاملي يظهر عند ربط Main2 مع main1/core.js.
- أي consumer يعتمد على عقد غير موثق خارج نطاق هذا الجزء.

### Final confidence

**متوسطة بالنسبة للإصلاحات المصدرية الستة المغلقة، ومنخفضة بالنسبة لإعلان Main2 closure الكامل.**

### Final Closure Status

```text
MAIN2 SOURCE SURGERY = PARTIALLY CLOSED
M2 CLOSED = 6/8
M2 OPEN = 2/8
PRODUCTION RUNTIME = NOT VERIFIED
GLOBAL MAIN2 CLOSURE = INCOMPLETE
```

## 9. الخطوة التالية الصحيحة

يجب إغلاق M2-02 وM2-04 مباشرةً في `Current/PWA/main2/main2.md` بتعديلين جراحيين فقط، ثم إجراء:

1. static/syntax verification.
2. diff review.
3. commit source mutation.
4. إعادة قراءة `main2.md` من `main` والتأكد من عدم وجود `orderIds` غير معرفة وعدم وجود barcode lookup غير scoped.
5. بعدها فقط يمكن الانتقال إلى الجزء التالي.

لا يجوز اعتبار Main2 مكتملًا أو الانتقال إلى final assembly قبل إغلاق هذين البندين والتحقق منهما.
