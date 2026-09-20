# Report276 — WAREHOUSE VOUCHERS / MOTHER INTEGRATION — CURRENT FORENSIC CONTINUATION
Date: 2026-09-20
Scope: `erp-frontend/companies/company-1/warehouse/vouchers.html`
Production project: `fiilmooggumokxanwiyx`

## 1. GOVERNANCE / SCOPE LOCK

This continuation starts from the last verified state; historical reports are evidence only. Current truth for this session is:

CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

Files explicitly protected from automated source modification:
- Mother: `companies/company-1/main.html`
- Standalone consumer: `companies/company-1/warehouse/vouchers.html`

No new Edge Function was created. No root frontend file was changed.

## 2. CURRENT GIT

### rawaie-erp-New
- HEAD: `e969579ae524e17ef586b0c694970610a5282e97`
- Parent: `d17db440071bd7af8e7d6627bcd77a2cb9b4df0f`
- Latest checkpoint commit: `docs: checkpoint warehouse vouchers standalone mother integration state`

### erp-frontend
- Mother current blob: `e2b0dcb8317034363365fe728e8b4c33d1bf08da`
- Latest Mother-related forensic commit inspected: `4aebf36b6da684ecb1e09d8f83063e0231c70866`
- Parent of that commit: `71151fbc2caa17447ad4c1800b02ab30f950937a`
- Latest vouchers commit: `f6d0558f1ae1525ccdb32bc6269ca87d9c378ae2`
- Vouchers parent: `8a1a75dd840b32cfc135178a9a9c466adefaf0ee`
- Vouchers blob: `887e9cbe85774c3702219a9030c3a6ed7a759bc4`

The latest Mother commit changes only a forensic extract, not the Mother runtime file.

## 3. CURRENT PRODUCTION — CHECKED FIRST

Production checked at:
`2026-09-20 18:37:51.586275+00`

Current counts:
- companies = 1
- branches = 2
- active_items = 16
- active_vehicles = 0
- active_suppliers = 1
- stock_vouchers = 0
- stock_voucher_details = 0
- stock_voucher_operations = 0
- inventory_log = 3
- audit_log = 2022

No permanent Voucher test residue exists.

### Current voucher-related deployments
- create-stock-voucher = ACTIVE v10, JWT required
- send-stock-voucher = ACTIVE v20, JWT required
- receive-stock-voucher = ACTIVE v22, JWT required
- complete-stock-voucher = ACTIVE v4, JWT required
- cancel-stock-voucher = ACTIVE v4, JWT required

No new Edge Function is required for this closure.

## 4. PRODUCTION CONTRACT

Current Production contains the canonical voucher capability chain:

CREATE
→ `create_manual_stock_voucher_atomic`

SEND
→ `send_stock_voucher_atomic`
→ `post_stock_movement`

RECEIVE
→ `post_manual_stock_voucher_atomic`
→ `post_stock_movement`

COMPLETE
→ `complete_manual_stock_voucher_atomic`

CANCEL
→ `cancel_manual_stock_voucher_atomic`

Physical stock remains:

PHYSICAL STOCK MOVEMENT
→ `post_stock_movement`
→ `stock_branches` + `inventory_log`

No parallel Physical Stock Engine was introduced by the voucher core.

## 5. PRODUCTION AUDIT / CONTROL PLANE

`stock_vouchers` is audited by:
`trg_audit_stock_vouchers`
→ `fn_audit_trigger()`
→ `audit_log`

Authenticated read/report capability:
`inventory_control(p_operation='VOUCHER_AUDIT')`

The current capability returns:
- voucher header
- voucher details
- audit history
- physical movements

The standalone application's `details(code)` already calls this authenticated RPC.

## 6. VERIFIED APPLICATION ROLE

`vouchers.html` is the field/operational consumer for manual stock operations outside the Order/Runsheet fulfillment spine:

1. Transfer
2. DirectSale
3. DirectReturn
4. SupplierReturn

Scrap and Adjustment remain on the separate Adjustment Engine and are not silently merged into the four voucher lifecycle types.

This preserves the project's deliberate separation between:
- operational Order/Runsheet stock lifecycle
- independent manual stock operations

## 7. MOTHER INTEGRATION — ACTUAL CURRENT STATE

The Mother router currently contains:

`vouchers` → `RW_Warehouse.loadVouchers()`
`transfer` → `RW_Warehouse.loadVoucherForm('Transfer')`
`direct-sale` → `RW_Warehouse.loadVoucherForm('DirectSale')`
`direct-return` → `RW_Warehouse.loadVoucherForm('DirectReturn')`
`supplier-return` → `RW_Warehouse.loadVoucherForm('SupplierReturn')`

Important architectural finding:

The four type routes are creation forms, not historical report pages.

The Mother unified Voucher list is the current historical control surface and reads the same Production `stock_vouchers` source with `source='Manual'`.

Therefore:
- Transfer records are available in the Mother unified Voucher history via type filtering.
- DirectSale records are available in the same surface.
- DirectReturn records are available in the same surface.
- SupplierReturn records are available in the same surface.

No second document model is required.

Because the Mother file is explicitly protected in this session, no separate historical list route was invented or injected.

## 8. CURRENT SOURCE FORENSICS — VOUCHERS.HTML

Current file was read to EOF.

Already CLOSED in current source and therefore deliberately NOT revisited:
- Category runtime fix
- App.init fix
- branch ACL / allowedBranch fix
- pickArr fix
- picker/selection fixes
- boot/runtime fixes
- receive operation identity
- current authenticated Production RPC contract

Current functions verified:
`loadList`, `renderList`, `filterList`, `details`, `callAction`, `receive`, `prepare`, `newWorkspace`, `allowedBranch`, `vehicleBranch`, `pickArr`, `pickShow`, `pickSearch`, `pickSelect`, `routeHtml`, `renderWorkspace`, `renderCats`, `sourceBranch`, `avail`, `renderProducts`, `renderCart`, `search`, `submit`.

## 9. REAL REMAINING CONSUMER GAPS

### GAP A — CREATE retry identity is tab-session scoped

Current exact element:

Function:
`newWorkspace:function(){`

Exact line currently present:
`sessionStorage.removeItem('RW_VOUCHER_CREATE:'+s.company+':'+s.type);`

This can destroy the pending CREATE operation identity before a legitimate retry after a page/session reconstruction.

Current `submit()` also persists the CREATE operation identity using `sessionStorage`.

Production already has a durable server-side operation registry; the browser should not discard the same business operation identity during a recoverable retry.

This is a Consumer reliability defect, not a Physical Stock defect.

### GAP B — document search is narrower than the actual document contract

Current `filterList()` searches only:
- voucher_code
- reference
- type

The document already contains:
- status
- source
- destination
- created_by
- notes

These can be searched safely without a schema change.

### GAP C — operational stock visibility is weaker than the available backend facts

The current cart shows quantity but does not expose the projected source availability after the requested quantity.

Daftra exposes available-before/available-after concepts for transfer records; Odoo, Dynamics, SAP and Manager expose explicit movement/location concepts and history. The equivalent safe improvement here is a read-only projected Before/After display.

### GAP D — list window

Current:
`.limit(150)`

This is a practical consumer limitation when the history grows.

## 10. COMPETITIVE BENCHMARK — DOCUMENTED

### Odoo 19
Odoo treats internal stock movements, customer/vendor returns, receipts, deliveries and scrap as stock operations, while inventory adjustments are handled as reconciliation operations. Odoo also supports forecasted/on-hand inventory and operational move history. Sources:
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/scrap_inventory.html

### Microsoft Dynamics 365
Dynamics Inventory Journals explicitly include Movement, Inventory Adjustment and Transfer; Transfer requires From/To inventory dimensions, and posting creates inspectable inventory transactions. Sources:
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals
- https://learn.microsoft.com/en-us/dynamics365/finance/general-ledger/inventory-posting

### SAP S/4HANA
SAP Goods Movement covers goods receipts, goods issues, physical stock transfers and transfer postings, with transaction/reporting support around stock movements. Sources:
- https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html
- https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/9e64bd534f22b44ce10000000a174cb4.html

### Daftra
Daftra's transfer workflow documents date, from/to warehouse, notes, item and quantity, with available-before/available-after visibility and transfer history. Source:
- https://daftra.com/

### Manager.io
Manager separates Inventory Transfers, Write-offs and inventory reports. Transfers include Date, Reference, Description, Item, Qty, From and To. Sources:
- https://www2.manager.io/guides/10707
- https://www2.manager.io/guides/11130
- https://www2.manager.io/guides/10709

## 11. COMPETITIVE GAP DECISION

Safe to implement in the current contract without changing business semantics:
1. durable CREATE retry identity
2. broader document smart search
3. read-only projected Available Before / Expected After
4. larger list window

Not implemented silently because each is a distinct future Business Contract:
- approval workflow
- attachments / document uploads
- lot / serial / expiry tracking
- formal in-transit document state
- CSV / bulk import
- full print/export contract
- persisted historical Before/After snapshots

## 12. REQUIRED SURGICAL PATCH — OWNER ONLY

### FILE
`erp-frontend/companies/company-1/warehouse/vouchers.html`

### PATCH A1 — delete only the destructive CREATE cache reset

Function:
`newWorkspace:function(){`

Find exactly:
```js
sessionStorage.removeItem('RW_VOUCHER_CREATE:'+s.company+':'+s.type);
```

Delete this line only.

Do not replace the whole `newWorkspace()`.

### PATCH A2 — CREATE idempotency storage

Function:
`submit:function(){`

Find exactly:
```js
var cached=sessionStorage.getItem(storageKey);
```

Replace with:
```js
var cached=localStorage.getItem(storageKey);
```

Find exactly:
```js
sessionStorage.setItem(
```

Replace with:
```js
localStorage.setItem(
```

Find exactly in the CREATE success branch:
```js
sessionStorage.removeItem(storageKey);
```

Replace with:
```js
localStorage.removeItem(storageKey);
```

No other `submit()` logic changes.

### PATCH B — full `filterList()` replacement

Delete the current complete function:
`filterList:function(){...}`

Replace it with:

```js
filterList:function(){
    var s=this;

    var q=s.norm(
        (RW_UI.byId('listSearch')||{}).value||''
    );

    var type=
        (RW_UI.byId('listType')||{}).value||'';

    var from=
        (RW_UI.byId('listFrom')||{}).value||'';

    var to=
        (RW_UI.byId('listTo')||{}).value||'';

    if(from&&to&&from>to){
        RW_UI.toast(
            'الفترة الزمنية غير صحيحة',
            'warning'
        );
        return;
    }

    var labels={
        Transfer:'تحويل مخزني',
        DirectSale:'صرف سيارة بيع مباشر',
        DirectReturn:'استلام مرتجع سيارة',
        SupplierReturn:'مرتجع لمورد'
    };

    var statusLabels={
        Draft:'مسودة',
        Sent:'مُرسل',
        Received:'مُستلم',
        Completed:'مكتمل',
        Cancelled:'ملغى'
    };

    var rows=this.vouchers.filter(function(v){

        var fromText=s.loc(
            v.from_id,
            v.from_type
        );

        var toText=s.loc(
            v.to_id,
            v.to_type
        );

        var haystack=[
            v.voucher_code,
            v.reference,
            v.type,
            labels[v.type],
            v.status,
            statusLabels[v.status],
            fromText,
            toText,
            v.created_by,
            v.notes
        ].map(function(x){
            return s.norm(x);
        });

        var textMatch=
            !q||
            haystack.some(function(x){
                return x.includes(q);
            });

        var typeMatch=
            !type||
            v.type===type;

        var date=
            String(v.voucher_date||'').slice(0,10);

        var fromMatch=
            !from||
            date>=from;

        var toMatch=
            !to||
            date<=to;

        return(
            textMatch&&
            typeMatch&&
            fromMatch&&
            toMatch
        );
    });

    RW_UI.safeText(
        RW_UI.byId('listCount'),
        String(rows.length)
    );

    var box=RW_UI.byId('listCards');

    if(!box){
        return;
    }

    RW_UI.safeHTML(
        box,
        this.cards(rows,this.tabName)
    );
},
```

### PATCH C — full `renderCart()` replacement

Delete the current complete function:
`renderCart:function(){...}`

Replace it with:

```js
renderCart:function(){
    var s=this,total=0;

    this.cart.forEach(function(x){
        total+=Number(x.qty)||0;
    });

    RW_UI.safeText(
        RW_UI.byId('badge'),
        this.cart.length
    );

    RW_UI.safeText(
        RW_UI.byId('mcount'),
        this.cart.length
    );

    RW_UI.safeText(
        RW_UI.byId('cartLines'),
        this.cart.length
    );

    RW_UI.safeText(
        RW_UI.byId('cartQty'),
        f(total)
    );

    var adjustmentMode=
        this.type==='Adjustment'
            ?((RW_UI.byId('wsMode')||{}).value||'replace')
            :null;

    RW_UI.safeHTML(
        RW_UI.byId('cartBox'),
        this.cart.map(function(x,i){

            var qty=Number(x.qty)||0;
            var before=s.avail(x.id);

            var after=null;

            if(before!==null){

                if(s.type==='Adjustment'){

                    if(adjustmentMode==='replace'){
                        after=qty;
                    }else if(adjustmentMode==='add'){
                        after=before+qty;
                    }else{
                        after=before-qty;
                    }

                }else{
                    after=before-qty;
                }
            }

            var stockBlock=
                before===null
                    ?
                    '<div class="mt-2 text-[10px] text-slate-500">المصدر غير محدد</div>'
                    :
                    '<div class="grid grid-cols-2 gap-2 mt-2">'+

                    '<div class="rounded-xl bg-slate-800/80 border border-slate-700 p-2">'+
                    '<span class="text-[9px] text-slate-500 block">المتاح قبل</span>'+
                    '<b class="text-[11px] text-slate-200">'+
                    f(before)+
                    '</b>'+
                    '</div>'+

                    '<div class="rounded-xl bg-slate-800/80 border border-slate-700 p-2">'+
                    '<span class="text-[9px] text-slate-500 block">المتاح المتوقع بعد</span>'+
                    '<b class="text-[11px] '+
                    (after<0
                        ?'text-rose-400'
                        :'text-emerald-400')+
                    '">'+
                    f(after)+
                    '</b>'+
                    '</div>'+

                    '</div>';

            return(
                '<div class="cart-line">'+

                '<div class="flex gap-2">'+
                '<div class="flex-1 min-w-0">'+
                '<b class="text-xs block truncate">'+
                s.esc(x.name)+
                '</b>'+
                '<span class="text-[10px] text-slate-500">'+
                s.esc(x.code)+
                ' · '+
                s.esc(x.unit)+
                '</span>'+
                '</div>'+

                '<button onclick="App.remove('+i+')" class="text-slate-500">✕</button>'+
                '</div>'+

                stockBlock+

                '<div class="flex justify-between items-center mt-2">'+
                '<span class="text-[10px] text-slate-500">الكمية: '+
                qty+
                '</span>'+
                '<div class="flex gap-1">'+
                '<button class="qty" onclick="App.dec('+i+')">−</button>'+
                '<span class="w-7 text-center font-black">'+
                qty+
                '</span>'+
                '<button class="qty plus" onclick="App.inc('+i+')">+</button>'+
                '</div>'+
                '</div>'+

                '</div>'
            );
        }).join('')||

        '<div class="text-center text-slate-500 py-16">'+
        '<div class="text-5xl mb-3">🛒</div>'+
        '<b>السلة فارغة</b>'+
        '</div>'
    );

    RW_UI.safeHTML(
        RW_UI.byId('drawerBox'),
        this.cart.length
            ?document.getElementById('cartBox').innerHTML
            :'<div class="text-center text-slate-500 py-16">السلة فارغة</div>'
    );
},
```

This is read-only display logic. It does not change stock, reservation or backend state.

### PATCH D — enlarge document history window

Function:
`loadList:function(scope){`

Find exactly:
```js
.limit(150);
```

Replace exactly with:
```js
.limit(1000);
```

No other `loadList()` change.

## 13. DO NOT TOUCH

Do not change:
- Mother `companies/company-1/main.html`
- `core.js`
- `sw.js`
- `register-sw.js`
- `renderCats()`
- `App.init()`
- `allowedBranch()`
- `pickArr()`
- `pickSelect()`
- `receive()`
- `details()`
- `prepare()`
- `handleScan()`
- Production `post_stock_movement`
- Production voucher core RPCs

No regression was proven in these closed areas.

## 14. ERROR-AT-END FORENSIC RESULT

The latest user message does not contain a literal runtime Error string that can be attributed to a specific exception.

Therefore no invented error was assigned.

The actual reproducible current source defect is:
CREATE operation identity is held in `sessionStorage`, while the Production side already has durable operation identity.

The Mother integration issue is not a missing database table:
the Mother already reads the same `stock_vouchers` source.

The architectural limitation is:
the four Mother type routes are current creation forms, not historical list routes. With Mother protected from modification, the correct integration surface remains the unified Mother Voucher history.

## 15. TEST STATUS

### Production
Current baseline checked.
No Voucher residue.
No data repair required for current Voucher dataset.

### Backend transactional evidence
The previous verified transactional E2E remains valid:
CREATE → SEND → RECEIVE → COMPLETE
- Completed status
- two physical movements
- two distinct movement idempotency keys
- one operation registry record
- voucher audit events
- full rollback
- baseline restored

No new Production change is needed for this continuation.

### Browser
Browser E2E remains OPEN until the Owner applies the exact source surgery above.

Required browser gate:
1. CREATE Transfer
2. refresh/retry with the same business operation
3. exactly one Voucher
4. SEND retry → no duplicate movement
5. partial RECEIVE retry → no duplicate movement
6. COMPLETE retry → duplicate-safe
7. smart search by reference/location/status/type/creator/notes
8. projected Available Before/After visible
9. Mother unified Voucher history shows the same record
10. final Production reread

DirectSale/DirectReturn positive E2E is not executable against current Production because active vehicles = 0.
SupplierReturn positive E2E is not executable against current Production because Purchase Orders = 0.
No permanent fixtures should be created only to manufacture a green result.

## 16. ZERO-DEBT STATUS

Physical Writers outside `post_stock_movement` in the current Voucher contract:
0 proven.

Production Voucher Core:
VERIFIED

Physical Stock Centralization:
VERIFIED

Mother data visibility:
VERIFIED through the existing unified manual Voucher history

Standalone Voucher Consumer:
OPEN — Owner surgical source patch + Browser E2E

Production Voucher data repair:
NONE

New Edge Function required:
NO

## 17. NEXT SESSION INSTRUCTION

1. Read this report and the final section of `CURRENT_STATE.md`.
2. Re-fetch system HEAD/parent.
3. Re-fetch frontend HEAD/parent and current `vouchers.html` blob SHA.
4. Check whether Patch A/B/C/D is already applied.
5. Do not redo any previously closed boot/category/ACL/receive fixes.
6. If patches are applied, run Browser E2E before any source modification.
7. Reread Production after the browser run.
8. Close only when Source + Production + Deployment + Browser evidence agree.

## END REPORT276
