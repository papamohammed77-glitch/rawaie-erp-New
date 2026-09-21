# Report279 — WAREHOUSE VOUCHERS / MOTHER LIVE FORENSIC SURGICAL CONTINUATION
التاريخ: 2026-09-21
النطاق: Warehouse Vouchers + Mother Main Integration
Production: fiilmooggumokxanwiyx

## 1) Scope Lock

هذه الجولة محصورة في:
- تبويب الأذونات المخزنية في Mother.
- الدوال الأربع الخاصة بإنشاء النماذج: Transfer / DirectSale / DirectReturn / SupplierReturn.
- تكامل Mother مع تطبيق الأذونات المخزنية المستقل.
- إثبات سبب SyntaxError الحالي.
- التحقق من Production وعدم إعادة فتح الإغلاقات السابقة.

لم يتم تعديل: Mother main.html أو standalone vouchers.html، ولم يتم إنشاء Edge Function جديدة.

## 2) CURRENT GIT — MOTHER

Repository: `papamohammed77-glitch/erp-frontend`
Current HEAD: `6fdf203cea72da68751bb8d73c28c8df0fd277f7`
HEAD message: `forensic: persist current Mother HR extract`
Immediate parent: `2e936dcfd8076cc197cb62229bffb600d68cc561`
Current Mother blob: `1513c7d1413776d0be370084b2556c017c016b3d`

الـparent المباشر هو commit `Refactor loadVoucherForm function for clarity`، وهو آخر تغيير مباشر مثبت على `main.html` قبل commit توثيقي لاحق.

## 3) CURRENT SOURCE — EXACT FAILURE

الدالة الحالية تبدأ عند السطر 13900 تقريبًا:

```javascript
function loadVoucherForm(type) {
    ...
    safeText(byId('rw-header-title'), cfg.title);
    safeHTML(c, <div class="p-4">
```

وبداخل نفس الكتلة:
- `\\${cfg.title}`
- `\\${cfg.entityLabel}`
- النهاية `</div>\\`);`

النتيجة المثبتة من parser على CURRENT SOURCE:
- Embedded script 0–4 = PASS
- Embedded script 5 = FAIL
- Error = `Unexpected token '<'`

إذن الـ`<` الموجود في بداية HTML هو أول token قاتل دخل إلى JavaScript خارج Template Literal.

## 4) ROOT CAUSE — CURRENT FORENSIC TRUTH

Report278 أصبح تاريخيًا جزئيًا من ناحية Attribution بعد تغير Mother.
الحقيقة الحالية المثبتة من CURRENT GIT هي أن commit:

`2e936dcfd8076cc197cb62229bffb600d68cc561`

هو آخر commit غيّر `loadVoucherForm()` وترك الكتلة الحالية غير صالحة نحويًا.

السبب التنفيذي:

```text
loadVoucherForm()
    ↓
opening template literal missing
    ↓
HTML token '<' enters JavaScript parser
    ↓
Unexpected token '<'
    ↓
embedded script 5 fails
    ↓
Mother initialization cannot complete
```

الـTailwind warning:
`cdn.tailwindcss.com should not be used in production`

ليست سبب توقف الشاشة ولا سبب الـSyntaxError، ولم يتم تغيير build pipeline لها.

## 5) PROOF OF SURGICAL FIX — IN MEMORY ONLY

تم اختبار إصلاح دقيق دون الكتابة إلى Mother:

```javascript
safeHTML(c, `<div class="p-4">
...
</div>`);
```

مع إعادة interpolation إلى:

```javascript
${cfg.title}
${cfg.entityLabel}
```

نتيجة parser بعد هذا الاستبدال في الذاكرة:
`ALL EMBEDDED SCRIPTS = PASS`

## 6) EXACT OWNER SURGICAL ACTION

### الملف الوحيد المطلوب تعديله يدويًا
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

### ابحث عن العنصر تحديدًا
```javascript
function loadVoucherForm(type) {
```

الموضع الحالي: `13900`
داخل `var RW_Warehouse = (function() {`

### احذف
الدالة كاملة من:

```javascript
function loadVoucherForm(type) {
```

حتى القوس الذي يسبق مباشرة:

```javascript
async function _renderVoucherHistory(type) {
```

### استبدلها بالكامل بهذا النص

```javascript
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
```

قواعد النقل:
- استخدم backticks حقيقية.
- لا تكتب backslash قبل backtick.
- لا تكتب backslash قبل `${cfg.title}` أو `${cfg.entityLabel}`.
- لا تعدل `_renderVoucherHistory(type)` أو أي دالة مجاورة.

## 7) MOTHER ARCHITECTURE — WHAT IS ALREADY PRESENT

Router الحالي المثبت:

```text
vouchers        → RW_Warehouse.loadVouchers()
transfer        → RW_Warehouse.loadVoucherForm('Transfer')
direct-sale     → RW_Warehouse.loadVoucherForm('DirectSale')
direct-return   → RW_Warehouse.loadVoucherForm('DirectReturn')
supplier-return → RW_Warehouse.loadVoucherForm('SupplierReturn')
```

`_renderVoucherHistory(type)` موجود بالفعل بعد `loadVoucherForm()` مباشرة، ولذلك إصلاح parser يعيد الوصول إلى read model الموجود دون بناء جديد.

`loadVouchers()` موجود أيضًا ويقرأ نفس `stock_vouchers` ضمن Company scope.

`_saveAndSendVoucher()` موجود ويستخدم:
- Company context من `RW_STATE`.
- `create-stock-voucher` الحالي.
- `send-stock-voucher` الحالي.
- Authorization token.
- Operation identity.

إذن Mother لا يحتاج Writer مخزني جديد.

## 8) DATA / WORKFLOW CONTRACT

### CREATE
```text
Mother
 ↓
create-stock-voucher
 ↓
create_manual_stock_voucher_atomic
 ↓
stock_vouchers + stock_voucher_details
```

### SEND
```text
send-stock-voucher
 ↓
send_stock_voucher_atomic
 ↓
post_stock_movement
 ↓
stock_branches + inventory_log
```

### RECEIVE
```text
receive-stock-voucher
 ↓
post_manual_stock_voucher_atomic
 ↓
post_stock_movement
 ↓
stock_branches + inventory_log
```

### COMPLETE / CANCEL
```text
complete-stock-voucher → complete_manual_stock_voucher_atomic
cancel-stock-voucher   → cancel_manual_stock_voucher_atomic
```

العقد المركزي للـPhysical Stock لم يتغير:
`post_stock_movement → stock_branches + inventory_log`

## 9) STANDALONE CURRENT REALITY

File:
`erp-frontend/companies/company-1/warehouse/vouchers.html`

Current SHA:
`3adf031cfb073c87db10c562c1b3e7d568bb61fd`

Latest surgical commit:
`a2de64c150c9e38f14af0c2ecafcbcd9861fa9cd`

Current parser:
`PASS`

Already closed there:
- durable CREATE retry identity through localStorage
- durable RECEIVE retry identity through localStorage
- smart document filtering
- Available Before
- Expected After
- larger history window

لا يُعاد فتح الملف أو إصلاحه مرة أخرى إلا إذا ظهر Regression جديد مثبت.

## 10) CURRENT PRODUCTION SNAPSHOT

Observed UTC:
`2026-09-21 05:12:00.160304`

```text
companies                = 1
active_branches          = 2
active_items             = 16
stock_vouchers            = 0
stock_voucher_details     = 0
inventory_log             = 3
audit_log                 = 2023
stock_voucher_operations  = 0
post_stock_movement overloads = 2
```

Voucher Production data repair:
`NONE REQUIRED`

لم يوجد سبب مشروع لعمل DDL أو data migration جديدة في هذه الجولة.

## 11) CURRENT PRODUCTION DEPLOYMENTS

- `create-stock-voucher` v10 — verify_jwt=true
- `send-stock-voucher` v20 — verify_jwt=true
- `receive-stock-voucher` v22 — verify_jwt=true
- `complete-stock-voucher` v4 — verify_jwt=true
- `cancel-stock-voucher` v4 — verify_jwt=true

Current database command set:
- create_manual_stock_voucher_atomic
- post_manual_stock_voucher_atomic
- send_stock_voucher_atomic
- complete_manual_stock_voucher_atomic
- cancel_manual_stock_voucher_atomic
- inventory_voucher_report
- post_stock_movement

No new Edge Function was required.

## 12) PRODUCTION E2E ALREADY PROVEN

Transactional E2E:
`CREATE → SEND → RECEIVE → RECEIVE retry → COMPLETE`

Verified:
- CREATE success
- SEND success
- RECEIVE success
- RECEIVE retry returned `duplicate=true`
- COMPLETE returned `status=Completed`
- physical movements = 2
- full transaction rollback
- no residue after rollback

Current clean state remains verified after that E2E.

## 13) COMPETITIVE FORENSIC BENCHMARK

Odoo 19 documents stock moves as movements between source and destination locations and supports one-, two-, and three-step inbound/outbound flows. This supports RAWAEA's explicit separation of operation document, source/destination and physical movement engine.

Dynamics 365 documents transfer-order receiving as an explicit receiving process, supporting the separation between transfer initiation and receipt confirmation.

SAP S/4HANA documents Stock Transport Order receiving with a separate Goods Receipt step and operational stock-in-transit visibility.

Daftra documents warehouse transfer with From Warehouse, To Warehouse, Notes, Quantity, Available Before and Available After, plus summary and detailed inventory transaction reports.

Manager.io documents inventory locations and location-aware inventory movement.

Official sources:
- Odoo: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html
- Odoo flows: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/shipping_receiving/daily_operations.html
- Dynamics: https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process
- SAP: https://help.sap.com/docs/s4hana-cloud-best-practices/stock-transfer-with-delivery-bme-sa/post-goods-receipt-for-stock-transport-order
- Daftra transfer: https://docs.daftra.com/en/tutorial/transferring-stock/
- Daftra detailed transactions: https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/
- Daftra summary: https://docs.daftra.com/en/tutorial/inventory-transactions-summary-report/
- Manager: https://www2.manager.io/guides/10677

لم يتم نسخ Business Contract من أي منافس؛ تم استخدام المقارنة للتحقق من اكتمال الاتجاه المعماري والـUX فقط.

## 14) COMPETITIVE GAP — NOT SILENTLY INVENTED

Already present:
- source/destination
- document type
- quantity
- status lifecycle
- reference/notes
- company scope
- actor context
- central physical movement
- audit trail
- operation identity
- partial receive
- before/after availability in standalone consumer
- historical reporting
- drill-down

Possible future Closure Units, but NOT implemented here:
- formal approval/rejection workflow
- attachments
- lot/serial/expiry
- dedicated stock-in-transit ledger
- bulk CSV/Paste
- expanded print/export contract
- stock request → voucher conversion
- spare-part warehouse subflow

## 15) DATA SAFETY

Current Production voucher tables are clean:
- stock_vouchers = 0
- stock_voucher_details = 0
- stock_voucher_operations = 0

No current voucher data was deleted, reassigned, or guessed.

## 16) BROWSER E2E STATUS

Mother source parser after exact replacement in memory:
`PASS`

Standalone source parser:
`PASS`

Browser Production E2E:
`OPEN — OWNER CUTOVER`

Reason:
`main.html` is owner-managed and was intentionally not auto-modified.

Therefore no false 100% closure is claimed.

## 17) GOVERNANCE SELF-AUDIT

### What was proved
- Current Mother HEAD/parent/blob.
- Current source failure and exact token.
- Current parser failure.
- Current parser success after exact surgical replacement in memory.
- Latest direct Mother refactor commit.
- Existing Mother Router.
- Existing Mother history/read model.
- Standalone current SHA and parser.
- Current Production voucher deployments and DB commands.
- Current Production counts.
- Existing transactional E2E.
- No voucher data repair required.
- No new Edge Function required.

### What was not proved
- Browser click-through after owner applies M1.
- Visual browser rendering after owner cutover.
- Live business voucher interaction against persistent Production data; Production was intentionally kept clean.

### What remains
`Owner applies M1 → browser E2E → fresh Production reread → closure`

## 18) SESSION RESET FOR NEXT CTO / ASSISTANT

ابدأ من:
- Mother HEAD `6fdf203...`
- Mother parent `2e936dc...`
- Mother blob `1513c7d...`
- Standalone voucher SHA `3adf031...`
- Backend voucher checkpoint commit `64e62366fc905cef3631bc5fee5b2fa006952b16`
- Current Production observed `2026-09-21 05:12:00 UTC`

Sequence:

```text
REFETCH CURRENT GIT
→ VERIFY OWNER M1
→ PARSER
→ BROWSER E2E
→ CURRENT PRODUCTION SNAPSHOT
→ FINAL CLOSE
```

لا تعيد إصلاح standalone أو Production voucher core ما لم يظهر Regression مثبت.

## 19) FINAL STATUS

```text
PRODUCTION VOUCHER CORE      = CLOSED
STANDALONE VOUCHER CONSUMER  = CLOSED
MOTHER ROUTER/READ MODEL     = EXISTING / VERIFIED
MOTHER CURRENT SOURCE        = SYNTAX BROKEN
MOTHER ROOT CAUSE            = PROVEN
MOTHER SURGICAL PATCH        = READY
PRODUCTION DATA REPAIR       = NONE
NEW EDGE FUNCTION            = NOT REQUIRED
BROWSER E2E                  = OPEN — OWNER CUTOVER
FULL MOTHER CLOSURE          = PENDING OWNER M1 + BROWSER E2E
```

# ROOT CAUSE — نهاية التقرير

الخطأ سببه المباشر في CURRENT SOURCE:

```text
function loadVoucherForm(type)
        ↓
safeHTML(c, <div class="p-4">
        ↓
Template Literal opening مفقود
        ↓
HTML token '<' يدخل محل JavaScript
        ↓
Unexpected token '<'
        ↓
Script 5 يفشل
        ↓
Mother لا يكتمل له parsing/initialization
```

والـcommit الحالي الذي ترك هذا الوضع هو:
`2e936dcfd8076cc197cb62229bffb600d68cc561`

أما تحذير Tailwind فليس سبب الخطأ.
