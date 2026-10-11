# Report414 — مزامنة Production لتبويب أوردرات المبيعات
التاريخ: 2026-10-11 15:49 UTC
المستودع: rawaie-erp-New
النطاق: تبويب أوردرات المبيعات في النظام الأم فقط.

## SELF-AUDIT
Production جرى فحصه حيًا في 2026-10-11 15:49:33.574207+00. المصدر الحالي في مستودع erp-frontend لم يرجع محتوى الملف عبر موصل GitHub، لذلك لا أدّعي مطابقة Snapshot مع المصدر الحي.

## حقائق Production المثبتة
- ORD-1006: Partially Returned؛ source=pos؛ created_by=cashier@rawaea.com؛ created_at=2026-10-11T07:31:00.768458+00:00؛ current total=135؛ original total=185؛ runsheet_id=NULL.
- تفاصيل الطلب: مجموع qty=2؛ مجموع qty_returned=1؛ المتبقي=1.
- create_runsheet_atomic وappend_orders_to_runsheet_atomic يحتويان حارس مصدر يسمح بـ telesales وtele-sales وorder-taker وonline-store، ويرفض pos والمصدر الفارغ/المجهول.
- ACL للدالتين: anon=false، authenticated=false، service_role=true؛ SECURITY DEFINER مع search_path=public.
- Edge Production: create-runsheet v26 ACTIVE verify_jwt=true؛ append-to-runsheet v8 ACTIVE verify_jwt=true.

## المصدر والسبب
Snapshot Current/PWA/main.html blob SHA 27b777528665dcc985809648f006452c861ae36e ما زال يعرض العيوب الموثقة: عدّ التفاصيل لا يراعي qty_returned، Realtime يحدّث رأس الطلب دون إعادة حساب التفاصيل المشتقة، الجدول لا يعرض المصدر/المنشئ/وقت الإنشاء، ومربعات الاختيار لا تستبعد POS. الملف الحي erp-frontend/companies/company-1/main.html له SHA 4f94f9c6ebdde1b59632384628c72767d3bb950d لكن محتواه فارغ عبر الموصل؛ لا يجوز استبداله عميانيًا.

## القرار
لا يوجد تعديل Production إضافي مبرر في هذه الدورة؛ عقد Core موجود بالفعل. التعديل الجراحي الأمامي موثق بالنصوص الكاملة في Report413، الأقسام 3A–3G. الملف الذي يعدله المالك فقط: erp-frontend/companies/company-1/main.html داخل RW_Orders. يجب مطابقة كل توقيع في الملف الحي قبل الاستبدال. لا تعدّل main.html أو التطبيقات التشغيلية من المساعد.

## الاختبارات بعد التطبيق
1. ORD-1006 يعرض المصدر كاشير، المنشئ كاشير مع البريد للتدقيق، وقت الإنشاء، عدد أصناف متبقية=1، الإجمالي النهائي=135.
2. POS والمصدر الفارغ/المجهول لا يمكن تحديدهما للرانشيت، والـRPC يرفض التجاوز.
3. اختبار مصدر مؤهل، Realtime، تفاصيل المرتجع، والطباعة من متصفح مصادق عليه.
4. تسجيل SHA المنشور والتحقق من baseline بعد اختبار Fixture معزول. لم تُنشأ بيانات تجريبية في Production.

## الحالة
VERIFIED: Production row/details، RPC source guard، ACL، Edge versions.
UNVERIFIED: live main source content/parity، تطبيق Patch، نشر الواجهة، browser/HTTP E2E، Realtime والطباعة.
لم تُعدّل بيانات الأعمال أو المخزون أو المحاسبة أو SQL أو Edge في هذه الدورة.
Final Closure Status: NOT CLOSED — بانتظار تطبيق المالك للتعديل الجراحي المطابق ثم اختبار المتصفح.

## SELF-AUDIT FINAL
What I Proved: حالة ORD-1006 وحارس Core وACL وإصدارات Edge.
What I Did Not Prove: تطابق المصدر الحي أو نشر الواجهة أو E2E.
What I Fixed: لا تغيير Production إضافي؛ تم توثيق المزامنة الحالية.
What I Initially Missed: عيوب الواجهة مستقلة عن صحة Core guard.
What Could Still Be Wrong: قد تختلف دوال RW_Orders الحية عن Snapshot.
Final Confidence: عالٍ في بيانات Production؛ غير مثبت في الواجهة الحية.
Final Closure Status: NOT CLOSED.
