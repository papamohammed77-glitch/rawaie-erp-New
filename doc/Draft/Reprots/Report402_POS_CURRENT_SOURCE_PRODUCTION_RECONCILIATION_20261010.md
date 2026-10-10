# Report402 — مطابقة مصدر POS الحالي مع Production وإغلاق فجوة قراءة الفواتير
**التاريخ:** 2026-10-10  
**النطاق:** تطبيق POS فقط؛ لم يتم تعديل `main.html` أو `companies/company-1/sales/pos.html`.  
**Production project:** `fiilmooggumokxanwiyx`  
**Frontend repository:** `papamohammed77-glitch/erp-frontend`  
**Documentation repository:** `papamohammed77-glitch/rawaie-erp-New`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** شاشة فواتير اليوم تعرض فواتير POS التي أنشأها الكاشير المصادق عليه؛ شاشة المرتجع تحتاج إلى جلب الفاتورة وتفاصيلها والكميات المرتجعة قبل تمرير العملية إلى مسار المرتجع الحالي.
- **Architecture Understanding:** POS → authenticated PostgreSQL RPC → orders/order_details. لا حاجة إلى Edge Function جديدة ولا إلى توسيع RLS على جداول الأعمال.
- **Database Understanding:** Production يحتوي `public.get_pos_invoice_data(text,text)` بصلاحية EXECUTE للمستخدم المصادق عليه، مع SECURITY DEFINER وsearch_path فارغ.
- **Historical Understanding:** راجعت Report401 ومصدره ومقارنته بالـcommit الأحدث، ولم أتعامل مع تقرير سابق على أنه حالة حالية.
- **Production Understanding:** تمت قراءة تعريف الدالة المنشورة وفحص ACL عبر PostgreSQL catalog. لم تظهر طلبات PostgREST إلى RPC خلال نافذة السجلات التي فُحصت (2026-10-10 16:00–17:05 UTC)، لذلك لم أعتبر ذلك دليل نجاح HTTP.
- **Current Understanding:** أحدث commit ظاهر هو `3b27e45adbdfcea4a08f414b2dc5a9082f1be422` بعنوان `Refactor return invoice search and data retrieval`، في 2026-10-10T16:59:32Z. Blob المصدر الحالي `companies/company-1/sales/pos.html` هو `21c6a0b318b9eb629f8f1917f9b3a4bbf21decfa` (87,793 حرفًا).
- **Execution Confidence:** مرتفع في مطابقة Git ووجود RPC وACL؛ غير كافٍ لإغلاق Runtime/HTTP/Browser E2E.

## 2. ما أثبته الفحص الحالي

### Current Git
المصدر الحالي يحتوي بالفعل على الدوال التالية:
- `self._getPosInvoiceData` — السطر 8331.
- `self._escapePosText` — السطر 8481.
- `self._searchReturnInvoice` — السطر 8571.
- `self.renderInvoicesView` — السطر 11111.
- `self._viewActiveInvoice` — السطر 12081.
- `self._viewCancelledInvoice` — السطر 12901.

الـcommit `3b27e45adbdfcea4a08f414b2dc5a9082f1be422` يحتوي تغييرًا صريحًا يستبدل استعلامات `supabase.from('orders')` و`supabase.from('order_details')` في مسار البحث عن المرتجع وقراءة فواتير اليوم/تفاصيلها باستدعاء RPC. لذلك لم أكرر الجراحة الأمامية ولم أعدّل الملف المستهدف.

### Production Database
تم التحقق من `pg_proc` وامتيازات الدالة المنشورة:
- Signature: `public.get_pos_invoice_data(p_action text, p_order_code text)`
- `SECURITY DEFINER = true`
- `search_path = ''`
- `anon EXECUTE = false`
- `authenticated EXECUTE = true`
- `service_role EXECUTE = true`

كما تمت قراءة سجل المستخدم `cashier@rawaea.com`: الدور `كاشير`، والصلاحية `pos`، والشركة `00000000-0000-0000-0000-000000000001`. وتوجد فاتورة `ORD-1004` بتاريخ 2026-10-10 وحالتها `Invoiced` وإجماليها 275 وثلاثة أسطر. هذه بيانات موجودة مسبقًا، ولم تُنشأ بيانات اختبار جديدة.

### Current vs Previous Checkpoint
الـcheckpoint السابق كان يسجل blob مختلفًا `49eae1c7898aca76d0deecfa74a55fc31808d149` ويقول إن جراحة الواجهة ما زالت بانتظار المالك. هذا الوصف أصبح قديمًا: المصدر الحالي والـcommit الأحدث يحتويان التعديلات الأمامية بالفعل. يجب عدم إعادة تطبيق Patch A–E.

## 3. السبب الجذري
كانت شاشة الفواتير والمرتجع تعتمد على قراءة مباشرة من `orders` و`order_details`، بينما سياسات RLS الحالية لا تمنح ملف POS-only حق القراءة المباشرة. وقد تُرجع القراءة الفارغة HTTP 200؛ لذلك لا يمكن تفسيرها على أنها عدم وجود فاتورة. الإصلاح المتوافق مع العزل هو RPC مصادق عليه يفرض الشركة والفروع والصلاحية، لا توسيع RLS.

## 4. ما لم يتم إثباته — لا يُعلن الإغلاق
- لم تُثبت في هذه الدورة استجابة HTTP فعلية من جلسة متصفح مسجل دخولها إلى RPC.
- لم يُثبت أن artifact الذي يقدمه الاستضافة حاليًا يطابق blob `21c6a0b318b9eb629f8f1917f9b3a4bbf21decfa`.
- لا توجد أدلة Browser E2E على عرض `ORD-1004` وفتح تفاصيلها وتحميلها داخل شاشة المرتجع.
- لا تزال وظيفة رد النقد/البطاقة من درج/وردية كاشير مستقلة غير مثبتة كعقد مالي مكتمل. شاشة تسجيل المرتجع أو الإشعار الدائن لا تعني أن النقد رُد فعليًا.
- لم يتم تنفيذ تعديل على `main.html` أو `pos.html` أو إنشاء بيانات تجريبية.

## 5. خطة التحقق التالية
1. افتح POS بحساب `cashier@rawaea.com` في المتصفح الفعلي.
2. افتح «فواتير اليوم» وتحقق من ظهور `ORD-1004` إن كانت ضمن يوم العمل ونطاق الفروع الحاليين.
3. افتح الفاتورة وتحقق من الرأس والأسطر الثلاثة والإجمالي.
4. ابحث عن `ORD-1004` في شاشة المرتجع وتحقق من الأصناف والكميات المتاحة بعد خصم `qty_returned`.
5. تحقق من رفض الفاتورة الملغاة، وعدم إظهار فواتير مصدرها غير POS، واحترام الشركة/الفروع المصرح بها.
6. راجع سجلات PostgREST بعد الاختبار، ثم تحقق من artifact المنشور/Service Worker. لا تعتبر غياب السجل اختبار نجاح.
7. لا تعتمد رد نقد/بطاقة أو تسوية درج فردي حتى يُثبت عقده المحاسبي في Production.

## SELF-AUDIT FINAL
- **What I Proved:** Current Git يحتوي إصلاحات القراءة الأمامية؛ Production يحتوي RPC آمنة نسبيًا مع ACL ضيقة؛ توجد فاتورة حقيقية قابلة للاستخدام في الاختبار.
- **What I Did Not Prove:** HTTP E2E، Browser E2E، artifact parity، ورد النقد الفعلي.
- **What I Fixed:** لا تغيير في كود الواجهة أو Production في هذه الدورة؛ تم تصحيح سجل الحالة والتوثيق كي لا يطلب إعادة جراحة أُنجزت بالفعل.
- **What I Initially Missed:** checkpoint Report401 لم يواكب commit اللاحق `3b27e45`.
- **What Could Still Be Wrong:** قد تختلف النسخة المنشورة عن Git؛ وقد تظهر مشكلة runtime أو cache؛ كما أن عقد رد النقد/البطاقة مستقل عن إصلاح القراءة.
- **Final Confidence:** مرتفع في Source/DB/ACL reconciliation، وغير كافٍ في Runtime.
- **Final Closure Status:** `SOURCE PATCH PRESENT / PRODUCTION RPC ACL VERIFIED / BROWSER-HTTP E2E UNVERIFIED / POS NOT CLOSED`.
