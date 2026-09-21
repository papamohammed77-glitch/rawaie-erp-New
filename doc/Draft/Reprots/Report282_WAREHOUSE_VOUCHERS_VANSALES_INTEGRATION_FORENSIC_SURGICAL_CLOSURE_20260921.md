
# تقرير 282 — الإغلاق الجنائي لتكامل الأذونات المخزنية مع البيع المباشر

التاريخ: 2026-09-21  
النطاق: Warehouse Vouchers + Van Sales Integration  
الحالة: Production changes executed; source synchronized; vouchers.html owner patch prepared only.

## 1. منهج التنفيذ
تم البدء من آخر حالة مثبتة، ثم:
Production → Current Source → Historical Contract → Contract Gap → Surgical Fix → Runtime Verification → Source Synchronization → State Update

لم يتم لمس main.html.
لم يتم تعديل erp-frontend/companies/company-1/warehouse/vouchers.html.

## 2. Git baseline
System repo HEAD عند البداية:
81ff22d93edf2f1d7f380b405263025786e3ac22

Parent:
3b0b50901482ec6ae34de84280ba1e5069b3003e

Vouchers current blob:
5eea64c53a344f588c8035dc278d559d2be1b242

Van Sales blob قبل التعديل:
445dff4217fbf4a82f333fa716bba5d74def7680

## 3. Production snapshot
companies = 1
branches = 2
vehicles = 0
stock_vouchers = 0
stock_voucher_details = 0
inventory_log = 3
audit_log = 2023
orders = 0

## 4. Inventory contract المثبت
Physical Movement:
post_stock_movement
ثم stock_branches + inventory_log

reserve_stock و release_stock_reservation ليستا Physical Movement Engines.

## 5. تاريخ ودور الأذونات
التطبيق مستقل للعمليات المخزنية غير المرتبطة مباشرة بـ Orders/Runsheets.

الأنواع التاريخية:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

Current architecture أبقى Scrap/Adjustment ضمن Adjustment Engine.

DirectSale هو مسار تزويد مخزن السيارة.
DirectReturn هو مسار إعادة مخزون السيارة.
Transfer هو نقل داخلي.
SupplierReturn هو خروج للمورد.

## 6. الحالة السابقة التي لم تُعاد
سبق إغلاق:
- send / cancel / complete wrapper drift
- summary regression
- CREATE operation identity
- RECEIVE operation identity
- before/after stock
- filtering/list
- unified audit/details
- DirectSale physical centralization

لم يتم إعادة تنفيذ أي منها.

## 7. Defect A — Vehicle identity drift
Van Sales كان يحمل أثرًا تاريخيًا يبني هوية المخزن من بريد المندوب.

Production contract الحالي أصبح:
vehicles.vehicle_code
+
vehicles.mobile_branch_id

كما أن fn_vehicle_context_guard يفرض أن mobile_branch_id يشير إلى branch داخل نفس الشركة وكوده VAN-vehicle_code.

العلاج:
تم تحديث setup-van-branch إلى version 4.

السلوك النهائي:
- Auth user → public user company
- company-scoped vehicle
- active vehicle
- mobile stock enabled
- canonical mobile_branch_id
- compatibility fallback إلى VAN-vehicle_code
- إنشاء branch عند الغياب
- ربط vehicles.mobile_branch_id
- setup_van_stock

Production:
setup-van-branch version 4
verify_jwt = true
deployment sha256:
4cd64c65643430eb7df439937878a31017ce145851211d4733ba7f730402211c

## 8. Defect B — Quick Sale selector drift
الواجهة أصبحت تعتمد على this.selCust، بينما submitQuickSale كان يبحث عن quickCustSelect الذي لم يعد موجودًا.

العلاج:
submitQuickSale يقرأ customer_code من this.selCust.

كما يمنع التنفيذ عند غياب:
vanBranchId
أو vanBranch.branch_code
أو cart.

## 9. Defect C — Double deduction
Production VanSale يخصم فعليًا من stock_branches.

Vehicle Stock UI كانت تحسب:
current stock - today's sales

وهذا يخصم نفس المبيعات مرتين.

العلاج:
الرصيد الحالي = stock_branches.qty
المباع اليوم = KPI معلوماتي فقط.

## 10. Defect D — Quick Sale operation identity
تم تثبيت operation_id محليًا باستخدام fingerprint يحتوي على:
- driver email
- customer
- vehicle branch
- item codes
- quantities
- prices

عند النجاح تزال هوية العملية.
عند retry تعاد نفس الهوية.

## 11. Production VanSale guard
أضيف الحارس إلى physical writer المركزي.

VanSale يتطلب:
- source branch داخل company
- active vehicle
- mobile_stock_enabled
- source branch = vehicles.mobile_branch_id
- vehicle.driver_id = authenticated user email

وبذلك لا يمكن تمرير مبيعات فان من مخزن سيارة أخرى أو من مستخدم غير المندوب المرتبط.

## 12. Runtime E2E
تم الاختبار داخل Transaction مؤقتة ثم ROLLBACK.

الكيانات المؤقتة:
Branch: VAN-E2E-VEH-20260921
Vehicle: E2E-VEH-20260921
Driver: vansales@rawaea.com
Item: 1006
Stock before: 10

النداء الصحيح:
VanSale + vansales@rawaea.com

النتيجة:
success = true
duplicate = false
qty = 1
stock after = 9
inventory log = 1

اختبار المستخدم الخاطئ:
sales.manager@rawaea.com
النتيجة: rejected

اختبار الفرع الخاطئ:
main branch
النتيجة: rejected

تم rollback كامل.
لا توجد بيانات اختبار دائمة في Production.

## 13. R1 ثم R2
تم تطبيق migration أولى:
20260921103000_vansales_mobile_branch_driver_guard

ثم اتضح أثناء المراجعة أن coupling إضافيًا مع fleet_driver_id ليس مثبتًا كعقد مطلوب لهذا المسار، فتم إصدار النسخة النهائية:
20260921110000_vansales_mobile_branch_driver_guard_r2

النسخة النهائية تعتمد فقط على:
vehicle.driver_id
+
authenticated driver
+
mobile_branch_id

تم حفظ النسختين في Git لأنهما تم تطبيقهما فعليًا في Production، وR2 هي الحالة النهائية.

## 14. Source synchronization
تم تحديث:
rawaie-erp-New/Current/Edge_Functions/setup-van-branch
ليطابق Production v4.

تم تعديل:
erp-frontend/companies/company-1/sales/van-sales.html

frontend current commit:
a914c3e268c8801533051a3f0901c0db5919ee64

كما تمت مزامنة:
rawaie-erp-New/Current/PWA/van-sales.html

canonical PWA commit:
99ca1c65bd8798ca433c1ee53ee2cf9c5d296af9

تم اجتياز JavaScript Parser validation.

## 15. Vouchers owner patch
vouchers.html لم يُعدل.

المطلوب فقط إصلاح UI integration بحيث يقرأ:
vehicles.mobile_branch_id
و mobile_stock_enabled
ويستخدم mobile_branch_id قبل VAN-vehicle_code fallback.

### PATCH 1
الملف:
erp-frontend/companies/company-1/warehouse/vouchers.html

الموضع:
loadRefs:function()
تقريبًا عند line 27

استبدل الدالة كاملة بالدالة التالية:

~~~javascript
loadRefs:function(){
    var s=this;

    return Promise.all([
        supabase
            .from('branches')
            .select('id,branch_code,name,is_active,company_id')
            .eq('company_id',s.company),

        supabase
            .from('users')
            .select('id,email,name,role,default_branch_id,allowed_branch_ids')
            .eq('company_id',s.company),

        supabase
            .from('vehicles')
            .select('id,vehicle_code,license_plate,model,driver_id,status,mobile_branch_id,mobile_stock_enabled')
            .eq('company_id',s.company),

        supabase
            .from('suppliers')
            .select('id,supplier_code,name,phone,branch_id')
            .eq('company_id',s.company),

        supabase
            .from('app_settings')
            .select('main_branch_id')
            .eq('company_id',s.company)
            .order('created_at',{ascending:true})
            .limit(1)
            .maybeSingle()
    ])
    .then(function(r){
        var refs={};

        refs.branches=(r[0]&&r[0].data)||[];
        refs.reps=(r[1]&&r[1].data)||[];
        refs.vehicles=(r[2]&&r[2].data)||[];
        refs.suppliers=(r[3]&&r[3].data)||[];

        refs.mainBranchId=
            r[4]&&r[4].data
                ? r[4].data.main_branch_id
                : null;

        refs.supplierBranchMap={};

        for(var i=0;i<refs.suppliers.length;i++){
            var sp=refs.suppliers[i];

            if(sp.branch_id&&sp.id){
                if(!refs.supplierBranchMap[sp.branch_id]){
                    refs.supplierBranchMap[sp.branch_id]={};
                }

                refs.supplierBranchMap[sp.branch_id][sp.id]=true;
            }
        }

        s.refs=refs;
        return refs;
    });
},
~~~

### PATCH 2
ابحث تحديدًا عن العنصر الحالي:
vehicleBranch:function(v){if(!v)return null;var code='VAN-'+String(v.vehicle_code||'').trim().toUpperCase();return(this.refs.branches||[]).find(function(b){return String(b.branch_code||'').trim().toUpperCase()===code})||null;},

وهو تقريبًا عند line 504.

احذف العنصر كاملًا واستبدله:

~~~javascript
vehicleBranch:function(v){
    if(!v)return null;

    if(v.mobile_stock_enabled===false){
        return null;
    }

    if(v.mobile_branch_id){
        var direct=(this.refs.branches||[]).find(function(b){
            return String(b.id)===String(v.mobile_branch_id);
        });

        if(
            direct &&
            direct.is_active!==false &&
            String(direct.company_id||'')===String(this.company||'')
        ){
            return direct;
        }
    }

    var code=
        'VAN-' +
        String(v.vehicle_code||'')
            .trim()
            .toUpperCase();

    return (this.refs.branches||[]).find(function(b){
        return (
            b.is_active!==false &&
            String(b.branch_code||'')
                .trim()
                .toUpperCase()===code
        );
    })||null;
},
~~~

لا تعدل:
callAction
send
cancel
complete
receive
summary
CREATE
RECEIVE operation identity
before/after stock
filter/list
audit/details

## 16. لماذا لم نضف Serial/Lot/Expiry الآن
Odoo وDaftra يثبتان وجود Lot/Serial/Expiry tracking في inventory workflows، وDaftra يضيف physical count/system count/difference في stocktaking.
Dynamics يميز Inventory Adjustment وTransfer وCounting وTag Counting وItem Arrival.
SAP يميز goods receipt وgoods issue وstock transfer وtransfer posting ويربط goods movements بوثائق مادية.

هذه features تنافسية حقيقية، لكنها تتطلب Business Contract + Schema Contract جديدًا في RAWAEA الحالية.
لم يتم اختراع جداول أو حقول غير مثبتة في Production خلال هذه المهمة.

## 17. Competitive evidence
Odoo:
https://www.odoo.com/documentation/19.0/

Dynamics 365:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

SAP:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/4eb099dbc8a6435c9b36a854a7e05522/1063bd534f22b44ce10000000a174cb4.html

Daftra:
https://docs.daftra.com/en/user_manual/the-inventory-stocktaking-method-used-in-the-system-and-its-features/

Daftra tracked products:
https://docs.daftra.com/en/user_manual/how-to-perform-inventory-stocktaking-of-tracked-products/

Manager.io لم يُستخدم كمصدر عقد في هذه الجلسة لعدم توفر توثيق رسمي موثوق من البحث المنفذ.

## 18. Status Matrix

| Closure | Status |
|---|---|
| Voucher CREATE | CLOSED |
| Voucher SEND | CLOSED |
| Voucher RECEIVE | CLOSED |
| Voucher COMPLETE | CLOSED |
| Voucher CANCEL | CLOSED |
| DirectSale central stock | CLOSED |
| Vehicle/mobile branch identity | CLOSED |
| VanSale driver/source guard | CLOSED |
| Van stock double deduction | CLOSED |
| Quick Sale customer selector | CLOSED |
| Quick Sale retry identity | CLOSED |
| Vouchers canonical mobile branch UI | OPEN — owner patch |
| Browser E2E with real vehicle | OPEN — Production vehicles = 0 |
| Lot/Serial/Expiry | FUTURE BUSINESS CONTRACT |

## 19. Self Audit

### What was proved
- Physical stock is centrally mutated.
- VanSale is tied to authenticated driver's mobile branch.
- setup-van-branch v4 is deployed.
- Quick Sale selector mismatch was real.
- Van stock visual double deduction was real.
- retry identity was strengthened.
- transaction E2E passed.
- test records were rolled back.
- canonical source copies were synchronized.

### What was not proved
- Browser E2E against a persistent real vehicle, because Production currently contains zero vehicles.
- Lot/Serial/Expiry contract.
- Final browser result after owner applies the two vouchers patches.

### What remains
Only:
1. owner patch in vouchers.html
2. browser E2E using an actual configured vehicle
3. then re-read Production in the same reporting window.

## 20. تعليمات الجلسة التالية

ابدأ من:
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

ثم:
1. افحص blob الحالي لـ vouchers.html.
2. تحقق هل PATCH 1 وPATCH 2 مطبقان.
3. لا تعيد أي closure سابق.
4. لا تلمس main.html.
5. لا تعيد إنشاء Edge Function.
6. بعد owner patch نفذ Browser E2E مع Vehicle حقيقي.
7. أعد مطابقة Production فورًا قبل أي نسبة أو تقرير جديد.
8. Lot/Serial/Expiry لا يبدأ قبل Business Contract وSchema Contract مستقلين.


## 21. Final full-path E2E — Production

تم تنفيذ المسار الكامل داخل Transaction ثم ROLLBACK:

van-sales
→ save-sales-invoice
→ save_sales_invoice_atomic
→ post_stock_movement(VanSale)
→ stock_branches
→ inventory_log

بيانات الاختبار:
- temporary branch: VAN-E2E-SAV-23
- temporary vehicle: E2E-SAV-23
- driver: vansales@rawaea.com
- item: 1006
- stock before: 10
- operation_id:
  7a4edb68-f0d1-4a03-8a01-c8e7d37b0b1e

العملية الأولى:
- success = true
- duplicate = false
- orderID = ORD-1001
- stock after = 9
- movement_count = 1
- cash_posted = true

إعادة نفس العملية بنفس operation_id:
- success = true
- duplicate = true
- نفس orderID
- لم تُنشأ حركة مخزنية ثانية

تم تنفيذ ROLLBACK بعد الاختبار.
نتيجة Production بعد الاختبار بقيت:
orders = 0
inventory_log = 3

وبذلك أصبح التكامل الخادم-الخادم مثبتًا، وليس مجرد static source review.

## 22. النتيجة النهائية بعد E2E الكامل

Van Sales physical stock integration = CLOSED

Van Sales operation idempotency = CLOSED

Van Sales mobile branch authorization = CLOSED

Standalone Vouchers canonical mobile branch UI = OPEN — owner patch فقط

Browser E2E الحقيقي على سيارة تشغيلية = OPEN بسبب أن Production الحالية تحتوي 0 vehicles.
