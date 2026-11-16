# RAWAEA ERP — المراجعة التشغيلية اليومية / CTO

## LVE-2026-11-16-729 — تدقيق صلاحيات المشتريات، حواجز إنشاء فاتورة PO، وتطابق Parent/Buyer

**التاريخ:** 2026-11-16 (Africa/Cairo) 22:32  
**Checkpoint السابق:** LVE-2026-11-16-728 — دورة PR/PO وهوية القسم وصلاحيات Production  
**الهدف الحالي:** التحقق من عدم تغير المصدر أو Production منذ LVE728، وتوسيع تدقيق الكتابة المباشرة، وإثبات صلاحية اختيار PO غير المستلم على مستوى الواجهة والخادم، دون إنشاء أي بيانات اختبار أو إجراء تغيير تشغيلي.

**المستودع التشغيلي:** papamohammed77-glitch/erp-frontend  
**الفرع:** main  
**Operational HEAD:** ebb2a01d07c8dc1460bd4f577962a7b8c26be920  
**Parent main.html blob:** 1af4430e34bb5434327cb24a3dca50b538188f42  
**Core companies/company-1/core.js blob:** 2b2211a3f95049042e27a7b2ecbab3640a584942  
**Buyer blob:** db1d311966a676dd2c7210895afefef5b5d2a954  
**Purchasing Supervisor blob:** 916636b89f6e376b437a9328087b02de82c2610d  
**save-purchase-order source blob:** 22971afed19c1f23cc0038bb62e56c251202f05e  
**CURRENT_STATE قبل هذا التحديث:** blob f7a4a76ad49a817e890c04b392e672954952ff34  
**الدستور التشغيلي الدائم:** blob 3a6b1e220af8509e314e94df76563bbc6f84910d — تمت قراءته كاملًا  
**Report728:** blob df1cfa6c50b8916b528effa5e6a76bfb43853104  
**Supabase SMART ERP:** fiilmooggumokxanwiyx — ACTIVE_HEALTHY — PostgreSQL 17.6.1.121 — 795 migrations، أحدثها 20261116144311  
**save-purchase-order Production:** Version 44 ACTIVE، verify_jwt=true، live SHA 0bf7e223babdf1bf9ee61c3d90148b86934fdfcebe16015004b1a030be9f0791؛ محتوى Production مطابق لملف GitHub byte-for-byte.  
**الحكم:** READY WITH LIMITATIONS للقراءة والتحليل والتوثيق؛ BLOCKED لأي تعديل تشغيلي أو Production حتى استكمال فحص المستهلكين واعتماد Change Set محدد.

---

## 1. نقطة البداية — LAST VERIFIED EVENT / Checkpoint

- استؤنف العمل من LVE-2026-11-16-728، وليس من بداية المشروع.
- HEAD ما زال ebb2a01؛ لم يظهر Commit تشغيلي جديد بعد LVE728.
- مقارنة 8c26511 بـebb2a01 تؤكد أن التغييرات السابقة اقتصرت على Buyer وملف CSS الخاص به وEdge save-purchase-order؛ main.html وcore.js وsupervisor.html لم تتغير في تلك السلسلة.
- لا يوجد إغلاق جديد لدورة PR/PO منذ LVE728.
- آخر إغلاق معروف يخص دورة الاستلام/دقة الكميات/Idempotency في LVE727؛ لا يعاد فتحه لعدم وجود دليل Regression جديد.
- هدف هذه المراجعة هو استكمال CS-PRPO-728-A بالأدلة الحية، لا تنفيذ Migration أو تعديل واجهة دون اعتماد.

## 2. CONFIRMED — الحقائق المثبتة

### 2.1 GitHub / Source

1. تم جلب الملفات الكاملة ذات الصلة وتحليل المسارات:
   - companies/company-1/main.html
   - companies/company-1/core.js
   - companies/company-1/purchasing/buyer.html
   - companies/company-1/purchasing/supervisor.html
   - supabase/functions/save-purchase-order/index.ts

2. لا توجد تغييرات جديدة في main أو Core أو Supervisor منذ LVE728. Core الحالي هو blob 2b2211a3؛ لم يظهر ضمن ملفات المقارنة المتغيرة.

3. **Parent — اختيار PO في فاتورة الشراء:** main.html عند 13664–13689 ما زال يطلب الحالات Draft وConfirmed وApproved وPartially Received وReceived. لا يوجد شرط على qty_received. هذا يخالف قاعدة المالك الحالية.

4. **Buyer — اختيار PO:** buyer.html يطبق فلترًا على PO جديد: الحالة Approved، وجود تفاصيل، وعدم وجود أي سطر ذي qty_received أكبر من صفر تقريبًا. كما يحتفظ بأمر الفاتورة Draft المفتوحة كمرجعها الأصلي المقفول، لا كاختيار جديد. هذا صحيح على مستوى الواجهة فقط.

5. **Parent — أمر شراء مباشر:** RW_Purchases.savePO في main.html عند 12190–12202 يرسل body بالشكل القديم orderHeader/itemsList دون operation أو payload. أما Edge v44 فيقرأ body.operation ويعالج CREATE_PO عبر payload. زر «أمر شراء مباشر» في عرض RW_PurchaseGold يصل إلى RW_Purchases.renderPOS؛ لذلك يوجد مسار UI قابل للوصول بعقد قديم لا يطابق Edge الحالي. لم يُختبر Runtime، لكن عدم تطابق العقدين مثبت من المصدرين.

6. **Parent — RFQ:** main.html عند 12821–12824 يسمح بإنشاء RFQ من PR بحالة Approved أو Draft. Buyer لا يعرض إجراء إنشاء RFQ إلا للطلب Approved. قاعدة Production purchase_create_rfq_atomic تسمح هي الأخرى بـDraft أو Approved.

7. **Parent — تحويل عرض المورد:** main.html عند 13123–13127 يعرض التحويل إلى PO عند Submitted أو Accepted. Buyer يقتصر على Accepted. RPC Production يقبل Submitted أو Accepted ويملأ accepted_by/accepted_at تلقائيًا عند تحويل Submitted. هذا تجاوز لاعتماد العرض، وليس مجرد اختلاف عرض.

8. **Buyer — إنشاء فاتورة PO:** المسار يستخدم CREATE_PO_INVOICE، وليس CREATE_INVOICE. عملية الخادم purchase_create_po_invoice_atomic موجودة ومحمية بـSECURITY DEFINER وSET search_path فارغ، وتتحقق من المستخدم النشط وصلاحية purchases ومن المورد والعملة وIdempotency. لكنها لا تفرض أن PO معتمد، ولا أن جميع كمياته لم تستلم، ولا أن بنود الفاتورة تطابق بنود PO وكمياتها المتبقية.

9. **Parent — إنشاء الفاتورة:** المسار القديم يستخدم CREATE_INVOICE ويصل إلى purchase_create_invoice_atomic_v2 / purchase_create_invoice_atomic. الدالة لا تفرض حالة PO أو عدم وجود استلام. إعداد Production الحالي require_receiving_before_invoice=false، ولذلك لا يضيف هذا الإعداد حارسًا يمنع فاتورة PO مستلم أو Draft.

10. **Supervisor:** supervisor.html عند 98–102 لا يطلب approved_by وapproved_at في SELECT الخاص بطلبات PR، بينما detail summary يعرضهما. اعتماد PO في الواجهة مقيد بـpurchases_supervisor أو Owner، لكن Edge/RPC يسمحان أيضًا بصلاحية purchases.

11. لا يوجد في الملفات الثلاثة الأساسية التي فُحصت كتابة مباشرة واضحة على جداول PR/RFQ/Quotation المستهدفة؛ الكتابة الظاهرة تمر عبر Edge/RPC. هذا لا يثبت خلو بقية المستودع من مستهلكين مباشرين.

### 2.2 Supabase Production — الصلاحيات والمخطط

1. مشروع SMART ERP نشط وسليم على مستوى حالة المشروع، وعدد الـmigrations المطبقة 795، وآخرها 20261116144311. آخر أربع migrations تخص receiving وprecision وRLS/read scope، ولا تمثل إغلاقًا جديدًا لصلاحيات PR/RFQ/Quotation.

2. في 81 جدولًا عامًا:
   - RLS مفعّل على 81/81.
   - FORCE RLS مفعّل على 11 جدولًا.
   - توجد INSERT/UPDATE/DELETE grants لـanon على 78 جدولًا، ولـauthenticated على 81 جدولًا.
   - لا يوجد ضمن هذا القياس جدول عام يحمل DML grants دون RLS.
   - وجود RLS وحده لا يثبت سلامة السياسة؛ يجب فحص policy لكل جدول.

3. الجداول التالية تجمع بين DML grants وسياسة ALL TO public لا تتحقق إلا من company_id عبر current_user_company_id، دون فحص صلاحية وظيفية أو صاحب المستند أو القسم:
   - purchase_requests
   - purchase_request_details
   - purchase_rfqs
   - purchase_rfq_details
   - purchase_rfq_suppliers
   - purchase_quotations
   - purchase_quotation_details
   - purchase_document_links
   - purchase_status_history
   - purchase_settings
   - purchase_payments
   - purchase_payment_allocations

4. نتيجة ذلك: المستخدم authenticated النشط داخل الشركة يستطيع تجاوز بوابة Edge/RPC في هذه الجداول إذا اتصل مباشرة بـPostgREST؛ يستطيع تعديل/حذف طلب أو عرض أو تفاصيله أو روابط المستندات أو سجل الحالة، كما يستطيع تعديل إعدادات المشتريات أو إنشاء سجل دفعة مضلل. سياسة الشركة لا تعني صلاحية المشتريات.

5. anon لديه grants أيضًا، لكن current_user_company_id لا يملك سياق مستخدم نشط له؛ لذلك لا أساوي بين grant وجودي وبين نجاح كتابة anon. الخطر المؤكد هو authenticated داخل الشركة بسبب policy company-only.

6. توجد ضوابط سليمة يجب الحفاظ عليها:
   - purchase_orders وpurchase_order_details لا يملكان DML grants للمستخدمين العاديين.
   - purchase_invoices وتفاصيلها وpurchase_returns ودفاتر supplier_ledger وjournal_entries وtreasury وcash_box وinventory_log وstock_branches لا تمنح authenticated كتابة مباشرة في فحص الامتيازات الذي أجري.
   - receiving وreceiving_details لديهما grants على مستوى الجدول، لكن RLS policy الحالية لهما SELECT فقط؛ لم يثبت السماح بكتابة العميل.

7. purchase_status_history قابل للكتابة المباشرة ضمن الشركة ولا يوجد عليه Trigger يمنع UPDATE/DELETE أو يجعله Append-only. هذه ثغرة في سلامة سجل التدقيق.

8. purchase_document_links يملك FK إلى company_id وقيد Unique على مجموعة الرابط، لكنه لا يملك FK على source_id أو target_id ولا يثبت أن المستندين من نفس الشركة أو من النوع الصحيح عبر FK. ومع DML المباشر يمكن تزوير سلسلة المستندات.

9. purchase_payments وpurchase_payment_allocations يسمحان بكتابة مباشرة ضمن الشركة. هذا قد ينتج حالة دفع مضللة في المستندات، لكنه لا يثبت تحريك النقدية أو المورد: الأثر الفعلي يمر بمسار الدفع المركزي الذي يرحل cash/supplier ledger. لم ينفذ أي دفع في هذه المراجعة.

10. pg_default_acl في public يمنح anon وauthenticated امتيازات واسعة افتراضيًا على الجداول الجديدة، ويمنح EXECUTE افتراضيًا على الدوال الجديدة، تحت grantors postgres وsupabase_admin. هذا خطر مستقبلي واسع؛ إصلاحه على مستوى schema بالكامل قد يكسر مستهلكين آخرين، ولا ينفذ قبل حصرهم واعتماد المالك.

11. purchase_orders محمية من DML المباشر، لكن purchase_create_po_atomic وpurchase_approve_po_atomic وpurchase_create_po_invoice_atomic تمنح authenticated EXECUTE مع تحقق صلاحية داخل الدوال. هذا هو الاتجاه الصحيح الذي يجب الحفاظ عليه.

### 2.3 دورة PR/PO والبيانات الحية

1. لقطة Production الحالية:
   - purchase_requests = 1
   - purchase_rfqs = 0
   - purchase_quotations = 1
   - purchase_orders = 4
   - purchase_document_links = 5
   - purchase_status_history = 22

2. PR-1000 حالته Approved، ومقدم الطلب والمعتمد هما حساب المالك. لا يوجد في جدول PR department_id أو branch_id أو requested_by_user_id. لا يوجد في users عمود department_id. جداول hr_departments وhr_employee_assignments وemployee_profiles فارغة حاليًا.

3. PR-1000 يحتوي:
   - item 1001 — كمية 2
   - item 1004 — كمية 4

4. PO-20260930 حالته Draft، ويحتوي:
   - item 1001 — كمية 10
   - item 1019 — كمية 3
   - لا يطابق سطور PR-1000، ولا يوجد رابط PR→PO له.

5. PO-20260930 أنشئ قبل PR-1000 في نفس اليوم، لكن هناك تعارض زمني في التوثيق: القراءة الحية الحالية تعيد 2026-11-16 17:09:11.379156+00، بينما LVE728 سجل 17:09:32Z. الهوية والحالة والترتيب قبل PR ثابتة؛ القيمة الزمنية السابقة لا تعتمد قبل تفسير الفرق.

6. PQT-1000 حالته Converted وrfq_id=NULL، وأنشأ PO-20260929 بحالة Draft. لا يوجد RFQ ولا PR مصدر لهذا العرض.

7. PO-20260928 حالته Received وكل سطوره مستلمة بالكامل. QA-SR-PO-20260927 حالته Approved لكن qty_received=5؛ يظل مرجع QA تاريخيًا ولا يُعدّل أو يُستخدم كبيانات اختبار.

8. لا يوجد حاليًا مسار بيانات يثبت PR-1000 → RFQ → Quotation → PO. لا يجوز ربط PO-20260930 بالطلب بأثر رجعي؛ السطور والتوقيت والرابط لا تسند ذلك.

9. purchase_settings الحالية:
   - require_request_approval=true
   - require_receiving_before_invoice=false
   - require_invoice_before_payment=true
   - default_branch_id=NULL

### 2.4 عقود الدوال

- purchase_approve_request_atomic يقبل Draft وPendingApproval وSubmitted؛ لا يثبت فصل مقدم الطلب عن المعتمد.
- purchase_reject_request_atomic يقبل Submitted وApproved والحالة العربية المقدمة/المعتمدة، لكنه لا يقبل PendingApproval رغم أن Buyer يعرض زر الرفض لهذه الحالة.
- purchase_create_rfq_atomic يقبل Draft أو Approved ويحوّل PR إلى Converted عند إنشاء RFQ، قبل وجود PO. توقيعه لا يحمل operation_id، فلا يوجد idempotency contract ظاهر لإنشاء RFQ.
- Buyer ينفذ CREATE_RFQ ثم SEND_RFQ في طلبين منفصلين؛ فشل الإرسال بعد الإنشاء قد يترك RFQ Draft وPR محولًا، وإعادة المحاولة لا تملك مفتاح idempotency موحدًا.
- purchase_convert_quotation_to_po_atomic يقبل Submitted أو Accepted ويستطيع إكمال بيانات القبول أثناء التحويل.
- purchase_approve_po_atomic يسمح purchases أو purchases_supervisor، ولا يمنع منشئ PO من اعتماد أمره.
- purchase_create_po_invoice_atomic يرفض Cancelled فقط في فحص PO، ولا يتحقق من Approved أو qty_received=0 أو مطابقة بنود الفاتورة مع PO؛ ثم يضبط receipt_status='NOT_RECEIVED' دون إثبات أن PO غير مستلم.
- purchase_create_invoice_atomic لا يفرض حالة PO أو عدم الاستلام؛ إعداد require_receiving_before_invoice=false حاليًا.
- purchase_create_po_atomic يكتب سجل Created يدويًا، كما أن Trigger trg_purchase_orders_status_history يسجل INSERT. Production يعرض تكرارًا فعليًا لسجل الإنشاء في PO-20260928 وPO-20260930.

### 2.5 Edge Functions

- إجمالي Edge Functions = 100.
- verify_jwt=false = 16:
  - 13 endpoint قديمًا/اختبارًا يعيد 410 retired ولا ينفذ العملية.
  - create-stock-voucher يتحقق يدويًا من Bearer token عبر auth.getUser ثم يستدعي RPC؛ لم يثبت في هذا النطاق وجود bypass جديد، لكن مصفوفة الصلاحيات الداخلية له تحتاج مراجعة مستقلة.
  - submit-online-order مسار متجر عام يستخدم storefront/API key؛ لا يُعامل كمسار مستخدم موظف.
- save-purchase-order v44 يبقى verify_jwt=true ومطابقًا للمصدر.
- لا Edge Function جديدة أنشئت.

## 3. UNKNOWN — ما لا تسمح الأدلة الحالية بحسمه

1. لا نعرف بعد كل مستهلك مباشر لجداول المشتريات على مستوى المستودع؛ GitHub Code Search index غير متاح للمستودع في هذه الجلسة، ولا توجد أداة شجرة مستودع كاملة متاحة هنا.
2. لا نعرف ما إذا كان مسار PO المباشر استثناءً تجاريًا معتمدًا أم يجب منعه لصالح PR إلزامي.
3. لا توجد هوية قسم/فرع معتمدة للموظفين يمكن ربطها بطلب PR حاليًا.
4. لا توجد أدلة تشغيل ميداني على دورة PR→PO→استلام→فاتورة→سداد كاملة.
5. لا توجد قياسات Forecast/Actual أو Latency/Realtime تصلح لدرجة نضج.
6. لم تُعد مراجعة فرق 20 EGP بين حساب الموردين والتحكم GL من LVE727 في هذا التشغيل؛ يظل OPEN كما هو.
7. لا يمكن تحديد أثر جميع 16 دالة verify_jwt=false على بقية النظام من عينة الفحص وحدها؛ 13 مغلقة بـ410، وثلاثة مسارات وظيفية لها نماذج مصادقة مختلفة.

## 4. CONFLICT — التعارضات

1. **توقيت PO-20260930:** CURRENT_STATE/Report728 سجلا 17:09:32Z؛ القراءة الحية الآن 17:09:11.379156+00. لا يتغير استنتاج أن PO سبق PR، لكن لا تعتمد القيمة القديمة.
2. **Parent مقابل Buyer:** Parent يعرض حالات PO غير المؤهلة، بينما Buyer يطبق Approved + تفاصيل + صفر استلام.
3. **واجهة الفاتورة مقابل الخادم:** Buyer يخفي PO Draft/Received، لكن purchase_create_po_invoice_atomic لا يفرض نفس الشروط.
4. **واجهة الرفض مقابل RPC:** Buyer يعرض Reject لـPendingApproval، بينما purchase_reject_request_atomic لا يقبل هذه الحالة.
5. **صلاحية اعتماد PO:** Supervisor UI تتطلب purchases_supervisor، بينما Edge/RPC تقبل purchases أيضًا.
6. **معنى Converted:** دالة RFQ تجعل PR Converted عند إنشاء RFQ، بينما المعنى التجاري الذي أكده المالك هو أن PR يتحول إلى PO؛ لا يوجد تعريف حالة وسيط واضح.

## 5. UNVERIFIED — نتائج لم تختبر مباشرة

- Artifact المنشور على Cloudflare Pages لم يُقرأ byte-for-byte في هذا التشغيل.
- لم تتوفر جلسة Browser مصادق عليها؛ لم يُفتح التطبيق المنشور ولم تُفحص Console/Network.
- لم يُنفذ Browser E2E أو Runtime E2E.
- لم يُختبر وصول Realtime أو reconnect أو latency أو تعدد المستخدمين.
- لم يُنفذ اختبار قاعدة بيانات على Production أو Staging.
- لا يوجد Staging معزول تم التحقق من مخططه وتطابقه في هذا التشغيل.
- لا يوجد إثبات أن التعديلات السابقة على Buyer ظهرت في النسخة المنشورة الحالية.

## 6. مصفوفة التحقق

| الطبقة | الحالة | الدليل | القيد |
|---|---|---|---|
| GitHub / Source | CONFIRMED | HEAD ebb2a01 والـblobs الحالية؛ ملفات Parent/Buyer/Supervisor/Edge/Core | Code Search index غير متاح؛ لا repository-wide scan |
| Supabase Production | CONFIRMED | SMART ERP ACTIVE_HEALTHY، 795 migrations، catalog/RLS/ACL/RPC/بيانات قراءة فقط | لم تُنفذ كتابة أو Migration |
| Deployed Artifact | UNVERIFIED | آخر دليل تاريخي في LVE728 فقط | لا قراءة حية للـCloudflare artifact أو headers/cache |
| Runtime / E2E | UNVERIFIED | لا Browser مصادق عليه ولا CI status جديد | لم يُجر اختبار تشغيلي |
| Business-Data Effects | CONFIRMED: لا أثر جديد | كل استعلامات DB قراءة فقط | لا توجد معاملات اختبار أو تغييرات |
| Staging | UNKNOWN | لا بيئة معزولة تم التحقق منها | لا اختبارات QA |

## 7. ما تم فعليًا

1. استعادة CURRENT_STATE كاملًا، 2396 سطرًا، وقراءة الدستور كاملًا، 310 أسطر، قبل مراجعة الكود.
2. مراجعة Report728 وReport727 والتقارير التاريخية ذات الصلة: Report569 و571 و599 و633 و680.
3. التحقق من HEAD وملفات المصدر وCore وEdge.
4. مقارنة save-purchase-order المنشور مع GitHub؛ التطابق كامل.
5. فحص مخطط PR/RFQ/Quotation/PO والفواتير والدفع وسجل الحالة والروابط.
6. فحص RLS policies وgrants وdefault privileges وtriggers وconstraints وRPC signatures.
7. إعادة قراءة بيانات PR/PO الحالية وتحديد عدم وجود سلسلة PR-originated PO.
8. حصر 16 Edge Function بـverify_jwt=false وتصنيف 13 منها على أنها retired/410.
9. إعداد أدلة Change Set جديدة؛ لم يطبق أي تغيير تشغيلي.

## 8. ما لم يتم ولماذا

- لم تُسحب أي صلاحيات DML؛ لأن فحص جميع المستهلكين المباشرين للمستودع لم يكتمل، والتغيير يمس عقدًا مشتركًا.
- لم تُعدّل main.html أو Buyer أو Supervisor؛ الدستور يطلب أن يطبق المالك تغييرات التطبيقات التشغيلية بعد عرض المقطع والأثر.
- لم تُنفذ Migration أو RPC write؛ لا توجد موافقة على Change Set محدد.
- لم تُنشأ QA fixtures؛ توجيه المالك الأحدث في هذه المهمة يمنع اختبار Production دون استثناء منفصل وصريح.
- لم يُنفذ E2E؛ لا Browser مصادق عليه ولا Staging موثق.
- لم يُحذف أي QA anchor أو مستند قائم.

## 9. صحة التطبيقات والتغطية

| النطاق | فُحص اليوم | النتيجة |
|---|---|---|
| Parent main.html | نعم، مسارات PR/RFQ/Quotation/PO/Invoice | عدة اختلافات عقدية مؤكدة؛ لا Runtime |
| Buyer.html | نعم، PR/PO/Invoice paths | فلتر PO الجديد صحيح في UI؛ الخادم لا يفرضه |
| Purchasing Supervisor | نعم، PR metadata وPO approval | SELECT ناقص؛ UI gate أضيق من Edge/RPC |
| save-purchase-order Edge | نعم، v44 + تطابق المصدر | العقد المركزي قائم؛ مسار Parent القديم لا يطابقه |
| core.js | تحقق blob والمسار وعدم تغيره | لا تغيير منذ LVE728؛ لم تُعد مراجعة كل وحداته |
| Receiver | لم يُعد E2E؛ لا تغيير مصدر منذ LVE728 | عقود الاستلام المغلقة في LVE727 تبقى دون إعادة فتح |
| بقية التطبيقات | لم تفحص اليوم | لا تعميم على سلامتها |

**Edge security coverage:** 13 من 16 endpoint ذات verify_jwt=false تعيد 410. create-stock-voucher وsubmit-online-order وظيفيان بنموذج مصادقة مختلف، ويحتاجان تدقيقًا مستقلًا خارج نطاق PR/PO. لا يوجد دليل في هذه المراجعة على أن endpoint retired ينفذ كتابة.

## 10. تدقيق التعديلات الأخيرة وآثارها

- لم يتغير operational HEAD بعد LVE728.
- Buyer source يتضمن فلتر PO الجديد؛ Parent لم يتغير وما زال يعرض الحالات Draft/Confirmed/Approved/Partially Received/Received.
- save-purchase-order v44 يطابق GitHub، لذلك عدم توافق Parent direct PO ناتج عن payload قديم في main، لا عن اختلاف Edge بين Git وProduction.
- آخر أربع migrations Production تخص receiving فقط؛ لا يظهر إغلاق جديد لصلاحيات جداول PR/RFQ/Quotation.
- لا دليل نشر جديد أو Runtime بعد آخر نقطة موثقة في LVE728.

## 11. الأخطاء والفجوات والسبب الجذري

### P0 — الكتابة المباشرة في دورة المشتريات وسجل التدقيق

**السبب المثبت:** DML grants مع سياسات ALL company-only؛ policy لا تفحص صلاحية العمل أو صاحب الطلب أو القسم. سجل الحالة والروابط قابلان للتعديل المباشر. Default privileges توسع المشكلة إلى الجداول والدوال المستقبلية.

**الأثر:** تجاوز CREATE/APPROVE/REJECT/CONVERT المركزي، تغيير الحالة دون RPC، تزوير روابط PR/PO، تعديل سجل التدقيق، تغيير إعدادات الشراء، وإضافة سجلات دفع مضللة.

**ما لم يثبت:** لم يثبت أن الكتابة المباشرة أحدثت أثرًا على treasury أو supplier_ledger أو journal_entries؛ هذه الجداول محمية من DML المباشر في الفحص الحالي، والأثر النقدي يمر بمسار مركزي.

### P1 — خادم فاتورة PO لا يفرض أهلية PO

**السبب:** purchase_create_po_invoice_atomic يتحقق من أن PO ليس Cancelled فقط، ولا يشترط Approved أو qty_received=0، ولا يطابق item lines/qty مع purchase_order_details. ثم يضع receipt_status='NOT_RECEIVED' دون فحص حقيقة الاستلام.

**الأثر:** يمكن لعميل مصادق بصلاحية purchases تجاوز فلتر Buyer وإنشاء Draft invoice على PO مستلم أو Draft أو بسطور/كميات لا تطابق PO. لا يثبت ذلك ترحيل مخزون أو قيد في هذه الخطوة، لكنه ينشئ حالة فاتورة غير صحيحة ويضعف ضوابط المطابقة.

**الملفات/الدوال:** buyer.html، main.html، Edge save-purchase-order، purchase_create_po_invoice_atomic، purchase_create_invoice_atomic.

### P1 — Parent invoice selector غير متوافق مع قاعدة المالك

Parent يعرض كل الحالات المذكورة ولا يقرأ qty_received؛ Buyer وحده يرشح PO المعتمد غير المستلم. Production لا يحتوي حاليًا PO جديدًا مؤهلًا وفق قاعدة Buyer؛ العدد 0، بينما Parent يعيد 4.

### P1 — Parent direct PO يرسل عقدًا قديمًا

RW_Purchases.savePO يرسل orderHeader/itemsList دون operation/payload، بينما Edge v44 يتطلب CREATE_PO داخل operation/payload. المسار قابل للوصول من زر «أمر شراء مباشر». لا يُصلح هذا المسار قبل قرار المالك بشأن السماح بالـPO المباشر.

### P1 — دورة PR/PO لا تمثل قرار المالك بدقة

- لا department_id أو branch_id أو requested_by_user_id في PR.
- CREATE_REQUEST يتطلب purchases، فلا يستطيع موظف قسم بلا صلاحية المشتريات إنشاء PR من المسار الحالي.
- PR approval لا يملك صلاحية مستقلة عن purchases ولا يمنع self-approval.
- Draft يمكن اعتماده أو تحويله إلى RFQ من Parent.
- PR يتحول إلى Converted عند RFQ، قبل إنشاء PO.
- Submitted quotation يمكن تحويله إلى PO ويُملأ له قبول تلقائيًا.
- مسار PO مباشر ومسار quotation بلا RFQ يسمحان بإنشاء PO دون PR.

### P1 — رفض PR بحالة PendingApproval يفشل تعاقديًا

Buyer يعرض Reject لهذه الحالة، لكن purchase_reject_request_atomic لا يقبل PendingApproval. لا يوجد اختبار Runtime، لكن mismatch في العقد مؤكد.

### P1 — عدم منع اعتماد المنشئ لأمره

purchase_approve_po_atomic يسمح purchases أو purchases_supervisor ولا يقارن المعتمد بـcreated_by. Supervisor UI أشد من الخادم، وبالتالي يمكن لمستخدم purchases تجاوز قيد الواجهة باستدعاء Edge/RPC المسموح.

### P1 — ازدواج سجل إنشاء PO

Trigger trg_purchase_orders_status_history يسجل INSERT، ودالة purchase_create_po_atomic تضيف سجل Created يدويًا. Production يظهر حدثي إنشاء لنفس PO في PO-20260928 وPO-20260930. يلزم الإبقاء على مصدر تاريخ واحد.

### P2 — RFQ غير Idempotent وعمليتا الإنشاء/الإرسال منفصلتان

purchase_create_rfq_atomic لا يحمل operation_id؛ Buyer ينفذ CREATE_RFQ ثم SEND_RFQ منفصلًا. فشل الإرسال قد يترك RFQ Draft وPR Converted، وإعادة المحاولة قد تنشئ RFQ مكررًا.

### P2 — Supervisor PR metadata وRealtime

SELECT لا يطلب approved_by/approved_at رغم استخدامهما في summary. اشتراكات Supervisor لا تشمل تفاصيل PR/PO والروابط وسجل الحالة؛ لا يوجد قياس latency.

## 12. الكفاءة التشغيلية والميدانية

| السيناريو | التصميم/الكود | النشر | إثبات التشغيل |
|---|---|---|---|
| موظف قسم ينشئ PR | غير مكتمل؛ لا department identity أو permission | غير مثبت | غير مختبر |
| اعتماد PR | RPC موجود لكن maker-checker غير مكتمل | Edge موجود | غير مختبر |
| PR إلى RFQ | موجود لكن Draft مسموح وConverted مبكر | المصدر موجود | لا RFQ حالي |
| RFQ إلى عروض الموردين | علاقات الجداول موجودة | غير مثبت Runtime | لا RFQ حالي |
| قبول عرض وتحويله إلى PO | موجود لكن Submitted يقبل التحويل | Edge موجود | لا سلسلة PR-originated |
| PO مباشر | مسار موجود في Buyer؛ Parent payload قديم | Edge v44 | لا اختبار |
| اعتماد PO | RPC وSupervisor UI | Edge v44 | لا اختبار maker-checker |
| فاتورة PO | UI Buyer مضبوط جزئيًا؛ Parent غير مضبوط؛ server guard ناقص | RPC موجود | لا اختبار |
| استلام PO | مسار Receiver قائم من LVE727 | لم يُعد فحصه اليوم | لا دورة كاملة اليوم |
| السداد والمورد | المسار المركزي موجود | لم يُفحص Runtime | لا أثر مالي جديد |

لا يوجد دليل اليوم على دورة تشغيل كاملة من احتياج قسم إلى PR معتمد ثم PO مرتبط ثم استلام وفاتورة وسداد. وجود الجداول أو الشاشات لا يثبت اكتمالها.

## 13. التخطيط والتنبؤ ومركز القرار الذكي

UNKNOWN في هذا التشغيل. لا توجد بيانات قسم/فرع مكتملة على PR ولا قياسات Forecast مقابل Actual. لا تُمنح درجة تنبؤ أو توصية شراء ذكية. بعد تثبيت هوية PR، يمكن ربط الاحتياج بالمخزون المتاح والمحجوز والطلبيات المفتوحة ومخزون الأمان، ثم قياس الخطأ الفعلي.

## 14. المقارنة التنافسية

لم يُنفذ Benchmark جديد في هذا التشغيل. تبقى مقارنة Report728 مرجعًا محدودًا لـPR/PO مع Microsoft Dynamics 365 وSAP S/4HANA وDaftra وOdoo وManager.io. الدلالة المستمرة: RAWAEA يحتاج فصلًا واضحًا بين إنشاء PR واعتماده، وربط القسم ومقدم الطلب، ثم تحويل العرض المقبول إلى PO مع provenance واضح. لم يُحدد بعد أي منتج مقصود باسم Next ERP؛ لا تُنسب له خصائص.

## 15. مصفوفة نضج المجالات الاثني عشر

| المجال | الدرجة | الثقة | الحالة في هذا التشغيل |
|---|---:|---|---|
| السلامة التقنية والمعمارية | 2/5 | متوسطة | Edge/Core موجودان؛ direct DML grants وسياسات واسعة |
| تكامل التطبيقات والبيانات | 2/5 | عالية ضمن المشتريات | Parent/Buyer/Supervisor لا يطبقون عقدًا موحدًا |
| العمليات التجارية | 2/5 | عالية ضمن المشتريات | PR/RFQ/Quote/PO جزئية؛ لا دورة ميدانية مثبتة |
| الرقابة المالية والمحاسبية | UNKNOWN | منخفضة | لم تُراجع دورة الدفع كاملة؛ فرق 20 EGP السابق OPEN |
| المخزون وسلاسل الإمداد | 2/5 | متوسطة | استلام PO موجود؛ لا سلسلة PR-originated PO مثبتة |
| التوزيع والعمل الميداني | UNKNOWN | منخفضة | خارج نطاق الفحص |
| التخطيط والتنبؤ | UNKNOWN | منخفضة | لا Forecast/Actual |
| التقارير وBI | UNKNOWN | منخفضة | لم تُفحص |
| الأمان والصلاحيات والتدقيق | 1/5 | عالية | DML company-only على مستندات وسجل تدقيق المشتريات |
| الأداء والاستقرار والتوسع | UNKNOWN | منخفضة | لا Runtime/Latency |
| تجربة المستخدم والإنتاجية | 2/5 | عالية ضمن المشتريات | Parent وBuyer يعرضان قواعد مختلفة |
| الجاهزية التشغيلية والتنافسية | 1/5 | متوسطة | P0 صلاحيات وP1 عقد الفاتورة ودورة PR/PO مفتوحة |

لا يوجد متوسط إجمالي. الدرجات محصورة في الأدلة الحالية ولا تعني تقييم كل تطبيق.

## 16. خريطة النظام الأم والقلب المركزي والعقود

- Parent: companies/company-1/main.html؛ يحتوي RW_PurchaseGold ومسارات PR/RFQ/Quotation/PO/Invoice، إضافة إلى RW_Purchases legacy direct PO.
- Core: companies/company-1/core.js؛ blob 2b2211a3، لم يتغير في هذه السلسلة.
- Buyer: companies/company-1/purchasing/buyer.html؛ يقرأ بيانات الشراء ويستدعي save-purchase-order.
- Supervisor: companies/company-1/purchasing/supervisor.html؛ قراءة المستندات واعتماد PO.
- Edge: supabase/functions/save-purchase-order/index.ts؛ Version 44 مطابق للمصدر.
- PR: purchase_requests + purchase_request_details.
- RFQ: purchase_rfqs.request_id + purchase_rfq_details + purchase_rfq_suppliers.
- Quotation: purchase_quotations.rfq_id + purchase_quotation_details.
- PO: purchase_orders + purchase_order_details.
- روابط المصدر: purchase_document_links.
- سجل الحالة: purchase_status_history.
- الإعدادات: purchase_settings.
- الفجوة: PR لا يحمل هوية القسم/الفرع/مقدم الطلب كمعرفات، وPO لا يحمل request_id مباشرًا؛ سلسلة المستندات غير مكتملة في البيانات الحالية.

## 17. مصفوفة المزامنة وRealtime

| التطبيق | الآلية المصدرية | النقص |
|---|---|---|
| Parent | Realtime على رؤوس المستندات | لا تفاصيل/links/history ضمن الاشتراك الحالي |
| Buyer | Realtime أوسع يشمل تفاصيل وروابط وحالة مع reconcile دوري | لا قياس وصول أو latency |
| Supervisor | Realtime على رؤوس المستندات | لا تفاصيل وروابط/history |
| Receiver | اشتراكات الاستلام وPO من العمل السابق | لم يُختبر reconnect أو أثر تغيير PO اليوم |

لم يُختبر حدث مباشر أو reconnect أو concurrent update. وجود listener لا يثبت وصول الحدث أو حداثة العرض.

## 18. جاهزية المساعد واستلام شعلة التطوير

**READY WITH LIMITATIONS** للقراءة والتحليل والتوثيق:
- نقطة الاستئناف LVE728 مستعادة.
- CURRENT_STATE والدستور والتقارير المرجعية قُرئت.
- Source وProduction catalog وRPC/Edge وبيانات PR/PO الحالية فُحصت.
- الملفات والعقود ذات الصلة محددة.

**BLOCKED** لأي تغيير تشغيلي:
- repository-wide direct DML scan غير مكتمل.
- موافقة المالك على Change Set محدد غير موجودة.
- لا Browser مصادق عليه ولا E2E.
- لا Staging موثق.
- توجيه المالك الحالي يمنع QA على Production دون استثناء منفصل وصريح.

## 19. الالتزام بالدستور التشغيلي الدائم

- تمت قراءة doc/Draft/Reprots/الدستور التشغيلي الدائم.md كاملًا؛ SHA 3a6b1e220af8509e314e94df76563bbc6f84910d.
- طُبقت §6.2: لم ينفذ أي تعديل مؤثر دون Change Set محدد وموافقة صريحة.
- طُبقت §7: لم تُعدل ملفات النظام الأم أو التطبيقات التشغيلية؛ لا ادعاء بصلاحية غير متاحة.
- طُبقت §8–§13: قراءة المصدر الحي، فحص العقود، عدم إعادة فتح الإغلاقات بلا دليل، وتوثيق الحالة الجديدة.
- السياسة المالية/المخزنية §6.3 محفوظة: Draft/PR/PO لا تنشئ أثر مخزون أو نقد أو دفتر بمجرد الإنشاء أو الاعتماد.
- توجيه المهمة الأحدث يمنع إنشاء QA أو معاملات اختبار في Production؛ يتقدم على سماح §6.4 الأقدم في هذه المراجعة.
- كل استعلامات Production كانت SELECT/catalog reads فقط. لم يحدث DDL أو DML أو RPC write أو نشر.

## 20. المخاطر والاعتماديات والقرارات المطلوبة من المالك

1. اعتماد Change Set محدد لإغلاق DML المباشر على جداول المشتريات، بعد اكتمال مسح جميع المستهلكين.
2. تحديد سياسة default privileges العامة؛ التغيير يؤثر في الجداول والدوال المستقبلية على مستوى public، ولا يدمج مع إصلاح procurement المحدود دون تحليل شامل.
3. اعتماد صاحب إنشاء PR وصاحب اعتماده: مدير القسم أم مشرف المشتريات أم موافقات متعددة المراحل.
4. اعتماد مصدر القسم والفرع: HR assignment أم ربط إداري آخر؛ لا توجد بيانات HR حالية.
5. تحديد سياسة PO المباشر: استثناء مضبوط أم منع.
6. اعتماد قاعدة PO invoice: Approved فقط، تفاصيل موجودة، qty_received=0 لكل البنود، والتحقق نفسه خادميًا؛ الفاتورة Draft لا ترحل أثرًا.
7. اعتماد منع self-approval لـPR وPO، وتحديد Owner override المسجل.
8. اعتماد معنى حالات PR الوسيطة: Submitted/PendingApproval/Approved/Sourcing/PartiallyOrdered/Ordered؛ لا تستخدم Converted عند إنشاء RFQ.
9. اعتماد إزالة ازدواج status history من مصدر واحد.
10. إتمام repository-wide DML consumer scan قبل REVOKE؛ Code Search index غير متاح حاليًا.

## 21. الخطوة التالية الواحدة ذات الأولوية

**CS-PRPO-729-A — استكمال Repository-wide Direct DML Consumer Census ثم تجهيز إغلاق DML/RLS لجداول المشتريات وسجل التدقيق.**

السبب: الخطر P0؛ الكتابة المباشرة تسمح بتجاوز مسارات الموافقة وتعديل audit history.  
النطاق الأولي المثبت: purchase_requests, purchase_request_details, purchase_rfqs, purchase_rfq_details, purchase_rfq_suppliers, purchase_quotations, purchase_quotation_details, purchase_document_links, purchase_status_history, purchase_settings, purchase_payments, purchase_payment_allocations.  
المطلوب قبل التنفيذ: حصر كل مستهلك في Parent/Buyer/Supervisor وبقية التطبيقات وEdge/RPC، تحديد ما إذا كانت أي كتابة مباشرة لازمة، ثم إعداد REVOKE/GRANT محدد يحافظ على SELECT ويُبقي الكتابة عبر RPC/Edge المصرح.  
**لا Migration ولا تعديل Source قبل عرض SQL/المقاطع والأثر والاختبارات وخطة التراجع واعتماد المالك.**

### Change Sets التالية بعد CS-PRPO-729-A

- **CS-PRPO-729-B — PO Invoice Eligibility:** توحيد Parent/Buyer والخادم؛ قبول PO معتمد غير مستلم فقط، التحقق من بنود PO والكميات المتبقية، وعدم كتابة receipt_status دون تحقق.
- **CS-PRPO-729-C — PR Department Identity & Approval:** إضافة هوية مقدم الطلب والقسم والفرع من مصدر موثوق، وصلاحيات إنشاء/اعتماد منفصلة، ومنع self-approval.
- **CS-PRPO-729-D — PR/RFQ/Quotation/PO State Machine:** Draft لا يتحول؛ رفض PendingApproval يعمل؛ RFQ idempotent؛ Submitted quotation لا يتحول؛ Accepted فقط؛ PR لا يصبح Ordered/Converted قبل وجود PO مرتبط.
- **CS-PRPO-729-E — Parent Direct PO Contract:** إما إصلاح المسار ليتبع CREATE_PO contract المركزي إذا كان PO المباشر استثناءً معتمدًا، أو تعطيل المدخل إذا كانت سياسة المالك PR-first.
- **CS-PRPO-729-F — Audit History:** إزالة ازدواج إنشاء PO، وجعل سجل الحالة Append-only للمستخدمين العاديين.

### خطة القبول وعدم التراجع

- لا direct DML لمستخدم authenticated على جداول المستندات/التدقيق بعد إغلاق الصلاحيات؛ SELECT الحالي يظل يعمل.
- كل كتابة تمر بمسار مركزي يتحقق من المستخدم والشركة والقسم والفرع والصلاحية.
- لا يمكن إنشاء RFQ من Draft أو رفض PendingApproval يفشل.
- لا يمكن تحويل Submitted quotation إلى PO.
- لا يستطيع منشئ PR/PO اعتماد مستنده إلا وفق Owner override معتمد ومسجل.
- لا يمكن إنشاء فاتورة PO على Draft أو مستلم أو بكمية/صنف خارج PO؛ ولا يحدث مخزون/خزينة/دفتر من إنشاء المسودة.
- Parent وBuyer وSupervisor يعرضون نفس حالة المستند ومصدره.
- لا تتكرر status history، ولا يمكن تعديل/حذف التاريخ من مستخدم عادي.
- لا تنفذ اختبارات أعمال على Production في هذه المرحلة. اختبارات القبول تتطلب بيئة معزولة موثقة أو استثناء QA منفصلًا صريحًا.
- التراجع يعيد الامتيازات/السياسات السابقة فقط إذا فشل اختبار القراءة/الكتابة المعتمد؛ لا يحذف مستندات أعمال ولا يعكس قيودًا أو مخزونًا.

### المراجع

- CURRENT_STATE.md
- الدستور التشغيلي الدائم.md
- Report569, Report571, Report599, Report633, Report680
- Report727_PURCHASE_RECEIPT_IDEMPOTENCY_AND_PARENT_INVOICE_STATE_CLOSURE_20261116.md
- Report728_DAILY_CTO_REVIEW_PR_PO_LIFECYCLE_20261116.md
- Parent: companies/company-1/main.html
- Buyer: companies/company-1/purchasing/buyer.html
- Supervisor: companies/company-1/purchasing/supervisor.html
- Core: companies/company-1/core.js
- Edge: supabase/functions/save-purchase-order/index.ts

**نهاية LVE-2026-11-16-729 — لا تغييرات تشغيلية أو Production في هذا التشغيل.**
