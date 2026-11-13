# Report712 — تدقيق فجوات سجل العمليات المكتملة والصور والتكامل في المخزن الشامل
**التاريخ:** 2026-11-13 (Africa/Cairo)  
**نقطة الاستئناف:** LVE-2026-11-12-711  
**الحكم:** READY WITH LIMITATIONS — اكتُشفت فجوات P1 مؤكدة في سجل العمليات المكتملة؛ إصلاح ملفات التطبيقات التشغيلية ينتظر تطبيق المالك وفق الدستور.  
**النطاق:** Warehouse Hub / Picker / Loader / Unloader / Returns / Counter / Vouchers / Supabase Production read-only / CI coverage.

## 1. نقطة البداية والحوكمة
- تمت قراءة CURRENT_STATE.md أولًا، ثم الدستور التشغيلي الدائم كاملًا قبل فحص المصدر أو قاعدة البيانات.
- CURRENT_STATE blob وقت القراءة: `6656bcff937d9e3974c3f87556c30b51bd379dac`.
- الدستور الدائم blob: `3a6b1e220af8509e314e94df76563bbc6f84910d`.
- آخر نقطة مثبتة: LVE-2026-11-12-711 / Report711.
- المستودع التشغيلي: `papamohammed77-glitch/erp-frontend`, الفرع `main`, HEAD الحالي المؤكد من سجل commits: `903a1fe22c3ec2f8f4f7a3ffeb45d1d8025e306d`. لا يوجد commit تشغيلي أحدث.
- ملف المخزن الشامل: `companies/company-1/warehouse/warehouse.html`, blob `41bab8f092dbb5ac1adf32ef34d5feaf92b8dc6e`, 637,494 bytes.
- الملفات الأصلية: picker `312b5e387daf2248737749c246c0174095535eac`; loader `89aea6635771f1a3328e82a456f3ecfe9ee02acd`; returns `39755507bc01331135a1640af5a87a22051ee3e7`; unloader `c0a5ac89012e9e612b37dbcfd4e9334adf5c16b9`.
- Workflow blob `2984414dfc0a5b9e2fa1118adaa46c71c2a92c80`; CI run `43276131519`, job `131384896689`, conclusion SUCCESS. الاختبارات محلية بمصادر/Mocks اصطناعية، وليست Production Runtime.

## 2. CONFIRMED — أخطاء سجل المكتملة (P1)

### 2.1 Picker: السجل مربوط بالحالة الحالية لا بحدث إتمام التحضير
- في الأصل `picker.html`، الدالة `renderCompletedTab` تستعلم من `runsheets` بشرط `status='Picked'` و`picker_id=current user`.
- النسخة المضمّنة في `warehouse.html` تحمل الشرط نفسه.
- Production يحتوي 4 عمليات `complete_runsheet_picking` بحالة `completed` في `erp_operation_registry`.
- لكن الرانشيتات الحالية التي تم تحضيرها انتقلت لاحقًا: RS-1 حالتها Delivered وRS-2 Returned. وبالتالي لا تعودان مطابقتين لشرط `status='Picked'`، فتختفيان من سجل التحضير المكتمل رغم وجود أحداث إتمام فعلية محفوظة.
- هذا خطأ تصميمي مؤكد في الأصل والنسخة المضمّنة، وليس اختلافًا بين النسختين.

### 2.2 Loader: السجل يختفي بعد التفريغ/الانتقال اللاحق
- في الأصل `loader.html`، الدالة `renderCompletedTab` تستعلم عن `runsheets.status='Loaded'` و`loader_id=current user`.
- النسخة المضمّنة تحمل الشرط نفسه.
- Production يحتوي 5 عمليات `complete_runsheet_loading` بحالة `completed` في `erp_operation_registry`.
- إجراء `public.complete_runsheet_unloading(p_company_id,p_runsheet_code,p_user_email)` يعيد الرانشيت من Loaded إلى Picked، ويمسح `loader_start` و`loader_end` و`loading_cycle_id`. وبعد تقدم الرانشيت إلى Delivered أو Returned لن تطابق سجل Loader شرط Loaded.
- لذلك سجل التحميل ليس سجلًا تاريخيًا؛ إنه مجرد استعلام عن الحالة الراهنة، ويُسقط عمليات تحميل مكتملة سابقًا. هذا خلل P1 مؤكد.

### 2.3 Unloader: مصدر سجل المكتملة غير صحيح
- في الأصل `unloader.html`، الدالة `loadCompleted` تقرأ `stock_vouchers` بشرط `type='Unloading'` و`status='Completed'`.
- النسخة المضمّنة في `warehouse.html` تحمل الاستعلام نفسه.
- Production: `stock_vouchers=0` و`stock_voucher_details=0`.
- عقد Production الفعلي لدالة `complete_runsheet_unloading` لا ينشئ `stock_vouchers`. بل يسجل حدثًا في `erp_operation_registry` من النوع `complete_runsheet_unloading`، ويستدعي `post_stock_movement(...,'Unloading',...)`، ثم يغيّر حالة الرانشيت إلى Picked.
- لذلك تبويب Unloader المكتملة يقرأ كيانًا لا تنتجه دورة التفريغ؛ وسيبقى فارغًا حتى بعد نجاح عمليات التفريغ. هذا خلل P1 مؤكد في الأصل والنسخة المضمّنة.
- لا يجوز استخدام كل صفوف `inventory_log.movement_type='Unloading'` بديلًا مباشرًا؛ السجلات الحالية البالغ عددها 16 مرتبطة بأحداث Reopen/عكس التحميل، وليست دليلًا على 16 عملية تفريغ نهائية. سجل الإتمام المرجعي هو `erp_operation_registry` بنوع العملية المذكور.

### 2.4 ما يثبته مصدر الحقيقة التاريخي
- `erp_operation_registry` يحتوي 4 أحداث Picking مكتملة و5 أحداث Loading مكتملة.
- سياسة RLS على `erp_operation_registry` تسمح للمستخدم المصادق بقراءة سجلات شركته فقط؛ امتياز SELECT لـauthenticated موجود، وسياسة `erp_operation_registry_select_company` تقيد `company_id` بالشركة الحالية.
- `request_payload` يحتوي `runsheet_code` و`user_email`، و`response_payload` يحتوي نتيجة العملية؛ وهو مصدر تاريخي مناسب للقراءة بعد التحقق من عقد العرض والصلاحيات.
- يجب أن يظل زر إعادة الفتح مقيدًا بالحالة الحالية وبقواعد RPC؛ عرض حدث مكتمل تاريخيًا لا يعني أن العملية قابلة لإعادة الفتح الآن.

## 3. CONFIRMED — بيانات Production الحالية ذات الصلة
### Runsheets
| الرانشيت | الحالة الحالية | الأسطر | المطلوب | محضّر | محمّل | مسلّم | مرتجع |
|---|---|---:|---:|---:|---:|---:|---:|
| RS-1 | Delivered | 5 | 14 | 13 | 13 | 13 | 0 |
| RS-2 | Returned | 7 | 9 | 6 | 6 | 1 | 5 |
| RS-3 | Open | 4 | 6 | 0 | 0 | 0 | 0 |
| RS-4 | Open | 3 | 3 | 0 | 0 | 0 | 0 |

- RS-1 وRS-2 يثبتان عمليًا أن سجل المكتملة لا يجوز ربطه حصريًا بالحالة الحالية للرانشيت.
- RS-3: الصنف 1010 متاح 1 مقابل طلب 2؛ الصنف ITM-20260939 لا يملك صف `stock_branches` في الفرع الرئيسي.
- RS-4: الصنف ITM-20260938 لا يملك صف `stock_branches` في الفرع الرئيسي.
- RS-3 وRS-4 لا تزالان Open، وكل كميات picked/loaded/delivered/returned تساوي صفرًا. لا تُنشأ أرصدة ولا تُنفذ عمليات إكمال لإجبار الاختبار.

### الصور
- عدد أسطر الرانشيتات الحالية: 19؛ لا يوجد أي سطر بلا `image_url`.
- روابط الصور في الأسطر: 17 Googleusercontent و2 Supabase Storage.
- RS-1 وRS-2 يعتمدان على Googleusercontent في جميع الأسطر؛ RS-3 وRS-4 بهما صورتان Storage وخمس Googleusercontent.
- لا يوجد إثبات متصفح حالي لـHTTP status أو `naturalWidth` لروابط Googleusercontent؛ وجود `image_url` في DB لا يثبت ظهور الصورة.
- إصلاح Picker cache في المصدر موجود، لكن لا يُعلن إصلاح الصور Runtime حتى فحص متصفح مصادق.

### الجرد والأذونات
- `inventory_counts=1`, النوع branch والحالة InProgress؛ له 35 سطرًا، جميعها `counted_qty IS NULL`، ولا يوجد أي سطر adjusted. هذا سجل أعمال قائم غير مكتمل؛ لا يُلغى أو يُستكمل أو يُستخدم كبيانات QA.
- `stock_vouchers=0`, `stock_voucher_details=0`, `stock_voucher_operations=32`.
- جميع سجلات `stock_voucher_operations` الـ32 لها `voucher_id IS NULL`، و15 منها فقط تبدأ بـQA-، والتواريخ من 2026-09-23 إلى 2026-09-28. هذا رصيد idempotency تاريخي/يتيم محتمل يحتاج تتبعًا منفصلًا لعقود الإنشاء القديمة؛ لا يُحذف ولا يُعاد استخدامه قبل إثبات أصله وأثره.
- `stock_discrepancies=0`.

## 4. CONFIRMED — عقد التفريغ المركزي
- Edge source `supabase/functions/unload-runsheet/index.ts`, blob `b0f2544afa7f47b87869453c5e15341e0cf821fc`, يستدعي RPC `complete_runsheet_unloading`.
- تعريف Production للـRPC تمت قراءته مباشرة. لا ينشئ سندًا في `stock_vouchers`.
- عند نجاح العملية: يسجل `erp_operation_registry.operation_type='complete_runsheet_unloading'`، ويكتب حركات Unloading عبر `post_stock_movement` بمفتاح idempotency، ثم يحول runsheet إلى Picked ويمسح حقول التحميل.
- لا توجد حاليًا سجلات `complete_runsheet_unloading` مكتملة في Production؛ لذلك لا توجد واقعة تفريغ نهائي حديثة يمكن استخدامها كاختبار عرض حي. وجود Unloading rows في inventory_log حاليًا ناتج عن Reopen وفق مراجع السجلات، ولا يُفسر كإتمام نهائي.

## 5. فجوات المزامنة والعزل
- Loader يشترك في `runsheets` فقط ويعيد reconciliation كل 60 ثانية؛ لا يشترك في `run_sheet_details`.
- Picker وReturns لا يظهر لهما اشتراك Realtime أو polling تشغيلي في المصدر الذي فُحص.
- وجود Publication لا يثبت وصول الأحداث أو تحديث DOM.
- Proxy `moduleDocument` في كل وحدة يستخدم fallback إلى `window.document` إذا لم يجد العنصر داخل `moduleRoot`؛ و`moduleUI.byId` يفعل fallback مشابهًا. هذا يخلق خطر وصول إلى DOM لوحدة أخرى عند غياب ID أو selector داخل الوحدة الحالية. لم يثبت تسرب فعلي في Runtime؛ يصنف P2 structural risk، ويحتاج اختبارًا قبل تشديد العزل.
- Workflow لا يحتوي اختبارًا يثبت ظهور عمليات Picking/Loading/Unloading المكتملة من سجل تاريخي بعد تقدم حالة الرانشيت؛ يغطي أساسًا surface/parity وبعض أخطاء القراءة وReceiver history. نجاح CI الحالي لا يغلق فجوة السجل المكتمل.

## 6. ما تم اختباره فعليًا
- GitHub: تم التحقق من HEAD وملفات الأصل والنسخة المضمّنة وملف Workflow.
- CI: Run `43276131519`، Job `131384896689`، كل الخطوات بما فيها Browser E2E انتهت SUCCESS.
- Supabase: استعلامات SELECT فقط لمخطط الجداول، حالات الرانشيت، التفاصيل والكميات، الصور، stock_branches، inventory_log، inventory_counts، stock_vouchers، stock_voucher_operations، erp_operation_registry، RLS، function definitions وfunction privileges.
- لم تُنفذ أي DML/DDL أو RPC/Edge calls أو تغييرات RLS/GRANT أو نشر أو عمليات Picking/Loading/Unloading/Returns.
- لا توجد جلسة Browser مصادق عليها متاحة في هذا التشغيل؛ محاولة قراءة التبويبات فشلت لعدم وجود originating browser context. فتح صفحة Pages عبر Web لم يكن متاحًا. لذلك Artifact parity وProduction Runtime وNetwork/naturalWidth وظهور Parent tabs تظل UNVERIFIED.

## 7. مصفوفة الأدلة
| الطبقة | الحالة | الدليل/الحد |
|---|---|---|
| GitHub Source | CONFIRMED | HEAD 903a1fe؛ blobs أعلاه |
| Supabase Production | CONFIRMED read-only | DB states, RPC definition, registry, RLS |
| CI | CONFIRMED SUCCESS | Run 43276131519 / Job 131384896689 |
| Deployed Artifact | UNKNOWN | لا وصول مباشر لbytes أو Dashboard deployment حي |
| Runtime / Authenticated E2E | UNVERIFIED | لا Browser session متاحة |
| Business effects | CONFIRMED على السجلات | سجل registry والمخزون؛ لا عمليات جديدة نفذها هذا التدقيق |
| Parent tabs | UNVERIFIED | لا جلسة واجهة ولا قراءة كاملة حية لـmain.html |

## 8. Change Set المقترح — لم يُطبق
### CS-WH-712-A — إصلاح سجل العمليات المكتملة (P1)
- الملفات التي يطبق المالك عليها التغيير: `warehouse.html` مع الملفات الأصلية المقابلة `picker.html`, `loader.html`, `unloader.html` حتى لا يستمر اختلاف الأصل عن المجمّع.
- Picker: بناء سجل الإكمال من `erp_operation_registry` حيث `operation_type='complete_runsheet_picking'` و`status='completed'`، مع `company_id` وهوية المنفذ؛ ربط كل حدث برقم الرانشيت والحالة الحالية، وإتاحة reopen فقط إذا سمح العقد المركزي والحالة الحالية.
- Loader: نفس النمط مع `operation_type='complete_runsheet_loading'`; لا تعتمد على `runsheets.status='Loaded'` كسجل تاريخي. إعادة الفتح لا تظهر إلا عندما يسمح RPC.
- Unloader: استبدال مصدر `stock_vouchers` الخاطئ بمصدر حدث `complete_runsheet_unloading` من `erp_operation_registry`، وعرض `request_payload.runsheet_code` ووقت الإكمال و`response_payload.unloaded_total`؛ لا تُشتق الإكمالات من inventory_log وحده.
- معيار القبول: حدث إتمام يظل ظاهرًا في سجل الوحدة بعد انتقال الرانشيت إلى المرحلة التالية؛ لا يتكرر الحدث؛ company/user scope صحيح؛ زر إعادة الفتح لا يسمح بإعادة فتح حالة غير مؤهلة؛ لا DML أو حركة مخزون إضافية عند فتح سجل المكتملة.
- اختبارات CI المطلوبة: fixtures محلية تمثل RS1 Delivered وRS2 Returned مع سجل Picking/Loading مكتمل، وحالة Open، وتعدد دورات التحميل، وعدم وجود unload event، ثم حدث unload مكتمل؛ والتحقق من مصدر البيانات والواجهة والزر.
- لم يُطبق هذا Change Set. السبب: الدستور §7A يوجب على المالك تطبيق تعديلات التطبيقات التشغيلية؛ كما أن بوابة §6.2 تتطلب Change Set محددًا ومراجعته قبل أي تغيير مؤثر.

### CS-WH-712-B — DOM isolation (P2)
- استبدال fallback العام في lookup APIs بنطاق moduleRoot للوحدات، مع فصل صريح لأي موارد عامة مطلوبة.
- معيار القبول: تكرار IDs بين الوحدات، عنصر مفقود داخل وحدة، تبديل سريع بين الوحدات؛ لا يصل أي selector إلى وحدة أخرى.

### CS-WH-712-C — Images & Realtime (P2)
- الصور: قياس HTTP/naturalWidth في Production مصادق. إذا فشلت Googleusercontent، تجهيز تغيير منفصل لمصدر الصور إلى Storage مع مراجعة أثر URLs/Cache وعدم تعديل بيانات الصور قبل الموافقة.
- Realtime: تحديد invalidation/reconciliation لكل وحدة بعد قياس staleness؛ Picker وReturns وLoader details؛ لا ادعاء مزامنة لحظية قبل قياس الحدث والـlatency.

## 9. قرارات السلامة
- لا تعديل يدوي لـstock_branches أو inventory_log أو runsheets أو stock_vouchers أو operation registry.
- لا حذف سجلات idempotency ذات voucher_id null قبل تتبع migration/function lineage والاعتماديات.
- لا تنفيذ عمليات حية لاختبار سجل مكتمل.
- لم تُعدل ملفات التطبيقات التشغيلية أو Parent/Core، ولم تُنفذ تغييرات Production.
- الحكم: READY WITH LIMITATIONS؛ يمكن تجهيز Change Set واختبارات CI، لكن تنفيذ ملفات التطبيقات التشغيلية وتغيير أي عقد/DB ينتظر مراجعة المالك وتطبيقه، والمتصفح/Artifact غير متاحين للتحقق النهائي.

**الخطوة التالية ذات الأولوية:** تطبيق CS-WH-712-A بواسطة المالك على المصدر الأصلي والمجمّع كحزمة واحدة، ثم تشغيل CI الموسع؛ وبعد نشره، اختبار Browser مصادق read-only على سجلات المكتملة والصور وظهور Parent tabs.  
**الحالة:** ROOT CAUSE CONFIRMED — OWNER FILE CHANGE REQUIRED / RUNTIME UNVERIFIED / NOT CLOSED.


## 10. اكتشاف إضافي — Unloader pending status لا يطابق عقد RPC (P1)
- المصدر الأصلي `companies/company-1/warehouse/unloader.html`، الدالة `loadRunsheets`، يحمّل الحالات `['Loaded','Delivering']`.
- النسخة المضمّنة في Warehouse Hub تستخدم الشرط نفسه.
- تعريف Production لـ`complete_runsheet_unloading` يقبل فقط `r.status='Loaded'` مع `loading_cycle_id IS NOT NULL`؛ أي حالة Delivering ستُرفض برسالة `runsheet not Loaded`، حتى لو ظهرت للمستخدم في قائمة التفريغ.
- هذا تناقض مباشر بين قائمة الأهلية وعقد الإكمال. لا توجد حاليًا runsheets بحالة Delivering في عينة Production الحالية، لذا أثره Runtime على سجل حالي غير مثبت، لكن المسار البرمجي مؤكد.
- الإصلاح الأدنى الموصى به: حصر قائمة Unloader في `Loaded` فقط، أو تقديم عقد عمل معتمد يثبت أن Delivering يجب أن يكون مؤهلًا وتعديل RPC/التحقق المركزي وفقًا له. الخيار الآمن حاليًا هو عدم عرض Delivering كعملية قابلة للتفريغ. لا تعديل RPC أو بيانات.
- معيار القبول: لا تظهر أي حالة لا يقبلها RPC في قائمة Unloader؛ كل عنصر ظاهر يمر preflight القراءة فقط، ولا يبدأ أي حركة إلا عبر RPC المركزي.

## 11. Change Set update
أضيفت نقطة `CS-WH-712-D` (P1) إلى حزمة التغيير: إزالة `Delivering` من حالات قائمة Unloader، مع تحديث الأصل والنسخة المضمّنة، واختبار عقد القائمة مقابل RPC. لم تُطبق.
