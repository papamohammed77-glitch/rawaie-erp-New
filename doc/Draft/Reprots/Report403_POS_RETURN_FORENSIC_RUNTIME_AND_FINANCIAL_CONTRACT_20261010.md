# Report403 — التحقيق الجنائي لتبويب المرتجع في POS: Source / Production / Financial Contract
**التاريخ:** 2026-10-10  
**النطاق:** تبويب المرتجع وتكامله مع تطبيق POS والنظام الأم؛ لم يتم تعديل `main.html` أو `companies/company-1/sales/pos.html`.  
**Production project:** `fiilmooggumokxanwiyx`  
**Frontend repository:** `papamohammed77-glitch/erp-frontend`  
**Documentation repository:** `papamohammed77-glitch/rawaie-erp-New`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** POS ينشئ فاتورة فورية، ويجب أن يسمح باسترجاع الفاتورة وأصنافها ثم تسجيل المرتجع دون تكرار الكمية. المتطلب التجاري المذكور يشمل رد المبلغ من خزنة الكاشير، وليس مجرد إشعار دائن.
- **Architecture Understanding:** شاشة POS → `get_pos_invoice_data` للقراءة المصادق عليها → `complete-return` (Edge قائم) → `complete_sales_return_credit_note_atomic` → `complete_return_atomic` → `post_stock_movement` للمخزون. لم يتم إنشاء Edge Function جديدة.
- **Database Understanding:** Production يحتوي RPC القراءة وACL ضيقًا. Production لا يحتوي كيانًا واضحًا لجلسة/درج نقدي خاص بكل كاشير؛ الجداول التي ظهرت في النطاق هي `treasury` و`cash_box`، كما أن الفواتير النقدية الحالية مرتبطة بالخزينة الرئيسية.
- **Historical Understanding:** تمت مراجعة Checkpoint Report402، ومعلومات Reports399–401 المسجلة في `CURRENT_STATE.md`، ومصدر migrations الخاص بـ`get_pos_branches` و`get_pos_invoice_data`، وتعريفات Core المنشورة.
- **Production Understanding:** تمت قراءة تعريفات RPC وEdge `complete-return` الحية، وفحص ACL، وبيانات الفاتورة الحقيقية `ORD-1004` وأسطرها وخزنتها وقيدها المحاسبي. لم يتم إنشاء أو تعديل أو حذف أي بيانات أعمال.
- **Current Understanding:** أحدث commit مرئي في `erp-frontend` هو `950abb6b78680d37c8d29f1beba78c8c1d6a51a4` بتاريخ 2026-10-10T17:33:22Z؛ وهو يغيّر `switchView` ليضبط أزرار التنقل ومناطق الدفع/السلة ويستدعي `renderReturnsView`. Blob الحالي لـ`pos.html` هو `967d486147cf3ca9911c4dbd3ba89042c373577e` بطول 88,823 حرفًا.
- **Execution Confidence:** مرتفع في Source/DB/Core inspection؛ غير كافٍ لإعلان HTTP/Browser E2E أو نشر واجهة الويب متحققًا منه.

### حالة الفحوص المطلوبة

| البند | النتيجة |
|---|---|
| Historical / previous checkpoints | تمت مراجعة أحدث Checkpoint Report402 ومراجع Reports399–401 المدرجة فيه |
| Current source | تمت قراءة المصدر الحالي وتحليل الدوال المحددة |
| Production RPC / ACL | تم التحقق مباشرة |
| Schema / triggers / dependencies | تمت مراجعة الجداول والأعمدة والمشغلات والـCore المرتبط |
| Authenticated-claim DB simulation | نجحت قراءة اليوم والبحث عن ORD-1004؛ معاملة القراءة فقط |
| Production HTTP / Browser E2E | **غير مثبت**؛ لا توجد جلسة متصفح فعلية أو نتيجة HTTP موثقة في هذه الدورة |
| Served artifact / Service Worker parity | **غير مثبت** |
| Data mutation / cleanup | لم يتم إنشاء أو حذف أو تعديل بيانات أعمال |

## 1. الأدلة الحالية

### 1.1 Current Git

- Latest commit: `950abb6b78680d37c8d29f1beba78c8c1d6a51a4` — `Refactor switchView to use allowedViews array`.
- Previous relevant commit: `3b27e45adbdfcea4a08f414b2dc5a9082f1be422` — `Refactor return invoice search and data retrieval`.
- Current `pos.html` blob: `967d486147cf3ca9911c4dbd3ba89042c373577e`.
- المصدر الحالي يحتوي `self.renderReturnsView` و`self._getPosInvoiceData` و`self._searchReturnInvoice`. البحث يستدعي RPC بدل قراءة `orders/order_details` مباشرة، ويعرض خطأ منفصلًا إذا لم تعد RPC فاتورة.
- أحدث commit أصلح تنظيم `switchView` بحيث يتم استدعاء `renderReturnsView()` وإخفاء/إظهار أزرار الدفع والسلة بأمان. لذلك **لا تعِد تطبيق Patch قديم ولا تعدّل الملف المستهدف لمجرد تكرار إصلاح موجود في Git**.

### 1.2 Production RPC

الدالة الحية `public.get_pos_invoice_data(text,text)`:
- `SECURITY DEFINER = true` و`search_path = ''`.
- `anon EXECUTE = false`؛ `authenticated EXECUTE = true`؛ `service_role EXECUTE = true`.
- تتحقق من `auth.uid()` وصلاحية `pos` وسياق الشركة، وتقيّد الفواتير على الفروع التي تعيدها `get_pos_branches()`.
- `get_pos_branches()` أيضًا `SECURITY DEFINER` مع `search_path = ''` وACL ضيقة.
- تمت محاكاة JWT claims للمستخدم `cashier@rawaea.com` في SQL. استدعاء `today` أعاد `ORD-1004` و`ORD-1005`، واستدعاء `return_lookup` أعاد `ORD-1004` مع أسطرها الثلاثة. هذا **اختبار DB claim simulation** وليس HTTP أو Browser E2E.

### 1.3 بيانات Production ذات الصلة

- `ORD-1004`: `source=pos`، `order_status=Invoiced`، `total_amount=275.00`، `branch_code=BR-01`، `created_by=cashier@rawaea.com`، `customer_id=NULL`.
- تفاصيل الفاتورة: ثلاثة أصناف؛ `qty=1` لكل صنف و`qty_returned=0). قيمة `qty_delivered=0`، ولذلك يعتمد كود الواجهة على fallback إلى `qty` كما هو مكتوب حاليًا.
- الفاتورة لها إيصال نقدي في `cash_box` بقيمة 275، `source_type=POS`، `source_id` يساوي معرّف الفاتورة، والخزينة هي `الخزينة الرئيسية`.
- لا توجد في الجداول التي تم فحصها بنية واضحة لجلسات أو أدراج نقدية مستقلة لكل كاشير. لذلك لا يجوز وصف الخزينة الحالية بأنها «درج الكاشير» أو الادعاء بأن ردًا نقديًا فرديًا يمكن ربطه به الآن.

## 2. Root Cause / Findings

### A. رسالة «الفاتورة غير موجودة في فروع POS المصرح بها»

الرسالة تظهر في الواجهة عندما ترجع RPC `payload.order = null`. لكن الدليل الحي الحالي يثبت أن `ORD-1004` تطابق الشركة والفرع ومصدر POS، وأن `return_lookup` يعيدها في محاكاة claims. لذلك:
- **لم يعد هناك دليل على أن قاعدة البيانات الحالية لا تستطيع العثور على الفاتورة.**
- الاحتمالات المتبقية التي لم تُحسم هي: artifact واجهة قديم/Service Worker cache، أو أن الطلب الفعلي من المتصفح لا يرسل نفس رقم الفاتورة/الجلسة/سياق الصلاحيات. لا أختار واحدًا منهما دون HTTP/Browser evidence.
- لم يظهر سجل PostgREST صالح من استعلام السجلات الذي جُرّب؛ أداة السجلات أعادت خطأ backend عام، فلا تُستخدم النتيجة كدليل نجاح أو فشل.

### B. التبويب لا يستجيب

Current Git يحتوي إصلاحًا أحدث لـ`switchView` في commit `950abb6`. يجب نشر/تقديم هذه النسخة إلى الاستضافة ثم اختبارها في المتصفح. لم أتمكن من إثبات أن الملف الذي يقدمه الموقع الفعلي يطابق blob الحالي، لذلك لا أعلن أن مشكلة المتصفح أُغلقت.

### C. عيب فعلي في عقد المرتجع المالي

Production Edge `complete-return` v26 يستدعي `complete_sales_return_credit_note_atomic(...)`، وهذه الدالة تستدعي `complete_return_atomic(...)`. تعريف `complete_return_atomic` المنشور يشترط وجود `customer_id` عند وجود قيمة مرتجع موجبة قبل إنشاء قيد دفتر العميل، ويرفع الخطأ:
`RETURN_CUSTOMER_REQUIRED_FOR_FINANCIAL_POSTING`.

لكن فاتورة POS نقدية حقيقية مثل `ORD-1004` لها `customer_id=NULL` لأنها «عميل نقدي». وبذلك فإن مسار تسجيل المرتجع لهذه الفاتورة سيصطدم بهذا الشرط بعد اجتياز قراءة الفاتورة؛ لا يكفي إصلاح الواجهة لإغلاق المسار.

**لم أزل الشرط ولم أضف workaround**؛ لأن تجاوز دفتر العميل وحده لن ينفذ رد النقد، ولن يثبت قيدًا محاسبيًا صحيحًا أو حركة من درج كاشير. كما أن Core الحالي ينشئ قيدًا للمخزون/تكلفة المبيعات ويحدّث كمية المرتجع؛ ولا يجوز الادعاء بأن ذلك يعادل رد مبلغ البيع من خزينة الكاشير.

### D. فجوة Business Contract لا يجوز إخفاؤها

الواجهة الحالية تصرح بعد نجاح العملية أن المرتجع يسجل وفق عقد الإشعار الدائن وأنها **لا تنفذ ردًا نقديًا أو رد بطاقة**. هذا متسق مع التنفيذ الحالي لكنه لا يحقق المتطلب التشغيلي المذكور بأن يعود النقد من خزنة الكاشير. Production الحالي لا يثبت درجًا/وردية مستقلة لكل كاشير؛ الموجود المؤكد هو الخزينة الرئيسية وسجل `cash_box` المرتبط بفاتورة POS.

لذلك يجب أن يتضمن الإغلاق الكامل عقدًا واحدًا متسقًا لـ:
1. ربط كل فاتورة/عملية POS بالكاشير ووسيلة الدفع والخزينة/الدرج الفعلي.
2. رد جزئي أو كامل مع قيد idempotency ومنع تجاوز الكمية المرتجعة.
3. تحديث المخزون عبر `post_stock_movement` فقط.
4. رد نقد/بطاقة مطابق لطريقة التحصيل، وقيد مالي متوازن، وسجل تدقيق قابل للمصالحة.
5. منع الرد من درج/خزينة غير مخوّلة أو غير كافية، دون اعتبار إشعار دائن بمثابة رد نقدي.

## 3. التعديل الجراحي على الواجهة

**لا يوجد تعديل جراحي جديد مبرر الآن على `pos.html` لمعالجة قراءة الفاتورة أو التنقل**؛ لأن المصدر الحالي يحتوي بالفعل على RPC read path وعلى تحديث `switchView` الأخير. لا تحذف ولا تستبدل `self._searchReturnInvoice` أو `self.switchView` بنسخ من التقارير القديمة.

### إجراء النشر/التحقق المطلوب
- انشر commit الحالي `950abb6b78680d37c8d29f1beba78c8c1d6a51a4` من `erp-frontend` عبر آلية النشر المعتمدة للمشروع.
- بعد النشر، امسح/تجاوز Service Worker cache وأعد تحميل POS.
- سجّل طلب HTTP حقيقيًا من جلسة الكاشير إلى `get_pos_invoice_data`، ثم اختبر ظهور الفواتير، وفتح تفاصيل `ORD-1004`، وتحميلها في تبويب المرتجع. قارن artifact المخدوم مع Git.
- لا تنفذ مرتجعًا تجريبيًا على فاتورة حقيقية؛ استخدم fixture معزولًا بعد تجهيز عقد رد الأموال، ثم أثبت استعادة baseline.

## 4. اختبار/تغيير البيانات

- لم تُنشأ fixtures أو فواتير اختبار جديدة.
- لم تُحذف أي بيانات قديمة؛ لم يثبت أن أي سجل POS حالي بيانات خاطئة أو يتيمة، وحذف `ORD-1004/ORD-1005` سيُفسد سجلات خزينة وقيودًا محاسبية موجودة.
- تمت قراءة بيانات الفواتير/الخزينة فقط ومحاكاة claims للقراءة. لم يتم تعديل حالة الفاتورة أو الكميات أو الخزينة أو دفتر الأستاذ.

## 5. الحالة

- `SOURCE: PATCH PRESENT`
- `PRODUCTION READ RPC / ACL: VERIFIED`
- `DB CLAIM SIMULATION: VERIFIED`
- `LIVE HTTP / BROWSER E2E: UNVERIFIED`
- `SERVED ARTIFACT PARITY: UNVERIFIED`
- `CASH POS RETURN: DEFECT CONFIRMED IN CORE CONTRACT`
- `PER-CASHIER DRAWER / SHIFT: NOT PRESENT IN VERIFIED SCHEMA`
- `POS RETURN CLOSURE: OPEN — NOT 100% CLOSED`

## SELF-AUDIT FINAL

- **What I Proved:** مصدر Git الحالي يعرض مسار القراءة عبر RPC؛ أحدث `switchView` موجود؛ RPC/ACL الحية صحيحة ضمن الفحص؛ محاكاة claims أعادت `ORD-1004` وأسطرها؛ فاتورة العميل النقدي لا تملك `customer_id` ولها إيصال خزينة رئيسية.
- **What I Did Not Prove:** HTTP حقيقي من المتصفح، artifact المنشور، اختبار عزل فعلي من المتصفح، أو رد نقد/بطاقة حقيقي.
- **What I Fixed:** لم أجرِ تغييرات على الكود أو قاعدة البيانات في هذه الدورة؛ منعت إعادة تطبيق جراحة قديمة وثبّتت السبب المتبقي من تعريفات Production.
- **What I Initially Missed:** الفرق بين نجاح lookup وبين قابلية إتمام المرتجع ماليًا؛ المسار المالي الحالي يتطلب عميلًا معرفًا ولا يملك عقد درج كاشير مثبتًا.
- **What Could Still Be Wrong:** قد تكون الاستضافة تقدم نسخة أقدم؛ وقد توجد تفاصيل نشر/كاش لم يمكن إثباتها؛ كما أن contract رد النقد يحتاج تصميمًا وتطبيقًا واختبارًا متكاملًا.
- **Final Confidence:** عالٍ في الأدلة المصدرية وقاعدة البيانات؛ غير كافٍ للإغلاق التشغيلي.
- **Final Closure Status:** `NOT CLOSED — SOURCE/DB READ PATH VERIFIED, LIVE UI AND CASH REFUND CONTRACT OPEN`.
