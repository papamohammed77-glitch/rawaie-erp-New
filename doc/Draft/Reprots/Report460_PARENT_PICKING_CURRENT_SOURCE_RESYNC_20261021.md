# Report460 — استكمال التكامل الجراحي لجدول التحضير في النظام الأم
التاريخ: 2026-10-21
النطاق: `erp-frontend/companies/company-1/main.html` — وحدة `loadPicking()` / `_applyPicking()` / `_showPickingDetails()` فقط، مع التحقق من عقود Production ذات الصلة.
حدود الملكية: لم أعدّل `main.html` أو `warehouse/picker.html`. لا توجد تغييرات Production/SQL في هذه الدورة؛ تعذر تنفيذ استعلام SQL حي بسبب رفض أداة التنفيذ، لذلك لا أصف قاعدة البيانات بأنها أُعيد التحقق منها الآن.

## PRE-CHANGE SELF-AUDIT

- Business Understanding: مثبت من تقارير 458–459؛ المطلوب أعمدة مسؤول التحضير وبدايته ونهايته وملاحظات `order_details.reason_picking`، مع عرض الكميات المحضرة الفعلية من `run_sheet_details.qty_picked`.
- Architecture Understanding: الواجهة الأم تقرأ بيانات العرض، والتطبيق التشغيلي يسجل دورة التحضير؛ لا تغيير في Core أو المخزون لهذه المشكلة ما لم يثبت انحراف جديد.
- Historical Understanding: تمت قراءة `CURRENT_STATE.md` ومحتوى Report458 وReport459، والتعامل مع الأدلة القديمة كمرجع تاريخي لا كدليل Production آني.
- Current Source: GitHub أعاد للملف الحالي `main.html` blob SHA `60c83c51be5aa24993a01fe5e148c4bd247ccca6`، لكنه لم يُرجع متن الملف (فارغ) حتى عند طلب نطاق أسطر؛ لذلك لا أدّعي أنني قرأت جسم الملف الحالي أو أستخدم أرقام أسطر قديمة.
- Production Edge: قائمة Supabase الحالية تعرض `start-picking v35` و`complete-picking v18`، وكلاهما ACTIVE و`verify_jwt=true`. هذا لا يثبت حالة SQL أو واجهة HTML المخدومة.
- Production SQL: محاولة قراءة SQL الحية رُفضت من طبقة الأدوات؛ حالة وجود RPC وACL والبيانات الحالية في هذه الدورة = UNVERIFIED. Report459 يسجل تاريخيًا تطبيق `public.get_picking_display_users(uuid[])` ونجاح اختبار سياق المستخدم والعزل، لكن لا أرفع هذا إلى ادعاء تحقق حي اليوم.
- Served HTML / Browser E2E: UNVERIFIED.
- Execution Confidence: مرتفع في مواصفات الجراحة بناءً على المصادر التاريخية؛ متوسط في مطابقتها حرفيًا مع متن المصدر الحالي بسبب تعذر جلبه.

## الأدلة الحالية وحدودها

1. المصدر الحالي المعلن: `main.html` SHA `60c83c51be5aa24993a01fe5e148c4bd247ccca6`. لا توجد قراءة متن قابلة للتدقيق في هذه الدورة.
2. آخر checkpoint سابق: Report459، والذي يذكر أن `main.html` كان يحتوي استعلامًا مباشرًا إلى `public.users` وأن RPC المقيدة `get_picking_display_users(uuid[])` أُضيفت لمعالجة RLS دون توسيع قراءة دليل المستخدمين.
3. Migration canonical موجود في Git: `supabase/migrations/20261021143458_picking_display_users_read_rpc.sql`. لم يُجرَ تطبيق Migration جديد الآن، ولم يُغيّر ACL أو schema.
4. قائمة Edge الحالية تؤكد فقط إصدارات `start-picking v35` و`complete-picking v18` النشطة. لا تُثبت هذه القائمة أن HTML المخدوم يطابق Git.
5. لا دليل جديد يبرر تغيير `complete_runsheet_picking` أو `sync_run_sheet_details` أو كميات المخزون والحجوزات. لا تُنشئ بيانات أعمال اصطناعية ولا تحذف صفوفًا غير مثبت أنها fixtures.

## التعديل الجراحي المطلوب من المالك

**الملف:** `erp-frontend/companies/company-1/main.html`  
**الـSHA الحالي الذي يجب إعادة فحصه قبل التطبيق:** `60c83c51be5aa24993a01fe5e148c4bd247ccca6`  
**الدالة:** `loadPicking()`  
**قاعدة التطبيق:** لا تعتمد على أرقام الأسطر من Report458/459؛ أعد فتح النسخة الحالية وابحث عن النص الحرفي. إذا كان المقطع المباشر أدناه موجودًا، استبدله فقط. إذا لم يكن موجودًا، لا تلصق التعديل في موضع تخميني؛ حدّد كتلة جلب هوية المحضّر الفعلية أولًا.

ابحث عن هذا المقطع:

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

احذفه كاملًا واستبدله بهذا النص:

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

هذا التغيير لا يوسّع RLS على جدول `users`، ولا يغيّر بقية `loadPicking()`.

### التحقق من بقية إصلاحات Report458 قبل إعادة تطبيقها

لا تُعد تطبيق Report458 بالكامل تلقائيًا؛ افحص المصدر الحالي أولًا. يجب أن تتحقق من هذه الشروط، وتُصلح فقط ما يثبت غيابه:
- استعلام `runsheets` يجلب `picker_id,picker_start,picker_end` ويشمل الحالات `Open, Confirmed, Picking, Picked` ضمن `company_id`.
- رأس الجدول وتسلسل الصف يعرضان مسؤول التحضير ووقت البداية ووقت الانتهاء وملاحظات التحضير، مع تطابق عدد الأعمدة و`colspan`.
- الملاحظات تُجمع من `order_details.reason_picking` لأوامر الشركة والرانشيتات المحددة، مع اسم/كود الطلب والصنف وفاصل واضح؛ لا تُقرأ ملاحظات من شركة أخرى.
- `_applyPicking()` تعرض الحالة الفعلية ولا تفرض `Picked` على كل صف.
- `_showPickingDetails()` تتحقق من أخطاء استعلام الرانشيت وتفاصيله، وتعرض `run_sheet_details.qty_picked` من دون تحويل أو استبدال مصدر الكمية.
- إذا كانت هذه الوظائف موجودة بالفعل، مرّرها بلا تعديل.

## الاختبارات المطلوبة بعد تطبيق المالك

1. إعادة جلب المصدر وتسجيل SHA؛ فحص JavaScript syntax للملف الحالي.
2. نشر النظام الأم بالطريق المعتمد، ثم Hard Reload مع تعطيل Cache وتسجيل هوية HTML المخدوم.
3. حساب لديه `warehouse` ولا يملك `users`: يظهر اسم المحضّر عبر RPC، ولا يتطلب كشف دليل المستخدمين.
4. التحقق من حالات Open وConfirmed وPicking وPicked، والأوقات، والملاحظات متعددة الأصناف، والبحث والتفاصيل.
5. إعادة فحص RS-1/RS-2 عبر SQL للقراءة فقط بعد استعادة إمكانية الاستعلام: يجب أن تتطابق مجاميع `order_details.qty_picked` و`run_sheet_details.qty_picked` مع حالة الرانشيت؛ لا تستخدم رقم 13 كحقيقة حالية إلا بعد استعلام جديد.
6. إذا ظهرت الكمية صفرًا، احفظ Network response الفعلي واسم الطلب ونسخة HTML المخدومة قبل أي تعديل Core.
7. اختبر عزل الشركة وعدم ظهور أسماء أو ملاحظات من شركة أخرى.
8. لا تنشئ بيانات أعمال اختبارية في Production ولا تحذف بيانات لم تثبت هويتها كـfixture.

## التغييرات المنفذة في هذه الدورة

- لا تعديل على Production SQL أو RPC أو ACL أو Edge Functions.
- لا تعديل على ملفات HTML.
- لا إنشاء أو حذف بيانات أعمال.
- أُعد هذا التقرير لتحديد الجراحة التالية وحدود ما ثبت وما بقي غير متحقق.

## SELF-AUDIT FINAL

- What I Proved: SHA الحالي المعلن لـmain.html تغيّر إلى `60c83c51be5aa24993a01fe5e148c4bd247ccca6`; قائمة Edge الحالية تعرض start-picking v35 وcomplete-picking v18 نشطتين؛ migration canonical وReport459 متاحان في Git.
- What I Did Not Prove: متن main.html الحالي، حالة RPC/ACL في SQL اليوم، بيانات Production الحالية، تطابق HTML المخدوم، أو نجاح Browser E2E.
- What I Fixed: لا تعديل تشغيلي في هذه الدورة؛ حدّدت الاستبدال الجراحي المقيد بـRPC وكتبت شروط منع إعادة تطبيق إصلاحات موجودة.
- What I Initially Missed: الاعتماد على تقرير سابق وأرقام أسطر قديمة لا يكفي بعد تغير blob الحالي.
- What Could Still Be Wrong: قد يكون المقطع قد تغيّر أو يكون الإصلاح مطبقًا بالفعل؛ يجب مطابقته حرفيًا على المصدر الحالي قبل أي لصق.
- Final Confidence: متوسط؛ مرتفع في الحدود والعقد الموصوفين، غير كافٍ لإغلاق runtime.
- Final Closure Status: `OWNER SOURCE PATCH / SOURCE BODY RECHECK / LIVE SQL RECHECK / SERVED HTML + BROWSER E2E OPEN — NOT CLOSED`.
