# Report428 — إعادة تحليل Console بعد تتبع النقرة والمزامنة الدورية
**التاريخ:** 2026-10-16  
**النطاق الوحيد:** جدول أوردرات المبيعات في النظام الأم `erp-frontend/companies/company-1/main.html`، الوحدة `RW_Orders`.  
**قيد الملكية:** لم يتم تعديل `main.html` أو أي تطبيق تشغيلي. لم تُجرَ أي كتابة على بيانات Production أو تغيير Schema/ACL/RPC.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** النقر على صف أوردر يجب أن يفتح تفاصيل الأوردر، من دون أن تؤثر عملية تحديث القائمة الدورية في تفاعل المستخدم.
- **Architecture Understanding:** مسار الواجهة هو click → `RW_Orders._showDetails(order_code)` → قراءة رأس الأوردر ضمن الشركة → قراءة `order_details` باستخدام `order.id` → إظهار المودال. التحديث الدوري يقرأ قائمة `orders` كل 30 ثانية وفق المصدر الحالي.
- **Database Understanding:** قاعدة Production تحتوي جداول `orders` و`order_details` و`runsheets`، وسياسات RLS المرئية تربط قراءة الأوردرات بالشركة الحالية والصلاحيات. لم يثبت أي خلل في ACL أو Schema.
- **Historical Understanding:** تمت مراجعة `CURRENT_STATE.md` وReport427؛ أُعيد تقييم استنتاجاتهما في ضوء Console trace الجديد بدل اعتماد تقرير سابق كحقيقة نهائية.
- **Production Understanding:** استعلامات Production السابقة كانت سليمة في النافذة المرصودة. السجل الجديد من المتصفح يُظهر أن طلب `orders` المرتبط بـ`ORD-1002` أعاد HTTP 200، كما أعادت طلبات القائمة الدورية الظاهرة HTTP 200.
- **Current Understanding:** مصدر Git الحالي هو `erp-frontend/companies/company-1/main.html`، blob SHA `a192704e07d984fdbecd00ce40a73e95fa806a7e`. لم يتغير هذا الملف في أحدث commits الخاصة بتطبيق POS؛ لا يوجد دليل على أن نسخة Pages المخدومة تطابق هذا الـblob.
- **Execution Confidence:** مرتفع في استبعاد عطل مستمر عام في قراءة `orders` من الأدلة الحالية؛ متوسط في ربط التحديث الدوري بتغيرات DOM؛ غير كافٍ لتسمية سبب نهائي لفشل ظهور التفاصيل لأن المراقب المرسل لا يسجل طلب `order_details` أو ظهور المودال.

## أدلة Console الجديدة كما وردت

1. عند الضغط على خلية داخل صف الأوردر، سجّل المراقب `rowFound: true`.
2. عند `click + microtask` كانت `rowStillConnected: true` و`rowStillSame: true`.
3. بعد 500ms بقي الصف متصلًا بالـDOM. لذلك **لم يثبت أن الصف الذي تم النقر عليه أُزيل أو استُبدل خلال أول 500ms**.
4. ظهر طلب `/rest/v1/orders` مرتبط بالرمز `ORD-1002` وأعاد HTTP 200.
5. ظهرت طلبات متكررة إلى `/rest/v1/orders` مع HTTP 200، وتزامنت بعضُها مع MutationObserver records.
6. خطأ `ERR_CONNECTION_CLOSED` السابق لم يتكرر في الطلبات الظاهرة هنا؛ لا يثبت هذا الخطأ منفردًا عطلًا في PostgreSQL أو RLS أو RPC.
7. المراقب المرسل يتعقب `/rest/v1/orders` فقط؛ لا يتعقب `/rest/v1/order_details`، ولا يثبت أن مودال التفاصيل ظهر أو فشل.

## النتيجة الجنائية

**ما ثبت:** لا يوجد في هذا الـtrace فشل HTTP لطلب `orders` المرتبط بالرمز `ORD-1002`، ولا دليل على فصل الصف من DOM خلال 500ms. توجد تحديثات دورية للقائمة وتغييرات DOM لاحقة.

**ما لم يثبت:** هل طلب `order_details` أُرسل أصلًا؛ وهل أعاد 200/خطأ؛ وهل أُنشئ مودال التفاصيل؛ وهل نسخة Cloudflare Pages التي اختبرها المستخدم تطابق SHA المصدر الحالي.

وعليه، لا يصح إعلان أن السبب الجذري هو التحديث الدوري وحده. التحديث الدوري مرشح للتحقيق بسبب تزامن طلبات القائمة مع تغييرات DOM، لكنه ليس سببًا مثبتًا لفشل النقرة. كما لا يوجد مبرر لتغيير Production DB/RLS/RPC أو إنشاء بيانات أوردر تجريبية.

## قرار التعديل الجراحي

**لا يوجد استبدال كود مثبت الاستحقاق في هذه الدورة. لا تعدّل `main.html` الآن.** إعطاء بديل كود قبل إثبات موضع الفشل سيكون تخمينًا، وقد يكرر إصلاحًا سابقًا أو يمس سلوكًا صحيحًا.

### اختبار الفصل الحاسم التالي — من دون تعديل ملفات

في DevTools:
1. Network → فعّل **Preserve log**.
2. امسح السجل ثم اضغط مرة واحدة على `ORD-1002`.
3. سجّل الطلبين إن ظهرا:
   - `/rest/v1/orders?...order_code=eq.ORD-1002`
   - `/rest/v1/order_details?...order_id=eq.<id>`
4. سجّل HTTP status وResponse body لكليهما، وابحث في Console عن `Order details error` وأي خطأ JavaScript.
5. افحص هل ظهر عنصر المودال بعد الاستجابة. لا يكفي HTTP 200 وحده لإثبات أن الواجهة عرضت التفاصيل.
6. إذا لم يظهر طلب `order_details`: افحص event handler والـartifact المخدوم مقابل Git SHA.
7. إذا أعاد الطلبان 200 ولم يظهر المودال: افحص خطأ JavaScript/طبقة المودال في الـartifact المخدوم.
8. إذا فشل طلب `order_details`: أصلح السبب المثبت من status/body فقط.
9. لا تغيّر فترة التحديث ولا توقف الـpolling إلا إذا أثبت تتبع إضافي أن هناك مؤقتات مكررة أو أن التحديث يقطع فعلًا عملية فتح التفاصيل.

## Production / Data / Security

- لم تُنفذ أي تغييرات Production؛ لا يوجد خلل DB/ACL مثبت.
- لم تُنشأ أو تُحذف بيانات أعمال؛ لا توجد حاجة مثبتة إلى Fixture.
- لم تُضف Edge Function أو RPC جديدة.
- لا توجد مطالبة بأن Browser E2E نجح؛ التتبع الحالي ليس اختبارًا كاملًا لظهور المودال.

## SELF-AUDIT FINAL

- **What I Proved:** الطلب المرتبط بـ`ORD-1002` وطلبات القائمة الدورية الظاهرة أعادت HTTP 200؛ الصف بقي متصلًا بعد النقرة مباشرة وبعد 500ms؛ توجد تغييرات DOM لاحقة؛ مصدر Git الحالي معروف.
- **What I Did Not Prove:** طلب `order_details` الناتج عن النقرة، نتيجة عرضه، هوية artifact Pages المخدوم، أو السبب النهائي لفشل الواجهة.
- **What I Fixed:** لا يوجد تعديل كود مبرر بالأدلة الحالية؛ حدّدت اختبار الفصل الذي يثبت طبقة الخلل من دون المساس بإنجازات سابقة.
- **What I Initially Missed:** المراقب الأول لم يكن يسجل `order_details` ولا حالة المودال؛ لذلك لا يمكن اعتباره تتبعًا كاملًا لمسار التفاصيل.
- **What Could Still Be Wrong:** قد تكون هناك مشكلة متقطعة في artifact المخدوم أو JavaScript/المودال، أو خطأ في طلب التفاصيل لا يلتقطه المراقب الحالي.
- **Final Confidence:** مرتفع في سلامة استجابة `orders` ضمن هذا الـtrace؛ متوسط في توصيف أثر polling؛ منخفض في تسمية السبب النهائي قبل تتبع `order_details` والمودال.
- **Final Closure Status:** `ORDERS HTTP OBSERVED 200 / ROW NOT DETACHED IN FIRST 500MS / DETAILS REQUEST + MODAL RESULT UNVERIFIED / NO UNSUPPORTED PATCH / OPEN`.
- **Next exact resumption point:** كرر نقرة واحدة مع Network Preserve log وسجّل طلب `order_details` وظهور المودال، ثم أصدر تعديلًا جراحيًا واحدًا على العنصر الذي يثبت فشله. لا تغيّر Production أو `main.html` بالتخمين.
