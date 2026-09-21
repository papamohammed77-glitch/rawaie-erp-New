# تقرير 287 — الإغلاق الجنائي الجراحي للأذونات المخزنية وتكامل Van Sales
تاريخ الجلسة: 2026-09-21
الحالة: **Production verified / Source verified / Browser E2E gate remains open**

## 1. قاعدة الإثبات
تم تطبيق مبدأ الحوكمة الحاكم:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
التقارير السابقة استُخدمت كسياق تاريخي فقط، ولم تُعامل كحالة حالية.

تمت مراجعة:
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS.
- CURRENT_STATE.md.
- تقرير Report286.
- آخر commits والـparent في المستودع الأم.
- آخر commits والـparent في مستودع التطبيقات.
- النسخة الحالية الفعلية من vouchers.html.
- النسخة الحالية الفعلية من van-sales.html.
- Production RPCs / triggers / schema / data.
- الملف التاريخي: Architecture/الأذونات المخزنية اليدوية.md.

## 2. Git forensic baseline
### System repository
Repository:
papamohammed77-glitch/rawaie-erp-New

HEAD قبل هذه الجلسة:
9827cc8bf06e68c76fb45268331c9c982acc6661
Parent:
ba4dfd78fd298367aeb98213b383d447dd241401

وظيفة آخر commit:
state: finalize Report286 commit references

### Mother frontend repository
Repository:
papamohammed77-glitch/erp-frontend

آخر HEAD قبل إصلاح Van Sales:
ff13516e04050a74d87771f949bcb69f7e085f3d
Parent:
5801db5d15673c49e88ccfc69e84f0a53cd8866d

وقد ثبت أن commits:
- c30e3a6c... حسّن حالات وأزرار الأذونات.
- 5801db5d... أضاف عرض المندوب المسؤول عن العهدة.
- ff13516e... أصلح syntax defect الناتج عن ذلك التعديل.

بعد الإغلاق الحالي:
Van Sales commit:
36e521f78c8507e431bb9eb780269612c2d6cbf0
Parent:
ff13516e04050a74d87771f949bcb69f7e085f3d

ملف Van Sales الحالي:
companies/company-1/sales/van-sales.html
Blob:
8d61382a8e0025a0d079e71dd94f33d106d9088e

ملف Vouchers الحالي:
companies/company-1/warehouse/vouchers.html
Blob:
97d3dc89eafa97dd11bcde997ab73f5db97b9008

## 3. الملفات التي لم تُلمس
تم الالتزام الصارم بـ:
- لم يتم تعديل Current/PWA/main.html.
- لم يتم تعديل companies/company-1/warehouse/vouchers.html مباشرة.
- لم يتم إنشاء Edge Function جديد.
- لم يتم إعادة تنفيذ migrations أغلقت سابقًا.

ملف Vouchers الحالي يحتوي بالفعل على الإصلاحات السابقة الخاصة بالعهدة، لذلك لم تتم إعادة كتابتها أو ترقيعها.

## 4. العقد الوظيفي المؤكد
التفسير الصحيح ليس:
Vehicle = مسؤول البضاعة

بل:
Physical source/location = Branch أو Vehicle mobile branch
Custodian = Representative
Vehicle = transport/mobile-stock container

### DirectSale
المصدر المادي:
Branch

النقطة المادية المستلمة:
Vehicle/mobile stock branch

المسؤول:
custodian_user_id = direct-sales representative

العلاقة:
vehicles.driver_id = custodian_user_id

### DirectReturn
المصدر المادي:
Vehicle/mobile stock

الجهة المادية المستقبلة:
Branch

المسؤول:
custodian_user_id = representative المرتبط بالمركبة

هذه البنية تحفظ المسؤولية القانونية/التشغيلية للمندوب، وتبقي السيارة وعاءً ومكانًا للموجودات، دون جعل السيارة نفسها صاحب العهدة.

## 5. Production proof للعهدة
الحارس الحالي في Production:
trg_stock_vouchers_custodian

ويستدعي:
enforce_stock_voucher_custodian()

الحارس يثبت:
- DirectSale يحتاج Vehicle endpoint.
- DirectReturn يحتاج Vehicle source.
- vehicle يجب أن يتبع الشركة.
- vehicle يجب أن يكون Active.
- mobile_stock_enabled يجب ألا يكون false.
- vehicle.driver_id يجب أن يكون موجودًا.
- إذا لم يُرسل custodian_user_id يتم اشتقاقه من vehicle.driver_id.
- إذا أُرسل custodian مختلف عن driver_id يتم رفض العملية.
- custodian يجب أن يكون مستخدمًا Active بدور مندوب بيع مباشر داخل نفس الشركة.
- بعد Sent/Received/Completed تصبح هوية الحركة المحمولة immutable.

### Production data snapshot النهائي
companies = 1
branches = 3
vehicles = 1
stock_vouchers = 1
stock_voucher_details = 3
stock_voucher_operations = 1
inventory_log = 3
audit_log = 2030
orders = 0
mobile vouchers missing custodian = 0

الإذن الحالي:
IN-1
type = DirectSale
status = Draft

المصدر:
الفرع الرئيسي

المندوب المسؤول:
مندوب مبيعات بيع مباشر
vansales@rawaea.com

المركبة:
VEH-TEST-260921

vehicle.driver_id = custodian_user_id

ولا توجد حاليًا حالة DirectSale/DirectReturn تفتقد custodian.

## 6. سبب الخطأ التاريخي الذي كشفه التحقيق
التقرير التاريخي السابق كان قد أصلح طبقة Production، ثم تم لاحقًا إصلاح عرض Vouchers في Mother frontend.
لكن المصدر الحالي كشف أن Van Sales نفسه كان يحمل أخطاء مستقلة لم تكن ظاهرة في إصلاح العهدة السابق.

### Defect A — هوية email خارج نطاق submitQuickSale
داخل:
submitQuickSale:function()

كان بناء العملية يعتمد على:
driver_email: email

بينما تعريف email الموجود في الملف كان محليًا داخل دوال أخرى مثل doLogin وloadVanBranch، وليس متغيرًا صالحًا داخل نطاق submitQuickSale.

الأثر:
إمكانية فشل مسار البيع السريع عند الوصول إلى بناء fingerprint قبل استدعاء save-sales-invoice.

العلاج المنفذ:
تم ربط email مباشرة بـ:
self.currentUser.email
مع التحقق من وجود الهوية قبل إنشاء العملية.

### Defect B — syncDown غير company-scoped
النسخة السابقة كانت تقرأ:
customers
items
stock_branches
branches
app_settings LIMIT 1

دون بناء Company context أولًا.

الأثر:
خرق محتمل لعقد tenant isolation، وتغذية Dexie ببيانات لا يثبت أنها تخص الشركة الحالية.

العلاج المنفذ:
- الحصول على auth session.
- حل users.company_id من auth_id.
- تحميل branches للشركة فقط.
- تحميل customers للشركة فقط.
- تحميل items للشركة فقط.
- تحميل stock_branches بواسطة branch IDs التابعة للشركة.
- تحميل app_settings للشركة نفسها.
- عدم مسح Dexie قبل التأكد من نجاح جميع القراءات.

### Defect C — startup offline dead-end
كان:
syncDown().then(loadVanBranch)

وبالتالي فشل syncDown الشبكي يمنع الوصول إلى loadVanBranch، رغم وجود fallback محلي داخل loadVanBranch نفسه.

العلاج المنفذ:
تم جعل loadVanBranch يصل إلى التنفيذ حتى عند فشل مزامنة الشبكة.

### Defect D — تحديث Dexie للجرد بمفتاح خاطئ
كان تحديث stock يعتمد على مقارنة:
s.item_id === items[j].itemCode

وهذا خلط صريح بين:
item_id
و
item_code

العلاج المنفذ:
بعد نجاح save-inventory-count تتم إعادة مزامنة الحالة من Production بدل كتابة حالة محلية غير صحيحة.

## 7. Van Sales — لماذا كان ذلك مهمًا للتكامل
Van Sales ليس نظامًا موازيًا مستقلًا عن ERP.
مساره الصحيح:
Representative session
→ vehicle/mobile branch
→ direct sale
→ save-sales-invoice
→ save_sales_invoice_atomic
→ order
→ order_details
→ post_stock_movement
→ stock_branches + inventory_log
→ accounting/ledger حسب عقد البيع.

وبالمثل:
Vehicle/mobile stock
→ DirectReturn voucher
→ send
→ receiving branch
→ receive
→ stock movement
→ inventory/audit.

لذلك فإن صحة هوية العملية داخل Van Sales ليست تحسينًا شكليًا؛ بل جزء من سلامة transaction identity وidempotency والتدقيق.

## 8. Vouchers source — الحالة الحالية
لم تتم إعادة تطبيق Report286.

وثبت من الـblob الحالي أن الإصلاحات السابقة موجودة بالفعل:
- filterList يعرض ويبحث عن custodian.
- cards تعرض "المستلم والمسؤول عن العهدة".
- details تعرض custodian منفصلًا عن vehicle/container.
- receive يستخدم operation identity محلية.
- submit يرسل rep_id + operation_id.
- vehicleBranch يعتمد على mobile_branch_id مع fallback canonical.
- DirectSale يتحقق من rep + vehicle + source branch.
- DirectReturn يتحقق من vehicle + rep + receiving branch.

## 9. التحسين الإنتاجي الوحيد في DB خلال هذه الجلسة
تم تعديل RPC موجود بالفعل:
inventory_control(p_operation,p_payload)

Migration:
inventory_control_voucher_audit_operations_20260921

الإضافة:
VOUCHER_AUDIT أصبح يقرأ أيضًا:
stock_voucher_operations

ويعيد:
- id
- operation_id
- fingerprint
- voucher_id
- created_at

الهدف:
عدم ترك operation identity موزعة بين inventory_log وaudit فقط، وتمكين طبقة الرقابة من الوصول إلى operation registry الرسمي من نفس RPC.

لم يتم إنشاء Edge Function جديد.

## 10. Physical Stock forensic result
تم فحص routines التي تحتوي على references إلى stock_branches/inventory_log.

النتيجة:
post_stock_movement هو الـwriter المركزي الذي يكتب:
stock_branches
+
inventory_log

الدوال:
reserve_stock
release_stock_reservation
setup_van_stock
تعمل في نطاقات reservation/initialization وليست Physical Movement engines مستقلة.

الدوال التشغيلية:
post_manual_stock_voucher_atomic_core_20260828
send_stock_voucher_atomic_core_20260828
post_inventory_adjustment_atomic
لا تنفذ Physical Movement مستقلًا؛ بل تنقل الحركة إلى post_stock_movement.

نتيجة هذا closure:
لا يوجد Writer تشغيلي بديل جديد تم اكتشافه يتجاوز post_stock_movement.

## 11. E2E transactional verification
تم تنفيذ سيناريو داخل transaction واحدة مع rollback كامل:

1. إنشاء DirectSale مؤقت.
2. التحقق من custodian بعد CREATE.
3. التحقق من vehicle.driver_id.
4. SEND.
5. قياس stock المصدر.
6. قياس stock mobile branch.
7. إنشاء DirectReturn مؤقت.
8. التحقق من custodian.
9. SEND.
10. RECEIVE إلى الفرع.
11. التأكد أن stock عاد إلى خط الأساس.
12. التأكد من إنشاء inventory movements المتوقعة.
13. ROLLBACK.

النتيجة:
E2E transaction completed without exception.

تم التحقق بعد ذلك أن Production عادت لنفس snapshot السابق:
stock_vouchers = 1
stock_voucher_details = 3
stock_voucher_operations = 1
inventory_log = 3

أي أن الاختبار لم يترك بيانات اختبارية دائمة.

## 12. Integrity gates التي أثبتها Production
missing custodian = 0

bad DirectSale shape = 0

bad DirectReturn shape = 0

invalid custodian = 0

كما أن:
vehicle.driver_id = custodian_user_id
في الحالة التشغيلية الموجودة.

## 13. مقارنة مختصرة مع الأنظمة المنافسة
### Odoo
Odoo 19 يعرض في Physical Inventory:
Location
Product
Lot/Serial Number
Counted
Difference
Unit
كما يدعم مسؤولًا وتاريخًا لخط العد، ويسجل فرق المخزون كحركة تطبيقية بعد الاعتماد.
المصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/count_products.html

ويدعم حركة المخزون والتقييم عبر receipts, returns, deliveries, vendor returns, scrap، كما تتغير قيمة المخزون مع adjustments.
المصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html

### Microsoft Dynamics 365
Inventory journals تشمل:
Movement
Inventory adjustment
Transfer
Counting
Tag counting

والـTransfer journal يحدد from/to inventory dimensions، ويولد issue + receipt، بينما تتطلب حالة in-transit استخدام transfer order.
المصدر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

### SAP S/4HANA
يدعم stock transfer مع stock in transit، مع بقاء الكمية والقيمة قابلة للتتبع، ويمر عبر goods issue ثم goods receipt.
المصدر:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/0864cb07010642b3bde45a20de4975bc/557a1702cb9d46559cfddda3e45d078e.html

### Daftra
Stock Transfer يتضمن:
date/time
from warehouse
to warehouse
notes
quantity
available before
available after

المصادر:
https://docs.daftra.com/en/tutorial/transferring-stock/
https://docs.daftra.com/en/user_manual/how-to-do-a-stocktaking-adjustment-for-a-product-or-for-the-stock/

كما يدعم tracked inventory والـlot/serial/expiration في stocktaking.
المصدر:
https://docs.daftra.com/en/user_manual/how-to-perform-inventory-stocktaking-of-tracked-products/

### Manager.io
Inventory Transfer يتضمن:
date
reference
description
item
qty
from
to

ويعدل الكمية في المكانين تلقائيًا.
المصدر:
https://www2.manager.io/guides/10707

## 14. ما يوجد في RAWAEA حاليًا وما لا يحتاج إعادة بناء
الموجود بالفعل ويجب الحفاظ عليه:
- physical source.
- mobile physical stock.
- direct-sales custodian.
- vehicle/representative relationship.
- operation identity.
- idempotency for voucher creation/receive.
- stock movement centralization.
- audit trail.
- separated operational PWAs.
- source/target restrictions.
- branch permissions.
- daily mobile workflow.

هذا ليس skeleton فقط؛ هذه أجزاء جوهرية من العقد الذي بني خلال مراحل سابقة ولا يجوز إعادة تصميمها لمجرد المقارنة الشكلية.

## 15. فجوات تنافسية حقيقية لم تُبْنَ بعد
لم يتم اختراع implementation داخل هذه الجلسة بدون عقد مثبت.
الفجوات التي ظهرت من المقارنة وتحتاج Business Contract مستقل قبل بناءها:
1. lot/serial/expiration traceability على مستوى item movement.
2. attachments/evidence على الإذن.
3. inventory before/after كبيانات عرض رسمية محفوظة أو محسوبة من الحركة.
4. explicit approval workflow للأذونات الحساسة.
5. stock-in-transit business object مستقل إذا قررت الشركة استخدام انتقال مرحلي لا يصبح فيه المخزون موجودًا في destination قبل الاستلام.
6. enhanced discrepancy/shortage reason taxonomy.
7. richer operational reports grouped by custodian + vehicle + branch + operation.

هذه النقاط لم تُفرض على Production لأن إدخالها الآن دون Business Contract موثق سيكون مخالفة مباشرة لمبدأ الحوكمة.

## 16. OWNER SURGICAL PATCHES — vouchers.html
الملف المطلوب:
companies/company-1/warehouse/vouchers.html

**لا تعيد تطبيق Patch 1/2/3 من Report286؛ فهي مطبقة بالفعل.**

المطلوب الجديد فقط هو إزالة الـglobal item lookup في مساحة العمل والـbarcode fallback.

### PATCH V-01 — prepare
ابحث حرفيًا عن:
prepare:function(){var s=this;return Promise.all([supabase.from('items').select('id,item_code,barcode,name,search_label,category,unit,description,image_url,sales_price,cost_price,is_active').eq('is_active',true).order('item_code').limit(5000),s.prefetchStock(true)]).then(function(r){if(r[0].error)throw r[0].error;s.items=r[0].data||[]})},

احذف السطر كاملًا واستبدله كاملًا بـ:

prepare:function(){
    var s=this;

    return Promise.all([
        supabase
            .from('items')
            .select(
                'id,item_code,barcode,name,search_label,'+
                'category,unit,description,image_url,'+
                'sales_price,cost_price,is_active'
            )
            .eq('company_id',s.company)
            .eq('is_active',true)
            .order('item_code')
            .limit(5000),

        s.prefetchStock(true)
    ]).then(function(r){

        if(r[0].error){
            throw r[0].error;
        }

        s.items=r[0].data||[];
    });
},

### PATCH V-02 — handleScan
ابحث حرفيًا عن:
handleScan:function(code){var s=this,scanCode=s.norm(code),scanNow=Date.now();if(!scanCode)return;if(s.scanLastCode===scanCode&&scanNow-s.scanLastAt<1200)return;s.scanLastCode=scanCode;s.scanLastAt=scanNow;var x=this.items.find(function(i){return s.norm(i.barcode)===scanCode||s.norm(i.item_code)===scanCode});if(x){s.add(x.item_code);RW_UI.toast('تمت إضافة '+(x.name||x.item_code),'success');return}supabase.from('items').select('id,item_code,barcode,name,search_label,category,unit,description,image_url,sales_price,cost_price,is_active').eq('is_active',true).or('barcode.eq.'+code+',item_code.eq.'+code).limit(1).then(function(r){if(r.error||!r.data||!r.data[0]){RW_UI.toast('الصنف غير موجود: '+code,'warning');return}s.add(r.data[0].item_code)})},

احذف الدالة كاملة واستبدلها بـ:

handleScan:function(code){
    var s=this;
    var scanCode=s.norm(code);
    var scanNow=Date.now();

    if(!scanCode){
        return;
    }

    if(
        s.scanLastCode===scanCode &&
        scanNow-s.scanLastAt<1200
    ){
        return;
    }

    s.scanLastCode=scanCode;
    s.scanLastAt=scanNow;

    var x=this.items.find(function(i){
        return(
            s.norm(i.barcode)===scanCode||
            s.norm(i.item_code)===scanCode
        );
    });

    if(x){
        s.add(x.item_code);

        RW_UI.toast(
            'تمت إضافة '+(x.name||x.item_code),
            'success'
        );

        return;
    }

    supabase
        .from('items')
        .select(
            'id,item_code,barcode,name,search_label,'+
            'category,unit,description,image_url,'+
            'sales_price,cost_price,is_active'
        )
        .eq('company_id',s.company)
        .eq('is_active',true)
        .eq('barcode',code)
        .limit(1)
        .then(function(r){

            if(r.error){
                RW_UI.toast(
                    r.error.message||
                    'تعذر البحث عن الصنف',
                    'error'
                );
                return;
            }

            if(r.data&&r.data[0]){
                s.add(r.data[0].item_code);
                return;
            }

            return supabase
                .from('items')
                .select(
                    'id,item_code,barcode,name,search_label,'+
                    'category,unit,description,image_url,'+
                    'sales_price,cost_price,is_active'
                )
                .eq('company_id',s.company)
                .eq('is_active',true)
                .eq('item_code',code)
                .limit(1);
        })
        .then(function(r){

            if(!r){
                return;
            }

            if(r.error){
                RW_UI.toast(
                    r.error.message||
                    'تعذر البحث عن الصنف',
                    'error'
                );
                return;
            }

            if(r.data&&r.data[0]){
                s.add(r.data[0].item_code);
                return;
            }

            RW_UI.toast(
                'الصنف غير موجود: '+code,
                'warning'
            );
        });
},

**لا تغيّر أي جزء آخر في vouchers.html لهذا closure.**

## 17. لماذا لم نغير to_type إلى User
التحقيق أثبت أن تغيير:
DirectSale to_type = Vehicle
إلى:
DirectSale to_type = User

سيكسر Physical Location contract للمخزون المحمول.

الحل الصحيح هو:
Vehicle/mobile branch = physical stock endpoint
custodian_user_id = accountable representative

وهذا هو الموجود في Production بالفعل.

## 18. لماذا لم ننشئ Edge Function
المشروع بلغ حد عدد/تكلفة Edge Functions.
الحل المستخدم:
- reuse existing Edge Functions.
- current create-stock-voucher.
- current send-stock-voucher.
- current receive-stock-voucher.
- existing RPC layer.
- inventory_control as authenticated capability.

لا يوجد Edge Function جديد في هذه الجلسة.

## 19. Production / Deployment status
Production:
- Custodian trigger active.
- DirectSale/DirectReturn shape guarded.
- create_manual_stock_voucher_atomic overload with rep_id + operation_id active.
- send_stock_voucher_atomic active.
- post_manual_stock_voucher_atomic active.
- post_stock_movement central.
- inventory_control updated to expose operation registry.

Edge Functions:
لم تتم إضافة أي Function جديدة.

Van Sales source:
تم إصلاحه commit:
36e521f78c8507e431bb9eb780269612c2d6cbf0

Main PWA:
لم يُلمس.

Vouchers PWA:
لم يُلمس مباشرة.

## 20. Self Audit — PRE-SWEEP
Business Understanding: Confirmed for current voucher/van custody contract.
Architecture Understanding: Confirmed.
Database Understanding: Confirmed.
Historical Understanding: Confirmed from current reports + historical voucher architecture + current code.
Production Understanding: Confirmed by direct SQL inspection.
Current Understanding: Confirmed from latest Git blobs.
Execution Confidence: High for implemented SQL + Van Sales source fixes; browser-level confidence intentionally not marked complete.

Confirmed facts:
- custodian exists in current Production.
- vehicle driver relationship is enforced.
- current Vouchers source displays custodian.
- Van Sales current source had four concrete defects and they were corrected.
- inventory_control now exposes stock_voucher_operations.
- transactional E2E completed and was rolled back.
- no new Edge Function created.
- Production final snapshot equals pre-test data counts.

Unknowns:
- Browser E2E against the deployed frontend URL.
- Real authenticated multi-device network retry behavior in a browser.
- Any deployment platform caching/cutover specific to the frontend host.

Conflicts:
- Reports before the last two Mother commits contained older blob/HEAD references. Current Git was treated as authoritative.
- Historical reports mentioning old Vouchers parser defects were not reapplied.

Unverified claims:
- No 100% browser closure claim is made.

## 21. Self Audit — FINAL
What I Proved:
- Production custodian contract.
- Physical movement centralization for the reviewed writer set.
- Current Vouchers source already contains custodian UI closure.
- Van Sales defects were reproduced from source structure and corrected.
- Production RPC audit path now exposes operation registry.
- Transactional CREATE/SEND/RETURN/RECEIVE workflow is coherent.
- Production test data was rolled back successfully.
- No new Edge Function was needed.

What I Did Not Prove:
- Browser E2E on the deployed frontend.
- Full field execution across all real devices/connection states.

What I Fixed:
- Van Sales email operation identity scope.
- Van Sales company-scoped synchronization.
- Van Sales offline startup path.
- Van Sales stale local inventory update after count.
- VOUCHER_AUDIT operation registry visibility.

What I Initially Missed:
- The Van Sales defects were outside the previously closed Custodian Production contract and required a separate source-level closure.

What Could Still Be Wrong:
- Frontend deployment/cache may differ from Git HEAD until cutover.
- Owner must apply V-01/V-02 to vouchers.html and then execute deployed browser E2E.

Final Closure Status:
**VOUCHER CUSTODY PRODUCTION = CLOSED**
**VAN SALES SOURCE CLOSURE = CLOSED**
**PHYSICAL STOCK CENTRALIZATION FOR REVIEWED PATHS = CLOSED**
**VOUCHER UI COMPANY-SCOPE PATCH = OWNER ACTION REQUIRED**
**BROWSER E2E = OPEN**

## 22. إرشادات الجلسة التالية
ابدأ دائمًا بهذه السلسلة:
1. اقرأ آخر section في CURRENT_STATE.
2. تحقق من System HEAD + parent.
3. تحقق من Mother HEAD + parent.
4. أعد جلب vouchers.html وvan-sales.html ولا تستخدم blob قديم.
5. تحقق أن V-01 وV-02 فقط هما patchان غير مطبقين.
6. لا تلمس main.html.
7. لا تعيد custodian migration.
8. لا تنشئ Edge Function جديدة.
9. طابق Production قبل أي نسبة أو closure statement.
10. بعد Owner cutover نفذ Browser E2E.
11. أعد snapshot Production في نفس لحظة التقرير.
12. إذا اختلف Git عن deployed frontend، فالحالة تكون Deployment Drift وليست Production/Source closure.

## 23. المصادر التاريخية والتنفيذية
Governance:
doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md

Latest prior closure:
doc/Draft/Reprots/Report286_WAREHOUSE_VOUCHERS_CUSTODIAN_FORENSIC_CLOSURE_20260921.md

Historical voucher architecture:
https://github.com/papamohammed77-glitch/rawaie-erp-review/blob/main/Architecture/%D8%A7%D9%84%D8%A3%D8%B0%D9%88%D9%86%D8%A7%D8%AA%20%D8%A7%D9%84%D9%85%D8%AE%D8%B2%D9%86%D9%8A%D8%A9%20%D8%A7%D9%84%D9%8A%D8%AF%D9%88%D9%8A%D8%A9.md

Vouchers source:
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/vouchers.html

Van Sales source:
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/sales/van-sales.html

System repository:
https://github.com/papamohammed77-glitch/rawaie-erp-New

End of Report287.
