# Report310 — التحقيق الجنائي الحالي لإغلاق Regression المركبات في تطبيق الأذونات المخزنية
## RAWAEA ERP — 2026-09-22

## 1. نطاق الجلسة
Closure Unit الوحيد:
Warehouse → Inventory Management → Stock Vouchers → Vehicle Smart Search

الهدف:
- إصلاح سبب اختفاء البحث الذكي عن المركبة في DirectSale وDirectReturn.
- إصلاح خطأ JavaScript الحالي: vouchers:1740 Uncaught SyntaxError: missing ) after argument list.
- عدم إعادة فتح الإصلاحات السابقة المغلقة.
- عدم لمس main.html أو vouchers.html بواسطة المساعد أو van-sales.html.
- عدم إنشاء Edge Function جديدة.
- الحفاظ على Production architecture الحالية ما لم يثبت احتياج حقيقي.

الحالة في نهاية هذه الدورة:
ROOT CAUSE PROVEN + OWNER SURGICAL PATCH READY + PRODUCTION CONTRACT VERIFIED + STATIC E2E PASS + BROWSER E2E OPEN

## 2. المصادر التي تم تثبيتها
تمت قراءة MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP من بدايته حتى قسم END OF MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS.
تمت مراجعة Report308 وReport309 وCURRENT_STATE والـcommits والـparents ومصدر vouchers الحالي وProduction.

القواعد المطبقة:
- Report ليس Current Truth.
- Current Truth = Current Git + Current Source + Current Production + Current Database + Current Deployment Evidence.
- لا يوجد Claim بلا Evidence.
- لا تعديل قبل فهم Historical Contract.
- كل Defect يمر بمسار إثبات ثم Root Cause ثم Surgical Fix ثم Test ثم Production Verification.
- ملفات المالك Current/PWA/main1..main11 يتم تعديلها بواسطة المالك؛ المساعد يعطي Owner Changeset كاملًا.
- لا 100% Closure بلا Runtime/Browser evidence.

## 3. Current Git
### System repository
Repository: papamohammed77-glitch/rawaie-erp-New
Current HEAD: 6b6a37ab3bd6473d14d2c13e3ef89d279d1eeaa2
Parent: 79c43c6582d697c1282bf02d5e804572384f9546
HEAD message: state: replace stale checkpoint with Report309 authoritative current state
Parent message: report: warehouse voucher vehicle picker forensic closure

### Frontend repository
Repository: papamohammed77-glitch/erp-frontend
Current HEAD: 78ecba3fd0e1adfa3af0249dc6bf1b7d80984c40
Parent: bf88f28e33b789b4822f2dd2b7ec025827a8c54a
Current vouchers.html blob: 712f717c818819c5d5d9afba843465c7ae892672

## 4. Git Forensic Chain
### bf88f28e...
Message: Refactor status checks for vouchers

هذا commit عدّل App.pickArr في موضع المركبات.
في DirectReturn:
- أُدخل منطق جديد للفرع التشغيلي للمستخدم/المندوب.
- أُزيل إغلاق filter الخاص بالمركبات.
- أصبح فرع DirectReturn غير مغلق بنيويًا.

في DirectSale:
- أزيل شرط s.allowedBranch(s.user,vb).
- بقيت صلاحية source operational branch وربط المندوب بالمركبة.
- Current DirectSale block أصبح في الاتجاه الصحيح، ولذلك لا يعاد تعديله الآن.

### 78ecba3...
Message: Remove unnecessary closing brace in vouchers.html
Parent: bf88f28...

هذا commit حذف قوسًا من الموضع الخطأ ولم يُعد إغلاق filter أو فرع DirectReturn.

## 5. السبب الجذري النهائي
السبب البرمجي المباشر:
App.pickArr في DirectReturn يحتوي على filter غير مغلق ثم فرع DirectReturn غير مغلق؛ لذلك parser يتوقف عند:
vouchers:1740 Uncaught SyntaxError: missing ) after argument list

السبب الوظيفي للمركبة:
تم الخلط بين:
1. Operational Branch Authorization للمستخدم.
2. Mobile Stock Custody Branch للمركبة.

Mobile branch هي هوية مخزن عهدة المركبة، وليست تلقائيًا branch تشغيلية يجب أن تكون ضمن allowed_branch_ids للمستخدم.

عندما أصبح candidate generation معتمدًا على صلاحية المستخدم على mobile branch اختفت المركبات قبل pickSearch.

## 6. Current Source — العنصر المعيب
الملف:
companies/company-1/warehouse/vouchers.html

Current SHA:
712f717c818819c5d5d9afba843465c7ae892672

Function:
App.pickArr(key)

الموضع:
حوالي الأسطر 1720–1742.

Search anchor:
return (s.refs.vehicles||[]).filter(function(v){

داخل:
if(key==='wsFrom'){
ثم:
if(s.type==='DirectReturn'){

العنصر المعيب ينتهي حاليًا خطأ قبل:
if(key==='wsRep'){

## 7. Owner Surgical Patch
المالك لا يحذف App.pickArr كاملة.

ابحث تحديدًا داخل:
if(s.type==='DirectReturn'){

عن أول:
return (s.refs.vehicles||[]).filter(function(v){

احذف هذا العنصر بالكامل حتى قبل:
if(key==='wsRep'){

والبديل الكامل هو:

return (s.refs.vehicles||[]).filter(function(v){
    var vb=s.vehicleBranch(v),
        rep=(s.refs.reps||[]).find(function(r){
            return r.id===v.driver_id;
        });

    return v.status==='Active' &&
           !!vb &&
           (
               !rep ||
               (s.refs.branches||[]).some(function(branch){
                   return s.allowedBranch(s.user,branch) &&
                          s.allowedBranch(rep,branch);
               })
           );
});
}

هذا هو التعديل الجراحي الوحيد المطلوب في vouchers.html في هذه الدورة.

## 8. لا تعدل العناصر التالية
لا تعدل:
- vehicleBranch()
- pickSearch()
- pickSelect()
- norm()
- loadRefs()
- submit()
- DirectSale vehicle block
- main.html
- van-sales.html

DirectSale لا يعاد إصلاحه لأن Current Source يحتوي بالفعل على الإصلاح الوظيفي الصحيح الذي أزال الاعتماد على صلاحية mobile branch للمستخدم.

## 9. Production Reality — Fresh Snapshot
Production UTC:
2026-09-22 18:34:13.135197+00

Counters:
- stock_vouchers = 25
- stock_voucher_details = 27
- inventory_log = 26
- audit_log = 2109
- vehicles = 2
- active company branches = 4

## 10. Persistent QA
لم يتم إنشاء Fixtures إضافية لأن بيانات QA المطلوبة موجودة بالفعل.

Vehicle:
VCH-QA-260922
license_plate: س م ج 26922
status: Active
mobile_stock_enabled: true
mobile_branch_code: VAN-VCH-QA-260922
driver: vansales@rawaea.com
company: 00000000-0000-0000-0000-000000000001

QA voucher IN-24:
DirectSale
Draft
Branch → Vehicle
reference: QA-SMART-VEHICLE-DS-260922

QA voucher IN-25:
DirectReturn
Draft
Vehicle → Branch
reference: QA-SMART-VEHICLE-DR-260922

QA inventory movements = 0

تم الاحتفاظ بهذه البيانات ولم يتم حذفها أو إعادة إنشائها.

## 11. Production Backend
Current create-stock-voucher deployment:
v10
verify_jwt = true

ويدعم:
- company resolution من المستخدم المصادق.
- rep_id.
- operation_id.
- 12-argument create_manual_stock_voucher_atomic.
- DirectSale/DirectReturn server-side guards.

Production current backend لا يحتاج Migration أو Edge Function جديدة لهذه regression.

لم يتم:
- إنشاء Edge Function.
- تغيير RLS.
- تغيير users permissions.
- تغيير vehicle contract.
- تغيير post_stock_movement.
- تغيير create_manual_stock_voucher_atomic.
- تغيير أي Production data.

## 12. Integration
Mother Application:
users + permissions + company + branches + vehicles + representatives + voucher control + reports/monitoring.

Standalone Vouchers:
Transfer + DirectSale + DirectReturn + SupplierReturn + Adjustment/Scrap، للعمليات غير المرتبطة مباشرة بأوردر/رانشيت.

Van Sales:
field sales + customer execution + vehicle mobile stock + mobile/offline workflow.

Architecture:
Mother Control → Voucher Operational Surface → Vehicle Mobile Custody → Van Sales Execution

Order/Runsheet fulfillment remains separate when the movement is order-linked.

## 13. Vehicle Search Contract
pickSearch الحالي يبحث في:
- vehicle_code
- license_plate
- model

norm الحالي تم إصلاحه تاريخيًا.
vehicleBranch الحالي تم إصلاحه تاريخيًا.
pickSelect الحالي يربط المركبة بالمندوب ويحافظ على contract.

إذن لا يوجد سبب لتعديل هذه العناصر.
العطل في candidate generation داخل pickArr.

## 14. Static Forensic Verification
Current malformed structure:
FAIL

Parser:
SyntaxError: missing ) after argument list

Corrected DirectReturn block:
PASS — JavaScript syntax

Deterministic vehicle E2E:
- DirectReturn candidates = 1
- DirectReturn vehicle code search = 1
- DirectReturn Arabic plate search = 1
- DirectReturn selection = PASS
- DirectSale candidates = 1
- DirectSale vehicle code search = 1
- DirectSale Arabic plate search = 1

## 15. Browser E2E
Authenticated Browser E2E:
OPEN

لم يتم تحويل static/deterministic PASS إلى Browser PASS.

بعد تطبيق Owner patch يجب اختبار:
- DirectSale vehicle code
- DirectSale Arabic plate
- DirectReturn vehicle code
- DirectReturn Arabic plate
- vehicle selection
- representative linkage
- branch authorization
- Draft creation
- no movement from Draft

## 16. Tailwind Warning
رسالة:
cdn.tailwindcss.com should not be used in production

ليست Root Cause للـsyntax error ولا للـvehicle candidate disappearance.
لم يتم تعديل Tailwind أو main.html.

## 17. Competitive Review
### Odoo
Odoo 19 يوثق barcode-driven inventory operations، transfers، inventory adjustments، وreal-time processing.
مصادر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html
https://www.odoo.com/documentation/master/applications/inventory_and_mrp/barcode/setup/operation_types.html

### Dynamics 365
يدعم mobile warehouse operations تشمل Inventory Movement وWarehouse Transfer وCycle Count وAdjustment In/Out، مع authorization بحسب warehouse.
المصدر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-mobile-devices-warehouse

### SAP
يفصل بين storage location وtransfer procedures، ويدعم one-step وtwo-step transfer وstock in transfer.
المصادر:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/ad64bd534f22b44ce10000000a174cb4.html
https://help.sap.com/docs/SAP_ERP_SPV/96bf9ad642cf4b26a29595e3d573fb8c/9e64bd534f22b44ce10000000a174cb4.html

### Daftra
يعرض source/destination/notes/quantity وAvailable Before/After في Stock Transfer.
المصدر:
https://docs.daftra.com/en/tutorial/transferring-stock/

### Manager.io
Inventory Transfers تستخدم item + quantity + From + To + reference/description، مع حساب الكميات حسب المواقع.
المصادر:
https://www2.manager.io/guides/10707
https://www2.manager.io/guides/10677

Competitive gaps identified for future independent Closure Units:
- stock before/after visible
- barcode-first voucher execution
- advanced vehicle/rep/branch/date/status filters
- PDF/print
- mobile custody dashboard
- in-transit visibility
- lot/batch/expiry/serial only after explicit business/schema contract

لم يتم إدخال هذه الميزات داخل هذه regression closure.

## 18. Responsibility Matrix
| Area | Current | Action |
|---|---|---|
| Vehicle identity | Verified | No change |
| Mobile custody branch | Verified | No change |
| Vehicle search algorithm | Verified | No change |
| Arabic normalization | Verified | No change |
| DirectSale candidate block | Correct current direction | No change |
| DirectReturn candidate block | Malformed | Owner surgical replacement |
| Voucher backend | Verified | No change |
| Physical Stock Engine | Centralized | No change |
| Mother integration | Verified | No change |
| Van Sales integration | Verified | No change |
| Browser E2E | Open | Owner patch + browser test |

## 19. Execution Result
تم إثبات:
- Governance read to EOF.
- Current system HEAD and parent.
- Current frontend HEAD and parent.
- Current vouchers.html SHA.
- Current Production snapshot.
- Existing QA records and preservation.
- Exact regression commits.
- Exact syntax defect.
- Exact vehicle candidate defect.
- Correct surgical replacement.
- Static compile PASS after replacement.
- Deterministic vehicle E2E PASS.
- Production backend compatibility.
- No need for Production migration.
- No new Edge Function.

لم يتم إثبات:
- authenticated Browser E2E after deployment.

## 20. Closure Status
ROOT CAUSE = CLOSED
PRODUCTION CONTRACT = VERIFIED
SURGICAL PATCH = READY
STATIC E2E = PASS
QA = RETAINED
BROWSER E2E = OPEN
100% CLOSED = NO

## 21. Next Exact Checkpoint
1. Verify current frontend HEAD again.
2. Verify Owner patch was actually applied.
3. Static compile.
4. DirectReturn vehicle code search.
5. DirectReturn Arabic plate search.
6. DirectSale vehicle code search.
7. DirectSale Arabic plate search.
8. Vehicle selection + representative linkage.
9. Branch authorization negative test.
10. Draft creation using current create-stock-voucher.
11. Confirm zero inventory movement for Draft.
12. Authenticated browser E2E.
13. Fresh Production snapshot.
14. Update CURRENT_STATE.
15. Close only after Browser PASS.

## 22. Final Root Cause — end of report
السبب النهائي للخطأ هو أن commit bf88f28e33b789b4822f2dd2b7ec025827a8c54a كسر إغلاق filter وفرع DirectReturn داخل App.pickArr، ثم commit 78ecba3fd0e1adfa3af0249dc6bf1b7d80984c40 حذف قوسًا إضافيًا في الموضع الخطأ؛ فصار JavaScript غير صالح وتوقفت قائمة المركبات قبل أن يصل البحث الذكي إليها. وظيفيًا، كان الخلط بين mobile custody branch وoperational branch authorization هو السبب الذي منع ظهور المركبة عند تشديد Branch Scope.

## 23. Next CTO Instructions
ابدأ من Current Git.
افحص vouchers.html ولا تفترض تطبيق Owner patch.
لا تعيد إصلاح DirectSale أو norm أو vehicleBranch أو pickSearch أو pickSelect.
اختبر Browser بعد تطبيق الجراحة.
لا تعلن 100% قبل Browser PASS.
لا تنشئ Edge Function جديدة.
لا تعدل main.html.
لا تعدل van-sales.html.
لا تبدأ Closure Unit أخرى قبل إغلاق هذه الوحدة.

# END OF REPORT310
