# تقرير 629 — Buyer Quick Market Supplier Search / Storage Access Boundary / LVE629
**التاريخ:** 4 نوفمبر 2026 — Africa/Cairo  
**نقطة البداية:** LVE628  
**النطاق:** استمرار Buyer Phase 1 دون لمس Parent/Core/Receiver/Vouchers.

## 1. التغيير الإضافي المنفذ

أضفت حقل بحث فوري للمورد داخل نافذة Quick Market في الملف نفسه:
- Repo: `papamohammed77-glitch/erp-frontend`
- File: `companies/company-1/purchasing/buyer.html`
- Commit: `a35cd59fab199e1614536cd4ce5421179a907608`
- Blob: `0ac1cd20c5e879405b7d11af7a3349124ea374cf`
- الفرق عن commit LVE628 السابق `240858a`: ملف واحد فقط، 13 إضافة و1 حذف.
- البحث يفلتر خيارات الموردين النشطين المحملة مسبقًا في النافذة، ويطابق نص الخيار الذي يحتوي اسم المورد وكوده، مع الحفاظ على المورد المحدد عند البحث.

**حد الوظيفة:** هذا بحث محلي في القائمة المحملة من `GET_DATA`، وحد القراءة الحالي 500 سجل. ليس بحثًا خادميًا مع pagination؛ إذا تجاوز عدد الموردين النشطين حد القراءة يجب ترقية الاستعلام إلى بحث خادمي محدود ومؤمن بدل الادعاء بأن البحث شامل.

## 2. إعادة التحقق من حالة التغييرات السابقة

- Buyer source الحالي أُعيد جلبه من GitHub؛ blob الحالي يثبت وجود:
  - حماية إثبات المورد عند نتيجة RPC مجهولة.
  - اشتراك `buyer_goods_custody_events` في Realtime.
  - تحديث تبويبي `vehicle` و`invoices`.
  - حقل `bqm-supplier-search` وفلترة خيارات المورد.
- Edge `save-purchase-order` لا يزال v26 ACTIVE مع SHA-256 `fb31ac953213d6f30a9e545f1da3b9075ca28638b5032450618769d20f2cb5b4`.
- SQL migration `20261104213909` والدوال الثلاث كما في Report628.
- لا بيانات اختبار ولا أثر مالي/مخزني جديد.

## 3. اكتشاف إضافي مهم — صلاحية قراءة ملفات Buyer

أعدت فحص Storage policies بدل الاكتفاء بتطابق مسار الملف مع دوال الشركة/الموظف:

- `employee_docs_storage_insert` تسمح للمستخدم النشط بالرفع إلى `employee-documents` عندما يطابق أول جزأين من المسار الشركة والموظف.
- `employee_docs_storage_select` لا تمنح الوصول العام لكل الشركة؛ تسمح للموظف صاحب الملف أو مستخدم HR.
- لذلك يستطيع المشتري قراءة ملفاته، لكن Finance/Finance Manager/Warehouse لا يكتسبون تلقائيًا حق فتح ملفات `buyer-goods` الخاصة بمشتري آخر.
- دالة `buyer_goods_custody_get_invoice_handover_progress_atomic` تعيد مسار الإثبات للجهات المخولة، لكن ذلك لا يمنحهم Storage permission لقراءة الملف نفسه.
- لا توجد سياسة مخصصة لـ `buyer-goods` في Storage. لم أضف سياسة جديدة قبل تحديد المستهلكين والـbranch scope؛ لا يجوز توسيع الوصول لكل الشركة لمجرد أن التطبيق يحتاج معاينة الملف.

### النتيجة
**P1 OPEN:** نحتاج سياسة SELECT مخصصة ومحدودة لمسارات `buyer-goods` تمنح:
1. المشتري صاحب الملف الوصول إلى ملفاته.
2. Finance/Finance Manager الوصول إلى المستندات اللازمة للمراجعة.
3. Warehouse/Receiver الوصول فقط إلى ملفات الفواتير التي تقع ضمن نطاق الفرع/العملية المخولة لهم، بعد إثبات helper أو علاقة branch scope الصحيحة.
4. Owner وفق سياسة المالك المعتمدة.

لا تُفتح بقية ملفات الموظفين أو `employee-documents` لهذه الأدوار، ولا يُحوّل الـbucket إلى Public.

## 4. اكتشاف إضافي — سجل المرفقات

Production `purchase_attachments` يحتوي:
- `company_id, document_type, document_id, file_name, storage_path, file_url, mime_type, uploaded_by, created_at`.
- RLS مفعّل وسياسة SELECT للشركة.
- authenticated لديه SELECT فقط؛ INSERT متاح لـ service_role وpostgres.
- Buyer الحالي لا يقرأ `purchase_attachments` في `openInvoice` ولا يعرض صورة فاتورة المورد في Quick Market.

هذا يعني أن إضافة صورة فاتورة المورد ليست مجرد حقل file input؛ يلزم ربط ملف Storage بسجل `purchase_attachments` عبر مسار خادمي يثبت ملكية فاتورة Quick Market، ثم عرض مرفق خاص برابط Signed URL مع سياسة وصول صحيحة. لم أضف عملية Edge جديدة أو سجل مرفق غير مكتمل في هذه الدورة.

## 5. صلاحيات أحداث الحيازة

سياسة `buyer_goods_custody_events_select_authorized` تسمح للمشتري صاحب الحيازة أو Finance/Finance Manager/Owner. لا تمنح Warehouse تلقائيًا قراءة جميع أحداث المشتريين. هذا متسق مع تأجيل Receiver، لكنه شرط يجب إكماله مع نطاق الفرع قبل تشغيل دورة Buyer→Warehouse.

## 6. الاختبارات والحالة

- تحقق GitHub: commit `a35cd59` متقدم commit واحدًا عن `240858a`، والتغيير الوحيد هو `buyer.html`.
- تحقق المصدر: blob الحالي `0ac1cd20` ويحتوي حقل البحث والمنطق والـpatches السابقة.
- تحقق Edge: v26 ACTIVE، دون تغيير إضافي.
- لم تتوفر جلسة Buyer مصادق عليها أو وسيلة تفاعل متصفح لتنفيذ E2E.
- Cloudflare deployment للـcommit `a35cd59` غير مثبت؛ الإعداد الظاهر سابقًا يقول Automatic deployments enabled لكن لقطة Dashboard قديمة.
- لا بيانات اختبار، ولا تحديث في stock/treasury/AP/GL.

## 7. الفجوات الحالية ذات الأولوية

1. **Quick Market invoice image:** إنشاء upload + سجل `purchase_attachments` مركزي idempotent + Signed URL display، بعد حسم صلاحيات Storage المحدودة.
2. **Storage read policy:** Buyer own + Finance + Warehouse branch-scoped، لا وصول عام.
3. **RLS purchase invoices:** Edge GET_DATA يفلتر فواتير المشتري حسب `purchaser_user_id` أو `created_by`، ويفتح الجميع للمالك/Finance؛ لكن RLS المباشر ما زال أوسع من هذا النطاق، ويلزم consumer map قبل تغييره.
4. **purchase_returns/details:** direct DML grants/policies لا تزال بحاجة إلى consumer map من Parent والتطبيقات الأخرى قبل سحبها.
5. **Buyer→Warehouse / Buyer→Supplier / partial acceptance:** غير مكتملة؛ Receiver مؤجل حتى اعتماد عقد Buyer.
6. **Cloudflare parity + authenticated E2E:** لم يثبتا.
7. **legacy reconciliation:** لا حذف أو تعديل مباشر لـ PINV-1000/PINV-1001 أو QA-SR دون مصالحة مخزون/AP/GL.

**الحالة:** `DB HARDENING APPLIED / EDGE v26 ACTIVE / BUYER SOURCE SEARCH ADDED / INVOICE IMAGE OPEN / STORAGE READ ACCESS OPEN / CLOUDFLARE UNVERIFIED / E2E NOT RUN / BUYER NOT CLOSED`.
