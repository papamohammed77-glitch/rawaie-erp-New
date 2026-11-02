# RAWAEA ERP — مراجعة تفويض أذونات المخازن وإعداد مخزن السيارة

**Checkpoint:** LVE-2026-11-03-593  
**التاريخ:** 2026-11-03  
**الحالة:** STOCK VOUCHER AUTHORIZATION GAPS / VAN SETUP AUTHORIZATION GAP / SOURCE-SCHEMA CONFLICT / READ-ONLY  
**نقطة البداية:** LVE-592.

---

## 1. النطاق

تم فحص مسارات:
- إنشاء/تعديل/حذف إذن المخزن.
- إرسال الإذن.
- استلام الإذن.
- إكمال الإذن وإلغاءه.
- الجرد والتسوية المخزنية.
- إنشاء/حذف صنف وفرع.
- إعداد مخزن السيارة وربطه بالمندوب والمركبة.

تمت مطابقة Edge Function sources مع RPC definitions وProduction user/role/branch-scope data. لا توجد كتابة في Production.

---

## 2. أذونات المخازن — نتائج CONFIRMED

### 2.1 إنشاء Stock Voucher

Edge:
- create-stock-voucher v17.
- verify_jwt=false، لكنه ينفذ تحققًا مخصصًا من token عبر auth.getUser.
- لا يفرض Edge effective warehouse/stock-voucher permission موحدًا.

المسار الجديد:
- عندما يصل operation_id أو rep_id، يستدعي Edge overload ذي 12 وسيطًا من create_manual_stock_voucher_atomic.
- هذا المسار يحتوي فحصًا أقوى للأدوار الإدارية/المخزنية ونطاق الفرع.

المسار القديم:
- عندما لا يصل operation_id ولا rep_id، يستدعي Edge overload ذي 10 وسائط.
- هذا overload يسمح بالإنشاء إذا كان:
  - permissions تحتوي *، أو
  - allowed_branch_ids فارغة/NULL/نجمة، أو
  - المستخدم مخزنيًا وله active_warehouse_role = أذونات.
- هذا يجعل branch scope وحده بديلًا عن stock-voucher permission.

Production user evidence:
- يوجد مستخدم نشط واحد role=موظف، permissions=[]، وallowed_branch_ids="*".
- هذا المستخدم يطابق شرط السماح في overload القديم رغم عدم امتلاكه صلاحية مخزنية مباشرة.

واجهة warehouse/vouchers.html الحالية ترسل operation_id عند إنشاء الإذن، وبالتالي تستخدم المسار الجديد في الاستخدام الحالي الذي فُحص. لكن Edge ما زال يعرض fallback قديمًا قابلًا للاستدعاء عند حذف operation_id أو عبر عميل آخر.

**الحكم:** legacy create overload يسمح بإنشاء إذن اعتمادًا على نطاق الفروع فقط؛ authorization conflict CONFIRMED. استخدامه من Runtime غير مختبر.

### 2.2 إرسال Stock Voucher

- send-stock-voucher v20، verify_jwt=true.
- Edge يتحقق من المستخدم النشط والشركة، لكنه لا يفرض effective permission.
- send_stock_voucher_atomic يقبل actor إذا كانت permissions تحتوي * أو allowed_branch_ids NULL/فارغة/نجمة، مع شرط دور مخزني خاص لبعض Transfer operations.
- يوجد مستخدم نشط بrole موظف وpermissions فارغة وallowed_branch_ids="*"؛ لذلك branch wildcard وحده يمرر شرط التفويض.
- واجهة warehouse/vouchers.html تستدعي send-stock-voucher في مسار الإرسال الحالي.

**الحكم:** مستخدم لا يملك stock-voucher/warehouse permission يستطيع اجتياز شرط RPC اعتمادًا على allowed_branch_ids="*". Authorization gap CONFIRMED.

### 2.3 حذف إذن Draft

- delete_manual_stock_voucher_atomic يتحقق من المستخدم النشط والشركة وحالة Draft ونطاق الفرع.
- لا يشترط stock-voucher permission مستقلًا.
- allowed_branch_ids="*" يسمح باجتياز branch-scope check.
- Edge create-stock-voucher يمرر عملية DELETE إلى هذا RPC.

**الحكم:** مستخدم wildcard بلا permission يمكنه حذف Draft voucher وفق عقد RPC الحالي. لم تُنفذ عملية حذف.

### 2.4 استلام Stock Voucher — Positive Control

post_manual_stock_voucher_atomic يحتوي قيودًا أفضل:
- Transfer RECEIVE يشترط أن actor.id يساوي receiver_user_id المعيّن على الإذن.
- DirectReturn RECEIVE يشترط صلاحية * أو دور مدير مخازن/مشرف مخازن/مدير عام/مدير النظام، أو دور مخزني مع active_warehouse_role = أذونات ونطاق الفرع.
- لذلك لا يجوز وصف كل stock voucher endpoints بأنها مفتوحة؛ مسار الاستلام المركزي يحتوي تحققًا واضحًا من المسؤولية والتعيين.

### 2.5 إكمال الإذن وإلغاءه — فجوة مؤثرة

complete_manual_stock_voucher_atomic_core:
- يتحقق من المستخدم النشط والشركة والإذن والحالة المتوقعة.
- لا يتحقق من effective permission أو role أو assignment.
- عند SupplierReturn ينشئ supplier ledger entry وقيد journal، ويحدث حالة الإذن إلى Completed.

cancel_manual_stock_voucher_atomic_core:
- يتحقق من المستخدم النشط والشركة وأن الإذن Draft.
- لا يتحقق من effective permission أو role أو assignment.
- يغير الحالة إلى Cancelled.

Edge:
- complete-stock-voucher v4 وcancel-stock-voucher v4 لا يضيفان effective permission check قبل استدعاء المسار المركزي باستخدام service_role.

**الحكم:** أي مستخدم نشط في الشركة يمكنه من حيث العقد الحالي إكمال SupplierReturn في الحالة المناسبة، بما ينتج عنه أثر Supplier AP/Journal، أو إلغاء Draft voucher. هذا تفويض مالي/مخزني غير مقبول دون سياسة مالك صريحة. HTTP execution لم يُختبر.

---

## 3. إعداد مخزن السيارة — CONFIRMED AUTHORIZATION GAP

Edge:
- setup-van-branch، version 3.
- يتحقق من JWT/المستخدم النشط والشركة، ثم يبحث عن driver_email في body ويتأكد أن المستخدم المستهدف ينتمي للشركة ودوره مندوب بيع مباشر.
- ينشئ/يربط mobile branch بالمركبة ويحدث vehicle.mobile_branch_id وmobile_stock_enabled، ثم يستدعي setup_van_stock عبر service_role.
- لا يتحقق من أن driver_email في الطلب يساوي البريد الإلكتروني للمستخدم الذي قدم JWT.
- لا يفرض fleet.manage أو warehouse/van-setup permission على الفاعل.

المستهلك الحالي:
- companies/company-1/sales/van-sales.html يستدعي setup-van-branch ويمرر بريد المستخدم الحالي لنفسه.
- هذا يثبت الاستخدام الطبيعي، لكنه لا يمنع تعديل body واستهداف مندوب آخر عبر API.

**الحكم:** UI يرسل self email، لكن Edge لا يفرض self-only ولا manager permission. أي مستخدم نشط في الشركة يستطيع طلب إعداد/ربط مخزن سيارة لمندوب آخر. Source contract gap CONFIRMED؛ لم يُنفذ طلب HTTP.

---

## 4. مسارات المخزون التي تطبق قيودًا أفضل

- save-inventory-count delegates to inventory_count_engine، الذي يفحص المستخدم النشط والشركة وأدوار/صلاحيات الجرد بحسب العملية.
- inventory_stock_request_engine يفحص صلاحيات/أدوار طلب المخزون والتحويل.
- bulk-stock-adjustment يفرض stock_adjustment permission في Edge.
- save-item يفرض items أو data_entry؛ وإذا كان openingQty أكبر من صفر يفرض stock_adjustment.
- delete-item يفرض items أو data_entry.
- save-branch وdelete-branch يفرضان branches permission.

هذه الضوابط يجب الحفاظ عليها وعدم تخفيضها إلى branch scope فقط.

---

## 5. تصحيح نتيجة سابقة — LVE-592

في LVE-592 صُنّف save-customer v4 وdelete-customer v3 كأمثلة على فحص customers permission. إعادة المطابقة مع Production أظهرت تعارضًا:

- كلا Edge Functions يطلب is_owner ضمن select من public.users.
- information_schema.columns في Production لا يحتوي public.users.is_owner.
- لذلك استعلام actor نفسه لا يطابق المخطط الحالي، وقد يفشل قبل الوصول إلى فحص permission.
- لم يُنفذ Runtime request، لذلك فشل الوظيفة فعليًا UNVERIFIED؛ لكن Source/Schema contract conflict CONFIRMED.
- لم يظهر consumer مباشر لهذين الاسمين في Parent main.html في البحث المحدد؛ لا نفترض أنهما المسار الوحيد لإدارة العملاء.

**تصحيح لازم:** لا تعتمد على نتيجة LVE-592 التي وصفت هذين المسارين بأنهما positive permission controls حتى تُصلح/تُثبت مطابقة عمود is_owner أو يُزال الاعتماد عليه.

---

## 6. مصفوفة الحالة

| المسار | التفويض | أثر الأعمال | الحالة |
|---|---|---|---|
| Create stock voucher — 12 args | manager/warehouse checks | Draft creation | أفضل |
| Create stock voucher — 10 args | wildcard branch scope قد يكفي | Draft creation | CONFLICT |
| Send stock voucher | wildcard branch scope قد يكفي | إرسال إذن | CONFLICT |
| Receive Transfer | receiver_user_id exact match | استلام/مخزون | أفضل |
| Receive DirectReturn | manager/warehouse role + branch | استلام/مخزون | أفضل |
| Delete Draft voucher | active company + branch scope | حذف Draft | CONFLICT |
| Complete voucher | active company + state فقط | Supplier AP/Journal محتمل | CRITICAL GAP |
| Cancel Draft voucher | active company + state فقط | إلغاء Draft | GAP |
| Setup van branch | active user/company + target driver exists | vehicle/mobile branch/stock setup | GAP |
| Inventory count | role/permission checks in RPC | stock count | أفضل |
| Bulk adjustment | stock_adjustment permission | stock change | أفضل |
| Save/Delete item | items/data_entry (+ stock_adjustment for opening) | item master/opening stock | أفضل |
| Save/Delete branch | branches permission | branch master | أفضل |

---

## 7. ما تم وما لم يتم

**تم:**
- فحص Edge versions: create-stock-voucher v17، send-stock-voucher v20، receive-stock-voucher v22، complete-stock-voucher v4، cancel-stock-voucher v4، save-inventory-count، setup-van-branch v3، save-item، delete-item، save-branch، delete-branch.
- فحص RPCs: create_manual_stock_voucher_atomic overloads، send_stock_voucher_atomic، delete_manual_stock_voucher_atomic، post_manual_stock_voucher_atomic، complete_manual_stock_voucher_atomic_core_20260828، cancel_manual_stock_voucher_atomic_core_20260828، inventory_count_engine، inventory_stock_request_engine.
- فحص حالة allowed_branch_ids حسب الدور دون إخراج بيانات تعريفية للمستخدمين.
- تأكيد أن واجهة vouchers الحالية ترسل operation_id في الإنشاء، وأنها تستدعي send/receive/complete/cancel من المسارات الحالية.

**لم يتم:**
- لم يتم إنشاء أو إرسال أو استلام أو إكمال أو حذف أي Stock Voucher.
- لم يتم إعداد Van Branch أو تعديل vehicle.
- لم يتم تعديل grants/RLS/RPC/Edge.
- لم يتم تنفيذ HTTP exploit أو Browser E2E.

---

## 8. الأولوية

إعداد تغييرات مالك محددة على مسار Stock Voucher وVan Setup:
1. إزالة/إغلاق legacy create overload أو فرض نفس صلاحية create الجديدة داخله.
2. فرض stock-voucher permission على send/delete/complete/cancel، مع permission منفصلة لإكمال SupplierReturn ذي الأثر المالي.
3. الحفاظ على receiver_user_id checks في Transfer وDirectReturn.
4. فرض fleet.manage أو صلاحية إعداد Van Branch، مع اشتراط actor=driver أو صلاحية مدير مخول.
5. تصحيح save-customer/delete-customer is_owner contract بعد تحديد مصدر owner الحقيقي.
6. اختبارات سلبية لمستخدم active بلا صلاحية، وإيجابية للدور المخول، على fixture معزول.

لا تنفيذ قبل موافقة صريحة وفق Master §77.2.

---

## 9. الحكم

**تم العثور على مسارات مخزنية قادرة على إنشاء/إرسال/إكمال/إلغاء أذونات دون صلاحية تشغيلية كافية، ومسار إعداد سيارة لا يربط الفاعل بالمندوب المستهدف. كما ظهر تعارض is_owner بين Edge وProduction users schema.**

الحالة: SOURCE/RPC AUTHORIZATION FINDINGS CONFIRMED / RUNTIME UNVERIFIED / NOT CLOSED.  
لا توجد تغييرات تشغيلية أو إنتاجية في LVE-593.
