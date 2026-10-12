# Report418 — إعادة مزامنة حيّة وتصحيح تسمية مصدر البيع المباشر
**التاريخ:** 2026-10-13  
**النطاق الوحيد:** جدول أوردرات المبيعات داخل `RW_Orders` في الملف الأم `erp-frontend/companies/company-1/main.html`.  
**سياسة الملكية:** لم أعدّل `main.html` أو أي تطبيق تشغيلي. لا يوجد تغيير Production/Supabase مبرر في هذه الدورة.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** جدول النظام الأم يعرض مصدر كل أوردر ويمنع مصادر البيع المباشر من اختيارها للرانشيت. المصادر المؤهلة: المتجر الإلكتروني، التلي سيلز، الأوردر تيكر؛ وغير المؤهلة: POS/الكاشير والبيع المباشر بالمندوب.
- **Architecture Understanding:** الواجهة تحسّن تجربة الاستخدام فقط؛ التحقق النهائي من أهلية المصدر موجود في RPCs المركزية التي تستدعيها Edge Functions.
- **Database Understanding:** Production الحالي يحتوي 6 أوردرات: 3 `pos` و3 `order-taker`. لم توجد حاليًا أوردرات `telesales` أو المتجر الإلكتروني أو `van-sales` في العينة الحية.
- **Historical Understanding:** تمت مراجعة CURRENT_STATE وتقارير Report413 وReport415 وReport417 كأدلة استرشادية، ثم مطابقة المواضع مع مصدر الملف الأم الحالي. تمت مراجعة مصدر المتجر التاريخي `store/index.html` عند commit `b2cd78da3af2ed7ff5f61b5fdea5c3d8a523f907`؛ وهو يستدعي `submit-online-order`.
- **Production Understanding:** فُحصت قاعدة SMART ERP / `fiilmooggumokxanwiyx` مباشرة في `2026-10-12 21:05:52.666893+00 UTC`. Edge `create-runsheet` منشورة v26 مع `verify_jwt=true`، و`append-to-runsheet` منشورة v8 مع `verify_jwt=true`.
- **Current Understanding:** المصدر الحالي للملف الأم `erp-frontend/companies/company-1/main.html` blob SHA `92bec4b0b006c7a280ba48e0ab4279e44282687a`، حجمه 1,762,278 حرفًا و32,436 سطرًا. هذا يختلف عن SHA الوارد في Report417؛ لذلك لا تُستخدم أرقام Report417 القديمة.
- **Execution Confidence:** مرتفع في مطابقة مصدر Git الحالي وتعريفات RPC وبيانات المصدر الحالية؛ لم يُثبت نشر هذا الـblob إلى الواجهة المخدومة أو Browser E2E في هذه الدورة.

## ما تم التحقق منه

1. تعديلات Report417 الخاصة بعرض وقت الإنشاء والمصدر والمنشئ، وعمود الجدول 11، وتعطيل اختيار المصادر غير المؤهلة، وعدّ التفاصيل المتبقية، وتحديث المشتقات بعد التأكيد وRealtime، وعرض المرتجع في التفاصيل والطباعة **موجودة بالفعل في المصدر الحالي**. لا تعِد تطبيقها.
2. في `_renderTable(data)`، السطور الحالية 10491–10509، يتم تطبيع المصدر باستبدال المسافات والشرطة السفلية بشرطة؛ لذلك `online_store` يصبح `online-store`، و`van_sales` يصبح `van-sales`.
3. خريطة العرض الحالية تتضمن `pos`, `telesales`, `tele-sales`, `order-taker`, `online-store`، لكنها لا تتضمن `van-sales`. نتيجة ذلك أن البيع المباشر يظهر بقيمة خام مثل `van-sales` بدل التسمية المطلوبة «بيع مباشر».
4. Production RPCs `create_runsheet_atomic(uuid,text[],text)` و`append_orders_to_runsheet_atomic(uuid,text,text[],text)` تسمح فقط بـ`telesales`, `tele-sales`, `order-taker`, `online-store` بعد التطبيع. ACL التي قرأتها: `anon=false`, `authenticated=false`, `service_role=true`. هذا صحيح ويجب الحفاظ عليه؛ `pos` و`van-sales` لا ينبغي أن يصبحا مؤهلين.
5. Production `submit_online_order_atomic` يسجل مصدر المتجر `online_store`؛ وتطبيع المصدر الحالي يحوله إلى `online-store`. لا حاجة لإضافة alias جديد أو تغيير RPC بناءً على افتراض.
6. لم أغيّر بيانات Production، ولم أنشئ أوردرات اختبار حقيقية في قاعدة Production؛ لا توجد بيئة Staging مستقلة مثبتة في الأدلة الحالية، وإنشاء أوردرات صناعية هنا قد يلوث دورة الطلب/المخزون/المحاسبة. لم تُحذف بيانات أعمال صحيحة.

## التعديل الجراحي الوحيد المطلوب من المالك

- **الملف:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
- **SHA الحالي:** `92bec4b0b006c7a280ba48e0ab4279e44282687a`
- **الوحدة:** `RW_Orders`
- **الدالة:** `_renderTable(data)`
- **الموضع الحالي:** السطور 10503–10509.
- **محدد البحث:** ابحث داخل `function _renderTable(data)` عن السطر:
  `var sourceLabel = {`
  ثم طابق الكائن الذي يحتوي `'online-store': 'المتجر الإلكتروني'`.
- **احذف الكائن كاملًا فقط** من `var sourceLabel = {` حتى نهاية تعبير `}[source] || (String(o.source || '').trim() || 'غير معروف');` واستبدله بالنص الكامل التالي:

```javascript
var sourceLabel = {
    'pos': 'كاشير / POS',
    'telesales': 'تلي سيلز',
    'tele-sales': 'تلي سيلز',
    'order-taker': 'أوردر تيكر',
    'online-store': 'المتجر الإلكتروني',
    'van-sales': 'بيع مباشر'
}[source] || (String(o.source || '').trim() || 'غير معروف');
```

**الأثر:** يظهر `van_sales` / `van-sales` باسم «بيع مباشر»، بينما يبقى checkbox معطلًا له، ويظل الحارس المركزي في Production رافضًا ضمه للرانشيت. لا يتغير عقد البيانات ولا دورة المخزون ولا صلاحيات RPC.

## اختبارات التحقق

| Fixture منطقي (بدون كتابة Production) | التسمية المتوقعة | أهلية الرانشيت |
|---|---|---|
| `pos` | كاشير / POS | مرفوض |
| `telesales` | تلي سيلز | مسموح فقط إذا كانت الحالة Confirmed/Pending وغير مرتبط برانشيت |
| `order-taker` | أوردر تيكر | مسموح فقط إذا كانت الحالة Confirmed/Pending وغير مرتبط برانشيت |
| `online_store` | المتجر الإلكتروني | مسموح فقط إذا كانت الحالة Confirmed/Pending وغير مرتبط برانشيت |
| `van_sales` | بيع مباشر | مرفوض |
| مصدر فارغ/مجهول | القيمة الخام أو «غير معروف» | مرفوض |

تم التحقق ساكنًا من قواعد التطبيع والحارس ومقارنة ذلك مع Production RPC. **لم يُنفذ Browser E2E** ولم يُثبت نشر الواجهة المخدومة بعد هذا التعديل؛ يجب على المالك تطبيق الكائن أعلاه ثم اختبار جدول الأوردرات في المتصفح. لا حاجة إلى تغيير Supabase أو Edge Functions لهذه النقطة.

## SELF-AUDIT FINAL

- **What I Proved:** SHA وحجم الملف الأم الحالي؛ وجود إصلاحات Report417 في المصدر الحالي؛ أن تسمية `van-sales` ناقصة؛ أن مصدر المتجر الحي يُكتب `online_store`؛ أن RPCs المركزية ترفض POS والمصادر غير المسموحة؛ حالة Edge versions وACL.
- **What I Did Not Prove:** نشر الملف الأم الحالي إلى الاستضافة، أو اختبار متصفح E2E، أو وجود سجلات حية من telesales/store/van-sales في Production.
- **What I Fixed:** لم أغيّر ملفًا يملكه المالك أو Production؛ جهزت تغييرًا جراحيًا واحدًا متبقيًا فقط.
- **What I Initially Missed:** SHA المصدر الحي تغيّر من Report417، ومعظم Patch القديم موجود بالفعل؛ إعادة تطبيقه ستكرر تعديلات سليمة. التسمية الوحيدة الناقصة في خريطة المصدر هي `van-sales`.
- **What Could Still Be Wrong:** لا يمكن اعتبار المهمة مغلقة حتى يطبق المالك التغيير، ويختبر الواجهة المخدومة ويثبت SHA المنشور.
- **Final Confidence:** 0.96 في تشخيص مصدر Git وProduction contract؛ غير مثبت في Browser E2E/الواجهة المنشورة.
- **Final Closure Status:** `CURRENT SOURCE VERIFIED / PRODUCTION CORE VERIFIED / ONE OWNER SURGICAL LABEL PATCH / DEPLOYMENT + BROWSER E2E OPEN`.
- **Next exact step:** طبّق استبدال كائن `sourceLabel` فقط عند SHA الحالي أعلاه، ثم انشر واختبر مصادر POS وorder-taker وبقية المصادر عند توفرها. لا تغيّر RPCs ولا تنشئ بيانات طلبات في Production.
