# التقرير التنفيذي اليومي — RAWAEA ERP
## LVE-2026-11-02-588 — إعادة التحقق الحي من Buyer Field Workbench

**التاريخ:** 2026-11-02 — Africa/Cairo  
**النطاق:** PR #10 / Buyer Field Workbench، ومطابقة عقد الفواتير بين المصدر وProduction.  
**الحالة النهائية:** PARTIAL / HOLD — PR ما زال Draft، غير جاهز للدمج أو النشر.  
**التغيير التشغيلي في هذا التشغيل:** لا يوجد. جميع استعلامات Production كانت SELECT/قراءة فقط؛ لم يحدث DDL أو DML أو تعديل RLS/grants أو Edge deploy أو merge أو Cloudflare publish.

---

## 1) نقطة البداية

### CURRENT_STATE

- جرى جلب CURRENT_STATE.md كاملًا من المستودع المرجعي قبل أي فحص آخر: 4,153 سطرًا، 641,694 حرفًا، blob SHA: dcc52b51579bf6699b6bf4d2caa00a5b0ae8a23b.
- آخر نقطة مسجلة عند البدء: LVE-2026-11-02-587 — Buyer Field Workbench Source Patch.
- LAST VERIFIED EVENT المسجل: إنشاء تعديل Buyer محدود على فرع العمل وفتح Draft PR #10، دون دمج أو نشر أو E2E.
- الهدف الحالي المستخرج: إعادة التحقق من نفس PR #10 وملف companies/company-1/purchasing/buyer.html، لا إعادة بناء التبويبات أو إعادة إصلاح LVE-583.
- آخر تغيير صغير مثبت ومحتفظ به: LVE-583 row-click لفتح تفاصيل الفاتورة، commit 37d4e95e030bf3085c232655bdec6f059a335ca1؛ ما زال موجودًا في مصدر Buyer الحالي.
- لا توجد حالة إغلاق للمهمة الحالية؛ LVE-587 ما زال Draft/Review وليس CLOSED.

### التعليمات الحاكمة التي تمت قراءتها

- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP، خصوصًا §77.2 و§77.4.
- الدستور التشغيلي الدائم، الأقسام ذات الصلة 6.1–6.3.
- تقرير LVE-587 قُرئ كخيط تحقيق فقط، ثم أعيد اختبار ادعاءاته من GitHub وProduction.

**قيد حاكم:** §77.2 يشترط عرض التغيير الدقيق وآثاره واعتمادياته واختباراته وخطة تراجعه، ثم موافقة صريحة على نفس changeset. اعتماد السياسة في §77.4 ليس تفويضًا تلقائيًا لتعديل SQL/RLS/grants أو الدمج أو النشر.

---

## 2) CONFIRMED

### A. GitHub / Source

**المستودع التشغيلي:** papamohammed77-glitch/erp-frontend، والفرع الافتراضي main.

| العنصر | الدليل الحي |
|---|---|
| main HEAD | 7a14d51b4d4c225240b215879abf6b77b99888d3 |
| PR branch | cto/buyer-field-workbench-lve-587 |
| PR head | 209c318f2324d741e61b0dceaf5253f830af8c2e |
| merge base | aa8cbffbfa8d42253726381080dcfc24eaea838b |
| مقارنة main بالفرع | 3 commits ahead / 2 behind |
| PR #10 | OPEN، Draft، unmerged، mergeable=true |
| نطاق diff | ملف واحد فقط: companies/company-1/purchasing/buyer.html؛ 142 additions / 34 deletions |
| Buyer blob الحالي | 100987d03c6ed94ff2e2acd1c623a63b80ffb471 |
| Buyer blob على main | 73d746571a10b1720bdd31631004abce0ac9afa1 |

الـcommitان اللذان تقدّم بهما main بعد merge base هما توثيقيان فقط:
- 7a14d51: تحديث handoff داخل CURRENT_STATE.md في مستودع التطبيق.
- 6381f63: إضافة تقرير LVE-587.
لم يظهر تعديل تشغيلي آخر في ملفات التطبيق ضمن هذين الـcommitين؛ لذلك لا يوجد source-code conflict ناتج عنهما، لكن الفرع متأخر توثيقيًا.

**تصحيح مهم للحالة المسجلة:** فرع العمل لم يعد عند 5ae94d7، بل وصل إلى 209c318. والـcommit 209c318 بعنوان fix(buyer): reuse stable operation id for PO retries LVE-587 يضيف operationId داخل createPO ويمرره إلى CREATE_PO. لذلك فإن handoff الموجود على main والذي يقول إن تعديل PO operation_id لم يطبق أصبح قديمًا. كما أن مقارنة 2 ahead/0 behind المسجلة سابقًا لم تعد صحيحة؛ المقارنة الحية الآن 3 ahead/2 behind.

**فحص Buyer الحالي:**
- الملف 1,155 سطرًا تقريبًا و149,274 حرفًا.
- ستة عناصر script إجمالًا: خمسة ملفات خارجية وكتلة inline واحدة؛ كتلة JavaScript inline اجتازت parse بواسطة new Function. هذا فحص syntax للكتلة inline فقط، وليس اختبار HTML أو Browser runtime.
- تسعة tab IDs وأفعال switchTab موجودة.
- صفر مراجع cost_price.
- بحث الأصناف اختُبر خوارزميًا على 30 صنفًا نشطًا حاليًا في Production: 7/7 حالات ناجحة (barcode exact، item code، اسم عربي، تطبيع الهمزة، الأرقام العربية، البحث الفارغ، وعدم وجود نتيجة).
- الكتالوج الحالي: 30 صنفًا نشطًا، 20 له barcode، و29 له image_url.
- App.data يطلب حدًا أقصى 500، وGET_DATA في Edge يقيّد النتيجة إلى 500. جميع الأصناف الحالية تقع داخل هذا الحد، لكن ذلك لا يثبت اكتمال القائمة عند توسع الكتالوج.
- إضافة الصنف إلى PO والـinvoice ترفض السعر الفارغ عند الإضافة الأولية، ولا تعيد cost_price تلقائيًا.
- createPO يرسل operation_id ثابتًا خلال محاولة المودال الواحدة؛ التعديل الأخير 209c318 مثبت في المصدر.

**نقاط مصدرية باقية:**
1. محرر سطر PO والـinvoice يستخدم Number(el.value). عند مسح حقل السعر يصبح Number('') مساويًا للصفر. preConfirm يتحقق من المورد ووجود سطر، ولا يعيد التحقق من السعر لكل سطر. دوال Production تقبل unit_price=0 وترفض القيم السالبة فقط. هذا السلوك موجود أيضًا على main، أي إنه عيب سابق لم ينشئه PR، لكنه يترك مسار السعر اليدوي غير محكم عند تعديل السطر بعد إضافته. لا يجوز تفسير الصفر تلقائيًا على أنه خطأ؛ المطلوب فصل blank عن صفر مقصود.
2. createPurchaseInvoice لا يرسل operation_id عند إنشاء فاتورة جديدة؛ يرسله فقط عند تعديل مسودة موجودة. Edge يولّد UUID جديدًا إذا لم يستلم operation_id. لذلك إعادة طلب CREATE_INVOICE بعد نتيجة شبكة ملتبسة قد تنشئ Draft ثانية؛ لم يثبت حدوث تكرار فعلي، لكن عقد idempotency الحالي لا يمنعه عبر محاولتين مستقلتين.
3. renderInvoices يفلتر created_by في المتصفح فقط. openInvoice لا يعيد التحقق من ملكية السجل. هذا ليس حد صلاحيات أو سرية.
4. PR لا يضيف invoice source/type، ولا صورة فاتورة، ولا حفظ مواصفات لكل سطر. صور الأصناف المعروضة من item master ليست بديلًا عن مرفق فاتورة أو snapshot لصورة/مواصفات السطر.

### B. Supabase Production — SMART ERP

- Project ref: fiilmooggumokxanwiyx، المشروع Active.
- العملة الحالية من app_settings: EGP.
- save-purchase-order: version 22، ACTIVE، verify_jwt=true، وآخر تحديث مسجل 2026-11-02 15:05:56 UTC.
- مصدر Git الحالي للدالة: supabase/functions/save-purchase-order/index.ts، blob bc038be8c60a3d593f604c7b2ae445e807bacf57.
- محتوى الدالة المنشورة مطابق للمصدر حرفيًا؛ deployed SHA-256: a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb.
- GET_DATA يتطلب صلاحية مشتريات/مالية مناسبة، ويقرأ company-scoped data بحد أقصى 500. لا يوجد created_by filter على مستوى Edge لـ purchase_invoices.
- سجل migrations في Production: 734 migration؛ آخر نسختين مسجلتين هما 20261102150516 buyer_invoice_draft_edit_delete_atomic_20261102 و20261102151137 quick_invoice_post_requires_receipt_contract_20261102. PR #10 لا يحتوي migrations أو تغييرات DB.
- ملفات SQL المصدر المطابقة لهذه النسخ لم تُعثر عليها في المسارات المتوقعة داخل الفرع main؛ لذلك لا أؤكد Git-to-migration file lineage ولا أوصي بأي db push اعتمادًا على السجل وحده.

**لقطة البيانات الحالية — قراءة فقط، observed_at من PostgreSQL:**
- items النشطة: 30.
- purchase_invoices: 3، وpurchase_invoice_details: 6.
- purchase_orders: 1، وpurchase_order_details: 1.
- buyer_custodies: 0، buyer_custody_expenses: 0، stock_vouchers: 0.
- inventory_log: 76، treasury: 4، cash_box: 8، supplier_ledger: 2، journal_entries: 19.
- من الفواتير الثلاث: اثنتان بلا PO وواحدة مرتبطة بـ PO؛ جميعها مسجلة بواسطة منشئ واحد، ولا توجد فاتورة منشأة بحساب Buyer الحالي. لذلك لا توجد بيانات Buyer-owned حقيقية لاختبار قائمة «فواتيري» عليها حاليًا.

**عقد PO والفاتورة:**
- purchase_create_po_atomic وpurchase_create_invoice_atomic يتطلبان p_operation_id، ويوجد unique index على (company_id, operation_id) لكل من PO والفاتورة.
- PO من Buyer الحالي يمرر operation_id بعد commit 209c318؛ نفس المفتاح يعيد نتيجة العملية المكررة بدل إنشاء PO آخر في مسار إعادة الطلب بنفس المفتاح.
- CREATE_INVOICE من Buyer الجديد لا يمرر المفتاح؛ Edge يولّد مفتاحًا جديدًا لكل طلب، ولذلك لا تستفيد إعادة المحاولة من unique idempotency key السابق.
- إنشاء Draft invoice وPO لا ينفذ بذاته حركة مخزون أو قيدًا أو تسوية مورد؛ الأثر يظل عبر مسارات الاستلام/الترحيل المعتمدة.
- purchase_post_invoice_atomic يحتوي حارس PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED لمنع ترحيل فاتورة سريعة بلا عقد استلام فعلي.

### C. تعارض أمني مؤكد في Production

هذه أهم نتيجة جديدة في هذا التشغيل:

- RLS مفعّل على purchase_invoices وpurchase_invoice_details.
- سياسة purchase_invoices_company من نوع PERMISSIVE وcommand=ALL، ومحددها company_id = app_private.current_user_company_id() فقط.
- سياسة purchase_invoice_details_company تسمح بالوصول إذا كان الأب تابعًا للشركة نفسها؛ ولا تضيف شرط مالك أو صلاحية مشتريات أو حالة Draft.
- authenticated لديه فعليًا SELECT وINSERT وUPDATE وDELETE على الجدولين وفق has_table_privilege.
- app_private.current_user_company_id() دالة SECURITY DEFINER تعيد company_id لأي مستخدم حالته ليست Inactive؛ لا تتحقق من صلاحية purchases.
- مشغلات purchase_invoices التي ظهرت هي status_history وupdated_at فقط؛ لا توجد مشغلات workflow guard على purchase_invoice_details.

**الأثر:** أي مستخدم authenticated غير Inactive داخل الشركة يستطيع الوصول إلى DML على رؤوس الفواتير وتفاصيلها ضمن سياسة الشركة، دون المرور بالـEdge/RPC المركزي أو شرط Draft/received/posted أو صلاحية purchases. وهذا يتيح تجاوز مسار الترحيل المعتمد، حتى مع وجود purchase_post_invoice_atomic الذي يطبق حارس الاستلام عند استخدام RPC. هذه مخالفة فعلية لعقد التحكم المركزي الذي تقرره سياسة المالك في §77.4. لم أغيّر RLS أو grants.

**مسار الاستهلاك الذي تم التحقق منه:**
- Buyer الحالي يقرأ الفواتير عبر GET_DATA ويكتب عبر Edge.
- Parent main.html يقرأ purchase_invoices عبر getData المباشر، ويقرأ purchase_invoice_details مباشرة في مسار المرتجعات، لكنه ينفذ CREATE_INVOICE وPOST_INVOICE عبر Edge API. لم يظهر DML مباشر على جدولي الفواتير في هذه المواضع.
- purchasing/supervisor.html وoffice/accountant.html وoffice/finance-manager.html لم يظهر بها مرجع مباشر لهذين الجدولين.
- لذلك يجب الحفاظ على SELECT الذي يحتاجه Parent، وألا يُنفذ revoke DML شامل قبل استكمال consumer scan لبقية التطبيقات. لا توجد تغييرات grants في هذا التشغيل.

### D. سجلات التشغيل

خلال آخر 24 ساعة على endpoint save-purchase-order:
- 11,637 استجابة 200.
- استجابتان 504، مدة كل منهما نحو 160,020ms، عند 2026-11-02 14:41:29.865 UTC و16:15:00.353 UTC.
- سجلات 504 لا تحتوي execution_id أو version، ولم يظهر لها function execution/error log مطابق.

هذا يثبت وجود timeout على مستوى endpoint/gateway، لكنه لا يثبت أن العملية التجارية فشلت أو أن DB commit لم يحدث؛ السبب والأثر الفعلي UNKNOWN.

### E. Staging

- مشروع rawaea-staging موجود وحالته ACTIVE_HEALTHY.
- لكنه لا يحتوي save-purchase-order Edge function، ولا purchase_invoices ولا purchase_invoice_details.
- سجل migrations فيه 62 فقط، وآخرها 2026-10-27.
- لذلك هو ليس بيئة staging صالحة لاختبار Buyer الحالي، ولا يجوز اعتبار وجود المشروع دليلًا على جاهزية E2E.

### F. Deployment

- تعليق Cloudflare على PR يؤكد نجاح Preview build لمشروع rawaea-erp على commit 209c318.
- مشاريع Pages الأخرى erp-frontend وrawaea-store وwarehouse-supervisor أبلغت عن build failures؛ لا أخلطها مع نجاح Preview المشروع المستهدف.
- لم أتمكن من جلب HTML/JS المنشور أو headers مباشرة، ولم تتوفر جلسة Browser صالحة. كما أن core.js في هذا الفرع متصل بـ Production؛ لذلك لم أجرِ أي اختبار كتابة على Preview حتى لا يكتب إلى قاعدة Production.

---

## 3) UNKNOWN

1. هل «فواتيري» تعني قائمة عرض شخصية فقط أم حد سرية/صلاحية يمنع المستخدم من رؤية فواتير غيره؟ المصدر الحالي لا يحقق السرية.
2. ملفات SQL المصدر التي تقابل آخر migrations في Production لم تُعثر عليها في المسارات المفحوصة؛ يلزم تحديد موقعها ومطابقة محتواها قبل أي db push.
3. سبب استجابتي 504 غير معروف؛ لا يوجد execution_id أو function log يربطهما بعملية داخل الدالة.
4. هل السعر صفر مقبول تجاريًا للأصناف المجانية؟ DB يقبله؛ المطلوب فقط عدم تحويل blank بصمت إلى صفر.
5. خريطة كل المستهلكين المباشرين لجدولي الفواتير عبر جميع التطبيقات لم تكتمل؛ لا يجوز سحب DML grants قبل اكتمالها.

---

## 4) CONFLICT

### CONFLICT-1 — CURRENT_STATE مقابل Git الحي
- CURRENT_STATE عند البدء يذكر head 5ae94d7 و2 ahead/0 behind.
- Git الحي يثبت head 209c318 و3 ahead/2 behind، وBuyer blob 100987d.
- main تقدم بملفين توثيقيين فقط؛ لا يوجد تعارض source code، لكن checkpoint وhandoff القديمين لم يعودا يعكسان الحالة الحية.

### CONFLICT-2 — سياسة المالك مقابل RLS/ACL في Production
- سياسة §77.4 تتطلب المرور بعقد مركزي مضبوط للحالة والصلاحيات قبل تعديل/حذف/ترحيل الفاتورة.
- RLS/ACL الحاليان يسمحان للمستخدم authenticated داخل الشركة بعمليات INSERT/UPDATE/DELETE مباشرة على invoice header/details دون شرط صلاحية أو مالك أو Draft.
- هذا blocker أمني/محاسبي حقيقي، وليس مجرد ملاحظة UI.

### CONFLICT-3 — تعريف «فواتيري» مقابل تنفيذ PR
- تعريف المالك في LVE-585: سجل فواتير الشراء السريع التي ينشئها مسؤول المشتريات من السوق، مع صورة الفاتورة وبنود الأصناف والأسعار والكميات والمواصفات وصور الأصناف.
- PR الحالي يفلتر created_by فقط، بينما يسمح بإنشاء فاتورة مرتبطة بـ PO أو بلا PO.
- schema لا يحتوي invoice_type/source/quick_market marker؛ ووجود purchase_order_id وحده لا يثبت أن كل فاتورة بلا PO هي فاتورة سوق.
- جدول التفاصيل يحتوي notes، لكن create RPC لا يحفظ ملاحظات السطر؛ لا يوجد مسار صورة فاتورة في Buyer الحالي.
- إذن PR يحقق جزءًا من UX، ولا يحقق تعريف «فواتيري» كاملًا.

### CONFLICT-4 — «فواتيري» كقائمة عرض مقابل عقد البيانات
- GET_DATA يعيد فواتير الشركة كلها للمستخدم المصرح له بالمشتريات، ثم يفلتر المتصفح created_by.
- openInvoice لا يعيد فحص created_by.
- لذلك نص الواجهة «فواتيرك أنت فقط» لا يمثل حد صلاحيات أو سرية. إذا كانت السرية مطلوبة، فهي غير مطبقة.

---

## 5) UNVERIFIED

- HTML/JS الذي يقدمه Cloudflare فعليًا، headers/cache، وربط artifact بـ commit.
- Authenticated Browser E2E للبحث وإضافة PO وإنشاء/تعديل/حذف Draft invoice.
- نجاح CREATE_PO وCREATE_INVOICE الإيجابي في بيئة معزولة.
- هل أدى أي 504 سابق إلى commit ثم إعادة محاولة؛ لا توجد بيانات كافية لإثبات ذلك.
- الأثر الفعلي لمسح السعر في line editor داخل المتصفح؛ ثبت مسار الكود فقط.
- لا توجد E2E على staging؛ schema وEdge function المطلوبان غير موجودين هناك.

---

## 6) مصفوفة التحقق

| الطبقة | الحالة | ما ثبت | ما لم يثبت |
|---|---|---|---|
| GitHub / Source | CONFIRMED جزئيًا | HEADs، PR diff، blob، static parse، search checks | موافقة المالك والدمج |
| Supabase Production | CONFIRMED مع CONFLICT | v22 byte-match، migrations ledger، schema، RPCs، RLS/grants، counts | اختبار كتابة إيجابي آمن |
| Deployed artifact | UNVERIFIED | تعليق Preview success للمشروع المستهدف | HTML/JS served identity وheaders |
| Runtime / E2E | UNVERIFIED | سجلات endpoint وtimeouts | Browser authenticated flow |
| Business-data effects | CONFIRMED قراءة فقط | snapshot للأعداد؛ لا كتابة من هذا التشغيل | نجاح دورة PO/invoice/receiving/posting كاملة |

---

## 7) ما تم فعليًا

1. جلب CURRENT_STATE كاملًا وقراءة نقطة البداية والتعليمات الحاكمة.
2. إعادة جلب repo/branch/PR/HEAD/diff/commits/reviews/checks بدل اعتماد الأرقام السابقة.
3. فتح Buyer الحالي على الفرع وmain، وفتح core.js وapp.html وParent main.html والملفات التشغيلية المرتبطة.
4. مطابقة Edge v22 المنشور مع مصدر Git byte-for-byte.
5. فحص Production schema/migrations/RPCs/RLS/grants/triggers والبيانات ذات الصلة باستخدام SELECT فقط.
6. تنفيذ static parse للكتلة inline، والتحقق من التبويبات ومراجع cost_price، واختبار خوارزمية البحث على بيانات الأصناف الحية.
7. مراجعة سجلات endpoint لآخر 24 ساعة والتحقق من حالة staging.
8. تسجيل تعارض RLS/ACL، وفجوة quick-market classification، وفجوة CREATE_INVOICE idempotency، وblank-to-zero validation gap.

## 8) ما لم يتم ولماذا

- لم أعدل Buyer أو main.html أو core.js؛ PR ما زال Draft ولا توجد موافقة صريحة على changeset محدث.
- لم أغير RLS أو grants أو RPCs أو migrations؛ تعارض الصلاحيات يحتاج consumer scan وخطة rollback واختبارًا معتمدًا.
- لم أكتب بيانات أو أنشئ PO/Invoice في Production؛ لا توجد موافقة على positive writes.
- لم أدمج PR أو أنشر Cloudflare؛ §77.2 لم يتحقق.
- لم أنفذ Browser E2E؛ جلسة Browser غير متاحة، وstaging لا يحتوي الجداول/الدالة اللازمة، وPreview متصل بقاعدة Production.
- لم أعتبر تعليق Preview success إثباتًا لسلامة runtime أو business-data effects.

---

## 9) الخطوة التالية الواحدة ذات الأولوية

**إبقاء PR #10 في Draft، وتجهيز حزمة تغيير واحدة محددة لاعتماد المالك قبل الدمج، تبدأ بحسم حدود «فواتيري» ثم تعالج عقد الفواتير المركزي:**
- فصل فاتورة السوق عن الفاتورة المرتبطة بـ PO بعلامة مصدر/نوع واضحة وفق تعريف المالك.
- إغلاق DML المباشر على invoice header/details للمستخدم authenticated مع الحفاظ على SELECT الذي يحتاجه Parent، بعد إكمال consumer scan.
- تمرير operation_id ثابت من Buyer عند CREATE_INVOICE، وليس ترك Edge يولّد مفتاحًا جديدًا لكل إعادة طلب.
- إعادة التحقق من السعر لكل سطر عند الحفظ، مع الفصل بين blank وصفر مقصود.
- ثم تحديث staging إلى schema/Edge parity واختبار E2E هناك قبل أي Production approval.

لا يتم تنفيذ DDL أو تعديل grants/RLS أو merge/deploy قبل عرض SQL/diff الدقيق، الأثر، اختبارات القبول، وخطة rollback والحصول على موافقة صريحة على نفس changeset.

**الخلاصة:** Source patch موجود، وPO idempotency patch موجود في branch head الحالي، لكن المهمة ليست CLOSED ولا Production Ready. أهم blocker حالي هو direct authenticated DML على فواتير الشراء وتفاصيلها خارج المسار المركزي.
