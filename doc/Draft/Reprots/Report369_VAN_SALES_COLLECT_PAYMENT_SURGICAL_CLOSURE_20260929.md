# REPORT369 — VAN SALES / COLLECT PAYMENT SURGICAL CLOSURE
## 2026-09-29

## SELF-AUDIT
Business Understanding: 99/100
Architecture Understanding: 99/100
Database Understanding: 100/100
Historical Understanding: 98/100
Production Understanding: 100/100
Current Understanding: 100/100
Execution Confidence: 98/100

Confirmed Facts: 11
Unknowns: 0 material to this closure
Conflicts: 0 material to this closure
Unverified Claims: 0

Historical Opened: YES
Original Opened: YES
Production Opened: YES
Current Opened: YES
Schema Checked: YES
Triggers Checked: YES
Dependencies Checked: YES
Consumers Checked: YES

## CURRENT AUTHORITATIVE STATE
Frontend repo latest main commit:
016a219419fbfcf6227135d99eea4813ea94e224

This commit is newer than the stale REPORT368 checkpoint and contains the three previously approved custody patches. They are already present and must NOT be repeated.

Protected:
- main.html
- vouchers.html
- van-sales.html

## FORENSIC FINDING — CURRENT OPEN UNIT
Target:
companies/company-1/sales/van-sales.html

Function:
App.collectPayment(code,name)

Current defect:
The frontend sends the legacy receipt payload:
- no header.customerId
- no header.operationId

Production save-receipt-voucher v8 requires both for Van Sales customer collection and routes the request to:
post_van_sales_collection_atomic

Therefore the current Van Sales collection UI is not aligned with the live v8 contract.

## PRODUCTION CORE VERIFICATION
Production currently has:
save-receipt-voucher = v8
post_van_sales_collection_atomic(uuid,uuid,uuid,text,numeric,date,uuid,uuid,uuid,text,text,text)

Direct production DB transaction test using:
customer = f159c414-f7f8-4909-ac75-f971b08ee508
representative = vansales@rawaea.com
amount = 1
operation_id = 11111111-1111-1111-1111-111111111111

returned:
success = true
receipt.status = Posted
customer ledger posted
then ROLLBACK restored all data.

No Production schema change is required.

## REQUIRED SURGICAL PATCH
DO NOT modify main.html.
DO NOT modify vouchers.html.
DO NOT modify any other van-sales function.

Replace ONLY:
App.collectPayment: function(code, name) { ... },

with the complete replacement below:

```javascript
collectPayment: function(code, name) {
    var self = this;

    Swal.fire({
        title: 'تحصيل نقدية من ' + (name || code),
        html: '<input type="number" id="collectAmount" class="swal2-input" placeholder="المبلغ المحصل" step="0.01" min="0">',
        showCancelButton: true,
        confirmButtonText: 'حفظ التحصيل',
        cancelButtonText: 'إلغاء',
        customClass: {
            popup: '!rounded-3xl',
            confirmButton: '!rounded-xl !bg-green-600',
            cancelButton: '!rounded-xl'
        },
        preConfirm: function() {
            var popup = Swal.getPopup();
            var amountEl = popup ? popup.querySelector('#collectAmount') : null;
            var amount = amountEl ? (parseFloat(amountEl.value) || 0) : 0;

            if (amount <= 0) {
                Swal.showValidationMessage('أدخل مبلغاً صحيحاً');
                return false;
            }

            return amount;
        }
    }).then(function(result) {
        if (!result.isConfirmed) return;

        var amount = Number(result.value) || 0;
        if (amount <= 0) return;

        var email = self.currentUser
            ? String(self.currentUser.email || '').trim().toLowerCase()
            : '';

        var companyId = self.companyId;

        if (!email) {
            RW_UI.toast('هوية مندوب البيع غير محددة', 'error');
            return;
        }

        if (!companyId) {
            RW_UI.toast('سياق الشركة غير محدد', 'error');
            return;
        }

        RW_UI.showLoader('جاري حفظ التحصيل...');

        function resolveCustomer() {
            var value = String(code || '').trim();

            if (!value) {
                throw new Error('هوية العميل غير محددة');
            }

            if (/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)) {
                return supabase
                    .from('customers')
                    .select('id,customer_code,name')
                    .eq('company_id', companyId)
                    .eq('id', value)
                    .eq('is_active', true)
                    .maybeSingle();
            }

            return supabase
                .from('customers')
                .select('id,customer_code,name')
                .eq('company_id', companyId)
                .eq('customer_code', value)
                .eq('is_active', true)
                .maybeSingle();
        }

        resolveCustomer()
            .then(function(customerRes) {
                if (customerRes.error) throw customerRes.error;

                var customer = customerRes.data;
                if (!customer) {
                    throw new Error('العميل غير موجود أو لا يتبع الشركة الحالية');
                }

                var operationId = crypto.randomUUID();

                var payload = {
                    header: {
                        date: new Date().toISOString().split('T')[0],
                        operationId: operationId,
                        customerId: customer.id,
                        reference: 'VAN-COL-' + operationId,
                        notes: 'تحصيل من عميل بواسطة مندوب البيع المباشر: ' + email,
                        sourceType: 'VAN_SALES'
                    },
                    lines: [{
                        accountName: customer.name || customer.customer_code || name || code,
                        description: 'تحصيل نقدية',
                        amount: amount
                    }]
                };

                return new Promise(function(resolve, reject) {
                    RW_API.call('save-receipt-voucher', payload, function(json, err) {
                        if (err) {
                            reject(new Error(err));
                            return;
                        }

                        if (!json || !json.success) {
                            reject(new Error(
                                (json && (json.error || json.msg)) ||
                                'فشل حفظ التحصيل'
                            ));
                            return;
                        }

                        resolve({
                            customer: customer,
                            operationId: operationId,
                            result: json
                        });
                    });
                });
            })
            .then(function(resultData) {
                RW_UI.hideLoader();

                Swal.fire({
                    icon: 'success',
                    title: '✅ تم التحصيل',
                    html:
                        '<div class="text-right">' +
                        '<p>تم تحصيل <strong>' +
                        RW_UI.formatNumber(amount) +
                        ' ج.م</strong> من ' +
                        (resultData.customer.name || resultData.customer.customer_code || name || code) +
                        '</p></div>',
                    confirmButtonText: 'حسناً',
                    customClass: {
                        popup: '!rounded-3xl',
                        confirmButton: '!rounded-xl !bg-green-600'
                    }
                }).then(function() {
                    self.loadBalanceDetail();
                    self.loadHomeBalanceSummary();
                });
            })
            .catch(function(error) {
                RW_UI.hideLoader();
                console.error('collectPayment:', error);
                RW_UI.toast(
                    error && error.message
                        ? error.message
                        : 'فشل حفظ التحصيل',
                    'error'
                );
            });
    });
},
```

## WHY THIS IS THE CORRECT BOUNDARY
The frontend only:
- validates amount;
- resolves the company-scoped customer;
- creates operationId;
- sends the established v8 contract.

The financial mutation remains in Production:
save-receipt-voucher v8
→ post_van_sales_collection_atomic
→ treasury + customer ledger

No new Edge Function.
No new RPC.
No new table.
No change to main.html or vouchers.html.

## VALIDATION REQUIRED AFTER OWNER APPLIES PATCH
1. Syntax gate.
2. Browser E2E from Van Sales.
3. Select an existing customer.
4. Collect a small test amount.
5. Verify receipt posted.
6. Verify customer ledger changed exactly once.
7. Repeat with the same payload only when testing idempotency.
8. Verify no unrelated stock mutation.
9. Verify the financial baseline after cleanup/reversal.

## NEXT OPEN UNITS
After this closure only:
- loadMyCustomers company/source scope
- loadCustomerPatterns scope and bounded detail query
- loadKPIs company/source scope
- loadHomeSalesSummary company/source scope
- loadMyInvoices company/source scope
- showCustomerDetail authorization/scope
- repeatOrder authorization/scope
- initiateEndOfDay settlement contract
- final Browser E2E of the patched frontend

## FINAL STATUS
collectPayment = READY FOR OWNER SURGICAL PATCH
Production financial Core = VERIFIED
Production schema/Edge modification = NONE REQUIRED
100% closure = NOT CLAIMED until Browser E2E passes after patch.

