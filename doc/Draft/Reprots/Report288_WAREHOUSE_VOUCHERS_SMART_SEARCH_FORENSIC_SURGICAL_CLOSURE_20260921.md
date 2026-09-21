# REPORT 288 — FORENSIC SURGICAL CLOSURE
## Vouchers Smart Search + Van Sales Integration
### RAWAEA ERP — 2026-09-21

---

## 1. نطاق المهمة

هذه الجلسة محصورة في:

- تبويب **الأذونات المخزنية** داخل النظام الأم.
- الملف:
  `companies/company-1/warehouse/vouchers.html`
- التكامل الوظيفي مع:
  `companies/company-1/sales/van-sales.html`
- تدفق DirectSale / DirectReturn / SupplierReturn.
- إصلاح البحث الذكي والربط السياقي دون إعادة بناء ما تم إغلاقه سابقًا.
- عدم تعديل `main.html`.
- عدم تعديل `vouchers.html` مباشرة في المستودع؛ تم تجهيز Owner Changeset كامل فقط.
- عدم إنشاء Edge Function جديد.

---

## 2. مصادر الحالة المعتمدة

### 2.1 Governance

تمت قراءة أحدث نسخة من:

`doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`

المبادئ الحاكمة المستخدمة في هذه المهمة:

1. التقرير ليس مصدر الحالة الحالية.
2. CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT هي أساس الحكم.
3. الدراسة التاريخية تسبق أي تعديل.
4. Writer/Capability واحد في كل Closure Unit.
5. لا تغيير في سلوك يبدو غريبًا قبل إثبات العقد.
6. لا Dual Write في Physical Stock.
7. لا إنشاء Edge Function جديد عند وجود RPC/Capability قائم يمكنه تنفيذ المطلوب.
8. لا Data Repair بالتخمين.
9. Owner Source Delivery Rule: ملف الواجهة لا يتم تعديله مباشرة إذا كان التغيير من اختصاص المالك.
10. لا يُعلن Browser E2E مغلقًا دون اختبار المتصفح الفعلي.

---

## 3. Current Git

### 3.1 System repository

Repository:

`papamohammed77-glitch/rawaie-erp-New`

Current HEAD:

`21e10441c593ca430a597284d5eaaeb2c3d49eb9`

Message:

`state: record Report287 vouchers and Van Sales forensic closure`

Parent:

`b12caa93c87ab87f4989c5f13ce31fe29fe613c0`

### 3.2 Mother frontend repository

Repository:

`papamohammed77-glitch/erp-frontend`

Latest repository HEAD at investigation time:

`7de2ef29cd701e20dbf227c9edadbd9cd9426bfa`

The latest commit before the unrelated Mother HR extraction was:

`58671e974675f1dd1d673664fc38248fc3a1132a`

Target file commit:

`76e5b12fb88f85f5df1ab4f758dbacb5f7af9ae1`

Message:

`Refactor receive and prepare functions in vouchers.html`

Target commit parent:

`36e521f78c8507e431bb9eb780269612c2d6cbf0`

Current target file blob:

`99f93c5a20a8d83e986f4efc6b5ed5fd34e71aac`

Current file length:

1507 lines.

---

## 4. Current Source — Mother Integration

The Mother application exposes:

`الأذونات المخزنية`

as the independent Vouchers application.

The Mother route remains untouched.

The Vouchers application remains responsible for warehouse operations that are **not order/runsheet fulfillment operations**, specifically:

- Transfer.
- DirectSale.
- DirectReturn.
- SupplierReturn.
- Scrap / Adjustment engine paths where enabled.

Order fulfillment remains in its own chain:

Order -> Runsheet -> Picking -> Loading -> Delivery -> Return / Unloading.

This separation is intentional and was preserved.

---

## 5. Historical Reconstruction

Historical architecture confirms:

### DirectSale

`Branch -> Vehicle`

The vehicle is the physical stock container for Van Sales.

### DirectReturn

`Vehicle -> Branch`

The current architecture is two-stage:

1. SEND: decrease mobile vehicle stock.
2. RECEIVE: increase the receiving branch.

Changing DirectReturn SEND into one-step Vehicle -> Branch stock addition would break the currently implemented lifecycle.

### SupplierReturn

`Branch -> Supplier`

Current Production does not contain a supplier-branch master relation.

The authoritative current creation contract requires evidence of a real purchase relationship:

`purchase_orders(company_id, supplier_id, branch_id)`

Therefore the UI must never invent a supplier/branch relationship.

---

## 6. Current Production Reality

Current live data was queried directly after the investigation and after all transactional tests:

- companies = 1
- branches = 3
- active direct-sales reps = 1
- active mobile-stock vehicles = 1
- active suppliers = 1
- purchase_orders = 0
- purchase_invoices = 0
- purchase_returns = 0
- stock_vouchers = 1
- stock_voucher_details = 3
- stock_voucher_operations = 1
- inventory_log = 3
- audit_log = 2031
- orders = 0
- runsheets = 0

Important live identities:

### Direct Sales Representative

- id = `111b0730-a977-4d11-bcd0-2427b178a9e5`
- email = `vansales@rawaea.com`
- role = `مندوب بيع مباشر`
- status = `Active`
- allowed branch = `BR-01`

### Vehicle

- id = `5fe9d0b6-fc54-4cc6-9bff-ede0e8557dd8`
- vehicle_code = `VEH-TEST-260921`
- license_plate = `س ن ر 6021`
- driver_id = Direct Sales Representative
- mobile_branch_id = `5372503d-f638-4e7f-808d-bda585825b2f`
- mobile_stock_enabled = true
- status = Active

### Main Branch

- id = `a38332b6-6cea-480a-ada1-6eb6ab0590db`
- code = `BR-01`

### Supplier

- id = `87c5a847-8e05-492e-a15d-30e0a5cc93cc`
- code = `SUPP-1001`
- name = `ابراهيم الأبيض`
- status = Active

### Current Stock Baseline

Item `1001`:

- Main branch = 2
- Mobile branch = 0

There are currently no Purchase Orders in Production. Therefore there is currently no verified SupplierReturn supplier/branch relation.

---

## 7. Production Writer Verification

The current physical stock writer is still:

`public.post_stock_movement`

The reviewed voucher execution path reaches it.

No parallel physical stock engine was introduced.

No new Edge Function was introduced.

Current Edge capabilities remain:

- create-stock-voucher
- send-stock-voucher
- receive-stock-voucher
- complete-stock-voucher
- cancel-stock-voucher

The project-wide Edge count/spend restriction was therefore not aggravated.

---

# 8. FORENSIC FINDING — DirectSale Vehicle Smart Search

## Faulty element

File:

`companies/company-1/warehouse/vouchers.html`

Function:

`pickArr:function(key){`

Current line:

approximately 853.

Current DirectSale vehicle candidate gate contains:

`rid`

as a mandatory condition:

`rid && v.driver_id===rid`

Therefore:

- Source branch selected.
- No representative selected.
- Vehicle field receives an empty candidate array.
- The already-existing smart search engine cannot search a vehicle that was filtered out before search scoring.

This is the actual root cause.

The smart-search function itself is not missing.

The candidate provider is incorrectly gated.

---

## 9. FORENSIC FINDING — DirectSale Selection Dependency

File:

`companies/company-1/warehouse/vouchers.html`

Function:

`pickSelect:function(key,id){`

Current line:

approximately 976.

Current generic selection only writes:

- hidden id
- visible label

When a DirectSale vehicle is selected first, the current implementation does not establish the representative from:

`vehicle.driver_id`

Therefore a vehicle-first search path cannot complete the business context.

This is the second half of the same UI defect.

---

# 10. FORENSIC FINDING — SupplierReturn False Availability

File:

`companies/company-1/warehouse/vouchers.html`

Function:

`pickArr:function(key){`

Current SupplierReturn fallback:

`return s.refs.suppliers||[];`

When the branch has no verified purchase relationship, all suppliers become searchable.

Production currently has:

`purchase_orders = 0`

Therefore the current fallback exposes a supplier that the server-side contract will reject.

This is a frontend contract drift defect.

The backend contract is correct and must not be weakened.

---

# 11. What was deliberately NOT changed

The following are already aligned and were left untouched:

`main.html`

`loadRefs:function(){`

`pickSearch:function`

`routeHtml:function`

`submit:function`

`prepare:function(){`

`handleScan:function(code){`

The latest target-file commit already contains the required company-scoped `prepare` and barcode `handleScan` work.

Repeating those fixes would create needless churn.

---

# 12. SURGICAL OWNER PATCH V-03

## File to modify

`companies/company-1/warehouse/vouchers.html`

## Exact element

Delete the complete function beginning with:

`pickArr:function(key){`

at approximately line 853,

ending immediately before:

`pickShow:function(key){`

## Replace the complete function with:

```javascript
pickArr:function(key){
    var s=this;

    var bid=(RW_UI.byId('wsFrom')||{}).value||'';

    var b=(s.refs.branches||[]).find(function(x){
        return x.id===bid;
    });

    var userBranches=
        (s.refs.branches||[]).filter(function(x){
            return s.allowedBranch(s.user,x);
        });

    if(key==='wsFrom'){

        if(s.type==='DirectReturn'){

            return (s.refs.vehicles||[]).filter(function(v){

                var vb=s.vehicleBranch(v);

                var rep=
                    (s.refs.reps||[]).find(function(r){
                        return r.id===v.driver_id;
                    });

                return (
                    v.status==='Active' &&
                    !!vb &&
                    v.mobile_stock_enabled!==false &&
                    !!rep
                );
            });
        }

        return userBranches;
    }

    if(key==='wsRep'){

        return (s.refs.reps||[]).filter(function(r){

            return (
                !!b &&
                s.allowedBranch(s.user,b) &&
                s.allowedBranch(r,b)
            );
        });
    }

    if(key==='wsTo'&&s.type==='Transfer'){
        return userBranches;
    }

    if(key==='wsTo'&&s.type==='DirectSale'){

        var rid=(RW_UI.byId('wsRep')||{}).value||'';

        return (s.refs.vehicles||[]).filter(function(v){

            var vb=s.vehicleBranch(v);

            var rep=
                (s.refs.reps||[]).find(function(r){
                    return r.id===v.driver_id;
                });

            return (
                v.status==='Active' &&
                !!vb &&
                v.mobile_stock_enabled!==false &&
                !!rep &&
                !!b &&
                s.allowedBranch(s.user,b) &&
                s.allowedBranch(rep,b) &&
                (!rid||v.driver_id===rid)
            );
        });
    }

    if(key==='wsTo'&&s.type==='DirectReturn'){

        var vid=(RW_UI.byId('wsFrom')||{}).value||'';

        var vv=
            (s.refs.vehicles||[]).find(function(x){
                return x.id===vid;
            });

        var rp=
            vv &&
            (s.refs.reps||[]).find(function(x){
                return x.id===vv.driver_id;
            });

        return userBranches.filter(function(x){

            return (
                !!x &&
                (!rp||s.allowedBranch(rp,x))
            );
        });
    }

    if(key==='wsTo'&&s.type==='SupplierReturn'){

        var m=(s.refs.supplierBranchMap||{})[bid];

        if(m&&Object.keys(m).length){

            return (s.refs.suppliers||[]).filter(function(x){
                return !!m[x.id];
            });
        }

        return [];
    }

    return userBranches;
},
```

### Result of V-03

DirectSale vehicle candidates are now available when the representative field is empty.

When a representative has already been selected, the list remains filtered to that representative.

SupplierReturn displays only suppliers proven to belong to the selected branch through existing purchase-document evidence.

---

# 13. SURGICAL OWNER PATCH V-04

## File to modify

`companies/company-1/warehouse/vouchers.html`

## Exact element

Delete the complete function beginning with:

`pickSelect:function(key,id){`

at approximately line 976,

ending immediately before:

`routeHtml:function()`

## Replace the complete function with:

```javascript
pickSelect:function(key,id){
    var s=this,
        arr=this.pickArr(key)||[],
        x=arr.find(function(z){
            return z.id===id;
        });

    if(!x){
        return;
    }

    if(key==='wsFrom'&&s.type==='DirectReturn'){

        var vb=s.vehicleBranch(x);

        if(!vb){
            RW_UI.toast(
                'المركبة لا تملك مخزنًا متنقلًا صالحًا',
                'error'
            );
            return;
        }

        RW_UI.byId('wsFrom').value=x.id;
        RW_UI.byId('wsFromSearch').value=x.vehicle_code||x.license_plate;
        RW_UI.byId('wsFromMenu').classList.add('hidden');

        var r=s.refs.reps.find(function(rp){
            return rp.id===x.driver_id;
        });

        RW_UI.byId('wsRep').value=r?r.id:'';
        RW_UI.byId('wsRepSearch').value=r?(r.name||r.email):'';

        if(r){
            RW_UI.byId('wsRepSearch').setAttribute(
                'readonly',
                'readonly'
            );
        }else{
            RW_UI.byId('wsRepSearch').removeAttribute(
                'readonly'
            );
        }

        s.summary();
        s.renderProducts();

        return;
    }

    RW_UI.byId(key).value=x.id;

    if(key==='wsRep'){

        RW_UI.byId(key+'Search').value=x.name||x.email;

    }else if(key==='wsTo'&&s.type==='DirectSale'){

        RW_UI.byId(key+'Search').value=
            x.vehicle_code||
            x.license_plate||
            x.model||
            '';

        var vehicleRep=
            (s.refs.reps||[]).find(function(rp){
                return rp.id===x.driver_id;
            });

        var sourceBranch=
            (s.refs.branches||[]).find(function(bb){
                return bb.id===(RW_UI.byId('wsFrom')||{}).value;
            });

        if(
            !vehicleRep||
            !sourceBranch||
            !s.allowedBranch(vehicleRep,sourceBranch)
        ){

            RW_UI.toast(
                'المركبة لا تملك مندوب بيع مباشر صالحًا لهذا الفرع',
                'error'
            );

            RW_UI.byId(key).value='';
            RW_UI.byId(key+'Search').value='';

            return;
        }

        RW_UI.byId('wsRep').value=vehicleRep.id;
        RW_UI.byId('wsRepSearch').value=
            vehicleRep.name||
            vehicleRep.email||
            '';

        RW_UI.byId('wsRepSearch').setAttribute(
            'readonly',
            'readonly'
        );

    }else if(key==='wsTo'&&s.type==='SupplierReturn'){

        RW_UI.byId(key+'Search').value=
            x.name||
            x.supplier_code||
            '';

    }else{

        RW_UI.byId(key+'Search').value=
            x.name||
            x.vehicle_code||
            x.supplier_code||
            x.branch_code||
            '';
    }

    RW_UI.byId(key+'Menu').classList.add('hidden');

    if(key==='wsFrom'&&s.type==='DirectSale'){

        RW_UI.byId('wsRep').value='';
        RW_UI.byId('wsRepSearch').value='';
        RW_UI.byId('wsRepSearch').removeAttribute('readonly');

        RW_UI.byId('wsTo').value='';
        RW_UI.byId('wsToSearch').value='';
    }

    if(key==='wsRep'&&s.type==='DirectSale'){

        RW_UI.byId('wsTo').value='';
        RW_UI.byId('wsToSearch').value='';
        RW_UI.byId('wsRepSearch').removeAttribute('readonly');
    }

    s.updateSource();
},
```

### Result of V-04

The vehicle can be selected first.

The application resolves:

`vehicle.driver_id -> Direct Sales Representative`

and writes that identity into the representative field.

The representative becomes readonly after vehicle-first selection because the vehicle's driver is the authoritative custodian identity.

This does not change the Production contract.

---

# 14. SupplierReturn contract — explicit rule

Do not change the existing submit validation.

Do not replace the current server contract with:

- all suppliers;
- supplier type guessing;
- branch-name guessing;
- manually inferred branch assignment.

The Production contract is explicit:

`purchase_orders.company_id + supplier_id + branch_id`

must prove the relationship.

Current Production has zero purchase orders.

Therefore the correct current UX is:

- no verified relation -> no supplier results;
- verified relation -> smart search returns that supplier;
- submit remains protected by the same server validation.

This is a deliberate fail-closed behavior.

---

# 15. Production change set

No Production DDL/DML was required for this closure.

Reason:

- DirectSale backend is already correct.
- DirectReturn two-stage backend is already correct.
- SupplierReturn backend guard is already correct.
- Rep identity and vehicle custody are already represented in Production.
- The defect is in the frontend candidate provider and selection binding.

No new Edge Function was created.

No existing Edge Function required a new version for this specific closure.

---

# 16. DirectReturn Production E2E

A transactional E2E was executed directly against the live database.

### Step 1

Create DirectSale:

`Branch -> Vehicle`

Result:

- main stock delta = -1
- mobile stock delta = +1

### Step 2

Create and SEND DirectReturn:

`Vehicle -> Branch`

SEND stage:

- main stock delta = 0
- mobile stock delta = -1

This was intentionally not treated as a defect because the current architecture is two-stage.

### Step 3

RECEIVE the DirectReturn:

- main stock delta = +1
- mobile stock delta = 0

### Final

`overall_restored = true`

Then the entire transaction was rolled back.

Final Production remained:

- main item 1001 = 2
- mobile item 1001 = 0
- temporary IN-2 = 0
- temporary IN-3 = 0

Therefore no Production data contamination was left by the E2E.

---

# 17. Frontend static verification

Current source blob:

`99f93c5a20a8d83e986f4efc6b5ed5fd34e71aac`

The surgical patch was assembled against this exact blob.

JavaScript parse/compile check:

`PASS`

Behavioral source test:

### Current source

DirectSale, source branch selected, representative empty:

`vehicle candidates = 0`

### Patched source

Same context:

`vehicle candidates = 1`

The real current vehicle identity was used in the test.

SupplierReturn:

- current source with empty verified relation: supplier candidate is exposed.
- patched source with empty verified relation: 0 candidates.
- patched source with a synthetic verified branch->supplier map: 1 candidate.

Vehicle-first selection:

- hidden vehicle id populated.
- representative id resolves from vehicle.driver_id.
- representative becomes readonly.

---

# 18. Integration with Van Sales

Current Van Sales source:

`companies/company-1/sales/van-sales.html`

Current blob:

`8d61382a8e0025a0d079e71dd94f33d106d9088e`

Closed commit:

`36e521f78c8507e431bb9eb780269612c2d6cbf0`

Parent:

`ff13516e04050a74d87771f949bcb69f7e085f3d`

Previously proven fixes were not repeated:

1. tenant-safe operation identity.
2. company-scoped sync.
3. offline startup recovery.
4. Dexie item identity correction.

The Vouchers integration now aligns with the same Production relationship:

`vehicle.driver_id`

is the representative/custodian identity for the vehicle's mobile stock.

No schema reinterpretation was introduced.

---

# 19. Competitive benchmark

Current official documentation was compared at the capability level, not by copying another product.

### Odoo

Odoo's current inventory/barcode workflow supports product/location lookup, barcode-driven operations, inventory adjustments and mobile execution.

Source:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/count_products.html

### Microsoft Dynamics 365

Dynamics supports inventory journals for movement, adjustment, transfer, item arrival, counting and tag counting. Transfers distinguish From/To inventory dimensions.

Source:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

### SAP

SAP's inventory transfer model explicitly represents issue and receipt, with two-step transfer concepts where in-transit visibility is required.

Source:
https://help.sap.com/

### Daftra

Daftra's transfer workflow explicitly captures date, From Warehouse, To Warehouse, notes, item quantity, and available quantity before/after.

Source:
https://docs.daftra.com/en/tutorial/transferring-stock/

https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/

### Competitive conclusion for RAWAEA

The Vouchers application already has the right architectural separation for:

- physical source/target;
- mobile-stock location;
- operational document lifecycle;
- centralized physical stock engine;
- contextual smart lookup.

The current closure therefore targets the missing interaction quality rather than rebuilding the business model.

---

# 20. No speculative feature expansion in this closure

The following ideas remain future capabilities, not reasons to alter the current contract now:

- richer supplier-master/branch authorization object;
- item available-before / available-after presentation in voucher lines;
- serial/lot constraints where business data supports them;
- attachment/evidence workflow;
- advanced keyboard navigation;
- dedicated transfer-in-transit state for cases where RAWAEA later adopts such a business workflow.

They are not merged into this surgical patch because current Production data/contracts do not establish their required business semantics.

---

# 21. Owner execution instruction

Apply only:

### V-03

`pickArr:function(key){`

### V-04

`pickSelect:function(key,id){`

Do not modify:

- `main.html`
- `loadRefs:function(){`
- `pickSearch:function`
- `routeHtml:function`
- `submit:function`
- `prepare:function(){`
- `handleScan:function(code){`

After applying the two functions:

1. verify the resulting `vouchers.html` parses successfully;
2. open DirectSale after selecting BR-01;
3. type/search in:
   - مندوب البيع المباشر
   - المركبة
4. select vehicle first and verify representative is auto-bound;
5. switch to SupplierReturn;
6. confirm no supplier appears while Production has no verified branch relationship;
7. after a real purchase order exists for a supplier and branch, verify the supplier becomes searchable;
8. execute authenticated Browser E2E.

---

# 22. Browser E2E status

Status:

`OPEN — OWNER EXECUTION REQUIRED`

Reason:

The database and source behavior have been tested, but a real browser session against the deployed frontend was not executed in this closure.

No claim of browser-level 100% closure is made.

---

# 23. Final Closure Matrix

| Item | Historical | Production | Current Source | Target | Status |
|---|---|---|---|---|---|
| DirectSale Branch->Vehicle | Confirmed | Confirmed | Partially blocked UI-first order | Smart vehicle-first UX | OWNER PATCH V-03/V-04 |
| DirectSale Rep search | Confirmed | Confirmed | Already scoped | Preserve | CLOSED |
| DirectSale Vehicle search | Confirmed | One eligible vehicle exists | Candidate gate requires rep | Search with/without rep | OWNER PATCH V-03 |
| Vehicle->Rep binding | Confirmed | vehicle.driver_id exists | Missing vehicle-first UI binding | Canonical binding | OWNER PATCH V-04 |
| DirectReturn Vehicle->Branch | Confirmed | Two-stage verified | Current UI supports selection | Preserve | PRODUCTION CLOSED |
| SupplierReturn Branch->Supplier | Confirmed | No PO relations | UI exposes all suppliers on empty map | Fail-closed smart search | OWNER PATCH V-03 |
| SupplierReturn server guard | Confirmed | Active | Consumer aligned | Preserve | CLOSED |
| Physical stock writer | post_stock_movement | Active | Existing path | Central engine | CLOSED |
| New Edge Function | Not required | None created | Existing Edge retained | None | CLOSED |
| main.html | Untouched | N/A | Untouched | Untouched | CLOSED |
| Browser E2E | Historical only | Not run in browser | Static verified | Real browser | OPEN |

---

# 24. SELF-AUDIT — FINAL

## What I Proved

- Current target source and exact target blob.
- Latest target commit and parent.
- Current Production identities for branch, representative, vehicle and supplier.
- Current Production absence of purchase-order supplier/branch relations.
- Root cause of DirectSale vehicle search gating.
- Root cause of SupplierReturn false availability.
- Current DirectReturn two-stage Production contract.
- DirectSale -> DirectReturn -> Receive stock restoration through `post_stock_movement`.
- No Production test contamination after rollback.
- No new Edge Function was necessary.
- Existing closed Van Sales fixes were not repeated.

## What I Did Not Prove

- Real browser rendering on the deployed frontend after Owner applies V-03/V-04.
- Multi-device browser retry behavior for this exact search UI.

## What I Fixed in this session

Production:

- No new Production mutation because no Production defect remained for this closure.

Repository:

- Created this forensic report.
- Prepared the exact Owner replacement functions.
- Updated continuity state is required below.

## What I Initially Risked Misreading

DirectReturn SEND by itself looks like it should increase the receiving branch.

Current historical and Production architecture prove otherwise:

`SEND = remove from vehicle`

`RECEIVE = add to branch`

This was explicitly validated end-to-end.

## What Could Still Be Wrong

Only the frontend deployment/application of V-03/V-04 and Browser E2E remain outside this closure.

## Final Closure Status

`VOUCHER SMART SEARCH FORENSIC ROOT CAUSE = CLOSED`

`PRODUCTION CONTRACT = CLOSED`

`OWNER SOURCE CHANGES = PREPARED`

`BROWSER E2E = OPEN`

`GLOBAL INVENTORY CORE = NOT REOPENED`

---

# 25. Continuity Instructions For The Next CTO / Assistant

Start here and do not restart the investigation:

1. Verify CURRENT GIT target blob `99f93c5a20a8d83e986f4efc6b5ed5fd34e71aac`.
2. Verify current Mother HEAD and target-file parent.
3. Verify Production counts and Item 1001 stock baseline.
4. Do not change `main.html`.
5. Do not repeat Report286/287 closed work.
6. Apply only V-03 and V-04 from this report.
7. Reparse the full file.
8. Run Browser E2E for DirectSale vehicle-first selection and SupplierReturn fail-closed lookup.
9. Re-snapshot Production at the exact end of the Browser E2E.
10. Update this state section only after the evidence is real.
11. If a new defect appears, open a new Closure Unit rather than modifying this one retroactively.

---

# END OF REPORT 288
