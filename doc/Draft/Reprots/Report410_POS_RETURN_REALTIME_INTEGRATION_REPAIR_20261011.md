# Report410 — Fresh Production Sync وإغلاق سبب عدم تزامن عدد الأصناف وتفاصيل مرتجع POS
**التاريخ:** 2026-10-11  
**النطاق:** تكامل مرتجع POS مع جدول أوردرات المبيعات ومودال التفاصيل في النظام الأم.  
**Production:** Supabase project `fiilmooggumokxanwiyx`  
**حدود التنفيذ:** لم أعدّل `main.html` أو `pos.html`، ولم أغيّر قاعدة البيانات أو بيانات الأعمال. التعديل في ملفات الواجهة محفوظ للمالك حسب التعليمات.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** المرتجع الجزئي يجب أن يغيّر الكمية المتبقية والإجمالي المعروض وعدد أسطر الأصناف المتبقية، مع إبقاء الكمية الأصلية وسجل البيع للتدقيق.
- **Architecture Understanding:** POS يقرأ تفاصيل الفاتورة من `public.get_pos_invoice_data(text,text)`. النظام الأم لديه `RW_Orders` ويقرأ `orders` و`order_details`. لا يوجد مبرر لتعديل Edge أو Core لإصلاح طريقة عرض الواجهة ما دامت البيانات المركزية صحيحة.
- **Database Understanding:** Production يحتوي `orders.total_amount`, `orders.original_total_amount`, `order_details.qty`, `qty_returned`, `line_amount`, `reason_return`.
- **Historical Understanding:** تمت مراجعة `CURRENT_STATE.md` وReport408 وReport409، ثم إعادة قراءة Production وCurrent Git في هذه الدورة. التقارير استرشادية؛ تم إعادة الاستعلام عن البيانات الحية.
- **Production Understanding:** `ORD-1006` ما زالت `Partially Returned`: الإجمالي الحالي 135.00 والأصلي 185.00؛ سطر `1001` كميته الأصلية 1 والمرتجع 1، وسطر `1003` كميته الأصلية 1 والمرتجع 0. Edge `complete-return v26` و`save-sales-invoice v18` نشطتان و`verify_jwt=true`.
- **Current Understanding:** POS الحالي في Git هو blob `0160f7cf9c4f194d954d2c7498d91fc639a5f419`، commit `12e68f21eca5be19beb7e9b678a1917dc1d40d71`. التعديل السابق يعرض الأصل/المرتجع/المتبقي في POS، لكن النشر وBrowser E2E غير مثبتين.
- **Execution Confidence:** مرتفع لصحة بيانات Production ولتحديد فجوة الحساب في snapshot النظام الأم؛ متوسط فقط بالنسبة إلى النص الدقيق للـmain.html الحي، لأن أداة GitHub أعادت محتوى فارغًا لهذا الملف. لا أدّعي byte parity بينه وبين snapshot.

### سجل التحقق الحي

1. تم قراءة تعريف Production لـ`public.get_pos_invoice_data(p_action text, p_order_code text)`. يعيد `qty`, `qty_delivered`, `qty_returned`, `line_amount`، ويعيد `orders.total_amount` و`order_status`.
2. ACL التي سبق التحقق منها في Production: `anon EXECUTE=false`, `authenticated=true`, `service_role=true`. الدالة `SECURITY DEFINER` مع `search_path` فارغ، وتتحقق من المصادقة وصلاحية POS والشركة والفروع المسموحة.
3. استعلام Production المباشر أعاد:
   - `ORD-1006`: `order_status=Partially Returned`, `total_amount=135.00`, `original_total_amount=185.00`.
   - `qty` الأصلية مجموعها 2، و`qty_returned` مجموعها 1، والمتبقي 1.
   - الصنف `1001`: `qty=1`, `qty_returned=1`, `reason_return=مرتجع نقطة بيع`.
   - الصنف `1003`: `qty=1`, `qty_returned=0`.
4. فحص سجلات Supabase أظهر طلبات متكررة ناجحة `GET 200` إلى `/rest/v1/order_details?select=order_id,item_code&order_id=in.(...)` من متصفح Chrome في نافذة الفحص. هذا يثبت أن مسار القراءة المباشر لعدد الأصناف نشط في وقت السجلات، لكنه لا يثبت وحده أن استجابة كل طلب احتوت صفوفًا أو أن الصفحة المنشورة تطابق snapshot.
5. تمت مراجعة snapshot `rawaie-erp-New/Current/PWA/main.html`, blob `27b777528665dcc985809648f006452c861ae36e`. فيه:
   - `loadData()` يجلب `order_id,item_code` فقط، ثم يعد كل سطر، ولا يقرأ `qty_returned`.
   - `refreshRealtimeChannel()` يشترك في تغييرات جدول `orders` فقط. عندما يجد الأوردر في الذاكرة يحدّث حقول رأس الأوردر ويستدعي `_applyFilters()`، ولا يعيد تحميل `order_details` ولا يعيد حساب `itemsCount`.
   - `_showDetails(code)` يعرض `qty` و`line_amount` الأصليين، ولا يعرض `qty_returned`، ويعيد حساب الإجمالي من السطور الأصلية ورسوم التوصيل.
6. تعذر قراءة نص `erp-frontend/companies/company-1/main.html` الحي عبر موصل GitHub؛ blob المرصود `4f94f9c6ebdde1b59632384628c72767d3bb950d`، لكن المحتوى عاد فارغًا. لذلك لا يجوز تطبيق استبدال كامل عليه قبل مقارنة النص الحي نفسه. هذا قيد إثبات، وليس مبررًا لإيقاف بقية العمل.

## السبب الجذري

هناك خللان مترابطان في مسار عرض النظام الأم، مثبتان في snapshot ومتسقان مع طلبات Production المرصودة:

1. **حساب عدد الأصناف:** الاستعلام لا يجلب `qty_returned` ولا يستبعد السطر الذي أصبح المتبقي منه صفرًا.
2. **تحديث لحظي:** مستمع Realtime يحدّث كائن الأوردر فقط. `itemsCount` قيمة مشتقة من `order_details`، لذلك لا تتجدد بمجرد تعديل رأس الأوردر وإعادة تطبيق الفلاتر.
3. **تفاصيل المودال:** العرض يستخدم الكمية وقيمة السطر الأصليتين، ويعيد اشتقاق الإجمالي بدل استخدام `orders.total_amount` النهائي.

**لا يوجد Defect مثبت في بيانات `ORD-1006` أو في عقد RPC يبرر تغيير Production SQL أو Edge Functions لإصلاح مشكلة العرض.**

## التعديل الجراحي المطلوب — Owner Change Set

### 1) الملف
`erp-frontend/companies/company-1/main.html` — لا أعدّله أنا.

### 2) الدالة والعنصر
داخل `RW_Orders`:
- `async function loadData()`
- `async function refreshRealtimeChannel()`
- `async function _showDetails(code)`

### 3) محدد البحث
ابحث داخل `RW_Orders` عن كل توقيع دالة كما هو أعلاه، وتحقق من النص الكامل في **الملف الحي** قبل الاستبدال. لا تستخدم snapshot بدلًا من النص الحي إذا اختلفت التبعيات أو أحداث الأزرار.

### 4) استبدال `loadData()` و`_showDetails(code)`
التبديل الكامل المرجعي موجود في Report408، قسم **OWNER CHANGESET — النظام الأم**:
[Report408 — POS Return State Details and Owner Changeset](Report408_POS_RETURN_STATE_DETAILS_AND_OWNER_CHANGESET_20261011.md)

- `loadData()`: يستخدم `select('order_id, item_code, qty, qty_returned')`، ويحسب السطر المتبقي فقط عندما `max(0, qty - qty_returned) > 0`.
- `_showDetails(code)`: يعرض الأصلي والمرتجع والمتبقي والملاحظة، ويستخدم `orders.total_amount` للإجمالي النهائي.
- يجب دمج البديل مع النص الحي بعد فحص تبعيات `esc`, `formatNumber`, `showLoader/hideLoader`, `Swal`, وأحداث تأكيد/حذف/طباعة؛ لا تستبدل نسخة حية مختلفة بلا دمج.

### 5) التعديل الإضافي اللازم — `refreshRealtimeChannel()`

في snapshot المرجعي، المستمع الحالي لا يعيد تحميل التفاصيل عندما يتغير الأوردر. بعد دمج ومراجعة النص الحي، استبدل الدالة كاملة بالنسخة التالية **فقط إذا كان النص الحي ما زال يطابق العقد المشار إليه**:

```javascript
async function refreshRealtimeChannel() {
    if (ordersRealtimeChannel) {
        try {
            await sb.removeChannel(ordersRealtimeChannel);
        } catch (e) {
            console.warn(e);
        }
        ordersRealtimeChannel = null;
    }

    var companyId = getCompanyId();
    ordersRealtimeChannel = sb.channel('orders-realtime-' + companyId)
        .on('postgres_changes', {
            event: '*',
            schema: 'public',
            table: 'orders',
            filter: 'company_id=eq.' + companyId
        }, function () {
            // itemsCount is derived from order_details; updating only the in-memory
            // orders row leaves the count stale after a return. Re-fetch both datasets.
            _refreshData().catch(function (e) {
                console.warn('Orders/return realtime refresh failed:', e);
            });
        })
        .subscribe();
}
```

هذه الجراحة تتجنب اشتراكًا غير مقيّد في `order_details` قد يكشف أحداث شركات أخرى. وهي تعيد قراءة أوردرات الشركة وتفاصيل الأوردرات الظاهرة عبر `loadData()` عند تغير رأس الأوردر. عقد المرتجع يجب أن يحدّث رأس الأوردر؛ وهذا حاصل في سجل `ORD-1006` عبر تغير `order_status/total_amount/updated_at`.

### 6) لا تغيّر
- لا تغيّر `qty` الأصلية.
- لا تحذف سطر المرتجع من قاعدة البيانات.
- لا تغيّر RPC أو Edge Function أو RLS لمجرد إصلاح عرض الواجهة.
- لا تلمس `pos.html`؛ تعديل عرض تفاصيل POS موجود أصلًا في commit المذكور أعلاه.
- لا تطبق أي replacement على `main.html` قبل مقارنة النص الحي؛ محتواه لم يُقرأ عبر الموصل في هذه الدورة.

## الاختبارات المطلوبة بعد الدمج والنشر

استخدم `ORD-1006` الموجودة أصلًا كـfixture قراءة، ولا تنشئ مرتجعًا ثانيًا ولا تعدّلها:
1. افتح أوردرات المبيعات وسجل عدد الأصناف قبل وبعد إعادة تحميل البيانات.
2. تحقق أن `ORD-1006` يعرض سطرًا متبقيًا واحدًا، مع حفظ السطر المرتجع في التفاصيل لأغراض التدقيق.
3. افتح المودال: سطر `1001` يعرض أصلي 1 / مرتجع 1 / متبقي 0؛ سطر `1003` يعرض أصلي 1 / مرتجع 0 / متبقي 1.
4. تحقق أن الإجمالي النهائي 135.00، وليس 185.00.
5. نفّذ مرتجعًا جزئيًا على fixture معزول جديد فقط بعد إعداد دورة مرتجع مالية صحيحة، ثم راقب تحديث الجدول دون إعادة تحميل يدوي.
6. اختبر الأوردر العادي والمرتجع الكامل والطباعة، مع التحقق من صلاحيات الشركة/الفرع.
7. بعد النشر، أعد فحص الـartifact المنشور وNetwork/Console، ثم أعد استعلام بيانات Production لإثبات عدم وجود test residue.

## التغييرات المنفذة في هذه الدورة

- **Production DB:** لا تغيير — البيانات وعقد القراءة متسقان مع حالة المرتجع.
- **Edge Functions:** لا تغيير — `complete-return v26` و`save-sales-invoice v18` نشطتان؛ لم يثبت عيب backend يسبب اختلاف العرض.
- **POS source:** لا تغيير — الإصلاح السابق موجود في Git؛ النشر وBrowser E2E غير مثبتين.
- **main.html:** لا تغيير — التعديل للمالك فقط، كما أن نص المصدر الحي لم يُسترجع من الموصل.
- **Fixtures:** لم تُنشأ بيانات جديدة ولم تُعدّل بيانات الأعمال؛ استخدمنا `ORD-1006` الموجودة أصلًا كدليل قراءة فقط.
- **Governance:** هذا التقرير يسجل إعادة فحص Production وGit في نفس دورة العمل.

## SELF-AUDIT FINAL

- **What I Proved:** بيانات `ORD-1006` متسقة؛ RPC تعيد الحقول اللازمة؛ Edge versions الحالية؛ snapshot يبين غياب حساب المتبقي وغياب refresh المشتق في مستمع Realtime؛ سجلات Supabase تثبت طلبات القراءة المباشرة إلى `order_details`.
- **What I Did Not Prove:** النص الكامل للـmain.html الحي؛ أن POS commit منشور على الاستضافة؛ Browser E2E بعد النشر؛ أن الجدول والمودال والطباعة في الموقع المنشور أصبحت صحيحة.
- **What I Fixed:** لم أغيّر بيانات صحيحة أو backend بلا داعٍ. حدّدت إصلاحًا إضافيًا في Realtime إلى جانب البديلين الكاملين الموثقين في Report408.
- **What I Initially Missed:** إصلاح `loadData()` وحده لا يضمن التحديث اللحظي؛ يجب إعادة تحميل التفاصيل عند وصول تحديث رأس الأوردر لأن `itemsCount` مشتق من `order_details`.
- **What Could Still Be Wrong:** قد تختلف الدوال الحية عن snapshot؛ قد لا تُنشر نسخة POS الحالية؛ وقد تبقى الطباعة غير متوافقة حتى فحصها.
- **Final Confidence:** مرتفع في عقد بيانات Production؛ متوسط في تشخيص المصدر الأم بسبب عدم استرجاع النص الحي؛ غير مثبت في نشر الواجهة وBrowser E2E.
- **Final Closure Status:** `PRODUCTION DATA VERIFIED / BACKEND CHANGE NOT WARRANTED / OWNER UI PATCH SPECIFIED / LIVE MAIN SOURCE COMPARISON + DEPLOYMENT + BROWSER E2E OPEN / NOT CLOSED`.

## نقطة الاستئناف الدقيقة

1. المالك يفتح `erp-frontend/companies/company-1/main.html` من المصدر الحي ويقارن الدوال الثلاث قبل أي استبدال.
2. يدمج بدائل `loadData()` و`_showDetails(code)` من Report408 مع إصلاح Realtime أعلاه.
3. ينشر الواجهة بالطريقة المعتادة، ثم يختبر الجدول والمودال والطباعة على `ORD-1006` قراءةً، ويستخدم fixture معزولًا لأي mutation E2E.
4. بعدها فقط يمكن تسجيل إغلاق واجهة النظام الأم. لا تسجل `100% CLOSED` قبل Browser E2E وartifact parity.
