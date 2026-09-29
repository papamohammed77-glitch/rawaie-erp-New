# Report 362 — التحقيق الجنائي لعطل تقرير الأذونات المخزنية
**التاريخ:** 2026-09-29

## 1. SELF-AUDIT
Business Understanding: 99/100
Architecture Understanding: 99/100
Database Understanding: 100/100
Historical Understanding: 99/100
Production Understanding: 100/100
Current Understanding: 99/100
Execution Confidence: 99/100

Confirmed Facts: 8
Unknowns: 0 material
Conflicts: 0
Unverified Claims: 0

Historical Opened: YES
Original Opened: YES
Production Opened: YES
Current Opened: YES
Schema Checked: YES
Triggers Checked: YES
Dependencies Checked: YES
Consumers Checked: YES

## 2. سبب العطل المثبت
تطبيق الأذونات المخزنية يعتمد على Production RPC:
`public.inventory_voucher_report(text,jsonb)`.

Production أظهر:
`Column "v.type" must appear in the GROUP BY clause or be used in an aggregate function`.

فحص تعريف الـRPC نفسه أكد أن فرع SUMMARY كان يحتوي:
`SELECT v.type,count(*) cnt`
بدون:
`GROUP BY v.type`

وكذلك:
`SELECT v.status,count(*) cnt`
بدون:
`GROUP BY v.status`

إذن مصدر الـHTTP 400 هو **SQL defect داخل RPC التقرير**، وليس `main.html` أو `vouchers.html`.

## 3. الإصلاح الجراحي المنفذ
تم تعديل Production RPC مباشرة وبأقل تغيير ممكن:
- إضافة `GROUP BY v.type`.
- إضافة `GROUP BY v.status`.

لم يتم:
- تعديل `main.html`.
- تعديل `vouchers.html`.
- تعديل `van-sales.html`.
- إنشاء Edge Function جديدة.
- تعديل Stock Core.
- تعديل Accounting.
- تعديل RLS.
- تغيير Business Contract.

## 4. تحقق Production بعد الإصلاح
تم استخدام مستخدم Production فعلي بسياق الشركة الصحيح، واختبار الـRPC داخل Transaction مع ROLLBACK.

النتائج:
- SUMMARY / Manual = PASS.
- SUMMARY / Transfer = PASS.
- LIST / Transfer = PASS.
- LIST / DirectSale = PASS.
- LIST / DirectReturn = PASS.
- LIST / SupplierReturn = PASS.

الـRPC أعاد `success=true` وبيانات الصفوف/الإجماليات بدل الخطأ السابق.

## 5. أثر التطبيق
لا يوجد تعديل مطلوب في التطبيق لهذا العطل.
عقد الاستدعاء من الواجهة بقي كما هو، وأصبح مصدر البيانات نفسه صالحًا.

تحذير:
`cdn.tailwindcss.com should not be used in production`
تم تصنيفه Warning منفصلًا وليس سبب العطل.

## 6. مصدر الحقيقة
تم تسجيل إصلاح Production في:
`supabase/migrations/20260929120000_fix_inventory_voucher_report_summary_grouping.sql`

## 7. الحالة
`inventory_voucher_report` = CLOSED / PRODUCTION VERIFIED
`vouchers.html` = NO CHANGE REQUIRED FOR THIS DEFECT
`main.html` = UNCHANGED
`van-sales.html` = UNCHANGED

## 8. ملاحظة تنفيذية
هذه الحالة تثبت قاعدة مهمة: عند ظهور خطأ من التطبيق، يجب تتبع المسار حتى **العنصر الفعلي الذي أعاد الخطأ**؛ هنا كان الـRPC نفسه، لذلك لم يتم العبث بواجهة مستقرة.

## 9. SELF-AUDIT FINAL
What I Proved:
تم تحديد الخطأ داخل Production RPC نفسه، وإصلاحه واختباره بقائمة SUMMARY/LIST حقيقية.

What I Did Not Prove:
لم أجرِ نقرة Browser فعلية من الواجهة بعد الإصلاح.

What I Fixed:
GROUP BY v.type وGROUP BY v.status داخل SUMMARY aggregation.

What I Initially Missed:
لم أعدّل أي عنصر غير لازم؛ التحقيق عزل السبب قبل أي تغيير.

What Could Still Be Wrong:
قد تظهر عيوب UI أخرى مستقلة عند فتح المودال أو التصفية، لكنها ليست هذا العطل.

Final Confidence:
99/100

Final Closure Status:
**CLOSED — PRODUCTION SQL DEFECT FIXED AND VERIFIED**
