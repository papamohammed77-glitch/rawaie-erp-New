# Report708 — معالجة فشل الشبكة وجدول الاستلام في النظام الأم
**التاريخ:** 2026-11-12  
**نقطة العمل:** LVE-2026-11-12-708  
**النطاق:** Service Worker، دورة Realtime/refresh في Receiver، جدول الاستلام في Parent `main.html`، واختبارات الحماية.

## 1. الخلاصة التنفيذية

- **CONFIRMED:** طلب `branches` الظاهر في Console صادر من دورة المصالحة الدورية في `RW_Realtime` (كل 30 ثانية في Receiver) التي تستدعي `requestQueueRefresh`، ثم `loadPurchaseOrders` أو `loadReceivingHistory`، ويعيد `resolveBranchScope` قراءة جدول `branches`.
- **CONFIRMED:** Service Worker كان يمرر طلبات API بـ`event.respondWith(fetch(request))` دون catch. عند رفض الشبكة، يرفض FetchEvent نفسه ويظهر `Uncaught (in promise) TypeError: Failed to fetch` في `sw.js`.
- **FIXED IN SOURCE:** طلبات Supabase/API أصبحت تعيد HTTP 503 JSON صريحًا عند فشل الشبكة، مع `code=NETWORK_ERROR` و`Cache-Control: no-store`. هذا يمنع رفض FetchEvent غير المعالج ولا يزيّف نجاح الطلب؛ يبقى الفشل واضحًا للمستهلك كي لا تُعرض بيانات جديدة غير موجودة.
- **FIXED IN SOURCE:** جدول الاستلام في النظام الأم يعرض رقم الفاتورة/المستند بدل رقم العملية، وتاريخ العملية، والمسؤول، ووقت بداية الاستلام، ووقت نهاية الاستلام، وعدد الأصناف، والحالة، وزر التفاصيل. البحث الأول أصبح على رقم المستند.
- **CONFIRMED LIMITATION:** بيانات Production الحالية فيها `start_time=end_time` لكل الاستلامات الأربع؛ لأن RPC الحالي يكتب `now(),now()` في نفس معاملة الاستلام. الواجهة تعرض الحقلين الموجودين دون اختلاق مدة. تصحيح وقت البداية الحقيقي يتطلب تغيير عقد RPC/عملية الاستلام، ولم يُجر أي تعديل SQL أو DB ضمن هذا الإصلاح.
- **UNRESOLVED / SEPARATE:** تحذير Tailwind CDN تحذير بناء/نشر منفصل عن فشل الشبكة. لا يزال CDN موجودًا في Parent وReceiver وWarehouse. لم يُحذف لأن الصفحات تعتمد على Tailwind utility classes، وحذفه قبل توفير CSS إنتاجي بديل قد يكسر التخطيط. يحتاج مشروع CSS build مستقل واختبار تغطية قبل إزالته.
- **CI:** أضيفت اختبارات static contract إلى Workflow الحالي وربط تشغيله بتغييرات `main.html` و`sw.js`. لم تتوفر قراءة مؤكدة لنتيجة تشغيل Workflow بعد هذا التعديل في وقت تسجيل التقرير.

## 2. تشخيص دورة الطلب

تسلسل الاستدعاء المرصود:
1. `RW_Realtime.start` في Receiver يضبط `reconcileMs:30000`.
2. `core.js` يشغّل `reconcile(state,'periodic')` كل 30 ثانية ما دامت الصفحة ظاهرة.
3. `onReconcile` في Receiver يستدعي `requestQueueRefresh('reconcile',false)`.
4. عند تبويب الانتظار ينفذ `loadPurchaseOrders`، وعند السجل المكتمل ينفذ `loadReceivingHistory`.
5. كلا المسارين يستدعي `resolveBranchScope`، والذي يقرأ `branches` ثم `app_settings`.
6. إذا فشل اتصال المتصفح/الشبكة أثناء هذا الطلب، كان Service Worker يترك Promise مرفوضًا دون تحويله إلى Response صالح.

هذا لا يثبت أن Supabase رفض الصلاحية أو أن بيانات الفروع غير صحيحة؛ الرسالة المعروضة هي فشل نقل/شبكة (`net::ERR_FAILED` / `Failed to fetch`)، وليست PostgREST 4xx أو SQL error.

## 3. إصلاح Service Worker

الملف: `companies/company-1/sw.js`  
Blob SHA: `f6b9372559f323c8e2512ca94662b2c619ec0d4f`  
Build marker: `RAWAEA_SW_P157_API_NETWORK_FAILURE_RESPONSE_20261112`  
Commit: `e5a70642f1c33b61f430b6b87793c61eae89fcfb`

التغيير:
- فصل API requests عن مسار ملفات runtime وطلبات manifest/SW.
- إحاطة `fetch(request)` الخاص بطلبات API بمعالجة رفض الشبكة.
- عند فشل الشبكة يعيد SW استجابة 503 JSON برمز `NETWORK_ERROR` ورسالة عربية و`Cache-Control: no-store`.
- لا يوجد fallback إلى cache لبيانات Supabase، ولا تُعرض بيانات قديمة على أنها نتيجة جديدة.
- لا يتم ابتلاع الخطأ على أنه نجاح؛ HTTP 503 يظل ظاهرًا لطبقة Supabase/التطبيق.

## 4. تعديل جدول الاستلام في النظام الأم

الملف: `companies/company-1/main.html`  
Blob SHA النهائي: `525eb0eda6d498e186a8f887912a0b3c5dae4d67`  
Commits: `da9834c9cf2535995f117274a6c131ac192d1f5a` و`45824b79023cd97dd1303d365f462f15194136c2`.

| العمود الجديد | مصدره |
|---|---|
| رقم الفاتورة / المستند | `receiving.po_number`؛ يحمل `invoice_code` في Quick Market، ورقم أمر الشراء في مسار PO |
| التاريخ | `receiving.date` |
| المسؤول | `receiving.responsible` |
| وقت بداية الاستلام | `receiving.start_time` |
| وقت نهاية الاستلام | `receiving.end_time` |
| الأصناف | عدد `receiving_details` المرتبطة بـ`operation_id` |
| الحالة | `receiving.status` |
| عرض | يظل `operation_id` مفتاحًا داخليًا لفتح التفاصيل، لكنه لم يعد عمود العرض الأول |

- البحث الأول صار يبحث في `po_number` (رقم المستند) بدل `operation_id`.
- تم إبقاء `operation_id` داخليًا لربط تفاصيل الاستلام وفتح النافذة؛ لم يتم تغيير أي مفتاح أو علاقة قاعدة بيانات.
- تنسيق الوقت يعرض وقت الساعة من timestamp دون تحويل خاطئ لتوقيت المتصفح.

## 5. تدقيق حقول الوقت في Production

تمت قراءة `receiving` مع ربط `purchase_invoices` و`purchase_orders` في Production دون كتابة:
- PO-20260928: `start_time=end_time=2026-11-09 23:02:02.8059`.
- PINV-1002 (11 نوفمبر): `start_time=end_time=2026-11-11 21:28:40.500528`.
- PINV-1003: `start_time=end_time=2026-11-11 21:29:48.841254`.
- PINV-1002 (12 نوفمبر): `start_time=end_time=2026-11-12 15:09:07.232688`.

وفحص تعريف RPC أثبت:
- `receive_purchase_atomic` ينشئ سجل الاستلام باستخدام `now(),now()`.
- `receive_quick_market_purchase_atomic` كذلك ينشئ سجل الاستلام باستخدام `now(),now()`.

إذًا عمودا الوقت سيظهران في الجدول كما طلبت، لكن القيم الحالية لا تقيس مدة الاستلام. لا يمكن تصحيح ذلك بأمان من واجهة العرض وحدها؛ يلزم تمرير وقت بدء موثوق إلى عقد RPC أو إنشاء حدث بدء مستقل قبل الترحيل الذري، مع حماية idempotency وتحديد السلوك عند إغلاق الصفحة/انقطاع الشبكة. هذه خطوة backend مستقلة ولم يتم تغييرها.

## 6. تحذير Tailwind

الرسالة `cdn.tailwindcss.com should not be used in production` تحذير من طريقة تحميل CSS وليست سبب طلب `branches` الفاشل. تم التحقق من وجود مرجع CDN في Parent وReceiver وWarehouse. لم يُحذف؛ لأن utility classes مستخدمة في هذه الصفحات. الحل الصحيح هو بناء CSS إنتاجي عبر Tailwind CLI/PostCSS وتضمين الناتج، ثم اختبار كل تطبيق قبل إزالة CDN. حذف script فقط سيكون تغييرًا بصريًا عالي المخاطر.

## 7. اختبارات الحماية

تم تعديل `.github/workflows/warehouse_hub_browser_e2e_20261110.yml`:
- أضيفت مسارات `main.html` و`sw.js` إلى triggers.
- أضيفت assertions للتحقق من أعمدة رقم المستند ووقت البداية والنهاية، ومن عدم عرض رقم العملية كعمود أول، ومن وجود استجابة 503 للشبكة.
- أضيفت علامات نجاح:
  - `PARENT_RECEIVING_LOG_DOCUMENT_AND_TIMESTAMPS=PASS`
  - `SERVICE_WORKER_API_NETWORK_FAILURE_HANDLING=PASS`
- Workflow commit: `655224be1f87c463ecd2210e54bc06e09d170927`.
- **UNVERIFIED:** لم تتوفر نتيجة Actions مؤكدة لهذا التشغيل حتى وقت إعداد التقرير؛ لذلك لا أسجل نجاح CI أو اختبار متصفح حي.

## 8. حدود التغيير

- لم يتم تشغيل RPC أو Edge Function.
- لم يتم تعديل أي صف أو رصيد أو قيد في Production.
- لم يتم تعديل SQL function أو schema أو RLS أو GRANT.
- لم يتم تغيير منطق اعتماد الاستلام أو الكميات أو ترحيل المخزون.
- لم يتم حذف Tailwind CDN.
- لم يتم إثبات نشر Cloudflare بعد هذه commits؛ GitHub source ليس وحده إثباتًا أن Production Pages يخدم هذه النسخة.

## 9. الخطوات التالية

1. التحقق من Workflow بعد trigger والتعامل مع أي فشل قبل اعتماد الإصلاح.
2. التحقق من Cloudflare Production SHA ثم اختبار فشل اتصال محاكى في المتصفح؛ يجب أن يظهر HTTP 503 صريحًا بلا `Uncaught (in promise)` صادر من FetchEvent.
3. اعتماد تغيير backend مستقل لقياس وقت بدء الاستلام الفعلي، بعد تصميم دورة start/finish لا تؤثر في atomic stock posting أو idempotency.
4. إعداد CSS build إنتاجي واختبار Parent وReceiver وWarehouse قبل إزالة Tailwind CDN.

**الحالة:** `SERVICE-WORKER API REJECTION HANDLED + PARENT RECEIVING LOG UPDATED + TRUE RECEIVING DURATION NOT YET RECORDED + TAILWIND CDN WARNING DEFERRED`.
