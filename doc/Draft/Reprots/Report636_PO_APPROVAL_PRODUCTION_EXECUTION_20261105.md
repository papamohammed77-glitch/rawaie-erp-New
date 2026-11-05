# Report636 — تنفيذ اعتماد PO متعدد القنوات وحماية الاستلام في SMART ERP Production
**التاريخ:** 2026-11-05  
**الحالة:** تنفيذ قاعدة البيانات وEdge مكتمل ومختبر داخل SMART ERP Production؛ تحديث ملفات الواجهة committed إلى فرع main؛ تأكيد نشر Cloudflare لآخر commit لم يظهر بعد في لوحة النشر المقروءة، ولذلك يظل التحقق النهائي من نسخة Pages غير مثبت.

---

## 1. حدود التنفيذ واحترام توجيه المالك

- بيئة الإنتاج المقصودة هي مشروع Supabase SMART ERP: `fiilmooggumokxanwiyx`.
- تم تنفيذ DDL مباشرة على قاعدة الإنتاج عبر SQL، ولم يُنشأ ملف Migration تشغيلي في مستودع النظام. هذا التقرير توثيق لحالة الإنتاج وليس مكوّنًا runtime.
- لم يتم تعديل `companies/company-1/main.html` من جانب CTO. راجعت نسخة المالك المنشورة وتحققت من تعديل الصلاحية الذي أجراه.
- تم تعديل ملفَي الواجهة المتبقيين فقط: `purchasing/supervisor.html` و`warehouse/receiver.html`.
- لم تُنشأ Edge Function جديدة؛ تم تحديث الدالتين القائمتين فقط.
- لا Branch ولا PR مستقل؛ تغييرات الواجهة committed إلى `main`.

## 2. main.html — مراجعة تعديل المالك

النسخة المنشورة التي تمت مراجعتها:
- Blob SHA: `59241e741abcbc318fa68d3c10775e40e2688927`
- Commit المالك: `684a55240a2f1145134b367204ef0da2c0b696e2`
- Cloudflare كان يعرض وقت الفحص Production deployment على commit `684a552`، URL: `https://bc437d24.rawaea-erp.pages.dev`.

نتيجة التحقق من المصدر:
- زر اعتماد PO في مودال النظام الأم أصبح يظهر عندما يكون PO بحالة Draft والمستخدم لديه `RW_Permissions_check('purchases')`.
- دالة `approvePO` تتحقق من `purchases` ثم تستدعي `api('APPROVE_PO', { id: poId })`.
- الدالة مصدّرة بالفعل ضمن `RW_PurchaseGold` ويستدعيها زر المودال.
- بعد نجاح الاعتماد يتم تحديث قائمة الأوامر.
- إذن تعديل الصلاحية الذي أجراه المالك صحيح وظيفيًا، وملف main لم يُمس من جانب CTO.

ملاحظة تحريرية واحدة للمالك: رسالة المنع داخل `approvePO` ما زالت تقول «اعتماد أمر الشراء يتطلب صلاحية مشرف المشتريات» رغم أن الشرط أصبح `purchases`. الرسالة المقترحة: «اعتماد أمر الشراء يتطلب صلاحية الوصول إلى دورة المشتريات». هذه الرسالة لا تمنع عمل المسار ولا تم تعديل main لإصلاحها.

## 3. SMART ERP — تغييرات قاعدة البيانات المنفذة مباشرة

### 3.1 RPC اعتماد PO

تم إنشاء:
`public.purchase_approve_po_atomic(p_po_id uuid)`

مواصفات الدالة:
- `SECURITY DEFINER` و`search_path TO ''`.
- تعتمد هوية المنفذ من `auth.uid()` ثم تربطها بمستخدم نشط داخل `public.users` وبالشركة.
- تشترط البريد الفعّال للمستخدم.
- تتحقق من الصلاحية الفعلية `purchases` أو `purchases_supervisor` باستخدام `app_private.current_user_has_effective_permission`؛ وبالتالي تشمل صلاحية `*` والمالك الفعّال.
- تحدد PO داخل شركة المستخدم فقط، مع `FOR UPDATE`.
- تسمح بالانتقال من Draft فقط؛ وإذا كانت الحالة Approved تعيد نتيجة idempotent `duplicate=true`.
- تتحقق من وجود بند واحد على الأقل بكمية مطلوبة موجبة.
- تضبط `rawaea.purchase_actor` ثم تحدّث `status='Approved'` و`updated_at` فقط.
- لا تنشئ استلامًا، ولا حركة مخزون، ولا ذمم مورد، ولا قيدًا محاسبيًا، ولا حركة خزينة.
- تم سحب التنفيذ من `PUBLIC` و`anon` ومنحه إلى `authenticated` فقط.

### 3.2 حارس Receiving

تم إنشاء:
`app_private.guard_po_receiving_status()`

وتم إنشاء:
`trg_receiving_require_approved_po BEFORE INSERT ON public.receiving`.

قواعد الحارس:
- إذا كان `po_number` فارغًا، لا يغيّر مسارات Receiving غير المرتبطة بـPO.
- إذا كان PO-linked، يشترط `company_id` ويبحث عن PO مطابق داخل الشركة نفسها.
- لا يسمح بإنشاء Receiving إلا عندما تكون حالة PO إحدى: `Approved` أو `Sent` أو `Partially Received`.
- يرفض Draft وReceived وCancelled، وكذلك رقم PO غير الموجود أو سياق شركة مفقود.
- الدالة داخل `app_private`، وسُحبت صلاحية استدعائها المباشر من PUBLIC وanon وauthenticated؛ يعمل بها الـTrigger فقط.

### 3.3 نتيجة تحقق ACL / Schema بعد التنفيذ

ثبت في الاستعلام الحي:
- `purchase_approve_po_atomic(uuid)` موجودة.
- `guard_po_receiving_status()` موجودة.
- `trg_receiving_require_approved_po` موجود مرة واحدة على `public.receiving`.
- `authenticated` لديه EXECUTE على RPC الاعتماد.
- `anon` ليس لديه EXECUTE على RPC الاعتماد.
- `authenticated` ليس لديه EXECUTE على دالة الحارس.

## 4. Edge Functions القائمة — التنفيذ الحي

### 4.1 save-purchase-order

- الإصدار السابق: v29.
- الإصدار الحالي: **ACTIVE v30**.
- SHA-256 الحالي: `838f8c05d5e64f040dc4a346eae52816877d635bab41684d32d77eebeae304e6`.
- `verify_jwt=true) بقي مفعّلًا.
- أضيف فرع صلاحية صريح لـ`APPROVE_PO`: `purchases` أو `purchases_supervisor`.
- أضيف dispatch يستدعي `profileClient.rpc('purchase_approve_po_atomic', { p_po_id: p.id })` باستخدام JWT المستخدم.
- لا يوجد UPDATE مباشر على جدول PO من الواجهة ولا تجاوز لصلاحيات الخادم.

### 4.2 receive-purchase

- الإصدار السابق: v13.
- الإصدار الحالي: **ACTIVE v14**.
- SHA-256 الحالي: `05584598ded76f17ff6e29d4c6fb951d2f347ed7fdd3549ec457d929756a74fb`.
- `verify_jwt=true) بقي مفعّلًا.
- بعد تحويل البنود والتحقق من الكميات، ترفض الدالة الطلب إذا لم يوجد بند واحد على الأقل بكمية `received_qty > 0`.
- لم يتم تغيير صلاحيات مستلم المخزن أو نطاق الفرع في Edge الحالية.
- لم يتم تغيير `receive_purchase_atomic` ولا إضافة Edge جديدة.

## 5. supervisor.html — التعديل المنشور إلى GitHub main

الملف:
`companies/company-1/purchasing/supervisor.html`

Commit:
`cf07aba424f5ca37cf75ac1804d756448841f4ea`

Blob SHA:
`8d46c3c6d6df487ebd880c29d438bcdd2bd789bf`

التنفيذ:
- بوابة الدخول أصبحت: Owner أو `*` أو `purchases_supervisor`، وليس `purchases` العام.
- يثبت `switchTab` قيمة `currentTab` التي تعتمد عليها Realtime callbacks.
- أضيف HTML escaping وأسماء عربية للحالات.
- `renderOrders` يقرأ جميع PO للشركة بصفحات 200، دون سقف 50، مع ترتيب ثابت أثناء pagination.
- تظهر هوية منشئ PO `created_by` مع المورد والفرع والتاريخ وموعد التوريد والحالة والقيمة والعملة.
- أضيف البحث برقم PO أو المورد أو منشئ الأمر أو الفرع، وفلتر بالحالة.
- أضيف مودال تفاصيل يقرأ البنود عن طريق `purchase_order_details.po_id` ويعرض المطلوب والمستلم والمتبقي والسعر.
- زر الاعتماد يظهر لأمر Draft فقط إذا احتوى على بند ذي كمية موجبة.
- الاعتماد يمر عبر `RW_API.call('save-purchase-order', ...)` إلى Edge القائمة؛ لا يوجد UPDATE مباشر على `purchase_orders`.

## 6. receiver.html — التعديل المنشور إلى GitHub main

الملف:
`companies/company-1/warehouse/receiver.html`

Commit:
`b728c09e1bb4c482effc48a492546b393ff02c1f`

Blob SHA:
`075ddf9e5801c25bd337d65bf883b4bf4b5736c3`

التنفيذ:
- استعلام قائمة أوامر الاستلام ما زال يعرض Approved وSent وPartially Received فقط.
- أصبح الاستعلام محددًا صراحةً بـ`company_id` ويحمّل جميع النتائج عبر صفحات 200 بدل `.limit(50)`.
- أضيف فحص `res.error` في تحميل القائمة.
- في تفاصيل PO يتم إخفاء زر الاستلام أولًا، ولا يظهر إلا إذا وُجد متبقٍ موجب.
- خطأ تحميل تفاصيل PO يظهر كخطأ تحميل صريح، ولا يُعرض على أنه «لا توجد أصناف».
- لا تُرسل البنود ذات الكمية صفر.
- يمنع التطبيق الكمية غير الرقمية أو السالبة أو التي تتجاوز المتبقي، ويرفض الإرسال إذا لم توجد كمية موجبة.
- تم جعل callback آمنًا عند غياب JSON.
- لم يتم تغيير عملية الاستلام المركزية أو منطق ترحيل المخزون والحسابات.

## 7. اختبارات Production المنفذة ونتائجها

تم استخدام fixture مؤقت داخل كتلة SQL واحدة، ثم تنظيفه قبل اكتمال التنفيذ. لم يُستخدم PO الحقيقي الموجود.

نتائج الاختبار:
1. مستخدم `cashier@rawaea.com` الذي يحمل `pos` فقط رُفض عند استدعاء RPC برسالة `PURCHASE_PO_APPROVAL_PERMISSION_REQUIRED`.
2. إدخال Receiving مرتبط بـPO بحالة Draft رُفض بالحارس برسالة `PURCHASE_PO_NOT_APPROVED_FOR_RECEIVING`.
3. مستخدم `buyer1@rawaea.com` الذي يحمل `purchases` دون `purchases_supervisor` نجح في اعتماد PO الاختباري من Draft إلى Approved.
4. إعادة الاعتماد أعادت `duplicate=true` ولم تكرر انتقال الحالة.
5. Trigger تاريخ الحالة أنشأ سجلًا واحدًا بالانتقال Draft → Approved وبفاعل `buyer1@rawaea.com`.
6. إدخال Receiving المرتبط بالأمر بعد الاعتماد اجتاز حارس الحالة.
7. حُذفت Receiving الاختبارية، وسجلات تاريخ PO التجريبية، وتفاصيل PO التجريبي، وPO التجريبي نفسه قبل انتهاء كتلة الاختبار.

### Current production data after QA

- `purchase_orders`: سجل واحد فقط، حالته Draft.
- `receiving`: صفر.
- سجلات `purchase_status_history` الخاصة بـ`purchase_orders`: صفر.
- PO الفعلي `QA-SR-PO-20260927` لم يتم تغييره.
- لم تُترك بيانات اختبار.
- لم يتم إجراء اختبار استلام حقيقي عبر Edge/API لأنه لم تتوفر وسيلة تفاعل من جلسة مستخدم Receive الفعلية في هذه المهمة؛ اختبار الحارس تم مباشرة على حدود جدول Receiving، كما تم اختبار كود Edge بالمصدر المنشور والإصدار النشط.

## 8. تحقق المصدر قبل النشر وفحص الجودة

- تم إعادة جلب ملفات GitHub بعد عمليات التعديل والتحقق من Blob SHA لكل ملف.
- تم تحليل JavaScript inline script داخل `supervisor.html` و`receiver.html` نحويًا بواسطة JavaScript parser؛ لم يظهر خطأ syntax.
- Edge metadata أعادت ACTIVE v30 وACTIVE v14 مع `verify_jwt=true`.
- فحص Supabase Security Advisor العام أظهر تحذيرات موجودة على وظائف أخرى: دالتان عامتان SECURITY DEFINER يمكن استدعاؤهما من anon، وتحذير عام عن دوال SECURITY DEFINER متاحة للمستخدم المصادق، إضافة إلى Leaked Password Protection disabled. لم يتم تعديل هذه العناصر لأنها خارج نطاق هذه المهمة. RPC الجديدة نفسها ليست متاحة لـanon.
- Performance Advisor أظهر عددًا كبيرًا من تنبيهات foreign keys غير المفهرسة على نطاق قاعدة البيانات؛ لم يجرِ إدخال فهارس خارج نطاق PO.

## 9. حالة Cloudflare Pages — نقطة التحقق المتبقية

- إعداد المشروع المقروء: Automatic deployments enabled، المصدر `main`، النطاق `rawaea-erp.pages.dev`.
- آخر Production deployment ظهر في محتوى لوحة Cloudflare المقروء وقت التحقق كان commit `684a552`، وليس `cf07aba` أو `b728c09`.
- لم أعتبر وجود commits في GitHub دليلًا على نجاح نشر Cloudflare.
- لذلك: ملفات الواجهة committed إلى main، لكن **تأكيد Production Pages لآخر commit لم يثبت في هذه المراجعة**. يلزم فتح سجل Deployments والتحقق من نشر commit `b728c09e1bb4c482effc48a492546b393ff02c1f) وأن حالته Success، ثم فحص التطبيق المنشور. لا ينبغي إعلان الواجهة مكتملة النشر قبل ذلك.

## 10. Rollback / الاستعادة

- DB: إذا لزم التراجع، تُزال `trg_receiving_require_approved_po` ثم `app_private.guard_po_receiving_status()` ثم `public.purchase_approve_po_atomic(uuid)` بعد مراجعة أي استهلاك حي. لا يُعاد PO فعلي معتمد إلى Draft تلقائيًا.
- Edge: النسخ السابقة محفوظة في Supabase versions: `save-purchase-order` v29 و`receive-purchase` v13. يمكن إعادة نشر المصدر المحفوظ لكل إصدار إذا تطلبت الاستعادة.
- Frontend: الرجوع إلى commit السابق لكل ملف على main مع مراجعة أثره على كل تغييرات main اللاحقة قبل أي revert.
- لا تُحذف أو تُعكس عمليات استلام فعلية بعد النشر بحذف الصفوف؛ تستخدم مستندات العكس المخزني/المحاسبي المعتادة.

## 11. نقطة الاستكمال للمساعد التالي

1. تحقق من Cloudflare Pages Deployment commit `b728c09e1bb4c482effc48a492546b393ff02c1f`، وافحص الحالة Success.
2. افتح `/companies/company-1/purchasing/supervisor.html` بهوية Supervisor فعلية لديها `purchases_supervisor` (لم يتوفر في بيانات Production المقروءة مستخدم منفصل بهذه الصلاحية دون Owner؛ اختُبر مسار purchases-only على DB).
3. اختبر واجهة النظام الأم بحساب `purchases` فقط، دون اعتماد أمر Production حقيقي.
4. اختبر Supervisor end-to-end على PO اختبار قابل للتنظيف، ثم Receiver والاستلام عبر Edge، مع عكس وتنظيف أي بيانات اختبار دون إبقاء أثر.
5. أبقِ أمر الإنتاج `QA-SR-PO-20260927` كما هو؛ ما زال Draft ولم يُستخدم في QA.

**الخلاصة:** طبقة قاعدة البيانات والدوال الخلفية نُفذت مباشرة على SMART ERP واختُبرت، وتعديلات Supervisor وReceiver committed إلى main. ما لم يثبت بعد هو نشر آخر commit في Cloudflare واختبار واجهة المستخدم بجلسات تشغيل فعلية.
