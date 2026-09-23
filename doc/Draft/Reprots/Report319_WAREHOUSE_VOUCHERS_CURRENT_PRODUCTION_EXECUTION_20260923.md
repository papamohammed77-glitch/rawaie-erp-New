# تقرير التنفيذ الجنائي — جلسة 2026-09-23
## RAWAEA ERP — Warehouse Vouchers / Mother ERP / Fleet Alignment

> مصادر الحقيقة في هذه الجلسة: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> التقارير السابقة استُخدمت كسياق تاريخي فقط، وتمت إعادة مطابقة النقاط الحساسة مع Production وCurrent Source.

---

## 1. نطاق التنفيذ

تم استئناف المهمة من آخر نقطة مثبتة في Report318 دون إعادة بناء ما ثبت إغلاقه.

تمت مراجعة:
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP
- CURRENT_STATE.md
- آخر commits وParent في المستودع الأم ومستودع الواجهة.
- Report318 والتقارير التنفيذية المرتبطة.
- Current vouchers.html
- Current main.html
- Current van-sales.html
- PostgreSQL Production.
- Edge Functions وRPCs الحالية.
- بيانات الاختبار وآثارها في audit_log.
- دورة DirectSale وعلاقة Vehicle / Representative / Mobile Branch.

لم تتم الكتابة إلى:
- erp-frontend/companies/company-1/main.html
- erp-frontend/companies/company-1/warehouse/vouchers.html
- erp-frontend/companies/company-1/sales/van-sales.html

---

## 2. الحالة الحالية المثبتة

### System Git
- HEAD بعد إضافة Migration الإغلاق: fd64fd443acd238fdf80f395adb7c325e84a7d15
- Report318: 07437dbb96a9becfdac50ea590430d65be2ca7d9

### Frontend Git
- HEAD: c2ac6d33cb5c20ba6539f61cabde1b33866ecb46
- Parent: 5cf09bac46aa65fa1e94ba34dfbdc3760cd446e2
- vouchers.html: 1bbca38299ff093798badaaafda6a2b986583527
- main.html: 8c3d6b05fd6a94a6b488f12b29da85ae888f70bc
- van-sales.html: 8d61382a8e0025a0d079e71dd94f33d106d9088e

---

## 3. Production Snapshot بعد التنفيذ

التقاط Production النهائي:
2026-09-23 13:50:39.591176+00 UTC

| المؤشر | القيمة |
|---|---:|
| Companies | 1 |
| Active Branches | 3 |
| Active Vehicles | 2 |
| Active Direct Sales Reps | 2 |
| Active Voucher Users | 1 |
| Items | 16 |
| Stock Branch Rows | 48 |
| Inventory Log | 6 |
| Audit Log | 2141 |
| Stock Vouchers | 0 |
| Draft Vouchers | 0 |
| Explicit TEST Vehicles | 1 |

تم حذف المسودة الحالية IN-1 بعد إثبات:
- reference = N-Test-01
- الحالة Draft
- لا توجد لها حركة Physical في inventory_log.

لم يتم حذف المركبات لأن إحدى المركبات غير موسومة صراحة بأنها TEST، ولا يوجد دليل كافٍ يسمح باعتبارها بيانات تجريبية قابلة للحذف.

---

# 4. Manual Voucher — النتيجة الإنتاجية

## 4.1 Physical Stock Contract

العقد الحالي:
PHYSICAL STOCK MOVEMENT
→ post_stock_movement
→ stock_branches + inventory_log

ولا يوجد Physical Writer مستقل مثبت خارج post_stock_movement.

reserve_stock / release_stock_reservation ما زالت Reservation-only.

لا يوجد إنشاء Edge Function جديدة.

---

## 4.2 CREATE / UPDATE / DELETE

الـEdge Function الحالية create-stock-voucher هي capability موجودة بالفعل.

Production version الحالية:
12

وتدعم:
- CREATE
- UPDATE-DRAFT
- DELETE-DRAFT

ولا توجد حاجة إلى Edge Function جديدة.

---

# 5. DirectSale — التحقيق الحاسم

## العقد الفعلي

DirectSale يتطلب:
- مصدر Branch صالح.
- وجهة Vehicle.
- Vehicle Active.
- mobile_stock_enabled = true.
- Vehicle مرتبطة بمندوب بيع مباشر.
- Representative صالح.
- Representative مسموح له بالمصدر.

هذا العقد مطبق داخل Production Core وليس UI فقط.

## الدليل الإنتاجي

المركبات الحالية في Production:

### CHV-2025-01
- Active
- mobile stock enabled
- driver_id = NULL
- route = Any
- operational condition = Good
- expected km/l = 11

### FRD-2025-02 TEST
- Active
- mobile stock enabled
- driver_id = NULL
- route = Any
- operational condition = Good
- expected km/l = 13

وبالتالي لا توجد حاليًا مركبة مؤهلة لـDirectSale picker للمندوبين، لأن الـCore يشترط vehicle.driver_id = representative.id.

هذه ليست مشكلة في pickSelect() أو Contract الـVehicle picker.

---

# 6. DirectSale E2E — Production Transactional Test

تم تنفيذ اختبار حقيقي على Production داخل Transaction واحدة مع Rollback.

### السيناريو
- Creator: vouchers@rawaea.com
- Representative: 111b0730-a977-4d11-bcd0-2427b178a9e5
- Vehicle: 69b08188-60ee-43af-9644-e1626a85bfa0
- Branch: BR-01
- Item: 1001

تم مؤقتًا ربط المركبة بالمندوب داخل الـTransaction.

### النتائج

| المرحلة | النتيجة |
|---|---|
| CREATE | PASS |
| SEND | PASS |
| COMPLETE | PASS |
| Physical stock delta | PASS |
| Movement log count | 1 |
| Custodian | Representative |
| Rollback | PASS |

الرصيد:
2 → 1 بعد الإرسال ثم عاد Production إلى حالته السابقة بعد Rollback.

الـSEND أعاد:
- custodian_user_id = representative
- custody_value = 50
- custody_ledger = true

وهذا يثبت أن Vehicle لا تُعامل كمالك للبضاعة؛ الحيازة التشغيلية مرتبطة بالمندوب.

---

# 7. Draft Printing — العيب الحقيقي

## Current Source

في vouchers.html:

App.printVoucher() الحالية تعمل فقط على:
.swal2-html-container

أي أنها تعتمد على وجود نافذة التفاصيل مفتوحة أصلًا.

وفي App.cards(rows,scope) عند Draft يوجد:
- Send
- Cancel

ولا يوجد:
- Print Draft
- Edit
- Delete

Report318 سبق أن أثبت الحاجة إلى:
- Edit
- Delete
- improved Draft lifecycle

وهذه patches ما زالت Owner-side pending.

## الإصلاح الجديد في هذه الجلسة

لا نعدل App.printVoucher() الحالية.

### PATCH 319-01 — App.printDraftVoucher

الملف:
companies/company-1/warehouse/vouchers.html

مكان الإدراج:
داخل كائن App مباشرة قبل:
printVoucher:function(){

ابحث عن:
printVoucher:function(){

ولا تحذفه.

أدرج قبله مباشرة:

```javascript
printDraftVoucher:function(code){
    var s=this,
        w=window.open(
            '',
            '_blank',
            'width=1200,height=900'
        );

    if(!w){
        RW_UI.toast(
            'تعذر فتح نافذة الطباعة',
            'error'
        );
        return;
    }

    RW_UI.showLoader(
        'جاري تجهيز المسودة للطباعة...'
    );

    supabase
        .from('stock_vouchers')
        .select(
            'id,voucher_code,voucher_date,type,status,'+
            'reference,from_type,from_id,to_type,to_id,'+
            'notes,created_by,created_at'
        )
        .eq('company_id',s.company)
        .eq('voucher_code',code)
        .maybeSingle()
        .then(function(r){

            if(r.error){
                throw r.error;
            }

            if(!r.data){
                throw new Error(
                    'الإذن غير موجود'
                );
            }

            if(r.data.status!=='Draft'){
                throw new Error(
                    'المستند لم يعد مسودة'
                );
            }

            var v=r.data;

            return supabase
                .from(
                    'stock_voucher_details'
                )
                .select(
                    'item_code,item_name,unit,qty,'+
                    'unit_price,notes'
                )
                .eq(
                    'voucher_id',
                    v.id
                )
                .order(
                    'created_at',
                    {ascending:true}
                )
                .order(
                    'id',
                    {ascending:true}
                )
                .then(function(d){

                    if(d.error){
                        throw d.error;
                    }

                    return{
                        v:v,
                        details:d.data||[]
                    };
                });
        })
        .then(function(x){

            var v=x.v,
                rows=x.details,
                esc=s.esc,
                from=s.loc(
                    v.from_id,
                    v.from_type
                ),
                to=s.loc(
                    v.to_id,
                    v.to_type
                );

            var lines=
                rows.map(
                    function(d){

                        return(
                            '<tr>'+
                                '<td>'+
                                    esc(
                                        d.item_code||''
                                    )+
                                '</td>'+
                                '<td>'+
                                    esc(
                                        d.item_name||
                                        d.item_code||
                                        ''
                                    )+
                                '</td>'+
                                '<td>'+
                                    esc(
                                        d.unit||'حبة'
                                    )+
                                '</td>'+
                                '<td>'+
                                    Number(
                                        d.qty||0
                                    )+
                                '</td>'+
                                '<td>'+
                                    Number(
                                        d.unit_price||0
                                    )+
                                '</td>'+
                                '<td>'+
                                    esc(
                                        d.notes||''
                                    )+
                                '</td>'+
                            '</tr>'
                        );
                    }
                ).join('');

            w.document.open();

            w.document.write(
                '<!doctype html>'+
                '<html lang="ar" dir="rtl">'+
                '<head>'+
                    '<meta charset="utf-8">'+
                    '<title>'+
                        'مسودة إذن مخزني '+
                        esc(v.voucher_code)+
                    '</title>'+
                    '<style>'+
                        'body{font-family:Arial,Tahoma,sans-serif;margin:24px;color:#111827}'+
                        'h1{font-size:22px;margin:0 0 8px}'+
                        'h2{font-size:14px;margin:22px 0 8px}'+
                        '.meta{display:grid;grid-template-columns:repeat(2,1fr);gap:8px;margin:14px 0}'+
                        '.box{border:1px solid #cbd5e1;padding:8px;border-radius:8px}'+
                        '.muted{color:#64748b;font-size:11px}'+
                        'table{width:100%;border-collapse:collapse;margin-top:10px}'+
                        'th,td{border:1px solid #cbd5e1;padding:8px;font-size:12px}'+
                        'th{background:#f1f5f9}'+
                        '.draft{padding:8px 12px;border:1px solid #f59e0b;background:#fffbeb;border-radius:8px;font-weight:700}'+
                        '@media print{body{margin:10mm}}'+
                    '</style>'+
                '</head>'+
                '<body>'+
                    '<div class="draft">'+
                        'مسودة — لا توجد حركة مخزنية حتى الإرسال'+
                    '</div>'+
                    '<h1>'+
                        'إذن مخزني — '+
                        esc(v.voucher_code)+
                    '</h1>'+
                    '<div class="meta">'+
                        '<div class="box">'+
                            '<span class="muted">النوع</span><br>'+
                            esc(v.type||'')+
                        '</div>'+
                        '<div class="box">'+
                            '<span class="muted">التاريخ</span><br>'+
                            esc(v.voucher_date||'')+
                        '</div>'+
                        '<div class="box">'+
                            '<span class="muted">المصدر</span><br>'+
                            esc(from)+
                        '</div>'+
                        '<div class="box">'+
                            '<span class="muted">الوجهة</span><br>'+
                            esc(to)+
                        '</div>'+
                        '<div class="box">'+
                            '<span class="muted">المرجع</span><br>'+
                            esc(v.reference||'')+
                        '</div>'+
                        '<div class="box">'+
                            '<span class="muted">أنشأ بواسطة</span><br>'+
                            esc(v.created_by||'')+
                        '</div>'+
                    '</div>'+
                    '<h2>الأصناف</h2>'+
                    '<table>'+
                        '<thead>'+
                            '<tr>'+
                                '<th>الكود</th>'+
                                '<th>الصنف</th>'+
                                '<th>الوحدة</th>'+
                                '<th>الكمية</th>'+
                                '<th>سعر الوحدة</th>'+
                                '<th>ملاحظات</th>'+
                            '</tr>'+
                        '</thead>'+
                        '<tbody>'+
                            lines+
                        '</tbody>'+
                    '</table>'+
                    '<h2>ملاحظات</h2>'+
                    '<div class="box">'+
                        esc(v.notes||'—')+
                    '</div>'+
                    '<div class="muted" style="margin-top:16px">'+
                        'تم إنشاء نسخة الطباعة من الحالة الحالية للمسودة في النظام.'+
                    '</div>'+
                '</body>'+
                '</html>'
            );

            w.document.close();

            setTimeout(
                function(){
                    try{
                        w.focus();
                        w.print();
                    }catch(e){}
                },
                250
            );
        })
        .catch(function(e){

            try{
                w.close();
            }catch(_e){}

            RW_UI.showError(
                e.message||
                'فشل تجهيز المسودة للطباعة'
            );
        })
        .finally(function(){

            RW_UI.hideLoader();
        });
},
```

### Draft Action block

بعد تطبيق Report318 PATCH-05 يصبح:

```javascript
if(act==='draft'){
    a+=
        '<button onclick="event.stopPropagation();App.editVoucher(\''+
        s.esc(v.voucher_code)+
        '\')" class="bg-amber-500 text-white px-3 py-2 rounded-xl text-xs font-black">تعديل</button>';

    a+=
        '<button onclick="event.stopPropagation();App.deleteVoucher(\''+
        s.esc(v.voucher_code)+
        '\')" class="bg-rose-600 text-white px-3 py-2 rounded-xl text-xs font-black">حذف</button>';

    a+=
        '<button onclick="event.stopPropagation();App.printDraftVoucher(\''+
        s.esc(v.voucher_code)+
        '\')" class="bg-slate-700 text-white px-3 py-2 rounded-xl text-xs font-black">طباعة</button>';

    a+=
        '<button onclick="event.stopPropagation();App.send(\''+
        s.esc(v.voucher_code)+
        '\')" class="bg-indigo-600 text-white px-3 py-2 rounded-xl text-xs font-black">إرسال</button>';
}
```

هذا ليس إعادة كتابة للـApp.cards().

---

# 8. Why Draft Print is durable

الطباعة الجديدة:
- لا تعتمد على Modal مفتوح.
- لا تعتمد على DOM موجود في الصفحة.
- تفتح نافذة الطباعة فورًا من click event.
- تقرأ المسودة الحالية مباشرة من Production.
- تتحقق أن الحالة Draft.
- تقرأ تفاصيل المستند نفسها.
- تعرض المصدر والوجهة والمرجع والمنشئ والأصناف.
- توضح أن المسودة لا تحمل حركة Physical حتى الإرسال.
- لا تنفذ Stock Movement.
- لا تنشئ Edge Function.
- لا تغير Contract المخزني.

Syntax للعنصر المقترح:
PASS

---

# 9. Fleet — الإصلاح Production-only المنفذ

## العيب

Current main.html يعرض:
- expected_km_per_liter
- operational_condition
- route_capability

لكن fleet_query('vehicles') لم يكن يعيدها في projection الأساسي رغم وجودها في vehicles.

## المعالجة

تم تنفيذ:
supabase/migrations/20260923_fleet_query_vehicle_operational_fields_projection_fix.sql

والـProduction runtime أصبح يعيد الحقول الثلاثة.

### Production verification

- CHV-2025-01:
  expected_km_per_liter = 11
  operational_condition = Good
  route_capability = Any

- FRD-2025-02 TEST:
  expected_km_per_liter = 13
  operational_condition = Good
  route_capability = Any

### حالة الإغلاق
PRODUCTION FIXED / RUNTIME RPC VERIFIED

ولا يوجد أي تعديل على main.html.

---

# 10. Fleet Edit — ما ثبت ولم يُغيّر

Current fleet_command_atomic يحتوي:
VEHICLE_UPDATE

ويقبل بيانات المركبة التفصيلية المطلوبة.

لكن main.html الحالي لا يضع زر Edit/Onclick للمركبة في جدول Fleet.

إذن:
- backend capability موجودة.
- UI action غير موجود.

لا توجد حاجة إلى Edge Function جديدة.

هذه Owner UI gap محمية صراحة في هذه الجلسة وتبقى مفتوحة حتى تعديل main.html من المالك.

---

# 11. Branch Add / save-branch

## ما تم إثباته

save-branch الحالية:
- تتحقق من Authorization.
- تستخدم auth.getUser.
- تربط المستخدم بـusers.auth_id.
- تتحقق من company/status.
- تولد Branch Code التالي رقميًا من آخر BR-n.

إذن آلية:
آخر Branch Code + 1
موجودة Production بالفعل.

## العيب UI

Current main.html يستخدم في New Branch قيمة افتراضية نصية هي "جديد" للحقل branch_code بدل الرقم المتوقع.

## رسالة:
سياق الشركة غير صالح

لا يوجد دليل آمن يسمح بتعديل Auth/Company Contract.

الحسابات الإدارية النشطة الحالية لديها auth_id صحيحًا في Production.

لذلك لم يتم تخفيف auth_id validation ولم تُفتح ثغرة Tenant Isolation لمعالجة رسالة Session-specific.

---

# 12. Vehicle vs Branch semantics

تمت مطابقة النموذج مع Production:

Vehicle:
- Master Vehicle.
- له mobile_branch_id.
- يمكن أن يكون Mobile Stock context.
- لا يتحول إلى Branch حقيقي في Business meaning.
- Physical custody في DirectSale مرتبطة بالمندوب.

DirectSale E2E أعاد:
custodian_user_id = representative

وهذا يثبت:
Vehicle = mobile container/context
Representative = custody/accountability actor

---

# 13. Van Sales

Current van-sales.html:
- يستخرج company عبر users.auth_id.
- يستخدم setup-van-branch.
- يعتمد mobile branch للمندوب.
- يحفظ Direct Sale عبر save-sales-invoice.
- لا يكتب Physical Stock مباشرة.

لا يوجد دليل جديد يبرر إعادة فتحه.

لم يتم تعديله.

---

# 14. Competitive review

تمت مراجعة الوثائق الرسمية الحديثة:

Odoo:
يدعم Barcode operations وBatch Transfers وإنشاء/معالجة Transfers.
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html

Dynamics 365 Business Central:
Transfer Orders تدعم Shipment وReceipt وin-transit tracking وdirect transfers وbatch posting وplanning-related timing.
https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-transfer-between-locations

Daftra:
Manual Transfer يدعم التاريخ والمصدر والوجهة والصنف والكمية، مع before/after، كما توفر تقارير Inventory Detailed Transactions الطباعة والتصدير.
https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

### Business capabilities التي يجب الحفاظ عليها في RAWAEA

- فصل Warehouse Voucher عن Orders/Runsheets.
- Physical Stock central engine.
- Mobile Vehicle context.
- Representative custody.
- Barcode workflow.
- Before/After audit.
- Realtime synchronization.
- Audit trail.
- Two-step transfer.
- Idempotency.

### فرص Business Contracts اللاحقة

- in-transit dashboard
- expected receipt date/time
- approval
- attachments
- transfer priority
- batch/wave transfer
- richer operation timeline
- lot/serial/expiry
- warehouse/bin metadata

هذه ليست إصلاحات لازمة لإغلاق الأزمة الحالية.

---

# 15. E2E Status

## Production RPC
PASS:
- DirectSale CREATE
- DirectSale SEND
- DirectSale COMPLETE
- stock delta
- custody assignment
- rollback

## Draft Data
PASS:
- Draft IN-1 had zero Physical Movement and was deleted through existing Draft delete capability.

## Fleet
PASS:
- runtime projection
- expected_km_per_liter
- operational_condition
- route_capability

## Browser
OPEN

لا يتم تحويل SQL E2E أو source-harness إلى Browser E2E.

---

# 16. ما لا يُعاد فتحه دون دليل جديد

- App.loadRefs()
- App.allowedBranch()
- App.vehicleBranch()
- App.pickArr()
- App.pickSelect()
- App.prefetchStock()
- App.routeHtml()
- App.renderWorkspace()
- Van Sales backend integration
- Physical Stock centralization

هذه الأجزاء ثبتت ولم يظهر Current Production evidence جديد يعارضها.

---

# 17. SELF-AUDIT

## What I Proved
- Current Production snapshot was captured after execution.
- Current System Git was reverified.
- Current Frontend SHA was reverified.
- Current vouchers SHA was reverified.
- DirectSale business contract is enforced in Production Core.
- DirectSale transactional E2E passed and rolled back.
- Current vehicles without representative assignment are correctly excluded.
- fleet_query lacked the three operational fields in its primary vehicle projection.
- Production now returns those fields.
- VEHICLE_UPDATE exists in current Production.
- save-branch already generates next numeric code in Production.
- No new Edge Function was created.
- Current Draft IN-1 was proven test data and deleted.
- main.html / vouchers.html / van-sales.html were not written by the assistant.

## What I Did Not Prove
- Which authenticated browser session caused the historical save-branch 400.
- Browser-authenticated E2E against the published artifact.
- Final served frontend SHA after owner application.

## Current Open Risks
- Report318 Owner patches remain unapplied.
- PATCH 319-01 is ready but owner-side.
- Fleet Edit UI remains absent from main.html.
- New Branch UI still shows "جديد".
- Served artifact and browser E2E remain unverified.
- DirectSale vehicle picker will remain empty until a production vehicle is actually assigned to a valid direct-sale representative.

## Final Status

Production Fleet projection:
CLOSED / VERIFIED

Manual Voucher Physical Core:
CLOSED / VERIFIED

DirectSale Business Contract:
CLOSED / VERIFIED

Voucher frontend Owner Patch:
OPEN / READY

Draft Print:
PATCH READY / OWNER APPLICATION REQUIRED

Browser E2E:
OPEN

Global Vouchers target:
PARTIALLY CLOSED

---

# 18. NEXT SESSION — لا تبدأ من الصفر

1. اقرأ هذا التقرير.
2. اقرأ CURRENT_STATE.md.
3. تحقق من System HEAD وParent.
4. تحقق من Frontend HEAD وvouchers.html SHA.
5. لا تعيد إصلاح أي جزء مصنف CLOSED.
6. طبّق Report318 PATCH-01 → PATCH-08 على vouchers.html.
7. أضف PATCH 319-01 للطباعة.
8. Static parse.
9. Commit frontend.
10. Publish.
11. طابق served artifact مع Git.
12. Authenticated Browser E2E:
   - Transfer
   - DirectSale
   - DirectReturn
   - SupplierReturn
   - Draft Print
   - Draft Edit
   - Draft Delete
   - Send
   - Receive
   - Complete
13. بعد كل Closure التقط Production snapshot جديد.
14. حدّث CURRENT_STATE.md.
15. لا تعلن GLOBAL INVENTORY CORE INTEGRITY = 100% CLOSED قبل served artifact verification + Browser E2E.

---

## Production migration

تم إنشاء وتسجيل:
supabase/migrations/20260923_fleet_query_vehicle_operational_fields_projection_fix.sql

Production runtime verification:
PASS

No new Edge Function.
No frontend source write.
No Physical Stock contract change.
