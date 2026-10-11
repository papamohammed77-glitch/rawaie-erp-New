# Report407 — إعادة تحقيق مشكلة بحث فاتورة المرتجع في POS
**التاريخ:** 2026-10-11  
**النطاق:** رسالة «الفاتورة غير موجودة في فروع POS المصرح بها» في تبويب المرتجع فقط.  
**Production Supabase:** `fiilmooggumokxanwiyx`  
**واجهة الإنتاج:** `papamohammed77-glitch/erp-frontend`  
**مستودع الحالة والتقارير:** `papamohammed77-glitch/rawaie-erp-New`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** إدخال رقم فاتورة POS صحيحة يجب أن يعيد بيانات الفاتورة وأسطرها القابلة للمرتجع، مع عدم السماح بقراءة فواتير شركة أو فروع غير مصرح بها.
- **Architecture Understanding:** واجهة POS تستدعي RPC القراءة الحالية `get_pos_invoice_data('return_lookup', code)`. لا حاجة إلى Edge Function جديدة، ولا يجوز تجاوز RLS أو توسيع نطاق الفروع لتجاوز رسالة الواجهة.
- **Database Understanding:** تمت قراءة تعريف RPC الحي، ودالة `get_pos_branches()` الحية، وبيانات الفواتير والفروع ذات الصلة، وACL.
- **Historical Understanding:** تمت مراجعة `CURRENT_STATE.md` وأحدث Checkpoints المتاحة، ومنها Report403 وReport404 وReport405 وReport406. التقارير استُخدمت للاستدلال فقط ثم أُعيد فحص Production والمصدر مباشرة.
- **Production Understanding:** تمت إعادة قراءة تعريف `public.get_pos_invoice_data(text,text)` من قاعدة Production وفحص ACL، ثم تنفيذ DB claim simulation بهوية POS الحالية على فاتورة Production قائمة.
- **Current Understanding:** تمت قراءة ملف الواجهة الحي كاملًا عبر GitHub Fetch، وفحص مقطع المرتجع؛ كما تمت قراءة ملف `Current/PWA/pos.html` المرجعي. ملف Current المرجعي أقدم بنيويًا ولا يمثل تلقائيًا نسخة الواجهة الحية.
- **Execution Confidence:** مرتفع بأن مسار RPC الحالي يستطيع استرجاع فاتورة POS حقيقية من الشركة والفرع المصرح بهما؛ غير كافٍ لتحديد سبب الرسالة في جلسة المتصفح التي أبلغ عنها المستخدم لأن كود الفاتورة الفاشل وطلب HTTP/استجابته غير متاحين.

### مصدر / Blob evidence

- Live frontend: `erp-frontend/companies/company-1/sales/pos.html`
  - Blob SHA: `fc52e51c185d945bff1ebc1c55b76601410db824`
- Historical/current reference: `rawaie-erp-New/Current/PWA/pos.html`
  - Blob SHA: `b1f008f92f85ca16005a097eff43af92e99b6929`
- الحالة السابقة التي روجعت: `rawaie-erp-New/CURRENT_STATE.md`, blob SHA عند بدء الفحص `cea10cacfa5e62531c5f280af64d3a2f3f5a4937`.

## الأدلة المباشرة

### 1. كود الواجهة الحي

في ملف `companies/company-1/sales/pos.html`:

- `self._getPosInvoiceData` (الأسطر 834–847 في النسخة التي تم جلبها) يستدعي `supabase.rpc('get_pos_invoice_data', { p_action, p_order_code })` ويتعامل مع أخطاء RPC صراحة.
- `self._searchReturnInvoice` (الأسطر 858–924) يزيل المسافات الخارجية من الإدخال، يستدعي `return_lookup`، ولا يعرض رسالة «الفاتورة غير موجودة...» إلا عندما تكون `payload.order` فارغة.
- عند وجود فاتورة، تقرأ الواجهة `payload.details` وتبني أصناف المرتجع. لذلك لا يوجد في هذا المسار استعلام مباشر إلى `orders` أو `order_details` من المتصفح.

### 2. Production RPC / Security

التعريف الحي لـ`public.get_pos_invoice_data(text,text)`:

- `SECURITY DEFINER` مع `search_path = ''`.
- يشترط `auth.uid()` وصلاحية `pos` وسياق شركة نشطًا.
- يستخرج الفروع المصرح بها من `get_pos_branches()`.
- يقيّد الفاتورة بالشركة الحالية، وبـ`branch_id` ضمن الفروع المصرح بها، وبـ`source='pos'`.
- يجلب تفاصيل الفاتورة بعد العثور على الطلب.
- ACL أعيد التحقق منها مباشرة:
  - `anon EXECUTE = false`
  - `authenticated EXECUTE = true`
  - `service_role EXECUTE = true`

لم أوسّع صلاحيات RLS أو ACL، ولم أغيّر نطاق الفروع.

### 3. اختبار قراءة Production

أُعيد فحص الفواتير الموجودة فعلًا. أحدث فاتورة POS ظاهرة وقت الفحص:

- `ORD-1006`، بتاريخ `2026-10-11`
- `source='pos'`
- `order_status='Invoiced'`
- `created_by='cashier@rawaea.com'`
- الشركة `00000000-0000-0000-0000-000000000001`
- الفرع `a38332b6-6cea-480a-ada1-6eb6ab0590db`، `BR-01`
- الإجمالي `185.00`

تم استدعاء `get_pos_invoice_data('return_lookup','ORD-1006')` بعد محاكاة JWT claims لمستخدم الكاشير داخل استعلام قاعدة البيانات. النتيجة: `success=true`، أعادت `order=ORD-1006` وسطرين من التفاصيل. كما نجح البحث عند إضافة مسافة نهائية إلى الرمز، لأن الدالة تستخدم `btrim(p_order_code)`.

هذا **DB claim simulation** وليس HTTP أو Browser E2E. لم تُنشأ أي بيانات تجريبية ولم تُعدّل أي فاتورة أو مخزون أو خزينة.

## Root-cause decision

**لم يثبت أن Production RPC عاجزة عن إيجاد فاتورة POS صالحة.** الدليل الحي يثبت أنها تعيد فاتورة حقيقية حديثة للكاشير والفرع المصرح بهما.

الرسالة التي تظهر في الواجهة تعني تحديدًا أن الاستجابة الناجحة تضمنت `payload.order = null`. وبغياب رقم الفاتورة الذي فشل فعلًا، وطلب الشبكة الفعلي واستجابته، لا يمكن حسم ما إذا كان السبب:
1. أن الرقم الذي أُدخل ليس `orders.order_code` الفعلي أو يختلف عنه؛
2. أن جلسة المتصفح الحالية تحمل هوية/شركة/صلاحيات مختلفة عن هوية الاختبار؛
3. أن المتصفح يقدم نسخة قديمة من الواجهة أو Service Worker cache؛
4. أن الفاتورة تخص فرعًا غير مصرح به، وهو رفض مقصود وليس عطلًا ينبغي تجاوزه.

لا توجد أدلة كافية لاختيار سبب من هذه الاحتمالات.

## القرار الجراحي

**لا تحذف ولا تستبدل** `self._getPosInvoiceData` أو `self._searchReturnInvoice` في `erp-frontend/companies/company-1/sales/pos.html` حاليًا. لا يوجد خلل مثبت في المقطع يبرر تغييره، واستبداله بتخمين قد يعيد عيوبًا تاريخية أو يوسع الوصول إلى فواتير غير مصرح بها.

لم أعدّل:
- `main.html`
- `erp-frontend/companies/company-1/sales/pos.html`
- قاعدة Production
- بيانات الأعمال

### الإجراء المحدد اللازم لحسم الرسالة المتبقية

في جلسة POS التي تُظهر المشكلة:
1. افتح DevTools → Network، فعّل Preserve log، ثم أعد إدخال رقم الفاتورة نفسه.
2. افتح طلب RPC `get_pos_invoice_data` وسجّل `p_action` و`p_order_code` من Request Payload، ثم سجّل HTTP status وResponse JSON.
3. قارن `p_order_code` مع `orders.order_code` للفاتورة المقصودة، وتحقق من هوية المستخدم والشركة والفرع في الجلسة نفسها.
4. إذا كانت الاستجابة من Production RPC تحتوي `order:null`، فسيكون لدينا رقم محدد يمكن تتبعه عبر الشركة والفرع والمصدر والـorder_code. إذا أعادت الاستجابة الفاتورة لكن الواجهة عرضت الرسالة، فحينها نصلح Artifact/JavaScript المحدد بدل تعديل قاعدة البيانات.

أداة قراءة السجلات الموحدة أعادت خطأ backend عند محاولة قراءة سجلات PostgREST؛ لم أعتبر ذلك دليلًا على نجاح الطلب أو فشله.

## SELF-AUDIT FINAL

- **What I Proved:** المصدر الحي يستخدم RPC؛ تعريف Production RPC يفرض الشركة والفرع وصلاحية POS؛ ACL ضيقة؛ DB claim simulation أعادت `ORD-1006` وتفاصيلها.
- **What I Did Not Prove:** HTTP الفعلي من المتصفح، الـartifact المخدوم/Service Worker parity، أو نتيجة طلب الفاتورة التي فشلت لدى المستخدم.
- **What I Fixed:** لم أغيّر كودًا أو بيانات لأن الأدلة لا تثبت أن المقطع الحالي معيب؛ تجنبت إعادة تطبيق Patch قديم أو توسيع الصلاحيات بلا مبرر.
- **What I Initially Missed:** يجب التمييز بين «RPC لا تجد الفاتورة» و«المتصفح يعرض نسخة/جلسة/رمزًا مختلفًا»؛ DB simulation وحدها لا تثبت سلوك المتصفح.
- **What Could Still Be Wrong:** قد تكون هناك فجوة في الـartifact المخدوم أو اختلاف في رمز الفاتورة/هوية الجلسة، ولا يمكن حسم ذلك قبل تسجيل Network request/response الفعلي.
- **Final Confidence:** مرتفع في مصدر الواجهة وقراءة قاعدة البيانات التي اختُبرت؛ متوسط في التشخيص النهائي للمشكلة المبلغ عنها.
- **Final Closure Status:** `SOURCE + PRODUCTION RPC VERIFIED / BROWSER ROOT CAUSE OPEN / NO UNSUPPORTED PATCH APPLIED`.
