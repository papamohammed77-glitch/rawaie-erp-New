# Report278 — إغلاق جنائي لمشكلة الأذونات المخزنية وربط Mother بالتطبيق المستقل
التاريخ: 2026-09-21
النطاق: Warehouse Vouchers + Mother Main Integration
Production: fiilmooggumokxanwiyx

## 1) الحالة التنفيذية
CLOSED:
- تم إثبات سبب توقف Mother من CURRENT SOURCE + CURRENT GIT.
- تم إثبات أن commit 10ef65f8e4fd38d7d767582d84bc54fdcf27f931 هو الذي أدخل الـescaping غير الصالح.
- تم إثبات أن الخطأ يقع في loadVoucherForm(type) عند السطر 13915 من Mother الحالي.
- تم اختبار نسخة Mother بعد الاستبدال في الذاكرة: جميع كتل JavaScript المضمنة اجتازت parser.
- لم يتم تعديل main.html آليًا.
- تم تعديل تطبيق الأذونات المخزنية الحالي فقط:
  commit a2de64c150c9e38f14af0c2ecafcbcd9861fa9cd
- تم التحقق من دورة Production: CREATE → SEND → RECEIVE → RECEIVE retry → COMPLETE.
- لم يتم إنشاء Edge Function جديدة.
- Physical Stock ما زال يمر عبر post_stock_movement.

PENDING:
- تطبيق المستخدم للـM1 في main.html.
- Browser E2E الفعلي للـMother بعد التطبيق.

## 2) CURRENT GIT — Mother
HEAD:
f2229bec9106f1c4836769b1eccda3cc48d4a482
Parent:
10ef65f8e4fd38d7d767582d84bc54fdcf27f931
Parent of parent:
4aebf36b6da684ecb1e09d8f83063e0231c70866
Current Mother blob:
e33c3527033bf0fa2e5bc582cea3556fd4ef5ca3

الـparent التاريخي السليم كان يستخدم Template Literal عادي.
commit 10ef65f8... غيّر:
safeHTML(c, `...`);
إلى:
safeHTML(c, \`...`);
وأدخل:
\${cfg.title}
\${cfg.entityLabel}
داخل JavaScript الحي.
هذا هو سبب SyntaxError.

## 3) ROOT CAUSE — مثبت
Current source:
main.html
function loadVoucherForm(type)
line 13900

أول token قاتل:
safeHTML(c, \`<div class="p-4">

والـinterpolation التالي:
\${cfg.title}
\${cfg.entityLabel}

Parser result قبل الإصلاح:
scripts 0–4 = PASS
script 5 = FAIL
error = Invalid or unexpected token

Parser result بعد M1 replacement:
كل embedded scripts = PASS

## 4) Tailwind warning
الرسالة:
cdn.tailwindcss.com should not be used in production
ليست سبب توقف الشاشة، وليست مرتبطة بالـSyntaxError.
لم يتم تغيير build pipeline.

## 5) الدور المعماري
Mother:
- vouchers = unified voucher management/history
- transfer/direct-sale/direct-return/supplier-return = type routes
- المركز الإداري والرقابي

Standalone vouchers.html:
- operational consumer للأذونات المخزنية اليدوية
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn

Scrap وAdjustment بقيا على Adjustment Engine المنفصل.

Production:
CREATE → create_manual_stock_voucher_atomic
SEND → send_stock_voucher_atomic → post_stock_movement
RECEIVE → post_manual_stock_voucher_atomic → post_stock_movement
COMPLETE → complete_manual_stock_voucher_atomic
CANCEL → cancel_manual_stock_voucher_atomic

Physical movement:
post_stock_movement → stock_branches + inventory_log

## 6) CURRENT PRODUCTION
وقت الفحص:
2026-09-21 04:10:59.880107+00 UTC

companies = 1
active_branches = 2
active_items = 16
active_vehicles = 0
active_suppliers = 1
stock_vouchers = 0
stock_voucher_details = 0
stock_voucher_operations = 0
inventory_log = 3
audit_log = 2022

بعد الاختبار:
stock_vouchers = 0
stock_voucher_details = 0
stock_voucher_operations = 0
inventory_log = 3
audit_log = 2022

لا يوجد test residue.

## 7) PRODUCTION E2E
اختبار داخل SAVEPOINT/ROLLBACK:

CREATE:
success=true
operation_id=CTO-E2E-20260921-CREATE
voucher_code=IN-1

SEND:
success=true
status=Sent
movement_count=1

RECEIVE:
success=true
status=Received
operation_id=CTO-E2E-20260921-RECEIVE

RECEIVE retry بنفس operation_id:
success=true
duplicate=true
status=Received

COMPLETE:
success=true
status=Completed

Physical movements:
2 فقط

تم Rollback كامل.
النتيجة تثبت idempotency وعدم إنشاء حركة ثالثة في retry.

محاولة استدعاء inventory_voucher_report من postgres المباشر أعاد "غير مصرح" لأن RPC يعتمد auth.uid؛ هذا Security Guard وليس Missing RPC.

## 8) STANDALONE SURGICAL FIX — تم التنفيذ
File:
companies/company-1/warehouse/vouchers.html

Previous blob:
887e9cbe85774c3702219a9030c3a6ed7a759bc4

New blob:
3adf031cfb073c87db10c562c1b3e7d568bb61fd

Commit:
a2de64c150c9e38f14af0c2ecafcbcd9861fa9cd

تم فقط:
1. إزالة reset المدمر لهوية CREATE من sessionStorage.
2. تحويل CREATE retry identity إلى localStorage.
3. توسيع filterList ليبحث في الكود والمرجع والنوع والحالة والمصدر والوجهة والمنشئ والملاحظات.
4. إظهار Available Before وExpected After قراءة فقط.
5. رفع نافذة history من 150 إلى 1000.
6. Parser check للـstandalone = PASS.

## 9) OWNER SURGICAL PATCH — main.html فقط
FILE:
papamohammed77-glitch/erp-frontend/companies/company-1/main.html

Current:
HEAD f2229bec9106f1c4836769b1eccda3cc48d4a482
blob e33c3527033bf0fa2e5bc582cea3556fd4ef5ca3

ابحث تحديدًا عن:
function loadVoucherForm(type) {

داخل:
var RW_Warehouse = (function() {

الموقع الحالي:
السطر 13900

احذف الدالة كاملة حتى القوس الذي يسبق:
async function _renderVoucherHistory(type) {

ثم استبدلها بالنص التالي:

function loadVoucherForm(type) {
    voucherCart = [];
    currentVoucherType = type;
    var configs = {
        'Transfer':      { title: 'تحويل مخزني', entityLabel: 'الفرع المحول إليه', showPrice: false, fromType: 'Branch', fromId: null, toType: 'Branch', toId: null, endpoint: 'save-voucher' },
        'DirectSale':    { title: 'صرف سيارة بيع مباشر', entityLabel: 'المندوب / السيارة', showPrice: true, fromType: 'Branch', fromId: null, toType: 'Vehicle', toId: null, endpoint: 'save-voucher' },
        'DirectReturn':  { title: 'استلام مرتجع سيارة', entityLabel: 'المندوب / السيارة', showPrice: true, fromType: 'Vehicle', fromId: null, toType: 'Branch', toId: null, endpoint: 'save-voucher' },
        'SupplierReturn':{ title: 'مرتجع لمورد', entityLabel: 'المورد', showPrice: true, fromType: 'Branch', fromId: null, toType: 'Supplier', toId: null, endpoint: 'save-voucher' }
    };
    var cfg = configs[type];
    if (!cfg) { showToast('نوع غير معروف', 'error'); return; }
    currentVoucherConfig = cfg;
    var c = byId('rw-page-container');
    if (!c) return;
    safeText(byId('rw-header-title'), cfg.title);
    safeHTML(c, `<div class="p-4">
        <div class="bg-white rounded-2xl shadow-sm border p-4">
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-xl font-bold"><i class="fa-solid fa-file-signature ml-2 text-indigo-600"></i>${cfg.title}</h2>
                <button onclick="RW_Warehouse.loadVouchers()" class="text-gray-500 hover:text-gray-700"><i class="fa-solid fa-xmark text-xl"></i></button>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <div>
                    <label class="block text-sm font-bold mb-1">${cfg.entityLabel}</label>
                    <select id="voucherEntitySelect" class="border rounded-lg p-2 w-full"><option value="">-- اختر --</option></select>
                </div>
                <div>
                    <label class="block text-sm font-bold mb-1">مرجع الإذن</label>
                    <input id="voucherReference" class="border rounded-lg p-2 w-full" placeholder="مرجع الإذن...">
                </div>
                <div>
                    <label class="block text-sm font-bold mb-1">ملاحظات</label>
                    <textarea id="voucherNotesLarge" rows="2" class="border rounded-lg p-2 w-full" placeholder="ملاحظات..."></textarea>
                </div>
            </div>
            <label class="block text-sm font-bold mb-1">بحث عن صنف</label>
            <div class="relative">
                <input type="text" id="voucherItemSearch" oninput="RW_Warehouse._searchVoucherItem(this.value)" autocomplete="off" placeholder="ابحث بالاسم أو الباركود..." class="border rounded-lg p-2 w-full">
                <div id="voucherSearchResults" class="absolute z-50 left-0 right-0 mt-1 bg-white shadow-xl rounded-xl max-h-60 overflow-y-auto hidden border"></div>
            </div>
            <div class="mb-4 overflow-y-auto" style="max-height:300px;" id="voucherItemsTable">
                <div class="text-center py-8 text-gray-400">أضف أصنافاً</div>
            </div>
            <div class="p-3 bg-gray-50 rounded-lg flex justify-between items-center mb-4">
                <span class="font-bold">عدد الأصناف: <span id="voucherTotalItems">0</span></span>
            </div>
            <div class="flex justify-end gap-3">
                <button onclick="RW_Warehouse._clearVoucherCart()" class="px-4 py-2 bg-gray-500 text-white rounded-lg font-bold">مسح الكل</button>
                <button onclick="RW_Warehouse._saveAndSendVoucher()" class="px-6 py-2 bg-indigo-600 text-white rounded-lg font-bold">حفظ وإرسال (Sent)</button>
            </div>
        </div>
        <div id="rw-voucher-history-panel" class="mt-6"></div>
    </div>`);
    _loadVoucherEntityOptions(type);
    _renderVoucherCart();
    _renderVoucherHistory(type);
}

مهم:
- backticks حقيقية.
- لا تضف backslash قبل backticks.
- لا تضف backslash قبل ${cfg.title} أو ${cfg.entityLabel}.
- لا تعدل _renderVoucherHistory(type) لأنها موجودة بالفعل.
- لا تعدل Router أو Permission Map أو loadVouchers أو _loadVoucherEntityOptions أو _renderVoucherCart أو _saveAndSendVoucher.

## 10) التكامل
M1 يعيد تشغيل _renderVoucherHistory(type) الموجود بالفعل في Mother.
وبالتالي لا نضيف route أو document model جديد.
Mother = Control Plane.
Standalone = Operational Plane.
كلاهما يستخدم نفس Production voucher contract.

## 11) COMPETITIVE FORENSIC BENCHMARK
Odoo:
- internal movements, receipts/deliveries, scrap and traceability.
- lot/serial tracking مرتبط بنوع العملية.
Sources:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/product_management/product_tracking/lots.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/product_management/product_tracking/serial_numbers.html

Dynamics 365:
- transfer order بين warehouses.
- shipment/receipt lifecycle.
- transport lead time وinventory transactions.
Sources:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/transfer-orders-warehouse
https://learn.microsoft.com/en-us/dynamics365/finance/general-ledger/inventory-posting
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process

SAP S/4HANA:
- Stock Transport Order.
- Goods Issue وGoods Receipt كعمليتين منفصلتين.
- stock in transit وtracking/order history.
Sources:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/95f56a29a41e4861ba3424598848ee2b/4d6ed2bb174a74dbe10000000a42189c.html
https://help.sap.com/docs/s4hana-cloud-best-practices/stock-transfer-with-delivery-bme-sa/post-goods-receipt-for-stock-transport-order

Daftra:
- From/To warehouse.
- Qty.
- Available Before / Available After.
- detailed inventory movement reports.
Sources:
https://docs.daftra.com/en/tutorial/transferring-stock/
https://docs.daftra.com/en/tutorial/inventory-transactions-summary-report/
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

Manager.io:
- Inventory Transfer بين locations.
- Date, Reference, Description, Item, Qty, From, To.
Source:
https://www2.manager.io/guides/10707

## 12) COMPETITIVE GAP DECISION
تم تنفيذ ما يمكن إغلاقه بدون عقد جديد:
- Durable retry identity
- smart document search
- projected availability
- larger history window
- unified Mother history/reporting path

لم يتم اختراع عقود جديدة صامتة:
- approval workflow
- attachments
- lot/serial/expiry
- formal transit state
- bulk import
- print/export contract
- persistent before/after snapshots

هذه نقاط Business Contract مستقلة وتحتاج تصميمًا مثبتًا قبل البناء.

## 13) DATA SAFETY
Current Production Item Master:
items.item_code = UNIQUE globally.

لذلك لم تتم إعادة إسناد أو تنظيف شركات افتراضيًا.
لا توجد Voucher rows حالية تستلزم repair.
لم يتم تغيير stock data.

## 14) FINAL SELF-AUDIT
What I proved:
- root cause
- exact defective line
- causal Git commit
- parser failure
- parser success after M1
- standalone consumer surgical closure
- Production lifecycle
- RECEIVE idempotency
- no physical duplicate
- no residue after rollback
- no new Edge Function required

What I did not prove:
- browser click-through on corrected Mother after owner patch
- visual UX in a real browser session

What I fixed:
- standalone consumer reliability and visibility
- Production lifecycle verified transactionally

What remains:
- owner applies M1
- browser E2E

Final status:
WAREHOUSE VOUCHER CONSUMER = CLOSED
PRODUCTION VOUCHER CORE = CLOSED
MOTHER ROOT CAUSE = PROVEN
MOTHER PATCH = READY
MOTHER BROWSER E2E = OWNER PENDING

## 15) NEXT CTO INSTRUCTIONS
Do not restart.
Start from CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT.
First verify owner-applied M1 by parser.
Then run browser route tests:
- vouchers
- transfer
- direct-sale
- direct-return
- supplier-return

Then verify:
- create
- send
- receive
- complete
- cancel
- history
- audit drill-down

No new Edge Function.
No rewrite.
No reopening closed areas.
Any new Production change must be preceded by current Production snapshot.

END REPORT278
