# Report439 — التحقيق الجنائي لتكامل POS مع Production وإغلاق فجوات الجلسة والوردية

**التاريخ:** 2026-10-18 UTC  
**النطاق الوحيد:** `erp-frontend/companies/company-1/sales/pos.html`، وما يتصل مباشرةً بعقد جلسة POS في `core.js)، وProduction Supabase.  
**سياسة التعديل:** لم يتم تعديل `main.html` أو `pos.html` أو `core.js` من هذه الجلسة. ملفات التطبيق التشغيلي تعديلات مالك النظام؛ تم تنفيذ فحوص Production للقراءة فقط واختبار RPC داخل معاملة تنتهي بـROLLBACK. لم تُنشأ مبيعات أو قيود مالية دائمة.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** لا يجوز إتمام بيع نقدي دون وردية مفتوحة ومتحقق منها؛ يجب ربط الفاتورة والقبض بالخزينة والوردية والجهاز نفسه، مع عدم إظهار نجاح غير حقيقي.
- **Architecture Understanding:** POS PWA يستدعي `pos_get_shift_summary` و`pos_open_shift` مباشرة عبر Supabase client المشترك؛ ترحيل الفاتورة يمر عبر Edge `save-sales-invoice` ثم `save_sales_invoice_atomic` وقلب المخزون/المحاسبة. لا توجد حاجة مثبتة إلى Edge Function جديدة.
- **Database Understanding:** Production يحتوي `pos_terminals`, `pos_shifts`, `pos_shift_events`, `pos_shift_cash_counts`, `cash_box`, `treasury`, وحقول `orders.shift_id/device_id`. الدوال المحورية مقيّدة بصلاحياتها الحالية.
- **Historical Understanding:** تقارير Report434–Report438 وسجل الحالة استخدمت للتوجيه فقط؛ تمت إعادة قراءة المصدر الحالي وقراءة تعريفات Production الحية قبل الحكم. لا أعدّ تقريرًا تاريخيًا دليلًا على الحالة الحالية.
- **Production Understanding:** المشروع `fiilmooggumokxanwiyx`; تم فحص تعريفات الدوال وACL والسجلات الحية والعلاقات بين الطرفيات والورديات والفواتير والقيود النقدية.
- **Current Understanding:** `pos.html` blob SHA `b09320129dd04a833d1304a76fee0768ab7c52a3` (2,292 سطرًا)، و`core.js` blob SHA `c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81` (773 سطرًا).
- **Execution Confidence:** مرتفع لعقود SQL الحالية والسبب المرجّح لطلبات RPC غير المصادق عليها؛ متوسط للتشخيص النهائي لسجلات 401 لأن السجلات لا تكشف الدور النهائي للـJWT. لا يوجد اختبار Browser/HTTP حقيقي في هذه الجلسة.

### سجل المصادر

- **Current POS:** مقروء، SHA أعلاه. مواضع مهمة: `_getShiftTerminalCode` عند السطور 290–299؛ `loadShiftState` عند 494–545؛ `startShift` عند 587 وما بعدها؛ `finalizeCheckout` عند 1243 وما بعدها؛ واجهة فتح الوردية عند 178 وما بعدها.
- **Current shared core:** مقروء، SHA أعلاه؛ استدعاء `signOut()` في فرع فشل تحميل الملف الشخصي قرب السطر 153، وفي `doLogout` قرب السطر 180.
- **Historical/Current reports:** Report434, Report435, Report436, Report437, Report438، وسجل `CURRENT_STATE.md`؛ استُخدمت كدلائل تاريخية ثم طوبقت مع المصدر الحي.
- **Production migrations:** `20261018161000_pos_terminal_treasury_sale_routing.sql` و`20261018182808_pos_terminal_auto_treasury_on_shift_open.sql) موجودتان في Git، ونسختا Production المقابلتان ظاهرتان في قاعدة البيانات.
- **Production Edge:** `save-sales-invoice` نشطة، v19، `verify_jwt=true`. لم يُنشأ أي Function جديد.
- **Production logs:** آخر سلسلة مرئية في نافذة السجلات التي فُحصت تتضمن `POST 401 /rest/v1/rpc/pos_get_shift_summary` و`permission denied for function pos_get_shift_summary` بين 19:45:50 و19:46:45 UTC يوم 2026-10-18. لا يُثبت هذا السجل وحده أن الطلب وصل بدور `anon`؛ لا أدّعي معرفة JWT role النهائي.

## نتائج مطابقة Production الحالية

### 1. ACL وعقد RPC

استعلام Production مباشر أثبت:

| Function | anon EXECUTE | authenticated EXECUTE | القرار |
|---|---:|---:|---|
| `pos_get_shift_summary(uuid)` | false | true | لا تمنح anon |
| `pos_open_shift(uuid,text,numeric,uuid,uuid,text)` | false | true | صحيح |
| `save_sales_invoice_atomic(jsonb,jsonb,text,text)` | false | false | صحيح؛ يستدعيها المسار الخادمي |

تم تنفيذ اختبار محاكاة مقيد داخل معاملة بـ`SET LOCAL ROLE authenticated` وclaims لمستخدم POS موجود، ثم استدعاء `pos_get_shift_summary(NULL)` و`ROLLBACK`. النتيجة: `success=true, active_shift=false, shift=null`. هذا يثبت أن الدالة قابلة للتنفيذ بدور authenticated عند توفر سياق مصادقة صحيح، لكنه **ليس** اختبار HTTP حقيقيًا ولا يثبت ما كان داخل JWT الخاص بالطلبات المسجلة.

**قرار Production:** لم أغيّر ACL أو تعريف الدوال؛ لا يوجد دليل يبرر منح `anon` أو تعديل Core. منح anon سيضعف حدًّا أمنيًا حول معلومات الوردية المالية.

### 2. حالة بيانات POS عند آخر استعلام حي

عند `2026-10-18 19:48:07 UTC`:

- الطرفيات: 2.
- الورديات: 2، وكلتاهما مغلقتان.
- أحداث الورديات: 4.
- صفوف عدّ النقد: 16.
- صفوف `cash_box`: 8.
- الخزائن: 4.
- فواتير POS: 5.
- الورديات المفتوحة: 0.

ظهرت خزينة تلقائية واحدة بعلامة `RAWAEA_AUTO_POS_TREASURY`، مرتبطة بطرفية فعلية ووردية مغلقة وفاتورة POS وسجلات قبض/رد نقدي. لذلك **لا أصنّفها مخلفات اختبار ولا أحذفها**. الطرفية والوردية التاريخيتان اللتان تحملان فرق إغلاق `-135.00` لهما سجلات قبض/مرتجع مرتبطة؛ حُفظتا دون تعديل. الوردية الأحدث فرقها `0`، ولها فاتورة مرتبطة تحمل `shift_id/device_id` وسجلات نقدية مرتبطة. توجد فواتير تاريخية أقدم ذات `shift_id/device_id = NULL`؛ لا تُحدّث بأثر رجعي لأن مصدرها وتاريخها لا يثبتان أنها عيوب أو بيانات اختبار.

### 3. ما أصبح صحيحًا في المصدر الحالي

- رسالة فتح الوردية توضّح أن خزينة الجهاز تُنشأ تلقائيًا؛ لم يعد واجبًا مسح QR لبدء وردية جديدة.
- `startShift` يحفظ `terminal_id` و`treasury_id` الراجعين من Production قبل إعادة تحميل حالة الوردية.
- `finalizeCheckout` يمنع البيع دون وردية موثقة، ويتحقق من تطابق الفرع، ويرسل `shift_id` و`device_id`، ويمنع الدفع غير النقدي غير المدعوم.
- generic cash customer محدد في عقد البيع الحالي، وخيارا البطاقة والدفع المختلط معطلان بدل تسجيلهما خطأً كنقد.
- `pos_get_shift_summary` يعيد `terminal_code` ضمن JSON؛ مقارنة الطرفية في المصدر ليست معتمدة على حقل مفقود.
- لا يوجد دليل كافٍ لإعادة كتابة التطبيق أو تغيير قاعدة بياناته في هذه الدورة.

## العيب المتبقي A — استدعاء ملخص الوردية دون التحقق من جلسة Supabase الحية

**الدليل:** `pos.html` السطر 500 يستدعي RPC مباشرة. الشرط الحالي يفحص `currentUser` ووجود client فقط؛ لا يتحقق من `supabase.auth.getSession()` أو تطابق مستخدم الجلسة مع `currentUser.auth_id`. Production logs سجّلت 401 وpermission-denied لهذه الدالة، بينما ACL الحالي يسمح بـauthenticated ويرفض anon. هذا يجعل إرسال RPC عند جلسة مفقودة/منتهية تفسيرًا قويًا، لكنه لا يثبت وحده سبب كل طلب فاشل.

### التعديل الجراحي للمالك — POS

- **الملف:** `erp-frontend/companies/company-1/sales/pos.html`
- **الدالة:** `self.loadShiftState = function(callback)`
- **السطر:** 500 وفق blob SHA الحالي فقط.
- **محدد البحث:** السطر الحرفي:
  `supabase.rpc('pos_get_shift_summary', { p_shift_id: null }).then(function(res) {`

**احذف هذا السطر فقط واستبدله بالمقطع التالي كاملًا:**

```javascript
    supabase.auth.getSession().then(function(sessionResult) {
        var session = sessionResult && sessionResult.data ? sessionResult.data.session : null;
        if (!sessionResult || sessionResult.error || !session || !session.user || !session.user.id ||
            !currentUser || !currentUser.auth_id ||
            String(currentUser.auth_id) !== String(session.user.id)) {
            RW_UI.toast('انتهت جلسة الدخول أو لم تعد مطابقة للمستخدم الحالي؛ أعد تسجيل الدخول قبل إدارة الوردية أو البيع.', 'warning');
            return {
                error: new Error('POS_SESSION_REQUIRED'),
                data: null
            };
        }
        return supabase.rpc('pos_get_shift_summary', { p_shift_id: null });
    }).then(function(res) {
```

- **طريقة التطبيق:** استبدل السطر المحدد فقط؛ اترك جميع معالجة `res.error` ونجاح الدالة و`catch` كما هي. هذا يحافظ على مسار النجاح الحالي ويمنع إرسال RPC إذا كانت الجلسة غائبة أو لا تطابق ملف المستخدم.
- **الأثر:** يقلل طلبات RPC المجهولة، ويمنع الاعتماد على حالة وردية قديمة عند غياب الجلسة. لا يغيّر ACL ولا يمنح صلاحية إضافية.
- **الاختبار:** مستخدم POS بجلسة صالحة؛ جلسة منتهية/غير موجودة؛ جلسة لمستخدم مختلف عن `currentUser.auth_id`؛ مستخدم بلا صلاحية POS؛ ثم راقب سجلات Production وتأكد من توقف 401 المتكررة. لا تعتبر هذا الاختبار مكتملًا قبل تطبيق المالك ونشره.

## العيب المتبقي B — تسجيل الخروج الافتراضي يوسّع الأثر إلى الجلسات الأخرى

**الدليل:** `core.js` SHA `c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81` يستدعي `supabase.auth.signOut()` بلا `scope` في فرع فشل hydrateProfile قرب السطر 153، وفي `doLogout` قرب السطر 180. هذا لا يطابق متطلب الجلسة المحلية لكل جهاز الذي وثقته تقارير POS السابقة.

### التعديل الجراحي للمالك — Core مشترك

1. في فرع `if (error || !user)` داخل `doLogin`، ابحث عن `supabase.auth.signOut().then(function() {` واستبدل **الاستدعاء فقط** بـ`supabase.auth.signOut({ scope: 'local' }).then(function() {`.
2. داخل `function doLogout(callback)`، ابحث عن `supabase.auth.signOut().then(function() {` واستبدل **الاستدعاء فقط** بـ`supabase.auth.signOut({ scope: 'local' }).then(function() {`.

**الأثر:** تسجيل الخروج من جهاز POS لا يطلب إبطال جلسات الأجهزة الأخرى. لأن `core.js` مشترك، يجب اختبار تسجيل الخروج في POS وتطبيق تشغيلي آخر قبل اعتماد النشر.

## نقاط لا أعدّها عيوبًا مثبتة

- لا أمنح `anon` تنفيذ `pos_get_shift_summary`؛ ACL الحالي صحيح.
- لا أفعّل البطاقة/المحفظة/الدفع المختلط قبل وجود عقد تسوية محاسبي ذري مثبت.
- لا أصف التطبيق بأنه يدعم Offline Sales: وجود IndexedDB أو قارئ طابور `pending_updates` لا يثبت أن مسار checkout يكتب عملية بيع غير متصلة قابلة للمزامنة.
- لا أحذف الخزينة التلقائية أو الفواتير/الورديات المرتبطة بها كـ“بيانات تجريبية” دون إثبات منشئها وعلاقاتها. لا توجد في هذا الفحص عملية حذف أو تعديل بيانات Production.
- تحذير Tailwind CDN و404 favicon لا يفسران وحدهما خطأ صلاحية RPC.

## مصفوفة التحقق

| المجال | الحالة المثبتة |
|---|---|
| Current POS source identity | VERIFIED — blob SHA أعلاه |
| Current shared core identity | VERIFIED — blob SHA أعلاه |
| Production `pos_get_shift_summary` ACL | VERIFIED — authenticated true / anon false |
| Authenticated simulated SQL RPC | PASS — transaction rolled back |
| Production `pos_open_shift` automatic treasury path | VERIFIED from live definition + canonical migration |
| Production sale/treasury relationships | VERIFIED read-only for observed rows |
| Production ACL/schema changes | NONE REQUIRED / NONE APPLIED |
| Owner POS session guard patch | READY — not applied in this session |
| Owner local sign-out patch | READY — not applied in this session |
| Real browser/HTTP E2E with cashier login | UNVERIFIED |
| Cloudflare-served POS parity with Git | UNVERIFIED |
| Post-patch Production log verification | OPEN |

## SELF-AUDIT FINAL

- **What I Proved:** هوية المصدر الحالي؛ ACL الفعلي للدوال؛ نجاح RPC في سياق authenticated محاكى داخل معاملة مرتجعة؛ وجود 401 وpermission-denied في السجلات؛ ارتباط الخزينة التلقائية بطرفية ووردية وفاتورة وسجلات مالية؛ سلامة حفظ الأثر التاريخي.
- **What I Did Not Prove:** الدور النهائي للـJWT في الطلبات المسجلة؛ نجاح تسجيل الدخول/فتح الوردية/البيع عبر HTTP حقيقي؛ مطابقة ملف Cloudflare المنشور مع Git.
- **What I Fixed:** لا تغيير Production كان مبررًا؛ لم أغيّر ACL أو بيانات الأعمال. جهزت تعديلين جراحيين دقيقين للمصدر الذي يطبقه المالك.
- **What I Initially Missed:** تقارير سابقة وثقت مشكلة RPC، لكن لم يكن هناك تحقق جلسة حي قبل الاستدعاء؛ كما أن `signOut()` الافتراضي يوسّع أثر الخروج عبر الأجهزة.
- **What Could Still Be Wrong:** قد يكون لبعض 401 سبب آخر متعلقًا بالـJWT أو عميل Supabase؛ لا يُغلق هذا الاحتمال إلا بعد تطبيق patch واختبار HTTP ومراجعة logs الجديدة. كذلك لا يمكن إعلان دعم Offline Sales أو دفع غير نقدي.
- **Final Confidence:** مرتفع في عقد Production الحالي والعلاقات التي تمت قراءتها؛ متوسط في السبب النهائي لكل 401 حتى التحقق من runtime.
- **Final Closure Status:** `PRODUCTION CORE/ACL VERIFIED — NO DB CHANGE REQUIRED / TWO OWNER SURGICAL PATCHES READY / BROWSER HTTP E2E + SERVED ARTIFACT PARITY OPEN / NOT 100% CLOSED`.
