# Report359 — تحقيق جنائي وإغلاق عقد Master Assignment في الأذونات المخزنية

**التاريخ:** 2026-09-28  
**النطاق:** \`erp-frontend/companies/company-1/warehouse/vouchers.html\`  
**حالة الإغلاق:** Backend/DB مغلقان؛ مصدر واجهة DirectReturn يحتاج 4 ترقيعات جراحية من المالك؛ لا يوجد تغيير Production إضافي مطلوب.

## 1. نقطة الاستكمال

تم الاستكمال من آخر نقطة مثبتة، مع استخدام التقارير كمرجع تاريخي فقط، والتحقق من:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

تمت مراجعة:
- \`MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md\` بالكامل حتى EOF.
- \`CURRENT_STATE.md\`.
- Report356 / Report357 / Report358.
- \`Current/PWA/main.html\`.
- \`companies/company-1/warehouse/vouchers.html\`.
- \`companies/company-1/sales/van-sales.html\`.
- Production Supabase والـRPCs الحالية.
- أحدث commits والـparent.
- GitHub Actions evidence.

## 2. Current Git

### النظام الأم
Repository: \`papamohammed77-glitch/rawaie-erp-New\`  
HEAD: \`e5d0a760bc60345458ad6a261a9094072d48133d\`  
Parent: \`57ba850b16826fca0361757d781f3b796d8eb0cf\`

### التطبيقات
Repository: \`papamohammed77-glitch/erp-frontend\`  
Current HEAD: \`56fee06ac0145faffbc4f71d3d6031fcd3b46f87\`  
Parent: \`31a255c6bac2e23f8ceb74734e66010039e9938c\`

Current \`vouchers.html\` blob:
\`e24eddf27d657a9baa6713b2c26b571c768cb28e\`

السلسلة التي تخص التطبيق قبل إصلاح test harness:
- \`826cfb658f7a35d9e55bb00b7653d447c047a1cf\`
- Parent: \`f28cbe21abe2dfc8d03d02fb0491cc984a273c13\`

## 3. الخلاصة الجنائية

Production يستخدم مصدر حقيقة واحدًا لعلاقة:
**Sales Rep ⇄ Vehicle**

وهو:
\`public.fleet_vehicle_sales_rep_assignments\`

لكن \`vouchers.html\` يحتوي على مواضع ما زالت تستخدم:
\`vehicles.driver_id\`

كمصدر أساسي.

Production يثبت:

### CHV-2025-01
- vehicle_id: \`69b08188-60ee-43af-9644-e1626a85bfa0\`
- rep: \`111b0730-a977-4d11-bcd0-2427b178a9e5\`
- email: \`vansales@rawaea.com\`
- driver_id: NULL
- mobile_branch_id: \`2fffcf58-be04-4599-a289-8791362398ff\`

### VHL-0422
- vehicle_id: \`7e58a39d-e1f4-435f-a6f7-fa625a234333\`
- rep: \`cb086d71-ba61-4392-8d3d-c4bec02ec913\`
- email: \`vansales2@rawaea.com\`
- driver_id: NULL
- mobile_branch_id: \`9a8a10b5-8d46-4e64-a33f-5ab46af542ac\`

إذن أي UI يبحث عن:
\`v.driver_id === s.user.id\`
سيعيد قائمة خاطئة لمندوب البيع المباشر.

## 4. ما تم إغلاقه بالفعل ولا يعاد فتحه

Commit 826 سبق أن أصلح:
- DirectReturn rep selection.
- rep/vehicle master mapping في مسارات الاختيار.
- submit assignment-first مع legacy fallback.
- جعل DirectReturn route قابلًا للاختيار.
- ربط Master Assignment داخل \`pickArr('wsRep')\`.

Report357 الخاص بمسودة DirectSale مغلق.
Transfer backend مغلق.
SupplierReturn backend/contract مغلق.
DirectReturn backend مغلق.

لا إعادة إصلاح لهذه البنود.

## 5. PATCH DR-UI-01 — مصدر مركبة DirectReturn للمندوب

**الملف:** \`companies/company-1/warehouse/vouchers.html\`  
**الدالة:** \`pickArr:function(key)\`  
**الموضع الحالي:** حوالي السطر 3498.

ابحث عن هذا العنصر حرفيًا واحذفه بالكامل:

\`\`\`
return (
    s.refs.vehicles||[]
)
.filter(function(v){

    return (
        v.status==='Active' &&
        v.mobile_stock_enabled!==false &&
        v.driver_id===
            s.user.id &&
        !!s.vehicleBranch(v)
    );
});
\`\`\`

استبدله بالكامل بـ:

\`\`\`
var currentUserId=
    String(
        (s.user||{}).id||
        ''
    );

var vehicleRepMap=
    s.refs.vehicleRepMap||
    Object.create(null);

return (
    s.refs.vehicles||[]
)
.filter(function(v){

    var linkedRepId=
        vehicleRepMap[
            String(v.id)
        ]||
        v.driver_id||
        '';

    return (
        v.status==='Active' &&
        v.mobile_stock_enabled!==false &&
        String(linkedRepId)===
            currentUserId &&
        !!s.vehicleBranch(v)
    );
});
\`\`\`

## 6. PATCH DR-UI-02 — fallback عند اختيار المندوب

**الدالة:** \`pickSelect:function(key,id)\`  
**الموضع:** حوالي السطر 4278.

احذف العنصر:

\`\`\`
var mappedVehicleId=
    s.refs.repVehicleMap[
        String(x.id)
    ]||
    '';

var mappedVehicle=
    (s.refs.vehicles||[])
        .find(function(v){
            return String(v.id)===
                String(mappedVehicleId);
        });
\`\`\`

واستبدله بـ:

\`\`\`
var mappedVehicleId=
    s.refs.repVehicleMap[
        String(x.id)
    ]||
    '';

var mappedVehicle=
    (s.refs.vehicles||[])
        .find(function(v){
            return String(v.id)===
                String(mappedVehicleId);
        });

if(!mappedVehicle){

    mappedVehicle=
        (s.refs.vehicles||[])
            .find(function(v){

                return (
                    String(
                        v.driver_id||
                        ''
                    )===
                    String(x.id) &&

                    v.status==='Active' &&
                    v.mobile_stock_enabled!==false &&
                    !!s.vehicleBranch(v)
                );
            })||
        null;
}
\`\`\`

## 7. PATCH DR-UI-03A — Smart Search

**الدالة:** \`pickSearch:function(key,q)\`  
**الموضع:** حوالي السطر 3959.

احذف:

\`\`\`
var vehicleRep=
    type==='vehicle' &&
    repById
        ?(
            repById[
                String(
                    x.driver_id||''
                )
            ]||
            null
        )
        :null;
\`\`\`

واستبدل:

\`\`\`
var vehicleRep=
    type==='vehicle' &&
    repById
        ?(
            repById[
                String(
                    (
                        s.refs.vehicleRepMap &&
                        s.refs.vehicleRepMap[
                            String(x.id)
                        ]
                    )||
                    x.driver_id||
                    ''
                )
            ]||
            null
        )
        :null;
\`\`\`

## 8. PATCH DR-UI-03B — نتيجة البحث

في نفس الدالة، الموضع الثاني المطابق حوالي السطر 4059.

احذف:

\`\`\`
vehicleRep=
    type==='vehicle' &&
    repById
        ?(
            repById[
                String(
                    x.driver_id||''
                )
            ]||
            null
        )
        :null,
\`\`\`

واستبدل:

\`\`\`
vehicleRep=
    type==='vehicle' &&
    repById
        ?(
            repById[
                String(
                    (
                        s.refs.vehicleRepMap &&
                        s.refs.vehicleRepMap[
                            String(x.id)
                        ]
                    )||
                    x.driver_id||
                    ''
                )
            ]||
            null
        )
        :null,
\`\`\`

## 9. PATCH DR-UI-04 — إعادة فتح Draft DirectReturn

**الدالة:** \`editVoucher:function(code)\`  
**الموضع:** حوالي السطر 2840.

احذف:

\`\`\`
var rr=
    vv&&
    (s.refs.reps||[])
    .find(function(x){
        return x.id===vv.driver_id;
    });
\`\`\`

واستبدل:

\`\`\`
var linkedRepId=
    v.custodian_user_id||
    (
        s.refs.vehicleRepMap &&
        s.refs.vehicleRepMap[
            String(v.from_id)
        ]
    )||
    (vv&&vv.driver_id)||
    '';

var rr=
    (s.refs.reps||[])
    .find(function(x){
        return String(x.id)===
            String(linkedRepId);
    })||
    null;
\`\`\`

## 10. لماذا هذه الأربعة فقط

هذه الترقيعات تكمل نفس العقد الموجود بالفعل:
**Master Assignment → Vehicle → Rep → Mobile Branch**

ولا تغير:
- الـRPC.
- الـEdge Functions.
- Physical movement.
- Custody.
- Accounting.
- Main shell.
- order/runsheet lifecycle.

## 11. Production Backend — إثبات الحالة

الـRPC الحالي:
\`create_manual_stock_voucher_atomic\`

وCore:
\`create_manual_stock_voucher_atomic_core_12_20260828\`

يدعمان بالفعل:
- DirectSale assignment-first.
- DirectReturn assignment-first.
- legacy driver fallback.
- company isolation.
- active mobile vehicle.
- active direct-sales rep.
- branch validation.
- operation_id idempotency.

لذلك لا يوجد سبب لإنشاء RPC أو Edge Function جديدة.

## 12. Main.html

تم فتح المصدر الحالي \`Current/PWA/main.html\`.

الحالة المؤكدة:
- Owner/Wildcard contract موجود.
- \`RW_Permissions_check\` يدعم \`*\`.
- \`vouchers:view\` مربوط بالأذونات.
- \`stock_vouchers\` delegated إلى \`vouchers.html\`.
- Physical stock core لا يزال مملوكًا لـ\`post_stock_movement\`.

**لا يوجد إصلاح مطلوب في main.html.**
ولم يتم تعديله.

## 13. Van Sales

تمت مراجعة:
\`companies/company-1/sales/van-sales.html\`

الدور:
- تطبيق تشغيلي مستقل للبيع المباشر.
- resolver للمركبة/المخزن المتنقل.
- يعتمد على Master Assignment.
- فواتير البيع تمر عبر \`save-sales-invoice\`.
- الحركة المخزنية والمالية مرتبطة بالدورة المركزية.
- لا ينشئ manual stock vouchers.

لا يوجد defect مثبت يستوجب تعديله.

## 14. دورة الأنواع الأربعة

### Transfer
Branch → Branch

Create:
Draft

Send:
خصم من المصدر

Receive:
إضافة للوجهة

وReceive مقيد بمسؤول الاستلام الصحيح.

### DirectSale
Branch → Vehicle

Send ينفذ الحركة الفعلية، وتثبت custody/driver ledger حسب العقد الحالي.

### DirectReturn
Vehicle → Branch

Send:
خصم من مخزون المركبة.

Receive:
إضافة لفرع الاستلام.

وهي النقطة الوحيدة التي تحتاج owner patch على مستوى UI الآن.

### SupplierReturn
Branch → Supplier

Standalone warehouse operation.
Supplier master هو الوجهة.
Contract guard موجود في Production.

## 15. الأثر المالي والمخزني

Internal transfer لا يمثل بيعًا.
DirectReturn ليس Sales Invoice.
SupplierReturn لا يعتمد على وجود PO كي تمنع العملية المادية إذا كان العقد يسمح بمرتجع مستقل.

هذا متسق مع ممارسات الأنظمة المرجعية:
- Odoo يميز internal stock moves عن inbound/outbound. https://www.odoo.com/documentation/20.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/operation_type.html
- Dynamics يدعم Ship/Receive وIn-Transit في Transfer Orders. https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-transfer-between-locations
- SAP يدعم one-step/two-step stock transfer. https://help.sap.com/docs/SAP_ERP/75c4b203fca64320b998cc04e2eb1468/719bc7536e8e2a4be10000000a174cb4.html
- دفترة يعرض source/destination والكمية والرصيد قبل/بعد وتقارير الحركة. https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
- Manager.io يستخدم inventory locations والتحويل بينها. https://www2.manager.io/guides/10677

## 16. اختبارات Production

تم استخدام \`BEGIN ... ROLLBACK\` في الاختبارات الجديدة حتى لا تترك QA artifacts.

### DirectReturn E2E
Create → Send → Receive
PASS

وأثبت:
- movement.
- custody ledger.
- rollback بدون residue.

### DirectReturn invalid pairing
Vehicle لا تتبع Rep المحدد.
الـRPC رفض:
\`المركبة المصدر لا تتبع مندوب البيع المباشر المحدد\`

وهذا guard صحيح.

### Transfer
Create → Send
PASS
Movement = 1
Rollback.

### DirectSale
Create → Send
PASS
Movement = 1
Custody ledger = true
Rollback.

### SupplierReturn
تم إثبات وجود Contract Guard في Production.
لا تم إنشاء QA data ثابتة.

## 17. QA Data

Production يحتوي على QA records قديمة تم ترحيلها بالفعل إلى:
- inventory_log
- driver_ledger
- journal_entries
- supplier_ledger

لذلك لم يتم حذفها قسرًا لأن ذلك سيكسر Audit/Financial/Stock integrity.

لا توجد Manual Draft QA جديدة متروكة من الاختبارات الجديدة.

## 18. Deployment / Browser Evidence

تم اكتشاف أن validator السابق كان يفترض:
\`<script>\`

بينما الصفحة تستخدم script attributes.

تم إصلاح **workflow فقط**:
\`.github/workflows/warehouse_vouchers_browser_e2e_20260920.yml\`

آخر workflow commit:
\`56fee06ac0145faffbc4f71d3d6031fcd3b46f87\`

Embedded Node validator:
**Syntax PASS**

Run الحالي:
\`36483037124\`
وكان قيد التنفيذ عند آخر قراءة.

لذلك لا يتم إعلان Browser E2E PASS قبل ظهور completed/success.

## 19. فجوات التنافسية المكتشفة، خارج أزمة DirectReturn

لا تدخل في patch الحالي:

- stock before/after per line بشكل أوضح.
- transit visibility للتحويل ثنائي المرحلة.
- barcode-first entry.
- attachments/evidence.
- richer reason analytics.
- SLA aging.
- exception queues.
- serial/lot/expiry عندما يكون tracking فعالًا.

هذه تحسينات مستقبلية، وليست مبررًا لتغيير البناء الحالي أثناء إغلاق عقد Master Assignment.

## 20. ما تم ولم يتم

### تم التنفيذ مباشرة
- إصلاح validator الخاص بـBrowser E2E.
- إثبات Production contracts.
- إثبات E2E عبر transactions قابلة للـrollback.
- إنشاء هذا التقرير.

### لم يتم
- تعديل \`main.html\`.
- تعديل \`vouchers.html\`.
- تعديل \`van-sales.html\`.
- إنشاء Edge Function.
- إنشاء RPC.
- إنشاء جدول.
- حذف QA history المرحّل.

## 21. حالة الإغلاق

| النقطة | الحالة |
|---|---|
| Main authorization | CLOSED |
| Transfer backend | CLOSED |
| DirectSale backend | CLOSED |
| SupplierReturn backend | CLOSED |
| DirectReturn backend | CLOSED |
| DirectReturn source UI | OPEN — DR-UI-01..04 |
| Browser validator source | FIXED |
| Browser E2E | PENDING runtime evidence |
| New Production infrastructure | NOT REQUIRED |

## 22. ترتيب الجلسة القادمة

1. ابدأ من \`erp-frontend main\` بعد آخر workflow commit.
2. افحص Run \`36483037124\` أو أحدث Run لهذا workflow.
3. لا تعيد تنفيذ ما ثبت إغلاقه.
4. افتح \`vouchers.html\`.
5. طبق DR-UI-01.
6. طبق DR-UI-02.
7. طبق DR-UI-03A وDR-UI-03B.
8. طبق DR-UI-04.
9. syntax gate.
10. Browser E2E.
11. Login بـ\`vansales2@rawaea.com\` والتأكد أن \`VHL-0422\` تظهر كمركبة مصدر.
12. فتح Draft DirectReturn والتأكد من بقاء \`custodian_user_id\`.
13. Smart Search باسم المندوب.
14. Create → Send → Receive.
15. Negative test لمركبة غير مرتبطة بالمندوب.
16. لا تغلق النقطة إلا بعد اكتمال evidence ثم حدّث CURRENT_STATE.

## Self Audit

- التقارير السابقة عوملت كمرجع تاريخي.
- لم يتم اعتبار test harness errors عيوبًا في Production.
- تم منع حذف transaction history.
- لم تتم إعادة إصلاح العناصر المغلقة.
- لم يتم إنشاء بنية جديدة رغم Function/Spend Cap.
- لم يتم لمس main.html أو vouchers.html أو van-sales.html.
- لا يجوز اعتبار Browser E2E ناجحًا قبل completed/success evidence.

**قاعدة البداية: لا تبدأ من التقرير؛ ابدأ من Git/Source/Production/Database/Deployment الحالي، ثم تحقق من العقد قبل أي إصلاح.**
