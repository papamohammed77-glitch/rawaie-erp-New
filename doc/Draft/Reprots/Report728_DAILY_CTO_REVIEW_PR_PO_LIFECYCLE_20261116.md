# RAWAEA ERP — المراجعة التشغيلية اليومية / CTO
## LVE-2026-11-16-728 — تدقيق دورة طلب الشراء PR إلى أمر الشراء PO وحوكمة الصلاحيات

**التاريخ:** 2026-11-16، 22:04 Africa/Cairo  
**النطاق الفعلي:** دورة المشتريات PR/RFQ/Quotation/PO، النظام الأم، Buyer، Purchasing Supervisor، Receiver، Edge Function، وعقود Supabase Production ذات الصلة.  
**نوع التنفيذ:** مراجعة قراءة فقط؛ لم تُنفذ أي كتابة تشغيلية أو DDL/DML أو اختبار بيانات في Production.  
**الحكم:** READY WITH LIMITATIONS للتحليل وتجهيز Change Set؛ BLOCKED لأي تعديل تشغيلي حتى اعتماد المالك للتغيير المحدد.

---

## 1. نقطة البداية — LAST VERIFIED EVENT / Checkpoint

- نقطة الاستئناف: LVE-2026-11-16-727، تقرير Report727 الخاص باستلام المشتريات وIdempotency وفصل حالة الفاتورة عن الاستلام والتسوية.
- تم استئناف العمل من الحالة الحالية، لا من تقرير قديم ولا من الذاكرة وحدها.
- CURRENT_STATE.md قُرئ كاملًا: 2,332 سطرًا، SHA: 55d4e38e68750dd56b9dd231ce66f43843a200c8.
- الدستور التشغيلي الدائم قُرئ كاملًا: 310 أسطر، SHA: 3a6b1e220af8509e314e94df76563bbc6f84910d.
- Report727 قُرئ كاملًا: 287 سطرًا، SHA: 9f10c98b5fadcf65a3a5896b97a450725f842582.
- ملف RAWAEA_PROJECT_MEMORY_117-02.md كان متوقفًا عند LVE-2026-11-15-726؛ لذلك جرى تحديثه في هذا التسليم بملخص LVE727 ثم LVE728 دون حذف التاريخ.
- المستودع التشغيلي: papamohammed77-glitch/erp-frontend، الفرع main، HEAD الحالي: ebb2a01d07c8dc1460bd4f577962a7b8c26be920، بتاريخ 2026-11-16 17:06:05Z. الفرع غير محمي.
- ملفات المنبع ذات الصلة:
  - companies/company-1/main.html — blob 1af4430e34bb5434327cb24a3dca50b538188f42.
  - companies/company-1/core.js — blob 2b2211a3f95049042e27a7b2ecbab3640a584942.
  - companies/company-1/purchasing/buyer.html — blob db1d311966a676dd2c7210895afefef5b5d2a954.
  - companies/company-1/purchasing/supervisor.html — blob 916636b89f6e376b437a9328087b02de82c2610d.
  - supabase/functions/save-purchase-order/index.ts — blob 22971afed19c1f23cc0038bb62e56c251202f05e.
- آخر إغلاق مؤكد في النطاق السابق: LVE727؛ لا يُعاد فتح اختبار الاستلام السابق بلا تغيير مؤثر في RPC أو مخططه.
- المسألة المفتوحة الحالية: الفصل الدلالي والتشغيلي بين PR وPO، وربط مصدر الطلب بالقسم والفرع وبأمر الشراء، مع ثغرة صلاحيات حرجة في جداول مستندات المشتريات وسجل التدقيق.

## 2. CONFIRMED — الحقائق المثبتة

### 2.1 GitHub / Source

- HEAD الحالي على main هو ebb2a01d07c8dc1460bd4f577962a7b8c26be920.
- منذ HEAD المسجل في LVE727، وهو 8c26511ec34f143aa0c07779bad213aa7c5f74ed، يوجد 15 commit. التغييرات محصورة في ثلاثة ملفات:
  1. buyer.html: +247 / -39.
  2. buyer.tailwind.css: +1 / -1.
  3. save-purchase-order/index.ts: +64.
- لم يتغير main.html أو core.js أو supervisor.html في هذه السلسلة.
- آخر commit يعالج إظهار أوامر الشراء المعتمدة التي لم يبدأ استلامها في اختيار فاتورة Buyer.
- لا يوجد تغيير في Core أو في النظام الأم لمعالجة دورة PR/PO منذ نقطة LVE727.

### 2.2 Supabase Production

- مشروع SMART ERP، ref: fiilmooggumokxanwiyx، الحالة ACTIVE_HEALTHY، PostgreSQL 17.6.1.121، المنطقة eu-west-1.
- عدد migrations المطبقة: 795؛ أحدث migration: 20261116144311_receiving_rls_context_and_fk_index_opt_20261116.
- آخر أربع migrations تخص قراءة الاستلام، دقة الكميات، دمج سياسات قراءة الاستلام، وتحسين سياق RLS والفهارس؛ لم يظهر ضمنها إصلاح جديد لعقد PR/PO.
- إعدادات الشراء الحالية: require_request_approval = true، وpurchase_settings.default_branch_id = NULL.
- أعداد البيانات الحالية: purchase_requests = 1، purchase_rfqs = 0، purchase_quotations = 1، purchase_orders = 4، purchase_document_links = 5، purchase_status_history = 22.
- لا يوجد RFQ حالي في Production؛ ولا توجد سلسلة PR → RFQ → Quotation → PO مكتملة في البيانات الحالية.

### 2.3 بيانات PR/PO الحالية

- PR-1000:
  - الحالة Approved.
  - requested_by = owner@rawaea.com.
  - approved_by = owner@rawaea.com.
  - أُنشئ في 2026-11-16 17:12:09.859888Z، واعتمد في 17:12:13.722863Z.
  - بنوده: الصنف 1004 كمية 4 كرتونة، والصنف 1001 كمية 2 صندوق.
  - لا يحتوي عقد الجدول على department_id أو branch_id أو requested_by_user_id.
  - سجل الحالة يثبت حدثي INSERT إلى PendingApproval ثم UPDATE إلى Approved، وكلاهما بواسطة owner@rawaea.com.
- PO-20260930:
  - الحالة Draft، أُنشئ بواسطة buyer1@rawaea.com في 2026-11-16 17:09:32.177Z، أي قبل PR-1000 بنحو دقيقتين و38 ثانية.
  - الفرع المسجل هو الفرع الرئيسي.
  - بنوده: الصنف 1019 كمية 3 كرتونة، والصنف 1001 كمية 10 صناديق.
  - لا يوجد رابط PR إليه، كما أن بنوده لا تطابق بنود PR-1000؛ لذلك لا يجوز اعتباره تحويلًا لهذا الطلب أو ربطه به بأثر رجعي.
- PQT-1000 هو عرض مستقل rfq_id فيه NULL وحالته Converted، ولا يوجد RFQ حالي يربطه بطلب PR. يرتبط بأمر شراء عبر purchase_document_links، لكنه لا يثبت سلسلة PR.
- لا توجد روابط حالية من PurchaseRequest إلى PurchaseRFQ أو PurchaseOrder في purchase_document_links.
- QA-SR-PO-20260927 ما زال أمرًا مرجعيًا قائمًا بحالة Approved وqty_received = 5؛ لم يُلمس. عنوان PR-1000 يحتوي كلمة «تجريبي»، لكن لا توجد علامة تشغيل QA موحدة أو مدة صلاحية أو مالك تنظيف مثبتة؛ لذلك لم يُعامل كبيانات قابلة للحذف.

### 2.4 Edge / Runtime contract

- save-purchase-order منشور في Supabase كـ Version 44، ACTIVE، verify_jwt=true.
- SHA للمصدر الحي: 0bf7e223babdf1bf9ee61c3d90148b86934fdfcebe16015004b1a030be9f0791.
- محتوى index.ts الحي مطابق حرفيًا لمصدر GitHub الحالي.
- العمليات الحالية تتضمن CREATE_REQUEST وAPPROVE_REQUEST وCREATE_RFQ وCONVERT_QUOTATION_TO_PO وCREATE_PO وAPPROVE_PO وGET_DATA وGET_PO_INVOICE_PROGRESS.
- لا توجد عملية SEND_PO في Edge الحالي، ولا دالة منشورة باسم purchase_send_po_atomic أو send_purchase_order_atomic. لكن Receiver يقبل أوامر Approved أو Sent أو Partially Received؛ لذلك عدم وجود SEND_PO لا يمنع الاستلام بعد الاعتماد، لكنه يترك إرسال أمر الشراء للمورد وحالته غير مثبتين داخل النظام.

## 3. UNKNOWN — ما لا تسمح الأدلة الحالية بحسمه

- لم تُقرأ بايتات HTML/JS التي يقدمها عنوان Cloudflare بعد النشر، ولم تُقارن رؤوس Cache أو Service Worker أو build lineage من Runtime.
- لم تُنفذ جلسة Browser مصادق عليها بحساب طالب PR أو المشتري أو مشرف المشتريات.
- لم يُقَس زمن وصول Realtime أو نجاح إعادة الاشتراك بعد انقطاع الشبكة.
- لم تُجرَ اختبارات E2E لدورة PR-originated PO؛ ولا توجد بيانات RFQ حالية يمكن تتبعها.
- لم تُراجع بقية تطبيقات المبيعات والتوزيع والخزينة والحسابات في هذا التشغيل؛ لا يجوز اعتبارها سليمة بناءً على هذه المراجعة.
- لم يُعَد التحقق من Staging اليوم، ولذلك لا يُفترض أنه صالح للاختبار.
- لا يمكن استنتاج قسم PR-1000 من عنوانه أو من الفرع الافتراضي لحساب المالك؛ القسم والفرع غير مخزنين على الطلب.

## 4. CONFLICT — التعارضات

1. الدستور التشغيلي الدائم، §6.4، يحتفظ بسياسة تاريخية تسمح ببيانات QA معلّمة داخل Production عند تحقق شروطها. أما تعليمات المالك الأحدث في هذا البروتوكول، §19، فتمنع إنشاء بيانات أو عمليات اختبار في Production وتطلب بيئة معزولة، وأي استثناء يحتاج موافقة منفصلة صريحة. طُبقت القاعدة الأحدث والأكثر حماية: لم يُنشأ أي سجل أو تنفيذ اختبار في Production.
2. تقرير Report633 التاريخي ذكر أن اعتماد PO غير موجود آنذاك. المصدر الحالي وقاعدة Production يثبتان أن purchase_approve_po_atomic وAPPROVE_PO وتطبيق Purchasing Supervisor أصبحت موجودة؛ لذلك أُغلقت تلك الملاحظة القديمة من ناحية وجود وظيفة الاعتماد، لكنها لم تُغلق من ناحية الفصل بين المنشئ والمعتمد.
3. تقرير Report569/571 يثبت أن التصميم المقصود تاريخيًا هو PR → RFQ → عروض الموردين → قبول العرض → PO. المسار الحالي لا يزال يحتوي هذه المراحل، لكنه يضع حالة PR = Converted عند إنشاء RFQ، أي قبل وجود PO؛ هذا تعارض دلالي بين اسم الحالة والواقعة التي حدثت.
4. توجد اختلافات بين التطبيقات في بوابات الحالات: Parent يسمح بإنشاء RFQ من Draft أو Approved، بينما Buyer يسمح بـ Approved فقط؛ Parent يسمح بتحويل عرض Submitted أو Accepted، بينما Buyer يعرض التحويل للعروض Accepted فقط.

## 5. UNVERIFIED — نتائج لم تُختبر مباشرة

- نجاح GitHub/Cloudflare check لا يثبت أن المتصفح يقدم نفس bytes أو أن المستخدم يستطيع إكمال المسار.
- لا يوجد اختبار مصادق عليه يثبت أن موظف قسم بلا صلاحية purchases يستطيع إنشاء PR أو متابعة طلبه.
- لا يوجد اختبار يثبت أن مستخدمًا غير مشتريات لا يستطيع الكتابة مباشرة عبر PostgREST؛ على العكس، عقود RLS وGRANT الحالية تثبت وجود مسار DML متاح للمستخدم المصادق داخل الشركة.
- لم تُنفذ عملية تحويل PR أو RFQ أو عرض إلى PO، ولم تُنشأ حركة مخزون أو قيد مالي أو عهدة في هذا التشغيل.

## 6. مصفوفة التحقق

| الطبقة | النتيجة | الدليل |
|---|---|---|
| GitHub / Source | CONFIRMED | main HEAD ebb2a01؛ ثلاثة ملفات تغيرت منذ LVE727؛ main/core/supervisor لم تتغير |
| Supabase Production | CONFIRMED | ACTIVE_HEALTHY؛ 795 migrations؛ مخطط وجداول ووظائف وسياسات وبيانات تمت قراءتها |
| Deployed Artifact | PARTIAL / UNVERIFIED | Cloudflare Pages check لمشروع rawaea-erp ناجح؛ لم تُقرأ bytes المنشورة أو alias |
| Runtime / E2E | UNVERIFIED | لا جلسة Browser مصادق عليها ولا اختبار مستخدم حقيقي |
| Business-Data Effects | CONFIRMED: NONE BY THIS RUN | كل استعلامات هذا التشغيل قراءة فقط؛ لم تحدث أي كتابة تشغيلية |
| Staging | UNKNOWN | لم يُعَد التحقق من جاهزيته ولم يُنفذ اختبار عليه |

## 7. ما تم فعليًا

1. استعادة CURRENT_STATE والدستور والتقرير السابق، ثم مراجعة التقارير التاريخية ذات الصلة: Report569 وReport571 وReport599 وReport633 وReport680 وReport727.
2. مقارنة commits من 8c26511 إلى ebb2a01 وفحص الملفات الثلاثة المتغيرة.
3. مطابقة save-purchase-order Version 44 الحي مع GitHub حرفيًا.
4. فحص مخطط Production وعلاقات PR/RFQ/Quotation/PO والقيود والفهارس والسياسات والصلاحيات والـTriggers والـFunctions ذات الصلة.
5. قراءة بيانات PR-1000 وأوامر الشراء والعروض والروابط وسجل الحالات، دون تعديلها.
6. فحص مسارات Parent وBuyer وPurchasing Supervisor وReceiver.
7. إجراء Benchmarking وظيفي محدود بمصادر رسمية.
8. عدم إجراء أي DDL أو DML أو RPC أو اختبار إنتاجي.

## 8. ما لم يتم ولماذا

- لم يُعدّل main.html أو buyer.html أو supervisor.html أو Edge أو Supabase؛ لأن التغيير التشغيلي المحدد لم يُعرض بعد على المالك كـChange Set مع النص والأثر والتراجع، ولأن الدستور يمنع التطبيق قبل الاعتماد.
- لم تُنشأ بيانات اختبار في Production امتثالًا لتوجيه المالك الأحدث.
- لم يُنفذ E2E بسبب عدم توفر جلسة Browser مصادق عليها وعدم إعادة التحقق من Staging.
- لم يُعدّل PR-1000 أو PO-20260930 أو QA-SR-PO-20260927؛ فالأول والثاني بيانات Production غير مصنفة QA بشكل منضبط، والثالث مرجع QA تاريخي يجب الحفاظ عليه.

## 9. صحة التطبيقات والتغطية

| التطبيق / النطاق | ما فُحص اليوم | الحالة |
|---|---|---|
| النظام الأم main.html | طلب PR، اعتماد PR، إنشاء RFQ، تحويل العرض إلى PO، اعتماد PO، اختيار PO في مودال الفاتورة، Realtime | فُحص مصدرًا؛ Runtime غير مختبر |
| Buyer.html | قائمة PR، تفاصيل PR، إنشاء RFQ، قائمة PO، إنشاء PO مباشر، اختيار PO للفاتورة، Realtime | فُحص مصدرًا؛ بعض الفلاتر صحيحة في المصدر |
| Purchasing Supervisor | عرض PR، تفاصيل PR، اعتماد PO، الصلاحيات، Realtime | فُحص مصدرًا؛ تفاصيل اعتماد PR ناقصة |
| Receiver.html | حالات PO المقبولة للاستلام والكمية المتبقية | فُحص مصدرًا؛ لم ينفذ استلام |
| save-purchase-order Edge | GET_DATA وCREATE_REQUEST وAPPROVE_REQUEST وCREATE_RFQ وCONVERT_QUOTATION_TO_PO وCREATE_PO وAPPROVE_PO | المصدر الحي مطابق لـGitHub |
| core.js | المسار والـSHA والتغيير منذ LVE727 | لم يتغير؛ لم يُعد تدقيق وحداته بالكامل لأن نطاق PR/PO لا يثبت اعتماد تعديل Core |
| المخزن الشامل والمبيعات والخزينة والحسابات | لا فحص تفصيلي اليوم | لم تُفحص؛ لا ادعاء سلامة |

## 10. تدقيق التعديلات الأخيرة

- commits الـ15 بعد LVE727 عالجت UOM وفواتير PO وقراءة تقدم الفاتورة وفلترة PO في Buyer.
- Buyer invoice selector أصبح يطلب PO حالته Approved، وله بنود، وجميع qty_received فيه تساوي صفرًا؛ ويُبقي PO الأصلي لفاتورة Draft مفتوحة كمرجع مقفول فقط.
- Production الحالي لا يحتوي PO مؤهلًا لهذا الاختيار: يوجد PO Approved واحد هو QA-SR-PO-20260927 وله qty_received = 5؛ بقية الأوامر Draft أو Received. لذلك Buyer selector يجب أن يعرض صفر PO جديد حاليًا.
- Parent main.html لم يتغير في هذه السلسلة؛ ومودال createInvoice ما زال يستعلم عن الحالات Draft وConfirmed وApproved وPartially Received وReceived، وبالتالي يعرض الأوامر الأربعة الحالية بما فيها المستلم بالكامل والمسودة. هذا يخالف قاعدة المالك التي حصرت المودال في PO غير المستلم.
- نجاح Cloudflare Pages check لمشروع rawaea-erp لا يثبت وحده أن كل نسخة Parent/Buer المنشورة مطابقة للمصدر؛ artifact الفعلي لم يُقرأ.

## 11. الأخطاء والفجوات والسبب الجذري

### P0 — ثغرة كتابة مباشرة وتعديل سجل التدقيق

CONFIRMED في Production:
- الجداول purchase_requests وpurchase_request_details وpurchase_rfqs وpurchase_rfq_details وpurchase_quotations وpurchase_document_links وpurchase_status_history لديها RLS policies من نوع ALL على مستوى الشركة.
- GRANT للمستخدم authenticated يتضمن INSERT وUPDATE وDELETE على هذه الجداول.
- سياسات RLS تتحقق من company_id = app_private.current_user_company_id() فقط، ولا تتحقق من صلاحية purchases أو دور مقدم الطلب أو القسم أو كون العملية عبر RPC مركزي.
- current_user_company_id() يعيد شركة أي مستخدم مصادق عليه ونشط؛ لا يفرض صلاحية شراء.
- purchase_status_history نفسه قابل للتعديل والحذف من مستخدم مصادق داخل الشركة، وpurchase_document_links قابل للإنشاء والتعديل والحذف دون FK على source/target.
- هذا يسمح نظريًا ومباشرة وفق GRANT + RLS بتجاوز Edge/RPC، وتغيير حالة PR أو تفاصيله، وكسر روابط المستندات، وتعديل/حذف أثر التدقيق. لم يُجرّب أي DML لإثبات ذلك عمليًا، لأن الاختبار ممنوع في Production؛ العقد الحالي نفسه دليل كافٍ على سطح الخطر.
- purchase_orders وpurchase_order_details مختلفان: سياساتهما SELECT فقط ولا تظهر لهما صلاحيات DML للمستخدم العادي.

**الإصلاح المقترح:** حصر الكتابة في Edge/RPC المعتمد، وسحب DML من anon/authenticated على جداول المستندات وسجل التدقيق، وتحويل السياسات إلى SELECT فقط بنطاق الشركة/القسم المناسب، بعد مسح المستودع كاملًا للتأكد من عدم وجود تطبيق قديم يعتمد على direct DML. لا تنفذ هذه الهجرة قبل موافقة المالك.

### P1 — لا توجد هوية قسم أو فرع على PR

- purchase_requests لا يحتوي department_id أو branch_id أو requested_by_user_id.
- purchase_create_request_atomic لا يستقبل هذه القيم؛ يخزن requested_by كنص بريد إلكتروني فقط.
- نموذج Parent لإنشاء PR لا يطلب القسم أو الفرع.
- Buyer يعرض البريد الإلكتروني تحت عنوان «الإدارة/مقدم الطلب» ويقر في التفاصيل بأن القسم غير محفوظ كحقل مستقل.
- HR master data غير جاهزة: hr_departments = 0، hr_employee_assignments = 0، employee_profiles = 0. حساب المالك الذي أنشأ PR-1000 employee_id لديه NULL؛ لذلك لا توجد علاقة موظف/قسم موثوقة.
- default_branch_id لحساب المالك يشير إلى الفرع الرئيسي، لكن PR لا يخزن هذا الفرع؛ لا يجوز استنتاجه أو تحويل نص العنوان إلى بيانات مرجعية.

**الإصلاح المقترح:** بعد تجهيز الأقسام وتعيينات الموظفين، أضف requested_by_user_id وdepartment_id وbranch_id إلى PR، واربطها بمصدر HR/الفرع، واحفظ Snapshot القسم والفرع عند الإنشاء. لا تنشئ Department selector يعتمد على جدول HR فارغ.

### P1 — لا يستطيع مستخدم القسم إنشاء PR من المسار المعتمد

- CREATE_REQUEST وAPPROVE_REQUEST وCREATE_RFQ في save-purchase-order تقع في بوابة purchases العامة.
- GET_DATA الخاص ببيانات المشتريات يسمح بـ purchases أو finance أو finance_manager.
- Buyer app لا يقبل إلا purchases أو finance أو finance_manager.
- دور مشرف المشتريات يملك purchases_supervisor فقط؛ وتطبيقه يعرض PR للقراءة ولا يوفر اعتماد PR.
- لا يوجد permission key مستقل لمقدم طلب شراء من الأقسام ولا نطاق رؤية لطلباته.
- النتيجة: لا يوجد مسار مثبت يسمح لموظف قسم لا يملك purchases بإنشاء PR ومتابعته، بينما RLS الحالي يسمح له نظريًا بالكتابة المباشرة؛ وهذا تناقض بين التطبيق والعقد الأمني.

**الإصلاح المقترح:** تعريف صلاحية مستقلة لمقدم PR ونطاق قراءة «طلباتي/طلبات قسمي»، وصلاحية اعتماد مستقلة يحدد المالك صاحبها. لا يُفترض أن purchases_supervisor هو معتمد PR قبل قرار المالك.

### P1 — حالة PR تتحول مبكرًا إلى Converted

- purchase_create_rfq_atomic يقبل PR حالته Approved أو Draft.
- عند إنشاء RFQ يحدّث PR.status إلى Converted، رغم أن RFQ طلب عروض وليس PO.
- بذلك قد تظهر حالة Converted قبل إنشاء أمر شراء فعلي.
- لا توجد حالة واضحة RFQCreated/Sourcing، ولا حالة PartiallyOrdered/Ordered في قيد الحالة الحالي.
- لا يحدث تحديث موثوق لحالة PR عند تحويل عرض مقبول إلى PO؛ دالة تحويل العرض لا تحدّث PR عبر RFQ.request_id.

**الإصلاح المقترح:** لا تستخدم Converted عند إنشاء RFQ. استخدم حالة RFQCreated/Sourcing، ولا تُحدّث PR إلى Ordered/PartiallyOrdered إلا بعد إنشاء PO وربطه فعليًا. احتفظ بمسار PR → RFQ → Quotation → Accepted → PO الذي وثقته التقارير التاريخية.

### P1 — تجاوز اعتماد PR عند إنشاء RFQ

- Parent createRFQ يختار الحالات Approved وDraft.
- دالة Production purchase_create_rfq_atomic تسمح بالحالتين.
- إعداد require_request_approval = true.
- Buyer يقصر زر إنشاء RFQ على Approved فقط، لكن Parent يسمح بـ Draft؛ وهذا تعارض تطبيقات ومسار تجاوز موافقة.

**الإصلاح المقترح:** Backend وParent يشترطان Approved فقط. إذا كانت سياسة الشركة لا تتطلب اعتماد PR، فإن purchase_create_request_atomic ينشئه Approved حسب الإعداد؛ لا حاجة للسماح بـ Draft.

### P1 — تحويل عرض Submitted إلى PO دون قبول

- Parent يعرض زر التحويل للعروض Accepted أو Submitted.
- Buyer يعرضه للعروض Accepted فقط.
- purchase_convert_quotation_to_po_atomic يقبل Submitted أو Accepted.
- عند التحويل يكتب accepted_by وaccepted_at إذا كانا فارغين؛ بذلك يستطيع التحويل أن يملأ بيانات قبول لم تحدث فعليًا.
- لا يتحقق المسار من وجود RFQ مرتبط أو PR معتمد؛ والـquotation الحالي الوحيد PQT-1000 لديه rfq_id = NULL.

**الإصلاح المقترح:** التحويل يتطلب Accepted فقط؛ لا تكتب بيانات قبول تلقائيًا داخل دالة التحويل؛ تحقق من سلسلة المصدر PR/RFQ/Quotation أو من استثناء مباشر معتمد.

### P1 — فصل المهام في اعتماد PR وPO غير مكتمل

- purchase_approve_request_atomic يقبل Draft وPendingApproval وSubmitted، ولا يقارن actor مع requested_by.
- Edge APPPROVE_REQUEST يمر عبر صلاحية purchases فقط، ولا يقبل purchases_supervisor صراحة.
- PR-1000 أنشأه واعتمده الحساب نفسه owner@rawaea.com؛ لا نحكم أن تصرف المالك غير صحيح، لكن لا توجد قاعدة عامة تمنع اعتماد مقدم الطلب لنفسه.
- purchase_approve_po_atomic موجود ويقبل purchases أو purchases_supervisor، لكنه لا يمنع created_by من اعتماد أمره بنفسه.
- Parent approvePO يفحص purchases، بينما رسالة الواجهة تقول إن الإجراء يتطلب مشرف المشتريات؛ Supervisor app يفحص purchases_supervisor. إذن الواجهتان لا تتبعان بوابة واحدة.
- اعتماد PO موجود حاليًا، خلافًا لما ذكره Report633 تاريخيًا، لكن الفصل بين المنشئ والمعتمد غير مغلق.

**الإصلاح المقترح:** قاعدة موحدة للمالك/المعتمد؛ فصل منشئ PR عن معتمده ومنشئ PO عن معتمده، مع Owner override موثق. تحديد ما إذا كان اعتماد PR من مدير القسم أو مشرف المشتريات قرارًا للمالك.

### P1 — أمر PO لا يحتفظ بمصدره التشغيلي

- purchase_rfqs.request_id يربط RFQ بطلب PR.
- purchase_quotations.rfq_id يربط العرض بـRFQ.
- purchase_document_links يربط العرض بـPO.
- purchase_orders لا يحتوي request_id أو source_request_id أو rfq_id.
- purchase_document_links لا يملك FK على source_id/target_id.
- تطبيقات Parent وBuyer لا تعرض PR المصدر في بطاقة PO.
- مسار التحويل إلى PO لا يحدّث حالة PR ولا يضيف رابط PR→PO مباشرًا.
- دالة purchase_convert_quotation_to_po_atomic لا تحفظ branch_id أو expected_delivery_date أو payment_terms في PO الناتج، مع أن جدول PO يدعم هذه الحقول.

**الإصلاح المقترح:** استخدم سلسلة مستندات موثقة ومتحققًا منها، وأنشئ رابط PR→PO عند التحويل (مع إبقاء روابط RFQ والعرض)، واعرض مصدر PO والقسم والفرع. انقل branch_id والموعد وشروط الدفع من مصدر موثوق؛ لا تستنتجها من واجهة العميل.

### P1 — Parent PO invoice selector ما زال يعرض أوامر غير مؤهلة

- Buyer يرشح Approved فقط ويشترط وجود بنود وعدم وجود أي qty_received > 0؛ وهذا صحيح بالنسبة لقاعدة المالك الحالية.
- Parent createInvoice ما زال يطلب Draft وConfirmed وApproved وPartially Received وReceived.
- في Production الحالي: Parent يعيد 4 أوامر، بينما Buyer يعيد 0 أمر مؤهلًا. لا يوجد أمر Approved غير مستلم حاليًا.
- هذا يجعل النظام الأم غير متسق مع Buyer ويعرض أمرًا مستلمًا بالكامل أو مسودة في مودال الفاتورة.

**الإصلاح المقترح:** توحيد helper eligibility في Parent وBuyer، ويشترط الحالة المعتمدة ووجود تفاصيل وكل الكميات المستلمة = صفر. الاحتفاظ بمرجع PO لفاتورة Draft مفتوحة كعنصر مقفول فقط، لا كخيار جديد.

### P2 — عرض بيانات PR في Supervisor ناقص

- config الخاص بـrequests في supervisor.html يطلب requested_by وstatus، لكنه لا يطلب approved_by وapproved_at.
- summary الخاص بتفاصيل PR يحاول عرض approved_by وapproved_at؛ لذلك لن تصل هذه القيم من نتيجة الاستعلام الحالية.
- التطبيق لا يقدم إجراء اعتماد PR؛ PR فيه للقراءة فقط.
- Realtime في Supervisor يشترك في رؤوس المستندات، ولا يشترك في purchase_request_details أو purchase_order_details أو purchase_document_links أو purchase_status_history.

### P2 — حالة PO المرسل غير ممثلة

- لا توجد عملية SEND_PO أو RPC لإثبات إرسال PO للمورد.
- Receiver يقبل Approved وSent وPartially Received، لذلك لا يمنع غياب SEND_PO الاستلام بعد اعتماد PO.
- لكن حالة إرسال المورد، وقت الإرسال، المستلم، وإعادة الإرسال لا يمكن إثباتها من المسار الحالي.

### P2 — مسار PO المباشر يحتاج سياسة استثناء

- purchase_create_po_atomic ومسار CREATE_PO ينشئان PO مباشرًا دون PR/RFQ/Quotation.
- المسار موجود في Buyer وProduction؛ لا يُحذف دون قرار المالك.
- يجب أن يكون إما استثناءً مصرحًا بسبب/موافقة وصلاحية منفصلة، أو يُمنع إذا كانت سياسة المالك تجعل كل PO صادرًا عن PR معتمد.

## 12. الكفاءة التشغيلية والميدانية

| السيناريو | التصميم | الكود | النشر | الاختبار الحالي |
|---|---|---|---|---|
| إنشاء PR من قسم | جزئي | نموذج موجود للمشتريات فقط؛ بلا قسم/فرع | غير مثبت Runtime | غير مختبر |
| اعتماد PR | جزئي | RPC موجود؛ بوابة صلاحية غير مناسبة | Edge v44 مطابق | لا E2E |
| PR إلى RFQ | موجود | يسمح Draft ويضع PR = Converted مبكرًا | المصدر/Edge موجود | لا بيانات RFQ حالية |
| RFQ إلى عروض | موجود جزئيًا | quotation.rfq_id موجود؛ يمكن أن يكون NULL | غير مثبت Runtime | لا RFQ في Production |
| قبول العرض | موجود | حالة Accepted موجودة؛ التحويل يقبل Submitted أيضًا | غير مثبت Runtime | لا اختبار |
| تحويل العرض إلى PO | موجود | ينشئ Draft PO؛ لا يحفظ branch/terms ولا يحدّث PR | Edge v44 | لا اختبار |
| اعتماد PO | موجود | RPC وSupervisor UI؛ لا يمنع اعتماد المنشئ لنفسه | Edge v44 | لا اختبار |
| استلام PO | موجود | Receiver يقبل Approved/Sent/Partially Received ويراقب الكمية المتبقية | المصدر موجود | لا اختبار PR-originated PO اليوم |
| فاتورة PO | جزئي | Buyer selector مضبوط؛ Parent selector غير مضبوط | مصدر Parent قديم | لا E2E |
| السداد/المورد | خارج نطاق اليوم | لا تغيير | غير متحقق اليوم | غير مختبر |

لا يوجد دليل اليوم على تشغيل دورة شراء كاملة من طلب قسم إلى PO واستلام وفاتورة وسداد. لا تُحسب شاشة أو دالة على أنها عملية ميدانية مكتملة.

## 13. التخطيط والتنبؤ ومركز القرار الذكي

- لا توجد أدلة هذا اليوم على تنبؤ طلب أو احتياج صافي أو مخزون أمان أو دقة Forecast.
- لا تُمنح درجة نضج؛ الحالة UNKNOWN في هذا النطاق.
- البيانات الحالية في PR/PO لا تحتوي قسمًا وفرعًا ومصدرًا موثوقًا كافيًا لبناء تحليل احتياج حسب القسم/الفرع.
- الخطوة المستقبلية بعد إغلاق عقد PR هي ربط PR بالاحتياج الفعلي والمخزون المتاح والمحجوز والطلبيات المفتوحة، ثم قياس دقة الاقتراح مقابل الاستهلاك والاستلام الفعلي.

## 14. Benchmarking تنافسي محدود — PR/PO فقط

| المنتج | ما تثبته الوثائق الرسمية التي تمت مراجعتها | دلالته على RAWAEA |
|---|---|---|
| Microsoft Dynamics 365 | Purchase requisition workflow يدعم توجيه الطلب أو بنوده إلى مدير مقدم الطلب أو مدير القسم أو مجموعة الموافقات، ثم الانتقال إلى أمر شراء وفق إعدادات الموافقة | RAWAEA يحتاج مقدم طلب وقسمًا وصلاحية اعتماد مستقلة وسجل قرار |
| SAP S/4HANA | توجد Workflow مستقلة لطلبات الشراء وأخرى لأوامر الشراء مع تحديد الوكلاء والموافقات وإعادة العمل | يجب فصل PR approval عن PO approval وعدم استخدام صلاحية المشتريات العامة لكليهما |
| Daftra | دليل دورة المشتريات يصف طلب شراء داخليًا، اعتماده، عروض الموردين، اختيار العرض، PO، الفاتورة، الاستلام والسداد؛ وتوجد صلاحيات منفصلة | أقرب مثال موثق في المقارنة لمسار طلب داخلي عربي متصل |
| Odoo | وثائق Purchase تشرح RFQ إلى PO وضبط فاتورة المورد حسب الكمية المطلوبة أو المستلمة؛ الصفحات التي تمت مراجعتها لا تثبت وحدها Workflow داخليًا للطلبات القسمية | RAWAEA يحتاج إثبات PR الداخلي وليس مجرد وجود RFQ/PO |
| Manager.io | الوثائق الرسمية تشرح PO وربط فاتورة المورد وتتبع حالة الكميات؛ لم تثبت الصفحات التي تمت مراجعتها Workflow داخليًا لاعتماد PR | معيار جيد لربط PO والفاتورة والكمية، وليس دليلًا على PR departmental approval |
| Next ERP | لم تتم المقارنة | الاسم غير محدد؛ لا يجوز افتراض المنتج أو المورد المقصود |

مصادر رسمية:
- Microsoft Dynamics 365: https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/purchase-requisitions-workflow
- SAP Purchase Requisition Workflow: https://help.sap.com/docs/SAP_S4HANA_CLOUD/...
- SAP Purchase Order Workflow: https://help.sap.com/docs/SAP_S4HANA_CLOUD/...
- Daftra purchase cycle: https://help.daftra.com/...
- Odoo RFQ/PO and bill control: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/purchase.html
- Manager.io purchase orders: https://www.manager.io/guides/purchase-orders

الخلاصة التنافسية المحدودة: RAWAEA لديه أجزاء من سلسلة RFQ/Quotation/PO، لكنه لا يثبت بعد مستوى Dynamics/SAP/Daftra في هوية القسم، صلاحية الاعتماد، عدم تجاوز الموافقة، وإظهار أصل PO. لا يُعلن تكافؤ عالمي.

## 15. مصفوفة نضج المجالات الاثني عشر

الدرجات التالية مؤقتة لنطاق الأدلة المتاحة؛ ليست تقييمًا شاملًا لكل النظام.

| المجال | الدرجة | الثقة | السبب |
|---|---:|---|---|
| السلامة التقنية والمعمارية | 2/5 | متوسطة | Edge مركزي وCore موجودان؛ لكن RLS المباشر يفتح كتابة خارج المسار المركزي |
| تكامل التطبيقات والبيانات | 2/5 | عالية ضمن المشتريات | PR/RFQ/Quotation/PO موزعة لكن رابط المصدر وحالة PR غير متسقين |
| العمليات التجارية | 2/5 | عالية ضمن المشتريات | دورة جزئية مع تجاوز Draft/Submitted ومسار PO مباشر |
| الرقابة المالية والمحاسبية | UNKNOWN | منخفضة | لم تُراجع اليوم؛ استثناء 20 EGP من LVE727 ما زال OPEN تاريخيًا ولم يُعَد فحصه |
| المخزون وسلاسل الإمداد | 2/5 | متوسطة | Receiver يستهلك PO المعتمد والكمية المتبقية؛ لا توجد سلسلة PR-originated PO مثبتة اليوم |
| التوزيع والعمل الميداني | UNKNOWN | منخفضة | خارج نطاق الفحص |
| التخطيط والتنبؤ | UNKNOWN | منخفضة | لا قياس Forecast أو Actual |
| التقارير وBI | UNKNOWN | منخفضة | لم تُفحص اليوم |
| الأمان والصلاحيات والتدقيق | 1/5 | عالية | DML مباشر على مستندات المشتريات وسجل التدقيق بنطاق الشركة فقط |
| الأداء والاستقرار والتوسع | UNKNOWN | منخفضة | لا Runtime أو قياسات Latency اليوم |
| تجربة المستخدم والإنتاجية | 2/5 | عالية ضمن المشتريات | Parent وBuyer يختلفان في شروط PO؛ بيانات القسم ناقصة |
| الجاهزية التشغيلية والتنافسية | 1/5 | متوسطة | P0 أمني وP1 دورة PR/PO يمنعان اعتماد المسار للقسم |

لا يوجد متوسط إجمالي؛ المجالات غير المفحوصة بقيت UNKNOWN.

## 16. خريطة النظام الأم والقلب المركزي والعقود

- النظام الأم: companies/company-1/main.html، وفيه RW_PurchaseGold وتبويبات دورة المشتريات ونماذج PR/RFQ/Quotation/PO والفاتورة.
- Core: companies/company-1/core.js، blob 2b2211a...؛ لم يتغير في commits الـ15 الأخيرة.
- Buyer PWA: companies/company-1/purchasing/buyer.html، يستخدم save-purchase-order للعمليات ويحتوي قراءة PR/PO والفواتير.
- Supervisor PWA: companies/company-1/purchasing/supervisor.html، مخصص لصلاحية purchases_supervisor ويعتمد على القراءة المباشرة وAPPROVE_PO.
- Receiver: companies/company-1/warehouse/receiver.html، يستهلك PO بحالات Approved/Sent/Partially Received مع فحص الكمية المتبقية.
- Edge المركزي: supabase/functions/save-purchase-order/index.ts، Version 44، وهو مسار CREATE_REQUEST/APPROVE_REQUEST/CREATE_RFQ/CONVERT_QUOTATION_TO_PO/CREATE_PO/APPROVE_PO/GET_DATA.
- مصدر الحقيقة الحالي:
  - PR header: purchase_requests.
  - PR lines: purchase_request_details.
  - RFQ: purchase_rfqs.request_id وpurchase_rfq_details.
  - Supplier quotation: purchase_quotations.rfq_id.
  - PO header/lines: purchase_orders وpurchase_order_details.
  - Link graph: purchase_document_links.
  - Status history: purchase_status_history.
  - إعدادات الطلب: purchase_settings.
  - مصدر القسم غير جاهز: hr_departments وhr_employee_assignments وemployee_profiles فارغة.
- العلاقة الممكنة حاليًا: PR → RFQ عبر request_id/رابط المستند، RFQ → Quotation عبر rfq_id، Quotation → PO عبر purchase_document_links. لكنها ليست ظاهرة في PO list ولا يوجد request_id مباشر في PO.

## 17. مصفوفة المزامنة وRealtime

| التطبيق | الآلية الظاهرة في المصدر | النقص |
|---|---|---|
| Parent | Supabase Realtime على رؤوس purchase_requests/RFQs/quotations/PO/invoices | لا اشتراك في request/order details أو document_links أو status_history |
| Buyer | Realtime على PR/PR details/RFQ/quote/PO/details/document_links/status_history، مع reconcile دوري يقارب 15 ثانية | لا قياس وصول فعلي أو Latency |
| Supervisor | Realtime على رؤوس المستندات، مع reconcile يقارب 60 ثانية | لا اشتراك في details أو links أو status_history؛ PR approval metadata غير مكتمل |
| Receiver | Realtime على PO والاستلام وتفاصيل الاستلام | لا اختبار متزامن بعد تغيير PR/PO اليوم |

وجود الاشتراك لا يثبت وصول الحدث؛ لم تُقَس latency ولم يُختبر reconnect أو concurrent updates.

## 18. جاهزية المساعد واستلام شعلة التطوير

**READY WITH LIMITATIONS**
- نقطة الاستئناف مستعادة من LVE727.
- CURRENT_STATE والدستور والتقرير السابق قُرئت كاملة.
- Source وSupabase contracts وEdge v44 والبيانات ذات الصلة تم فحصها.
- تم تحديد الملفات والجداول والوظائف والـRLS والـroles اللازمة للخطوة التالية.
- يمكن إعداد Change Set دقيق ومراجعته.
- لا يمكن تنفيذ أي تعديل في main/Buyer/Supervisor أو Production قبل اعتماد المالك.
- لا يوجد Browser مصادق عليه ولا Staging تم التحقق منه؛ لذلك Runtime/E2E غير متاحين في هذا التشغيل.

## 19. الالتزام بالدستور التشغيلي الدائم

- الملف المقروء كاملًا: doc/Draft/Reprots/الدستور التشغيلي الدائم.md، SHA 3a6b1e220af8509e314e94df76563bbc6f84910d.
- طُبقت بوابة عدم الأثر: PR/RFQ/PO/approval لا تنشئ مخزونًا أو خزينة أو قيدًا بمجرد إنشائها أو اعتمادها؛ الاستلام الفعلي فقط يمر بمسار المخزون المركزي.
- طُبقت حماية RLS/ACL: لم تُجرّب أي كتابة مباشرة ولم تُستخدم هوية أو صلاحية بديلة.
- طُبقت بوابة موافقة المالك: لم يُعدّل أي ملف تشغيلي ولم تُنفذ هجرة.
- طُبق توجيه المالك الأحدث بشأن عدم اختبار Production؛ لا بيانات QA جديدة ولا معاملات اختبار.
- التعارض التاريخي مع §6.4 موثق في القسم 4، وتم اتباع التوجيه الأحدث الأكثر حماية.

## 20. المخاطر والاعتماديات والقرارات المطلوبة من المالك

1. اعتماد P0: سحب DML من المستخدمين العاديين على PR/RFQ/Quotation/Document Links/Status History، بعد مسح جميع المستهلكين للتأكد من أن الكتابة تمر عبر RPC/Edge.
2. تحديد صاحب اعتماد PR: مدير القسم، مشرف المشتريات، أو مسار موافقات متعدد المراحل. لا توجد صلاحية مستقلة حاليًا.
3. اعتماد مصدر القسم والفرع: استخدام HR departments وemployee assignments بعد إدخال بياناتها، مع branch_id محفوظ على PR.
4. تحديد سياسة PO المباشر: استثناء موثق ومقيد، أم منع وإنشاء PO فقط من PR/Quotation.
5. اعتماد معنى الحالات: RFQCreated/Sourcing بعد RFQ؛ PartiallyOrdered/Ordered بعد PO فعلي؛ لا تستخدم Converted قبل إنشاء PO.
6. اعتماد الفصل بين منشئ PO ومعتمده؛ current RPC يسمح purchases وpurchases_supervisor ولا يمنع المنشئ من اعتماد أمره.
7. تأكيد ما إذا كان مودال Parent المقصود ضمن قاعدة «PO غير المستلم فقط»؛ مصدر Parent الحالي يخالفها قطعًا، بينما Buyer source يطبقها.
8. Staging غير معاد التحقق منه؛ لا يبدأ E2E قبل إثبات بيئة معزولة صالحة.

## 21. الخطوة التالية الواحدة ذات الأولوية

**CS-PRPO-728-A — إغلاق ثغرة DML/RLS في مستندات المشتريات وسجل التدقيق، ثم اعتماد عقد PR القسم/الفرع والصلاحيات قبل تعديل الواجهات.**

السبب: الثغرة الحالية تسمح بتجاوز المسارات المركزية وتعديل سجل التدقيق، وهي أخطر من اختلاف العرض. الملفات/العقود المتأثرة: سياسات وجداول purchase_requests وpurchase_request_details وpurchase_rfqs وpurchase_rfq_details وpurchase_quotations وpurchase_document_links وpurchase_status_history، مع Edge save-purchase-order وParent/Buyer/Supervisor. لا تُنفذ قبل Change Set معتمد وخطة تراجع ومسح المستهلكين.

### ملحق — Change Set المقترح (لم يُطبق)

1. **RLS/GRANT:** سحب INSERT/UPDATE/DELETE من anon وauthenticated على الجداول أعلاه، وإبقاء SELECT وفق نطاق الشركة/القسم؛ الإبقاء على الكتابة عبر service_role/SECURITY DEFINER RPC فقط. قبل الهجرة: repository-wide scan لكل direct insert/update/delete لهذه الجداول.
2. **PR identity:** إضافة requested_by_user_id وdepartment_id وbranch_id، مع FK/تحقق شركة، واشتقاق القسم من تعيين HR نشط أو اختيار مصرح به. لا يُقبل إنشاء PR بلا قسم/فرع صالحين بعد اعتماد سياسة المالك.
3. **PR authorization:** فصل صلاحية إنشاء PR عن purchases، وصلاحية اعتماد PR عن صلاحية الشراء. نطاق القراءة يكون طلباتي/طلبات قسمي/كل الشركة حسب الدور. منع مقدم الطلب من اعتماد طلبه إلا Owner override مسجل.
4. **PR status:** دالة purchase_create_rfq_atomic تشترط Approved فقط، ولا تغيّر PR إلى Converted عند إنشاء RFQ؛ تستخدم حالة RFQCreated/Sourcing. حالة Ordered/PartiallyOrdered لا تحدث إلا بعد إنشاء PO مرتبط.
5. **Quotation conversion:** purchase_convert_quotation_to_po_atomic يقبل Accepted فقط، ويتوقف عن كتابة accepted_by/accepted_at عند التحويل؛ يتحقق من سلسلة PR/RFQ أو من استثناء معتمد.
6. **PO source:** عند التحويل، إنشاء رابط PR→PO إضافة إلى Quote→PO، وتحديث حالة PR، ونقل branch_id وexpected_delivery_date وpayment_terms من مصدر موثوق.
7. **PO approval:** بوابة موحدة تعتمد purchases_supervisor أو Owner override، وتمنع created_by من اعتماد PO نفسه؛ توحيد Parent وSupervisor على نفس السياسة.
8. **Direct PO:** إما إبقاؤه كاستثناء يتطلب سببًا وصلاحية وموافقة، أو تعطيله إذا اعتمد المالك أن كل PO يجب أن يصدر من PR.
9. **UI:** Parent وBuyer يعرضان PR منفصلًا عن PO مع اسم مقدم الطلب والقسم والفرع وروابط RFQ/Quote/PO. Parent createRFQ يقبل Approved فقط. Parent تحويل العرض يقبل Accepted فقط. Parent createInvoice يطابق Buyer eligibility.
10. **Supervisor:** إضافة approved_by وapproved_at إلى SELECT الخاص بطلبات PR؛ وإضافة details/document_links/status_history إلى آلية التحديث أو reconcile.
11. **Acceptance tests في بيئة معزولة فقط:** مستخدم قسم ينشئ PR ويرى نطاقه؛ لا يستطيع تعديل PR آخر أو سجل التدقيق؛ Draft لا يتحول إلى RFQ؛ Submitted quote لا يتحول إلى PO؛ Accepted quote فقط ينتج PO؛ منشئ PO لا يعتمده؛ PO يحفظ القسم/الفرع والمصدر؛ Parent/Buyer يعرضان نفس PO eligibility؛ لا أثر مخزون/مالي قبل الاستلام؛ Realtime/reconnect؛ reload persistence؛ idempotency.
12. **Rollback:** إعادة السياسات/GRANT إلى النسخة السابقة فقط إذا فشل اختبار القراءة/الكتابة المعتمد، مع إبقاء جميع سجلات الأعمال وعدم حذف أي مستند أو أثر تدقيق.

### مراجع المشروع

- CURRENT_STATE.md: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CURRENT_STATE.md
- الدستور التشغيلي الدائم: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/الدستور%20التشغيلي%20الدائم.md
- Report569: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report569_BUYER_PURCHASING_WORKFLOW_FORENSIC_AUDIT_20261031.md
- Report571: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report571_BUYER_PURCHASING_INTEGRATION_EXECUTION_20261101.md
- Report599: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report599_CTO_PROCUREMENT_RECEIVING_INVOICE_PAYMENT_ACCOUNTING_FLOW_20261103.md
- Report633: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report633_BUYER_PO_SUPPLIER_INVOICE_SEPARATION_20261105.md
- Report727: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report727_PURCHASE_RECEIPT_IDEMPOTENCY_AND_PARENT_INVOICE_STATE_CLOSURE_20261116.md
- Parent main: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
- Buyer: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/purchasing/buyer.html
- Purchasing Supervisor: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/purchasing/supervisor.html
- save-purchase-order: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/supabase/functions/save-purchase-order/index.ts
