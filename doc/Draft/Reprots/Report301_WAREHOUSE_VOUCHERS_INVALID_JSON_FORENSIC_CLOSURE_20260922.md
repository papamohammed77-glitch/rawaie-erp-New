# تقرير 301 — التحقيق الجنائي وإغلاق خطأ inventory_control في تطبيق الأذونات المخزنية
**التاريخ:** 2026-09-22  
**الهدف:** إغلاق خطأ `invalid input syntax for type json` في تطبيق الأذونات المخزنية مع المحافظة على البنية الحالية وعدم إعادة إصلاح ما ثبت إصلاحه.

---

## 1. قاعدة الحقيقة المعتمدة

تمت إعادة بناء الحالة من المصادر الحالية، لا من التقارير القديمة وحدها:

- System repository: `papamohammed77-glitch/rawaie-erp-New`
- Current system HEAD قبل هذا التقرير: `764015555783a00a5bb7d786974fe5e564ea96e8`
- Parent: `a16434e447f4b48e6bd7cdc0e34f3f496650db50`
- Frontend repository: `papamohammed77-glitch/erp-frontend`
- Current frontend HEAD: `6715825ec05e62482a4e37335ab366f5512805cf`
- Frontend parent: `745a615ccd0baff09ad2619b0316e46507a862e9`
- Current vouchers source blob: `b23a7a8f605ff6151fd87b021de1e1d593672a57`
- Current Mother main blob inspected directly: `8c3d6b05fd6a94a6b488f12b29da85ae888f70bc`

التقارير السابقة استُخدمت لفهم التاريخ فقط. تقرير 300 أثبت أن إصلاح Vehicle Picker سبق هذه المهمة وأن `newWorkspace()` هو الجزء المعتمد حاليًا، ولذلك لم تتم إعادة لمسه.

---

## 2. العناصر التي تمت مراجعتها قبل التنفيذ

تمت مراجعة:

1. `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
2. `CURRENT_STATE.md`
3. آخر تقرير تنفيذي مرتبط بالمخزون والتحقق التاريخي.
4. آخر commits وparent للمستودع الأم.
5. المصدر الحالي الكامل لتطبيق:
   `companies/company-1/warehouse/vouchers.html`
6. المصدر الحالي لـ:
   `companies/company-1/main.html`
7. المصدر الحالي لـ:
   `companies/company-1/sales/van-sales.html`
8. Production PostgreSQL: RPCs, grants, schema, constraints, triggers, audit path.
9. Production Edge Functions الحالية المرتبطة بالأذونات والحركات.
10. Production migration history حتى `20260922081156`.

---

## 3. بنية تطبيق الأذونات ودوره

التطبيق الحالي ليس تطبيق طلبات أوردرات أو رانشيتات. دوره هو إدارة **العمليات المخزنية المستقلة** غير المرتبطة مباشرة برحلة Order/Runsheet.

الأنواع الحالية المثبتة في المصدر:

- Transfer — فرع → فرع
- DirectSale — فرع → مركبة
- DirectReturn — مركبة → فرع
- SupplierReturn — فرع → مورد
- Scrap — عبر Adjustment Engine
- Adjustment — عبر Adjustment Engine

التطبيق يربط:

`Voucher`
→ `stock_voucher_details`
→ `stock_voucher_operations`
→ capability / RPC
→ `post_stock_movement`
→ `stock_branches` + `inventory_log`

ولا يوجد Writer موازٍ للمخزون داخل المسار الحالي المعتمد.

---

## 4. التكامل مع النظام الأم

تم فحص المصدر الحالي للنظام الأم مباشرة.

النظام الأم يحتوي على:

`إدارة المخازن والمخزون`
→ `مركز التحكم في المخزون`
→ `العمليات المخزنية`
→ `الأذونات المخزنية`
→ `الجرد`

والـMother لديه بالفعل:

`loadInventoryControl()`

وتحتوي قائمة إدارة المخازن على:

- مركز التحكم في المخزون.
- العمليات المخزنية: Receiving / Picking / Loading / Delivery / Return / Unloading.
- الأذونات المخزنية: تحويل / صرف سيارة / استلام مرتجع سيارة / مرتجع مورد / عرض الأذونات.
- الجرد.

**لم يتم تعديل main.html.**

---

## 5. التكامل مع Van Sales

تم فحص `van-sales.html` الحالي.

التدفق المثبت:

`setup-van-branch`
→ يحدد مخزن/فرع السيارة
→ يحفظ `branch_id / vehicle_id / vehicle_code / driver_id`
→ Van Sales ينشئ الفاتورة
→ `save-sales-invoice`
→ `save_sales_invoice_atomic`
→ الحركة الفيزيائية تمر عبر `post_stock_movement`

إذن:

**DirectSale Voucher**
ينقل العهدة من الفرع إلى مخزن المركبة.

ثم:

**Van Sales Invoice**
يستهلك مخزون المركبة عن طريق نفس Physical Stock Engine.

وهذا يحافظ على التكامل بدلاً من جعل الأذونات وVan Sales جزيرتين منفصلتين.

---

# 6. المشكلة الأصلية كما ظهرت في Production

رسالة المتصفح:

`invalid input syntax for type json`

والشبكة:

`POST /rest/v1/rpc/inventory_control 400`

ومن Console ظهر أن الاستدعاء خرج من:

`vouchers.html` → `details()`

لكن التحقيق أثبت أن الخطأ **ليس في payload الخاص بالتطبيق**.

الاستدعاء الحالي في التطبيق هو:

```js
supabase.rpc(
    'inventory_control',
    {
        p_operation:'VOUCHER_AUDIT',
        p_payload:{
            voucher_code:code
        }
    }
)
```

وهذا JSON صحيح.

---

# 7. ROOT CAUSE — السبب الجذري المثبت

تم تنفيذ نفس استدعاء Production تحت Auth context حقيقي للمستخدم:

`vouchers@rawaea.com`

قبل الإصلاح كانت PostgreSQL ترجع:

`22P02 invalid input syntax for type json`

وكان الخطأ داخل:

`inventory_control(text,jsonb)`

وتحديدًا في حارس الصلاحيات:

```sql
v_privileged :=
  coalesce(v_actor.permissions,'[]'::jsonb)
  @> '[\\\"*\\\"]'::jsonb
```

وهذه صياغة JSON malformed بسبب escaping زائد داخل تعريف الدالة المنشورة.

إذن:

`details()`
لم يكن يرسل JSON خاطئًا.

بل:

`inventory_control()`
كان يكسر JSON داخليًا **قبل تنفيذ VOUCHER_AUDIT**.

وهذا هو سبب ظهور:

`invalid input syntax for type json`

---

# 8. لماذا تحذير Tailwind ليس السبب

ظهر أيضًا:

`cdn.tailwindcss.com should not be used in production`

هذا تحذير Build/Performance.

لا علاقة له بالـ`22P02`.

لم تتم معالجته ضمن هذه المهمة حتى لا نفتح تغييرًا غير متعلق بالأزمة.

---

# 9. لماذا Service Worker 404 ليس سبب الأزمة

ظهر:

`/companies/company-1/warehouse/sw.js → 404`

وهذا يعطل تسجيل Service Worker لهذا المسار فقط.

لكنه لا يسبب خطأ PostgreSQL:

`invalid input syntax for type json`

وبالتالي تم فصل المشكلتين بدل دمجهما عشوائيًا.

---

# 10. الإصلاح الفعلي في Production

تم تنفيذ migration حقيقي في Production:

`20260922081156_fix_inventory_control_json_permission_literals_20260922`

الإصلاح الجراحي:

بدلاً من JSON text literals التي كانت قابلة للكسر:

```sql
@> '[\\\"*\\\"]'::jsonb
```

تم استخدام منشئ JSON أصلي من PostgreSQL:

```sql
@> jsonb_build_array('*')
```

وبالمثل:

```sql
jsonb_build_array('reports')
jsonb_build_array('warehouse')
jsonb_build_array('warehouse_manager')
jsonb_build_array('warehouse_supervisor')
jsonb_build_array('transfer')
```

وبذلك لم يعد الحارس يعتمد على escaping داخل literal نصي.

تم الحفاظ على:

- `auth.uid()`
- استخراج `users.auth_id`
- `users.company_id`
- Owner wildcard semantics
- warehouse/report permissions
- `SNAPSHOT`
- `MOVEMENTS`
- `REPLENISHMENT`
- `COUNT`
- `REQUEST`
- `VOUCHER_AUDIT`
- grants الحالية

ولم يتم إنشاء Edge Function جديدة.

---

# 11. لماذا لم نعدل vouchers.html

بعد الإصلاح، تمت إعادة فحص:

`details:function(code)`

وتم إثبات أنها تستخدم RPC الصحيح بالصيغة الصحيحة.

**لا يوجد سبب هندسي لتعديلها الآن.**

لذلك:

- لا تحذف الدالة.
- لا تستبدلها.
- لا تضف `JSON.stringify`.
- لا تغير `p_payload`.
- لا تعيد إصلاح `newWorkspace()`.

التعديل الحقيقي المطلوب للأزمة تم في Production RPC.

## الدالة الكاملة المعتمدة حاليًا للتدقيق

المقطع التالي هو نفس الدالة الموجودة في Current Source بعد الإصلاح، وليس مطلوبًا استبدالها:

```javascript
details:function(code){
    var s=this;

    RW_UI.showLoader();

    supabase
        .rpc(
            'inventory_control',
            {
                p_operation:'VOUCHER_AUDIT',
                p_payload:{
                    voucher_code:code
                }
            }
        )
        .then(function(r){

            RW_UI.hideLoader();

            if(r.error){
                throw new Error(
                    r.error.message||
                    'تعذر قراءة بيانات الإذن'
                );
            }

            var data=r.data||{};
            var v=data.voucher;

            var custodianText='—';
            var vehicleText='—';

            if(
                v &&
                (v.type==='DirectSale'||v.type==='DirectReturn')
            ){
                if(v.custodian_user_id){
                    var rep=(s.refs.reps||[]).find(function(r){
                        return r.id===v.custodian_user_id;
                    });

                    if(rep){
                        custodianText=rep.name||rep.email||'—';
                    }
                }

                vehicleText=
                    v.type==='DirectSale'
                        ?s.loc(v.to_id,'Vehicle')
                        :s.loc(v.from_id,'Vehicle');
            }

            if(!v){
                throw new Error('الإذن غير موجود');
            }

            var d=Array.isArray(data.details)
                ?data.details
                :[];

            var aud=Array.isArray(data.audit)
                ?data.audit
                :[];

            var movements=Array.isArray(data.movements)
                ?data.movements
                :[];

            var aH=aud.length
                ?aud.map(function(x){
                    var op=x.operation_id
                        ?'<br>Operation: '+s.esc(x.operation_id)
                        :'';

                    return(
                        '<div class="text-xs border-b py-2">'+
                        '<b>'+s.esc(x.action||'')+'</b>'+
                        ' · '+
                        s.esc(x.user_email||'system')+
                        '<span class="text-slate-400">'+
                        ' · '+
                        s.esc(x.created_at||'')+
                        '</span>'+
                        op+
                        '</div>'
                    );
                }).join('')
                :
                '<div class="text-xs text-slate-400">لا توجد سجلات تدقيق متاحة لهذه الوثيقة</div>';

            var movementH=movements.length
                ?movements.map(function(x){

                    var from=x.source_branch_id
                        ?s.loc(x.source_branch_id,'Branch')
                        :'—';

                    var to=x.target_branch_id
                        ?s.loc(x.target_branch_id,'Branch')
                        :'—';

                    return(
                        '<tr class="border-t">'+
                        '<td class="p-2 text-xs">'+
                        s.esc(x.item_name||x.item_code||'')+
                        '<div class="text-[10px] text-slate-400">'+
                        s.esc(x.item_code||'')+
                        '</div>'+
                        '</td>'+
                        '<td class="p-2 text-center text-xs">'+
                        s.esc(x.movement_type||'')+
                        '</td>'+
                        '<td class="p-2 text-center">'+
                        f(x.qty)+
                        '</td>'+
                        '<td class="p-2 text-xs">'+
                        s.esc(from)+
                        ' → '+
                        s.esc(to)+
                        '</td>'+
                        '<td class="p-2 text-xs">'+
                        s.esc(x.user_email||'system')+
                        '</td>'+
                        '</tr>'
                    );
                }).join('')
                :
                '<tr><td colspan="5" class="p-4 text-center text-slate-400">لا توجد حركة فعلية مسجلة لهذا الإذن حتى الآن</td></tr>';

            var h=
                '<div class="text-right">'+

                '<div class="grid grid-cols-2 gap-2 text-xs mb-3">'+
                '<div class="p-3 bg-slate-50 rounded-2xl">النوع<br><b>'+s.esc(v.type)+'</b></div>'+
                '<div class="p-3 bg-slate-50 rounded-2xl">الحالة<br><b>'+s.esc(v.status)+'</b></div>'+
                '<div class="p-3 bg-slate-50 rounded-2xl">المصدر<br><b>'+s.esc(s.loc(v.from_id,v.from_type))+'</b></div>'+
                '<div class="p-3 bg-slate-50 rounded-2xl">الوجهة<br><b>'+s.esc(s.loc(v.to_id,v.to_type))+'</b></div>'+
                ((v.type==='DirectSale'||v.type==='DirectReturn')
                    ?
                    '<div class="p-3 bg-amber-50 border border-amber-100 rounded-2xl">المستلم والمسؤول عن العهدة<br><b>'+s.esc(custodianText)+'</b></div>'+
                    '<div class="p-3 bg-slate-50 rounded-2xl">المركبة / وعاء النقل<br><b>'+s.esc(vehicleText)+'</b></div>'
                    :
                    '')+
                '<div class="p-3 bg-slate-50 rounded-2xl">أنشأ بواسطة<br><b>'+s.esc(v.created_by||'—')+'</b></div>'+
                '<div class="p-3 bg-slate-50 rounded-2xl">أكمل بواسطة<br><b>'+s.esc(v.completed_by||'—')+'</b></div>'+
                '</div>'+

                '<div class="mb-3 text-xs text-slate-500">'+
                'المرجع: '+s.esc(v.reference||'—')+
                '<br>المصدر: '+s.esc(v.source||'—')+
                '<br>تاريخ الإنشاء: '+s.esc(v.created_at||'—')+
                '<br>الإرسال: '+s.esc(v.sent_date||'—')+
                '<br>الاستلام: '+s.esc(v.received_date||'—')+
                '<br>الإكمال: '+s.esc(v.completed_at||'—')+
                '<br>ملاحظات: '+s.esc(v.notes||'—')+
                '</div>'+

                '<div class="border rounded-2xl overflow-auto">'+
                '<table class="w-full text-sm">'+
                '<thead class="bg-slate-100">'+
                '<tr>'+
                '<th class="p-3">الصنف</th>'+
                '<th class="p-3">الكمية</th>'+
                '<th class="p-3">المستلم</th>'+
                '<th class="p-3">المتبقي</th>'+
                '</tr>'+
                '</thead>'+
                '<tbody>'+
                d.map(function(x){
                    return(
                        '<tr class="border-t">'+
                        '<td class="p-3">'+
                        s.esc(x.item_name||x.item_code)+
                        '</td>'+
                        '<td class="p-3 text-center">'+
                        f(x.qty)+
                        '</td>'+
                        '<td class="p-3 text-center">'+
                        f(x.received_qty)+
                        '</td>'+
                        '<td class="p-3 text-center">'+
                        f(Math.max(
                            0,
                            Number(x.qty||0)-
                            Number(x.received_qty||0)
                        ))+
                        '</td>'+
                        '</tr>'
                    );
                }).join('')+
                '</tbody>'+
                '</table>'+
                '</div>'+

                '<div class="mt-4 border rounded-2xl overflow-auto">'+
                '<div class="p-3 bg-slate-100 font-black text-sm">الحركات الفعلية المرتبطة</div>'+
                '<table class="w-full text-sm">'+
                '<thead class="bg-slate-50">'+
                '<tr>'+
                '<th class="p-2">الصنف</th>'+
                '<th class="p-2">نوع الحركة</th>'+
                '<th class="p-2">الكمية</th>'+
                '<th class="p-2">المسار</th>'+
                '<th class="p-2">المنفذ</th>'+
                '</tr>'+
                '</thead>'+
                '<tbody>'+
                movementH+
                '</tbody>'+
                '</table>'+
                '</div>'+

                '<details class="mt-4">'+
                '<summary class="cursor-pointer font-black text-sm">سجل التدقيق</summary>'+
                '<div class="mt-2">'+aH+'</div>'+
                '</details>'+

                '</div>';

            Swal.fire({
                title:'تفاصيل الإذن '+s.esc(code),
                html:h,
                width:940,
                showConfirmButton:false,
                showCloseButton:true,
                customClass:{
                    popup:'!rounded-3xl'
                }
            });
        })
        .catch(function(e){
            RW_UI.hideLoader();
            RW_UI.showError(
                e.message||
                'تعذر تحميل تفاصيل الإذن'
            );
        });
}
```

---

# 12. تعديل المصدر الجراحي — النتيجة

## الملف المطلوب تعديله

`papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/vouchers.html`

## نتيجة التحقيق

**لا يوجد تعديل مصدر جديد مطلوب لإغلاق Incident 22P02.**

السبب:

`Current vouchers.html`
→ `details()`
→ payload صحيح
→ RPC correct signature
→ Production RPC كانت هي Root Cause
→ Production RPC تم إصلاحها
→ نفس الاستدعاء نجح بعد الإصلاح

إذن أي تغيير إضافي في `vouchers.html` الآن سيكون إعادة عمل بلا داعٍ.

---

# 13. بيانات QA الجديدة — تم إنشاؤها ولم تُحذف

تم إنشاء بيانات Production تجريبية دائمة عمدًا:

## IN-3

- Type: `DirectSale`
- Status: `Draft`
- Reference: `QA-INVALID-JSON-DETAILS-20260922`
- Source: BR-01
- Destination: VEH-TEST-260921
- Item: 1001
- Qty: 1
- Operation ID: `QA-OP-INVALID-JSON-DETAILS-20260922`

## IN-4

- Type: `DirectReturn`
- Status: `Draft`
- Reference: `QA-DIRECT-RETURN-DETAILS-20260922`
- Source: VEH-TEST-260921
- Destination: BR-01
- Item: 1001
- Qty: 1
- Operation ID: `QA-OP-DIRECT-RETURN-DETAILS-20260922`

هذه البيانات **لم تُحذف**.

ولا توجد حركة مخزنية فعلية مرتبطة بـ`IN-2 / IN-3 / IN-4` حتى لحظة التحقق النهائي.

---

# 14. E2E / Production Verification

## Test A — VOUCHER_AUDIT

تم تشغيل:

`inventory_control('VOUCHER_AUDIT', {'voucher_code':'IN-3'})`

بالـAuth الحقيقي للمستخدم:

`vouchers@rawaea.com`

النتيجة:

`success=true`

وأعيد:

- voucher
- details
- audit
- operations

## Test B — DirectReturn audit

تم تشغيل:

`inventory_control('VOUCHER_AUDIT', {'voucher_code':'IN-4'})`

والنتيجة:

`success=true`

## Test C — CREATE capability

تم تشغيل `create_manual_stock_voucher_atomic` بالـ12 arguments على عملية DirectSale داخل Transaction.

النتيجة:

`success=true`

ثم تم عمل rollback لأن هذا الاختبار كان خاصًا بالتحقق فقط.

## Test D — SEND capability

تم تشغيل `send_stock_voucher_atomic` على `IN-2` داخل Transaction.

النتيجة المثبتة:

`success=true`
`status=Sent`
`movement_count=1`

ثم rollback.

## Test E — Control Snapshot

تم اختبار `inventory_control('SNAPSHOT')` من Owner context في Production، ونجح.

## Test F — Replenishment

تم اختبار `inventory_control('REPLENISHMENT')` من Owner context، ونجح، وأعاد بيانات فعلية من Production.

---

# 15. Production Counts بعد الاختبار

الحالة الحالية المثبتة:

- Total stock vouchers: 4
- QA vouchers: 3
- QA movements: 0
- QA operation registry rows: 3
- QA audit rows: 3

إذن بيانات الاختبار محفوظة، لكن لم يتم تلويث Physical Stock بحركة تجريبية غير مقصودة.

---

# 16. Physical Stock integrity

تم التأكد أن:

```
Physical Stock Movement
        ↓
post_stock_movement
        ↓
stock_branches
+
inventory_log
```

وأن:

`reserve_stock`

محرك Reservation فقط.

ولم يتم إنشاء Physical Writer جديد.

---

# 17. تدفق Audit

Production لديها:

`stock_vouchers`
→ `trg_audit_stock_vouchers`
→ `fn_audit_trigger()`
→ `audit_log`

وتم فحص هذا المسار مباشرة.

كما أن `inventory_control('VOUCHER_AUDIT')` يعيد:

- Audit records
- operation registry
- actual inventory movements
- voucher details

وهذا يحقق دورًا رقابيًا موحدًا أعلى من مجرد شاشة CRUD.

---

# 18. المنافسة العالمية — ما هو مثبت

## Odoo

Odoo 19 يدعم في الجرد:

- تحديد الموقع.
- الصنف.
- Lot/Serial.
- Counted.
- Difference.
- On Hand.
- User.
- Scheduled date.
- Request a Count.
- Barcode counting.
- Count Entire Locations.
- History/Audit.

المصادر الرسمية:

https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/count_products.html

https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

## Microsoft Dynamics 365

Inventory Journals تتضمن:

- Movement
- Inventory Adjustment
- Transfer
- Counting
- Tag Counting
- Item Arrival

والـTransfer يعتمد From/To dimensions.

المصدر الرسمي:

https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

## SAP

Goods Movement يشمل:

- Goods Receipt
- Goods Issue
- Stock Transfer
- Transfer Posting

المصدر الرسمي:

https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/4eb099dbc8a6435c9b36a854a7e05522/1063bd534f22b44ce10000000a174cb4.html

## Daftra

التوثيق الرسمي يثبت:

- Manual Transfer
- From Warehouse
- To Warehouse
- Quantity
- Available Before
- Available After
- Notes
- Detailed Inventory Movement Report
- Product
- Warehouse
- Type
- Opening balance
- Barcode stocktaking
- Stocktaking sheets
- Import from CSV
- Stock permissions

المصادر الرسمية:

https://docs.daftra.com/en/tutorial/transferring-stock/

https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

https://docs.daftra.com/en/tutorial/importing-stocktaking-sheet/

## Manager.io

يدعم Inventory Locations، واستخدام Location في حركات الشراء والبيع، ونقل المخزون بين المواقع.

المصدر الرسمي:

https://www2.manager.io/guides/10677

---

# 19. الفجوات التنافسية الحقيقية التي تستحق التطوير لاحقًا

هذه ليست إصلاحات Incident 22P02، ولذلك لم تُنفذ بدون دليل مباشر.

الأولوية الوظيفية المستقبلية للتطبيق يمكن أن تكون:

1. Available Before / Available After لكل سطر في Workspace.
2. Reason Code منظم بدل Notes فقط.
3. Attachment / document evidence.
4. Effective Date + Effective Time.
5. Assignment / approval / reviewer.
6. External Reference.
7. Bulk CSV / Excel import.
8. Print/export document variants.
9. Lot / Serial / Expiry عندما يدخل ذلك في Master Data.
10. فرق الطلب/الإذن عن الحركة المنفذة في التقارير.
11. نافذة Timeline موحدة للإذن.
12. ربط أعمق مع Control Center لإظهار أثر الإذن على العهدة والمخزون والحسابات.

ولا ينبغي نسخ Odoo أو SAP حرفيًا؛ المطلوب هو استثمار مزايا RAWAEA الحالية:

`Voucher → Mobile Stock → Van Sales → Order → Fulfillment → Return → Settlement`

مع الإبقاء على العمليات الميدانية المنفصلة.

---

# 20. ملاحظة Business Contract مفتوحة ظهرت أثناء الاختبار

أثناء اختبار Control Gateway للمستخدم `vouchers@rawaea.com` ظهر الآتي:

- Gateway يسمح لمسار `MOVEMENTS` بسبب صلاحية warehouse.
- محرك `inventory_movement_report` نفسه يفرض `reports`.

هذه ليست مشكلة في Incident JSON، ولذلك لم يتم تغيير الصلاحيات بشكل تخميني.

الحالة الصحيحة:

**CONTRACT GAP — منفصل**

والقرار الحالي:

عدم توسيع الصلاحيات.

يجب لاحقًا تحديد العقد الرسمي:

- هل MOVEMENTS للـwarehouse؟
- أم للـreports؟
- أم warehouse managers فقط؟

ثم تعديل طبقة واحدة بشكل موثق.

---

# 21. Git Canonical Closure

تمت إضافة migration المطابق لما نُفذ في Production:

`supabase/migrations/20260922081156_fix_inventory_control_json_permission_literals_20260922.sql`

Commit:

`f8ff61d7506ff42038c6a8a0c6ecf61c2233f87d`

وهذا يمنع عودة المشكلة بسبب drift بين Production وGit.

---

# 22. ما لم يتم تغييره

لم يتم تعديل:

- `main.html`
- `vouchers.html`
- `van-sales.html`
- `newWorkspace()`
- `loadRefs()`
- `vehicleBranch()`
- `pickArr()`
- `pickSearch()`
- `pickSelect()`
- `submit()`
- أي Edge Function جديد

كما لم يتم حذف بيانات QA.

---

# 23. الحالة النهائية

```
ROOT CAUSE = PROVEN
PRODUCTION RPC REPAIRED = YES
MALFORMED JSON GUARD = REMOVED
VOUCHER AUDIT = VERIFIED
DIRECTSALE QA = RETAINED
DIRECTRETURN QA = RETAINED
PHYSICAL STOCK SIDE EFFECT FROM QA = 0
NO NEW EDGE FUNCTION = YES
MAIN.HTML TOUCHED = NO
VOUCHERS.HTML TOUCHED = NO
VAN-SALES TOUCHED = NO
CANONICAL GIT MIGRATION = ADDED
PRODUCTION MIGRATION = APPLIED
```

## Incident 22P02

**CLOSED at Production/RPC level.**

## Browser E2E

لم يتم تسجيل Browser automation حقيقي من داخل Chrome في هذه الجلسة؛ لذلك لا يتم الادعاء بأن Browser/Console/Network closure النهائي = 100%.

الـDB/RPC runtime evidence للخطأ نفسه أصبحت PASS.

---

# 24. تعليمات للمساعد/CTO التالي

ابدأ من:

1. Current Git.
2. Current Production.
3. Current frontend source.
4. Migration history.
5. لا تعد فتح Incident 22P02؛ السبب مثبت ومغلق.
6. لا تعد إصلاح Vehicle Picker.
7. افحص Browser runtime فقط لإثبات أن التطبيق المنشور فعليًا يستطيع فتح:
   `details(IN-3)`
8. تحقق أن Console لم يعد يظهر:
   `22P02 invalid input syntax for type json`
9. لا تعدل `details()` إلا إذا ظهر Browser evidence جديد يخالف Production RPC PASS.
10. افتح بعد ذلك عقد `MOVEMENTS` كمسألة مستقلة ولا تخلطها مع Incident 22P02.

قاعدة الحقيقة:

```
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
+
BROWSER EVIDENCE
```

لا ترفع أي Closure إلى 100% بدون آخر عنصر.
