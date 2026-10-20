# Report456 — منع قبول كمية تحضير أكبر من المطلوب في Picker

**التاريخ:** 2026-10-20  
**النطاق الوحيد:** `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/picker.html`  
**قاعدة الملكية:** المالك يطبق تعديل HTML/PWA؛ لم أعدّل `picker.html` أو `main.html`. فُحص Production/Supabase مباشرة، ولم يُجر أي تغيير في قاعدة البيانات أو Edge Functions لأن عقد Production الحالي يحتوي بالفعل على رفض للكمية الزائدة.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** المحضّر يجب أن يرى خطأ واضحًا إذا أدخل كمية تتجاوز كمية الصنف المطلوبة؛ لا يجوز تعديل الرقم بصمت أو تسجيل كمية غير التي أدخلها.
- **Architecture Understanding:** `App.editPickedItem(index)` يحفظ الكمية في جلسة الجهاز؛ `App.completePicking()` يرسلها إلى `complete-picking` ثم RPC `complete_runsheet_picking`. واجهة الإدخال ليست مصدر الحقيقة الوحيد، ويجب أن يظل الخادم هو الحارس النهائي.
- **Database Understanding:** `order_details.qty` و`qty_picked` من نوع numeric. دالة Production المركزية تتحقق من أن كمية التحضير لا تتجاوز مجموع الكمية المطلوبة للصنف قبل الحجز وتوزيع الكميات.
- **Historical Understanding:** تمت مقارنة الموضع المناظر في `rawaie-erp-review/PWA/warehouse/picker.html`، blob `7626ba320021a607854bf219f4bacd81fc3d1d92`. النسخة التاريخية تستخدم نفس نمط `Math.min(..., it.qty_ordered)`، لذا فالعيب قديم ومستمر، وليس تغييرًا أدخله آخر commit.
- **Production Understanding:** Edge Function الحية `complete-picking` هي **v18** و`verify_jwt=true`، و`ezbr_sha256=14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`. مصدرها يستدعي `complete_runsheet_picking` مع `p_operation_id`. لم تُجر عملية HTTP E2E ببيانات أعمال فعلية في هذه الدورة.
- **Current Understanding:** الملف الحالي `erp-frontend/companies/company-1/warehouse/picker.html`، blob SHA `13f0b5337749e5796774028989f92ffe95e5667b`، 1,004 أسطر / 52,782 حرفًا. أحدث commit مفحوص هو `88fde32d59c96ed1158d8ecdf49071de2d11b008`، وغيّر ترتيب `title/width` فقط لإصلاح خطأ نحوي سابق؛ لا تعِد تطبيق إصلاح Report455. إصلاح الصورة في Report422 موجود بالفعل في المصدر الحالي، فلا يُعاد تطبيقه.
- **Execution Confidence:** عالٍ في تحديد سبب القبول الصامت من المصدر؛ الإغلاق النهائي يتطلب تطبيق المالك ثم اختبار المتصفح على النسخة المنشورة.

## السبب الجذري المثبت

داخل `App.editPickedItem(index)`، عند السطر الحالي 687–689، يعيد `preConfirm`:

```javascript
preConfirm: function(){
    return { qty: Math.max(0, Math.min(parseInt(document.getElementById('swal-qty').value) || 0, it.qty_ordered)), notes: document.getElementById('swal-notes').value.trim() };
}
```

استخدام `Math.min(..., it.qty_ordered)` يخفي إدخال المستخدم الزائد ويحوّله تلقائيًا إلى الحد الأعلى، ولا يظهر أي تحذير. خاصية HTML `max` وحدها لا تكفي لمنع كتابة رقم أكبر يدويًا داخل عنصر HTML مضمّن في SweetAlert2.

## Production / Database contract — فحص مباشر

- `complete-picking`: Production v18، `verify_jwt=true`.
- `public.complete_runsheet_picking(uuid,text,text,jsonb,uuid)`: موجودة، `SECURITY DEFINER` مع `search_path=public`.
- صلاحيات التنفيذ التي فُحصت لهذه النسخة: `anon=false`, `authenticated=false`, `service_role=true`.
- الدالة المركزية تحتوي الحارس:
  `if rec.picked_qty > total_qty then raise exception 'picked quantity exceeds ordered quantity for %',rec.item_code; end if;`
- هذا يثبت وجود حماية خادمية في الـRPC المستعمل من Edge الحالية. لذلك لا يوجد مبرر لتعديل Production أو ACL أو المخزون لمعالجة مشكلة عرض التحذير في الواجهة.
- توجد أيضًا نسخة RPC قديمة بأربعة معاملات في Production. لم تُعدّل في هذه المهمة لأنها ليست عقد Edge الحالي ذي الخمسة معاملات، ولم يثبت أنها سبب هذه المشكلة؛ تُسجل كعنصر legacy منفصل لا يُخلط بإصلاح واجهة الكمية.

## التعديل الجراحي — يطبقه المالك

- **الملف:** `companies/company-1/warehouse/picker.html`
- **Blob SHA المستهدف:** `13f0b5337749e5796774028989f92ffe95e5667b`
- **الدالة:** `App.editPickedItem(index)`
- **الموضع:** السطور 687–689 في النسخة الحالية.
- **محدد البحث الفريد:** `preConfirm: function(){` داخل `editPickedItem: function(index){`.
- **ابحث عن كتلة `preConfirm` التالية واحذفها بالكامل:**

```javascript
            preConfirm: function(){
                return { qty: Math.max(0, Math.min(parseInt(document.getElementById('swal-qty').value) || 0, it.qty_ordered)), notes: document.getElementById('swal-notes').value.trim() };
            }
```

**واستبدلها بهذه الكتلة كاملة فقط:**

```javascript
            preConfirm: function(){
                var qtyElement = document.getElementById('swal-qty');
                var notesElement = document.getElementById('swal-notes');
                var rawQty = qtyElement ? qtyElement.value.trim() : '';
                var qty = rawQty === '' ? NaN : Number(rawQty);
                var maxQty = Number(it.qty_ordered);

                if (!Number.isFinite(qty) || !Number.isFinite(maxQty) || !Number.isInteger(qty)) {
                    Swal.showValidationMessage('أدخل كمية صحيحة كعدد صحيح.');
                    return false;
                }

                if (qty < 0) {
                    Swal.showValidationMessage('لا يمكن أن تكون الكمية المحضّرة أقل من صفر.');
                    return false;
                }

                if (qty > maxQty) {
                    Swal.showValidationMessage(
                        'الكمية المحضّرة (' + qty + ') أكبر من الكمية المطلوبة (' + maxQty + '). صحح الكمية قبل الحفظ.'
                    );
                    return false;
                }

                return {
                    qty: qty,
                    notes: notesElement ? notesElement.value.trim() : ''
                };
            }
```

لا تستبدل الدالة كاملة. لا تغيّر `main.html`، ولا تعدّل حفظ المسودة أو `operation_id` أو الحجز أو دورة حياة الرانشيت.

## اختبارات إلزامية بعد التطبيق

1. كمية مطابقة للمطلوب: تُحفظ وتنعكس في القائمة.
2. كمية أقل من المطلوب: تستمر في الحفظ وتظهر آلية سبب النقص كما هي.
3. كمية أكبر من المطلوب بمقدار 1: يظهر التحذير بالعربية، وتبقى النافذة مفتوحة، ولا تتغير المسودة.
4. كمية أكبر بكثير من المطلوب: نفس الرفض، دون تحويل صامت إلى الحد الأعلى.
5. كمية سالبة أو فارغة أو كسرية: لا تُحفظ؛ يظهر تحذير تحقق واضح.
6. بعد إدخال قيمة زائدة وظهور التحذير، صححها إلى قيمة صحيحة ثم احفظ؛ يجب أن ينجح الحفظ مرة واحدة.
7. أكمل التحضير بعد حفظ كمية صحيحة؛ تحقق من أن `complete-picking` وRPC يعملان بعقدهما الحالي، وأن الحارس الخادمي يرفض أي payload زائد إذا تجاوز الواجهة.
8. اختبر على النسخة المنشورة مع تعطيل cache. سجّل SHA المصدر بعد التطبيق، والـcommit، ورابط النسخة المنشورة، ونتيجة Browser E2E.
9. لا تنشئ أو تعدّل بيانات Production لمجرد اختبار التحقق الأمامي؛ لا حاجة إلى fixture مخزني لهذا الإصلاح.

## ما تم وما لم يتم

- **تم:** قراءة المصدر الحالي والتاريخي، فحص أحدث commit وparent diff، فحص Edge Function الحية، فحص تعريف RPC المركزي وصلاحياته، وتحديد سبب القبول الصامت.
- **لم يتم:** تعديل ملف التطبيق (ملكية المالك)، نشر واجهة، Browser E2E، أو إثبات تطابق HTML المقدّم من الاستضافة مع Git.
- **Production/Supabase:** لا تغيير؛ الحارس الخادمي المطلوب موجود في RPC التي تستدعيها Edge الحالية.
- **البيانات التجريبية:** لم تُنشأ ولم تُحذف أي بيانات؛ لا حاجة إلى تغيير بيانات أعمال لعلاج سلوك تحقق في الواجهة.

## SELF-AUDIT FINAL

- **What I Proved:** سبب قبول الرقم الزائد بصمت هو `Math.min(..., it.qty_ordered)`؛ الحارس الخادمي الحالي يرفض تجاوز مجموع المطلوب؛ الإصلاح جراحي في `preConfirm` فقط.
- **What I Did Not Prove:** لم أختبر النسخة المنشورة في متصفح ولم أرسل HTTP E2E إلى Production.
- **What I Fixed:** لم أعدّل التطبيق أو Production؛ وثّقت الاستبدال الدقيق للمالك، وتجنبت تغييرًا غير لازم في قاعدة البيانات.
- **What I Initially Missed:** تقارير الحالة السابقة كانت تركز على syntax والصورة؛ بعد إصلاح syntax، ظل منطق الكمية نفسه يقبل الزيادة عن طريق قصّها بصمت.
- **What Could Still Be Wrong:** قد يختلف HTML المنشور عن Git؛ يجب إعادة جلب المصدر بعد تطبيق المالك واختبار النسخة المقدمة. لا يُعد هذا التقرير إثباتًا للنشر.
- **Final Confidence:** مرتفع في السبب والحل المقترح؛ غير كافٍ لإغلاق Runtime.
- **Final Closure Status:** `OWNER SURGICAL PATCH READY / PRODUCTION CORE GUARD VERIFIED / DEPLOYMENT + BROWSER E2E OPEN`.
