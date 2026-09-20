# Report277 — التحقيق الجنائي والإغلاق الجراحي لتقارير الأذونات المخزنية داخل النظام الأم
## التاريخ: 2026-09-20

### 1. Scope Lock
- النطاق: تكامل سجل الأذونات المخزنية بين التطبيق المستقل وMother.
- Mother main.html تم فحصه Read Only ولم يُعدّل تلقائيًا.
- Standalone vouchers.html لم يُعدّل في هذه الدورة.
- لا Edge Function جديدة.
- التغيير الإنتاجي الوحيد: RPC قراءة مصادق عليه.

### 2. Current Git
System repository HEAD: 965304ad01ec689bbc8eac45a0f54ed681a0b25a
System parent: b66a2d6d71d1149d2d80895c594ff76d5521dfbc
Mother HEAD: 4aebf36b6da684ecb1e09d8f83063e0231c70866
Mother parent: 71151fbc2caa17447ad4c1800b02ab30f950937a
Mother current blob: e2b0dcb8317034363365fe728e8b4c33d1bf08da
Standalone vouchers HEAD: f6d0558f1ae1525ccdb32bc6269ca87d9c378ae2
Standalone vouchers parent: 8a1a75dd840b32cfc135178a9a9c466adefaf0ee

### 3. Current source finding
Mother loadVouchers() هو السجل الموحد الحالي.
الـroutes transfer / direct-sale / direct-return / supplier-return تستدعي loadVoucherForm(type) فقط.
إذن routes الأنواع الأربعة هي creation forms وليست historical reporting surfaces.
الفجوة مثبتة كـConsumer/View Contract Gap وليست Data Contract Gap.

### 4. Data contract
المستند الموحد: stock_vouchers.
التفاصيل: stock_voucher_details.
Physical movement: post_stock_movement ثم stock_branches + inventory_log.
Audit: audit_log.
لا يوجد origin_app مثبت في schema؛ لم يتم اختراعه.

### 5. Production action
تم إنشاء public.inventory_voucher_report(text,jsonb) كـSECURITY DEFINER.
الوظيفة read-only ولا تنفذ أي Physical Stock mutation.
الصلاحيات تعتمد على auth.uid → users → company_id، مع voucher/report/warehouse permission gate.
الدالة تدعم LIST وSUMMARY، Manual source افتراضي، type/status/date/search/pagination.
البحث يشمل voucher code/reference/status/source/creator/completer/notes/item/branch/vehicle/supplier.
يعرض التقرير from/to labels وitem_lines وtotal_qty وmovement_count وaudit_count.

### 6. Production verification
Authorized warehouse supervisor: LIST Transfer أعاد success=true وtotal=0 في الحالة النظيفة الحالية.
SUMMARY Manual أعاد success=true وtotal=0.
Unauthorized vansales أعاد: غير مصرح بقراءة تقارير الأذونات المخزنية.
Probe داخلي Transaction أنشأ أربعة أنواع مؤقتًا: Transfer / DirectSale / DirectReturn / SupplierReturn.
SUMMARY أعاد كل نوع = 1 وCompleted = 4، ثم ROLLBACK.
Production final clean state: stock_vouchers=0; stock_voucher_details=0; stock_voucher_operations=0; inventory_log=3; audit_log=2022.

### 7. Competitive benchmark
Odoo يميز stock movement operations عن inventory adjustments. المصدر: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html
Dynamics 365 يوفر Inventory Journals لأنواع Movement/Adjustment/Transfer/Item arrival/Counting وغيرها. المصدر: https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals
SAP يوفر Goods Movement وتقارير وحركة stock transfer. المصدر: https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html
Daftra يثبت قيمة source/target/date/quantity وAvailable Before/After، وتقارير تفصيلية بفلترة التاريخ والمصدر والمنتج والمخزن والنوع. المصادر: https://docs.daftra.com/en/tutorial/transferring-stock/ و https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/
Manager.io استخدم كـbenchmark category فقط دون نسبة خصائص غير موثقة.

### 8. Architectural decision
لا جدول History جديد.
لا Physical Stock engine جديد.
لا تغيير للـworkflow الميداني.
لا تغيير Router أو Permission Map.
الحل: Read Model موحد + Historical/Control surface داخل كل type route.

### 9. Owner surgical patch
الملف الوحيد المطلوب تعديلُه يدويًا: papamohammed77-glitch/erp-frontend/companies/company-1/main.html
المواضع المثبتة: loadVoucherForm(type) في lines 13900–13956، ثم insertion قبل async function _loadVoucherEntityOptions(type) {.
الـPatch الكامل موجود في Report277_MOTHER_MAIN_SURGICAL_PATCH_20260920.md.

### 10. E2E gate
بعد تطبيق M1/M2: اختبر Transfer ثم DirectSale ثم DirectReturn ثم SupplierReturn.
لكل نوع: إنشاء من التطبيق المستقل، ظهور في Mother، search، status/date filter، فتح الرقابة، ثم Production reread.
لا تعتبر 100% closed قبل تطابق CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DEPLOYMENT + BROWSER.

### 11. Open contracts
Browser E2E مفتوح حتى تطبيق M1/M2.
origin_app provenance غير مبني.
Historical Available Before/After snapshot غير مبني كعقد تاريخي.
Lot/serial/expiry وapproval وattachments خارج هذا النطاق.

### 12. Error forensic conclusion
لا توجد رسالة runtime error فعلية مرفقة في طلب المستخدم؛ لا يجوز اختراعها.
الخطأ الفعلي المثبت: Mother routes الأربعة كانت Forms فقط، بينما التاريخ كان محصورًا في unified voucher list.

### 13. Final self-audit
What I proved: current Git, current Mother source, current Voucher data contract, Production report RPC, tenant gate, four-type report probe, rollback cleanliness.
What I did not prove: Browser UI بعد Owner patch، live DirectSale/DirectReturn/SupplierReturn بلا fixtures دائمة، origin_app provenance، historical before/after.
What I fixed: Production read/report contract فقط.
Final status: PRODUCTION READ CONTRACT VERIFIED; MOTHER SOURCE UNTOUCHED; OWNER PATCH READY; BROWSER E2E OPEN; DATA REPAIR NONE; NEW EDGE FUNCTION NO.

### 14. Next session
ابدأ بقراءة هذا التقرير وCURRENT_STATE، ثم أعد فحص HEAD/parent/blob، ثم تحقق من تطبيق M1/M2، ثم Browser E2E، ثم Production reread. لا تعيد أي Closure سابق.

## END REPORT277