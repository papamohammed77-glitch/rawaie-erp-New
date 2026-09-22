# تقرير 295 — إغلاق جراحي لتبويب الأذونات المخزنية / نقل البحث إلى الكتالوج والتحقق من تكامل المركبة
## التاريخ
2026-09-22

## 1. نطاق المهمة
هذه الجلسة أُعيدت إلى نقطة العمل الخاصة بتطبيق:
`companies/company-1/warehouse/vouchers.html`
مع مراجعة تكامل:
`companies/company-1/sales/van-sales.html`
ودور النظام الأم:
`Current/PWA/main.html`

القيود التنفيذية المحترمة:
- لا تعديل مباشر على `main.html`.
- لا تعديل مباشر على `erp-frontend/.../vouchers.html` من خلال مستودع المصدر.
- لا تعديل على `van-sales.html`.
- لا إنشاء Edge Function جديدة.
- أي إصلاح Production ضروري ينفذ مباشرة في Supabase.
- لا إعادة تنفيذ V-03 إلى V-08 أو أي Closure ثبت إغلاقه.
- لا إعادة بناء التطبيق من الصفر.

## 2. مصادر الحقيقة المستخدمة
### Current System Git
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- HEAD: `a4d263950ecff28f3e3735d4dee13e7676e2d9df`
- Parent: `31e63e105d7d3c028e469285acc956f8f9f6c7ca`
- آخر Commit: `state: correct Report294 checkpoint wording`
- هذا الـcommit وثائقي فقط وصحح وصف `cart controls` في CURRENT_STATE.

### Current Frontend Git
- Repository: `papamohammed77-glitch/erp-frontend`
- HEAD: `0115399c79d5a9fc5ef9c92450cc42381d560f22`
- Parent: `4f4afdc102fe6293d9755a134bc692d8f44bb43f`
- vouchers.html blob: `1bf0382d45bcc06f524eefccc962abe6dcbbe4f3`
- van-sales.html blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`

### Production Supabase
تم أخذ snapshot جديد أثناء هذه الجلسة قبل اعتماد النتيجة:
- companies = 1
- branches = 3
- items = 17
- vehicles = 1
- stock_vouchers = 1
- stock_voucher_operations = 1
- inventory_log = 6
- audit_log = 2034
- orders = 0
- runsheets = 0

الهويات الإنتاجية المثبتة:
- Main branch: `BR-01`
- Direct Sales Rep: `vansales@rawaea.com`
- Warehouse Voucher User: `vouchers@rawaea.com`
- Vehicle: `VEH-TEST-260921`
- Vehicle mobile branch: `VAN-VEH-TEST-260921`
- vehicle.driver_id = direct-sales-rep
- vehicle.mobile_stock_enabled = true
- vehicle.mobile_branch_id = `5372503d-f638-4e7f-808d-bda585825b2f`

## 3. قراءة حاكمة
تمت مراجعة `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS` حتى النهاية، 2606 سطرًا.
القواعد الحاكمة المؤثرة في هذه المهمة:
- REPORT != CURRENT STATE != PRODUCTION.
- CURRENT PRODUCTION + CURRENT SOURCE + CURRENT GIT + CURRENT DEPLOYMENT هي المرجع.
- لا تعديل قبل إعادة بناء العقد التاريخي والسلوك الحالي.
- Business Capability هي وحدة الإغلاق وليس مجرد وجود Function أو Screen.
- لا Commit = Deployment.
- لا Deployment = Runtime Success.
- لا Runtime Success = Production Verified.
- لا يجوز تكرار إصلاح مغلق.
- عند المالك: التسليم الجراحي يكون بالعنصر المحدد، وبالبديل الكامل القابل للاستبدال.
- لا New Edge Function ما دام يمكن استخدام البنية الحالية.

## 4. استرجاع الحالة من التقارير الأخيرة
Report291:
- ثبت عيب Escape في `handleKeys`.
- الإغلاق المطلوب وقتها كان منع الخروج من Workspace عند الكتابة.
- هذه النقطة موجودة الآن بالفعل ولا يُعاد إصلاحها.

Report292:
- V-03: ظهور المركبات بدون اشتراط اختيار المندوب أولاً.
- V-04: Vehicle-first binding.
- V-05: Rep-first search.
- V-06: الاحتفاظ بالمندوب الصالح عند تغيير الفرع مع تصفير المركبة.
- V-07: Safe Escape.
- V-08: Service Worker registration.
- DirectSale permission/RLS Production closure.
هذه النقاط مثبتة في المصدر الحالي ولا تُعاد.

Report293:
- `wsTopPanel` collapse/expand.
- كمية العنصر في Modal.
- Quantity draft controls.
- Cart quantity controls.
هذه الوظائف موجودة بالفعل في المصدر الحالي.

Report294:
- Current source target verified.
- Production backend verified.
- Deployment identity وBrowser E2E ظلّا مفتوحين.
- التوصية كانت عدم إعادة تطبيق الإصلاحات المغلقة.

## 5. إعادة فحص النظام الأم
في `Current/PWA/main.html`:
- العقد المركزي يضع `stock_vouchers` تحت ملكية التطبيق المتخصص `vouchers.html`.
- `inventory` في النظام الأم هو read-only view.
- التنقل يحمل `vouchers` إلى `RW_Warehouse.loadVouchers`.
- الصلاحيات تستخدم `vouchers` كقدرة مستقلة.
- لذلك لا يوجد مبرر لإدخال منطق الأذونات التفصيلي إلى `main.html`.
- لم يتم لمس `main.html`.

النتيجة المعمارية:
النظام الأم هو Control/Navigation/Monitoring Plane، وتطبيق الأذونات هو Operational Plane للأذونات غير المرتبطة بالأوردرات والرانشيتات، بينما Physical Stock Engine في Production هو `post_stock_movement`.

## 6. الدور الفعلي لتطبيق الأذونات
العقد الحالي المثبت من المصدر والتاريخ:
- Transfer: Branch → Branch.
- DirectSale: Branch → Vehicle.
- DirectReturn: Vehicle → Branch.
- SupplierReturn: Branch → Supplier.
- Adjustment/Scrap: Adjustment Engine.

DirectSale هنا ليس بيع العميل.
هو تحويل فعلي للبضاعة إلى المخزن المتنقل المرتبط بالمركبة تمهيدًا لأن يقوم `van-sales.html` بالبيع المباشر لاحقًا.

DirectReturn هو إعادة البضاعة من وعاء المخزن المتنقل للمركبة إلى مخزن الفرع.

المركبة ليست ذمة مالية بحد ذاتها.
المركبة وعاء Stock Container، والـhuman custodian/rep هو صاحب المسؤولية التشغيلية عند الحاجة.
هذا يطابق التنفيذ الحالي:
- vehicles.driver_id يحدد المندوب.
- vehicles.mobile_branch_id يحدد المخزن المتنقل.
- voucher.custodian_user_id/rep linkage يحدد الشخص التشغيلي.
- DirectSale/DirectReturn لا يتحولان إلى Invoice.

## 7. الفحص الجنائي لملف vouchers.html
### 7.1 ربط المركبة
المصدر الحالي يحمل المركبات مباشرة من جدول `vehicles`:
- `id`
- `vehicle_code`
- `license_plate`
- `model`
- `driver_id`
- `status`
- `mobile_branch_id`
- `mobile_stock_enabled`

مع `eq('company_id', s.company)` و`eq('status','Active')`.

هذا ليس Text-only field.
الحقل الذكي يختار UUID من `vehicles`، وتوجد دالة `vehicleBranch(v)` التي تربط المركبة بالمخزن المتنقل عبر `mobile_branch_id` ثم fallback موثق باسم `VAN-vehicle_code`.

### 7.2 DirectSale
المصدر الحالي يرفض المسار ما لم يتحقق:
- branch موجود.
- rep موجود.
- vehicle موجود.
- vehicle.driver_id == rep.id.
- rep مسموح على الفرع.
- vehicle له mobile branch صالح.

### 7.3 DirectReturn
المصدر الحالي:
- يختار المركبة أولاً.
- يستخرج المندوب من `vehicle.driver_id`.
- يفرض فرعًا صالحًا للجهة المستلمة.
- يفرض mobile branch صالحًا للمركبة.

إذن طلب ربط المركبة بجدول المركبات **مغلق بالفعل في المصدر الحالي** ولا يوجد Defect مثبت يبرر إعادة إصلاحه.

## 8. الفحص الجنائي لملف van-sales.html
الدور مثبت:
- يدخل المستخدم بصلاحية `van-sales`.
- `loadVanBranch` يحصل على المخزن المتنقل canonical.
- المخزون في `vanBranchId` هو مخزون السيارة.
- Quick Sale يستخدم العميل + cart + stock.
- الحفظ يرسل `source: 'van-sales'` إلى `save-sales-invoice`.
- الحالة `Invoiced` تؤدي في Production RPC إلى `post_stock_movement(...,'VanSale',...)`.
- المحاسبة تُنشأ في نفس المعالجة.
- لا يوجد prerequisite Order سابق.
- Production orders = 0 حاليًا، وهو متسق مع طبيعة direct sale التي لم تسجل اختبارًا دائمًا.

تم فحص مصدر البيع المباشر ولم يثبت في هذه المهمة خلل جديد يستدعي تعديل `van-sales.html`.
لذلك لم يُلمس.

## 9. Production Core verification
الـRPCs الحالية ذات الصلة:
- `create_manual_stock_voucher_atomic` موجود وله:
  - signature تاريخية 10 arguments.
  - signature canonical 12 arguments مع `p_rep_id` و`p_operation_id`.
- `send_stock_voucher_atomic` موجود.
- `post_manual_stock_voucher_atomic` موجود.
- `post_stock_movement` موجود.
- Physical movement chain ما زالت:
  `post_stock_movement → stock_branches + inventory_log`.

تم تنفيذ اختبار Production transactional جديد لإنشاء DirectSale باستخدام:
- Branch `BR-01`
- Vehicle `VEH-TEST-260921`
- Rep `vansales@rawaea.com`
- Item `1001`
- qty = 1
- operation_id ثابت للاختبار

النتيجة:
- success = true
- rep_id صحيح
- company_id صحيح
- operation_id محفوظ في نتيجة الـRPC
- ثم ROLLBACK كامل.
لا يوجد Test Residue.

## 10. السبب الجذري للمشكلة الحالية
### المشكلة المثبتة
في `renderWorkspace:function()` داخل `vouchers.html`:
`wsSearch` و`wsCats` موجودان داخل:
`wsTopPanel`

والـ`wsTopPanel` هو الجزء القابل للطي عبر `toggleTopPanel()`.

### النتيجة
عند طي Route/Reference Panel يختفي معه عنصر بحث الأصناف.
وهذا يفصل وظيفة البحث عن المجال الذي يخصها فعليًا: Catalog/Product Selection.

### لماذا هذا Defect حقيقي؟
لأن:
- البحث موجود فعليًا ومختبر Source-level.
- `renderProducts` و`search` يعتمدان على نفس `wsSearch`.
- المشكلة ليست نقص Function.
- وليست مشكلة Production.
- وليست مشكلة vehicle binding.
- المشكلة الوحيدة هي placement/interaction boundary داخل Workspace UI.

## 11. القرار الجراحي
نقل:
- `wsSearch`
- `wsResults`
- `wsScanBtn`
- `wsCats`

من داخل `wsTopPanel` إلى رأس Catalog الثابت.

مع الإبقاء على:
- نفس IDs.
- نفس event handlers.
- نفس `App.search`.
- نفس `App.searchKey`.
- نفس `App.openScanner`.
- نفس `App.renderCats`.
- نفس Product filtering.
- نفس Barcode workflow.

لا Functions جديدة.
لا API جديدة.
لا RPC جديدة.
لا تغيير Business Contract.

## 12. Owner Surgical Patch — الملف الوحيد المطلوب تعديله
### الملف
`papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/vouchers.html`

### العنصر المحدد
داخل:
`renderWorkspace:function()`

في النسخة الحالية يبدأ تقريبًا عند السطر 1168 بالكتلة التي تبدأ بـ:
`'<div id="wsTopPanel"...`

وينتهي في نفس السلسلة عند:
`'<div class="ws-grid"><section class="catalog"...`

### احذف الكتلة التالية كاملة واستبدلها بالكامل
```text
            '<div id="wsTopPanel" class="ws-top-panel mt-3'+(topCollapsed?' ws-top-collapsed':'')+'">'+
              '<div>'+s.routeHtml()+'</div>'+
              '<div class="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-2"><input id="wsRef" class="smart-input" placeholder="المرجع الإجباري"><input id="wsNotes" class="smart-input" placeholder="'+(engine?'السبب الإجباري':'ملاحظات (اختياري)')+'"></div>'+
              (engine&&this.type==='Adjustment'?'<select id="wsMode" class="smart-input mt-2"><option value="replace">تسوية إلى الرصيد الفعلي</option><option value="add">زيادة</option><option value="deduct">نقص</option></select>':'')+
              '<div class="relative mt-3"><input id="wsSearch" autocomplete="off" oninput="App.search(this.value)" onkeydown="App.searchKey(event)" class="dark-input w-full rounded-2xl px-4 py-3.5 text-sm font-bold pr-12 pl-14" placeholder="🔍 امسح الباركود أو ابحث باسم/كود الصنف... (F2)"><button id="wsScanBtn" type="button" onclick="App.openScanner()" class="absolute left-2 top-1/2 -translate-y-1/2 w-10 h-10 rounded-xl bg-blue-600 text-white"><i class="fa-solid fa-camera"></i></button><i class="fa-solid fa-magnifying-glass absolute right-4 top-1/2 -translate-y-1/2 text-slate-500"></i><div id="wsResults" class="hidden result-pop"></div></div>'+
              '<div id="wsCats" class="flex gap-2 overflow-x-auto mt-3"></div>'+
            '</div>'+
          '</div>'+
          '<div class="ws-grid"><section class="catalog"><div class="flex items-center justify-between p-3 text-xs text-slate-500"><span>الكتالوج <b id="count"></b></span><span id="stockHint">اختر المصدر لمعرفة المتاح</span></div><div id="products" class="flex-1 min-h-0 overflow-y-auto p-3 grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-2"></div></section>'+
```

### واستبدلها بالكامل بالآتي
```text
            '<div id="wsTopPanel" class="ws-top-panel mt-3'+(topCollapsed?' ws-top-collapsed':'')+'">'+
              '<div>'+s.routeHtml()+'</div>'+
              '<div class="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-2"><input id="wsRef" class="smart-input" placeholder="المرجع الإجباري"><input id="wsNotes" class="smart-input" placeholder="'+(engine?'السبب الإجباري':'ملاحظات (اختياري)')+'"></div>'+
              (engine&&this.type==='Adjustment'?'<select id="wsMode" class="smart-input mt-2"><option value="replace">تسوية إلى الرصيد الفعلي</option><option value="add">زيادة</option><option value="deduct">نقص</option></select>':'')+
            '</div>'+
          '</div>'+
          '<div class="ws-grid"><section class="catalog">'+
            '<div class="p-3 bg-slate-950 border-b border-slate-800">'+
              '<div class="flex items-center justify-between text-xs text-slate-500"><span>الكتالوج <b id="count"></b></span><span id="stockHint">اختر المصدر لمعرفة المتاح</span></div>'+
              '<div class="relative mt-3"><input id="wsSearch" autocomplete="off" oninput="App.search(this.value)" onkeydown="App.searchKey(event)" class="dark-input w-full rounded-2xl px-4 py-3.5 text-sm font-bold pr-12 pl-14" placeholder="🔍 امسح الباركود أو ابحث باسم/كود الصنف... (F2)"><button id="wsScanBtn" type="button" onclick="App.openScanner()" class="absolute left-2 top-1/2 -translate-y-1/2 w-10 h-10 rounded-xl bg-blue-600 text-white"><i class="fa-solid fa-camera"></i></button><i class="fa-solid fa-magnifying-glass absolute right-4 top-1/2 -translate-y-1/2 text-slate-500"></i><div id="wsResults" class="hidden result-pop"></div></div>'+
              '<div id="wsCats" class="flex gap-2 overflow-x-auto mt-3"></div>'+
            '</div>'+
            '<div id="products" class="flex-1 min-h-0 overflow-y-auto p-3 grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-2"></div></section>'+
```

## 13. لماذا هذه الجراحة آمنة
- نفس `wsSearch` ID.
- نفس `wsResults` ID.
- نفس scan button ID.
- لا تغيير في `search()`.
- لا تغيير في `renderProducts()`.
- لا تغيير في `itemDetails()`.
- لا تغيير في Cart.
- لا تغيير في Submit.
- لا تغيير في DirectSale/DirectReturn.
- لا تغيير في vehicle binding.
- لا تغيير في RPCs.
- لا تغيير في permission contract.

الاختبار الساكن على النسخة المعدلة في الذاكرة:
- JavaScript parse = PASS.
- wsSearch count = 1.
- wsCats count = 1.
- wsSearch خارج wsTopPanel = PASS.
- old target block removed exactly = PASS.
- file line count بعد الجراحة = 1830.

## 14. المهمة الثانية — المركبة
### النتيجة
**لا Patch مطلوب.**

السبب المثبت:
- `loadRefs()` يقرأ جدول `vehicles` مباشرة.
- `pickArr('wsTo')` يفلتر vehicles حسب branch + rep + mobile branch.
- `pickSelect('wsTo')` يحفظ UUID الخاص بالمركبة ويستخرج rep من `driver_id`.
- `vehicleBranch()` يربط المركبة بالمخزن المتنقل canonical.
- `submit()` يرسل `to_type='Vehicle'` و`to_id=vehicle.id` في DirectSale.
- `submit()` يرسل `from_type='Vehicle'` و`from_id=vehicle.id` في DirectReturn.
- Production يحتوي المركبة والمخزن المتنقل والrep المرتبط فعليًا.
- Production transactional CREATE DirectSale عاد `success=true`.

أي تعديل آخر هنا سيكون إعادة إصلاح لشيء مغلق، ومخالفًا للـgovernance.

## 15. المقارنة التنافسية
### Odoo
Odoo 19 يوثق تشغيل المخزون عبر عمليات يومية، Barcode، Inventory Adjustments، اختيار المنتجات يدويًا، تعديل الكمية و+1/-1، وإنهاء العملية. هذا يجعل فصل بحث المنتج عن Route/Location controls قرار UX صحيحًا لأن البحث ينتمي إلى Product Operation space. كما أن Odoo يسمح بإضافة Product يدويًا داخل عملية العد مع Quantity وLocation.

### Dynamics 365
Dynamics 365 يستخدم Inventory Journals مستقلة للحركة والتسوية والتحويل والعد، ويحدد From/To dimensions للحركة. هذا يعضد فصل Document Route/Dimensions عن سطر المنتج داخل نفس العملية.

### SAP
SAP S/4HANA يعامل Goods Movement كقدرة موثقة تشمل Goods Receipt وGoods Issue وPhysical Stock Transfer وTransfer Posting مع material-document trail.

### Daftra
Daftra يوفر Inventory Detailed Transactions مع Date/Product/Warehouse/Type filters وفتح تفاصيل كل حركة، كما يوفر Stocktaking Sheet وإضافة المنتجات يدويًا وإظهار System Count مقابل Physical Count.

### النتيجة بالنسبة إلى RAWAEA
RAWAEA بالفعل يملك:
- Source/To dimensions.
- Vehicle/rep binding.
- Barcode/Product Search.
- Quantity controls.
- Stock availability.
- Document reference.
- Separate operational applications.
- Central Physical Stock Engine.
- Mother-system read model and audit/reporting.

ما يظل مهمًا كتطوير لاحق وليس ضمن هذه الجراحة:
- تقارير حركة مخزنية أكثر عمقًا داخل Control Plane.
- Filters أكثر ثراءً للحركة والتدقيق.
- عمليات Inventory Count موجهة/assigned على نمط الأنظمة العالمية.
هذه ليست فجوات مثبتة في capability الحالية تستدعي كسر نطاق المهمة، ولا يجوز اختلاقها داخل vouchers.html لمجرد المطابقة الشكلية.

## 16. Data / Business Contract Integrity
لا يوجد في هذه الجراحة:
- حذف بيانات.
- تغيير quantities.
- تغيير stock.
- تغيير vouchers.
- تغيير orders.
- تغيير runsheets.
- تغيير permissions.
- تغيير vehicle ownership.
- تغيير company scope.

Current Production data remains unchanged.

## 17. Edge Function / Gateway decision
لا Function جديدة.
الـexisting capabilities الحالية كافية:
- create-stock-voucher v10.
- send-stock-voucher v20.
- receive-stock-voucher v22.
- complete-stock-voucher v4.
- cancel-stock-voucher v4.
ولا يوجد سبب هندسي لإضافة Function جديدة لنقل Search UI أو ربط المركبة.

## 18. Production execution status
### Implemented in Production in this closure
لا يوجد Production schema/business change مطلوب.

### Production verified
- Current vehicle exists and is active.
- Vehicle has canonical mobile branch.
- Vehicle driver is current Direct Sales Rep.
- DirectSale CREATE canonical RPC succeeds transactionally.
- Physical Stock chain remains centralized.
- No test residue after rollback.

### Current source
- vouchers.html current blob verified.
- van-sales.html current blob verified.
- main.html current role/delegation verified.

### Owner patch
جاهز في القسم 12.
لم يُدفع إلى frontend source لأنه Owner-owned file بحسب governance.

### Browser E2E
ظل مفتوحًا.
لم تتوفر في هذه الجلسة بيئة browser click-through مصادق عليها يمكن بها إثبات login → New Voucher → DirectSale → search → vehicle → save → send من الواجهة المنشورة.
لذلك لا يوجد ادعاء Browser E2E PASS.

## 19. Closure Matrix
| النقطة | الحالة |
|---|---|
| Physical Stock centralization | CLOSED |
| DirectSale Production contract | CLOSED |
| DirectReturn Production contract | CLOSED |
| Vehicle → vehicles table linkage | CLOSED |
| Rep/Vehicle binding | CLOSED |
| V-03/V-04/V-05/V-06/V-07/V-08 | CLOSED / PRESERVED |
| Quantity/Cart controls | CLOSED / PRESERVED |
| Item Search placement | OWNER PATCH READY |
| main.html | UNTOUCHED |
| van-sales.html | UNTOUCHED |
| New Edge Function | NOT CREATED |
| Production business schema change | NOT REQUIRED |
| Browser authenticated E2E | OPEN |
| Deployment identity | OPEN |

## 20. SELF-AUDIT
### What was proven
- Current Git and parents.
- Current frontend blob and parent.
- Current Production inventory/vehicle/voucher state.
- Mother-system delegation.
- Vehicle binding is already implemented.
- DirectSale/DirectReturn contract is already implemented.
- Exact source root cause for the current item-search usability defect.
- Exact surgical replacement was syntax-checked in memory.

### What was not proven
- Live authenticated browser click-through against the currently published frontend artifact.
- Current published frontend artifact identity against frontend Git HEAD.

### What was fixed
- This closure prepares one surgical owner patch only: move item search + category chooser from collapsible top route panel to persistent catalog header.

### What was intentionally not changed
- main.html.
- van-sales.html.
- Production business schema.
- Edge Functions.
- already-closed DirectSale/Vehicle contracts.
- physical stock engine.

### What could still be wrong
Only the deployment/browser boundary remains unproven. The source-level patch itself passed syntax/static placement checks.

## 21. Next exact start point
1. Verify current system HEAD/parent and frontend HEAD/parent.
2. Verify that the owner applied the exact Report295 replacement.
3. Parse the complete vouchers.html after merge.
4. Prove current published artifact identity.
5. Run authenticated Browser E2E:
   New Voucher → DirectSale → collapse top panel → search item remains visible → select Branch → Rep → Vehicle → quantity → Save Draft → Send → verify Production.
6. Re-snapshot Production at the exact end of the test.
7. Open a new Closure Unit only for a newly proven defect.

## 22. Governance conclusion
هذه المهمة لم تحتج إلى تعديل Production لأن Production ليست موضع الخلل المثبت.
الخلل الموجود حاليًا هو UI boundary داخل Workspace:
Route/Reference Controls وProduct Search جرى وضعهما في حاوية واحدة رغم اختلاف مسؤوليتهما الوظيفية.

الجراحة المقترحة لا تعيد بناء ما تم إنجازه؛ بل تفصل المسؤوليتين في مكانهما الطبيعي مع الحفاظ الكامل على الـIDs والـhandlers والـAPI والـRPC والـBusiness Contract.

**FINAL STATUS: SOURCE SURGICAL PATCH READY — PRODUCTION CONTRACT VERIFIED — BROWSER E2E OPEN**
