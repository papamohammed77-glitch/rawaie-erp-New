# REPORT371 — VAN SALES / COLLECT PAYMENT — FORENSIC COMPLETION CHECKPOINT
## 2026-09-29

## PRE-CHANGE SELF-AUDIT

Business Understanding: 99/100
Architecture Understanding: 99/100
Database Understanding: 100/100
Historical Understanding: 98/100
Production Understanding: 100/100
Current Understanding: 100/100
Execution Confidence: 97/100

Confirmed Facts: 16
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

# 1. AUTHORITATIVE REALITY

The protected frontend artifact is:
- Repository: papamohammed77-glitch/erp-frontend
- File: companies/company-1/sales/van-sales.html
- Current HEAD: cf90684a3b1afd017a97e7b7802e9308d6ae158c
- Parent: 016a219419fbfcf6227135d99eea4813ea94e224
- Current file SHA: 0e6926a15d3d6ea59ed8e01fa7b1ce5de3d6ea59ed8e01fa7b1ce5adc140235
- Protected: no frontend mutation was performed.

The system governance requires one Closure Unit at a time and forbids treating reports as proof.

# 2. COLLECT PAYMENT — ACTUAL DEFECT

Current App.collectPayment() already supplies:
- customerId
- operationId
- sourceType = VAN_SALES

The remaining frontend defect is:

    var operationId = crypto.randomUUID();

This creates a NEW business operation ID on every confirmation attempt.

Therefore:
Successful financial posting + lost response
→ user retries
→ NEW operation_id
→ server idempotency registry cannot recognize the retry as the same business operation
→ possible duplicate collection.

This is a real reliability defect in the protected frontend.

# 3. PRODUCTION BACKEND FINDING — FIXED NOW

Production save-receipt-voucher v8 was verified.
It routes customer collections to:
post_van_sales_collection_atomic

Production post_van_sales_collection_atomic was inspected directly.

Before this corrective change it posted:
- treasury receipt
- customer ledger

but did NOT reduce the direct-sales representative's driver liability.

That conflicted with the established RAWAEA custody contract:
credit Van Sale increases the representative liability;
customer collection must reduce that liability.

The production driver_ledger data currently shows:
- vansales@rawaea.com mathematical net = 383
- vansales2@rawaea.com mathematical net = 135

This historical data was not deleted or rewritten.

## Corrective Production change executed

Migration:
20260929193000_van_sales_collection_driver_ledger_credit

The function now:
- validates an active Direct Sales Representative in the same company;
- locks that representative;
- posts the treasury receipt atomically;
- posts the customer ledger credit atomically;
- posts a matching driver-ledger CREDIT for the collected amount;
- uses the same operation identity and erp_operation_registry for idempotency;
- returns the driver-ledger result.

Production application result:
SUCCESS

The deployed function definition was re-read after application and confirmed to contain the driver-ledger credit call.

# 4. GIT SOURCE ALIGNMENT

The same migration source has been recorded in:
supabase/migrations/20260929193000_van_sales_collection_driver_ledger_credit.sql

Production and canonical Git now contain the corrective backend source.

No new Edge Function was created.

# 5. REQUIRED FRONTEND SURGICAL PATCH — OWNER

Protected file:
companies/company-1/sales/van-sales.html

Function:
App.collectPayment(code, name)

Do NOT modify any other element.

## DEFECTIVE ELEMENT

Delete ONLY:

    var operationId = crypto.randomUUID();

## FULL REPLACEMENT

Replace it with this complete element:

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

IMPORTANT:
The existing successful save-receipt-voucher callback must also remove the pending identity only after confirmed success:

    try {
        localStorage.removeItem(operationStorageKey);
    } catch (e) {}

Do NOT remove it on transport failure.

Because operationStorageKey is local to the customer-resolution branch, pass it through the resolved object if necessary so the existing final success handler can remove it safely.

# 6. DO NOT TOUCH

- main.html
- companies/company-1/warehouse/vouchers.html
- any other part of van-sales.html
- save-receipt-voucher v8
- post_cash_receipt_atomic
- post_customer_ledger_entry

No new Edge Function.
No new RPC for this frontend defect.

# 7. WHY THIS MATCHES THE ARCHITECTURE

The permanent contract is:

Van Sales Collection
→ authenticated user/company
→ save-receipt-voucher
→ post_van_sales_collection_atomic
→ post_cash_receipt_atomic
→ post_customer_ledger_entry
→ post_driver_ledger_entry (credit)
→ erp_operation_registry

The frontend only carries a durable operation identity across transport retries.

The database remains the final financial authority.

# 8. TEST REQUIREMENTS

After the owner applies the exact frontend patch:

A. Syntax
- full V8 parse of van-sales.html

B. Browser E2E
- open Van Sales
- select real customer
- collect a positive amount
- confirm success

C. Same-operation retry
- reuse the persisted operation identity
- verify duplicate=true / no second posting

D. Financial verification
- cash_box: exactly one receipt
- treasury balance: exactly one increase
- customer_ledger: exactly one credit
- driver_ledger: exactly one matching credit
- erp_operation_registry: exactly one completed operation

E. Failure/retry
- simulate response/transport failure without deleting pending operation identity
- retry the same business operation
- verify no duplicate financial posting

F. Baseline and audit
- no unrelated rows changed
- audit trail remains intact

# 9. FINANCIAL HISTORY

Production QA/reversal entries in driver_ledger were deliberately preserved.

No historical financial rows were deleted in this Closure Unit because deletion without complete provenance would damage the audit trail.

The historical driver-ledger reconciliation remains a separate controlled Closure Unit.

# 10. NEXT CLOSURE ORDER

This Closure Unit is:

collectPayment() — OPEN OWNER PATCH

After it reaches 100%:

1. loadMyCustomers()
2. loadCustomerPatterns()
3. loadKPIs()
4. loadHomeSalesSummary()
5. loadMyInvoices()
6. showCustomerDetail()
7. repeatOrder()
8. initiateEndOfDay()

Do not skip ahead.

# FINAL SELF-AUDIT

What I Proved:
- Current protected collectPayment implementation and exact reliability defect.
- Production save-receipt-voucher v8 contract.
- Production post_van_sales_collection_atomic.
- Production custody-financial relationship.
- Production driver-ledger arithmetic state.
- Permanent backend correction applied in Production.
- Migration source recorded in canonical Git.
- No protected frontend file was modified.

What I Did Not Prove:
- Browser behavior after the owner applies the exact frontend patch.
- End-to-end duplicate retry after the frontend persistence patch.

What I Fixed:
- Production customer-collection path now credits the Direct Sales Representative driver ledger atomically.
- Canonical Git migration source recorded.

What I Initially Missed:
- A Van Sales collection must reduce representative custody liability as part of the same atomic business operation, not only cash and customer ledger.

What Could Still Be Wrong:
- The protected frontend remains unpatched until the owner applies the exact surgery.
- Historical driver-ledger snapshot inconsistency remains a separate financial reconciliation concern.

Final Confidence: 97/100

Final Closure Status:
INCOMPLETE — OWNER SURGICAL PATCH + E2E VERIFICATION REQUIRED

LAST VERIFIED CHECKPOINT:
Production backend custody-credit correction applied and verified in function definition.

NEXT EXACT EXECUTION STEP:
Apply only the documented App.collectPayment() surgical replacement in van-sales.html, then execute Syntax → Browser E2E → Same-operation Retry → Financial Verification → Close at 100%.
