# Report461 — إصلاح حفظ ملاحظات التحضير والتحقق من عرض الكميات

التاريخ: 2026-10-21  
النطاق: `complete_runsheet_picking` في Supabase Production، مع مراجعة `main.html` الحالية الخاصة بجدول التحضير.  
حدود الملكية: لم يتم تعديل `main.html` أو `warehouse/picker.html`. تم إصلاح Core في Production عبر migration موثقة. اختبار التحقق استخدم معاملة SQL انتهت بـ ROLLBACK، ولم يترك بيانات اختبار.

## PRE-CHANGE SELF-AUDIT

- Business Understanding: مثبت — التطبيق التشغيلي يرسل `item_code/picked_qty/notes`، والنظام الأم يجمع `order_details.reason_picking` لعرض الملاحظات حسب الرانشيت.
- Architecture Understanding: مثبت — `complete-picking v18` يستدعي overload ذي خمسة معاملات `complete_runsheet_picking(..., p_operation_id)`؛ ثم يقوم trigger `sync_run_sheet_details` بتحديث إسقاط الكميات من `order_details` إلى `run_sheet_details`.
- Historical Understanding: تمت مراجعة Report458 وReport459 وReport460 و`CURRENT_STATE.md` وسجل commits الحالي.
- Current Source: `erp-frontend/companies/company-1/main.html` blob SHA `60c83c51be5aa24993a01fe5e148c4bd247ccca6`؛ تم جلب الـblob وقراءة `loadPicking()` و`_applyPicking()` و`_showPickingDetails()`. مصدر تطبيق التحضير `warehouse/picker.html` SHA `ffe18d4483ee074230e32b1c96f60507e5876a4b`.
- Current Git: آخر commit لملف `main.html` هو `8da2acbd450a0debd49f3c721881007683d873ca` بتاريخ 2026-10-21 14:42:39 UTC، ورسالة commit: `Refactor user retrieval to use RPC call`. Parent: `166914a29e5bce2173c030fc827e07e191d0779a`.
- Production: `start-picking v35` و`complete-picking v18` نشطتان و`verify_jwt=true`. RPC هوية المحضّر `get_picking_display_users(uuid[])` موجودة وACL الحالي: anon=false، authenticated=true، service_role=true.
- Execution Confidence: مرتفع لإثبات خلل حفظ الملاحظات وإصلاحه واختباره داخل معاملة متراجعة؛ غير كافٍ لإثبات HTML المخدوم أو Browser E2E.

## 1. الأدلة الحية قبل الإصلاح

### 1.1 كميات التحضير

استعلام Production المباشر أثبت:

| الرانشيت | الحالة | مجموع order_details.qty_picked | مجموع run_sheet_details.qty_picked |
|---|---|---:|---:|
| RS-1 | Picked | 13 | 13 |
| RS-2 | Open | 0 | 0 |

التحقق التفصيلي من إسقاط `run_sheet_details` لـRS-1 أعاد خمس صفوف بقيم 4، 3، 4، 1، 1؛ المجموع 13. وRS-2 يعرض صفرًا في جميع تفاصيله لأنه ما زال Open. لذلك لا يوجد عيب كمية مثبت في Core أو projection لهذه اللقطة الحية. لا يثبت ذلك ما يعرضه HTML المنشور في المتصفح.

### 1.2 السبب الجذري المثبت لفقدان بعض الملاحظات

النسخة السابقة من overload ذي خمسة معاملات كانت تحتوي:

```sql
v_note := case when assign_qty < coalesce(od_rec.qty,0) then rec.notes else null end;
```

هذا يكتب الملاحظة فقط عندما تكون الكمية المسندة لسطر الطلب أقل من المطلوب. عند تحضير كامل الكمية مع إدخال ملاحظة (مثل تلف تغليف، ملاحظة جودة أو تداول)، كانت القيمة المحفوظة `reason_picking` تصبح NULL. وبما أن النظام الأم يجمع الملاحظات من `order_details.reason_picking`، فلا توجد ملاحظة يمكن للواجهة عرضها أصلًا.

### 1.3 اختبار إعادة إنتاج قبل الإصلاح

أُجري اختبار تشخيصي داخل معاملة على RS-2 باستخدام `operation_id` مؤقت وملاحظة `QA_FULL_QTY_NOTE_ROLLBACK`. النتيجة قبل الإصلاح: `qty_picked=1` بينما `reason_picking=NULL` رغم إرسال الملاحظة. انتهت المعاملة بـ `ROLLBACK`؛ ثم أثبت فحص مستقل أن RS-2 عاد إلى Open، والكمية المحضّرة 0، ولا توجد ملاحظة اختبار ولا سجل operation registry متبقٍ.

## 2. إصلاح Production المنفذ

تم تعديل overload المستخدم فعليًا فقط:

```
public.complete_runsheet_picking(
  uuid, text, text, jsonb, uuid
)
```

- أبقيت overload القديم ذي أربعة معاملات دون تعديل؛ ACL الحي يثبت أنه غير قابل للتنفيذ من anon/authenticated/service_role، ولا يستخدمه Edge الحالي.
- أبقيت `complete-picking v18` وAPI contract و`operation_id` و`reserve_stock` والتوزيع والكميات والحالة دون تغيير.
- أبقيت سلوك ملاحظات النقص: إذا كانت الكمية الإجمالية المحضّرة أقل من المطلوبة، تُحفظ الملاحظة على سطور الطلبات غير المكتملة كما كان مقصودًا.
- أضفت سلوكًا محدودًا: إذا اكتملت الكمية الإجمالية للصنف ومع ذلك أُدخلت ملاحظة، تُحفظ الملاحظة مرة واحدة على أول سطر طلب حتميًا حسب `created_at NULLS FIRST, id`، لتجنب تكرار الملاحظة نفسها على كل طلب يحتوي الصنف.
- الملاحظة الفارغة أو المكونة من مسافات تتحول إلى NULL.
- لم تُضف جداول أو Edge Functions، ولم يتغير أي ACL أو RLS.

**Canonical migration:**  
`supabase/migrations/20261021145600_preserve_picking_notes_when_fully_picked.sql`  
**Commit:** `4cba5b3832b775030e609a098be5a55056e0d727`  
**Production migration:** نجاح التطبيق مؤكد من نتيجة أداة migration، ثم تم فحص تعريف الدالة الحي بعد التطبيق.

## 3. اختبارات ما بعد الإصلاح

### 3.1 تعريف Production وACL

PASS:
- overload الخماسي يحتوي منطق `v_note_written` وشرط المقارنة `rec.picked_qty < total_qty`.
- `anon EXECUTE=false`.
- `authenticated EXECUTE=false`.
- `service_role EXECUTE=true`.
- overload الرباعي القديم: لا يملك EXECUTE لـanon أو authenticated أو service_role.

### 3.2 اختبار سلوك الملاحظات داخل معاملة

تم تنفيذ اختبار بعد الإصلاح على RS-2 داخل معاملة متراجعة:
- صنف 1001: الكمية المطلوبة 1، المحضّرة 1، الملاحظة `QA_FULL_QTY_NOTE_ROLLBACK` — **PASS: الملاحظة حُفظت**.
- صنف 1004: الكمية الإجمالية المطلوبة 2، المحضّرة 1، الملاحظة `QA_SHORTAGE_NOTE_ROLLBACK` — **PASS: بقيت الملاحظة على السطر غير المكتمل، ولم تُكتب على السطر المكتمل**.
- `ROLLBACK` أعاد RS-2 إلى `Open`، و`picker_id=NULL`، ومجموع `qty_picked=0`.
- فحص residue بعد المعاملة: ملاحظات اختبار = 0، operation registry = 0، والكمية الأصلية للمخزون للصنف 1001 = 6.0000؛ لم يبقَ أثر من الاختبار.

## 4. ما أثبته فحص المصدر الحالي

المصدر الحالي يتضمن بالفعل:
- أعمدة مسؤول التحضير ووقت البداية والنهاية وملاحظات التحضير.
- الحالات Open وConfirmed وPicking وPicked، مع عرض الحالة الحقيقية.
- استدعاء `get_picking_display_users` بدل قراءة جدول users مباشرة.
- تجميع `order_details.reason_picking` حسب الطلب والصنف.
- تفاصيل الكمية تقرأ `run_sheet_details.qty_picked`، وهو العمود الصحيح والمتطابق مع المصدر في بيانات Production الحالية.

لا تعِد تطبيق هذه الأجزاء.

### فجوة واجهة باقية: معالجة أخطاء نافذة التفاصيل

في `_showPickingDetails(code)`، السطور الحالية 15475–15482، لا يتم فحص `rsRes.error` أو `itemsRes.error`، ولا يتم التحقق من أن الرانشيت موجود قبل استعلام التفاصيل. هذا لا يثبت أنه سبب الصفر السابق، لكنه يسمح بإخفاء خطأ الاستعلام خلف رسالة «لا توجد أصناف». على المالك تنفيذ الجراحة التالية فقط.

**الملف:** `erp-frontend/companies/company-1/main.html`  
**الدالة:** `_showPickingDetails(code)`  
**SHA المطابق:** `60c83c51be5aa24993a01fe5e148c4bd247ccca6`  
**ابحث عن المقطع الذي يبدأ بـ** `var rsRes = await supabase.from('runsheets')` **وينتهي بـ** `var items = itemsRes.data || [];`  
**استبدله كاملًا بهذا النص:**

```javascript
var rsRes = await supabase
    .from('runsheets')
    .select('id,status')
    .eq('company_id', companyId)
    .eq('runsheet_code', code)
    .maybeSingle();

if (rsRes.error) {
    hideLoader();
    showToast('فشل قراءة الرانشيت: ' + rsRes.error.message, 'error');
    return;
}
if (!rsRes.data || !rsRes.data.id) {
    hideLoader();
    showToast('الرانشيت غير موجود في الشركة الحالية', 'error');
    return;
}

var itemsRes = await supabase
    .from('run_sheet_details')
    .select('item_code,item_name,unit,qty_ordered,qty_picked')
    .eq('runsheet_id', rsRes.data.id)
    .order('item_code');

if (itemsRes.error) {
    hideLoader();
    showToast('فشل قراءة كميات التحضير: ' + itemsRes.error.message, 'error');
    return;
}

hideLoader();
var items = itemsRes.data || [];
```

هذا التغيير يضيف فحصًا صريحًا للأخطاء فقط ولا يغيّر مصدر الكمية أو منطق المخزون.

## 5. ما لم يثبت بعد

- لا توجد أدلة على أن HTML المخدوم من Cloudflare يطابق blob SHA الحالي.
- لم يتوفر Browser E2E مصادق عليه أو Network response من الجلسة التي عرضت الكمية صفرًا.
- لذلك لا يمكن نسبة الصفر السابق إلى Production Core؛ قاعدة البيانات الحالية تعيد 13 لـRS-1 في المصدر والإسقاط. إذا استمر الصفر بعد تطبيق جراحة الأخطاء والنشر، يجب تسجيل Response طلب `run_sheet_details` ونسخة HTML المخدومة قبل تغيير أي Core آخر.
- الملاحظات التي لم تُحفظ تاريخيًا بسبب الشرط القديم لا يمكن استعادتها من قاعدة البيانات إذا لم تُسجل في مصدر آخر؛ لا تُخترع ولا تُعاد كتابتها تخمينًا.

## 6. التغييرات المنفذة

- Migration SQL canonical أضيفت إلى Git.
- Production overload الخماسي تم تحديثه والتحقق من تعريفه وACL.
- اختبار ما قبل الإصلاح أعاد إنتاج فقدان الملاحظة داخل معاملة متراجعة.
- اختبار ما بعد الإصلاح أثبت حفظ الملاحظة عند اكتمال الكمية مع الحفاظ على سلوك النقص.
- تم التحقق من عدم بقاء أي أثر اختبار في RS-2 أو operation registry أو المخزون.
- لم يتم تعديل أي HTML ولم يتم تغيير بيانات أعمال دائمة.

## SELF-AUDIT FINAL

- **What I Proved:** المصدر السابق كان يهمل ملاحظة الصنف عندما تساوي الكمية المحضّرة المطلوبة؛ الاختبار أعاد إنتاج ذلك. المصدر الحالي للكميات صحيح، وRS-1=13 وRS-2=0 في Production. التعديل الحي يحفظ ملاحظة الكمية الكاملة مرة واحدة ويحافظ على ملاحظات النقص.
- **What I Did Not Prove:** تطابق HTML المخدوم، أو أن المتصفح الحالي يعرض RS-1=13 بعد النشر، أو نجاح Browser E2E.
- **What I Fixed:** Core Production لحفظ الملاحظات كاملة الكمية؛ وثبتت migration canonical ونتيجة اختبار متراجع بلا residue.
- **What I Initially Missed:** سبب ضياع الملاحظات لم يكن عرض الجدول وحده؛ جزء منها كان يُسقط قبل التخزين في `reason_picking`.
- **What Could Still Be Wrong:** قد يكون الصفر المرئي ناتجًا عن HTML مخدوم قديم أو استجابة مختلفة؛ لا دليل حاسم قبل Network/served artifact.
- **Final Confidence:** مرتفع في إصلاح حفظ الملاحظات؛ متوسط في التكامل النهائي للواجهة.
- **Final Closure Status:** `PRODUCTION NOTE-PERSISTENCE FIX VERIFIED / OWNER DETAILS-ERROR SURGERY REQUIRED / SERVED HTML + BROWSER E2E UNVERIFIED — NOT FULLY CLOSED`.
