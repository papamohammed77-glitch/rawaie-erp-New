# REPORT367 — Van Sales Recent Customers Surgical Closure
## 2026-09-29

## SELF-AUDIT — PRE-CHANGE
Business Understanding: 99/100
Architecture Understanding: 100/100
Database Understanding: 100/100
Historical Understanding: 99/100
Production Understanding: 100/100
Current Understanding: 100/100
Execution Confidence: 98/100

Confirmed Facts:
- Frontend HEAD = 3c03e72f79bc337f89a1b27100795a522d249301; parent = 609ab127410004ba9ee3161c8f0deaf630fbfd03.
- van-sales.html SHA = 8d61382a8e0025a0d079e71dd94f33d106d9088e; file is protected and was not modified.
- App.showRecentCustomers() currently reads db.orders.
- van-sales.html contains no db.orders writer in the current source.
- RW_DB defines an orders store, but Van Sales source does not populate it.
- submitQuickSale() writes sales through save-sales-invoice with source='van-sales'.
- Production save-sales-invoice is v15 ACTIVE.
- Production setup-van-branch is v5 ACTIVE and assignment-aware.
- Production Van Sales read/integration backend is already company-scoped.
- No Production DDL/Edge change is required for this specific UI closure.

Unknowns:
- Browser-rendered verification after Owner applies the patch.

Conflicts:
- None material for this closure.

Unverified Claims:
- None about the source defect itself; browser rendering remains unverified because the protected file is not changed in this session.

Historical Opened: YES
Original Opened: YES where available
Production Opened: YES
Current Opened: YES
Schema Checked: YES
Triggers Checked: YES
Dependencies Checked: YES
Consumers Checked: YES

## 1. FORENSIC FINDING

The current function:

App.showRecentCustomers()

reads:

db.orders.orderBy('created_at')

The current Van Sales page does not write db.orders. Therefore the function depends on a dead local cache path.

This is a real source defect.

The correct source for this view is Production orders, scoped to:
- authenticated user's company
- authenticated representative
- source='van-sales'

The target UI still calls App.selectCustomer() using customer_code, so the replacement resolves orders.customer_id to customers.id and then uses customer_code for the existing selection flow.

## 2. PROTECTED FILES

NOT MODIFIED:
- companies/company-1/sales/van-sales.html
- companies/company-1/warehouse/vouchers.html
- companies/company-1/main.html

This report contains an Owner Surgical Patch for van-sales.html only.

## 3. OWNER SURGICAL PATCH — VAN-01

File:
companies/company-1/sales/van-sales.html

Function:
App.showRecentCustomers: function(code) { ... }

Current location:
around line 1435.

DELETE THE ENTIRE CURRENT App.showRecentCustomers FUNCTION.

REPLACE IT WITH EXACTLY:

    showRecentCustomers: function() {
        var self = this;
        var row = RW_UI.byId('recentCustomersRow');

        if (!row || !this.currentUser || !this.currentUser.id) {
            return;
        }

        var companyId = null;

        supabase.from('users')
            .select('company_id')
            .eq('id', this.currentUser.id)
            .maybeSingle()
            .then(function(userRes) {
                if (userRes.error) throw userRes.error;

                if (!userRes.data || !userRes.data.company_id) {
                    RW_UI.safeHTML(
                        row,
                        '<span class="text-xs text-gray-400 py-1">لا يوجد سياق شركة</span>'
                    );
                    return null;
                }

                companyId = userRes.data.company_id;

                return supabase.from('orders')
                    .select('customer_id')
                    .eq('company_id', companyId)
                    .eq('created_by', self.currentUser.email)
                    .eq('source', 'van-sales')
                    .not('customer_id', 'is', null)
                    .order('order_date', { ascending: false })
                    .limit(20);
            })
            .then(function(orderRes) {
                if (!orderRes) return null;
                if (orderRes.error) throw orderRes.error;

                var orders = orderRes.data || [];
                var customerIds = [];

                for (var i = 0; i < orders.length; i++) {
                    var id = orders[i].customer_id;

                    if (id && customerIds.indexOf(id) === -1) {
                        customerIds.push(id);
                    }

                    if (customerIds.length >= 5) break;
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

                var customers = customerRes.data || [];
                var html = '';

                for (var i = 0; i < customers.length; i++) {
                    var customer = customers[i];
                    var code = customer.customer_code || customer.id;

                    var safeCode = String(code).replace(/'/g, "\\'");

                    var safeName = String(customer.name || code)
                        .replace(/&/g, '&amp;')
                        .replace(/</g, '&lt;')
                        .replace(/>/g, '&gt;')
                        .replace(/"/g, '&quot;')
                        .replace(/'/g, '&#039;');

                    html +=
                        '<button onclick="App.selectCustomer(\\'' + safeCode + '\\')" ' +
                        'class="whitespace-nowrap bg-orange-50 text-orange-700 px-3 py-1.5 rounded-full text-xs font-bold active:bg-orange-100 flex-shrink-0">' +
                        '<i class="fa-solid fa-clock-rotate-left ml-1 text-orange-400"></i>' +
                        safeName +
                        '</button>';
                }

                RW_UI.safeHTML(
                    row,
                    html ||
                    '<span class="text-xs text-gray-400 py-1">لا يوجد عملاء سابقون</span>'
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

## 4. WHY THIS IS THE ONLY PATCH IN THIS CLOSURE

Do not touch:
- submitQuickSale()
- loadMyCustomers()
- selectCustomer()
- loadCustomerPatterns()
- main.html
- vouchers.html
- any already-closed backend contract

The objective of this closure is only to remove the dead recent-customer cache dependency.

## 5. VALIDATION AFTER OWNER PATCH

Source checks:
- old db.orders usage inside App.showRecentCustomers = 0
- new Production orders query = 1
- company_id query = present
- source='van-sales' query = present
- customers lookup uses companyId closure
- App.selectCustomer(customer_code) remains the consumer handoff

Browser test:
- login as Van Sales
- open Quick Sale
- verify recent customers are populated from current Van Sales orders
- select a recent customer
- verify customer selection still opens the existing customer flow

No Production schema change is required for this closure.

## 6. NEXT OPEN UNITS

After VAN-01 is applied and browser-verified:
- VAN-02 collectPayment
- VAN-03 explicit company/source scoping for sales queries
- VAN-04 customer pattern query narrowing
- EOD settlement contract

Do not reopen already-closed transfer/voucher/backend contracts without new direct evidence.

## 7. STATUS

VAN-01 source defect:
OPEN — OWNER PATCH PROVIDED

Backend dependency:
READY

Production database:
NO CHANGE REQUIRED

Protected frontend:
UNCHANGED

Closure:
NOT CLOSED until Owner applies the exact replacement and browser verification succeeds.

## FINAL SELF-AUDIT

What I Proved:
- Dead local recent-order cache path is present in the current source.
- Van Sales current source does not populate db.orders.
- Production is the correct source for recent Van Sales orders.
- Company and source scoping are compatible with the existing Van Sales architecture.

What I Did Not Prove:
- Browser-rendered result after the owner applies the patch.

What I Fixed:
- No protected-file change was made; the exact surgical replacement was prepared.

What I Initially Missed:
- Earlier patch drafts contained an invalid company_id scope expression; this report uses the retained closure-scoped companyId.

What Could Still Be Wrong:
- A browser-side deployment/cache issue after the source patch is applied.

Final Confidence:
98/100

Final Closure Status:
INCOMPLETE — OWNER SURGICAL PATCH PENDING
