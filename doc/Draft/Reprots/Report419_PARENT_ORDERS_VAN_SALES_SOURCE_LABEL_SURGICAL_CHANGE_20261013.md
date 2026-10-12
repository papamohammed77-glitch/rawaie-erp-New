# Report419 — التعديل الجراحي لتسمية مصدر «بيع مباشر» في جدول أوردرات المبيعات

- التاريخ: 2026-10-13
- النطاق الوحيد: جدول أوردرات المبيعات في وحدة `RW_Orders` داخل الملف الأم.
- سياسة الملكية: لم يتم تعديل `main.html` أو أي تطبيق تشغيلي؛ المالك هو من يطبق تعديل الواجهة.
- المستودع المستهدف للمصدر: `papamohammed77-glitch/erp-frontend`.
- SHA المصدر الحالي الذي أعادته GitHub API: `92bec4b0b006c7a280ba48e0ab4279e44282687a`.
- مصدر سجل الاستمرارية: `CURRENT_STATE.md`، وآخر تقرير متخصص: `Report418_PARENT_ORDERS_FRESH_RESYNC_AND_DIRECT_SALES_LABEL_20261013.md`.

## SELF-AUDIT قبل التعديل

- Business Understanding: المطلوب تصحيح تسمية مصدر البيع المباشر فقط، مع إبقاء المصدر غير مؤهل للضم إلى الرانشيت.
- Architecture Understanding: الواجهة تعرض التسمية وتقيّد الاختيار؛ قواعد الأهلية النهائية تُفرض أيضًا في RPC المركزي.
- Database Understanding: استعلام Production الحي أعاد 6 أوردرات: 3 مصدرها `pos` و3 مصدرها `order-taker`.
- Historical Understanding: تقرير Report418 يحدد أن التعديلات الأوسع في Report417 موجودة بالفعل في المصدر الحالي، فلا تُعاد.
- Production Understanding: المشروع `SMART ERP / fiilmooggumokxanwiyx`; آخر استعلام حي في هذه الدورة عند `2026-10-12 21:27:14.559315+00 UTC`.
- Current Understanding: GitHub أعاد SHA الحالي نفسه `92bec4b0b006c7a280ba48e0ab4279e44282687a`. أداة جلب محتوى الملف الضخم أعادت SHA دون جسم الملف في هذه الدورة؛ لذلك لا أدّعي إعادة قراءة محتوى الملف الكامل هنا. موضع التغيير والنص البديل مؤسسان على Report418 الذي يشير إلى SHA نفسه، ويجب على المالك مطابقة محدد البحث أدناه مع الملف المفتوح قبل الاستبدال.
- Execution Confidence: مرتفع في عقد Production وأهلية المصدر؛ متوسط في إعادة التحقق المستقلة من جسم الملف بسبب عدم إرجاع أداة GitHub محتوى الملف الضخم.

## Production — التحقق الحالي

وقت الفحص: `2026-10-12 21:27:14.559315+00 UTC`.

- `orders`: `pos=3`, `order-taker=3`; لا توجد سجلات في هذه اللقطة لمصادر `telesales` أو `online_store` أو `van_sales`.
- `create_runsheet_atomic(p_company_id uuid, p_selected_orders text[], p_user_email text)`: `anon EXECUTE=false`, `authenticated EXECUTE=false`, `service_role EXECUTE=true`.
- `append_orders_to_runsheet_atomic(p_company_id uuid, p_runsheet_code text, p_selected_orders text[], p_user_email text)`: `anon EXECUTE=false`, `authenticated EXECUTE=false`, `service_role EXECUTE=true`.
- تعريفات RPC التي تم جلبها من Production تتحقق من المصدر بعد التطبيع، وتسمح فقط بـ`telesales`, `tele-sales`, `order-taker`, `online-store`. لذلك `pos` و`van-sales` مرفوضان مركزيًا.
- `submit_online_order_atomic` يسجل مصدر المتجر على هيئة `online_store`، وتطبيع الواجهة إلى `online-store` متوافق مع عقد RPC.
- لم يجر أي تعديل على Production أو البيانات؛ لا يوجد عيب Production مثبت يتطلب تعديلًا لهذه المهمة الخاصة بالتسمية.

## التعديل الجراحي الوحيد المطلوب من المالك

- **الملف:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
- **SHA:** `92bec4b0b006c7a280ba48e0ab4279e44282687a`
- **الوحدة:** `RW_Orders`
- **الدالة:** `_renderTable(data)`
- **موضع تقرير Report418:** الأسطر 10503–10509 في SHA المذكور.
- **محدد البحث الدقيق:** داخل `function _renderTable(data)` ابحث عن `var sourceLabel = {` ثم تأكد أن الكائن نفسه يحتوي `'online-store': 'المتجر الإلكتروني'`.
- **الإجراء:** احذف كائن `sourceLabel` الحالي كاملًا حتى نهاية تعبير الفهرسة والـfallback، واستبدله بالكامل بالنص التالي.

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

### التأثير المتوقع

- `van_sales` بعد التطبيع إلى `van-sales` يظهر للمستخدم باسم «بيع مباشر».
- يظل اختيار أوردرات `van-sales` و`pos` ممنوعًا لإضافتها إلى الرانشيت.
- لا يتغير عقد قاعدة البيانات أو دورة المخزون أو RPC ACL.
- لا يُعاد تطبيق أي إصلاح أوسع موجود بالفعل في المصدر.

### الاختبار بعد تطبيق المالك

| المصدر | التسمية | أهلية الضم |
|---|---|---|
| `pos` | كاشير / POS | مرفوض |
| `telesales` | تلي سيلز | مسموح فقط مع الحالة والارتباط الصحيحين |
| `order-taker` | أوردر تيكر | مسموح فقط مع الحالة والارتباط الصحيحين |
| `online_store` | المتجر الإلكتروني | مسموح فقط مع الحالة والارتباط الصحيحين |
| `van_sales` | بيع مباشر | مرفوض |
| فارغ أو مجهول | القيمة الخام أو «غير معروف» | مرفوض |

اختبر في الواجهة المخدومة بعد الدمج: ظهور التسمية، تعطيل checkbox للمصدرين `pos` و`van-sales`، وإمكانية اختيار المصادر المؤهلة فقط. لا توجد في هذه الدورة أدلة Browser E2E أو نشر واجهة بعد تطبيق التغيير.

## SELF-AUDIT FINAL

- What I Proved: SHA الحالي؛ بيانات Production الحية ومصادر الأوردرات؛ ACL وتعريفات RPC؛ أن العقد المركزي يرفض مصادر البيع المباشر.
- What I Did Not Prove: لم أستطع استخراج جسم الملف الأم الكامل من أداة GitHub في هذه الدورة، ولم يثبت نشر الواجهة أو Browser E2E.
- What I Fixed: لا تعديل مباشر على الملف الأم أو Production؛ تم إعداد تغيير جراحي واحد محدد وتوثيقه.
- What I Initially Missed: يجب عدم اعتبار تقرير سابق بديلًا عن التحقق من جسم الملف الحالي؛ تم توثيق محدودية جلب الجسم صراحة.
- What Could Still Be Wrong: يجب مطابقة الكائن المستهدف في الملف المفتوح قبل الاستبدال، ثم اختبار الواجهة المنشورة.
- Final Confidence: مرتفع في Production contract، ومتوسط في تحقق النص الحالي بسبب محدودية جلب الملف.
- Final Closure Status: `PRODUCTION CONTRACT VERIFIED / OWNER SURGICAL PATCH READY / SOURCE BODY RECHECK + DEPLOYMENT + BROWSER E2E OPEN`.
- Next exact step: يطبق المالك الاستبدال المحدد أعلاه على SHA الحالي، ثم ينشر الواجهة ويختبر التسمية وأهلية الضم. لا تغييرات Supabase لازمة لهذه النقطة.
