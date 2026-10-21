# Report459 — إصلاح قراءة هوية المحضّر في النظام الأم والتحقق الحي من كميات التحضير

**التاريخ:** 2026-10-21  
**النطاق الوحيد:** تكامل جدول التحضير في `erp-frontend/companies/company-1/main.html` مع صلاحيات Production.  
**حدود الملكية:** لم أعدّل `main.html` ولا `warehouse/picker.html`. التعديل الجراحي في HTML يطبقه المالك. نُفذ فقط إصلاح قاعدة البيانات اللازم ضمن صلاحيات Production، ووُثّق في migration canonical.

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** مثبت — جدول النظام الأم يعرض الرانشيتات وحالة التحضير وهوية المحضّر وأوقات التحضير وملاحظات النقص/التلف؛ تفاصيل الكميات مصدرها إسقاط `run_sheet_details` المشتق من `order_details`.
- **Architecture Understanding:** مثبت — `main.html` يقرأ بيانات العرض عبر Supabase Data API، وتتحكم RLS في الصفوف. لا يجوز تجاوز RLS بإتاحة دليل المستخدمين بالكامل.
- **Database Understanding:** مثبت من Production — `runsheets.picker_id/picker_start/picker_end`، و`users.id/name/email`، و`order_details.reason_picking/qty_picked`، و`run_sheet_details.qty_picked` موجودة.
- **Historical Understanding:** تمت مراجعة `CURRENT_STATE.md` وتقارير Picker 449–458، مع التعامل معها كمؤشرات تاريخية ثم إعادة فحص Production الحالي.
- **Production Understanding:** تمت قراءة تعريف `complete_runsheet_picking` و`sync_run_sheet_details`، وسياسات RLS، وامتيازات الجداول، وبيانات الرانشيتات الحية. لا يوجد دليل يبرر تغيير Core التحضير أو المخزون.
- **Current Source Understanding:** آخر commit للنظام الأم هو `bce36e7942e3d13da4a81e31738bd1a7b0e6dd4b` ووالده `ed7c4bc65fee776802e6461bef72d6a8a59c808c`. blob `main.html` الحالي حسب GitHub connector: `abe90901dfcf01f7055fe83db27183ce78390367`. تعذر على connector إرجاع متن الملف الضخم أو line ranges؛ تمت مراجعة diff الكامل للـcommit الأخير الذي يضيف التغييرات المستهدفة. لا أدّعي قراءة كامل متن `main.html` في هذه الدورة.
- **Operational Source:** `picker.html` SHA `ffe18d4483ee074230e32b1c96f60507e5876a4b`؛ لم يُعدّل.
- **Execution Confidence:** مرتفع في تشخيص RLS وإثبات بيانات Production؛ لا يمكن إغلاق الواجهة حتى يطبق المالك التغيير الجراحي ويختبر HTML المخدوم.

## 2. ما ثبت من Production في هذه الدورة

وقت الاستعلام: `2026-10-21 14:30:01 UTC` تقريبًا.

| الرانشيت | الحالة | المحضّر | بداية التحضير | نهاية التحضير | مجموع `order_details.qty_picked` | مجموع `run_sheet_details.qty_picked` |
|---|---|---|---|---|---:|---:|
| RS-1 | Picked | `picker@rawaea.com` / مسؤول مخازن (تحضير احتياطي) | موجود | موجود | 13 | 13 |
| RS-2 | Open | لا يوجد | لا يوجد | لا يوجد | 0 | 0 |

- صفوف `run_sheet_details` الفعلية لـRS-1 تعيد الكميات: item 1001 = 4، و1003 = 3، و1004 = 4، و1005 = 1، و1008 = 1؛ المجموع 13.
- لذلك لا يوجد عيب Production مثبت يعيد صفرًا للرانشيت RS-1 في القراءة الحالية. إذا بقي الصفر في المتصفح، يجب التقاط Response الفعلي من Network ونسخة HTML المخدومة قبل تغيير مصدر الكمية.
- تعريف `sync_run_sheet_details()` يجمع `order_details.qty_picked` إلى Projection عند التحديث؛ لم يُغيّر هذا المسار.
- لم تُنشأ أو تُعدّل أو تُحذف أي بيانات أعمال تجريبية.

## 3. السبب الجذري الجديد المثبت: RLS على `public.users`

التغيير الذي أُضيف في commit `bce36e7` يستعلم مباشرة من:

```js
supabase.from('users')
  .select('id,company_id,name,email')
  .eq('company_id', companyId)
  .in('id', pickerIds)
```

لكن سياسة Production `users_select_company` تسمح بقراءة دليل المستخدمين داخل الشركة فقط لمن لديه صلاحية `users`، بالإضافة إلى المستخدم نفسه. سياسة `users_select_direct_reps_warehouse` تخص مندوبي البيع المباشر، ولا تسمح بقراءة هوية المحضّر العادي لمجرد امتلاك صلاحية `warehouse`.

حساب المحضّر الفعلي `picker@rawaea.com` لديه صلاحية `warehouse` ولا يملك صلاحية `users`. لذلك استعلام الواجهة المباشر لا يضمن إرجاع الاسم؛ قد يرجع صفر صفوف بلا خطأ، فتظهر الشرطة بدل اسم المحضّر. **لم أوسّع SELECT على جدول users ولم أضعف RLS.**

## 4. إصلاح Production المنفذ

أُنشئت الدالة المقيدة التالية في Production:

`public.get_picking_display_users(uuid[])`

- تتحقق من وجود `auth.uid()`.
- تستنتج الشركة من `app_private.current_user_company_id()` ولا تقبل `company_id` من العميل.
- تتطلب `warehouse` أو `runsheets` وفق حدود قراءة الرانشيت.
- لا تُرجع إلا المستخدمين الذين تنتمي سجلاتهم للشركة الحالية والذين ارتبطوا فعلًا برانشيت داخل الشركة.
- ترفض قائمة أكبر من 500 هوية.
- تعيد فقط `id/name/email` المطلوبة للعرض.
- `SECURITY DEFINER` مع `search_path = ''` وأسماء كائنات مؤهلة بالكامل.
- تم سحب EXECUTE من `PUBLIC` و`anon` و`authenticated` ثم منح EXECUTE لـ`authenticated` فقط. فحص Production: `anon=false`, `authenticated=true`. `service_role` يظهر قادرًا على التنفيذ بحكم امتيازاته.
- لا تنشئ Edge Function جديدة، ولا تغير جداول المخزون أو كميات التحضير أو RPCs التجارية.

**Canonical migration:**  
`supabase/migrations/20261021143458_picking_display_users_read_rpc.sql`  
**Migration-file commit:** `a8b316efdae5d81adef7ed0607645c31c4af92ec` (canonical filename aligned to the applied Production version `20261021143458`; the superseded filename was removed in commit `d9802c14ed1c0777ea47056207fedcf73ca42c7d`).  
**Production migration:** تطبيق ناجح عبر Supabase Migration API.

### اختبارات Production المنفذة

1. تعريف الدالة الحية وACL: PASS — anon غير مسموح، authenticated مسموح.
2. محاكاة سياق هوية المستخدم `picker@rawaea.com` مع `auth.uid()` عبر JWT claim محلي للاستعلام: PASS — أعادت `34758d59-21db-4f28-9028-f2dd8125f69b` واسم `مسؤول مخازن (تحضير احتياطي)`.
3. اختبار تمرير هويات من شركة أخرى تحت سياق الشركة الحالية: PASS — صفر صفوف.
4. لم يُنفذ اختبار متصفح/HTTP على HTML المخدوم، ولم أدّع ذلك.

## 5. التعديل الجراحي الذي يطبقه المالك

**الملف:** `erp-frontend/companies/company-1/main.html`  
**الدالة:** `loadPicking()`  
**المرجع الحالي:** commit `bce36e7942e3d13da4a81e31738bd1a7b0e6dd4b`، والـblob الحالي المعلن `abe90901dfcf01f7055fe83db27183ce78390367`.  
**ملاحظة تحديد:** لا تعتمد على أرقام الأسطر القديمة في Report458؛ آخر commit أعاد كتابة المقطع، والـconnector لم يُرجع متن الملف الضخم لطلب line-range.

**ابحث عن هذا المقطع حرفيًا** داخل `loadPicking()`:

```javascript
var usersById = {};

if (pickerIds.length) {
    var usersRes = await supabase
        .from('users')
        .select('id,company_id,name,email')
        .eq('company_id', companyId)
        .in('id', pickerIds);

    if (usersRes.error) throw usersRes.error;

    (usersRes.data || []).forEach(function(u) {
        usersById[u.id] = u.name || u.email || '';
    });
}
```

**احذفه كاملًا واستبدله بهذا النص كاملًا:**

```javascript
var usersById = {};

if (pickerIds.length) {
    var usersRes = await supabase.rpc('get_picking_display_users', {
        p_picker_ids: pickerIds
    });

    if (usersRes.error) throw usersRes.error;

    (usersRes.data || []).forEach(function(u) {
        usersById[u.id] = u.name || u.email || '';
    });
}
```

لا تعدّل بقية `loadPicking()` ولا `_applyPicking()` ولا `_showPickingDetails()` في هذه الجراحة. هذا التعديل يستبدل مصدر اسم المحضّر فقط بمصدر مصادق ومحدود بالشركة؛ ويُبقي استعلام الملاحظات والكميات والحالات كما هو.

## 6. اختبار المالك بعد تطبيق HTML ونشره

1. أعد جلب `main.html` وسجّل SHA جديدًا؛ لا تستخدم SHA أعلاه إذا تغيّر.
2. تحقق من Syntax للـinline JavaScript كاملًا.
3. افتح النظام الأم مع تعطيل Cache.
4. افتح تبويب التحضير بحساب يملك `warehouse` فقط ولا يملك `users`: يجب أن يظهر اسم المحضّر.
5. تحقق من RS-1: اسم المحضّر ووقتا البداية والنهاية؛ المجموع في التفاصيل يجب أن يعكس صفوف `run_sheet_details` الفعلية ومجموعها 13.
6. تحقق من RS-2: الحالة Open، ولا توجد أوقات أو هوية تحضير وهمية، والكميات صفر لأنها لم تُحضّر.
7. تحقق من تجميع `reason_picking` بعد وجود ملاحظة فعلية؛ لا تخلق بيانات أعمال في Production لأجل الاختبار.
8. اختبر عزل الشركة وسلوك فشل RPC. إذا ظهر الصفر في التفاصيل، التقط Network response للطلب الذي يقرأ `run_sheet_details` ونسخة HTML المخدومة قبل أي تغيير في Core.
9. أعد استعلامًا للقراءة فقط عن كميات RS-1 وRS-2 للتأكد من عدم تغير أي كمية أو حجز.

## 7. ما لم يُثبت بعد

- لم يُثبت أن HTML المخدوم من Cloudflare يطابق Git blob الحالي.
- لم يُنفذ Browser E2E أو HTTP E2E مصادق عليه بعد إصلاح HTML.
- لا يمكن إغلاق طلب العرض حتى يطبق المالك التعديل الجراحي وينشره ويختبره.
- لم يثبت سبب الصفر الذي ظهر سابقًا في المتصفح؛ Production الحالية لا تعيد صفرًا للرانشيت RS-1.

## SELF-AUDIT FINAL

- **What I Proved:** RLS الحالية لا تضمن قراءة هوية المحضّر لحساب warehouse-only؛ Production data تعرض RS-1 بمجموع 13 في المصدر والإسقاط؛ الدالة الجديدة تعمل ضمن سياق الشركة وتمنع نتيجة cross-company.
- **What I Did Not Prove:** تطابق Cloudflare served HTML مع Git؛ نجاح الواجهة بعد نشر المالك؛ سبب الصفر التاريخي في المتصفح.
- **What I Fixed:** أضفت ونشرت RPC قراءة مقيدة بهوية المحضّر، وثبت ACL واختبار الشركة.
- **What I Initially Missed:** الاعتماد على SELECT مباشر من `public.users` رغم أن سياسة RLS تتطلب صلاحية `users` لقراءة بقية مستخدمي الشركة.
- **What Could Still Be Wrong:** قد توجد مشكلة أخرى في HTML المخدوم أو استجابة تفاصيل الرانشيت لا يمكن حسمها دون Network/browser evidence.
- **Final Confidence:** مرتفع في إصلاح RLS/هوية المحضّر؛ متوسط في التكامل النهائي للواجهة.
- **Final Closure Status:** `PRODUCTION RPC VERIFIED / OWNER SURGICAL HTML PATCH REQUIRED / SERVED HTML + BROWSER E2E OPEN / NOT CLOSED`.
