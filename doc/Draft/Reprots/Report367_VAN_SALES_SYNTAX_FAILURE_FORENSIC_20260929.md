# REPORT367 — VAN SALES SYNTAX FAILURE FORENSIC & SURGICAL FIX
## 2026-09-29

## SELF-AUDIT
Business Understanding: 99/100
Architecture Understanding: 99/100
Database Understanding: 100/100
Historical Understanding: 99/100
Production Understanding: 100/100
Current Understanding: 100/100
Execution Confidence: 99/100

Confirmed Facts: 15+
Unknowns: 1 — whether the currently served browser artifact is exactly Git HEAD 22e2; hosting deployment is not directly evidenced here.
Conflicts: 0 material
Unverified Claims: 0 material

## 1. AUTHORITATIVE CURRENT SOURCE

Repository: papamohammed77-glitch/erp-frontend
File: companies/company-1/sales/van-sales.html
Current main HEAD: 22e2b851fde0aa136eaf6f55c617d06a4b43ed50
Parent: 3c03e72f79bc337f89a1b27100795a522d249301

The parent source parses successfully.
The current HEAD fails JavaScript parsing with: Unexpected string.
The failure is at the exact reported browser location: line 1522.

Defective element inside App.showRecentCustomers:

    html +=
        '<button onclick="App.selectCustomer(\\'' + safeCode + '\\')" ' +

This malformed quote escaping was introduced by commit 22e2b851fde0aa136eaf6f55c617d06a4b43ed50.

A full-script parse was executed against CURRENT main with V8 new Function(...) and returned Unexpected string.
A full-script parse was executed again after replacing ONLY showRecentCustomers with the corrected element below and returned PASS.

## 2. ERROR CASCADE

line 1522 SyntaxError → script aborts → App object is never defined → onclick App... raises ReferenceError.
The Tailwind CDN warning is unrelated to the crash. The apple web app capability warning is also unrelated.

## 3. SURGICAL OWNER PATCH

Protected file: companies/company-1/sales/van-sales.html
Do NOT modify main.html.
Do NOT modify warehouse/vouchers.html.
Do NOT add an Edge Function for this defect.

Delete only the complete showRecentCustomers: function(){ ... }, element immediately before the showProductDetail section.
Replace it with the following complete element:

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

                for (var j = 0; j < customers.length; j++) {
                    var customer = customers[j];
                    var code = customer.customer_code || customer.id;
                    var safeCode = String(code).replace(/'/g, "\\'");
                    var safeName = String(customer.name || code)
                        .replace(/&/g, '&amp;')
                        .replace(/</g, '&lt;')
                        .replace(/>/g, '&gt;')
                        .replace(/"/g, '&quot;')
                        .replace(/'/g, '&#039;');

                    html +=
                        '<button onclick="App.selectCustomer(\'' + safeCode + '\')" ' +
                        'class="whitespace-nowrap bg-orange-50 text-orange-700 px-3 py-1.5 rounded-full text-xs font-bold active:bg-orange-100 flex-shrink-0">' +
                        '<i class="fa-solid fa-clock-rotate-left ml-1 text-orange-400"></i>' +
                        safeName +
                        '</button>';
                }

                RW_UI.safeHTML(
                    row,
                    html || '<span class="text-xs text-gray-400 py-1">لا يوجد عملاء سابقون</span>'
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

## 4. ARCHITECTURE CHECK

The corrected element keeps the current Van Sales contract and does not create a second cache source.
RW_Auth in core.js resolves the authenticated session email to public.users.id and returns that public user id as App.currentUser.id; therefore lookup by users.id is compatible with the current shared auth layer.
The orders query is explicitly company-scoped, created_by-scoped, and source=van-sales scoped.
The customer query is company-scoped.
No inventory movement is performed by this UI helper.

## 5. PRODUCTION BACKEND CONTEXT

Production relevant functions verified:
save-sales-invoice v15 ACTIVE
save-inventory-count v5 ACTIVE
setup-van-branch v5 ACTIVE
save-receipt-voucher v8 ACTIVE
post_stock_movement remains the physical stock movement engine.
No Production DB or Edge change is required for this JavaScript syntax defect itself.

## 6. CURRENT OPEN VAN SALES UNITS

VAN-01 showRecentCustomers — source syntax defect caused by latest refactor; surgical fix prepared and syntax-validated.
VAN-02 collectPayment — open owner patch.
VAN-03 source/company scoping for sales queries — open owner patch.
VAN-04 loadCustomerPatterns order-id-bounded query — open owner patch.
EOD settlement/custody reconciliation — open business contract.
Browser-rendered E2E after owner-applied frontend patch — open.

## 7. CONTINUATION RULE

Do not modify van-sales.html automatically in this Closure Unit.
Owner applies only the surgical replacement above.
After owner patch: syntax gate → browser E2E → verify recent customers → close VAN-01 → continue VAN-02.

## FINAL SELF-AUDIT

What I Proved: parent 3c03 parses; current 22e2 fails with Unexpected string; exact failure is line 1522; replacing only showRecentCustomers with the above block makes the entire inline script parse successfully.
What I Did Not Prove: whether the currently served Cloudflare/browser artifact exactly equals Git main HEAD 22e2.
What I Fixed: prepared and syntax-validated the exact surgical replacement; no protected frontend file was modified.
What I Initially Missed: the latest showRecentCustomers refactor commit itself introduced the syntax failure.
What Could Still Be Wrong: a deployed hosting artifact may differ from Git main until deployment evidence is checked.
Final Confidence: 99/100 for root cause and surgical fix.
Final Closure Status: KNOWN DEFECT → SURGICAL PATCH READY → OWNER VERIFICATION REQUIRED.