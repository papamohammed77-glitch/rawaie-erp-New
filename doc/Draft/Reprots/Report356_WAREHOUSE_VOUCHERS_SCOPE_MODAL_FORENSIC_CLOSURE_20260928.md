# تقرير 356 — إغلاق جنائي لتكامل الأذونات المخزنية
## RAWAEA ERP — 2026-09-28

### 1. نقطة البداية المعتمدة
تم استرجاع آخر حالة من:
- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `CURRENT_STATE.md`
- التقارير المتسلسلة 344–355 داخل `doc/Draft/Reprots`
ثم تمت مطابقة ما ورد فيها مع Git الحالي، المصدر الحالي، Production، وقاعدة البيانات. التقارير التاريخية استُخدمت كإشارات فقط، ولم تُعامل كحالة حالية.

الحالة الحالية قبل هذه الجلسة:
- System repo HEAD: `21d4171b8f3efbbd5340198eb6a640ac9bbe55c8`
- System parent: `4b62e4b5f730186263daa63a0c7fa3dcbf60f77a`
- Frontend HEAD: `cd125b126cd40527a81f20508139506b8e48031f`
- Frontend parent: `85e825de61333f3b7da014580dd7275146818b2a`
- `vouchers.html` blob الحالي: `4b99d7f12ab0fb255b523ae29465b7d3a9f56047`
- `main.html` blob: `810e4f5440f5975f55099a124deb42b086a49183`
- `van-sales.html` blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`

### 2. النتيجة الجنائية المختصرة
تم عزل ثلاث نقاط حقيقية:

1. **قائمة `loadList()` ليست branch/workflow scoped**؛ كانت تقرأ `stock_vouchers` مباشرة على مستوى الشركة، ولذلك كانت «مكتملة» قادرة على إظهار كل العمليات.
2. **`details()` يطلب `inventory_voucher_stock_context`** رغم أن هذا السياق التفصيلي إداري بطبيعته. بعد إغلاق Production أصبح رفضه للموظف مقصودًا، ولذلك يجب على واجهة الموظف ألا تستدعيه.
3. **مودال التفاصيل يعرض طبقات إدارية لا تخص التطبيق التشغيلي**: KPI، الحركات الفعلية، المحاسبة، التدقيق، منشئ الإذن، منفذ الإكمال، وتفاصيل زمنية.

### 3. مشكلة الطباعة: ما ثبت وما لم يُعد
Commit `cd125b126cd40527a81f20508139506b8e48031f` أصلح بالفعل خطأ بناء `codeJs` داخل `details()` باستخدام literal آمن محاط بعلامة اقتباس مفردة. هذا هو الخطأ الذي كان يجعل handlers المضمنة في المودال، ومنها الطباعة والاستلام، قابلة للكسر.

لذلك:
- **لا تعدّل `printVoucher()`**.
- **لا تعيد patch الـ`codeJs` الحالي**.
- بعد تنفيذ patchات هذه الجلسة، يصبح زر الطباعة في مودال المستلم مسارًا صحيحًا: المودال نفسه يفتح، ويستدعي `App.printVoucher()`، والطباعة تطبع محتوى المودال المحدود.

### 4. Production — ما تم تنفيذه مباشرة
لم يتم إنشاء Edge Function جديدة، ولم يتم إنشاء RPC جديد.

تم تحديث البنية الموجودة عبر:
- `inventory_voucher_report`
- `inventory_control`
- `inventory_voucher_stock_context`

المعاني التي أصبحت مركزية:

#### قائمة pending
المستخدم غير الإداري يرى فقط العملية التي تقع ضمن مسؤوليته الحالية:
- Draft أنشأه بنفسه.
- Transfer Sent يكون هو `receiver_user_id`.
- DirectReturn Sent إلى فرع ضمن نطاقه.
- DirectSale / SupplierReturn Sent أنشأه بنفسه.
- Received أنشأه أو هو المستلم.

#### قائمة completed
- لا تدخل إلا `Completed` أو `Cancelled`.
- المالك/إدارة المخازن ذات الامتياز المركزي تبقى على مستوى الشركة.
- الموظف غير الإداري يبقى branch-scoped حسب `default_branch_id` و`allowed_branch_ids`.
- `reports` وحدها لم تعد تحول مستخدمًا غير إداري إلى all-company scope.

#### تفاصيل الموظف
تم تحويل عقد `VOUCHER_AUDIT` للموظف إلى payload محدود:
- Header: رقم الإذن، التاريخ، النوع، الحالة، المصدر، الوجهة، المرجع، الملاحظات، وعند اللزوم العهدة/المركبة.
- Item lines: الصنف، الكود، الوحدة، الكمية، المستلم، المتبقي.
- Audit / movements / operations / financial / KPI: غير متاحة للموظف.

#### حماية إضافية
`inventory_voucher_stock_context` أصبح إداريًا فقط؛ الموظف لا يستطيع استخدامه لتجاوز إخفاء بيانات المودال.

كما تمت إزالة وصول `created_by` و`completed_by` من نتيجة LIST للموظف، مع الإبقاء عليها للإدارة ذات النطاق المركزي.

### 5. تصحيح داخل الجلسة
أثناء اختبار التغيير الأول ظهر خطأ منطقي مؤقت: `v_all_scope` سمح للمالك بأن يتجاوز filter «مكتملة» نفسها، فظهر `IN-7` Received داخل القائمة.

تم تصحيح ذلك فورًا.
العقد النهائي هو:
- `workflow_scope` يحدد دورة العمل أولًا.
- `v_all_scope` يحدد اتساع النطاق داخل دورة العمل، ولا يلغي الحالة.

تم أيضًا اكتشاف أن استبدالًا نصيًا أوليًا للـsanitization لم يطابق تنسيق تعريف الدالة الحالي؛ لم يُعتبر نجاحًا، وتم الوصول إلى المطابقة الدقيقة ثم إعادة الاختبار حتى أصبحت الحماية مثبتة.

### 6. اختبارات Production النهائية

تمت محاكاة Auth على `auth_id` الصحيح لمستخدم BR-2:

#### BR-2 — Pending
النتيجة:
- total = 1
- voucher = `IN-7`

#### BR-2 — Completed
النتيجة:
- total = 0
- لا توجد أي عملية خارج نطاق الفرع

#### BR-2 — Details على `IN-7`
النتيجة:
- Header keys فقط
- Item keys فقط: `item_id, item_code, item_name, qty, received_qty, unit, remaining_qty`
- audit_count = 0
- movement_count = 0
- financial = فارغ
- KPI = فارغ

#### BR-2 — محاولة فتح `IN-1`
النتيجة:
- مرفوض: `غير مصرح بالوصول إلى هذا الإذن`

#### BR-2 — محاولة استدعاء stock context
النتيجة:
- مرفوض: `غير مصرح بقراءة سياق الحركة المخزنية التفصيلي`

#### Owner
- Completed = 5
- `IN-7` لا يظهر في «مكتملة» لأنه Received.
- تفاصيل `IN-1` الإدارية كاملة ما زالت متاحة:
  - audit_count = 3
  - movement_count = 5
  - financial keys = `driver_ledger, journal_entries, supplier_ledger`
  - `created_by` موجود
  - تفاصيل الصنف الإدارية تشمل `unit_price`

#### LIST employee data leakage
بعد التصحيح:
- `created_by = null`
- `completed_by = null`
- باقي حقول العرض اللازمة للقائمة بقيت موجودة.

### 7. بيانات الاختبار والتنظيف
لم يتم إنشاء سجل إنتاجي جديد غير ضروري.

تم استخدام `IN-7` لأنه يمثل بالفعل حالة Receiver/Pending حقيقية في Production ومتصلة بسلسلة العمليات:
- create audit event
- send audit event
- receive audit event

وله أيضًا حركة مخزنية مرتبطة.
لذلك تم **عدم حذف أو تعديل هذا السجل بطريقة تتجاوز حواجز التكامل**. حذف سجل Received ذي حركة مخزنية لمجرد تنظيفه كان سيحوّل الاختبار إلى تدخل في أثر تشغيلي.

الحالة الحالية للـManual vouchers:
- Completed = 5
- Received = 1
- لا يوجد Draft جديد أُنشئ بواسطة هذه الجلسة.

### 8. التعديل الجراحي المطلوب من المستخدم
**الملف الوحيد المطلوب تعديله يدويًا:**
`companies/company-1/warehouse/vouchers.html`

**لا تلمس:** `main.html`
**لا تلمس:** `van-sales.html`
**لا تعدّل:** `printVoucher()`

---

## PATCH 1 — إصلاح قائمة «معلقة/مكتملة» وربطها بالمحرك المركزي

### ابحث عن:
الدالة:
`loadList:function(scope)`

العنصر الحالي المحدد:
~~~js
loadList:function(scope){var s=this;RW_UI.showSkeleton('mainContent',3,'card');var q=supabase.from('stock_vouchers').select('*').eq('company_id',s.company).eq('source','Manual').order('voucher_date',{ascending:false}).order('created_at',{ascending:false}).limit(1000);q=scope==='pending'?q.in('status',['Draft','Sent','Received']):q.in('status',['Completed','Cancelled']);q.then(function(r){if(r.error)throw r.error;s.vouchers=r.data||[];s.markSync();s.renderList(scope)}).catch(function(e){RW_UI.showError(e.message||'فشل تحميل الأذونات')})},
~~~

### احذفه بالكامل.

### واستبدله بالكامل بـ:
~~~js
loadList:function(scope){
    var s=this;

    RW_UI.showSkeleton(
        'mainContent',
        3,
        'card'
    );

    var workflowScope=
        scope==='pending'
            ?'pending'
            :'completed';

    supabase.rpc(
        'inventory_voucher_report',
        {
            p_operation:'LIST',
            p_payload:{
                source:'Manual',
                workflow_scope:workflowScope,
                limit:1000,
                offset:0
            }
        }
    ).then(function(r){

        if(r.error){
            throw r.error;
        }

        var data=r.data||{};

        s.vouchers=
            Array.isArray(data.rows)
                ?data.rows
                :[];

        s.markSync();
        s.renderList(scope);

    }).catch(function(e){

        RW_UI.showError(
            e.message||
            'فشل تحميل الأذونات'
        );

    });
},
~~~

**سبب التعديل:** منع القراءة المباشرة لكل `stock_vouchers` ونقل scope إلى الـcentral read model الموجود.

---

## PATCH 2 — منع طلب Stock Context في مودال الموظف

### داخل:
`details:function(code)`

### ابحث عن هذا العنصر فقط:
~~~js
supabase.rpc(
    'inventory_voucher_stock_context',
    {
        p_voucher_code:code
    }
)
~~~

### احذفه بالكامل.

### واستبدله بالكامل بـ:
~~~js
Promise.resolve({
    data:{
        movements:[]
    }
})
~~~

لا تحذف `Promise.all(...)` ولا تغيّر بقية `details()`.

**سبب التعديل:** `inventory_voucher_stock_context` أصبح مسارًا إداريًا، والمودال التشغيلي لا يحتاجه بعد إخفاء الحركات والرصيد قبل/بعد.

---

## PATCH 3 — استبدال عنصر رسم المودال فقط

### داخل:
`details:function(code)`

### ابحث عن بداية العنصر:
~~~js
var h=
~~~

ثم حدده بالكامل حتى الـ`;` الذي يسبق:
~~~js
Swal.fire({
~~~

### احذف هذا العنصر بالكامل واستبدله بـ:
~~~js
var h=
    topActions+
    '<div class="grid grid-cols-2 gap-2 text-xs mb-3">'+
        '<div class="p-3 bg-slate-50 rounded-2xl">رقم الإذن<br><b>'+s.esc(v.voucher_code||code)+'</b></div>'+
        '<div class="p-3 bg-slate-50 rounded-2xl">التاريخ<br><b>'+s.esc(v.voucher_date||'—')+'</b></div>'+
        '<div class="p-3 bg-slate-50 rounded-2xl">النوع<br><b>'+s.esc(v.type||'—')+'</b></div>'+
        '<div class="p-3 bg-slate-50 rounded-2xl">الحالة<br><b>'+s.esc(v.status||'—')+'</b></div>'+
        '<div class="p-3 bg-slate-50 rounded-2xl">المصدر<br><b>'+s.esc(s.loc(v.from_id,v.from_type))+'</b></div>'+
        '<div class="p-3 bg-slate-50 rounded-2xl">الوجهة<br><b>'+s.esc(s.loc(v.to_id,v.to_type))+'</b></div>'+
        (
            v.type==='DirectSale'||v.type==='DirectReturn'
                ?
                '<div class="p-3 bg-amber-50 border border-amber-100 rounded-2xl">العهدة<br><b>'+s.esc(custodianText)+'</b></div>'+
                '<div class="p-3 bg-slate-50 rounded-2xl">المركبة<br><b>'+s.esc(vehicleText)+'</b></div>'
                :
                ''
        )+
        '<div class="p-3 bg-slate-50 rounded-2xl">المرجع<br><b>'+s.esc(v.reference||'—')+'</b></div>'+
        '<div class="p-3 bg-slate-50 rounded-2xl">ملاحظات<br><b>'+s.esc(v.notes||'—')+'</b></div>'+
    '</div>'+

    '<div class="border rounded-2xl overflow-auto">'+
        '<table class="w-full text-sm">'+
            '<thead class="bg-slate-100">'+
                '<tr>'+
                    '<th class="p-3">كود الصنف</th>'+
                    '<th class="p-3">الصنف</th>'+
                    '<th class="p-3">الوحدة</th>'+
                    '<th class="p-3">الكمية</th>'+
                    '<th class="p-3">المستلم</th>'+
                    '<th class="p-3">المتبقي</th>'+
                '</tr>'+
            '</thead>'+
            '<tbody>'+
                d.map(function(x){
                    return(
                        '<tr class="border-t">'+
                            '<td class="p-3">'+s.esc(x.item_code||'—')+'</td>'+
                            '<td class="p-3">'+s.esc(x.item_name||x.item_code||'—')+'</td>'+
                            '<td class="p-3 text-center">'+s.esc(x.unit||'—')+'</td>'+
                            '<td class="p-3 text-center">'+f(x.qty)+'</td>'+
                            '<td class="p-3 text-center">'+f(x.received_qty)+'</td>'+
                            '<td class="p-3 text-center">'+
                                f(
                                    x.remaining_qty!==undefined&&x.remaining_qty!==null
                                        ?x.remaining_qty
                                        :Math.max(
                                            0,
                                            Number(x.qty||0)-
                                            Number(x.received_qty||0)
                                        )
                                )+
                            '</td>'+
                        '</tr>'
                    );
                }).join('')+
            '</tbody>'+
        '</table>'+
    '</div>';
~~~

**نتيجة العنصر:** Header + Item Table فقط.

لا يحتوي على:
- KPI
- الحركات الفعلية
- الرصيد قبل/بعد
- المحاسبة
- دفاتر المندوب/المورد
- Audit
- منشئ الإذن
- منفذ الإكمال
- تفاصيل الزمن الإدارية

### 9. Preflight للمصدر
تم تطبيق الترقيعات الثلاثة في الذاكرة فقط على نسخة `vouchers.html` الحالية:
- JS syntax = PASS
- loadList يستخدم `inventory_voucher_report` = PASS
- استدعاء `inventory_voucher_stock_context` أزيل من `details()` = PASS
- المودال لا يحتوي movement section = PASS
- المودال لا يحتوي financial section = PASS
- المودال لا يحتوي audit section = PASS
- المودال لا يحتوي created_by/completed_by/KPI = PASS

لم يتم كتابة أي تغيير إلى مستودع `erp-frontend`.

### 10. E2E / Deployment Evidence
يوجد Workflow:
`.github/workflows/warehouse_vouchers_browser_e2e_20260920.yml`

لكن بوابة المصدر فيه تستخدم:
`s.indexOf('<body>', ...)`
بينما الملف الحالي يبدأ بـ:
`<body class="...">`

لذلك فشل سابقًا قبل تشغيل Browser Smoke.
لا يوجد Tool متاح هنا لـworkflow dispatch.

الحالة:
- Production contract E2E = PASS
- Source patch preflight = PASS
- Auth scope tests = PASS
- Browser E2E على المتصفح = OPEN
- Published artifact verification = OPEN

لا يجوز تسجيل Browser E2E PASS قبل تطبيق التعديلات ونشرها واختبار الـserved artifact نفسه.

### 11. تاريخ التبويب ودوره المعماري
الأذونات المخزنية في RAWAEA ليست بديلًا عن دورة Order → Runsheet → Picking → Loading → Delivery.
هي تغطي العمليات المخزنية غير المرتبطة بالأوردرات/الرانشيتات:
- Transfer
- Direct Sale / Mobile Stock
- Direct Return
- Supplier Return
- Adjustment / Scrap

التطبيق المنفصل هو operational surface.
النظام الأم هو control plane:
- master data
- branches
- users/roles
- permissions
- centralized reporting/control
- audit
- financial supervision

ولا تزال `van-sales.html` مالكة لمسار البيع الميداني المباشر، بينما الأذونات المخزنية تظل حاملة للوثيقة/الحركة المخزنية المرتبطة بها، بدون نسخ منطق van-sales.

### 12. المقارنة التنافسية
المتطلبات الأساسية التي أصبحت واضحة في التطبيق تتوافق مع النمط الموجود في الأنظمة المرجعية:
- Odoo: الحركات الداخلية ترتبط بالمصدر والوجهة والكمية والحالة.
- Microsoft Dynamics: Transfer Orders تبنى على From/To warehouse مع مراحل الشحن والاستلام.
- SAP: تحويلات Storage Location تميز بين موقع الإصدار والاستلام ويمكن تنفيذها كمرحلة واحدة أو مرحلتين.
- دفترة: Transfer Stock يعرض المصدر والوجهة والكمية والأرصدة قبل/بعد.
- Manager: Inventory Transfers تسجل نقل المخزون بين locations بدل اعتبارها بيعًا أو شراءً.

مصادر المقارنة الحالية: وثائق Odoo 19 Inventory، Microsoft Dynamics 365 Supply Chain، SAP Help، دفترة Knowledge Base، وManager Guides.

### 13. فجوات تنافسية مؤجلة — لا تدخل في هذا الإصلاح
هذه ليست أعطالًا حالية، ولا تُبنى تلقائيًا في هذه الجلسة:
- Attachment/evidence لكل إذن.
- سبب الحركة كـbusiness reason موحد.
- batch/serial/expiry عند الأصناف التي تتطلب tracking.
- expected receipt date.
- variance/discrepancy عند الاستلام الجزئي.
- barcode-first receiving/counting.
- dedicated administrative voucher analytics في النظام الأم.

هذه تحسينات Business Contracts مستقلة، ولا يجوز إضافتها داخل patch صغير بلا عقد وظيفي ثابت.

### 14. الحالة عند الإغلاق
#### CLOSED
- Branch-aware Pending/Completed read contract.
- Employee modal redaction contract.
- Employee direct stock-context bypass.
- Owner/admin full-details preservation.
- No new Edge Function.
- No new RPC.
- No change to `main.html`.
- No change to `van-sales.html`.
- No rework of fixed `codeJs`.

#### OPEN
1. تطبيق PATCH 1–3 يدويًا على `vouchers.html`.
2. إعادة syntax/source gate.
3. نشر الـfrontend.
4. التحقق من served artifact identity.
5. Browser E2E بحساب BR-2 وبحساب Owner.
6. Pending → open modal → Print.
7. Completed → branch-only.
8. إعادة اختبار الإخفاء من Browser network/UI.
9. تثبيت closure النهائي في CURRENT_STATE بعد نجاح Browser E2E.

### 15. تعليمات الاستمرار للمساعد التالي
ابدأ دائمًا من:
CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT EVIDENCE

ثم:
1. افحص `vouchers.html` الحالي؛ لا تفترض أن patch ما زال مطلوبًا.
2. تحقق من SHA/HEAD قبل أي تعديل.
3. لا تعيد `codeJs`؛ هو CLOSED في `cd125...`.
4. لا تعدّل `main.html`.
5. لا تنشئ Edge Function جديدة.
6. لا تنشئ RPC جديدة ما دام `inventory_voucher_report` و`inventory_control` يغطيان العقد.
7. لا تحذف سجلًا له أثر مخزني/محاسبي لتجميل QA.
8. لا تعتبر Production RPC PASS بديلًا عن Browser E2E.
9. عند التعديل على Frontend أعطِ المستخدم: الملف + الدالة + anchor الفريد + العنصر الكامل + البديل الكامل.
10. بعد نجاح Browser E2E فقط سجّل الإغلاق النهائي.

### 16. أثر تغييرات Production
التعديلات الإنتاجية تم تنفيذها مباشرة عبر migrations على الدوال القائمة:
- `20260928_vouchers_branch_scope_and_employee_modal_redaction`
- `20260928_fix_voucher_workflow_scope_admin_status_filter`
- `20260928_fix_voucher_scope_privilege_boundary`
- `20260928_sanitize_voucher_list_personnel_fields`
- `20260928_fix_voucher_list_personnel_redaction_exact`

محاولة migration واحدة إضافية خاصة بإعادة بناء `inventory_control` فشلت في compilation بسبب mismatched parentheses ولم تُطبّق؛ لم تُسجل كإغلاق ولم تعتمد كحالة إنتاجية.

### 17. المبدأ النهائي
القائمة لا تكون جزيرة.
المودال لا يكون جزيرة.
التطبيق التنفيذي لا يقرر النطاق من نفسه.
النظام الأم يملك السلطة، والـRPC المركزي يملك read contract، والعمليات القائمة تظل صاحبة الكتابة الذرية، والتطبيق الميداني يعرض فقط ما يخص دوره ومسؤوليته.
