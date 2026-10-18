# Report437 — POS: خزينة الجهاز تلقائيًا دون إلزام QR — 2026-10-18

## PRE-CHANGE SELF-AUDIT

**النطاق:** دورة فتح وردية POS وربط هوية الجهاز بالخزينة فقط. لم أعد كتابة `pos.html` أو `core.js` أو `main.html`. التغيير المباشر الوحيد في Production هو RPC `public.pos_open_shift`، مع تسجيل Migration في Git.

- **Business Understanding:** الكاشير يبدأ عمله بتسجيل الدخول ثم فتح وردية على جهازه. الجهاز يمثل حاوية النقد الميدانية؛ لا يجوز أن يكون مسح QR شرطًا لفتح الوردية. يجب أن تظل هوية الموظف والفرع والشركة محفوظة في كل عملية.
- **Architecture Understanding:** POS يستدعي `pos_open_shift` مباشرة عبر RPC مصادق عليه. الفواتير النقدية تُربط بالوردية والجهاز، ثم يوجّه `save_sales_invoice_atomic` القبض إلى خزينة الوردية. لم تُضف Edge Function جديدة.
- **Database Understanding:** Production يحتوي `pos_terminals`, `pos_shifts`, `pos_shift_events`, `pos_shift_cash_counts`, `treasury`, و`cash_box`. حساب الخزينة يتطلب `company_id`, `account_code`, `account_name`, `type`; الحسابات النقدية الحالية نوعها `Cash`.
- **Historical Understanding:** تمت قراءة `CURRENT_STATE.md` وReport436 كاملًا، وفحص Migration توجيه قبض POS، ومصدر POS الحالي، وتعريف RPC الحي، وقيود/فهارس/أعمدة `treasury`، وعلاقة الوردية بالخزينة، وسجلات الوردية المتاحة.
- **Production Understanding:** أعيد فحص Production مباشرة قبل التغيير. الخطأ التاريخي `SHIFT_TREASURY_SELECTION_REQUIRED` يحدث عندما لا يطابق رمز الجهاز المحلي سجل `pos_terminals` وتوجد عدة خزائن نشطة. رفض اختيار خزينة عشوائية صحيح أمنيًا، لكن جعل QR شرطًا دائمًا لا يطابق طلب المالك الحالي.
- **Current Understanding:** مصدر POS الحالي `companies/company-1/sales/pos.html`، blob SHA `962dc6474a9c2692c1072631bd9d09d359d7d982`، 2,278 سطرًا. آخر commit موثق للمصدر `e4876b012f9a00ce785b2d8c899e740102c842e7`. لم أعد تطبيق تغييرات موجودة بالفعل.
- **Execution Confidence:** مرتفع لتعديل عقد فتح الوردية واختبار SQL المعزول؛ اختبار Browser/HTTP على الـartifact المنشور لم يُنفذ في هذه الدورة.

## CURRENT PRODUCTION FACTS

اللقطة الحية قبل الإصلاح:
- `pos_terminals=1`
- `pos_shifts=1` (الوردية الموجودة مغلقة)
- `pos_shift_events=2`
- `pos_shift_cash_counts=8`
- `cash_box=6`
- `treasury=3`
- `POS orders=4`
- الخزائن النشطة الثلاث: الخزينة الرئيسية، كاشير1، كاشير2.
- الجهاز التاريخي المسجل كان مربوطًا بالخزينة الرئيسية؛ فرق الإغلاق التاريخي `-135.00` محفوظ كما هو.
- لا يجوز تغيير خزينة الجهاز التاريخي أو ترحيل عملياته القديمة إلى خزينة جديدة. الربط الحالي محفوظ، وتُنشأ خزينة مستقلة تلقائيًا للأجهزة الجديدة أو رموز الأجهزة غير المسجلة.

## ROOT CAUSE

النسخة السابقة من `pos_open_shift` كانت:
1. تستخدم خزينة الجهاز إذا تطابق `terminal_code` مع جهاز مربوط مسبقًا.
2. إذا لم تجد جهازًا مربوطًا، تحاول اختيار خزينة من الخزائن النشطة.
3. ترفض المتابعة عند وجود أكثر من خزينة نشطة برسالة `SHIFT_TREASURY_SELECTION_REQUIRED`.

رفض الاختيار العشوائي كان صحيحًا. الخلل الوظيفي هو أن تسجيل دخول الكاشير وفتح الوردية كانا يعتمدان على إعداد يدوي سابق عبر QR. الإصلاح لا يختار خزينة قائمة عشوائيًا؛ بل ينشئ خزينة نقدية محددة للجهاز نفسه عند أول فتح وردية.

## PRODUCTION REPAIR APPLIED

Migration Production:
- الاسم: `pos_terminal_auto_treasury_on_shift_open_20261018`
- نسخة Migration الحية: `20261018182808`
- ملف Git: `supabase/migrations/20261018182808_pos_terminal_auto_treasury_on_shift_open.sql`
- Commit ملف Migration: `92e648365d8b65463ceba2909860d706718a0bf8`

التغيير الجوهري في `public.pos_open_shift`:
1. التحقق من جلسة Supabase وصلاحية `pos` وسياق الشركة والفرع قبل أي إنشاء.
2. استخدام قفل معاملات `pg_advisory_xact_lock` لكل شركة/رمز جهاز لمنع إنشاء خزائن مكررة بالتزامن.
3. إذا كان الجهاز مسجلًا وله خزينة، تُستخدم الخزينة نفسها دون إعادة تعيينها.
4. إذا كان الجهاز غير مسجل أو بلا خزينة، تُنشأ خزينة `Cash` ذات رمز حتمي مرتبط بالشركة ورمز الجهاز، وفرع محدد، ورصيد افتتاحي صفر، وعلامة تدقيق تربطها بالجهاز.
5. يُسجل الجهاز ويرتبط بالخزينة الجديدة داخل المعاملة نفسها.
6. فشل فتح الوردية يُرجع المعاملة كلها، بما فيها أي خزينة/جهاز تم إنشاؤه مؤقتًا؛ فلا تبقى آثار جزئية.
7. بقيت عملية ربط الخزينة الإدارية القديمة متاحة، لكن فتح الوردية العادي لا يحتاج إليها.
8. تم الإبقاء على صلاحيات التنفيذ: `anon EXECUTE=false`, `authenticated EXECUTE=true`, `service_role EXECUTE=true`.

لم يتم تعديل `save_sales_invoice_atomic` أو trigger `pos_assign_order_shift` في هذه الدورة؛ فهما يستفيدان من `terminal_id/treasury_id` التي يثبتها فتح الوردية.

## SQL E2E — TRANSACTION ISOLATED

نُفذ اختبار SQL داخل معاملة معزولة وبهوية كاشير Production مصادق عليها، ثم أُلغيت المعاملة:
- فتح وردية على رمز جهاز تجريبي جديد دون QR: **PASS**.
- إنشاء خزينة مرتبطة بالجهاز تلقائيًا: **PASS**.
- إعادة الطلب بنفس `operation_id`: **PASS**؛ أعاد نفس `terminal_id/treasury_id` ونتيجة `duplicate=true`.
- محاولة الفتح على فرع غير مصرح به: **PASS**؛ رُفضت بـ`POS_BRANCH_NOT_ALLOWED`.
- استعادة خط الأساس بعد الاختبار: **PASS**؛ بقيت الأعداد `terminals=1, shifts=1, events=2, shift_counts=8, cash_box=6, treasury=3, POS orders=4`.
- بقايا الاختبار: `0` جهاز، `0` خزينة، `0` وردية، `0` حركة مالية.

ملاحظة: أداة SQL لم تُظهر رسائل `NOTICE`، لكن الاستدعاء انتهى دون خطأ، ثم أثبت استعلام مستقل عدم وجود أي بقايا. هذا اختبار SQL داخل قاعدة البيانات وليس Browser/HTTP E2E.

## OWNER-ONLY SURGICAL POS PATCH

**لا تعدل الملف كله. لا تلمس `main.html`.** المصدر الحالي SHA `962dc6474a9c2692c1072631bd9d09d359d7d982`.

### Patch A — إزالة QR خزينة الجهاز كشرط مرئي

**الملف:** `companies/company-1/sales/pos.html`  
**الموضع:** `#posShiftOpenPanel`، أسطر المصدر الحالية 178–183 تقريبًا.  
**ابحث عن الكتلة كاملة التالية واحذفها واستبدلها بالكتلة البديلة:**

```html
        <p class="text-sm text-slate-300">هوية الموظف منفصلة عن الجهاز. اربط الجهاز بالخزينة الثابتة مرة واحدة قبل فتح أول وردية عليه.</p>
        <button type="button" onclick="POS.bindTerminalTreasuryQR()" class="w-full p-3 rounded-xl bg-violet-700 hover:bg-violet-600 text-white font-black">
          <i class="fa-solid fa-qrcode ml-2"></i>ربط هذا الجهاز بخزينة ثابتة عبر QR
        </button>
        <p class="text-[11px] text-slate-400">يجب مسح QR للخزينة من النظام الأم بحساب المالك أو مدير مخوّل. الربط يتحقق منه الخادم ولا يعتمد على قيمة محلية وحدها.</p>
```

**البديل الكامل:**

```html
        <p class="text-sm text-slate-300">هوية الموظف تُثبت بتسجيل الدخول. هذا الجهاز له خزينة نقدية مستقلة ينشئها النظام تلقائيًا عند أول فتح وردية، ثم يثبت ارتباط الجهاز والخزينة لحماية العهدة وسجل العمليات.</p>
```

### Patch B — منع رسالة خطأ قديمة من إجبار الكاشير على QR

**الملف:** `companies/company-1/sales/pos.html`  
**الدالة:** `self.startShift`  
**ابحث عن هذا المقطع كاملًا واستبدله:**

```javascript
            if (message.indexOf('SHIFT_TREASURY_SELECTION_REQUIRED') !== -1 ||
                message.indexOf('SHIFT_TERMINAL_CONFIGURATION_REQUIRED') !== -1) {
                message = 'هذا الجهاز غير مربوط بخزينة ثابتة. اربطه أولًا بمسح QR الخزينة من النظام الأم بحساب مخول.';
            } else if (message.indexOf('SHIFT_TERMINAL_TREASURY_MISMATCH') !== -1) {
                message = 'الخزينة المختارة لا تطابق الخزينة الثابتة لهذا الجهاز. لم تُفتح وردية ولم تُغيّر الخزينة.';
            } else if (message.indexOf('SHIFT_TERMINAL_BRANCH_MISMATCH') !== -1) {
                message = 'هذا الجهاز مسجل لفرع آخر. لا يمكن نقله بتغيير اختيار الفرع.';
            }
```

**البديل الكامل:**

```javascript
            if (message.indexOf('SHIFT_TREASURY_SELECTION_REQUIRED') !== -1 ||
                message.indexOf('SHIFT_TERMINAL_CONFIGURATION_REQUIRED') !== -1) {
                message = 'تعذر تهيئة خزينة هذا الجهاز تلقائيًا. لم تُفتح الوردية. أعد المحاولة، وإذا استمر الخطأ فراجع مدير النظام.';
            } else if (message.indexOf('POS_AUTO_TREASURY_IDENTITY_CONFLICT') !== -1) {
                message = 'تعذر التحقق من هوية خزينة الجهاز. لم تُفتح الوردية ولم تُسجل حركة مالية.';
            } else if (message.indexOf('SHIFT_TERMINAL_TREASURY_MISMATCH') !== -1) {
                message = 'هوية الجهاز مرتبطة بخزينة مختلفة. لم تُفتح الوردية ولم يُغيّر النظام أي ربط مالي.';
            } else if (message.indexOf('SHIFT_TERMINAL_BRANCH_MISMATCH') !== -1) {
                message = 'هذا الجهاز مسجل لفرع آخر. لا يمكن نقله بتغيير اختيار الفرع.';
            }
```

**طريقة التطبيق:** استبدل كل كتلة كما هي، ولا تستبدل `self.startShift` كاملة. لا تحذف دالة `bindTerminalTreasuryQR` في هذه الخطوة؛ أصبحت غير مستخدمة من واجهة فتح الوردية، ويمكن إزالتها لاحقًا فقط بعد بحث كل callers على مستوى المصدر.

## INDUSTRY BENCHMARK — OFFICIAL PRODUCT DOCUMENTATION

هذه مقارنة نطاقية لتوجيه تطوير POS، وليست ادعاءً بأن كل ميزة غير مذكورة هنا غائبة قطعًا عن RAWAEA.

- **Square for Retail:** توثّق Square دعم الدفع أثناء انقطاع الاتصال مع حفظ المبيعات للمزامنة لاحقًا، وردود/استبدالات كاملة أو جزئية، وإضافة الأصناف بالباركود، وتحديث المخزون عبر المواقع والقنوات، والتنبيه لانخفاض المخزون، وأوامر الشراء والاستلام، وصلاحيات الموظفين. المصدر: https://squareup.com/us/en/retail/capabilities
- **Shopify POS:** توثّق Shopify البيع متعدد القنوات، والمخزون متعدد المواقع، واستلام/إرسال/تحويل المخزون، والتنبيهات والتقارير، وأدوار الموظفين وصلاحياتهم، وموافقات المدير لبعض العمليات، وتتبع النقد، واسترجاع/استبدال الطلبات بين القنوات. المصادر: https://www.shopify.com/pos/features وhttps://help.shopify.com/en/manual/your-account/users/roles/permissions/pos-permissions
- **ما تأكد وجوده في POS الحالي من قراءة المصدر:** قارئ/بحث باركود، ذاكرة محلية ومزامنة معلقة، تعليق واستئناف الفاتورة، الدفع النقدي وتقسيم الدفع، سجل فواتير اليوم، تدفق المرتجعات، إدارة الوردية، عدّ فئات النقد وإغلاق الوردية.
- **الأولوية الحالية ليست إضافة واجهات جديدة:** إصلاح تهيئة خزينة الجهاز دون QR أولًا. بعد تطبيق Patch A/B واختبار البيع الحقيقي، يوصى بتدقيق منفصل ومثبت لعقود: offline checkout/idempotency، manager approval للخصومات/المرتجعات، سجل تدقيق لأفعال الكاشير، ومطابقة Z-report مع cash_box. لا يُعلن أن هذه النقاط غائبة نهائيًا دون تتبع كامل لمستهلكيها وRPCs وقواعد البيانات.

## VERIFICATION MATRIX

| البند | النتيجة |
|---|---|
| Production RPC updated | VERIFIED |
| Migration recorded in Supabase | VERIFIED — `20261018182808` |
| Git migration artifact | VERIFIED — commit `92e648365d8b65463ceba2909860d706718a0bf8` |
| Existing device treasury/history preserved | VERIFIED by read-only baseline |
| No-QR first-open SQL test | PASS |
| Idempotent retry SQL test | PASS |
| Unauthorized branch SQL test | PASS |
| Baseline restored / test residue zero | PASS |
| POS HTML owner patch | PROVIDED — not yet applied |
| Browser/HTTP E2E against served artifact | UNVERIFIED |
| Cloudflare served-artifact parity | UNVERIFIED |

## SELF-AUDIT FINAL

- **What I Proved:** Production `pos_open_shift` now provisions a deterministic device-specific cash treasury on first shift open without requiring QR; company/user/branch checks remain before provisioning; repeated operation identity is idempotent; an unauthorized branch is rejected; SQL fixture was rolled back and baseline counts restored.
- **What I Did Not Prove:** Browser/HTTP E2E against the actual Cloudflare-served POS artifact; whether the owner has applied Patch A/B; end-user camera/login UX.
- **What I Fixed:** Production RPC and committed its canonical migration to Git.
- **What I Initially Missed:** Report436 correctly diagnosed a device-code mismatch, but its recommended QR-only recovery was no longer aligned with the owner's newer operating requirement. I preserved the security checks while changing first-use device setup instead of selecting an arbitrary existing treasury.
- **What Could Still Be Wrong:** The UI still shows the old QR instructions until Patch A/B are applied. Existing historical terminal remains bound to its historical treasury intentionally; it was not reassigned. The new treasury account is created when a new terminal identity first opens a shift.
- **Final Confidence:** High for the database contract and isolated SQL checks; not complete for browser/runtime UX.
- **Final Closure Status:** `PRODUCTION RPC REPAIRED / SQL E2E PASS / BASELINE RESTORED / OWNER POS PATCH PENDING / BROWSER HTTP E2E OPEN — NOT 100% CLOSED`.
