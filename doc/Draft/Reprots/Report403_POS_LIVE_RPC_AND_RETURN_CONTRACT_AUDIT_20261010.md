# Report403 — POS Invoice/Return Runtime Evidence and Cash Refund Contract Audit

**التاريخ:** 2026-10-10  
**النطاق:** تطبيق الكاشير POS فقط، تبويبا «فواتير اليوم» و«مرتجع»، وعقد رد النقد/الدرج.  
**Production:** Supabase `fiilmooggumokxanwiyx`  
**Frontend:** `papamohammed77-glitch/erp-frontend`  
**Documentation:** `papamohammed77-glitch/rawaie-erp-New`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** الكاشير يحتاج إلى عرض فواتيره، فتح تفاصيل الفاتورة، واختيار فاتورة POS أصلية للمرتجع. تسجيل الإشعار الدائن ليس مساويًا لرد نقدي فعلي من درج الكاشير.
- **Architecture Understanding:** POS source → authenticated `get_pos_invoice_data` RPC → `orders/order_details`; تنفيذ المرتجع الحالي → `complete-return` Edge Function → `complete_sales_return_credit_note_atomic` → `complete_return_atomic`.
- **Database Understanding:** تم فحص تعريف RPC المنشورة وACL والجداول المالية ذات الصلة.
- **Historical Understanding:** تمت مراجعة `CURRENT_STATE.md` وReport402 وcommit/source checkpoint. لم أعد تطبيق Patch A–E لأن commit الحالي يحتويها بالفعل.
- **Production Understanding:** Production هو المرجع. سجلات Edge/PostgREST الحية تُظهر طلبات authenticated من مستخدم الكاشير إلى RPC بإجابات HTTP 200.
- **Current Understanding:** ملف POS الحالي يحتوي `_getPosInvoiceData`, `_searchReturnInvoice`, `renderInvoicesView`, `_viewActiveInvoice`, و`_viewCancelledInvoice`. لم يتم تعديل `main.html` أو `pos.html`.
- **Execution Confidence:** مرتفع في عقد قراءة الفواتير/RPC والـACL؛ متوسط في E2E الوظيفي بسبب عدم وجود تسجيل مرئي موثّق من جلسة المتصفح في هذه الدورة؛ منخفض/غير مكتمل في رد النقد من درج مستقل.

### مصادر التحقق

- `erp-frontend/companies/company-1/sales/pos.html` — current blob SHA: `21c6a0b318b9eb629f8f1917f9b3a4bbf21decfa`.
- Commit الحالي المسجل في checkpoint: `3b27e45adbdfcea4a08f414b2dc5a9082f1be422` — `Refactor return invoice search and data retrieval`.
- Production RPC: `public.get_pos_invoice_data(text,text)`; `SECURITY DEFINER=true`; `search_path=''`.
- ACL حي: `anon EXECUTE=false`, `authenticated EXECUTE=true`, `service_role EXECUTE=true`.
- Production Edge Function `complete-return`: version 26, `verify_jwt=true`; تستدعي `complete_sales_return_credit_note_atomic`.
- الفواتير الموجودة أصلًا: `ORD-1004` بإجمالي 275 وثلاثة أسطر، و`ORD-1005` بإجمالي 185 وسطرين، بتاريخ 2026-10-10؛ لم تُنشأ أو تُحذف بيانات تجريبية.

## 1. نتائج Production الفعلية

### HTTP / PostgREST

سجلات Production الحية تتضمن طلبات من مستخدم الكاشير المصادق عليه `8dbcede3-3a94-40c6-a6c9-7d500f127f4a`، مرجع الصفحة `https://rawaea-erp.pages.dev/`، إلى:

`POST /rest/v1/rpc/get_pos_invoice_data`

والنتائج:
- `2026-10-10T17:01:22.022Z` — HTTP 200.
- `2026-10-10T17:01:36.347Z` — HTTP 200.
- `2026-10-10T17:01:52.566Z` — HTTP 200.
- `2026-10-10T17:13:21.530Z` — HTTP 200.
- `2026-10-10T17:13:30.585Z` — HTTP 200.

هذا يثبت أن عميلًا من صفحة التطبيق وصل إلى RPC بهوية الكاشير وأن HTTP نجح. لا يكشف السجل وحده أي action أو payload كان داخل كل طلب؛ لذلك لا أدّعي أن كل نقرة UI قد اجتازت اختبارًا مرئيًا.

### Authenticated DB contract simulation

تم تنفيذ قراءة داخل transaction مع محاكاة claims لحساب الكاشير ثم `ROLLBACK`، دون أي كتابة على بيانات الأعمال. النتائج:

| الاختبار | النتيجة |
|---|---|
| `get_pos_invoice_data('today', NULL)` | PASS — يعيد `ORD-1005` و`ORD-1004` للكاشير الحالي |
| `get_pos_invoice_data('detail','ORD-1004')` | PASS — رأس الفاتورة وإجمالي 275 وثلاثة أسطر |
| `get_pos_invoice_data('return_lookup','ORD-1004')` | PASS — الفاتورة والأسطر الثلاثة ضمن النطاق المسموح |
| `get_pos_invoice_data('return_lookup','ORD-1005')` | PASS — الفاتورة والسطران ضمن النطاق المسموح |
| استعادة baseline | PASS — transaction انتهت بـ`ROLLBACK`; لا توجد بيانات تجريبية أُنشئت في هذا الاختبار |

هذا اختبار DB/JWT-claim simulation وليس بديلًا عن اختبار متصفح مرئي كامل.

## 2. التشخيص الجذري للتبويبات

كانت القراءة المباشرة من `orders` و`order_details` غير متوافقة مع سياسات RLS الخاصة بحساب POS-only؛ وقد تعيد قراءة فارغة مع HTTP 200. المسار الحالي يستعمل RPC مصادقًا عليه بدل توسيع RLS، والمصدر الحالي يحتوي بالفعل على استدعاءات RPC اللازمة. لذلك **لا يوجد مبرر لإعادة تعديل الملف الأم أو ملف POS في هذه الدورة**؛ إعادة تطبيق patch سابق ستكرر إصلاحًا موجودًا.

## 3. فجوة عقد المرتجع النقدي — مثبتة

المسار الحالي في `pos.html` يستدعي `complete-return` مع `is_pos_return: true`. الدالة المنشورة تستدعي `complete_sales_return_credit_note_atomic`، والتي تنشئ إشعارًا دائنًا وتستدعي `complete_return_atomic`.

كما أن واجهة POS الحالية تنص صراحة على أن تسجيل المرتجع لا ينفذ ردًا نقديًا/بطاقة من هذه الشاشة. فحص Production أظهر أن `treasury` يحتوي خزينة عامة واحدة نشطة (`CASH-01 / الخزينة الرئيسية`) ولا يوجد جدول واضح لوردية/درج مستقل لكل كاشير من أسماء الجداول الحالية التي تم فحصها. لا يوجد دليل كافٍ لربط رد نقدي بدرج كاشير بعينه أو لخصم المبلغ من رصيد خزينة بأمان.

**القرار:** لا تُنشأ حركة نقدية تلقائيًا من دون عقد معتمد يحدد درج/خزينة الكاشير، جلسة الوردية، صلاحية الرد، مفتاح idempotency، الربط بين الإشعار الدائن وإيصال الصرف، والقيد المحاسبي. إنشاء رد نقدي على `CASH-01` تخمين محاسبي وليس إصلاحًا آمنًا.

## 4. التعديل الجراحي المطلوب

### ملف الواجهة
- الملف: `erp-frontend/companies/company-1/sales/pos.html`
- العناصر ذات الصلة: `self._getPosInvoiceData`, `self._searchReturnInvoice`, `self.renderInvoicesView`, `self._viewActiveInvoice`, `self._viewCancelledInvoice`.
- **الإجراء الآن: لا تستبدل هذه الدوال**؛ الإصلاح موجود في الـcommit الحالي. لا تلمس `main.html` أو `pos.html) دون Defect جديد محدد بدليل runtime.
- إذا ظل التبويب لا يعرض النتائج في المتصفح، فالتعديل الجراحي التالي ليس إعادة كتابة هذه الدوال عشوائيًا؛ بل إثبات artifact المنشور وService Worker/cache مقابل blob SHA، ثم فحص payload/action ونتيجة الاستجابة عند النقرة الفعلية.

### Production / Supabase
- RPC قراءة الفواتير موجودة ومنشورة وصلاحياتها متحققة؛ لا تعديل إضافي مطلوب حاليًا في هذا العقد.
- لا يوجد تعديل نقدي منشور في هذه الدورة؛ لا تُعلن أن رد النقد مكتمل.

## 5. E2E matrix والحالة

| المسار | الحالة |
|---|---|
| Production HTTP الوصول إلى RPC من جلسة الكاشير | VERIFIED — عدة POST/200 مسجلة |
| قراءة فواتير اليوم عبر claims المصادق عليها | PASS |
| قراءة تفاصيل فاتورة POS | PASS |
| lookup لفاتورة مرتجع | PASS |
| ACL/RPC عزل anon/authenticated | PASS |
| company/branch isolation السلوكي بين شركتين مختلفتين | UNVERIFIED في هذه الدورة |
| العرض المرئي داخل المتصفح ومطابقة artifact المنشور للـblob | UNVERIFIED |
| رفض الفاتورة الملغاة من الواجهة | المصدر يحتوي الفرع؛ لم يُنفذ اختبار متصفح موثق |
| رد نقد فعلي من درج الكاشير + تحديث الخزنة والقيد المحاسبي | OPEN — العقد غير موجود/غير مثبت |
| إنشاء/تنظيف بيانات E2E | لا بيانات جديدة؛ لا residue من هذا الاختبار |

## SELF-AUDIT FINAL

- **What I Proved:** مصدر Git الحالي يحتوي إصلاح القراءة؛ RPC موجودة وآمنة نسبيًا وفق ACL/search_path؛ Production يسجل طلبات كاشير authenticated ناجحة؛ قراءة اليوم والتفاصيل وlookup نجحت بمحاكاة claims مع rollback.
- **What I Did Not Prove:** عرض UI في متصفح حقيقي لهذه الدورة، تطابق artifact المنشور مع blob، واختبار عزل شركة أخرى من runtime.
- **What I Fixed:** لا تغيير كود؛ صححت الحكم التنفيذي اعتمادًا على Production الحالي بدل إعادة جراحة موجودة.
- **What I Initially Missed:** نجاح HTTP إلى RPC لا يثبت وحده نجاح عرض البيانات في كل تبويب، كما أن credit note لا يثبت رد نقد.
- **What Could Still Be Wrong:** Service Worker/cache قد يقدمان نسخة مختلفة؛ قد تكون هناك مشكلة UI لا تظهر في سجلات RPC؛ عقد درج/وردية الكاشير غير مكتمل.
- **Final Confidence:** مرتفع في قراءة RPC؛ متوسط في تكامل الواجهة؛ غير كافٍ في cash refund.
- **Final Closure Status:** `INVOICE/RETURN READ RPC VERIFIED / FRONTEND PATCH ALREADY PRESENT / CASH REFUND CONTRACT OPEN / POS NOT CLOSED`.
