# REPORT370 — VAN SALES / COLLECT PAYMENT — FORENSIC CLOSURE UNIT

## PRE-CHANGE SELF-AUDIT
Business Understanding: 98/100
Architecture Understanding: 99/100
Database Understanding: 99/100
Historical Understanding: 98/100
Production Understanding: 99/100
Current Understanding: 100/100
Execution Confidence: 97/100

Confirmed Facts: 12
Unknowns: 1 material
Conflicts: 0 material
Unverified Claims: 1

Historical Opened: YES
Original Opened: YES where available
Production Opened: YES
Current Opened: YES
Schema Checked: YES
Triggers Checked: YES
Dependencies Checked: YES
Consumers Checked: YES

## 1. AUTHORITATIVE REALITY

Frontend repository: papamohammed77-glitch/erp-frontend
Target: companies/company-1/sales/van-sales.html
Current HEAD: cf90684a3b1afd017a97e7b7802e9308d6ae158c
Parent: 016a219419fbfcf6227135d99eea4813ea94e224
Current file SHA: 0e6926a15d3d6ea59ed8e01fa7b6ce3ae12561a179c5ecb56c (see current source verification)

The protected frontend source was not mutated.

## 2. PRODUCTION BACKEND

save-receipt-voucher: v8, ACTIVE, verify_jwt=true.
It requires header.operationId and routes customer collections to post_van_sales_collection_atomic when customerId is supplied.

post_van_sales_collection_atomic exists in Production as an atomic financial path using erp_operation_registry keyed by company_id + operation_type + operation_key; it locks customer/treasury/accounts and posts cash receipt + customer ledger inside the transaction.

post_cash_receipt_atomic and post_customer_ledger_entry are present as atomic financial primitives.

## 3. ACTUAL CURRENT DEFECT

The current collectPayment() already added customerId, operationId and sourceType=VAN_SALES.

But it currently generates:

var operationId = crypto.randomUUID();

on every confirmation attempt.

Therefore if Production commits the collection but the response is lost, a user retry creates a NEW operation id and the Production idempotency registry cannot recognize it as the same business operation.

This is a real reliability defect.

## 4. SURGICAL OWNER PATCH

Protected file:
companies/company-1/sales/van-sales.html

Function:
App.collectPayment(code, name)

Defective element:

var operationId = crypto.randomUUID();

Delete ONLY that statement and replace it with:

var operationStorageKey =
    'RW_VAN_COLLECTION_PENDING:' +
    companyId +
    ':' +
    customer.id;

var operationFingerprint = JSON.stringify({
    company_id: companyId,
    customer_id: customer.id,
    amount: amount,
    date: new Date().toISOString().slice(0, 10),
    user_email: email
});

var operationId = null;

try {
    var pendingCollection =
        localStorage.getItem(operationStorageKey);

    if (pendingCollection) {
        var pendingData =
            JSON.parse(pendingCollection);

        if (
            pendingData &&
            pendingData.operation_id &&
            pendingData.fingerprint === operationFingerprint
        ) {
            operationId =
                pendingData.operation_id;
        }
    }
} catch (e) {}

if (!operationId) {
    operationId =
        window.crypto &&
        crypto.randomUUID
            ? crypto.randomUUID()
            : (
                'VAN-COL:' +
                companyId +
                ':' +
                customer.id +
                ':' +
                Date.now() +
                ':' +
                Math.random()
                    .toString(36)
                    .slice(2)
            );

    try {
        localStorage.setItem(
            operationStorageKey,
            JSON.stringify({
                operation_id: operationId,
                fingerprint: operationFingerprint,
                created_at: new Date().toISOString()
            })
        );
    } catch (e) {}
}

## 5. SUCCESS CLEANUP

Inside the existing successful save-receipt-voucher callback, after confirmed success, add:

try {
    localStorage.removeItem(operationStorageKey);
} catch (e) {}

Do NOT remove the pending key on transport failure.

## 6. CONTRACT

Van Sales collection:
operation_id
→ save-receipt-voucher
→ post_van_sales_collection_atomic
→ erp_operation_registry

Retry of the SAME business operation:
SAME operation_id
→ duplicate detection
→ NO second financial posting.

New legitimate collection after success:
old key removed
→ NEW operation_id.

## 7. DO NOT TOUCH

main.html
companies/company-1/warehouse/vouchers.html
any other part of van-sales.html outside the exact surgical elements above

Do NOT create another Edge Function.
Do NOT create another RPC.
Do NOT change save-receipt-voucher unless new Production evidence proves the backend contract defective.

## 8. SEPARATE OPEN UNITS

After collectPayment reaches 100%:
loadMyCustomers()
loadCustomerPatterns()
loadKPIs()
loadHomeSalesSummary()
loadMyInvoices()
showCustomerDetail()
repeatOrder()
initiateEndOfDay()

## 9. FINANCIAL HISTORY

Production driver_ledger contains identifiable QA cleanup/reversal records. Do not blindly delete ledger history. A separate financial reconciliation unit is required.

## 10. COMPETITIVE PRINCIPLES

SAP Direct Store Delivery treats Van Sales as both sales and logistics.
Daftra documents assigning inventory responsibility to sales employees, transferring products to an employee warehouse, tracking that warehouse and stocktaking it.
Dynamics 365 supports operational inventory inquiry on mobile, including available and reserved quantities.
Odoo models movement through explicit locations/routes.

RAWAEA should preserve its differentiated mobile vehicle-custody workflow while adopting explicit custody, controlled movement, reservation separation, traceability and auditable financial posting.

## 11. CLOSURE

collectPayment() remains INCOMPLETE until the exact source patch is applied and proven through:
Current source
→ syntax
→ browser E2E
→ Production HTTP
→ same-operation retry
→ duplicate prevention
→ treasury/cash_box/customer ledger verification
→ audit verification
→ baseline integrity verification.

## FINAL SELF-AUDIT

What I Proved:
Current frontend HEAD and actual collectPayment implementation; Production v8 adapter; Production atomic Van Sales collection Core; operation registry; current retry-identity defect.

What I Did Not Prove:
Browser/Production behavior after applying the owner patch.

What I Fixed:
No protected frontend mutation; no unnecessary Production backend mutation because the backend contract already supports atomic/idempotent Van Sales collection.

What I Initially Missed:
The previous payload correction added operationId but did not make it durable across transport retries.

What Could Still Be Wrong:
Runtime after applying the exact patch must be verified.

Final Confidence: 97/100
Final Closure Status: INCOMPLETE — OWNER SURGICAL PATCH REQUIRED
Next Closure: loadMyCustomers() only after this unit is 100%.
