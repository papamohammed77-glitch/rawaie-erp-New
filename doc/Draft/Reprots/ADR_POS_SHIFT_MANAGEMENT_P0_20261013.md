# ADR-POS-001 — إدارة الورديات والخزينة في تطبيق الكاشير RAWAEA ERP

- **التاريخ:** 2026-10-13
- **الحالة:** Proposed / P0 design approved for implementation planning; production schema changes intentionally not applied in this ADR.
- **النطاق:** POS shift lifecycle, cash reconciliation, terminal assignment, X/Z reports, and controlled paid-in/paid-out.
- **قيود:** لا تعديل على `main.html` أو ملف POS التشغيلي من المساعد؛ لا Edge Function جديدة افتراضيًا؛ لا إنشاء قيود مالية مكررة؛ لا ترحيل Production قبل تنسيق نشر UI/Edge/RPC.

## 1. Context — evidence from current Production

Production schema inspection confirmed the existence of:
- `public.orders` with `company_id`, `branch_id`, `source`, `payment_type`, `operation_id`, `order_status`; it does not currently have `shift_id`.
- `public.cash_box`, `public.treasury`, `public.sales_payment_receipts`, `public.audit_log`.
- No current `public.shifts`, `public.cash_movements`, `public.cash_count_details`, or `public.pos_terminals` tables were found.
- No `open_shift`, `close_shift`, `get_shift_summary`, or `get_pos_terminals` RPCs were found.

The current POS UI supports cash checkout, invoice lookup, returns and a pending-update reader. A complete offline checkout writer was not proven. Current live return-core ACL was separately repaired and is recorded in Report423.

## 2. Problem

The POS lacks a durable shift control plane for opening float, current X-report, counted cash, Z-report, immutable close, and device assignment. Adding UI-only fields would not establish accounting correctness or authorization. A second free-form `cash_movements` ledger would risk divergence from `cash_box`, `sales_payment_receipts`, orders and journal entries.

## 3. Decision

### 3.1 Shift is an operational control record, not a second financial ledger

A shift records:
- company, branch, cashier, terminal, assigned treasury/drawer, open/close timestamps and state;
- opening float, expected cash, counted cash, difference, discrepancy reason, close actor;
- immutable closing snapshot and operation identity.

Financial truth continues to come from the existing order/receipt/cash-box/journal contracts. Shift events may link to those records for reconciliation, but must not independently duplicate sale/refund/paid-in/paid-out money postings.

### 3.2 Proposed logical objects

1. **`pos_terminals`** — company-scoped terminal identity, terminal code, branch assignment, active flag and audit timestamps. Enforce company/branch consistency and a company-scoped unique terminal code.
2. **`pos_shifts`** — company, branch, cashier user, terminal, optional treasury/drawer, state (`open`, `closing`, `closed`, `frozen`), opening float, timestamps, expected/actual/difference, close reason and a stable operation identifier. Enforce at most one open shift per terminal and cashier/branch according to the owner-approved policy; use a partial unique index and row locks to prevent concurrent duplicate opens/closes.
3. **`pos_shift_cash_counts`** — denomination and non-negative count per shift, unique by shift + denomination, with positive denomination checks. Totals must be calculated by the database, not trusted from the browser.
4. **`pos_shift_events`** — immutable audit/link records for open, close, cash count, approval, and references to existing financial operations. This is not a financial ledger and must not become the source for balances.
5. **`orders.shift_id`** — nullable during rollout, referencing the shift used by a POS order. It becomes required for new POS sales only after the served POS UI and existing `save-sales-invoice` Edge are updated and verified. Historical non-POS orders remain unaffected.

Names and exact DDL are provisional until parent-table keys, existing order-core definitions, treasury semantics and authorization helpers are rechecked in the implementation commit. Do not copy the earlier proposal's DDL: it duplicates `company_id`, has no safe FK/RLS/unique/idempotency contract, and defines a globally unique shift code.

## 4. Authorization and database contract

- All mutating shift operations must run through authenticated, company-bound PostgreSQL RPCs, with `auth.uid()` resolved to `public.users.auth_id`, active status, company, POS permission, allowed branch and terminal assignment verified inside the database.
- Do not trust `company_id`, cashier identity, terminal identity, `isOwner`, supervisor PIN, amount, or close totals supplied by the browser.
- RPCs should use `SECURITY INVOKER` where feasible. If `SECURITY DEFINER` is required, use a fixed safe `search_path`, explicit ACL revokes from `PUBLIC/anon`, server-derived identity checks, and least-privilege grants.
- Required RPC contract candidates: `pos_open_shift`, `pos_get_shift_summary`, `pos_close_shift`, `pos_get_active_terminal_options`, and an approval RPC for sensitive actions. Names must be reconciled against the current schema and naming conventions before migration.
- Every mutating RPC needs a stable `operation_id`, request fingerprint, duplicate response behavior, row-level locking, and an audit event.
- RLS must be enabled on exposed tables. Policies must constrain both company and the actual permission/branch scope; `TO authenticated` alone is not authorization.
- Never store a supervisor PIN in plaintext in `public.users`. Use a server-side credential verifier with rate limiting, expiry, action scope, and audit logging, or use an authenticated approval flow already present in the project.

## 5. X-Report / Z-Report contract

- **X-Report** is a read-only snapshot and does not close or mutate the shift. Totals derive from the existing orders, cash receipt/refund and voucher records tied to the shift, plus opening float. It must identify the timestamp and data cutoff.
- **Z-Report** is a single atomic close transition. The database locks the shift, validates it is open, calculates expected cash from authoritative records, accepts denomination counts, computes actual cash and difference, requires a reason for non-zero difference, persists an immutable snapshot, records who closed it, and rejects repeated close attempts except as an idempotent replay of the same operation.
- `expected_cash = opening_float + cash receipts attributed to shift - cash refunds attributed to shift + approved paid-in - approved paid-out`. Do not include card/wallet settlements in physical drawer cash.
- A shift close does **not** automatically create a generic receipt voucher. A transfer to the main treasury is a separate real transfer, posted once through the existing approved transfer contract and linked to the shift. Never use a receipt voucher to represent cash already recorded as a sale.

## 6. Paid In / Paid Out and void/refund

- Paid In/Out must be posted through existing voucher/treasury contracts after their live definitions, idempotency and ACLs are audited. The shift event links to the resulting voucher/operation; it must not independently mutate cash balances.
- Limits and supervisor approval are server-side policy, not only UI validation.
- A POS void is not merely `orders.order_status='Cancelled'` plus a journal entry. It requires an atomic, idempotent reversal contract for stock, receipt/refund, accounting, original sale identity and audit. Do not add a void button until that contract is verified.
- Cash returns remain governed by the current `complete-return` flow and original receipt checks. Non-cash returns remain disabled until a complete settlement/refund contract exists.

## 7. Deployment sequence — no broken live POS

1. Reconfirm live schema, table constraints, voucher Edge sources, sale Core and order receipt posting.
2. Commit corrected schema/RLS migration and security tests, but do not apply yet.
3. Implement RPCs and database tests: normal open, duplicate retry, concurrent open, company/branch/terminal isolation, unauthorized role, normal close, concurrent close, mismatch reason, idempotent replay.
4. Update the **existing** `save-sales-invoice` Edge to validate and persist `shift_id` without creating a new Edge Function. Until the UI is coordinated, retain compatibility only as a time-bounded rollout flag; do not silently allow shiftless sales after the cutover.
5. Owner applies the POS UI change: shift gate before checkout, opening float/count, shift status, X-report, Z-report, terminal selection, pending-state messaging.
6. Deploy in a coordinated window; run authenticated E2E in isolated staging/test company. Never create synthetic financial transactions in real customer data.
7. Verify Production artifact/version, normal sale, retry, concurrent attempts, return, close, cash discrepancy, company isolation, no duplicate ledger postings and baseline restoration.
8. After all served clients enforce the shift contract, make `shift_id` mandatory for new POS sales in a separate migration and close the rollout debt.

## 8. Explicit non-goals for this ADR

- No new Edge Function by default.
- No UI redesign or change to `main.html`.
- No plaintext supervisor PIN.
- No direct browser writes to shift/cash tables.
- No new generic cash ledger competing with `cash_box`.
- No automatic treasury receipt at Z-close without a real transfer.
- No enablement of card/split payments without settlement contracts.
- No claim of completion before served-browser E2E and Production verification.

## 9. Acceptance gates

- Company/branch/terminal isolation proven at database level.
- At most one active shift according to the chosen policy under concurrency.
- Cash expected/actual/difference computed server-side and reproducible.
- Close is immutable and idempotent.
- Every cash operation links to its authoritative existing financial record.
- No duplicate receipts, refunds, journal entries or stock movements on retry.
- RLS/ACL and direct-RPC denial verified.
- Existing POS sale path remains functional during rollout and is fully shift-bound after cutover.
- Browser E2E, production deployment provenance, and clean baseline evidence are recorded before closure.
