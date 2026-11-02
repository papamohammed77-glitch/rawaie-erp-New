# RAWAEA ERP — مراجعة التفويض الخادمي وأثر المخزون عبر دورة التشغيل

**Checkpoint:** LVE-2026-11-03-590  
**التاريخ:** 2026-11-03  
**الحالة:** CRITICAL CROSS-MODULE AUTHORIZATION & INVENTORY CONTRACT FINDINGS / READ-ONLY / NOT CLOSED  
**نقطة البداية:** LVE-589 — تقرير التهيئة وإعادة التحقق المستقل.

---

## 1. الهدف والنطاق

بعد استعادة الهيكل العام للمشروع، جرى توسيع التحقق من Buyer إلى مسارات التشغيل ذات الأثر الأعلى: Runsheet creation/append، Picking، Loading، Receiving، Delivery، Return، Unloading، وDaily Settlement.

الهدف ليس إعادة فتح كل تقرير تاريخي، بل اختبار عقدين حاكمين:
1. هل كل Edge/RPC يتحقق من صلاحية المستخدم وتعيينه على العملية على الخادم، أم يعتمد على إخفاء الشاشة/التطبيق؟
2. هل أحداث التسليم والمرتجعات تنقل الكمية بين فروع المخزون بطريقة تحفظ التوازن بين المخزن والمركبة والعميل؟

لم تُنفذ أي كتابة أو عملية تشغيلية في Production.

---

## 2. قاعدة البداية والأدلة

- CURRENT_STATE عند بداية الجولة: LVE-589.
- التطبيق التشغيلي: erp-frontend/main، HEAD 7a14d51b4d4c225240b215879abf6b77b99888d3.
- Parent main.html blob: 53b5a9e9d0433a785c3d5471a9c0d68c25497882.
- Production project: fiilmooggumokxanwiyx.
- تم جلب Edge versions المنشورة مباشرة، وقراءة RPC definitions من PostgreSQL، وفحص triggers على orders/order_details/run_sheet_details/runsheets، وفحص run sheets وstock_branches وinventory_log بقراءة فقط.

---

## 3. نتائج التفويض الخادمي — CONFIRMED

### 3.1 المسارات التي تطبق فحص صلاحية فعليًا

أمثلة صحيحة يجب الحفاظ عليها:

- start-picking v35 وcomplete-picking v18 يتحققان من صلاحية warehouse على الخادم قبل تنفيذ العملية.
- start-return وcomplete-return يطبقان فحص صلاحية warehouse.
- save-sales-invoice v19 يبني effective permissions من user permissions وrole permissions وrole_permissions، ثم يتحقق من صلاحية المصدر: pos أو orders أو van-sales أو غيرها بحسب العملية.
- save-purchase-order v22 يحدد operation ويطبق الصلاحية المناسبة لكل operation.
- delivery_supervisor_assign_deliverer_atomic يتحقق من delivery_supervisor أو fleet.manage، ثم يتحقق من أن الموظف المستهدف يملك delivery permission.

هذه أمثلة على العقد المطلوب: هوية موثقة + شركة + صلاحية تشغيلية + ملكية/تعيين + حالة العملية + RPC ذري.

### 3.2 المسارات التي لا تفرض صلاحية تشغيلية على الخادم

| المسار | النسخة المنشورة | ما تم التحقق منه | الخطر |
|---|---:|---|---|
| create-runsheet | v26 | Edge يتحقق من JWT ووجود المستخدم والشركة؛ RPC create_runsheet_atomic لا يفحص permission | مستخدم داخل الشركة يمكنه طلب إنشاء Runsheet خارج صلاحية الواجهة |
| append-to-runsheet | v8 | Edge/RPC يتحققان من الشركة والحالة والطلبات، لا من effective permission | إضافة طلبات إلى Runsheet دون تفويض خادمي |
| start-loading | v6 | Edge يتحقق من المستخدم والشركة؛ start_runsheet_loading لا يفحص warehouse/loader permission | بدء تحميل أي Runsheet مؤهل من مستخدم لا يملك دور التحميل |
| complete-loading | v11 | Edge/RPC لا يتحققان من أن p_user_email هو loader_id ولا من صلاحية التحميل | إتمام تحميل Runsheet بواسطة مستخدم آخر |
| unload-runsheet | v6 | Edge/RPC لا يتحققان من unloader assignment أو warehouse permission | تنفيذ Unloading دون تفويض خادمي |
| receive-purchase | v12 | JWT + company membership فقط؛ لا effective receiving/purchasing permission | استلام PO من مستخدم لا يملك صلاحية الاستلام |
| complete-delivery | v4 | يتحقق من الشركة وحالة Runsheet، لا من deliverer_id أو delivery permission | إغلاق Runsheet أثناء التسليم من مستخدم آخر |
| complete-order-delivery | v14 | Edge لا يفحص deliverer assignment؛ complete_order_delivery_atomic لا يطابق p_user_email مع deliverer_id | تعديل كميات delivered/refused لأي Order ضمن الشركة |
| save-daily-settlement | v4 | JWT + company membership + operation_id؛ لا يفحص driver assignment أو settlement permission في Edge/RPC | ترحيل تسوية وإغلاق Runsheet من مستخدم غير مفوض |

هذه نتائج Source/Backend contract، وليست اختبار استغلال HTTP. لم أرسل طلبات كتابة لمستخدم غير مصرح به.

### 3.3 لماذا إخفاء التطبيق ليس حماية

app.html يوجه الموظف وفق active roles/permissions، وParent main.html يخفي الشاشات حسب permissionMap. هذه طبقة UX وليست حدًا أمنيًا. Edge Functions تستخدم service_role وتتجاوز RLS، ولذلك يجب أن تفرض هي أو RPC ذري موثوق صلاحية المستخدم وتعيينه بنفسها.

وجود JWT صالح وcompany_id صحيح لا يعني أن المستخدم مخول لبدء تحميل أو استلام PO أو تسليم طلب أو إغلاق تسوية.

### 3.4 تفصيل مسارات التسليم

- start-delivery v8 يتحقق من أن deliverer_id يساوي المستخدم الحالي قبل بدء التسليم.
- complete-delivery v4 لا يعيد فحص deliverer_id.
- complete-order-delivery v14 يستدعي complete_order_delivery_atomic، لكن RPC لا يفرض أن p_user_email هو deliverer_id ولا يتحقق من delivery permission.
- driver.html يعرض Runsheets المعيّنة عبر deliverer_id، ثم يستدعي complete-order-delivery وcomplete-delivery.
- إذن فحص التعيين موجود في بداية العملية ولا يُعاد عند إتمامها؛ يمكن تجاوز واجهة المستخدم باستدعاء Endpoint الإتمام مباشرة.

### 3.5 تعارض cancel-delivery مع تعيين السائق

- delivery_supervisor_assign_deliverer_atomic يكتب deliverer_id.
- driver.html يقرأ Runsheets عبر deliverer_id.
- start-delivery يتحقق من deliverer_id.
- cancel-delivery v5 يتحقق من driver_id بدل deliverer_id.

هذا تعارض مصدر/عقد مؤكد. لم يجر اختبار إلغاء فعلي؛ لذلك فشل الإلغاء وقت التشغيل UNVERIFIED. كما أن cancel-delivery يجري عدة تحديثات مباشرة متتابعة دون معاملة ذرية واحدة، ولا يتحقق من أخطاء كل تحديث، ويعيد ضبط qty_delivered في run_sheet_details على مستوى Runsheet. لا تنفذ هذا المسار على بيانات حقيقية قبل مراجعة كاملة.

---

## 4. نتائج أثر المخزون — CONFIRMED SOURCE CONTRACT + QA DATA EVIDENCE

### 4.1 مسار Loading

complete_runsheet_loading:
- يتحقق من حالة Runsheet وloading_cycle_id والكمية.
- يستدعي post_stock_movement لنقل الكمية من branch المخزن إلى mobile branch للمركبة.
- لا يثبت أن المستخدم الحالي هو loader_id ولا يتحقق من warehouse permission داخل RPC.

هذا يثبت أن تحميل البضاعة يرفع رصيد المركبة ويخفض رصيد المخزن.

### 4.2 مسار التسليم

complete_order_delivery_atomic:
- يحدّث order_details.qty_delivered وqty_refused.
- يحدّث run_sheet_details.qty_delivered وdriver_liability.
- يحدّث حالة الطلب.
- لا يستدعي post_stock_movement.
- لا يوجد trigger على orders أو order_details أو run_sheet_details ينفذ حركة مخزون عند تحديث qty_delivered.

complete-delivery:
- يحدّث حالة Runsheet إلى Delivered ويغلق delivery timestamps.
- لا ينفذ حركة مخزون ولا يعيد التحقق من تسليم كل الطلبات أو من تعيين deliverer.

إذًا لا يوجد في المسار الحالي الذي فُحص خصم مثبت من mobile branch عند تسليم البضاعة للعميل.

### 4.3 مسار المرتجعات

complete_return_atomic:
- يضيف الكمية المرتجعة إلى main branch عبر post_stock_movement.
- يستدعي الحركة بمصدر branch فارغ/NULL ووجهة main branch.
- لا يخصم الكمية المرتجعة من mobile branch.

هذا قد يضيف البضاعة إلى المخزن الرئيسي مع إبقائها في رصيد المركبة، إذا كانت mobile branch تمثل المخزون المادي الموجود بالسيارة.

### 4.4 مسار Unloading

complete_runsheet_unloading ينقل qty_loaded من mobile branch إلى main branch عندما تكون Runsheet في حالة Loaded. هذا المسار لا يمثل بديلًا عن خصم الكمية التي تم تسليمها للعميل أو عن خصم المرتجعات من السيارة بعد حالة Delivered/Returned.

### 4.5 عدم وجود Trigger تعويضي

تم فحص triggers الحالية على:
- orders
- order_details
- run_sheet_details
- runsheets

لم يظهر Trigger ينفذ حركة مخزون عند تحديث qty_delivered أو qty_returned أو تغيير حالة الطلب إلى Delivered/Returned. لذلك لا يوجد دليل على تعويض حركة المخزون من Trigger خفي في هذه الجداول.

### 4.6 Production QA records التي تكشف الفجوة

البيانات الحالية تحمل مؤشرات QA واضحة، فلا تُعامل كخسارة مخزون حقيقية ولا تُحذف:

- Runsheet RS-1: status=Delivered، إجمالي qty_loaded=13 وإجمالي qty_delivered=13.
- المركبة المرتبطة بها لها mobile branch VAN-CHV-2025-01، وما زال مجموع رصيد الأصناف الخمسة المرتبطة 13.
- سجل inventory_log المرتبط يُظهر Loading وUnloading، ولا يظهر Delivery/VanSale movement يخصم الـ13 بعد التسليم.
- Runsheet RS-2: status=Returned، qty_loaded=6 وqty_delivered=1 وqty_returned=5.
- mobile branch VAN-VHL-0422 ما زال يحمل رصيدًا إجماليًا 6 في الأصناف المرتبطة.
- inventory_log يسجل SalesReturn إلى main branch بمصدر NULL، ولا يثبت خصم الخمسة من mobile branch في حدث الإرجاع.
- movement types الحالية في inventory_log: DirectReturn، InventoryIncrease، Loading، POSSale، PurchaseIn، SalesReturn، TransferOut، Unloading، VoidInvoice. لا يظهر Delivery أو VanSale movement type.

هذه QA evidence تتفق مع فجوة المصدر: تسليم العميل لا يخصم vehicle stock، وإرجاع العميل لا يخصم vehicle stock قبل إضافة المرتجع إلى main branch.

**الحكم:** فجوة حركة المخزون في Source/DB contract CONFIRMED. أثرها على التشغيل الحقيقي UNVERIFIED لأن السجلات الحالية QA ولم يُنفذ E2E آمن. يجب عدم إجراء أي تعديل أرصدة يدوي أو إعادة ترحيل لهذه السجلات.

---

## 5. Idempotency — التمييز بين إعادة المحاولة وعملية جديدة

- receive_purchase_atomic عند غياب operation_id يستخدم Edge مفتاحًا deterministic مبنيًا على المستخدم والشركة وPO والـitems.
- complete_order_delivery_atomic يستخدم مفتاحًا deterministic مبنيًا على المستخدم/الشركة/الـRunsheet/الطلب والـitems.
- هذا يحمي من تكرار نفس payload عند إعادة إرسالها، لكنه قد يمنع عملية جزئية جديدة مشروعة إذا كانت نفس الأصناف والكميات تُستلم أو تُسلّم مرة أخرى في وقت لاحق.
- يجب أن يكون operation_id فريدًا لكل محاولة عمل منطقية، وأن يحتفظ العميل بنفس المفتاح عند retry لنفس المحاولة، وأن ينشئ مفتاحًا جديدًا لعملية جديدة مقصودة.
- complete_runsheet_loading يستخدم loading_cycle_id، وهو مفتاح دورة تحميل مستقرة.
- save-daily-settlement يتطلب operation_id، وواجهة Van Sales تحتفظ به في localStorage قبل إعادة المحاولة.

لا يوجد اختبار Runtime لتكرار طلب أو لعملية partial receipt/delivery ثانية؛ لذلك الأثر العملي لهذه المفارقة UNVERIFIED.

---

## 6. مصفوفة الحالة عبر الطبقات

| المجال | Git/Source | Production DB/RPC | Runtime | Business data |
|---|---|---|---|---|
| Picking | فحص warehouse permission موجود في Edge | لم يظهر نقص صلاحية في المسار الذي فُحص | UNVERIFIED | لم تنفذ حركة |
| Loading | Edge/RPC لا يفرضان loader permission/assignment | RPC SECURITY DEFINER بلا فحص تعيين | UNVERIFIED | أثر الحركة غير مختبر |
| Receiving | receive-purchase بلا effective permission | RPC service_role-only لكنه لا يعوض غياب فحص Edge | UNVERIFIED | لا استلام جديد |
| Delivery start | يتحقق من deliverer_id | assignment موجود | UNVERIFIED | لا أثر جديد |
| Delivery complete | لا يعيد فحص deliverer_id | RPC لا يطابق p_user_email بالتعيين | UNVERIFIED | QA stock discrepancy ظاهر |
| Return | واجهة تستدعي RPC مركزيًا | SalesReturn يزيد main من NULL ولا يخصم vehicle | UNVERIFIED | QA fixture يظهر vehicle balance باقٍ |
| Unloading | لا فحص unloader permission | RPC لا يطابق المستخدم بالتعيين | UNVERIFIED | لا أثر جديد |
| Daily settlement | operation_id موجود في UI | لا فحص driver/settlement permission في Edge/RPC | UNVERIFIED | لا تسوية جديدة |

---

## 7. ما تم فعليًا

- فحص نسخ Edge المنشورة مباشرة: start-picking v35، complete-picking v18، start-loading v6، complete-loading v11، unload-runsheet v6، receive-purchase v12، start-delivery v8، complete-delivery v4، complete-order-delivery v14، cancel-delivery v5، save-daily-settlement v4.
- فحص تعريفات RPCs: create_runsheet_atomic، append_orders_to_runsheet_atomic، start_runsheet_loading، complete_runsheet_loading، complete_runsheet_unloading، complete_order_delivery_atomic، complete_return_atomic، post_daily_settlement_atomic، delivery_supervisor_assign_deliverer_atomic.
- فحص triggers على جداول دورة الطلب والرانشيت.
- فحص سجلات RS-1 وRS-2 والـmobile branches وinventory_log بقراءة فقط.
- فحص مستهلكات Edge ذات الصلة في driver.html وreceiver.html وloader/unloader وvan-sales وdelivery supervisor.

### Mutation Ledger

- Git source: لا تعديل.
- Supabase schema/data: SELECT فقط.
- Edge Functions: لا تعديل/نشر.
- Cloudflare: لا نشر.
- PR #10: لا دمج ولا تعديل.
- لا حذف أو تنظيف لبيانات QA.
- لا إنشاء سجلات اختبار.

---

## 8. ما لم يتم

1. لم أرسل أي Edge HTTP request بصفة مستخدم غير مصرح به؛ تجنبًا لتغيير بيانات حقيقية.
2. لم أختبر عملية تحميل أو تسليم أو إرجاع أو تسوية فعلية.
3. لم أثبت served artifact أو Console/Network.
4. لم أنفذ أي إصلاح في Production.
5. لم أحسم إذا كان vehicle branch مصممًا ليبقى يحمل الكميات بعد التسليم؛ تصميم المخزون الحالي وبيانات QA يشيران إلى خلاف ذلك، ويحتاج قرار مالك واضح.
6. لم أراجع جميع Edge Functions الـ100؛ هذا فحص للمسارات التشغيلية الأعلى أثرًا فقط.

---

## 9. الأولوية التنفيذية التالية

**لا تبدأ بدمج Buyer PR. الأولوية الآن إعداد حزمة مراجعة مالك لمسار Warehouse/Delivery/Settlement، بالتوازي مع حزمة Procurement، لأن فجوات التفويض وأثر vehicle stock قد تمس المخزون والتسوية مباشرة.**

الحزمة يجب أن تتضمن:
1. effective permission + assignment checks داخل start/complete loading، receiving، unloading، delivery completion، order delivery، daily settlement، runsheet creation/append.
2. إعادة فحص deliverer_id مقابل driver_id في cancel-delivery.
3. حركة مخزون صريحة: خصم qty_delivered من vehicle branch، ونقل qty_returned من vehicle branch إلى main branch مرة واحدة، مع منع الازدواجية.
4. فصل إلغاء التسليم عن عكس المخزون والدفاتر، واستخدام RPC ذري واحد لكل business operation.
5. operation_id لكل محاولة منطقية، ثابت عند retry وفريد عند العملية الجديدة.
6. اختبارات acceptance على fixture معزول، ومقارنة stock_branches مع inventory_log قبل/بعد، دون لمس QA fixtures الحالية.

كل ذلك يظل مقترحًا حتى موافقة المالك الصريحة وفق Master §77.2. لا تنفذ DDL أو DML أو Edge deployment الآن.

---

## 10. الحكم

**LVE-590 يثبت أن الفحص لم يعد Buyer-only: توجد فجوات تفويض خادمي متقاطعة في مسارات التحميل والاستلام والتسليم والتسوية، وفجوة في عقد حركة vehicle stock.**

لا توجد عملية إصلاح أو إغلاق في هذه الجولة.  
الحالة: CRITICAL FINDINGS CONFIRMED AT SOURCE/DB CONTRACT / RUNTIME UNVERIFIED / NOT CLOSED.  
مرحلة التهيئة العامة للمشروع ما زالت IN PROGRESS؛ لا تُعلن «تم الفهم الكامل للمشروع».
