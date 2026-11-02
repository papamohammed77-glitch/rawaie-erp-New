# RAWAEA ERP — مراجعة التفويض المالي وسرية البيانات المالية

**Checkpoint:** LVE-2026-11-03-591  
**التاريخ:** 2026-11-03  
**الحالة:** FINANCE AUTHORIZATION GAPS CONFIRMED / READ-ONLY / NOT CLOSED  
**نقطة البداية:** LVE-590.

---

## 1. الهدف

استكمال فهم النظام عبر فحص بوابات العمليات المالية ذات الأثر المباشر على:
- القيود اليومية.
- سندات الصرف.
- سندات القبض.
- التحويل بين الخزائن.
- دفتر المندوب.
- التدفقات النقدية.

التركيز على الفرق بين صلاحية الواجهة وصلاحية الخادم، وبين RPC قابل للاستدعاء من authenticated وRPC محصور في service_role خلف Edge Function.

لم تُنفذ أي عملية مالية أو كتابة في Production.

---

## 2. ملخص النتائج

### 2.1 المسارات التي ظهر بها نقص تفويض خادمي

| Edge Function | Version | ما يفعله | نتيجة فحص التفويض |
|---|---:|---|---|
| save-journal-entry | v8 | إنشاء قيد يومية عبر post_journal_entry | يتحقق من JWT والمستخدم والشركة، ولا يتحقق من finance permission |
| save-payment-voucher | v7 | تسجيل مصروف عبر finance_save_expense | يتحقق من المستخدم والشركة والفرع والخزينة، ولا يتحقق من finance permission |
| save-receipt-voucher | v8 | سند قبض عام أو تحصيل Van Sales | يتحقق من JWT والمستخدم والشركة، ولا يفرض finance permission على المسار العام |
| save-transfer-voucher | v4 | تحويل بين خزائن الشركة | يتحقق من JWT والمستخدم والشركة، ولا يتحقق من finance permission |
| update-driver-ledger | v2 | إضافة مدين/دائن إلى دفتر المندوب | يتحقق من JWT والمستخدم والشركة، ولا يتحقق من finance/driver-ledger permission |
| get-cash-flow | v1 | عرض التدفقات النقدية | يتحقق من JWT فقط؛ لا يفرض finance permission في Edge أو RPC |

هذه نتائج Source/RPC contract مؤكدة. لم أرسل طلبات HTTP أو أُنشئ قيودًا أو سندات لاختبار الاستغلال.

### 2.2 المسارات التي تحتوي فحص صلاحية أفضل

- save-sales-invoice v19 يبني effective permissions من المستخدم والدور وrole_permissions ويحدد صلاحية المصدر.
- sales-payment-allocation v2 يفحص finance أو finance_manager.
- save-purchase-order v22 يفحص الصلاحية حسب operation.
- delivery_supervisor_assign_deliverer_atomic يفحص صلاحية المشرف أو fleet.manage وصلاحية الموظف المستهدف.

المقارنة تؤكد أن آلية حساب effective permissions موجودة في النظام بالفعل، لكنها غير مطبقة بصورة متسقة على العمليات المالية.

---

## 3. أدلة Production/RPC

### 3.1 post_journal_entry

- SECURITY DEFINER.
- EXECUTE للمستخدم authenticated غير ممنوح مباشرة؛ service_role يستطيع التنفيذ.
- الدالة تتحقق من الشركة وتوازن القيد وصحة الحسابات والفترة المالية وoperation_id.
- شرط company context يتجاوز التحقق عندما يكون auth.role() = service_role.
- save-journal-entry يستعمل service_role client، ولا يفحص finance permission قبل استدعاء الدالة.

النتيجة: أي مستخدم نشط داخل الشركة يستطيع، عبر Edge wrapper، محاولة إنشاء قيد متوازن دون صلاحية مالية. قيود الحسابات والتوازن لا تعوض فحص التفويض.

### 3.2 finance_save_expense

- توجد overloads اثنتان، وكلتاهما SECURITY DEFINER.
- EXECUTE ممنوح لـauthenticated وservice_role.
- فحص الدالة يثبت company context وbranch/treasury والحسابات والفترة المالية وoperation_id.
- لا يظهر فحص finance permission داخل الدالة.
- save-payment-voucher يستعمل userClient بAuthorization الخاص بالمستخدم لاستدعاء finance_save_expense؛ لذلك لا يعتمد المسار على service_role وحده.
- لأن RPC قابل للتنفيذ من authenticated، فإن غياب permission check داخل RPC يعني أن إخفاء شاشة سند الصرف لا يمنع استدعاء RPC مباشرة.

النتيجة: نقص التفويض مؤكد على مستوى RPC نفسه، وليس فقط في Edge wrapper.

### 3.3 post_cash_receipt_atomic

- SECURITY DEFINER.
- EXECUTE محصور في service_role؛ authenticated لا يستطيع استدعاءه مباشرة.
- الدالة تتحقق من الشركة والخزينة والحسابات والمبلغ والتاريخ وoperation_id، لكنها لا تتحقق من صلاحية المستخدم النهائي.
- save-receipt-voucher يستعمل service_role client ولا يفحص finance permission في المسار العام.

النتيجة: Edge wrapper هو الحد الأمني، لكنه لا يطبق صلاحية مالية قبل تمرير الطلب إلى الدالة.

### 3.4 post_treasury_transfer_atomic

- SECURITY DEFINER.
- EXECUTE محصور في service_role.
- الدالة تتحقق من الشركة والخزائن والحسابات والمبلغ والاتجاه وoperation_id، لكنها لا تتحقق من هوية المستخدم أو صلاحية finance.
- save-transfer-voucher يستعمل service_role client ولا يفحص finance permission.

النتيجة: مستخدم authenticated نشط داخل الشركة يمكنه طلب تحويل خزينة عبر Edge دون فحص صلاحية مالي خادمي.

### 3.5 post_driver_ledger_entry

- SECURITY DEFINER.
- EXECUTE محصور في service_role.
- update-driver-ledger يستعمل service_role، ويتحقق من المستخدم النشط والشركة، ثم يمرر driver_email وdebit/credit.
- لا يوجد effective permission check في Edge wrapper.

النتيجة: يمكن طلب حركة دفتر مندوب دون التحقق من صلاحية مالية/إدارية مناسبة. لم يُختبر أثرها على دفتر فعلي.

### 3.6 post_van_sales_collection_atomic

- SECURITY DEFINER وEXECUTE محصور في service_role.
- save-receipt-voucher يمرر بريد المستخدم الحالي بوصفه driver_email.
- RPC يتحقق من أن المستخدم الممرر هو مندوب بيع مباشر، وأن العميل تابع للشركة ومخصص للمندوب.
- هذا يوفر قيد دور/تخصيص أفضل لمسار Van Sales collection.
- لا يجوز تعميم هذا الفحص على مسار سند القبض العام؛ generic receipt يستدعي post_cash_receipt_atomic ولا يحتوي شرط مندوب.

### 3.7 get_cash_flow

- RPC SECURITY INVOKER وEXECUTE ممنوح لـauthenticated.
- يعتمد على app_private.current_user_company_id() لعزل الشركة.
- لا يحتوي فحص finance permission.
- get-cash-flow Edge يتحقق من JWT ثم يستعمل client منشأ بمفتاح service_role لاستدعاء RPC؛ لم يُنفذ Runtime request لتحديد ما إذا كان service_role context يجعل current_user_company_id() فارغًا ويعيد نتيجة فارغة.
- حتى دون Edge، authenticated يستطيع استدعاء RPC مباشرة؛ لذلك نقص صلاحية قراءة التدفقات المالية مؤكد على مستوى grant/contract، أما البيانات التي يعيدها المسار عبر Edge فغير مختبرة.

---

## 4. تصنيف المخاطر

### CONFIRMED

1. save-journal-entry لا يفحص finance permission قبل تنفيذ RPC service_role-only.
2. save-payment-voucher لا يفحص finance permission، وfinance_save_expense callable من authenticated ولا يفحص finance permission داخل RPC.
3. save-receipt-voucher generic path لا يفحص finance permission قبل RPC service_role-only.
4. save-transfer-voucher لا يفحص finance permission قبل تحويل خزينة.
5. update-driver-ledger لا يفحص permission قبل إضافة حركة إلى دفتر المندوب.
6. get_cash_flow قابل للاستدعاء من authenticated ولا يفحص finance permission.
7. يوجد نمط إيجابي فعلي في save-sales-invoice وsales-payment-allocation يمكن استخدامه لتوحيد الفحص بدل إنشاء منظومة صلاحيات موازية.

### UNKNOWN

- هل هناك سياسة مقصودة تسمح لكل مستخدم نشط داخل الشركة بإنشاء بعض أنواع القبض أو المصروفات؟ لم يظهر تعريف مالك يجيز ذلك.
- هل بعض هذه العمليات مخصصة لأدوار تشغيلية غير finance مثل Van Sales؟ يجب فصلها حسب نوع العملية ومصدرها بدل فتح Endpoint عام.
- هل get-cash-flow Edge يعيد بيانات فارغة بسبب service_role context؟ لم يُختبر Runtime.

### CONFLICT

- واجهات النظام تقيد سندات الصرف والقبض والتحويل والقيود والتدفقات النقدية حسب الدور، بينما Edge/RPC في المسارات أعلاه لا تفرض نفس الصلاحية على الخادم.
- finance_save_expense callable من authenticated، لكن لا يوجد finance permission check داخلي.
- post_journal_entry يسمح لمسار service_role بتجاوز company-context check، بينما Edge wrapper لا يضيف finance permission.

### UNVERIFIED

- لم يتم إنشاء قيد أو سند أو تحويل فعلي بواسطة مستخدم غير مالي.
- لم يتم اختبار قراءة cash flow عبر authenticated مباشر أو Edge.
- لم يتم اختبار أثر حركة driver ledger على settlement أو التقارير.

---

## 5. ضوابط التصميم الواجب اعتمادها

1. كل Edge يستخدم service_role يجب أن يثبت effective permission للمستخدم النهائي قبل أي كتابة.
2. أي SECURITY DEFINER RPC قابل للتنفيذ من authenticated يجب أن يفرض permission check داخليًا أو يقتصر EXECUTE على مسار محمي مع دليل معماري واضح.
3. لا يكفي التحقق من company_id؛ يجب التحقق من نوع العملية والفاعل والفرع والخزينة والموظف/العميل المخصص.
4. لا تخلط generic receipt مع Van Sales collection؛ لكل منهما صلاحية ومصدر ودفتر فرعي مختلف.
5. لا تسمح بكتابة Manual Journal إلا لصلاحية finance محددة، مع حسابات الشركة والفترة المالية وتوازن القيد.
6. لا تسمح بتحويل الخزينة أو سند الصرف بمجرد معرفة treasury_id أو branch_id.
7. get_cash_flow وبيانات الدفاتر المالية يجب أن تكون مقيدة على الخادم بصلاحيات Finance، وليس فقط بعزل الشركة.
8. يجب أن يكون operation_id ثابتًا لمحاولة العمل الواحدة، وأن يكون جديدًا للعملية المقصودة الجديدة.

---

## 6. ما تم وما لم يتم

**تم:**
- قراءة Edge source المنشور للوظائف الست.
- فحص RPC signatures وSECURITY DEFINER وEXECUTE privileges.
- فحص تعريفات finance_save_expense وget_cash_flow وpost_journal_entry وpost_cash_receipt_atomic وpost_treasury_transfer_atomic وpost_van_sales_collection_atomic.
- مقارنة save-sales-invoice وsales-payment-allocation كنمطين يطبقان صلاحيات أفضل.

**لم يتم:**
- لم تُنفذ أي كتابة مالية.
- لم تُغيّر RLS أو grants أو function ACL.
- لم تُنشر Edge Functions.
- لم يُختبر HTTP exploit أو Runtime.
- لم يتم اعتماد سياسة مالية جديدة من المالك.

---

## 7. الأولوية

إعداد Finance Authorization Matrix مع المالك قبل أي إصلاح:
- من يقرأ Cash Flow؟
- من ينشئ Manual Journal؟
- من ينشئ Expense/Payment Voucher؟
- من ينشئ Generic Receipt؟
- من ينفذ Van Sales Collection؟
- من يحول Treasury؟
- من يعدل Driver Ledger؟

ثم تحويل الإجابات إلى effective permission checks موحدة في Edge/RPC، مع اختبارات سلبية لمستخدم داخل الشركة بلا الصلاحية، واختبارات إيجابية للدور الصحيح، دون أي تغيير Production قبل الموافقة الصريحة.

**الحالة:** FINANCIAL AUTHORIZATION GAPS CONFIRMED AT SOURCE/RPC LEVEL / RUNTIME UNVERIFIED / NOT CLOSED.  
**لم يحدث أي تغيير تشغيلي أو مالي في LVE-591.**
