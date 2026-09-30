# تقرير تدقيق جنائي — VAN SALES / التكامل والعهدة والتحصيل
## Report 374 — 2026-09-30

## SELF-AUDIT — PRE-CHECK
Business Understanding: 99/100
Architecture Understanding: 99/100
Database Understanding: 99/100
Historical Understanding: 98/100
Production Understanding: 99/100
Current Understanding: 99/100
Execution Confidence: 97/100

Confirmed Facts: 19+
Unknowns: 2
Conflicts: 0 material
Unverified Claims: 1

Historical: OPENED
Original: OPENED
Current: OPENED
Production: OPENED
Schema: CHECKED
Triggers: CHECKED
Dependencies: CHECKED
Consumers: CHECKED

## CURRENT SOURCE — VERIFIED
Frontend repository: papamohammed77-glitch/erp-frontend
File: companies/company-1/sales/van-sales.html
Current main SHA: e696a82faaacc956301a36a48c15723685d9ce70
Current file: 3048 lines / 143255 characters
Latest frontend commit: df0137d062a990cfccf7acbdfd53bc2af34ba610
Parent: 8a972680d3a34ae61cb2d12811d14283c6d99361

Protected:
- van-sales.html
- main.html
- warehouse/vouchers.html

لم يتم تعديل الملفات المحمية.

## PRODUCTION — VERIFIED
setup-van-branch: v5 ACTIVE
save-sales-invoice: v13 ACTIVE
save-receipt-voucher: v8 ACTIVE
post_van_sales_collection_atomic: موجود وSECURITY DEFINER وذري عبر erp_operation_registry

Production data:
- vansales2@rawaea.com → VHL-0422 → VAN-VHL-0422
- vansales@rawaea.com → CHV-2025-01 → VAN-CHV-2025-01
- كلا الحسابين Direct Sales Rep وحالتهما Active.
- fleet_vehicle_sales_rep_assignments يحتوي Primary Assignment فعليًا.
- customer_assignments حاليًا = 0.
- Van Sales orders حاليًا = 0.
- driver_ledger لـvansales2 حاليًا = 0.
- VAN-VHL-0422 يحتوي 17 Stock Master rows، وإجمالي qty = 0 وallocated_qty = 0.

## WAREHOUSE VOUCHERS ↔ VAN SALES
تمت مطابقة المصدر الفعلي للهوية:

fleet_vehicle_sales_rep_assignments
→ Sales Rep
→ Vehicle
→ mobile_branch_id / VAN-{vehicle_code}

vouchers.html يستخدم هذا المصدر عبر fleet_query وvehicleBranch وsyncDirectSaleVehicleWithRep.
van-sales.html يستخدم setup-van-branch، وProduction v5 يتحقق من نفس Master Assignment ويربط المركبة بالفرع المتنقل canonical.

الحكم:
Vehicle/Branch identity integration = VERIFIED

## CUSTODY
الإصلاحات السابقة الخاصة بالعهدة موجودة بالفعل في Current:
- loadHomeStockSummary يقرأ stock_branches.qty حيًا.
- _loadVehicleStock يقرأ نفس المصدر الحي.
- القيمة التجارية تحسب على كل الصفوف الموجبة.
- الصفوف صفرية الكمية لا تظهر كعهدة.
- enterApp يوقف العرض عند فشل syncDown.

هذا متسق مع فكرة المخزون في موقع/مخزن متنقل. Odoo يفرق بين الحركات الداخلية والمخزون في المواقع، وDaftra يدعم تخصيص مخزون لموظف مع مستودع ومسؤولية وصلاحيات، وSAP Direct Store Delivery يعامل Van Sales كعملية مبيعات ولوجستيات مرتبطة بالمركبة والمندوب.

## CLOSURE UNIT الحالية: collectPayment
الحالة = OPEN

الدالة: collectPayment
الأسطر: 1365–1589

التحقيق أثبت أن persistence لهوية العملية موجود حاليًا، لكن cleanup بعد نجاح العملية غير موجود.

المشكلة:
بعد نجاح التحصيل، تبقى قيمة RW_VAN_COLLECTION_PENDING في localStorage.

هذا قد يجعل تحصيلًا جديدًا في نفس اليوم لنفس العميل وبنفس المبلغ يعيد operation_id قديمًا، وبالتالي يُرفض كduplicate رغم أنه عملية مالية جديدة.

## SURGICAL OWNER PATCH
لا تحذف بلوك operationId الحالي؛ هو صحيح.

العنصر المطلوب إضافته فقط داخل success continuation في collectPayment، قبل RW_UI.hideLoader() مباشرة، في المنطقة الحالية حول السطر 1555–1576:

try {
    localStorage.removeItem(operationStorageKey);
} catch (e) {}

RW_UI.hideLoader();

لا تعديل لأي جزء آخر من collectPayment في هذه Closure Unit.

## BACKEND
لا توجد حاجة إلى Production DB/Edge mutation لهذه الوحدة.

Production backend يثبت:
- save-receipt-voucher v8
- post_van_sales_collection_atomic
- erp_operation_registry idempotency
- customer assignment validation
- treasury/account validation
- atomic cash receipt
- customer ledger posting
- driver ledger posting

## OPEN NEXT UNITS
بعد collectPayment فقط:
1. loadMyCustomers
2. loadCustomerPatterns
3. loadKPIs
4. loadHomeSalesSummary
5. loadMyInvoices
6. loadHomeBalanceSummary / loadBalanceDetail
7. showCustomerDetail / repeatOrder
8. initiateEndOfDay

لا يجوز خلط هذه الوحدات مع collectPayment.

## FINAL STATUS
Van custody integration = VERIFIED
Warehouse voucher integration = VERIFIED
Vehicle assignment integration = VERIFIED
Production collection backend = VERIFIED
collectPayment = INCOMPLETE
Frontend Van Sales = NOT 100% CLOSED

## SELF-AUDIT — FINAL
What I Proved:
Current source الحقيقي، Production vehicle/master assignments، canonical VAN branches، collection backend، والتكامل مع vouchers.

What I Did Not Prove:
Browser E2E بعد patch المالك، لأن van-sales.html ملف محمي ولم أعدله.

What I Fixed:
لا تغيير في الملف المحمي ولا في Production backend؛ تم تحديد العيب الحالي والتعديل الجراحي الدقيق.

What I Initially Missed:
cleanup بعد نجاح التحصيل ما زال مفقودًا رغم وجود persistence.

What Could Still Be Wrong:
الوحدات التالية ما زالت مفتوحة، وأي واحدة منها لا تُغلق قبل فحصها المستقل.

Final Confidence: 97/100
Final Closure Status: INCOMPLETE — collectPayment surgical patch + browser E2E pending.
