/* RAWAEA ERP — OWNER-SIDE REALTIME SUPPLEMENT — Multiple / Partial Sales Payment Allocation
 * TARGET ONLY: papamohammed77-glitch/erp-frontend/companies/company-1/main.html
 * Apply AFTER SALES_PAYMENT_ALLOCATION_OWNER_SURGICAL_PATCH_20260914.js
 * Do not modify Current/PWA/main2, New-main, or historical fragments.
 */

/* PATCH R1 — Add one module-level channel variable immediately before:
       function _customerPaymentEndpoint() {
   This line is inside the newly inserted payment module.
*/
var _customerPaymentRealtimeChannel = null;

/* PATCH R2 — Add this function immediately BEFORE the exact line:
       function _customerPaymentEndpoint() {
*/
function _startCustomerPaymentRealtime() {
    if (_customerPaymentRealtimeChannel) {
        try { supabase.removeChannel(_customerPaymentRealtimeChannel); } catch (e) {}
        _customerPaymentRealtimeChannel = null;
    }

    var companyId = _companyId();
    if (!companyId || !supabase || typeof supabase.channel !== 'function') return;

    _customerPaymentRealtimeChannel = supabase
        .channel('rw-customer-payment-' + companyId)
        .on('postgres_changes', {
            event: '*',
            schema: 'public',
            table: 'sales_payment_receipts',
            filter: 'company_id=eq.' + companyId
        }, function () {
            _customerPaymentFetch({ action: 'list' })
                .then(function (data) {
                    _renderCustomerPaymentReceiptList(data);
                })
                .catch(function () {});
        })
        .on('postgres_changes', {
            event: '*',
            schema: 'public',
            table: 'sales_payment_allocations',
            filter: 'company_id=eq.' + companyId
        }, function () {
            _customerPaymentFetch({ action: 'list' })
                .then(function (data) {
                    _renderCustomerPaymentReceiptList(data);
                })
                .catch(function () {});
        })
        .subscribe();
}

/* PATCH R3 — In the exact replacement body of _renderReceipts() from PATCH A,
   locate the line:
       var companyId = _companyId();
   Immediately AFTER that line add:
       _startCustomerPaymentRealtime();
*/
_startCustomerPaymentRealtime();

/* PATCH R4 — Cleanup before leaving the finance receipt view is optional because
   _startCustomerPaymentRealtime() removes the previous channel before recreating it.
*/
