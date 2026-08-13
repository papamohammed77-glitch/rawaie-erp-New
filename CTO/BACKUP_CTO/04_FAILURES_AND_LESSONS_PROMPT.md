# BACKUP CTO — PROMPT 04
## FAILURE HISTORY / LESSONS / ANTI-REGRESSION

هذه الذاكرة إلزامية حتى لا تتكرر أخطاء التنفيذ السابقة.

### FAILURE 1 — THEORY VS PRODUCTION
تم سابقًا اعتبار بعض المهام منفذة وهي مجرد design/migration نظرية.
القاعدة الجديدة:
**لا CLOSED / GO بلا Production evidence.**

### FAILURE 2 — WRONG FILE/SCHEMA ASSUMPTION
حدث استخدام لأعمدة غير مثبتة مثل:
`received_by`
وتم اكتشاف أنها غير موجودة في Production.
القاعدة:
استعلام schema أولًا، ثم SQL.

### FAILURE 3 — GENERATED COLUMN
`available_qty` كانت Generated Column، لكن `setup_van_stock` حاول إدخال قيمة لها.
القاعدة:
تحقق من `is_generated`/column definition قبل INSERT/UPDATE.

### FAILURE 4 — DIRECTSALE SOURCE-ONLY
`post_stock_movement` كان يخصم من المصدر فقط، بينما Business Contract يتطلب MAIN→VAN.
النتيجة: MAIN ينقص وVAN لا يزيد.
الدرس:
كل movement topology يجب تعريفها صراحةً Source/Target قبل التنفيذ.

### FAILURE 5 — TARGET NOT PASSED
`send_manual_stock_voucher_v2` مرر target=NULL.
الدرس:
لا يكفي أن Voucher لديه `to_id`; يجب التأكد أن consumer يمرره إلى Core.

### FAILURE 6 — ROLLBACK ERASED THE FIX
تم وضع Fix ثم الاختبار داخل نفس transaction ثم حدث rollback، فاختفى الإصلاح الدائم.
القاعدة:
**Persist Fix first. Test second. Rollback test data only.**

### FAILURE 7 — REPEATED TEST WITHOUT NEW INFORMATION
تم تكرار DirectSale test قبل عزل مصدر فقدان target.
القاعدة:
إذا فشل الاختبار، لا تكرره بنفس الفرضية. اجمع Trace يحدد نقطة الانحراف.

### FAILURE 8 — WRONG REPOSITORY FOR RECORDS
تم استخدام `rawaie-erp-review` لسجلات CTO أثناء وجود `rawaie-erp-New` كمستودع curated recovery.
القرار الحالي:
`rawaie-erp-New` = المصدر الوحيد النشط.
`rawaie-erp-review` = تاريخ/مراجعة/مرجع.

### FAILURE 9 — EXPERIMENTAL DATA CLEANUP
كانت هناك عدة vehicles تجريبية.
تم الاحتفاظ بـ`VEH-92yrzb` وحذف النماذج القديمة بعد evidence gate.
الدرس:
لا تحذف test data بدون reference audit.

### FAILURE 10 — DRIVER/VEHICLE CONFUSION
كان احتمال إنشاء `VAN-{email}` مطروحًا.
القرار الصحيح:
Vehicle identity = vehicle_code.
Driver identity = users.id.
Mobile branch = vehicle-derived.

## MANDATORY ANTI-REGRESSION
قبل أي تعديل اسأل:
- هل هذا Production fact أم Target design؟
- هل أصل المشكلة في Core أم Consumer؟
- هل التعديل دائم أم workaround؟
- هل أستطيع إثبات نجاحه من Production؟
- هل سأترك وراءي GAP غير موثق؟
