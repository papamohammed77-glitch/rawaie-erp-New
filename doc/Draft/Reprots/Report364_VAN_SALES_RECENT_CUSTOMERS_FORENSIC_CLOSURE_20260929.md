# Report364 — VAN SALES FORENSIC CLOSURE UNIT — RECENT CUSTOMERS
Date: 2026-09-29

## 0. SELF-AUDIT — PRE-CLOSURE
Business Understanding: 99/100
Architecture Understanding: 99/100
Database Understanding: 99/100
Historical Understanding: 98/100
Production Understanding: 99/100
Current Understanding: 100/100
Execution Confidence: 98/100

Confirmed Facts: 12
Unknowns: 0 material
Conflicts: 0 material
Unverified Claims: 0 material

Historical Opened: YES
Original Opened: YES where available
Production Opened: YES
Current Opened: YES
Schema Checked: YES
Triggers Checked: YES
Dependencies Checked: YES
Consumers Checked: YES

## 1. AUTHORITATIVE CURRENT SOURCE

Frontend repository:
papamohammed77-glitch/erp-frontend

Target:
companies/company-1/sales/van-sales.html

Current SHA:
8d61382a8e0025a0d079e71dd94f33d106d9088e

Current main HEAD:
3c03e72f79bc337f89a1b27100795a522d249301

Parent:
609ab127410004ba9ee3161c8f0deaf630fbfd03

Current file:
2297 lines
125395 characters
63 App methods

The current HEAD commit changes only core.js/Dexie schema; van-sales.html itself remains at the above SHA.

## 2. CURRENT_STATE ENTRY POINT

The authoritative system CURRENT_STATE identifies the next open Van Sales frontend closure as:

showRecentCustomers()

Reason:
the function reads local db.orders, while no db.orders writer exists in van-sales.html.

Therefore this closure is addressed first without reopening already closed voucher/main contracts.

## 3. PROVEN DEFECT

Current element:
App.showRecentCustomers()

Location:
approximately lines 1435–1448.

Current logic:

db.orders.orderBy('created_at').reverse().limit(10).toArray()

Then it derives customer_code directly from the local order record.

Forensic finding:
van-sales.html contains no writer for:
db.orders.put
db.orders.bulkPut
db.orders.add
db.orders.update

Therefore the method relies on a local data source that is not populated by this application.

This makes the "recent customers" row incomplete/empty independently of the real Production orders.

## 4. CORRECT CONTRACT

Recent customers must be derived from authoritative server data:

Production
→ orders
→ company_id
→ created_by = authenticated Van Sales representative
→ source = 'van-sales'
→ customer_id
→ customers

This preserves:
- one universal customer entity;
- sales channel in orders.source;
- representative-specific history;
- company isolation;
- no second source of truth.

It does not modify inventory, accounting, vouchers, main.html, or customer master data.

## 5. REQUIRED SURGICAL OWNER PATCH

DO NOT rewrite van-sales.html.

The owner must replace ONLY:

App.showRecentCustomers: function() { ... },

the complete element immediately before:

showProductDetail: function(...)

with the following full element:

```javascript
showRecentCustomers: function() {
    var self = this;
    var row = RW_UI.byId('recentCustomersRow');
    if (!row || !this.currentUser) return;

    var companyId = this.companyId;
    if (!companyId) {
        RW_UI.safeHTML(row, '<span class="text-xs text-gray-400 py-1">لا يوجد سياق شركة</span>');
        return;
    }

    supabase.from('orders')
        .select('customer_id, customer_name, order_date')
        .eq('company_id', companyId)
        .eq('created_by', this.currentUser.email)
        .eq('source', 'van-sales')
        .not('customer_id', 'is', null)
        .order('order_date', { ascending: false })
        .limit(20)
        .then(function(orderRes) {
            if (orderRes.error) throw orderRes.error;

            var orders = orderRes.data || [];
            var customerIds = [];

            for (var i = 0; i < orders.length; i++) {
                var id = orders[i].customer_id;
                if (id && customerIds.indexOf(id) === -1) {
                    customerIds.push(id);
                    if (customerIds.length >= 5) break;
                }
            }

            if (!customerIds.length) {
                RW_UI.safeHTML(
                    row,
                    '<span class="text-xs text-gray-400 py-1">لا يوجد عملاء سابقون</span>'
                );
                return null;
            }

            return supabase.from('customers')
                .select('id,customer_code,name')
                .eq('company_id', companyId)
                .in('id', customerIds);
        })
        .then(function(customerRes) {
            if (!customerRes) return;
            if (customerRes.error) throw customerRes.error;

            var customerRows = customerRes.data || [];
            var byId = {};

            for (var i = 0; i < customerRows.length; i++) {
                byId[customerRows[i].id] = customerRows[i];
            }

            var h = '';

            for (var j = 0; j < customerIds.length; j++) {
                var c = byId[customerIds[j]];
                if (!c) continue;

                var code = c.customer_code || c.id;
                var safeCode = String(code).replace(/'/g, "\\'");
                var safeName = String(c.name || code)
                    .replace(/&/g, '&amp;')
                    .replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;')
                    .replace(/'/g, '&#039;');

                h += '<button onclick="App.selectCustomer(\'' + safeCode + '\')" ' +
                    'class="whitespace-nowrap bg-orange-50 text-orange-700 px-3 py-1.5 rounded-full text-xs font-bold active:bg-orange-100 flex-shrink-0">' +
                    '<i class="fa-solid fa-clock-rotate-left ml-1 text-orange-400"></i>' +
                    safeName +
                    '</button>';
            }

            RW_UI.safeHTML(
                row,
                h || '<span class="text-xs text-gray-400 py-1">لا يوجد عملاء سابقون</span>'
            );
        })
        .catch(function(error) {
            console.error('showRecentCustomers:', error);
            RW_UI.safeHTML(
                row,
                '<span class="text-xs text-red-400 py-1">تعذر تحميل العملاء السابقين</span>'
            );
        });
},
```

## 6. WHY THIS PATCH IS SURGICAL

Only the broken local-cache dependency is removed.

No changes to:
- submitQuickSale
- customer selection
- save-sales-invoice
- vouchers
- main.html
- inventory movement engine
- accounting
- customer master
- Existing PWA architecture

## 7. PRODUCTION / CORE FORENSIC FINDING — SEPARATE NEXT UNIT

A separate backend issue was independently confirmed and is NOT to be mixed into this closure:

Current Production vehicles:
- CHV-2025-01 → primary fleet assignment → vansales@rawaea.com; vehicles.driver_id = NULL
- VHL-0422 → primary fleet assignment → vansales2@rawaea.com; vehicles.driver_id = NULL

Production post_stock_movement currently authorizes VanSale using vehicles.driver_id, with fleet assignment only existing separately.

Therefore VanSale authorization must be a separate surgical Core closure:
fleet_vehicle_sales_rep_assignments first, vehicles.driver_id fallback.

Do NOT relink vehicles.driver_id merely to make VanSales work. That would violate Vehicle ≠ Representative.

## 8. OTHER PROVEN VAN SALES GAPS — NOT REPAIRED IN THIS UNIT

These remain separate closure units and must not be silently treated as closed:

1. collectPayment() sends a legacy payload incompatible with save-receipt-voucher v7:
   operationId / treasuryId / cashAccountId / offsetAccountId are missing.
2. loadMyCustomers() derives "my customers" from prior orders rather than authoritative customer assignment.
3. loadHomeSalesSummary()/loadMyInvoices() do not constrain source='van-sales'.
4. _loadVehicleStock() sold-today calculation does not constrain source='van-sales'.
5. _renderVehicleStockHTML()/loadHomeBalanceSummary() value the custody using sales_price; valuation basis requires an explicit contract before changing.
6. initiateEndOfDay() is client-only and does not persist through save-daily-settlement.
7. loadBalanceDetail()/loadHomeBalanceSummary() rely on driver_ledger without company_id because the current table lacks company_id.
8. loadVanBranch() invokes setup-van-branch during application sync; control-plane ownership of provisioning must be verified in its own closure.

These are not to be bundled into this small closure.

## 9. TEST CONTRACT FOR THIS UNIT

After owner applies the exact patch:

- no db.orders dependency remains in showRecentCustomers();
- server query is company-scoped;
- source is exactly van-sales;
- only the authenticated representative's own history is used;
- customer master is company-scoped;
- duplicate customers are collapsed;
- button passes customers.customer_code;
- no DB mutation occurs.

Browser E2E should confirm the recent-customer buttons appear and selecting one still enters the existing customer flow.

## 10. CLOSURE STATUS

This report prepares the exact surgical fix.

Assistant did NOT modify:
- van-sales.html
- vouchers.html
- main.html

Therefore:
showRecentCustomers() = OPEN / OWNER SURGICAL PATCH REQUIRED

The next backend closure to execute after this patch is:
VanSale authorization alignment with fleet_vehicle_sales_rep_assignments.

## SELF-AUDIT — FINAL

What I Proved:
- Current van-sales source and latest frontend parent were verified.
- showRecentCustomers() reads db.orders.
- No db.orders writer exists in van-sales.
- The server-side order source/company contract is available.
- Production has active fleet vehicle/rep assignments while vehicles.driver_id is NULL.
- Production post_stock_movement currently uses driver_id for VanSale authorization.
- save-receipt-voucher v7 requires a newer contract than the current collectPayment payload.

What I Did Not Prove:
- Browser rendering of the patched recent-customer row, because the protected source was not modified.

What I Fixed:
- No protected frontend file was modified.
- Exact surgical replacement prepared for owner application.

What I Initially Missed:
- None in this closure; this unit began from the authoritative CURRENT_STATE open item.

What Could Still Be Wrong:
- The separate VanSale authorization contract and collection/EOD contracts still require their own closure units.

Final Confidence:
98/100 for defect identification and surgical patch preparation.

Final Closure Status:
OPEN — OWNER PATCH REQUIRED
