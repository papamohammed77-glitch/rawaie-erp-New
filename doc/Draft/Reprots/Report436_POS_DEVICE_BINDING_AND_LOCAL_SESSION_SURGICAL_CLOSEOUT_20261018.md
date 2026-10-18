# Report436 — POS: تشخيص ربط الجهاز بالخزينة وتصحيح نطاق تسجيل الخروج — 2026-10-18

## PRE-CHANGE SELF-AUDIT

**النطاق:** الشركات/company-1/sales/pos.html وملف النواة المشترك companies/company-1/core.js، مع التحقق من Production. لم يتم تعديل main.html أو pos.html أو core.js في هذه الدورة؛ المالك يطبق تعديلات المصدر التشغيلي.

- **Business Understanding:** هوية الكاشير مستقلة عن هوية الجهاز والخزينة والوردية. لا يجوز فتح وردية على جهاز غير مربوط أو اختيار خزينة عشوائيًا.
- **Architecture Understanding:** POS → pos_open_shift / pos_bind_terminal_treasury؛ البيع النقدي يمر عبر save-sales-invoice v19 إلى save_sales_invoice_atomic ثم يرحّل القبض إلى خزينة الوردية/الجهاز.
- **Database Understanding:** Production يحتوي pos_terminals وpos_shifts وpos_shift_events وpos_shift_cash_counts، مع orders.shift_id/device_id وcash_box.shift_id.
- **Historical Understanding:** تمت مراجعة CURRENT_STATE.md وReport435 وأحدث commit لمصدر POS ومصدر POS الحالي وcore.js وتعريف RPC الحي وسجلات Postgres/PostgREST.
- **Production Understanding:** أعيد فحص الحالة الحية في fiilmooggumokxanwiyx بتاريخ 2026-10-18؛ لم يُعتمد تقرير Report435 كحقيقة حالية دون إعادة تحقق.
- **Current Understanding:** POS الحالي blob SHA 962dc6474a9c2692c1072631bd9d09d359d7d982؛ أحدث commit مرئي e4876b012f9a00ce785b2d8c899e740102c842e7. النواة المشتركة core.js blob SHA c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81.
- **Execution Confidence:** مرتفع في تشخيص خطأ فتح الوردية من Production logs وتعريف RPC؛ لا يوجد ادعاء بإجراء Browser E2E أو إصلاح واجهة منشورة.

## CURRENT PRODUCTION SNAPSHOT

- pos_terminals=1، pos_shifts=1، pos_shift_events=2، pos_shift_cash_counts=8، cash_box=6، treasury=3، orders=10.
- جهاز Production المسجل: terminal ID 6c7e8574-4146-4f45-8633-dd3335d95796، terminal code POS-f79a1587-378c-422d-9bd3-e7231e8864f4، الفرع BR-01، الخزينة 0a9d9357-b5f3-4dfa-886f-7c73de4f274e (CASH-01 / الخزينة الرئيسية). الجهاز نشط والخزينة المرتبطة به غير فارغة.
- حساب الطلب الذي فشل: cashier@rawaea.com، نشط، الشركة 00000000-0000-0000-0000-000000000001، الصلاحية pos، الفرع المسموح BR-01.
- الخزائن النشطة الثلاث هي CASH-01 / الخزينة الرئيسية، كاشير1 - الفرع الرئيسي، وكاشير2-الفرع الرئيسي. لا يجوز استخدام قاعدة «اختر خزينة واحدة» لأن العقد الحالي يربط الجهاز بخزينة ثابتة.
- Migration Production pos_terminal_treasury_sale_routing_20261018، version 20261018160955 موجودة، ومصدرها في Git: supabase/migrations/20261018161000_pos_terminal_treasury_sale_routing.sql، commit c1402a7671a69886ce909aabb3db64bfb599ab97.
- save_sales_invoice_atomic غير قابل للتنفيذ مباشرة من anon/authenticated، ومتاح لـservice_role فقط. RPCs إدارة الوردية وربط الجهاز تتطلب authenticated وتتحقق من صلاحيات المستخدم.
- سجل Production أظهر 400 على POST /rest/v1/rpc/pos_open_shift بتاريخ 2026-10-18T16:39:09.245Z؛ رسالة Postgres الدقيقة SHIFT_TREASURY_SELECTION_REQUIRED من pos_open_shift line 64. في النافذة الزمنية نفسها لم يظهر طلب pos_bind_terminal_treasury ضمن نتائج البحث.

## ROOT CAUSE — ما أثبتته الأدلة

الدالة الحية pos_open_shift تبحث عن جهاز بالشروط company_id + terminal_code. إذا وجدت الجهاز المربوط بالخزينة، فإن إرسال p_treasury_id = null صحيح ويستخدم خزينة الجهاز الثابتة. لكن الخطأ SHIFT_TREASURY_SELECTION_REQUIRED لا يحدث إلا عندما لا تجد الدالة جهازًا مطابقًا بخزينة ثابتة، ثم تحاول مسار الخزائن البديل وترفضه لأن عدد الخزائن النشطة ليس واحدًا.

بما أن الشركة والحساب متطابقان مع سجل الجهاز الحالي، فإن قيمة p_terminal_code التي وصلت في الطلب الفاشل لم تطابق الجهاز المسجل، أو أن الجهاز المطابق لم يكن له treasury_id وقت الطلب. سجل Production الحالي يثبت أن الجهاز المسجل له treasury_id؛ لذلك عدم تطابق رمز الجهاز هو التفسير الأقوى. السجل لا يحفظ قيمة p_terminal_code المرسلة، فلا يمكن الجزم بالقيمة المحلية الحالية دون قراءتها من نفس المتصفح. لا يوجد دليل يبرر تعديل RPC لاختيار خزينة عشوائية.

### الإجراء الصحيح للجهاز الذي فشل

1. افتح النظام الأم بحساب مخوّل لإدارة الخزائن.
2. افتح خزينة الجهاز المطلوبة واعرض QR الخاص بها.
3. على جهاز الكاشير نفسه افتح POS واضغط زر ربط الجهاز بالخزينة عبر QR، وامسح QR من هذا الجهاز.
4. بعد نجاح الربط، أعد فتح إدارة الوردية. يجب أن يطابق الرمز المحلي سجل pos_terminals ويُستخدم treasury_id المثبت دون إرسال خزينة يختارها الكاشير.
5. إذا استمر الخطأ، اجمع من نفس المتصفح قيمة rawaea_pos_terminal_code من Local Storage وقارنها بـ pos_terminals.terminal_code، ولا تعدّل قاعدة البيانات لتتجاوز هذا الفحص.

## مقارنة المصدر الحالي بتغييرات Report435

التغييرات التالية موجودة بالفعل في المصدر الحالي ولا تعاد:
- loadShiftState يقارن terminal_id وtreasury_id وterminal_code قبل استخدام الوردية.
- startShift يمنع استخدام وردية جهاز آخر.
- finalizeCheckout يرسل shift_id وdevice_id ويثبت العميل النقدي العام.
- loadBranches يطبق الفرع الافتراضي/قائمة الفروع المسموحة.
- loadCustomers يعطل اختيار العميل ويثبت العميل النقدي العام.
- زر ومسار bindTerminalTreasuryQR موجودان بالفعل.

لا يوجد تغيير Production إضافي مبرر في هذه الجولة: الـRPC يرفض الجهاز غير المطابق بأمان، كما أن البيع النقدي الحي قد تم توجيهه في Migration السابقة إلى خزينة الوردية. تعديل RPC ليختار أي خزينة أو إنشاء جهاز بديل تلقائيًا سيضعف عقد الأمان.

## SURGICAL OWNER CHANGE — تسجيل خروج محلي للجهاز فقط

**الملف:** companies/company-1/core.js  
**SHA الحالي:** c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81  
**الدالتان:** doLogin (تنظيف جلسة الدخول التي تعذر تحميل ملفها) وdoLogout  
**السبب:** كلا الموضعين يستدعيان supabase.auth.signOut() دون تحديد النطاق؛ هذا قد ينهي الجلسات البعيدة أيضًا، خلافًا لمتطلب استقلال كل جهاز.

### التعديل الأول — داخل doLogin

ابحث داخل hydrateProfile(function(user, error) {، في فرع if (error || !user) عن السطر:

~~~javascript
supabase.auth.signOut().then(function() {
~~~

استبدل هذا السطر فقط بـ:

~~~javascript
supabase.auth.signOut({ scope: 'local' }).then(function() {
~~~

### التعديل الثاني — داخل doLogout(callback)

ابحث داخل function doLogout(callback) عن السطر:

~~~javascript
supabase.auth.signOut().then(function() {
~~~

استبدل هذا السطر فقط بـ:

~~~javascript
supabase.auth.signOut({ scope: 'local' }).then(function() {
~~~

**لا تستبدل الدالة كاملة، ولا تغيّر main.html أو pos.html أو أي RPC.** التغيير سطر واحد في كل موضع. بعد تطبيقه اختبر تسجيل الخروج من الجهاز A وتأكد أن جلسة الجهاز B تبقى صالحة، ثم اختبر فشل تحميل ملف المستخدم بعد تسجيل الدخول وأن الجلسة المحلية تُنظّف.

## SELF-AUDIT FINAL

- **What I Proved:** الحالة الحية لجدول الجهاز والخزائن، حساب الكاشير وصلاحياته وفرعه، وجود Migration توجيه المبيعات، ACL الأساسية، وخطأ SHIFT_TREASURY_SELECTION_REQUIRED في سجلات Production.
- **What I Did Not Prove:** قيمة rawaea_pos_terminal_code الموجودة محليًا في متصفح المستخدم؛ تطابق Artifact الذي يخدمه Cloudflare مع Git؛ Browser E2E بعد تطبيق تعديل core.js.
- **What I Fixed:** لا تغييرات في Production أو ملفات التطبيق في هذه الدورة؛ لم أغير RPC سليمًا لتجاوز رفض الجهاز غير المطابق. تم توثيق التعديل الجراحي المتبقي بدقة.
- **What I Initially Missed:** اختلاف الحالة الحية عن Report435، ووجود سجل 400 بعده، وأن التعديلات A–E أصبحت بالفعل في المصدر الحالي.
- **What Could Still Be Wrong:** Local Storage على جهاز الكاشير قد يحمل terminal code مختلفًا عن السجل المثبت؛ لا يُحسم ذلك دون فحص المتصفح نفسه.
- **Final Confidence:** مرتفع في تشخيص فرع خطأ الـRPC؛ متوسط في سبب عدم التطابق المحدد لأن قيمة الطلب غير مسجلة؛ غير مثبت بالنسبة إلى Browser E2E.
- **Final Closure Status:** PRODUCTION CORE ROUTING VERIFIED / DEVICE BINDING REQUEST REQUIRES SAME-DEVICE QR RECONCILIATION / CORE.JS LOCAL SIGNOUT SURGICAL PATCH READY / NOT 100% CLOSED.
