# تقرير تدقيق جنائي وتنفيذ جراحي — VAN SALES
## Report 377 — 2026-09-30

## SELF-AUDIT — PRE-CHECK
Business Understanding: 98/100
Architecture Understanding: 99/100
Database Understanding: 99/100
Historical Understanding: 98/100
Production Understanding: 99/100
Current Understanding: 99/100
Execution Confidence: 97/100

Confirmed Facts: كثيرة ومثبتة من Git/Production/DB
Unknowns: 2
Conflicts: 1
Unverified Claims: 2

Historical Opened: YES
Original Opened: YES / baseline family
Production Opened: YES
Current Opened: YES
Schema Checked: YES
Triggers Checked: YES
Dependencies Checked: YES
Consumers Checked: YES

---

# 1. CURRENT REALITY

Repository: papamohammed77-glitch/erp-frontend
File: companies/company-1/sales/van-sales.html
HEAD SHA: 77fec23ef5fb91367284f17f0ce2391ff73ee922
HEAD commit: e5f3e8ed0e2a491a243bce0029aeb2e73cc824dc
Parent: 74b122f9c2721178f27dd8f495cfd61134ba610
Size: 3103 lines / 144367 characters

Reports 374–376 are now stale for exact line/SHA data. The latest Git commit is the source of truth for Current.

---

# 2. HISTORICAL COMPARISON

Historical:
rawaie-erp-review/PWA/sales/van-sales.html
SHA: 445dff4217fbf4a82f333fa716bba5d74def7680
2124 lines / 120218 characters
66 functions

Current:
3103 lines / 144367 characters
65 functions

The only function-name difference is _createVanBranch, whose responsibility was moved to setup-van-branch. The remaining operational function set is retained.

The increase is approximately 979 lines and 24149 characters. This is not treated as proof of quality by itself; it reflects later integrations and hardening.

---

# 3. WHAT IS ALREADY CORRECT IN CURRENT

Verified in latest Git:

1. syncDown derives company context from users.auth_id and company_id and scopes branches/customers/items.
2. loadVanBranch uses setup-van-branch and canonical mobile_branch_id.
3. loadMyCustomers uses the production customer-account RPC.
4. loadCustomerPatterns now scopes orders by company_id and source=van-sales and restricts order_details to returned order_ids.
5. loadKPIs is company/source scoped.
6. loadHomeSalesSummary is company/source scoped.
7. loadMyInvoices is company/source scoped.
8. collectPayment already contains successful-operation cleanup from the 74b commit.
9. showCustomerDetail uses the customer-account RPC and UUID identity.
10. submitQuickSale uses save-sales-invoice with operation_id and van-sales source.
11. submitQuickInventory uses save-inventory-count.
12. Vehicle stock reads the canonical VAN branch.

Do not repeat these changes without a new verified defect.

---

# 4. DEFECT A — repeatOrder

Current function:
App.repeatOrder()
Current location: around line 1364.

Two defects are proven in the latest Current source.

A. The initial order query is not company/source scoped.

Current query:
supabase.from('orders').select('*').eq('id', orderId).single()

It must be scoped by:
company_id = self.companyId
source = van-sales

B. The latest commit handles the Supabase response object as though it were the customer row.

Current pattern:
maybeSingle().then(function(c) {
    if (c) {
        self.selCust = { customer_code: c.customer_code, ... }
    }
})

The correct object is cRes.data.

This is a real code defect introduced by the latest commit and not a historical report issue.

## OWNER SURGICAL REPLACEMENT

Replace only the complete App.repeatOrder function with a corrected version that:
- verifies self.companyId;
- queries orders by id + company_id + source=van-sales;
- checks oRes.error;
- loads order_details by order_id;
- loads customers by id + company_id;
- reads customer from cRes.data;
- uses customer.customer_code when calling openQuickSaleForCustomer;
- does not use customer UUID as customer_code;
- preserves the existing cart construction and UI behavior.

The complete replacement is provided in the same report in the exact surgical section below.

---

# 5. DEFECT B — initiateEndOfDay

Current function:
App.initiateEndOfDay()
Current location: around line 1996.

The current function is client-only:
driver_ledger query
→ local balance calculation
→ self.eodLocked
→ success UI

It does not execute save-daily-settlement.

Production already has:
save-daily-settlement v4
post_daily_settlement_atomic(...)

The Production Core contract requires a real Delivered/Returned runsheet and an operation_id, then creates daily_settlements, settles pending driver liabilities, posts a shortage journal when applicable, and closes the runsheet.

Therefore the current UI "إقفال الوردية" is not a real settlement operation.

## OWNER SURGICAL REPLACEMENT

Replace only App.initiateEndOfDay with a function that:
- derives the public users.id already available through RW_Auth/App.currentUser;
- finds company-scoped runsheets for that driver in Delivered/Returned status;
- lets the user select the runsheet if more than one exists;
- checks driver ledger balance before settlement;
- creates/persists a UUID operation_id;
- calls save-daily-settlement through RW_API;
- clears the pending operation key only after success;
- keeps it on failure for safe retry;
- refreshes the balance view;
- marks EOD locked only when no eligible runsheet remains.

No new settlement engine is required.

---

# 6. PRODUCTION BACKEND REALITY

Production project:
fiilmooggumokxanwiyx

Verified current Edge functions:
save-sales-invoice v15 ACTIVE
save-receipt-voucher v8 ACTIVE
setup-van-branch v5 ACTIVE
save-inventory-count v5 ACTIVE
save-daily-settlement v4 ACTIVE
delete-order v9 ACTIVE
confirm-order v4 ACTIVE

Verified Core:
post_van_sales_collection_atomic
post_daily_settlement_atomic
get_van_sales_customer_accounts

Verified runsheets schema:
company_id
runsheet_code
run_date
driver_id
vehicle_id
status
picking/loading/delivery/return timestamps
loading_cycle_id
picking_reservation_released

Current Production snapshot has no runsheets at the moment of this audit, and no Van Sales orders. Therefore no permanent business fixture was created merely to manufacture a PASS.

---

# 7. COMPETITOR PRINCIPLES

Dynamics 365 Field Service explicitly treats a technician truck as a warehouse/location and transfers inventory between source warehouse and truck with corresponding quantity changes. This supports RAWAEA's mobile VAN stock model. 
Manager separates sales invoicing from receipt transactions and supports customer statements and receipt allocation.
These are principles only; RAWAEA's field workflow remains its own design.

---

# 8. REQUIRED OWNER PATCH — repeatOrder

File:
companies/company-1/sales/van-sales.html

Function:
App.repeatOrder()

Replace the complete function with:

    repeatOrder: function(orderId) {
        var self = this;

        Swal.close();
        RW_UI.showLoader('جاري تحميل الأوردر...');

        if (!this.companyId) {
            RW_UI.hideLoader();
            RW_UI.toast('سياق الشركة غير محدد', 'error');
            return;
        }

        supabase.from('orders')
            .select('*')
            .eq('id', orderId)
            .eq('company_id', this.companyId)
            .eq('source', 'van-sales')
            .maybeSingle()
            .then(function(oRes) {
                if (oRes.error) throw oRes.error;

                var order = oRes.data;

                if (!order) {
                    RW_UI.hideLoader();
                    RW_UI.toast('الأوردر غير موجود أو لا يتبع مبيعات السيارة الحالية', 'error');
                    return;
                }

                return supabase.from('order_details')
                    .select('*')
                    .eq('order_id', order.id)
                    .then(function(dRes) {
                        if (dRes.error) throw dRes.error;

                        var details = dRes.data || [];
                        self.cart = [];

                        for (var i = 0; i < details.length; i++) {
                            self.cart.push({
                                code: details[i].item_code,
                                name: details[i].item_name,
                                price: Number(details[i].unit_price) || 0,
                                unit: details[i].unit || 'حبة',
                                qty: Number(details[i].qty) || 1
                            });
                        }

                        if (order.customer_id) {
                            return supabase.from('customers')
                                .select('id,customer_code,name,area,payment_type')
                                .eq('company_id', self.companyId)
                                .eq('id', order.customer_id)
                                .maybeSingle()
                                .then(function(cRes) {
                                    if (cRes.error) throw cRes.error;

                                    var customer = cRes.data;

                                    RW_UI.hideLoader();

                                    if (!customer || !customer.customer_code) {
                                        RW_UI.toast('تعذر تحديد كود العميل لإعادة الطلب', 'error');
                                        return;
                                    }

                                    self.selCust = {
                                        customer_code: customer.customer_code,
                                        name: customer.name || order.customer_name || '',
                                        area: customer.area || order.area || '',
                                        payment_type: customer.payment_type || order.payment_type || 'نقدي'
                                    };

                                    self.openQuickSaleForCustomer(self.selCust.customer_code);
                                    RW_UI.toast('تم نسخ الأوردر للسلة', 'success');
                                });
                        }

                        RW_UI.hideLoader();
                        self.openQuickSale();
                        RW_UI.toast('تم نسخ الأوردر للسلة', 'success');
                    });
            })
            .catch(function(err) {
                RW_UI.hideLoader();
                RW_UI.toast(
                    err && err.message ? err.message : 'فشل تحميل الأوردر',
                    'error'
                );
            });
    },

---

# 9. REQUIRED OWNER PATCH — initiateEndOfDay

File:
companies/company-1/sales/van-sales.html

Function:
App.initiateEndOfDay()

Replace the complete function with:

    initiateEndOfDay: function() {
        var self = this;

        if (!this.companyId) {
            RW_UI.toast('سياق الشركة غير محدد', 'error');
            return;
        }

        var driverId = this.currentUser && this.currentUser.id
            ? this.currentUser.id
            : (RW_Auth.getUser() && RW_Auth.getUser().id
                ? RW_Auth.getUser().id
                : null);

        if (!driverId) {
            RW_UI.toast('هوية مندوب البيع غير محددة', 'error');
            return;
        }

        RW_UI.showLoader('جاري البحث عن الرانشيتات الجاهزة للتسوية...');

        supabase.from('runsheets')
            .select('runsheet_code,status,run_date,vehicle_id')
            .eq('company_id', this.companyId)
            .eq('driver_id', driverId)
            .in('status', ['Delivered', 'Returned'])
            .order('run_date', { ascending: false })
            .order('updated_at', { ascending: false })
            .limit(20)
            .then(function(res) {
                RW_UI.hideLoader();

                if (res.error) throw res.error;

                var runsheets = res.data || [];

                if (!runsheets.length) {
                    self.eodLocked = true;
                    self.renderBalanceView();
                    RW_UI.toast('لا توجد رانشيتات وصلت إلى مرحلة التسوية.', 'info');
                    return;
                }

                var options = {};
                for (var i = 0; i < runsheets.length; i++) {
                    var rs = runsheets[i];
                    options[rs.runsheet_code] =
                        rs.runsheet_code + ' — ' + rs.status + ' — ' + (rs.run_date || '');
                }

                return Swal.fire({
                    title: 'إقفال الوردية',
                    text: 'اختر الرانشيت التي تريد تسويتها وإغلاقها:',
                    input: 'select',
                    inputOptions: options,
                    inputPlaceholder: 'اختر رانشيت',
                    showCancelButton: true,
                    confirmButtonText: 'متابعة التسوية',
                    cancelButtonText: 'إلغاء',
                    customClass: {
                        popup: '!rounded-3xl',
                        confirmButton: '!rounded-xl !bg-green-600',
                        cancelButton: '!rounded-xl'
                    },
                    inputValidator: function(value) {
                        return value ? undefined : 'اختر رانشيت أولاً';
                    }
                }).then(function(choice) {
                    if (!choice.isConfirmed || !choice.value) return;

                    var runsheetCode = choice.value;
                    var opKey = 'RW_VAN_SETTLEMENT_OP:' + self.companyId + ':' + runsheetCode;
                    var operationId = null;

                    try {
                        var saved = JSON.parse(localStorage.getItem(opKey) || 'null');
                        if (saved && saved.operation_id) operationId = saved.operation_id;
                    } catch (e) {}

                    if (!operationId) {
                        operationId = window.crypto && crypto.randomUUID
                            ? crypto.randomUUID()
                            : ('VAN-SETTLE-' + Date.now() + '-' + Math.random().toString(36).slice(2));
                        try {
                            localStorage.setItem(opKey, JSON.stringify({
                                operation_id: operationId,
                                created_at: new Date().toISOString()
                            }));
                        } catch (e) {}
                    }

                    RW_UI.showLoader('جاري التحقق من الرصيد...');

                    return supabase.from('driver_ledger')
                        .select('debit,credit')
                        .eq('driver_email', self.currentUser.email)
                        .then(function(balanceRes) {
                            if (balanceRes.error) throw balanceRes.error;

                            var rows = balanceRes.data || [];
                            var totalDebit = 0;
                            var totalCredit = 0;

                            for (var j = 0; j < rows.length; j++) {
                                totalDebit += Number(rows[j].debit) || 0;
                                totalCredit += Number(rows[j].credit) || 0;
                            }

                            var balance = totalDebit - totalCredit;

                            if (balance !== 0) {
                                RW_UI.hideLoader();
                                RW_UI.toast(
                                    'يجب تصفير الرصيد أولاً. المتبقي: ' +
                                    RW_UI.formatNumber(Math.abs(balance)) +
                                    ' ج.م',
                                    'warning'
                                );
                                return;
                            }

                            RW_UI.showLoader('جاري حفظ التسوية المحاسبية...');

                            RW_API.call(
                                'save-daily-settlement',
                                {
                                    runsheet_code: runsheetCode,
                                    operation_id: operationId,
                                    notes: 'تسوية يومية للرانشيت ' + runsheetCode
                                },
                                function(json) {
                                    RW_UI.hideLoader();

                                    if (!json || !json.success) {
                                        RW_UI.showError(
                                            (json && (json.msg || json.error)) ||
                                            'فشل حفظ التسوية'
                                        );
                                        return;
                                    }

                                    try {
                                        localStorage.removeItem(opKey);
                                    } catch (e) {}

                                    supabase.from('runsheets')
                                        .select('runsheet_code')
                                        .eq('company_id', self.companyId)
                                        .eq('driver_id', driverId)
                                        .in('status', ['Delivered', 'Returned'])
                                        .limit(1)
                                        .then(function(leftRes) {
                                            self.eodLocked =
                                                !leftRes.data || leftRes.data.length === 0;
                                            self.renderBalanceView();

                                            RW_UI.toast(
                                                json.duplicate
                                                    ? 'تم استرجاع نتيجة التسوية السابقة'
                                                    : 'تم حفظ وإغلاق التسوية بنجاح',
                                                'success'
                                            );
                                        })
                                        .catch(function() {
                                            self.eodLocked = false;
                                            self.renderBalanceView();
                                        });
                                }
                            );
                        })
                        .catch(function(err) {
                            RW_UI.hideLoader();
                            RW_UI.showError(
                                err && err.message
                                    ? err.message
                                    : 'فشل التحقق من الرصيد'
                            );
                        });
                });
            })
            .catch(function(err) {
                RW_UI.hideLoader();
                RW_UI.showError(
                    err && err.message
                        ? err.message
                        : 'فشل تحميل رانشيتات التسوية'
                );
            });
    },

---

# 10. TESTS REQUIRED AFTER OWNER PATCH

Because the target frontend artifact is owner-managed, these two patches must be applied first.

Then execute in the real application:

A. repeatOrder:
- same-company Van Sales invoice → opens the correct customer.
- customer UUID is never treated as customer_code.
- wrong-company order cannot be loaded.
- non-van-sales order cannot be loaded.

B. initiateEndOfDay:
- no Delivered/Returned runsheet → no fake success.
- one eligible runsheet → settlement is posted through save-daily-settlement.
- two eligible runsheets → user chooses the runsheet.
- same operation retry → no second settlement.
- failure → pending operation remains.
- success → pending operation is removed.
- after settlement, runsheet becomes Closed and the UI refreshes.

C. Existing critical paths:
- setup van branch
- customer accounts
- vehicle stock
- quick sale
- collection
- quick inventory

No existing protected file should be rewritten wholesale.

---

# 11. DATA / PRODUCTION

Current Production has no active runsheets/orders for a safe permanent Van Sales fixture at this audit time.

Therefore no permanent fake business data was left behind.

Any runtime test requiring data should use an approved reversible fixture or a transaction/controlled test path and must verify baseline restoration.

---

# 12. FINAL STATUS

Van Sales Current:
INCOMPLETE

Already implemented in latest Git:
- customer account integration
- company/source scoping for patterns/KPIs/sales/invoices
- collection operation cleanup
- canonical vehicle branch integration
- live vehicle stock reading

Open defects:
1. repeatOrder — real Current code defect.
2. initiateEndOfDay — real business integration gap.

No Production backend mutation is required for these two defects; existing Production Core/Edge contracts already support the correct solution.

Frontend deployment of the latest Git HEAD is not verified.

100% closure is therefore not claimable.

---

# FINAL SELF-AUDIT

What I Proved:
- Current HEAD and parent.
- Historical size/function baseline.
- Production Edge contracts for Van Sales.
- Production settlement/collection Core.
- Exact defects in repeatOrder and initiateEndOfDay.
- The latest commit e5f3 fixed several older scope defects, so they must not be repeated.

What I Did Not Prove:
- Deployment of frontend HEAD 77fec... to its public hosting.
- Browser execution after the two owner patches.

What I Fixed:
- No protected frontend file was modified.
- Two exact surgical replacement blocks were prepared.

What I Initially Missed:
- e5f3 fixed old report items but introduced a response-object bug in repeatOrder.

What Could Still Be Wrong:
- Browser E2E may reveal another defect after these two patches; any new defect must be fixed in the same closure unit before moving on.

Final Confidence:
97/100

Final Closure:
INCOMPLETE — owner surgical patches + real browser verification required.
