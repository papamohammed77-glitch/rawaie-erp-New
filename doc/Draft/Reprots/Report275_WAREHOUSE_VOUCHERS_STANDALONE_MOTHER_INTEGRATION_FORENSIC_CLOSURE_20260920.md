# Report275 — التحقيق الجنائي والإكمال الجراحي لتطبيق الأذونات المخزنية وربطه بالنظام الأم
## RAWAEA ERP — 2026-09-20

### 0. Scope Lock
- النطاق: `erp-frontend/companies/company-1/warehouse/vouchers.html`
- Mother `erp-frontend/companies/company-1/main.html`: لم يُعدّل.
- `vouchers.html`: لم يُعدّل من CTO؛ تم إعداد Owner Surgical Patch فقط.
- لا Edge Function جديدة.
- لا إعادة بناء Inventory Core.
- لا إعادة إصلاح Category / App.init / allowedBranch / pickArr / core.js / sw.js / register-sw.js.
- Production changes in this closure: لا توجد؛ لأن الـbackend الحالي أثبت كفاية العقد القائم.

### 1. قاعدة الحقيقة الحالية
الحالة الحاكمة:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

التقارير السابقة استرشادية فقط، وتم استخدامها لتحديد ما يجب إعادة فحصه، لا كمرجع حالة حالي.

### 2. Current Git / Parent
System repository:
- HEAD: `d17db440071bd7af8e7d6627bcd77a2cb9b4df0f`
- Parent: `8ad8e02564049ca3aea5a3cee9b3eaf0c53605cc`
- HEAD message: `docs: checkpoint warehouse vouchers category forensic closure`

Standalone frontend repository:
- HEAD: `f6d0558f1ae1525ccdb32bc6269ca87d9c378ae2`
- Parent: `8a1a75dd840b32cfc135178a9a9c466adefaf0ee`
- HEAD message: `Refactor voucher search and selection functionality`
- Current vouchers blob SHA: `887e9cbe85774c3702219a9030c3a6ed7a759bc4`

Mother current source inspected read-only:
- `companies/company-1/main.html`
- Current blob inspected: `e2b0dcb8317034363365fe728e8b4c33d1bf08da`

### 3. Historical reconstruction
التحليل التاريخي للأذونات اليدوية يثبت أنها Consumer مستقل للعمليات المخزنية الخارجة عن Order/Runsheet:
1. Transfer — فرع → فرع.
2. DirectSale — فرع → مركبة.
3. DirectReturn — مركبة → فرع.
4. SupplierReturn — فرع → مورد.

Scrap وAdjustment لا يعاد تعريفهما داخل Voucher physical workflow؛ لهما Adjustment Engine منفصل.

المعمارية المقصودة:
- Mother = control plane / navigation / unified visibility.
- Standalone vouchers = field/operational consumer.
- Production RPCs = business rules.
- `post_stock_movement` = physical stock engine.
- `stock_vouchers` + `stock_voucher_details` = business document.
- `inventory_log` = physical movement history.
- `inventory_control(VOUCHER_AUDIT)` = authenticated audit/detail read capability.

لا يوجد سبب تاريخي لإعادة دمج التطبيق داخل Mother.

### 4. Mother integration — ما أثبته المصدر الحالي
الـMother الحالي يملك:
- Router لـ `vouchers`.
- Form views مستقلة لـ Transfer / DirectSale / DirectReturn / SupplierReturn.
- Unified voucher list تقرأ `stock_vouchers` مباشرة من Company current context.
- Filter by type/status/date.
- Manual source visibility عبر `source='Manual'`.

إذن عمليات `vouchers.html` تدخل بالفعل في نفس مصدر البيانات الذي يقرأه Mother.

ملاحظة حاكمة:
صفحات `transfer`, `direct-sale`, `direct-return`, `supplier-return` في Mother هي Forms وليست historical list pages. لذلك لا يجوز الادعاء بأن إدخال صف تاريخي داخل هذه الـForms يمكن إنجازه من `vouchers.html` وحده. الرؤية الموحدة الحالية تتم عبر View الأذونات الموحدة، مع type filter.

أي تحويل الـForms نفسها إلى صفحات History يحتاج Mother patch مستقل، وهو خارج Scope هذه الجلسة وممنوع لمس `main.html`.

### 5. Production current truth
Production Supabase:
- companies = 1
- branches = 2
- active vehicles = 0
- active items = 16
- stock_vouchers = 0
- stock_voucher_operations = 0
- active suppliers = 1
- purchase_orders = 0

Current stock baseline for Item 1001:
- BR-01 = qty 2 / allocated 0
- BR-2 = qty 1 / allocated 0

لا توجد Voucher records حالية تحتاج data repair داخل هذا closure.

### 6. Production contract verification
Production contains the following voucher capabilities:
- `create_manual_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`
- `cancel_manual_stock_voucher_atomic`
- `inventory_control`
- `post_stock_movement`

Physical stock remains centralized:
PHYSICAL STOCK MOVEMENT → `post_stock_movement` → `stock_branches` + `inventory_log`.

The voucher execution RPCs do not introduce another physical stock engine.

### 7. Current audit path
`stock_vouchers` is covered by:
`trg_audit_stock_vouchers` → `fn_audit_trigger()` → `audit_log`.

Current `inventory_control(VOUCHER_AUDIT)` returns:
- voucher
- details
- audit
- movements

No direct client audit writer was introduced by the current vouchers Consumer.

### 8. Forensic finding — the real remaining Consumer defect
The current `vouchers.html` already contains:
- corrected Category runtime;
- corrected App.init;
- corrected branch ACL parsing;
- corrected pickArr;
- receive `operation_id`;
- create `operation_id`;
- Production RPC contract.

But one reliability gap remains:

`submit()` persists CREATE operation identity in `sessionStorage`.

Current pattern:
`RW_VOUCHER_CREATE:<company>:<type>`

with:
`sessionStorage.getItem(...)`
and
`sessionStorage.setItem(...)`.

The same function then clears the key on successful completion.

#### Why this is a real gap
`stock_voucher_operations` is the server-side idempotency registry:
- UNIQUE(company_id, operation_id)
- operation_id
- fingerprint
- voucher_id.

The browser should therefore preserve the same operation identity when a request result is lost because of refresh/tab crash/network interruption.

`sessionStorage` is tab-session scoped. A browser refresh / session reconstruction can lose the identity, allowing the same business document to be retried under a new operation identity.

This is not a physical stock bug; it is a Consumer reliability/idempotency propagation defect.

### 9. Forensic finding — list search is weaker than the current data contract
Current `filterList()` searches only:
- voucher_code
- reference
- type

The actual voucher document already contains:
- source
- destination
- created_by
- notes
- status.

The reference fields are already company-scoped and resolved by `loc()`.

Therefore search can be safely extended without a schema change.

### 10. Competitive evidence used as benchmark
Official current documentation was checked.

Odoo 19:
- stock movements cover receipts, deliveries, internal movements, customer/vendor returns and scrap;
- barcode operations are supported.

Dynamics 365:
- inventory transfer journals explicitly capture From/To dimensions;
- posted inventory journals create inspectable inventory transactions;
- inventory adjustment journals are a first-class operation.

SAP S/4HANA:
- Goods Movement covers goods receipts, goods issues, physical stock transfers and transfer postings;
- movement documentation and reporting are core capabilities.

Daftra:
- Manual transfer captures date, from/to warehouse, notes, item, quantity;
- transfer screen exposes Available Before / Available After;
- inventory movement reporting can be filtered by movement type.

Manager.io:
- Inventory Transfers support date, reference, description, item, quantity, From and To;
- Inventory Write-offs support date, reference, description, location and quantity;
- inventory reports expose movement/location information.

Competitive conclusion:
The next value that can be safely added to RAWAEA without inventing a new Business Contract is:
1. durable operation identity;
2. stronger document search;
3. visible projected stock before/after in the cart.

More advanced capabilities such as approval, attachments, lot/serial/expiry, bulk import, formal in-transit state and document export remain separate Business Contracts and are not to be inserted as silent assumptions.

### 11. Surgical Patch A — CREATE operation identity durability
File:
`erp-frontend/companies/company-1/warehouse/vouchers.html`

#### A-1 — newWorkspace
Function:
`newWorkspace:function(){`

Find exactly:
`sessionStorage.removeItem('RW_VOUCHER_CREATE:'+s.company+':'+s.type);`

Delete this line only.

Do not replace the whole function.

Reason:
The successful request already clears the key. Keeping an uncommitted operation identity allows a legitimate retry after refresh. A different new document gets a new fingerprint and therefore a new operation_id.

#### A-2 — submit
Function:
`submit:function(){`

Inside the CREATE idempotency block, replace exactly:
`sessionStorage.getItem(storageKey)`
with:
`localStorage.getItem(storageKey)`

Replace exactly:
`sessionStorage.setItem(`
with:
`localStorage.setItem(`

Inside the success branch replace exactly:
`sessionStorage.removeItem(storageKey)`
with:
`localStorage.removeItem(storageKey)`

No other line in `submit()` changes.

### 12. Surgical Patch B — smart document search
File:
`erp-frontend/companies/company-1/warehouse/vouchers.html`

Function:
`filterList:function(){`

Delete the current `filterList:function(){...}` in full.

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

هذا التغيير لا يغير Database Contract ولا الـworkflow.

### 13. Surgical Patch C — projected Available Before / After
File:
`erp-frontend/companies/company-1/warehouse/vouchers.html`

Function:
`renderCart:function(){`

Delete the current function in full.

Replace it بالكامل:

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

هذا عرض معلوماتي فقط.
لا يغير الرصيد ولا يحجز الكمية ولا يبدل الـbackend enforcement.

### 14. Surgical Patch D — extend list window
Function:
`loadList:function(scope){`

Find exactly:
`.limit(150);`

Replace with:
`.limit(1000);`

No other part of `loadList()` changes.

### 15. ما لا يجب لمسه
لا تعيد تعديل:
- `renderCats`
- `App.init`
- `allowedBranch`
- `pickArr`
- `pickSelect`
- `receive`
- `details`
- `prepare`
- `handleScan`
- `core.js`
- `sw.js`
- `register-sw.js`
- Mother `main.html`
- Production `post_stock_movement`
- Production voucher cores.

### 16. Production E2E — current closure evidence
تم تشغيل Transactional Production E2E على نفس الـRPCs الحالية وببيانات Production الموجودة، ثم ROLLBACK.

Baseline:
- BR-01 / Item 1001 = 2
- BR-2 / Item 1001 = 1

Test:
CREATE → SEND → RECEIVE → COMPLETE

النتيجة:
- status = Completed
- source qty = 1 أثناء المعاملة
- target qty = 2 أثناء المعاملة
- physical movements = 2
- distinct idempotency movements = 2
- stock voucher operation registry = 1
- stock_vouchers audit events = 4
- final transaction ROLLBACK = PASS

بعد الـrollback:
- BR-01 / Item 1001 = 2
- BR-2 / Item 1001 = 1
- stock_vouchers = 0
- stock_voucher_operations = 0

إذن لا يوجد test residue.

### 17. Limits of E2E
لا توجد سيارات نشطة في Production حاليًا.
لا توجد Purchase Orders حاليًا.
لذلك:
- Transfer backend E2E = verified.
- DirectSale / DirectReturn full positive production E2E = not executable against real current data without introducing a temporary vehicle fixture.
- SupplierReturn positive E2E = not executable against current data because there are no Purchase Orders linking supplier and branch.

هذا لا يبرر إنشاء بيانات دائمة في Production.

### 18. Browser E2E status
Browser E2E = OPEN.

السبب:
- `vouchers.html` Owner-managed.
- الجراحة لم تُطبّق في Git.
- لا يجوز إعلان Consumer Closure قبل أن يطابق الملف الجديد هذا التقرير ويجتاز Browser E2E.

### 19. Error-at-message-end forensic result
لم تحتوي الرسالة الحالية على نص Error literal محدد يمكن نسبته إلى Exception بعينه.
لذلك لم يتم اختراع Error غير موجود.

المشكلة التقنية المؤكدة القابلة للإصلاح في الحالة الحالية:
- CREATE operation identity persistence تستخدم `sessionStorage` بدل durable `localStorage`.

أما مشكلة Gateway / Edge Functions:
- لا نحتاج Function جديدة.
- لا يوجد سبب لفتح Edge capability جديدة لهذا closure.
- الحل الحالي يظل RPC + existing Edge capability.

### 20. GLOBAL WRITER STATUS
Physical writer outside `post_stock_movement` in the voucher flow:
0 proven in current voucher contract.

Manual Voucher orchestration:
- CREATE → canonical RPC
- SEND → canonical RPC
- RECEIVE → canonical RPC → `post_stock_movement`
- COMPLETE → canonical state transition
- CANCEL → canonical state transition

### 21. Competitive gap status
Implemented / contract-covered:
- multi-type manual voucher workflow
- from/to context
- reference
- notes
- quantity
- status lifecycle
- audit history
- movement history
- branch/vehicle/supplier context
- barcode/item search
- source availability
- live synchronization
- retry operation identity on RECEIVE
- retry operation identity on CREATE server side

Safe Consumer enhancements issued now:
- durable CREATE operation identity
- smart document search
- projected available before/after
- larger list window

Explicit Future Business Contracts:
- approval workflow
- attachments/documents
- lot/serial/expiry
- formal in-transit state
- bulk CSV/import
- full print/export contract
- historical before/after snapshot persisted server-side

### 22. Governance self-audit

#### Confirmed facts
- Current system HEAD/parent checked.
- Current frontend HEAD/parent checked.
- Current vouchers source inspected to EOF.
- Current Mother source inspected read-only.
- Current Production voucher RPCs inspected.
- Current Production data counts checked.
- Current audit trigger path checked.
- Current item identity contract checked.
- Current Production transactional Transfer lifecycle verified.
- Test transaction rolled back.
- Current Category fix was left untouched.
- Existing Edge Function limit was respected.
- No new Edge Function created.
- No new Production table created.
- No permanent test data created.

#### What was disproven from historical reports
- Historical “Category bug still open” is false for current source.
- Historical “filterList missing” is false for current source.
- Historical “App.init patch still absent” is false for current source.
- Historical “allowedBranch patch still absent” is false for current source.
- Historical “pickArr patch still absent” is false for current source.

#### Remaining open
- Owner applies Surgical Patch A/B/C/D.
- Browser E2E.
- Re-read Production after browser E2E.
- Only then mark Standalone Voucher Consumer = CLOSED.

### 23. Instruction for the next session — start from truth
1. Read CURRENT_STATE current section first.
2. Re-fetch system HEAD + parent.
3. Re-fetch frontend HEAD + parent.
4. Re-fetch current `vouchers.html` blob SHA.
5. Verify the exact four surgical changes are either absent or already applied.
6. Never reapply Category / App.init / ACL / boot fixes unless current source regressed.
7. Run Browser E2E before another source change.
8. After owner patch:
   - CREATE retry across refresh → one voucher
   - SEND retry → no second movement
   - partial RECEIVE retry → no extra movement
   - COMPLETE retry → duplicate-safe
   - search by reference/location/creator/status/type
   - before/after stock display
   - Mother unified voucher list sees the same record
9. Re-read Production stock_vouchers / operations / inventory_log / audit_log.
10. Close only if all evidence agrees.

### 24. Final closure
Production Voucher Core = VERIFIED
Physical Stock Centralization = VERIFIED
Mother Data Integration = VERIFIED via unified voucher list
Standalone Consumer = OPEN FOR OWNER SOURCE PATCH + BROWSER E2E
Production data repair required for current Voucher dataset = NONE
New Edge Function required = NO

## END REPORT275
