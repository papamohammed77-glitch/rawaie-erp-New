# RAWAEA ERP — تقرير التهيئة المعرفية وإعادة التحقق التشغيلي المستقل

**Checkpoint:** LVE-2026-11-03-589  
**تاريخ الفحص:** 2026-11-03  
**الحالة:** INITIALIZATION IN PROGRESS / CURRENT REALITY REVALIDATED / NEW PROCUREMENT SECURITY & CONTRACT FINDINGS / NOT CLOSED  
**نطاق هذه الجولة:** استعادة الحالة، دراسة الدستور والتقارير 400–500، استعادة خريطة المشروع، ثم إعادة فحص GitHub وSupabase Production وStaging وقرائن النشر. لا توجد تعديلات تشغيلية أو إنتاجية في هذه الجولة.

---

## 1. نقطة البداية الإلزامية — CURRENT_STATE

تم جلب CURRENT_STATE.md كاملًا من مستودع الحوكمة، ثم قراءة أحدث checkpoint قبل فتح التقارير أو الذاكرة:

- المستودع المرجعي: papamohammed77-glitch/rawaie-erp-New
- الفرع: main
- HEAD عند بدء الفحص: 0df0738d308b8e77117ceca8889eeb9b2e1412f6
- CURRENT_STATE blob عند بدء الفحص: bfe0f1c2cac018b0a807500867d9d544019d112c
- حجم CURRENT_STATE: 4,153 سطرًا / 641,694 حرفًا.
- LAST VERIFIED EVENT المسجل عند البداية: LVE-2026-11-02-588.
- الهدف المسجل: Buyer Field Workbench في PR #10، مع إبقاء PR في Draft وعدم الدمج قبل مراجعة المالك.
- آخر micro-change مغلق ومطلوب الحفاظ عليه: LVE-583 — فتح صف الفاتورة وعرض التفاصيل، commit 37d4e95e030bf3085c232655bdec6f059a335ca1.
- حالة Buyer field-workbench في LVE-588: غير مغلقة؛ التعديل موجود في فرع PR، وليس في main.

**ملاحظة حاكمة:** لم أبدأ من Report588 أو الذاكرة. استُخدما بعد CURRENT_STATE لتفسير الادعاءات، ثم أُعيد جلب الأدلة الحية.

## 2. الوثائق التي تمت دراستها

### 2.1 الدستور والحوكمة

1. الدستور التشغيلي الدائم:
   - المسار: doc/Draft/Reprots/الدستور التشغيلي الدائم.md
   - blob: d2afa896514b1cb6abd247d2af7a862251ce0604
   - 293 سطرًا؛ تمت قراءته كاملًا.
2. MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP:
   - المسار: doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md
   - blob: 1a0c81c2984103b5a7f3b40db41607d74051b310
   - 2,665 سطرًا؛ تمت قراءة محتواه ومراجعة أقسام الحوكمة ذات الصلة، وبالأخص 77.2 و77.3 و77.4.
3. writing-block.md:
   - تمت مراجعة الأقسام المرتبطة بتوزيع مسؤوليات المساعد والمالك، التعديل الجراحي، منع الأخطاء المتكررة، التقارير، وحدود المهمة القديمة.
   - هذا الملف يتضمن وحدة مهمة Loader/Picker تاريخية؛ لا يجوز اعتبارها هدف التشغيل الحالي بعد انتقال CURRENT_STATE إلى Buyer.

### 2.2 التقارير 400–500

- جرى جلب ملفات التقارير الموجودة فعليًا ضمن النطاق 400–500 من مجلد Reprots.
- عدد الملفات الموجودة في النطاق: 114 ملفًا.
- توجد أرقام تقارير مكررة، كما لم يظهر ملفان مستقلان بالرقمين 490 و491.
- تمت مراجعة تسلسل العناوين والبنية والنتائج/الخواتيم لجميع الملفات، مع قراءة تفصيلية للتقارير المحورية التي تشرح منهج العمل والانتقال إلى الحالة الحالية.
- Report499 هو تقرير إعادة التحقق التشغيلي اليومي الأخير ضمن السلسلة.
- Report500 هو خريطة ذهنية للمشروع، وليس شهادة إغلاق Production أو Runtime؛ ويصرح بأن الجرد العام وربط كل المستهلكين ما زالا مفتوحين.

**التطور التاريخي الذي تثبته السلسلة:**

| نطاق التقارير | المحور الغالب | ما يجب الحفاظ عليه |
|---|---|---|
| 400–420 | POS، المرتجعات، تفاصيل الفواتير، تكامل الطلبات مع الرانشيت | عدم فصل واجهة البيع عن أثر المخزون والخزينة والدفاتر |
| 421–450 | صلاحيات POS، الورديات، الخزينة، قنوات الطلبات والمتجر | فحص صلاحيات الخادم، لا الاكتفاء بإخفاء الأزرار |
| 451–480 | Picker، الحجز، عرض الرانشيت، الصور، التحضير والتحميل | فصل الحجز عن المخزون الفعلي، والحفاظ على عقد Picker/Loader |
| 481–489 | Loader/Picker، اختيار المركبة، دورة التحميل، تصحيح نطاق التكامل | عدم نسخ تطبيق مرجعي بالكامل، وفصل إصلاح العرض عن عيوب Backend |
| 492–500 | إعادة التحقق، تصحيح دورة Loader/Picker، إعادة بناء أمر CTO، الخريطة الذهنية | تقارير الأدلة ليست إثبات نشر، ووجود كود لا يثبت Runtime |

التقارير ليست مصدر الحقيقة. بعض تقارير هذه السلسلة تتضمن قرارات أو بصمات قديمة تجاوزها Git الحالي أو Production. لا تُستعاد أي حالة مغلقة إلا عند ظهور دليل حي جديد.

### 2.3 أحدث التقارير والذاكرة ذات الصلة

- Report500_RAWAEA_ERP_MIND_MAP_20261025.md — blob 1949266c2a4daf3a1af9daa0df5dd9ad8446b318، 261 سطرًا.
- Report585_BUYER_QUICK_PURCHASE_CUSTODY_PURCHASING_VEHICLE_CORRECTED_DESIGN_20261102.md — blob 1bf56c28ef76f2ef6987a9e2644271a59fcfc192، 570 سطرًا.
- Report588_BUYER_FIELD_WORKBENCH_DAILY_REVALIDATION_20261102.md — blob 19dcba2e7c19e1b405d312f47885be27b4b5d1de، 236 سطرًا.
- RAWAEA_PROJECT_MEMORY_117-02.md — blob f244462c12e61f6e1d5c1642db5bfe2781c42712، 796 سطرًا.

**تعريفات المالك المعتمدة في Report585 وMaster §77.4:**

1. رصيد سيارة مسؤول المشتريات هو مخزون عهدة مادي موجود فعليًا في سيارة مسؤول المشتريات، وليس مخزون مندوب التوصيل أو Van Sales أو mobile branch.
2. العهدة النقدية هي مال سُلّم فعليًا لمسؤول المشتريات، مع فصل النقد المستلم والمصروفات المعلقة والمعتمدة والمرفوضة والنقد المرتجع.
3. «فواتيري» سجل فواتير الشراء السريع من السوق، وليس قائمة عامة لكل فواتير الموردين.
4. مصروف الشراء السريع يحتاج إثبات فاتورة المورد وإثبات الاستلام المادي بالمخزن.
5. الوقود يحتاج إيصال محطة؛ النقل يحتاج تذكرة/إيصال؛ والمصروفات الأخرى تحتاج مستندًا مناسبًا.
6. اعتماد مصروف نقدي سبق أن دفعه مسؤول المشتريات من عهدته لا يجوز أن يتحول تلقائيًا إلى سداد مورد أو تخفيض Supplier AP.
7. Draft لا ينشئ مخزونًا أو خزينة أو ذممًا أو قيدًا. إنشاء PO أو اعتماده أو تحويله لا ينشئ أثرًا ماليًا بمجرده.
8. الفاتورة السريعة بلا PO لا تُرحّل مخزنيًا أو محاسبيًا قبل إثبات الاستلام الفعلي واعتماد مستنداته.
9. Posted / PartiallyPaid / Paid لا تُحذف من مسار Draft؛ التصحيح يكون بمسار إلغاء/عكس معتمد ومدقق.

---

## 3. قواعد العمل الملزمة التي تحكم أي خطوة لاحقة

### 3.1 بوابة موافقة المالك — Master §77.2

قبل أي كتابة أو Migration أو Trigger/RPC change أو تعديل RLS/grants أو نشر أو تغيير قد يمس Production أو المخزون أو الخزينة أو دفاتر الأطراف أو مسارات المشتريات والمبيعات والتوصيل، يجب عرض الآتي على المالك:

1. الحقائق المثبتة من Git وSource وProduction وDatabase وDeployment.
2. العنصر المحدد المطلوب تغييره وسبب التغيير وأدلته.
3. النص الكامل للتعديل أو SQL المقترح.
4. الأثر المتوقع على المخزون والخزينة والعملاء والموردين والقيود وبقية التطبيقات.
5. الاعتماديات والسيناريوهات التي قد تتعطل.
6. اختبارات القبول وعدم التراجع وخطة rollback.

ثم انتظار موافقة صريحة على التغيير نفسه. اعتماد سياسة المشتريات في §77.4 ليس موافقة تنفيذية عامة على أي SQL أو كود.

### 3.2 حدود التعديل

- لا تعديل واسع على companies/company-1/main.html.
- لا تعديل مباشر على HTML التشغيلي عندما تكون سياسة المهمة أن المالك هو من يطبق الرقعة.
- يُقدّم للمالك المقطع الأصلي المحدد والبديل الكامل ومحدد البحث والموضع والأثر والاختبار.
- لا إعادة كتابة ملف أو دالة سليمة لإصلاح مقطع صغير.
- لا إنشاء Edge Function أو Workflow أو Executor أو PR أو بنية موازية بلا حاجة معمارية مثبتة.
- لا حذف لبيانات QA أو بيانات مجهولة المصدر.
- لا اختبار مالي أو مخزني حقيقي في Production.
- لا إعلان FIXED أو CLOSED أو VERIFIED دون اختبار مباشر يناسب طبقة الادعاء.

### 3.3 طريقة التعامل مع الأدلة

يجب فصل:
- SOURCE CODE
- PRODUCTION DATABASE
- DEPLOYED ARTIFACT
- RUNTIME BEHAVIOR
- BUSINESS-DATA EFFECTS

ويجب تصنيف كل نتيجة:
- CONFIRMED: دليل مباشر يثبتها.
- UNKNOWN: لا توجد أدلة كافية.
- CONFLICT: عقدان أو دليلان حاليان متعارضان.
- UNVERIFIED: لم يجر اختبار مباشر، حتى لو بدا السلوك منطقيًا.

---

## 4. خريطة النظام المستعادة من المصدر التشغيلي

### 4.1 المستودع التشغيلي والفرع

- التطبيق التشغيلي: papamohammed77-glitch/erp-frontend
- الفرع: main
- HEAD الحالي: 7a14d51b4d4c225240b215879abf6b77b99888d3
- Parent main.html blob: 53b5a9e9d0433a785c3d5471a9c0d68c25497882
- core.js blob: f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1
- app.html blob: 2e47a68fe83956e27d569e786a08dcee91af2924
- Buyer على main blob: 73d746571a10b1720bdd31631004abce0ac9afa1
- Receiver blob: 3111b5e801d1bc021cf18fd66d633fbdc54ac0d6
- save-purchase-order source blob: bc038be8c60a3d593f604c7b2ae445e807bacf57

تم جلب main.html كاملًا من Git blob API لأن fetch_file أعاد محتوى فارغًا لهذا الملف الكبير. حجم المصدر المقروء: 1,800,879 حرفًا / 33,358 سطرًا. جرى تحليل وحداته ومسارات المشتريات والتوجيه والصلاحيات؛ لا أدعي أن هذا وحده يغني عن تتبع كل مستهلك في كل وحدة.

### 4.2 الهيكل المعماري

المعمارية الحالية ليست تطبيق HTML منفردًا؛ هي Parent ERP + مجموعة PWAs مستقلة + Supabase موحد + Edge/RPC + PostgreSQL.

- index.html: بوابة اختيار النظام الأم أو تطبيقات الموظفين.
- app.html: تسجيل الدخول وتحديد ملف المستخدم/الشركة والصلاحيات وتوجيه الموظف إلى التطبيق المناسب.
- main.html: النظام الأم ومركز القيادة، ويحتوي وحدات الإدارة والتقارير والمبيعات والمشتريات والمخزون والمالية والتوصيل والموارد البشرية.
- core.js: النواة المشتركة للمصادقة وقاعدة البيانات المحلية/API والواجهة والصور وتحديث Service Worker وRealtime.
- PWAs: تطبيقات تشغيل مستقلة للمبيعات والمخازن والتوصيل والمشتريات والمكتب والمتجر.
- Supabase: المصدر المركزي للبيانات والهوية والصلاحيات والعمليات الذرية.

core.js الحالي: 1,008 أسطر، ويحتوي وحدات RW_Auth وRW_DB وRW_API وRW_UI وRW_ImageCache وRW_SW وRW_Realtime.

الجرد الحالي لملفات HTML في companies/company-1:
- 30 ملف HTML إجمالًا: 27 تطبيقًا/واجهة تشغيلية مستقلة، إضافة إلى index.html وapp.html وmain.html.
- Sales: 6.
- Warehouse: 10 ملفات، منها 9 تطبيقات تشغيلية وملف data-entry.
- Delivery: 2.
- Purchasing: 2.
- Office: 5.
- Store: 2.

تحليل main.html أظهر:
- 46 وحدة/namespace باسم RW_.
- 1,016 تصريح function.
- 48 اسم جدول مباشر ظاهر في استدعاءات from().
- 41 RPC مباشر.
- 48 Edge endpoint ظاهرًا في النص.
هذه أعداد Static references وليست إثباتًا أن كل الاستدعاءات أو المستهلكين قد تم اختبارهم.

### 4.3 تدفق الأعمال الذي يجب الحفاظ عليه

- قنوات البيع: POS، Telesales، Order Taker، Van Sales، Online Store.
- الطلبات المؤكدة تتصل بالـRunsheet والتجهيز والتسليم والمرتجعات والتسوية.
- Picking حجز/تخصيص؛ Loading/Unloading/Delivery/Return هي أحداث مادية لها أثر مخزني.
- الشراء: PR/RFQ/Quotation/PO/Receiving/Invoice/Payment، مع فصل المستند التجاري عن الاستلام المادي والترحيل المالي.
- المخزون الفعلي لا يساوي المخزون المحجوز؛ لا يجوز اعتبار تغيير حالة الواجهة حركة مخزون.
- المحاسبة والدفاتر يجب أن تتطابق مع حركات الأعمال الفعلية، لا مع إنشاء المستندات وحده.

---

## 5. GitHub — حالة Buyer الحالية مستقلة عن تقاريرها

### 5.1 PR #10

- PR: https://github.com/papamohammed77-glitch/erp-frontend/pull/10
- الحالة: OPEN / DRAFT / UNMERGED.
- Base branch: main.
- Base commit المسجل للـPR: aa8cbffbfa8d42253726381080dcfc24eaea838b.
- Head branch: cto/buyer-field-workbench-lve-587.
- Head commit الحالي: 209c318f2324d741e61b0dceaf5253f830af8c2e.
- المقارنة الحالية المسجلة: 3 commits ahead / 2 behind.
- ملف التغيير الوحيد: companies/company-1/purchasing/buyer.html.
- التغيير: 140 additions / 33 deletions.
- لا تغييرات في main.html أو core.js أو Receiver أو SQL أو Edge أو RLS/ACL ضمن PR.

### 5.2 ما يثبته فرع PR

- يحتفظ بالتبويبات التسعة الحالية.
- يضيف تنقلًا أفقيًا مناسبًا للهاتف.
- يزيل cost_price من Buyer.
- يضيف بحثًا في كتالوج الأصناف بالاسم والكود والباركود مع تطبيع عربي وترتيب تطابق الباركود.
- «فواتيري» يفلتر created_by في الواجهة فقط.
- PO creation يرسل operation_id ثابتًا ضمن عملية الإنشاء.
- PR لا يضيف invoice_type/source marker، ولا صور فواتير السوق أو صور الأصناف، ولا line specifications، ولا server-side invoice ownership، ولا quick receiving، ولا يعيد بناء عهدة النقد أو مخزون سيارة المشتريات.

### 5.3 ما لم يغلقه PR

- إنشاء فاتورة جديدة لا يرسل operation_id ثابتًا؛ Edge ينشئ UUID جديدًا عند غياب المفتاح، وبالتالي إعادة الطلب بمفتاح جديد لا تمنع إنشاء Draft مكرر.
- تحرير السعر يسمح بتحويل القيمة الفارغة إلى صفر عبر Number(el.value)، وpreConfirm لا يعيد التحقق من كل سطر؛ هذا موجود في main أيضًا وليس أثرًا جديدًا للـPR.
- فلتر «فواتيري» في الواجهة ليس حدًا أمنيًا خادميًا.
- PR لا يعالج صلاحيات الكتابة المباشرة على جداول الفواتير.
- PR لا يثبت أن المستخدم يستطيع إتمام رحلة الشراء السريع end-to-end.

**القرار:** يظل PR #10 Draft ولا يدمج أو ينشر قبل مراجعة المالك، ومعالجة العقود الأمنية والاختبارات اللازمة.

---

## 6. Supabase Production — لقطة مباشرة

**المشروع:** SMART ERP  
**Project ref:** fiilmooggumokxanwiyx  
**الحالة:** ACTIVE_HEALTHY  
**PostgreSQL:** 17.6.1.121 بحسب سجل المشروع.

### 6.1 حجم قاعدة البيانات والخدمات

الاستعلامات الحية أعطت:

| العنصر | العدد |
|---|---:|
| Public tables | 186 |
| Public functions | 297 |
| RLS-enabled public tables | 186 |
| Public RLS policies | 247 |
| Public triggers | 304 |
| Applied migrations | 734 |
| Edge Functions | 100 |

يوجد 16 Edge Function بقيمة verify_jwt=false:
- 14 منها Test/Canary/Recovery endpoints متقاعدة وتعيد HTTP 410، ولم يظهر فيها تنفيذ أعمال حي.
- create-stock-voucher يطبق تحققًا مخصصًا من هوية المستخدم.
- submit-online-order هو مسار المتجر العام وله عقد مصادقة مختلف.
لا يصح وصف كل verify_jwt=false تلقائيًا بأنه ثغرة؛ يجب فحص مصادقة كل Endpoint نفسه.

### 6.2 Edge Functions ذات الصلة بالمشتريات

**save-purchase-order**
- ACTIVE، version 22، verify_jwt=true.
- deployed SHA-256: a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb.
- المصدر في erp-frontend مطابق للنص المنشور حرفيًا، 23,077 حرفًا.
- Gateway يتحقق من المستخدم وملف الشركة والصلاحية حسب operation، ثم يوجه إلى RPCs المركزية.
- هذا هو المسار المركزي الموجود الذي يجب الحفاظ عليه وعدم إنشاء بديل له.

**receive-purchase**
- ACTIVE، version 12، verify_jwt=true.
- deployed SHA-256: bcf5f3d576cebfac3d7f3ce655515acfd33ac25cbbce376db42568da8e06aa06.
- Edge يتحقق من JWT ووجود مستخدم نشط في الشركة، لكنه لا يتحقق من effective permission الخاصة بالاستلام/المخازن/المشتريات قبل استدعاء RPC باستخدام service_role.
- receive_purchase_atomic هو SECURITY DEFINER وتنفيذ RPC المباشر محصور في service_role.
- RPC يتحقق من عضوية المستخدم والشركة، لكنه لا يضيف فحص صلاحية تشغيلية يعوض غياب الفحص في Edge.
- لم يُنفذ HTTP request لمحاكاة مستخدم غير مصرح به؛ لذلك فجوة التفويض في Source/Backend contract CONFIRMED، والاستغلال الفعلي عبر HTTP UNVERIFIED.
- مصدر receive-purchase غير موجود ضمن supabase/functions في المستودع التشغيلي؛ يوجد snapshot تاريخي في مستودع الحوكمة، ولا يجوز نشر snapshot بدل المصدر المنشور دون استعادة ومطابقة كاملة.

### 6.3 صلاحيات فواتير الموردين — CONFLICT مؤثر

في Production:
- purchase_invoices عليه RLS policy من نوع ALL إلى public، وشرطها company_id = app_private.current_user_company_id().
- purchase_invoice_details عليه ALL إلى public، وشرطه ارتباط السطر بفاتورة في الشركة نفسها.
- authenticated لديه effective SELECT/INSERT/UPDATE/DELETE على الجدولين.
- current_user_company_id() يعيد company_id لأي public.users مرتبط بـauth.uid() وحالته ليست Inactive؛ لا يفحص purchases permission.
- لا توجد سياسة RLS تفصل القراءة عن الكتابة أو تشترط صلاحية المشتريات على عمليات DML.
- مشغلات الفاتورة لا تمثل بديلًا عن بوابة الصلاحيات؛ المشغلات المرئية مرتبطة بسجل الحالة وupdated_at.

النتيجة:
مستخدم authenticated داخل الشركة يستطيع من حيث ACL/RLS تنفيذ DML مباشر على رأس الفاتورة وتفاصيلها خارج save-purchase-order وRPC المعتمد. هذا يتعارض مع سياسة المالك §77.4 التي تشترط Draft edit/delete بصلاحية وحالة ومن خلال عقد مركزي.

**Consumer scan الذي أُعيد في هذه الجولة:**
- Buyer يقرأ عبر GET_DATA ويكتب عبر Gateway.
- Parent main.html يقرأ purchase_invoices وpurchase_invoice_details ويستخدم Edge للإنشاء/الترحيل؛ لم يظهر DML مباشر للفواتير في المسار الذي فُحص.
- warehouse/vouchers.html يقرأ purchase_invoices فقط في سياق المرتجعات.
- بقية ملفات HTML المستقلة التي جرى مسحها لم يظهر فيها استعمال مباشر لهذين الجدولين.
- لم يظهر مستهلك HTML يفرض الإبقاء على INSERT/UPDATE/DELETE المباشر. يجب مع ذلك إعادة فحص أي consumer جديد قبل تغيير ACL.

purchase_attachments أيضًا لديه company-only ALL policy، مع صلاحيات DML واسعة؛ لا يوجد حتى الآن مسار آمن مكتمل لرفع وعرض صور فواتير السوق.

### 6.4 Storage / المستندات

Production يحتوي:
- product-images: public.
- employee-documents: private.

سياسات employee-documents الحالية تشمل employee docs وbuyer-custody paths. لم يظهر buyer-purchases invoice path خاص يربط الملف بالفاتورة وبندها وصلاحيات المشتري/المالية.
لا تستخدم product-images العام لحفظ فاتورة مورد أو إيصال عهدة.
purchase_attachments لا يثبت وجود upload/download آمن؛ الجدول وحده ليس نظام مستندات.

### 6.5 عقد Receiver مع Production — CONFLICT

المصدر الحالي:
companies/company-1/warehouse/receiver.html

في loadPODetails() ينفذ:
purchase_order_details.select(...).eq('po_code', code)

لكن Production schema الفعلي لـpurchase_order_details يحتوي:
id, po_id, item_id, item_code, item_name, unit, qty_ordered, unit_price, qty_received, line_amount, notes, created_at

ولا يحتوي عمود po_code. po_code موجود في purchase_orders فقط.

إذًا يوجد تعارض مباشر بين مصدر Receiver ومخطط Production. لم يتم تشغيل Browser/Network لإثبات رسالة PostgREST الفعلية؛ لذلك:
- Source/DB contract conflict: CONFIRMED.
- فشل تحميل تفاصيل PO وقت التشغيل: UNVERIFIED حتى اختبار HTTP/Browser.
- التصحيح يجب أن يربط تفاصيل الأمر بـpo_id بعد جلب PO id، لا أن يخترع عمودًا أو يغير schema لتناسب الاستدعاء.

ملاحظة إضافية:
Receiver يستخدم parseInt لقيم الاستلام، بينما qty_ordered في Production من النوع numeric. هذا يقتطع الكسور إن كانت الوحدات تسمح بكميات عشرية؛ دعم الكسور في السيناريوهات التشغيلية يحتاج إثباتًا من بيانات الوحدات وقواعد العمل قبل تعديل الحقل.

### 6.6 Parent legacy purchase-pos — CONFLICT

في main.html:
- purchase-pos ما زال معرفًا في قائمة التنقل وpermissionMap وView dispatch.
- view purchase-pos يستدعي RW_Purchases.renderPOS().
- RW_Purchases.savePO() يرسل payload قديمًا يحتوي orderHeader وitemsList ولا يرسل operation المطلوب.
- save-purchase-order v22 يشترط operation في body ويعيد خطأ عند غيابه.
- لذلك يوجد تعارض عقد مصدر مؤكد في المسار legacy purchase-pos؛ لم يُنفذ Browser E2E، فلا أصفه بأنه runtime failure مثبت.
- وحدة RW_PurchaseGold منفصلة، وتعيد تعيين RW_Purchases.renderOrders = RW_PurchaseGold.render؛ أي إن مسار purchases الرئيسي يستخدم وحدة أحدث، بينما purchase-pos ما زال route منفصلًا. لا تخلط المسارين ولا تعالج أحدهما بتغيير الآخر دون تتبع كامل.

### 6.7 Buyer cash custody — عقد قائم لا يطابق تعريف المالك

فحص تعريفات Production الحية أكد:

- buyer_custody_issue_atomic وbuyer_custody_add_advance_atomic ينفذان posting نقدي/محاسبي عند إنشاء التسليم أو الزيادة، بينما acknowledgment الموظف حدث منفصل لاحق.
- buyer_custody_submit_expense_atomic يشترط فاتورة Draft مرتبطة بـPO ومستند استلام PO؛ لا يدعم PURCHASE market مستقلًا ولا FUEL أو TRANSPORT أو OTHER.
- buyer_custody_review_expense_atomic عند Approved ينشئ Journal Dr Supplier AP 211 / Cr Employee Custody 127، ويسجل buyer_custody_payment، ويحوّل الفاتورة إلى Paid ويضيف debit إلى supplier_ledger.
- هذا المسار لا يجوز إعادة استخدامه لمشتريات السوق التي سبق أن دفعها الموظف من نقدية العهدة؛ وإلا يتحول إثبات مصروف الموظف إلى سداد مورد ثانٍ.
- buyer_custody_settle_atomic يطابق المبلغ المرتجع حسابيًا، لكن لا توجد في التوقيع الحالي مرفقات إثبات مادي مستقلة لعودة النقد.
- buyer_custody_expenses لا يحتوي expense_type.
- جميع جداول buyer_custodies وadvances وexpenses وpayments كانت فارغة في اللقطة الحالية؛ لا توجد حركة عهدة فعلية يمكن الادعاء بأنها اختُبرت.

### 6.8 Supplier AP — إغلاق قديم أعيد التحقق منه

تم فحص triggers الحية على supplier_ledger وsuppliers:
- بقي trigger واحد فقط: supplier_ledger_sync_accounts_payable → app_private.sync_supplier_accounts_payable().
- لم يعد trigger القديم المكرر موجودًا.
- stored suppliers.accounts_payable يساوي supplier_ledger net لكل الموردين في اللقطة الحالية.
- إجمالي المورد ذي الحركة: 3,970.00 مقابل 3,970.00 في الدفتر، والفرق صفر.
هذا يثبت أن مشكلة ازدواجية Supplier AP التي كانت مفتوحة في LVE-578 لم تعد مفتوحة في Production الحالي. لا تعِد فتحها بلا دليل جديد.

### 6.9 Production data snapshot

SELECT-only snapshot:

| الجدول | الصفوف |
|---|---:|
| purchase_invoices | 3 |
| purchase_invoice_details | 6 |
| purchase_attachments | 0 |
| buyer_custodies | 0 |
| buyer_custody_advances | 0 |
| buyer_custody_expenses | 0 |
| buyer_custody_payments | 0 |
| purchase_orders | 1 |
| purchase_order_details | 1 |
| receiving | 0 |
| receiving_details | 0 |

البيانات الثلاثة للفواتير في اللقطة تحمل أوصافًا تجريبية/QA:
- فاتورتان Posted قديمتان بلا PO، بقيم 2,640 و1,330 وبعملة SAR، وإجمالي 3,970 يطابق supplier_ledger.
- فاتورة QA Draft مرتبطة بأمر QA-SR-PO-20260927، بقيمة 375، وبها سطر QA.
- أمر QA نفسه حالته Draft مع qty_received=5، والفاتورة QA فيها is_received=true، بينما receiving وreceiving_details فارغان.

هذه سجلات QA مرجعية مرتبطة باختبارات SupplierReturn؛ لا تحذفها ولا تعاملها كحركة تشغيلية حقيقية دون تتبع مصدرها. كما أن SAR في الفواتير القديمة لا يثبت أن العملة الحالية SAR؛ app_settings وpurchase_settings الحاليان EGP. سبب/تاريخ تغيير العملة التاريخي غير محسوم في هذه الجولة.

---

## 7. Migration lineage — اختلاف مصدر/إصدار يجب ألا يتحول إلى db push

- Production migration ledger: 734 إصدارًا.
- مستودع التطبيق التشغيلي يحتوي 47 ملف SQL في supabase/migrations.
- مستودع الحوكمة يحتوي 216 ملف SQL في supabase/migrations.
- أحدث نسختين في Production ledger:
  - 20261102150516 / buyer_invoice_draft_edit_delete_atomic_20261102
  - 20261102151137 / quick_invoice_post_requires_receipt_contract_20261102
- ملفات التطبيق الحالية تحمل:
  - 20261102160000_buyer_invoice_draft_edit_delete_atomic.sql
  - 20261102162000_quick_invoice_post_requires_receipt_contract.sql
- التوقيت/الإصدار واسم migration لا يتطابق حرفيًا بين ledger وGit.
- تعريفات الدوال الثلاث المرتبطة بالتعديل والحذف والترحيل تطابق تعريفات Production بعد تطبيع اختلافات التنسيق النصي.

الاستنتاج:
- سلوك الدوال في Production متوافق مع source function bodies التي فُحصت.
- Provenance/lineage للـmigration غير متطابق واحدًا لواحد.
- لا تشغّل supabase db push ولا تعِد تطبيق هذه migrations قبل توثيق العلاقة بين النسخ والأسماء والإصدارات.

---

## 8. Staging

مشروع staging:
- ref: hfzznsiprnwkpayskzhu
- الحالة: ACTIVE_HEALTHY.
- migration ledger: 62.
- لا يوجد purchase_invoices أو purchase_invoice_details.
- لا يوجد save-purchase-order أو receive-purchase في Edge registry.

إذًا Staging غير جاهز لاختبار Buyer/Procurement E2E ولا يثبت parity مع Production. حالة ACTIVE_HEALTHY لا تعني اكتمال schema أو business contracts.

---

## 9. Deployment / Runtime

### CONFIRMED من GitHub PR bot comments

في PR #10، سجل Cloudflare bot على commit 209c318:
- مشروع rawaea-erp: Deploy successful، مع Preview URL:
  https://d936b351.rawaea-erp.pages.dev
- Branch Preview URL:
  https://cto-buyer-field-workbench-lv.rawaea-erp.pages.dev
- مشاريع erp-frontend وrawaea-store وwarehouse-supervisor سجلت Build failed لنفس commit.

هذه تعليقات نشر من GitHub bot، وليست فحصًا للـHTML الذي يقدمه الخادم أو سلوك المستخدم.

### UNVERIFIED

- لم أتمكن من فتح preview URL عبر أداة الويب.
- لا يوجد Browser tab context متاح في جلسة الفحص.
- لا توجد قراءة مباشرة من Cloudflare dashboard/logs في هذه الجولة.
- لم أقرأ headers الفعلية أو artifact الذي يقدمه الخادم.
- لم أنفذ Console/Network أو authenticated E2E.
- لم أثبت أي مشروع Pages يمثل production domain الفعلي لكل تطبيق.
- لا أستنتج نجاح runtime من نجاح preview build.

---

## 10. مصفوفة التحقق

| الطبقة | النتيجة | حدود الإثبات |
|---|---|---|
| GitHub/source | CONFIRMED | HEAD، Buyer/Receiver/Core، main blob، PR diff، Edge source |
| Supabase Production | CONFIRMED | schema، ACL/RLS، RPC definitions، triggers، migrations، counts |
| Deployed Edge artifact | CONFIRMED جزئيًا | save-purchase-order v22 byte-match؛ receive-purchase v12 source lineage غير مكتمل |
| Cloudflare deployed HTML | UNVERIFIED | bot comment موجود، لكن لم يُقرأ served artifact أو headers |
| Runtime / Browser E2E | UNVERIFIED | لا Browser context، ولا Console/Network |
| Business-data effects | CONFIRMED جزئيًا | أعداد/دفاتر QA متطابقة؛ لم تُنفذ عمليات أعمال جديدة |
| Security exploit execution | UNVERIFIED | لم تُرسل طلبات كتابة أو محاكاة استغلال |
| Staging E2E | BLOCKED | schema وEdge parity غير مكتملين |

---

## 11. ما تم فعليًا في LVE-589

1. جلب CURRENT_STATE.md من المستودع المرجعي وتثبيت LVE-588 كنقطة البداية.
2. قراءة الدستور التشغيلي الدائم كاملًا.
3. قراءة Master CTO Governance ومراجعة قواعد الموافقة والملكية وحماية Production.
4. جلب ومراجعة ملفات التقارير الموجودة ضمن 400–500، وتحديد التكرارات والفجوات.
5. قراءة Report500 وReport585 وReport588 والذاكرة الحالية 117-02.
6. التحقق من HEAD والفرع والـPR والـdiff في المستودع التشغيلي.
7. جلب كامل main.html عبر Git blob API وتحليل وحداته ومسارات المشتريات والتوجيه والصلاحيات ذات الصلة.
8. جلب core.js وapp.html وBuyer وReceiver وPWA/SW/headers.
9. إعادة فحص Production schema وRLS/ACL وRPCs وEdge registry وmigration ledger.
10. إعادة التحقق من Supplier AP trigger ودفتر الموردين؛ ثبت أن التكرار السابق مغلق حاليًا.
11. فحص staging schema وEdge registry.
12. مراجعة PR bot deployment comments وتصنيفها دون ادعاء فحص artifact.
13. فحص مستهلكي purchase_invoices وpurchase_invoice_details في ملفات HTML المستقلة وParent ضمن النطاق المتاح.

### Mutation Ledger

- GitHub application source: لم يتغير.
- PR #10: لم يدمج ولم يتغير.
- Supabase Production: SELECT/read-only فقط؛ لا DDL ولا DML ولا RLS/grants ولا RPC/trigger changes.
- Edge Functions: لم يتم نشر أو تعديل أي Function.
- Cloudflare: لم يتم نشر أو تعديل أي Project.
- Business data: لم تتغير أي كمية أو فاتورة أو عهدة أو خزينة أو دفتر.
- لا تم حذف أو إنشاء بيانات اختبار.

---

## 12. ما لم يتم ولماذا

1. لم تُصلح فجوة receive-purchase authorization؛ لأنها تمس استلام المخزون وتحتاج exact owner-approved changeset واختبارات عدم الأثر الجانبي.
2. لم تُصلح RLS/ACL لفواتير الموردين؛ لأن التغيير يمس مستهلكي Parent والفواتير ويحتاج SQL كاملًا وخطة تراجع وموافقة صريحة.
3. لم تُعدل Receiver؛ لأن source patch يجب أن يقدّم للمالك وفق سياسة الملفات التشغيلية، وبعد حسم contract الدقيق.
4. لم تُصلح legacy purchase-pos؛ لأن ذلك يتطلب تحديد ما إذا كان المسار سيُحافظ عليه أو يُحوّل إلى gateway الحالي، مع اختبار كل المستهلكين.
5. لم تُضف invoice_type أو source marker أو storage path أو expense_type أو purchasing vehicle ledger؛ هذه قرارات schema/Business design وليست تغييرات تخمينية.
6. لم تُنفذ successful CREATE_PO/CREATE_INVOICE/Receiving في Production.
7. لم تُنفذ Browser E2E أو فحص Cloudflare artifact.
8. لم يتم رسم خريطة كاملة لكل 100 Edge Function وكل 297 public function وكل 186 جدولًا؛ جرى بناء خريطة عليا وفحص المسارات ذات الصلة، ولا يصح وصف الجرد الشامل بأنه مكتمل.
9. لم يُحسم تاريخ تغيير العملة من SAR إلى EGP.
10. لم يُثبت أن أيًا من أخطاء source التي اكتُشفت يظهر بالفعل في Runtime؛ بقيت نتائج التشغيل UNVERIFIED عند عدم إجراء اختبار آمن.

---

## 13. سجل CONFIRMED / UNKNOWN / CONFLICT / UNVERIFIED

### CONFIRMED
- LVE-588 هو آخر checkpoint قبل هذه الجولة.
- PR #10 Draft وغير مدمج.
- save-purchase-order v22 مطابق للمصدر في Git.
- receive-purchase v12 لا يحتوي effective permission check في مسار الاستلام.
- invoice header/detail DML متاح لـauthenticated تحت company-only RLS.
- current_user_company_id لا يفحص purchases permission.
- Receiver يستخدم po_code على purchase_order_details رغم عدم وجود العمود في Production.
- legacy purchase-pos يرسل عقدًا لا يطابق save-purchase-order v22.
- supplier AP trigger المكرر أزيل؛ بقي trigger projection واحد والأرصدة متطابقة 3,970.
- بيانات الفواتير الحالية QA/test references؛ لا تُحذف.
- Staging لا يملك جداول الفواتير أو Edge functions اللازمة لاختبار Buyer.

### UNKNOWN
- أي Cloudflare Pages project هو production origin المعتمد لكل تطبيق.
- تاريخ تغيير العملة وسبب بقاء سجلات SAR القديمة.
- ما إذا كانت الكميات الكسرية مطلوبة فعليًا في Receiver لكل وحدات القياس.
- هل هناك consumers غير HTML أو dynamic SQL تستعمل direct DML على invoices.
- ما إذا كان buyer invoice ownership حدًا أمنيًا مطلوبًا على الخادم أم عرضًا فقط؛ تعريف المالك لـ«فواتيري» يحدد نوع المستند لكن لا يثبت وحده حدود القراءة.
- الخريطة الكاملة لجميع migrations الـ734 إلى ملفات Git وcommits.

### CONFLICT
- receive-purchase authorization: Edge/Backend يسمحان بمرور الاستلام بعد التحقق من الهوية والشركة دون effective permission، بينما سياسة المشروع تتطلب صلاحية خادمية.
- invoice DML: company-only RLS/ACL يسمح بالكتابة المباشرة خارج central gateway، خلافًا لسياسة المالك.
- Receiver query: مصدر HTML يستخدم po_code في تفاصيل PO، وProduction لا يحتوي هذا العمود.
- purchase-pos legacy payload لا يطابق operation contract في Edge v22.
- Buyer «فواتيري» يفلتر creator فقط، بينما تعريف المالك يقصد سجل مشتريات السوق؛ لا يوجد source/type marker في schema.
- Migration version/time lineage لا يطابق حرفيًا بين Git وProduction رغم تطابق تعريفات الدوال.

### UNVERIFIED
- فشل Receiver في Runtime لم يُثبت عبر Browser/Network.
- إمكانية استغلال receive-purchase من مستخدم بلا صلاحية لم تُختبر بطلب HTTP.
- نجاح/فشل legacy purchase-pos وقت التشغيل لم يُختبر.
- التكرار الفعلي عند إعادة محاولة CREATE_INVOICE لم يُختبر.
- Cloudflare served artifact/headers غير مفحوصة.
- Browser E2E والآثار التجارية بعد عمليات حقيقية غير منفذة.

---

## 14. الخطوة التالية ذات الأولوية

**إعداد حزمة مراجعة مالك واحدة لمسار المشتريات والاستلام قبل أي دمج أو نشر:**

1. تصحيح تفويض receive-purchase على الخادم باستخدام effective permission الصحيح وربطه بالمستخدم/الشركة.
2. إصلاح عقد Receiver لربط purchase_order_details بـpo_id، والتحقق من decimal quantity contract.
3. تحديد مصير legacy purchase-pos وإصلاح payload أو تعطيل المسار فقط بعد قرار مالك واضح.
4. تقديم SQL المقترح لفصل SELECT عن DML المباشر على invoice header/details مع الحفاظ على Parent read consumers.
5. تضمين operation_id ثابت لكل عملية إنشاء/إعادة محاولة، والاختبارات والrollback.
6. عدم تنفيذ أي عنصر من هذه الحزمة قبل عرض النصوص والأثر والمخاطر والاختبارات على المالك وانتظار موافقته الصريحة.

يبقى PR #10 Draft إلى أن يُحسم أثره الأمني والتشغيلي وتُستكمل الاختبارات. لا تُنشأ بنية جديدة ولا Edge Function جديدة.

---

## 15. الحكم النهائي لمرحلة التهيئة

**لم تُعلن عبارة «تم الفهم الكامل للمشروع».**

تم استعادة الدستور، ومنهج التقارير، والرؤية العليا، وخريطة التطبيقات، والحالة الحالية، وأدلة GitHub وProduction ذات الصلة. لكن الفهم الكامل للنظام لا يزال يتطلب استكمال ربط المستهلكين لجميع التطبيقات مع Edge/RPC/DB، واستكمال lineage للمigrations، والتحقق من النشر والـRuntime، وإغلاق أو توثيق التناقضات المكتشفة.

**حالة التهيئة:** ADVANCED / IN PROGRESS / NOT COMPLETE.  
**لا يوجد تغيير تشغيلي أو إنتاجي في LVE-589.**
