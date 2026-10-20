# Report457 — توحيد تنبيه زيادة الكمية مع تجربة تنبيه النقص في Picker

**التاريخ:** 2026-10-20  
**النطاق الوحيد:** `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/picker.html`  
**ملكية التطبيق:** المالك يطبق تعديل HTML/PWA؛ لم أعدّل `picker.html` أو `main.html` ولم أنشر التطبيق.  
**Production:** تمت إعادة قراءة Edge Function وRPC الحية للقراءة فقط؛ لم أغيّر قاعدة البيانات أو Edge أو ACL أو بيانات الأعمال.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** المطلوب أن يرى المحضّر نافذة تنبيه واضحة ومتسقة عند إدخال كمية أعلى من المطلوب، على غرار نافذة النقص، دون أن تُحفظ كمية مخالفة.
- **Architecture Understanding:** `App.editPickedItem(index)` يدير إدخال الكمية ومسودة الجلسة محليًا. إتمام التحضير يمر عبر `complete-picking` ثم `complete_runsheet_picking`. لا يجوز تحويل تنبيه واجهة المستخدم إلى تجاوز لعقد الخادم.
- **Database Understanding:** Production RPC ذات خمسة معاملات تتحقق من أن `picked_qty <= total_qty` قبل الحجز وتوزيع الكمية على تفاصيل الطلبات.
- **Historical Understanding:** تمت مراجعة النسخة التاريخية `rawaie-erp-review/PWA/warehouse/picker.html`، SHA `7626ba320021a607854bf219f4bacd81fc3d1d92`، مع التمييز بينها وبين المصدر الحالي. كما تمت مراجعة تقرير Report456 وسجل الحالة، ثم مطابقة ادعاءاتهما مع المصدر وProduction الحاليين.
- **Production Understanding:** `complete-picking` نشطة، الإصدار **v18**، `verify_jwt=true`، `ezbr_sha256=14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`. وهي تستدعي `complete_runsheet_picking(..., p_operation_id)`.
- **Current Understanding:** الملف الحالي SHA `55d84b1a95a425597520b007af999315be7bcae6`، 1,030 سطرًا. آخر تعديل ذي صلة: commit `67748842e6030c81ab8a2046b197f256d53a9c75`، الذي أزال القص الصامت للكمية وأضاف التحقق العددي الصريح. يجب الحفاظ على هذا الإصلاح.
- **Execution Confidence:** مرتفع في السبب وعقد Production. التطبيق والنشر واختبار المتصفح الفعلي لم تُنفذها هذه الجلسة لأن ملف التطبيق التشغيلي من اختصاص المالك.

## السبب الجذري المثبت

في `App.editPickedItem(index)`:

- السطور **687–715**: `preConfirm` يرفض الزيادة باستخدام `Swal.showValidationMessage`، فيبقي المستخدم داخل نافذة إدخال الكمية.
- السطور **729–735**: النقص المقبول بعد الحفظ يفتح نافذة SweetAlert2 مستقلة بتصميم `question` وأزرار مخصصة، ثم يعيد فتح محرر الصنف إذا طلب المستخدم إضافة سبب.

إذًا الخلل الحالي ليس قبول الزيادة أو نقص حماية الخادم؛ بل اختلاف تجربة التنبيه بين الحالتين.

## قرار العقد — لا نسمح بحفظ الزيادة

Production RPC تحتوي الحارس:

```sql
if rec.picked_qty > total_qty then
  raise exception 'picked quantity exceeds ordered quantity for %', rec.item_code;
end if;
```

وعليه، الإصلاح أدناه **لا يحفظ الكمية الزائدة ولا يغير العقد الخادمي**. يسمح فقط بوصول القيمة الصحيحة عدديًا إلى نتيجة تأكيد الواجهة، ثم يعرض نافذة تنبيه مستقلة قبل أي تعديل للجلسة أو IndexedDB. إذا اختار المستخدم التصحيح، يعاد فتح المحرر بالقيمة المحفوظة السابقة.

## التعديل الجراحي A — استبدال كتلة preConfirm فقط

- **الملف:** `erp-frontend/companies/company-1/warehouse/picker.html`
- **SHA المستهدف:** `55d84b1a95a425597520b007af999315be7bcae6`
- **الدالة:** `App.editPickedItem(index)`
- **الموضع:** السطور **687–715**.
- **محدد البحث:** `preConfirm: function(){` داخل `Swal.fire` التي تعرض `#swal-qty` و`#swal-notes`.
- **الإجراء:** استبدل كتلة `preConfirm` الحالية كاملة بالنص التالي، مع إبقاء خيارات `Swal.fire` وبقية الدالة كما هي.

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

                return {
                    qty: qty,
                    notes: notesElement ? notesElement.value.trim() : ''
                };
            }
```

**سبب هذا الجزء:** يحافظ على رفض القيم الفارغة وغير الصحيحة والكسور والسالب. لا يحفظ أي شيء؛ فقط يمرر العدد الصحيح إلى مرحلة القرار التالية حتى يمكن عرض نافذة التنبيه المستقلة المطلوبة.

## التعديل الجراحي B — إضافة حارس التنبيه قبل أي تعديل للجلسة

- **الدالة:** `App.editPickedItem(index)`
- **الموضع:** مباشرة بعد السطر `if(r.isConfirmed){` في بداية `.then(function(r){`، حاليًا قرب السطر **717**.
- **محدد البحث الحرفي:**

```javascript
        }).then(function(r){
            if(r.isConfirmed){
                if (self.session.items[index].qty_picked !== r.value.qty ||
```

- **الإجراء:** أبقِ السطرين الأولين، وأدرج المقطع التالي بعد `if(r.isConfirmed){` مباشرةً وقبل مقارنة `qty_picked`. لا تحذف بقية منطق الحفظ.

```javascript
                var maxQty = Number(it.qty_ordered);
                if (r.value.qty > maxQty) {
                    Swal.fire({
                        title: 'تنبيه',
                        text: 'الكمية المحضّرة أكبر من الكمية المطلوبة. لا يمكن حفظ كمية تتجاوز المطلوب. هل تريد تصحيح الكمية؟',
                        icon: 'question',
                        showCancelButton: true,
                        confirmButtonText: 'تصحيح الكمية',
                        cancelButtonText: 'إلغاء',
                        customClass: {
                            popup: '!rounded-3xl',
                            confirmButton: '!rounded-xl !bg-amber-500 !px-6',
                            cancelButton: '!rounded-xl'
                        }
                    }).then(function(r2) {
                        if (r2.isConfirmed) {
                            self.editPickedItem(index);
                        }
                    });
                    return;
                }
```

**أثر الحارس:** يقع قبل تغيير `self.session.items` وقبل إبطال `operation_id` وقبل `db.session.put`. لذلك لا تتغير المسودة ولا يُنشأ أثر حفظ للكمية الزائدة. زر التصحيح يعيد فتح المحرر؛ زر الإلغاء يترك القيمة السابقة كما هي.

## مقارنة المسؤوليات — قبل وبعد

| السلوك | قبل | بعد التعديل المقترح |
|---|---|---|
| قيمة فارغة / كسر / قيمة غير رقمية | رفض داخل النافذة | يظل الرفض داخل النافذة |
| قيمة سالبة | رفض داخل النافذة | يظل الرفض داخل النافذة |
| كمية تساوي المطلوب | حفظ المسودة | دون تغيير |
| كمية أقل من المطلوب | حفظ المسودة ثم تنبيه النقص الحالي | دون تغيير |
| كمية أعلى من المطلوب | رسالة تحقق داخل محرر الكمية | نافذة تنبيه مستقلة بأسلوب SweetAlert2 مماثل لتنبيه النقص، دون حفظ، مع خيار إعادة التصحيح |
| حارس Production | يرفض الزيادة | دون تغيير |

## الاختبارات المطلوبة بعد تطبيق المالك

1. المطلوب 5، أدخل 6 واضغط حفظ: تظهر نافذة تنبيه مستقلة بنفس نمط نافذة النقص؛ لا تُحفظ 6 ولا تتغير المسودة.
2. اضغط **تصحيح الكمية**: يعود محرر الصنف بالقيمة المحفوظة السابقة، ويمكن إدخال 5 ثم حفظها.
3. أعد الاختبار واضغط **إلغاء**: يغلق التنبيه وتبقى الكمية المحفوظة السابقة دون تغيير.
4. المطلوب 5، أدخل 5: تحفظ القيمة كالمعتاد.
5. المطلوب 5، أدخل 3: يستمر تنبيه النقص الحالي دون تغيير.
6. اختبر فارغًا، وكسورًا، وسالبًا: تظل مرفوضة.
7. اختبر بعد إعادة فتح الصنف وبعد إعادة تحميل التطبيق: لا تبقى أي قيمة زائدة في المسودة.
8. تحقق من أن `operation_id` لا يُمسح بسبب محاولة زيادة مرفوضة.
9. نفّذ اختبار المتصفح على النسخة المنشورة، ثم أعد جلب SHA للمصدر والخدمة المنشورة. لا تُنشئ طلبات أو حركات مخزون تجريبية دائمة في Production.

## ما لم يُنفذ

- لم يُعدّل ملف `picker.html` أو `main.html`.
- لم تُنشر نسخة Frontend جديدة ولم يُنفذ Browser E2E؛ هذه الخطوات بيد المالك.
- لم يُعدّل Production أو RPC أو ACL أو البيانات؛ لا يوجد ما يبرر ذلك لهذا العيب.
- لم يُثبت تطابق HTML الذي يقدمه Cloudflare مع Git في هذه الدورة.

## SELF-AUDIT FINAL

- **What I Proved:** اختلاف آلية عرض التنبيه بين الزيادة والنقص؛ هوية المصدر الحالي؛ وجود حارس خادمي حي يمنع كمية التحضير الأعلى من مجموع المطلوب؛ بقاء Edge الحالية على v18.
- **What I Did Not Prove:** أن التعديل المقترح طُبق أو نُشر، أو أن نافذة التنبيه الجديدة اختُبرت في متصفح فعلي.
- **What I Fixed:** جهزت تغييرًا جراحيًا من جزأين في `App.editPickedItem(index)` لتوحيد تجربة التنبيه دون حفظ الزيادة.
- **What I Initially Missed:** تقرير Report456 ركز على منع القبول الصامت والرفض داخل النافذة، لكنه لم يغلق طلب المالك الأحدث المتعلق بتطابق شكل وطريقة ظهور تنبيه الزيادة مع تنبيه النقص.
- **What Could Still Be Wrong:** يجب اختبار SweetAlert2 على النسخة المنشورة، خصوصًا عودة المحرر وحالة المسودة و`operation_id`.
- **Final Confidence:** مرتفع في التشخيص والتوافق مع عقد Production؛ غير مثبت في النشر والتشغيل.
- **Final Closure Status:** `ROOT CAUSE VERIFIED / OWNER SURGICAL PATCH READY / PRODUCTION UNCHANGED / BROWSER E2E + SERVED ARTIFACT PARITY OPEN`.
