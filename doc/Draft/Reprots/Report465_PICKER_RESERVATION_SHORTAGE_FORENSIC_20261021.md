# Report465 — تحقيق خطأ إنهاء التحضير ورفض الحجز المخزني
التاريخ: 2026-10-21

## 1. النطاق والقاعدة
النطاق الوحيد: خطأ HTTP 400 عند إنهاء التحضير من `companies/company-1/warehouse/picker.html` عبر `complete-picking`.
لم يتم تعديل `main.html` أو ملف التطبيق التشغيلي. لا يجوز تجاوز `reserve_stock` أو تعديل الأرصدة يدويًا لإجبار العملية على النجاح.

## 2. مزامنة Production الحالية
- Supabase project: `fiilmooggumokxanwiyx`.
- Edge `complete-picking`: ACTIVE v18، `verify_jwt=true`، deployment hash `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`.
- Current Git source `erp-frontend/companies/company-1/warehouse/picker.html`: blob SHA `ffe18d4483ee074230e32b1c96f60507e5876a4b`.
- RPC المستخدم من Edge هو `complete_runsheet_picking(uuid,text,text,jsonb,uuid)` ويستدعي `reserve_stock` قبل إكمال التحضير. قاعدة الحجز لم تُرخَ.

## 3. السبب الجذري المثبت
- الرانشيت `RS-1` حالته `Picked`، وبند الصنف `1008` (مصاصة 2ج) لديه `qty_picked=1` ويحمل دورة تحميل قائمة.
- الرانشيت `RS-2` ما زال `Picking` ويطلب وحدة أخرى من الصنف نفسه.
- في الفرع الرئيسي: `qty=1`, `allocated_qty=1`, `available_qty=0`.
- لذلك رفض الحجز في `RS-2` صحيح؛ الوحدة الوحيدة محجوزة بالفعل لـ`RS-1`. هذه ليست مشكلة في المحرك المركزي ولا مبررًا لتجاوز الحجز.
- الأثر على UX: شاشة التحضير الحالية لا تعرض المتاح الفعلي قبل الإنهاء؛ لذلك يستطيع المستخدم إدخال كمية غير متاحة ثم لا يكتشف التعارض إلا عند الإرسال.

## 4. تغيير Production المنفذ
تم تطبيق migration باسم `picking_reservation_diagnostic_contract_20261021` لتطوير رسالة الرفض داخل `reserve_stock` فقط. عند عدم كفاية المتاح ستعرض الرسالة رمز الصنف والكمية المطلوبة والمتاحة:
`insufficient available stock for reservation: item_code=1008, requested=1, available=0`
لا يغير هذا التعديل أي رصيد أو تخصيص أو قاعدة قبول/رفض.

## 5. الاختبار والتحقق
- اختبار SQL سلبي معزول استدعى `reserve_stock` للصنف 1008 بكمية 1 عندما المتاح صفر؛ تحقق الاختبار من وجود رمز الصنف والكمية المطلوبة والمتاحة في الخطأ. نجح الاختبار ولم يغيّر الرصيد.
- تحقق مستقل بعد الاختبار: الفرع الرئيسي للصنف 1008 ما زال `qty=1, allocated_qty=1, available_qty=0`.
- لم يتم تنفيذ HTTP E2E ناجح لإنهاء `RS-2` لأن ذلك يتطلب تسجيل نقص حقيقي (الكمية المحضرة صفر مع سبب) أو إدخال مخزون فعلي صحيح عبر مسار حركة المخزون المركزي. لم تُنشأ بيانات تجريبية ولم تُعدّل بيانات الأعمال.

## 6. التعديل الجراحي المطلوب من المالك في picker.html
**الملف:** `erp-frontend/companies/company-1/warehouse/picker.html`
**الدالة:** `App.completePicking`
**الموضع:** آخر `.catch` داخل `completePicking` مباشرة بعد معالجة نجاح الإنهاء، وليس أي `.catch` آخر في الملف.

ابحث عن:
```js
}).catch(function(err){ Swal.close(); toast(err.message || 'فشل الاتصال', 'error'); });
```

واستبدل هذا السطر فقط بـ:
```js
}).catch(function(err){
    Swal.close();
    var message = err && err.message ? err.message : 'فشل الاتصال';
    if (message.indexOf('insufficient available stock for reservation:') !== -1) {
        var match = message.match(/item_code=([^,]+), requested=([^,]+), available=([^\s]+)/);
        var detail = match
            ? 'الصنف ' + match[1] + ' — المطلوب حجزه: ' + match[2] + ' — المتاح فعليًا: ' + match[3]
            : message;
        Swal.fire({
            title: 'المخزون المتاح لا يكفي',
            text: detail + '. سجّل الكمية المحضّرة الفعلية وسبب النقص، أو تأكد من وجود مخزون فعلي قبل إعادة المحاولة.',
            icon: 'warning',
            confirmButtonText: 'مراجعة الكميات',
            customClass: { popup: '!rounded-3xl', confirmButton: '!rounded-xl !bg-amber-500 !px-6' }
        });
        return;
    }
    toast(message, 'error');
});
```

**الأثر:** رسالة دائمة وواضحة بدل Toast قصير، مع إظهار الصنف والمطلوب والمتاح. هذا تحسين تشخيصي؛ منع تجاوز المتاح قبل الإرسال يتطلب إضافة عرض available quantity في واجهة التحضير، ولا يجوز ادعاء أن هذا الجزء تحقق دون تطبيق المالك واختباره.

## 7. الحالة
- Production reservation guard: VERIFIED.
- Production diagnostic message: DEPLOYED + SQL negative test PASS.
- Actual business conflict for RS-2/item 1008: VERIFIED, not cleared; must be resolved according to physical reality.
- Picker UI surgical patch: PROVIDED TO OWNER, NOT APPLIED.
- Browser E2E / served HTML parity: UNVERIFIED.
- Closure: `ROOT CAUSE VERIFIED / RESERVATION INTEGRITY PRESERVED / UI OWNER PATCH REQUIRED / NOT 100% CLOSED`.

## SELF-AUDIT FINAL
- **What I Proved:** الوحدة الوحيدة من الصنف 1008 محجوزة بالفعل للرانشيت RS-1؛ RS-2 لا يملك متاحًا منها. الحارس المركزي يمنع ازدواج الحجز.
- **What I Did Not Prove:** لم أختبر متصفحًا فعليًا، ولم أثبت تطابق HTML المنشور مع Git، ولم أنفذ إكمالًا ناجحًا لـRS-2.
- **What I Fixed:** حسّنت رسالة الخطأ في `reserve_stock` دون تغيير قواعد المخزون أو البيانات.
- **What I Initially Missed:** السبب ليس بالضرورة خللًا برمجيًا؛ البيانات الحالية تثبت تعارضًا حقيقيًا في التوفر بين رانشيتين.
- **What Could Still Be Wrong:** قد توجد فجوة UX أوسع في إظهار المتاح الفعلي قبل التحضير؛ تحتاج تعديل المالك واختبارًا حيًا.
- **Final Confidence:** مرتفع في سبب الرفض وحالة الرصيد؛ متوسط في تجربة المستخدم حتى تطبيق التعديل الجراحي.
- **Final Closure Status:** `NOT CLOSED — OWNER UI PATCH + BROWSER E2E REMAIN`.
